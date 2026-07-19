import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/features/exercises_implementations/cubes/domain/pattern_generator.dart';

/// Vérifie que les motifs des Cubes sont ALÉATOIRES PAR PASSATION : deux
/// sessions ne présentent pas les mêmes items, mais la PROGRESSION de
/// difficulté (14 slots canoniques) reste identique pour tous.
///
/// Ce test DOIT échouer si un seed fixe est réintroduit en production.
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
  group('CubePatternGenerator — aléa par passation', () {
    test('deux passations sans seed produisent des banques différentes', () {
      final a = CubePatternGenerator().generateBank().map(_itemSig).toList();
      final b = CubePatternGenerator().generateBank().map(_itemSig).toList();

      expect(a, isNot(equals(b)),
          reason: 'Deux sessions ne doivent jamais présenter les mêmes motifs '
              '(un seed fixe a probablement été réintroduit).');
    });

    test('un même seed explicite est reproductible (tests/démo)', () {
      final a = CubePatternGenerator(seed: 42).generateBank().map(_itemSig);
      final b = CubePatternGenerator(seed: 42).generateBank().map(_itemSig);
      expect(a.toList(), equals(b.toList()), reason: 'Même graine → même banque.');
    });

    test('la progression de difficulté est FIXE quel que soit le tirage', () {
      for (var seed = 0; seed < 20; seed++) {
        final items = CubePatternGenerator(seed: seed).generateBank();
        expect(items.length, 14, reason: 'seed=$seed : 14 items au total');
        expect(
          items.map((it) => it.difficulty).toList(),
          equals(CubePatternGenerator.kDifficultyProgression),
          reason: 'seed=$seed : chaque slot garde son niveau de difficulté — '
              'seul le contenu des motifs change entre passations.',
        );
      }
    });
  });
}
