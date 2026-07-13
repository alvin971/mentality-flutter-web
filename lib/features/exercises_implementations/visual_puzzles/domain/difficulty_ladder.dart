import 'package:flutter/foundation.dart';
import 'base_shapes.dart';
import 'cut_engine.dart';
import 'trap_engine.dart';

/// Mode couleur du MOTIF de la cible pour un item.
enum ColorMode {
  /// 2 zones, frontière axiale (horizontale/verticale) — motif très lisible.
  twoZonesAxial,

  /// 2 zones, frontière oblique libre.
  twoZones,

  /// 3 zones.
  threeZones,

  /// 1 zone : monochrome — plus aucun indice de localisation par la couleur,
  /// difficulté purement géométrique (le haut de l'échelle).
  monochrome,
}

/// Recette d'un item : les RADICAUX — les leviers qui pilotent réellement la
/// difficulté — fixés par palier, identiques pour tous les patients.
///
/// Les INCIDENTAUX (forme précise tirée du pool, angles exacts des découpes,
/// couleurs de la palette, ordre des 6 cases) restent aléatoires : chaque
/// patient voit un contenu différent, mais gravit la MÊME échelle de
/// difficulté → les scores bruts sont comparables (formes parallèles, au
/// sens psychométrique de la génération d'items par gabarits).
@immutable
class ItemRecipe {
  const ItemRecipe({
    required this.palier,
    required this.shapes,
    required this.strategies,
    required this.rotationAngles,
    required this.minRotatedPieces,
    this.minDiagonalPieces = 0,
    required this.colorMode,
    required this.trapSlots,
    required this.maxTwins,
    required this.subtlety,
    required this.timeLimitSeconds,
  });

  /// Palier 1..8 (P1 = apprentissage, P8 = plafond).
  final int palier;

  /// Pool de formes cibles autorisées. Toujours `[BaseShape.square]` depuis
  /// la refonte 2026-07 : comme dans le WAIS-IV réel, un contour distinctif
  /// (pointe de triangle, arc de cercle) donnerait des indices gratuits de
  /// localisation — la difficulté vient exclusivement de la découpe, du
  /// motif, des rotations et des pièges. (Les autres [BaseShape] restent
  /// utilisées par le piège `foreignShape`.)
  final List<BaseShape> shapes;

  /// Pool de stratégies de découpe autorisées.
  final List<CutStrategy> strategies;

  /// Pool d'angles d'affichage possibles pour les pièces.
  final List<double> rotationAngles;

  /// Nombre MINIMAL de vraies pièces affichées tournées (≠ 0°) — imposé par
  /// construction : le coût de rotation mentale est un radical, pas un
  /// hasard de tirage.
  final int minRotatedPieces;

  /// Nombre minimal de vraies pièces à angle diagonal (45°, 135°…).
  final int minDiagonalPieces;

  final ColorMode colorMode;

  /// Slots ordonnés de types de pièges (listes prioritaires avec fallbacks).
  final List<List<TrapKind>> trapSlots;

  /// Budget de « jumeaux » : nombre max de pièges autorisés à copier une
  /// vraie pièce AFFICHÉE (scaled/mirrored/stretched/wrongColors sourcés sur
  /// une vraie pièce). Au-delà, ces pièges sont sourcés sur une pièce d'une
  /// AUTRE découpe de la cible → pas de paire repérable, l'élimination par
  /// doublons ne fonctionne plus. 3 en P1 (pédagogique) → 0 en P7-P8.
  final int maxTwins;

  /// Subtilité des pièges ∈ [0,1] (amplitudes du TrapEngine).
  final double subtlety;

  final int timeLimitSeconds;
}

// Pools d'angles partagés.
const List<double> _rot0 = [0.0];
const List<double> _rotCard = [0.0, 90.0, 270.0];
const List<double> _rotCard4 = [0.0, 90.0, 180.0, 270.0];
const List<double> _rotDiag1 = [0.0, 45.0, 90.0, 180.0, 270.0];
const List<double> _rotFree = [
  0.0, 45.0, 90.0, 135.0, 180.0, 225.0, 270.0, 315.0,
];

