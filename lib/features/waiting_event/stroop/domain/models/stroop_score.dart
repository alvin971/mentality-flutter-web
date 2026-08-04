// Le score du Stroop — un ÉCART, jamais une vitesse.
//
// ═══ LA RÈGLE QUI JUSTIFIE TOUT CE FICHIER ═══
//
// Le score affiché est `conflit − neutre`, en millisecondes. Il n'est JAMAIS
// la vitesse brute, et ce n'est pas une préférence de présentation : c'est ce
// qui empêche ce jeu de faire doublon avec la batterie.
//
// La batterie mesure déjà la vitesse de traitement (indice PSI, deux
// sous-tests chronométrés). Un jeu noté « tu as répondu en 640 ms en moyenne »
// remesurerait le PSI sous un autre nom — deux mesures de la même chose,
// présentées comme deux informations différentes. La DIFFÉRENCE entre les deux
// conditions, elle, soustrait tout ce que les deux ont en commun : l'acuité
// visuelle, la vitesse motrice, la familiarité de l'écran, la fatigue du jour,
// et la vitesse de traitement elle-même. Ce qui reste est le surcoût propre à
// l'inhibition — orthogonal à la batterie.
//
// Conséquence directe, encodée par un test : deux passations menées l'une à
// 500/700 ms et l'autre à 900/1100 ms donnent le MÊME score (200 ms). Quelqu'un
// de globalement lent n'a pas un « mauvais » Stroop.
//
// ═══ CE QUI ENTRE DANS LES MÉDIANES ═══
//
// · Les essais SCORÉS seulement : l'entraînement est écarté (les premiers
//   essais mesurent la découverte de l'écran, pas l'inhibition).
// · Les essais CORRECTS seulement. Une erreur n'est pas une réponse lente,
//   c'est une autre réponse : son temps ne dit rien du coût d'inhiber. La
//   justesse est rapportée à part, jamais fondue dans le temps.
// · Les temps PLAUSIBLES seulement, entre [minPlausibleMs] et
//   [maxPlausibleMs]. En deçà, l'appui précède la lecture du stimulus (on
//   tapait déjà) ; au-delà, l'attention était ailleurs. Les deux
//   empoisonneraient une moyenne — et l'un d'eux ferait joli au classement.
//
// ═══ MÉDIANE, PAS MOYENNE ═══
//
// Une seule distraction de trois secondes déplace une moyenne de 18 essais de
// plus de 100 ms — soit l'ordre de grandeur de l'effet qu'on cherche à
// mesurer. La médiane, elle, ne bouge pas. C'est l'usage en chronométrie de
// temps de réaction, et ici c'est ce qui empêche le bruit d'être lu comme un
// résultat.

import 'package:equatable/equatable.dart';

import 'stroop_trial.dart';

class StroopScore extends Equatable {
  const StroopScore({
    required this.neutralMedianMs,
    required this.conflictMedianMs,
    required this.validNeutral,
    required this.validConflict,
    required this.correctCount,
    required this.scoredCount,
  });

  /// En deçà, l'appui n'est pas une réponse au stimulus : il a été lancé
  /// avant qu'on ait pu le voir. Seuil usuel en chronométrie.
  static const int minPlausibleMs = 150;

  /// Au-delà, l'attention a décroché. L'essai compte pour la justesse, jamais
  /// pour le temps.
  static const int maxPlausibleMs = 3000;

  /// En dessous de ce nombre d'essais valides PAR CONDITION, une médiane ne
  /// veut plus rien dire. On préfère ne rien annoncer plutôt qu'annoncer un
  /// chiffre que le hasard suffirait à expliquer.
  static const int minTrialsPerCondition = 8;

  final int neutralMedianMs;
  final int conflictMedianMs;
  final int validNeutral;
  final int validConflict;

  /// Réponses justes parmi les essais scorés — l'entraînement exclu.
  final int correctCount;

  /// Nombre d'essais scorés présentés.
  final int scoredCount;

  /// ★ LE SCORE. Le surcoût, en millisecondes, de nommer une couleur quand un
  /// mot dit le contraire. Plus il est bas, plus l'inhibition est efficace.
  ///
  /// Peut être NÉGATIF, et ce n'est pas une anomalie à corriger : quelques
  /// personnes sont un peu plus rapides en conflit (l'attention s'y mobilise
  /// davantage). Ramener ces valeurs à zéro inventerait un plancher qui
  /// n'existe pas.
  int get interferenceMs => conflictMedianMs - neutralMedianMs;

  /// Y a-t-il de quoi annoncer un écart ? Sinon, l'écran le dit et propose de
  /// rejouer — il n'affiche pas un chiffre en s'excusant.
  bool get isReliable =>
      validNeutral >= minTrialsPerCondition &&
      validConflict >= minTrialsPerCondition;

  /// Justesse en pourcentage entier, 0 quand rien n'a été présenté.
  int get accuracyPercent =>
      scoredCount == 0 ? 0 : ((correctCount * 100) / scoredCount).round();

  /// Calcule le score d'une passation.
  ///
  /// [responses] peut contenir l'entraînement et les erreurs : le tri est fait
  /// ici, en un seul endroit, pour qu'aucun appelant n'ait à s'en souvenir.
  factory StroopScore.of(List<StroopResponse> responses) {
    final scorees = responses.where((r) => r.trial.scored).toList();

    List<int> temps(StroopCondition condition) => [
          for (final r in scorees)
            if (r.trial.condition == condition &&
                r.isCorrect &&
                r.elapsedMs >= minPlausibleMs &&
                r.elapsedMs <= maxPlausibleMs)
              r.elapsedMs,
        ];

    final neutres = temps(StroopCondition.neutral);
    final conflits = temps(StroopCondition.conflict);

    return StroopScore(
      neutralMedianMs: medianOf(neutres),
      conflictMedianMs: medianOf(conflits),
      validNeutral: neutres.length,
      validConflict: conflits.length,
      correctCount: scorees.where((r) => r.isCorrect).length,
      scoredCount: scorees.length,
    );
  }

  /// La médiane d'une liste de temps, arrondie à l'entier. `0` sur une liste
  /// vide — la fiabilité, elle, se lit dans [isReliable], jamais dans une
  /// valeur sentinelle.
  ///
  /// Trie une COPIE : une fonction de lecture qui réordonne l'argument de son
  /// appelant est un piège qu'on ne voit qu'une fois posé.
  static int medianOf(List<int> valeurs) {
    if (valeurs.isEmpty) return 0;
    final tries = [...valeurs]..sort();
    final milieu = tries.length ~/ 2;
    return tries.length.isOdd
        ? tries[milieu]
        : ((tries[milieu - 1] + tries[milieu]) / 2).round();
  }

  @override
  List<Object?> get props => [
        neutralMedianMs,
        conflictMedianMs,
        validNeutral,
        validConflict,
        correctCount,
        scoredCount,
      ];
}
