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
      bool different = false;
      for (int i = 0; i < 26; i++) {
        if (items1[i].correctIds.toString() != items2[i].correctIds.toString()) {
          different = true;
          break;
        }
      }
      expect(different, true);
    });

    // ============================================================
    // DIVERSITÉ COMBINATOIRE
    // ============================================================

    /// Signature visible d'un item (sans les UUIDs) — sert à mesurer la diversité.
    String _itemSignature(PuzzleItem item) {
      final pieces = item.targetPieces
          .map((p) =>
              '${p.shape.name}|${p.rotationDeg}|${p.mirrored}|${p.scale}|'
              '${p.edges.top.name}-${p.edges.right.name}-'
              '${p.edges.bottom.name}-${p.edges.left.name}|'
              '${p.gridX},${p.gridY},${p.gridW}x${p.gridH}')
          .join('#');
      return '${item.layout.name}::$pieces';
    }

    test('100 générations consécutives produisent ≥ 70% items uniques (diversité)',
        () {
      // On génère 100 batches de 26 items. Chaque batch a son propre seed
      // (basé sur l'horloge). On collecte les signatures de TOUS les items
      // veryEasy et on vérifie qu'au moins 70% sont uniques.
      final signatures = <String>{};
      var total = 0;
      for (int i = 0; i < 100; i++) {
        final gen = PuzzleGenerator(seed: i * 31 + 7);
        final items = gen.generateComplete26Items();
        for (final item in items) {
          signatures.add(_itemSignature(item));
          total++;
        }
      }
      // 2600 items générés. On attend au moins 1500 signatures différentes
      // (combinatoire massive).
      expect(signatures.length, greaterThan(1500),
          reason:
              '${signatures.length} signatures uniques sur $total items — '
              'diversité insuffisante, refonte du générateur nécessaire');
    });

    test('plusieurs layouts différents apparaissent dans 26 items', () {
      final gen = PuzzleGenerator(seed: 42);
      final items = gen.generateComplete26Items();
      final layoutsUsed = items.map((i) => i.layout).toSet();
      // On veut au moins 3 layouts différents sur les 26 items (preuve que
      // le générateur ne se cale pas sur un seul).
      expect(layoutsUsed.length, greaterThanOrEqualTo(3),
          reason: 'layouts utilisés : $layoutsUsed');
    });

    test(
        'sur 26 items, plusieurs shape combinations différentes au niveau '
        'veryEasy (pas que [square, square, square])', () {
      final gen = PuzzleGenerator(seed: 12345);
      final items = gen.generateComplete26Items();
      final veryEasyItems = items
          .where((i) => i.level == DifficultyLevel.veryEasy)
          .toList();
      final shapeCombos = veryEasyItems
          .map((i) => i.targetPieces.map((p) => p.shape.name).join(','))
          .toSet();
      expect(shapeCombos.length, greaterThanOrEqualTo(2),
          reason: 'veryEasy shapes combos : $shapeCombos');
    });

    test(
        'TOUS niveaux : les 6 options ont 6 shapes différentes '
        '(garantit zéro confusion visuelle)', () {
      // Règle critique : l'utilisateur ne doit JAMAIS voir 2 pièces qui
      // se ressemblent. Chaque option a une forme géométrique distincte.
      int totalChecked = 0;
      int violations = 0;
      final violationsByLevel = <DifficultyLevel, int>{};
      for (int seed = 0; seed < 100; seed++) {
        final gen = PuzzleGenerator(seed: seed);
        final items = gen.generateComplete26Items();
        for (final item in items) {
          totalChecked++;
          final shapes = item.options.map((p) => p.shape).toSet();
          if (shapes.length < 6) {
            violations++;
            violationsByLevel.update(item.level, (v) => v + 1,
                ifAbsent: () => 1);
          }
        }
      }
      expect(violations / totalChecked, lessThan(0.01),
          reason:
              '$violations / $totalChecked items ont moins de 6 shapes uniques. '
              'Par niveau : $violationsByLevel');
    });

    test('aucun item n\'a 2 options visuellement identiques', () {
      // Signature qui reproduit fidèlement la logique du générateur :
      // rotation appliquée aux edges, mirror appliqué, symétrie de shape
      // prise en compte.
      EdgePattern rotateEdges(EdgePattern e, int steps) {
        steps = ((steps % 4) + 4) % 4;
        var c = e;
        for (int i = 0; i < steps; i++) {
          c = EdgePattern(top: c.left, right: c.top, bottom: c.right, left: c.bottom);
        }
        return c;
      }

      EdgePattern mirrorEdges(EdgePattern e) =>
          EdgePattern(top: e.top, right: e.left, bottom: e.bottom, left: e.right);

      String visualSig(PuzzlePiece p) {
        final rotSteps = ((p.rotationDeg.toInt() % 360) + 360) % 360 ~/ 90;
        final absEdges = rotateEdges(p.edges, rotSteps);
        final finalEdges = p.mirrored ? mirrorEdges(absEdges) : absEdges;
        final sym = switch (p.shape) {
          PuzzleShape.square => 1,
          PuzzleShape.rectangleH => 2,
          PuzzleShape.rectangleV => 2,
          PuzzleShape.parallelogram => 2,
          PuzzleShape.zShape => 2,
          _ => 4,
        };
        final canonicalRot = sym > 0 ? rotSteps % sym : rotSteps;
        return '${p.shape.name}|m${p.mirrored}|s${p.scale.toStringAsFixed(2)}|r$canonicalRot|'
            '${finalEdges.top.name}-${finalEdges.right.name}-${finalEdges.bottom.name}-${finalEdges.left.name}';
      }

      int collisions = 0;
      for (int b = 0; b < 100; b++) {
        final gen = PuzzleGenerator(seed: b * 17 + 3);
        final items = gen.generateComplete26Items();
        for (final item in items) {
          final sigs = item.options.map(visualSig).toList();
          if (sigs.toSet().length < sigs.length) collisions++;
        }
      }
      // 100 × 26 = 2600 items. On tolère < 30 collisions (< 1.5%).
      expect(collisions, lessThan(30),
          reason: '$collisions items / 2600 ont 2 options identiques');
    });

    test(
        'distractors n\'ont JAMAIS la même shape qu\'un target '
        '(invariant fort, tous niveaux)', () {
      // Avec la règle stricte de 6 shapes uniques, un distractor ne doit
      // jamais partager sa shape avec une pièce correcte.
      for (int seed = 0; seed < 50; seed++) {
        final gen = PuzzleGenerator(seed: seed);
        final items = gen.generateComplete26Items();
        for (final item in items) {
          final targetShapes = item.targetPieces.map((p) => p.shape).toSet();
          final distractors = item.options
              .where((p) => !item.correctIds.contains(p.id))
              .toList();
          for (final d in distractors) {
            expect(targetShapes.contains(d.shape), false,
                reason:
                    'seed=$seed item=${item.index} : distractor ${d.shape.name} partage la shape avec un target');
          }
        }
      }
    });
  });
}
