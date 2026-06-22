import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/auth_local_store.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_notifier.dart';
import '../../../../core/l10n/l10n_ext.dart';
import '../../../../core/widgets/et_logo_animated.dart';
import '../../../../core/widgets/kepler_button.dart';
import '../../../../core/widgets/language_switcher_button.dart';
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

  /// Efface le token local et renvoie à l'écran de connexion.
  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.homeLogoutTitle),
        content: Text(context.l10n.homeLogoutBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.homeLogoutConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await AuthLocalStore.instance.clear();
    if (!context.mounted) return;
    context.go(AppConstants.routeRegister);
  }

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
                const LanguageSwitcherButton(),
                SizedBox(width: 4.w),
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: themeNotifier,
                  builder: (_, mode, __) => IconButton(
                    icon: Icon(
                      mode == ThemeMode.dark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                      size: 20.sp,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    onPressed: themeNotifier.toggle,
                  ),
                ),
                IconButton(
                  tooltip: context.l10n.homeLogoutConfirm,
                  icon: Icon(
                    Icons.logout_outlined,
                    size: 20.sp,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () => _confirmLogout(context),
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
        Text(context.l10n.homeHeroTitle, style: AppText.heroDisplay()),
        Text(context.l10n.homeHeroTitleItalic, style: AppText.heroItalic()),
        SizedBox(height: 16.h),
        Container(
          width: 36.w,
          height: 1,
          color: AppColors.primary.withValues(alpha: 0.4),
        ),
        SizedBox(height: 16.h),
        Text(
          context.l10n.homeHeroBody,
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
          title: context.l10n.homeActionStartTitle,
          subtitle: context.l10n.homeActionStartSubtitle,
          icon: Icons.east,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AssessmentIntroPage()),
          ),
        ),
        SizedBox(height: 14.h),
        _ActionCard(
          eyebrow: '02',
          title: context.l10n.homeActionResultsTitle,
          subtitle: context.l10n.homeActionResultsSubtitle,
          icon: Icons.east,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ResultsHistoryPage()),
          ),
        ),
        SizedBox(height: 14.h),
        _ActionCard(
          eyebrow: '03',
          title: context.l10n.homeActionChatTitle,
          subtitle: context.l10n.homeActionChatSubtitle,
          icon: Icons.east,
          comingSoon: true,
          onTap: () {},
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
    this.comingSoon = false,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool comingSoon;

  @override
  Widget build(BuildContext context) {
    final card = KeplerCard(
      onTap: comingSoon ? null : onTap,
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
                if (comingSoon) ...[
                  Text(context.l10n.homeComingSoon,
                      style: AppText.monoLabel(color: AppColors.warning)),
                  SizedBox(height: 4.h),
                ],
                Text(title, style: AppText.h3()),
                SizedBox(height: 2.h),
                Text(subtitle, style: AppText.bodySmall()),
              ],
            ),
          ),
          Icon(
            comingSoon ? Icons.schedule_outlined : icon,
            size: 18.sp,
            color: comingSoon ? AppColors.warning : AppColors.primary,
          ),
        ],
      ),
    );
    return comingSoon
        ? IgnorePointer(child: Opacity(opacity: 0.55, child: card))
        : card;
  }
}

class _About extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tiles = [
      _InfoTile(
        eyebrow: 'I',
        title: context.l10n.homeAboutSubtestsTitle,
        body: context.l10n.homeAboutSubtestsBody,
      ),
      _InfoTile(
        eyebrow: 'II',
        title: context.l10n.homeAboutAdaptiveTitle,
        body: context.l10n.homeAboutAdaptiveBody,
      ),
      _InfoTile(
        eyebrow: 'III',
        title: context.l10n.homeAboutValidationTitle,
        body: context.l10n.homeAboutValidationBody,
      ),
    ];
    return KeplerCard(
      surface: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.homeAboutEyebrow,
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
              style: AppText.monoLabel(color: Theme.of(context).colorScheme.outline)),
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
                Text(context.l10n.homeResumeEyebrow,
                    style: AppText.monoLabel(color: AppColors.primary)),
                SizedBox(height: 4.h),
                Text(context.l10n.homeResumeTitle, style: AppText.bodyStrong()),
              ],
            ),
          ),
          KeplerButton(
            label: context.l10n.homeResumeButton,
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
