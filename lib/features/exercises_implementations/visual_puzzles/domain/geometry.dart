import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Tolérance pour les comparaisons flottantes en géométrie.
const double kGeomEps = 1e-6;

/// Polygone simple (non auto-intersectant), sommets en coords normalisées
/// [0,1] × [0,1].
@immutable
class Polygon {
  const Polygon(this.vertices);
  final List<Offset> vertices;

  /// Aire signée (positive si CCW, négative si CW) — formule du lacet de Gauss.
  double signedArea() {
    if (vertices.length < 3) return 0;
    double a = 0;
    for (int i = 0; i < vertices.length; i++) {
      final p1 = vertices[i];
      final p2 = vertices[(i + 1) % vertices.length];
      a += (p1.dx * p2.dy) - (p2.dx * p1.dy);
    }
    return a / 2;
  }

  double area() => signedArea().abs();

  Offset centroid() {
    if (vertices.isEmpty) return Offset.zero;
    double sx = 0, sy = 0;
    for (final v in vertices) {
      sx += v.dx;
      sy += v.dy;
    }
    return Offset(sx / vertices.length, sy / vertices.length);
  }

  Rect bbox() {
    if (vertices.isEmpty) return Rect.zero;
    double minX = vertices[0].dx, minY = vertices[0].dy;
    double maxX = vertices[0].dx, maxY = vertices[0].dy;
    for (final v in vertices) {
      if (v.dx < minX) minX = v.dx;
      if (v.dy < minY) minY = v.dy;
      if (v.dx > maxX) maxX = v.dx;
      if (v.dy > maxY) maxY = v.dy;
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  bool contains(Offset p) {
    bool inside = false;
    int j = vertices.length - 1;
    for (int i = 0; i < vertices.length; i++) {
      final a = vertices[i];
      final b = vertices[j];
      if ((a.dy > p.dy) != (b.dy > p.dy)) {
        final xCross = (b.dx - a.dx) * (p.dy - a.dy) / (b.dy - a.dy) + a.dx;
        if (p.dx < xCross) inside = !inside;
      }
      j = i;
    }
    return inside;
  }

  Polygon transform({
    double rotationDeg = 0,
    bool mirrored = false,
    double scale = 1.0,
    Offset translation = Offset.zero,
  }) {
    final c = centroid();
    final rad = rotationDeg * math.pi / 180;
    final cosR = math.cos(rad);
    final sinR = math.sin(rad);
    final mx = mirrored ? -1.0 : 1.0;
    final newVerts = <Offset>[];
    for (final v in vertices) {
      var x = (v.dx - c.dx) * mx;
      var y = v.dy - c.dy;
      final rx = x * cosR - y * sinR;
      final ry = x * sinR + y * cosR;
      final sx = rx * scale;
      final sy = ry * scale;
      newVerts.add(Offset(sx + c.dx + translation.dx, sy + c.dy + translation.dy));
    }
    return Polygon(newVerts);
  }

  Polygon withVertexNudged(int index, double dx, double dy) {
    final newVerts = List<Offset>.from(vertices);
    final v = newVerts[index];
    newVerts[index] = Offset(v.dx + dx, v.dy + dy);
    return Polygon(newVerts);
  }
}

@immutable
class CutLine {
  const CutLine(this.a, this.b);
  final Offset a;
  final Offset b;

  double sideOf(Offset p) =>
      (b.dx - a.dx) * (p.dy - a.dy) - (b.dy - a.dy) * (p.dx - a.dx);

  Offset? intersectSegment(Offset p1, Offset p2) {
    final d1 = sideOf(p1);
    final d2 = sideOf(p2);
    if ((d1 > kGeomEps && d2 > kGeomEps) || (d1 < -kGeomEps && d2 < -kGeomEps)) {
      return null;
    }
    if (d1.abs() < kGeomEps && d2.abs() < kGeomEps) return null;
    final t = d1 / (d1 - d2);
    return Offset(p1.dx + t * (p2.dx - p1.dx), p1.dy + t * (p2.dy - p1.dy));
  }
}

/// Découpe un polygone par une ligne infinie, retourne 2 sous-polygones.
List<Polygon> cutPolygonByLine(Polygon poly, CutLine line) {
  final pos = <Offset>[];
  final neg = <Offset>[];
  final n = poly.vertices.length;
  if (n < 3) return [poly, const Polygon([])];

  for (int i = 0; i < n; i++) {
    final cur = poly.vertices[i];
    final next = poly.vertices[(i + 1) % n];
    final sCur = line.sideOf(cur);
    final sNext = line.sideOf(next);

    if (sCur >= -kGeomEps) pos.add(cur);
    if (sCur <= kGeomEps) neg.add(cur);

    if ((sCur > kGeomEps && sNext < -kGeomEps) ||
        (sCur < -kGeomEps && sNext > kGeomEps)) {
      final p = line.intersectSegment(cur, next);
      if (p != null) {
        pos.add(p);
        neg.add(p);
      }
    }
  }
  return [Polygon(pos), Polygon(neg)];
}

/// Vérifie que `pieces` reconstituent `target` (somme des aires + non-overlap).
bool isReconstruction(List<Polygon> pieces, Polygon target,
    {double areaTolerance = 0.05}) {
  if (pieces.length != 3) return false;
  for (final p in pieces) {
    if (p.vertices.length < 3) return false;
  }
  final targetA = target.area();
  if (targetA < kGeomEps) return false;
  double sum = 0;
  for (final p in pieces) {
    sum += p.area();
  }
  if ((sum - targetA).abs() / targetA > areaTolerance) return false;

  for (int i = 0; i < pieces.length; i++) {
    final ci = pieces[i].centroid();
    for (int j = 0; j < pieces.length; j++) {
      if (i == j) continue;
      if (pieces[j].contains(ci)) return false;
    }
  }
  return true;
}
