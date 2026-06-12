import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';
import '../../../../../core/l10n/l10n_ext.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/test/kepler_test_button.dart';
import '../../../../../core/widgets/test/kepler_test_scaffold.dart';
import '../../domain/symbol_search_generator.dart';

/// Page du test Recherche de Symboles (Symbol Search)
/// 60 items en 120 secondes avec réponse OUI/NON
class SymbolSearchTestPage extends StatefulWidget {
  final String? filterLevel;
  const SymbolSearchTestPage({super.key, this.filterLevel});

  @override
  State<SymbolSearchTestPage> createState() => _SymbolSearchTestPageState();
}

class _SymbolSearchTestPageState extends State<SymbolSearchTestPage> {
  final SymbolSearchGenerator _generator = SymbolSearchGenerator();
  late List<SymbolSearchItem> _testItems;
  late List<SymbolSearchItem> _trainingItems;

  // Réponses utilisateur (60 items)
  final List<bool?> _userAnswers = List.filled(60, null);

  // Phase du test
  TestPhase _currentPhase = TestPhase.intro;
  bool _isTraining = false;

  // Timer
  Timer? _countdownTimer;
  int _remainingSeconds = 120;

  // Index de l'item actuel
  int _currentItemIndex = 0;

  @override
  void initState() {
    super.initState();
    _testItems = _generator.getAllItems();
    _trainingItems = _generator.getTrainingItems();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  SymbolSearchItem get _currentItem {
    if (_isTraining) {
      return _trainingItems[_currentItemIndex];
    } else {
      return _testItems[_currentItemIndex];
    }
  }

  void _startTraining() {
    setState(() {
      _isTraining = true;
      _currentPhase = TestPhase.testing;
      _currentItemIndex = 0;
    });
  }

  void _startTest() {
    setState(() {
      _isTraining = false;
      _currentPhase = TestPhase.testing;
      _remainingSeconds = 120;
      _currentItemIndex = 0;
      _userAnswers.fillRange(0, 60, null);
    });

    // Démarrer le chronomètre
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds--;
      });

