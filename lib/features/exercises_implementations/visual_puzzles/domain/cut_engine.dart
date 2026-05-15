import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'geometry.dart';

/// Stratégies de découpe ordonnées par complexité croissante.
enum CutStrategy {
  /// 2 traits droits parallèles (horizontal OU vertical) → 3 bandes.
  twoParallelStraight,

  /// 1 trait droit + 1 trait droit perpendiculaire dans une moitié (L ou T).
  perpendicularL,

  /// 1 trait droit + 1 trait droit oblique.
  oneStraightOneOblique,

  /// 2 traits obliques (diagonales).
  twoOblique,

  /// 1 trait brisé (2 segments avec angle) + 1 trait droit.
  oneBent,

  /// 2 traits brisés (zigzag) — pour niveaux les plus difficiles.
  twoBent,
}

/// Découpe un polygone en EXACTEMENT 3 sous-polygones selon une stratégie.
///
/// L'algorithme garantit :
///   - Les 3 polygones résultants reconstituent strictement le polygone d'entrée
///     (à epsilon près), vérifiable via `isReconstruction`.
///   - Aucun chevauchement entre les 3 polygones.
///
/// `rng` est utilisé pour les positions aléatoires des coupes.
class CutEngine {
  CutEngine({math.Random? rng}) : _rng = rng ?? math.Random();

  final math.Random _rng;

  /// Découpe en 3 pièces selon la stratégie demandée. Tente jusqu'à 6 fois
  /// si la première tentative produit un polygone dégénéré (< 3 sommets).
  List<Polygon> cut(Polygon base, CutStrategy strategy) {
    for (int attempt = 0; attempt < 6; attempt++) {
      final result = _tryCut(base, strategy);
      if (result != null) return result;
    }
    // Fallback : 2 traits verticaux fixes pour garantir un résultat.
    return _fallbackThreeBands(base);
  }

  List<Polygon>? _tryCut(Polygon base, CutStrategy strategy) {
    switch (strategy) {
      case CutStrategy.twoParallelStraight:
        return _twoParallelStraight(base);
      case CutStrategy.perpendicularL:
        return _perpendicularL(base);
      case CutStrategy.oneStraightOneOblique:
        return _oneStraightOneOblique(base);
      case CutStrategy.twoOblique:
        return _twoOblique(base);
      case CutStrategy.oneBent:
        return _oneBent(base);
      case CutStrategy.twoBent:
        return _twoBent(base);
    }
  }

  /// 2 traits parallèles → 3 bandes.
  List<Polygon>? _twoParallelStraight(Polygon base) {
    final bbox = base.bbox();
    final vertical = _rng.nextBool();
    // 2 positions de coupe entre 25%-40% et 60%-75% de la dimension
    final t1 = 0.25 + _rng.nextDouble() * 0.15;
    final t2 = 0.60 + _rng.nextDouble() * 0.15;

    CutLine line1, line2;
    if (vertical) {
      final x1 = bbox.left + bbox.width * t1;
      final x2 = bbox.left + bbox.width * t2;
      line1 = CutLine(Offset(x1, bbox.top - 1), Offset(x1, bbox.bottom + 1));
      line2 = CutLine(Offset(x2, bbox.top - 1), Offset(x2, bbox.bottom + 1));
    } else {
      final y1 = bbox.top + bbox.height * t1;
      final y2 = bbox.top + bbox.height * t2;
      line1 = CutLine(Offset(bbox.left - 1, y1), Offset(bbox.right + 1, y1));
      line2 = CutLine(Offset(bbox.left - 1, y2), Offset(bbox.right + 1, y2));
    }

    // Coupe 1 : sépare gauche/droite (ou haut/bas)
    final after1 = cutPolygonByLine(base, line1);
    if (after1[0].vertices.length < 3 || after1[1].vertices.length < 3) {
      return null;
    }
    // Identifie quelle moitié contient line2 (la "grande" moitié)
    // Coupe ensuite cette moitié avec line2
    final left = after1[1]; // côté "négatif" de line1
    final right = after1[0]; // côté "positif"

    final after2 = cutPolygonByLine(right, line2);
    if (after2[0].vertices.length < 3 || after2[1].vertices.length < 3) {
      return null;
    }
    return [left, after2[1], after2[0]];
  }

