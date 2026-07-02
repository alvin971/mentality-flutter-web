import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'geometry.dart';

/// Stratégies de découpe ordonnées par complexité visuelle.
enum CutStrategy {
  twoParallel, // 2 coupes parallèles (bandes)
  perpendicularL, // 1 coupe + 1 coupe perpendiculaire sur le grand morceau
  oneStraightOneOblique, // 1 droite + 1 oblique
  twoOblique, // 2 obliques
  fan, // 2 lignes passant près du centre (3 secteurs)
}

/// Découpe un polygone convexe en exactement 3 morceaux équilibrés.
///
/// Garanties :
/// - aucun morceau < `minShare` de l'aire totale (pas d'éclats) ;
/// - aucun morceau "aiguille" (bbox trop fine) ;
/// - fallback déterministe par bisection d'aire si les tirages échouent.
class CutEngine {
  CutEngine({math.Random? rng}) : _rng = rng ?? math.Random();
  final math.Random _rng;

  static const double minShare = 0.14;

  List<Polygon> cut(Polygon base, CutStrategy strategy) {
    for (int attempt = 0; attempt < 24; attempt++) {
      final r = _tryCut(base, strategy);
      if (r != null && _isBalanced(r, base)) {
        return r.map((p) => p.cleaned()).toList();
      }
    }
    return _fallbackBands(base);
  }

  bool _isBalanced(List<Polygon> pieces, Polygon base) {
    if (!isReconstruction(pieces, base,
        areaTolerance: 0.03, minAreaShare: minShare)) {
      return false;
    }
    final baseBb = base.bbox();
    final refDim = math.max(baseBb.width, baseBb.height);
    for (final p in pieces) {
      final bb = p.bbox();
      // Pas de pièce "aiguille" : sa plus petite dimension doit rester
      // lisible, y compris sur une case mobile (~70 px → 0.16 ≈ 11 px).
      if (math.min(bb.width, bb.height) < 0.16 * refDim) return false;
    }
    return true;
  }

  List<Polygon>? _tryCut(Polygon base, CutStrategy strategy) =>
      switch (strategy) {
        CutStrategy.twoParallel => _twoParallel(base),
        CutStrategy.perpendicularL => _perpendicularL(base),
        CutStrategy.oneStraightOneOblique => _oneStraightOneOblique(base),
        CutStrategy.twoOblique => _twoOblique(base),
        CutStrategy.fan => _fan(base),
      };

  // ---------- Coupes par fraction d'AIRE (jamais de slivers) ----------

