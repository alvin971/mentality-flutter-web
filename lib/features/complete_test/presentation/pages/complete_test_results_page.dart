import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/kepler_colors.dart';
import '../../../../core/widgets/kepler_button.dart';
import '../../../../core/widgets/kepler_card.dart';
import '../../../../core/widgets/kepler_scaffold.dart';
import '../../../../core/models/complete_test_session.dart';
import '../../../../services/session_history_service.dart';
import '../../../scoring/domain/entities/iq_score.dart';
import '../../../scoring/domain/services/scoring_service.dart';
import '../../domain/services/pdf_report_service.dart';
import '../../../unlock/data/completion_reporter.dart';
import '../../../unlock/data/unlock_service.dart';
import '../../../unlock/presentation/pages/unlock_gate_page.dart';
import '../../../share_score/presentation/pages/score_share_preview_page.dart';
import '../../../../core/l10n/l10n_ext.dart';

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

  /// Gate marketing : tant que les paliers (parrainage + attente) ne sont
  /// pas franchis côté serveur, la page affiche UnlockGatePage à la place du
  /// résultat. Le score reste calculé et sauvegardé en historique (inchangé).
  bool _unlocked = !UnlockService.instance.gateEnabled;

  /// Le serveur a REFUSÉ la fin de test (session jugée non plausible) : il
  /// faut le dire, sinon l'utilisateur croit sa mission validée alors que son
  /// parrain ne sera jamais crédité.
  bool _completionRejected = false;

  /// La fin de test n'est pas encore confirmée (serveur injoignable) : on
  /// rejouera, mais l'utilisateur doit savoir que ce n'est pas acquis.
  bool _completionPending = false;

  /// Un déblocage DÉJÀ acquis par ce passe ne doit pas être re-demandé : sans
  /// cette relecture du cache, un utilisateur débloqué qui repasse un test se
  /// heurtait au mur d'erreur du gate dès que le worker était injoignable.
  Future<void> _honorCachedUnlock() async {
    if (_unlocked) return;
    final locked = await UnlockService.instance.isLocked();
    if (!locked && mounted) setState(() => _unlocked = true);
  }

  /// Code d'invitation à imprimer sur la carte de partage. `null` tant qu'il
  /// n'a pas été récupéré (worker injoignable, gate désactivé) — le bouton de
  /// partage reste alors masqué : une carte sans code ne sert à rien.
  String? _inviteCode;
  String? _inviteLink;

  Future<void> _loadInviteCode() async {
    if (!UnlockService.instance.gateEnabled) return;
    final p = await UnlockService.instance.getProgress();
    if (p == null || p.referralCode.isEmpty || !mounted) return;
    setState(() {
      _inviteCode = p.referralCode;
      _inviteLink = p.inviteLink;
    });
  }

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
    _retryPendingCompletion();
    _honorCachedUnlock();
    _loadInviteCode();
  }

  /// Rejoue la déclaration de fin de test si le serveur ne l'a pas encore
  /// confirmée.
  ///
  /// La déclaration elle-même n'a plus lieu ici : elle part désormais dès le
  /// dernier sous-test (orchestrateur), avant l'étape orale. Cet écran n'est
  /// plus qu'une occasion de plus de rattraper un envoi qui n'a pas abouti —
  /// il ne doit surtout pas redevenir le seul point d'émission.
  Future<void> _retryPendingCompletion() async {
    await CompletionReporter.instance.retryPending();
    if (!mounted) return;
    final refuse = await CompletionReporter.instance.wasRejected();
    final attente = await CompletionReporter.instance.hasPending();
    if (!mounted) return;
    setState(() {
      _completionRejected = refuse;
      _completionPending = attente;
    });
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
    if (!_unlocked) {
      return UnlockGatePage(
        onUnlocked: () {
          if (mounted) setState(() => _unlocked = true);
        },
      );
    }
    return KeplerScaffold(
      title: context.l10n.ctResultsTitle,
      eyebrow: context.l10n.ctResultsEyebrow,
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(),
          SizedBox(height: 24.h),
          // Fin de test non aboutie : le dire, même ici. Un résultat affiché
          // ne prouve pas que la complétion a été enregistrée côté serveur.
          if (_completionRejected || _completionPending) ...[
            _CompletionNotice(rejected: _completionRejected),
            SizedBox(height: 20.h),
          ],
          _SessionMeta(
            date: _formatDate(session.startTime),
            duration: _formatDuration(session.totalDuration),
            completed: '${session.completedTestsCount} / ${session.totalTests}',
            age: ageInMonths != null
                ? context.l10n.ctAgeYears((ageInMonths! / 12).floor())
                : null,
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
          _Actions(
            session: session,
            iq: _iqScore,
            ageInMonths: ageInMonths,
            inviteCode: _inviteCode,
            inviteLink: _inviteLink,
          ),
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

/// Fin de test refusée (session trop courte) ou pas encore confirmée.
class _CompletionNotice extends StatelessWidget {
  const _CompletionNotice({required this.rejected});
  final bool rejected;

  @override
  Widget build(BuildContext context) {
    final couleur = rejected
        ? KeplerColors.of(context).error
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return KeplerCard(
      surface: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(rejected ? Icons.error_outline : Icons.sync_problem_outlined,
              size: 18.sp, color: couleur),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              rejected
                  ? context.l10n.completionRejectedNotice
                  : context.l10n.completionPendingNotice,
              style: AppText.of(context).bodySmall(color: couleur),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.ctResultsHero1, style: AppText.of(context).heroDisplay()),
        Text(context.l10n.ctResultsHero2, style: AppText.of(context).heroItalic()),
        SizedBox(height: 12.h),
        Container(
            width: 36.w,
            height: 1,
            color: KeplerColors.of(context).primary.withValues(alpha: 0.4)),
        SizedBox(height: 12.h),
        Text(
          context.l10n.ctResultsSummary,
          style: AppText.of(context).body(),
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
          _row(context, context.l10n.ctMetaDate, date),
          _row(context, context.l10n.ctMetaDuration, duration),
          _row(context, context.l10n.ctMetaSubtests, completed),
          if (age != null) _row(context, context.l10n.ctMetaAge, age!),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppText.of(context).monoLabel(color: KeplerColors.of(context).textTertiary)),
          Text(value, style: AppText.of(context).bodyStrong()),
        ],
      ),
    );
  }
}