  /// Cut en L ou T : 1 trait coupe en 2, puis 1 perpendiculaire coupe une moitié.
  List<Polygon>? _perpendicularL(Polygon base) {
    final bbox = base.bbox();
    final firstVertical = _rng.nextBool();
    final t1 = 0.35 + _rng.nextDouble() * 0.30;

    CutLine line1;
    if (firstVertical) {
      final x = bbox.left + bbox.width * t1;
      line1 = CutLine(Offset(x, bbox.top - 1), Offset(x, bbox.bottom + 1));
    } else {
      final y = bbox.top + bbox.height * t1;
      line1 = CutLine(Offset(bbox.left - 1, y), Offset(bbox.right + 1, y));
    }
    final after1 = cutPolygonByLine(base, line1);
    if (after1[0].vertices.length < 3 || after1[1].vertices.length < 3) {
      return null;
    }
    // Choisit la pièce qu'on coupe avec line2 (la "plus grande" par aire)
    final big = after1[0].area() > after1[1].area() ? after1[0] : after1[1];
    final small = big == after1[0] ? after1[1] : after1[0];

    final bigBbox = big.bbox();
    final t2 = 0.40 + _rng.nextDouble() * 0.20;
    CutLine line2;
    if (firstVertical) {
      // Perpendiculaire = horizontal
      final y = bigBbox.top + bigBbox.height * t2;
      line2 = CutLine(Offset(bigBbox.left - 1, y), Offset(bigBbox.right + 1, y));
    } else {
      final x = bigBbox.left + bigBbox.width * t2;
      line2 = CutLine(Offset(x, bigBbox.top - 1), Offset(x, bigBbox.bottom + 1));
    }
    final after2 = cutPolygonByLine(big, line2);
    if (after2[0].vertices.length < 3 || after2[1].vertices.length < 3) {
      return null;
    }
    return [small, after2[0], after2[1]];
  }

  /// 1 trait droit + 1 trait oblique.
  List<Polygon>? _oneStraightOneOblique(Polygon base) {
    final bbox = base.bbox();
    final t1 = 0.4 + _rng.nextDouble() * 0.2;
    final y = bbox.top + bbox.height * t1;
    final line1 = CutLine(Offset(bbox.left - 1, y), Offset(bbox.right + 1, y));
    final after1 = cutPolygonByLine(base, line1);
    if (after1[0].vertices.length < 3 || after1[1].vertices.length < 3) {
      return null;
    }
    final big = after1[0].area() > after1[1].area() ? after1[0] : after1[1];
    final small = big == after1[0] ? after1[1] : after1[0];

    final bigBbox = big.bbox();
    // Oblique passant approximativement par le centre, angle ±30°
    final angle = (math.pi / 6) * (_rng.nextBool() ? 1 : -1);
    final cx = bigBbox.center.dx;
    final cy = bigBbox.center.dy;
    final dx = math.cos(angle);
    final dy = math.sin(angle);
    final line2 = CutLine(
      Offset(cx - dx * 2, cy - dy * 2),
      Offset(cx + dx * 2, cy + dy * 2),
    );
    final after2 = cutPolygonByLine(big, line2);
    if (after2[0].vertices.length < 3 || after2[1].vertices.length < 3) {
      return null;
    }
    return [small, after2[0], after2[1]];
  }

  /// 2 traits obliques croisant le centre.
  List<Polygon>? _twoOblique(Polygon base) {
    final bbox = base.bbox();
    final cx = bbox.center.dx;
    final cy = bbox.center.dy;
    final ang1 = (math.pi / 8) + _rng.nextDouble() * (math.pi / 6);
    final ang2 = ang1 + math.pi / 2 + (_rng.nextDouble() - 0.5) * (math.pi / 6);
    // Point de croisement décalé légèrement pour ne pas tomber pile au centre
    final ox = cx + (_rng.nextDouble() - 0.5) * bbox.width * 0.15;
    final oy = cy + (_rng.nextDouble() - 0.5) * bbox.height * 0.15;
    final dx1 = math.cos(ang1);
    final dy1 = math.sin(ang1);
    final dx2 = math.cos(ang2);
    final dy2 = math.sin(ang2);
    final line1 =
        CutLine(Offset(ox - dx1 * 2, oy - dy1 * 2), Offset(ox + dx1 * 2, oy + dy1 * 2));
    final line2 =
        CutLine(Offset(ox - dx2 * 2, oy - dy2 * 2), Offset(ox + dx2 * 2, oy + dy2 * 2));

    final after1 = cutPolygonByLine(base, line1);
    if (after1[0].vertices.length < 3 || after1[1].vertices.length < 3) {
      return null;
    }
    final big = after1[0].area() > after1[1].area() ? after1[0] : after1[1];
    final small = big == after1[0] ? after1[1] : after1[0];

    final after2 = cutPolygonByLine(big, line2);
    if (after2[0].vertices.length < 3 || after2[1].vertices.length < 3) {
      return null;
    }
    return [small, after2[0], after2[1]];
  }

