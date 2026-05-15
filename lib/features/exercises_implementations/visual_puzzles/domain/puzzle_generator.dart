import 'dart:math' as math;
import 'package:flutter/material.dart';

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

/// Forme géométrique de base d'une pièce.
enum PuzzleShape {
  square,
  rectangleH,
  rectangleV,
  triangle,
  trapezoid,
  parallelogram,
  lShape,
  tShape,
  zShape,
}

/// Type d'arête d'une pièce (utile pour 4 côtés top/right/bottom/left).
///
/// Les paires complémentaires (qui s'emboîtent visuellement) :
///   - flat ↔ flat
///   - convex ↔ concave
///   - jaggedOut ↔ jaggedIn
enum EdgeType { flat, convex, concave, jaggedOut, jaggedIn }

/// Pattern de 4 arêtes d'une pièce. Pour les formes non-rectangulaires
/// (triangle, parallélogramme…), seules `top` et `bottom` sont utilisées.
@immutable
class EdgePattern {
  const EdgePattern({
    this.top = EdgeType.flat,
    this.right = EdgeType.flat,
    this.bottom = EdgeType.flat,
    this.left = EdgeType.flat,
  });

  final EdgeType top;
  final EdgeType right;
  final EdgeType bottom;
  final EdgeType left;
}

/// Une pièce de puzzle individuelle.
///
/// Identité stable via `id` (UUID-like) — évite les bugs de matching par
/// attributs identiques.
@immutable
class PuzzlePiece {
  const PuzzlePiece({
    required this.id,
    required this.shape,
    this.rotationDeg = 0,
    this.mirrored = false,
    this.scale = 1.0,
    this.edges = const EdgePattern(),
    this.gridX = 0,
    this.gridY = 0,
    this.gridW = 1,
    this.gridH = 1,
  });

  final String id;
  final PuzzleShape shape;
  final double rotationDeg; // 0, 90, 180, 270
  final bool mirrored;
  final double scale; // 0.8 .. 1.2
  final EdgePattern edges;

  /// Position dans la grille de la cible (en unités de cellule).
  final int gridX;
  final int gridY;
  final int gridW;
  final int gridH;

  PuzzlePiece copyWith({
    String? id,
    PuzzleShape? shape,
    double? rotationDeg,
    bool? mirrored,
    double? scale,
    EdgePattern? edges,
    int? gridX,
    int? gridY,
    int? gridW,
    int? gridH,
  }) =>
      PuzzlePiece(
        id: id ?? this.id,
        shape: shape ?? this.shape,
        rotationDeg: rotationDeg ?? this.rotationDeg,
        mirrored: mirrored ?? this.mirrored,
        scale: scale ?? this.scale,
        edges: edges ?? this.edges,
        gridX: gridX ?? this.gridX,
        gridY: gridY ?? this.gridY,
        gridW: gridW ?? this.gridW,
        gridH: gridH ?? this.gridH,
      );
}

/// Un item complet du test : cible + 6 options dont 3 correctes.
@immutable
class PuzzleItem {
  const PuzzleItem({
    required this.index,
    required this.level,
    required this.targetPieces,
    required this.options,
    required this.correctIds,
    required this.timeLimitSeconds,
    required this.gridCols,
    required this.gridRows,
  });

  final int index; // 1..26
  final DifficultyLevel level;

  /// Les 3 pièces qui composent la cible (avec leur position dans la grille).
  final List<PuzzlePiece> targetPieces;

  /// Les 6 options présentées au sujet (3 correctes + 3 distracteurs), mélangées.
  final List<PuzzlePiece> options;

  /// Set des ids de pièces correctes (= targetPieces.map((p) => p.id).toSet()).
  /// Le matching de validation se fait par comparaison de ce set.
  final Set<String> correctIds;

  final int timeLimitSeconds;
  final int gridCols;
  final int gridRows;
}

// ============================================================
// GÉNÉRATEUR
// ============================================================

/// Générateur de 26 items WAIS-IV Visual Puzzles.
///
/// Distribution :
///   - 6 items très faciles (1-6)
///   - 8 items faciles (7-14)
///   - 6 items moyens (15-20)
///   - 6 items difficiles (21-26)
class PuzzleGenerator {
  PuzzleGenerator({int? seed}) : _rng = math.Random(seed);

