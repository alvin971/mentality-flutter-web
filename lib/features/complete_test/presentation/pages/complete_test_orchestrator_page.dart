import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../bloc/complete_test_bloc.dart';
import '../../bloc/complete_test_event.dart';
import '../../bloc/complete_test_state.dart';
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

/// Orchestrateur du test complet WAIS-IV.
///
/// Pilote la séquence des 12 sous-tests via CompleteTestBloc.
/// Chaque sous-test est lancé dans Navigator.push() et retourne
/// son score via Navigator.pop(score).
class CompleteTestOrchestratorPage extends StatelessWidget {
  const CompleteTestOrchestratorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CompleteTestBloc(),
      child: const _OrchestratorView(),
    );
  }
}

class _OrchestratorView extends StatefulWidget {
  const _OrchestratorView();

  @override
  State<_OrchestratorView> createState() => _OrchestratorViewState();
}

class _OrchestratorViewState extends State<_OrchestratorView> {
  final TextEditingController _ageController = TextEditingController();
  int? _ageInMonths;

  @override
  void dispose() {
    _ageController.dispose();
    super.dispose();
  }

  void _launchTest(BuildContext context, String testName) {
    final page = _getTestPage(testName);
    Navigator.push<int>(
      context,
      MaterialPageRoute(builder: (_) => page),
    ).then((score) {
      if (!context.mounted) return;
      if (score != null) {
        context.read<CompleteTestBloc>().add(
              SubmitSubtestScoreEvent(testName: testName, score: score),
            );
      }
    });
  }

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
          body: Center(child: Text('Test non trouvé : $testName')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CompleteTestBloc, CompleteTestState>(
      listener: (context, state) {
        if (state is CompleteTestRunningState) {
          // Lancer le prochain sous-test après 500 ms
          Future.delayed(const Duration(milliseconds: 500), () {
            if (context.mounted) {
              _launchTest(context, state.nextTestName);
            }
          });
        } else if (state is CompleteTestDoneState) {
          // addPostFrameCallback garantit que la navigation se fait
          // après la fin du cycle de build (évite l'écran gris).
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => CompleteTestResultsPage(
                    session: state.session,
                    ageInMonths: state.ageInMonths,
                  ),
                ),
              );
            }
          });
        }
      },
      builder: (context, state) {
        if (state is CompleteTestIntroState) {
          return _buildIntroScreen(context);
        }
        // CompleteTestDoneState : afficher un écran d'attente pendant la
        // navigation (addPostFrameCallback n'est pas encore exécuté).
        if (state is CompleteTestDoneState) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  SizedBox(height: 24.h),
                  Text('Chargement des résultats...',
                      style: TextStyle(fontSize: 16.sp)),
                ],
              ),
            ),
          );
        }
        return _buildProgressScreen(context, state);
      },
    );
  }

  Widget _buildIntroScreen(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Test Complet WAIS-IV',
            style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold)),
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
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Column(children: [
                  Icon(Icons.psychology, size: 64.sp, color: AppColors.primary),
                  SizedBox(height: 16.h),
                  Text('Test Complet WAIS-IV',
                      style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary),
                      textAlign: TextAlign.center),
                  SizedBox(height: 8.h),
                  Text('Évaluation cognitive complète',
                      style: TextStyle(fontSize: 16.sp, color: AppColors.grey600),
                      textAlign: TextAlign.center),
                ]),
              ),

              SizedBox(height: 24.h),

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
                    '• Cubes • Similitudes • Mémoire des chiffres\n'
                    '• Matrices • Vocabulaire • Arithmétique\n'
                    '• Recherche de symboles • Puzzles visuels\n'
                    '• Information • Code • Mémoire des images • Balances',
              ),
              _buildInfoCard(
                icon: Icons.warning_amber,
                title: 'Important',
                description:
                    'Les tests se lanceront automatiquement l\'un après l\'autre. '
                    'Assurez-vous d\'avoir suffisamment de temps.',
                color: AppColors.warning,
              ),

              SizedBox(height: 32.h),

              // Saisie de l'âge
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Âge du patient (requis pour les normes)',
                        style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.grey900)),
                    SizedBox(height: 12.h),
                    TextField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Ex : 35',
                        suffixText: 'ans',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r)),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 12.h),
                      ),
                      onChanged: (v) {
                        final years = int.tryParse(v);
                        setState(() {
                          _ageInMonths = (years != null &&
                                  years >= 16 &&
                                  years <= 90)
                              ? years * 12
                              : null;
                        });
                      },
                    ),
                    if (_ageController.text.isNotEmpty && _ageInMonths == null)
                      Padding(
                        padding: EdgeInsets.only(top: 8.h),
                        child: Text('Âge valide : entre 16 et 90 ans',
                            style: TextStyle(
                                fontSize: 13.sp, color: AppColors.error)),
                      ),
                  ],
                ),
              ),

              SizedBox(height: 24.h),

              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed: _ageInMonths != null
                      ? () => context.read<CompleteTestBloc>().add(
                            StartTestEvent(_ageInMonths!),
                          )
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    disabledBackgroundColor:
                        AppColors.success.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r)),
                  ),
                  child: Text('Commencer le Test Complet',
                      style: TextStyle(
                          fontSize: 18.sp, fontWeight: FontWeight.bold)),
                ),
              ),

              SizedBox(height: 16.h),

              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r)),
                  ),
                  child: Text('Annuler',
                      style:
                          TextStyle(fontSize: 18.sp, color: AppColors.error)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressScreen(BuildContext context, CompleteTestState state) {
    final session = state is CompleteTestRunningState
        ? state.session
        : state is CompleteTestAwaitingNextState
            ? state.session
            : null;

    return Scaffold(
      appBar: AppBar(
        title: Text('Test en cours',
            style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Progression du Test',
                  style:
                      TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 24.h),

              if (session != null) ...[
                // Barre de progression globale
                LinearProgressIndicator(
                  value: session.progressPercentage / 100,
                  backgroundColor: AppColors.surfaceVariant,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 12.h,
                ),
                SizedBox(height: 16.h),
                Text(
                  '${session.completedTestsCount} / ${session.totalTests} tests complétés',
                  style:
                      TextStyle(fontSize: 18.sp, color: AppColors.grey600),
                ),
              ],

              SizedBox(height: 48.h),
              const CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 24.h),
              Text('Lancement du prochain test...',
                  style: TextStyle(fontSize: 16.sp, color: AppColors.grey600),
                  textAlign: TextAlign.center),

              if (state is CompleteTestRunningState) ...[
                SizedBox(height: 16.h),
                Text(
                  'Prochain : ${state.nextTestName}',
                  style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary),
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
    final c = color ?? AppColors.primary;
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border:
            Border.all(color: c.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: c, size: 24.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: c)),
                SizedBox(height: 4.h),
                Text(description,
                    style:
                        TextStyle(fontSize: 14.sp, color: AppColors.grey600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
