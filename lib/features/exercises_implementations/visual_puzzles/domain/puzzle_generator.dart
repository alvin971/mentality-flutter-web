import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'base_shapes.dart';
import 'cut_engine.dart';
import 'geometry.dart';
import 'trap_engine.dart';

export 'base_shapes.dart' show BaseShape, BaseShapeX;
export 'cut_engine.dart' show CutStrategy;
export 'geometry.dart'
    show Polygon, ColoredRegion, congruent, isReconstruction, intersectConvex;
export 'trap_engine.dart' show TrapKind, TrapResult;

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
    required this.regions,
    this.displayRotationDeg = 0,
    this.isCorrect = false,
    this.trapKind,
  });

  final String id;

  /// Silhouette en coordonnées de la cible (la translation n'a pas de sens
  /// pour l'affichage : chaque pièce est centrée dans sa case).
  final Polygon polygon;

  /// Régions colorées de la pièce (même espace que [polygon]). Une pièce
  /// peut être bicolore : la frontière de couleur du motif de la cible est
  /// INDÉPENDANTE des lignes de découpe — c'est ce qui empêche de résoudre
  /// l'item par simple correspondance de couleurs.
  final List<ColoredRegion> regions;

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

  /// Régions telles qu'affichées : même pivot de rotation que la pièce
  /// entière (centroïde de [polygon]) pour rester solidaires.
  List<ColoredRegion> get displayRegions {
    if (displayRotationDeg == 0) return regions;
    final pivot = polygon.centroid();
    return regions
        .map((r) => ColoredRegion(
              r.polygon
                  .transform(rotationDeg: displayRotationDeg, center: pivot),
              r.colorIndex,
            ))
        .toList();
  }
}

@immutable
class PuzzleItem {
  const PuzzleItem({
    required this.index,
    required this.level,
    required this.baseShape,
    required this.targetPolygon,
    required this.colorZones,
    required this.palette,
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

  /// Zones de couleur du MOTIF de la cible. Leurs frontières sont
  /// indépendantes des lignes de découpe : une pièce peut chevaucher
  /// plusieurs zones (pièce bicolore). 1 seule zone = item monochrome.
  final List<ColoredRegion> colorZones;

  /// Palette de l'item : `colorIndex` des régions → couleur réelle.
  final List<Color> palette;

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

    // 2b. Zones de couleur du motif — INDÉPENDANTES des lignes de découpe.
    // Exigence (items multicolores) : au moins une vraie pièce bicolore,
    // sinon les couleurs trahiraient la correspondance pièce ↔ zone.
    final zoneInfo = _buildColorZones(targetPolygon, level, cuts);
    if (zoneInfo == null) return null;
    final (zones, paletteSize) = zoneInfo;
    final palette = _pickPalette(paletteSize);

    // 2c. Coloration des vraies pièces (fragments du motif).
    final trueRegions =
        cuts.map((poly) => clipToZones(poly, zones)).toList();

    // 3. Vraies pièces avec rotation d'affichage selon le niveau
    final rotationPool = _rotationPool(level);
    final truePieces = <PuzzlePiece>[];
    for (int i = 0; i < cuts.length; i++) {
      truePieces.add(PuzzlePiece(
        id: _uuid(),
        polygon: cuts[i],
        regions: trueRegions[i],
        displayRotationDeg: rotationPool[_rng.nextInt(rotationPool.length)],
        isCorrect: true,
      ));
    }

    // 4. Distracteurs
    final distractors = _buildDistractors(cuts, trueRegions, targetPolygon,
        zones, paletteSize, level, subtlety, rotationPool, baseShape);
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
      colorZones: zones,
      palette: palette,
      options: options,
      correctIds: truePieces.map((p) => p.id).toSet(),
      timeLimitSeconds: timeLimitForIndex(index),
      cutStrategy: strategy,
      maxPieceExtent: maxExtent,
    );
  }

  // ---------- Zones de couleur ----------

