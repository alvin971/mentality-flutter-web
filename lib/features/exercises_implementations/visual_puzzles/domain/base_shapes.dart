import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'geometry.dart';

/// Forme de base de la cible (avant découpe).
///
/// Toutes les formes sont définies en coordonnées normalisées [0,1] × [0,1].
/// Le centre du polygone est ≈ (0.5, 0.5) pour faciliter la composition.
enum BaseShape { square, rectangle, triangleEq, triangleRight, hexagon, circle }

extension BaseShapeX on BaseShape {
  String get label => switch (this) {
        BaseShape.square => 'Carré',
        BaseShape.rectangle => 'Rectangle',
        BaseShape.triangleEq => 'Triangle équilatéral',
        BaseShape.triangleRight => 'Triangle rectangle',
        BaseShape.hexagon => 'Hexagone',
        BaseShape.circle => 'Cercle',
      };
}

/// Construit le polygone d'une forme de base dans [0,1] × [0,1].
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
      // Rectangle 2:1 horizontal — occupe la zone [0,1]×[0.25,0.75]
      return const Polygon([
        Offset(0.0, 0.25),
        Offset(1.0, 0.25),
        Offset(1.0, 0.75),
        Offset(0.0, 0.75),
      ]);
    case BaseShape.triangleEq:
      // Triangle équilatéral pointant vers le haut, inscrit dans [0,1]×[0,1]
      // Centre du triangle ≈ (0.5, 0.5)
      // Hauteur = √3/2 ≈ 0.866 → on scale pour tenir dans 1.0
      const h = 0.866;
      const top = (1 - h) / 2; // ~0.067
      return Polygon(const [
        Offset(0.5, top), // sommet
        Offset(1.0, top + h), // bas-droite
        Offset(0.0, top + h), // bas-gauche
      ]);
    case BaseShape.triangleRight:
      // Triangle rectangle, angle droit en bas-gauche
      return const Polygon([
        Offset(0, 0),
        Offset(1, 1),
        Offset(0, 1),
      ]);
    case BaseShape.hexagon:
      // Hexagone régulier inscrit dans le cercle de rayon 0.5
      final verts = <Offset>[];
      for (int i = 0; i < 6; i++) {
        final ang = math.pi / 3 * i - math.pi / 6; // commence en haut-droite
        verts.add(Offset(0.5 + 0.5 * math.cos(ang), 0.5 + 0.5 * math.sin(ang)));
      }
      return Polygon(verts);
    case BaseShape.circle:
      // Approximation par polygone à 48 sommets
      const samples = 48;
      final verts = <Offset>[];
      for (int i = 0; i < samples; i++) {
        final ang = 2 * math.pi * i / samples;
        verts.add(Offset(0.5 + 0.5 * math.cos(ang), 0.5 + 0.5 * math.sin(ang)));
      }
      return Polygon(verts);
  }
}
