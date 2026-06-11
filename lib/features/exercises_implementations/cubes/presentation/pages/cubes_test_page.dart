import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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

  // 14 items selon WAIS-IV : 2 exemples + 3 faciles + 4 moyens + 5 difficiles
  final List<DifficultyLevel> _difficultyProgression = [
    // Items 1-2 : Exemples (non cotés)
    DifficultyLevel.example,
    DifficultyLevel.example,

    // Items 3-5 : 2×2 simple, symétrique (2 points, pas de bonus)
    DifficultyLevel.veryEasy,
    DifficultyLevel.veryEasy,
    DifficultyLevel.veryEasy,

    // Items 6-9 : 3×3 modéré avec diagonales (4-7 points + bonus)
    DifficultyLevel.easy,
    DifficultyLevel.easy,
    DifficultyLevel.medium,
    DifficultyLevel.medium,

    // Items 10-14 : 3×3 complexe, haute cohésion (4-7 points + bonus)
    DifficultyLevel.mediumHard,
    DifficultyLevel.mediumHard,
    DifficultyLevel.hard,
    DifficultyLevel.veryHard,
    DifficultyLevel.veryHard,
  ];

  int _consecutiveFailures = 0;

  @override
  void initState() {
    super.initState();
    _patternGenerator = CubePatternGenerator();
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
    // Items 3-5 (indices 2-4) : 2 points fixes, pas de bonus
    if (currentLevel >= 2 && currentLevel <= 4) {
      return 2;
    }

    // Items 6-14 (indices 5-13) : 4-7 points base + bonus temps
    final basePoints = 4;

    // Bonus de temps selon WAIS-IV (en secondes absolues)
    int bonus = 0;
    if (timeSeconds <= 15) {
      bonus = 3; // 1-15 secondes : +3 points
    } else if (timeSeconds <= 30) {
      bonus = 2; // 16-30 secondes : +2 points
    } else if (timeSeconds <= 60) {
      bonus = 1; // 31-60 secondes : +1 point
    }
    // 61+ secondes : 0 bonus

    return basePoints + bonus;
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
              isCorrect ? 'Bravo !' : 'Incorrect',
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
            Text('Temps écoulé : ${_formatTime(timeSeconds)}'),
            if (isCorrect) ...[
              SizedBox(height: 8.h),
              Text(
                'Points gagnés : ${_calculatePoints(timeSeconds)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
            ],
            SizedBox(height: 8.h),
            Text('Score total : $score'),
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
                  ? 'Voir résultats (test terminé)'
                  : (currentLevel < _generatedPatterns.length - 1 ? 'Item suivant' : 'Voir résultats'),
            ),
          ),
        ],
      ),
    );
  }

  void _showFinalResults() {
    final completedItems = currentLevel + 1;
    final avgTime = completedItems > 0 ? totalTime ~/ completedItems : 0;

    // Score max : Items 3-5 = 2 pts × 3 = 6, Items 6-14 = 7 pts × 9 = 63, Total = 69
    final maxScore = 69;
    final percentageCorrect = (score / maxScore * 100).round();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Test terminé !'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _resultRow('Score total', '$score/$maxScore pts'),
            _resultRow('Items complétés', '$completedItems/14'),
            _resultRow('Taux de réussite', '$percentageCorrect%'),
            _resultRow('Temps moyen', _formatTime(avgTime)),
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
                    'Évaluation :',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    _getPerformanceLevel(percentageCorrect),
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
            child: const Text('Terminer'),
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
            child: const Text('Recommencer'),
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

  String _getPerformanceLevel(int percentage) {
    if (percentage >= 90) return 'Excellent ! Capacités visuospatiales très supérieures.';
    if (percentage >= 75) return 'Très bien ! Bonnes capacités d\'analyse visuelle.';
    if (percentage >= 60) return 'Bien. Capacités moyennes à bonnes.';
    if (percentage >= 40) return 'Moyen. Des améliorations sont possibles.';
    return 'Résultats en-dessous de la moyenne. Entraînement recommandé.';
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
      testName: 'Test des Cubes',
      eyebrow: 'RAISONNEMENT FLUIDE · FRI',
      accentColor: AppColors.indexFRI,
      currentItem: currentLevel + 1,
      totalItems: _generatedPatterns.length,
      // Tout tient à l'écran : les deux grilles se redimensionnent à la
      // hauteur disponible, les boutons restent toujours visibles.
      scrollable: false,
      trailing: [
        Padding(
          padding: EdgeInsets.only(left: 8.w),
          child: Text('$score pts',
              style: AppText.monoLabel(color: AppColors.indexFRI)),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Niveau — version compacte (la progression est déjà dans le scaffold)
          _buildLevelHeader(pattern),
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
  Widget _buildLevelHeader(CubePattern pattern) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Text(
            _getDifficultyLabel(pattern.difficulty),
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
            '${pattern.description} · Cohésion: ${pattern.cohesionScore}',
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

  String _getDifficultyLabel(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.example:
        return 'Exemple';
      case DifficultyLevel.veryEasy:
        return 'Facile';
      case DifficultyLevel.easy:
        return 'Moyen';
      case DifficultyLevel.medium:
        return 'Moyen';
      case DifficultyLevel.mediumHard:
        return 'Difficile';
      case DifficultyLevel.hard:
        return 'Difficile';
      case DifficultyLevel.veryHard:
        return 'Très difficile';
    }
  }
}
