import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/models/complete_test_session.dart';
import '../../../exercises_implementations/cubes/presentation/pages/cubes_test_page.dart';
import '../../../exercises_implementations/similarities/presentation/pages/similarities_test_page.dart';
import '../../../exercises_implementations/digit_span/presentation/pages/digit_span_test_page.dart';
import '../../../exercises_implementations/matrices/presentation/pages/matrices_test_page.dart';
import '../../../exercises_implementations/vocabulary/presentation/pages/vocabulary_test_page.dart';
import '../../../exercises_implementations/arithmetic/presentation/pages/arithmetic_test_page.dart';
import '../../../exercises_implementations/symbol_search/presentation/pages/symbol_search_test_page.dart';
import '../../../exercises_implementations/visual_puzzles/presentation/pages/visual_puzzles_test_page.dart';
import '../../../exercises_implementations/information/presentation/pages/information_test_page.dart';
import '../../../exercises_implementations/coding/presentation/pages/coding_test_page.dart';
import '../../../exercises_implementations/picture_span/presentation/pages/picture_span_test_page.dart';
import '../../../exercises_implementations/figure_weights/presentation/pages/figure_weights_test_page.dart';
import 'complete_test_results_page.dart';

/// Page d'orchestration du test complet WAIS-IV
/// Lance automatiquement tous les subtests dans l'ordre
class CompleteTestOrchestratorPage extends StatefulWidget {
  const CompleteTestOrchestratorPage({Key? key}) : super(key: key);

  @override
  State<CompleteTestOrchestratorPage> createState() => _CompleteTestOrchestratorPageState();
}

class _CompleteTestOrchestratorPageState extends State<CompleteTestOrchestratorPage> {
  late CompleteTestSession _session;
  bool _isIntroScreen = true;

  @override
  void initState() {
    super.initState();
    _session = CompleteTestSession(startTime: DateTime.now());
  }

