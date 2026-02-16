import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../domain/puzzle_generator.dart';
import '../widgets/puzzle_piece_widget.dart';
import '../widgets/puzzle_target_widget.dart';

/// Page du test des Puzzles Visuels (Visual Puzzles)
/// WAIS-IV : 26 items
/// Sélectionner exactement 3 pièces parmi 6 qui reconstituent la forme cible
/// Notation dichotomique : 1 si les 3 pièces sont correctes, 0 sinon
/// Temps limite : 20-30s selon difficulté
/// Règle de discontinuation : 3 échecs consécutifs
class VisualPuzzlesTestPage extends StatefulWidget {
  const VisualPuzzlesTestPage({super.key});

  @override
  State<VisualPuzzlesTestPage> createState() => _VisualPuzzlesTestPageState();
}

class _VisualPuzzlesTestPageState extends State<VisualPuzzlesTestPage> {
  int currentLevel = 0;
  int score = 0;
  int totalTime = 0;
  int _consecutiveFailures = 0;
  final Set<int> _selectedIndices = {};
  DateTime? _itemStartTime;
  Timer? _countdownTimer;
  int _remainingSeconds = 0;

  late List<PuzzleItem> _generatedItems;

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
    // Génération des 26 items UNIQUES en une seule fois
    final generator = PuzzleGenerator();
    _generatedItems = generator.generateComplete26Items();
  }

  void _startItem() {
    _itemStartTime = DateTime.now();
    _selectedIndices.clear();
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

  void _togglePieceSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        if (_selectedIndices.length < 3) {
          _selectedIndices.add(index);
        }
      }
    });
  }

  void _submitAnswer() {
    _countdownTimer?.cancel();

    final timeSeconds = _itemStartTime != null
        ? DateTime.now().difference(_itemStartTime!).inSeconds
        : 0;

    totalTime += timeSeconds;

    // Vérifier si les 3 pièces sélectionnées sont exactement les bonnes
    final correctIndices = _generatedItems[currentLevel].correctIndices.toSet();
    final isCorrect = _selectedIndices.length == 3 &&
        _selectedIndices.containsAll(correctIndices) &&
        correctIndices.containsAll(_selectedIndices);

    if (isCorrect) {
      score++;
      _consecutiveFailures = 0;
    } else {
      _consecutiveFailures++;
    }

    _showFeedbackDialog(isCorrect, timeSeconds);
  }

  void _showFeedbackDialog(bool isCorrect, int timeSeconds) {
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isCorrect
                  ? 'Bonne réponse ! +1 point'
                  : 'Mauvaise réponse. Les bonnes pièces étaient :',
            ),
            if (!isCorrect) ...[
              SizedBox(height: 12.h),
              Wrap(
                spacing: 8.w,
                children: _generatedItems[currentLevel].correctIndices.map((idx) {
                  return Text(
                    String.fromCharCode(65 + idx),
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  );
                }).toList(),
              ),
            ],
            SizedBox(height: 12.h),
            Text('Temps : ${timeSeconds}s'),
            Text('Score : $score/${currentLevel + 1}'),
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
          'Test des Puzzles Visuels - Résultats',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Score brut : $score/26 points'),
            Text('Items complétés : ${currentLevel + 1}/26'),
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
              'Test de rotation mentale et visualisation spatiale',
              style: TextStyle(
                fontSize: 12.sp,
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade600,
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
    if (score >= 22) return 'Performance exceptionnelle (θ > +2.0)';
    if (score >= 17) return 'Performance supérieure (θ > +1.0)';
    if (score >= 11) return 'Performance moyenne (θ ≈ 0)';
    if (score >= 6) return 'Performance inférieure (θ < 0)';
    return 'Performance faible (θ < -1.0)';
  }

  Color _getPerformanceColor(int score) {
    if (score >= 22) return Colors.purple;
    if (score >= 17) return Colors.green;
    if (score >= 11) return Colors.blue;
    if (score >= 6) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final currentItem = _generatedItems[currentLevel];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Puzzles Visuels'),
        backgroundColor: AppColors.indexVSI,
        actions: [
          Center(
            child: Padding(
              padding: EdgeInsets.only(right: 16.w),
              child: Text(
                'Item ${currentLevel + 1}/26',
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
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  'Sélectionnez exactement 3 pièces qui reconstituent la forme ci-dessous.',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              SizedBox(height: 20.h),

              // Forme cible
              Text(
                'Forme à reconstituer :',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.h),
              PuzzleTargetWidget(targetPieces: currentItem.targetPieces),

              SizedBox(height: 24.h),

              // Pièces disponibles
              Text(
                'Pièces disponibles (sélectionnez 3) :',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12.h),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12.w,
                  mainAxisSpacing: 12.h,
                  childAspectRatio: 1,
                ),
                itemCount: currentItem.allPieces.length,
                itemBuilder: (context, index) {
                  final isSelected = _selectedIndices.contains(index);
                  return Column(
                    children: [
                      Expanded(
                        child: PuzzlePieceWidget(
                          piece: currentItem.allPieces[index],
                          isSelected: isSelected,
                          onTap: () => _togglePieceSelection(index),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        String.fromCharCode(65 + index), // A, B, C...
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                },
              ),

              SizedBox(height: 24.h),

              // Compteur de sélection
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: _selectedIndices.length == 3
                      ? Colors.green.shade50
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: _selectedIndices.length == 3
                        ? Colors.green.shade300
                        : Colors.orange.shade300,
                  ),
                ),
                child: Text(
                  'Pièces sélectionnées : ${_selectedIndices.length}/3',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: _selectedIndices.length == 3
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              SizedBox(height: 16.h),

              // Bouton Valider
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: _selectedIndices.length == 3 ? _submitAnswer : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.indexVSI,
                    disabledBackgroundColor: Colors.grey.shade300,
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
            color: _remainingSeconds <= 5 ? Colors.red.shade100 : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: _remainingSeconds <= 5 ? Colors.red.shade400 : Colors.blue.shade300,
              width: 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timer,
                size: 20.sp,
                color: _remainingSeconds <= 5 ? Colors.red.shade700 : Colors.blue.shade700,
              ),
              SizedBox(width: 8.w),
              Text(
                '${_remainingSeconds}s',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: _remainingSeconds <= 5 ? Colors.red.shade700 : Colors.blue.shade700,
                ),
              ),
            ],
          ),
        ),

        // Score
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: Colors.green.shade300, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.star,
                size: 20.sp,
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
}
