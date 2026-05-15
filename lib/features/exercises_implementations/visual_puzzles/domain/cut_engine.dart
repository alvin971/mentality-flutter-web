import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'geometry.dart';

/// Stratégies de découpe ordonnées par complexité.
enum CutStrategy {
  twoParallelStraight,
  perpendicularL,
  oneStraightOneOblique,
  twoOblique,
  threeFromCenter,
}

/// Découpe un polygone en exactement 3 sous-polygones.
class CutEngine {
  CutEngine({math.Random? rng}) : _rng = rng ?? math.Random();
  final math.Random _rng;

  List<Polygon> cut(Polygon base, CutStrategy strategy) {
    for (int attempt = 0; attempt < 8; attempt++) {
      final r = _tryCut(base, strategy);
      if (r != null) return r;
    }
    return _fallbackThreeBands(base);
  }

  List<Polygon>? _tryCut(Polygon base, CutStrategy strategy) => switch (strategy) {
        CutStrategy.twoParallelStraight => _twoParallelStraight(base),
        CutStrategy.perpendicularL => _perpendicularL(base),
        CutStrategy.oneStraightOneOblique => _oneStraightOneOblique(base),
        CutStrategy.twoOblique => _twoOblique(base),
        CutStrategy.threeFromCenter => _threeFromCenter(base),
      };

  List<Polygon>? _twoParallelStraight(Polygon base) {
    final bb = base.bbox();
    final vertical = _rng.nextBool();
    final t1 = 0.20 + _rng.nextDouble() * 0.20;
    final t2 = 0.55 + _rng.nextDouble() * 0.25;
    CutLine line1, line2;
    if (vertical) {
      final x1 = bb.left + bb.width * t1;
      final x2 = bb.left + bb.width * t2;
      line1 = CutLine(Offset(x1, bb.top - 1), Offset(x1, bb.bottom + 1));
      line2 = CutLine(Offset(x2, bb.top - 1), Offset(x2, bb.bottom + 1));
    } else {
      final y1 = bb.top + bb.height * t1;
      final y2 = bb.top + bb.height * t2;
      line1 = CutLine(Offset(bb.left - 1, y1), Offset(bb.right + 1, y1));
      line2 = CutLine(Offset(bb.left - 1, y2), Offset(bb.right + 1, y2));
    }
    final a1 = cutPolygonByLine(base, line1);
    if (a1[0].vertices.length < 3 || a1[1].vertices.length < 3) return null;
    final big = a1[0].area() > a1[1].area() ? a1[0] : a1[1];
    final small1 = big == a1[0] ? a1[1] : a1[0];
    final a2 = cutPolygonByLine(big, line2);
    if (a2[0].vertices.length < 3 || a2[1].vertices.length < 3) return null;
    return [small1, a2[0], a2[1]];
  }

  List<Polygon>? _perpendicularL(Polygon base) {
    final bb = base.bbox();
    final firstVertical = _rng.nextBool();
    final t1 = 0.35 + _rng.nextDouble() * 0.30;
    CutLine line1;
    if (firstVertical) {
      final x = bb.left + bb.width * t1;
      line1 = CutLine(Offset(x, bb.top - 1), Offset(x, bb.bottom + 1));
    } else {
      final y = bb.top + bb.height * t1;
      line1 = CutLine(Offset(bb.left - 1, y), Offset(bb.right + 1, y));
    }
    final a1 = cutPolygonByLine(base, line1);
    if (a1[0].vertices.length < 3 || a1[1].vertices.length < 3) return null;
    final big = a1[0].area() > a1[1].area() ? a1[0] : a1[1];
    final small = big == a1[0] ? a1[1] : a1[0];
    final bigBb = big.bbox();
    final t2 = 0.35 + _rng.nextDouble() * 0.30;
    CutLine line2;
    if (firstVertical) {
      final y = bigBb.top + bigBb.height * t2;
      line2 = CutLine(Offset(bigBb.left - 1, y), Offset(bigBb.right + 1, y));
    } else {
      final x = bigBb.left + bigBb.width * t2;
      line2 = CutLine(Offset(x, bigBb.top - 1), Offset(x, bigBb.bottom + 1));
    }
    final a2 = cutPolygonByLine(big, line2);
    if (a2[0].vertices.length < 3 || a2[1].vertices.length < 3) return null;
    return [small, a2[0], a2[1]];
  }

