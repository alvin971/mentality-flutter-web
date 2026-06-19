import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/l10n/l10n_ext.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/test/kepler_test_button.dart';
import '../../../../../core/widgets/test/kepler_test_scaffold.dart';
import '../../domain/matrix_generator.dart';
import '../widgets/matrix_cell_widget.dart';

/// Page de test des Matrices Progressives (WAIS-IV: 26 items, WISC-V: 32 items)
class MatricesTestPage extends StatefulWidget {
  final String? filterLevel;
  const MatricesTestPage({super.key, this.filterLevel});

  @override
  State<MatricesTestPage> createState() => _MatricesTestPageState();
}

class _MatricesTestPageState extends State<MatricesTestPage> {
  int currentLevel = 0;
  int score = 0;
  int totalTime = 0;
  int _consecutiveFailures = 0;
  MatrixCell? _selectedAnswer;
  DateTime? _itemStartTime;

  late List<MatrixItem> _generatedItems;

  @override
  void initState() {
    super.initState();
    _generateItems();
    _itemStartTime = DateTime.now();
  }

  void _generateItems() {
    // Génération des 26 items UNIQUES en une seule fois
    final generator = MatrixGenerator();
    final all = generator.generateComplete26Items();
    final level = widget.filterLevel;
    if (level != null) {
      final filtered = all.where((item) => item.difficulty.name == level).toList();
      _generatedItems = filtered.isNotEmpty ? filtered : all;
    } else {
      _generatedItems = all;
    }
  }

  void _handleAnswerSelected(MatrixCell answer) {
    setState(() {
      _selectedAnswer = answer;
    });
  }

  void _handleSubmit() {
    if (_selectedAnswer == null) return;

    final isCorrect = _selectedAnswer == _generatedItems[currentLevel].correctAnswer;
    final timeSeconds = DateTime.now().difference(_itemStartTime!).inSeconds;

    setState(() {
      totalTime += timeSeconds;

      if (isCorrect) {
        score++;
        _consecutiveFailures = 0;
      } else {
        _consecutiveFailures++;
      }
    });

    _showFeedbackDialog(isCorrect, timeSeconds);
  }

