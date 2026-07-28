// LA garde de ce lot : le score du Stroop est un ÉCART, jamais une vitesse.
//
// Le plan produit l'écrit noir sur blanc, et la raison est structurelle : la
// batterie mesure déjà la vitesse de traitement (indice PSI). Un jeu noté à la
// vitesse brute remesurerait le PSI sous un autre nom, et le catalogue
// afficherait deux fois la même chose comme deux informations distinctes.
//
// Le test central est `deux passations de vitesses très différentes mais de
// même écart donnent le MÊME score`. Il tomberait au premier retour à une
// notation en vitesse — y compris à une notation « mixte » qui pondérerait
// l'écart par le temps moyen.

import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/features/waiting_event/stroop/domain/models/stroop_score.dart';
import 'package:mentality/features/waiting_event/stroop/domain/models/stroop_trial.dart';

/// Une réponse JUSTE en [ms] dans la condition demandée.
StroopResponse juste(StroopCondition condition, int ms, {bool scored = true}) {
  final trial = condition == StroopCondition.neutral
      ? StroopTrial.neutral(StroopInk.bleu, scored: scored)
      : StroopTrial.conflict(
          ink: StroopInk.bleu, word: StroopInk.rouge, scored: scored);
  return StroopResponse(trial: trial, chosen: StroopInk.bleu, elapsedMs: ms);
}

/// Une réponse FAUSSE en [ms] : l'encre est bleue, on a désigné le rouge.
StroopResponse fausse(StroopCondition condition, int ms) {
  final trial = condition == StroopCondition.neutral
      ? const StroopTrial.neutral(StroopInk.bleu)
      : const StroopTrial.conflict(ink: StroopInk.bleu, word: StroopInk.rouge);
  return StroopResponse(trial: trial, chosen: StroopInk.rouge, elapsedMs: ms);
}

/// [n] réponses justes à [ms] dans [condition].
List<StroopResponse> serie(StroopCondition condition, int ms, {int n = 12}) =>
    [for (var i = 0; i < n; i++) juste(condition, ms)];

