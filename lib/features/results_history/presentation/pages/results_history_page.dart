import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/kepler_colors.dart';
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

class _ResultsHistoryPageState extends State<ResultsHistoryPage>
    with WidgetsBindingObserver {
  /// Résultats DU PASSE COURANT uniquement (jamais ceux d'un autre passe ayant
  /// utilisé le même téléphone). Vide tant que le chargement n'a pas répondu.
  List<SessionHistoryEntry> _entries = const [];
  bool _loadingEntries = true;

  /// Gate marketing : tant que les missions (parrainage + attente) ne sont
  /// pas toutes validées côté serveur, les scores restent FLOUTÉS et les
  /// cartes ouvrent les missions au lieu du détail. Fail-closed : verrouillé
  /// par défaut dès que le gate est actif, déverrouillé seulement sur
  /// confirmation (serveur ou cache local d'un déblocage déjà acquis).
  bool _locked = UnlockService.instance.gateEnabled;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadEntries();
    _refreshLock();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Le déblocage se produit côté serveur (délai d'attente, filleuls qui
  /// terminent). Sans cette relecture au retour au premier plan, les scores
  /// restaient floutés jusqu'à la réouverture manuelle de la page.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshLock();
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
        title: Text(context.l10n.histDeleteResultTitle, style: AppText.of(context).h3()),
        content:
            Text(context.l10n.histDeleteResultBody, style: AppText.of(context).body()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.commonCancel,
                style: AppText.of(context).bodySmall(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.histDelete,
                style: AppText.of(context).bodySmall(color: KeplerColors.of(context).error)),
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
          // Verrouillé ⇒ toujours la liste, même sans résultat : c'est le seul
          // accès aux missions et au lien d'invitation. L'écran « aucun
          // résultat » n'est montré que si rien n'est verrouillé.
          : (_entries.isEmpty && !_locked)
              ? _EmptyState(onStart: () => Navigator.pop(context))
              : ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              // Une carte « missions » en tête de liste tant que verrouillé.
              itemCount: _entries.length + (_locked ? 1 : 0),
              separatorBuilder: (_, __) => SizedBox(height: 12.h),
              itemBuilder: (_, i) {
                if (_locked && i == 0) {
                  return _MissionsBanner(
                    onOpen: _openMissions,
                    hasResults: _entries.isNotEmpty,
                  );
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
                  color: KeplerColors.of(context).primary.withValues(alpha: 0.3)),
            ),
            SizedBox(height: 20.h),
            Text(_formatDate(e.date).toUpperCase(),
                style: AppText.of(context).monoLabel(color: KeplerColors.of(context).primary)),
            SizedBox(height: 8.h),
            Text(e.classification, style: AppText.of(context).h1Italic()),
            SizedBox(height: 6.h),
            Text(context.l10n.histAgeYears(age), style: AppText.of(context).bodySmall()),
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
        style: AppText.of(context).monoScore(color: KeplerColors.of(context).primary, size: 26.sp));
    final classification =
        Text(entry.classification, style: AppText.of(context).bodyStrong());
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
                        style: AppText.of(context).monoLabel(
                            color: Theme.of(context).colorScheme.outline)),
                    if (locked) ...[
                      SizedBox(width: 4.w),
                      Icon(Icons.lock_outline,
                          size: 12.sp, color: KeplerColors.of(context).primary),
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
                    style: AppText.of(context).bodySmall()),
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
/// parcours de déblocage (lien d'invitation, progression, attente).
class _MissionsBanner extends StatelessWidget {
  const _MissionsBanner({required this.onOpen, required this.hasResults});
  final VoidCallback onOpen;

  /// Adapte le texte : parler d'un « résultat enregistré » serait faux quand
  /// le passe courant n'a encore aucun résultat.
  final bool hasResults;

  @override
  Widget build(BuildContext context) {
    return KeplerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_outline, size: 18.sp, color: KeplerColors.of(context).primary),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(context.l10n.histLockedTitle,
                    style: AppText.of(context).bodyStrong()),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            hasResults
                ? context.l10n.histLockedBody
                : context.l10n.histLockedBodyNoResult,
            style: AppText.of(context).bodySmall(),
          ),
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
                style: AppText.of(context).monoLabel(color: KeplerColors.of(context).primary)),
            SizedBox(height: 12.h),
            Text(context.l10n.histEmptyHero1, style: AppText.of(context).heroDisplay()),
            Text(context.l10n.histEmptyHero2, style: AppText.of(context).heroItalic()),
            SizedBox(height: 16.h),
            Text(
              context.l10n.histEmptyDescription,
              style: AppText.of(context).body(),
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
                style: highlight ? AppText.of(context).bodyStrong() : AppText.of(context).body()),
          ),
          Text(
            value.toString(),
            style: AppText.of(context).monoScore(
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
