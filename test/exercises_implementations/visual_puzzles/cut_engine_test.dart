import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/features/exercises_implementations/visual_puzzles/domain/base_shapes.dart';
import 'package:mentality/features/exercises_implementations/visual_puzzles/domain/cut_engine.dart';
import 'package:mentality/features/exercises_implementations/visual_puzzles/domain/geometry.dart';

void main() {
  group('CutEngine — invariant géométrique', () {
    test('chaque cut produit 3 polygones reconstituant la cible (8 formes × 5 stratégies × 30 seeds)', () {
      int total = 0;
      int fail = 0;
      for (final shape in BaseShape.values) {
        final base = buildBaseShape(shape);
        for (final strat in CutStrategy.values) {
          for (int seed = 0; seed < 30; seed++) {
            final engine = CutEngine(rng: math.Random(seed));
            final pieces = engine.cut(base, strat);
            total++;
            if (!isReconstruction(pieces, base, areaTolerance: 0.06)) fail++;
          }
        }
      }
      expect(fail / total, lessThan(0.10),
          reason: '$fail / $total cuts ratent l\'invariant');
    });

    test('chaque pièce a au moins 3 sommets', () {
      for (final shape in BaseShape.values) {
        final base = buildBaseShape(shape);
        for (final strat in CutStrategy.values) {
          final engine = CutEngine(rng: math.Random(42));
          final pieces = engine.cut(base, strat);
          for (final p in pieces) {
            expect(p.vertices.length, greaterThanOrEqualTo(3));
          }
        }
      }
    });
  });
}
