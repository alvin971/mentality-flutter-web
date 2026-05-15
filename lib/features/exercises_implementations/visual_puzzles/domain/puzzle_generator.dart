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

/// Type d'arête (5 types ; complémentaires : flat↔flat, convex↔concave,
/// jaggedOut↔jaggedIn).
enum EdgeType { flat, convex, concave, jaggedOut, jaggedIn }

/// Topologie de la cible (comment les 3 pièces sont arrangées).
///
/// Chacune définit une grille `gridCols × gridRows` et des positions fixes
/// pour les 3 pièces. Les **arêtes adjacentes** entre pièces sont contraintes
/// par le générateur (complémentarité visible).
enum TargetLayout {
  /// 3 pièces en rangée 3×1 (horizontal classique).
  rowH3,

  /// 3 pièces en colonne 1×3 (vertical).
  colV3,

  /// 2×2 dont 1 grande pièce 2×1 en haut + 2 pièces 1×1 en bas.
  /// Pos: (0,0,2×1) + (0,1,1×1) + (1,1,1×1)
  topWideBottomSplit,

  /// 2×2 dont 2 pièces 1×1 en haut + 1 grande 2×1 en bas.
  topSplitBottomWide,

  /// Forme L : 2 pièces verticales 1×1 à gauche + 1 horizontale 2×1 en bas.
  /// Pos: (0,0,1×1) + (0,1,1×1) + (1,1,1×1)→shifted. On utilisera 2x2 grid.
  lLayout,

  /// 2×2 avec une cellule vide en haut-droite : pos (0,0,1×1) + (0,1,1×1) + (1,1,1×1).
  cornerL,
}

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

  EdgePattern copyWith({
    EdgeType? top,
    EdgeType? right,
    EdgeType? bottom,
    EdgeType? left,
  }) =>
      EdgePattern(
        top: top ?? this.top,
        right: right ?? this.right,
        bottom: bottom ?? this.bottom,
        left: left ?? this.left,
      );
}

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
  final double rotationDeg;
  final bool mirrored;
  final double scale;
  final EdgePattern edges;
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

@immutable
class PuzzleItem {
  const PuzzleItem({
    required this.index,
    required this.level,
    required this.layout,
    required this.targetPieces,
    required this.options,
    required this.correctIds,
    required this.timeLimitSeconds,
    required this.gridCols,
    required this.gridRows,
  });

  final int index;
  final DifficultyLevel level;
  final TargetLayout layout;
  final List<PuzzlePiece> targetPieces;
  final List<PuzzlePiece> options;
  final Set<String> correctIds;
  final int timeLimitSeconds;
  final int gridCols;
  final int gridRows;
}

// ============================================================
// GÉNÉRATEUR — diversité combinatoire massive
// ============================================================

/// Espace de combinaisons par item (estimation min) :
///   layout (3-6) × shapes (9^3 = 729 / pool effective) ×
///   edges (5^4 contrainte par complémentarité ≈ 50) × rotation cible (4) ×
///   distracteur types (C(6,3)=20) × choix pièce-cible (3^3=27)
///   ≈ 3 × 50 × 50 × 4 × 20 × 27 ≈ 16M combinaisons par item
/// → impossible que 2 utilisateurs aient le même test.
class PuzzleGenerator {
  PuzzleGenerator({int? seed})
      : _rng = math.Random(seed ?? DateTime.now().microsecondsSinceEpoch);

  final math.Random _rng;
  int _idCounter = 0;

  String _uuid() {
    _idCounter++;
    return 'p$_idCounter-${_rng.nextInt(1 << 30).toRadixString(36)}-${_rng.nextInt(1 << 30).toRadixString(36)}';
  }

  List<PuzzleItem> generateComplete26Items() {
    final items = <PuzzleItem>[];

    void addItems(int count, DifficultyLevel level) {
      for (int i = 0; i < count; i++) {
        items.add(_generateItem(items.length + 1, level));
      }
    }

    addItems(6, DifficultyLevel.veryEasy);
    addItems(8, DifficultyLevel.easy);
    addItems(6, DifficultyLevel.medium);
    addItems(6, DifficultyLevel.hard);

    assert(items.length == 26);
    return items;
  }

