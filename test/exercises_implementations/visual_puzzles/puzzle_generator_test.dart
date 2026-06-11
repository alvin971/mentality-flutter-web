import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/features/exercises_implementations/visual_puzzles/domain/puzzle_generator.dart';

void main() {
  group('PuzzleGenerator — structure du test', () {
    test('génère exactement 26 items avec la bonne répartition de niveaux',
        () {
      final items = PuzzleGenerator(seed: 42).generateComplete26Items();
      expect(items.length, 26);
      expect(
          items.where((i) => i.level == DifficultyLevel.veryEasy).length, 6);
      expect(items.where((i) => i.level == DifficultyLevel.easy).length, 8);
      expect(items.where((i) => i.level == DifficultyLevel.medium).length, 6);
      expect(items.where((i) => i.level == DifficultyLevel.hard).length, 6);
    });

    test('temps limites conformes : 20 s items 1-7, 30 s items 8-26', () {
      final items = PuzzleGenerator(seed: 7).generateComplete26Items();
      for (final item in items) {
        expect(item.timeLimitSeconds, item.index <= 7 ? 20 : 30,
            reason: 'item ${item.index}');
      }
    });

    test('chaque item a 6 options dont exactement 3 correctes', () {
      final items = PuzzleGenerator(seed: 99).generateComplete26Items();
      for (final item in items) {
        expect(item.options.length, 6, reason: 'item ${item.index}');
        expect(item.correctIds.length, 3, reason: 'item ${item.index}');
        expect(item.options.where((o) => o.isCorrect).length, 3,
            reason: 'item ${item.index}');
        final ids = item.options.map((o) => o.id).toSet();
        expect(ids.length, 6, reason: 'ids uniques, item ${item.index}');
        expect(ids.containsAll(item.correctIds), isTrue);
      }
    });
  });

  group('PuzzleGenerator — invariants géométriques (500 items)', () {
    late List<PuzzleItem> allItems;

    setUpAll(() {
      allItems = [
        for (int seed = 0; seed < 20; seed++)
          ...PuzzleGenerator(seed: seed).generateComplete26Items(),
      ];
    });

    test('les 3 vraies pièces reconstituent toujours la cible', () {
      for (final item in allItems) {
        final pieces = item.correctPieces.map((p) => p.polygon).toList();
        expect(
          isReconstruction(pieces, item.targetPolygon,
              areaTolerance: 0.03, minAreaShare: 0.10),
          isTrue,
          reason: 'item ${item.index} (${item.baseShape.name}, '
              '${item.cutStrategy.name})',
        );
      }
    });

    test('aucune pièce minuscule ni dégénérée parmi les options', () {
      for (final item in allItems) {
        final targetArea = item.targetPolygon.area();
        for (final o in item.options) {
          expect(o.polygon.vertices.length, greaterThanOrEqualTo(3));
          expect(o.polygon.area() / targetArea, greaterThan(0.05),
              reason: 'item ${item.index}, piège ${o.trapKind}');
        }
      }
    });

    test(
        'aucun distracteur congruent à une vraie pièce par rotation '
        '(sinon 2 réponses valides)', () {
      for (final item in allItems) {
        final correct = item.correctPieces;
        for (final o in item.options.where((o) => !o.isCorrect)) {
          for (final c in correct) {
            expect(congruent(o.polygon, c.polygon), isFalse,
                reason: 'item ${item.index} : piège ${o.trapKind} congruent '
                    'à une vraie pièce');
          }
        }
      }
    });

    test('le piège miroir n\'est jamais une simple rotation de sa source', () {
      for (final item in allItems) {
        for (final o
            in item.options.where((o) => o.trapKind == TrapKind.mirrored)) {
          for (final c in item.correctPieces) {
            expect(congruent(o.polygon, c.polygon), isFalse);
          }
        }
      }
    });

    test('maxPieceExtent couvre bien toutes les options affichées', () {
      for (final item in allItems) {
        for (final o in item.options) {
          final bb = o.displayPolygon.bbox();
          expect(bb.width, lessThanOrEqualTo(item.maxPieceExtent + 1e-6));
          expect(bb.height, lessThanOrEqualTo(item.maxPieceExtent + 1e-6));
        }
      }
    });
  });

  group('PuzzleGenerator — progression de difficulté', () {
    test('subtilité des pièges croissante de l\'item 1 à 26', () {
      expect(PuzzleGenerator.subtletyForItem(1), closeTo(0.05, 1e-9));
      expect(PuzzleGenerator.subtletyForItem(26), closeTo(0.95, 1e-9));
      for (int i = 1; i < 26; i++) {
        expect(PuzzleGenerator.subtletyForItem(i + 1),
            greaterThan(PuzzleGenerator.subtletyForItem(i)));
      }
    });

    test('items très faciles : aucune rotation d\'affichage', () {
      final items = PuzzleGenerator(seed: 5).generateComplete26Items();
      for (final item
          in items.where((i) => i.level == DifficultyLevel.veryEasy)) {
        for (final o in item.options) {
          expect(o.displayRotationDeg, 0.0,
              reason: 'item ${item.index} doit rester sans rotation');
        }
      }
    });

    test('items difficiles : des rotations apparaissent', () {
      final items = [
        for (int seed = 0; seed < 5; seed++)
          ...PuzzleGenerator(seed: seed).generateComplete26Items(),
      ];
      final hardRotations = items
          .where((i) => i.level == DifficultyLevel.hard)
          .expand((i) => i.options)
          .where((o) => o.displayRotationDeg != 0)
          .length;
      expect(hardRotations, greaterThan(0));
    });

    test('diversité : 2 générateurs sans seed produisent des items variés',
        () {
      final a = PuzzleGenerator(seed: 1).generateComplete26Items();
      final b = PuzzleGenerator(seed: 2).generateComplete26Items();
      int differing = 0;
      for (int i = 0; i < 26; i++) {
        if (a[i].baseShape != b[i].baseShape ||
            a[i].cutStrategy != b[i].cutStrategy) {
          differing++;
        }
      }
      expect(differing, greaterThan(8));
    });
  });

  group('Géométrie — congruence', () {
    test('un polygone est congruent à sa rotation', () {
      const square = Polygon([
        Offset(0, 0),
        Offset(0.4, 0),
        Offset(0.4, 0.4),
        Offset(0, 0.4),
      ]);
      final rotated = square.transform(rotationDeg: 90);
      expect(congruent(square, rotated), isTrue);
    });

    test('un polygone n\'est pas congruent à sa version agrandie', () {
      const square = Polygon([
        Offset(0, 0),
        Offset(0.4, 0),
        Offset(0.4, 0.4),
        Offset(0, 0.4),
      ]);
      final scaled = square.transform(scale: 1.15);
      expect(congruent(square, scaled), isFalse);
    });

    test('miroir détecté uniquement avec allowMirror', () {
      const tri = Polygon([
        Offset(0, 0),
        Offset(0.5, 0),
        Offset(0, 0.3),
      ]);
      final mirrored = tri.transform(mirrored: true);
      expect(congruent(tri, mirrored), isFalse);
      expect(congruent(tri, mirrored, allowMirror: true), isTrue);
    });
  });
}
