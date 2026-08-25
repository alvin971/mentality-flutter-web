import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/complete_test_session.dart';
import '../../../../core/services/auth_local_store.dart';
import '../../../../core/services/resume_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/kepler_colors.dart';
import '../../../../core/theme/theme_notifier.dart';
import '../../../../core/l10n/l10n_ext.dart';
import '../../../../core/widgets/et_logo_animated.dart';
import '../../../../core/widgets/kepler_button.dart';
import '../../../../core/widgets/language_switcher_button.dart';
import '../../../../core/widgets/kepler_card.dart';
import '../../../../core/widgets/kepler_scaffold.dart';
import '../../../assessment/presentation/pages/assessment_intro_page.dart';
import '../../../chat/presentation/pages/mentality_chat_page.dart';
import '../../../complete_test/presentation/pages/complete_test_orchestrator_page.dart';
import '../../../results_history/presentation/pages/results_history_page.dart';

/// Home Kepler — hero éditorial + 3 cards d'action + résumé "À propos".
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// Ce qu'il y a à reprendre, ou `null`. Relu à chaque retour sur cet écran :
  /// l'utilisateur en revient précisément après avoir avancé dans le bilan, et
  /// la version précédente — un `StatelessWidget` lisant Hive en synchrone —
  /// affichait indéfiniment la progression du premier rendu.
  Future<ResumableSession?>? _reprise;

  @override
  void initState() {
    super.initState();
    // Pas de setState ici : le premier build n'a pas encore eu lieu.
    _reprise = ResumeService.instance.lookup();
  }

  void _rafraichir() {
    if (!mounted) return;
    setState(() => _reprise = ResumeService.instance.lookup());
  }

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
                    style: AppText.of(context).monoLabel(color: KeplerColors.of(context).primary)),
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
          // La bannière ne s'affiche QUE sur une reprise réelle. Auparavant
          // elle apparaissait dès qu'une session traînait en local et son
          // bouton menait au lancement standard : elle promettait une reprise
          // et faisait tout recommencer.
          FutureBuilder<ResumableSession?>(
            future: _reprise,
            builder: (context, snap) {
              final reprise = snap.data;
              if (reprise == null) return const SizedBox.shrink();
              return Padding(
                padding: EdgeInsets.only(bottom: 20.h),
                child: _ResumeBanner(
                  reprise: reprise,
                  onChanged: _rafraichir,
                ),
              );
            },
          ),
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
        Text(context.l10n.homeHeroTitle, style: AppText.of(context).heroDisplay()),
        Text(context.l10n.homeHeroTitleItalic, style: AppText.of(context).heroItalic()),
        SizedBox(height: 16.h),
        Container(
          width: 36.w,
          height: 1,
          color: KeplerColors.of(context).primary.withValues(alpha: 0.4),
        ),
        SizedBox(height: 16.h),
        Text(
          context.l10n.homeHeroBody,
          style: AppText.of(context).body(),
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
                style: AppText.of(context).monoLabel(color: KeplerColors.of(context).primary)),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (comingSoon) ...[
                  Text(context.l10n.homeComingSoon,
                      style: AppText.of(context).monoLabel(color: KeplerColors.of(context).warning)),
                  SizedBox(height: 4.h),
                ],
                Text(title, style: AppText.of(context).h3()),
                SizedBox(height: 2.h),
                Text(subtitle, style: AppText.of(context).bodySmall()),
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
              style: AppText.of(context).monoLabel(color: KeplerColors.of(context).primary)),
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
              style: AppText.of(context).monoLabel(color: Theme.of(context).colorScheme.outline)),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.of(context).bodyStrong()),
              SizedBox(height: 2.h),
              Text(body, style: AppText.of(context).bodySmall()),
            ],
          ),
        ),
      ],
    );
  }
}

