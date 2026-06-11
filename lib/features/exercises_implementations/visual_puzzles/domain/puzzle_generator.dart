import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'base_shapes.dart';
import 'cut_engine.dart';
import 'geometry.dart';
import 'trap_engine.dart';

export 'base_shapes.dart' show BaseShape, BaseShapeX;
export 'cut_engine.dart' show CutStrategy;
export 'geometry.dart' show Polygon, congruent, isReconstruction;
export 'trap_engine.dart' show TrapKind;

/// Niveau de difficulté d'un item (progression type WAIS-IV).
enum DifficultyLevel { veryEasy, easy, medium, hard }

extension DifficultyLevelX on DifficultyLevel {
  String get label => switch (this) {
        DifficultyLevel.veryEasy => 'Très facile',
        DifficultyLevel.easy => 'Facile',
        DifficultyLevel.medium => 'Moyen',
        DifficultyLevel.hard => 'Difficile',
      };
}

/// Pièce proposée (vraie pièce ou distracteur).
@immutable
class PuzzlePiece {
  const PuzzlePiece({
    required this.id,
    required this.polygon,
    this.displayRotationDeg = 0,
    this.isCorrect = false,
    this.trapKind,
  });

  final String id;

  /// Silhouette en coordonnées de la cible (la translation n'a pas de sens
  /// pour l'affichage : chaque pièce est centrée dans sa case).
  final Polygon polygon;

  /// Rotation appliquée à l'AFFICHAGE uniquement (rotation mentale à
  /// effectuer par le sujet). Les pièces peuvent être tournées, pas
  /// retournées.
  final double displayRotationDeg;

  final bool isCorrect;

  /// Pour les distracteurs : type de piège (debug/analytique).
  final TrapKind? trapKind;

  /// Polygone tel qu'affiché (rotation incluse).
  Polygon get displayPolygon => displayRotationDeg == 0
      ? polygon
      : polygon.transform(rotationDeg: displayRotationDeg);
}

@immutable
class PuzzleItem {
  const PuzzleItem({
    required this.index,
    required this.level,
    required this.baseShape,
    required this.targetPolygon,
    required this.options,
    required this.correctIds,
    required this.timeLimitSeconds,
    required this.cutStrategy,
    required this.maxPieceExtent,
  });

  final int index;
  final DifficultyLevel level;
  final BaseShape baseShape;

  /// Silhouette complète (affichée SANS lignes internes, comme dans le vrai
  /// subtest : c'est au sujet de trouver mentalement la décomposition).
  final Polygon targetPolygon;

  /// 6 options mélangées (3 vraies + 3 pièges).
  final List<PuzzlePiece> options;
  final Set<String> correctIds;
  final int timeLimitSeconds;
  final CutStrategy cutStrategy;

  /// Plus grande dimension (bbox) parmi les 6 options AFFICHÉES.
  /// Les widgets s'en servent pour dessiner toutes les options à la MÊME
  /// échelle — c'est ce qui rend les pièges de taille détectables.
  final double maxPieceExtent;

  List<PuzzlePiece> get correctPieces =>
      options.where((p) => p.isCorrect).toList();
}

/// Générateur d'items "Puzzles visuels".
///
/// Principe fidèle au subtest VP du WAIS-IV (contenu 100 % original) :
/// une silhouette cible pleine, 6 pièces numérotées, choisir les 3 qui la
/// reconstituent. Les pièces peuvent être tournées mentalement, jamais
/// retournées.
///
/// Difficulté progressive sur 26 items :
/// - formes de base de plus en plus complexes ;
/// - découpes de plus en plus obliques ;
/// - rotations d'affichage de plus en plus libres ;
/// - distracteurs de plus en plus subtils (subtlety 0 → 1) ;
/// - temps : 20 s (items 1-7) puis 30 s (items 8-26), comme le vrai test.
///
/// La génération est entièrement paramétrique et aléatoire (seed optionnel)
/// → banque d'items virtuellement illimitée.
class PuzzleGenerator {
  PuzzleGenerator({int? seed})
      : _seed = seed ?? DateTime.now().microsecondsSinceEpoch {
    _rng = math.Random(_seed);
    _cutEngine = CutEngine(rng: math.Random(_seed + 1));
    _trapEngine = TrapEngine(
      rng: math.Random(_seed + 2),
      cutEngine: CutEngine(rng: math.Random(_seed + 3)),
    );
  }

  final int _seed;
  late final math.Random _rng;
  late final CutEngine _cutEngine;
  late final TrapEngine _trapEngine;
  int _idCounter = 0;