  /// Couleurs franches type "papier découpé" (palette originale).
  static const List<Color> colorPool = [
    Color(0xFFC93A32), // rouge brique
    Color(0xFF2D6BC9), // bleu
    Color(0xFF3E9E4E), // vert
    Color(0xFFEC9C2E), // orange
    Color(0xFFD8447C), // magenta
    Color(0xFF45BFD3), // cyan
    Color(0xFF8A5BD6), // violet
    Color(0xFFE4D94F), // jaune
  ];

  /// Paires de [colorPool] interdites dans une même palette.
  ///
  /// 5 paires violent la règle quantitative « distance RGB ≥ 100 ET
  /// (écart de luminance ≥ 40 OU écart de canal bleu ≥ 40, approximation
  /// deutéranopie) » ; magenta/violet la satisfait de justesse mais s'est
  /// révélée confusable en conditions réelles (audit visuel 2026-07-02).
  /// La mécanique wrongColors repose sur une discrimination de couleur
  /// instantanée : aucune paire ambiguë n'est tolérable.
  static const List<(Color, Color)> bannedColorPairs = [
    (Color(0xFFC93A32), Color(0xFF3E9E4E)), // rouge / vert (daltonisme)
    (Color(0xFFC93A32), Color(0xFFD8447C)), // rouge / magenta
    (Color(0xFF2D6BC9), Color(0xFF45BFD3)), // bleu / cyan
    (Color(0xFF2D6BC9), Color(0xFF8A5BD6)), // bleu / violet
    (Color(0xFFEC9C2E), Color(0xFFE4D94F)), // orange / jaune
    (Color(0xFFD8447C), Color(0xFF8A5BD6)), // magenta / violet
    (Color(0xFF45BFD3), Color(0xFF8A5BD6)), // cyan / violet (daltonisme)
  ];

  /// Vrai si deux couleurs peuvent cohabiter dans la palette d'un item.
  static bool paletteCompatible(Color a, Color b) {
    for (final (p, q) in bannedColorPairs) {
      if ((a == p && b == q) || (a == q && b == p)) return false;
    }
    return true;
  }

  List<Color> _pickPalette(int size) {
    final pool = [...colorPool];
    for (int attempt = 0; attempt < 40; attempt++) {
      pool.shuffle(_rng);
      final pick = pool.take(size).toList();
      bool ok = true;
      for (int i = 0; i < pick.length && ok; i++) {
        for (int j = i + 1; j < pick.length; j++) {
          if (!paletteCompatible(pick[i], pick[j])) {
            ok = false;
            break;
          }
        }
      }
      if (ok) return pick;
    }
    // Fallback déterministe : triplet sûr (toutes paires compatibles).
    return [colorPool[1], colorPool[3], colorPool[2]].take(size).toList();
  }

  /// Construit les zones de couleur de l'item.
  ///
  /// Nombre de zones par niveau :
  /// - veryEasy/easy : 2 (frontière simple, axiale au tout début)
  /// - medium        : 2 ou 3
  /// - hard          : 3, ou 1 (monochrome, ~25 % — difficulté purement
  ///   géométrique, comme dans les items difficiles du subtest réel)
  ///
  /// Items multicolores : on retente jusqu'à obtenir AU MOINS une vraie
  /// pièce bicolore (frontière de couleur ≠ lignes de découpe).
  (List<ColoredRegion>, int)? _buildColorZones(
      Polygon target, DifficultyLevel level, List<Polygon> cuts) {
    final nZones = switch (level) {
      DifficultyLevel.veryEasy || DifficultyLevel.easy => 2,
      DifficultyLevel.medium => 2 + _rng.nextInt(2),
      DifficultyLevel.hard => _rng.nextDouble() < 0.25 ? 1 : 3,
    };
    if (nZones == 1) return ([ColoredRegion(target, 0)], 1);

    for (int attempt = 0; attempt < 16; attempt++) {
      final zones = _tryZones(target, nZones, level);
      if (zones == null) continue;
      if (_hasBicolorPiece(cuts, zones)) return (zones, nZones);
    }
    return null;
  }

