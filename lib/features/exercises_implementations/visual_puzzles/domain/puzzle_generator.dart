import 'dart:math';
import 'dart:ui';

/// Générateur de Puzzles Visuels selon standards WAIS-IV
/// Format: 1 puzzle cible + 6 pièces options → sélectionner 3 pièces correctes
/// Distracteurs basés sur erreurs cognitives documentées (REF, ROT-PART, 2-PIECE, EDGE-FAIL, SCALE)
class PuzzleGenerator {
  final Random _random;
  final List<PuzzleItem> _preGeneratedItems = [];
  final Set<String> _generatedSignatures = {};

  PuzzleGenerator({int? seed}) : _random = Random(seed) {
    _initializeAllItems();
  }

  /// Initialise TOUS les 26 items uniques avec génération aléatoire
  void _initializeAllItems() {
    _preGeneratedItems.clear();
    _generatedSignatures.clear();

    // Items 1-6 : Facile (θ = -1.5 à -0.5)
    for (int i = 0; i < 6; i++) {
      _addUniqueItem(() => _generateEasyItem(-1.5 + i * 0.2));
    }

    // Items 7-14 : Moyen-Facile (θ = -0.3 à 1.1)
    for (int i = 0; i < 8; i++) {
      _addUniqueItem(() => _generateMediumEasyItem(-0.3 + i * 0.175));
    }

    // Items 15-20 : Moyen (θ = 1.3 à 2.3)
    for (int i = 0; i < 6; i++) {
      _addUniqueItem(() => _generateMediumItem(1.3 + i * 0.2));
    }

    // Items 21-26 : Difficile (θ = 2.5 à 3.5)
    for (int i = 0; i < 6; i++) {
      _addUniqueItem(() => _generateHardItem(2.5 + i * 0.2));
    }
  }

