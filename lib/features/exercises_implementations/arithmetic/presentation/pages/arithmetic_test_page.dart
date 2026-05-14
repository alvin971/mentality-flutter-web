import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/test/kepler_test_scaffold.dart';
import '../../domain/arithmetic_generator.dart';

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
  final ArithmeticGenerator _generator = ArithmeticGenerator();
  late List<ArithmeticItem> _generatedItems;

  int _currentItemIndex = 0;
  int _score = 0;
  int _bonusPoints = 0;
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
        title: const Text('Répétition du problème'),
        content: Text(
          _currentItem.problem,
          style: TextStyle(fontSize: 16.sp),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Compris'),
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
            Icon(Icons.timer_off, color: AppColors.error, size: 32.sp),
            SizedBox(width: 12.w),
            const Text('Temps écoulé !'),
          ],
        ),
        content: Text('Réponse correcte : ${_currentItem.correctAnswer}'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _processAnswer(null);
            },
            child: const Text('Continuer'),
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
    final isCorrect = userAnswer == _currentItem.correctAnswer;
    final hasBonus = itemScore > 1;

    setState(() {
      if (itemScore == 0) {
        _consecutiveFailures++;
      } else {
        _consecutiveFailures = 0;
        _score += 1; // 1 point pour réponse correcte
        if (hasBonus) {
          _bonusPoints += 1; // Bonus de temps
        }
      }
    });

    _showFeedback(isCorrect, hasBonus);
  }

  void _showFeedback(bool isCorrect, bool hasBonus) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isCorrect ? Icons.check_circle : Icons.cancel,
              color: isCorrect ? AppColors.success : AppColors.error,
              size: 32.sp,
            ),
            SizedBox(width: 12.w),
            Text(isCorrect ? 'Correct !' : 'Incorrect'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Réponse correcte : ${_currentItem.correctAnswer}'),
            if (isCorrect) ...[
              SizedBox(height: 8.h),
              Text('Temps : $_elapsedSeconds secondes'),
              if (hasBonus) ...[
                SizedBox(height: 8.h),
                Text(
                  '🎉 Bonus de rapidité ! (+1 point)',
                  style: TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _nextItem();
            },
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
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

  void _showFinalResults() {
    _countdownTimer?.cancel();

    final totalScore = _score + _bonusPoints;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Test terminé !'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Items complétés : ${_currentItemIndex + 1}/22',
              style: TextStyle(fontSize: 16.sp),
            ),
            SizedBox(height: 12.h),
            Text('Score de base : $_score points'),
            Text('Bonus de rapidité : $_bonusPoints points'),
            SizedBox(height: 16.h),
            Text(
              'Score Total : $totalScore points',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.indexWMI,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              final totalScore = _score + _bonusPoints;
              Navigator.pop(context);
              Navigator.pop(context, totalScore);
            },
            child: const Text('Retour'),
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
      testName: 'Arithmétique',
      eyebrow: 'MÉMOIRE DE TRAVAIL · WMI',
      accentColor: AppColors.indexWMI,
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
                'Test d\'Arithmétique',
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.indexWMI,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Ce test mesure votre mémoire de travail et votre raisonnement numérique.',
                style: TextStyle(fontSize: 16.sp),
              ),
              SizedBox(height: 24.h),
              _buildInfoCard(
                'Calcul mental uniquement',
                'Résolvez les problèmes sans papier ni calculatrice',
                Icons.psychology_outlined,
              ),
              SizedBox(height: 12.h),
              _buildInfoCard(
                'Temps limité',
                'Chaque problème a une limite de temps (15-60 secondes)',
                Icons.timer_outlined,
              ),
              SizedBox(height: 12.h),
              _buildInfoCard(
                'Bonus de rapidité',
                'Réponses rapides sur certains items = points bonus',
                Icons.speed_outlined,
              ),
              SizedBox(height: 12.h),
              _buildInfoCard(
                'Répétition possible',
                'Vous pouvez demander de répéter UNE fois (chrono continue)',
                Icons.replay_outlined,
              ),
              SizedBox(height: 24.h),
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.info, size: 24.sp),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        '22 problèmes au total. Le test s\'arrête après 3 échecs consécutifs.',
                        style: TextStyle(color: AppColors.info, fontSize: 14.sp),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32.h),
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: _startItem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.indexWMI,
                  ),
                  child: Text(
                    'Commencer le test',
                    style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
      ),
    );
  }

  Widget _buildTestScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Arithmétique'),
        actions: [
          Center(
            child: Padding(
              padding: EdgeInsets.only(right: 16.w),
              child: Text(
                'Problème ${_currentItemIndex + 1}/22',
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
                        '$_remainingSeconds s',
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
                  _currentItem.difficultyName,
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
                  hintText: 'Votre réponse',
                  hintStyle: TextStyle(
                    fontSize: 24.sp,
                    color: AppColors.grey400,
                  ),
                  filled: true,
                  fillColor: AppColors.grey50,
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
                          'Répéter',
                          style: TextStyle(fontSize: 16.sp),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.indexWMI,
                          side: BorderSide(color: AppColors.indexWMI, width: 2),
                          disabledForegroundColor: AppColors.grey400,
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
                          disabledBackgroundColor: AppColors.grey300,
                        ),
                        child: Text(
                          'Valider',
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
                  style: TextStyle(fontSize: 13.sp, color: AppColors.grey700),
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
}
