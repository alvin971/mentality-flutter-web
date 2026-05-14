import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/test/kepler_test_scaffold.dart';
import '../../domain/vocabulary_generator.dart';

/// Page du test de Vocabulaire (Vocabulary)
/// WAIS-IV : 30 mots
/// Définir le mot présenté
/// Scoring : 0, 1, ou 2 points selon la précision de la définition
/// Règle de discontinuation : 3 scores consécutifs de 0
class VocabularyTestPage extends StatefulWidget {
  final String? filterLevel;
  const VocabularyTestPage({super.key, this.filterLevel});

  @override
  State<VocabularyTestPage> createState() => _VocabularyTestPageState();
}

class _VocabularyTestPageState extends State<VocabularyTestPage> {
  int currentLevel = 0;
  int score = 0;
  int totalTime = 0;
  int _consecutiveZeros = 0;
  final TextEditingController _answerController = TextEditingController();
  DateTime? _itemStartTime;
  Timer? _timer;
  int _elapsedSeconds = 0;

  late List<VocabularyItem> _generatedItems;
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
    // Génération des 30 items UNIQUES en une seule fois
    final generator = VocabularyGenerator();
    _generatedItems = generator.generateComplete30Items();
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
      word: currentItem.word,
      userAnswer: userAnswer,
      score: itemScore,
      timeSeconds: timeSeconds,
    ));

    _showFeedbackDialog(itemScore, timeSeconds, currentItem);
  }

  void _showFeedbackDialog(int itemScore, int timeSeconds, VocabularyItem item) {
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
                    ? 'Définition complète et précise ! +2 points'
                    : itemScore == 1
                        ? 'Définition partielle mais correcte. +1 point'
                        : 'Réponse incorrecte ou trop vague. 0 point',
              ),
              SizedBox(height: 12.h),
              Text(
                'Mot : "${item.word}"',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Votre réponse : "${_answerController.text.isEmpty ? "(vide)" : _answerController.text}"',
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
    final maxScore = _generatedItems.length * 2; // 30 items × 2 points = 60 max
    final percentageScore = (score / maxScore * 100).round();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(
          'Test de Vocabulaire - Résultats',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Score brut : $score/$maxScore points'),
              Text('Items complétés : ${currentLevel + 1}/30'),
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
                'Test de connaissance lexicale et compréhension verbale',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontStyle: FontStyle.italic,
                  color: AppColors.grey600,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Répartition par fréquence :',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
              SizedBox(height: 8.h),
              ..._buildFrequencyBreakdown(),
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

  List<Widget> _buildFrequencyBreakdown() {
    final frequencyScores = <WordFrequency, List<int>>{};

    for (int i = 0; i < _results.length; i++) {
      final result = _results[i];
      final item = _generatedItems[i];
      frequencyScores.putIfAbsent(item.frequency, () => []);
      frequencyScores[item.frequency]!.add(result.score);
    }

    return frequencyScores.entries.map((entry) {
      final total = entry.value.fold(0, (sum, score) => sum + score);
      final max = entry.value.length * 2;
      final frequencyName = _generatedItems
          .firstWhere((item) => item.frequency == entry.key)
          .frequencyName;

      return Padding(
        padding: EdgeInsets.only(bottom: 4.h),
        child: Text(
          '$frequencyName: $total/$max points',
          style: TextStyle(fontSize: 13.sp),
        ),
      );
    }).toList();
  }

  String _getPerformanceLevel(int score) {
    if (score >= 50) return 'Performance exceptionnelle (θ > +2.0)';
    if (score >= 40) return 'Performance supérieure (θ > +1.0)';
    if (score >= 28) return 'Performance moyenne (θ ≈ 0)';
    if (score >= 18) return 'Performance inférieure (θ < 0)';
    return 'Performance faible (θ < -1.0)';
  }

  Color _getPerformanceColor(int score) {
    if (score >= 50) return AppColors.indexFSIQ;
    if (score >= 40) return AppColors.success;
    if (score >= 28) return AppColors.info;
    if (score >= 18) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final currentItem = _generatedItems[currentLevel];

    return KeplerTestScaffold(
      testName: 'Vocabulaire',
      eyebrow: 'COMPRÉHENSION VERBALE · VCI',
      accentColor: AppColors.indexVCI,
      currentItem: currentLevel + 1,
      totalItems: _generatedItems.length,
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
                  'Définissez le mot suivant',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              SizedBox(height: 32.h),

              // Le mot à définir
              Container(
                padding: EdgeInsets.all(32.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.indexVCI.withValues(alpha: 0.15),
                      AppColors.indexVCI.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: AppColors.indexVCI, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.indexVCI.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    currentItem.word,
                    style: TextStyle(
                      fontSize: 42.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.indexVCI,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 24.h),

              // Fréquence du mot
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: _getFrequencyColor(currentItem.frequency),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star,
                          size: 16.sp,
                          color: AppColors.white,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          currentItem.frequencyName,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 28.h),

              // Champ de réponse
              Text(
                'Votre définition :',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.h),
              TextField(
                controller: _answerController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Écrivez la définition du mot...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: AppColors.grey300, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: AppColors.indexVCI, width: 2),
                  ),
                  filled: true,
                  fillColor: AppColors.grey50,
                  contentPadding: EdgeInsets.all(16.w),
                ),
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(fontSize: 15.sp),
              ),

              SizedBox(height: 20.h),

              // Aide au scoring
              Container(
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: AppColors.warningContainer,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.warningLight, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: AppColors.warning,
                          size: 20.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'Conseils pour obtenir 2 points :',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.sp,
                            color: AppColors.tertiary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      '• Donnez une définition complète et précise',
                      style: TextStyle(fontSize: 13.sp),
                    ),
                    Text(
                      '• Utilisez des synonymes exacts',
                      style: TextStyle(fontSize: 13.sp),
                    ),
                    Text(
                      '• Expliquez le sens avec contexte',
                      style: TextStyle(fontSize: 13.sp),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24.h),

              // Bouton Valider
              SizedBox(
                width: double.infinity,
                height: 54.h,
                child: ElevatedButton(
                  onPressed: _answerController.text.trim().isNotEmpty
                      ? _submitAnswer
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.indexVCI,
                    disabledBackgroundColor: AppColors.grey300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 4,
                  ),
                  child: Text(
                    'Valider',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Timer
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: AppColors.infoContainer,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: AppColors.infoLight, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timer_outlined,
                size: 22.sp,
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
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: AppColors.successContainer,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: AppColors.successLight, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.stars_rounded,
                size: 22.sp,
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

  Color _getFrequencyColor(WordFrequency frequency) {
    switch (frequency) {
      case WordFrequency.veryHigh:
        return AppColors.success;
      case WordFrequency.high:
        return AppColors.info;
      case WordFrequency.medium:
        return AppColors.warning;
      case WordFrequency.low:
        return AppColors.indexPSI;
      case WordFrequency.veryLow:
        return AppColors.error;
    }
  }
}

// ========== MODÈLE DE RÉSULTAT ==========

class ItemResult {
  final String word;
  final String userAnswer;
  final int score;
  final int timeSeconds;

  ItemResult({
    required this.word,
    required this.userAnswer,
    required this.score,
    required this.timeSeconds,
  });
}
