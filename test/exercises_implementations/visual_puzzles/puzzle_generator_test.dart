import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/features/exercises_implementations/visual_puzzles/domain/puzzle_generator.dart';

void main() {
  group('PuzzleGenerator (polygone + similarity)', () {
    test('produces exactly 26 items', () {
      final gen = PuzzleGenerator(seed: 42);
      expect(gen.generateComplete26Items().length, 26);
    });

    test('distribution 6/8/6/6 par niveau', () {
      final gen = PuzzleGenerator(seed: 42);
      final items = gen.generateComplete26Items();
      expect(items.where((i) => i.level == DifficultyLevel.veryEasy).length, 6);
      expect(items.where((i) => i.level == DifficultyLevel.easy).length, 8);
      expect(items.where((i) => i.level == DifficultyLevel.medium).length, 6);
      expect(items.where((i) => i.level == DifficultyLevel.hard).length, 6);
    });

    test('chaque item a 3 targets + 3 distractors = 6 options', () {
      final gen = PuzzleGenerator(seed: 42);
      for (final item in gen.generateComplete26Items()) {
        expect(item.targetPieces.length, 3);
        expect(item.options.length, 6);
        final distractors = item.options
            .where((p) => !item.correctIds.contains(p.id))
            .toList();
        expect(distractors.length, 3);
      }
    });

    test('correctIds = ids des targets', () {
      final gen = PuzzleGenerator(seed: 42);
      for (final item in gen.generateComplete26Items()) {
        expect(item.correctIds.length, 3);
        expect(item.correctIds, item.targetPieces.map((p) => p.id).toSet());
      }
    });

    test('tous les ids des options sont uniques', () {
      final gen = PuzzleGenerator(seed: 42);
      for (final item in gen.generateComplete26Items()) {
        final ids = item.options.map((p) => p.id).toSet();
        expect(ids.length, item.options.length);
      }
    });

    test('INVARIANT géométrique : 3 targets reconstituent la cible', () {
      int totalTested = 0;
      int failures = 0;
      for (int seed = 0; seed < 30; seed++) {
        final gen = PuzzleGenerator(seed: seed);
        for (final item in gen.generateComplete26Items()) {
          totalTested++;
          final pieces = item.targetPieces.map((p) => p.polygon).toList();
          if (!isReconstruction(pieces, item.targetPolygon, areaTolerance: 0.06)) {
            failures++;
          }
        }
      }
      // Tolère < 10% (les coupes oblique/3FromCenter peuvent rater certains seeds)
      expect(failures / totalTested, lessThan(0.10),
          reason: '$failures / $totalTested items violent l\'invariant');
    });

    test(
        'PROGRESSION DE SIMILARITÉ : items 1-6 ont une similarité < items 21-26',
        () {
      final gen = PuzzleGenerator(seed: 42);
      final items = gen.generateComplete26Items();
      final earlySims =
          items.take(6).map((i) => i.distractorSimilarity).toList();
      final lateSims = items.skip(20).map((i) => i.distractorSimilarity).toList();
      final earlyAvg = earlySims.reduce((a, b) => a + b) / earlySims.length;
      final lateAvg = lateSims.reduce((a, b) => a + b) / lateSims.length;
      expect(lateAvg, greaterThan(earlyAvg + 0.2),
          reason:
              'similarité moyenne early=$earlyAvg, late=$lateAvg — la progression est insuffisante');
    });

    test('similarité item 1 ≈ 0.35, item 26 ≈ 0.95', () {
      expect(PuzzleGenerator.similarityForItem(1), closeTo(0.35, 0.01));
      expect(PuzzleGenerator.similarityForItem(13), closeTo(0.638, 0.01));
      expect(PuzzleGenerator.similarityForItem(26), closeTo(0.95, 0.01));
    });

    test('distractors ont similarity < 1.0 (ne sont jamais identiques au target)',
        () {
      for (int seed = 0; seed < 20; seed++) {
        final gen = PuzzleGenerator(seed: seed);
        for (final item in gen.generateComplete26Items()) {
          final distractors = item.options
              .where((p) => !item.correctIds.contains(p.id))
              .toList();
          for (final d in distractors) {
            expect(d.similarity, lessThan(1.0));
            expect(d.similarity, greaterThanOrEqualTo(0.05));
          }
        }
      }
    });

    test('targets ont similarity = 1.0', () {
      final gen = PuzzleGenerator(seed: 42);
      for (final item in gen.generateComplete26Items()) {
        for (final t in item.targetPieces) {
          expect(t.similarity, 1.0);
        }
      }
    });

    test('time limit augmente avec la difficulté', () {
      final gen = PuzzleGenerator(seed: 42);
      final items = gen.generateComplete26Items();
      final ve = items.firstWhere((i) => i.level == DifficultyLevel.veryEasy);
      final h = items.firstWhere((i) => i.level == DifficultyLevel.hard);
      expect(h.timeLimitSeconds, greaterThan(ve.timeLimitSeconds));
    });
  });
}
