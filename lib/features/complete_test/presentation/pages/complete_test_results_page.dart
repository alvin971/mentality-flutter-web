import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/kepler_button.dart';
import '../../../../core/widgets/kepler_card.dart';
import '../../../../core/widgets/kepler_scaffold.dart';
import '../../../../core/models/complete_test_session.dart';
import '../../../../services/session_history_service.dart';
import '../../../scoring/domain/entities/iq_score.dart';
import '../../../scoring/domain/services/scoring_service.dart';
import '../../domain/services/pdf_report_service.dart';

class CompleteTestResultsPage extends StatefulWidget {
  final CompleteTestSession session;
  final int? ageInMonths;

  const CompleteTestResultsPage({
    super.key,
    required this.session,
    this.ageInMonths,
  });

  @override
  State<CompleteTestResultsPage> createState() =>
      _CompleteTestResultsPageState();
}

class _CompleteTestResultsPageState extends State<CompleteTestResultsPage> {
  late final IQScore? _iqScore;

  @override
  void initState() {
    super.initState();
    try {
      _iqScore = widget.ageInMonths != null
          ? const ScoringService()
              .computeScore(widget.session, widget.ageInMonths!)
          : null;
    } catch (_) {
      _iqScore = null;
    }
    _saveToHistory();
  }

  Future<void> _saveToHistory() async {
    if (_iqScore == null) return;
    final entry = SessionHistoryEntry(
      id: const Uuid().v4(),
      date: widget.session.startTime,
      ageInMonths: widget.ageInMonths!,
      fsiq: _iqScore.fsiq,
      vci: _iqScore.vci,
      vsi: _iqScore.vsi,
      fri: _iqScore.fri,
      wmi: _iqScore.wmi,
      psi: _iqScore.psi,
      classification: _iqScore.fsiqClassification,
    );
    await SessionHistoryService.instance.saveEntry(entry);
  }

  CompleteTestSession get session => widget.session;
  int? get ageInMonths => widget.ageInMonths;

  @override
  Widget build(BuildContext context) {
    return KeplerScaffold(
      title: 'Résultats',
      eyebrow: 'BILAN WAIS-IV',
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(),
          SizedBox(height: 24.h),
          _SessionMeta(
            date: _formatDate(session.startTime),
            duration: _formatDuration(session.totalDuration),
            completed: '${session.completedTestsCount} / ${session.totalTests}',
            age:
                ageInMonths != null ? '${(ageInMonths! / 12).floor()} ans' : null,
          ),
          SizedBox(height: 24.h),
          if (_iqScore != null) ...[
            _FSIQCard(iq: _iqScore),
            SizedBox(height: 20.h),
            _IndexProfile(iq: _iqScore),
            SizedBox(height: 20.h),
            _SubtestDetails(iq: _iqScore, session: session),
            SizedBox(height: 20.h),
            _StrengthsWeaknesses(iq: _iqScore),
          ] else ...[
            _RawFallback(session: session),
            SizedBox(height: 16.h),
            _NoScoreNotice(),
          ],
          SizedBox(height: 28.h),
          _Actions(session: session, iq: _iqScore, ageInMonths: ageInMonths),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year} · '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration? d) {
    if (d == null) return 'N/A';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m}min ${s}s';
    if (m > 0) return '${m}min ${s}s';
    return '${s}s';
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bilan', style: AppText.heroDisplay()),
        Text('terminé.', style: AppText.heroItalic()),
        SizedBox(height: 12.h),
        Container(
            width: 36.w,
            height: 1,
            color: AppColors.primary.withValues(alpha: 0.4)),
        SizedBox(height: 12.h),
        Text(
          'Synthèse de vos performances cognitives sur les douze subtests WAIS-IV.',
          style: AppText.body(),
        ),
      ],
    );
  }
}

class _SessionMeta extends StatelessWidget {
  const _SessionMeta(
      {required this.date,
      required this.duration,
      required this.completed,
      this.age});
  final String date;
  final String duration;
  final String completed;
  final String? age;

  @override
  Widget build(BuildContext context) {
    return KeplerCard(
      surface: true,
      child: Column(
        children: [
          _row('DATE', date),
          _row('DURÉE', duration),
          _row('SUBTESTS', completed),
          if (age != null) _row('ÂGE', age!),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppText.monoLabel(color: AppColors.textTertiary)),
          Text(value, style: AppText.bodyStrong()),
        ],
      ),
    );
  }
}

class _FSIQCard extends StatelessWidget {
  const _FSIQCard({required this.iq});
  final IQScore iq;

  String _ordinal(int n) => n == 1 ? 'er' : 'e';

