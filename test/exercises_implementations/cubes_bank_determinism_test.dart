import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/features/exercises_implementations/cubes/domain/pattern_generator.dart';

/// Signature canonique et stable d'un item (champs identifiants) :
/// taille de grille + pattern complet (faces par index) + score de cohésion
/// + limite de temps + difficulté. Deux items sont « identiques » ssi leurs
/// signatures le sont — l'ORDRE des cellules est significatif.
String _itemSig(CubePattern item) {
  final patternSig = item.pattern
      .map((row) => row.map((face) => face.index).join(','))
      .join(';');
  return [
    'grid=${item.gridSize}',
    'diff=${item.difficulty.index}',
    'cohesion=${item.cohesionScore}',
    'time=${item.timeLimit}',
    'pattern=$patternSig',
  ].join('|');
}

void main() {
  group('CubePatternGenerator — banque déterministe et versionnée', () {
    test('deux instances produisent une banque IDENTIQUE (mêmes items, même ordre)', () {
      // Deux générateurs indépendants → si la moindre source d'aléa fuit
      // (Random non seedé, shuffle() sans argument, itération de Set...),
      // au moins une signature diffère et le test échoue.
      final a = CubePatternGenerator().generateBank();
      final b = CubePatternGenerator().generateBank();

      // Garde-fou : la banque doit contenir exactement 14 items (dont 12 cotés).
      expect(a.length, 14, reason: 'La banque doit produire 14 items.');
      expect(b.length, a.length,
          reason: 'Les deux banques doivent avoir la même taille.');

      // Comparaison item par item.
      for (var i = 0; i < a.length; i++) {
        expect(
          _itemSig(b[i]),
          _itemSig(a[i]),
          reason: 'Item #$i diffère entre deux passations → aléa non déterministe.',
        );
      }

      // Comparaison globale de la séquence (ordre des items inclus).
      final seqA = a.map(_itemSig).toList();
      final seqB = b.map(_itemSig).toList();
      expect(seqB, equals(seqA),
          reason: 'La séquence complète des items doit être identique.');
    });

    test('une graine explicite identique reproduit exactement la banque', () {
      final a = CubePatternGenerator(seed: CubePatternGenerator.kBankSeed)
          .generateBank();
      final b = CubePatternGenerator(seed: CubePatternGenerator.kBankSeed)
          .generateBank();

      expect(a.map(_itemSig).toList(), equals(b.map(_itemSig).toList()),
          reason: 'Même graine → même banque.');
    });

    test('la banque contient 14 items (progression figée)', () {
      final items = CubePatternGenerator().generateBank();
      expect(items.length, 14, reason: '14 items au total');
      expect(CubePatternGenerator.kDifficultyProgression.length, 14,
          reason: 'La progression canonique figée compte 14 items.');
    });

    test('la graine de banque est figée (versionnage)', () {
      expect(CubePatternGenerator.kBankSeed, 20260616,
          reason: 'Bumper kBankSeed est le seul moyen de régénérer la banque.');
    });
  });
}