  static const int totalItems = 26;

  String _uuid() {
    _idCounter++;
    return 'p$_idCounter-${_rng.nextInt(1 << 30).toRadixString(36)}';
  }

  List<PuzzleItem> generateComplete26Items() {
    final items = <PuzzleItem>[];
    void add(int count, DifficultyLevel level) {
      for (int i = 0; i < count; i++) {
        items.add(generateItem(items.length + 1, level));
      }
    }

    add(6, DifficultyLevel.veryEasy);
    add(8, DifficultyLevel.easy);
    add(6, DifficultyLevel.medium);
    add(6, DifficultyLevel.hard);
    assert(items.length == totalItems);
    return items;
  }

  /// Subtilité des pièges pour l'item `index` (1-based) :
  /// 0.05 (item 1, pièges énormes) → 0.95 (item 26, pièges quasi invisibles).
  static double subtletyForItem(int index) {
    final t = ((index - 1) / (totalItems - 1)).clamp(0.0, 1.0);
    return 0.05 + 0.90 * t;
  }

  /// Temps limite WAIS-IV : 20 s pour les items 1-7, 30 s ensuite.
  static int timeLimitForIndex(int index) => index <= 7 ? 20 : 30;

  PuzzleItem generateItem(int index, DifficultyLevel level) {
    final subtlety = subtletyForItem(index);

    for (int attempt = 0; attempt < 12; attempt++) {
      final item = _tryGenerateItem(index, level, subtlety);
      if (item != null) return item;
    }
    // Dernier recours : item le plus simple possible (toujours valide).
    return _tryGenerateItem(index, DifficultyLevel.veryEasy, 0.1)!;
  }

  PuzzleItem? _tryGenerateItem(
      int index, DifficultyLevel level, double subtlety) {
    // 1. Forme de base
    final baseShape = _pickShape(level);
    final targetPolygon = buildBaseShape(baseShape);

    // 2. Découpe en 3 pièces équilibrées
    final strategy = _pickStrategy(level);
    final cuts = _cutEngine.cut(targetPolygon, strategy);
    if (!isReconstruction(cuts, targetPolygon,
        areaTolerance: 0.03, minAreaShare: CutEngine.minShare)) {
      return null;
    }

    // 3. Vraies pièces avec rotation d'affichage selon le niveau
    final rotationPool = _rotationPool(level);
    final truePieces = cuts
        .map((poly) => PuzzlePiece(
              id: _uuid(),
              polygon: poly,
              displayRotationDeg:
                  rotationPool[_rng.nextInt(rotationPool.length)],
              isCorrect: true,
            ))
        .toList();

    // 4. Distracteurs
    final distractors =
        _buildDistractors(cuts, targetPolygon, level, subtlety, rotationPool);
    if (distractors == null) return null;

    // 5. Mélange + échelle commune
    final options = [...truePieces, ...distractors]..shuffle(_rng);
    double maxExtent = 0;
    for (final o in options) {
      final bb = o.displayPolygon.bbox();
      maxExtent = math.max(maxExtent, math.max(bb.width, bb.height));
    }
    if (maxExtent < kGeomEps) return null;

    return PuzzleItem(
      index: index,
      level: level,
      baseShape: baseShape,
      targetPolygon: targetPolygon,
      options: options,
      correctIds: truePieces.map((p) => p.id).toSet(),
      timeLimitSeconds: timeLimitForIndex(index),
      cutStrategy: strategy,
      maxPieceExtent: maxExtent,
    );
  }

