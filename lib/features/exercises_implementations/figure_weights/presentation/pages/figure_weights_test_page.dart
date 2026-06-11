import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/test/kepler_test_button.dart';
import '../../../../../core/widgets/test/kepler_test_scaffold.dart';
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

    return KeplerTestScaffold(
      testName: 'Balances Quantitatives',
      eyebrow: 'RAISONNEMENT FLUIDE · FRI',
      accentColor: AppColors.indexFRI,
      currentItem: currentLevel + 1,
      totalItems: _generatedItems.length,
      // Timer + score dans l'AppBar (gain de hauteur) et bouton Valider
      // sticky en bas : plus jamais besoin de scroller pour valider.
      trailing: [
        Padding(
          padding: EdgeInsets.only(left: 8.w),
          child: _buildTimerBadge(),
        ),
        Padding(
          padding: EdgeInsets.only(left: 6.w),
          child: Text('$score/${currentLevel + 1}',
              style: AppText.monoLabel(color: AppColors.indexFRI)),
        ),
      ],
      bottomBar: KeplerTestButton.primary(
        label: 'Valider',
        accentColor: AppColors.indexFRI,
        onPressed: _selectedAnswer != null ? _submitAnswer : null,
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
                  'Trouvez la valeur manquante qui équilibre la balance.',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              SizedBox(height: 10.h),

              // Balances connues (équations) - TOUJOURS montrer les balances de référence
              ...currentItem.balances.map((balance) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 10.h),
                  child: BalanceWidget(
                    balance: balance,
                    showQuestion: false, // Ne jamais modifier la balance de référence
                    questionTokens: null,
                  ),
                );
              }),

              SizedBox(height: 6.h),

              // Question
              if (currentItem.question.targetSide.isNotEmpty) ...[
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
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
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Flexible(
                        child: _buildTokenList(currentItem.question.targetSide),
                      ),
                      Text(
                        ' ?',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10.h),
              ],

              // Options de réponse
              Text(
                'Choisissez la réponse :',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.h),

              ...currentItem.options.asMap().entries.map((entry) {
                final index = entry.key;
                final option = entry.value;
                final isSelected = _selectedAnswer != null &&
                    _listsEqual(_selectedAnswer!, option);

                return Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedAnswer = option;
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 12.w, vertical: 8.h),
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
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: _buildTokenList(option),
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

  Widget _buildTimerBadge() {
    final danger = _remainingSeconds <= 5;
    final color = danger ? AppColors.error : AppColors.info;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 14.sp, color: color),
          SizedBox(width: 4.w),
          Text(
            '${_remainingSeconds}s',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
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
