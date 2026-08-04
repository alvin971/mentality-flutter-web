// Description d'une journée de l'événement d'attente des 8 jours.
//
// Ce fichier ne décrit que la STRUCTURE d'une journée — ce qu'elle contient et
// comment elle se présente. Les questions, leurs échelles et leur cotation
// arrivent avec le moteur de questionnaire ; les textes affichés vivent dans
// les ARB, jamais ici.

import 'package:equatable/equatable.dart';

/// Le morceau du profil cognitif — DÉJÀ gagné pendant le test — rendu ce
/// jour-là. C'est le cadeau quotidien : l'utilisateur ne fait rien, il
/// découvre. Les valeurs correspondent aux indices calculés par la batterie.
enum RevealKind {
  /// Indice de compréhension verbale.
  vci,

  /// Vitesse de traitement.
  psi,

  /// Mémoire de travail.
  wmi,

  /// Raisonnement fluide.
  fri,

  /// Indice visuo-spatial.
  vsi,

  /// Comparaison des cinq indices entre eux.
  strengths,

  /// QI global — la récompense du dernier jour.
  fullIq,
}

/// Cadrage de l'activité principale du jour.
///
/// La distinction est CONTRACTUELLE, pas cosmétique : elle décide si un
/// résultat est promis à l'utilisateur. Un test annoncé affiche un score et un
/// seuil ; une contribution n'en affiche aucun et le dit d'emblée, parce qu'on
/// ne fait pas attendre un résultat qui n'existe pas encore.
enum DayActivityKind {
  /// « Ton résultat » — instrument validé, score et seuil affichés.
  announced,

  /// « Aide-nous à construire notre test » — questions candidates, aucun score.
  contribution,

  /// Récompense finale, sans questions.
  share,
}

/// Jeu du jour. Aucun ne recoupe les sous-tests de la batterie.
enum GameKind {
  /// Inhibition — score en ÉCART conflit/neutre, jamais en vitesse brute.
  stroop,

  /// Impulsivité de choix (« 100 € maintenant ou 150 € dans un mois »).
  delayChoice,

  /// Perception des durées.
  timeEstimation,

  /// Métacognition — quiz d'estimations, jamais de culture générale.
  confidenceCalibration,
}

/// Une journée du programme, telle que le hub l'annonce.
class EventDay extends Equatable {
  const EventDay({
    required this.day,
    this.reveal,
    this.activityKind,
    this.game,
    this.questionCount = 0,
  });

  /// 1..8, aligné sur le jour serveur (`UnlockProgress.dayIndex`, où 9 signifie
  /// que l'événement est derrière nous).
  final int day;

  /// `null` le seul jour qui n'en a pas : le bilan autisme (J7) est le jour
  /// vedette, aucune révélation ne vient lui faire concurrence.
  final RevealKind? reveal;

  final DayActivityKind? activityKind;

  /// `null` les jours sans jeu.
  final GameKind? game;

  /// Volume du questionnaire du jour. La règle du programme est de 40 à 50
  /// questions par test ; une garde de test le vérifie pour chaque journée.
  final int questionCount;

  @override
  List<Object?> get props => [day, reveal, activityKind, game, questionCount];
}
