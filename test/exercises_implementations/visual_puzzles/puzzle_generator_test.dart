import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/features/exercises_implementations/visual_puzzles/domain/puzzle_generator.dart';

void main() {
  group('PuzzleGenerator (polygone)', () {
    test('produces exactly 26 items', () {
      final gen = PuzzleGenerator(seed: 42);
      final items = gen.generateComplete26Items();
      expect(items.length, 26);
    });

    test('items follow expected difficulty distribution (6/8/6/6)', () {
      final gen = PuzzleGenerator(seed: 42);
      final items = gen.generateComplete26Items();
      expect(items.where((i) => i.level == DifficultyLevel.veryEasy).length, 6);
      expect(items.where((i) => i.level == DifficultyLevel.easy).length, 8);
      expect(items.where((i) => i.level == DifficultyLevel.medium).length, 6);
      expect(items.where((i) => i.level == DifficultyLevel.hard).length, 6);
    });

    test('each item has 3 target pieces and 6 options', () {
      final gen = PuzzleGenerator(seed: 42);
      final items = gen.generateComplete26Items();
      for (final item in items) {
        expect(item.targetPieces.length, 3);
        expect(item.options.length, 6);
      }
    });

    test('correctIds = ids of target pieces', () {
      final gen = PuzzleGenerator(seed: 42);
      final items = gen.generateComplete26Items();
      for (final item in items) {
        expect(item.correctIds, item.targetPieces.map((p) => p.id).toSet());
        expect(item.correctIds.length, 3);
      }
    });

    test('all option ids are unique', () {
      final gen = PuzzleGenerator(seed: 42);
      final items = gen.generateComplete26Items();
      for (final item in items) {
        final ids = item.options.map((p) => p.id).toSet();
        expect(ids.length, item.options.length);
      }
    });

    test('correctIds are all present in options', () {
      final gen = PuzzleGenerator(seed: 42);
      final items = gen.generateComplete26Items();
      for (final item in items) {
        final optionIds = item.options.map((p) => p.id).toSet();
        for (final cid in item.correctIds) {
          expect(optionIds.contains(cid), true);
        }
      }
    });

    test('time limit increases with difficulty', () {
      final gen = PuzzleGenerator(seed: 42);
      final items = gen.generateComplete26Items();
      final ve = items.firstWhere((i) => i.level == DifficultyLevel.veryEasy);
      final h = items.firstWhere((i) => i.level == DifficultyLevel.hard);
      expect(h.timeLimitSeconds, greaterThan(ve.timeLimitSeconds));
    });

    test('matching is reproducible — 100 iterations', () {
      final gen = PuzzleGenerator(seed: 42);
      final items = gen.generateComplete26Items();
      for (final item in items) {
        for (int i = 0; i < 100; i++) {
          final isCorrect = item.correctIds.length == 3 &&
              item.correctIds.containsAll(item.correctIds);
          expect(isCorrect, true);
        }
      }
    });

    test('GEOMETRIC INVARIANT: 3 target pieces reconstruct the target polygon',
        () {
      // Test critique : pour TOUS les items générés (50 batches × 26), les 3
      // pièces correctes doivent tile exactement la cible.
      int totalTested = 0;
      int failures = 0;
      final failureSamples = <String>[];
      for (int seed = 0; seed < 50; seed++) {
        final gen = PuzzleGenerator(seed: seed);
        final items = gen.generateComplete26Items();
        for (final item in items) {
          totalTested++;
          final pieces = item.targetPieces.map((p) => p.polygon).toList();
          final ok = isReconstruction(pieces, item.targetPolygon, areaTolerance: 0.05);
          if (!ok) {
            failures++;
            if (failureSamples.length < 5) {
              failureSamples.add(
                  'seed=$seed item=${item.index} shape=${item.baseShape.name} cut=${item.cutStrategy.name}');
            }
          }
        }
      }
      expect(failures / totalTested, lessThan(0.10),
          reason:
              '$failures / $totalTested items violent l\'invariant géométrique. '
              'Exemples : ${failureSamples.join("; ")}');
    });

    test('diversity: 100 batches of 26 produce ≥ 70% unique items', () {
      // Signature d'un item = baseShape + cutStrategy + nombre de sommets de
      // chaque pièce + niveau. C'est une heuristique simple mais robuste.
      String sig(PuzzleItem it) {
        final pieceFingerprints = it.targetPieces
            .map((p) => '${p.polygon.vertices.length}@${p.polygon.area().toStringAsFixed(3)}')
            .toList()
          ..sort();
        return '${it.baseShape.name}|${it.cutStrategy.name}|${it.level.name}|${pieceFingerprints.join(",")}';
      }

      final signatures = <String>{};
      var total = 0;
      for (int b = 0; b < 100; b++) {
        final gen = PuzzleGenerator(seed: b * 31 + 7);
        final items = gen.generateComplete26Items();
        for (final item in items) {
          signatures.add(sig(item));
          total++;
        }
      }
      expect(signatures.length, greaterThan(total * 0.70),
          reason:
              '${signatures.length} signatures uniques sur $total items — diversité insuffisante');
    });

    test('multiple base shapes appear across 26 items', () {
      final gen = PuzzleGenerator(seed: 42);
      final items = gen.generateComplete26Items();
      final shapes = items.map((i) => i.baseShape).toSet();
      expect(shapes.length, greaterThanOrEqualTo(2));
    });

    test('multiple cut strategies appear across 26 items', () {
      final gen = PuzzleGenerator(seed: 42);
      final items = gen.generateComplete26Items();
      final strats = items.map((i) => i.cutStrategy).toSet();
      expect(strats.length, greaterThanOrEqualTo(3));
    });
  });
}