  @override
  Widget build(BuildContext context) {
    final ci = iq.confidenceIntervals['FSIQ'];
    final percentile = iq.percentiles['FSIQ'] ?? 50;
    final classif = iq.classifications['FSIQ'] ?? '';

    return KeplerCard(
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('QI TOTAL · FSIQ',
              style: AppText.monoLabel(color: AppColors.primary)),
          SizedBox(height: 16.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${iq.fsiq}',
                  style: AppText.monoScore(
                      color: AppColors.primary, size: 80.sp)),
              SizedBox(width: 12.w),
              Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Text(classif, style: AppText.h2Italic()),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Container(
              width: 36.w,
              height: 1,
              color: AppColors.primary.withValues(alpha: 0.4)),
          SizedBox(height: 12.h),
          if (ci != null)
            Text('IC 95% · ${ci.lowerBound} – ${ci.upperBound}',
                style: AppText.monoLabel(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          SizedBox(height: 4.h),
          Text(
              'Percentile · $percentile${_ordinal(percentile)}',
              style: AppText.monoLabel(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _IndexProfile extends StatelessWidget {
  const _IndexProfile({required this.iq});
  final IQScore iq;

  @override
  Widget build(BuildContext context) {
    final indices = <(String, String, int?)>[
      ('VCI', 'Compréhension Verbale', iq.vci),
      ('VSI', 'Visuo-Spatial', iq.vsi),
      ('FRI', 'Raisonnement Fluide', iq.fri),
      ('WMI', 'Mémoire de Travail', iq.wmi),
      ('PSI', 'Vitesse de Traitement', iq.psi),
    ];

    return KeplerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PROFIL DES INDICES',
              style: AppText.monoLabel(color: AppColors.primary)),
          SizedBox(height: 16.h),
          for (final e in indices) ...[
            if (e.$3 != null) _row(e.$1, e.$2, e.$3!, iq),
            if (e.$3 != null) SizedBox(height: 14.h),
          ],
        ],
      ),
    );
  }

  Widget _row(String code, String label, int score, IQScore iq) {
    final ci = iq.confidenceIntervals[code];
    final percentile = iq.percentiles[code] ?? 50;
    final classif = iq.classifications[code] ?? '';
    final bar = ((score - 40) / 120).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                SizedBox(
                    width: 44.w,
                    child: Text(code,
                        style: AppText.monoLabel(color: AppColors.primary))),
                Text(label, style: AppText.bodyStrong()),
              ],
            ),
            Text('$score',
                style: AppText.monoScore(
                    color: AppColors.primary, size: 22.sp)),
          ],
        ),
        SizedBox(height: 6.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(2.r),
          child: LinearProgressIndicator(
            value: bar,
            minHeight: 4.h,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
        SizedBox(height: 6.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(classif, style: AppText.bodySmall()),
            Text(
              ci != null
                  ? 'IC ${ci.lowerBound}–${ci.upperBound} · ${percentile}e %ile'
                  : '${percentile}e %ile',
              style: AppText.monoLabel(color: AppColors.textTertiary),
            ),
          ],
        ),
      ],
    );
  }
}

class _SubtestDetails extends StatelessWidget {
  const _SubtestDetails({required this.iq, required this.session});
  final IQScore iq;
  final CompleteTestSession session;

