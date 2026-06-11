import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'base_shapes.dart';
import 'cut_engine.dart';
import 'geometry.dart';

/// Types de pièges. Tous produisent des pièces PLAUSIBLES (polygones propres,
/// pas de déformations cabossées) — la difficulté vient de la subtilité de la
/// différence, pas de l'aspect "cassé".
enum TrapKind {
  /// Pièce issue d'une AUTRE découpe valide de la même cible — très plausible,
  /// mais ne complète pas les deux autres pièces.
  /// ⚠ Réservé aux niveaux MEDIUM et HARD uniquement.
  alternativeCut,

  /// Vraie pièce agrandie/réduite. Amplitude forte en début de test
  /// (clairement trop petite) → subtile en fin.
  scaled,

  /// Vraie pièce en miroir. Les pièces peuvent être tournées mais PAS
  /// retournées → invalide. (Rejeté si la pièce est symétrique.)
  mirrored,

  /// Vraie pièce étirée selon un axe (proportions fausses). En mode subtil,
  /// l'aire est préservée (étirement compensé) — piège redoutable.
  stretched,

  /// Pièce d'une forme visuellement CONTRASTANTE (courbe vs angulaire) —
  /// piège évident, réservé aux items faciles.
  foreignShape,

  /// GÉOMÉTRIE EXACTE d'une vraie pièce mais COULEURS FAUSSES (permutation
  /// de la palette). Le piège classique des premiers items du subtest réel :
  /// bonne forme, mauvaise couleur. Nécessite un item multicolore.
  wrongColors,
}

/// Résultat d'un piège : la silhouette + ses régions colorées (même espace
/// de coordonnées que le polygone).
@immutable
class TrapResult {
  const TrapResult(this.polygon, this.regions);
  final Polygon polygon;
  final List<ColoredRegion> regions;
}

/// Fabrique de distracteurs.
///
/// `subtlety` ∈ [0,1] : 0 = piège énorme (début de test), 1 = piège quasi
/// indétectable (fin de test). Les amplitudes sont interpolées en conséquence.
class TrapEngine {
  TrapEngine({math.Random? rng, CutEngine? cutEngine})
      : _rng = rng ?? math.Random(),
        _cutEngine = cutEngine ?? CutEngine(rng: rng);

