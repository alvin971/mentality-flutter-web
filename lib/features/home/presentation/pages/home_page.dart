import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_notifier.dart';
import '../../../../services/session_persistence_service.dart';
import '../../../assessment/presentation/pages/assessment_intro_page.dart';
import '../../../chat/presentation/pages/mentality_chat_page.dart';
import '../../../complete_test/presentation/pages/complete_test_orchestrator_page.dart';
import '../../../results_history/presentation/pages/results_history_page.dart';

/// Page d'accueil principale de l'application Mentality.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 800;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16.w,
        title: Row(
          children: [
            Container(
              width: 32.w,
              height: 32.w,
              decoration: const BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.adjust, color: Colors.white, size: 18.sp),
            ),
            SizedBox(width: 10.w),
            Text(
              'Mentality',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeNotifier,
            builder: (_, mode, __) => IconButton(
              icon: Icon(
                mode == ThemeMode.dark
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
                color: AppColors.textSecondary,
              ),
              onPressed: themeNotifier.toggle,
            ),
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
          child: isWide
              ? _buildWideLayout(context)
              : _buildNarrowLayout(context),
        ),
      ),
    );
  }

  Widget _buildResumeBanner(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.warning.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.play_circle_outline, color: AppColors.warning, size: 28.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Test en cours',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15.sp,
                        color: AppColors.warning)),
                Text('Vous avez un test incomplet. Reprendre ?',
                    style: TextStyle(fontSize: 12.sp, color: AppColors.grey700)),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const CompleteTestOrchestratorPage()),
            ),
            child: const Text('Reprendre'),
          ),
        ],
      ),
    );
  }

  Widget _buildWideLayout(BuildContext context) {
    final hasPending = SessionPersistenceService.instance.hasPendingSession;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasPending) _buildResumeBanner(context),
        if (hasPending) SizedBox(height: 16.h),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroSection(context),
                  SizedBox(height: 32.h),
                  _buildStatsGrid(context),
                ],
              ),
            ),
            SizedBox(width: 32.w),
            Expanded(
              flex: 3,
              child: _buildPillarsSection(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(BuildContext context) {
    final hasPending = SessionPersistenceService.instance.hasPendingSession;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasPending) _buildResumeBanner(context),
        if (hasPending) SizedBox(height: 16.h),
        _buildHeroSection(context),
        SizedBox(height: 28.h),
        _buildCTAButtons(context),
        SizedBox(height: 28.h),
        _buildStatsGrid(context),
        SizedBox(height: 28.h),
        _buildPillarsSection(context),
      ],
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LA PLATEFORME',
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.8,
            color: AppColors.textTertiary,
          ),
        ),
        SizedBox(height: 12.h),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
            children: const [
              TextSpan(text: 'Votre santé mentale mérite\nune '),
              TextSpan(
                text: 'attention sérieuse.',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          'Des tests cognitifs rigoureux jusqu\'à un accompagnement IA pour votre bien-être mental.',
          style: TextStyle(
            fontSize: 14.sp,
            color: AppColors.textSecondary,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildCTAButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AssessmentIntroPage()),
            ),
            child: const Text('Commencer une évaluation'),
          ),
        ),
        SizedBox(height: 12.h),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ResultsHistoryPage()),
            ),
            child: const Text('Mes résultats →'),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12.h,
      crossAxisSpacing: 12.w,
      childAspectRatio: 1.4,
      children: const [
        _StatCard(value: '12', label: 'Tests cognitifs validés'),
        _StatCard(value: '100%', label: 'Gratuit pour toujours'),
        _StatCard(value: '4', label: 'Indices composites'),
        _StatCard(value: '24/7', label: 'Accompagnement IA'),
      ],
    );
  }

  Widget _buildPillarsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trois piliers pour prendre soin de votre esprit.',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            height: 1.3,
          ),
        ),
        SizedBox(height: 16.h),
        _PillarCard(
          number: '01',
          icon: Icons.psychology_outlined,
          title: 'Évaluation cognitive complète',
          description:
              '12 tests basés sur le WAIS-IV · 4 indices composites · profil détaillé de vos forces et fragilités cognitives',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AssessmentIntroPage()),
          ),
        ),
        SizedBox(height: 12.h),
        _PillarCard(
          number: '02',
          icon: Icons.favorite_outline,
          title: 'Accompagnement psychologique IA',
          description:
              'Un espace d\'écoute active disponible 24h/24 · pour comprendre vos résultats et explorer ce que vous ressentez',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MentalityChatPage()),
          ),
        ),
        SizedBox(height: 12.h),
        _PillarCard(
          number: '03',
          icon: Icons.verified_outlined,
          title: 'Supervision clinique réelle',
          description:
              'Chaque test est validé et amélioré en continu par des psychologues partenaires',
          onTap: () {},
        ),
        SizedBox(height: 24.h),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AssessmentIntroPage()),
            ),
            child: const Text('Commencer une évaluation'),
          ),
        ),
        SizedBox(height: 12.h),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ResultsHistoryPage()),
            ),
            child: const Text('Mes résultats →'),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;

  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.secondary,
                height: 1,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PillarCard extends StatelessWidget {
  final String number;
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _PillarCard({
    required this.number,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.all(18.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40.w,
                    height: 40.w,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(icon, color: Colors.white, size: 22.sp),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    number,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
