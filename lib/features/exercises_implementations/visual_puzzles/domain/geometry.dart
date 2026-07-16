import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Tolérance pour les comparaisons flottantes en géométrie.
const double kGeomEps = 1e-6;

/// Tolérance PERCEPTUELLE pour [congruent] : en dessous de cet écart relatif,
/// deux polygones sont indiscernables à l'œil nu sur une case d'option
/// (~70-150 px). Sert aux gardes anti-ambiguïté des distracteurs : un piège
/// « différent » de moins de 8 % d'une vraie pièce donnerait de fait deux
/// réponses visuellement valides (mesuré : 4,6 % des items avant garde).
const double kPerceptualTol = 0.08;

/// Seuil de distinctness ÉLARGI pour les items MONOCHROMES : sans couleur,
/// la géométrie doit discriminer seule. Calibré sur l'audit visuel
/// 2026-07-16 : les pièges alternativeCut « bande diagonale » des items 22
/// (seeds 1 et 7) devenaient quasi indécidables face à la vraie bande
/// (déclenchement mesuré à relTol 0.15–0.18 selon la paire).
const double kMonoDistinctTol = 0.18;

/// Polygone simple (non auto-intersectant), sommets en coords normalisées
/// [0,1] × [0,1].
@immutable
class Polygon {
  const Polygon(this.vertices);
  final List<Offset> vertices;

  /// Aire signée (positive si CCW en repère écran, négative sinon) —
  /// formule du lacet de Gauss.
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

