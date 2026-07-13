import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'geometry.dart';

/// Stratégies de découpe ordonnées par complexité visuelle.
///
/// Depuis la refonte « cible carré unique » (2026-07), la découpe est le
/// radical principal de difficulté : les trois dernières stratégies servent
/// les paliers hauts (asymétrie des aires, cadre diagonal).
enum CutStrategy {
  twoParallel, // 2 coupes parallèles (bandes de largeurs distinctes)
  perpendicularL, // 1 coupe + 1 coupe perpendiculaire sur le grand morceau
  oneStraightOneOblique, // 1 droite + 1 oblique
  twoOblique, // 2 obliques
  fan, // 2 lignes passant près du centre (3 secteurs)
  twoObliqueSteep, // 2 obliques quasi parallèles → bande oblique + 2 chapeaux inégaux
  fanOffset, // éventail décentré → 3 secteurs d'aires très inégales
  nearDiagonal, // coupes quasi parallèles aux diagonales du carré
}

/// Découpe un polygone convexe en exactement 3 morceaux équilibrés.
///
/// Garanties :
/// - aucun morceau < `minShare` de l'aire totale (pas d'éclats) ;
/// - aucun morceau "aiguille" (bbox trop fine) ;
/// - fallback déterministe par bisection d'aire si les tirages échouent.
///
/// Note de conception (refonte carré 2026-07) : la stratégie « zigzag »
/// (1 droite + 1 oblique traversant les DEUX sous-pièces) a été écartée —
/// une droite infinie traversant les 2 sous-pièces produit 4 morceaux,
/// pas 3, ce qui viole l'invariant fondamental de l'exercice.
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
        CutStrategy.twoObliqueSteep => _twoObliqueSteep(base),
        CutStrategy.fanOffset => _fanOffset(base),
        CutStrategy.nearDiagonal => _nearDiagonal(base),
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
    // Largeurs explicitement DISTINCTES : écart relatif d'aire ≥ ~19 % entre
    // chaque paire de bandes — la porte de confusabilité (congruent /
    // perceptuallyIdentical) est à 2·kPerceptualTol = 16 % d'aire relative.
    // Plancher 0.24 : à subtilité minimale, le piège « scaled » réduit l'aire
    // à ×0.213 — la pièce piège doit rester > 5 % de la cible (0.24·0.213).
    final wSmall = 0.24 + _rng.nextDouble() * 0.02; // 0.24-0.26
    final wMid = 0.31 + _rng.nextDouble() * 0.02; // 0.31-0.33
    final widths = [wSmall, wMid, 1.0 - wSmall - wMid] // grande : 0.41-0.45
      ..shuffle(_rng); // la position de chaque bande varie
    final s1 = _splitByAreaFrac(base, axis, widths[0]);
    if (s1 == null) return null;
    final s2 =
        _splitByAreaFrac(s1.$2, axis, widths[1] / (widths[1] + widths[2]));
    if (s2 == null) return null;
    return [s1.$1, s2.$1, s2.$2];
  }

  List<Polygon>? _perpendicularL(Polygon base) {
    final axis = _rng.nextInt(2);
    final f1 = 0.30 + _rng.nextDouble() * 0.15;
    final s1 = _splitByAreaFrac(base, axis, f1);
    if (s1 == null) return null;
    final (first, rest) = s1;
    // Jamais de f2 dans [0.44, 0.56] : les deux morceaux de la 2e coupe
    // doivent différer d'au moins ~21 % d'aire relative (garde de
    // discernabilité des vraies pièces). Plancher 0.36 : la plus petite
    // pièce (1−f1max)·f2min ≈ 0.198 doit survivre au piège « scaled »
    // (aire ×0.279 à subtilité 0.20) au-dessus de 5 % de la cible.
    final f2raw = 0.36 + _rng.nextDouble() * 0.08; // 0.36-0.44
    final f2 = _rng.nextBool() ? f2raw : 1.0 - f2raw;
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

  /// 2 obliques quasi parallèles (écart 10-18°) → bande oblique centrale +
  /// 2 chapeaux d'aires nettement inégales. Les pièces sont allongées et se
  /// ressemblent au premier regard, mais leurs aires diffèrent d'au moins
  /// ~25 % relatif (plages d'offsets disjointes de part et d'autre du centre).
  List<Polygon>? _twoObliqueSteep(Polygon base) {
    final c = base.centroid();
    final bb = base.bbox();
    final ref = math.max(bb.width, bb.height);
    // Angle commun jamais quasi-axial (20-70°), signe aléatoire.
    final a1 = (_rng.nextBool() ? 1 : -1) *
        (20 + _rng.nextDouble() * 50) *
        math.pi /
        180;
    final delta = (_rng.nextBool() ? 1 : -1) *
        (10 + _rng.nextDouble() * 8) *
        math.pi /
        180;
    final n = Offset(-math.sin(a1), math.cos(a1));
    final d1 = (0.14 + _rng.nextDouble() * 0.04) * ref;
    final d2 = -(0.26 + _rng.nextDouble() * 0.05) * ref;
    final p1 = cutPolygonByLine(base, _lineThrough(c + n * d1, a1));
    if (p1[0].vertices.length < 3 || p1[1].vertices.length < 3) return null;
    final (mid, cap1) = p1[0].contains(c) ? (p1[0], p1[1]) : (p1[1], p1[0]);
    final p2 = cutPolygonByLine(mid, _lineThrough(c + n * d2, a1 + delta));
    if (p2[0].vertices.length < 3 || p2[1].vertices.length < 3) return null;
    return [cap1, p2[0], p2[1]];
  }

  /// Éventail DÉCENTRÉ : moyeu déporté de 14-26 % de la bbox → 3 secteurs
  /// d'aires très inégales (mais ≥ minShare, garanti par la validation).
  /// Casse l'heuristique « la grosse pièce va au milieu » du fan centré.
  List<Polygon>? _fanOffset(Polygon base) {
    final c = base.centroid();
    final bb = base.bbox();
    final dir = _rng.nextDouble() * 2 * math.pi;
    final rho = 0.14 + _rng.nextDouble() * 0.12;
    final o = c +
        Offset(
          math.cos(dir) * bb.width * rho,
          math.sin(dir) * bb.height * rho,
        );
    final a1 = _rng.nextDouble() * math.pi;
    // Écart 55-85° : plafonné sous 90° pour éviter deux sous-secteurs
    // quasi congruents (cas symétrique).
    final a2 = a1 + (55 + _rng.nextDouble() * 30) * math.pi / 180;
    final p1 = cutPolygonByLine(base, _lineThrough(o, a1));
    if (p1[0].vertices.length < 3 || p1[1].vertices.length < 3) return null;
    final small = p1[0].area() < p1[1].area() ? p1[0] : p1[1];
    final big = p1[0].area() < p1[1].area() ? p1[1] : p1[0];
    final p2 = cutPolygonByLine(big, _lineThrough(o, a2));
    if (p2[0].vertices.length < 3 || p2[1].vertices.length < 3) return null;
    return [small, p2[0], p2[1]];
  }

  /// Coupes quasi parallèles aux DIAGONALES du carré (±6° de jitter) :
  /// les pièces perdent leurs angles droits (hors coins hérités du cadre) —
  /// plus d'indice « coin de carré » pour localiser une pièce. Deux modes :
  /// bande diagonale (2 coupes quasi parallèles à la même diagonale, offsets
  /// asymétriques) ou X décentré (diagonale + anti-diagonale, moyeu décalé
  /// LE LONG de la première pour déséquilibrer les deux sous-secteurs).
  List<Polygon>? _nearDiagonal(Polygon base) {
    final c = base.centroid();
    final bb = base.bbox();
    final ref = math.max(bb.width, bb.height);
    final theta0 = (_rng.nextBool() ? 45 : 135) * math.pi / 180;
    double jitter() => (_rng.nextDouble() - 0.5) * 12 * math.pi / 180;
    if (_rng.nextBool()) {
      // Mode BANDE : coins ≈ 0.30-0.37 et 0.17-0.24 d'aire (écart ≥ 21 %),
      // bande centrale ≥ 0.39.
      final n = Offset(-math.sin(theta0), math.cos(theta0));
      final d1 = (0.10 + _rng.nextDouble() * 0.06) * ref;
      final d2 = -(0.22 + _rng.nextDouble() * 0.08) * ref;
      final p1 =
          cutPolygonByLine(base, _lineThrough(c + n * d1, theta0 + jitter()));
      if (p1[0].vertices.length < 3 || p1[1].vertices.length < 3) return null;
      final (mid, coin1) = p1[0].contains(c) ? (p1[0], p1[1]) : (p1[1], p1[0]);
      final p2 =
          cutPolygonByLine(mid, _lineThrough(c + n * d2, theta0 + jitter()));
      if (p2[0].vertices.length < 3 || p2[1].vertices.length < 3) return null;
      return [coin1, p2[0], p2[1]];
    } else {
      // Mode X : l1 coupe ~50/50, le décalage du moyeu le long de l1
      // déséquilibre les deux sous-secteurs de l2 (écart ≥ ~35 %).
      final u = Offset(math.cos(theta0), math.sin(theta0));
      final n = Offset(-u.dy, u.dx);
      final s =
          (_rng.nextBool() ? 1 : -1) * (0.08 + _rng.nextDouble() * 0.08) * ref;
      final t = (_rng.nextDouble() - 0.5) * 0.10 * ref;
      final o = c + u * s + n * t;
      final p1 = cutPolygonByLine(base, _lineThrough(o, theta0 + jitter()));
      if (p1[0].vertices.length < 3 || p1[1].vertices.length < 3) return null;
      final small = p1[0].area() < p1[1].area() ? p1[0] : p1[1];
      final big = p1[0].area() < p1[1].area() ? p1[1] : p1[0];
      final p2 = cutPolygonByLine(
          big, _lineThrough(o, theta0 + math.pi / 2 + jitter()));
      if (p2[0].vertices.length < 3 || p2[1].vertices.length < 3) return null;
      return [small, p2[0], p2[1]];
    }
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
    // Parts 0.44 / 0.24 / 0.32 : écarts relatifs ≥ 25 % — le fallback doit
    // lui-même passer la garde « vraies pièces mutuellement discernables »
    // du générateur, sinon aucun recours ne resterait possible.
    final s1 = _splitByAreaFrac(base, 0, 0.44);
    if (s1 == null) return [base, const Polygon([]), const Polygon([])];
    final s2 = _splitByAreaFrac(s1.$2, 0, 0.24 / 0.56);
    if (s2 == null) return [s1.$1, s1.$2, const Polygon([])];
    return [s1.$1, s2.$1, s2.$2];
  }
}
