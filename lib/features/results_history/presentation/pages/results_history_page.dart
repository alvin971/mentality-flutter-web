import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/session_history_service.dart';

/// Page "Mes résultats" — historique des évaluations terminées.
///
/// Lit depuis [SessionHistoryService] (Hive local, chiffré AES).
/// Prêt pour synchronisation Firestore — voir firebase_config.dart.
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
        title: const Text('Supprimer ce résultat ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Supprimer', style: TextStyle(color: AppColors.error)),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Mes résultats')),
      body: SafeArea(
        child: _entries.isEmpty
            ? _buildEmptyState(context)
            : _buildSessionList(context),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart_rounded,
              size: 80.sp,
              color: AppColors.grey300,
            ),
            SizedBox(height: 24.h),
            Text(
              'Aucune évaluation pour l\'instant',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.grey600,
                  ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12.h),
            Text(
              'Complétez votre première évaluation WAIS-IV pour voir vos résultats ici.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.grey500,
                  ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32.h),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Commencer une évaluation'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionList(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.all(16.w),
      itemCount: _entries.length,
      separatorBuilder: (_, __) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        final entry = _entries[index];
        return _buildEntryCard(context, entry);
      },
    );
  }

  Widget _buildEntryCard(BuildContext context, SessionHistoryEntry entry) {
    final ageYears = (entry.ageInMonths / 12).floor();
    final color = _colorForFSIQ(entry.fsiq);

    return Card(
      child: InkWell(
        onTap: () => _showEntryDetail(context, entry),
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              // FSIQ circle
              Container(
                width: 60.w,
                height: 60.w,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${entry.fsiq}',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 20.sp,
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.classification,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      _formatDate(entry.date),
                      style: TextStyle(fontSize: 13.sp, color: AppColors.grey500),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '$ageYears ans  •  QI ${entry.fsiq}',
                      style: TextStyle(fontSize: 13.sp, color: AppColors.grey600),
                    ),
                  ],
                ),
              ),
              // Actions
              IconButton(
                icon: Icon(Icons.delete_outline, color: AppColors.grey400, size: 20.sp),
                onPressed: () => _deleteEntry(entry),
                tooltip: 'Supprimer',
              ),
              Icon(Icons.arrow_forward_ios, size: 14.sp, color: AppColors.grey400),
            ],
          ),
        ),
      ),
    );
  }

  void _showEntryDetail(BuildContext context, SessionHistoryEntry entry) {
    final ageYears = (entry.ageInMonths / 12).floor();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 40.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'Résultats du ${_formatDate(entry.date)}',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.h),
            Text('$ageYears ans', style: TextStyle(color: AppColors.grey500)),
            SizedBox(height: 24.h),
            _detailRow('QI Total (FSIQ)', entry.fsiq, _colorForFSIQ(entry.fsiq)),
            if (entry.vci != null) _detailRow('Compréhension Verbale', entry.vci!, AppColors.indexVCI),
            if (entry.vsi != null) _detailRow('Visuo-Spatial', entry.vsi!, AppColors.indexVSI),
            if (entry.fri != null) _detailRow('Raisonnement Fluide', entry.fri!, AppColors.indexFRI),
            if (entry.wmi != null) _detailRow('Mémoire de Travail', entry.wmi!, AppColors.indexWMI),
            if (entry.psi != null) _detailRow('Vitesse de Traitement', entry.psi!, AppColors.indexPSI),
            SizedBox(height: 16.h),
            Text(
              entry.classification,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: _colorForFSIQ(entry.fsiq),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, int score, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 15.sp, color: AppColors.grey700)),
          Text(
            '$score',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  Color _colorForFSIQ(int fsiq) {
    if (fsiq >= 130) return AppColors.success;
    if (fsiq >= 115) return const Color(0xFF2196F3);
    if (fsiq >= 85) return AppColors.primary;
    if (fsiq >= 70) return AppColors.warning;
    return AppColors.error;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