  /// Ajoute un item en s'assurant qu'il est unique (pas de duplications)
  void _addUniqueItem(PuzzleItem Function() generator) {
    const maxAttempts = 50;
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      final item = generator();
      final signature = _generateItemSignature(item);

      if (!_generatedSignatures.contains(signature)) {
        _generatedSignatures.add(signature);
        _preGeneratedItems.add(item);
        return;
      }
    }
    // Fallback si échec après 50 tentatives
    _preGeneratedItems.add(generator());
  }

  /// Génère une signature unique pour détecter les duplicatas
  String _generateItemSignature(PuzzleItem item) {
    final correctShapes = item.correctIndices
        .map((i) => item.allPieces[i].shape.toString())
        .join(',');
    final correctRotations = item.correctIndices
        .map((i) => item.allPieces[i].rotation.toStringAsFixed(0))
        .join(',');
    return '$correctShapes|$correctRotations|${item.difficulty}';
  }

  /// Retourne les 26 items générés
  List<PuzzleItem> generateComplete26Items() {
    return List.from(_preGeneratedItems);
  }

  // ========== GÉNÉRATEURS PAR NIVEAU ==========

  /// Niveau 1 (Facile): 3 formes simples, 0° rotation, distracteurs évidents
  /// θ = -1.5 à -0.5 | Temps: 20s
  /// Format WAIS-IV: 1 puzzle cible + 6 options → choisir 3
  PuzzleItem _generateEasyItem(double theta) {
    final simpleShapes = [
      PieceShape.square,
      PieceShape.rectangleHorizontal,
      PieceShape.triangle,
      PieceShape.circle,
      PieceShape.rectangleVertical,
    ];
    simpleShapes.shuffle(_random);

    // PUZZLE CIBLE: 3 pièces simples sans rotation
    final shape1 = simpleShapes[0];
    final shape2 = simpleShapes[1];
    final shape3 = simpleShapes[2];

    final targetPieces = [
      PuzzlePiece(shape: shape1, position: const Offset(0, 0), rotation: 0, edgeTop: EdgeType.flat, edgeRight: EdgeType.flat, edgeBottom: EdgeType.flat, edgeLeft: EdgeType.flat),
      PuzzlePiece(shape: shape2, position: const Offset(1, 0), rotation: 0, edgeTop: EdgeType.flat, edgeRight: EdgeType.flat, edgeBottom: EdgeType.flat, edgeLeft: EdgeType.flat),
      PuzzlePiece(shape: shape3, position: const Offset(0, 1), rotation: 0, edgeTop: EdgeType.flat, edgeRight: EdgeType.flat, edgeBottom: EdgeType.flat, edgeLeft: EdgeType.flat),
    ];

    // DISTRACTEURS (3) selon erreurs cognitives WAIS-IV
    final distractors = [
      // D1 (DIF): Forme différente (erreur de différenciation)
      PuzzlePiece(shape: simpleShapes[3], position: const Offset(0, 0), rotation: 0, edgeTop: EdgeType.flat, edgeRight: EdgeType.flat, edgeBottom: EdgeType.flat, edgeLeft: EdgeType.flat),

      // D2 (SCALE): Même forme, taille incorrecte (erreur d'échelle)
      PuzzlePiece(shape: shape1, position: const Offset(0, 0), rotation: 0, scale: 0.7, edgeTop: EdgeType.flat, edgeRight: EdgeType.flat, edgeBottom: EdgeType.flat, edgeLeft: EdgeType.flat),

      // D3 (REF): Forme miroir (erreur de réflexion)
      PuzzlePiece(shape: shape2, position: const Offset(0, 0), rotation: 0, isMirrored: true, edgeTop: EdgeType.flat, edgeRight: EdgeType.flat, edgeBottom: EdgeType.flat, edgeLeft: EdgeType.flat),
    ];

    final allPieces = [...targetPieces, ...distractors];
    allPieces.shuffle(_random);

    final correctIndices = _findCorrectIndices(allPieces, targetPieces);

    return PuzzleItem(
      targetPieces: targetPieces,
      correctIndices: correctIndices,
      allPieces: allPieces,
      difficulty: DifficultyLevel.easy,
      thetaValue: theta,
      timeLimitSeconds: 20,
    );
  }

  /// Niveau 2 (Moyen-Facile): 3 formes mixtes, rotation 0-90°, distracteurs ROT-PART
  /// θ = -0.3 à 1.1 | Temps: 25s
  PuzzleItem _generateMediumEasyItem(double theta) {
    final shapes = [
      PieceShape.square,
      PieceShape.rectangleHorizontal,
      PieceShape.triangle,
      PieceShape.diamond,
      PieceShape.lShape,
    ];
    shapes.shuffle(_random);

    final shape1 = shapes[0];
    final shape2 = shapes[1];
    final shape3 = shapes[2];

    // Rotation simple: 0° ou 90° uniquement
    final rotation1 = _random.nextBool() ? 0.0 : 90.0;
    final rotation2 = _random.nextBool() ? 0.0 : 90.0;

    final targetPieces = [
      PuzzlePiece(shape: shape1, position: const Offset(0, 0), rotation: rotation1, edgeTop: EdgeType.straight, edgeRight: EdgeType.straight, edgeBottom: EdgeType.straight, edgeLeft: EdgeType.straight),
      PuzzlePiece(shape: shape2, position: const Offset(1, 0), rotation: rotation2, edgeTop: EdgeType.straight, edgeRight: EdgeType.straight, edgeBottom: EdgeType.straight, edgeLeft: EdgeType.straight),
      PuzzlePiece(shape: shape3, position: const Offset(0.5, 1), rotation: 0, edgeTop: EdgeType.straight, edgeRight: EdgeType.straight, edgeBottom: EdgeType.straight, edgeLeft: EdgeType.straight),
    ];

    // DISTRACTEURS (3) selon erreurs cognitives
    final distractors = [
      // D1 (ROT-PART): Rotation partielle incorrecte (45° au lieu de 90°)
      PuzzlePiece(shape: shape1, position: const Offset(0, 0), rotation: 45, edgeTop: EdgeType.straight, edgeRight: EdgeType.straight, edgeBottom: EdgeType.straight, edgeLeft: EdgeType.straight),

      // D2 (ROT-PART): Sur-rotation (180° au lieu de 90°)
      PuzzlePiece(shape: shape2, position: const Offset(0, 0), rotation: 180, edgeTop: EdgeType.straight, edgeRight: EdgeType.straight, edgeBottom: EdgeType.straight, edgeLeft: EdgeType.straight),

      // D3 (2-PIECE): Solution partielle (copie une pièce correcte mais ajoute forme incorrecte)
      PuzzlePiece(shape: shapes[3], position: const Offset(0, 0), rotation: 0, edgeTop: EdgeType.straight, edgeRight: EdgeType.straight, edgeBottom: EdgeType.straight, edgeLeft: EdgeType.straight),
    ];

    final allPieces = [...targetPieces, ...distractors];
    allPieces.shuffle(_random);

    final correctIndices = _findCorrectIndices(allPieces, targetPieces);

    return PuzzleItem(
      targetPieces: targetPieces,
      correctIndices: correctIndices,
      allPieces: allPieces,
      difficulty: DifficultyLevel.mediumEasy,
      thetaValue: theta,
      timeLimitSeconds: 25,
    );
  }

  /// Niveau 3 (Moyen): 3 formes complexes, rotations 90-180°, distracteurs EDGE-FAIL
  /// θ = 1.3 à 2.3 | Temps: 28s
  PuzzleItem _generateMediumItem(double theta) {
    final complexShapes = [
      PieceShape.lShape,
      PieceShape.tShape,
      PieceShape.trapezoid,
      PieceShape.diamond,
      PieceShape.triangleSmall,
    ];
    complexShapes.shuffle(_random);

    final shape1 = complexShapes[0];
    final shape2 = complexShapes[1];
    final shape3 = complexShapes[2];

    // Rotations intermédiaires: 90° ou 180°
    final rotations = [0.0, 90.0, 180.0];
    rotations.shuffle(_random);

    final targetPieces = [
      PuzzlePiece(shape: shape1, position: const Offset(0, 0), rotation: rotations[0], edgeTop: EdgeType.jagged, edgeRight: EdgeType.concave, edgeBottom: EdgeType.straight, edgeLeft: EdgeType.jagged),
      PuzzlePiece(shape: shape2, position: const Offset(1, 0), rotation: rotations[1], edgeTop: EdgeType.concave, edgeRight: EdgeType.convex, edgeBottom: EdgeType.jagged, edgeLeft: EdgeType.straight),
      PuzzlePiece(shape: shape3, position: const Offset(0.5, 1), rotation: 0, edgeTop: EdgeType.convex, edgeRight: EdgeType.jagged, edgeBottom: EdgeType.flat, edgeLeft: EdgeType.concave),
    ];

    // DISTRACTEURS (3) selon erreurs cognitives avancées
    final distractors = [
      // D1 (EDGE-FAIL): Incompatibilité d'arêtes (convex-convex au lieu de convex-concave)
      PuzzlePiece(shape: shape1, position: const Offset(0, 0), rotation: rotations[0], edgeTop: EdgeType.convex, edgeRight: EdgeType.convex, edgeBottom: EdgeType.straight, edgeLeft: EdgeType.jagged),

      // D2 (ROT-PART): Rotation critique incorrecte (120° au lieu de 90° - angle à haute erreur)
      PuzzlePiece(shape: shape2, position: const Offset(0, 0), rotation: 120, edgeTop: EdgeType.concave, edgeRight: EdgeType.convex, edgeBottom: EdgeType.jagged, edgeLeft: EdgeType.straight),

      // D3 (REF): Miroir d'une pièce correcte (erreur de réflexion horizontale)
      PuzzlePiece(shape: shape3, position: const Offset(0, 0), rotation: 0, isMirrored: true, edgeTop: EdgeType.convex, edgeRight: EdgeType.jagged, edgeBottom: EdgeType.flat, edgeLeft: EdgeType.concave),
    ];

    final allPieces = [...targetPieces, ...distractors];
    allPieces.shuffle(_random);

    final correctIndices = _findCorrectIndices(allPieces, targetPieces);

    return PuzzleItem(
      targetPieces: targetPieces,
      correctIndices: correctIndices,
      allPieces: allPieces,
      difficulty: DifficultyLevel.medium,
      thetaValue: theta,
      timeLimitSeconds: 28,
    );
  }

  /// Niveau 4 (Difficile): 3 formes irrégulières, rotations multiples (0-270°), tous types d'erreurs
  /// θ = 2.5 à 3.5 | Temps: 30s
  PuzzleItem _generateHardItem(double theta) {
    final hardShapes = [
      PieceShape.irregular,
      PieceShape.circleSector,
      PieceShape.lShape,
      PieceShape.tShape,
      PieceShape.trapezoid,
    ];
    hardShapes.shuffle(_random);

    final shape1 = hardShapes[0];
    final shape2 = hardShapes[1];
    final shape3 = hardShapes[2];

    // Rotations complètes: 0°, 90°, 180°, 270°
    final rotations = [0.0, 90.0, 180.0, 270.0];
    rotations.shuffle(_random);

    final targetPieces = [
      PuzzlePiece(shape: shape1, position: const Offset(0, 0), rotation: rotations[0], edgeTop: EdgeType.jagged, edgeRight: EdgeType.concave, edgeBottom: EdgeType.convex, edgeLeft: EdgeType.jagged),
      PuzzlePiece(shape: shape2, position: const Offset(1, 0), rotation: rotations[1], edgeTop: EdgeType.convex, edgeRight: EdgeType.jagged, edgeBottom: EdgeType.concave, edgeLeft: EdgeType.convex),
      PuzzlePiece(shape: shape3, position: const Offset(0.5, 1), rotation: rotations[2], edgeTop: EdgeType.concave, edgeRight: EdgeType.convex, edgeBottom: EdgeType.jagged, edgeLeft: EdgeType.concave),
    ];

    // DISTRACTEURS (3) combinant plusieurs types d'erreurs
    final distractors = [
      // D1 (EDGE-FAIL + SCALE): Incompatibilité d'arêtes + échelle incorrecte
      PuzzlePiece(shape: shape1, position: const Offset(0, 0), rotation: rotations[0], scale: 1.15, edgeTop: EdgeType.convex, edgeRight: EdgeType.convex, edgeBottom: EdgeType.convex, edgeLeft: EdgeType.jagged),

      // D2 (ROT-PART): Rotation critique de 120° (angle statistiquement à haute erreur selon recherche)
      PuzzlePiece(shape: shape2, position: const Offset(0, 0), rotation: 120, edgeTop: EdgeType.convex, edgeRight: EdgeType.jagged, edgeBottom: EdgeType.concave, edgeLeft: EdgeType.convex),

      // D3 (2-PIECE + REF): Solution partielle avec miroir (erreur composite)
      PuzzlePiece(shape: hardShapes[3], position: const Offset(0, 0), rotation: 90, isMirrored: true, edgeTop: EdgeType.jagged, edgeRight: EdgeType.concave, edgeBottom: EdgeType.straight, edgeLeft: EdgeType.convex),
    ];

    final allPieces = [...targetPieces, ...distractors];
    allPieces.shuffle(_random);

    final correctIndices = _findCorrectIndices(allPieces, targetPieces);

    return PuzzleItem(
      targetPieces: targetPieces,
      correctIndices: correctIndices,
      allPieces: allPieces,
      difficulty: DifficultyLevel.hard,
      thetaValue: theta,
      timeLimitSeconds: 30,
    );
  }

  // ========== FONCTIONS UTILITAIRES ==========

  /// Trouve les indices des pièces correctes après mélange
  /// Compare forme, rotation, miroir et échelle
  List<int> _findCorrectIndices(List<PuzzlePiece> allPieces, List<PuzzlePiece> targetPieces) {
    final correctIndices = <int>[];

    for (final target in targetPieces) {
      for (int i = 0; i < allPieces.length; i++) {
        if (allPieces[i].shape == target.shape &&
            allPieces[i].rotation == target.rotation &&
            allPieces[i].isMirrored == target.isMirrored &&
            (allPieces[i].scale - target.scale).abs() < 0.01 &&
            !correctIndices.contains(i)) {
          correctIndices.add(i);
          break;
        }
      }
    }

    return correctIndices;
  }

}

