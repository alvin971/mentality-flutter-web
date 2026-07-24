import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';
import '../../../../../core/l10n/l10n_ext.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/test/kepler_test_button.dart';
import '../../../../../core/widgets/test/kepler_test_scaffold.dart';
import '../../domain/coding_generator.dart';

/// Page du test Code (Coding / Digit Symbol)
/// 135 cases à compléter en 120 secondes avec palette de symboles
class CodingTestPage extends StatefulWidget {
  final String? filterLevel;
  const CodingTestPage({super.key, this.filterLevel});

  @override
  State<CodingTestPage> createState() => _CodingTestPageState();
}

class _CodingTestPageState extends State<CodingTestPage> {
  final CodingGenerator _generator = CodingGenerator();
  late List<int> _digitSequence;
  late Map<int, String> _referenceKey;
  late List<String> _symbolPalette;

  // Réponses utilisateur (135 cases)
  final List<String?> _userAnswers = List.filled(135, null);

  // Phase du test
  TestPhase _currentPhase = TestPhase.intro;
  bool _isTraining = false;

  // Timer
  Timer? _countdownTimer;
  int _remainingSeconds = 120;
  int _elapsedSeconds = 0;

  // Index de la case actuellement sélectionnée
  int _selectedCellIndex = 0;

  // Scroll controller pour suivre la progression
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _digitSequence = _generator.getDigitSequence();
    _referenceKey = _generator.getReferenceKey();
    _symbolPalette = _generator.getAllSymbols();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _startTraining() {
    setState(() {
      _isTraining = true;
      _currentPhase = TestPhase.testing;
      _selectedCellIndex = 0;
    });
  }

