import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';
import '../../../../../core/l10n/l10n_ext.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/kepler_colors.dart';
import '../../../../../core/widgets/test/kepler_test_button.dart';
import '../../../../../core/widgets/test/kepler_test_scaffold.dart';
import '../../domain/digit_span_generator.dart';
import '../../../../../core/services/results_sync.dart';
import '../../../../../core/services/subtest_instrumentation.dart';
import '../../../../../core/services/subtest_progress_store.dart';

/// Page du test Mémoire des Chiffres (Digit Span)
/// 3 parties : Forward, Backward, Sequencing
/// Présentation auditive TTS à 1 chiffre/seconde
class DigitSpanTestPage extends StatefulWidget {
  final String? filterLevel;
  const DigitSpanTestPage({super.key, this.filterLevel});

  @override
  State<DigitSpanTestPage> createState() => _DigitSpanTestPageState();
}

class _DigitSpanTestPageState extends State<DigitSpanTestPage> {
  final DigitSpanGenerator _generator = DigitSpanGenerator();

  // État général
  TestPhase _currentPhase = TestPhase.intro;
  SpanType _currentSpanType = SpanType.forward;

  // Items par partie
  late List<DigitSpanItem> _forwardItems;
  late List<DigitSpanItem> _backwardItems;
  late List<DigitSpanItem> _sequencingItems;

  // Progression
  int _currentItemIndex = 0;

  /// Rang de l'item DANS TOUT LE SOUS-TEST, qui ne redescend jamais.
  ///
  /// `_currentItemIndex` repart à zéro à chaque partie (direct, inverse,
  /// croissant) : s'en servir comme identifiant d'item produisait des rangs
  /// dupliqués (0,1,2,3 puis 0,1…). La clé d'unicité côté base est
  /// (session, sous-test, rang) : Postgres refuse un upsert qui touche deux
  /// fois la même ligne, et TOUT le lot d'items était rejeté d'un bloc. Les
  /// réponses de cet exercice n'ont donc jamais été enregistrées — personne ne
  /// s'en était aperçu, l'exercice n'ayant jamais été mené à terme en vrai.
  int _rangGlobal = 0;

  /// Mesure item par item (latence, hésitation, reprises).
  /// Aucune frappe individuelle n'est captée — cf. SubtestInstrumentation.
  final SubtestInstrumentation _instr =
      SubtestInstrumentation('digit_span');
  final List<int> _userAnswer = [];

  // Scoring par partie
  int _forwardScore = 0;
  int _backwardScore = 0;
  int _sequencingScore = 0;

  // Suivi des échecs consécutifs PAR LONGUEUR
  int _currentLength = 0;
  int _failuresAtCurrentLength = 0;

  // Présentation auditive
  bool _isPlayingSequence = false;
  int _currentDigitIndex = 0;
  Timer? _presentationTimer;

  @override
  void initState() {
    super.initState();
    _forwardItems = _generator.getForwardItems();
    _backwardItems = _generator.getBackwardItems();
    _sequencingItems = _generator.getSequencingItems();
    _reprendreSiInterrompu();
  }

  /// Reprend l'exercice là où une pause l'a laissé.
  ///
  /// Lecture SYNCHRONE — on est dans `initState`, on ne peut pas attendre, et
  /// le premier écran doit déjà refléter le bon endroit. Sans reprise, tout
  /// l'exercice repartait de son premier item : trois parties à refaire pour
  /// une pause prise à la dernière.
  void _reprendreSiInterrompu() {
    final p = SubtestProgressStore.instance.pour('digit_span');
    if (p == null) return;
    final e = p.etat;
    _currentSpanType = SpanType.values.firstWhere(
      (v) => v.name == e['spanType'],
      orElse: () => SpanType.forward,
    );
    _currentItemIndex = e['itemIndex'] is int ? e['itemIndex'] as int : 0;
    // Repli sur le NOMBRE de mesures déjà collectées, pas sur zéro : un point
    // de reprise écrit par une version antérieure ne porte pas `rangGlobal`,
    // et repartir de zéro ferait entrer en collision les rangs des nouveaux
    // items avec ceux des anciens — le dédoublonnage serveur en écraserait la
    // moitié. Constaté en base : 12 items déclarés, 6 enregistrés.
    _rangGlobal =
        e['rangGlobal'] is int ? e['rangGlobal'] as int : p.items.length;
    _forwardScore = e['forward'] is int ? e['forward'] as int : 0;
    _backwardScore = e['backward'] is int ? e['backward'] as int : 0;
    _sequencingScore = e['sequencing'] is int ? e['sequencing'] as int : 0;
    // Le compteur d'échecs repart à zéro : il porte sur une longueur de
    // séquence en cours, notion qui ne survit pas à une interruption. Au pire
    // l'exercice dure un essai de plus — jamais un de moins.
    _failuresAtCurrentLength = 0;
    _instr.rehydrate(p.items);
    // On rentre par l'introduction de partie : reprendre en plein milieu d'une
    // présentation auditive n'aurait aucun sens, la séquence a été entendue.
    _currentPhase = TestPhase.partIntro;
  }

