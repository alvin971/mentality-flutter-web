// Le programme des 8 jours — source unique.
//
// Cette table encode le tableau maître du plan produit. Elle décide de ce que
// chaque journée contient ; les modules de questions viendront s'y rattacher.
// Aucun texte affiché ici : le hub lit cette table pour savoir QUOI annoncer,
// et les ARB pour savoir COMMENT le dire.
//
// Ordre du programme, tel qu'arrêté : J1 ouvre sur du valorisant (jamais un
// dépistage clinique en premier), J5 est volontairement léger, l'autisme ferme
// la série en J7, et J8 ne pose aucune question — c'est la récompense.

import '../models/event_day.dart';

abstract final class EventSchedule {
  /// L'événement dure 8 jours. Le serveur renvoie 9 quand il est terminé.
  static const int totalDays = 8;

  static const List<EventDay> days = [
    // Personnalité : IPIP-50 en entier, plus l'auto-estimation du QI qui sera
    // confrontée au QI réel au dernier jour.
    EventDay(
      day: 1,
      reveal: RevealKind.vci,
      activityKind: DayActivityKind.announced,
      questionCount: 50,
    ),
    // Vitesse révélée, Stroop et dyslexie : la lecture, sous trois angles.
    EventDay(
      day: 2,
      reveal: RevealKind.psi,
      activityKind: DayActivityKind.contribution,
      game: GameKind.stroop,
      questionCount: 40,
    ),
    // Mémoire révélée le jour où l'on interroge les plaintes cognitives : le
    // croisement des deux est ce que personne d'autre ne peut afficher.
    EventDay(
      day: 3,
      reveal: RevealKind.wmi,
      activityKind: DayActivityKind.announced,
      questionCount: 45,
    ),
    EventDay(
      day: 4,
      reveal: RevealKind.fri,
      activityKind: DayActivityKind.contribution,
      game: GameKind.delayChoice,
      questionCount: 45,
    ),
    EventDay(
      day: 5,
      reveal: RevealKind.vsi,
      activityKind: DayActivityKind.contribution,
      game: GameKind.timeEstimation,
      questionCount: 40,
    ),
    EventDay(
      day: 6,
      reveal: RevealKind.strengths,
      activityKind: DayActivityKind.announced,
      game: GameKind.confidenceCalibration,
      questionCount: 44,
    ),
    // Jour vedette : aucune révélation ne vient lui faire concurrence.
    EventDay(
      day: 7,
      activityKind: DayActivityKind.announced,
      questionCount: 49,
    ),
    // Zéro question : le QI global, et de quoi le partager.
    EventDay(
      day: 8,
      reveal: RevealKind.fullIq,
      activityKind: DayActivityKind.share,
    ),
  ];

  /// La journée [day] (1..8).
  static EventDay byDay(int day) {
    assert(day >= 1 && day <= totalDays, 'jour hors programme : $day');
    return days[day - 1];
  }
}
