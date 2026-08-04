// La partie du jeu des durées — ce qui est tiré d'avance, et ce qui s'adapte.
//
// Ce que ces tests protègent :
//
// 1. LES DEUX DURÉES D'UN ESSAI NE SONT JAMAIS ÉGALES. Un essai sans bonne
//    réponse compterait la personne fausse une fois sur deux pour une raison qui
//    n'a rien à voir avec sa perception. Le risque est réel : sur un standard
//    court et un écart au plancher, un arrondi ordinaire les confond.
// 2. STANDARDS ET POSITIONS SONT ÉQUILIBRÉS, sans longue série — sinon le seuil
//    contient l'échelle de durée dominante, ou se gagne sans regarder.
// 3. LA COMPARAISON EST TOUJOURS LA PLUS LONGUE. C'est la définition de la bonne
//    réponse ; l'inverser silencieusement retournerait toute la justesse.

import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/features/waiting_event/time_estimation/domain/services/time_estimation_run.dart';
import 'package:mentality/features/waiting_event/time_estimation/domain/services/time_staircase.dart';

/// Joue toute la partie en répondant toujours juste.
TimeEstimationRun jouerJuste(TimeEstimationRun run) {
  var partie = run;
  while (!partie.isDone) {
    partie = partie.answer(choseFirst: partie.trial!.comparisonFirst);
  }
  return partie;
}

/// Joue toute la partie en répondant toujours faux.
TimeEstimationRun jouerFaux(TimeEstimationRun run) {
  var partie = run;
  while (!partie.isDone) {
    partie = partie.answer(choseFirst: !partie.trial!.comparisonFirst);
  }
  return partie;
}