  final math.Random _rng;
  final CutEngine _cutEngine;

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  /// Tente de produire un piège de type `kind`.
  ///
  /// [sourceRegions] : régions colorées de la pièce source (même espace que
  /// [source]) — transformées avec la même matrice que le polygone du piège.
  /// [zones] : zones de couleur de la cible (pour colorer les pièces créées
  /// en espace cible : alternativeCut).
  /// [paletteSize] : nombre de couleurs de l'item (1 = monochrome).
  /// [targetShape] est utilisé par [TrapKind.foreignShape] pour choisir une
  /// forme visuellement contrastante (courbe pour cible angulaire, etc.).
  TrapResult? tryTrap({
    required TrapKind kind,
    required Polygon source,
    required List<ColoredRegion> sourceRegions,
    required Polygon target,
    required List<Polygon> truePieces,
    required List<ColoredRegion> zones,
    required int paletteSize,
    required double subtlety,
    BaseShape? targetShape,
  }) {
    final t = subtlety.clamp(0.0, 1.0);
    switch (kind) {
      case TrapKind.scaled:
        // Amplitude large en début de test : pièce clairement trop petite.
        // Pour t < 0.5 on réduit TOUJOURS (jamais d'agrandissement), ce qui
        // évite d'augmenter le maxPieceExtent et de réduire les vraies pièces.
        // Pour t ≥ 0.5 (medium/hard) : les deux directions, amplitude subtile.
        final mag = _lerp(0.56, 0.12, t);
        final factor = t < 0.5
            ? 1.0 - mag
            : (_rng.nextBool() ? 1.0 + mag : 1.0 - mag);
        return TrapResult(
          source.transform(scale: factor),
          _transformRegions(sourceRegions, source.centroid(), scale: factor),
        );

      case TrapKind.mirrored:
        final m = source.transform(mirrored: true);
        if (congruent(m, source)) return null;
        return TrapResult(
          m,
          _transformRegions(sourceRegions, source.centroid(), mirrored: true),
        );

      case TrapKind.stretched:
        // Amplitude bien plus grande qu'avant : visible dès les items moyens.
        final mag = _lerp(0.78, 0.18, t);
        final fx = _rng.nextBool() ? 1 + mag : 1 / (1 + mag);
        // En mode subtil : étirement à aire constante (fy = 1/fx).
        final fy = t > 0.55 ? 1 / fx : 1.0;
        final swap = _rng.nextBool();
        final sx = swap ? fy : fx;
        final sy = swap ? fx : fy;
        final s = source.transform(scaleX: sx, scaleY: sy);
        if (congruent(s, source)) return null;
        return TrapResult(
          s,
          _transformRegions(sourceRegions, source.centroid(),
              scaleX: sx, scaleY: sy),
        );

      case TrapKind.alternativeCut:
        for (int attempt = 0; attempt < 6; attempt++) {
          final strategy =
              CutStrategy.values[_rng.nextInt(CutStrategy.values.length)];
          final pieces = _cutEngine.cut(target, strategy);
          if (pieces.length != 3) continue;
          final candidates = pieces.where((p) {
            if (p.vertices.length < 3) return false;
            for (final tp in truePieces) {
              if (congruent(p, tp, allowMirror: true)) return false;
            }
            if (t > 0.5) {
              final ratio = p.area() / math.max(source.area(), kGeomEps);
              if (ratio < 0.6 || ratio > 1.6) return false;
            }
            return true;
          }).toList();
          if (candidates.isNotEmpty) {
            final pick = candidates[_rng.nextInt(candidates.length)];
            // La pièce vit dans l'espace cible → elle hérite du motif réel.
            return TrapResult(pick, clipToZones(pick, zones));
          }
        }
        return null;

      case TrapKind.foreignShape:
        // Choisir une forme visuellement CONTRASTANTE avec la cible :
        // - courbe (cercle, demi-cercle) pour cible angulaire → arc évident
        // - angulaire simple pour cible courbe
        final shapes = _contrastingShapes(targetShape);
        final shape = shapes[_rng.nextInt(shapes.length)];
        final other = buildBaseShape(shape);
        // Coupes simples (bandes) pour items faciles → fragment reconnaissable.
        final strategy =
            t < 0.4 ? CutStrategy.twoParallel : CutStrategy.twoOblique;
        final pieces = _cutEngine.cut(other, strategy);
        if (pieces.length != 3) return null;
        final pick = pieces[_rng.nextInt(pieces.length)];
        if (pick.vertices.length < 3) return null;
        for (final tp in truePieces) {
          if (congruent(pick, tp, allowMirror: true)) return null;
        }
        return TrapResult(pick, _plausibleColoring(pick, paletteSize));

      case TrapKind.wrongColors:
        // Géométrie inchangée, couleurs permutées (décalage cyclique sans
        // point fixe → AUCUNE région ne garde sa couleur d'origine).
        //
        // GARDE-FOU anti-ambiguïté : l'histogramme aire-par-couleur doit
        // changer nettement. Une rotation préserve cet histogramme ; s'il
        // était inchangé (ex. pièce symétrique 50/50 aux couleurs échangées),
        // une rotation pourrait faire coïncider le piège avec la vraie pièce
        // → deux réponses valides. On refuse ces cas.
        if (paletteSize < 2 || sourceRegions.isEmpty) return null;
        final histo = <int, double>{};
        for (final r in sourceRegions) {
          histo[r.colorIndex] =
              (histo[r.colorIndex] ?? 0) + r.polygon.area();
        }
        final shifts = [for (int s = 1; s < paletteSize; s++) s]
          ..shuffle(_rng);
        for (final shift in shifts) {
          final shifted = <int, double>{};
          histo.forEach(
              (k, v) => shifted[(k + shift) % paletteSize] = v);
          double diff = 0, total = 0;
          for (final k in {...histo.keys, ...shifted.keys}) {
            diff += ((histo[k] ?? 0) - (shifted[k] ?? 0)).abs();
            total += (histo[k] ?? 0) + (shifted[k] ?? 0);
          }
          if (total > kGeomEps && diff / total > 0.10) {
            return TrapResult(
              source,
              sourceRegions
                  .map((r) => ColoredRegion(
                      r.polygon, (r.colorIndex + shift) % paletteSize))
                  .toList(),
            );
          }
        }
        return null;
    }
  }