// ========== MODÈLES DE DONNÉES ==========

class PuzzleItem {
  final List<PuzzlePiece> targetPieces;      // 3 pièces composant le puzzle cible
  final List<int> correctIndices;             // Indices des 3 pièces correctes dans allPieces
  final List<PuzzlePiece> allPieces;          // 6 pièces options (3 correctes + 3 distracteurs)
  final DifficultyLevel difficulty;
  final double thetaValue;
  final int timeLimitSeconds;

  PuzzleItem({
    required this.targetPieces,
    required this.correctIndices,
    required this.allPieces,
    required this.difficulty,
    required this.thetaValue,
    required this.timeLimitSeconds,
  });
}

class PuzzlePiece {
  final PieceShape shape;
  final Offset position;        // Position dans le puzzle cible (0-2 pour x, 0-1 pour y)
  final double rotation;        // Rotation en degrés (0, 45, 90, 120, 180, 270)
  final bool isMirrored;        // Réflexion horizontale (erreur REF)
  final double scale;           // Échelle (erreur SCALE: 0.7-1.3)

  // Types d'arêtes pour validation EDGE-FAIL
  final EdgeType edgeTop;
  final EdgeType edgeRight;
  final EdgeType edgeBottom;
  final EdgeType edgeLeft;

  PuzzlePiece({
    required this.shape,
    required this.position,
    this.rotation = 0,
    this.isMirrored = false,
    this.scale = 1.0,
    this.edgeTop = EdgeType.flat,
    this.edgeRight = EdgeType.flat,
    this.edgeBottom = EdgeType.flat,
    this.edgeLeft = EdgeType.flat,
  });

