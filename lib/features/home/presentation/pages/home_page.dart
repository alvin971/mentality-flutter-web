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
///
/// Présente les 3 actions principales en cards et une section "À propos".
/// Adaptatif : layout 2 colonnes sur écrans larges (>= 800 px).
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mentality'),
        actions: [
          // Toggle dark / light mode
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeNotifier,
            builder: (_, mode, __) => IconButton(
              icon: Icon(mode == ThemeMode.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined),
              tooltip: mode == ThemeMode.dark ? 'Mode clair' : 'Mode sombre',
              onPressed: themeNotifier.toggle,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
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
        borderRadius: BorderRadius.circular(12.r),
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
                    style:
                        TextStyle(fontSize: 12.sp, color: AppColors.grey700)),
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
            // Colonne gauche : header + à propos
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  SizedBox(height: 48.h),
                  _buildAboutSection(context),
                ],
              ),
            ),
            SizedBox(width: 32.w),
            // Colonne droite : cards actions
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  _buildEvaluationCard(context),
                  SizedBox(height: 16.h),
                  _buildResultsCard(context),
                  SizedBox(height: 16.h),
                  _buildChatCard(context),
                ],
              ),
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
        _buildHeader(context),
        SizedBox(height: 32.h),
        _buildEvaluationCard(context),
        SizedBox(height: 16.h),
        _buildResultsCard(context),
        SizedBox(height: 16.h),
        _buildChatCard(context),
        SizedBox(height: 32.h),
        _buildAboutSection(context),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bienvenue', style: Theme.of(context).textTheme.displayLarge),
        SizedBox(height: 8.h),
        Text(
          'Découvrez votre profil cognitif à travers une évaluation scientifique adaptative.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }

  Widget _buildEvaluationCard(BuildContext context) {
    return _ActionCard(
      icon: Icons.play_arrow_rounded,
      iconColor: AppColors.primary,
      title: 'Commencer une évaluation',
      subtitle: 'Durée : 30-45 minutes',
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AssessmentIntroPage()),
      ),
    );
  }

  Widget _buildResultsCard(BuildContext context) {
    return _ActionCard(
      icon: Icons.bar_chart_rounded,
      iconColor: AppColors.secondary,
      title: 'Mes résultats',
      subtitle: 'Historique des évaluations',
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ResultsHistoryPage()),
      ),
    );
  }

  Widget _buildChatCard(BuildContext context) {
    return _ActionCard(
      icon: Icons.chat_bubble_outline,
      iconColor: AppColors.tertiary,
      title: 'Parler avec Mentality',
      subtitle: 'Assistant IA pour vos questions',
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MentalityChatPage()),
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('À propos', style: Theme.of(context).textTheme.titleMedium),
        SizedBox(height: 12.h),
        _InfoTile(
          icon: Icons.psychology_outlined,
          title: '12 types d\'exercices',
          subtitle: 'Évaluation complète des capacités cognitives',
        ),
        SizedBox(height: 8.h),
        _InfoTile(
          icon: Icons.auto_awesome,
          title: 'IA adaptative',
          subtitle: 'Difficulté ajustée en temps réel',
        ),
        SizedBox(height: 8.h),
        _InfoTile(
          icon: Icons.verified_user_outlined,
          title: 'Scientifiquement validé',
          subtitle: 'Inspiré des échelles Wechsler (WAIS-IV)',
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Row(
            children: [
              Container(
                width: 60.w,
                height: 60.w,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(icon, size: 32.sp, color: iconColor),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    SizedBox(height: 4.h),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.grey600,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: 20.sp, color: AppColors.grey400),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 24.sp, color: AppColors.primary),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