void main() {
  group('les essais', () {
    test('vingt-quatre essais, pas un de plus', () {
      final partie = TimeEstimationRun.start(seed: 7);
      expect(partie.standards, hasLength(TimeEstimationRun.trials));
      expect(partie.comparisonFirst, hasLength(TimeEstimationRun.trials));
      expect(jouerJuste(partie).answered, TimeEstimationRun.trials);
    });

    test('★ la comparaison est TOUJOURS strictement plus longue', () {
      // Vérifié sur les deux régimes extrêmes, donc sur toute l'étendue des
      // écarts que l'escalier peut atteindre.
      for (final jouer in [jouerJuste, jouerFaux]) {
        var partie = TimeEstimationRun.start(seed: 7);
        while (!partie.isDone) {
          final essai = partie.trial!;
          expect(essai.comparisonMs, greaterThan(essai.standardMs),
              reason: 'essai ${partie.answered}');
          partie = partie.answer(choseFirst: essai.comparisonFirst);
        }
        jouer(TimeEstimationRun.start(seed: 7));
      }
    });

    test('★ au plancher de l\'escalier, les deux durées restent distinctes', () {
      // 2 % de 600 ms font 12 ms : un arrondi ordinaire les rendrait égales sur
      // les standards les plus courts. C'est le cas limite que le `max` couvre.
      var partie = TimeEstimationRun.start(seed: 7);
      // Trente bonnes réponses écrasent l'escalier sur son plancher.
      for (var i = 0; i < TimeEstimationRun.trials; i++) {
        final essai = partie.trial!;
        expect(essai.comparisonMs, greaterThan(essai.standardMs));
        partie = partie.answer(choseFirst: essai.comparisonFirst);
      }
      expect(partie.staircase.delta, TimeStaircase.minDelta);
    });

    test('l\'écart de l\'essai reflète celui de l\'escalier', () {
      final partie = TimeEstimationRun.start(seed: 7);
      expect(partie.trial!.delta, closeTo(TimeStaircase.startDelta, 0.01));
    });

    test('le premier et le second suivent la position de la comparaison', () {
      final partie = TimeEstimationRun.start(seed: 7);
      final essai = partie.trial!;
      if (essai.comparisonFirst) {
        expect(essai.firstMs, essai.comparisonMs);
        expect(essai.secondMs, essai.standardMs);
      } else {
        expect(essai.firstMs, essai.standardMs);
        expect(essai.secondMs, essai.comparisonMs);
      }
    });

    test('répondre « le premier » est juste quand la comparaison est première',
        () {
      final essai = TimeEstimationRun.start(seed: 7).trial!;
      expect(essai.isCorrect(choseFirst: true), essai.comparisonFirst);
      expect(essai.isCorrect(choseFirst: false), !essai.comparisonFirst);
    });
  });

  group('équilibrages', () {
    test('★ les quatre standards reviennent le même nombre de fois', () {
      for (final graine in [1, 7, 99, 4242]) {
        final standards = TimeEstimationRun.start(seed: graine).standards;
        for (final valeur in TimeEstimationRun.standardsMs) {
          expect(
            standards.where((s) => s == valeur).length,
            TimeEstimationRun.trials ~/ TimeEstimationRun.standardsMs.length,
            reason: 'graine $graine, standard $valeur',
          );
        }
      }
    });

    test('★ aucun standard plus de deux fois d\'affilée', () {
      for (final graine in [1, 7, 99, 4242]) {
        final standards = TimeEstimationRun.start(seed: graine).standards;
        var serie = 1;
        for (var i = 1; i < standards.length; i++) {
          serie = standards[i] == standards[i - 1] ? serie + 1 : 1;
          expect(serie, lessThanOrEqualTo(TimeEstimationRun.maxStandardRun),
              reason: 'graine $graine, essai $i');
        }
      }
    });

    test('★ les positions sont équilibrées et sans longue série', () {
      for (final graine in [1, 7, 99, 4242]) {
        final positions = TimeEstimationRun.start(seed: graine).comparisonFirst;
        expect(positions.where((p) => p).length, positions.length ~/ 2,
            reason: 'graine $graine');
        var serie = 1;
        for (var i = 1; i < positions.length; i++) {
          serie = positions[i] == positions[i - 1] ? serie + 1 : 1;
          expect(serie, lessThanOrEqualTo(TimeEstimationRun.maxSideRun),
              reason: 'graine $graine, essai $i');
        }
      }
    });
  });

  group('reproductibilité', () {
    test('★ la même graine rejoue exactement la même partie', () {
      final a = TimeEstimationRun.start(seed: 4242);
      final b = TimeEstimationRun.start(seed: 4242);
      expect(a.standards, b.standards);
      expect(a.comparisonFirst, b.comparisonFirst);
    });

    test('deux graines donnent deux parties différentes', () {
      final a = TimeEstimationRun.start(seed: 1);
      final b = TimeEstimationRun.start(seed: 2);
      expect(a.standards == b.standards && a.comparisonFirst == b.comparisonFirst,
          isFalse);
    });

    test('répondre ne modifie pas la partie précédente', () {
      final avant = TimeEstimationRun.start(seed: 7);
      final apres = avant.answer(choseFirst: true);
      expect(avant.answered, 0);
      expect(apres.answered, 1);
    });
  });

  group('score de la partie', () {
    test('tout juste : le seuil descend au plus fin', () {
      final finie = jouerJuste(TimeEstimationRun.start(seed: 7));
      expect(finie.correct, TimeEstimationRun.trials);
      // Aucune erreur, donc aucune inversion : rien à annoncer, et c'est correct
      // — un sans-faute ne dit pas où la personne hésite, il dit qu'on n'a pas
      // trouvé sa limite.
      expect(finie.score.isReliable, isFalse);
    });

    test('tout faux : rien n\'est annoncé', () {
      final finie = jouerFaux(TimeEstimationRun.start(seed: 7));
      expect(finie.correct, 0);
      expect(finie.score.isReliable, isFalse);
    });

    test('★ une partie réaliste rend un seuil exploitable', () {
      // Juste deux fois sur trois : le régime vers lequel l'escalier attire.
      var partie = TimeEstimationRun.start(seed: 7);
      while (!partie.isDone) {
        final essai = partie.trial!;
        final juste = partie.answered % 3 != 2;
        partie = partie.answer(
          choseFirst: juste ? essai.comparisonFirst : !essai.comparisonFirst,
        );
      }
      final s = partie.score;
      expect(s.isReliable, isTrue);
      expect(s.thresholdPercent, inExclusiveRange(0, 100));
      expect(s.answeredCount, TimeEstimationRun.trials);
    });
  });
}
