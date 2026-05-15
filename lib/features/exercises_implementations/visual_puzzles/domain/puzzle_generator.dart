import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'base_shapes.dart';
import 'cut_engine.dart';
import 'geometry.dart';
import 'trap_engine.dart';

export 'base_shapes.dart' show BaseShape, BaseShapeX;
export 'cut_engine.dart' show CutStrategy;
export 'geometry.dart' show Polygon, isReconstruction;

enum DifficultyLevel { veryEasy, easy, medium, hard }

extension DifficultyLevelX on DifficultyLevel {
  String get label => switch (this) {
        DifficultyLevel.veryEasy => 'Très facile',
        DifficultyLevel.easy => 'Facile',
        DifficultyLevel.medium => 'Moyen',
        DifficultyLevel.hard => 'Difficile',
      };
}

/// Pièce d'un puzzle (vraie pièce ou distracteur).
///
/// `polygon` est la silhouette de la pièce en coords normalisées
/// `targetCentroid` est la position d'origine dans la cible (utile pour
/// la silhouette globale).
@immutable
class PuzzlePiece {
  const PuzzlePiece({
    required this.id,
    required this.polygon,
    required this.targetCentroid,
    this.similarity = 1.0,
  });

  final String id;
  final Polygon polygon;
  final Offset targetCentroid;

  /// Pour les distracteurs : à quel point cette pièce ressemble à la vraie
  /// pièce d'origine. 1.0 = identique (vraie pièce), < 1.0 = piège.
  final double similarity;
}

@immutable
class PuzzleItem {
  const PuzzleItem({
    required this.index,
    required this.level,
    required this.baseShape,
    required this.targetPolygon,
    required this.targetPieces,
    required this.options,
    required this.correctIds,
    required this.timeLimitSeconds,
    required this.cutStrategy,
    required this.distractorSimilarity,
  });

  final int index;
  final DifficultyLevel level;
  final BaseShape baseShape;
  final Polygon targetPolygon;
  final List<PuzzlePiece> targetPieces;
  final List<PuzzlePiece> options;
  final Set<String> correctIds;
  final int timeLimitSeconds;
  final CutStrategy cutStrategy;

  /// Niveau de similarité moyen des 3 distracteurs (en moyenne).
  /// Faible (0.30) au début du test, élevé (0.95) à la fin.
  final double distractorSimilarity;
}

/// Générateur avec progression de similarité.
///
/// Pour chaque item, la **similarité** des distracteurs est calculée :
///   similarity = 0.35 + 0.60 × (index - 1) / 25
///
/// Item 1 → 0.35 (distracteurs très différents)
/// Item 26 → 0.95 (distracteurs presque identiques)
class PuzzleGenerator {
  PuzzleGenerator({int? seed})
      : _seed = seed ?? DateTime.now().microsecondsSinceEpoch {
    _rng = math.Random(_seed);
    _cutEngine = CutEngine(rng: math.Random(_seed + 1));
    _trapEngine = TrapEngine(rng: math.Random(_seed + 2));
  }

  final int _seed;
  late final math.Random _rng;
  late final CutEngine _cutEngine;
  late final TrapEngine _trapEngine;
  int _idCounter = 0;

  String _uuid() {
    _idCounter++;
    return 'p$_idCounter-${_rng.nextInt(1 << 30).toRadixString(36)}';
  }

  List<PuzzleItem> generateComplete26Items() {
    final items = <PuzzleItem>[];
    void add(int count, DifficultyLevel level) {
      for (int i = 0; i < count; i++) {
        items.add(_generateItem(items.length + 1, level));
      }
    }

    add(6, DifficultyLevel.veryEasy);
    add(8, DifficultyLevel.easy);
    add(6, DifficultyLevel.medium);
    add(6, DifficultyLevel.hard);
    assert(items.length == 26);
    return items;
  }

  /// Similarité ciblée pour l'item d'index `index` (1-based).
  /// Progresse linéairement de 0.35 (item 1) à 0.95 (item 26).
  static double similarityForItem(int index) {
    final t = ((index - 1) / 25.0).clamp(0.0, 1.0);
    return 0.35 + 0.60 * t;
  }

