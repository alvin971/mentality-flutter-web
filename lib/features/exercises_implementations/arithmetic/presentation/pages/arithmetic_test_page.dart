import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';
import '../../../../../core/l10n/l10n_ext.dart';
import '../../../../../core/l10n/locale_notifier.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/test/kepler_test_button.dart';
import '../../../../../core/widgets/test/kepler_test_scaffold.dart';
import '../../domain/arithmetic_generator.dart';
import '../../../../../core/theme/kepler_colors.dart';
import '../../../../../core/services/results_sync.dart';
import '../../../../../core/services/subtest_instrumentation.dart';
import '../../../../../core/services/subtest_progress_store.dart';

/// Page du test Arithmétique (Arithmetic)
/// Résolution mentale de 22 problèmes sous contrainte de temps
/// Possibilité de répéter l'énoncé UNE fois (chrono continue)
class ArithmeticTestPage extends StatefulWidget {
  final String? filterLevel;
  const ArithmeticTestPage({super.key, this.filterLevel});

  @override
  State<ArithmeticTestPage> createState() => _ArithmeticTestPageState();
}

class _ArithmeticTestPageState extends State<ArithmeticTestPage> {
  final ArithmeticGenerator _generator =
      ArithmeticGenerator(languageCode: localeNotifier.contentTag);
  late List<ArithmeticItem> _generatedItems;

  int _currentItemIndex = 0;
  int _score = 0;

  /// Mesure item par item (latence, hésitation, reprises).
  /// Aucune frappe individuelle n'est captée — cf. SubtestInstrumentation.
  final SubtestInstrumentation _instr =
      SubtestInstrumentation('arithmetic');
  int _consecutiveFailures = 0;

  // Timer
  Timer? _countdownTimer;
  int _remainingSeconds = 0;
  int _elapsedSeconds = 0;
  bool _isTimerRunning = false;

  // Entrée utilisateur
  final TextEditingController _answerController = TextEditingController();
  bool _hasRepeated = false; // Pour limiter la répétition à 1 fois

  @override
  void initState() {
    super.initState();
    final all = _generator.generateComplete22Items();
    final level = widget.filterLevel;
    if (level != null) {
      final filtered = all.where((item) => item.difficulty.name == level).toList();
      _generatedItems = filtered.isNotEmpty ? filtered : all;
    } else {
      _generatedItems = all;
    }
      _reprendreSiInterrompu();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _answerController.dispose();
    super.dispose();
  }

  ArithmeticItem get _currentItem => _generatedItems[_currentItemIndex];