void main() {
  group('le score est un écart, pas une vitesse', () {
    test('l\'écart est conflit − neutre', () {
      final score = StroopScore.of([
        ...serie(StroopCondition.neutral, 600),
        ...serie(StroopCondition.conflict, 780),
      ]);

      expect(score.interferenceMs, 180);
    });

    test('★ deux passations de vitesses opposées, même écart, MÊME score', () {
      // Quelqu'un de globalement rapide…
      final rapide = StroopScore.of([
        ...serie(StroopCondition.neutral, 480),
        ...serie(StroopCondition.conflict, 680),
      ]);
      // …et quelqu'un de globalement lent, au surcoût identique.
      final lent = StroopScore.of([
        ...serie(StroopCondition.neutral, 1100),
        ...serie(StroopCondition.conflict, 1300),
      ]);

      expect(rapide.interferenceMs, lent.interferenceMs,
          reason: 'un score qui les sépare est un score de VITESSE — il '
              'ferait doublon avec le PSI de la batterie');
      expect(rapide.interferenceMs, 200);
    });

    test('un écart négatif est rendu tel quel, jamais ramené à zéro', () {
      final score = StroopScore.of([
        ...serie(StroopCondition.neutral, 800),
        ...serie(StroopCondition.conflict, 740),
      ]);

      expect(score.interferenceMs, -60,
          reason: 'rare mais réel ; un plancher à zéro serait inventé');
    });
  });

  group('ce qui entre dans les médianes', () {
    test('les essais d\'entraînement sont écartés', () {
      final score = StroopScore.of([
        // Trois essais d'entraînement très lents — ceux où l'on cherche
        // encore ses boutons.
        juste(StroopCondition.neutral, 2500, scored: false),
        juste(StroopCondition.neutral, 2400, scored: false),
        juste(StroopCondition.neutral, 2600, scored: false),
        ...serie(StroopCondition.neutral, 600),
        ...serie(StroopCondition.conflict, 800),
      ]);

      expect(score.neutralMedianMs, 600);
      expect(score.scoredCount, 24, reason: 'l\'entraînement ne compte pas '
          'non plus dans la justesse');
    });

    test('les erreurs sont hors médiane mais comptent dans la justesse', () {
      final score = StroopScore.of([
        ...serie(StroopCondition.neutral, 600),
        // Une erreur très rapide : incluse, elle tirerait la médiane vers le
        // bas et ferait passer une réponse au hasard pour de la performance.
        fausse(StroopCondition.neutral, 200),
        ...serie(StroopCondition.conflict, 800),
      ]);

      expect(score.neutralMedianMs, 600);
      expect(score.validNeutral, 12, reason: 'l\'erreur n\'est pas un temps');
      expect(score.correctCount, 24);
      expect(score.scoredCount, 25);
      expect(score.accuracyPercent, 96);
    });

    test('les temps implausibles sont écartés des deux côtés', () {
      final score = StroopScore.of([
        ...serie(StroopCondition.neutral, 600),
        juste(StroopCondition.neutral, 40), // on tapait déjà
        juste(StroopCondition.neutral, 9000), // l'attention est ailleurs
        ...serie(StroopCondition.conflict, 800),
      ]);

      expect(score.validNeutral, 12);
      expect(score.neutralMedianMs, 600);
      expect(score.correctCount, 26,
          reason: 'ils restent des réponses justes — seul leur TEMPS est '
              'inexploitable');
    });

    test('les bornes de plausibilité sont inclusives', () {
      final score = StroopScore.of([
        ...serie(StroopCondition.neutral, StroopScore.minPlausibleMs, n: 6),
        ...serie(StroopCondition.neutral, StroopScore.maxPlausibleMs, n: 6),
        ...serie(StroopCondition.conflict, 800),
      ]);

      expect(score.validNeutral, 12);
    });
  });

  group('médiane, pas moyenne', () {
    test('une seule distraction ne déplace pas le score', () {
      final propre = StroopScore.of([
        ...serie(StroopCondition.neutral, 600),
        ...serie(StroopCondition.conflict, 800),
      ]);
      final avecUneDistraction = StroopScore.of([
        ...serie(StroopCondition.neutral, 600, n: 11),
        juste(StroopCondition.neutral, 2900), // dans les bornes, mais énorme
        ...serie(StroopCondition.conflict, 800),
      ]);

      expect(avecUneDistraction.interferenceMs, propre.interferenceMs,
          reason: 'une moyenne aurait bougé d\'environ 190 ms — soit '
              'l\'ordre de grandeur de l\'effet mesuré');
    });

    test('la médiane d\'un nombre pair de valeurs est la moyenne des deux du '
        'milieu, arrondie', () {
      expect(StroopScore.medianOf([100, 200, 300, 401]), 250);
      expect(StroopScore.medianOf([100, 201]), 151);
      expect(StroopScore.medianOf([500]), 500);
      expect(StroopScore.medianOf([]), 0);
    });

    test('le calcul ne réordonne pas la liste de son appelant', () {
      final valeurs = [900, 100, 500];
      StroopScore.medianOf(valeurs);
      expect(valeurs, [900, 100, 500]);
    });
  });

  group('fiabilité', () {
    test('sous le minimum d\'essais valides, rien n\'est annoncé', () {
      final score = StroopScore.of([
        ...serie(StroopCondition.neutral, 600, n: 4),
        ...serie(StroopCondition.conflict, 800, n: 12),
      ]);

      expect(score.isReliable, isFalse);
      expect(score.validNeutral, 4);
    });

    test('une partie où tout est faux n\'est pas fiable', () {
      final score = StroopScore.of([
        for (var i = 0; i < 18; i++) fausse(StroopCondition.neutral, 600),
        for (var i = 0; i < 18; i++) fausse(StroopCondition.conflict, 800),
      ]);

      expect(score.isReliable, isFalse,
          reason: 'aucun temps exploitable : un écart y serait du hasard');
      expect(score.accuracyPercent, 0);
    });

    test('le minimum exact suffit', () {
      final score = StroopScore.of([
        ...serie(StroopCondition.neutral, 600,
            n: StroopScore.minTrialsPerCondition),
        ...serie(StroopCondition.conflict, 800,
            n: StroopScore.minTrialsPerCondition),
      ]);

      expect(score.isReliable, isTrue);
    });

    test('une partie vide ne fait planter ni médiane ni justesse', () {
      final score = StroopScore.of([]);

      expect(score.isReliable, isFalse);
      expect(score.interferenceMs, 0);
      expect(score.accuracyPercent, 0);
    });
  });
}
