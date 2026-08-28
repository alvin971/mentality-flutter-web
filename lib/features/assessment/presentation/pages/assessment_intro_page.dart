import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/services/resume_service.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/kepler_colors.dart';
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
import '../../../../core/l10n/l10n_ext.dart';

class AssessmentIntroPage extends StatefulWidget {
  const AssessmentIntroPage({super.key});

  @override
  State<AssessmentIntroPage> createState() => _AssessmentIntroPageState();
}

class _AssessmentIntroPageState extends State<AssessmentIntroPage> {
  /// La passation à poursuivre, s'il y en a une.
  ///
  /// C'est ICI que la question se pose : cette page est la porte d'entrée du
  /// bilan, et n'offrir que « Lancer le bilan complet » à quelqu'un qui en a un
  /// en cours lui faisait effacer son travail d'un seul bouton, sans un mot.
  ResumableSession? _reprise;
  bool _recherche = true;

  @override
  void initState() {
    super.initState();
    _chercher();
  }

  Future<void> _chercher() async {
    final r = await ResumeService.instance.lookup();
    if (!mounted) return;
    setState(() {
      _reprise = r;
      _recherche = false;
    });
  }

  /// Poursuit la passation en cours. L'écran suivant se contente d'obéir : la
  /// question ne se pose qu'ICI, une seule fois.
  Future<void> _reprendre() async {
    final r = _reprise;
    if (r == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CompleteTestOrchestratorPage(reprise: r),
      ),
    );
    if (mounted) _chercher();
  }

  /// Repart de zéro. Irréversible, donc confirmé : la passation en cours est
  /// close côté serveur et son état local effacé.
  Future<void> _recommencer() async {
    final r = _reprise;
    if (r != null) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (d) => AlertDialog(
          title: Text(d.l10n.homeResumeRestartTitle),
          content: Text(d.l10n.homeResumeRestartBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(d, false),
              child: Text(d.l10n.commonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(d, true),
              child: Text(d.l10n.homeResumeRestart),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
      await ResumeService.instance.abandon(r);
      if (!mounted) return;
      setState(() => _reprise = null);
    }
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CompleteTestOrchestratorPage(),
      ),
    );
    if (mounted) _chercher();
  }

  /// Libellé localisé d'un sous-test à partir de sa clé de séquence.
  String _nomExercice(BuildContext context, String cle) =>
      localizedSubtestName(context, cle);

  @override
  Widget build(BuildContext context) {
    final domains = [
      ('VCI', context.l10n.assessDomainVci),
      ('VSI', context.l10n.assessDomainVsi),
      ('FRI', context.l10n.assessDomainFri),
      ('WMI', context.l10n.assessDomainWmi),
      ('PSI', context.l10n.assessDomainPsi),
      ('LO', context.l10n.assessDomainLo),
    ];
    return KeplerScaffold(
      title: context.l10n.assessIntroTitle,
      eyebrow: context.l10n.assessIntroEyebrow,
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.assessIntroHero1, style: AppText.of(context).heroDisplay()),
          Text(context.l10n.assessIntroHero2, style: AppText.of(context).heroItalic()),
          SizedBox(height: 16.h),
          Container(
              width: 36.w,
              height: 1,
              color: KeplerColors.of(context).primary.withValues(alpha: 0.4)),
          SizedBox(height: 16.h),
          Text(
            context.l10n.assessIntroDescription,
            style: AppText.of(context).body(),
          ),
          SizedBox(height: 28.h),
          KeplerCard(
            surface: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.assessDomainsHeader,
                    style: AppText.of(context).monoLabel(color: KeplerColors.of(context).primary)),
                SizedBox(height: 16.h),
                for (final d in domains) _DomainRow(code: d.$1, label: d.$2),
              ],
            ),
          ),
          SizedBox(height: 24.h),
          KeplerCard(
            child: Row(
              children: [
                Container(width: 3.w, height: 32.h, color: KeplerColors.of(context).primary),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.l10n.assessBeforeStartHeader,
                          style: AppText.of(context).monoLabel(color: KeplerColors.of(context).primary)),
                      SizedBox(height: 4.h),
                      Text(
                        context.l10n.assessBeforeStartBody,
                        style: AppText.of(context).bodySmall(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 28.h),
          // Un bilan en cours ? On propose de le POURSUIVRE, et recommencer
          // devient un choix explicite. Sans bilan en cours, l'écran ne change
          // pas d'un pixel : un bouton « Recommencer » permanent serait un
          // bouton sans objet.
          if (_reprise != null) ...[
            KeplerCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                      width: 3.w,
                      height: 36.h,
                      color: KeplerColors.of(context).primary),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.l10n.homeResumeEyebrow,
                            style: AppText.of(context).monoLabel(
                                color: KeplerColors.of(context).primary)),
                        SizedBox(height: 4.h),
                        Text(
                          context.l10n.homeResumeProgress(
                              _reprise!.completedCount, _reprise!.totalTests),
                          style: AppText.of(context).bodyStrong(),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          _reprise!.nextTestName == null
                              ? context.l10n.homeResumeFinish
                              : _reprise!.reprendEnPleinExercice
                                  ? context.l10n.homeResumeCurrent(
                                      _nomExercice(
                                          context, _reprise!.nextTestName!))
                                  : context.l10n.homeResumeNext(_nomExercice(
                                      context, _reprise!.nextTestName!)),
                          style: AppText.of(context).bodySmall(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),
            KeplerButton(
              label: context.l10n.ctResumeFullTest,
              icon: Icons.east,
              expand: true,
              onPressed: _reprendre,
            ),
            SizedBox(height: 12.h),
            KeplerButton(
              label: context.l10n.homeResumeRestart,
              variant: KeplerButtonVariant.secondary,
              expand: true,
              onPressed: _recommencer,
            ),
          ] else
            KeplerButton(
              label: context.l10n.assessLaunchFullAssessment,
              icon: Icons.east,
              expand: true,
              onPressed: _recherche ? null : _recommencer,
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
                child: Text(context.l10n.assessOrIndividualSubtest,
                    style: AppText.of(context).monoLabel()),
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
                  style: AppText.of(context).monoLabel(color: KeplerColors.of(context).primary))),
          Expanded(child: Text(label, style: AppText.of(context).body())),
        ],
      ),
    );
  }
}

