import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/l10n/l10n_ext.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/kepler_colors.dart';
import '../../../../../core/widgets/kepler_card.dart';
import '../../../../../core/widgets/kepler_scaffold.dart';
import '../../../_shared/data/event_local_store.dart';
import '../../../_shared/domain/models/day_status.dart';
import '../../../_shared/domain/models/event_day.dart';
import '../../../_shared/domain/services/event_schedule.dart';
import '../../../_shared/domain/services/q_module_registry.dart';
import '../../../_shared/presentation/questionnaire_runner_page.dart';
import '../../../reveals/data/self_estimate_store.dart';
import '../../../reveals/domain/services/reveal_source.dart';
import '../../../reveals/presentation/pages/reveal_page.dart';
import '../../../reveals/presentation/pages/self_estimate_page.dart';

/// Hub de l'événement d'attente : le programme des 8 jours, et où l'on en est.
///
/// La page est DÉLIBÉRÉMENT sans état et sans réseau. Le jour courant lui est
/// remis par l'appelant, qui le tient du serveur ([UnlockProgress.dayIndex]) :
/// il n'y a ici ni horloge ni minuterie, donc rien qu'une date de téléphone
/// puisse déplacer. Une valeur légèrement périmée n'ouvre jamais un jour en
/// avance — elle en montre un de moins, et le rafraîchissement de la carte
/// d'attente la corrige au prochain aller-retour.
class DayHubPage extends StatelessWidget {
  const DayHubPage({
    super.key,
    required this.serverDayIndex,
    this.moduleForDay = QModuleRegistry.forDay,
    this.store,
    this.revealSource = const RevealSource(),
    this.selfEstimateStore = const SelfEstimateStore(),
  });

  /// 1..8 pendant l'attente, 9 une fois le déblocage acquis.
  final int serverDayIndex;

  /// Où le hub va chercher le questionnaire d'une journée. Injectable pour les
  /// tests ; en production, le registre des modules livrés.
  final QModuleResolver moduleForDay;

  /// Stockage des réponses. `null` = le stockage chiffré de l'app (le défaut
  /// n'est pas une constante : il ouvre une box Hive).
  final EventAnswerStore? store;

  /// Le profil à révéler — l'historique local du passe courant.
  final RevealSource revealSource;

  /// L'auto-estimation du jour 1, gardée sur l'appareil.
  final SelfEstimateStore selfEstimateStore;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final termine = serverDayIndex > EventSchedule.totalDays;
    return KeplerScaffold(
      eyebrow: l10n.weHubEyebrow,
      title: termine ? l10n.weHubTitleDone : l10n.weHubTitle(serverDayIndex),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.weHubIntro, style: AppText.of(context).bodySmall()),
          SizedBox(height: 20.h),
          for (final jour in EventSchedule.days) ...[
            _DayCard(
              day: jour,
              status: statusOfDay(
                day: jour.day,
                serverDayIndex: serverDayIndex,
              ),
              moduleForDay: moduleForDay,
              store: store,
              revealSource: revealSource,
              selfEstimateStore: selfEstimateStore,
            ),
            SizedBox(height: 12.h),
          ],
        ],
      ),
    );
  }
}

