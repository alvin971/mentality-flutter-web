import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/kepler_button.dart';
import '../../../../core/widgets/kepler_card.dart';
import '../../../../core/widgets/kepler_scaffold.dart';
import '../../../../services/session_history_service.dart';
import '../../../../core/l10n/l10n_ext.dart';
import '../../../unlock/data/unlock_service.dart';
import '../../../unlock/presentation/pages/unlock_gate_page.dart';

class ResultsHistoryPage extends StatefulWidget {
  const ResultsHistoryPage({super.key});

  @override
  State<ResultsHistoryPage> createState() => _ResultsHistoryPageState();
}

class _ResultsHistoryPageState extends State<ResultsHistoryPage> {
  /// Résultats DU PASSE COURANT uniquement (jamais ceux d'un autre passe ayant
  /// utilisé le même téléphone). Vide tant que le chargement n'a pas répondu.
  List<SessionHistoryEntry> _entries = const [];
  bool _loadingEntries = true;

  /// Gate marketing : tant que les missions (parrainage + Instagram) ne sont
  /// pas toutes validées côté serveur, les scores restent FLOUTÉS et les
  /// cartes ouvrent les missions au lieu du détail. Fail-closed : verrouillé
  /// par défaut dès que le gate est actif, déverrouillé seulement sur
  /// confirmation (serveur ou cache local d'un déblocage déjà acquis).
  bool _locked = UnlockService.instance.gateEnabled;

  @override
  void initState() {
    super.initState();
    _loadEntries();
    _refreshLock();
  }

  Future<void> _loadEntries() async {
    final entries =
        await SessionHistoryService.instance.getAllForCurrentAccount();
    if (!mounted) return;
    setState(() {
      _entries = entries;
      _loadingEntries = false;
    });
  }

  Future<void> _refreshLock() async {
    if (!_locked) return;
    final locked = await UnlockService.instance.isLocked();
    if (mounted && locked != _locked) setState(() => _locked = locked);
  }