  List<ColoredRegion>? _tryZones(
      Polygon target, int nZones, DifficultyLevel level) {
    final totalArea = target.area();
    if (totalArea < kGeomEps) return null;

    // Première frontière : axiale en veryEasy (motif très lisible),
    // oblique libre ensuite.
    final angle1 = level == DifficultyLevel.veryEasy
        ? (_rng.nextBool() ? 0.0 : math.pi / 2)
        : _rng.nextDouble() * math.pi;
    final parts1 = _splitByLine(target, angle1);
    if (parts1 == null) return null;
    final (a, b) = parts1;
    if (math.min(a.area(), b.area()) / totalArea < 0.28) return null;

    if (nZones == 2) {
      return [ColoredRegion(a, 0), ColoredRegion(b, 1)];
    }

    // 3 zones : recouper la plus grande moitié avec un angle nettement
    // différent (≥ ~30°) pour un motif intéressant.
    final big = a.area() >= b.area() ? a : b;
    final small = a.area() >= b.area() ? b : a;
    final delta =
        (math.pi / 6) + _rng.nextDouble() * (math.pi - math.pi / 3);
    final angle2 = (angle1 + delta) % math.pi;
    final parts2 = _splitByLine(big, angle2);
    if (parts2 == null) return null;
    final (c, d) = parts2;
    if (math.min(c.area(), d.area()) / totalArea < 0.16) return null;

    return [ColoredRegion(small, 0), ColoredRegion(c, 1), ColoredRegion(d, 2)];
  }

  /// Coupe un polygone par une ligne d'angle donné passant près du centroïde
  /// (jitter pour varier les proportions).
  (Polygon, Polygon)? _splitByLine(Polygon poly, double angle) {
    final bb = poly.bbox();
    final c = poly.centroid() +
        Offset(
          (_rng.nextDouble() - 0.5) * bb.width * 0.24,
          (_rng.nextDouble() - 0.5) * bb.height * 0.24,
        );
    final d = Offset(math.cos(angle), math.sin(angle));
    final parts = cutPolygonByLine(poly, CutLine(c - d * 3, c + d * 3));
    if (parts[0].vertices.length < 3 || parts[1].vertices.length < 3) {
      return null;
    }
    return (parts[0], parts[1]);
  }

  /// Vrai si au moins une pièce chevauche ≥ 2 zones de façon significative
  /// (chaque fragment ≥ 18 % de l'aire de la pièce).
  bool _hasBicolorPiece(List<Polygon> cuts, List<ColoredRegion> zones) {
    for (final piece in cuts) {
      final pieceArea = piece.area();
      if (pieceArea < kGeomEps) continue;
      int significant = 0;
      for (final z in zones) {
        final inter = intersectConvex(piece, z.polygon);
        if (inter.vertices.length >= 3 &&
            inter.area() / pieceArea >= 0.18) {
          significant++;
        }
      }
      if (significant >= 2) return true;
    }
    return false;
  }