  void _showFeedbackDialog(bool isCorrect, int timeSeconds) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isCorrect ? Icons.check_circle : Icons.cancel,
              color: isCorrect ? AppColors.success : AppColors.error,
              size: 32.sp,
            ),
            SizedBox(width: 12.w),
            Text(
              isCorrect ? context.l10n.matCorrect : context.l10n.matIncorrect,
              style: TextStyle(
                color: isCorrect ? AppColors.success : AppColors.error,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.matResponseTime(timeSeconds)),
            SizedBox(height: 8.h),
            Text(context.l10n.matScoreFraction(score, currentLevel + 1)),
            if (_consecutiveFailures >= 3) ...[
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  context.l10n.matDiscontinue3,
                  style: TextStyle(
                    color: AppColors.warning,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);

              // Règle de discontinuation WAIS-IV : 3 scores 0 consécutifs
              if (_consecutiveFailures >= 3 || currentLevel >= _generatedItems.length - 1) {
                _showFinalResults();
              } else {
                setState(() {
                  currentLevel++;
                  _selectedAnswer = null;
                  _itemStartTime = DateTime.now();
                });
              }
            },
            child: Text(
              _consecutiveFailures >= 3
                  ? context.l10n.matSeeResultsEnded
                  : (currentLevel < _generatedItems.length - 1
                      ? context.l10n.matNextItem
                      : context.l10n.matSeeResults),
            ),
          ),
        ],
      ),
    );
  }

  void _showFinalResults() {
    final completedItems = currentLevel + 1;
    final avgTime = completedItems > 0 ? totalTime ~/ completedItems : 0;
    final percentageCorrect = (score / completedItems * 100).round();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.matFinishedTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _resultRow(context.l10n.matRawScore, '$score/$completedItems'),
            _resultRow(context.l10n.matSuccessRate, '$percentageCorrect%'),
            _resultRow(context.l10n.matAvgTimePerItem, '${avgTime}s'),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.matEvaluation,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    _getPerformanceLevel(context, percentageCorrect),
                    style: TextStyle(fontSize: 13.sp),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, score); // Retourne le score final
            },
            child: Text(context.l10n.commonFinish),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                currentLevel = 0;
                score = 0;
                totalTime = 0;
                _consecutiveFailures = 0;
                _selectedAnswer = null;
                _generateItems(); // Régénérer de nouveaux items
                _itemStartTime = DateTime.now();
              });
            },
            child: Text(context.l10n.matRestart),
          ),
        ],
      ),
    );
  }

  Widget _resultRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _getPerformanceLevel(BuildContext context, int percentage) {
    final l10n = context.l10n;
    if (percentage >= 90) return l10n.matPerfExcellent;
    if (percentage >= 75) return l10n.matPerfVeryGood;
    if (percentage >= 60) return l10n.matPerfGood;
    if (percentage >= 40) return l10n.matPerfAverage;
    return l10n.matPerfBelowAverage;
  }

  @override
  Widget build(BuildContext context) {
    final item = _generatedItems[currentLevel];

    return KeplerTestScaffold(
      testName: context.l10n.matTestName,
      eyebrow: context.l10n.matEyebrow,
      accentColor: AppColors.indexFSIQ,
      currentItem: currentLevel + 1,
      totalItems: _generatedItems.length,
      // Tout tient à l'écran : matrice redimensionnée à la hauteur disponible,
      // bouton Valider sticky en bas (jamais besoin de scroller).
      scrollable: false,
      trailing: [
        Padding(
          padding: EdgeInsets.only(left: 8.w),
          child: Text(context.l10n.matPoints(score),
              style: AppText.monoLabel(color: AppColors.indexFSIQ)),
        ),
      ],
      bottomBar: KeplerTestButton.primary(
        label: context.l10n.matValidateAnswer,
        accentColor: AppColors.indexFSIQ,
        onPressed: _selectedAnswer == null ? null : _handleSubmit,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Infos item (difficulté) — version compacte
          _buildLevelHeader(context, item),
          SizedBox(height: 8.h),

          // Consigne
          _buildInstructions(context),

          // Matrice — occupe l'espace restant, réduite si nécessaire
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10.h),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: _buildMatrix(item),
              ),
            ),
          ),

          // Options de réponse — une seule ligne adaptée à la largeur
          _buildOptions(context, item),
          SizedBox(height: 4.h),
        ],
      ),
    );
  }

  // Version compacte : la progression d'items est déjà affichée par le
  // scaffold (KeplerProgress) — on ne garde ici que la difficulté et les
  // métadonnées de l'item, sur une seule ligne.
  Widget _buildLevelHeader(BuildContext context, MatrixItem item) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Text(
            _getDifficultyLabel(context, item.difficulty),
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            context.l10n.matRulesTheta(
                item.rules.length, item.thetaValue.toStringAsFixed(1)),
            style: TextStyle(
              fontSize: 11.sp,
              color: AppColors.grey600,
              fontStyle: FontStyle.italic,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildInstructions(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.info, size: 18.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              context.l10n.matInstruction,
              style: TextStyle(fontSize: 12.sp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatrix(MatrixItem item) {
    final cellSize = item.gridSize == 2 ? 90.0 : 70.0;

    return Center(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4.r),
          border: Border.all(color: AppColors.grey800, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(4, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(item.gridSize, (row) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(item.gridSize, (col) {
                  return MatrixCellWidget(
                    cell: item.matrix[row][col],
                    size: cellSize,
                  );
                }),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildOptions(BuildContext context, MatrixItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.matChooseAnswer,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8.h),
        // Une seule ligne : la taille des options s'adapte à la largeur de
        // l'écran (jamais de retour à la ligne ni de scroll horizontal).
        LayoutBuilder(
          builder: (context, constraints) {
            final n = item.options.length;
            const gap = 8.0;
            final cellSize =
                ((constraints.maxWidth - gap * (n - 1)) / n).clamp(36.0, 70.0);
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < n; i++) ...[
                  if (i > 0) const SizedBox(width: gap),
                  MatrixCellWidget(
                    cell: item.options[i],
                    size: cellSize,
                    isOption: true,
                    isSelected: _selectedAnswer == item.options[i],
                    onTap: () => _handleAnswerSelected(item.options[i]),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  String _getDifficultyLabel(BuildContext context, DifficultyLevel difficulty) {
    final l10n = context.l10n;
    switch (difficulty) {
      case DifficultyLevel.veryEasy:
        return l10n.matDiffEasy;
      case DifficultyLevel.easy:
        return l10n.matDiffMediumEasy;
      case DifficultyLevel.medium:
        return l10n.matDiffMedium;
      case DifficultyLevel.mediumHard:
        return l10n.matDiffMediumHard;
      case DifficultyLevel.hard:
        return l10n.matDiffHard;
    }
  }
}