  @override
  void dispose() {
    _presentationTimer?.cancel();
    super.dispose();
  }

  List<DigitSpanItem> get _currentItems {
    switch (_currentSpanType) {
      case SpanType.forward:
        return _forwardItems;
      case SpanType.backward:
        return _backwardItems;
      case SpanType.sequencing:
        return _sequencingItems;
    }
  }

  DigitSpanItem get _currentItem => _currentItems[_currentItemIndex];

  /// Libellé localisé du type d'empan (remplace [DigitSpanItem.typeDescription]).
  String _typeLabel(SpanType type) {
    switch (type) {
      case SpanType.forward:
        return context.l10n.dsTypeForward;
      case SpanType.backward:
        return context.l10n.dsTypeBackward;
      case SpanType.sequencing:
        return context.l10n.dsTypeSequencing;
    }
  }

  /// Consigne localisée du type d'empan (remplace [DigitSpanItem.instruction]).
  String _typeInstruction(SpanType type) {
    switch (type) {
      case SpanType.forward:
        return context.l10n.dsForwardInstruction;
      case SpanType.backward:
        return context.l10n.dsBackwardInstruction;
      case SpanType.sequencing:
        return context.l10n.dsSequencingInstruction;
    }
  }

  void _startTest() {
    setState(() {
      _currentPhase = TestPhase.partIntro;
      _currentSpanType = SpanType.forward;
      _currentItemIndex = 0;
    });
  }

  void _startPart() {
    setState(() {
      _currentPhase = TestPhase.sequencePresentation;
      _currentItemIndex = 0;
      _currentLength = _currentItem.length;
      _failuresAtCurrentLength = 0;
    });
    _playSequence();
  }