  /// Génère les 3 distracteurs pour un item.
  ///
  /// Logique par niveau (ordre prioritaire des types de pièges) :
  /// - veryEasy → wrongColors + foreignShape + scaled
  ///   Le trio classique des premiers items du subtest réel : bonne forme
  ///   mauvaise couleur, forme clairement étrangère, pièce trop petite.
  /// - easy     → wrongColors + scaled + mirrored
  /// - medium   → scaled + wrongColors/mirrored + alternativeCut
  /// - hard     → mirrored + alternativeCut + wrongColors/stretched
  ///   Tous les pièges subtils ; le joueur doit analyser finement.
  List<PuzzlePiece>? _buildDistractors(
    List<Polygon> truePieces,
    List<List<ColoredRegion>> trueRegions,
    Polygon target,
    List<ColoredRegion> zones,
    int paletteSize,
    DifficultyLevel level,
    double subtlety,
    List<double> rotationPool,
    BaseShape baseShape,
  ) {
    // Chaque slot a une liste ordonnée de types à essayer (fallbacks inclus).
    final slots = _trapSlotsFor(level);
    final result = <PuzzlePiece>[];
    final produced = <Polygon>[];
    bool wrongColorsUsed = false;

    for (int slot = 0; slot < 3; slot++) {
      TrapResult? trap;
      TrapKind? usedKind;

      outer:
      for (final kind in slots[slot]) {
        // Un seul piège "couleurs fausses" par item : deux pièces identiques
        // aux couleurs près seraient déroutantes sans valeur diagnostique.
        if (kind == TrapKind.wrongColors && wrongColorsUsed) continue;

        for (int attempt = 0; attempt < 6; attempt++) {
          final srcIdx = _rng.nextInt(truePieces.length);

          // wrongColors garde la géométrie EXACTE d'une vraie pièce : la
          // source ne doit donc être QUASI congruente (seuil perceptuel) à
          // aucune AUTRE vraie pièce, sinon le piège recoloré pourrait se
          // confondre avec cette autre pièce → deux réponses valides.
          if (kind == TrapKind.wrongColors) {
            bool unique = true;
            for (int j = 0; j < truePieces.length; j++) {
              if (j != srcIdx &&
                  congruent(truePieces[srcIdx], truePieces[j],
                      allowMirror: true, relTol: kPerceptualTol)) {
                unique = false;
                break;
              }
            }
            if (!unique) continue;
          }

          final candidate = _trapEngine.tryTrap(
            kind: kind,
            source: truePieces[srcIdx],
            sourceRegions: trueRegions[srcIdx],
            target: target,
            truePieces: truePieces,
            zones: zones,
            paletteSize: paletteSize,
            subtlety: subtlety,
            targetShape: baseShape,
          );
          if (candidate == null) continue;

          // Anti-dégénérescence wrongColors : si le piège recoloré est UNI
          // et qu'une vraie pièce unie porte la MÊME couleur, l'item se
          // réduit à comparer les tailles de deux pièces de même couleur
          // (mesuré : 17 % des items veryEasy) — plus aucun raisonnement
          // sur le motif. On rejette et on retente (autre source ou kind).
          if (kind == TrapKind.wrongColors) {
            final trapUni = _uniColorOf(candidate.regions, candidate.polygon);
            if (trapUni != null) {
              bool degenerate = false;
              for (int j = 0; j < truePieces.length; j++) {
                if (_uniColorOf(trueRegions[j], truePieces[j]) == trapUni) {
                  degenerate = true;
                  break;
                }
              }
              if (degenerate) continue;
            }
          }

          // Validation au seuil PERCEPTUEL : pas quasi-congruent aux vraies
          // pièces ni aux distracteurs déjà retenus (un écart < ~8 % est
          // invisible sur une case d'option). Exceptions : mirrored (miroir
          // d'une vraie pièce = valide par définition, tant qu'il n'est pas
          // superposable par simple rotation) et wrongColors (congruence
          // voulue, la différence est dans les couleurs).
          bool clash = false;
          if (kind != TrapKind.wrongColors) {
            for (final tp in truePieces) {
              if (congruent(candidate.polygon, tp,
                  allowMirror: true, relTol: kPerceptualTol)) {
                if (kind == TrapKind.mirrored &&
                    !congruent(candidate.polygon, tp,
                        relTol: kPerceptualTol)) {
                  continue;
                }
                clash = true;
                break;
              }
            }
          }
          if (clash) continue;
          for (final d in produced) {
            if (congruent(candidate.polygon, d,
                allowMirror: true, relTol: kPerceptualTol)) {
              clash = true;
              break;
            }
          }
          if (clash) continue;

          // Lisibilité : pas de piège "aiguille" (les étirements peuvent
          // passer sous le seuil garanti par CutEngine pour les vraies
          // pièces). Ratio bbox aligné sur CutEngine (0.16).
          final cbb = candidate.polygon.bbox();
          final cMax = math.max(cbb.width, cbb.height);
          if (cMax < kGeomEps ||
              math.min(cbb.width, cbb.height) / cMax < 0.16) {
            continue;
          }

          trap = candidate;
          usedKind = kind;
          if (kind == TrapKind.wrongColors) wrongColorsUsed = true;
          break outer;
        }
      }

      // Fallback garanti : pièce réduite à une taille distincte par slot.
      if (trap == null) {
        final fallbackFactors = [0.42, 0.50, 0.58];
        final srcIdx = slot % truePieces.length;
        final source = truePieces[srcIdx];
        final f = fallbackFactors[slot];
        final c = source.centroid();
        trap = TrapResult(
          source.transform(scale: f),
          trueRegions[srcIdx]
              .map((r) => ColoredRegion(
                  r.polygon.transform(scale: f, center: c), r.colorIndex))
              .toList(),
        );
        usedKind = TrapKind.scaled;
      }

      produced.add(trap.polygon);
      result.add(PuzzlePiece(
        id: _uuid(),
        polygon: trap.polygon,
        regions: trap.regions,
        displayRotationDeg: rotationPool[_rng.nextInt(rotationPool.length)],
        isCorrect: false,
        trapKind: usedKind,
      ));
    }
    return result.length == 3 ? result : null;
  }