/// Une journée du programme. Les journées passées restent ouvertes — rien ne
/// se perd à en manquer une.
class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.day,
    required this.status,
    required this.moduleForDay,
    required this.store,
    required this.revealSource,
    required this.selfEstimateStore,
  });

  final EventDay day;
  final DayStatus status;
  final QModuleResolver moduleForDay;
  final EventAnswerStore? store;
  final RevealSource revealSource;
  final SelfEstimateStore selfEstimateStore;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = KeplerColors.of(context);
    final verrouille = status == DayStatus.locked;

    final (String etiquette, Color teinte, IconData icone) = switch (status) {
      DayStatus.open => (l10n.weTodayTag, colors.primary, Icons.east),
      DayStatus.past => (
          l10n.wePastTag,
          colors.textSecondary,
          Icons.history,
        ),
      DayStatus.locked => (
          l10n.weLockedTag(day.day),
          colors.textTertiary,
          Icons.lock_outline,
        ),
    };

    final carte = KeplerCard(
      onTap: verrouille ? null : () => _ouvrir(context),
      child: Row(
        children: [
          SizedBox(
            width: 32.w,
            child: Text(
              'J${day.day}',
              style: AppText.of(context).monoLabel(color: teinte),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(etiquette,
                    style: AppText.of(context).monoLabel(color: teinte)),
                SizedBox(height: 4.h),
                Text(_titre(l10n), style: AppText.of(context).h3()),
                SizedBox(height: 2.h),
                Text(_sousTitre(l10n),
                    style: AppText.of(context)
                        .bodySmall(color: colors.textSecondary)),
              ],
            ),
          ),
          Icon(icone, size: 18.sp, color: teinte),
        ],
      ),
    );

    return verrouille
        ? IgnorePointer(child: Opacity(opacity: 0.55, child: carte))
        : carte;
  }

  /// Ouvre la journée dans l'ORDRE du programme (plan produit §3) :
  ///
  ///   1. l'auto-estimation du QI, tant qu'elle n'a pas été réglée — elle
  ///      passe avant TOUTE révélation, sans quoi elle serait ancrée par le
  ///      chiffre qu'on vient de montrer ;
  ///   2. la révélation du jour, le cadeau qui ne demande rien ;
  ///   3. l'activité : le questionnaire s'il est livré, sinon l'annonce
  ///      honnête qu'il arrive.
  ///
  /// La garde de l'étape 1 porte sur « cette journée révèle-t-elle quelque
  /// chose », PAS sur « sommes-nous au jour 1 ». La nuance est tout sauf
  /// cosmétique : les journées passées sont rattrapables, donc rien ne
  /// garantit que le jour 1 soit la première carte ouverte. Un utilisateur au
  /// jour 3 qui rattrape d'abord le jour 2 y lirait sa vitesse de traitement,
  /// et l'estimation demandée ensuite ne mesurerait plus une croyance mais un
  /// calcul — silencieusement, puisque `record` est en écriture unique.
  ///
  /// Chaque étape ne cède la place à la suivante que si elle a été menée à son
  /// terme (sortie par le bouton, pas par le retour système) : refermer une
  /// révélation d'un geste de retour ramène au programme, ça n'enchaîne pas.
  Future<void> _ouvrir(BuildContext context) async {
    final reveal = day.reveal;

    if (reveal != null) {
      final deja = await selfEstimateStore.read();
      if (!context.mounted) return;
      if (!deja.isSettled) {
        final reglee = await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => SelfEstimatePage(store: selfEstimateStore),
          ),
        );
        // `false` = rien n'a pu être écrit : on n'enchaîne pas sur la
        // révélation, sans quoi la question se reposerait APRÈS elle.
        if (!context.mounted || reglee != true) return;
      }
    }

    if (reveal != null) {
      final profil = await revealSource.latest();
      // L'estimation n'est relue que là où elle sert : la révélation finale.
      final estimation = reveal == RevealKind.fullIq
          ? await selfEstimateStore.read()
          : SelfEstimate.absent;
      if (!context.mounted) return;

      final lue = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (revealContext) => RevealPage(
            kind: reveal,
            data: profil,
            selfEstimate: estimation,
            ctaLabel: _aUneActivite
                ? revealContext.l10n.weRvContinue
                : revealContext.l10n.weRvBackToHub,
          ),
        ),
      );
      if (!context.mounted || lue != true) return;
      if (!_aUneActivite) return;
    }

    _ouvrirActivite(context);
  }

  /// Le jour 8 n'a rien à faire faire : sa « activité » est la carte de
  /// partage, qui vit dans l'écran de déblocage. Enchaîner sur une annonce
  /// « contenu à venir » juste après le QI global serait du bruit.
  bool get _aUneActivite =>
      day.activityKind != null && day.activityKind != DayActivityKind.share;

  /// L'activité du jour : son questionnaire s'il est livré, sinon l'annonce
  /// honnête. Le contenu arrive module par module, et chaque journée s'active
  /// d'elle-même dès que le sien est enregistré.
  void _ouvrirActivite(BuildContext context) {
    final module = moduleForDay(day.day);
    if (module == null) return _annoncer(context);

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuestionnaireRunnerPage(
          module: module,
          store: store ?? EventLocalStore.instance,
          title: _titre(context.l10n),
        ),
      ),
    );
  }

  void _annoncer(BuildContext context) {
    final l10n = context.l10n;
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 28.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_titre(l10n), style: AppText.of(sheetContext).h2()),
            SizedBox(height: 12.h),
            Text(l10n.wePlaceholderTitle,
                style: AppText.of(sheetContext).monoLabel(
                    color: KeplerColors.of(sheetContext).textSecondary)),
            SizedBox(height: 6.h),
            Text(l10n.wePlaceholderBody,
                style: AppText.of(sheetContext).bodySmall()),
          ],
        ),
      ),
    );
  }

  String _titre(AppLocalizations l10n) => switch (day.day) {
        1 => l10n.weDay1Title,
        2 => l10n.weDay2Title,
        3 => l10n.weDay3Title,
        4 => l10n.weDay4Title,
        5 => l10n.weDay5Title,
        6 => l10n.weDay6Title,
        7 => l10n.weDay7Title,
        _ => l10n.weDay8Title,
      };

  /// Ce que la journée contient : sa révélation, son cadrage, son jeu.
  String _sousTitre(AppLocalizations l10n) {
    final parts = <String>[
      if (day.reveal != null) _reveal(l10n, day.reveal!),
      if (day.activityKind != null) _activite(l10n, day.activityKind!),
      if (day.game != null) _jeu(l10n, day.game!),
    ];
    return parts.join(' · ');
  }

  String _reveal(AppLocalizations l10n, RevealKind kind) => switch (kind) {
        RevealKind.vci => l10n.weRevealVci,
        RevealKind.psi => l10n.weRevealPsi,
        RevealKind.wmi => l10n.weRevealWmi,
        RevealKind.fri => l10n.weRevealFri,
        RevealKind.vsi => l10n.weRevealVsi,
        RevealKind.strengths => l10n.weRevealStrengths,
        RevealKind.fullIq => l10n.weRevealFullIq,
      };

  String _activite(AppLocalizations l10n, DayActivityKind kind) =>
      switch (kind) {
        DayActivityKind.announced => l10n.weAnnouncedTag,
        DayActivityKind.contribution => l10n.weContributionTag,
        DayActivityKind.share => l10n.weShareTag,
      };

  String _jeu(AppLocalizations l10n, GameKind kind) => switch (kind) {
        GameKind.stroop => l10n.weGameStroop,
        GameKind.delayChoice => l10n.weGameDelayChoice,
        GameKind.timeEstimation => l10n.weGameTimeEstimation,
        GameKind.confidenceCalibration => l10n.weGameConfidence,
      };
}