  List<PuzzlePiece>? _buildDistractors(
    List<Polygon> truePieces,
    Polygon target,
    DifficultyLevel level,
    double subtlety,
    List<double> rotationPool,
  ) {
    final kindQueue = _trapKindsFor(level)..shuffle(_rng);
    final result = <PuzzlePiece>[];
    final produced = <Polygon>[];

    int kindCursor = 0;
    int guard = 0;
    while (result.length < 3 && guard < 40) {
      guard++;
      final kind = kindQueue[kindCursor % kindQueue.length];
      kindCursor++;
      final source = truePieces[_rng.nextInt(truePieces.length)];
      final trap = _trapEngine.tryTrap(
        kind: kind,
        source: source,
        target: target,
        truePieces: truePieces,
        subtlety: subtlety,
      );
      if (trap == null) continue;

      // Validation finale : jamais congruent à une vraie pièce (miroir
      // compris) ni à un piège déjà retenu.
      bool clash = false;
      for (final tp in truePieces) {
        if (congruent(trap, tp, allowMirror: true)) {
          // Exception : le piège "miroir" est PAR DESIGN le miroir d'une
          // vraie pièce — il est valide précisément parce que les pièces ne
          // peuvent pas être retournées. On ne rejette que s'il est
          // congruent par simple ROTATION.
          if (kind == TrapKind.mirrored && !congruent(trap, tp)) continue;
          clash = true;
          break;
        }
      }
      if (clash) continue;
      for (final d in produced) {
        if (congruent(trap, d, allowMirror: true)) {
          clash = true;
          break;
        }
      }
      if (clash) continue;

      produced.add(trap);
      result.add(PuzzlePiece(
        id: _uuid(),
        polygon: trap,
        displayRotationDeg: rotationPool[_rng.nextInt(rotationPool.length)],
        isCorrect: false,
        trapKind: kind,
      ));
    }
    return result.length == 3 ? result : null;
  }

  // ---------- Pools par niveau ----------

  BaseShape _pickShape(DifficultyLevel level) {
    final pool = switch (level) {
      DifficultyLevel.veryEasy => [
          BaseShape.square,
          BaseShape.rectangleWide,
          BaseShape.rectangleTall,
          BaseShape.diamond,
        ],
      DifficultyLevel.easy => [
          BaseShape.square,
          BaseShape.rectangleWide,
          BaseShape.rectangleTall,
          BaseShape.diamond,
          BaseShape.triangleEq,
          BaseShape.triangleRight,
          BaseShape.trapezoid,
          BaseShape.house,
        ],
      DifficultyLevel.medium => [
          BaseShape.triangleEq,
          BaseShape.triangleRight,
          BaseShape.trapezoid,
          BaseShape.parallelogram,
          BaseShape.house,
          BaseShape.pentagon,
          BaseShape.hexagon,
          BaseShape.semicircle,
        ],
      DifficultyLevel.hard => [
          BaseShape.parallelogram,
          BaseShape.pentagon,
          BaseShape.hexagon,
          BaseShape.octagon,
          BaseShape.semicircle,
          BaseShape.circle,
        ],
    };
    return pool[_rng.nextInt(pool.length)];
  }

  CutStrategy _pickStrategy(DifficultyLevel level) {
    final pool = switch (level) {
      DifficultyLevel.veryEasy => [
          CutStrategy.twoParallel,
          CutStrategy.perpendicularL,
        ],
      DifficultyLevel.easy => [
          CutStrategy.twoParallel,
          CutStrategy.perpendicularL,
          CutStrategy.oneStraightOneOblique,
        ],
      DifficultyLevel.medium => [
          CutStrategy.perpendicularL,
          CutStrategy.oneStraightOneOblique,
          CutStrategy.twoOblique,
          CutStrategy.fan,
        ],
      DifficultyLevel.hard => [
          CutStrategy.oneStraightOneOblique,
          CutStrategy.twoOblique,
          CutStrategy.fan,
        ],
    };
    return pool[_rng.nextInt(pool.length)];
  }

  /// Rotations d'affichage possibles : aucune au début (correspondance
  /// directe avec la cible), puis de plus en plus libres (rotation mentale).
  List<double> _rotationPool(DifficultyLevel level) => switch (level) {
        DifficultyLevel.veryEasy => const [0.0],
        DifficultyLevel.easy => const [0.0, 90.0, 270.0],
        DifficultyLevel.medium => const [0.0, 90.0, 180.0, 270.0],
        DifficultyLevel.hard => const [
            0.0,
            45.0,
            90.0,
            135.0,
            180.0,
            225.0,
            270.0,
            315.0,
          ],
      };

  List<TrapKind> _trapKindsFor(DifficultyLevel level) => switch (level) {
        DifficultyLevel.veryEasy => [
            TrapKind.foreignShape,
            TrapKind.scaled,
            TrapKind.alternativeCut,
          ],
        DifficultyLevel.easy => [
            TrapKind.scaled,
            TrapKind.alternativeCut,
            TrapKind.stretched,
            TrapKind.mirrored,
          ],
        DifficultyLevel.medium => [
            TrapKind.alternativeCut,
            TrapKind.mirrored,
            TrapKind.scaled,
            TrapKind.stretched,
          ],
        DifficultyLevel.hard => [
            TrapKind.mirrored,
            TrapKind.alternativeCut,
            TrapKind.stretched,
            TrapKind.scaled,
          ],
      };
}