  /// Couleur d'une pièce visuellement UNIE : l'index de couleur qui couvre
  /// ≥ 95 % de l'aire de la pièce, ou null si la pièce est multicolore.
  static int? _uniColorOf(List<ColoredRegion> regions, Polygon piece) {
    final total = piece.area();
    if (total < kGeomEps) return null;
    final byColor = <int, double>{};
    for (final r in regions) {
      byColor[r.colorIndex] = (byColor[r.colorIndex] ?? 0) + r.polygon.area();
    }
    for (final e in byColor.entries) {
      if (e.value / total >= 0.95) return e.key;
    }
    return null;
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

  /// Slots ordonnés de types de pièges par niveau de difficulté.
  ///
  /// Chaque slot est une liste PRIORITAIRE : le premier type est essayé en
  /// premier ; si tryTrap retourne null, on essaie le suivant.
  ///
  /// Règles cardinales :
  ///   - veryEasy / easy → PAS d'alternativeCut (trop dur à distinguer)
  ///   - medium / hard   → alternativeCut autorisé en complément
  ///   - wrongColors apparaît dans UN slot par niveau (verrou anti-doublon
  ///     dans _buildDistractors) ; impossible sur item monochrome → fallback
  List<List<TrapKind>> _trapSlotsFor(DifficultyLevel level) => switch (level) {
        DifficultyLevel.veryEasy => [
            // Slot 0 : bonne forme, MAUVAISE couleur (piège classique des
            // premiers items réels — facile à voir, apprend la mécanique)
            [TrapKind.wrongColors, TrapKind.foreignShape, TrapKind.scaled],
            // Slot 1 : forme clairement étrangère (arc courbe vs angulaire)
            [TrapKind.foreignShape, TrapKind.scaled],
            // Slot 2 : pièce vraie mais clairement trop petite (~44 % taille)
            [TrapKind.scaled],
          ],
        DifficultyLevel.easy => [
            // Slot 0 : couleurs fausses, sinon forme étrangère
            [TrapKind.wrongColors, TrapKind.foreignShape, TrapKind.scaled],
            // Slot 1 : pièce trop petite (~55 % taille)
            [TrapKind.scaled, TrapKind.stretched],
            // Slot 2 : miroir si asymétrique, sinon étirement (évite doublon
            // scaled quand la pièce est symétrique comme un rectangle)
            [TrapKind.mirrored, TrapKind.stretched, TrapKind.foreignShape],
          ],
        DifficultyLevel.medium => [
            // Slot 0 : taille modérément différente (~70 %)
            [TrapKind.scaled, TrapKind.alternativeCut],
            // Slot 1 : couleurs fausses ou miroir
            [TrapKind.wrongColors, TrapKind.mirrored, TrapKind.alternativeCut],
            // Slot 2 : découpe alternative (même cible, autre décomposition)
            [TrapKind.alternativeCut, TrapKind.stretched],
          ],
        DifficultyLevel.hard => [
            // Slot 0 : miroir subtil
            [TrapKind.mirrored, TrapKind.alternativeCut],
            // Slot 1 : découpe alternative indétectable
            [TrapKind.alternativeCut, TrapKind.stretched],
            // Slot 2 : couleurs fausses (subtil sur motif 3 couleurs), sinon
            // étirement à aire constante (piège le plus fin)
            [TrapKind.wrongColors, TrapKind.stretched, TrapKind.alternativeCut],
          ],
      };
}