  final math.Random _rng;
  int _idCounter = 0;

  String _uuid() {
    _idCounter++;
    return 'p$_idCounter-${_rng.nextInt(1 << 30).toRadixString(36)}';
  }

  List<PuzzleItem> generateComplete26Items() {
    final items = <PuzzleItem>[];
    _DistractorType? lastDistractorType;

    void addItems(int count, DifficultyLevel level) {
      for (int i = 0; i < count; i++) {
        final item = _generateItem(items.length + 1, level, lastDistractorType);
        items.add(item);
        lastDistractorType = _DistractorType
            .values[_rng.nextInt(_DistractorType.values.length)];
      }
    }

    addItems(6, DifficultyLevel.veryEasy);
    addItems(8, DifficultyLevel.easy);
    addItems(6, DifficultyLevel.medium);
    addItems(6, DifficultyLevel.hard);

    assert(items.length == 26, 'expected 26 items, got ${items.length}');
    return items;
  }

  PuzzleItem _generateItem(
      int index, DifficultyLevel level, _DistractorType? avoidType) {
    final (targetPieces, cols, rows) = _buildTarget(level);
    final distractors = _buildDistractors(targetPieces, level, avoidType);
    final options = [...targetPieces, ...distractors]..shuffle(_rng);

    return PuzzleItem(
      index: index,
      level: level,
      targetPieces: targetPieces,
      options: options,
      correctIds: targetPieces.map((p) => p.id).toSet(),
      timeLimitSeconds: _timeLimitFor(level),
      gridCols: cols,
      gridRows: rows,
    );
  }

  /// Construit 3 pièces consécutives qui s'emboîtent dans une rangée 3×1.
  /// Les arêtes adjacentes sont complémentaires (convex ↔ concave, etc.).
  (List<PuzzlePiece>, int, int) _buildTarget(DifficultyLevel level) {
    final shapes = _shapesFor(level);
    final pieces = <PuzzlePiece>[];

    const cols = 3;
    const rows = 1;
    EdgeType prevRight = EdgeType.flat;

    for (int i = 0; i < 3; i++) {
      final isFirst = i == 0;
      final isLast = i == 2;
      final leftEdge = isFirst ? EdgeType.flat : _complementOf(prevRight);
      final rightEdge = isLast ? EdgeType.flat : _randomNonFlatEdge(level);

      pieces.add(PuzzlePiece(
        id: _uuid(),
        shape: shapes[i],
        rotationDeg: 0,
        mirrored: false,
        scale: 1.0,
        edges: EdgePattern(
          top: EdgeType.flat,
          right: rightEdge,
          bottom: EdgeType.flat,
          left: leftEdge,
        ),
        gridX: i,
        gridY: 0,
        gridW: 1,
        gridH: 1,
      ));
      prevRight = rightEdge;
    }
    return (pieces, cols, rows);
  }

  EdgeType _complementOf(EdgeType e) => switch (e) {
        EdgeType.flat => EdgeType.flat,
        EdgeType.convex => EdgeType.concave,
        EdgeType.concave => EdgeType.convex,
        EdgeType.jaggedOut => EdgeType.jaggedIn,
        EdgeType.jaggedIn => EdgeType.jaggedOut,
      };

  EdgeType _randomNonFlatEdge(DifficultyLevel level) {
    final pool = switch (level) {
      DifficultyLevel.veryEasy => [EdgeType.convex, EdgeType.concave],
      DifficultyLevel.easy => [EdgeType.convex, EdgeType.concave],
      DifficultyLevel.medium => [
          EdgeType.convex,
          EdgeType.concave,
          EdgeType.jaggedOut,
          EdgeType.jaggedIn,
        ],
      DifficultyLevel.hard => [
          EdgeType.convex,
          EdgeType.concave,
          EdgeType.jaggedOut,
          EdgeType.jaggedIn,
        ],
    };
    return pool[_rng.nextInt(pool.length)];
  }

