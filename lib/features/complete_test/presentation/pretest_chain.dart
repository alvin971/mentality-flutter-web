// L'enchaînement « questionnaire préalable → batterie », en un seul endroit.
//
// Il existe pour que l'écran de lancement n'ait pas à connaître la règle
// « quand faut-il poser la question » : elle vit ici, et une seule fois. C'est
// le même découpage que `diagnostic_chain.dart`.
//
// LA QUESTION NE SE REPOSE JAMAIS. Un test interrompu puis repris passe par le
// même bouton ; sans cette garde, on redemanderait son estimation à quelqu'un
// qui a déjà vu des exercices — et à la troisième reprise, la question serait
// devenue un péage. `PretestStore` refuse d'écraser, mais c'est ici qu'on
// évite de POSER la question.

import 'package:flutter/material.dart';

import '../data/pretest_store.dart';
import 'pages/pretest_questionnaire_page.dart';

/// Pose le questionnaire préalable s'il n'a jamais été rempli.
///
/// Renvoie `true` quand la batterie peut démarrer : soit la question était déjà
/// close, soit elle vient de recevoir sa réponse. Renvoie `false` quand
/// l'utilisateur est ressorti sans répondre — la question obligatoire l'est
/// vraiment, et on le ramène à l'écran de lancement plutôt que de démarrer le
/// test derrière son dos.
///
/// Un stockage illisible fait POSER la question (voir `PretestStore.read`) :
/// mieux vaut la reposer une fois de trop que bloquer l'accès au test.
Future<bool> ensurePretest(
  BuildContext context, {
  PretestStore store = const PretestStore(),
}) async {
  final deja = await store.read();
  if (deja.isSettled) return true;
  if (!context.mounted) return false;

  final repondu = await Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => PretestQuestionnairePage(store: store)),
  );
  return repondu == true;
}