  /// 1 trait brisé (2 segments avec un angle) + 1 trait droit.
  /// Approximation : on coupe avec 2 lignes droites successives qui se rejoignent
  /// (la 2e ligne ne coupe que la pièce qui contient le "coude").
  List<Polygon>? _oneBent(Polygon base) {
    // On simule un trait brisé par 2 coupes successives sur la même pièce.
    final bbox = base.bbox();
    final cx = bbox.center.dx;
    final cy = bbox.center.dy;
    final t = 0.4 + _rng.nextDouble() * 0.2;
    final y = bbox.top + bbox.height * t;
    final line1 = CutLine(Offset(bbox.left - 1, y), Offset(cx, y));
    // Variation : on fait line1 ne couper qu'une partie en limitant le segment
    // Mais cutPolygonByLine utilise une ligne INFINIE. Pour un trait brisé
    // qui ne traverse pas tout, on a besoin d'autre chose.
    // → Pour MVP, on utilise un cut diagonal en 2 étapes (small wedge).
    final angle1 = math.pi / 5; // ~36°
    final dx1 = math.cos(angle1);
    final dy1 = math.sin(angle1);
    final cutLine1 = CutLine(
      Offset(cx - dx1 * 2, cy - dy1 * 2),
      Offset(cx + dx1 * 2, cy + dy1 * 2),
    );
    final after1 = cutPolygonByLine(base, cutLine1);
    if (after1[0].vertices.length < 3 || after1[1].vertices.length < 3) {
      return null;
    }
    // Deuxième cut sur la moitié top à un autre angle
    final big = after1[0].area() > after1[1].area() ? after1[0] : after1[1];
    final small = big == after1[0] ? after1[1] : after1[0];

    final bigC = big.centroid();
    final angle2 = -math.pi / 4 + _rng.nextDouble() * math.pi / 3;
    final dx2 = math.cos(angle2);
    final dy2 = math.sin(angle2);
    final cutLine2 = CutLine(
      Offset(bigC.dx - dx2 * 2, bigC.dy - dy2 * 2),
      Offset(bigC.dx + dx2 * 2, bigC.dy + dy2 * 2),
    );
    final after2 = cutPolygonByLine(big, cutLine2);
    if (after2[0].vertices.length < 3 || after2[1].vertices.length < 3) {
      return null;
    }
    // Suppression inutile : on ignore line1 (TS pas vu)
    // ignore: unused_local_variable
    final _ = line1;
    return [small, after2[0], after2[1]];
  }

  /// 2 traits brisés (couches d'obliques).
  List<Polygon>? _twoBent(Polygon base) {
    // Pour MVP, on fait 2 cuts obliques très inclinés
    final bbox = base.bbox();
    final cx = bbox.center.dx;
    final cy = bbox.center.dy;
    final ang1 = math.pi / 5 + _rng.nextDouble() * math.pi / 6;
    final ang2 = -math.pi / 4 - _rng.nextDouble() * math.pi / 6;
    final dx1 = math.cos(ang1);
    final dy1 = math.sin(ang1);
    final dx2 = math.cos(ang2);
    final dy2 = math.sin(ang2);
    final ox = cx + (_rng.nextDouble() - 0.5) * bbox.width * 0.2;
    final oy = cy + (_rng.nextDouble() - 0.5) * bbox.height * 0.2;
    final line1 =
        CutLine(Offset(ox - dx1 * 2, oy - dy1 * 2), Offset(ox + dx1 * 2, oy + dy1 * 2));
    final after1 = cutPolygonByLine(base, line1);
    if (after1[0].vertices.length < 3 || after1[1].vertices.length < 3) {
      return null;
    }
    final big = after1[0].area() > after1[1].area() ? after1[0] : after1[1];
    final small = big == after1[0] ? after1[1] : after1[0];

    final bigC = big.centroid();
    final line2 = CutLine(
      Offset(bigC.dx - dx2 * 2, bigC.dy - dy2 * 2),
      Offset(bigC.dx + dx2 * 2, bigC.dy + dy2 * 2),
    );
    final after2 = cutPolygonByLine(big, line2);
    if (after2[0].vertices.length < 3 || after2[1].vertices.length < 3) {
      return null;
    }
    return [small, after2[0], after2[1]];
  }

  List<Polygon> _fallbackThreeBands(Polygon base) {
    final bbox = base.bbox();
    final x1 = bbox.left + bbox.width / 3;
    final x2 = bbox.left + bbox.width * 2 / 3;
    final line1 = CutLine(Offset(x1, bbox.top - 1), Offset(x1, bbox.bottom + 1));
    final line2 = CutLine(Offset(x2, bbox.top - 1), Offset(x2, bbox.bottom + 1));
    final after1 = cutPolygonByLine(base, line1);
    final after2 = cutPolygonByLine(after1[0], line2);
    return [after1[1], after2[0], after2[1]];
  }
}