class _IndividualTests extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tests = <(String, String, Widget Function())>[
      ('VSI', context.l10n.assessSubtestCubes, () => const CubesTestPage()),
      ('FRI', context.l10n.assessSubtestMatrices,
          () => const MatricesTestPage()),
      ('FRI', context.l10n.assessSubtestFigureWeights,
          () => const FigureWeightsTestPage()),
      ('VSI', context.l10n.assessSubtestVisualPuzzles,
          () => const VisualPuzzlesTestPage()),
      ('VCI', context.l10n.assessSubtestSimilarities,
          () => const SimilaritiesTestPage()),
      ('VCI', context.l10n.assessSubtestVocabulary,
          () => const VocabularyTestPage()),
      ('VCI', context.l10n.assessSubtestInformation,
          () => const InformationTestPage()),
      ('WMI', context.l10n.assessSubtestDigitSpan,
          () => const DigitSpanTestPage()),
      ('WMI', context.l10n.assessSubtestArithmetic,
          () => const ArithmeticTestPage()),
      ('WMI', context.l10n.assessSubtestPictureSpan,
          () => const PictureSpanTestPage()),
      ('PSI', context.l10n.assessSubtestCoding, () => const CodingTestPage()),
      ('PSI', context.l10n.assessSubtestSymbolSearch,
          () => const SymbolSearchTestPage()),
      ('LO', context.l10n.assessSubtestOralComprehension,
          () => const OralTestFlow()),
    ];
    return Column(
      children: [
        for (final t in tests) ...[
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
                        style: AppText.of(context).monoLabel(color: KeplerColors.of(context).primary))),
                Expanded(child: Text(t.$2, style: AppText.of(context).bodyStrong())),
                Icon(Icons.east, size: 16.sp, color: KeplerColors.of(context).primary),
              ],
            ),
          ),
          SizedBox(height: 10.h),
        ],
      ],
    );
  }
}