  void _startItem() {
    setState(() {
      _remainingSeconds = _currentItem.timeLimitSeconds;
      _elapsedSeconds = 0;
      _isTimerRunning = true;
      _hasRepeated = false;
      _answerController.clear();
    });
    if (_currentItemIndex < _generatedItems.length) {
      _instr.startItem(
        index: _currentItemIndex,
        itemId: _currentItem.problem,
      );
    }

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds--;
        _elapsedSeconds++;
      });

      if (_remainingSeconds <= 0) {
        timer.cancel();
        _handleTimeout();
      }
    });
  }

  void _repeatProblem() {
    if (!_hasRepeated) {
      setState(() {
        _hasRepeated = true;
      });
      // Le chrono continue pendant la répétition
      _showRepeatDialog();
    }
  }

  void _showRepeatDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.arithRepeatTitle),
        content: Text(
          _currentItem.problem,
          style: TextStyle(fontSize: 16.sp),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(context.l10n.arithUnderstood),
          ),
        ],
      ),
    );
  }

  void _handleTimeout() {
    _countdownTimer?.cancel();
    setState(() {
      _isTimerRunning = false;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.timer_off, color: KeplerColors.of(context).error, size: 32.sp),
            SizedBox(width: 12.w),
            Text(context.l10n.arithTimeUp),
          ],
        ),
        // Pas de révélation de la bonne réponse : le participant ne reçoit
        // aucun retour de justesse pendant la passation (protocole WAIS-IV).
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _processAnswer(null);
            },
            child: Text(context.l10n.commonContinue),
          ),
        ],
      ),
    );
  }

  void _submitAnswer() {
    _countdownTimer?.cancel();
    setState(() {
      _isTimerRunning = false;
    });

    final userAnswer = int.tryParse(_answerController.text.trim());
    _processAnswer(userAnswer);
  }

  void _processAnswer(int? userAnswer) {
    final itemScore = _currentItem.calculateScore(userAnswer, _elapsedSeconds);

    _instr.endItem(
      response: userAnswer?.toString(),
      isCorrect: itemScore > 0,
      score: itemScore,
      timedOut: userAnswer == null,
    );

    unawaited(SubtestProgressStore.instance.jalon(
      subtest: 'arithmetic',
      prochainItem: _currentItemIndex + 1,
      score: _score,
      instr: _instr,
    ));

    setState(() {
      if (itemScore == 0) {
        _consecutiveFailures++;
      } else {
        _consecutiveFailures = 0;
        _score += 1; // 1 point pour réponse correcte (précision pure)
      }
    });

    _nextItem();
  }

  void _nextItem() {
    // Vérifier discontinuation : 3 échecs consécutifs
    if (_consecutiveFailures >= 3) {
      _showFinalResults();
      return;
    }

    // Passer à l'item suivant
    if (_currentItemIndex < _generatedItems.length - 1) {
      setState(() {
        _currentItemIndex++;
      });
      _startItem();
    } else {
      _showFinalResults();
    }
  }

  /// Reprend l'exercice au STADE où une pause l'a laissé.
  ///
  /// Aucun démarrage n'est déclenché ici : cet exercice attend que
  /// l'utilisateur lance lui-même, et `_startItem()` lira alors le rang
  /// restauré. On restitue le stade, jamais l'énoncé — les items sont
  /// regénérés au hasard, et c'est voulu.
  void _reprendreSiInterrompu() {
    final p = SubtestProgressStore.instance.pour('arithmetic');
    if (p == null) return;
    _currentItemIndex = p.itemIndex;
    _score = p.score;
    // Repart à zéro : il porte sur une série en cours, qui ne survit pas à une
    // interruption. Au pire un item de plus, jamais un de moins.
    _consecutiveFailures = 0;
    _instr.rehydrate(p.items);
  }

  void _showFinalResults() {
    // Terminé : plus rien à reprendre.
    unawaited(SubtestProgressStore.instance.clear());

    _countdownTimer?.cancel();

    // Les mesures partent MAINTENANT, sous-test par sous-test : une app
    // fermée plus loin dans la batterie ne doit pas emporter ce qui a déjà
    // été mesuré. Tir-et-oublie, fail-soft.
    unawaited(ResultsSync.instance.flushSubtest(
      _instr.toPayload(rawScore: _score, maxScore: _generatedItems.length),
    ));

    // Test non noté à l'écran : aucun récapitulatif de points/temps/réussite,
    // simple confirmation de fin — le score repart vers l'appelant, sans être montré.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.arithTestEnded),
        actions: [
          TextButton(
            onPressed: () {
              final totalScore = _score;
              Navigator.pop(context);
              Navigator.pop(context, totalScore);
            },
            child: Text(context.l10n.commonBack),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentItemIndex == 0 && !_isTimerRunning) {
      return _buildIntroScreen();
    }
    return _buildTestScreen();
  }

  Widget _buildIntroScreen() {
    return KeplerTestScaffold(
      testName: context.l10n.arithTestName,
      eyebrow: context.l10n.arithEyebrow,
      accentColor: AppColors.indexWMI,
      // Bouton de démarrage sticky : visible sans scroller.
      bottomBar: KeplerTestButton.primary(
        label: context.l10n.arithStartTest,
        accentColor: AppColors.indexWMI,
        onPressed: _startItem,
      ),
      child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.calculate_outlined,
                size: 80.sp,
                color: AppColors.indexWMI,
              ),
              SizedBox(height: 24.h),
              Text(
                context.l10n.arithIntroTitle,
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.indexWMI,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                context.l10n.arithIntroDescription,
                style: TextStyle(fontSize: 16.sp),
              ),
              SizedBox(height: 24.h),
              _buildInfoCard(
                context.l10n.arithInfoMentalTitle,
                context.l10n.arithInfoMentalSubtitle,
                Icons.psychology_outlined,
              ),
              SizedBox(height: 12.h),
              _buildInfoCard(
                context.l10n.arithInfoTimeTitle,
                context.l10n.arithInfoTimeSubtitle,
                Icons.timer_outlined,
              ),
              SizedBox(height: 12.h),
              _buildInfoCard(
                context.l10n.arithInfoRepeatTitle,
                context.l10n.arithInfoRepeatSubtitle,
                Icons.replay_outlined,
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
                        context.l10n.arithIntroDiscontinueNote,
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

  Widget _buildTestScreen() {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(context.l10n.arithTestName),
        actions: [
          Center(
            child: Padding(
              padding: EdgeInsets.only(right: 16.w),
              child: Text(
                context.l10n.arithProblemCounter(
                    _currentItemIndex + 1, _generatedItems.length),
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
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
              // Timer circulaire
              Container(
                width: 120.w,
                height: 120.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _remainingSeconds <= 5 ? AppColors.error : AppColors.indexWMI,
                    width: 6,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.timer,
                        size: 32.sp,
                        color: _remainingSeconds <= 5 ? AppColors.error : AppColors.indexWMI,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        context.l10n.commonSeconds(_remainingSeconds),
                        style: TextStyle(
                          fontSize: 28.sp,
                          fontWeight: FontWeight.bold,
                          color: _remainingSeconds <= 5 ? AppColors.error : AppColors.indexWMI,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 32.h),

              // Badge de difficulté
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: _getDifficultyColor().withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: _getDifficultyColor()),
                ),
                child: Text(
                  _difficultyName(_currentItem.difficulty),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: _getDifficultyColor(),
                  ),
                ),
              ),
              SizedBox(height: 24.h),

              // Énoncé du problème
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    padding: EdgeInsets.all(24.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.indexWMI.withValues(alpha: 0.15),
                          AppColors.indexWMI.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: AppColors.indexWMI, width: 2),
                    ),
                    child: Text(
                      _currentItem.problem,
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24.h),

              // Champ de réponse
              TextField(
                controller: _answerController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.indexWMI,
                ),
                decoration: InputDecoration(
                  hintText: context.l10n.arithAnswerHint,
                  hintStyle: TextStyle(
                    fontSize: 24.sp,
                    color: KeplerColors.of(context).textTertiary,
                  ),
                  filled: true,
                  fillColor: KeplerColors.of(context).surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: AppColors.indexWMI, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: AppColors.indexWMI, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: AppColors.indexWMI, width: 3),
                  ),
                ),
              ),
              SizedBox(height: 16.h),

              // Boutons d'action
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50.h,
                      child: OutlinedButton.icon(
                        onPressed: !_hasRepeated ? _repeatProblem : null,
                        icon: Icon(Icons.replay, size: 20.sp),
                        label: Text(
                          context.l10n.arithRepeat,
                          style: TextStyle(fontSize: 16.sp),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.indexWMI,
                          side: BorderSide(color: AppColors.indexWMI, width: 2),
                          disabledForegroundColor: KeplerColors.of(context).textTertiary,
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
                        onPressed: _answerController.text.trim().isNotEmpty
                            ? _submitAnswer
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.indexWMI,
                          disabledBackgroundColor: KeplerColors.of(context).surface,
                        ),
                        child: Text(
                          context.l10n.commonValidate,
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
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
          Icon(icon, size: 28.sp, color: AppColors.indexWMI),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.indexWMI,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 13.sp, color: KeplerColors.of(context).textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor() {
    switch (_currentItem.difficulty) {
      case DifficultyLevel.easy:
        return AppColors.success;
      case DifficultyLevel.medium:
        return AppColors.info;
      case DifficultyLevel.hard:
        return AppColors.warning;
      case DifficultyLevel.veryHard:
        return AppColors.error;
    }
  }

  /// Nom localisé du niveau de difficulté.
  String _difficultyName(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.easy:
        return context.l10n.arithDifficultyEasy;
      case DifficultyLevel.medium:
        return context.l10n.arithDifficultyMedium;
      case DifficultyLevel.hard:
        return context.l10n.arithDifficultyHard;
      case DifficultyLevel.veryHard:
        return context.l10n.arithDifficultyVeryHard;
    }
  }
}
