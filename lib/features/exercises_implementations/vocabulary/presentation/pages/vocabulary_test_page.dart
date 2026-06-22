import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/l10n/l10n_ext.dart';
import '../../../../../core/l10n/locale_notifier.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/test/kepler_test_button.dart';
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
    final generator =
        VocabularyGenerator(languageCode: localeNotifier.contentTag);
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
    final l10n = context.l10n;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          itemScore == 2
              ? l10n.vocabFeedbackExcellent
              : itemScore == 1
                  ? l10n.vocabFeedbackCorrect
                  : l10n.vocabFeedbackIncomplete,
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
                    ? l10n.vocabFeedbackTwoPoints
                    : itemScore == 1
                        ? l10n.vocabFeedbackOnePoint
                        : l10n.vocabFeedbackZeroPoint,
              ),
              SizedBox(height: 12.h),
              Text(
                l10n.vocabWordLabel(item.word),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                l10n.vocabYourAnswerLabel(
                  _answerController.text.isEmpty
                      ? l10n.vocabEmptyAnswer
                      : _answerController.text,
                ),
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
              SizedBox(height: 12.h),
              if (itemScore < 2) ...[
                Text(
                  l10n.vocabTwoPointExamples,
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
                  l10n.vocabOnePointExamples,
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
              Text(l10n.vocabTimeSeconds(timeSeconds)),
              Text(l10n.vocabTotalScore(score)),
              if (_consecutiveZeros >= 3) ...[
                SizedBox(height: 8.h),
                Text(
                  l10n.vocabDiscontinued,
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
              _consecutiveZeros >= 3 ||
                      currentLevel >= _generatedItems.length - 1
                  ? l10n.vocabViewResults
                  : l10n.commonContinue,
            ),
          ),
        ],
      ),
    );
  }

  void _showFinalResults() {
    final l10n = context.l10n;
    final maxScore = _generatedItems.length * 2; // 30 items × 2 points = 60 max
    final percentageScore = (score / maxScore * 100).round();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          l10n.vocabResultsTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.vocabRawScore(score, maxScore)),
              Text(l10n.vocabItemsCompleted(
                  currentLevel + 1, _generatedItems.length)),
              Text(l10n.vocabPercentage(percentageScore)),
              Text(l10n.vocabTotalTime(totalTime)),
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
                l10n.vocabTestCaption,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontStyle: FontStyle.italic,
                  color: AppColors.grey600,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                l10n.vocabFrequencyBreakdownTitle,
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
            child: Text(l10n.commonBack),
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
      final frequencyName = _frequencyName(entry.key);

      return Padding(
        padding: EdgeInsets.only(bottom: 4.h),
        child: Text(
          context.l10n.vocabFrequencyBreakdownRow(frequencyName, total, max),
          style: TextStyle(fontSize: 13.sp),
        ),
      );
    }).toList();
  }

  /// Nom localisé du niveau de fréquence (FR/EN selon la locale courante).
  String _frequencyName(WordFrequency frequency) {
    final l10n = context.l10n;
    switch (frequency) {
      case WordFrequency.veryHigh:
        return l10n.vocabFreqVeryHigh;
      case WordFrequency.high:
        return l10n.vocabFreqHigh;
      case WordFrequency.medium:
        return l10n.vocabFreqMedium;
      case WordFrequency.low:
        return l10n.vocabFreqLow;
      case WordFrequency.veryLow:
        return l10n.vocabFreqVeryLow;
    }
  }

  String _getPerformanceLevel(int score) {
    final l10n = context.l10n;
    if (score >= 50) return l10n.vocabPerfExceptional;
    if (score >= 40) return l10n.vocabPerfSuperior;
    if (score >= 28) return l10n.vocabPerfAverage;
    if (score >= 18) return l10n.vocabPerfBelowAverage;
    return l10n.vocabPerfLow;
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
    final l10n = context.l10n;
    final currentItem = _generatedItems[currentLevel];

    return KeplerTestScaffold(
      testName: l10n.vocabTestName,
      eyebrow: l10n.vocabEyebrow,
      accentColor: AppColors.indexVCI,
      currentItem: currentLevel + 1,
      totalItems: _generatedItems.length,
      // Timer + score dans l'AppBar et bouton Valider sticky en bas :
      // visible sans scroller, et il reste au-dessus du clavier.
      trailing: [
        Padding(
          padding: EdgeInsets.only(left: 8.w),
          child: Text(l10n.vocabTimerScore(_elapsedSeconds, score),
              style: AppText.monoLabel(color: AppColors.indexVCI)),
        ),
      ],
      bottomBar: KeplerTestButton.primary(
        label: l10n.commonValidate,
        accentColor: AppColors.indexVCI,
        onPressed:
            _answerController.text.trim().isNotEmpty ? _submitAnswer : null,
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
                  l10n.vocabInstruction,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              SizedBox(height: 12.h),

              // Le mot à définir
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
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
                  // FittedBox : les mots longs se réduisent au lieu de
                  // déborder sur les écrans étroits.
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      currentItem.word,
                      style: TextStyle(
                        fontSize: 34.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.indexVCI,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 12.h),

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
                          color: Theme.of(context).colorScheme.surface,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          _frequencyName(currentItem.frequency),
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.surface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12.h),

              // Champ de réponse
              Text(
                l10n.vocabYourDefinitionLabel,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 6.h),
              TextField(
                controller: _answerController,
                maxLines: 3,
                // Met à jour l'état du bouton Valider à chaque frappe.
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: l10n.vocabDefinitionHint,
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

              SizedBox(height: 12.h),

              // Aide au scoring
              Container(
                padding: EdgeInsets.all(10.w),
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
                        Expanded(
                          child: Text(
                            l10n.vocabTipsTitle,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                              color: AppColors.tertiary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      l10n.vocabTipComplete,
                      style: TextStyle(fontSize: 13.sp),
                    ),
                    Text(
                      l10n.vocabTipSynonyms,
                      style: TextStyle(fontSize: 13.sp),
                    ),
                    Text(
                      l10n.vocabTipContext,
                      style: TextStyle(fontSize: 13.sp),
                    ),
                  ],
                ),
              ),

            ],
      ),
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
