// J1 — « Ta personnalité ». L'IPIP-50 et rien d'autre.
//
// C'est la seule journée du programme dont le test est un instrument validé
// SEUL : cinquante items scorés remplissent exactement la règle de volume
// (40 à 50), donc aucune de nos questions candidates n'a de place ici — et
// c'est tant mieux, parce que J1 ouvre la série. La première chose qu'on
// demande à quelqu'un qui vient de payer 90 minutes de test doit lui rendre
// quelque chose, pas lui prendre encore.
//
// Le bloc diagnostic, lui, se rattache aussi au jour 1 mais n'est PAS dans ce
// module : il a son propre stockage (tout-ou-rien, écriture unique) et son
// propre gate art. 9. Il s'enchaîne à la SORTIE de ce questionnaire.

import '../../_shared/data/question_bank/ipip50.dart';
import '../../_shared/domain/models/event_day.dart';
import '../../_shared/domain/models/q_module.dart';

/// Identifiant de stockage et segment de clé R2. Slug, comme l'exige le
/// worker.
const String kPersonalityModuleId = 'personality';

final QModule personalityModule = QModule(
  id: kPersonalityModuleId,
  day: 1,
  // Annoncé : un score est promis, et il sera affiché (rapport J1, LOT I).
  kind: DayActivityKind.announced,
  instruments: [ipip50],
);