  /// Ouvre l'écran des missions ; se referme tout seul au déblocage.
  Future<void> _openMissions() async {
    var popped = false;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (gateCtx) => UnlockGatePage(
          onUnlocked: () {
            if (popped) return;
            popped = true;
            Navigator.of(gateCtx).pop();
          },
        ),
      ),
    );
    if (mounted) await _refreshLock();
  }

  Future<void> _deleteEntry(SessionHistoryEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r)),
        title: Text(context.l10n.histDeleteResultTitle, style: AppText.h3()),
        content:
            Text(context.l10n.histDeleteResultBody, style: AppText.body()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.commonCancel,
                style: AppText.bodySmall(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.histDelete,
                style: AppText.bodySmall(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await SessionHistoryService.instance.deleteEntry(entry.id);
      await _loadEntries();
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeplerScaffold(
      title: context.l10n.histTitle,
      eyebrow: context.l10n.histEyebrow,
      scroll: false,
      padding: EdgeInsets.zero,
      child: _loadingEntries
          // Sans cet état, l'écran « aucun résultat » clignoterait le temps de
          // lire l'historique du passe courant.
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? _EmptyState(onStart: () => Navigator.pop(context))
              : ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              // Une carte « missions » en tête de liste tant que verrouillé.
              itemCount: _entries.length + (_locked ? 1 : 0),
              separatorBuilder: (_, __) => SizedBox(height: 12.h),
              itemBuilder: (_, i) {
                if (_locked && i == 0) {
                  return _MissionsBanner(onOpen: _openMissions);
                }
                final entry = _entries[_locked ? i - 1 : i];
                return _EntryCard(
                  entry: entry,
                  locked: _locked,
                  onTap: () =>
                      _locked ? _openMissions() : _showDetail(entry),
                  onDelete: () => _deleteEntry(entry),
                );
              },
            ),
    );
  }

  void _showDetail(SessionHistoryEntry e) {
    final age = (e.ageInMonths / 12).floor();
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 36.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                  width: 40.w,
                  height: 3.h,
                  color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            SizedBox(height: 20.h),
            Text(_formatDate(e.date).toUpperCase(),
                style: AppText.monoLabel(color: AppColors.primary)),
            SizedBox(height: 8.h),
            Text(e.classification, style: AppText.h1Italic()),
            SizedBox(height: 6.h),
            Text(context.l10n.histAgeYears(age), style: AppText.bodySmall()),
            SizedBox(height: 24.h),
            _ScoreRow(
                label: context.l10n.histScoreFsiq,
                value: e.fsiq,
                highlight: true),
            if (e.vci != null)
              _ScoreRow(label: context.l10n.histScoreVci, value: e.vci!),
            if (e.vsi != null)
              _ScoreRow(label: context.l10n.histScoreVsi, value: e.vsi!),
            if (e.fri != null)
              _ScoreRow(label: context.l10n.histScoreFri, value: e.fri!),
            if (e.wmi != null)
              _ScoreRow(label: context.l10n.histScoreWmi, value: e.wmi!),
            if (e.psi != null)
              _ScoreRow(label: context.l10n.histScorePsi, value: e.psi!),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}

class _EntryCard extends StatelessWidget {
  const _EntryCard(
      {required this.entry,
      required this.locked,
      required this.onTap,
      required this.onDelete});
  final SessionHistoryEntry entry;

  /// Scores floutés + cadenas tant que les missions ne sont pas validées.
  final bool locked;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  /// Floute le contenu (le score reste deviné, jamais lisible).
  Widget _blur(Widget child) => ClipRect(
        child: ImageFiltered(
          imageFilter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: child,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final age = (entry.ageInMonths / 12).floor();
    final fsiq = Text('${entry.fsiq}',
        style: AppText.monoScore(color: AppColors.primary, size: 26.sp));
    final classification =
        Text(entry.classification, style: AppText.bodyStrong());
    return KeplerCard(
      onTap: onTap,
      child: Row(
        children: [
          SizedBox(
            width: 64.w,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('FSIQ',
                        style: AppText.monoLabel(
                            color: Theme.of(context).colorScheme.outline)),
                    if (locked) ...[
                      SizedBox(width: 4.w),
                      Icon(Icons.lock_outline,
                          size: 12.sp, color: AppColors.primary),
                    ],
                  ],
                ),
                SizedBox(height: 4.h),
                locked ? _blur(fsiq) : fsiq,
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                locked ? _blur(classification) : classification,
                SizedBox(height: 2.h),
                Text('${_formatDate(entry.date)} · ${context.l10n.histAgeYears(age)}',
                    style: AppText.bodySmall()),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline,
                color: Theme.of(context).colorScheme.outline, size: 18.sp),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

/// Carte en tête de « Mes résultats » tant que les missions ne sont pas
/// toutes validées : rappelle pourquoi le résultat est flouté et ouvre le
/// parcours de déblocage (lien d'invitation, progression, Instagram).
class _MissionsBanner extends StatelessWidget {
  const _MissionsBanner({required this.onOpen});
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return KeplerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_outline, size: 18.sp, color: AppColors.primary),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(context.l10n.histLockedTitle,
                    style: AppText.bodyStrong()),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(context.l10n.histLockedBody, style: AppText.bodySmall()),
          SizedBox(height: 12.h),
          KeplerButton(
            label: context.l10n.histLockedCta,
            icon: Icons.east,
            expand: true,
            onPressed: onOpen,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.histEmptyEyebrow,
                style: AppText.monoLabel(color: AppColors.primary)),
            SizedBox(height: 12.h),
            Text(context.l10n.histEmptyHero1, style: AppText.heroDisplay()),
            Text(context.l10n.histEmptyHero2, style: AppText.heroItalic()),
            SizedBox(height: 16.h),
            Text(
              context.l10n.histEmptyDescription,
              style: AppText.body(),
            ),
            SizedBox(height: 28.h),
            KeplerButton(
                label: context.l10n.histStartAssessment,
                icon: Icons.east,
                onPressed: onStart),
          ],
        ),
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow(
      {required this.label, required this.value, this.highlight = false});
  final String label;
  final int value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: highlight ? AppText.bodyStrong() : AppText.body()),
          ),
          Text(
            value.toString(),
            style: AppText.monoScore(
              color: highlight
                  ? AppColors.primary
                  : Theme.of(context).colorScheme.onSurface,
              size: highlight ? 22.sp : 18.sp,
            ),
          ),
        ],
      ),
    );
  }
}
