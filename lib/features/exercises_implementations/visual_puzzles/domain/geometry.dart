import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Tolérance pour les comparaisons flottantes en géométrie.
const double kGeomEps = 1e-6;

/// Polygone simple (non auto-intersectant) défini par sa liste de sommets
/// dans l'ordre — anti-horaire ou horaire — dans un repère normalisé
/// [0,1] × [0,1].
///
/// Les opérations garantissent qu'un polygone simple en entrée produit
/// des polygones simples en sortie.
@immutable
class Polygon {
  const Polygon(this.vertices);
  final List<Offset> vertices;

  /// Aire signée (positive si CCW, négative si CW) — formule du lacet de
  /// Gauss (Shoelace).
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

  /// Aire absolue.
  double area() => signedArea().abs();

  /// Centroïde (barycentre des sommets).
  Offset centroid() {
    if (vertices.isEmpty) return Offset.zero;
    double sx = 0, sy = 0;
    for (final v in vertices) {
      sx += v.dx;
      sy += v.dy;
    }
    return Offset(sx / vertices.length, sy / vertices.length);
  }

  /// Bounding box du polygone.
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

  /// Test inclusion d'un point dans le polygone (ray casting).
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

  /// Polygone transformé (rotation + scale + translation autour du centroïde).
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
      // Centre autour du centroïde
      var x = (v.dx - c.dx) * mx;
      var y = v.dy - c.dy;
      // Rotation
      final rx = x * cosR - y * sinR;
      final ry = x * sinR + y * cosR;
      // Scale
      final sx = rx * scale;
      final sy = ry * scale;
      // Retour à l'origine + translation
      newVerts.add(Offset(sx + c.dx + translation.dx, sy + c.dy + translation.dy));
    }
    return Polygon(newVerts);
  }

  /// Décale légèrement un vertex spécifique (pour pièges subtils).
  Polygon withVertexNudged(int index, double dx, double dy) {
    final newVerts = List<Offset>.from(vertices);
    final v = newVerts[index];
    newVerts[index] = Offset(v.dx + dx, v.dy + dy);
    return Polygon(newVerts);
  }
}

// ============================================================
// COUPE D'UN POLYGONE PAR UNE LIGNE INFINIE
// ============================================================

/// Une ligne infinie passant par 2 points (a et b).
@immutable
class CutLine {
  const CutLine(this.a, this.b);
  final Offset a;
  final Offset b;

  /// Signe : positif d'un côté de la ligne, négatif de l'autre, 0 sur la ligne.
  double sideOf(Offset p) {
    return (b.dx - a.dx) * (p.dy - a.dy) - (b.dy - a.dy) * (p.dx - a.dx);
  }

  /// Calcule l'intersection entre cette ligne et le segment (p1, p2).
  /// Retourne null si pas d'intersection dans le segment.
  Offset? intersectSegment(Offset p1, Offset p2) {
    final d1 = sideOf(p1);
    final d2 = sideOf(p2);
    // Pas de changement de signe → pas d'intersection
    if ((d1 > kGeomEps && d2 > kGeomEps) || (d1 < -kGeomEps && d2 < -kGeomEps)) {
      return null;
    }
    if (d1.abs() < kGeomEps && d2.abs() < kGeomEps) return null; // colinéaire
    final t = d1 / (d1 - d2);
    return Offset(p1.dx + t * (p2.dx - p1.dx), p1.dy + t * (p2.dy - p1.dy));
  }
}

/// Découpe un polygone simple par une ligne, retourne 2 polygones (left, right).
/// Si la ligne ne traverse pas le polygone, retourne [polygon, Polygon([])].
///
/// Algorithme : on parcourt les arêtes ; chaque vertex est assigné au côté
/// "positif" ou "négatif" selon `CutLine.sideOf`. À chaque changement de
/// signe on insère le point d'intersection dans LES DEUX sous-polygones.
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

    // Si changement de signe strict, ajoute l'intersection aux deux
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

// ============================================================
// VALIDATION : 3 pièces reconstituent la cible ?
// ============================================================

/// Vérifie que la somme des aires des `pieces` ≈ aire de `target`, et que
/// les pièces ne se chevauchent pas (en bouding box approximée + check
/// centroïde dans une autre pièce).
///
/// **Précondition** : les pièces sont issues d'un découpage de la cible.
/// Cette fonction sert de garde-fou côté tests pour s'assurer que les
/// algorithmes de découpe sont corrects.
bool isReconstruction(List<Polygon> pieces, Polygon target,
    {double areaTolerance = 0.005}) {
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
  final relError = (sum - targetA).abs() / targetA;
  if (relError > areaTolerance) return false;

  // Pas de chevauchement : le centroïde d'une pièce ne doit pas être dans
  // l'intérieur strict d'une autre (à epsilon près sur la frontière).
  for (int i = 0; i < pieces.length; i++) {
    final ci = pieces[i].centroid();
    for (int j = 0; j < pieces.length; j++) {
      if (i == j) continue;
      if (pieces[j].contains(ci)) {
        // Centroïde de i dans j → chevauchement suspect
        return false;
      }
    }
  }
  return true;
}