      if (_remainingSeconds <= 0) {
        timer.cancel();
        _finishTest();
      }
    });
  }

  void _answerYes() {
    _submitAnswer(true);
  }

  void _answerNo() {
    _submitAnswer(false);
  }

  void _submitAnswer(bool answer) {
    if (_isTraining) {
      // Mode entraînement
      if (_currentItemIndex < _trainingItems.length) {
        if (_currentItemIndex < _trainingItems.length - 1) {
          setState(() {
            _currentItemIndex++;
          });
        } else {
          _finishTraining();
        }
      }
    } else {
      // Mode test
      setState(() {
        _userAnswers[_currentItemIndex] = answer;
      });

      if (_currentItemIndex < _testItems.length - 1) {
        setState(() {
          _currentItemIndex++;
        });
      } else {
        _finishTest();
      }
    }
  }

  void _finishTraining() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.codingTrainingDoneTitle),
        content: Text(context.l10n.ssTrainingDoneBody),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startTest();
            },
            child: Text(context.l10n.codingStartTest),
          ),
        ],
      ),
    );
  }

  void _finishTest() {
    _countdownTimer?.cancel();

    final score = _generator.calculateScore(_userAnswers);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.codingTestDoneTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.ssItemsAnswered(score.totalAnswered), style: TextStyle(fontSize: 16.sp)),
            SizedBox(height: 8.h),
            Text(context.l10n.ssCorrectAnswers(score.correct)),
            Text(context.l10n.ssIncorrectAnswers(score.incorrect), style: TextStyle(color: AppColors.error)),
            Text(context.l10n.ssNotAnswered(score.notAnswered), style: TextStyle(color: AppColors.grey600)),
            SizedBox(height: 16.h),
            Text(
              context.l10n.ssRawScore(score.rawScore),
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.indexPSI,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              context.l10n.ssScoreFormulaShort,
              style: TextStyle(fontSize: 12.sp, color: AppColors.grey600),
            ),
            SizedBox(height: 12.h),
            Text(
              _getPerformanceMessage(context, score.rawScore),
              style: TextStyle(fontSize: 14.sp, color: AppColors.grey700),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, score.rawScore);
            },
            child: Text(context.l10n.commonBack),
          ),
        ],
      ),
    );
  }

  String _getPerformanceMessage(BuildContext context, int score) {
    if (score >= 58) return context.l10n.codingPerfExceptional;
    if (score >= 50) return context.l10n.codingPerfVeryGood;
    if (score >= 40) return context.l10n.ssPerfGood;
    if (score >= 30) return context.l10n.codingPerfAverage;
    return context.l10n.codingPerfBelowAverage;
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentPhase) {
      case TestPhase.intro:
        return _buildIntroScreen();
      case TestPhase.testing:
        return _buildTestScreen();
    }
  }

  Widget _buildIntroScreen() {
    return KeplerTestScaffold(
      testName: context.l10n.ssTestName,
      eyebrow: context.l10n.codingEyebrow,
      accentColor: AppColors.indexPSI,
      // Bouton de démarrage sticky : visible sans scroller.
      bottomBar: KeplerTestButton.primary(
        label: context.l10n.codingStartTraining,
        accentColor: AppColors.indexPSI,
        onPressed: _startTraining,
      ),
      child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.search,
                size: 80.sp,
                color: AppColors.indexPSI,
              ),
              SizedBox(height: 24.h),
              Text(
                context.l10n.ssTestName,
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.indexPSI,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                context.l10n.ssDescription,
                style: TextStyle(fontSize: 16.sp),
              ),
              SizedBox(height: 24.h),
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppColors.indexPSI.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.indexPSI, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.ssExampleLabel,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.indexPSI,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        // Cibles
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: AppColors.grey100,
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(color: AppColors.indexPSI, width: 2),
                          ),
                          child: Column(
                            children: [
                              Text(context.l10n.ssTargets, style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold)),
                              SizedBox(height: 8.h),
                              Row(
                                children: [
                                  Text('┴', style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold)),
                                  SizedBox(width: 8.w),
                                  Text('∨', style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Icon(Icons.arrow_forward, size: 24.sp, color: AppColors.indexPSI),
                        SizedBox(width: 12.w),
                        // Groupe de recherche
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: AppColors.grey100,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Column(
                              children: [
                                Text(context.l10n.ssGroup, style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold)),
                                SizedBox(height: 8.h),
                                Wrap(
                                  spacing: 8.w,
                                  children: ['○', '┴', '─', '×', '∪']
                                      .map((s) => Text(s, style: TextStyle(fontSize: 20.sp)))
                                      .toList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      context.l10n.ssExampleAnswer,
                      style: TextStyle(fontSize: 14.sp, color: AppColors.success, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),
              _buildInfoCard(
                context.l10n.ssTaskTitle,
                context.l10n.ssTaskDesc,
                Icons.visibility_outlined,
              ),
              SizedBox(height: 12.h),
              _buildInfoCard(
                context.l10n.ssQuickAnswerTitle,
                context.l10n.ssQuickAnswerDesc,
                Icons.touch_app_outlined,
              ),
              SizedBox(height: 12.h),
              _buildInfoCard(
                context.l10n.ssScoringPenaltyTitle,
                context.l10n.ssScoringPenaltyDesc,
                Icons.calculate_outlined,
              ),
              SizedBox(height: 12.h),
              _buildInfoCard(
                context.l10n.ssTimeLimitTitle,
                context.l10n.ssTimeLimitDesc,
                Icons.timer_outlined,
              ),
            ],
      ),
    );
  }

  Widget _buildTestScreen() {
    final maxItems = _isTraining ? _trainingItems.length : _testItems.length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_isTraining ? context.l10n.codingTrainingTab : context.l10n.ssTestName),
        actions: [
          if (!_isTraining)
            Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16.w),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: _remainingSeconds <= 10
                        ? AppColors.errorContainer
                        : AppColors.grey200,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.timer, size: 20.sp, color: _remainingSeconds <= 10 ? AppColors.error : Theme.of(context).colorScheme.onSurface),
                      SizedBox(width: 4.w),
                      Text(
                        context.l10n.commonSeconds(_remainingSeconds),
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: _remainingSeconds <= 10 ? AppColors.error : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progression
            Container(
              padding: EdgeInsets.all(16.w),
              color: AppColors.indexPSI.withValues(alpha: 0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.l10n.ssItemProgress(_currentItemIndex + 1, maxItems),
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                  ),
                  if (!_isTraining)
                    Text(
                      context.l10n.ssAnsweredProgress(_userAnswers.where((a) => a != null).length),
                      style: TextStyle(fontSize: 14.sp, color: AppColors.grey600),
                    ),
                ],
              ),
            ),

            const Spacer(),

            // Zone des symboles cibles
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                children: [
                  Text(
                    context.l10n.ssTargetSymbols,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.indexPSI,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: AppColors.indexPSI.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: AppColors.indexPSI, width: 3),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _currentItem.targetSymbols.map((symbol) {
                        return Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: Text(
                            symbol,
                            style: TextStyle(
                              fontSize: 48.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.indexPSI,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 32.h),

            // Flèche
            Icon(
              Icons.arrow_downward,
              size: 32.sp,
              color: AppColors.indexPSI,
            ),

            SizedBox(height: 32.h),

            // Groupe de recherche
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                children: [
                  Text(
                    context.l10n.ssSearchGroup,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.grey700,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: AppColors.grey400, width: 2),
                    ),
                    child: Wrap(
                      spacing: 16.w,
                      alignment: WrapAlignment.center,
                      children: _currentItem.searchGroup.map((symbol) {
                        return Text(
                          symbol,
                          style: TextStyle(
                            fontSize: 40.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Boutons OUI/NON
            Padding(
              padding: EdgeInsets.all(24.w),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 70.h,
                      child: ElevatedButton(
                        onPressed: _answerNo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Text(
                          context.l10n.ssNo,
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: SizedBox(
                      height: 70.h,
                      child: ElevatedButton(
                        onPressed: _answerYes,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Text(
                          context.l10n.ssYes,
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String subtitle, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.indexPSI.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.indexPSI.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 28.sp, color: AppColors.indexPSI),
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
                    color: AppColors.indexPSI,
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
}

enum TestPhase {
  intro,
  testing,
}
