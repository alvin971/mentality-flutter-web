import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/l10n/l10n_ext.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/kepler_colors.dart';
import '../../../../../core/widgets/kepler_card.dart';
import '../../../../../core/widgets/kepler_scaffold.dart';
import '../../../_shared/domain/models/day_status.dart';
import '../../../_shared/domain/models/event_day.dart';
import '../../../_shared/domain/services/event_schedule.dart';

/// Hub de l'événement d'attente : le programme des 8 jours, et où l'on en est.
///
/// La page est DÉLIBÉRÉMENT sans état et sans réseau. Le jour courant lui est
/// remis par l'appelant, qui le tient du serveur ([UnlockProgress.dayIndex]) :
/// il n'y a ici ni horloge ni minuterie, donc rien qu'une date de téléphone
/// puisse déplacer. Une valeur légèrement périmée n'ouvre jamais un jour en
/// avance — elle en montre un de moins, et le rafraîchissement de la carte
/// d'attente la corrige au prochain aller-retour.
class DayHubPage extends StatelessWidget {
  const DayHubPage({super.key, required this.serverDayIndex});

  /// 1..8 pendant l'attente, 9 une fois le déblocage acquis.
  final int serverDayIndex;

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
  const _DayCard({required this.day, required this.status});

  final EventDay day;
  final DayStatus status;

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

  /// Le contenu des journées arrive module par module ; d'ici là, la carte
  /// s'ouvre sur une annonce honnête plutôt que sur un écran vide.
  void _ouvrir(BuildContext context) {
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
