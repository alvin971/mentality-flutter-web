import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../domain/similarities_generator.dart';

/// Page du test des Similitudes (Similarities)
/// WAIS-IV : 21 items
/// Expliquer la similitude entre deux mots/concepts
/// Scoring : 0, 1, ou 2 points selon le niveau d'abstraction
/// Règle de discontinuation : 3 scores consécutifs de 0
class SimilaritiesTestPage extends StatefulWidget {
  final String? filterLevel;
  const SimilaritiesTestPage({super.key, this.filterLevel});

  @override
  State<SimilaritiesTestPage> createState() => _SimilaritiesTestPageState();
}

class _SimilaritiesTestPageState extends State<SimilaritiesTestPage> {
  int currentLevel = 0;
  int score = 0;
  int totalTime = 0;
  int _consecutiveZeros = 0;
  final TextEditingController _answerController = TextEditingController();
  DateTime? _itemStartTime;
  Timer? _timer;
  int _elapsedSeconds = 0;

  late List<SimilarityItem> _generatedItems;
  final List<ItemResult> _results = [];

  @override
  void initState() {
    super.initState();
    _generateItems();
    _startItem();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _answerController.dispose();
    super.dispose();
  }

  void _generateItems() {
    // Génération des 21 items UNIQUES en une seule fois
    final generator = SimilaritiesGenerator();
    _generatedItems = generator.generateComplete21Items();
  }