  PuzzleItem _generateItem(int index, DifficultyLevel level) {
    // 1. Forme de base (variée selon le niveau)
    final baseShape = _pickShape(level);
    final targetPolygon = buildBaseShape(baseShape);

    // 2. Stratégie de découpe
    final strategy = _pickStrategy(level);

    // 3. Découpe + invariant
    List<Polygon> cuts;
    int attempts = 0;
    do {
      cuts = _cutEngine.cut(targetPolygon, strategy);
      attempts++;
    } while (
        !isReconstruction(cuts, targetPolygon, areaTolerance: 0.04) && attempts < 8);

    // 4. Vraies pièces (similarity = 1.0)
    final truePieces = cuts
        .map((poly) => PuzzlePiece(
              id: _uuid(),
              polygon: poly,
              targetCentroid: poly.centroid(),
              similarity: 1.0,
            ))
        .toList();

    // 5. Distracteurs avec progression de similarité
    final targetSim = similarityForItem(index);
    final distractors = _buildDistractors(truePieces, targetSim);

    // 6. Mélange
    final allOptions = [...truePieces, ...distractors]..shuffle(_rng);

    return PuzzleItem(
      index: index,
      level: level,
      baseShape: baseShape,
      targetPolygon: targetPolygon,
      targetPieces: truePieces,
      options: allOptions,
      correctIds: truePieces.map((p) => p.id).toSet(),
      timeLimitSeconds: _timeLimitFor(level),
      cutStrategy: strategy,
      distractorSimilarity: targetSim,
    );
  }

  /// Construit 3 distracteurs avec des similarités proches de `targetSim`
  /// (variation de ±0.08 pour éviter l'uniformité).
  List<PuzzlePiece> _buildDistractors(List<PuzzlePiece> truePieces, double targetSim) {
    final result = <PuzzlePiece>[];
    final variations = [0.0, -0.08, 0.05]; // 3 similarities autour de targetSim
    for (int i = 0; i < 3; i++) {
      final source = truePieces[_rng.nextInt(truePieces.length)];
      final s = (targetSim + variations[i]).clamp(0.10, 0.95);
      final polygon = _trapEngine.distract(source.polygon, s);
      result.add(PuzzlePiece(
        id: _uuid(),
        polygon: polygon,
        targetCentroid: source.targetCentroid,
        similarity: s,
      ));
    }
    return result;
  }

  BaseShape _pickShape(DifficultyLevel level) {
    final pool = switch (level) {
      DifficultyLevel.veryEasy => [BaseShape.square, BaseShape.rectangle],
      DifficultyLevel.easy => [
          BaseShape.square,
          BaseShape.rectangle,
          BaseShape.triangleEq,
          BaseShape.diamond,
        ],
      DifficultyLevel.medium => [
          BaseShape.square,
          BaseShape.rectangle,
          BaseShape.triangleEq,
          BaseShape.triangleRight,
          BaseShape.hexagon,
          BaseShape.diamond,
          BaseShape.pentagon,
        ],
      DifficultyLevel.hard => BaseShape.values,
    };
    return pool[_rng.nextInt(pool.length)];
  }

  CutStrategy _pickStrategy(DifficultyLevel level) {
    final pool = switch (level) {
      DifficultyLevel.veryEasy => [
          CutStrategy.twoParallelStraight,
          CutStrategy.perpendicularL,
        ],
      DifficultyLevel.easy => [
          CutStrategy.twoParallelStraight,
          CutStrategy.perpendicularL,
          CutStrategy.oneStraightOneOblique,
        ],
      DifficultyLevel.medium => [
          CutStrategy.perpendicularL,
          CutStrategy.oneStraightOneOblique,
          CutStrategy.twoOblique,
          CutStrategy.threeFromCenter,
        ],
      DifficultyLevel.hard => CutStrategy.values,
    };
    return pool[_rng.nextInt(pool.length)];
  }

  int _timeLimitFor(DifficultyLevel level) => switch (level) {
        DifficultyLevel.veryEasy => 25,
        DifficultyLevel.easy => 30,
        DifficultyLevel.medium => 35,
        DifficultyLevel.hard => 40,
      };
}