  /// Trouve par bisection la ligne perpendiculaire à `axis` (0 = verticale,
  /// 1 = horizontale) telle que la fraction d'aire à gauche/en haut ≈ `frac`.
  CutLine _areaSplitLine(Polygon poly, int axis, double frac) {
    final bb = poly.bbox();
    double lo = axis == 0 ? bb.left : bb.top;
    double hi = axis == 0 ? bb.right : bb.bottom;
    final total = poly.area();
    for (int i = 0; i < 28; i++) {
      final mid = (lo + hi) / 2;
      final line = _axisLine(bb, axis, mid);
      final parts = cutPolygonByLine(poly, line);
      // Avec nos lignes orientées, parts[0] = côté gauche (axis 0) / haut
      // (axis 1) ; son aire CROÎT avec `mid` → bisection monotone.
      final firstArea =
          parts[0].vertices.length >= 3 ? parts[0].area() : 0.0;
      if (firstArea / total < frac) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return _axisLine(bb, axis, (lo + hi) / 2);
  }

  CutLine _axisLine(Rect bb, int axis, double pos) => axis == 0
      ? CutLine(Offset(pos, bb.top - 1), Offset(pos, bb.bottom + 1))
      : CutLine(Offset(bb.right + 1, pos), Offset(bb.left - 1, pos));

  (Polygon, Polygon)? _splitByAreaFrac(Polygon poly, int axis, double frac) {
    final line = _areaSplitLine(poly, axis, frac);
    final parts = cutPolygonByLine(poly, line);
    if (parts[0].vertices.length < 3 || parts[1].vertices.length < 3) {
      return null;
    }
    return (parts[0], parts[1]); // (côté demandé ≈ frac, reste)
  }

  // ---------- Stratégies ----------

  List<Polygon>? _twoParallel(Polygon base) {
    final axis = _rng.nextInt(2);
    final f1 = 0.26 + _rng.nextDouble() * 0.14; // 1er morceau : 26-40 %
    final s1 = _splitByAreaFrac(base, axis, f1);
    if (s1 == null) return null;
    final (first, rest) = s1;
    final f2 = 0.42 + _rng.nextDouble() * 0.16; // partage du reste : 42-58 %
    final s2 = _splitByAreaFrac(rest, axis, f2);
    if (s2 == null) return null;
    return [first, s2.$1, s2.$2];
  }

  List<Polygon>? _perpendicularL(Polygon base) {
    final axis = _rng.nextInt(2);
    final f1 = 0.30 + _rng.nextDouble() * 0.15;
    final s1 = _splitByAreaFrac(base, axis, f1);
    if (s1 == null) return null;
    final (first, rest) = s1;
    final f2 = 0.40 + _rng.nextDouble() * 0.20;
    final s2 = _splitByAreaFrac(rest, 1 - axis, f2);
    if (s2 == null) return null;
    return [first, s2.$1, s2.$2];
  }

  List<Polygon>? _oneStraightOneOblique(Polygon base) {
    final axis = _rng.nextInt(2);
    final f1 = 0.30 + _rng.nextDouble() * 0.15;
    final s1 = _splitByAreaFrac(base, axis, f1);
    if (s1 == null) return null;
    final (first, rest) = s1;
    final cut2 = _obliqueThroughCentroid(rest, maxTiltDeg: 40);
    if (cut2 == null) return null;
    return [first, cut2.$1, cut2.$2];
  }

  List<Polygon>? _twoOblique(Polygon base) {
    final cut1 = _obliqueThroughCentroid(base,
        maxTiltDeg: 50, offsetScale: 0.22, keepFracMin: 0.28);
    if (cut1 == null) return null;
    final (a, b) = cut1;
    final small = a.area() < b.area() ? a : b;
    final big = a.area() < b.area() ? b : a;
    final cut2 = _obliqueThroughCentroid(big, maxTiltDeg: 60);
    if (cut2 == null) return null;
    return [small, cut2.$1, cut2.$2];
  }

  /// 2 lignes sécantes près du centre → 3 morceaux en éventail.
  List<Polygon>? _fan(Polygon base) {
    final c = base.centroid();
    final bb = base.bbox();
    final jitter = Offset(
      (_rng.nextDouble() - 0.5) * bb.width * 0.12,
      (_rng.nextDouble() - 0.5) * bb.height * 0.12,
    );
    final o = c + jitter;
    final a1 = _rng.nextDouble() * math.pi;
    final a2 = a1 + math.pi / 3 + _rng.nextDouble() * math.pi / 3;
    final l1 = _lineThrough(o, a1);
    final l2 = _lineThrough(o, a2);
    final p1 = cutPolygonByLine(base, l1);
    if (p1[0].vertices.length < 3 || p1[1].vertices.length < 3) return null;
    final small = p1[0].area() < p1[1].area() ? p1[0] : p1[1];
    final big = p1[0].area() < p1[1].area() ? p1[1] : p1[0];
    final p2 = cutPolygonByLine(big, l2);
    if (p2[0].vertices.length < 3 || p2[1].vertices.length < 3) return null;
    return [small, p2[0], p2[1]];
  }

  // ---------- Helpers obliques ----------

  (Polygon, Polygon)? _obliqueThroughCentroid(Polygon poly,
      {double maxTiltDeg = 45,
      double offsetScale = 0.18,
      double keepFracMin = 0.30}) {
    final c = poly.centroid();
    final bb = poly.bbox();
    final ang = _rng.nextDouble() * math.pi;
    final tilt = (ang % math.pi);
    // Évite les lignes quasi confondues avec un côté très court : peu importe,
    // la validation d'équilibre filtre. On jitter l'origine autour du centroïde.
    final o = c +
        Offset(
          (_rng.nextDouble() - 0.5) * bb.width * offsetScale,
          (_rng.nextDouble() - 0.5) * bb.height * offsetScale,
        );
    final line = _lineThrough(o, tilt.clamp(0, math.pi));
    final parts = cutPolygonByLine(poly, line);
    if (parts[0].vertices.length < 3 || parts[1].vertices.length < 3) {
      return null;
    }
    final total = poly.area();
    final fracSmall =
        math.min(parts[0].area(), parts[1].area()) / math.max(total, kGeomEps);
    if (fracSmall < keepFracMin) return null;
    return (parts[0], parts[1]);
  }

  CutLine _lineThrough(Offset o, double angle) {
    final d = Offset(math.cos(angle), math.sin(angle));
    return CutLine(o - d * 3, o + d * 3);
  }

  // ---------- Fallback déterministe ----------

  List<Polygon> _fallbackBands(Polygon base) {
    final s1 = _splitByAreaFrac(base, 0, 1 / 3);
    if (s1 == null) return [base, const Polygon([]), const Polygon([])];
    final s2 = _splitByAreaFrac(s1.$2, 0, 0.5);
    if (s2 == null) return [s1.$1, s1.$2, const Polygon([])];
    return [s1.$1, s2.$1, s2.$2];
  }
}