  /// Lance le test suivant dans la séquence
  void _launchNextTest() {
    if (_session.isComplete) {
      _showResults();
      return;
    }

    final testName = _session.currentTestName;

    // Navigation vers le test approprié
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _getTestPage(testName),
      ),
    ).then((result) {
      // Récupérer le score du test
      if (result != null && result is int) {
        _saveTestScore(testName, result);
        _session.completeCurrentTest();
        setState(() {});

        // Lancer le test suivant automatiquement
        if (!_session.isComplete) {
          Future.delayed(const Duration(milliseconds: 500), () {
            _launchNextTest();
          });
        } else {
          _showResults();
        }
      }
    });
  }

  /// Retourne la page de test appropriée
  Widget _getTestPage(String testName) {
    switch (testName) {
      case 'Cubes':
        return const CubesTestPage();
      case 'Similitudes':
        return const SimilaritiesTestPage();
      case 'Mémoire des Chiffres':
        return const DigitSpanTestPage();
      case 'Matrices':
        return const MatricesTestPage();
      case 'Vocabulaire':
        return const VocabularyTestPage();
      case 'Arithmétique':
        return const ArithmeticTestPage();
      case 'Recherche de Symboles':
        return const SymbolSearchTestPage();
      case 'Puzzles Visuels':
        return const VisualPuzzlesTestPage();
      case 'Information':
        return const InformationTestPage();
      case 'Code':
        return const CodingTestPage();
      case 'Mémoire des Images':
        return const PictureSpanTestPage();
      case 'Balances':
        return const FigureWeightsTestPage();
      default:
        return Scaffold(
          body: Center(child: Text('Test non trouvé: $testName')),
        );
    }
  }

  /// Sauvegarde le score d'un test
  void _saveTestScore(String testName, int score) {
    switch (testName) {
      case 'Cubes':
        _session = _session.copyWith(cubesScore: score);
        break;
      case 'Similitudes':
        _session = _session.copyWith(similaritiesScore: score);
        break;
      case 'Mémoire des Chiffres':
        _session = _session.copyWith(digitSpanScore: score);
        break;
      case 'Matrices':
        _session = _session.copyWith(matricesScore: score);
        break;
      case 'Vocabulaire':
        _session = _session.copyWith(vocabularyScore: score);
        break;
      case 'Arithmétique':
        _session = _session.copyWith(arithmeticScore: score);
        break;
      case 'Recherche de Symboles':
        _session = _session.copyWith(symbolSearchScore: score);
        break;
      case 'Puzzles Visuels':
        _session = _session.copyWith(visualPuzzlesScore: score);
        break;
      case 'Information':
        _session = _session.copyWith(informationScore: score);
        break;
      case 'Code':
        _session = _session.copyWith(codingScore: score);
        break;
      case 'Mémoire des Images':
        _session = _session.copyWith(pictureSpanScore: score);
        break;
      case 'Balances':
        _session = _session.copyWith(figureWeightsScore: score);
        break;
    }
  }

  /// Affiche la page de résultats finaux
  void _showResults() {
    _session = _session.copyWith(endTime: DateTime.now());
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => CompleteTestResultsPage(session: _session),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isIntroScreen) {
      return _buildIntroScreen();
    }

    return _buildProgressScreen();
  }

  Widget _buildIntroScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Test Complet WAIS-IV',
          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Column(
                  children: [
                    Icon(Icons.psychology, size: 64.sp, color: AppColors.primary),
                    SizedBox(height: 16.h),
                    Text(
                      'Test Complet WAIS-IV',
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Évaluation cognitive complète',
                      style: TextStyle(fontSize: 16.sp, color: AppColors.grey600),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24.h),

              // Description
              _buildInfoCard(
                icon: Icons.info_outline,
                title: 'À propos du test',
                description:
                    'Ce test complet évalue 4 indices cognitifs majeurs à travers 12 subtests standardisés.',
              ),

              _buildInfoCard(
                icon: Icons.timer,
                title: 'Durée estimée',
                description: '60-90 minutes pour compléter tous les subtests.',
              ),

              _buildInfoCard(
                icon: Icons.list_alt,
                title: '12 Subtests inclus',
                description:
                    '• Cubes (Design de blocs)\n'
                    '• Similitudes\n'
                    '• Mémoire des chiffres\n'
                    '• Matrices\n'
                    '• Vocabulaire\n'
                    '• Arithmétique\n'
                    '• Recherche de symboles\n'
                    '• Puzzles visuels\n'
                    '• Information\n'
                    '• Code\n'
                    '• Mémoire des images\n'
                    '• Balances',
              ),

              _buildInfoCard(
                icon: Icons.trending_up,
                title: 'Indices évalués',
                description:
                    '• ICV - Compréhension Verbale\n'
                    '• IRP - Raisonnement Perceptif\n'
                    '• IMT - Mémoire de Travail\n'
                    '• IVT - Vitesse de Traitement',
              ),

              _buildInfoCard(
                icon: Icons.warning_amber,
                title: 'Important',
                description:
                    'Les tests se lanceront automatiquement l\'un après l\'autre. '
                    'Assurez-vous d\'avoir suffisamment de temps avant de commencer.',
                color: AppColors.warning,
              ),

              SizedBox(height: 32.h),

              // Bouton de démarrage
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isIntroScreen = false;
                    });
                    _launchNextTest();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    'Commencer le Test Complet',
                    style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              SizedBox(height: 16.h),

              // Bouton d'annulation
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    'Annuler',
                    style: TextStyle(fontSize: 18.sp, color: AppColors.error),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Test en cours',
          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Progression
              Text(
                'Progression du Test',
                style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 24.h),

              // Barre de progression
              LinearProgressIndicator(
                value: _session.progressPercentage / 100,
                backgroundColor: AppColors.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 12.h,
              ),
              SizedBox(height: 16.h),

              Text(
                '${_session.completedTestsCount} / ${_session.totalTests} tests complétés',
                style: TextStyle(fontSize: 18.sp, color: AppColors.grey600),
              ),

              SizedBox(height: 48.h),

              // Message d'attente
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 24.h),

              Text(
                'Lancement du prochain test...',
                style: TextStyle(fontSize: 16.sp, color: AppColors.grey600),
                textAlign: TextAlign.center,
              ),

              if (!_session.isComplete) ...[
                SizedBox(height: 16.h),
                Text(
                  'Prochain: ${_session.currentTestName}',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
    Color? color,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: color?.withOpacity(0.3) ?? AppColors.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color ?? AppColors.primary, size: 24.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: color ?? AppColors.grey900,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  description,
                  style: TextStyle(fontSize: 14.sp, color: AppColors.grey600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