  void _startItem() {
    _itemStartTime = DateTime.now();
    _elapsedSeconds = 0;
    _answerController.clear();

    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  void _submitAnswer() {
    _timer?.cancel();

    final timeSeconds = _itemStartTime != null
        ? DateTime.now().difference(_itemStartTime!).inSeconds
        : 0;

    totalTime += timeSeconds;

    final currentItem = _generatedItems[currentLevel];
    final userAnswer = _answerController.text.trim();

    // Scoring automatique basé sur les réponses pré-définies
    final itemScore = currentItem.scoreAnswer(userAnswer);

    score += itemScore;

    // Gestion des échecs consécutifs
    if (itemScore == 0) {
      _consecutiveZeros++;
    } else {
      _consecutiveZeros = 0;
    }

    // Enregistrer le résultat
    _results.add(ItemResult(
      word1: currentItem.word1,
      word2: currentItem.word2,
      userAnswer: userAnswer,
      score: itemScore,
      timeSeconds: timeSeconds,
    ));

    _showFeedbackDialog(itemScore, timeSeconds, currentItem);
  }

  void _showFeedbackDialog(int itemScore, int timeSeconds, SimilarityItem item) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          itemScore == 2
              ? 'Excellent !'
              : itemScore == 1
                  ? 'Correct'
                  : 'Réponse incomplète',
          style: TextStyle(
            color: itemScore == 2
                ? AppColors.success
                : itemScore == 1
                    ? AppColors.warning
                    : AppColors.error,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                itemScore == 2
                    ? 'Réponse abstraite/catégorielle ! +2 points'
                    : itemScore == 1
                        ? 'Réponse fonctionnelle/propriété. +1 point'
                        : 'Réponse incorrecte ou trop vague. 0 point',
              ),
              SizedBox(height: 12.h),
              Text(
                'Votre réponse : "${_answerController.text}"',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
              SizedBox(height: 12.h),
              if (itemScore < 2) ...[
                Text(
                  'Exemples de réponses à 2 points :',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
                ...item.twoPointAnswers.take(2).map((ans) => Padding(
                      padding: EdgeInsets.only(left: 8.w, top: 4.h),
                      child: Text('• $ans'),
                    )),
              ],
              if (itemScore == 0) ...[
                SizedBox(height: 8.h),
                Text(
                  'Exemples de réponses à 1 point :',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.warning,
                  ),
                ),
                ...item.onePointAnswers.take(2).map((ans) => Padding(
                      padding: EdgeInsets.only(left: 8.w, top: 4.h),
                      child: Text('• $ans'),
                    )),
              ],
              SizedBox(height: 12.h),
              Text('Temps : ${timeSeconds}s'),
              Text('Score total : $score points'),
              if (_consecutiveZeros >= 3) ...[
                SizedBox(height: 8.h),
                Text(
                  '3 scores de 0 consécutifs - Test terminé (WAIS-IV)',
                  style: TextStyle(
                    color: AppColors.warning,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();

              // Règle de discontinuation : 3 scores de 0 consécutifs (WAIS-IV)
              if (_consecutiveZeros >= 3 || currentLevel >= _generatedItems.length - 1) {
                _showFinalResults();
              } else {
                setState(() {
                  currentLevel++;
                  _startItem();
                });
              }
            },
            child: Text(
              _consecutiveZeros >= 3 || currentLevel >= _generatedItems.length - 1
                  ? 'Voir les résultats'
                  : 'Continuer',
            ),
          ),
        ],
      ),
    );
  }

  void _showFinalResults() {
    final maxScore = _generatedItems.length * 2; // 21 items × 2 points = 42 max
    final percentageScore = (score / maxScore * 100).round();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(
          'Test des Similitudes - Résultats',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Score brut : $score/$maxScore points'),
              Text('Items complétés : ${currentLevel + 1}/21'),
              Text('Pourcentage : $percentageScore%'),
              Text('Temps total : ${totalTime}s'),
              SizedBox(height: 12.h),
              Text(
                _getPerformanceLevel(score),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _getPerformanceColor(score),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Test de raisonnement verbal et abstraction conceptuelle',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontStyle: FontStyle.italic,
                  color: AppColors.grey600,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Répartition par niveau :',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
              SizedBox(height: 8.h),
              ..._buildLevelBreakdown(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(score);
            },
            child: const Text('Retour'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildLevelBreakdown() {
    final levelScores = <AbstractionLevel, List<int>>{};

    for (int i = 0; i < _results.length; i++) {
      final result = _results[i];
      final item = _generatedItems[i];
      levelScores.putIfAbsent(item.level, () => []);
      levelScores[item.level]!.add(result.score);
    }

    return levelScores.entries.map((entry) {
      final total = entry.value.fold(0, (sum, score) => sum + score);
      final max = entry.value.length * 2;
      final levelName = _generatedItems
          .firstWhere((item) => item.level == entry.key)
          .levelName;

      return Padding(
        padding: EdgeInsets.only(bottom: 4.h),
        child: Text(
          '$levelName: $total/$max points',
          style: TextStyle(fontSize: 13.sp),
        ),
      );
    }).toList();
  }

  String _getPerformanceLevel(int score) {
    if (score >= 36) return 'Performance exceptionnelle (θ > +2.0)';
    if (score >= 28) return 'Performance supérieure (θ > +1.0)';
    if (score >= 20) return 'Performance moyenne (θ ≈ 0)';
    if (score >= 12) return 'Performance inférieure (θ < 0)';
    return 'Performance faible (θ < -1.0)';
  }

  Color _getPerformanceColor(int score) {
    if (score >= 36) return AppColors.indexFSIQ;
    if (score >= 28) return AppColors.success;
    if (score >= 20) return AppColors.info;
    if (score >= 12) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final currentItem = _generatedItems[currentLevel];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Similitudes'),
        actions: [
          Center(
            child: Padding(
              padding: EdgeInsets.only(right: 16.w),
              child: Text(
                'Item ${currentLevel + 1}/21',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Timer et score
              _buildHeader(),

              SizedBox(height: 24.h),

              // Instructions
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.infoContainer,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: AppColors.infoLight),
                ),
                child: Text(
                  'En quoi ces deux mots sont-ils similaires ?',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              SizedBox(height: 32.h),

              // Les deux mots
              Container(
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.indexVCI.withValues(alpha: 0.1),
                      AppColors.indexVCI.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.indexVCI, width: 2),
                ),
                child: Column(
                  children: [
                    Text(
                      currentItem.word1,
                      style: TextStyle(
                        fontSize: 32.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.indexVCI,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      '&',
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w300,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      currentItem.word2,
                      style: TextStyle(
                        fontSize: 32.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.indexVCI,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24.h),

              // Niveau d'abstraction
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: _getLevelColor(currentItem.level),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  'Niveau : ${currentItem.levelName}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              SizedBox(height: 24.h),

              // Champ de réponse
              Text(
                'Votre réponse :',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.h),
              TextField(
                controller: _answerController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Expliquez en quoi ils sont similaires...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  filled: true,
                  fillColor: AppColors.grey50,
                ),
                textCapitalization: TextCapitalization.sentences,
              ),

              SizedBox(height: 16.h),

              // Aide au scoring
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.warningContainer,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: AppColors.warningLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Conseils pour obtenir 2 points :',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.sp,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '• Donnez une catégorie abstraite ou superordonnée',
                      style: TextStyle(fontSize: 12.sp),
                    ),
                    Text(
                      '• Ex: "Ce sont des...", "Formes de...", "Types de..."',
                      style: TextStyle(fontSize: 12.sp),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24.h),

              // Bouton Valider
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: _answerController.text.trim().isNotEmpty
                      ? _submitAnswer
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.indexVCI,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Timer
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: AppColors.infoContainer,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: AppColors.infoLight, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timer,
                size: 20.sp,
                color: AppColors.info,
              ),
              SizedBox(width: 8.w),
              Text(
                '${_elapsedSeconds}s',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.info,
                ),
              ),
            ],
          ),
        ),

        // Score
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: AppColors.successContainer,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: AppColors.successLight, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.star,
                size: 20.sp,
                color: AppColors.warning,
              ),
              SizedBox(width: 8.w),
              Text(
                '$score pts',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getLevelColor(AbstractionLevel level) {
    switch (level) {
      case AbstractionLevel.concrete:
        return AppColors.success;
      case AbstractionLevel.functional:
        return AppColors.info;
      case AbstractionLevel.categorical:
        return AppColors.warning;
      case AbstractionLevel.abstract:
        return AppColors.indexFSIQ;
    }
  }
}

// ========== MODÈLE DE RÉSULTAT ==========

class ItemResult {
  final String word1;
  final String word2;
  final String userAnswer;
  final int score;
  final int timeSeconds;

  ItemResult({
    required this.word1,
    required this.word2,
    required this.userAnswer,
    required this.score,
    required this.timeSeconds,
  });
}