  // ============================================================
  // PIPELINE PAR ITEM
  // ============================================================

  PuzzleItem _generateItem(int index, DifficultyLevel level) {
    final layout = _pickLayout(level);
    final (targetPieces, cols, rows) = _buildTarget(layout, level);

    // Distracteurs : 3 transformations différentes piochées dans le pool 6
    final distractors = _buildDistractors(targetPieces, level);

    final options = [...targetPieces, ...distractors]..shuffle(_rng);

    return PuzzleItem(
      index: index,
      level: level,
      layout: layout,
      targetPieces: targetPieces,
      options: options,
      correctIds: targetPieces.map((p) => p.id).toSet(),
      timeLimitSeconds: _timeLimitFor(level),
      gridCols: cols,
      gridRows: rows,
    );
  }

  // ============================================================
  // LAYOUTS — varier la topologie de la cible
  // ============================================================

  TargetLayout _pickLayout(DifficultyLevel level) {
    final pool = switch (level) {
      DifficultyLevel.veryEasy => [TargetLayout.rowH3, TargetLayout.colV3],
      DifficultyLevel.easy => [
          TargetLayout.rowH3,
          TargetLayout.colV3,
          TargetLayout.topWideBottomSplit,
          TargetLayout.topSplitBottomWide,
        ],
      DifficultyLevel.medium => TargetLayout.values,
      DifficultyLevel.hard => TargetLayout.values,
    };
    return pool[_rng.nextInt(pool.length)];
  }

  /// Définit la grille (cols × rows) et les cellules (gridX, gridY, gridW, gridH)
  /// pour chaque pièce selon le layout.
  List<(int gx, int gy, int gw, int gh)> _slotsForLayout(TargetLayout layout) {
    switch (layout) {
      case TargetLayout.rowH3:
        return [(0, 0, 1, 1), (1, 0, 1, 1), (2, 0, 1, 1)];
      case TargetLayout.colV3:
        return [(0, 0, 1, 1), (0, 1, 1, 1), (0, 2, 1, 1)];
      case TargetLayout.topWideBottomSplit:
        return [(0, 0, 2, 1), (0, 1, 1, 1), (1, 1, 1, 1)];
      case TargetLayout.topSplitBottomWide:
        return [(0, 0, 1, 1), (1, 0, 1, 1), (0, 1, 2, 1)];
      case TargetLayout.lLayout:
        return [(0, 0, 1, 1), (0, 1, 1, 1), (1, 1, 1, 1)];
      case TargetLayout.cornerL:
        return [(0, 0, 1, 1), (0, 1, 1, 1), (1, 1, 1, 1)];
    }
  }

  /// Renvoie (cols, rows) de la grille pour un layout.
  (int, int) _gridSizeForLayout(TargetLayout layout) {
    switch (layout) {
      case TargetLayout.rowH3:
        return (3, 1);
      case TargetLayout.colV3:
        return (1, 3);
      case TargetLayout.topWideBottomSplit:
      case TargetLayout.topSplitBottomWide:
      case TargetLayout.lLayout:
      case TargetLayout.cornerL:
        return (2, 2);
    }
  }

  // ============================================================
  // BUILD TARGET — 3 pièces qui s'emboîtent
  // ============================================================