class _FSIQCard extends StatelessWidget {
  const _FSIQCard({required this.iq});
  final IQScore iq;

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
          Text(context.l10n.ctFsiqCardLabel,
              style: AppText.of(context).monoLabel(color: KeplerColors.of(context).primary)),
          SizedBox(height: 16.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${iq.fsiq}',
                  style: AppText.of(context).monoScore(
                      color: KeplerColors.of(context).primary, size: 80.sp)),
              SizedBox(width: 12.w),
              Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Text(classif, style: AppText.of(context).h2Italic()),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Container(
              width: 36.w,
              height: 1,
              color: KeplerColors.of(context).primary.withValues(alpha: 0.4)),
          SizedBox(height: 12.h),
          if (ci != null)
            Text(
                context.l10n
                    .ctConfidenceInterval95(ci.lowerBound, ci.upperBound),
                style: AppText.of(context).monoLabel(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          SizedBox(height: 4.h),
          Text(
              context.l10n.ctPercentileLabel(percentile),
              style: AppText.of(context).monoLabel(color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
      ('VCI', context.l10n.ctIndexVci, iq.vci),
      ('VSI', context.l10n.ctIndexVsi, iq.vsi),
      ('FRI', context.l10n.ctIndexFri, iq.fri),
      ('WMI', context.l10n.ctIndexWmi, iq.wmi),
      ('PSI', context.l10n.ctIndexPsi, iq.psi),
    ];

    return KeplerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.ctIndexProfileHeader,
              style: AppText.of(context).monoLabel(color: KeplerColors.of(context).primary)),
          SizedBox(height: 16.h),
          for (final e in indices) ...[
            if (e.$3 != null) _row(context, e.$1, e.$2, e.$3!, iq),
            if (e.$3 != null) SizedBox(height: 14.h),
          ],
        ],
      ),
    );
  }

  Widget _row(
      BuildContext context, String code, String label, int score, IQScore iq) {
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
                        style: AppText.of(context).monoLabel(color: KeplerColors.of(context).primary))),
                Text(label, style: AppText.of(context).bodyStrong()),
              ],
            ),
            Text('$score',
                style: AppText.of(context).monoScore(
                    color: KeplerColors.of(context).primary, size: 22.sp)),
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
            Text(classif, style: AppText.of(context).bodySmall()),
            Text(
              ci != null
                  ? context.l10n.ctIndexCiPercentile(
                      ci.lowerBound, ci.upperBound, percentile)
                  : context.l10n.ctIndexPercentile(percentile),
              style: AppText.of(context).monoLabel(color: KeplerColors.of(context).textTertiary),
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
        context.l10n.ctGroupVciVerbal,
        [
          (context.l10n.ctTestSimilarities, 'SI', session.similaritiesScore),
          (context.l10n.ctTestVocabulary, 'VO', session.vocabularyScore),
          (context.l10n.ctTestInformation, 'IN', session.informationScore),
        ]
      ),
      (
        context.l10n.ctGroupVsiVisuoSpatial,
        [
          (context.l10n.ctTestCubes, 'BD', session.cubesScore),
          (context.l10n.ctTestVisualPuzzles, 'VP', session.visualPuzzlesScore),
        ]
      ),
      (
        context.l10n.ctGroupFriReasoning,
        [
          (context.l10n.ctTestMatrices, 'MR', session.matricesScore),
          (context.l10n.ctTestFigureWeights, 'FW', session.figureWeightsScore),
        ]
      ),
      (
        context.l10n.ctGroupWmiMemory,
        [
          (context.l10n.ctTestDigitSpan, 'DS', session.digitSpanScore),
          (context.l10n.ctTestArithmetic, 'AR', session.arithmeticScore),
          (context.l10n.ctTestPictureSpan, 'PM', session.pictureSpanScore),
        ]
      ),
      (
        context.l10n.ctGroupPsiSpeed,
        [
          (context.l10n.ctTestCoding, 'CD', session.codingScore),
          (context.l10n.ctTestSymbolSearch, 'SS', session.symbolSearchScore),
        ]
      ),
    ];

    return KeplerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.ctStandardizedScoresHeader,
              style: AppText.of(context).monoLabel(color: KeplerColors.of(context).primary)),
          SizedBox(height: 16.h),
          for (var i = 0; i < groups.length; i++) ...[
            Text(groups[i].$1, style: AppText.of(context).bodyStrong()),
            SizedBox(height: 8.h),
            for (final s in groups[i].$2)
              if (s.$3 != null)
                _subRow(context, s.$1, s.$2, s.$3!, iq),
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

  Widget _subRow(
      BuildContext context, String name, String code, int raw, IQScore iq) {
    final scaled = iq.percentiles[code];
    final classif = iq.classifications[code] ?? '';
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          Expanded(
              flex: 3,
              child: Text(name,
                  style: AppText.of(context).body(color: KeplerColors.of(context).textPrimary))),
          Text(context.l10n.ctRawScore(raw),
              style: AppText.of(context).monoLabel(color: KeplerColors.of(context).textTertiary)),
          SizedBox(width: 12.w),
          Container(
            width: 36.w,
            height: 28.h,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: KeplerColors.of(context).primary.withValues(alpha: 0.08),
              border: Border.all(
                  color: KeplerColors.of(context).primary.withValues(alpha: 0.4)),
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: Text('${scaled ?? '-'}',
                style: AppText.of(context).monoScore(
                    color: KeplerColors.of(context).primary, size: 14.sp)),
          ),
          SizedBox(width: 10.w),
          Expanded(
            flex: 2,
            child: Text(classif,
                style: AppText.of(context).bodySmall(color: KeplerColors.of(context).textTertiary),
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

  String _indexLabel(BuildContext context, String code) {
    switch (code) {
      case 'VCI':
        return context.l10n.ctIndexVci;
      case 'VSI':
        return context.l10n.ctIndexVsi;
      case 'FRI':
        return context.l10n.ctIndexFri;
      case 'WMI':
        return context.l10n.ctIndexWmi;
      case 'PSI':
        return context.l10n.ctIndexPsi;
      default:
        return code;
    }
  }

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
          Text(context.l10n.ctCognitiveProfileHeader,
              style: AppText.of(context).monoLabel(color: KeplerColors.of(context).primary)),
          SizedBox(height: 12.h),
          Text(
            homogeneous
                ? context.l10n.ctProfileHomogeneous
                : context.l10n.ctProfileHeterogeneous,
            style: AppText.of(context).body(),
          ),
          SizedBox(height: 4.h),
          Text(context.l10n.ctMaxDiscrepancy(iq.maxIndexDiscrepancy),
              style: AppText.of(context).monoLabel(color: Theme.of(context).colorScheme.outline)),
          if (strengths.isNotEmpty) ...[
            SizedBox(height: 16.h),
            Text(context.l10n.ctRelativeStrengths,
                style: AppText.of(context).bodyStrong(color: KeplerColors.of(context).success)),
            SizedBox(height: 6.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 6.h,
              children: strengths
                  .map((c) =>
                      _chip(context, _indexLabel(context, c), KeplerColors.of(context).success))
                  .toList(),
            ),
          ],
          if (weaknesses.isNotEmpty) ...[
            SizedBox(height: 16.h),
            Text(context.l10n.ctVigilancePoints,
                style: AppText.of(context).bodyStrong(color: KeplerColors.of(context).warning)),
            SizedBox(height: 6.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 6.h,
              children: weaknesses
                  .map((c) =>
                      _chip(context, _indexLabel(context, c), KeplerColors.of(context).warning))
                  .toList(),
            ),
          ],
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              border: Border.all(
                  color: KeplerColors.of(context).primary.withValues(alpha: 0.2)),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Text(
              context.l10n.ctIndicativeDisclaimer,
              style: AppText.of(context).bodySmall(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, String label, Color c) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        border: Border.all(color: c.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(label, style: AppText.of(context).bodySmall(color: c)),
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
          Text(context.l10n.ctRawScoresHeader,
              style: AppText.of(context).monoLabel(color: KeplerColors.of(context).primary)),
          SizedBox(height: 16.h),
          _row(context, context.l10n.ctTestSimilarities, session.similaritiesScore),
          _row(context, context.l10n.ctTestVocabulary, session.vocabularyScore),
          _row(context, context.l10n.ctTestInformation, session.informationScore),
          _row(context, context.l10n.ctTestCubes, session.cubesScore),
          _row(context, context.l10n.ctTestMatrices, session.matricesScore),
          _row(context, context.l10n.ctTestVisualPuzzles, session.visualPuzzlesScore),
          _row(context, context.l10n.ctTestDigitSpan, session.digitSpanScore),
          _row(context, context.l10n.ctTestArithmetic, session.arithmeticScore),
          _row(context, context.l10n.ctTestPictureSpan, session.pictureSpanScore),
          _row(context, context.l10n.ctTestCoding, session.codingScore),
          _row(context, context.l10n.ctTestSymbolSearch, session.symbolSearchScore),
          _row(context, context.l10n.ctTestFigureWeights, session.figureWeightsScore),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String name, int? score) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: AppText.of(context).body()),
          Text(score?.toString() ?? '—',
              style: AppText.of(context).monoScore(size: 18.sp)),
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
          Container(width: 3.w, height: 36.h, color: KeplerColors.of(context).warning),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.ctMissingAgeHeader,
                    style: AppText.of(context).monoLabel(color: KeplerColors.of(context).warning)),
                SizedBox(height: 6.h),
                Text(
                  context.l10n.ctMissingAgeBody,
                  style: AppText.of(context).bodySmall(),
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
  const _Actions({
    required this.session,
    required this.iq,
    required this.ageInMonths,
    this.inviteCode,
    this.inviteLink,
  });
  final CompleteTestSession session;
  final IQScore? iq;
  final int? ageInMonths;
  final String? inviteCode;
  final String? inviteLink;

  @override
  Widget build(BuildContext context) {
    final iqScore = iq;
    final code = inviteCode;
    final link = inviteLink;
    // Le partage suppose un score ET un code d'invitation : sans l'un ou
    // l'autre la carte n'aurait rien à montrer. La page entière n'est de toute
    // façon atteignable qu'une fois les résultats débloqués.
    final canShare = iqScore != null && code != null && link != null;

    return Column(
      children: [
        if (canShare) ...[
          KeplerButton(
            label: context.l10n.ctShareScore,
            icon: Icons.ios_share,
            expand: true,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ScoreSharePreviewPage(
                  iq: iqScore.fsiq,
                  percentile: iqScore.percentiles['FSIQ'] ?? 50,
                  classification: iqScore.classifications['FSIQ'] ?? '',
                  inviteCode: code,
                  inviteLink: link,
                ),
              ),
            ),
          ),
          SizedBox(height: 12.h),
        ],
        KeplerButton(
          label: context.l10n.ctExportPdf,
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
                  SnackBar(content: Text(context.l10n.ctPdfError('$e'))),
                );
              }
            }
          },
        ),
        SizedBox(height: 12.h),
        KeplerButton(
          label: context.l10n.ctBackToHome,
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
