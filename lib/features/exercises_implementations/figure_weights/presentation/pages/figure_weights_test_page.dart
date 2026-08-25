import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/l10n/l10n_ext.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/test/kepler_test_button.dart';
import '../../../../../core/widgets/test/kepler_test_scaffold.dart';
import '../../domain/balance_generator.dart';
import '../widgets/balance_widget.dart';
import '../widgets/token_widget.dart';
import '../../../../../core/theme/kepler_colors.dart';
import '../../../../../core/services/results_sync.dart';
import '../../../../../core/services/subtest_instrumentation.dart';
import '../../../../../core/services/subtest_progress_store.dart';

/// Page du test des Balances Quantitatives (Figure Weights)
/// WAIS-IV : 27 items, g-loading = 0.78
/// Temps limite : 20s (facile), 30s (moyen), 45s (difficile)
/// Règle de discontinuation : 3 échecs consécutifs
class FigureWeightsTestPage extends StatefulWidget {
  final String? filterLevel;
  const FigureWeightsTestPage({super.key, this.filterLevel});

  @override
  State<FigureWeightsTestPage> createState() => _FigureWeightsTestPageState();
}

class _FigureWeightsTestPageState extends State<FigureWeightsTestPage> {
  int currentLevel = 0;
  int score = 0;
  int totalTime = 0;
  int _consecutiveFailures = 0;
  List<Token>? _selectedAnswer;

  /// Mesure item par item (latence, hésitation, reprises).
  /// Aucune frappe individuelle n'est captée — cf. SubtestInstrumentation.
  final SubtestInstrumentation _instr =
      SubtestInstrumentation('figure_weights');
  DateTime? _itemStartTime;
  Timer? _countdownTimer;
  int _remainingSeconds = 0;
  bool _submitted = false;

  late List<BalanceItem> _generatedItems;

  /// Phase de DÉMONSTRATION : TROIS items d'exemple fixes, sans chrono ni
  /// score, chacun rejouable jusqu'à réussite — comme la démonstration du
  /// protocole réel.
  bool _demoPhase = true;
  late final List<BalanceItem> _demoItems;

  /// Item d'entraînement courant.
  int _demoIndex = 0;

  bool get _isLastDemo => _demoIndex >= _demoItems.length - 1;

  @override
  void initState() {
    super.initState();
    _demoItems = _buildDemoItems();
    _generateItems();
    // La démonstration n'est pas chronométrée : le compte à rebours ne
    // démarre qu'au passage au premier item réel (_startRealTest).
      _reprendreSiInterrompu();
  }

  /// Les TROIS items d'entraînement, FIXES et déterministes (aucun aléatoire).
  ///
  /// Un seul exemple ne montrait que la lecture d'une balance ; il ne montrait
  /// pas ce que l'exercice demande réellement, qui est de CONVERTIR une forme
  /// en une autre. La progression est donc :
  ///
  /// 1. **Une seule forme.** « 2 cercles = 2 cercles » : on apprend à lire la
  ///    balance et à choisir parmi 4 options.
  /// 2. **Deux formes, une conversion.** « 1 carré = 2 cercles », donc
  ///    2 carrés valent 4 cercles — le premier item où il faut convertir.
  /// 3. **Deux balances enchaînées.** « 1 triangle = 2 carrés » et
  ///    « 1 carré = 2 cercles », donc 1 triangle vaut 4 cercles : c'est la
  ///    forme des items cotés, où la réponse passe par une forme
  ///    intermédiaire.
  List<BalanceItem> _buildDemoItems() => [
        _demoOneShape(),
        _demoConversion(),
        _demoChained(),
      ];

  /// 1 — « 2 cercles = 2 cercles », question « 2 cercles = ? ».
  BalanceItem _demoOneShape() {
    const shape = TokenShape.circle;
    final correctAnswer = [Token(shape: shape, count: 2)];
    return BalanceItem(
      balances: [
        Balance(
          leftSide: [Token(shape: shape, count: 2)],
          rightSide: [Token(shape: shape, count: 2)],
        ),
      ],
      question: BalanceQuestion(
        type: QuestionType.findEquivalent,
        targetSide: [Token(shape: shape, count: 2)],
      ),
      correctAnswer: correctAnswer,
      options: <List<Token>>[
        [Token(shape: shape, count: 1)],
        [Token(shape: shape, count: 3)],
        correctAnswer,
        [Token(shape: shape, count: 4)],
      ],
      timeLimitSeconds: 20,
      thetaValue: -1.8,
    );
  }

