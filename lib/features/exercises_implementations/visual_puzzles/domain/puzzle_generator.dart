import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'base_shapes.dart';
import 'cut_engine.dart';
import 'difficulty_ladder.dart';
import 'geometry.dart';
import 'trap_engine.dart';

export 'base_shapes.dart' show BaseShape, BaseShapeX;
export 'cut_engine.dart' show CutStrategy;
export 'difficulty_ladder.dart' show ItemRecipe, ColorMode, kLadder;
export 'geometry.dart'
    show
        Polygon,
        ColoredRegion,
        congruent,
        perceptuallyIdentical,
        visuallyConfusable,
        kMonoDistinctTol,
        isReconstruction,
        intersectConvex;
export 'trap_engine.dart' show TrapKind, TrapResult;

/// Niveau de difficulté d'un item, DÉRIVÉ du palier de sa recette
/// (P1-P2 → veryEasy, P3-P4 → easy, P5-P6 → medium, P7-P8 → hard).
/// Conservé pour l'affichage et le mode entraînement (`filterLevel`).
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
    this.isTwin = false,
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

  /// Vrai si ce piège est un « jumeau » : sourcé sur une vraie pièce
  /// AFFICHÉE (paire repérable dans les 6 cases). Plafonné par palier via
  /// `ItemRecipe.maxTwins` — analytique/journal, invisible pour le sujet.
  final bool isTwin;

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
    required this.palier,
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
    this.fallbackUsed = false,
  });

  final int index;

  /// Palier 1..8 de l'échelle de difficulté (radical, identique pour tous
  /// les patients à la même position — voir [kLadder]).
  final int palier;

  /// Niveau dérivé du palier (affichage, mode entraînement).
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

  /// Vrai si la génération a dû recourir à un plan B (piège de dernier
  /// recours, couleurs relaxées vers monochrome). Journalisé : un taux
  /// élevé signalerait une recette trop contrainte.
  final bool fallbackUsed;

  List<PuzzlePiece> get correctPieces =>
      options.where((p) => p.isCorrect).toList();
}

