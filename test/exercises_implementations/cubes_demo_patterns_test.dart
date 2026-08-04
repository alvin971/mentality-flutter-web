import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/features/exercises_implementations/cubes/domain/pattern_generator.dart';
import 'package:mentality/features/exercises_implementations/cubes/presentation/widgets/cubes_exercise_widget.dart';

/// Les trois items d'ENTRAÎNEMENT des Cubes ne mesurent rien : ils
/// apprennent l'interface. Ce test tient la seule promesse qui compte —
/// **l'entraînement doit obliger à découvrir le multi-appui**.
///
/// La grille de l'utilisateur démarre toute blanche, et un appui fait avancer
/// une case d'un cran dans le cycle
/// blanc → rouge → ↘ → ↙ → ↖ → ↗ → blanc (`_toggleCube`). Un motif
/// d'entraînement fait uniquement d'aplats se résout donc à un appui par
/// case, et n'apprend rien des faces diagonales : elles se découvraient à
/// l'item 6 coté, chronométré.
const _cycle = <CubeFace>[
  CubeFace.whiteSolid,
  CubeFace.redSolid,
  CubeFace.diagonalRedWhite_0,
  CubeFace.diagonalRedWhite_90,
  CubeFace.diagonalRedWhite_180,
  CubeFace.diagonalRedWhite_270,
];

/// Nombre d'appuis nécessaires pour amener une case de blanc à [face].
int _tapsFor(CubeFace face) {
  final i = _cycle.indexOf(face);
  expect(i, isNot(-1),
      reason: 'face $face inatteignable : hors du cycle de _toggleCube — '
          'un motif qui la contient serait insoluble');
  return i;
}

/// Appuis nécessaires sur la case la plus coûteuse du motif.
int _maxTaps(CubePattern p) =>
    p.pattern.expand((row) => row).map(_tapsFor).reduce((a, b) => a > b ? a : b);

void main() {
  group('Cubes — les trois items d\'entraînement', () {
    final demos = CubePatternGenerator.demoPatterns();

    test('il y en a trois, tous hors barème', () {
      expect(demos, hasLength(3));
      for (final d in demos) {
        expect(d.difficulty, DifficultyLevel.example);
        expect(d.cohesionScore, 0);
      }
    });

    test('toutes les faces sont atteignables au doigt', () {
      // _tapsFor échoue sur une face hors cycle (les alias
      // diagonalRedWhite / diagonalWhiteRed, notamment, que le cycle ne
      // produit jamais : un motif qui en contient ne peut PAS être résolu).
      for (final d in demos) {
        expect(() => _maxTaps(d), returnsNormally);
      }
    });

    test('le 1er s\'obtient en un appui par case', () {
      expect(_maxTaps(demos[0]), 1,
          reason: 'le premier item enseigne « toucher change la case », '
              'rien de plus');
    });

    test('le 2e EXIGE plusieurs appuis sur une même case', () {
      expect(_maxTaps(demos[1]), greaterThan(1),
          reason: "c'est la raison d'être de l'item 2 : sans lui, on découvre "
              'les faces diagonales à l\'item 6 coté, chrono lancé');
      final faces = demos[1].pattern.expand((row) => row).toSet();
      expect(faces.any((f) => _tapsFor(f) >= 2), isTrue);
    });

    test('le 3e est une 3×3 qui garde des diagonales', () {
      expect(demos[2].gridSize, 3);
      expect(_maxTaps(demos[2]), greaterThan(1));
    });

    test('les trois items sont fixes — mêmes motifs à chaque appel', () {
      final again = CubePatternGenerator.demoPatterns();
      for (var i = 0; i < demos.length; i++) {
        expect(again[i].pattern, demos[i].pattern,
            reason: 'tout le monde s\'entraîne sur les mêmes items');
      }
    });

    test('les motifs d\'entraînement ne sont pas modifiables entre appels', () {
      // Chaque appel doit rendre des lignes NEUVES : le widget d'exercice
      // reçoit `targetPattern` et rien ne lui interdit d'y écrire.
      CubePatternGenerator.demoPatterns()[0].pattern[0][0] = CubeFace.redSolid;
      expect(CubePatternGenerator.demoPatterns()[0].pattern[0][0],
          demos[0].pattern[0][0]);
    });
  });
}
