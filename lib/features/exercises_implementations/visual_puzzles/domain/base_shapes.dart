import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'geometry.dart';

/// Formes de base utilisables comme cibles entières (avant découpe).
enum BaseShape {
  square,
  rectangle,
  triangleEq,
  triangleRight,
  hexagon,
  circle,
  pentagon,
  diamond,
}

extension BaseShapeX on BaseShape {
  String get label => switch (this) {
        BaseShape.square => 'Carré',
        BaseShape.rectangle => 'Rectangle',
        BaseShape.triangleEq => 'Triangle équilatéral',
        BaseShape.triangleRight => 'Triangle rectangle',
        BaseShape.hexagon => 'Hexagone',
        BaseShape.circle => 'Cercle',
        BaseShape.pentagon => 'Pentagone',
        BaseShape.diamond => 'Losange',
      };
}

Polygon buildBaseShape(BaseShape shape) {
  switch (shape) {
    case BaseShape.square:
      return const Polygon([
        Offset(0, 0),
        Offset(1, 0),
        Offset(1, 1),
        Offset(0, 1),
      ]);
    case BaseShape.rectangle:
      return const Polygon([
        Offset(0.0, 0.20),
        Offset(1.0, 0.20),
        Offset(1.0, 0.80),
        Offset(0.0, 0.80),
      ]);
    case BaseShape.triangleEq:
      const h = 0.866; // √3/2
      const top = (1 - h) / 2;
      return Polygon(const [
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
    case BaseShape.hexagon:
      final verts = <Offset>[];
      for (int i = 0; i < 6; i++) {
        final ang = math.pi / 3 * i - math.pi / 6;
        verts.add(Offset(0.5 + 0.5 * math.cos(ang), 0.5 + 0.5 * math.sin(ang)));
      }
      return Polygon(verts);
    case BaseShape.circle:
      // Approx 36 sommets
      const samples = 36;
      final verts = <Offset>[];
      for (int i = 0; i < samples; i++) {
        final ang = 2 * math.pi * i / samples;
        verts.add(Offset(0.5 + 0.5 * math.cos(ang), 0.5 + 0.5 * math.sin(ang)));
      }
      return Polygon(verts);
    case BaseShape.pentagon:
      final verts = <Offset>[];
      for (int i = 0; i < 5; i++) {
        final ang = 2 * math.pi * i / 5 - math.pi / 2;
        verts.add(Offset(0.5 + 0.5 * math.cos(ang), 0.5 + 0.5 * math.sin(ang)));
      }
      return Polygon(verts);
    case BaseShape.diamond:
      return const Polygon([
        Offset(0.5, 0.0),
        Offset(1.0, 0.5),
        Offset(0.5, 1.0),
        Offset(0.0, 0.5),
      ]);
  }
}
