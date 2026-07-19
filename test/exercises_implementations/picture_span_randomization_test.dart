import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/features/exercises_implementations/picture_span/domain/picture_span_generator.dart';

/// Vérifie que Mémoire des Images est ALÉATOIRE PAR PASSATION : deux sessions
/// ne présentent pas les mêmes séquences d'images (avant ce test, les 12
/// essais étaient codés en dur — identiques pour tout le monde), tandis que
/// la STRUCTURE (6 niveaux × 2 essais, temps, thêta) reste fixe.
String _itemSig(PictureSpanItem it) =>
    '${it.targetImageIds.join(",")}|${it.distractorImageIds.join(",")}';

void main() {
  group('PictureSpanGenerator — aléa par passation', () {
    test('deux passations sans seed produisent des essais différents', () {
      final a =
          PictureSpanGenerator().generateComplete12Items().map(_itemSig).toList();
      final b =
          PictureSpanGenerator().generateComplete12Items().map(_itemSig).toList();

      expect(a, isNot(equals(b)),
          reason: 'Deux sessions ne doivent jamais présenter les mêmes '
              'séquences d\'images.');
    });

    test('un même seed explicite est reproductible (tests/diagnostics)', () {
      final a =
          PictureSpanGenerator(seed: 42).generateComplete12Items().map(_itemSig);
      final b =
          PictureSpanGenerator(seed: 42).generateComplete12Items().map(_itemSig);
      expect(a.toList(), equals(b.toList()));
    });

    test('structure invariante : 6 niveaux × 2 essais, cibles/distracteurs cohérents', () {
      for (var seed = 0; seed < 30; seed++) {
        final items = PictureSpanGenerator(seed: seed).generateComplete12Items();
        expect(items.length, 12, reason: 'seed=$seed');

        var index = 0;
        for (var level = 1; level <= 6; level++) {
          for (var trial = 1; trial <= 2; trial++) {
            final it = items[index++];
            expect(it.level, level, reason: 'seed=$seed');
            expect(it.trial, trial, reason: 'seed=$seed');
            expect(it.targetImageIds.length, level,
                reason: 'seed=$seed : niveau $level = $level cibles');
            expect(it.distractorImageIds.length, 8,
                reason: 'seed=$seed : toujours 8 distracteurs');
            expect(it.presentationSeconds, level * 3, reason: 'seed=$seed');

            // Aucun doublon, et aucun chevauchement cibles/distracteurs.
            final targets = it.targetImageIds.toSet();
            final distractors = it.distractorImageIds.toSet();
            expect(targets.length, it.targetImageIds.length,
                reason: 'seed=$seed : cibles toutes distinctes');
            expect(distractors.length, it.distractorImageIds.length,
                reason: 'seed=$seed : distracteurs tous distincts');
            expect(targets.intersection(distractors), isEmpty,
                reason: 'seed=$seed : une cible ne peut pas être distracteur');

            // La grille de rappel est une permutation STABLE de cibles+distracteurs.
            expect(it.recallGridIds.toSet(), targets.union(distractors),
                reason: 'seed=$seed : grille = cibles + distracteurs');
            expect(it.recallGridIds, equals(it.recallGridIds),
                reason: 'seed=$seed');
            final again = it.recallGridIds;
            expect(again, equals(it.recallGridIds),
                reason: 'seed=$seed : l\'ordre de la grille ne doit pas '
                    'changer entre deux lectures (rebuild du widget)');
          }
        }
      }
    });

    test('l\'échelle thêta par niveau est fixe d\'une passation à l\'autre', () {
      final ref = PictureSpanGenerator(seed: 1)
          .generateComplete12Items()
          .map((it) => it.thetaValue)
          .toList();
      for (var seed = 2; seed < 20; seed++) {
        final thetas = PictureSpanGenerator(seed: seed)
            .generateComplete12Items()
            .map((it) => it.thetaValue)
            .toList();
        expect(thetas, equals(ref));
      }
    });
  });
}
