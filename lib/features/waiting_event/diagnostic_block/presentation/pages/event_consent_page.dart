// L'écran de recueil du consentement art. 9 — le seul endroit de l'app où
// l'on peut autoriser l'envoi d'une donnée de santé.
//
// Ce que le RGPD exige d'un consentement explicite, et que cet écran tient :
//   · un ACTE POSITIF — deux boutons distincts, aucun présélectionné, aucun
//     « en continuant vous acceptez » ;
//   · une INFORMATION PRÉALABLE — ce qui part, pourquoi, où, et pour combien
//     de temps ça engage ;
//   · un REFUS SANS CONSÉQUENCE, dit à l'écran : ni le déblocage, ni les
//     résultats, ni le reste du programme n'en dépendent (et rien dans le
//     code ne les y relie — c'est la garde de non-gamification) ;
//   · un RETRAIT aussi simple que l'octroi (art. 7-3).
//
// L'écran ne décide de rien d'autre : il renvoie `true` seulement si le
// consentement a été accordé ET écrit. Un échec d'écriture renvoie `false` —
// l'appelant ne doit surtout pas enchaîner sur des questions de santé en
// croyant l'accord acquis.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/l10n/l10n_ext.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/kepler_colors.dart';
import '../../../../../core/widgets/kepler_button.dart';
import '../../../../../core/widgets/kepler_card.dart';
import '../../../../../core/widgets/kepler_scaffold.dart';
import '../../../_shared/domain/services/event_consent.dart';

class EventConsentPage extends StatefulWidget {
  const EventConsentPage({super.key, this.consent = const AppEventConsent()});

  final EventConsent consent;

  @override
  State<EventConsentPage> createState() => _EventConsentPageState();
}

class _EventConsentPageState extends State<EventConsentPage> {
  /// Verrou de ré-entrance, pour la même raison qu'à l'auto-estimation :
  /// l'écriture ouvre SharedPreferences, et pendant ce temps les deux boutons
  /// restent tactiles. Un second appui dépilerait la route SUIVANTE — le hub —
  /// et le bloc diagnostic s'afficherait par-dessus l'écran de déblocage.
  bool _enCours = false;

  Future<void> _repondre(bool accepte) async {
    if (_enCours) return;
    setState(() => _enCours = true);

    // Un refus n'écrit rien : il n'y a pas de « non » à prouver, et écrire un
    // enregistrement pour le seul fait d'avoir refusé créerait une donnée là
    // où la personne vient de demander qu'il n'y en ait pas.
    final ok = accepte ? await widget.consent.setGranted(true) : false;
    if (!mounted) return;
    // On renvoie ce qui s'est VRAIMENT passé : `false` sur une écriture en
    // échec, jamais l'intention de l'utilisateur.
    Navigator.of(context).pop(ok);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return KeplerScaffold(
      eyebrow: l10n.weCsEyebrow,
      title: l10n.weCsTitle,
      bottomBar: SafeArea(
        minimum: EdgeInsets.fromLTRB(20.w, 0, 20.w, 12.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            KeplerButton(
              label: l10n.weCsAccept,
              expand: true,
              onPressed: _enCours ? null : () => _repondre(true),
            ),
            // Écart généreux : les deux cibles n'ont pas du tout la même
            // portée, et l'une d'elles autorise l'envoi de données de santé.
            SizedBox(height: 12.h),
            KeplerButton(
              label: l10n.weCsDecline,
              variant: KeplerButtonVariant.secondary,
              expand: true,
              onPressed: _enCours ? null : () => _repondre(false),
            ),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16.h),
          Text(l10n.weCsIntro, style: AppText.of(context).body()),
          SizedBox(height: 20.h),
          _Section(titre: l10n.weCsWhatTitle, corps: l10n.weCsWhat),
          _Section(titre: l10n.weCsPurposeTitle, corps: l10n.weCsPurpose),
          _Section(titre: l10n.weCsWhoTitle, corps: l10n.weCsWho),
          _Section(titre: l10n.weCsRightsTitle, corps: l10n.weCsRights),
          SizedBox(height: 4.h),
          // Le caractère facultatif, dit là où la décision se prend — pas
          // dans une page annexe que personne n'ouvre.
          Text(
            l10n.weCsOptional,
            style: AppText.of(context)
                .bodySmall(color: KeplerColors.of(context).textSecondary),
          ),
          SizedBox(height: 8.h),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.titre, required this.corps});

  final String titre;
  final String corps;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: 12.h),
        child: KeplerCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titre,
                style: AppText.of(context)
                    .monoLabel(color: KeplerColors.of(context).primary),
              ),
              SizedBox(height: 6.h),
              Text(corps, style: AppText.of(context).bodySmall()),
            ],
          ),
        ),
      );
}
