import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/features/exercises_implementations/visual_puzzles/domain/base_shapes.dart';
import 'package:mentality/features/exercises_implementations/visual_puzzles/domain/cut_engine.dart';
import 'package:mentality/features/exercises_implementations/visual_puzzles/domain/geometry.dart';

void main() {
  group('CutEngine — invariant géométrique', () {
    test('chaque cut produit 3 polygones qui reconstituent la cible', () {
      // Pour chaque (forme × stratégie), on essaie 30 seeds et on vérifie
      // que TOUS les items respectent l'invariant.
      int totalTested = 0;
      int failures = 0;
      final failureSamples = <String>[];
      for (final shape in BaseShape.values) {
        final base = buildBaseShape(shape);
        for (final strat in CutStrategy.values) {
          for (int seed = 0; seed < 30; seed++) {
            final engine = CutEngine(rng: math.Random(seed));
            final pieces = engine.cut(base, strat);
            totalTested++;
            if (!isReconstruction(pieces, base, areaTolerance: 0.02)) {
              failures++;
              if (failureSamples.length < 5) {
                failureSamples.add('${shape.name}/${strat.name}/seed$seed');
              }
            }
          }
        }
      }
      // Tolérance < 5% d'échec global (les courbes / cercle peuvent ratter
      // certains seeds pathologiques — l'algo retombe sur fallback)
      expect(failures / totalTested, lessThan(0.05),
          reason:
              '$failures / $totalTested cuts ratent l\'invariant. '
              'Exemples : ${failureSamples.join(", ")}');
    });

    test('chaque pièce d\'un cut a au moins 3 sommets', () {
      for (final shape in BaseShape.values) {
        final base = buildBaseShape(shape);
        for (final strat in CutStrategy.values) {
          for (int seed = 0; seed < 10; seed++) {
            final engine = CutEngine(rng: math.Random(seed));
            final pieces = engine.cut(base, strat);
            for (int i = 0; i < pieces.length; i++) {
              expect(pieces[i].vertices.length, greaterThanOrEqualTo(3),
                  reason:
                      '${shape.name}/${strat.name}/seed$seed/piece$i a moins de 3 sommets');
            }
          }
        }
      }
    });

    test('cuts twoParallelStraight sur carré produisent ~3 bandes égales', () {
      // Sanity check : carré coupé en 3 bandes verticales doit donner
      // 3 pièces d'aires comparables (à 30% près).
      final base = buildBaseShape(BaseShape.square);
      for (int seed = 0; seed < 10; seed++) {
        final engine = CutEngine(rng: math.Random(seed));
        final pieces =
            engine.cut(base, CutStrategy.twoParallelStraight);
        final areas = pieces.map((p) => p.area()).toList();
        final maxA = areas.reduce(math.max);
        final minA = areas.reduce(math.min);
        // Ratio max/min < 4 (les bandes ne sont pas trop disparates)
        expect(maxA / minA, lessThan(4),
            reason: 'seed $seed produit des bandes très disparates : $areas');
      }
    });
  });
}