/// Bannière de reprise — la seule porte vers un bilan interrompu.
///
/// Elle annonce ce qui est RÉELLEMENT fait (« 4 exercices sur 12 · prochain :
/// Vocabulaire ») parce que la version précédente n'annonçait rien du tout et
/// menait au lancement standard : « Reprendre » recommençait le bilan.
class _ResumeBanner extends StatelessWidget {
  const _ResumeBanner({required this.reprise, required this.onChanged});

  final ResumableSession reprise;

  /// Appelé quand l'état de reprise a pu changer (retour du bilan, abandon).
  final VoidCallback onChanged;

  /// Abandon volontaire : irréversible, donc confirmé. La passation serveur est
  /// close AVANT l'effacement local — sinon elle reviendrait se proposer au
  /// démarrage suivant, sans plus aucun moyen de l'identifier.
  Future<void> _confirmerAbandon(BuildContext context) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.homeResumeRestartTitle),
        content: Text(ctx.l10n.homeResumeRestartBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ctx.l10n.homeResumeRestart),
          ),
        ],
      ),
    );
    if (confirme != true) return;
    await ResumeService.instance.abandon(reprise);
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final suivant = reprise.nextTestName;
    return KeplerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 3.w,
                height: 44.h,
                color: KeplerColors.of(context).primary,
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.l10n.homeResumeEyebrow,
                        style: AppText.of(context)
                            .monoLabel(color: KeplerColors.of(context).primary)),
                    SizedBox(height: 4.h),
                    Text(context.l10n.homeResumeTitle,
                        style: AppText.of(context).bodyStrong()),
                    SizedBox(height: 4.h),
                    Text(
                      context.l10n.homeResumeProgress(
                          reprise.completedCount, reprise.totalTests),
                      style: AppText.of(context).bodySmall(),
                    ),
                    Text(
                      suivant == null
                          ? context.l10n.homeResumeFinish
                          // « En cours » et non « prochain » quand la pause est
                          // tombée EN PLEIN exercice : on n'en propose pas un
                          // nouveau, on finit celui qui est ouvert.
                          : reprise.reprendEnPleinExercice
                              ? context.l10n.homeResumeCurrent(
                                  _localizedSubtest(context, suivant))
                              : context.l10n.homeResumeNext(
                                  _localizedSubtest(context, suivant)),
                      style: AppText.of(context).bodySmall(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: KeplerButton(
                  label: context.l10n.homeResumeButton,
                  variant: KeplerButtonVariant.secondary,
                  expand: true,
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CompleteTestOrchestratorPage(reprise: reprise),
                      ),
                    );
                    onChanged();
                  },
                ),
              ),
              SizedBox(width: 10.w),
              KeplerButton(
                label: context.l10n.homeResumeRestart,
                variant: KeplerButtonVariant.ghost,
                onPressed: () => _confirmerAbandon(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Libellé localisé d'un sous-test à partir de sa clé de séquence.
///
/// La clé de [CompleteTestSession.testSequence] est en français et sert
/// d'identifiant : l'afficher telle quelle laisserait « Mémoire des Chiffres »
/// au milieu d'une interface allemande.
String _localizedSubtest(BuildContext context, String key) {
  switch (key) {
    case 'Cubes':
      return context.l10n.ctTestCubes;
    case 'Similitudes':
      return context.l10n.ctTestSimilarities;
    case 'Mémoire des Chiffres':
      return context.l10n.ctTestDigitSpan;
    case 'Matrices':
      return context.l10n.ctTestMatrices;
    case 'Vocabulaire':
      return context.l10n.ctTestVocabulary;
    case 'Arithmétique':
      return context.l10n.ctTestArithmetic;
    case 'Recherche de Symboles':
      return context.l10n.ctTestSymbolSearch;
    case 'Puzzles Visuels':
      return context.l10n.ctTestVisualPuzzles;
    case 'Information':
      return context.l10n.ctTestInformation;
    case 'Code':
      return context.l10n.ctTestCoding;
    case 'Mémoire des Images':
      return context.l10n.ctTestPictureSpan;
    case 'Balances':
      return context.l10n.ctTestFigureWeights;
    default:
      return key;
  }
}
