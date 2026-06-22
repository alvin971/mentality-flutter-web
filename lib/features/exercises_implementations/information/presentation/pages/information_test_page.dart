import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/l10n/l10n_ext.dart';
import '../../../../../core/l10n/locale_notifier.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/test/kepler_test_button.dart';
import '../../../../../core/widgets/test/kepler_test_scaffold.dart';
import '../../domain/information_generator.dart';

/// Page du test d'Information (Connaissances générales)
/// WAIS-IV : 28 questions
/// QCM à 4 options
/// Scoring dichotomique : 0 ou 1
/// Règle de discontinuation : 3 échecs consécutifs
class InformationTestPage extends StatefulWidget {
  final String? filterLevel;
  const InformationTestPage({super.key, this.filterLevel});

  @override
  State<InformationTestPage> createState() => _InformationTestPageState();
}

class _InformationTestPageState extends State<InformationTestPage> {
  int currentLevel = 0;
  int score = 0;
  int totalTime = 0;
  int _consecutiveFailures = 0;
  int? _selectedAnswer;
  DateTime? _itemStartTime;
  Timer? _timer;
  int _elapsedSeconds = 0;

  late List<InformationItem> _generatedItems;
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
    super.dispose();
  }

  void _generateItems() {
    // Génération des 28 items UNIQUES en une seule fois
    final generator =
        InformationGenerator(languageCode: localeNotifier.contentTag);
    final all = generator.generateComplete28Items();
    final level = widget.filterLevel;
    if (level != null) {
      final filtered = all.where((item) => item.difficulty.name == level).toList();
      _generatedItems = filtered.isNotEmpty ? filtered : all;
    } else {
      _generatedItems = all;
    }
  }

  void _startItem() {
    _itemStartTime = DateTime.now();
    _elapsedSeconds = 0;
    _selectedAnswer = null;

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

  void _selectAnswer(int index) {
    setState(() {
      _selectedAnswer = index;
    });
  }

  void _submitAnswer() {
    if (_selectedAnswer == null) return;

    _timer?.cancel();

    final timeSeconds = _itemStartTime != null
        ? DateTime.now().difference(_itemStartTime!).inSeconds
        : 0;

    totalTime += timeSeconds;

    final currentItem = _generatedItems[currentLevel];
    final isCorrect = currentItem.isCorrect(_selectedAnswer!);

    if (isCorrect) {
      score++;
      _consecutiveFailures = 0;
    } else {
      _consecutiveFailures++;
    }

    // Enregistrer le résultat
    _results.add(ItemResult(
      question: currentItem.question,
      selectedAnswer: _selectedAnswer!,
      correctAnswer: currentItem.correctAnswer,
      isCorrect: isCorrect,
      timeSeconds: timeSeconds,
    ));

    _showFeedbackDialog(isCorrect, timeSeconds, currentItem);
  }

  void _showFeedbackDialog(
      bool isCorrect, int timeSeconds, InformationItem item) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          isCorrect ? context.l10n.infoCorrect : context.l10n.infoIncorrect,
          style: TextStyle(
            color: isCorrect ? AppColors.success : AppColors.error,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isCorrect
                    ? context.l10n.infoFeedbackRight
                    : context.l10n.infoFeedbackWrong,
              ),
              SizedBox(height: 12.h),
              Text(
                context.l10n.infoQuestionLabel(item.question),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.h),
              if (!isCorrect) ...[
                Text(
                  context.l10n.infoCorrectAnswerLabel(
                      item.options[item.correctAnswer]),
                  style: TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
              ],
              Text(context.l10n.infoTimeLabel(timeSeconds)),
              Text(context.l10n.infoScoreLabel(score, currentLevel + 1)),
              SizedBox(height: 8.h),
              Text(
                context.l10n.infoDomainLabel(_domainName(item.domain)),
                style: TextStyle(
                  fontSize: 12.sp,
                  fontStyle: FontStyle.italic,
                  color: AppColors.grey600,
                ),
              ),
              if (_consecutiveFailures >= 3) ...[
                SizedBox(height: 8.h),
                Text(
                  context.l10n.infoDiscontinue3,
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

              // Règle de discontinuation : 3 échecs consécutifs (WAIS-IV)
              if (_consecutiveFailures >= 3 ||
                  currentLevel >= _generatedItems.length - 1) {
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
                  ? context.l10n.infoSeeResults
                  : context.l10n.commonContinue,
            ),
          ),
        ],
      ),
    );
  }

  void _showFinalResults() {
    final maxScore = _generatedItems.length; // 28 items × 1 point = 28 max
    final percentageScore = (score / maxScore * 100).round();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          context.l10n.infoResultsTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.l10n.infoRawScore(score, maxScore)),
              Text(context.l10n
                  .infoItemsCompleted(currentLevel + 1, _generatedItems.length)),
              Text(context.l10n.infoPercentage(percentageScore)),
              Text(context.l10n.infoTotalTime(totalTime)),
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
                context.l10n.infoTestSubtitle,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontStyle: FontStyle.italic,
                  color: AppColors.grey600,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                context.l10n.infoDomainBreakdownTitle,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
              SizedBox(height: 8.h),
              ..._buildDomainBreakdown(),
            ],
          ),
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

  List<Widget> _buildDomainBreakdown() {
    final domainScores = <KnowledgeDomain, List<bool>>{};

    for (int i = 0; i < _results.length; i++) {
      final result = _results[i];
      final item = _generatedItems[i];
      domainScores.putIfAbsent(item.domain, () => []);
      domainScores[item.domain]!.add(result.isCorrect);
    }

    return domainScores.entries.map((entry) {
      final correctCount = entry.value.where((isCorrect) => isCorrect).length;
      final total = entry.value.length;
      final domainName = _domainName(entry.key);

      return Padding(
        padding: EdgeInsets.only(bottom: 4.h),
        child: Text(
          context.l10n.infoDomainBreakdownRow(domainName, correctCount, total),
          style: TextStyle(fontSize: 13.sp),
        ),
      );
    }).toList();
  }

  /// Nom localisé du domaine de connaissance.
  String _domainName(KnowledgeDomain domain) {
    switch (domain) {
      case KnowledgeDomain.science:
        return context.l10n.infoDomainScience;
      case KnowledgeDomain.historyGeography:
        return context.l10n.infoDomainHistoryGeography;
      case KnowledgeDomain.generalCulture:
        return context.l10n.infoDomainGeneralCulture;
      case KnowledgeDomain.mathLogic:
        return context.l10n.infoDomainMathLogic;
      case KnowledgeDomain.artsLiterature:
        return context.l10n.infoDomainArtsLiterature;
    }
  }

  /// Nom localisé du niveau de difficulté.
  String _difficultyName(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.easy:
        return context.l10n.infoDifficultyEasy;
      case DifficultyLevel.medium:
        return context.l10n.infoDifficultyMedium;
      case DifficultyLevel.hard:
        return context.l10n.infoDifficultyHard;
    }
  }

  String _getPerformanceLevel(int score) {
    if (score >= 24) return context.l10n.infoPerfExceptional;
    if (score >= 20) return context.l10n.infoPerfSuperior;
    if (score >= 14) return context.l10n.infoPerfAverage;
    if (score >= 8) return context.l10n.infoPerfBelow;
    return context.l10n.infoPerfLow;
  }

  Color _getPerformanceColor(int score) {
    if (score >= 24) return AppColors.indexFSIQ;
    if (score >= 20) return AppColors.success;
    if (score >= 14) return AppColors.info;
    if (score >= 8) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final currentItem = _generatedItems[currentLevel];

    return KeplerTestScaffold(
      testName: context.l10n.infoTestName,
      eyebrow: context.l10n.infoEyebrow,
      accentColor: AppColors.indexVCI,
      currentItem: currentLevel + 1,
      totalItems: _generatedItems.length,
      // Timer + score dans l'AppBar et bouton Valider sticky en bas :
      // question + 4 options + validation visibles sans scroller.
      trailing: [
        Padding(
          padding: EdgeInsets.only(left: 8.w),
          child: Text(
              context.l10n.infoTrailingStatus(
                  _elapsedSeconds, score, currentLevel + 1),
              style: AppText.monoLabel(color: AppColors.indexVCI)),
        ),
      ],
      bottomBar: KeplerTestButton.primary(
        label: context.l10n.commonValidate,
        accentColor: AppColors.indexVCI,
        onPressed: _selectedAnswer != null ? _submitAnswer : null,
      ),
      child: Column(
crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Domaine et difficulté
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: _getDomainColor(currentItem.domain),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        _domainName(currentItem.domain),
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.surface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor(currentItem.difficulty),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      _difficultyName(currentItem.difficulty),
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12.h),

              // Question
              Container(
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.indexVCI.withValues(alpha: 0.1),
                      AppColors.indexVCI.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: AppColors.indexVCI, width: 2),
                ),
                child: Text(
                  currentItem.question,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              SizedBox(height: 14.h),

              // Options (QCM)
              ...List.generate(4, (index) {
                final isSelected = _selectedAnswer == index;
                return Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: InkWell(
                    onTap: () => _selectAnswer(index),
                    borderRadius: BorderRadius.circular(12.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 12.w, vertical: 10.h),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.indexVCI.withValues(alpha: 0.15)
                            : AppColors.grey50,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.indexVCI
                              : AppColors.grey300,
                          width: isSelected ? 3 : 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32.w,
                            height: 32.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? AppColors.indexVCI
                                  : AppColors.grey300,
                            ),
                            child: Center(
                              child: Text(
                                String.fromCharCode(65 + index), // A, B, C, D
                                style: TextStyle(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.surface
                                      : Theme.of(context).colorScheme.outline,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.sp,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              currentItem.options[index],
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? AppColors.indexVCI
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
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


  Color _getDomainColor(KnowledgeDomain domain) {
    switch (domain) {
      case KnowledgeDomain.science:
        return AppColors.success;
      case KnowledgeDomain.historyGeography:
        return AppColors.info;
      case KnowledgeDomain.generalCulture:
        return AppColors.warning;
      case KnowledgeDomain.mathLogic:
        return AppColors.indexFSIQ;
      case KnowledgeDomain.artsLiterature:
        return AppColors.indexPSI;
    }
  }

  Color _getDifficultyColor(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.easy:
        return AppColors.success;
      case DifficultyLevel.medium:
        return AppColors.warning;
      case DifficultyLevel.hard:
        return AppColors.error;
    }
  }
}

// ========== MODÈLE DE RÉSULTAT ==========

class ItemResult {
  final String question;
  final int selectedAnswer;
  final int correctAnswer;
  final bool isCorrect;
  final int timeSeconds;

  ItemResult({
    required this.question,
    required this.selectedAnswer,
    required this.correctAnswer,
    required this.isCorrect,
    required this.timeSeconds,
  });
}