  // ---------- Couleurs ----------

  /// Applique aux régions la MÊME transformation que la pièce entière
  /// (pivot = centroïde de la pièce source, pas celui de chaque région).
  List<ColoredRegion> _transformRegions(
    List<ColoredRegion> regions,
    Offset center, {
    double scale = 1.0,
    double scaleX = 1.0,
    double scaleY = 1.0,
    bool mirrored = false,
  }) {
    return regions
        .map((r) => ColoredRegion(
              r.polygon.transform(
                scale: scale,
                scaleX: scaleX,
                scaleY: scaleY,
                mirrored: mirrored,
                center: center,
              ),
              r.colorIndex,
            ))
        .toList();
  }

  /// Coloration plausible d'une pièce étrangère : même palette que l'item,
  /// motif bicolore (coupe oblique aléatoire) ou uni si item monochrome.
  List<ColoredRegion> _plausibleColoring(Polygon piece, int paletteSize) {
    if (paletteSize < 2) return [ColoredRegion(piece, 0)];
    final c1 = _rng.nextInt(paletteSize);
    // Une chance sur trois : pièce unie (existe aussi dans les vrais items).
    if (_rng.nextInt(3) == 0) return [ColoredRegion(piece, c1)];
    var c2 = _rng.nextInt(paletteSize - 1);
    if (c2 >= c1) c2++;
    final centroid = piece.centroid();
    final ang = _rng.nextDouble() * math.pi;
    final d = Offset(math.cos(ang), math.sin(ang));
    final parts =
        cutPolygonByLine(piece, CutLine(centroid - d * 3, centroid + d * 3));
    if (parts[0].vertices.length < 3 || parts[1].vertices.length < 3) {
      return [ColoredRegion(piece, c1)];
    }
    return [ColoredRegion(parts[0], c1), ColoredRegion(parts[1], c2)];
  }

  // ---------- Shapes contrastantes ----------

  /// Renvoie les formes de base qui contrastent visuellement avec [target].
  ///
  /// Logique :
  /// - cible angulaire simple (≤6 sommets) → préférer formes COURBES
  /// - cible courbe (cercle/demi-cercle) → préférer formes angulaires
  /// - cible complexe (maison, polygones ≥5 côtés) → préférer rectangulaires
  List<BaseShape> _contrastingShapes(BaseShape? target) {
    const curved = [BaseShape.circle, BaseShape.semicircle];
    const simpleAngular = [
      BaseShape.square,
      BaseShape.rectangleWide,
      BaseShape.rectangleTall,
      BaseShape.triangleEq,
      BaseShape.triangleRight,
      BaseShape.diamond,
    ];
    const complex = [
      BaseShape.trapezoid,
      BaseShape.parallelogram,
      BaseShape.house,
      BaseShape.pentagon,
      BaseShape.hexagon,
      BaseShape.octagon,
    ];

    if (target == null) return [...curved, ...simpleAngular];

    if (curved.contains(target)) return simpleAngular;
    if (simpleAngular.contains(target)) return [...curved, ...complex];
    // Complex target → prefer simple angular for obvious contrast
    return [...simpleAngular, ...curved];
  }
}
