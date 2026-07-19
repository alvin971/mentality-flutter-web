import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/features/exercises_implementations/matrices/domain/matrix_generator.dart';

/// Vérifie que les Matrices sont ALÉATOIRES PAR PASSATION : deux sessions
/// ne présentent pas les mêmes items, mais l'ÉCHELLE de difficulté (ordre
/// des paliers, thêta par slot) reste identique pour tous.
///
/// Ce test DOIT échouer si un seed fixe est réintroduit en production.
String _cellSig(MatrixCell? cell) {
  if (cell == null) return 'NULL';
  return [
    cell.shape.index,
    cell.size,
    cell.count,
    cell.color.index,
    cell.rotation.toStringAsFixed(2),
  ].join(':');
}

/// Signature canonique d'un item : grille + bonne réponse + options (ordre
/// inclus). Deux items sont « identiques » ssi leurs signatures le sont.
String _itemSig(MatrixItem item) {
  final matrixSig =
      item.matrix.map((row) => row.map(_cellSig).join(',')).join(';');
  final optionsSig = item.options.map(_cellSig).join(',');
  return 'matrix=$matrixSig|answer=${_cellSig(item.correctAnswer)}|options=$optionsSig';
}

void main() {
  group('MatrixGenerator — aléa par passation', () {
    test('deux passations sans seed produisent des banques différentes', () {
      final a = MatrixGenerator().generateComplete26Items().map(_itemSig).toList();
      final b = MatrixGenerator().generateComplete26Items().map(_itemSig).toList();

      expect(a.length, 26);
      expect(a, isNot(equals(b)),
          reason: 'Deux sessions ne doivent jamais présenter le même test '
              '(un seed fixe a probablement été réintroduit).');
    });

    test('un même seed explicite est reproductible (tests/diagnostics)', () {
      final a = MatrixGenerator(seed: 42).generateComplete26Items().map(_itemSig);
      final b = MatrixGenerator(seed: 42).generateComplete26Items().map(_itemSig);
      expect(a.toList(), equals(b.toList()), reason: 'Même graine → même banque.');
    });

    test('l\'ordre des paliers de difficulté est FIXE (5+7+6+5+3), quel que soit le tirage', () {
      final expectedOrder = <DifficultyLevel>[
        ...List.filled(5, DifficultyLevel.veryEasy),
        ...List.filled(7, DifficultyLevel.easy),
        ...List.filled(6, DifficultyLevel.medium),
        ...List.filled(5, DifficultyLevel.mediumHard),
        ...List.filled(3, DifficultyLevel.hard),
      ];

      for (var seed = 0; seed < 20; seed++) {
        final items = MatrixGenerator(seed: seed).generateComplete26Items();
        expect(items.map((it) => it.difficulty).toList(), equals(expectedOrder),
            reason: 'seed=$seed : les 26 slots doivent suivre l\'ordre de '
                'difficulté canonique.');
      }
    });

    test('l\'échelle thêta par slot est identique d\'une passation à l\'autre', () {
      final ref = MatrixGenerator(seed: 1)
          .generateComplete26Items()
          .map((it) => it.thetaValue)
          .toList();
      for (var seed = 2; seed < 20; seed++) {
        final thetas = MatrixGenerator(seed: seed)
            .generateComplete26Items()
            .map((it) => it.thetaValue)
            .toList();
        expect(thetas, equals(ref),
            reason: 'seed=$seed : le thêta est une propriété du SLOT, pas du '
                'contenu tiré.');
      }
    });
  });
}
