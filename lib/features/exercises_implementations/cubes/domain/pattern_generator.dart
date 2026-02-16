import 'dart:math';
import '../presentation/widgets/cubes_exercise_widget.dart';

/// Générateur procédural de patterns pour le test des Cubes
/// Génération 100% aléatoire avec contraintes de difficulté
class CubePatternGenerator {
  final Random _random;

  CubePatternGenerator({int? seed}) : _random = Random(seed);

  /// Génère un pattern aléatoire selon le niveau de difficulté
  CubePattern generatePattern(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.example:
        return _generateExample();
      case DifficultyLevel.veryEasy:
        return _generate2x2Simple();
      case DifficultyLevel.easy:
      case DifficultyLevel.medium:
        return _generate3x3Moderate();
      case DifficultyLevel.mediumHard:
      case DifficultyLevel.hard:
      case DifficultyLevel.veryHard:
        return _generate3x3Complex();
    }
  }

  /// Items 1-2 : Exemples (génération aléatoire simple)
  CubePattern _generateExample() {
    final pattern = List.generate(2, (_) => List.generate(2, (_) =>
      _random.nextBool() ? CubeFace.redSolid : CubeFace.whiteSolid
    ));

    return CubePattern(
      gridSize: 2,
      pattern: pattern,
      cohesionScore: 0,
      timeLimit: 999,
      description: 'Item exemple - Ne compte pas pour le score',
      difficulty: DifficultyLevel.example,
    );
  }

  /// Items 3-5 : 2×2 simple (TOUS les cubes sont différents)
  CubePattern _generate2x2Simple() {
    // Génération aléatoire pure - 2 solides seulement
    final pattern = List.generate(2, (_) => List.generate(2, (_) =>
      _random.nextBool() ? CubeFace.redSolid : CubeFace.whiteSolid
    ));

    return CubePattern(
      gridSize: 2,
      pattern: pattern,
      cohesionScore: _calculateCohesion(pattern),
      timeLimit: 30,
      description: 'Pattern 2×2 simple',
      difficulty: DifficultyLevel.veryEasy,
    );
  }

  /// Items 6-9 : 3×3 modéré avec diagonales
  CubePattern _generate3x3Moderate() {
    final pattern = _generateRandom3x3(useDiagonals: true, diagonalProbability: 0.4);

    return CubePattern(
      gridSize: 3,
      pattern: pattern,
      cohesionScore: _calculateCohesion(pattern),
      timeLimit: 60,
      description: 'Pattern 3×3 avec diagonales',
      difficulty: DifficultyLevel.easy,
    );
  }

  /// Items 10-14 : 3×3 complexe (BEAUCOUP de diagonales, toutes rotations)
  CubePattern _generate3x3Complex() {
    final pattern = _generateRandom3x3(useDiagonals: true, diagonalProbability: 0.7);

    return CubePattern(
      gridSize: 3,
      pattern: pattern,
      cohesionScore: _calculateCohesion(pattern),
      timeLimit: 120,
      description: 'Pattern 3×3 complexe - Haute cohésion',
      difficulty: DifficultyLevel.veryHard,
    );
  }

  /// Génère un pattern 3×3 complètement aléatoire
  List<List<CubeFace>> _generateRandom3x3({
    required bool useDiagonals,
    required double diagonalProbability,
  }) {
    final allFaces = <CubeFace>[
      CubeFace.whiteSolid,
      CubeFace.redSolid,
      if (useDiagonals) ...[
        CubeFace.diagonalRedWhite_0,
        CubeFace.diagonalRedWhite_90,
        CubeFace.diagonalRedWhite_180,
        CubeFace.diagonalRedWhite_270,
      ],
    ];

    return List.generate(3, (row) {
      return List.generate(3, (col) {
        // Décider si on utilise une diagonale ou un solide
        final useDiagonal = useDiagonals && _random.nextDouble() < diagonalProbability;

        if (useDiagonal) {
          // Choisir une rotation aléatoire parmi les 4
          final diagonals = [
            CubeFace.diagonalRedWhite_0,
            CubeFace.diagonalRedWhite_90,
            CubeFace.diagonalRedWhite_180,
            CubeFace.diagonalRedWhite_270,
          ];
          return diagonals[_random.nextInt(4)];
        } else {
          // Solide rouge ou blanc
          return _random.nextBool() ? CubeFace.redSolid : CubeFace.whiteSolid;
        }
      });
    });
  }

  /// Calcule le score de cohésion (nombre d'arêtes adjacentes de même couleur)
  int _calculateCohesion(List<List<CubeFace>> pattern) {
    int cohesion = 0;
    final size = pattern.length;

    for (int i = 0; i < size; i++) {
      for (int j = 0; j < size; j++) {
        // Vérifier arête droite
        if (j < size - 1) {
          if (_edgesMatch(pattern[i][j], pattern[i][j + 1], EdgeDirection.horizontal)) {
            cohesion++;
          }
        }
        // Vérifier arête bas
        if (i < size - 1) {
          if (_edgesMatch(pattern[i][j], pattern[i + 1][j], EdgeDirection.vertical)) {
            cohesion++;
          }
        }
      }
    }

    return cohesion;
  }

  /// Vérifie si deux faces ont des arêtes de même couleur
  bool _edgesMatch(CubeFace face1, CubeFace face2, EdgeDirection direction) {
    final color1 = _getEdgeColor(face1, direction, isRightOrBottom: true);
    final color2 = _getEdgeColor(face2, direction, isRightOrBottom: false);
    return color1 == color2;
  }

  /// Récupère la couleur d'une arête spécifique (gère les 4 rotations)
  EdgeColor _getEdgeColor(CubeFace face, EdgeDirection direction, {required bool isRightOrBottom}) {
    switch (face) {
      case CubeFace.whiteSolid:
        return EdgeColor.white;
      case CubeFace.redSolid:
        return EdgeColor.red;

      // Rotation 0° : Rouge haut-gauche (↘)
      case CubeFace.diagonalRedWhite_0:
      case CubeFace.diagonalRedWhite:
        if (direction == EdgeDirection.horizontal) {
          return isRightOrBottom ? EdgeColor.white : EdgeColor.red;
        } else {
          return isRightOrBottom ? EdgeColor.white : EdgeColor.red;
        }

      // Rotation 90° : Rouge haut-droite (↙)
      case CubeFace.diagonalRedWhite_90:
        if (direction == EdgeDirection.horizontal) {
          return isRightOrBottom ? EdgeColor.red : EdgeColor.white;
        } else {
          return isRightOrBottom ? EdgeColor.white : EdgeColor.red;
        }

      // Rotation 180° : Rouge bas-droite (↖)
      case CubeFace.diagonalRedWhite_180:
      case CubeFace.diagonalWhiteRed:
        if (direction == EdgeDirection.horizontal) {
          return isRightOrBottom ? EdgeColor.red : EdgeColor.white;
        } else {
          return isRightOrBottom ? EdgeColor.red : EdgeColor.white;
        }

      // Rotation 270° : Rouge bas-gauche (↗)
      case CubeFace.diagonalRedWhite_270:
        if (direction == EdgeDirection.horizontal) {
          return isRightOrBottom ? EdgeColor.white : EdgeColor.red;
        } else {
          return isRightOrBottom ? EdgeColor.red : EdgeColor.white;
        }
    }
  }
}

/// Modèle de pattern de cubes
class CubePattern {
  final int gridSize;
  final List<List<CubeFace>> pattern;
  final int cohesionScore;
  final int timeLimit;
  final String description;
  final DifficultyLevel difficulty;

  CubePattern({
    required this.gridSize,
    required this.pattern,
    required this.cohesionScore,
    required this.timeLimit,
    required this.description,
    required this.difficulty,
  });
}

/// Niveaux de difficulté
enum DifficultyLevel {
  example,       // Items 1-2 : Exemples (non cotés)
  veryEasy,      // Items 3-5 : 2×2 simple (30s, 2 pts)
  easy,          // Items 6-7 : 3×3 modéré (60s, 4-7 pts + bonus)
  medium,        // Items 8-9 : 3×3 modéré (60s, 4-7 pts + bonus)
  mediumHard,    // Items 10-11 : 3×3 complexe (120s, 4-7 pts + bonus)
  hard,          // Item 12-13 : 3×3 complexe (120s, 4-7 pts + bonus)
  veryHard,      // Item 14 : 3×3 très complexe (120s, 4-7 pts + bonus)
}

/// Direction d'arête
enum EdgeDirection { horizontal, vertical }

/// Couleur d'arête
enum EdgeColor { red, white, mixed }