  /// Joue la séquence de chiffres avec TTS simulé (1 chiffre/seconde)
  void _playSequence() {
    _presentationTimer?.cancel();

    setState(() {
      _isPlayingSequence = true;
      _currentDigitIndex = 0;
      _userAnswer.clear();
    });

    _presentationTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      if (_currentDigitIndex >= _currentItem.sequence.length) {
        timer.cancel();
        setState(() {
          _isPlayingSequence = false;
          _currentPhase = TestPhase.userInput;
        });
        // L'item s'ouvre ICI : la séquence vient d'être jouée, la saisie
        // devient possible. L'ouvrir dans `_submitAnswer`, juste avant de le
        // fermer, faisait relever une latence de zéro milliseconde sur tous
        // les items — une mesure fausse, pire qu'absente.
        _instr.startItem(index: _rangGlobal);
      } else {
        setState(() {
          _currentDigitIndex++;
        });
      }
    });
  }

  void _addDigit(int digit) {
    if (_userAnswer.length < _currentItem.length) {
      setState(() {
        _userAnswer.add(digit);
      });
    }
  }

  void _removeLastDigit() {
    if (_userAnswer.isNotEmpty) {
      setState(() {
        _userAnswer.removeLast();
      });
    }
  }

  void _submitAnswer() {
    final isCorrect = _currentItem.isCorrect(_userAnswer);

    int pointsEarned = 0;

    _instr.endItem(
      response: _userAnswer.join(''),
      isCorrect: isCorrect,
      score: isCorrect ? 1 : 0,
    );

    if (isCorrect) {
      // Barème harmonisé : 1 point par essai réussi (max 46), pas de 2/1.
      pointsEarned = 1;
      _failuresAtCurrentLength = 0; // Réinitialiser les échecs
    } else {
      // Échec
      pointsEarned = 0;
      _failuresAtCurrentLength++;
    }

    // Ajouter les points à la partie en cours
    switch (_currentSpanType) {
      case SpanType.forward:
        _forwardScore += pointsEarned;
        break;
      case SpanType.backward:
        _backwardScore += pointsEarned;
        break;
      case SpanType.sequencing:
        _sequencingScore += pointsEarned;
        break;
    }

    _rangGlobal++;

    unawaited(SubtestProgressStore.instance.jalon(
      subtest: 'digit_span',
      prochainItem: _rangGlobal,
      score: _forwardScore + _backwardScore + _sequencingScore,
      instr: _instr,
      etat: {
        'spanType': _currentSpanType.name,
        'itemIndex': _currentItemIndex + 1,
        'rangGlobal': _rangGlobal,
        'forward': _forwardScore,
        'backward': _backwardScore,
        'sequencing': _sequencingScore,
      },
    ));

    _nextItem();
  }

  void _nextItem() {
    // Vérifier discontinuation : 0 point aux 2 essais d'une même longueur
    if (_failuresAtCurrentLength >= 2) {
      _endCurrentPart();
      return;
    }

    // Passer à l'item suivant
    if (_currentItemIndex < _currentItems.length - 1) {
      setState(() {
        _currentItemIndex++;
        // Si on change de longueur, réinitialiser le compteur d'échecs
        if (_currentItem.length != _currentLength) {
          _currentLength = _currentItem.length;
          _failuresAtCurrentLength = 0;
        }
        _currentPhase = TestPhase.sequencePresentation;
      });
      _playSequence();
    } else {
      _endCurrentPart();
    }
  }

  void _endCurrentPart() {
    // Passer à la partie suivante ou terminer le test
    if (_currentSpanType == SpanType.forward) {
      setState(() {
        _currentSpanType = SpanType.backward;
        _currentItemIndex = 0;
        _currentPhase = TestPhase.partIntro;
      });
    } else if (_currentSpanType == SpanType.backward) {
      setState(() {
        _currentSpanType = SpanType.sequencing;
        _currentItemIndex = 0;
        _currentPhase = TestPhase.partIntro;
      });
    } else {
      _showFinalResults();
    }
  }

  void _showFinalResults() {
    final totalScore = _forwardScore + _backwardScore + _sequencingScore;

    // Ferme le dialogue puis rend la main à l'orchestrateur AVEC le score.
    // On pope la page avec le contexte de l'État (pas celui du dialogue,
    // désactivé après le premier pop) : sans score retourné, l'orchestrateur
    // croit à un abandon et propose de recommencer le sous-test.
    void finish(BuildContext dialogContext) {
      Navigator.pop(dialogContext);
      if (mounted) Navigator.pop(context, totalScore);
    }

    // Les mesures partent MAINTENANT, sous-test par sous-test : une app
    // fermée plus loin dans la batterie ne doit pas emporter ce qui a déjà
    // été mesuré. Tir-et-oublie, fail-soft.
    // L'exercice est fini : il n'y a plus rien à reprendre. Laisser le point
    // de reprise en place le ferait redémarrer au milieu la fois suivante.
    unawaited(SubtestProgressStore.instance.clear());

    unawaited(ResultsSync.instance.flushSubtest(
      _instr.toPayload(),
    ));

    // Test non noté à l'écran : aucun récapitulatif de points/temps/réussite,
    // simple confirmation de fin — le score repart vers l'appelant, sans être montré.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) finish(dialogContext);
        },
        child: AlertDialog(
          title: Text(context.l10n.codingTestDoneTitle),
          actions: [
            TextButton(
              key: const Key('dsResultsBack'),
              onPressed: () => finish(dialogContext),
              child: Text(context.l10n.commonBack),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentPhase) {
      case TestPhase.intro:
        return _buildIntroScreen();
      case TestPhase.partIntro:
        return _buildPartIntroScreen();
      case TestPhase.sequencePresentation:
        return _buildSequencePresentationScreen();
      case TestPhase.userInput:
        return _buildUserInputScreen();
    }
  }

  Widget _buildIntroScreen() {
    return KeplerTestScaffold(
      testName: context.l10n.dsTestName,
      eyebrow: context.l10n.dsEyebrow,
      accentColor: AppColors.indexWMI,
      // Bouton de démarrage sticky : visible sans scroller.
      bottomBar: KeplerTestButton.primary(
        label: context.l10n.codingStartTest,
        accentColor: AppColors.indexWMI,
        onPressed: _startTest,
      ),
      child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.memory_outlined,
                size: 80.sp,
                color: AppColors.indexWMI,
              ),
              SizedBox(height: 24.h),
              Text(
                context.l10n.dsTestName,
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.indexWMI,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                context.l10n.dsDescription,
                style: TextStyle(fontSize: 16.sp),
              ),
              SizedBox(height: 24.h),
              _buildInfoCard(
                context.l10n.dsForwardTitle,
                context.l10n.dsForwardInstruction,
                Icons.arrow_forward,
              ),
              SizedBox(height: 12.h),
              _buildInfoCard(
                context.l10n.dsBackwardTitle,
                context.l10n.dsBackwardInstruction,
                Icons.swap_horiz,
              ),
              SizedBox(height: 12.h),
              _buildInfoCard(
                context.l10n.dsSequencingTitle,
                context.l10n.dsSequencingInstruction,
                Icons.sort,
              ),
              SizedBox(height: 24.h),
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: KeplerColors.of(context).info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: KeplerColors.of(context).info.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: KeplerColors.of(context).info, size: 24.sp),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        context.l10n.dsPresentationInfo,
                        style: TextStyle(color: KeplerColors.of(context).info, fontSize: 14.sp),
                      ),
                    ),
                  ],
                ),
              ),
            ],
      ),
    );
  }

  Widget _buildPartIntroScreen() {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_typeLabel(_currentItem.type)),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getPartIcon(),
                size: 80.sp,
                color: AppColors.indexWMI,
              ),
              SizedBox(height: 24.h),
              Text(
                _typeLabel(_currentItem.type),
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.indexWMI,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                _typeInstruction(_currentItem.type),
                style: TextStyle(fontSize: 18.sp),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 48.h),
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  key: const Key('dsStartPart'),
                  onPressed: _startPart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.indexWMI,
                  ),
                  child: Text(
                    context.l10n.dsStartPart,
                    style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSequencePresentationScreen() {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_typeLabel(_currentItem.type)),
        actions: [
          Center(
            child: Padding(
              padding: EdgeInsets.only(right: 16.w),
              child: Text(
                context.l10n.dsLengthTrial(_currentItem.length, _currentItem.trial),
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                context.l10n.dsListenCarefully,
                style: TextStyle(fontSize: 20.sp, color: KeplerColors.of(context).textSecondary),
              ),
              SizedBox(height: 8.h),
              // Rappel de la consigne de la partie en cours : sans lui,
              // l'utilisateur qui a raté l'écran d'intro croit devoir répéter
              // dans l'ordre entendu et vit l'inverse/le tri comme un bug.
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.w),
                child: Text(
                  _typeInstruction(_currentItem.type),
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.indexWMI,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 32.h),
              if (_currentDigitIndex > 0 && _currentDigitIndex <= _currentItem.sequence.length)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.8, end: 1.2),
                  duration: const Duration(milliseconds: 300),
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 150.w,
                        height: 150.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.indexWMI.withValues(alpha: 0.2),
                          border: Border.all(color: AppColors.indexWMI, width: 4),
                        ),
                        child: Center(
                          child: Text(
                            key: const Key('dsDigit'),
                            _currentItem.sequence[_currentDigitIndex - 1].toString(),
                            style: TextStyle(
                              fontSize: 64.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.indexWMI,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              if (_currentDigitIndex == 0)
                Container(
                  width: 150.w,
                  height: 150.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: KeplerColors.of(context).border,
                  ),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.indexWMI,
                      strokeWidth: 6.w,
                    ),
                  ),
                ),
              SizedBox(height: 24.h),
              Text(
                '${_currentDigitIndex} / ${_currentItem.sequence.length}',
                style: TextStyle(
                  fontSize: 18.sp,
                  color: KeplerColors.of(context).textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInputScreen() {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_typeLabel(_currentItem.type)),
        actions: [
          Center(
            child: Padding(
              padding: EdgeInsets.only(right: 16.w),
              child: Text(
                context.l10n.dsLengthTrial(_currentItem.length, _currentItem.trial),
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            children: [
              Text(
                _typeInstruction(_currentItem.type),
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32.h),
              // Affichage de la réponse de l'utilisateur
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: AppColors.indexWMI.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.indexWMI, width: 2),
                ),
                child: Wrap(
                  spacing: 12.w,
                  children: _userAnswer.isEmpty
                      ? [
                          Text(
                            context.l10n.dsEnterAnswer,
                            style: TextStyle(fontSize: 18.sp, color: KeplerColors.of(context).textSecondary),
                          )
                        ]
                      : _userAnswer.map((digit) {
                          return Container(
                            width: 50.w,
                            height: 50.w,
                            decoration: BoxDecoration(
                              color: AppColors.indexWMI,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Center(
                              child: Text(
                                digit.toString(),
                                style: TextStyle(
                                  fontSize: 24.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.surface,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                ),
              ),
              SizedBox(height: 32.h),
              // Clavier numérique — les 9 touches tiennent toujours dans la
              // hauteur disponible (pas de scroll interne).
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final tileW =
                        (constraints.maxWidth - 2 * 12.w) / 3;
                    final tileH =
                        (constraints.maxHeight - 2 * 12.h) / 3;
                    final aspectRatio =
                        (tileW / tileH).clamp(0.6, 4.0).toDouble();
                    return GridView.count(
                      crossAxisCount: 3,
                      mainAxisSpacing: 12.h,
                      crossAxisSpacing: 12.w,
                      childAspectRatio: aspectRatio,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        for (int i = 1; i <= 9; i++)
                          _buildNumberButton(i),
                      ],
                    );
                  },
                ),
              ),
              SizedBox(height: 16.h),
              // Boutons d'action
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50.h,
                      child: ElevatedButton(
                        onPressed: _userAnswer.isNotEmpty ? _removeLastDigit : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          disabledBackgroundColor: KeplerColors.of(context).surface,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.backspace, size: 20.sp),
                              SizedBox(width: 8.w),
                              Text(context.l10n.codingClear,
                                  style: TextStyle(fontSize: 16.sp)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 50.h,
                      child: ElevatedButton(
                        key: const Key('dsValidate'),
                        onPressed: _userAnswer.length == _currentItem.length
                            ? _submitAnswer
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.indexWMI,
                          disabledBackgroundColor: KeplerColors.of(context).surface,
                        ),
                        child: Text(
                          context.l10n.dsValidateProgress(_userAnswer.length, _currentItem.length),
                          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberButton(int number) {
    final isDisabled = _userAnswer.length >= _currentItem.length;
    return ElevatedButton(
      key: Key('dsKey$number'),
      onPressed: isDisabled ? null : () => _addDigit(number),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.indexWMI,
        disabledBackgroundColor: KeplerColors.of(context).surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
      child: Text(
        number.toString(),
        style: TextStyle(
          fontSize: 32.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String subtitle, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.indexWMI.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.indexWMI.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 32.sp, color: AppColors.indexWMI),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.indexWMI,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 14.sp, color: KeplerColors.of(context).textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getPartIcon() {
    switch (_currentSpanType) {
      case SpanType.forward:
        return Icons.arrow_forward;
      case SpanType.backward:
        return Icons.swap_horiz;
      case SpanType.sequencing:
        return Icons.sort;
    }
  }
}

enum TestPhase {
  intro,
  partIntro,
  sequencePresentation,
  userInput,
}