// Slots de pièges partagés par palier.
const List<List<TrapKind>> _slotsP1 = [
  [TrapKind.wrongColors, TrapKind.foreignShape, TrapKind.scaled],
  [TrapKind.foreignShape, TrapKind.scaled],
  [TrapKind.scaled],
];
const List<List<TrapKind>> _slotsP2 = [
  [TrapKind.wrongColors, TrapKind.foreignShape, TrapKind.scaled],
  [TrapKind.scaled, TrapKind.stretched],
  [TrapKind.mirrored, TrapKind.stretched, TrapKind.foreignShape],
];
const List<List<TrapKind>> _slotsP3 = [
  [TrapKind.wrongColors, TrapKind.scaled, TrapKind.foreignShape],
  [TrapKind.scaled, TrapKind.stretched],
  [TrapKind.mirrored, TrapKind.stretched, TrapKind.foreignShape],
];
const List<List<TrapKind>> _slotsP4 = [
  [TrapKind.scaled, TrapKind.stretched],
  [TrapKind.wrongColors, TrapKind.mirrored, TrapKind.stretched],
  [TrapKind.mirrored, TrapKind.stretched, TrapKind.scaled],
];
const List<List<TrapKind>> _slotsP5 = [
  [TrapKind.alternativeCut, TrapKind.scaled],
  [TrapKind.wrongColors, TrapKind.mirrored, TrapKind.stretched],
  [TrapKind.scaled, TrapKind.stretched, TrapKind.alternativeCut],
];
const List<List<TrapKind>> _slotsP6 = [
  [TrapKind.mirrored, TrapKind.alternativeCut],
  [TrapKind.alternativeCut, TrapKind.stretched],
  [TrapKind.wrongColors, TrapKind.stretched, TrapKind.alternativeCut],
];
// P7-P8 : AUCUN jumeau (maxTwins 0) → pas de wrongColors (géométrie d'une
// vraie pièce par construction) ; scaled/mirrored/stretched sont sourcés sur
// une découpe alternative de la cible.
const List<List<TrapKind>> _slotsTop = [
  [TrapKind.alternativeCut, TrapKind.mirrored],
  [TrapKind.alternativeCut, TrapKind.stretched],
  [TrapKind.mirrored, TrapKind.scaled, TrapKind.stretched],
];

ItemRecipe _p1(double subtlety) => ItemRecipe(
      palier: 1,
      shapes: const [BaseShape.square],
      strategies: const [CutStrategy.twoParallel],
      rotationAngles: _rot0,
      minRotatedPieces: 0,
      colorMode: ColorMode.twoZonesAxial,
      trapSlots: _slotsP1,
      maxTwins: 3,
      subtlety: subtlety,
      timeLimitSeconds: 20,
    );

ItemRecipe _p2(double subtlety) => ItemRecipe(
      palier: 2,
      shapes: const [BaseShape.square],
      strategies: const [CutStrategy.twoParallel, CutStrategy.perpendicularL],
      rotationAngles: _rotCard,
      minRotatedPieces: 1,
      colorMode: ColorMode.twoZones,
      trapSlots: _slotsP2,
      maxTwins: 3,
      subtlety: subtlety,
      timeLimitSeconds: 20,
    );

ItemRecipe _p3(double subtlety) => ItemRecipe(
      palier: 3,
      shapes: const [BaseShape.square],
      strategies: const [
        CutStrategy.perpendicularL,
        CutStrategy.oneStraightOneOblique,
      ],
      rotationAngles: _rotCard,
      minRotatedPieces: 2,
      colorMode: ColorMode.twoZones,
      trapSlots: _slotsP3,
      maxTwins: 2,
      subtlety: subtlety,
      timeLimitSeconds: 30,
    );

ItemRecipe _p4(double subtlety) => ItemRecipe(
      palier: 4,
      shapes: const [BaseShape.square],
      strategies: const [
        CutStrategy.oneStraightOneOblique,
        CutStrategy.twoOblique,
      ],
      rotationAngles: _rotCard4,
      minRotatedPieces: 2,
      colorMode: ColorMode.threeZones,
      trapSlots: _slotsP4,
      maxTwins: 2,
      subtlety: subtlety,
      timeLimitSeconds: 30,
    );

