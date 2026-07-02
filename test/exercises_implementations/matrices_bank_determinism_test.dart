import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/features/exercises_implementations/matrices/domain/matrix_generator.dart';

/// Signature canonique et stable d'une cellule (champs identifiants).
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

/// Signature canonique d'un item : grille + bonne réponse + options (ordre inclus)
/// + difficulté + thêta. Deux items sont « identiques » ssi leurs signatures le sont.
String _itemSig(MatrixItem item) {
  final matrixSig = item.matrix
      .map((row) => row.map(_cellSig).join(','))
      .join(';');
  final optionsSig = item.options.map(_cellSig).join(','); // ORDRE significatif
  final rulesSig = item.rules.map((r) => r.index).join('-');
  return [
    'grid=${item.gridSize}',
    'theta=${item.thetaValue.toStringAsFixed(4)}',
    'diff=${item.difficulty.index}',
    'rules=$rulesSig',
    'matrix=$matrixSig',
    'answer=${_cellSig(item.correctAnswer)}',
    'options=$optionsSig',
  ].join('|');
}

void main() {
  group('MatrixGenerator — banque déterministe et versionnée', () {
    test('deux instances produisent une banque IDENTIQUE (mêmes items, même ordre)', () {
      final a = MatrixGenerator().generateComplete26Items();
      final b = MatrixGenerator().generateComplete26Items();

      // Garde-fou : la banque doit contenir exactement 26 items.
      expect(a.length, 26, reason: 'La banque doit produire 26 items.');
      expect(b.length, a.length, reason: 'Les deux banques doivent avoir la même taille.');

      // Comparaison item par item : si la moindre source d'aléa fuit
      // (Random non seedé, shuffle() sans argument, itération de Set, etc.),
      // au moins une signature diffère et le test échoue.
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

    test('l\'ordre des paliers de difficulté est préservé (5+7+6+5+3)', () {
      final items = MatrixGenerator().generateComplete26Items();
      final difficulties = items.map((it) => it.difficulty).toList();

      final expectedOrder = <DifficultyLevel>[
        ...List.filled(5, DifficultyLevel.veryEasy),
        ...List.filled(7, DifficultyLevel.easy),
        ...List.filled(6, DifficultyLevel.medium),
        ...List.filled(5, DifficultyLevel.mediumHard),
        ...List.filled(3, DifficultyLevel.hard),
      ];

      expect(difficulties, equals(expectedOrder),
          reason: 'Les 26 items doivent suivre l\'ordre de difficulté attendu.');
    });

    test('la graine de banque est figée (versionnage)', () {
      expect(MatrixGenerator.kBankSeed, 20260616,
          reason: 'Bumper kBankSeed est le seul moyen de régénérer la banque.');
    });
  });
}
