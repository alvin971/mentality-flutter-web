import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../domain/information_generator.dart';

/// Page du test d'Information (Connaissances générales)
/// WAIS-IV : 28 questions
/// QCM à 4 options
/// Scoring dichotomique : 0 ou 1
/// Règle de discontinuation : 3 échecs consécutifs
class InformationTestPage extends StatefulWidget {
  const InformationTestPage({super.key});

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
    final generator = InformationGenerator();
    _generatedItems = generator.generateComplete28Items();
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
          isCorrect ? 'Correct !' : 'Incorrect',
          style: TextStyle(
            color: isCorrect ? Colors.green : Colors.red,
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
                    ? 'Bonne réponse ! +1 point'
                    : 'Mauvaise réponse. 0 point',
              ),
              SizedBox(height: 12.h),
              Text(
                'Question : ${item.question}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.h),
              if (!isCorrect) ...[
                Text(
                  'Bonne réponse : ${item.options[item.correctAnswer]}',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
              ],
              Text('Temps : ${timeSeconds}s'),
              Text('Score : $score/${currentLevel + 1}'),
              SizedBox(height: 8.h),
              Text(
                'Domaine : ${item.domainName}',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade600,
                ),
              ),
              if (_consecutiveFailures >= 3) ...[
                SizedBox(height: 8.h),
                Text(
                  '3 échecs consécutifs - Test terminé (WAIS-IV)',
                  style: TextStyle(
                    color: Colors.orange,
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
                  ? 'Voir les résultats'
                  : 'Continuer',
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
        title: const Text(
          'Test d\'Information - Résultats',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Score brut : $score/$maxScore points'),
              Text('Items complétés : ${currentLevel + 1}/28'),
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
                'Test de connaissances générales acquises',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Répartition par domaine :',
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
            child: const Text('Retour'),
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
      final domainName = _generatedItems
          .firstWhere((item) => item.domain == entry.key)
          .domainName;

      return Padding(
        padding: EdgeInsets.only(bottom: 4.h),
        child: Text(
          '$domainName: $correctCount/$total',
          style: TextStyle(fontSize: 13.sp),
        ),
      );
    }).toList();
  }

  String _getPerformanceLevel(int score) {
    if (score >= 24) return 'Performance exceptionnelle (θ > +2.0)';
    if (score >= 20) return 'Performance supérieure (θ > +1.0)';
    if (score >= 14) return 'Performance moyenne (θ ≈ 0)';
    if (score >= 8) return 'Performance inférieure (θ < 0)';
    return 'Performance faible (θ < -1.0)';
  }

  Color _getPerformanceColor(int score) {
    if (score >= 24) return Colors.purple;
    if (score >= 20) return Colors.green;
    if (score >= 14) return Colors.blue;
    if (score >= 8) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final currentItem = _generatedItems[currentLevel];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Information'),
        backgroundColor: AppColors.indexVCI,
        actions: [
          Center(
            child: Padding(
              padding: EdgeInsets.only(right: 16.w),
              child: Text(
                'Item ${currentLevel + 1}/28',
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
                        currentItem.domainName,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
                      currentItem.difficultyName,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 24.h),

              // Question
              Container(
                padding: EdgeInsets.all(20.w),
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
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              SizedBox(height: 28.h),

              // Options (QCM)
              ...List.generate(4, (index) {
                final isSelected = _selectedAnswer == index;
                return Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: InkWell(
                    onTap: () => _selectAnswer(index),
                    borderRadius: BorderRadius.circular(12.r),
                    child: Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.indexVCI.withValues(alpha: 0.15)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.indexVCI
                              : Colors.grey.shade300,
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
                                  : Colors.grey.shade300,
                            ),
                            child: Center(
                              child: Text(
                                String.fromCharCode(65 + index), // A, B, C, D
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black54,
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
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              SizedBox(height: 24.h),

              // Bouton Valider
              SizedBox(
                width: double.infinity,
                height: 54.h,
                child: ElevatedButton(
                  onPressed: _selectedAnswer != null ? _submitAnswer : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.indexVCI,
                    disabledBackgroundColor: Colors.grey.shade300,
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
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: Colors.blue.shade300, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timer_outlined,
                size: 22.sp,
                color: Colors.blue.shade700,
              ),
              SizedBox(width: 8.w),
              Text(
                '${_elapsedSeconds}s',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
        ),

        // Score
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: Colors.green.shade300, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.stars_rounded,
                size: 22.sp,
                color: Colors.amber.shade700,
              ),
              SizedBox(width: 8.w),
              Text(
                '$score/${currentLevel + 1}',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getDomainColor(KnowledgeDomain domain) {
    switch (domain) {
      case KnowledgeDomain.science:
        return Colors.green;
      case KnowledgeDomain.historyGeography:
        return Colors.blue;
      case KnowledgeDomain.generalCulture:
        return Colors.orange;
      case KnowledgeDomain.mathLogic:
        return Colors.purple;
      case KnowledgeDomain.artsLiterature:
        return Colors.pink;
    }
  }

  Color _getDifficultyColor(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.easy:
        return Colors.green.shade600;
      case DifficultyLevel.medium:
        return Colors.orange.shade600;
      case DifficultyLevel.hard:
        return Colors.red.shade600;
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
