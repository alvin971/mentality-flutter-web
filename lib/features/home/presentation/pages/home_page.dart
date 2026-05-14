import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_notifier.dart';
import '../../../../core/widgets/et_logo_animated.dart';
import '../../../../core/widgets/kepler_button.dart';
import '../../../../core/widgets/kepler_card.dart';
import '../../../../core/widgets/kepler_scaffold.dart';
import '../../../../services/session_persistence_service.dart';
import '../../../assessment/presentation/pages/assessment_intro_page.dart';
import '../../../chat/presentation/pages/mentality_chat_page.dart';
import '../../../complete_test/presentation/pages/complete_test_orchestrator_page.dart';
import '../../../results_history/presentation/pages/results_history_page.dart';

/// Home Kepler — hero éditorial + 3 cards d'action + résumé "À propos".
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final hasPending = SessionPersistenceService.instance.hasPendingSession;
    final isWide = MediaQuery.sizeOf(context).width >= 800;

    return KeplerScaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(64.h),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
            child: Row(
              children: [
                Text('MENTAL E.T.',
                    style: AppText.monoLabel(color: AppColors.primary)),
                SizedBox(width: 10.w),
                EtLogoAnimated(size: 28.w),
                const Spacer(),
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: themeNotifier,
                  builder: (_, mode, __) => IconButton(
                    icon: Icon(
                      mode == ThemeMode.dark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                      size: 20.sp,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: themeNotifier.toggle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasPending) ...[
            _ResumeBanner(),
            SizedBox(height: 20.h),
          ],
          SizedBox(height: 8.h),
          _Hero(),
          SizedBox(height: 32.h),
          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _Actions()),
                SizedBox(width: 24.w),
                Expanded(child: _About()),
              ],
            )
          else ...[
            _Actions(),
            SizedBox(height: 32.h),
            _About(),
            SizedBox(height: 24.h),
          ],
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Découvrez', style: AppText.heroDisplay()),
        Text('votre profil cognitif.', style: AppText.heroItalic()),
        SizedBox(height: 16.h),
        Container(
          width: 36.w,
          height: 1,
          color: AppColors.primary.withValues(alpha: 0.4),
        ),
        SizedBox(height: 16.h),
        Text(
          'Une évaluation scientifique adaptative, inspirée des échelles Wechsler. '
          '12 sous-tests, 5 indices, un score global.',
          style: AppText.body(),
        ),
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ActionCard(
          eyebrow: '01',
          title: 'Commencer une évaluation',
          subtitle: 'Durée : 30 – 45 minutes',
          icon: Icons.east,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AssessmentIntroPage()),
          ),
        ),
        SizedBox(height: 14.h),
        _ActionCard(
          eyebrow: '02',
          title: 'Mes résultats',
          subtitle: 'Historique des évaluations',
          icon: Icons.east,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ResultsHistoryPage()),
          ),
        ),
        SizedBox(height: 14.h),
        _ActionCard(
          eyebrow: '03',
          title: 'Parler avec Mentality',
          subtitle: 'Assistant IA, questions psychologiques',
          icon: Icons.east,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MentalityChatPage()),
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return KeplerCard(
      onTap: onTap,
      child: Row(
        children: [
          SizedBox(
            width: 32.w,
            child: Text(eyebrow,
                style: AppText.monoLabel(color: AppColors.primary)),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.h3()),
                SizedBox(height: 2.h),
                Text(subtitle, style: AppText.bodySmall()),
              ],
            ),
          ),
          Icon(icon, size: 18.sp, color: AppColors.primary),
        ],
      ),
    );
  }
}

class _About extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tiles = [
      _InfoTile(
        eyebrow: 'I',
        title: '12 sous-tests',
        body: 'Évaluation complète des cinq indices cognitifs WAIS-IV.',
      ),
      _InfoTile(
        eyebrow: 'II',
        title: 'IA adaptative',
        body: 'Difficulté ajustée en temps réel via inférence IRT.',
      ),
      _InfoTile(
        eyebrow: 'III',
        title: 'Validation scientifique',
        body: 'Items inspirés des échelles Wechsler (WPPSI / WISC / WAIS).',
      ),
    ];
    return KeplerCard(
      surface: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('À PROPOS',
              style: AppText.monoLabel(color: AppColors.primary)),
          SizedBox(height: 16.h),
          for (var i = 0; i < tiles.length; i++) ...[
            tiles[i],
            if (i < tiles.length - 1) ...[
              SizedBox(height: 16.h),
              Container(
                height: 1,
                color: Colors.black.withValues(alpha: 0.06),
              ),
              SizedBox(height: 16.h),
            ],
          ],
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.eyebrow,
    required this.title,
    required this.body,
  });

  final String eyebrow;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24.w,
          child: Text(eyebrow,
              style: AppText.monoLabel(color: AppColors.textTertiary)),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.bodyStrong()),
              SizedBox(height: 2.h),
              Text(body, style: AppText.bodySmall()),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResumeBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return KeplerCard(
      child: Row(
        children: [
          Container(
            width: 3.w,
            height: 36.h,
            color: AppColors.primary,
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TEST EN COURS',
                    style: AppText.monoLabel(color: AppColors.primary)),
                SizedBox(height: 4.h),
                Text('Reprendre votre évaluation', style: AppText.bodyStrong()),
              ],
            ),
          ),
          KeplerButton(
            label: 'Reprendre',
            variant: KeplerButtonVariant.secondary,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const CompleteTestOrchestratorPage()),
            ),
          ),
        ],
      ),
    );
  }
}