  List<PuzzleShape> _shapesFor(DifficultyLevel level) {
    switch (level) {
      case DifficultyLevel.veryEasy:
        return [PuzzleShape.square, PuzzleShape.square, PuzzleShape.square];
      case DifficultyLevel.easy:
        final pool = [PuzzleShape.square, PuzzleShape.rectangleH];
        return List.generate(3, (_) => pool[_rng.nextInt(pool.length)]);
      case DifficultyLevel.medium:
        final pool = [
          PuzzleShape.square,
          PuzzleShape.rectangleH,
          PuzzleShape.triangle,
          PuzzleShape.trapezoid,
        ];
        return List.generate(3, (_) => pool[_rng.nextInt(pool.length)]);
      case DifficultyLevel.hard:
        final pool = [
          PuzzleShape.lShape,
          PuzzleShape.tShape,
          PuzzleShape.zShape,
          PuzzleShape.triangle,
          PuzzleShape.parallelogram,
          PuzzleShape.trapezoid,
        ];
        return List.generate(3, (_) => pool[_rng.nextInt(pool.length)]);
    }
  }

  // ============================================================
  // DISTRACTEURS
  // ============================================================

  List<PuzzlePiece> _buildDistractors(
    List<PuzzlePiece> correct,
    DifficultyLevel level,
    _DistractorType? avoidType,
  ) {
    final pool = _DistractorType.values.toList()..remove(avoidType);
    pool.shuffle(_rng);
    final chosen = pool.take(3).toList();

    return chosen
        .map((type) =>
            _applyDistractor(type, correct[_rng.nextInt(correct.length)], level))
        .toList();
  }

  PuzzlePiece _applyDistractor(
      _DistractorType type, PuzzlePiece base, DifficultyLevel level) {
    switch (type) {
      case _DistractorType.mirrorPiece:
        return base.copyWith(id: _uuid(), mirrored: !base.mirrored);
      case _DistractorType.rotateWrong:
        final rot = [90.0, 180.0, 270.0][_rng.nextInt(3)];
        return base.copyWith(id: _uuid(), rotationDeg: rot);
      case _DistractorType.scaleOff:
        final sc = _rng.nextBool() ? 0.8 : 1.2;
        return base.copyWith(id: _uuid(), scale: sc);
      case _DistractorType.wrongEdge:
        final edge = _rng.nextBool() ? 'right' : 'left';
        final newEdges = edge == 'right'
            ? EdgePattern(
                top: base.edges.top,
                right: _flipEdge(base.edges.right),
                bottom: base.edges.bottom,
                left: base.edges.left,
              )
            : EdgePattern(
                top: base.edges.top,
                right: base.edges.right,
                bottom: base.edges.bottom,
                left: _flipEdge(base.edges.left),
              );
        return base.copyWith(id: _uuid(), edges: newEdges);
      case _DistractorType.shapeSwap:
        final pool = PuzzleShape.values.where((s) => s != base.shape).toList();
        return base.copyWith(
            id: _uuid(), shape: pool[_rng.nextInt(pool.length)]);
      case _DistractorType.extraPiece:
        return PuzzlePiece(
          id: _uuid(),
          shape: PuzzleShape.values[_rng.nextInt(PuzzleShape.values.length)],
          rotationDeg: [0.0, 90.0, 180.0, 270.0][_rng.nextInt(4)],
          mirrored: _rng.nextBool(),
          scale: [0.9, 1.0, 1.1][_rng.nextInt(3)],
          edges: EdgePattern(
            top: _randomNonFlatEdge(level),
            right: _randomNonFlatEdge(level),
            bottom: _randomNonFlatEdge(level),
            left: _randomNonFlatEdge(level),
          ),
        );
    }
  }

  /// Bascule l'arête vers un type incompatible avec l'original
  EdgeType _flipEdge(EdgeType e) => switch (e) {
        EdgeType.flat => EdgeType.convex,
        EdgeType.convex => EdgeType.jaggedOut,
        EdgeType.concave => EdgeType.jaggedIn,
        EdgeType.jaggedOut => EdgeType.convex,
        EdgeType.jaggedIn => EdgeType.concave,
      };

  int _timeLimitFor(DifficultyLevel level) => switch (level) {
        DifficultyLevel.veryEasy => 20,
        DifficultyLevel.easy => 25,
        DifficultyLevel.medium => 28,
        DifficultyLevel.hard => 30,
      };
}

enum _DistractorType {
  mirrorPiece,
  rotateWrong,
  scaleOff,
  wrongEdge,
  shapeSwap,
  extraPiece,
}
