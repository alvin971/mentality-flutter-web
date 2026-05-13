import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/kepler_button.dart';
import '../../../../core/widgets/kepler_card.dart';
import '../../../../core/widgets/kepler_scaffold.dart';
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

class AssessmentIntroPage extends StatelessWidget {
  const AssessmentIntroPage({super.key});

  static const _domains = [
    ('VCI', 'Compréhension Verbale'),
    ('VSI', 'Raisonnement Visuo-Spatial'),
    ('FRI', 'Raisonnement Fluide'),
    ('WMI', 'Mémoire de Travail'),
    ('PSI', 'Vitesse de Traitement'),
    ('LO',  'Langage Oral'),
  ];

  @override
  Widget build(BuildContext context) {
    return KeplerScaffold(
      title: 'Nouvelle évaluation',
      eyebrow: 'BILAN COGNITIF',
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cinq indices,', style: AppText.heroDisplay()),
          Text('une mesure.', style: AppText.heroItalic()),
          SizedBox(height: 16.h),
          Container(
              width: 36.w,
              height: 1,
              color: AppColors.primary.withValues(alpha: 0.4)),
          SizedBox(height: 16.h),
          Text(
            'Cette évaluation mesure vos capacités cognitives à travers six domaines '
            'issus du WAIS-IV. Un score global (FSIQ) en est la synthèse.',
            style: AppText.body(),
          ),
          SizedBox(height: 28.h),
          KeplerCard(
            surface: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('§ DOMAINES MESURÉS §',
                    style: AppText.monoLabel(color: AppColors.primary)),
                SizedBox(height: 16.h),
                for (final d in _domains) _DomainRow(code: d.$1, label: d.$2),
              ],
            ),
          ),
          SizedBox(height: 24.h),
          KeplerCard(
            child: Row(
              children: [
                Container(width: 3.w, height: 32.h, color: AppColors.primary),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('§ AVANT DE COMMENCER §',
                          style: AppText.monoLabel(color: AppColors.primary)),
                      SizedBox(height: 4.h),
                      Text(
                        'Durée estimée 30 à 45 minutes. Calme et concentration requis.',
                        style: AppText.bodySmall(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 28.h),
          KeplerButton(
            label: 'Lancer le bilan complet',
            icon: Icons.east,
            expand: true,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const CompleteTestOrchestratorPage()),
            ),
          ),
          SizedBox(height: 36.h),
          Row(
            children: [
              Expanded(
                  child: Container(
                      height: 1,
                      color: Colors.black.withValues(alpha: 0.08))),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                child: Text('§ OU SUBTEST INDIVIDUEL §',
                    style: AppText.monoLabel()),
              ),
              Expanded(
                  child: Container(
                      height: 1,
                      color: Colors.black.withValues(alpha: 0.08))),
            ],
          ),
          SizedBox(height: 20.h),
          _IndividualTests(),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }
}

class _DomainRow extends StatelessWidget {
  const _DomainRow({required this.code, required this.label});
  final String code;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        children: [
          SizedBox(
              width: 48.w,
              child: Text(code,
                  style: AppText.monoLabel(color: AppColors.primary))),
          Expanded(child: Text(label, style: AppText.body())),
        ],
      ),
    );
  }
}

class _IndividualTests extends StatelessWidget {
  static final _tests = <(String, String, Widget Function())>[
    ('VSI', 'Cubes (Block Design)', () => const CubesTestPage()),
    ('FRI', 'Matrices Progressives', () => const MatricesTestPage()),
    ('FRI', 'Balances Quantitatives', () => const FigureWeightsTestPage()),
    ('VSI', 'Puzzles Visuels', () => const VisualPuzzlesTestPage()),
    ('VCI', 'Similitudes', () => const SimilaritiesTestPage()),
    ('VCI', 'Vocabulaire', () => const VocabularyTestPage()),
    ('VCI', 'Information', () => const InformationTestPage()),
    ('WMI', 'Mémoire des Chiffres', () => const DigitSpanTestPage()),
    ('WMI', 'Arithmétique', () => const ArithmeticTestPage()),
    ('WMI', 'Mémoire des Images', () => const PictureSpanTestPage()),
    ('PSI', 'Code', () => const CodingTestPage()),
    ('PSI', 'Recherche de Symboles', () => const SymbolSearchTestPage()),
    ('LO',  'Compréhension Orale', () => const OralTestFlow()),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final t in _tests) ...[
          KeplerCard(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => t.$3()),
            ),
            child: Row(
              children: [
                SizedBox(
                    width: 40.w,
                    child: Text(t.$1,
                        style: AppText.monoLabel(color: AppColors.primary))),
                Expanded(child: Text(t.$2, style: AppText.bodyStrong())),
                Icon(Icons.east, size: 16.sp, color: AppColors.primary),
              ],
            ),
          ),
          SizedBox(height: 10.h),
        ],
      ],
    );
  }
}
