// Conformité du générateur aux recettes de l'échelle (radicaux respectés).
//
// Pour un échantillon de graines : chaque item de la batterie doit respecter
// TOUS les radicaux de sa recette — c'est la garantie « contenu différent,
// difficulté équivalente » entre patients. Vérifie aussi le budget de
// jumeaux (problème n° 1 de l'audit) et la rareté des fallbacks
// (problème n° 4 : plus de piège débutant dans un item dur).

import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/features/exercises_implementations/visual_puzzles/domain/puzzle_generator.dart';

void main() {
  const nSeeds = 40;

  test('chaque item respecte les radicaux de sa recette', () {
    var fallbacks = 0;
    var totalItems = 0;

    for (int seed = 0; seed < nSeeds; seed++) {
      final items = PuzzleGenerator(seed: seed).generateComplete26Items();
      expect(items.length, kLadder.length);

      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        final recipe = kLadder[i];
        final ctx = 'seed=$seed item=${i + 1} (P${recipe.palier})';
        totalItems++;
        if (item.fallbackUsed) fallbacks++;

        // Identité de position.
        expect(item.index, i + 1, reason: ctx);
        expect(item.palier, recipe.palier, reason: ctx);
        expect(item.timeLimitSeconds, recipe.timeLimitSeconds, reason: ctx);

        // Pools de la recette.
        expect(recipe.shapes.contains(item.baseShape), isTrue,
            reason: '$ctx : forme ${item.baseShape.name} hors pool');
        expect(recipe.strategies.contains(item.cutStrategy), isTrue,
            reason: '$ctx : découpe ${item.cutStrategy.name} hors pool');

        // Structure : 6 options, 3 vraies.
        expect(item.options.length, 6, reason: ctx);
        expect(item.correctPieces.length, 3, reason: ctx);

        // Rotations des vraies pièces : dans le pool + minimums imposés.
        final trueRots =
            item.correctPieces.map((p) => p.displayRotationDeg).toList();
        for (final rot in trueRots) {
          expect(recipe.rotationAngles.contains(rot), isTrue,
              reason: '$ctx : rotation $rot hors pool');
        }
        expect(trueRots.where((r) => r != 0).length,
            greaterThanOrEqualTo(recipe.minRotatedPieces),
            reason: '$ctx : pas assez de pièces tournées');
        expect(trueRots.where((r) => r % 90 != 0).length,
            greaterThanOrEqualTo(recipe.minDiagonalPieces),
            reason: '$ctx : pas assez de pièces à angle diagonal');

        // Budget de jumeaux (problème n° 1) : jamais dépassé.
        final twins = item.options.where((o) => o.isTwin).length;
        expect(twins, lessThanOrEqualTo(recipe.maxTwins),
            reason: '$ctx : $twins jumeaux > budget ${recipe.maxTwins}');

        // Mode couleur : hors fallback, le nombre de zones suit la recette.
        if (!item.fallbackUsed) {
          final expectedZones = switch (recipe.colorMode) {
            ColorMode.monochrome => 1,
            ColorMode.twoZonesAxial || ColorMode.twoZones => 2,
            ColorMode.threeZones => 3,
          };
          expect(item.colorZones.length, expectedZones, reason: ctx);
          expect(item.palette.length, expectedZones, reason: ctx);
        }

        // wrongColors ne doit jamais apparaître sur un item monochrome ni
        // sans budget de jumeau.
        final hasWrongColors =
            item.options.any((o) => o.trapKind == TrapKind.wrongColors);
        if (item.palette.length < 2 || recipe.maxTwins == 0) {
          expect(hasWrongColors, isFalse, reason: ctx);
        }
      }
    }

    // Fallbacks rares (< 5 %) : au-delà, une recette est trop contrainte.
    final rate = fallbacks / totalItems;
    // ignore: avoid_print
    print('conformité : $totalItems items, fallbacks=$fallbacks '
        '(${(100 * rate).toStringAsFixed(2)} %)');
    expect(rate, lessThan(0.05),
        reason: 'taux de fallback $rate ≥ 5 % — recette(s) trop contrainte(s)');
  }, timeout: const Timeout(Duration(minutes: 5)));

  test('même graine → même batterie (reproductibilité du journal)', () {
    final a = PuzzleGenerator(seed: 424242).generateComplete26Items();
    final b = PuzzleGenerator(seed: 424242).generateComplete26Items();
    for (int i = 0; i < a.length; i++) {
      expect(a[i].baseShape, b[i].baseShape, reason: 'item ${i + 1}');
      expect(a[i].cutStrategy, b[i].cutStrategy, reason: 'item ${i + 1}');
      expect(a[i].palette, b[i].palette, reason: 'item ${i + 1}');
      final rotsA = a[i].options.map((o) => o.displayRotationDeg).toList();
      final rotsB = b[i].options.map((o) => o.displayRotationDeg).toList();
      expect(rotsA, rotsB, reason: 'item ${i + 1}');
      final trapsA = a[i].options.map((o) => o.trapKind?.name).toList();
      final trapsB = b[i].options.map((o) => o.trapKind?.name).toList();
      expect(trapsA, trapsB, reason: 'item ${i + 1}');
    }
  });
}
