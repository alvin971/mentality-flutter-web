// L'interrupteur de l'événement d'attente des 8 jours.
//
// ## Ce qu'il fait
//
// `false` retire l'UNIQUE porte d'entrée du programme : le bouton « Voir le
// programme du jour » de la carte d'attente (`unlock_gate_page.dart`). Tout
// le reste — hub des 8 jours, révélations, auto-estimation du QI, IPIP-50,
// bloc diagnostic, jeux Stroop / délai / durées — n'est atteignable QUE par
// cette porte. La fermer les rend tous inaccessibles d'un coup, sans qu'aucune
// ligne ne soit supprimée.
//
// Pendant les 8 jours, l'utilisateur voit donc exactement ce qu'il voyait
// avant : le décompte, et rien d'autre. C'est un choix de lancement — un
// programme de huit journées à remplir est beaucoup à assumer pour un début.
//
// ## Ce qu'il ne fait PAS
//
// · Il ne supprime rien. Le code, ses tests et ses contenus restent dans la
//   branche, vérifiés à chaque exécution de la suite. Rallumer l'événement est
//   un changement d'une ligne, ici.
// · Il ne touche pas au serveur. `workers/referral` continue de calculer
//   `dayIndex` (c'est additif, et il faudra bien qu'il soit là le jour où l'on
//   rallume) ; le client le reçoit et n'en fait simplement rien.
//   `workers/event` n'a jamais été déployé.
// · Il n'empêche pas un envoi : il rend l'envoi IMPOSSIBLE, ce qui est plus
//   fort. Aucun écran qui alimente `EventUploadService` n'est atteignable,
//   donc rien n'entre jamais dans la file.
//
// ## Pour rallumer
//
// Passer [kWaitingEventEnabled] à `true`, puis mettre à jour la garde de
// `waiting_event_feature_test.dart` qui épingle sa valeur — elle est là pour
// qu'un rallumage soit une DÉCISION, jamais un effet de bord. Vérifier avant
// que `AppConstants.eventWorkerUrl` ne soit plus un gabarit et que
// `workers/event` soit déployé, sans quoi les réponses s'empileraient dans la
// file locale sans jamais partir.

/// L'événement d'attente est-il proposé à l'utilisateur ?
///
/// `const` à dessein : le compilateur peut alors éliminer la branche morte, et
/// le programme ne pèse rien dans le binaire tant qu'il est éteint.
const bool kWaitingEventEnabled = false;