  List<Polygon>? _oneStraightOneOblique(Polygon base) {
    final bb = base.bbox();
    final t = 0.35 + _rng.nextDouble() * 0.30;
    final y = bb.top + bb.height * t;
    final line1 = CutLine(Offset(bb.left - 1, y), Offset(bb.right + 1, y));
    final a1 = cutPolygonByLine(base, line1);
    if (a1[0].vertices.length < 3 || a1[1].vertices.length < 3) return null;
    final big = a1[0].area() > a1[1].area() ? a1[0] : a1[1];
    final small = big == a1[0] ? a1[1] : a1[0];
    final bigBb = big.bbox();
    final angle = (math.pi / 6) * (_rng.nextBool() ? 1 : -1);
    final cx = bigBb.center.dx;
    final cy = bigBb.center.dy;
    final dx = math.cos(angle);
    final dy = math.sin(angle);
    final line2 = CutLine(
      Offset(cx - dx * 2, cy - dy * 2),
      Offset(cx + dx * 2, cy + dy * 2),
    );
    final a2 = cutPolygonByLine(big, line2);
    if (a2[0].vertices.length < 3 || a2[1].vertices.length < 3) return null;
    return [small, a2[0], a2[1]];
  }

  List<Polygon>? _twoOblique(Polygon base) {
    final bb = base.bbox();
    final cx = bb.center.dx;
    final cy = bb.center.dy;
    final ang1 = (math.pi / 8) + _rng.nextDouble() * (math.pi / 5);
    final ang2 = ang1 + math.pi / 2 + (_rng.nextDouble() - 0.5) * (math.pi / 6);
    final ox = cx + (_rng.nextDouble() - 0.5) * bb.width * 0.15;
    final oy = cy + (_rng.nextDouble() - 0.5) * bb.height * 0.15;
    final dx1 = math.cos(ang1);
    final dy1 = math.sin(ang1);
    final dx2 = math.cos(ang2);
    final dy2 = math.sin(ang2);
    final line1 = CutLine(Offset(ox - dx1 * 2, oy - dy1 * 2), Offset(ox + dx1 * 2, oy + dy1 * 2));
    final line2 = CutLine(Offset(ox - dx2 * 2, oy - dy2 * 2), Offset(ox + dx2 * 2, oy + dy2 * 2));
    final a1 = cutPolygonByLine(base, line1);
    if (a1[0].vertices.length < 3 || a1[1].vertices.length < 3) return null;
    final big = a1[0].area() > a1[1].area() ? a1[0] : a1[1];
    final small = big == a1[0] ? a1[1] : a1[0];
    final a2 = cutPolygonByLine(big, line2);
    if (a2[0].vertices.length < 3 || a2[1].vertices.length < 3) return null;
    return [small, a2[0], a2[1]];
  }

  /// 3 traits qui partent du centre vers le bord (étoile à 3 branches),
  /// produit 3 secteurs.
  List<Polygon>? _threeFromCenter(Polygon base) {
    final bb = base.bbox();
    final cx = bb.center.dx + (_rng.nextDouble() - 0.5) * bb.width * 0.1;
    final cy = bb.center.dy + (_rng.nextDouble() - 0.5) * bb.height * 0.1;
    final baseAng = _rng.nextDouble() * 2 * math.pi;
    // 3 lignes à 120° d'écart approximativement
    final ang1 = baseAng;
    final ang2 = baseAng + 2 * math.pi / 3 + (_rng.nextDouble() - 0.5) * 0.3;
    // line1: passe par centre, direction ang1
    final dir1 = Offset(math.cos(ang1), math.sin(ang1));
    final dir2 = Offset(math.cos(ang2), math.sin(ang2));
    final line1 = CutLine(
      Offset(cx - dir1.dx * 2, cy - dir1.dy * 2),
      Offset(cx + dir1.dx * 2, cy + dir1.dy * 2),
    );
    final a1 = cutPolygonByLine(base, line1);
    if (a1[0].vertices.length < 3 || a1[1].vertices.length < 3) return null;
    final big = a1[0].area() > a1[1].area() ? a1[0] : a1[1];
    final small = big == a1[0] ? a1[1] : a1[0];
    final line2 = CutLine(
      Offset(cx - dir2.dx * 2, cy - dir2.dy * 2),
      Offset(cx + dir2.dx * 2, cy + dir2.dy * 2),
    );
    final a2 = cutPolygonByLine(big, line2);
    if (a2[0].vertices.length < 3 || a2[1].vertices.length < 3) return null;
    return [small, a2[0], a2[1]];
  }

  List<Polygon> _fallbackThreeBands(Polygon base) {
    final bb = base.bbox();
    final x1 = bb.left + bb.width / 3;
    final x2 = bb.left + bb.width * 2 / 3;
    final l1 = CutLine(Offset(x1, bb.top - 1), Offset(x1, bb.bottom + 1));
    final l2 = CutLine(Offset(x2, bb.top - 1), Offset(x2, bb.bottom + 1));
    final a1 = cutPolygonByLine(base, l1);
    final a2 = cutPolygonByLine(a1[0], l2);
    return [a1[1], a2[0], a2[1]];
  }
}
