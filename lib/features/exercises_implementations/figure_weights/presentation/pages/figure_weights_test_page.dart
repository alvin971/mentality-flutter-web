import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/l10n/l10n_ext.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/test/kepler_test_button.dart';
import '../../../../../core/widgets/test/kepler_test_scaffold.dart';
import '../../domain/balance_generator.dart';
import '../widgets/balance_widget.dart';
import '../widgets/token_widget.dart';

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
  DateTime? _itemStartTime;
  Timer? _countdownTimer;
  int _remainingSeconds = 0;
  bool _submitted = false;

  late List<BalanceItem> _generatedItems;

  /// Phase de DÉMONSTRATION : un item d'exemple fixe, sans chrono ni score,
  /// rejouable jusqu'à réussite — comme la démonstration du protocole réel.
  bool _demoPhase = true;
  late final BalanceItem _demoItem;

  @override
  void initState() {
    super.initState();
    _demoItem = _buildDemoItem();
    _generateItems();
    // La démonstration n'est pas chronométrée : le compte à rebours ne
    // démarre qu'au passage au premier item réel (_startRealTest).
  }

  /// Item de démonstration FIXE et déterministe (aucun aléatoire) : une
  /// balance triviale « 2 cercles = 2 cercles », question « 2 cercles = ? »,
  /// 4 options A-D dont une seule correcte (2 cercles). Volontairement très
  /// facile pour illustrer le principe de l'exercice sans le noter.
  BalanceItem _buildDemoItem() {
    const shape = TokenShape.circle;
    final balance = Balance(
      leftSide: [Token(shape: shape, count: 2)],
      rightSide: [Token(shape: shape, count: 2)],
    );
    final correctAnswer = [Token(shape: shape, count: 2)];
    final options = <List<Token>>[
      [Token(shape: shape, count: 1)],
      [Token(shape: shape, count: 3)],
      correctAnswer,
      [Token(shape: shape, count: 4)],
    ];
    return BalanceItem(
      balances: [balance],
      question: BalanceQuestion(
        type: QuestionType.findEquivalent,
        targetSide: [Token(shape: shape, count: 2)],
      ),
      correctAnswer: correctAnswer,
      options: options,
      timeLimitSeconds: 20,
      thetaValue: -1.8,
    );
  }

  BalanceItem get _currentItem =>
      _demoPhase ? _demoItem : _generatedItems[currentLevel];

  void _startRealTest() {
    setState(() => _demoPhase = false);
    _startItem();
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

    if (isCorrect) {
      score++;
      _consecutiveFailures = 0;
    } else {
      _consecutiveFailures++;
    }

    _showFeedbackDialog(isCorrect, timeSeconds);
  }

  bool _listsEqual(List<Token> a, List<Token> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _showFeedbackDialog(bool isCorrect, int timeSeconds) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          isCorrect ? context.l10n.matCorrect : context.l10n.matIncorrect,
          style: TextStyle(
            color: isCorrect ? AppColors.success : AppColors.error,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isCorrect
                  ? context.l10n.fwCorrectAnswerPoint
                  : context.l10n.fwWrongAnswer,
            ),
            if (!isCorrect) ...[
              SizedBox(height: 8.h),
              _buildTokenList(_generatedItems[currentLevel].correctAnswer),
            ],
            SizedBox(height: 12.h),
            Text(context.l10n.fwTime(timeSeconds)),
            Text(context.l10n.matScoreFraction(score, currentLevel + 1)),
            if (_consecutiveFailures >= 3) ...[
              SizedBox(height: 8.h),
              Text(
                context.l10n.fwDiscontinue3,
                style: TextStyle(
                  color: AppColors.warning,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();

              // Règle de discontinuation : 3 échecs consécutifs (WAIS-IV)
              if (_consecutiveFailures >= 3 || currentLevel >= _generatedItems.length - 1) {
                _showFinalResults();
              } else {
                setState(() {
                  currentLevel++;
                  _startItem();
                });
              }
            },
            child: Text(
              _consecutiveFailures >= 3 ||
                      currentLevel >= _generatedItems.length - 1
                  ? context.l10n.fwSeeResults
                  : context.l10n.commonContinue,
            ),
          ),
        ],
      ),
    );
  }

  void _showFinalResults() {
    final percentageScore = (score / _generatedItems.length * 100).round();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          context.l10n.fwResultsTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.fwRawScorePoints(score)),
            Text(context.l10n.fwItemsCompleted(currentLevel + 1)),
            Text(context.l10n.fwPercentage(percentageScore)),
            Text(context.l10n.fwTotalTime(totalTime)),
            SizedBox(height: 12.h),
            Text(
              _getPerformanceLevel(context, score),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _getPerformanceColor(score),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              context.l10n.fwGLoading,
              style: TextStyle(
                fontSize: 12.sp,
                fontStyle: FontStyle.italic,
                color: AppColors.grey600,
              ),
            ),
          ],
        ),
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

  String _getPerformanceLevel(BuildContext context, int score) {
    final l10n = context.l10n;
    if (score >= 23) return l10n.fwPerfExceptional;
    if (score >= 18) return l10n.fwPerfSuperior;
    if (score >= 12) return l10n.fwPerfAverage;
    if (score >= 7) return l10n.fwPerfInferior;
    return l10n.fwPerfLow;
  }

  Color _getPerformanceColor(int score) {
    if (score >= 23) return AppColors.indexFSIQ;
    if (score >= 18) return AppColors.success;
    if (score >= 12) return AppColors.info;
    if (score >= 7) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final currentItem = _currentItem;

    return KeplerTestScaffold(
      testName: context.l10n.fwTestName,
      eyebrow: _demoPhase ? context.l10n.demoBadge : context.l10n.fwEyebrow,
      accentColor: AppColors.indexFRI,
      // Pas de barre de progression pendant la démo (hors des items notés) :
      // l'eyebrow « PRACTICE » s'affiche alors dans l'AppBar.
      currentItem: _demoPhase ? null : currentLevel + 1,
      totalItems: _demoPhase ? null : _generatedItems.length,
      // Timer + score dans l'AppBar (gain de hauteur) et bouton Valider
      // sticky en bas : plus jamais besoin de scroller pour valider.
      // Aucun badge chrono/score pendant la démo (non chronométrée, non notée).
      trailing: _demoPhase
          ? null
          : [
              Padding(
                padding: EdgeInsets.only(left: 8.w),
                child: _buildTimerBadge(context),
              ),
              Padding(
                padding: EdgeInsets.only(left: 6.w),
                child: Text(context.l10n.fwScoreFraction(score, currentLevel + 1),
                    style: AppText.monoLabel(color: AppColors.indexFRI)),
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
                    color: AppColors.grey600,
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
                                    : AppColors.grey50,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: demoResult == true
                              ? AppColors.success
                              : demoResult == false
                                  ? AppColors.error
                                  : isSelected
                                      ? AppColors.info
                                      : AppColors.grey300,
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
      return isCorrect ? context.l10n.demoStart : context.l10n.demoRetry;
    }
    return context.l10n.commonValidate;
  }

  VoidCallback? _bottomBarAction(BalanceItem item) {
    if (_demoPhase && _submitted) {
      final isCorrect = _selectedAnswer != null &&
          _listsEqual(_selectedAnswer!, item.correctAnswer);
      return isCorrect ? _startRealTest : _retryDemo;
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
