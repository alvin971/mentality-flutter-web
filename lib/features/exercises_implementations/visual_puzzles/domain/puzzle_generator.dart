import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'base_shapes.dart';
import 'cut_engine.dart';
import 'geometry.dart';
import 'trap_engine.dart';

// Re-exports pour compatibilité avec les widgets existants
export 'base_shapes.dart' show BaseShape, BaseShapeX;
export 'cut_engine.dart' show CutStrategy;
export 'geometry.dart' show Polygon, isReconstruction;
export 'trap_engine.dart' show TrapKind;

/// Niveau de difficulté d'un item (conforme à la progression WAIS-IV).
enum DifficultyLevel { veryEasy, easy, medium, hard }

extension DifficultyLevelX on DifficultyLevel {
  String get label => switch (this) {
        DifficultyLevel.veryEasy => 'Très facile',
        DifficultyLevel.easy => 'Facile',
        DifficultyLevel.medium => 'Moyen',
        DifficultyLevel.hard => 'Difficile',
      };
}

/// Une pièce de puzzle (vraie ou distracteur).
///
/// Identité stable via `id`. Le `polygon` est le contenu visuel ; la
/// position d'origine dans la cible est `targetCentroid` (utilisée pour
/// reconstituer la silhouette).
@immutable
class PuzzlePiece {
  const PuzzlePiece({
    required this.id,
    required this.polygon,
    required this.targetCentroid,
  });

  final String id;
  final Polygon polygon;
  final Offset targetCentroid;
}

/// Item complet : cible + 3 pièces vraies + 3 distracteurs.
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
  });

  final int index;
  final DifficultyLevel level;
  final BaseShape baseShape;

  /// Le polygone de la cible (forme entière non-découpée).
  final Polygon targetPolygon;

  /// Les 3 pièces vraies. Quand on les remet à leur targetCentroid, elles
  /// reconstituent `targetPolygon` (invariant testé).
  final List<PuzzlePiece> targetPieces;

  /// Les 6 options présentées (3 vraies + 3 pièges), mélangées.
  final List<PuzzlePiece> options;

  /// IDs des 3 pièces vraies.
  final Set<String> correctIds;

  final int timeLimitSeconds;
  final CutStrategy cutStrategy;
}

/// Générateur de 26 items WAIS-IV Visual Puzzles, version polygonale.
///
/// Pipeline par item :
/// 1. Choisir une `BaseShape` selon le niveau.
/// 2. Construire le polygone cible normalisé.
/// 3. Découper via `CutEngine` selon une stratégie compatible avec le niveau.
/// 4. Valider l'invariant : les 3 pièces reconstituent la cible.
/// 5. Générer 3 distracteurs via `TrapEngine` avec un pool de pièges
///    croissant en subtilité selon le niveau.
/// 6. Mélanger les 6 options.
class PuzzleGenerator {
  PuzzleGenerator({int? seed})
      : _rng = math.Random(seed ?? DateTime.now().microsecondsSinceEpoch),
        _cutEngine = CutEngine(rng: math.Random(seed ?? DateTime.now().microsecondsSinceEpoch)),
        _trapEngine = TrapEngine(rng: math.Random(seed ?? DateTime.now().microsecondsSinceEpoch));

  final math.Random _rng;
  final CutEngine _cutEngine;
  final TrapEngine _trapEngine;
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

  PuzzleItem _generateItem(int index, DifficultyLevel level) {
    // 1. Forme de base
    final baseShape = _pickShape(level);
    final targetPolygon = buildBaseShape(baseShape);

    // 2. Stratégie de découpe
    final strategy = _pickStrategy(level);

    // 3. Découpe + validation invariant
    List<Polygon> cuts;
    int attempts = 0;
    do {
      cuts = _cutEngine.cut(targetPolygon, strategy);
      attempts++;
    } while (
        !isReconstruction(cuts, targetPolygon, areaTolerance: 0.03) && attempts < 8);

    // 4. Construction des pièces vraies (avec id stable + centroïde d'origine)
    final truePieces = cuts
        .map((poly) => PuzzlePiece(
              id: _uuid(),
              polygon: poly,
              targetCentroid: poly.centroid(),
            ))
        .toList();

    // 5. Distracteurs : pool de pièges selon niveau
    final distractors = _buildDistractors(truePieces, level);

    // 6. Mélanger
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
    );
  }

  BaseShape _pickShape(DifficultyLevel level) {
    final pool = switch (level) {
      DifficultyLevel.veryEasy => [BaseShape.square, BaseShape.rectangle],
      DifficultyLevel.easy => [
          BaseShape.square,
          BaseShape.rectangle,
          BaseShape.triangleEq,
        ],
      DifficultyLevel.medium => [
          BaseShape.square,
          BaseShape.rectangle,
          BaseShape.triangleEq,
          BaseShape.triangleRight,
          BaseShape.hexagon,
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
          CutStrategy.oneBent,
        ],
      DifficultyLevel.hard => [
          CutStrategy.twoOblique,
          CutStrategy.oneBent,
          CutStrategy.twoBent,
        ],
    };
    return pool[_rng.nextInt(pool.length)];
  }

  List<TrapKind> _trapPoolFor(DifficultyLevel level) => switch (level) {
        DifficultyLevel.veryEasy => [
            TrapKind.random,
            TrapKind.random,
            TrapKind.rotate180,
            TrapKind.scaleBig,
          ],
        DifficultyLevel.easy => [
            TrapKind.random,
            TrapKind.mirror,
            TrapKind.rotate180,
            TrapKind.scaleBig,
          ],
        DifficultyLevel.medium => [
            TrapKind.rotate90,
            TrapKind.mirror,
            TrapKind.scaleBig,
            TrapKind.vertexNudgeMedium,
          ],
        DifficultyLevel.hard => [
            TrapKind.vertexNudgeMedium,
            TrapKind.vertexNudgeSmall,
            TrapKind.scaleSubtle,
            TrapKind.rotate90,
            TrapKind.mirror,
          ],
      };

  List<PuzzlePiece> _buildDistractors(
      List<PuzzlePiece> truePieces, DifficultyLevel level) {
    final pool = _trapPoolFor(level).toList()..shuffle(_rng);
    final picks = pool.take(3).toList();
    return picks.map((kind) {
      final source = truePieces[_rng.nextInt(truePieces.length)];
      final modified = _trapEngine.apply(source.polygon, kind);
      return PuzzlePiece(
        id: _uuid(),
        polygon: modified,
        targetCentroid: source.targetCentroid,
      );
    }).toList();
  }

  int _timeLimitFor(DifficultyLevel level) => switch (level) {
        DifficultyLevel.veryEasy => 25,
        DifficultyLevel.easy => 30,
        DifficultyLevel.medium => 35,
        DifficultyLevel.hard => 40,
      };
}
