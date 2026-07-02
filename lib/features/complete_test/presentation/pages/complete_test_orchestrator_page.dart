import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/kepler_button.dart';
import '../../../../core/widgets/kepler_card.dart';
import '../../../../core/widgets/kepler_progress.dart';
import '../../../../core/widgets/kepler_scaffold.dart';
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
import '../../../../core/l10n/l10n_ext.dart';

/// Traduit la clé technique d'un sous-test (français, issue de
/// [CompleteTestSession.testSequence]) en libellé localisé pour l'affichage.
/// La clé elle-même reste inchangée (elle sert d'identifiant dans les `switch`).
String _localizedTestName(BuildContext context, String key) {
  switch (key) {
    case 'Cubes':
      return context.l10n.ctTestCubes;
    case 'Similitudes':
      return context.l10n.ctTestSimilarities;
    case 'Mémoire des Chiffres':
      return context.l10n.ctTestDigitSpan;
    case 'Matrices':
      return context.l10n.ctTestMatrices;
    case 'Vocabulaire':
      return context.l10n.ctTestVocabulary;
    case 'Arithmétique':
      return context.l10n.ctTestArithmetic;
    case 'Recherche de Symboles':
      return context.l10n.ctTestSymbolSearch;
    case 'Puzzles Visuels':
      return context.l10n.ctTestVisualPuzzles;
    case 'Information':
      return context.l10n.ctTestInformation;
    case 'Code':
      return context.l10n.ctTestCoding;
    case 'Mémoire des Images':
      return context.l10n.ctTestPictureSpan;
    case 'Balances':
      return context.l10n.ctTestFigureWeights;
    default:
      return key;
  }
}

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
    final page = _getTestPage(context, testName);
    Navigator.push<int>(
      context,
      MaterialPageRoute(builder: (_) => page),
    ).then((score) {
      if (!context.mounted) return;
      if (score != null) {
        context.read<CompleteTestBloc>().add(
              SubmitSubtestScoreEvent(testName: testName, score: score),
            );
      } else {
        // L'utilisateur a quitté le sous-test sans le terminer (retour
        // arrière). Sans ce garde-fou, aucun événement n'est émis et
        // l'orchestrateur reste bloqué indéfiniment sur « Lancement… ».
        // On propose de reprendre le sous-test ou d'arrêter l'évaluation.
        _handleSubtestAbandon(context, testName);
      }
    });
  }

  Future<void> _handleSubtestAbandon(
      BuildContext context, String testName) async {
    final resume = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.l10n.ctSubtestExitTitle),
        content: Text(dialogContext.l10n.ctSubtestExitBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(dialogContext.l10n.ctBackToHome),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(dialogContext.l10n.ctSubtestExitResume),
          ),
        ],
      ),
    );
    if (!context.mounted) return;
    if (resume == true) {
      _launchTest(context, testName); // relance le même sous-test
    } else {
      Navigator.of(context).maybePop(); // quitte la batterie vers l'écran précédent
    }
  }

  Widget _getTestPage(BuildContext context, String testName) {
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
        return KeplerScaffold(
          title: context.l10n.commonError,
          child: Center(child: Text(context.l10n.ctTestNotFound(testName))),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CompleteTestBloc, CompleteTestState>(
      listener: (context, state) {
        if (state is CompleteTestRunningState) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (context.mounted) _launchTest(context, state.nextTestName);
          });
        } else if (state is CompleteTestDoneState) {
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
        if (state is CompleteTestIntroState) return _buildIntroScreen(context);
        if (state is CompleteTestDoneState) {
          return KeplerScaffold(
            title: context.l10n.ctComputingResultsTitle,
            eyebrow: context.l10n.ctComputingResultsEyebrow,
            scroll: false,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 20.h),
                  Text(context.l10n.ctProcessing,
                      style: AppText.monoLabel(color: AppColors.primary)),
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
    return KeplerScaffold(
      title: context.l10n.ctIntroTitle,
      eyebrow: 'WAIS-IV',
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.ctIntroHero1, style: AppText.heroDisplay()),
          Text(context.l10n.ctIntroHero2, style: AppText.heroItalic()),
          SizedBox(height: 16.h),
          Container(
              width: 36.w,
              height: 1,
              color: AppColors.primary.withValues(alpha: 0.4)),
          SizedBox(height: 16.h),
          Text(
            context.l10n.ctIntroDescription,
            style: AppText.body(),
          ),
          SizedBox(height: 24.h),
          _InfoCard(
              eyebrow: context.l10n.ctIntroDurationEyebrow,
              title: context.l10n.ctIntroDurationTitle,
              body: context.l10n.ctIntroDurationBody),
          SizedBox(height: 12.h),
          _InfoCard(
              eyebrow: context.l10n.ctIntroContentEyebrow,
              title: context.l10n.ctIntroContentTitle,
              body: context.l10n.ctIntroContentBody),
          SizedBox(height: 12.h),
          _InfoCard(
              eyebrow: context.l10n.ctIntroImportantEyebrow,
              title: context.l10n.ctIntroImportantTitle,
              body: context.l10n.ctIntroImportantBody),
          SizedBox(height: 24.h),
          KeplerCard(
            surface: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.ctPatientAgeHeader,
                    style: AppText.monoLabel(color: AppColors.primary)),
                SizedBox(height: 12.h),
                Text(
                    context.l10n.ctPatientAgeHint,
                    style: AppText.bodySmall()),
                SizedBox(height: 12.h),
                TextField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  style: AppText.monoScore(size: 22.sp),
                  decoration: InputDecoration(
                    hintText: '00',
                    hintStyle: AppText.monoScore(
                        color: Theme.of(context).colorScheme.outline, size: 22.sp),
                    suffixText: context.l10n.ctAgeSuffix,
                    suffixStyle:
                        AppText.monoLabel(color: Theme.of(context).colorScheme.outline),
                    filled: true,
                    fillColor: Theme.of(context).scaffoldBackgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6.r),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6.r),
                      borderSide:
                          BorderSide(color: Colors.black.withValues(alpha: 0.07)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6.r),
                      borderSide: const BorderSide(
                          color: AppColors.primary, width: 2),
                    ),
                  ),
                  onChanged: (v) {
                    final years = int.tryParse(v);
                    setState(() {
                      _ageInMonths = (years != null && years >= 16 && years <= 90)
                          ? years * 12
                          : null;
                    });
                  },
                ),
                if (_ageController.text.isNotEmpty && _ageInMonths == null)
                  Padding(
                    padding: EdgeInsets.only(top: 8.h),
                    child: Text(context.l10n.ctAgeRangeError,
                        style: AppText.bodySmall(color: AppColors.error)),
                  ),
              ],
            ),
          ),
          SizedBox(height: 24.h),
          KeplerButton(
            label: context.l10n.ctLaunchFullTest,
            icon: Icons.east,
            expand: true,
            onPressed: _ageInMonths != null
                ? () => context.read<CompleteTestBloc>().add(
                      StartTestEvent(_ageInMonths!),
                    )
                : null,
          ),
          SizedBox(height: 12.h),
          KeplerButton(
            label: context.l10n.commonCancel,
            variant: KeplerButtonVariant.ghost,
            expand: true,
            onPressed: () => Navigator.pop(context),
          ),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  Widget _buildProgressScreen(BuildContext context, CompleteTestState state) {
    final session = state is CompleteTestRunningState
        ? state.session
        : state is CompleteTestAwaitingNextState
            ? state.session
            : null;

    final progress = session != null ? session.progressPercentage / 100 : 0.0;
    final completed = session?.completedTestsCount ?? 0;
    final total = session?.totalTests ?? 12;
    final next = state is CompleteTestRunningState ? state.nextTestName : null;

    return KeplerScaffold(
      title: context.l10n.ctRunningTitle,
      eyebrow: 'WAIS-IV',
      scroll: false,
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          KeplerProgress(
            value: progress,
            current: completed,
            total: total,
            label: context.l10n.ctGlobalProgress,
          ),
          SizedBox(height: 40.h),
          if (next != null) ...[
            Text(context.l10n.ctNextSubtest,
                style: AppText.monoLabel(color: AppColors.primary)),
            SizedBox(height: 8.h),
            Text(_localizedTestName(context, next), style: AppText.h1Italic()),
            SizedBox(height: 24.h),
          ],
          Row(
            children: [
              SizedBox(
                width: 18.w,
                height: 18.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: 12.w),
              Text(context.l10n.ctLaunching,
                  style: AppText.monoLabel(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard(
      {required this.eyebrow, required this.title, required this.body});
  final String eyebrow;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return KeplerCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 3.w, height: 36.h, color: AppColors.primary),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$eyebrow',
                    style: AppText.monoLabel(color: AppColors.primary)),
                SizedBox(height: 4.h),
                Text(title, style: AppText.bodyStrong()),
                SizedBox(height: 4.h),
                Text(body, style: AppText.bodySmall()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
