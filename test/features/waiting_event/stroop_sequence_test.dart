// Les propriétés de la séquence — celles qu'aucun écran ne trahirait.
//
// Un bloc où une encre domine, ou une série de cinq fois la même couleur : rien
// ne se voit à l'affichage, et pourtant l'écart mesuré cesse de vouloir dire ce
// qu'on croit. C'est le même genre de garde que l'ordre d'une journée — elle
// porte sur une donnée, pas sur des pixels.

import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/features/waiting_event/stroop/domain/models/stroop_trial.dart';
import 'package:mentality/features/waiting_event/stroop/domain/services/stroop_sequence.dart';

/// Toutes les graines d'un balayage : les propriétés doivent tenir pour
/// CHAQUE passation, pas seulement pour une graine bien choisie.
final graines = List<int>.generate(120, (i) => i * 7 + 1);

List<StroopTrial> blocNeutre(List<StroopTrial> essais) => essais
    .sublist(StroopSequence.practiceCount,
        StroopSequence.practiceCount + StroopSequence.blockLength);

List<StroopTrial> blocConflit(List<StroopTrial> essais) =>
    essais.sublist(StroopSequence.practiceCount + StroopSequence.blockLength);

int serieMax(List<StroopTrial> essais) {
  var max = 1, courante = 1;
  for (var i = 1; i < essais.length; i++) {
    courante = essais[i].ink == essais[i - 1].ink ? courante + 1 : 1;
    if (courante > max) max = courante;
  }
  return max;
}

void main() {
  group('structure de la passation', () {
    test('entraînement puis neutre puis conflit, dans cet ordre', () {
      final essais = StroopSequence.build(seed: 42);

      expect(essais, hasLength(StroopSequence.totalTrials));
      expect(
        essais.take(StroopSequence.practiceCount).every((e) => !e.scored),
        isTrue,
        reason: 'les premiers essais mesurent la découverte de l\'écran',
      );
      expect(blocNeutre(essais).every((e) => e.scored), isTrue);
      expect(blocConflit(essais).every((e) => e.scored), isTrue);
      expect(
        blocNeutre(essais)
            .every((e) => e.condition == StroopCondition.neutral),
        isTrue,
      );
      expect(
        blocConflit(essais)
            .every((e) => e.condition == StroopCondition.conflict),
        isTrue,
      );
    });

    test('l\'entraînement est en neutre — on ne s\'entraîne pas au conflit',
        () {
      final essais = StroopSequence.build(seed: 3);

      expect(
        essais
            .take(StroopSequence.practiceCount)
            .every((e) => e.condition == StroopCondition.neutral),
        isTrue,
      );
    });

    test('les deux blocs comptés ont exactement la même longueur', () {
      final essais = StroopSequence.build(seed: 11);

      expect(blocNeutre(essais).length, blocConflit(essais).length,
          reason: 'des blocs inégaux donneraient deux médianes de précisions '
              'différentes, et l\'écart hériterait de la moins bonne');
    });
  });

  group('en conflit, le mot contredit TOUJOURS l\'encre', () {
    test('aucun essai congruent ne se glisse dans le bloc', () {
      for (final graine in graines) {
        for (final essai in blocConflit(StroopSequence.build(seed: graine))) {
          expect(essai.word, isNotNull);
          expect(essai.word, isNot(essai.ink),
              reason: 'un essai congruent est plus RAPIDE : il abaisserait la '
                  'médiane du bloc de conflit, donc l\'écart mesuré — sans que '
                  'rien à l\'écran ne le signale (graine $graine)');
        }
      }
    });

    test('les mots ne sont pas toujours les mêmes pour une encre donnée', () {
      // Si le rouge portait systématiquement « BLEU », l'écart vaudrait pour
      // cette paire-là et pour aucune autre.
      final motsParEncre = <StroopInk, Set<StroopInk>>{};
      for (final graine in graines.take(20)) {
        for (final e in blocConflit(StroopSequence.build(seed: graine))) {
          motsParEncre.putIfAbsent(e.ink, () => {}).add(e.word!);
        }
      }

      for (final encre in StroopInk.values) {
        expect(motsParEncre[encre], hasLength(2),
            reason: 'les DEUX autres couleurs doivent servir de mot pour $encre');
      }
    });
  });

  group('équilibre et répétitions', () {
    test('chaque encre revient le même nombre de fois dans chaque bloc', () {
      final attendu = StroopSequence.blockLength ~/ StroopInk.values.length;

      for (final graine in graines) {
        final essais = StroopSequence.build(seed: graine);
        for (final bloc in [blocNeutre(essais), blocConflit(essais)]) {
          for (final encre in StroopInk.values) {
            expect(bloc.where((e) => e.ink == encre).length, attendu,
                reason: 'un bloc déséquilibré compare deux couleurs plutôt que '
                    'deux conditions (graine $graine)');
          }
        }
      }
    });

    test('jamais plus de deux fois la même encre d\'affilée', () {
      for (final graine in graines) {
        final essais = StroopSequence.build(seed: graine);
        for (final bloc in [blocNeutre(essais), blocConflit(essais)]) {
          expect(serieMax(bloc), lessThanOrEqualTo(StroopSequence.maxRun),
              reason: 'au-delà, on répond sans regarder — le bouton est déjà '
                  'sous le doigt (graine $graine)');
        }
      }
    });
  });

  test('la séquence est reproductible à graine égale, et varie sinon', () {
    expect(StroopSequence.build(seed: 7), StroopSequence.build(seed: 7));

    final distinctes = {
      for (final graine in graines.take(30))
        StroopSequence.build(seed: graine).map((e) => e.ink.name).join()
    };
    expect(distinctes.length, greaterThan(20),
        reason: 'deux personnes ne doivent pas jouer la même partie');
  });
}