  void _startTest() {
    setState(() {
      _isTraining = false;
      _currentPhase = TestPhase.testing;
      _remainingSeconds = 120;
      _elapsedSeconds = 0;
      _selectedCellIndex = 0;
      _userAnswers.fillRange(0, 135, null);
    });

    // Démarrer le chronomètre
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds--;
        _elapsedSeconds++;
      });

      if (_remainingSeconds <= 0) {
        timer.cancel();
        _finishTest();
      }
    });
  }

  void _selectSymbol(String symbol) {
    if (_isTraining) {
      // Mode entraînement : seulement les 7 premières cases
      if (_selectedCellIndex < 7) {
        setState(() {
          _userAnswers[_selectedCellIndex] = symbol;
          if (_selectedCellIndex < 6) {
            _selectedCellIndex++;
            _scrollToCurrentCell();
          }
        });
      }
    } else {
      // Mode test : toutes les 135 cases
      if (_selectedCellIndex < 135) {
        setState(() {
          _userAnswers[_selectedCellIndex] = symbol;
          if (_selectedCellIndex < 134) {
            _selectedCellIndex++;
            _scrollToCurrentCell();
          }
        });
      }
    }
  }

  void _scrollToCurrentCell() {
    // Auto-scroll pour suivre la progression
    final cellWidth = 50.w + 8.w; // largeur + espacement
    final targetPosition = _selectedCellIndex * cellWidth;
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        targetPosition,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    }
  }

  void _selectCell(int index) {
    if (_isTraining && index >= 7) return;
    if (!_isTraining && index >= 135) return;

    setState(() {
      _selectedCellIndex = index;
    });
  }

  void _clearCurrentCell() {
    setState(() {
      _userAnswers[_selectedCellIndex] = null;
    });
  }

  void _finishTraining() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.codingTrainingDoneTitle),
        content: Text(context.l10n.codingTrainingDoneBody),
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

    // Test non noté à l'écran : aucun récapitulatif de points/temps/réussite,
    // simple confirmation de fin — le score repart vers l'appelant, sans être montré.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.codingTestDoneTitle),
        actions: [
          TextButton(
            onPressed: () {
              final score = _generator.calculateScore(_userAnswers);
              Navigator.pop(context);
              Navigator.pop(context, score);
            },
            child: Text(context.l10n.commonBack),
          ),
        ],
      ),
    );
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
      testName: context.l10n.codingTestName,
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
                Icons.grid_on,
                size: 80.sp,
                color: AppColors.indexPSI,
              ),
              SizedBox(height: 24.h),
              Text(
                context.l10n.codingTitle,
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.indexPSI,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                context.l10n.codingDescription,
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
                      context.l10n.codingReferenceKey,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.indexPSI,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    _buildReferenceKey(),
                  ],
                ),
              ),
              SizedBox(height: 24.h),
              _buildInfoCard(
                context.l10n.codingTaskTitle,
                context.l10n.codingTaskDesc,
                Icons.task_outlined,
              ),
              SizedBox(height: 12.h),
              _buildInfoCard(
                context.l10n.codingTimeLimitTitle,
                context.l10n.codingTimeLimitDesc,
                Icons.timer_outlined,
              ),
              SizedBox(height: 12.h),
              _buildInfoCard(
                context.l10n.codingScoringTitle,
                context.l10n.codingScoringDesc,
                Icons.stars_outlined,
              ),
            ],
      ),
    );
  }

  Widget _buildTestScreen() {
    final maxCells = _isTraining ? 7 : 135;
    final displaySequence = _isTraining
        ? _generator.getTrainingSequence()
        : _digitSequence;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_isTraining ? context.l10n.codingTrainingTab : context.l10n.codingTitle),
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
            // Clé de référence (toujours visible)
            Container(
              padding: EdgeInsets.all(12.w),
              color: AppColors.indexPSI.withValues(alpha: 0.1),
              child: Column(
                children: [
                  Text(
                    context.l10n.codingReferenceShort,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.indexPSI,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  _buildReferenceKey(),
                ],
              ),
            ),
            SizedBox(height: 8.h),

            // Progression
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.l10n.codingCellProgress(_selectedCellIndex + 1, maxCells),
                    style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    context.l10n.codingCompletedProgress(
                      _userAnswers.take(maxCells).where((a) => a != null).length,
                      maxCells,
                    ),
                    style: TextStyle(fontSize: 14.sp, color: AppColors.grey600),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),

            // Grille de cases
            SizedBox(
              height: 100.h,
              child: ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                itemCount: maxCells,
                itemBuilder: (context, index) {
                  final digit = displaySequence[index];
                  final isSelected = index == _selectedCellIndex;
                  final userAnswer = _userAnswers[index];

                  return GestureDetector(
                    onTap: () => _selectCell(index),
                    child: Container(
                      width: 50.w,
                      margin: EdgeInsets.only(right: 8.w),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.indexPSI.withValues(alpha: 0.2)
                            : AppColors.grey100,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: isSelected ? AppColors.indexPSI : AppColors.grey300,
                          width: isSelected ? 3 : 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            digit.toString(),
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.indexPSI,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            userAnswer ?? '_',
                            style: TextStyle(
                              fontSize: 24.sp,
                              fontWeight: FontWeight.bold,
                              color: userAnswer != null ? Colors.black : AppColors.grey400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const Spacer(),

            // Palette de symboles
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.grey50,
                border: Border(top: BorderSide(color: AppColors.grey300, width: 2)),
              ),
              child: Column(
                children: [
                  Text(
                    context.l10n.codingSelectSymbol,
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12.h),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      crossAxisSpacing: 8.w,
                      mainAxisSpacing: 8.h,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: _symbolPalette.length,
                    itemBuilder: (context, index) {
                      final symbol = _symbolPalette[index];
                      return ElevatedButton(
                        onPressed: () => _selectSymbol(symbol),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.indexPSI,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        child: Text(
                          symbol,
                          style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _clearCurrentCell,
                          icon: Icon(Icons.backspace, size: 20.sp),
                          label: Text(context.l10n.codingClear),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: BorderSide(color: AppColors.error, width: 2),
                          ),
                        ),
                      ),
                      if (_isTraining) ...[
                        SizedBox(width: 12.w),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _finishTraining,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.indexPSI,
                            ),
                            child: Text(context.l10n.codingFinishTraining),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReferenceKey() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(9, (index) {
        final digit = index + 1;
        final symbol = _referenceKey[digit]!;
        return Column(
          children: [
            Text(
              digit.toString(),
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.indexPSI,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              symbol,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      }),
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
