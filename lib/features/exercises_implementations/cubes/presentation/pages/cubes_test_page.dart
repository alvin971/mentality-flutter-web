import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/l10n/l10n_ext.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/test/kepler_test_scaffold.dart';
import '../widgets/cubes_exercise_widget.dart';
import '../../domain/pattern_generator.dart';

/// Page de test des Cubes avec progression par niveaux
class CubesTestPage extends StatefulWidget {
  final String? filterLevel;
  const CubesTestPage({super.key, this.filterLevel});

  @override
  State<CubesTestPage> createState() => _CubesTestPageState();
}

class _CubesTestPageState extends State<CubesTestPage> {
  int currentLevel = 0;
  int score = 0;
  int totalTime = 0;
  bool showResult = false;
  bool? lastAnswerCorrect;

  late final CubePatternGenerator _patternGenerator;
  late List<CubePattern> _generatedPatterns;

  // 14 items selon WAIS-IV : 2 exemples + 3 faciles + 4 moyens + 5 difficiles.
  // L'ordre canonique (figé, versionné) est défini une seule fois dans le
  // générateur → source unique de vérité pour la banque déterministe.
  final List<DifficultyLevel> _difficultyProgression =
      CubePatternGenerator.kDifficultyProgression;

  int _consecutiveFailures = 0;

  @override
  void initState() {
    super.initState();
    // Graine versionnée explicite → banque déterministe (mêmes items,
    // même ordre pour toutes les passations, comparabilité CTT).
    _patternGenerator =
        CubePatternGenerator(seed: CubePatternGenerator.kBankSeed);
    _generateLevels();
  }

  void _generateLevels() {
    final level = widget.filterLevel;
    final progression = level != null
        ? _difficultyProgression.where((d) => d.name == level).toList()
        : _difficultyProgression;
    final effectiveProgression = progression.isNotEmpty ? progression : _difficultyProgression;
    _generatedPatterns = effectiveProgression
        .map((difficulty) => _patternGenerator.generatePattern(difficulty))
        .toList();
  }

  void _handleComplete(bool isCorrect, int timeSeconds) {
    setState(() {
      showResult = true;
      lastAnswerCorrect = isCorrect;
      totalTime += timeSeconds;

      // Gestion des échecs consécutifs
      if (isCorrect) {
        _consecutiveFailures = 0;
        // Calcul du score (pas de points pour les exemples)
        if (currentLevel >= 2) {
          int points = _calculatePoints(timeSeconds);
          score += points;
        }
      } else {
        _consecutiveFailures++;
      }
    });

    // Afficher le feedback
    _showFeedbackDialog(isCorrect, timeSeconds);
  }

  int _calculatePoints(int timeSeconds) {
    // Barème harmonisé : précision pure, AUCUN bonus de temps.
    // Items 3-5 (indices 2-4) : 2 points ; items 6-14 (indices 5-13) : 4 points.
    if (currentLevel >= 2 && currentLevel <= 4) {
      return 2;
    }
    return 4;
  }