/// Générateur d'items "Puzzles visuels".
///
/// Principe fidèle au subtest VP (contenu 100 % original):
/// une silhouette cible pleine, 6 pièces numérotées, choisir les 3 qui la
/// reconstituent. Les pièces peuvent être tournées mentalement, jamais
/// retournées.
///
/// Depuis la refonte 2026-07 la difficulté n'est PLUS tirée au sort : chaque
/// item suit la RECETTE de sa position dans l'échelle [kLadder] (26 items,
/// 8 paliers). Les radicaux (forme, découpe, rotations minimales, indices
/// couleur, types de pièges, budget de jumeaux) sont fixés par la recette ;
/// seuls les incidentaux (forme précise du pool, angles, couleurs, ordre des
/// cases) sont aléatoires → contenu différent par patient, difficulté
/// équivalente (formes parallèles).
///
/// La génération est paramétrique et reproductible (`seed`).
/// Plafond d'inflation de l'échelle d'affichage : le bbox TOURNÉ d'une
/// option ne doit pas dépasser 1,15 × la plus grande dimension non tournée
/// des vraies pièces. Une rotation diagonale ne coûte presque rien sur une
/// bande fine ((L+l)/√2 < L) mais ×1,41 sur une pièce carrée — avant
/// l'audit visuel 2026-07-16, ces ×1,41 écrasaient l'échelle commune de
/// l'item (cible ~53 px sur mobile pour 26/260 items audités). Le choix
/// pièce/angle se fait donc sur le bbox tourné RÉEL ; le minimum de
/// diagonales de la recette prime toujours (violation minimisée si
/// géométriquement inévitable).
const double kMaxDisplayInflation = 1.15;

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

  /// Graine de la banque générée — à JOURNALISER avec les résultats : c'est
  /// elle qui rend une session reproductible (debug d'un item suspect,
  /// ré-analyse des données par item).
  int get seed => _seed;

  late final math.Random _rng;
  late final CutEngine _cutEngine;
  late final TrapEngine _trapEngine;
  int _idCounter = 0;

  static const int totalItems = 26;

  /// Pièges « jumeaux » : ceux qui copient la géométrie d'une pièce source.
  /// Sourcés sur une vraie pièce AFFICHÉE, ils créent une paire repérable —
  /// leur nombre est plafonné par `recipe.maxTwins`.
  static const Set<TrapKind> _twinKinds = {
    TrapKind.scaled,
    TrapKind.mirrored,
    TrapKind.stretched,
    TrapKind.wrongColors,
  };

  String _uuid() {
    _idCounter++;
    return 'p$_idCounter-${_rng.nextInt(1 << 30).toRadixString(36)}';
  }

  /// La batterie complète : un item par recette de l'échelle.
  List<PuzzleItem> generateComplete26Items() {
    assert(kLadder.length == totalItems);
    final items = <PuzzleItem>[];
    for (int i = 0; i < kLadder.length; i++) {
      items.add(generateItemFromRecipe(i + 1, kLadder[i]));
    }
    return items;
  }

  /// API héritée : génère l'item de la position [index] de l'échelle.
  ///
  /// [level] est IGNORÉ — la difficulté est entièrement portée par la
  /// recette du palier correspondant à [index]. Paramètre conservé pour
  /// compatibilité (démo, tests existants).
  PuzzleItem generateItem(int index, DifficultyLevel level) {
    final recipe = kLadder[(index - 1).clamp(0, kLadder.length - 1)];
    return generateItemFromRecipe(index, recipe);
  }

  /// Génère un item conforme à [recipe].
  ///
  /// Politique de recours (JAMAIS de dégradation d'un radical vers plus
  /// facile) : on retente d'abord d'autres incidentaux du même palier ;
  /// en dernier recours les couleurs sont relaxées vers monochrome (plus
  /// dur, pas plus facile) et l'item est marqué `fallbackUsed`.
  PuzzleItem generateItemFromRecipe(int index, ItemRecipe recipe) {
    for (int attempt = 0; attempt < 24; attempt++) {
      final item = _tryGenerateFromRecipe(index, recipe);
      if (item != null) return item;
    }
    for (int attempt = 0; attempt < 40; attempt++) {
      final item = _tryGenerateFromRecipe(index, recipe, relaxColors: true);
      if (item != null) return item;
    }
    // Jamais observé (le CutEngine et les pièges ont leurs propres recours
    // garantis) — si on arrive ici, un invariant géométrique est cassé.
    throw StateError(
        'PuzzleGenerator : génération impossible pour le palier '
        '${recipe.palier} (seed $_seed, item $index)');
  }

  DifficultyLevel _levelForPalier(int palier) => switch (palier) {
        1 || 2 => DifficultyLevel.veryEasy,
        3 || 4 => DifficultyLevel.easy,
        5 || 6 => DifficultyLevel.medium,
        _ => DifficultyLevel.hard,
      };

  PuzzleItem? _tryGenerateFromRecipe(int index, ItemRecipe recipe,
      {bool relaxColors = false}) {
    bool fallbackUsed = false;

    // 1. Forme de base et découpe — incidentaux tirés dans les pools de la
    // recette (radicaux : les pools eux-mêmes).
    final baseShape = recipe.shapes[_rng.nextInt(recipe.shapes.length)];
    final targetPolygon = buildBaseShape(baseShape);
    final strategy = recipe.strategies[_rng.nextInt(recipe.strategies.length)];
    final cuts = _cutEngine.cut(targetPolygon, strategy);
    if (!isReconstruction(cuts, targetPolygon,
        areaTolerance: 0.03, minAreaShare: CutEngine.minShare)) {
      return null;
    }

    // 1b. GARDE refonte carré : les 3 vraies pièces doivent être mutuellement
    // discernables (à rotation ET miroir près) — sur un carré coupé en bandes,
    // deux vraies pièces quasi identiques rendraient l'appariement ambigu et
    // réactiveraient l'élimination par doublons. Rejet → autre tirage au même
    // palier (jamais de dégradation de radical).
    for (int i = 0; i < cuts.length; i++) {
      for (int j = i + 1; j < cuts.length; j++) {
        if (visuallyConfusable(cuts[i], cuts[j], allowMirror: true)) {
          return null;
        }
      }
    }

    // 2. Zones de couleur du motif — INDÉPENDANTES des lignes de découpe.
    // Exigence (items multicolores) : au moins une vraie pièce bicolore,
    // sinon les couleurs trahiraient la correspondance pièce ↔ zone.
    var zoneInfo = _buildColorZones(targetPolygon, recipe.colorMode, cuts);
    if (zoneInfo == null) {
      if (!relaxColors) return null;
      // Recours : monochrome — retire des indices, ne dégrade jamais la
      // difficulté vers le bas.
      zoneInfo = ([ColoredRegion(targetPolygon, 0)], 1);
      fallbackUsed = true;
    }
    final (zones, paletteSize) = zoneInfo;
    final palette = _pickPalette(paletteSize);

    // 2b. Coloration des vraies pièces (fragments du motif).
    final trueRegions = cuts.map((poly) => clipToZones(poly, zones)).toList();

    // 3. Vraies pièces — rotations d'affichage garanties par construction
    // (minimums de la recette imposés, pas espérés du tirage).
    final rotations = _drawRotationsFor3(recipe, cuts);
    final truePieces = <PuzzlePiece>[];
    for (int i = 0; i < cuts.length; i++) {
      truePieces.add(PuzzlePiece(
        id: _uuid(),
        polygon: cuts[i],
        regions: trueRegions[i],
        displayRotationDeg: rotations[i],
        isCorrect: true,
      ));
    }

    // 4. Distracteurs (budget de jumeaux de la recette).
    final distractorInfo = _buildDistractors(cuts, trueRegions, targetPolygon,
        zones, paletteSize, recipe, baseShape);
    if (distractorInfo == null) return null;
    final (distractors, trapFallback) = distractorInfo;
    fallbackUsed = fallbackUsed || trapFallback;

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
      palier: recipe.palier,
      level: _levelForPalier(recipe.palier),
      baseShape: baseShape,
      targetPolygon: targetPolygon,
      colorZones: zones,
      palette: palette,
      options: options,
      correctIds: truePieces.map((p) => p.id).toSet(),
      timeLimitSeconds: recipe.timeLimitSeconds,
      cutStrategy: strategy,
      maxPieceExtent: maxExtent,
      fallbackUsed: fallbackUsed,
    );
  }

  /// Tire les 3 rotations d'affichage des vraies pièces en GARANTISSANT les
  /// minimums de la recette (pièces tournées, pièces à angle diagonal) :
  /// on tire librement puis on force des cases jusqu'au compte — aucune
  /// possibilité d'échec, la rotation n'est jamais une cause de re-tirage.
  ///
  /// Les angles DIAGONAUX sont réservés aux pièces les plus PETITES : une
  /// grande pièce tournée à 45° gonfle son bbox de ×√2, ce qui écrase
  /// l'échelle commune de tout l'item (audit visuel 2026-07-16 : cible
  /// réduite à ~53 px sur mobile pour 26/260 items). Le minimum de la
  /// recette prime toujours : en dernier recours une grande pièce reçoit
  /// quand même la diagonale.
  List<double> _drawRotationsFor3(ItemRecipe recipe, List<Polygon> pieces) {
    final pool = recipe.rotationAngles;
    final maxDim = pieces.map(_maxDim).reduce(math.max);
    final budget = kMaxDisplayInflation * maxDim;

    // Bbox TOURNÉ réel : c'est lui qui dicte l'échelle commune, pas la
    // taille brute (bande fine à 45° ≈ ×0,88, pièce carrée à 45° = ×1,41).
    double rotDim(int i, double a) =>
        _maxDim(a == 0 ? pieces[i] : pieces[i].transform(rotationDeg: a));
    bool ok(int i, double a) => rotDim(i, a) <= budget;
    // Les angles cardinaux préservent le bbox : toujours dans le budget.
    List<double> okAngles(int i, Iterable<double> src) =>
        src.where((a) => a % 90 == 0 || ok(i, a)).toList();

    // 1. Tirage libre, borné au budget d'inflation.
    final rots = List<double>.generate(3, (i) {
      final allowed = okAngles(i, pool);
      return allowed[_rng.nextInt(allowed.length)];
    });

    // 2. Minimum de pièces tournées (angle non nul, dans le budget).
    final nonZero = pool.where((a) => a != 0).toList();
    if (nonZero.isNotEmpty && recipe.minRotatedPieces > 0) {
      var count = rots.where((a) => a != 0).length;
      final order = [0, 1, 2]..shuffle(_rng);
      for (final i in order) {
        if (count >= recipe.minRotatedPieces) break;
        if (rots[i] == 0) {
          final allowed = okAngles(i, nonZero);
          rots[i] = allowed.isNotEmpty
              ? allowed[_rng.nextInt(allowed.length)]
              : nonZero[_rng.nextInt(nonZero.length)];
          count++;
        }
      }
    }

    // 3. Minimum de pièces à angle diagonal : on choisit le couple
    //    pièce × angle de bbox tourné MINIMAL (le minimum de la recette
    //    prime — si aucun couple ne tient dans le budget, on prend le
    //    moins coûteux).
    final diagonals = pool.where((a) => a % 90 != 0).toList();
    if (diagonals.isNotEmpty && recipe.minDiagonalPieces > 0) {
      var count = rots.where((a) => a % 90 != 0).length;
      while (count < recipe.minDiagonalPieces) {
        int? bestI;
        double? bestA;
        var bestCost = double.infinity;
        for (int i = 0; i < 3; i++) {
          if (rots[i] % 90 != 0) continue;
          for (final a in diagonals) {
            final cost = rotDim(i, a);
            // Léger bruit pour ne pas figer le choix à coût quasi égal.
            final jitter = 1 + _rng.nextDouble() * 0.02;
            if (cost * jitter < bestCost) {
              bestCost = cost * jitter;
              bestI = i;
              bestA = a;
            }
          }
        }
        if (bestI == null) break; // plus de case cardinale à convertir
        rots[bestI] = bestA!;
        count++;
      }
    }
    return rots;
  }

  /// Plus grande dimension du bbox d'une pièce (non tournée).
  static double _maxDim(Polygon p) {
    final bb = p.bbox();
    return math.max(bb.width, bb.height);
  }

  /// Rotation d'affichage d'un PIÈGE : même budget d'inflation que les
  /// vraies pièces (bbox tourné ≤ [kMaxDisplayInflation] × plus grande
  /// vraie pièce) — un seul piège carré tourné à 45° suffirait à écraser
  /// l'échelle commune de tout l'item.
  double _trapRotation(ItemRecipe recipe, Polygon trapPoly, double maxTrueDim) {
    final pool = recipe.rotationAngles;
    final budget = kMaxDisplayInflation * maxTrueDim;
    final allowed = pool
        .where((a) =>
            a % 90 == 0 ||
            _maxDim(trapPoly.transform(rotationDeg: a)) <= budget)
        .toList();
    final src = allowed.isNotEmpty ? allowed : pool;
    return src[_rng.nextInt(src.length)];
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

  /// Construit les zones de couleur de l'item selon le mode de la recette.
  ///
  /// Items multicolores : on retente jusqu'à obtenir AU MOINS une vraie
  /// pièce bicolore (frontière de couleur ≠ lignes de découpe).
  (List<ColoredRegion>, int)? _buildColorZones(
      Polygon target, ColorMode mode, List<Polygon> cuts) {
    final nZones = switch (mode) {
      ColorMode.monochrome => 1,
      ColorMode.twoZonesAxial || ColorMode.twoZones => 2,
      ColorMode.threeZones => 3,
    };
    if (nZones == 1) return ([ColoredRegion(target, 0)], 1);

    for (int attempt = 0; attempt < 16; attempt++) {
      final zones = _tryZones(target, nZones,
          axial: mode == ColorMode.twoZonesAxial);
      if (zones == null) continue;
      if (_hasBicolorPiece(cuts, zones)) return (zones, nZones);
    }
    return null;
  }

  List<ColoredRegion>? _tryZones(Polygon target, int nZones,
      {required bool axial}) {
    final totalArea = target.area();
    if (totalArea < kGeomEps) return null;

    // Première frontière : axiale (motif très lisible) ou oblique libre.
    final angle1 = axial
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

  // ---------- Distracteurs ----------

  /// Pièce d'une AUTRE découpe valide de la cible, NON confusable avec une
  /// vraie pièce affichée : la source des pièges « sans jumeau » (budget
  /// maxTwins épuisé). Le piège transformé qui en dérive est plausible
  /// (motif réel de la cible via clipToZones) mais n'a AUCUNE paire visible
  /// dans les 6 cases → l'élimination par doublons ne s'applique pas.
  Polygon? _altSourcePiece(Polygon target, List<Polygon> truePieces) {
    for (int attempt = 0; attempt < 6; attempt++) {
      final strategy =
          CutStrategy.values[_rng.nextInt(CutStrategy.values.length)];
      final pieces = _cutEngine.cut(target, strategy);
      if (pieces.length != 3) continue;
      final candidates = pieces.where((p) {
        if (p.vertices.length < 3) return false;
        for (final tp in truePieces) {
          if (visuallyConfusable(p, tp, allowMirror: true)) return false;
        }
        return true;
      }).toList();
      if (candidates.isNotEmpty) {
        return candidates[_rng.nextInt(candidates.length)];
      }
    }
    return null;
  }

  /// Génère les 3 distracteurs d'un item selon la recette.
  ///
  /// Retourne (pièges, fallbackUsed) ou null si un slot n'a rien produit
  /// (l'appelant retente d'autres incidentaux).
  ///
  /// Budget de jumeaux : les pièges de [_twinKinds] sourcés sur une vraie
  /// pièce affichée comptent dans `recipe.maxTwins` ; au-delà,
  /// scaled/mirrored/stretched sont sourcés sur [_altSourcePiece] et
  /// wrongColors (géométrie d'une vraie pièce PAR DÉFINITION) est sauté.
  (List<PuzzlePiece>, bool)? _buildDistractors(
    List<Polygon> truePieces,
    List<List<ColoredRegion>> trueRegions,
    Polygon target,
    List<ColoredRegion> zones,
    int paletteSize,
    ItemRecipe recipe,
    BaseShape baseShape,
  ) {
    final slots = recipe.trapSlots;
    final subtlety = recipe.subtlety;
    final result = <PuzzlePiece>[];
    final produced = <Polygon>[];
    final maxTrueDim = truePieces.map(_maxDim).reduce(math.max);
    bool wrongColorsUsed = false;
    bool fallbackUsed = false;
    int twinsUsed = 0;

    for (int slot = 0; slot < 3; slot++) {
      TrapResult? trap;
      TrapKind? usedKind;
      bool trapIsTwin = false;

      outer:
      for (final kind in slots[slot]) {
        // Un seul piège "couleurs fausses" par item : deux pièces identiques
        // aux couleurs près seraient déroutantes sans valeur diagnostique.
        // Et wrongColors est un jumeau par construction → budget requis.
        if (kind == TrapKind.wrongColors &&
            (wrongColorsUsed || twinsUsed >= recipe.maxTwins)) {
          continue;
        }

        for (int attempt = 0; attempt < 6; attempt++) {
          final needAltSource = _twinKinds.contains(kind) &&
              kind != TrapKind.wrongColors &&
              twinsUsed >= recipe.maxTwins;

          final Polygon source;
          final List<ColoredRegion> sourceRegions;
          final bool sourcedOnTruePiece;
          if (needAltSource) {
            final alt = _altSourcePiece(target, truePieces);
            if (alt == null) continue;
            source = alt;
            sourceRegions = clipToZones(alt, zones);
            sourcedOnTruePiece = false;
          } else {
            final srcIdx = _rng.nextInt(truePieces.length);

            // wrongColors garde la géométrie EXACTE d'une vraie pièce : la
            // source ne doit donc être QUASI confusable à aucune AUTRE vraie
            // pièce, sinon le piège recoloré pourrait se confondre avec
            // cette autre pièce → deux réponses valides.
            if (kind == TrapKind.wrongColors) {
              bool unique = true;
              for (int j = 0; j < truePieces.length; j++) {
                if (j != srcIdx &&
                    visuallyConfusable(truePieces[srcIdx], truePieces[j],
                        allowMirror: true)) {
                  unique = false;
                  break;
                }
              }
              if (!unique) continue;
            }
            source = truePieces[srcIdx];
            sourceRegions = trueRegions[srcIdx];
            sourcedOnTruePiece = true;
          }

          final candidate = _trapEngine.tryTrap(
            kind: kind,
            source: source,
            sourceRegions: sourceRegions,
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

          // Validation au seuil PERCEPTUEL (garde combinée signature +
          // contour) : pas quasi-confusable aux vraies pièces ni aux
          // distracteurs déjà retenus. Exceptions : mirrored (miroir d'une
          // vraie pièce = valide par définition, tant qu'il n'est pas
          // superposable par simple rotation) et wrongColors (congruence
          // voulue, la différence est dans les couleurs).
          bool clash = false;
          if (kind != TrapKind.wrongColors) {
            for (final tp in truePieces) {
              if (visuallyConfusable(candidate.polygon, tp,
                  allowMirror: true)) {
                if (kind == TrapKind.mirrored &&
                    !visuallyConfusable(candidate.polygon, tp)) {
                  continue;
                }
                clash = true;
                break;
              }
            }
          }
          if (clash) continue;

          // Items MONOCHROMES : la couleur ne discrimine plus rien, la
          // géométrie doit être NETTEMENT distincte des vraies pièces.
          // Audit visuel 2026-07-16 : un piège alternativeCut « bande
          // diagonale rectangle » à 4-13 % d'aire de la vraie bande
          // hexagonale rendait l'item quasi indécidable en 30 s (2 items
          // sur 11 exemplaires). Seuil élargi [kMonoDistinctTol]. Le miroir
          // reste exempté : sa proximité à sa source EST le piège
          // (chiralité), et il n'est jamais superposable par rotation.
          if (paletteSize == 1 && kind != TrapKind.mirrored) {
            for (final tp in truePieces) {
              if (perceptuallyIdentical(candidate.polygon, tp,
                  allowMirror: true, relTol: kMonoDistinctTol)) {
                clash = true;
                break;
              }
            }
            if (clash) continue;
          }

          for (final d in produced) {
            if (visuallyConfusable(candidate.polygon, d, allowMirror: true)) {
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
          trapIsTwin = sourcedOnTruePiece && _twinKinds.contains(kind);
          if (kind == TrapKind.wrongColors) wrongColorsUsed = true;
          break outer;
        }
      }

      // Dernier recours GARANTI, à la subtilité de la recette (jamais un
      // piège de niveau débutant dans un item dur) : pièce réduite selon
      // l'amplitude scaled du palier, jitter par slot pour éviter deux
      // recours identiques. Marqué fallbackUsed pour le journal.
      if (trap == null) {
        fallbackUsed = true;
        final mag = 0.56 + (0.12 - 0.56) * subtlety;
        final f = (1.0 - mag) * const [0.94, 1.0, 1.06][slot];
        // Source : hors affichage si le budget de jumeaux est épuisé.
        Polygon? src = twinsUsed >= recipe.maxTwins
            ? _altSourcePiece(target, truePieces)
            : null;
        List<ColoredRegion>? srcRegions;
        bool srcIsTwin = false;
        if (src == null) {
          final srcIdx = slot % truePieces.length;
          src = truePieces[srcIdx];
          srcRegions = trueRegions[srcIdx];
          srcIsTwin = true;
        } else {
          srcRegions = clipToZones(src, zones);
        }
        final c = src.centroid();

        // Même le dernier recours reste soumis aux gardes de distinctness :
        // sans cela, il réintroduisait exactement les quasi-jumeaux qu'on
        // interdit (audit 2026-07-16 : 9 pièges scaled perceptuellement
        // identiques à une vraie pièce sur items monochromes). On resserre
        // le facteur d'échelle par paliers jusqu'à distinctness ; le plus
        // petit facteur sert d'ultime filet (jamais d'échec).
        bool tooClose(Polygon p) {
          for (final tp in truePieces) {
            if (visuallyConfusable(p, tp, allowMirror: true) ||
                (paletteSize == 1 &&
                    perceptuallyIdentical(p, tp,
                        allowMirror: true, relTol: kMonoDistinctTol))) {
              return true;
            }
          }
          for (final d in produced) {
            if (visuallyConfusable(p, d, allowMirror: true)) return true;
          }
          return false;
        }

        // L'échelle descend jusqu'à sortir de la porte d'aire de TOUTES les
        // vraies pièces (une échelle fixe peut « traverser » la taille d'une
        // petite vraie pièce en rétrécissant — 2 cas mesurés sur 60 seeds).
        // Si aucune marche ne passe, on prend celle de marge d'aire maximale.
        var fUsed = f;
        var bestMargin = -1.0;
        var found = false;
        for (final shrink in const [1.0, 0.9, 0.8, 0.7, 0.6, 0.5, 0.42]) {
          final cand = f * shrink;
          final poly = src.transform(scale: cand);
          if (!tooClose(poly)) {
            fUsed = cand;
            found = true;
            break;
          }
          final aC = poly.area();
          var margin = double.infinity;
          for (final tp in truePieces) {
            final aT = tp.area();
            margin =
                math.min(margin, (aC - aT).abs() / math.max(aC, aT));
          }
          if (margin > bestMargin) {
            bestMargin = margin;
            fUsed = cand;
          }
        }
        assert(found || bestMargin >= 0);

        trap = TrapResult(
          src.transform(scale: fUsed),
          srcRegions
              .map((r) => ColoredRegion(
                  r.polygon.transform(scale: fUsed, center: c), r.colorIndex))
              .toList(),
        );
        usedKind = TrapKind.scaled;
        trapIsTwin = srcIsTwin;
      }

      if (trapIsTwin) twinsUsed++;
      produced.add(trap.polygon);
      result.add(PuzzlePiece(
        id: _uuid(),
        polygon: trap.polygon,
        regions: trap.regions,
        displayRotationDeg: _trapRotation(recipe, trap.polygon, maxTrueDim),
        isCorrect: false,
        trapKind: usedKind,
        isTwin: trapIsTwin,
      ));
    }
    return result.length == 3 ? (result, fallbackUsed) : null;
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
}
