import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../domain/balance_generator.dart';
import '../widgets/balance_widget.dart';
import '../widgets/token_widget.dart';

/// Page du test des Balances Quantitatives (Figure Weights)
/// WAIS-IV : 27 items, g-loading = 0.78
/// Temps limite : 20s (facile), 30s (moyen), 45s (difficile)
/// Règle de discontinuation : 3 échecs consécutifs
class FigureWeightsTestPage extends StatefulWidget {
  final String? filterLevel;
  const FigureWeightsTestPage({super.key, this.filterLevel});

  @override
  State<FigureWeightsTestPage> createState() => _FigureWeightsTestPageState();
}

class _FigureWeightsTestPageState extends State<FigureWeightsTestPage> {
  int currentLevel = 0;
  int score = 0;
  int totalTime = 0;
  int _consecutiveFailures = 0;
  List<Token>? _selectedAnswer;
  DateTime? _itemStartTime;
  Timer? _countdownTimer;
  int _remainingSeconds = 0;

  late List<BalanceItem> _generatedItems;

  @override
  void initState() {
    super.initState();
    _generateItems();
    _startItem();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _generateItems() {
    // Génération des 27 items UNIQUES en une seule fois
    final generator = BalanceGenerator();
    _generatedItems = generator.generateComplete27Items();
  }

  void _startItem() {
    _itemStartTime = DateTime.now();
    _selectedAnswer = null;
    _remainingSeconds = _generatedItems[currentLevel].timeLimitSeconds;

    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _remainingSeconds--;
      });

      if (_remainingSeconds <= 0) {
        timer.cancel();
        // Temps écoulé = réponse incorrecte
        _submitAnswer();
      }
    });
  }

  void _submitAnswer() {
    _countdownTimer?.cancel();

    final timeSeconds = _itemStartTime != null
        ? DateTime.now().difference(_itemStartTime!).inSeconds
        : 0;

    totalTime += timeSeconds;

    final isCorrect = _selectedAnswer != null &&
        _listsEqual(_selectedAnswer!, _generatedItems[currentLevel].correctAnswer);

    if (isCorrect) {
      score++;
      _consecutiveFailures = 0;
    } else {
      _consecutiveFailures++;
    }

    _showFeedbackDialog(isCorrect, timeSeconds);
  }

  bool _listsEqual(List<Token> a, List<Token> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _showFeedbackDialog(bool isCorrect, int timeSeconds) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          isCorrect ? 'Correct !' : 'Incorrect',
          style: TextStyle(
            color: isCorrect ? AppColors.success : AppColors.error,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isCorrect
                  ? 'Bonne réponse ! +1 point'
                  : 'Mauvaise réponse. La bonne réponse était :',
            ),
            if (!isCorrect) ...[
              SizedBox(height: 8.h),
              _buildTokenList(_generatedItems[currentLevel].correctAnswer),
            ],
            SizedBox(height: 12.h),
            Text('Temps : ${timeSeconds}s'),
            Text('Score : $score/${currentLevel + 1}'),
            if (_consecutiveFailures >= 3) ...[
              SizedBox(height: 8.h),
              Text(
                '3 échecs consécutifs - Test terminé (WAIS-IV)',
                style: TextStyle(
                  color: AppColors.warning,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();

              // Règle de discontinuation : 3 échecs consécutifs (WAIS-IV)
              if (_consecutiveFailures >= 3 || currentLevel >= _generatedItems.length - 1) {
                _showFinalResults();
              } else {
                setState(() {
                  currentLevel++;
                  _startItem();
                });
              }
            },
            child: Text(
              _consecutiveFailures >= 3 || currentLevel >= _generatedItems.length - 1
                  ? 'Voir les résultats'
                  : 'Continuer',
            ),
          ),
        ],
      ),
    );
  }

  void _showFinalResults() {
    final percentageScore = (score / _generatedItems.length * 100).round();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(
          'Test des Balances Quantitatives - Résultats',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Score brut : $score/27 points'),
            Text('Items complétés : ${currentLevel + 1}/27'),
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
              'g-loading : 0.78 (le plus élevé du WAIS-IV)',
              style: TextStyle(
                fontSize: 12.sp,
                fontStyle: FontStyle.italic,
                color: AppColors.grey600,
              ),
            ),
          ],
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

  String _getPerformanceLevel(int score) {
    if (score >= 23) return 'Performance exceptionnelle (θ > +2.0)';
    if (score >= 18) return 'Performance supérieure (θ > +1.0)';
    if (score >= 12) return 'Performance moyenne (θ ≈ 0)';
    if (score >= 7) return 'Performance inférieure (θ < 0)';
    return 'Performance faible (θ < -1.0)';
  }

  Color _getPerformanceColor(int score) {
    if (score >= 23) return AppColors.indexFSIQ;
    if (score >= 18) return AppColors.success;
    if (score >= 12) return AppColors.info;
    if (score >= 7) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final currentItem = _generatedItems[currentLevel];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Balances Quantitatives'),
        actions: [
          Center(
            child: Padding(
              padding: EdgeInsets.only(right: 16.w),
              child: Text(
                'Item ${currentLevel + 1}/27',
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

              SizedBox(height: 16.h),

              // Instructions
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.infoContainer,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: AppColors.infoLight),
                ),
                child: Text(
                  'Trouvez la valeur manquante qui équilibre la balance.',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              SizedBox(height: 20.h),

              // Balances connues (équations) - TOUJOURS montrer les balances de référence
              ...currentItem.balances.map((balance) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 16.h),
                  child: BalanceWidget(
                    balance: balance,
                    showQuestion: false, // Ne jamais modifier la balance de référence
                    questionTokens: null,
                  ),
                );
              }),

              SizedBox(height: 20.h),

              // Question
              if (currentItem.question.targetSide.isNotEmpty) ...[
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppColors.warningContainer,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: AppColors.warningLight, width: 2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Que vaut ',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      _buildTokenList(currentItem.question.targetSide),
                      Text(
                        ' ?',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),
              ],

              // Options de réponse
              Text(
                'Choisissez la réponse :',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12.h),

              ...currentItem.options.asMap().entries.map((entry) {
                final index = entry.key;
                final option = entry.value;
                final isSelected = _selectedAnswer != null &&
                    _listsEqual(_selectedAnswer!, option);

                return Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedAnswer = option;
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.infoContainer
                            : AppColors.grey50,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.info
                              : AppColors.grey300,
                          width: isSelected ? 3 : 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '${String.fromCharCode(65 + index)}. ',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: _buildTokenList(option),
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
                height: 50.h,
                child: ElevatedButton(
                  onPressed: _selectedAnswer != null ? _submitAnswer : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.indexFRI,
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
            color: _remainingSeconds <= 5 ? AppColors.errorContainer : AppColors.infoContainer,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: _remainingSeconds <= 5 ? AppColors.errorLight : AppColors.infoLight,
              width: 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timer,
                size: 20.sp,
                color: _remainingSeconds <= 5 ? AppColors.error : AppColors.info,
              ),
              SizedBox(width: 8.w),
              Text(
                '${_remainingSeconds}s',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: _remainingSeconds <= 5 ? AppColors.error : AppColors.info,
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
                '$score/${currentLevel + 1}',
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

  Widget _buildTokenList(List<Token> tokens) {
    return Wrap(
      spacing: 4.w,
      runSpacing: 4.h,
      alignment: WrapAlignment.center,
      children: tokens.map((token) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TokenWidget(
              token: token,
              size: 28,
            ),
            if (tokens.indexOf(token) < tokens.length - 1)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Text(
                  '+',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        );
      }).toList(),
    );
  }
}