  @override
  bool operator ==(Object other) {
    if (other is! PuzzlePiece) return false;
    return shape == other.shape &&
        position == other.position &&
        rotation == other.rotation &&
        isMirrored == other.isMirrored &&
        (scale - other.scale).abs() < 0.01;
  }

  @override
  int get hashCode => Object.hash(shape, position, rotation, isMirrored, scale);
}

/// Formes de pièces selon WAIS-IV Visual Puzzles
enum PieceShape {
  square,                   // Carré (facile)
  rectangleHorizontal,      // Rectangle horizontal (facile)
  rectangleVertical,        // Rectangle vertical (facile)
  triangle,                 // Triangle équilatéral (facile)
  triangleSmall,            // Petit triangle (moyen)
  circle,                   // Cercle (facile)
  circleSector,             // Secteur de cercle (difficile)
  diamond,                  // Losange (moyen)
  lShape,                   // Forme en L (moyen-difficile)
  tShape,                   // Forme en T (moyen-difficile)
  trapezoid,                // Trapèze (moyen-difficile)
  irregular,                // Forme irrégulière (difficile)
}

/// Types d'arêtes pour validation d'alignement (EDGE-FAIL)
enum EdgeType {
  flat,       // Arête plate (pas de connexion requise)
  straight,   // Arête droite standard
  concave,    // Arête concave (creux)
  convex,     // Arête convexe (bosse)
  jagged,     // Arête dentelée (zigzag)
}

enum DifficultyLevel {
  easy,         // θ = -1.5 à -0.5 | Formes simples, 0° rotation
  mediumEasy,   // θ = -0.3 à 1.1  | Mix formes, 0-90° rotation
  medium,       // θ = 1.3 à 2.3   | Formes complexes, 90-180° rotation
  hard,         // θ = 2.5 à 3.5   | Formes irrégulières, 0-270° rotation
}
