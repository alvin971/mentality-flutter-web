// L'escalier d'ajustement et la partie — la mécanique qui cerne un point de
// bascule en quatre choix.
//
// Ce que ces tests protègent :
//
// 1. LES MONTANTS RESTENT DANS (0 ; 150). Aucune pince ne les y maintient : ce
//    sont les paramètres eux-mêmes qui le garantissent. Ce test est donc la
//    SEULE chose qui casse si quelqu'un porte `stepsPerDelay` à six — sans lui,
//    l'écran proposerait un jour « -2 € tout de suite ».
// 2. L'ESCALIER CONVERGE dans les deux sens.
// 3. LES POSITIONS ALTERNENT et les délais sont mélangés — sinon on répond à
//    l'endroit, ou à une pente, plutôt qu'à la question.

import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/features/waiting_event/delay_choice/domain/services/delay_choice_run.dart';
import 'package:mentality/features/waiting_event/delay_choice/domain/services/delay_choice_staircase.dart';

/// Joue une partie entière avec la même réponse à chaque fois.
DelayChoiceRun jouerTout(DelayChoiceRun run, bool toutDeSuite) {
  var partie = run;
  while (!partie.isDone) {
    partie = partie.answer(toutDeSuite);
  }
  return partie;
}

void main() {
  group('escalier', () {
    DelayChoiceStaircase depart() => DelayChoiceStaircase.start(
          delayDays: 30,
          delayedAmount: DelayChoiceRun.delayedAmount,
          answers: DelayChoiceRun.stepsPerDelay,
        );

    test('part à la moitié de la somme différée', () {
      expect(depart().immediateAmount, 75);
      expect(depart().step, 38);
    });

    test('« tout de suite » fait BAISSER l\'offre immédiate', () {
      expect(depart().answer(true).immediateAmount, 75 - 38);
    });

    test('« plus tard » fait MONTER l\'offre immédiate', () {
      expect(depart().answer(false).immediateAmount, 75 + 38);
    });

    test('le pas est chaque fois la moitié du précédent', () {
      var e = depart();
      final pas = <int>[e.step];
      for (var i = 0; i < 3; i++) {
        e = e.answer(true);
        pas.add(e.step);
      }
      expect(pas, [38, 19, 10, 5]);
    });

    test('★ toujours « tout de suite » : le montant reste au-dessus de zéro',
        () {
      var e = depart();
      for (var i = 0; i < DelayChoiceRun.stepsPerDelay; i++) {
        e = e.answer(true);
        expect(e.immediateAmount, greaterThan(0));
      }
      expect(e.isDone, isTrue);
      expect(e.indifferenceAmount, 3);
    });

    test('★ toujours « plus tard » : le montant reste sous la somme différée',
        () {
      var e = depart();
      for (var i = 0; i < DelayChoiceRun.stepsPerDelay; i++) {
        e = e.answer(false);
        expect(e.immediateAmount, lessThan(DelayChoiceRun.delayedAmount));
      }
      expect(e.indifferenceAmount, 147);
    });

    test('des réponses alternées convergent vers le milieu', () {
      final e = depart().answer(true).answer(false).answer(true).answer(false);
      // 75 → 37 → 56 → 46 → 51 : la fourchette se resserre autour de la moitié.
      expect(e.indifferenceAmount, inInclusiveRange(45, 60));
    });
  });

  group('partie', () {
    test('vingt choix : cinq délais, quatre chacun', () {
      final run = DelayChoiceRun.start(seed: 7);
      expect(run.totalTrials, 20);
      expect(run.stairs.length, 5);
    });

    test('un délai est mené à son terme avant de passer au suivant', () {
      var partie = DelayChoiceRun.start(seed: 7);
      final premier = partie.offer!.delayDays;
      for (var i = 0; i < DelayChoiceRun.stepsPerDelay; i++) {
        expect(partie.offer!.delayDays, premier, reason: 'essai $i');
        partie = partie.answer(true);
      }
      expect(partie.offer!.delayDays, isNot(premier));
    });

    test('★ l\'ordre des délais est mélangé', () {
      // Présentés du plus court au plus long, ils dessinent une pente qu'on
      // suit sans plus lire les offres.
      final ordre = [
        for (final e in DelayChoiceRun.start(seed: 7).stairs) e.delayDays,
      ];
      expect(ordre.toSet(), DelayChoiceRun.delaysDays.toSet());
      expect(ordre, isNot(DelayChoiceRun.delaysDays));
    });

    test('★ les positions sont équilibrées et sans longue série', () {
      for (final graine in [1, 7, 99, 4242]) {
        final positions = DelayChoiceRun.start(seed: graine).immediateOnTop;
        expect(positions.where((p) => p).length, positions.length ~/ 2,
            reason: 'graine $graine');
        var serie = 1;
        for (var i = 1; i < positions.length; i++) {
          serie = positions[i] == positions[i - 1] ? serie + 1 : 1;
          expect(serie, lessThanOrEqualTo(DelayChoiceRun.maxSameSideRun),
              reason: 'graine $graine, essai $i');
        }
      }
    });

    test('la somme différée ne bouge jamais', () {
      var partie = DelayChoiceRun.start(seed: 7);
      while (!partie.isDone) {
        expect(partie.offer!.delayedAmount, DelayChoiceRun.delayedAmount);
        partie = partie.answer(partie.answered.isEven);
      }
    });

    test('l\'offre immédiate est toujours strictement sous la différée', () {
      var partie = DelayChoiceRun.start(seed: 7);
      while (!partie.isDone) {
        final offre = partie.offer!;
        expect(offre.immediateAmount, greaterThan(0));
        expect(offre.immediateAmount, lessThan(offre.delayedAmount));
        partie = partie.answer(partie.answered % 3 == 0);
      }
    });

    test('les points d\'indifférence arrivent rangés par délai', () {
      final finie = jouerTout(DelayChoiceRun.start(seed: 7), true);
      expect(finie.indifferencePoints.keys.toList(),
          [...DelayChoiceRun.delaysDays]..sort());
    });

    test('une partie abandonnée ne rend que les délais terminés', () {
      var partie = DelayChoiceRun.start(seed: 7);
      for (var i = 0; i < DelayChoiceRun.stepsPerDelay * 2; i++) {
        partie = partie.answer(true);
      }
      expect(partie.indifferencePoints.length, 2);
      expect(partie.isDone, isFalse);
    });

    test('★ la même graine rejoue exactement la même partie', () {
      final a = DelayChoiceRun.start(seed: 4242);
      final b = DelayChoiceRun.start(seed: 4242);
      expect([for (final e in a.stairs) e.delayDays],
          [for (final e in b.stairs) e.delayDays]);
      expect(a.immediateOnTop, b.immediateOnTop);
    });

    test('deux graines donnent deux parties différentes', () {
      final a = DelayChoiceRun.start(seed: 1);
      final b = DelayChoiceRun.start(seed: 2);
      expect(
        [for (final e in a.stairs) e.delayDays] == //
            [for (final e in b.stairs) e.delayDays],
        isFalse,
      );
    });

    test('répondre ne modifie pas la partie précédente', () {
      final avant = DelayChoiceRun.start(seed: 7);
      final apres = avant.answer(true);
      expect(avant.answered, 0);
      expect(apres.answered, 1);
      expect(avant.offer, isNot(apres.offer));
    });
  });
}
