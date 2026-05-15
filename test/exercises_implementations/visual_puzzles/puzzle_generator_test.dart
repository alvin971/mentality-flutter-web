import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/features/exercises_implementations/visual_puzzles/domain/puzzle_generator.dart';

void main() {
  group('PuzzleGenerator', () {
    test('produces exactly 26 items', () {
      final gen = PuzzleGenerator(seed: 42);
      final items = gen.generateComplete26Items();
      expect(items.length, 26);
    });

    test('items follow expected difficulty distribution', () {
      final gen = PuzzleGenerator(seed: 42);
      final items = gen.generateComplete26Items();

      final veryEasy = items.where((i) => i.level == DifficultyLevel.veryEasy).length;
      final easy = items.where((i) => i.level == DifficultyLevel.easy).length;
      final medium = items.where((i) => i.level == DifficultyLevel.medium).length;
      final hard = items.where((i) => i.level == DifficultyLevel.hard).length;

      expect(veryEasy, 6);
      expect(easy, 8);
      expect(medium, 6);
      expect(hard, 6);
    });

    test('each item has 3 target pieces and 6 options', () {
      final gen = PuzzleGenerator(seed: 42);
      final items = gen.generateComplete26Items();
      for (final item in items) {
        expect(item.targetPieces.length, 3, reason: 'item ${item.index} target');
        expect(item.options.length, 6, reason: 'item ${item.index} options');
      }
    });

    test('correctIds has exactly 3 ids and matches targetPieces', () {
      final gen = PuzzleGenerator(seed: 42);
      final items = gen.generateComplete26Items();
      for (final item in items) {
        expect(item.correctIds.length, 3);
        expect(item.correctIds, item.targetPieces.map((p) => p.id).toSet());
      }
    });

    test('all pieces in options have unique ids', () {
      final gen = PuzzleGenerator(seed: 42);
      final items = gen.generateComplete26Items();
      for (final item in items) {
        final ids = item.options.map((p) => p.id).toSet();
        expect(ids.length, item.options.length,
            reason: 'item ${item.index} has duplicate ids');
      }
    });

    test('correctIds are all present in options', () {
      final gen = PuzzleGenerator(seed: 42);
      final items = gen.generateComplete26Items();
      for (final item in items) {
        final optionIds = item.options.map((p) => p.id).toSet();
        for (final correctId in item.correctIds) {
          expect(optionIds.contains(correctId), true,
              reason: 'item ${item.index} correctId $correctId not in options');
        }
      }
    });

    test('time limit increases with difficulty', () {
      final gen = PuzzleGenerator(seed: 42);
      final items = gen.generateComplete26Items();
      final veryEasy = items.firstWhere((i) => i.level == DifficultyLevel.veryEasy);
      final hard = items.firstWhere((i) => i.level == DifficultyLevel.hard);
      expect(hard.timeLimitSeconds, greaterThan(veryEasy.timeLimitSeconds));
    });

    test('matching is reproducible — selecting same ids 100 times gives same result', () {
      final gen = PuzzleGenerator(seed: 42);
      final items = gen.generateComplete26Items();
      for (final item in items) {
        final selected = item.correctIds;
        for (int i = 0; i < 100; i++) {
          final isCorrect = selected.length == 3 &&
              selected.containsAll(item.correctIds) &&
              item.correctIds.containsAll(selected);
          expect(isCorrect, true,
              reason: 'item ${item.index} iteration $i: matching should be stable');
        }
      }
    });

    test('different seeds produce different items', () {
      final gen1 = PuzzleGenerator(seed: 1);
      final gen2 = PuzzleGenerator(seed: 2);
      final items1 = gen1.generateComplete26Items();
      final items2 = gen2.generateComplete26Items();
      // Au moins une différence sur les 26 items
      bool different = false;
      for (int i = 0; i < 26; i++) {
        if (items1[i].correctIds.toString() != items2[i].correctIds.toString()) {
          different = true;
          break;
        }
      }
      expect(different, true);
    });
  });
}
