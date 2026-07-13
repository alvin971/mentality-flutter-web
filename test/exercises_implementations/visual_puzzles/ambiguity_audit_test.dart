// Audit anti-ambiguïté des Puzzles Visuels.
//
// Depuis la refonte « cible carré unique » (2026-07), le risque auditée n'est
// plus la discrétisation des cibles courbes mais la SYMÉTRIE D4 du carré :
// découpes alternatives et miroirs y ont une probabilité élevée de
// quasi-coïncidence à rotation près (un secteur recoupé autrement peut
// retomber sur une vraie pièce). Ce test reste le filet de régression des
// gardes perceptuelles branchées dans le générateur et le TrapEngine.
//
// Ce test génère des items medium/hard en masse et compte, avec la métrique
// perceptuelle par rééchantillonnage de contour (`perceptuallyIdentical`),
// les paires piège ↔ vraie pièce indiscernables à rotation près.
//
// Exclusions justifiées :
// - wrongColors : géométrie identique PAR CONSTRUCTION (la différence est
//   dans les couleurs) ;
// - mirrored comparé en mode miroir : identité miroir voulue (le piège EST
//   le miroir d'une vraie pièce) — seule l'identité à ROTATION près serait
//   une ambiguïté (pièce superposable sans retournement).
//
// Attendu APRÈS branchement des gardes : zéro paire ambiguë.

import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/features/exercises_implementations/visual_puzzles/domain/puzzle_generator.dart';

void main() {
  test('aucun piège perceptuellement identique à une vraie pièce', () {
    const nMedium = 600;
    const nHard = 1200;
    const tolerances = [0.03, 0.05, 0.08];

    // tolérance → (clé de comptage → occurrences)
    final ambiguousByTol = {for (final t in tolerances) t: <String, int>{}};
    var ambiguousItemsAtGuardTol = 0;
    var totalItems = 0;
    final examples = <String>[];

    void auditItem(PuzzleItem item, int seed) {
      totalItems++;
      var itemFlagged = false;
      for (final trap in item.options.where((o) => !o.isCorrect)) {
        if (trap.trapKind == TrapKind.wrongColors) continue;
        for (final truePiece in item.correctPieces) {
          for (final tol in tolerances) {
            if (perceptuallyIdentical(trap.polygon, truePiece.polygon,
                relTol: tol)) {
              final key =
                  '${item.cutStrategy.name}/${trap.trapKind?.name ?? "?"}';
              final counts = ambiguousByTol[tol]!;
              counts[key] = (counts[key] ?? 0) + 1;
              if (tol == 0.08 && !itemFlagged) {
                itemFlagged = true;
                if (examples.length < 12) {
                  examples.add(
                      'seed=$seed item=${item.index} ${item.baseShape.name} '
                      '${item.cutStrategy.name} piège=${trap.trapKind?.name}');
                }
              }
            }
          }
        }
      }
      if (itemFlagged) ambiguousItemsAtGuardTol++;
    }

    for (int i = 0; i < nMedium; i++) {
      final gen = PuzzleGenerator(seed: 100000 + i);
      auditItem(gen.generateItem(18, DifficultyLevel.medium), 100000 + i);
    }
    for (int i = 0; i < nHard; i++) {
      final gen = PuzzleGenerator(seed: 200000 + i);
      auditItem(gen.generateItem(24, DifficultyLevel.hard), 200000 + i);
    }

    final buffer = StringBuffer('\n=== AUDIT AMBIGUÏTÉ ($totalItems items) ===\n');
    for (final tol in tolerances) {
      final counts = ambiguousByTol[tol]!;
      final total = counts.values.fold<int>(0, (a, b) => a + b);
      buffer.writeln('tol=$tol : $total paires ambiguës '
          '(${counts.isEmpty ? "—" : counts.toString()})');
    }
    buffer.writeln(
        'items avec ≥1 ambiguïté au seuil de garde (0.08) : '
        '$ambiguousItemsAtGuardTol / $totalItems '
        '(${(100 * ambiguousItemsAtGuardTol / totalItems).toStringAsFixed(2)} %)');
    if (examples.isNotEmpty) {
      buffer.writeln('exemples reproductibles :');
      for (final e in examples) {
        buffer.writeln('  $e');
      }
    }
    // ignore: avoid_print
    print(buffer);

    expect(ambiguousItemsAtGuardTol, 0,
        reason: 'Des pièges indiscernables d\'une vraie pièce passent les '
            'gardes — items « loterie ». Voir le détail imprimé ci-dessus.');
  }, timeout: const Timeout(Duration(minutes: 5)));
}
