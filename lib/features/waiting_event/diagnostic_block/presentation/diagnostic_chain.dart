// L'enchaînement consentement → bloc diagnostic, en un seul endroit.
//
// Extrait de la carte autonome du hub, qui n'existe plus : le programme veut
// ce bloc à la FIN du jour 1, et une fin n'existait pas tant que le
// questionnaire du jour 1 n'était pas livré. Il l'est (IPIP-50), donc le bloc
// prend sa place réelle — en sortie de questionnaire.
//
// L'ordre est non négociable : le consentement art. 9 D'ABORD, les questions
// de santé ensuite. Jamais l'inverse, et jamais « on demandera à l'envoi » —
// recueillir des déclarations puis découvrir qu'on n'a pas le droit de les
// envoyer laisserait sur l'appareil une donnée que personne n'a autorisée et
// que rien n'exploitera.
//
// Le gate est DUR ici, alors qu'il est SOUPLE pour les questionnaires du
// programme (jouables sans consentement, score affiché, rien d'envoyé). La
// différence est assumée : ce bloc n'affiche aucun résultat et ne calcule rien
// pour la personne. Le faire remplir sans pouvoir l'exploiter, ce serait lui
// prendre deux écrans de déclarations de santé pour rien.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/l10n/l10n_ext.dart';
import '../../../../core/theme/app_typography.dart';
import '../../_shared/domain/services/event_consent.dart';
import '../data/diagnostic_block_store.dart';
import 'pages/diagnostic_block_page.dart';
import 'pages/event_consent_page.dart';

/// Ouvre le bloc diagnostic derrière son gate art. 9.
///
/// Renvoie `true` seulement si la déclaration a été RÉELLEMENT close et
/// écrite. Les quatre autres issues renvoient `false` et laissent la question
/// entière — donc reposable en rouvrant la journée :
///
///  · le consentement est refusé ;
///  · le consentement est accordé mais l'écriture échoue (on enchaîne sur le
///    RÉSULTAT de l'écriture, jamais sur l'intention) ;
///  · l'écran est quitté en route (le bloc est tout-ou-rien) ;
///  · l'écriture de la déclaration elle-même échoue.
///
/// Dans les deux premiers cas, on explique pourquoi rien ne s'ouvre plutôt que
/// de ne rien faire du tout.
Future<bool> openDiagnosticBlock(
  BuildContext context, {
  required DiagnosticBlockStore store,
  required EventConsent consent,
}) async {
  if (!await consent.isGranted()) {
    if (!context.mounted) return false;
    final accorde = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => EventConsentPage(consent: consent),
      ),
    );
    if (!context.mounted) return false;
    // Refus, retour arrière, ou écriture en échec : dans les trois cas on n'a
    // pas le droit d'aller plus loin.
    if (accorde != true) {
      showDiagnosticDeclined(context);
      return false;
    }
  }

  if (!context.mounted) return false;
  final close = await Navigator.of(context).push<bool>(
    MaterialPageRoute<bool>(
      builder: (_) => DiagnosticBlockPage(store: store),
    ),
  );
  return close == true;
}

/// « Rien ne partira » — l'explication du refus, plutôt qu'un écran qui ne
/// s'ouvre pas sans raison visible.
void showDiagnosticDeclined(BuildContext context) {
  final l10n = context.l10n;
  showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 28.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.weDxDeclinedTitle, style: AppText.of(sheetContext).h2()),
          SizedBox(height: 12.h),
          Text(l10n.weDxDeclinedBody,
              style: AppText.of(sheetContext).bodySmall()),
        ],
      ),
    ),
  );
}