  (List<PuzzlePiece>, int, int) _buildTarget(
      TargetLayout layout, DifficultyLevel level) {
    final (cols, rows) = _gridSizeForLayout(layout);
    final slots = _slotsForLayout(layout);
    final shapes = _pickShapes(slots, level);

    final pieces = <PuzzlePiece>[];
    // Map d'arêtes assignées par cellule pour gérer la complémentarité
    // adjacent. Clé : (gx,gy) ; valeur : EdgePattern partiel.
    final edgesByPiece = <int, EdgePattern>{
      for (int i = 0; i < slots.length; i++) i: const EdgePattern(),
    };

    // Pour chaque paire de pièces adjacentes, choisir un type d'arête et
    // attribuer le complément à la pièce voisine.
    // Adjacence détectée si une cellule de A et une cellule de B partagent
    // un bord (cellules consécutives en x ou y).
    for (int i = 0; i < slots.length; i++) {
      for (int j = i + 1; j < slots.length; j++) {
        final adj = _findAdjacency(slots[i], slots[j]);
        if (adj == null) continue;
        final edgeType = _randomEdge(level);
        final compl = _complementOf(edgeType);
        // Side pour i ; opposite pour j
        edgesByPiece[i] = _setEdge(edgesByPiece[i]!, adj.sideOnA, edgeType);
        edgesByPiece[j] = _setEdge(edgesByPiece[j]!, adj.sideOnB, compl);
      }
    }

    // Génère les pièces effectives
    for (int i = 0; i < slots.length; i++) {
      final (gx, gy, gw, gh) = slots[i];
      pieces.add(PuzzlePiece(
        id: _uuid(),
        shape: shapes[i],
        rotationDeg: 0,
        mirrored: false,
        scale: 1.0,
        edges: edgesByPiece[i]!,
        gridX: gx,
        gridY: gy,
        gridW: gw,
        gridH: gh,
      ));
    }

    return (pieces, cols, rows);
  }

  /// Pool de shapes pour chaque pièce selon le niveau, en respectant la taille
  /// (gw, gh) du slot : un slot 2×1 ne peut pas être un triangle équilatéral
  /// par exemple — on filtre.
  List<PuzzleShape> _pickShapes(
      List<(int, int, int, int)> slots, DifficultyLevel level) {
    final basePool = switch (level) {
      DifficultyLevel.veryEasy => [
          PuzzleShape.square,
          PuzzleShape.rectangleH,
          PuzzleShape.rectangleV,
        ],
      DifficultyLevel.easy => [
          PuzzleShape.square,
          PuzzleShape.rectangleH,
          PuzzleShape.rectangleV,
          PuzzleShape.triangle,
          PuzzleShape.trapezoid,
        ],
      DifficultyLevel.medium => [
          PuzzleShape.square,
          PuzzleShape.rectangleH,
          PuzzleShape.rectangleV,
          PuzzleShape.triangle,
          PuzzleShape.trapezoid,
          PuzzleShape.parallelogram,
          PuzzleShape.lShape,
        ],
      DifficultyLevel.hard => PuzzleShape.values,
    };

    return List.generate(slots.length, (i) {
      final (_, _, gw, gh) = slots[i];
      // Filtre selon dimensions du slot
      final filtered = basePool.where((s) => _shapeFitsSlot(s, gw, gh)).toList();
      final pool = filtered.isEmpty ? [PuzzleShape.square] : filtered;
      return pool[_rng.nextInt(pool.length)];
    });
  }

  bool _shapeFitsSlot(PuzzleShape shape, int gw, int gh) {
    // Les formes "rectangleH" préfèrent gw>=gh, etc. Mais on accepte tout
    // pour ne pas trop restreindre la diversité.
    if (shape == PuzzleShape.rectangleV && gw > gh && gw == gh + 1) return false;
    if (shape == PuzzleShape.rectangleH && gh > gw && gh == gw + 1) return false;
    return true;
  }

  // ============================================================
  // ADJACENCE — détection de bords partagés entre 2 slots
  // ============================================================

  /// Détecte si 2 slots partagent un bord et renvoie quel côté.
  _Adjacency? _findAdjacency(
      (int, int, int, int) a, (int, int, int, int) b) {
    final (ax, ay, aw, ah) = a;
    final (bx, by, bw, bh) = b;
    // A right ↔ B left
    if (ax + aw == bx && _verticalOverlap(ay, ah, by, bh)) {
      return _Adjacency(sideOnA: _Side.right, sideOnB: _Side.left);
    }
    // A left ↔ B right
    if (bx + bw == ax && _verticalOverlap(ay, ah, by, bh)) {
      return _Adjacency(sideOnA: _Side.left, sideOnB: _Side.right);
    }
    // A bottom ↔ B top
    if (ay + ah == by && _horizontalOverlap(ax, aw, bx, bw)) {
      return _Adjacency(sideOnA: _Side.bottom, sideOnB: _Side.top);
    }
    // A top ↔ B bottom
    if (by + bh == ay && _horizontalOverlap(ax, aw, bx, bw)) {
      return _Adjacency(sideOnA: _Side.top, sideOnB: _Side.bottom);
    }
    return null;
  }

