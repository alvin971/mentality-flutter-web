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

/// Catégories de tests affichées dans le tab bar
enum _TestDomain { verbal, visuel, memoire, vitesse }

/// Page d'introduction à l'évaluation cognitive.
class AssessmentIntroPage extends StatefulWidget {
  const AssessmentIntroPage({super.key});

  @override
  State<AssessmentIntroPage> createState() => _AssessmentIntroPageState();
}

class _AssessmentIntroPageState extends State<AssessmentIntroPage> {
  _TestDomain _selectedDomain = _TestDomain.verbal;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle évaluation'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              SizedBox(height: 28.h),
              _buildTabBar(),
              SizedBox(height: 16.h),
              _buildTestList(),
              SizedBox(height: 8.h),
              _buildDomainIndicator(),
              SizedBox(height: 28.h),
              _buildCompleteTestButton(),
              SizedBox(height: 12.h),
              _buildOralButton(),
              SizedBox(height: 16.h),
              _buildInfoBanner(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LES 12 TESTS',
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.8,
            color: AppColors.textTertiary,
          ),
        ),
        SizedBox(height: 10.h),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 26.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.25,
            ),
            children: const [
              TextSpan(text: 'Basé sur le '),
              TextSpan(
                text: 'WAIS-IV',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'La batterie de tests d\'intelligence la plus utilisée et validée scientifiquement dans le monde.',
          style: TextStyle(
            fontSize: 13.sp,
            color: AppColors.textSecondary,
            height: 1.55,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    final tabs = [
      (_TestDomain.verbal, Icons.menu_book_outlined, 'Verbal'),
      (_TestDomain.visuel, Icons.visibility_outlined, 'Visuel'),
      (_TestDomain.memoire, Icons.storage_outlined, 'Mémoire'),
      (_TestDomain.vitesse, Icons.bolt_outlined, 'Vitesse'),
    ];

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: tabs.map((tab) {
          final isActive = _selectedDomain == tab.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedDomain = tab.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: EdgeInsets.symmetric(vertical: 10.h),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(9.r),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Column(
                  children: [
                    Icon(
                      tab.$2,
                      size: 18.sp,
                      color: isActive
                          ? AppColors.secondary
                          : AppColors.textTertiary,
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      tab.$3,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isActive
                            ? AppColors.textPrimary
                            : AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTestList() {
    final testsMap = {
      _TestDomain.verbal: [
        ('01', 'Similitudes', 'Identifier des points communs entre deux concepts.',
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SimilaritiesTestPage()))),
        ('02', 'Vocabulaire', 'Définir le sens de mots de complexité croissante.',
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VocabularyTestPage()))),
        ('03', 'Information', 'Répondre à des questions de culture générale.',
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InformationTestPage()))),
      ],
      _TestDomain.visuel: [
        ('01', 'Cubes', 'Reproduire des modèles géométriques avec des cubes.',
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CubesTestPage()))),
        ('02', 'Matrices Progressives', 'Compléter des séquences de formes abstraites.',
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MatricesTestPage()))),
        ('03', 'Puzzles Visuels', 'Reconstruire une image à partir de pièces.',
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VisualPuzzlesTestPage()))),
        ('04', 'Balances', 'Résoudre des équations de balance visuelle.',
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FigureWeightsTestPage()))),
      ],
      _TestDomain.memoire: [
        ('01', 'Mémoire des Chiffres', 'Répéter des séquences de chiffres.',
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DigitSpanTestPage()))),
        ('02', 'Mémoire des Images', 'Mémoriser et reconnaître des séquences d\'images.',
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PictureSpanTestPage()))),
        ('03', 'Arithmétique', 'Résoudre des problèmes mathématiques de tête.',
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ArithmeticTestPage()))),
      ],
      _TestDomain.vitesse: [
        ('01', 'Code', 'Associer des symboles à des chiffres rapidement.',
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CodingTestPage()))),
        ('02', 'Recherche de Symboles', 'Détecter des symboles cibles parmi des distracteurs.',
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SymbolSearchTestPage()))),
      ],
    };

    final tests = testsMap[_selectedDomain] ?? [];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: List.generate(tests.length, (i) {
          final t = tests[i];
          final isLast = i == tests.length - 1;
          return _TestRow(
            number: t.$1,
            title: t.$2,
            description: t.$3,
            onTap: t.$4,
            showDivider: !isLast,
          );
        }),
      ),
    );
  }

  Widget _buildDomainIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: _TestDomain.values.map((d) {
        final isActive = d == _selectedDomain;
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 3.w),
          width: isActive ? 20.w : 6.w,
          height: 6.h,
          decoration: BoxDecoration(
            color: isActive ? AppColors.secondary : AppColors.grey300,
            borderRadius: BorderRadius.circular(3.r),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCompleteTestButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const CompleteTestOrchestratorPage()),
        ),
        child: const Text('Commencer l\'évaluation complète'),
      ),
    );
  }

  Widget _buildOralButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const OralTestFlow()),
        ),
        child: const Text('Test de compréhension orale →'),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule_outlined,
              color: AppColors.textSecondary, size: 20.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              'Durée estimée : 30-45 min · Environnement calme recommandé',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TestRow extends StatelessWidget {
  final String number;
  final String title;
  final String description;
  final VoidCallback onTap;
  final bool showDivider;

  const _TestRow({
    required this.number,
    required this.title,
    required this.description,
    required this.onTap,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: showDivider
              ? BorderRadius.zero
              : BorderRadius.only(
                  bottomLeft: Radius.circular(16.r),
                  bottomRight: Radius.circular(16.r),
                ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            child: Row(
              children: [
                Container(
                  width: 32.w,
                  height: 32.w,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    number,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios,
                    size: 14.sp, color: AppColors.grey400),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: AppColors.grey200,
            indent: 16.w,
            endIndent: 16.w,
          ),
      ],
    );
  }
}
