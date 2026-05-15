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
enum TargetLayout {
  rowH3,
  colV3,
  topWideBottomSplit,
  topSplitBottomWide,
  lLayout,
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
// GÉNÉRATEUR
// ============================================================

/// Pool de pièges ordonnés par **subtilité** :
///   - shapeSwap / extraPiece     : différences ÉNORMES (forme totalement autre)
///   - rotateWrong180             : rotation 180° (visible sur shapes asymétriques)
///   - mirrorPiece                : miroir (visible sur shapes asymétriques)
///   - rotateWrong90              : rotation 90° (moins évidente)
///   - scaleBig                   : taille 0.8 / 1.2 (visible)
///   - scaleSubtle                : taille 0.9 / 1.1 (subtil)
///   - wrongEdge                  : 1 seule arête différente (très subtil)
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

  // ============================================================
  // PIPELINE PAR ITEM
  // ============================================================

  PuzzleItem _generateItem(int index, DifficultyLevel level) {
    final layout = _pickLayout(level);
    final (targetPieces, cols, rows) = _buildTarget(layout, level);

    // Génère 3 distracteurs DISTINCTS visuellement des targets et entre eux.
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
  // LAYOUTS
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

  List<(int, int, int, int)> _slotsForLayout(TargetLayout l) => switch (l) {
        TargetLayout.rowH3 => [(0, 0, 1, 1), (1, 0, 1, 1), (2, 0, 1, 1)],
        TargetLayout.colV3 => [(0, 0, 1, 1), (0, 1, 1, 1), (0, 2, 1, 1)],
        TargetLayout.topWideBottomSplit => [(0, 0, 2, 1), (0, 1, 1, 1), (1, 1, 1, 1)],
        TargetLayout.topSplitBottomWide => [(0, 0, 1, 1), (1, 0, 1, 1), (0, 1, 2, 1)],
        TargetLayout.lLayout => [(0, 0, 1, 1), (0, 1, 1, 1), (1, 1, 1, 1)],
        TargetLayout.cornerL => [(0, 0, 1, 1), (0, 1, 1, 1), (1, 1, 1, 1)],
      };

  (int, int) _gridSizeForLayout(TargetLayout l) => switch (l) {
        TargetLayout.rowH3 => (3, 1),
        TargetLayout.colV3 => (1, 3),
        _ => (2, 2),
      };

  // ============================================================
  // CIBLE
  // ============================================================

  (List<PuzzlePiece>, int, int) _buildTarget(
      TargetLayout layout, DifficultyLevel level) {
    final (cols, rows) = _gridSizeForLayout(layout);
    final slots = _slotsForLayout(layout);
    final shapes = _pickShapes(slots, level);

    final edgesByPiece = <int, EdgePattern>{
      for (int i = 0; i < slots.length; i++) i: const EdgePattern(),
    };

    for (int i = 0; i < slots.length; i++) {
      for (int j = i + 1; j < slots.length; j++) {
        final adj = _findAdjacency(slots[i], slots[j]);
        if (adj == null) continue;
        final edgeType = _randomEdge(level);
        final compl = _complementOf(edgeType);
        edgesByPiece[i] = _setEdge(edgesByPiece[i]!, adj.sideOnA, edgeType);
        edgesByPiece[j] = _setEdge(edgesByPiece[j]!, adj.sideOnB, compl);
      }
    }

    final pieces = <PuzzlePiece>[];
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

    // STRICT (TOUS niveaux) : les 3 targets doivent avoir 3 shapes
    // DIFFÉRENTES. Combiné avec les 3 distractors qui prennent 3 autres
    // shapes uniques → les 6 options ont toutes une SHAPE différente.
    // L'utilisateur ne peut JAMAIS être confus par 2 pièces qui se
    // ressemblent visuellement.
    final picked = <PuzzleShape>[];
    for (int i = 0; i < slots.length; i++) {
      final filtered = basePool.toList()
        ..removeWhere((s) => picked.contains(s));
      final pool = filtered.isEmpty ? basePool : filtered;
      picked.add(pool[_rng.nextInt(pool.length)]);
    }
    return picked;
  }

  // ============================================================
  // ADJACENCE
  // ============================================================

  _Adjacency? _findAdjacency(
      (int, int, int, int) a, (int, int, int, int) b) {
    final (ax, ay, aw, ah) = a;
    final (bx, by, bw, bh) = b;
    if (ax + aw == bx && _vOverlap(ay, ah, by, bh)) {
      return _Adjacency(sideOnA: _Side.right, sideOnB: _Side.left);
    }
    if (bx + bw == ax && _vOverlap(ay, ah, by, bh)) {
      return _Adjacency(sideOnA: _Side.left, sideOnB: _Side.right);
    }
    if (ay + ah == by && _hOverlap(ax, aw, bx, bw)) {
      return _Adjacency(sideOnA: _Side.bottom, sideOnB: _Side.top);
    }
    if (by + bh == ay && _hOverlap(ax, aw, bx, bw)) {
      return _Adjacency(sideOnA: _Side.top, sideOnB: _Side.bottom);
    }
    return null;
  }

  bool _vOverlap(int ay, int ah, int by, int bh) =>
      ay < by + bh && by < ay + ah;
  bool _hOverlap(int ax, int aw, int bx, int bw) =>
      ax < bx + bw && bx < ax + aw;

  EdgePattern _setEdge(EdgePattern p, _Side side, EdgeType type) =>
      switch (side) {
        _Side.top => p.copyWith(top: type),
        _Side.right => p.copyWith(right: type),
        _Side.bottom => p.copyWith(bottom: type),
        _Side.left => p.copyWith(left: type),
      };

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

  EdgeType _flipEdge(EdgeType e) => switch (e) {
        EdgeType.flat => EdgeType.convex,
        EdgeType.convex => EdgeType.jaggedOut,
        EdgeType.concave => EdgeType.jaggedIn,
        EdgeType.jaggedOut => EdgeType.concave,
        EdgeType.jaggedIn => EdgeType.convex,
      };

  // ============================================================
  // DISTRACTEURS
  //   - Pool ordonné par subtilité selon le niveau
  //   - Vérification de distinctness : aucun distracteur ne doit être
  //     visuellement identique à un target ni à un autre distracteur
  // ============================================================

  List<_DistractorType> _distractorPoolFor(DifficultyLevel level) =>
      switch (level) {
        DifficultyLevel.veryEasy => [
            _DistractorType.shapeSwap,
            _DistractorType.shapeSwap,
            _DistractorType.extraPiece,
            _DistractorType.extraPiece,
            _DistractorType.rotateWrong180, // visible si asymétrique
          ],
        DifficultyLevel.easy => [
            _DistractorType.shapeSwap,
            _DistractorType.rotateWrong180,
            _DistractorType.mirrorPiece,
            _DistractorType.extraPiece,
            _DistractorType.scaleBig,
          ],
        DifficultyLevel.medium => [
            _DistractorType.rotateWrong90,
            _DistractorType.mirrorPiece,
            _DistractorType.scaleBig,
            _DistractorType.shapeSwap,
            _DistractorType.wrongEdge,
          ],
        DifficultyLevel.hard => [
            _DistractorType.wrongEdge,
            _DistractorType.wrongEdge,
            _DistractorType.scaleSubtle,
            _DistractorType.rotateWrong90,
            _DistractorType.mirrorPiece,
          ],
      };

  List<PuzzlePiece> _buildDistractors(
      List<PuzzlePiece> correct, DifficultyLevel level) {
    // RÈGLE STRICTE (TOUS niveaux) : tous les distracteurs ont une SHAPE
    // différente des targets ET entre eux → 6 shapes uniques.
    // L'utilisateur ne peut JAMAIS confondre 2 pièces visuellement.
    final targetShapes = correct.map((p) => p.shape).toSet();
    final usedShapes = Set<PuzzleShape>.from(targetShapes);
    final distractors = <PuzzlePiece>[];

    while (distractors.length < 3) {
      final remaining = PuzzleShape.values
          .where((s) => !usedShapes.contains(s))
          .toList();
      if (remaining.isEmpty) {
        // Sécurité : pool épuisé (rare, slots > 9 shapes). On utilise
        // PuzzleShape.values aléatoirement avec différentes rotations.
        break;
      }
      final newShape = remaining[_rng.nextInt(remaining.length)];
      usedShapes.add(newShape);
      final base = correct[_rng.nextInt(correct.length)];

      // Aux niveaux medium/hard, on rend les distracteurs légèrement plus
      // sophistiqués (rotation/scale variable) — mais TOUJOURS shape
      // différente des targets pour conserver la clarté visuelle.
      double rotation = 0;
      double scale = 1.0;
      bool mirrored = false;
      if (level == DifficultyLevel.medium || level == DifficultyLevel.hard) {
        if (_rng.nextBool()) rotation = [90.0, 180.0, 270.0][_rng.nextInt(3)];
        if (_rng.nextBool()) scale = _rng.nextBool() ? 0.85 : 1.15;
        if (_rng.nextBool()) mirrored = true;
      }

      distractors.add(PuzzlePiece(
        id: _uuid(),
        shape: newShape,
        rotationDeg: rotation,
        mirrored: mirrored,
        scale: scale,
        edges: EdgePattern(
          top: _randomEdge(level),
          right: _randomEdge(level),
          bottom: _randomEdge(level),
          left: _randomEdge(level),
        ),
        gridX: base.gridX,
        gridY: base.gridY,
        gridW: base.gridW,
        gridH: base.gridH,
      ));
    }

    // Fallback si on n'a pas pu créer 3 distracteurs uniques (pool épuisé)
    while (distractors.length < 3) {
      final candidate = _applyDistractor(
          _DistractorType.extraPiece, correct[0], level);
      distractors.add(candidate);
    }
    return distractors;
  }

  PuzzlePiece _applyDistractor(
      _DistractorType type, PuzzlePiece base, DifficultyLevel level) {
    switch (type) {
      case _DistractorType.shapeSwap:
        final pool = PuzzleShape.values.where((s) => s != base.shape).toList();
        return base.copyWith(
          id: _uuid(),
          shape: pool[_rng.nextInt(pool.length)],
        );
      case _DistractorType.rotateWrong180:
        return base.copyWith(id: _uuid(), rotationDeg: 180);
      case _DistractorType.rotateWrong90:
        return base.copyWith(
          id: _uuid(),
          rotationDeg: _rng.nextBool() ? 90.0 : 270.0,
        );
      case _DistractorType.mirrorPiece:
        return base.copyWith(id: _uuid(), mirrored: !base.mirrored);
      case _DistractorType.scaleBig:
        final sc = _rng.nextBool() ? 0.78 : 1.22;
        return base.copyWith(id: _uuid(), scale: sc);
      case _DistractorType.scaleSubtle:
        final sc = _rng.nextBool() ? 0.90 : 1.10;
        return base.copyWith(id: _uuid(), scale: sc);
      case _DistractorType.wrongEdge:
        // Choisir un côté qui n'est pas flat, le flip
        final sides = _Side.values
            .where((s) => _readEdge(base.edges, s) != EdgeType.flat)
            .toList();
        final side = sides.isEmpty
            ? _Side.values[_rng.nextInt(4)]
            : sides[_rng.nextInt(sides.length)];
        final current = _readEdge(base.edges, side);
        final flipped = _flipEdge(current);
        return base.copyWith(
            id: _uuid(), edges: _setEdge(base.edges, side, flipped));
      case _DistractorType.extraPiece:
        return PuzzlePiece(
          id: _uuid(),
          shape: PuzzleShape.values[_rng.nextInt(PuzzleShape.values.length)],
          rotationDeg: [0.0, 90.0, 180.0, 270.0][_rng.nextInt(4)],
          mirrored: _rng.nextBool(),
          scale: [0.85, 1.0, 1.15][_rng.nextInt(3)],
          edges: EdgePattern(
            top: _randomEdge(level),
            right: _randomEdge(level),
            bottom: _randomEdge(level),
            left: _randomEdge(level),
          ),
          gridW: base.gridW,
          gridH: base.gridH,
        );
    }
  }

  EdgeType _readEdge(EdgePattern p, _Side side) => switch (side) {
        _Side.top => p.top,
        _Side.right => p.right,
        _Side.bottom => p.bottom,
        _Side.left => p.left,
      };

  // ============================================================
  // DISTINCTNESS — signature visuelle d'une pièce
  //
  // On prend en compte la symétrie de la forme :
  //   - square : 4-fold (rot 0/90/180/270 identiques SI edges symétriques)
  //   - rectangleH/V/parallelogram/zShape : 2-fold (rot 0/180 = identique)
  //   - autres : pas de symétrie rotationnelle
  // On calcule donc une "rotation canonique" + on applique la rotation aux edges
  // pour comparer dans une orientation absolue.
  // ============================================================

  String _visualSig(PuzzlePiece p) {
    final rotSteps = ((p.rotationDeg.toInt() % 360) + 360) % 360 ~/ 90;
    final edgesAbsolute = _rotateEdgesNTimes(p.edges, rotSteps);
    final edgesAfterMirror =
        p.mirrored ? _mirrorEdges(edgesAbsolute) : edgesAbsolute;

    // Symétrie rotationnelle de la shape : on quotiente rotation par la symétrie
    final sym = _rotationalSymmetrySteps(p.shape);
    final canonicalRot = sym > 0 ? rotSteps % sym : rotSteps;

    return [
      p.shape.name,
      'm${p.mirrored}',
      's${p.scale.toStringAsFixed(2)}',
      'r$canonicalRot',
      '${edgesAfterMirror.top.name}_${edgesAfterMirror.right.name}_'
          '${edgesAfterMirror.bottom.name}_${edgesAfterMirror.left.name}',
    ].join('|');
  }

  /// Pour les shapes parfaitement symétriques sous rotation N : si
  /// les edges sont aussi symétriques, alors la pièce est strictement
  /// identique. Cette fonction détecte ces cas trop évidents.
  bool _isSymmetricallyIdentical(PuzzlePiece candidate, PuzzlePiece base) {
    // Cas : square + rotation X + edges all flat ou tous identiques → identique
    if (candidate.shape == PuzzleShape.square &&
        candidate.scale == base.scale &&
        candidate.mirrored == base.mirrored &&
        _allEdgesEqual(candidate.edges)) {
      return true;
    }
    return false;
  }

  bool _allEdgesEqual(EdgePattern e) =>
      e.top == e.right && e.right == e.bottom && e.bottom == e.left;

  /// Rotation horaire des edges de N×90°
  EdgePattern _rotateEdgesNTimes(EdgePattern e, int n) {
    n = ((n % 4) + 4) % 4;
    var current = e;
    for (int i = 0; i < n; i++) {
      // 90° horaire : top → right → bottom → left → top
      current = EdgePattern(
        top: current.left,
        right: current.top,
        bottom: current.right,
        left: current.bottom,
      );
    }
    return current;
  }

  EdgePattern _mirrorEdges(EdgePattern e) {
    // Miroir horizontal : left ↔ right
    return EdgePattern(
      top: e.top,
      right: e.left,
      bottom: e.bottom,
      left: e.right,
    );
  }

  /// Nombre de "steps" (90°) après lesquels la shape revient à elle-même.
  /// - square : 1 (revient à elle-même à chaque rotation 90°)
  /// - rectangleH/V/parallelogram/zShape : 2
  /// - autres : 4 (pas de symétrie)
  int _rotationalSymmetrySteps(PuzzleShape s) => switch (s) {
        PuzzleShape.square => 1,
        PuzzleShape.rectangleH => 2,
        PuzzleShape.rectangleV => 2,
        PuzzleShape.parallelogram => 2,
        PuzzleShape.zShape => 2,
        PuzzleShape.triangle => 4,
        PuzzleShape.trapezoid => 4,
        PuzzleShape.lShape => 4,
        PuzzleShape.tShape => 4,
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
  shapeSwap,        // forme totalement différente — TRÈS visible
  extraPiece,       // pièce totalement aléatoire — TRÈS visible
  rotateWrong180,   // rotation 180° — visible sur shape asymétrique
  mirrorPiece,      // miroir — visible sur shape asymétrique
  rotateWrong90,    // rotation 90° — visible
  scaleBig,         // scale 0.78 / 1.22 — visible
  scaleSubtle,      // scale 0.90 / 1.10 — subtil
  wrongEdge,        // 1 arête différente — très subtil
}

enum _Side { top, right, bottom, left }

class _Adjacency {
  const _Adjacency({required this.sideOnA, required this.sideOnB});
  final _Side sideOnA;
  final _Side sideOnB;
}