  @override
  Widget build(BuildContext context) {
    final groups = [
      (
        'VCI · Verbal',
        [
          ('Similitudes', 'SI', session.similaritiesScore),
          ('Vocabulaire', 'VO', session.vocabularyScore),
          ('Information', 'IN', session.informationScore),
        ]
      ),
      (
        'VSI · Visuo-Spatial',
        [
          ('Cubes', 'BD', session.cubesScore),
          ('Puzzles Visuels', 'VP', session.visualPuzzlesScore),
        ]
      ),
      (
        'FRI · Raisonnement',
        [
          ('Matrices', 'MR', session.matricesScore),
          ('Balances', 'FW', session.figureWeightsScore),
        ]
      ),
      (
        'WMI · Mémoire',
        [
          ('Mémoire des Chiffres', 'DS', session.digitSpanScore),
          ('Arithmétique', 'AR', session.arithmeticScore),
          ('Mémoire des Images', 'PM', session.pictureSpanScore),
        ]
      ),
      (
        'PSI · Vitesse',
        [
          ('Code', 'CD', session.codingScore),
          ('Recherche de Symboles', 'SS', session.symbolSearchScore),
        ]
      ),
    ];

    return KeplerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('NOTES STANDARDISÉES',
              style: AppText.monoLabel(color: AppColors.primary)),
          SizedBox(height: 16.h),
          for (var i = 0; i < groups.length; i++) ...[
            Text(groups[i].$1, style: AppText.bodyStrong()),
            SizedBox(height: 8.h),
            for (final s in groups[i].$2)
              if (s.$3 != null)
                _subRow(s.$1, s.$2, s.$3!, iq),
            if (i < groups.length - 1) ...[
              SizedBox(height: 14.h),
              Container(
                  height: 1, color: Colors.black.withValues(alpha: 0.06)),
              SizedBox(height: 14.h),
            ],
          ],
        ],
      ),
    );
  }

  Widget _subRow(String name, String code, int raw, IQScore iq) {
    final scaled = iq.percentiles[code];
    final classif = iq.classifications[code] ?? '';
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          Expanded(
              flex: 3,
              child: Text(name,
                  style: AppText.body(color: AppColors.textPrimary))),
          Text('brut $raw',
              style: AppText.monoLabel(color: AppColors.textTertiary)),
          SizedBox(width: 12.w),
          Container(
            width: 36.w,
            height: 28.h,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.4)),
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: Text('${scaled ?? '-'}',
                style: AppText.monoScore(
                    color: AppColors.primary, size: 14.sp)),
          ),
          SizedBox(width: 10.w),
          Expanded(
            flex: 2,
            child: Text(classif,
                style: AppText.bodySmall(color: AppColors.textTertiary),
                textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}

class _StrengthsWeaknesses extends StatelessWidget {
  const _StrengthsWeaknesses({required this.iq});
  final IQScore iq;

  static const _labels = {
    'VCI': 'Compréhension Verbale',
    'VSI': 'Visuo-Spatial',
    'FRI': 'Raisonnement Fluide',
    'WMI': 'Mémoire de Travail',
    'PSI': 'Vitesse de Traitement',
  };

  @override
  Widget build(BuildContext context) {
    final strengths = iq.strengths;
    final weaknesses = iq.weaknesses;
    final homogeneous = iq.isHomogeneousProfile;

    return KeplerCard(
      surface: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PROFIL COGNITIF',
              style: AppText.monoLabel(color: AppColors.primary)),
          SizedBox(height: 12.h),
          Text(
            homogeneous
                ? 'Profil homogène — les indices sont cohérents entre eux.'
                : 'Profil hétérogène — disparités notables entre indices.',
            style: AppText.body(),
          ),
          SizedBox(height: 4.h),
          Text('Écart max · ${iq.maxIndexDiscrepancy} pts',
              style: AppText.monoLabel(color: Theme.of(context).colorScheme.outline)),
          if (strengths.isNotEmpty) ...[
            SizedBox(height: 16.h),
            Text('Forces relatives',
                style: AppText.bodyStrong(color: AppColors.success)),
            SizedBox(height: 6.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 6.h,
              children: strengths
                  .map((c) => _chip(_labels[c] ?? c, AppColors.success))
                  .toList(),
            ),
          ],
          if (weaknesses.isNotEmpty) ...[
            SizedBox(height: 16.h),
            Text('Points de vigilance',
                style: AppText.bodyStrong(color: AppColors.warning)),
            SizedBox(height: 6.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 6.h,
              children: weaknesses
                  .map((c) => _chip(_labels[c] ?? c, AppColors.warning))
                  .toList(),
            ),
          ],
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2)),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Text(
              'Résultats indicatifs. Pour une évaluation clinique officielle, '
              'consultez un neuropsychologue ou un psychologue qualifié.',
              style: AppText.bodySmall(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color c) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        border: Border.all(color: c.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(label, style: AppText.bodySmall(color: c)),
    );
  }
}

class _RawFallback extends StatelessWidget {
  const _RawFallback({required this.session});
  final CompleteTestSession session;

  @override
  Widget build(BuildContext context) {
    return KeplerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SCORES BRUTS',
              style: AppText.monoLabel(color: AppColors.primary)),
          SizedBox(height: 16.h),
          _row('Similitudes', session.similaritiesScore),
          _row('Vocabulaire', session.vocabularyScore),
          _row('Information', session.informationScore),
          _row('Cubes', session.cubesScore),
          _row('Matrices', session.matricesScore),
          _row('Puzzles Visuels', session.visualPuzzlesScore),
          _row('Mémoire des Chiffres', session.digitSpanScore),
          _row('Arithmétique', session.arithmeticScore),
          _row('Mémoire des Images', session.pictureSpanScore),
          _row('Code', session.codingScore),
          _row('Recherche de Symboles', session.symbolSearchScore),
          _row('Balances', session.figureWeightsScore),
        ],
      ),
    );
  }

  Widget _row(String name, int? score) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: AppText.body()),
          Text(score?.toString() ?? '—',
              style: AppText.monoScore(size: 18.sp)),
        ],
      ),
    );
  }
}

class _NoScoreNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return KeplerCard(
      surface: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 3.w, height: 36.h, color: AppColors.warning),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ÂGE MANQUANT',
                    style: AppText.monoLabel(color: AppColors.warning)),
                SizedBox(height: 6.h),
                Text(
                  'Sans l\'âge du patient, seuls les scores bruts sont affichés. '
                  'Relancez le test en renseignant l\'âge pour obtenir le QI standardisé, '
                  'les percentiles et les intervalles de confiance.',
                  style: AppText.bodySmall(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions(
      {required this.session, required this.iq, required this.ageInMonths});
  final CompleteTestSession session;
  final IQScore? iq;
  final int? ageInMonths;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        KeplerButton(
          label: 'Exporter en PDF',
          icon: Icons.picture_as_pdf_outlined,
          expand: true,
          onPressed: () async {
            try {
              await const PdfReportService().generateAndPrint(
                session: session,
                iqScore: iq,
                ageInMonths: ageInMonths,
              );
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur PDF : $e')),
                );
              }
            }
          },
        ),
        SizedBox(height: 12.h),
        KeplerButton(
          label: 'Retour à l\'accueil',
          variant: KeplerButtonVariant.secondary,
          icon: Icons.home_outlined,
          expand: true,
          onPressed: () =>
              Navigator.popUntil(context, (route) => route.isFirst),
        ),
      ],
    );
  }
}
