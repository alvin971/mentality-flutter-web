// La pièce affichée doit être le CALQUE EXACT de sa découpe.
//
// Les zones de couleur pavent la cible ; une pièce est incluse dans la cible ;
// donc les intersections pièce ∩ zones pavent la pièce, et la somme de leurs
// aires vaut EXACTEMENT l'aire de la pièce. Toute perte signale un fragment
// de couleur jeté par `clipToZones` — ce qui était le cas avec un seuil de
// rejet à 2 % de l'aire (coin cyan de 1,85 % perdu sur graine 1 / item 5 /
// pièce E, plus 3 autres pièces sur les 8 modèles de référence).
import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/features/exercises_implementations/visual_puzzles/domain/puzzle_generator.dart';

void main() {
  test('les régions d une pièce pavent la pièce (aucun fragment de couleur perdu)',
      () {
    const seeds = 20;
    var piecesVues = 0;
    var pire = 0.0;
    String? pireOu;

    for (var seed = 1; seed <= seeds; seed++) {
      for (final item in PuzzleGenerator(seed: seed).generateComplete26Items()) {
        for (final o in item.options.where((o) => o.isCorrect)) {
          final airePiece = o.polygon.area();
          if (airePiece <= 0) continue;
          final aireRegions =
              o.regions.fold<double>(0, (s, r) => s + r.polygon.area());
          final ecart = (airePiece - aireRegions).abs() / airePiece;
          piecesVues++;
          if (ecart > pire) {
            pire = ecart;
            pireOu = 'graine $seed item ${item.index} ${item.cutStrategy.name}';
          }
        }
      }
    }

    // ignore: avoid_print
    print('pièces vérifiées : $piecesVues · pire écart : '
        '${(pire * 100).toStringAsFixed(4)} % ($pireOu)');
    expect(piecesVues, greaterThan(1000));
    expect(pire, lessThan(0.005),
        reason: 'un fragment de couleur est perdu à l extraction ($pireOu)');
  });
}