  void _showFeedbackDialog(bool isCorrect, int timeSeconds) {
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
            Text(
              isCorrect ? context.l10n.cubesBravo : context.l10n.matIncorrect,
              style: TextStyle(
                color: isCorrect ? AppColors.success : AppColors.error,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.cubesElapsedTime(_formatTime(timeSeconds))),
            if (isCorrect) ...[
              SizedBox(height: 8.h),
              Text(
                context.l10n.cubesPointsEarned(_calculatePoints(timeSeconds)),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
            ],
            SizedBox(height: 8.h),
            Text(context.l10n.cubesTotalScore(score)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);

              // Vérifier règle de discontinuation (2 échecs consécutifs)
              if (_consecutiveFailures >= 2 || currentLevel >= _generatedPatterns.length - 1) {
                _showFinalResults();
              } else {
                setState(() {
                  currentLevel++;
                  showResult = false;
                  lastAnswerCorrect = null;
                });
              }
            },
            child: Text(
              _consecutiveFailures >= 2
                  ? context.l10n.matSeeResultsEnded
                  : (currentLevel < _generatedPatterns.length - 1
                      ? context.l10n.matNextItem
                      : context.l10n.matSeeResults),
            ),
          ),
        ],
      ),
    );
  }

  void _showFinalResults() {
    final completedItems = currentLevel + 1;
    final avgTime = completedItems > 0 ? totalTime ~/ completedItems : 0;

    // Score max : Items 3-5 = 2 pts × 3 = 6, Items 6-14 = 4 pts × 9 = 36, Total = 42
    final maxScore = 42;
    final percentageCorrect = (score / maxScore * 100).round();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.cubesFinishedTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _resultRow(context.l10n.cubesTotalScoreLabel,
                context.l10n.cubesTotalScoreValue(score, maxScore)),
            _resultRow(context.l10n.cubesItemsCompletedLabel,
                context.l10n.cubesItemsCompletedValue(completedItems)),
            _resultRow(
                context.l10n.matSuccessRate, '$percentageCorrect%'),
            _resultRow(context.l10n.cubesAvgTime, _formatTime(avgTime)),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.matEvaluation,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    _getPerformanceLevel(context, percentageCorrect),
                    style: TextStyle(fontSize: 13.sp),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, score); // Retourne le score final
            },
            child: Text(context.l10n.commonFinish),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                currentLevel = 0;
                score = 0;
                totalTime = 0;
                showResult = false;
                lastAnswerCorrect = null;
                _generateLevels(); // Régénérer des patterns aléatoires
              });
            },
            child: Text(context.l10n.matRestart),
          ),
        ],
      ),
    );
  }

  Widget _resultRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _getPerformanceLevel(BuildContext context, int percentage) {
    final l10n = context.l10n;
    if (percentage >= 90) return l10n.cubesPerfExcellent;
    if (percentage >= 75) return l10n.cubesPerfVeryGood;
    if (percentage >= 60) return l10n.matPerfGood;
    if (percentage >= 40) return l10n.matPerfAverage;
    return l10n.matPerfBelowAverage;
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final pattern = _generatedPatterns[currentLevel];

    return KeplerTestScaffold(
      testName: context.l10n.cubesTestName,
      eyebrow: context.l10n.fwEyebrow,
      accentColor: AppColors.indexFRI,
      currentItem: currentLevel + 1,
      totalItems: _generatedPatterns.length,
      // Tout tient à l'écran : les deux grilles se redimensionnent à la
      // hauteur disponible, les boutons restent toujours visibles.
      scrollable: false,
      trailing: [
        Padding(
          padding: EdgeInsets.only(left: 8.w),
          child: Text(context.l10n.matPoints(score),
              style: AppText.monoLabel(color: AppColors.indexFRI)),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Niveau — version compacte (la progression est déjà dans le scaffold)
          _buildLevelHeader(context, pattern),
          SizedBox(height: 8.h),

          // Exercice — occupe toute la hauteur restante
          Expanded(
            child: CubesExerciseWidget(
              key: ValueKey(currentLevel),
              gridSize: pattern.gridSize,
              targetPattern: pattern.pattern,
              timeLimitSeconds: pattern.timeLimit,
              onComplete: _handleComplete,
            ),
          ),
        ],
      ),
    );
  }

  // Version compacte : la progression d'items est déjà affichée par le
  // scaffold (KeplerProgress) — on ne garde que difficulté + description.
  Widget _buildLevelHeader(BuildContext context, CubePattern pattern) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Text(
            _getDifficultyLabel(context, pattern.difficulty),
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            '${_getPatternDescription(context, pattern.difficulty)} · '
            '${context.l10n.cubesCohesion(pattern.cohesionScore)}',
            style: TextStyle(
              fontSize: 11.sp,
              color: AppColors.grey600,
              fontStyle: FontStyle.italic,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _getDifficultyLabel(BuildContext context, DifficultyLevel difficulty) {
    final l10n = context.l10n;
    switch (difficulty) {
      case DifficultyLevel.example:
        return l10n.cubesDiffExample;
      case DifficultyLevel.veryEasy:
        return l10n.matDiffEasy;
      case DifficultyLevel.easy:
        return l10n.matDiffMedium;
      case DifficultyLevel.medium:
        return l10n.matDiffMedium;
      case DifficultyLevel.mediumHard:
        return l10n.matDiffHard;
      case DifficultyLevel.hard:
        return l10n.matDiffHard;
      case DifficultyLevel.veryHard:
        return l10n.cubesDiffVeryHard;
    }
  }

  String _getPatternDescription(
      BuildContext context, DifficultyLevel difficulty) {
    final l10n = context.l10n;
    switch (difficulty) {
      case DifficultyLevel.example:
        return l10n.cubesDescExample;
      case DifficultyLevel.veryEasy:
        return l10n.cubesDesc2x2;
      case DifficultyLevel.easy:
      case DifficultyLevel.medium:
        return l10n.cubesDesc3x3Diagonals;
      case DifficultyLevel.mediumHard:
      case DifficultyLevel.hard:
      case DifficultyLevel.veryHard:
        return l10n.cubesDesc3x3Complex;
    }
  }
}
