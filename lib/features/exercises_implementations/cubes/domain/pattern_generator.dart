import 'dart:math';
import '../presentation/widgets/cubes_exercise_widget.dart';

/// Générateur procédural de patterns pour le test des Cubes
/// Génération ALÉATOIRE PAR PASSATION : les motifs sont tirés au hasard à
/// chaque session — deux passations ne présentent pas les mêmes items. La
/// PROGRESSION de difficulté, elle, est fixe ([kDifficultyProgression]) :
/// chaque slot garde son niveau et son barème quel que soit le tirage.
class CubePatternGenerator {
  /// Progression de difficulté CANONIQUE (14 items, dont 12 cotés).
  /// 2 exemples (non cotés) + 3 très faciles + 4 modérés + 5 complexes.
  /// L'ordre est FIGÉ : ne pas réordonner (échelle de difficulté commune
  /// à toutes les passations, seul le CONTENU des items change).
  static const List<DifficultyLevel> kDifficultyProgression = <DifficultyLevel>[
    // Items 1-2 : Exemples (non cotés)
    DifficultyLevel.example,
    DifficultyLevel.example,

    // Items 3-5 : 2×2 simple (2 points, pas de bonus)
    DifficultyLevel.veryEasy,
    DifficultyLevel.veryEasy,
    DifficultyLevel.veryEasy,

    // Items 6-9 : 3×3 modéré avec diagonales (4 points)
    DifficultyLevel.easy,
    DifficultyLevel.easy,
    DifficultyLevel.medium,
    DifficultyLevel.medium,

    // Items 10-14 : 3×3 complexe, haute cohésion (4 points)
    DifficultyLevel.mediumHard,
    DifficultyLevel.mediumHard,
    DifficultyLevel.hard,
    DifficultyLevel.veryHard,
    DifficultyLevel.veryHard,
  ];

  /// Les trois items d'ENTRAÎNEMENT, écrits à la main et identiques pour tout
  /// le monde. Ils ne mesurent rien : ils apprennent l'interface, et l'ordre
  /// est ce qui compte.
  ///
  /// 1. **Deux couleurs pleines.** Un appui suffit : on découvre qu'une case
  ///    se change en la touchant.
  /// 2. **Des diagonales.** Aucune ne s'obtient en un appui — il faut toucher
  ///    la MÊME case plusieurs fois pour parcourir le cycle
  ///    blanc → rouge → 4 diagonales. C'est le seul item qui l'enseigne, et
  ///    c'est sa raison d'être : sans lui, les faces diagonales se découvrent
  ///    à l'item 6 coté, chrono lancé.
  /// 3. **Une 3×3 mêlant les deux**, au format des items cotés.
  ///
  /// Écrits en dur plutôt que tirés d'une seed : un tirage « très facile »
  /// 2×2 ne contient JAMAIS de diagonale (cf. [_generate2x2Simple]), donc
  /// aucune seed ne peut produire l'item 2.
  static List<CubePattern> demoPatterns() => <CubePattern>[
        // 1 — pleines seulement : 1 appui (rouge), 0 appui (blanc).
        _demo(2, const [
          [CubeFace.redSolid, CubeFace.whiteSolid],
          [CubeFace.whiteSolid, CubeFace.redSolid],
        ]),
        // 2 — deux diagonales : 2 appuis pour ↘, 4 pour ↖.
        _demo(2, const [
          [CubeFace.redSolid, CubeFace.diagonalRedWhite_0],
          [CubeFace.diagonalRedWhite_180, CubeFace.whiteSolid],
        ]),
        // 3 — croix rouge et quatre coins diagonaux pointant vers l'extérieur.
        _demo(3, const [
          [
            CubeFace.diagonalRedWhite_0,
            CubeFace.redSolid,
            CubeFace.diagonalRedWhite_90
          ],
          [CubeFace.redSolid, CubeFace.redSolid, CubeFace.redSolid],
          [
            CubeFace.diagonalRedWhite_270,
            CubeFace.redSolid,
            CubeFace.diagonalRedWhite_180
          ],
        ]),
      ];

  /// Fabrique d'item d'entraînement : hors barème, hors chrono.
  ///
  /// `timeLimit` n'est jamais lu — la page passe `timeLimitSeconds: null`
  /// pendant l'entraînement — mais le champ est requis par [CubePattern].
  static CubePattern _demo(int gridSize, List<List<CubeFace>> pattern) =>
      CubePattern(
        gridSize: gridSize,
        pattern: pattern.map(List<CubeFace>.from).toList(),
        cohesionScore: 0,
        timeLimit: 999,
        description: 'Item d\'entraînement — ne compte pas',
        difficulty: DifficultyLevel.example,
      );

  final Random _random;

  /// [seed] optionnel : tirage reproductible (tests, item de démonstration).
  /// null = aléatoire réel → items différents à chaque passation.
  CubePatternGenerator({int? seed}) : _random = Random(seed);

  /// Construit la banque complète des 14 items, dans l'ordre canonique
  /// de [kDifficultyProgression].
  List<CubePattern> generateBank() {
    return kDifficultyProgression
        .map((difficulty) => generatePattern(difficulty))
        .toList();
  }

  /// Génère un pattern aléatoire selon le niveau de difficulté
  CubePattern generatePattern(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.example:
        return _generateExample();
      case DifficultyLevel.veryEasy:
        return _generate2x2Simple();
      case DifficultyLevel.easy:
      case DifficultyLevel.medium:
        return _generate3x3Moderate(difficulty);
      case DifficultyLevel.mediumHard:
      case DifficultyLevel.hard:
      case DifficultyLevel.veryHard:
        return _generate3x3Complex(difficulty);
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
  CubePattern _generate3x3Moderate(DifficultyLevel difficulty) {
    final pattern = _generateRandom3x3(useDiagonals: true, diagonalProbability: 0.4);

    return CubePattern(
      gridSize: 3,
      pattern: pattern,
      cohesionScore: _calculateCohesion(pattern),
      timeLimit: 60,
      description: 'Pattern 3×3 avec diagonales',
      difficulty: difficulty,
    );
  }

  /// Items 10-14 : 3×3 complexe (BEAUCOUP de diagonales, toutes rotations)
  CubePattern _generate3x3Complex(DifficultyLevel difficulty) {
    final pattern = _generateRandom3x3(useDiagonals: true, diagonalProbability: 0.7);

    return CubePattern(
      gridSize: 3,
      pattern: pattern,
      cohesionScore: _calculateCohesion(pattern),
      timeLimit: 120,
      description: 'Pattern 3×3 complexe - Haute cohésion',
      difficulty: difficulty,
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