  /// Centroïde pondéré par l'aire (et non moyenne des sommets — important
  /// pour les pièces à densité de sommets inégale, ex. secteurs de cercle).
  Offset centroid() {
    if (vertices.length < 3) {
      if (vertices.isEmpty) return Offset.zero;
      double sx = 0, sy = 0;
      for (final v in vertices) {
        sx += v.dx;
        sy += v.dy;
      }
      return Offset(sx / vertices.length, sy / vertices.length);
    }
    final a = signedArea();
    if (a.abs() < kGeomEps) {
      double sx = 0, sy = 0;
      for (final v in vertices) {
        sx += v.dx;
        sy += v.dy;
      }
      return Offset(sx / vertices.length, sy / vertices.length);
    }
    double cx = 0, cy = 0;
    for (int i = 0; i < vertices.length; i++) {
      final p1 = vertices[i];
      final p2 = vertices[(i + 1) % vertices.length];
      final cross = p1.dx * p2.dy - p2.dx * p1.dy;
      cx += (p1.dx + p2.dx) * cross;
      cy += (p1.dy + p2.dy) * cross;
    }
    return Offset(cx / (6 * a), cy / (6 * a));
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

  double perimeter() {
    double p = 0;
    for (int i = 0; i < vertices.length; i++) {
      p += (vertices[(i + 1) % vertices.length] - vertices[i]).distance;
    }
    return p;
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

  /// Transformation autour du centroïde (ou de [center] si fourni) :
  /// miroir (axe vertical), puis étirement (scaleX/scaleY), puis rotation,
  /// puis translation.
  ///
  /// [center] sert à transformer une RÉGION d'une pièce avec le même pivot
  /// que la pièce entière (sinon chaque région tournerait sur elle-même).
  Polygon transform({
    double rotationDeg = 0,
    bool mirrored = false,
    double scale = 1.0,
    double scaleX = 1.0,
    double scaleY = 1.0,
    Offset translation = Offset.zero,
    Offset? center,
  }) {
    final c = center ?? centroid();
    final rad = rotationDeg * math.pi / 180;
    final cosR = math.cos(rad);
    final sinR = math.sin(rad);
    final mx = mirrored ? -1.0 : 1.0;
    final newVerts = <Offset>[];
    for (final v in vertices) {
      var x = (v.dx - c.dx) * mx * scale * scaleX;
      var y = (v.dy - c.dy) * scale * scaleY;
      final rx = x * cosR - y * sinR;
      final ry = x * sinR + y * cosR;
      newVerts.add(Offset(rx + c.dx + translation.dx, ry + c.dy + translation.dy));
    }
    return Polygon(newVerts);
  }

  Polygon withVertexNudged(int index, double dx, double dy) {
    final newVerts = List<Offset>.from(vertices);
    final v = newVerts[index];
    newVerts[index] = Offset(v.dx + dx, v.dy + dy);
    return Polygon(newVerts);
  }

  /// Supprime les sommets dupliqués consécutifs et les sommets colinéaires
  /// (produits par les découpes). Indispensable avant un test de congruence.
  Polygon cleaned({double eps = 1e-5}) {
    if (vertices.length < 3) return this;
    // 1. Dédoublonnage consécutif
    final dedup = <Offset>[];
    for (final v in vertices) {
      if (dedup.isEmpty || (v - dedup.last).distance > eps) dedup.add(v);
    }
    if (dedup.length >= 2 && (dedup.first - dedup.last).distance <= eps) {
      dedup.removeLast();
    }
    if (dedup.length < 3) return Polygon(dedup);
    // 2. Suppression des colinéaires
    final out = <Offset>[];
    final n = dedup.length;
    for (int i = 0; i < n; i++) {
      final prev = dedup[(i - 1 + n) % n];
      final cur = dedup[i];
      final next = dedup[(i + 1) % n];
      final ab = cur - prev;
      final bc = next - cur;
      final cross = ab.dx * bc.dy - ab.dy * bc.dx;
      final lenScale = ab.distance * bc.distance;
      if (lenScale < eps * eps || cross.abs() / lenScale > 1e-3) {
        out.add(cur);
      }
    }
    return out.length >= 3 ? Polygon(out) : Polygon(dedup);
  }

  /// Retourne le polygone en orientation CCW (aire signée positive).
  Polygon ccw() =>
      signedArea() >= 0 ? this : Polygon(vertices.reversed.toList());
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

/// Découpe un polygone CONVEXE par une ligne infinie → 2 sous-polygones.
/// (Sur un polygone convexe, chaque moitié est garantie connexe et convexe.)
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
  return [Polygon(pos).cleaned(), Polygon(neg).cleaned()];
}

/// Région colorée : un sous-polygone + un index dans la palette de l'item.
///
/// Sert à deux choses :
/// - zones de couleur de la figure CIBLE (le "motif" du dessin) ;
/// - fragments de couleur portés par chaque pièce (une pièce peut être
///   bicolore si la frontière de couleur traverse sa découpe).
@immutable
class ColoredRegion {
  const ColoredRegion(this.polygon, this.colorIndex);
  final Polygon polygon;
  final int colorIndex;
}

/// Intersection de deux polygones CONVEXES (clipping de Sutherland-Hodgman :
/// on rogne `subject` successivement par chaque arête de `clip`).
Polygon intersectConvex(Polygon subject, Polygon clip) {
  if (subject.vertices.length < 3 || clip.vertices.length < 3) {
    return const Polygon([]);
  }
  final interior = clip.centroid();
  var cur = subject;
  final n = clip.vertices.length;
  for (int i = 0; i < n; i++) {
    if (cur.vertices.length < 3) return const Polygon([]);
    final line = CutLine(clip.vertices[i], clip.vertices[(i + 1) % n]);
    final parts = cutPolygonByLine(cur, line);
    cur = line.sideOf(interior) >= 0 ? parts[0] : parts[1];
  }
  return cur.cleaned();
}

/// Colorie une pièce en la découpant par les zones de couleur de la cible.
///
/// Chaque zone qui recouvre ≥ 2 % de l'aire de la pièce produit une région.
/// Si rien ne recouvre (pièce hors cible, ex. forme étrangère), la pièce
/// entière prend la couleur de la première zone.
List<ColoredRegion> clipToZones(Polygon piece, List<ColoredRegion> zones) {
  final out = <ColoredRegion>[];
  final pieceArea = piece.area();
  if (pieceArea < kGeomEps) return out;
  for (final z in zones) {
    final inter = intersectConvex(piece, z.polygon);
    if (inter.vertices.length >= 3 && inter.area() > pieceArea * 0.02) {
      out.add(ColoredRegion(inter, z.colorIndex));
    }
  }
  return out.isEmpty ? [ColoredRegion(piece, zones.first.colorIndex)] : out;
}

/// Vérifie que `pieces` reconstituent `target` :
/// somme des aires ≈ aire cible, centroïdes mutuellement hors des autres
/// pièces (non-chevauchement), aucune pièce dégénérée ni trop petite.
bool isReconstruction(List<Polygon> pieces, Polygon target,
    {double areaTolerance = 0.03, double minAreaShare = 0.10}) {
  if (pieces.length != 3) return false;
  final targetA = target.area();
  if (targetA < kGeomEps) return false;
  double sum = 0;
  for (final p in pieces) {
    if (p.vertices.length < 3) return false;
    final a = p.area();
    if (a / targetA < minAreaShare) return false;
    sum += a;
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

/// Congruence de deux polygones à ROTATION + TRANSLATION près
/// (et miroir si `allowMirror`).
///
/// Méthode : signature cyclique (longueurs d'arêtes, angles de rotation aux
/// sommets) comparée sur tous les décalages. Les polygones sont nettoyés et
/// normalisés CCW au préalable.
///
/// Sert à garantir qu'un distracteur n'est JAMAIS une vraie pièce déguisée :
/// si un piège était congruent à une vraie pièce, l'item aurait deux réponses
/// visuellement valides.
bool congruent(Polygon a, Polygon b,
    {bool allowMirror = false, double relTol = 0.02}) {
  final pa = a.cleaned().ccw();
  final pb = b.cleaned().ccw();
  final na = pa.vertices.length;
  final nb = pb.vertices.length;
  if (na < 3 || nb < 3 || na != nb) return false;

  final areaA = pa.area();
  final areaB = pb.area();
  final maxArea = math.max(areaA, areaB);
  if (maxArea < kGeomEps) return true;
  if ((areaA - areaB).abs() / maxArea > 2 * relTol) return false;

  final scaleRef = math.sqrt(maxArea);
  final lenTol = relTol * 2.5 * scaleRef;
  // Tolérance angulaire proportionnelle à relTol (3.0 × 0.02 = 0.06 rad
  // ≈ 3.4°, la valeur historique au relTol par défaut) : en mode perceptuel
  // (kPerceptualTol), deux pièces dont les angles diffèrent de < ~14° sont
  // aussi considérées congruentes.
  final angTol = 3.0 * relTol;

  final sigA = _signature(pa);
  final sigB = _signature(pb);

  if (_cyclicMatch(sigA, sigB, lenTol, angTol)) return true;
  if (allowMirror) {
    final mirrored = pb.transform(mirrored: true).ccw();
    if (_cyclicMatch(sigA, _signature(mirrored), lenTol, angTol)) return true;
  }
  return false;
}

/// Quasi-identité PERCEPTUELLE de deux polygones à rotation + translation
/// près (et miroir si [allowMirror]), INSENSIBLE au nombre de sommets.
///
/// Complète [congruent], qui exige le même compte de sommets et échoue donc
/// sur les formes courbes discrétisées : deux secteurs de cercle visuellement
/// identiques peuvent différer d'un sommet d'échantillonnage (12 vs 13) —
/// [congruent] répond « différents », l'œil répond « identiques ». C'est ce
/// trou qui laissait passer des pièges indiscernables d'une vraie pièce sur
/// les cibles cercle/demi-cercle.
///
/// Méthode : contours rééchantillonnés en [samples] points équirépartis par
/// abscisse curviligne, centrés sur leur centroïde ; alignement optimal en
/// rotation (Procrustes, forme close par corrélation complexe) minimisé sur
/// tous les décalages de point de départ. Identiques si l'écart RMS rapporté
/// à √aire est ≤ [relTol].
/// SYMÉTRIQUE par construction : l'alignement sur 64 décalages discrets
/// introduit une erreur de discrétisation dépendante du sens d'appel — sur
/// une paire limite, (a,b) pouvait dire « identiques » et (b,a) « distincts »
/// (bug latent exposé par l'audit 2026-07-16 : garde du générateur passée
/// dans un sens, re-vérification de conformité rouge dans l'autre). Une
/// garde anti-ambiguïté doit être conservatrice : identiques si L'UN OU
/// L'AUTRE sens le dit.
bool perceptuallyIdentical(Polygon a, Polygon b,
    {bool allowMirror = false,
    double relTol = kPerceptualTol,
    int samples = 64}) =>
    _perceptuallyIdenticalOneWay(a, b,
        allowMirror: allowMirror, relTol: relTol, samples: samples) ||
    _perceptuallyIdenticalOneWay(b, a,
        allowMirror: allowMirror, relTol: relTol, samples: samples);

bool _perceptuallyIdenticalOneWay(Polygon a, Polygon b,
    {required bool allowMirror,
    required double relTol,
    required int samples}) {
  final pa = a.cleaned().ccw();
  final pb = b.cleaned().ccw();
  if (pa.vertices.length < 3 || pb.vertices.length < 3) return false;

  final areaA = pa.area();
  final areaB = pb.area();
  final maxArea = math.max(areaA, areaB);
  if (maxArea < kGeomEps) return true;
  // Rejets rapides : aire ou périmètre trop différents (mêmes bornes que
  // congruent — un écart d'aire relatif > 2·relTol se voit).
  if ((areaA - areaB).abs() / maxArea > 2 * relTol) return false;
  final perA = pa.perimeter();
  final perB = pb.perimeter();
  if (math.max(perA, perB) < kGeomEps) return false;
  if ((perA - perB).abs() / math.max(perA, perB) > 2 * relTol) return false;

  final scaleRef = math.sqrt(maxArea);
  final tol = relTol * scaleRef;

  final ca = _resampleContour(pa, samples);
  if (_minRmsOverShifts(ca, _resampleContour(pb, samples)) <= tol) return true;
  if (allowMirror) {
    final mb = pb.transform(mirrored: true).ccw();
    if (_minRmsOverShifts(ca, _resampleContour(mb, samples)) <= tol) {
      return true;
    }
  }
  return false;
}

/// Garde anti-ambiguïté combinée : vrai si deux pièces sont indiscernables à
/// l'œil par L'UNE OU L'AUTRE méthode — signature de sommets ([congruent]) ou
/// contour rééchantillonné ([perceptuallyIdentical]).
///
/// C'est la fonction à utiliser dans TOUTES les gardes de génération :
/// l'audit 2026-07-12 (ambiguity_audit_test) a mesuré que la signature seule
/// laissait passer un piège indiscernable d'une vraie pièce dans 47 % des
/// items medium/hard (miroirs quasi superposables par rotation, découpes
/// alternatives sur formes symétriques ou courbes).
bool visuallyConfusable(Polygon a, Polygon b, {bool allowMirror = false}) =>
    congruent(a, b, allowMirror: allowMirror, relTol: kPerceptualTol) ||
    perceptuallyIdentical(a, b, allowMirror: allowMirror);

/// [samples] points équirépartis par longueur d'arc le long du contour,
/// recentrés sur le centroïde (aire) du polygone.
List<Offset> _resampleContour(Polygon p, int samples) {
  final c = p.centroid();
  final verts = p.vertices;
  final n = verts.length;
  final cum = List<double>.filled(n + 1, 0);
  for (int i = 0; i < n; i++) {
    cum[i + 1] = cum[i] + (verts[(i + 1) % n] - verts[i]).distance;
  }
  final total = cum[n];
  final out = <Offset>[];
  if (total < kGeomEps) {
    return List.filled(samples, verts.first - c);
  }
  int seg = 0;
  for (int k = 0; k < samples; k++) {
    final target = total * k / samples;
    while (seg < n - 1 && cum[seg + 1] < target) {
      seg++;
    }
    final segLen = cum[seg + 1] - cum[seg];
    final t = segLen < kGeomEps ? 0.0 : (target - cum[seg]) / segLen;
    final a = verts[seg];
    final b = verts[(seg + 1) % n];
    out.add(Offset(a.dx + (b.dx - a.dx) * t, a.dy + (b.dy - a.dy) * t) - c);
  }
  return out;
}

/// RMS minimal entre deux contours rééchantillonnés (mêmes longueurs), sur
/// tous les décalages de départ, avec rotation optimale par décalage.
///
/// Forme close : en complexes, pour un décalage s, la rotation optimale donne
/// RMS² = (Σ|a|² + Σ|b|² − 2·|Σ conj(a_i)·b_{i+s}|) / K.
double _minRmsOverShifts(List<Offset> a, List<Offset> b) {
  final k = a.length;
  double sa2 = 0, sb2 = 0;
  for (int i = 0; i < k; i++) {
    sa2 += a[i].dx * a[i].dx + a[i].dy * a[i].dy;
    sb2 += b[i].dx * b[i].dx + b[i].dy * b[i].dy;
  }
  double best = double.infinity;
  for (int s = 0; s < k; s++) {
    double re = 0, im = 0;
    for (int i = 0; i < k; i++) {
      final p = a[i];
      final q = b[(i + s) % k];
      // conj(a) * b
      re += p.dx * q.dx + p.dy * q.dy;
      im += p.dx * q.dy - p.dy * q.dx;
    }
    final cross = math.sqrt(re * re + im * im);
    final mse = (sa2 + sb2 - 2 * cross) / k;
    if (mse < best) best = mse;
  }
  return best <= 0 ? 0 : math.sqrt(best);
}

List<(double, double)> _signature(Polygon p) {
  final n = p.vertices.length;
  final sig = <(double, double)>[];
  for (int i = 0; i < n; i++) {
    final prev = p.vertices[(i - 1 + n) % n];
    final cur = p.vertices[i];
    final next = p.vertices[(i + 1) % n];
    final e1 = cur - prev;
    final e2 = next - cur;
    final len = e2.distance;
    final turn = math.atan2(
      e1.dx * e2.dy - e1.dy * e2.dx,
      e1.dx * e2.dx + e1.dy * e2.dy,
    );
    sig.add((len, turn));
  }
  return sig;
}

bool _cyclicMatch(List<(double, double)> a, List<(double, double)> b,
    double lenTol, double angTol) {
  final n = a.length;
  for (int shift = 0; shift < n; shift++) {
    bool ok = true;
    for (int i = 0; i < n; i++) {
      final (la, ta) = a[i];
      final (lb, tb) = b[(i + shift) % n];
      if ((la - lb).abs() > lenTol || (ta - tb).abs() > angTol) {
        ok = false;
        break;
      }
    }
    if (ok) return true;
  }
  return false;
}