  bool _verticalOverlap(int ay, int ah, int by, int bh) =>
      ay < by + bh && by < ay + ah;
  bool _horizontalOverlap(int ax, int aw, int bx, int bw) =>
      ax < bx + bw && bx < ax + aw;

  EdgePattern _setEdge(EdgePattern p, _Side side, EdgeType type) {
    switch (side) {
      case _Side.top:
        return p.copyWith(top: type);
      case _Side.right:
        return p.copyWith(right: type);
      case _Side.bottom:
        return p.copyWith(bottom: type);
      case _Side.left:
        return p.copyWith(left: type);
    }
  }

  // ============================================================
  // EDGES
  // ============================================================

  EdgeType _complementOf(EdgeType e) => switch (e) {
        EdgeType.flat => EdgeType.flat,
        EdgeType.convex => EdgeType.concave,
        EdgeType.concave => EdgeType.convex,
        EdgeType.jaggedOut => EdgeType.jaggedIn,
        EdgeType.jaggedIn => EdgeType.jaggedOut,
      };

  EdgeType _randomEdge(DifficultyLevel level) {
    final pool = switch (level) {
      DifficultyLevel.veryEasy => [EdgeType.convex, EdgeType.concave],
      DifficultyLevel.easy => [
          EdgeType.convex,
          EdgeType.concave,
          EdgeType.jaggedOut,
          EdgeType.jaggedIn,
        ],
      DifficultyLevel.medium => EdgeType.values.where((e) => e != EdgeType.flat).toList(),
      DifficultyLevel.hard => EdgeType.values.where((e) => e != EdgeType.flat).toList(),
    };
    return pool[_rng.nextInt(pool.length)];
  }

  // ============================================================
  // DISTRACTEURS — randomisés massivement
  // ============================================================

  List<PuzzlePiece> _buildDistractors(
      List<PuzzlePiece> correct, DifficultyLevel level) {
    final pool = _DistractorType.values.toList()..shuffle(_rng);
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
        final sc = [0.75, 0.85, 1.15, 1.25][_rng.nextInt(4)];
        return base.copyWith(id: _uuid(), scale: sc);
      case _DistractorType.wrongEdge:
        // Flip une arête au hasard (top/right/bottom/left)
        final side = _Side.values[_rng.nextInt(_Side.values.length)];
        final current = _readEdge(base.edges, side);
        final flipped = _flipEdge(current);
        return base.copyWith(
            id: _uuid(), edges: _setEdge(base.edges, side, flipped));
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
            top: _randomEdge(level),
            right: _randomEdge(level),
            bottom: _randomEdge(level),
            left: _randomEdge(level),
          ),
        );
    }
  }

  EdgeType _readEdge(EdgePattern p, _Side side) => switch (side) {
        _Side.top => p.top,
        _Side.right => p.right,
        _Side.bottom => p.bottom,
        _Side.left => p.left,
      };

  EdgeType _flipEdge(EdgeType e) => switch (e) {
        EdgeType.flat => EdgeType.convex,
        EdgeType.convex => EdgeType.jaggedOut,
        EdgeType.concave => EdgeType.jaggedIn,
        EdgeType.jaggedOut => EdgeType.concave,
        EdgeType.jaggedIn => EdgeType.convex,
      };

  int _timeLimitFor(DifficultyLevel level) => switch (level) {
        DifficultyLevel.veryEasy => 20,
        DifficultyLevel.easy => 25,
        DifficultyLevel.medium => 28,
        DifficultyLevel.hard => 30,
      };
}

// ============================================================
// HELPERS PRIVÉS
// ============================================================

enum _DistractorType {
  mirrorPiece,
  rotateWrong,
  scaleOff,
  wrongEdge,
  shapeSwap,
  extraPiece,
}

enum _Side { top, right, bottom, left }

class _Adjacency {
  const _Adjacency({required this.sideOnA, required this.sideOnB});
  final _Side sideOnA;
  final _Side sideOnB;
}