  /// 2 — « 1 carré = 2 cercles », question « 2 carrés = ? » → 4 cercles.
  ///
  /// Les distracteurs sont les erreurs qu'on fait vraiment : oublier de
  /// doubler (2), ne convertir qu'un seul carré (3), doubler deux fois (8).
  BalanceItem _demoConversion() {
    const a = TokenShape.square;
    const b = TokenShape.circle;
    final correctAnswer = [Token(shape: b, count: 4)];
    return BalanceItem(
      balances: [
        Balance(
          leftSide: [Token(shape: a, count: 1)],
          rightSide: [Token(shape: b, count: 2)],
        ),
      ],
      question: BalanceQuestion(
        type: QuestionType.findEquivalent,
        targetSide: [Token(shape: a, count: 2)],
      ),
      correctAnswer: correctAnswer,
      options: <List<Token>>[
        [Token(shape: b, count: 2)],
        correctAnswer,
        [Token(shape: b, count: 3)],
        [Token(shape: b, count: 8)],
      ],
      timeLimitSeconds: 25,
      thetaValue: -1.5,
    );
  }

  /// 3 — « 1 triangle = 2 carrés » et « 1 carré = 2 cercles »,
  /// question « 1 triangle = ? » → 4 cercles.
  BalanceItem _demoChained() {
    const a = TokenShape.triangle;
    const b = TokenShape.square;
    const c = TokenShape.circle;
    final correctAnswer = [Token(shape: c, count: 4)];
    return BalanceItem(
      balances: [
        Balance(
          leftSide: [Token(shape: a, count: 1)],
          rightSide: [Token(shape: b, count: 2)],
        ),
        Balance(
          leftSide: [Token(shape: b, count: 1)],
          rightSide: [Token(shape: c, count: 2)],
        ),
      ],
      question: BalanceQuestion(
        type: QuestionType.findEquivalent,
        targetSide: [Token(shape: a, count: 1)],
      ),
      correctAnswer: correctAnswer,
      options: <List<Token>>[
        [Token(shape: c, count: 2)],
        [Token(shape: c, count: 3)],
        correctAnswer,
        [Token(shape: c, count: 6)],
      ],
      timeLimitSeconds: 30,
      thetaValue: -1.2,
    );
  }

  BalanceItem get _currentItem =>
      _demoPhase ? _demoItems[_demoIndex] : _generatedItems[currentLevel];

  void _startRealTest() {
    setState(() => _demoPhase = false);
    _startItem();
  }

  /// Item d'entraînement suivant : même remise à zéro qu'un réessai, sur
  /// l'item d'après. Toujours pas de chrono — [_startItem] n'est appelé qu'au
  /// passage au test réel.
  void _nextDemo() {
    setState(() {
      _demoIndex++;
      _selectedAnswer = null;
      _submitted = false;
    });
  }

