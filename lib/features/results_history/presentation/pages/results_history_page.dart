import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/kepler_button.dart';
import '../../../../core/widgets/kepler_card.dart';
import '../../../../core/widgets/kepler_scaffold.dart';
import '../../../../services/session_history_service.dart';
import '../../../../core/l10n/l10n_ext.dart';

class ResultsHistoryPage extends StatefulWidget {
  const ResultsHistoryPage({super.key});

  @override
  State<ResultsHistoryPage> createState() => _ResultsHistoryPageState();
}

class _ResultsHistoryPageState extends State<ResultsHistoryPage> {
  late List<SessionHistoryEntry> _entries;

  @override
  void initState() {
    super.initState();
    _entries = SessionHistoryService.instance.getAll();
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
      setState(() => _entries = SessionHistoryService.instance.getAll());
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeplerScaffold(
      title: context.l10n.histTitle,
      eyebrow: context.l10n.histEyebrow,
      scroll: false,
      padding: EdgeInsets.zero,
      child: _entries.isEmpty
          ? _EmptyState(onStart: () => Navigator.pop(context))
          : ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              itemCount: _entries.length,
              separatorBuilder: (_, __) => SizedBox(height: 12.h),
              itemBuilder: (_, i) => _EntryCard(
                entry: _entries[i],
                onTap: () => _showDetail(_entries[i]),
                onDelete: () => _deleteEntry(_entries[i]),
              ),
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
            Text('${_formatDate(e.date).toUpperCase()}',
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
      {required this.entry, required this.onTap, required this.onDelete});
  final SessionHistoryEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  @override
  Widget build(BuildContext context) {
    final age = (entry.ageInMonths / 12).floor();
    return KeplerCard(
      onTap: onTap,
      child: Row(
        children: [
          SizedBox(
            width: 64.w,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('FSIQ',
                    style: AppText.monoLabel(color: Theme.of(context).colorScheme.outline)),
                SizedBox(height: 4.h),
                Text('${entry.fsiq}',
                    style: AppText.monoScore(
                        color: AppColors.primary, size: 26.sp)),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.classification, style: AppText.bodyStrong()),
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
