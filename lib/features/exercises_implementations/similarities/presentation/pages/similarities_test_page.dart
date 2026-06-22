import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/l10n/l10n_ext.dart';
import '../../../../../core/l10n/locale_notifier.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/test/kepler_test_button.dart';
import '../../../../../core/widgets/test/kepler_test_scaffold.dart';
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
    final generator =
        SimilaritiesGenerator(languageCode: localeNotifier.contentTag);
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
              ? context.l10n.simFeedbackExcellent
              : itemScore == 1
                  ? context.l10n.simFeedbackCorrect
                  : context.l10n.simFeedbackIncomplete,
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
                    ? context.l10n.simFeedbackMsg2pts
                    : itemScore == 1
                        ? context.l10n.simFeedbackMsg1pt
                        : context.l10n.simFeedbackMsg0pt,
              ),
              SizedBox(height: 12.h),
              Text(
                context.l10n.simYourAnswerQuoted(_answerController.text),
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
              SizedBox(height: 12.h),
              if (itemScore < 2) ...[
                Text(
                  context.l10n.simExamples2pts,
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
                  context.l10n.simExamples1pt,
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
              Text(context.l10n.simTimeSeconds(timeSeconds)),
              Text(context.l10n.simTotalScore(score)),
              if (_consecutiveZeros >= 3) ...[
                SizedBox(height: 8.h),
                Text(
                  context.l10n.simDiscontinue,
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
                  ? context.l10n.simSeeResults
                  : context.l10n.commonContinue,
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
        title: Text(
          context.l10n.simResultsTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.l10n.simRawScore(score, maxScore)),
              Text(context.l10n
                  .simItemsCompleted(currentLevel + 1, _generatedItems.length)),
              Text(context.l10n.simPercentage(percentageScore)),
              Text(context.l10n.simTotalTime(totalTime)),
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
                context.l10n.simSubtitle,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontStyle: FontStyle.italic,
                  color: AppColors.grey600,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                context.l10n.simBreakdownTitle,
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
            child: Text(context.l10n.simBack),
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
      final levelName = _levelName(entry.key);

      return Padding(
        padding: EdgeInsets.only(bottom: 4.h),
        child: Text(
          context.l10n.simBreakdownLine(levelName, total, max),
          style: TextStyle(fontSize: 13.sp),
        ),
      );
    }).toList();
  }

  /// Nom localisé du niveau d'abstraction (remplace [SimilarityItem.levelName]
  /// qui est figé en français).
  String _levelName(AbstractionLevel level) {
    switch (level) {
      case AbstractionLevel.concrete:
        return context.l10n.simLevelConcrete;
      case AbstractionLevel.functional:
        return context.l10n.simLevelFunctional;
      case AbstractionLevel.categorical:
        return context.l10n.simLevelCategorical;
      case AbstractionLevel.abstract:
        return context.l10n.simLevelAbstract;
    }
  }

  String _getPerformanceLevel(int score) {
    if (score >= 36) return context.l10n.simPerfExceptional;
    if (score >= 28) return context.l10n.simPerfSuperior;
    if (score >= 20) return context.l10n.simPerfAverage;
    if (score >= 12) return context.l10n.simPerfBelow;
    return context.l10n.simPerfLow;
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

    return KeplerTestScaffold(
      testName: context.l10n.simTestName,
      eyebrow: context.l10n.simEyebrow,
      accentColor: AppColors.indexVCI,
      currentItem: currentLevel + 1,
      totalItems: _generatedItems.length,
      // Timer + score dans l'AppBar et bouton Valider sticky en bas :
      // visible sans scroller, et il reste au-dessus du clavier.
      trailing: [
        Padding(
          padding: EdgeInsets.only(left: 8.w),
          child: Text(context.l10n.simStatusBar(_elapsedSeconds, score),
              style: AppText.monoLabel(color: AppColors.indexVCI)),
        ),
      ],
      bottomBar: KeplerTestButton.primary(
        label: context.l10n.commonValidate,
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
                  context.l10n.simQuestionPrompt,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              SizedBox(height: 12.h),

              // Les deux mots
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
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
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        currentItem.word1,
                        style: TextStyle(
                          fontSize: 26.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.indexVCI,
                        ),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      '&',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w300,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        currentItem.word2,
                        style: TextStyle(
                          fontSize: 26.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.indexVCI,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 12.h),

              // Niveau d'abstraction
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: _getLevelColor(currentItem.level),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  context.l10n.simLevelLabel(_levelName(currentItem.level)),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              SizedBox(height: 12.h),

              // Champ de réponse
              Text(
                context.l10n.simAnswerLabel,
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
                  hintText: context.l10n.simAnswerHint,
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
                      context.l10n.simTipsTitle,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.sp,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      context.l10n.simTipsLine1,
                      style: TextStyle(fontSize: 12.sp),
                    ),
                    Text(
                      context.l10n.simTipsLine2,
                      style: TextStyle(fontSize: 12.sp),
                    ),
                  ],
                ),
              ),

            ],
      ),
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
