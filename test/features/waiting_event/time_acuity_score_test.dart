// L'escalier adaptatif et le seuil qu'il produit.
//
// Ce que ces tests protègent, dans l'ordre d'importance :
//
// 1. L'ESCALIER NE PART PAS À LA DÉRIVE. Une série de coups de chance ne doit
//    pas pouvoir emmener l'écart vers l'imperceptible, ni une série d'erreurs
//    vers le grotesque.
// 2. LA MOYENNE EST GÉOMÉTRIQUE. Sur une échelle multiplicative, une moyenne
//    arithmétique laisse une seule inversion haute emporter le seuil.
// 3. DEUX PARTIES SANS MESURE SONT REFUSÉES : trop peu d'inversions, ou un seuil
//    resté au plafond. Une partie tapée au hasard ne doit rien annoncer.

import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/features/waiting_event/time_estimation/domain/models/time_acuity_score.dart';
import 'package:mentality/features/waiting_event/time_estimation/domain/services/time_staircase.dart';

TimeAcuityScore score(
  List<double> inversions, {
  int correct = 17,
  int answered = 24,
}) =>
    TimeAcuityScore(
      reversals: inversions,
      correctCount: correct,
      answeredCount: answered,
    );

/// Fait jouer [reponses] à un escalier neuf.
TimeStaircase jouer(List<bool> reponses) {
  var e = TimeStaircase.start();
  for (final juste in reponses) {
    e = e.answer(juste);
  }
  return e;
}

void main() {
  group('escalier', () {
    test('part à 60 % d\'écart', () {
      expect(TimeStaircase.start().delta, TimeStaircase.startDelta);
      expect(TimeStaircase.start().reversals, isEmpty);
    });

    test('avant la première inversion, UNE bonne réponse durcit', () {
      // Phase grossière : pas de palier à tenir, on descend tout de suite.
      expect(jouer([true]).delta, closeTo(0.30, 1e-9));
      expect(jouer([true, true]).delta, closeTo(0.15, 1e-9));
    });

    test('★ après la première inversion, il faut DEUX bonnes de suite', () {
      // true → descend ; false → remonte (première inversion) ; puis une seule
      // bonne réponse ne doit plus rien bouger.
      final apresInversion = jouer([true, false]);
      expect(apresInversion.reversals, hasLength(1));
      final uneBonne = apresInversion.answer(true);
      expect(uneBonne.delta, apresInversion.delta,
          reason: 'une seule bonne réponse a durci');
      expect(uneBonne.answer(true).delta, lessThan(apresInversion.delta));
    });

    test('une erreur relâche toujours, sans palier à tenir', () {
      final apres = jouer([true, false, true, true, false]);
      final avant = jouer([true, false, true, true]);
      expect(apres.delta, greaterThan(avant.delta));
    });

    test('l\'inversion est relevée AVANT le mouvement', () {
      // À 0,15 la personne se trompe : le point de retournement est 0,15, pas la
      // valeur relâchée qui suit.
      final e = jouer([true, true, false]);
      expect(e.reversals, hasLength(1));
      expect(e.reversals.single, closeTo(0.15, 1e-9));
      expect(e.delta, greaterThan(0.15));
    });

    test('le pas devient fin après la première inversion', () {
      final grossier = jouer([true]).delta; // 0,60 / 2
      expect(grossier, closeTo(0.30, 1e-9));
      final e = jouer([true, false]); // remonte × 2 → 0,60
      expect(e.delta, closeTo(0.60, 1e-9));
      // Ensuite deux bonnes → ÷ 1,4 seulement.
      expect(e.answer(true).answer(true).delta, closeTo(0.60 / 1.4, 1e-9));
    });

    test('★ trente bonnes réponses ne descendent pas sous le plancher', () {
      final e = jouer(List.filled(30, true));
      expect(e.delta, greaterThanOrEqualTo(TimeStaircase.minDelta));
    });

    test('★ trente erreurs ne montent pas au-dessus du plafond', () {
      final e = jouer(List.filled(30, false));
      expect(e.delta, lessThanOrEqualTo(TimeStaircase.maxDelta));
    });

    test('★ le régime d\'une personne assise sur son seuil converge', () {
      // Deux bonnes puis une erreur, en boucle : c'est ce que produit quelqu'un
      // qui répond juste environ deux fois sur trois, soit exactement le niveau
      // de justesse vers lequel la règle « deux bonnes pour durcir » attire.
      // Une vraie partie doit y produire de quoi mesurer.
      final e = jouer([for (var i = 0; i < 24; i++) i % 3 != 2]);
      expect(e.reversals.length,
          greaterThanOrEqualTo(TimeAcuityScore.minUsableReversals + 1));
      final s = score(e.reversals);
      expect(s.isReliable, isTrue);
    });

    test('★ une alternance stricte ne produit AUCUNE mesure', () {
      // Juste-faux-juste-faux n'atteint jamais deux bonnes de suite : l'escalier
      // ne redescend plus, il monte jusqu'au plafond et n'inverse plus. C'est le
      // comportement voulu — une réponse sur deux au hasard n'est pas un seuil,
      // et le résultat doit être refusé plutôt qu'arrondi en chiffre.
      final e = jouer([for (var i = 0; i < 24; i++) i.isEven]);
      expect(e.delta, TimeStaircase.maxDelta);
      expect(score(e.reversals).isReliable, isFalse);
    });
  });

  group('seuil', () {
    test('la première inversion est jetée', () {
      // 0,50 est la descente initiale : elle ne dit pas où l'on hésite.
      final s = score([0.50, 0.10, 0.10, 0.10, 0.10]);
      expect(s.usableReversals, hasLength(4));
      expect(s.thresholdPercent, 10);
    });

    test('★ la moyenne est GÉOMÉTRIQUE, pas arithmétique', () {
      // 5 % et 45 % : l'arithmétique rendrait 25 %, qui n'est au milieu de rien.
      final s = score([0.99, 0.05, 0.45, 0.05, 0.45, 0.05, 0.45]);
      expect(s.thresholdPercent, 15);
    });

    test('un seuil fin reste fin', () {
      expect(score([0.40, 0.06, 0.06, 0.06, 0.06]).thresholdPercent, 6);
    });

    test('★ sous quatre inversions exploitables, rien n\'est annoncé', () {
      expect(score([0.40, 0.10, 0.10, 0.10]).isReliable, isFalse);
      expect(score([0.40, 0.10, 0.10, 0.10, 0.10]).isReliable, isTrue);
    });

    test('★ un seuil resté au plafond n\'est pas une mesure', () {
      // Quelqu'un qui ne distinguerait pas 800 ms de 1500 ms n'a pas regardé
      // l'écran. Le chiffre existe, il ne veut rien dire.
      final hasard = score([0.90, 0.85, 0.90, 0.85, 0.90, 0.85]);
      expect(hasard.thresholdDelta,
          greaterThan(TimeAcuityScore.maxMeaningfulDelta));
      expect(hasard.isReliable, isFalse);
    });

    test('une partie vide ne casse pas le calcul', () {
      final vide = score(const [], correct: 0, answered: 0);
      expect(vide.isReliable, isFalse);
      expect(vide.thresholdPercent, 0);
      expect(vide.accuracyPercent, 0);
    });

    test('la justesse est rapportée à part', () {
      expect(score([0.4, 0.1, 0.1, 0.1, 0.1], correct: 18, answered: 24)
          .accuracyPercent, 75);
    });
  });
}
