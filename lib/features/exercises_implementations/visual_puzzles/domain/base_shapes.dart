import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'geometry.dart';

/// Formes de base utilisables comme cibles entières (avant découpe).
///
/// CONTRAINTE : toutes les formes sont CONVEXES. Une coupe en ligne droite
/// d'un polygone convexe produit toujours 2 morceaux connexes et convexes —
/// c'est ce qui rend le moteur de découpe fiable à 100 %.
enum BaseShape {
  square,
  rectangleWide,
  rectangleTall,
  triangleEq,
  triangleRight,
  diamond,
  trapezoid,
  parallelogram,
  house,
  pentagon,
  hexagon,
  octagon,
  semicircle,
  circle,
}

extension BaseShapeX on BaseShape {
  String get label => switch (this) {
        BaseShape.square => 'Carré',
        BaseShape.rectangleWide => 'Rectangle large',
        BaseShape.rectangleTall => 'Rectangle haut',
        BaseShape.triangleEq => 'Triangle équilatéral',
        BaseShape.triangleRight => 'Triangle rectangle',
        BaseShape.diamond => 'Losange',
        BaseShape.trapezoid => 'Trapèze',
        BaseShape.parallelogram => 'Parallélogramme',
        BaseShape.house => 'Pentagone maison',
        BaseShape.pentagon => 'Pentagone',
        BaseShape.hexagon => 'Hexagone',
        BaseShape.octagon => 'Octogone',
        BaseShape.semicircle => 'Demi-cercle',
        BaseShape.circle => 'Cercle',
      };
}

/// Construit le polygone normalisé [0,1]² d'une forme de base.
Polygon buildBaseShape(BaseShape shape) {
  switch (shape) {
    case BaseShape.square:
      return const Polygon([
        Offset(0, 0),
        Offset(1, 0),
        Offset(1, 1),
        Offset(0, 1),
      ]);
    case BaseShape.rectangleWide:
      return const Polygon([
        Offset(0.0, 0.18),
        Offset(1.0, 0.18),
        Offset(1.0, 0.82),
        Offset(0.0, 0.82),
      ]);
    case BaseShape.rectangleTall:
      return const Polygon([
        Offset(0.18, 0.0),
        Offset(0.82, 0.0),
        Offset(0.82, 1.0),
        Offset(0.18, 1.0),
      ]);
    case BaseShape.triangleEq:
      const h = 0.866; // √3/2
      const top = (1 - h) / 2;
      return const Polygon([
        Offset(0.5, top),
        Offset(1.0, top + h),
        Offset(0.0, top + h),
      ]);
    case BaseShape.triangleRight:
      return const Polygon([
        Offset(0, 0),
        Offset(1, 1),
        Offset(0, 1),
      ]);
    case BaseShape.diamond:
      return const Polygon([
        Offset(0.5, 0.0),
        Offset(1.0, 0.5),
        Offset(0.5, 1.0),
        Offset(0.0, 0.5),
      ]);
    case BaseShape.trapezoid:
      return const Polygon([
        Offset(0.22, 0.16),
        Offset(0.78, 0.16),
        Offset(1.0, 0.84),
        Offset(0.0, 0.84),
      ]);
    case BaseShape.parallelogram:
      return const Polygon([
        Offset(0.22, 0.18),
        Offset(1.0, 0.18),
        Offset(0.78, 0.82),
        Offset(0.0, 0.82),
      ]);
    case BaseShape.house:
      // Carré + toit triangulaire = pentagone convexe.
      return const Polygon([
        Offset(0.5, 0.0),
        Offset(1.0, 0.38),
        Offset(1.0, 1.0),
        Offset(0.0, 1.0),
        Offset(0.0, 0.38),
      ]);
    case BaseShape.pentagon:
      return _regular(5, startAngle: -math.pi / 2);
    case BaseShape.hexagon:
      return _regular(6, startAngle: -math.pi / 6);
    case BaseShape.octagon:
      return _regular(8, startAngle: -math.pi / 8);
    case BaseShape.semicircle:
      final verts = <Offset>[const Offset(0.0, 0.75), const Offset(1.0, 0.75)];
      const samples = 20;
      for (int i = 1; i < samples; i++) {
        final ang = math.pi * i / samples;
        verts.insert(
            1, Offset(0.5 + 0.5 * math.cos(ang), 0.75 - 0.5 * math.sin(ang)));
      }
      return Polygon(verts);
    case BaseShape.circle:
      const samples = 36;
      final verts = <Offset>[];
      for (int i = 0; i < samples; i++) {
        final ang = 2 * math.pi * i / samples;
        verts.add(Offset(0.5 + 0.5 * math.cos(ang), 0.5 + 0.5 * math.sin(ang)));
      }
      return Polygon(verts);
  }
}

Polygon _regular(int sides, {double startAngle = 0}) {
  final verts = <Offset>[];
  for (int i = 0; i < sides; i++) {
    final ang = 2 * math.pi * i / sides + startAngle;
    verts.add(Offset(0.5 + 0.5 * math.cos(ang), 0.5 + 0.5 * math.sin(ang)));
  }
  return Polygon(verts);
}