ItemRecipe _p5(double subtlety) => ItemRecipe(
      palier: 5,
      shapes: const [BaseShape.square],
      strategies: const [CutStrategy.twoOblique, CutStrategy.fan],
      rotationAngles: _rotDiag1,
      minRotatedPieces: 2,
      minDiagonalPieces: 1,
      colorMode: ColorMode.threeZones,
      trapSlots: _slotsP5,
      maxTwins: 1,
      subtlety: subtlety,
      timeLimitSeconds: 30,
    );

ItemRecipe _p6(double subtlety) => ItemRecipe(
      palier: 6,
      shapes: const [BaseShape.square],
      strategies: const [
        CutStrategy.twoObliqueSteep,
        CutStrategy.fanOffset,
      ],
      rotationAngles: _rotFree,
      minRotatedPieces: 3,
      minDiagonalPieces: 2,
      colorMode: ColorMode.threeZones,
      trapSlots: _slotsP6,
      maxTwins: 1,
      subtlety: subtlety,
      timeLimitSeconds: 30,
    );

ItemRecipe _p7(double subtlety, ColorMode colorMode) => ItemRecipe(
      palier: 7,
      shapes: const [BaseShape.square],
      strategies: const [
        CutStrategy.nearDiagonal,
        CutStrategy.twoObliqueSteep,
      ],
      rotationAngles: _rotFree,
      minRotatedPieces: 3,
      minDiagonalPieces: 2,
      colorMode: colorMode,
      trapSlots: _slotsTop,
      maxTwins: 0,
      subtlety: subtlety,
      timeLimitSeconds: 30,
    );

ItemRecipe _p8(double subtlety, ColorMode colorMode) => ItemRecipe(
      palier: 8,
      shapes: const [BaseShape.square],
      strategies: const [
        CutStrategy.nearDiagonal,
        CutStrategy.fanOffset,
        CutStrategy.twoObliqueSteep,
      ],
      rotationAngles: _rotFree,
      minRotatedPieces: 3,
      minDiagonalPieces: 2,
      colorMode: colorMode,
      trapSlots: _slotsTop,
      maxTwins: 0,
      subtlety: subtlety,
      timeLimitSeconds: 30,
    );

/// L'échelle des 26 items — la MÊME pour tous les patients.
///
/// Cible = CARRÉ pour les 26 items (protocole WAIS-IV). Progression des
/// radicaux, portée par la DÉCOUPE :
/// P1 bandes parallèles · P2 + L perpendiculaire · P3 + 1 oblique ·
/// P4 + 2 obliques · P5 + éventail · P6 obliques rapprochées / éventail
/// décentré · P7 coupes quasi diagonales · P8 les découpes les plus
/// trompeuses. S'y ajoutent : rotations mentales croissantes, indices
/// couleur retirés (monochrome au sommet), jumeaux 3 → 0.
///
/// Les items monochromes de P7/P8 sont placés DÉTERMINISTIQUEMENT (pas au
/// hasard) : même dosage d'indices couleur pour tout le monde.
final List<ItemRecipe> kLadder = List.unmodifiable(<ItemRecipe>[
  // P1 — items 1-4
  _p1(0.05), _p1(0.08), _p1(0.11), _p1(0.14),
  // P2 — items 5-7
  _p2(0.20), _p2(0.25), _p2(0.30),
  // P3 — items 8-10
  _p3(0.36), _p3(0.40), _p3(0.44),
  // P4 — items 11-14
  _p4(0.50), _p4(0.54), _p4(0.58), _p4(0.62),
  // P5 — items 15-17
  _p5(0.66), _p5(0.70), _p5(0.74),
  // P6 — items 18-20
  _p6(0.78), _p6(0.81), _p6(0.84),
  // P7 — items 21-23 (monochrome sur l'item 22)
  _p7(0.87, ColorMode.threeZones),
  _p7(0.89, ColorMode.monochrome),
  _p7(0.91, ColorMode.threeZones),
  // P8 — items 24-26 (monochrome sur 24 et 26)
  _p8(0.93, ColorMode.monochrome),
  _p8(0.94, ColorMode.threeZones),
  _p8(0.95, ColorMode.monochrome),
]);
