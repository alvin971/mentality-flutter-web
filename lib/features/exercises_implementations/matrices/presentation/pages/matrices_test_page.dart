import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../domain/matrix_generator.dart';
import '../widgets/matrix_cell_widget.dart';

/// Page de test des Matrices Progressives (WAIS-IV: 26 items, WISC-V: 32 items)
class MatricesTestPage extends StatefulWidget {
  const MatricesTestPage({super.key});

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
    _generatedItems = generator.generateComplete26Items();
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
              isCorrect ? 'Correct !' : 'Incorrect',
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
            Text('Temps de réponse : ${timeSeconds}s'),
            SizedBox(height: 8.h),
            Text('Score : $score/${currentLevel + 1}'),
            if (_consecutiveFailures >= 4) ...[
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  '4 échecs consécutifs - Test terminé (WAIS-IV)',
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

              // Règle de discontinuation : 4 échecs consécutifs (WAIS-IV)
              if (_consecutiveFailures >= 4 || currentLevel >= _generatedItems.length - 1) {
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
              _consecutiveFailures >= 4
                  ? 'Voir résultats (test terminé)'
                  : (currentLevel < _generatedItems.length - 1 ? 'Item suivant' : 'Voir résultats'),
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
        title: const Text('Test des Matrices terminé !'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _resultRow('Score brut', '$score/$completedItems'),
            _resultRow('Taux de réussite', '$percentageCorrect%'),
            _resultRow('Temps moyen/item', '${avgTime}s'),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Évaluation :',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    _getPerformanceLevel(percentageCorrect),
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
            child: const Text('Terminer'),
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
            child: const Text('Recommencer'),
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

  String _getPerformanceLevel(int percentage) {
    if (percentage >= 90) return 'Excellent ! Raisonnement fluide très supérieur.';
    if (percentage >= 75) return 'Très bien ! Bonnes capacités d\'analyse logique.';
    if (percentage >= 60) return 'Bien. Capacités moyennes à bonnes.';
    if (percentage >= 40) return 'Moyen. Des améliorations sont possibles.';
    return 'Résultats en-dessous de la moyenne. Entraînement recommandé.';
  }

  @override
  Widget build(BuildContext context) {
    final item = _generatedItems[currentLevel];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test des Matrices'),
        actions: [
          Center(
            child: Padding(
              padding: EdgeInsets.only(right: 16.w),
              child: Text(
                'Score: $score',
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
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header avec progression
              _buildLevelHeader(item),
              SizedBox(height: 24.h),

              // Consigne
              _buildInstructions(),
              SizedBox(height: 24.h),

              // Matrice
              _buildMatrix(item),
              SizedBox(height: 32.h),

              // Options de réponse
              _buildOptions(item),
              SizedBox(height: 24.h),

              // Bouton de validation
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelHeader(MatrixItem item) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Item ${currentLevel + 1}/${_generatedItems.length}',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  _getDifficultyLabel(item.difficulty),
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            'Règles : ${item.rules.length} | θ = ${item.thetaValue.toStringAsFixed(1)}',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.white.withOpacity(0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(height: 12.h),
          // Barre de progression
          ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: LinearProgressIndicator(
              value: (currentLevel + 1) / _generatedItems.length,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8.h,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.info.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.info, size: 24.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'Trouvez la pièce manquante qui complète logiquement la matrice',
              style: TextStyle(fontSize: 13.sp),
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
              color: Colors.black.withOpacity(0.2),
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

  Widget _buildOptions(MatrixItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choisissez la réponse :',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12.h),
        Wrap(
          spacing: 12.w,
          runSpacing: 12.h,
          children: item.options.map((option) {
            final isSelected = _selectedAnswer == option;
            return MatrixCellWidget(
              cell: option,
              size: 70,
              isOption: true,
              isSelected: isSelected,
              onTap: () => _handleAnswerSelected(option),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _selectedAnswer == null ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.grey300,
        ),
        child: Text(
          'Valider la réponse',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  String _getDifficultyLabel(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.veryEasy:
        return 'Facile';
      case DifficultyLevel.easy:
        return 'Moyen-Facile';
      case DifficultyLevel.medium:
        return 'Moyen';
      case DifficultyLevel.mediumHard:
        return 'Moyen-Difficile';
      case DifficultyLevel.hard:
        return 'Difficile';
    }
  }
}
