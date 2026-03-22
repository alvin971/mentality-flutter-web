import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../complete_test/presentation/pages/complete_test_orchestrator_page.dart';
import '../../../data_collection/oral_test_flow.dart';
import '../../../exercises_implementations/cubes/presentation/pages/cubes_test_page.dart';
import '../../../exercises_implementations/matrices/presentation/pages/matrices_test_page.dart';
import '../../../exercises_implementations/figure_weights/presentation/pages/figure_weights_test_page.dart';
import '../../../exercises_implementations/visual_puzzles/presentation/pages/visual_puzzles_test_page.dart';
import '../../../exercises_implementations/similarities/presentation/pages/similarities_test_page.dart';
import '../../../exercises_implementations/vocabulary/presentation/pages/vocabulary_test_page.dart';
import '../../../exercises_implementations/information/presentation/pages/information_test_page.dart';
import '../../../exercises_implementations/digit_span/presentation/pages/digit_span_test_page.dart';
import '../../../exercises_implementations/arithmetic/presentation/pages/arithmetic_test_page.dart';
import '../../../exercises_implementations/picture_span/presentation/pages/picture_span_test_page.dart';
import '../../../exercises_implementations/coding/presentation/pages/coding_test_page.dart';
import '../../../exercises_implementations/symbol_search/presentation/pages/symbol_search_test_page.dart';

/// Page d'introduction à l'évaluation cognitive.
///
/// Présente les 5+1 domaines mesurés, puis propose :
/// - Un bouton "TEST COMPLET WAIS-IV" bien mis en avant
/// - Des boutons pour chaque sous-test individuel
class AssessmentIntroPage extends StatelessWidget {
  const AssessmentIntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 800;

    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle évaluation')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isWide ? 80.w : 24.w,
            vertical: 24.h,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroSection(context),
              SizedBox(height: 32.h),
              _buildDomainsSection(context),
              SizedBox(height: 24.h),
              _buildInfoBanner(context),
              SizedBox(height: 24.h),
              _buildCompleteTestButton(context),
              SizedBox(height: 24.h),
              _buildDivider(context),
              SizedBox(height: 16.h),
              _buildIndividualTests(context, isWide),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 140.w,
            height: 140.w,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.psychology, size: 72.sp, color: AppColors.primary),
          ),
          SizedBox(height: 24.h),
          Text(
            'Évaluation cognitive',
            style: Theme.of(context).textTheme.displayMedium,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12.h),
          Text(
            'Cette évaluation mesure vos capacités cognitives à travers 5 domaines :',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDomainsSection(BuildContext context) {
    final domains = [
      (Icons.chat_bubble_outline, 'Compréhension Verbale', AppColors.indexVCI),
      (Icons.view_in_ar_outlined, 'Raisonnement Visuo-Spatial', AppColors.indexVSI),
      (Icons.extension_outlined, 'Raisonnement Fluide', AppColors.indexFRI),
      (Icons.memory_outlined, 'Mémoire de Travail', AppColors.indexWMI),
      (Icons.speed_outlined, 'Vitesse de Traitement', AppColors.indexPSI),
      (Icons.record_voice_over, 'Langage Oral', Colors.teal),
    ];

    return Column(
      children: domains
          .map((d) => Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: _DomainTile(icon: d.$1, title: d.$2, color: d.$3),
              ))
          .toList(),
    );
  }

  Widget _buildInfoBanner(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.info.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.info, size: 24.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'Durée estimée : 30-45 minutes\nAssurez-vous d\'être dans un environnement calme sans distractions.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.info),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteTestButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 72.h,
      child: ElevatedButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CompleteTestOrchestratorPage()),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.psychology, size: 28.sp),
            SizedBox(width: 12.w),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TEST COMPLET WAIS-IV',
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Tous les subtests (60-90 min)',
                  style: TextStyle(fontSize: 12.sp),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: AppColors.grey300)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Text(
            'OU tests individuels',
            style: TextStyle(fontSize: 14.sp, color: AppColors.grey600),
          ),
        ),
        Expanded(child: Divider(color: AppColors.grey300)),
      ],
    );
  }

  Widget _buildIndividualTests(BuildContext context, bool isWide) {
    final tests = [
      ('Cubes (Block Design)', AppColors.indexVSI, () => const CubesTestPage()),
      ('Matrices Progressives', AppColors.indexFRI, () => const MatricesTestPage()),
      ('Balances Quantitatives', AppColors.indexFRI, () => const FigureWeightsTestPage()),
      ('Puzzles Visuels', AppColors.indexVSI, () => const VisualPuzzlesTestPage()),
      ('Similitudes', AppColors.indexVCI, () => const SimilaritiesTestPage()),
      ('Vocabulaire', AppColors.indexVCI, () => const VocabularyTestPage()),
      ('Information', AppColors.indexVCI, () => const InformationTestPage()),
      ('Mémoire des Chiffres', AppColors.indexWMI, () => const DigitSpanTestPage()),
      ('Arithmétique', AppColors.indexWMI, () => const ArithmeticTestPage()),
      ('Mémoire des Images', AppColors.indexWMI, () => const PictureSpanTestPage()),
      ('Code (Coding)', AppColors.indexPSI, () => const CodingTestPage()),
      ('Recherche de Symboles', AppColors.indexPSI, () => const SymbolSearchTestPage()),
      ('Compréhension Orale', Colors.teal, () => const OralTestFlow()),
    ];

    if (isWide) {
      // Grille 2 colonnes sur desktop
      final rows = <Widget>[];
      for (int i = 0; i < tests.length; i += 2) {
        rows.add(
          Row(
            children: [
              Expanded(child: _testButton(context, tests[i])),
              SizedBox(width: 12.w),
              Expanded(
                child: i + 1 < tests.length
                    ? _testButton(context, tests[i + 1])
                    : const SizedBox(),
              ),
            ],
          ),
        );
        rows.add(SizedBox(height: 12.h));
      }
      return Column(children: rows);
    }

    return Column(
      children: tests.map((t) {
        return Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: _testButton(context, t),
        );
      }).toList(),
    );
  }

  Widget _testButton(
    BuildContext context,
    (String, Color, Widget Function()) test,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => test.$3()),
        ),
        style: ElevatedButton.styleFrom(backgroundColor: test.$2),
        child: Text(test.$1),
      ),
    );
  }
}

class _DomainTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _DomainTile({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, size: 20.sp, color: color),
        ),
        SizedBox(width: 12.w),
        Text(title, style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }
}