  void _retryDemo() {
    setState(() {
      _selectedAnswer = null;
      _submitted = false;
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _generateItems() {
    // Génération des 27 items UNIQUES en une seule fois
    final generator = BalanceGenerator();
    _generatedItems = generator.generateComplete27Items();
  }

  void _startItem() {
    _itemStartTime = DateTime.now();
    _selectedAnswer = null;
    _submitted = false;
    _remainingSeconds = _currentItem.timeLimitSeconds;
    if (!_demoPhase && currentLevel < _generatedItems.length) {
      _instr.startItem(index: currentLevel);
    }

    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _remainingSeconds--;
      });

      if (_remainingSeconds <= 0) {
        timer.cancel();
        // Temps écoulé = réponse incorrecte
        _submitAnswer();
      }
    });
  }

  void _submitAnswer() {
    if (_demoPhase) {
      // Démo : feedback visuel seulement — ni score, ni règle d'arrêt, ni
      // chrono, ni dialog révélant la suite (le bouton devient
      // « Commencer » / « Réessayer »).
      setState(() => _submitted = true);
      return;
    }

    _countdownTimer?.cancel();

    final timeSeconds = _itemStartTime != null
        ? DateTime.now().difference(_itemStartTime!).inSeconds
        : 0;

    totalTime += timeSeconds;

    final isCorrect = _selectedAnswer != null &&
        _listsEqual(_selectedAnswer!, _generatedItems[currentLevel].correctAnswer);

    _instr.endItem(
      response: _selectedAnswer?.map((t) => t.toString()).join(','),
      isCorrect: isCorrect,
      score: isCorrect ? 1 : 0,
      timedOut: _selectedAnswer == null,
    );

    unawaited(SubtestProgressStore.instance.jalon(
      subtest: 'figure_weights',
      prochainItem: currentLevel + 1,
      score: score,
      instr: _instr,
    ));

    if (isCorrect) {
      score++;
      _consecutiveFailures = 0;
    } else {
      _consecutiveFailures++;
    }

    // Test non noté à l'écran : on enchaîne sans retour « juste/faux ».
    // Discontinuation WAIS-IV : 3 échecs consécutifs.
    if (_consecutiveFailures >= 3 ||
        currentLevel >= _generatedItems.length - 1) {
      _showFinalResults();
    } else {
      setState(() {
        currentLevel++;
        _startItem();
      });
    }
  }

  bool _listsEqual(List<Token> a, List<Token> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Reprend l'exercice au STADE où une pause l'a laissé.
  ///
  /// On restitue le stade — rang, score, progression — jamais l'énoncé : les
  /// items sont regénérés au hasard à chaque lancement, et c'est voulu. Le
  /// compteur d'échecs consécutifs repart à zéro : il porte sur une série en
  /// cours, notion qui ne survit pas à une interruption. Au pire l'exercice
  /// dure un item de plus, jamais un de moins.
  ///
  /// La démonstration est sautée : elle a déjà été vue avant la pause, et la
  /// reposer à chaque reprise en ferait un péage.
  void _reprendreSiInterrompu() {
    final p = SubtestProgressStore.instance.pour('figure_weights');
    if (p == null) return;
    currentLevel = p.itemIndex;
    score = p.score;
    _consecutiveFailures = 0;
    _instr.rehydrate(p.items);
    _startRealTest();
  }

  void _showFinalResults() {
    // L'exercice est terminé : plus rien à reprendre. Laisser le point de
    // reprise en place le ferait redémarrer au milieu la fois suivante.
    unawaited(SubtestProgressStore.instance.clear());

    // Les mesures partent MAINTENANT, sous-test par sous-test : une app
    // fermée plus loin dans la batterie ne doit pas emporter ce qui a déjà
    // été mesuré. Tir-et-oublie, fail-soft.
    unawaited(ResultsSync.instance.flushSubtest(
      _instr.toPayload(rawScore: score, maxScore: _generatedItems.length),
    ));

    // Test non noté à l'écran : aucun récapitulatif de points/temps/réussite,
    // simple confirmation de fin — le score repart vers l'appelant, sans être montré.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.fwResultsTitle),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(score);
            },
            child: Text(context.l10n.commonBack),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentItem = _currentItem;

    return KeplerTestScaffold(
      stimulusSurface: true,
      testName: context.l10n.fwTestName,
      eyebrow: _demoPhase ? context.l10n.demoBadge : context.l10n.fwEyebrow,
      accentColor: AppColors.indexFRI,
      // Pendant l'entraînement, la barre compte les 3 items d'exemple et non
      // les items cotés — l'eyebrow « ENTRAÎNEMENT » lui sert de libellé.
      currentItem: _demoPhase ? _demoIndex + 1 : currentLevel + 1,
      totalItems: _demoPhase ? _demoItems.length : _generatedItems.length,
      // Chrono seul dans l'AppBar (gain de hauteur) et bouton Valider sticky
      // en bas : plus jamais besoin de scroller pour valider. Aucun score
      // visible pendant la passation (protocole WAIS-IV), et pas de chrono
      // pendant la démo (non chronométrée, non notée).
      trailing: _demoPhase
          ? null
          : [
              Padding(
                padding: EdgeInsets.only(left: 8.w),
                child: _buildTimerBadge(context),
              ),
            ],
      bottomBar: KeplerTestButton.primary(
        label: _bottomBarLabel(context, currentItem),
        accentColor: AppColors.indexFRI,
        onPressed: _bottomBarAction(currentItem),
      ),
      child: Column(
crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Instructions
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColors.infoContainer,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: AppColors.infoLight),
                ),
                child: Text(
                  context.l10n.fwInstruction,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              if (_demoPhase) ...[
                SizedBox(height: 6.h),
                Text(
                  context.l10n.demoNotice,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontStyle: FontStyle.italic,
                    color: KeplerColors.of(context).textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              SizedBox(height: 10.h),

              // Balances connues (équations) - TOUJOURS montrer les balances de référence
              ...currentItem.balances.map((balance) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 10.h),
                  child: BalanceWidget(
                    balance: balance,
                    showQuestion: false, // Ne jamais modifier la balance de référence
                    questionTokens: null,
                  ),
                );
              }),

              SizedBox(height: 6.h),

              // Question
              if (currentItem.question.targetSide.isNotEmpty) ...[
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: AppColors.warningContainer,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: AppColors.warningLight, width: 2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        context.l10n.fwWhatIs,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Flexible(
                        child: _buildTokenList(
                          currentItem.question.targetSide,
                          separator: currentItem.question.type ==
                                  QuestionType.findDifference
                              ? '−'
                              : '+',
                        ),
                      ),
                      Text(
                        ' ?',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10.h),
              ],

              // Options de réponse
              Text(
                context.l10n.matChooseAnswer,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.h),

              ...currentItem.options.asMap().entries.map((entry) {
                final index = entry.key;
                final option = entry.value;
                final isSelected = _selectedAnswer != null &&
                    _listsEqual(_selectedAnswer!, option);
                // Retour visuel de démo : une fois soumise, l'option choisie
                // se colore en vert (bonne réponse) ou rouge (mauvaise).
                final demoResult = (_demoPhase && _submitted && isSelected)
                    ? _listsEqual(option, currentItem.correctAnswer)
                    : null;

                return Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: InkWell(
                    onTap: (_demoPhase && _submitted)
                        ? null
                        : () {
                            setState(() {
                              _selectedAnswer = option;
                            });
                          },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 12.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: demoResult == true
                            ? AppColors.successContainer
                            : demoResult == false
                                ? AppColors.errorContainer
                                : isSelected
                                    ? AppColors.infoContainer
                                    : KeplerColors.of(context).surface,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: demoResult == true
                              ? AppColors.success
                              : demoResult == false
                                  ? AppColors.error
                                  : isSelected
                                      ? AppColors.info
                                      : KeplerColors.of(context).border,
                          width: isSelected ? 3 : 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '${String.fromCharCode(65 + index)}. ',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: _buildTokenList(option),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
        ],
      ),
    );
  }

  String _bottomBarLabel(BuildContext context, BalanceItem item) {
    if (_demoPhase && _submitted) {
      final isCorrect = _selectedAnswer != null &&
          _listsEqual(_selectedAnswer!, item.correctAnswer);
      if (!isCorrect) return context.l10n.demoRetry;
      return _isLastDemo ? context.l10n.demoStart : context.l10n.demoContinue;
    }
    return context.l10n.commonValidate;
  }

  VoidCallback? _bottomBarAction(BalanceItem item) {
    if (_demoPhase && _submitted) {
      final isCorrect = _selectedAnswer != null &&
          _listsEqual(_selectedAnswer!, item.correctAnswer);
      if (!isCorrect) return _retryDemo;
      return _isLastDemo ? _startRealTest : _nextDemo;
    }
    return _selectedAnswer != null ? _submitAnswer : null;
  }

  Widget _buildTimerBadge(BuildContext context) {
    final danger = _remainingSeconds <= 5;
    final color = danger ? AppColors.error : AppColors.info;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 14.sp, color: color),
          SizedBox(width: 4.w),
          Text(
            context.l10n.fwSeconds(_remainingSeconds),
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTokenList(List<Token> tokens, {String separator = '+'}) {
    return Wrap(
      spacing: 4.w,
      runSpacing: 4.h,
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var i = 0; i < tokens.length; i++) ...[
          TokenWidget(
            token: tokens[i],
            size: 28,
          ),
          if (i < tokens.length - 1)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Text(
                separator,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ],
    );
  }
}
