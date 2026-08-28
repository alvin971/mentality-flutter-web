import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/features/exercises_implementations/matrices/domain/matrix_generator.dart';

/// Invariants du générateur de matrices progressives.
///
/// Bug historique couvert : items difficiles avec réponse `MatrixCell.empty()`
/// → 4 options blanches indiscernables (une seule acceptée). Tout item doit
/// désormais avoir une réponse visible et des options visuellement distinctes.
void main() {
  group('MatrixGenerator — invariants structurels', () {
    test('génère exactement 26 items', () {
      for (var seed = 0; seed < 20; seed++) {
        final items = MatrixGenerator(seed: seed).generateComplete26Items();
        expect(items.length, 26, reason: 'seed=$seed');
      }
    });

    test('répartition des niveaux de difficulté (5/7/6/5/3) et θ croissant', () {
      final items = MatrixGenerator(seed: 42).generateComplete26Items();

      final counts = <DifficultyLevel, int>{};
      for (final item in items) {
        counts[item.difficulty] = (counts[item.difficulty] ?? 0) + 1;
      }
      expect(counts[DifficultyLevel.veryEasy], 5);
      expect(counts[DifficultyLevel.easy], 7);
      expect(counts[DifficultyLevel.medium], 6);
      expect(counts[DifficultyLevel.mediumHard], 5);
      expect(counts[DifficultyLevel.hard], 3);

      for (var i = 1; i < items.length; i++) {
        expect(items[i].thetaValue, greaterThanOrEqualTo(items[i - 1].thetaValue),
            reason: 'θ doit être croissant (item $i)');
      }
      expect(items.first.thetaValue, -2.0);
      expect(items.last.thetaValue, closeTo(2.8, 0.001));
    });
  });

  group('MatrixGenerator — invariants des options (bug carrés blancs)', () {
    test('la réponse correcte n\'est JAMAIS une cellule vide', () {
      for (var seed = 0; seed < 100; seed++) {
        final items = MatrixGenerator(seed: seed).generateComplete26Items();
        for (final item in items) {
          expect(item.correctAnswer.isEmpty, isFalse,
              reason: 'seed=$seed, difficulté=${item.difficulty}: '
                  'réponse vide = option invisible');
        }
      }
    });

    test('aucune option n\'est une cellule vide', () {
      for (var seed = 0; seed < 100; seed++) {
        final items = MatrixGenerator(seed: seed).generateComplete26Items();
        for (final item in items) {
          for (final option in item.options) {
            expect(option.isEmpty, isFalse,
                reason: 'seed=$seed, difficulté=${item.difficulty}');
          }
        }
      }
    });

    test('5 options par item, toutes VISUELLEMENT distinctes', () {
      for (var seed = 0; seed < 100; seed++) {
        final items = MatrixGenerator(seed: seed).generateComplete26Items();
        for (final item in items) {
          expect(item.options.length, 5,
              reason: 'seed=$seed: chaque item doit présenter 5 options');

          final signatures =
              item.options.map(MatrixGenerator.visualSignature).toSet();
          expect(signatures.length, 5,
              reason: 'seed=$seed, difficulté=${item.difficulty}: '
                  'deux options ont le même rendu visuel '
                  '(${item.options.map(MatrixGenerator.visualSignature).toList()})');
        }
      }
    });

    test('exactement une option correspond à la réponse correcte', () {
      for (var seed = 0; seed < 100; seed++) {
        final items = MatrixGenerator(seed: seed).generateComplete26Items();
        for (final item in items) {
          final matching =
              item.options.where((o) => o == item.correctAnswer).length;
          expect(matching, 1,
              reason: 'seed=$seed, difficulté=${item.difficulty}');

          final correctSig = MatrixGenerator.visualSignature(item.correctAnswer);
          final visualMatches = item.options
              .where((o) => MatrixGenerator.visualSignature(o) == correctSig)
              .length;
          expect(visualMatches, 1,
              reason: 'seed=$seed: un distracteur a le même rendu que la réponse');
        }
      }
    });
  });

  group('visualSignature — symétries de rotation', () {
    test('cercle : toute rotation est visuellement identique', () {
      final a = MatrixCell(shape: MatrixShape.circle, rotation: 0);
      final b = MatrixCell(shape: MatrixShape.circle, rotation: 45);
      expect(MatrixGenerator.visualSignature(a),
          MatrixGenerator.visualSignature(b));
    });

    test('carré : rotation de 90° identique, 45° différente', () {
      final base = MatrixCell(shape: MatrixShape.square, rotation: 0);
      final rot90 = MatrixCell(shape: MatrixShape.square, rotation: 90);
      final rot45 = MatrixCell(shape: MatrixShape.square, rotation: 45);
      expect(MatrixGenerator.visualSignature(base),
          MatrixGenerator.visualSignature(rot90));
      expect(MatrixGenerator.visualSignature(base),
          isNot(MatrixGenerator.visualSignature(rot45)));
    });

    test('losange = carré tourné de 45°', () {
      final diamond = MatrixCell(shape: MatrixShape.diamond, rotation: 0);
      final square45 = MatrixCell(shape: MatrixShape.square, rotation: 45);
      expect(MatrixGenerator.visualSignature(diamond),
          MatrixGenerator.visualSignature(square45));
    });

    test('toutes les cellules vides sont visuellement identiques', () {
      final a = MatrixCell.empty();
      final b = MatrixCell(shape: MatrixShape.star, size: 0);
      final c = MatrixCell(shape: MatrixShape.hexagon, count: 0, color: CellColor.gray);
      expect(MatrixGenerator.visualSignature(a), 'EMPTY');
      expect(MatrixGenerator.visualSignature(b), 'EMPTY');
      expect(MatrixGenerator.visualSignature(c), 'EMPTY');
    });

    test('hexagone : symétrie 60°, étoile : symétrie 72°', () {
      expect(
        MatrixGenerator.visualSignature(
            MatrixCell(shape: MatrixShape.hexagon, rotation: 60)),
        MatrixGenerator.visualSignature(
            MatrixCell(shape: MatrixShape.hexagon, rotation: 0)),
      );
      expect(
        MatrixGenerator.visualSignature(
            MatrixCell(shape: MatrixShape.star, rotation: 72)),
        MatrixGenerator.visualSignature(
            MatrixCell(shape: MatrixShape.star, rotation: 0)),
      );
    });
  });
}
