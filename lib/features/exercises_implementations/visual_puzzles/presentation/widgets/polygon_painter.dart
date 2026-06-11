import 'package:flutter/material.dart';
import '../../domain/geometry.dart';

/// Painter générique pour un polygone en coords normalisées.
///
/// Deux modes :
/// - `unitsPerTile == null` : le polygone est mis à l'échelle pour remplir la
///   zone (utilisé pour la CIBLE uniquement) ;
/// - `unitsPerTile != null` : échelle FIXE — `unitsPerTile` unités normalisées
///   correspondent au côté de la zone. Toutes les pièces d'un item sont
///   dessinées avec le même `unitsPerTile` → leurs tailles relatives sont
///   fidèles, ce qui rend les pièges de taille/proportion détectables.
class PolygonPainter extends CustomPainter {
  PolygonPainter({
    required this.polygon,
    required this.fillColor,
    required this.strokeColor,
    this.strokeWidth = 2.4,
    this.padding = 0.06,
    this.unitsPerTile,
  });

  final Polygon polygon;
  final Color fillColor;
  final Color strokeColor;
  final double strokeWidth;
  final double padding;
  final double? unitsPerTile;

  @override
  void paint(Canvas canvas, Size size) {
    if (polygon.vertices.length < 3) return;
    final bb = polygon.bbox();

    double scale;
    if (unitsPerTile != null && unitsPerTile! > 0) {
      // Échelle fixe : px par unité normalisée.
      final side = size.shortestSide * (1 - 2 * padding);
      scale = side / unitsPerTile!;
    } else {
      final usableW = size.width * (1 - 2 * padding);
      final usableH = size.height * (1 - 2 * padding);
      scale = (bb.width > 0 && bb.height > 0)
          ? (usableW / bb.width < usableH / bb.height
              ? usableW / bb.width
              : usableH / bb.height)
          : 1.0;
    }

    // Centre le bbox du polygone dans la zone.
    final offX = (size.width - bb.width * scale) / 2 - bb.left * scale;
    final offY = (size.height - bb.height * scale) / 2 - bb.top * scale;

    final path = Path();
    final v0 = polygon.vertices[0];
    path.moveTo(v0.dx * scale + offX, v0.dy * scale + offY);
    for (int i = 1; i < polygon.vertices.length; i++) {
      final v = polygon.vertices[i];
      path.lineTo(v.dx * scale + offX, v.dy * scale + offY);
    }
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = strokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(covariant PolygonPainter old) =>
      old.polygon != polygon ||
      old.fillColor != fillColor ||
      old.strokeColor != strokeColor ||
      old.unitsPerTile != unitsPerTile;
}

/// Painter d'une PIÈCE avec ses régions colorées (fragments du motif).
///
/// Même logique d'échelle que [PolygonPainter] (`unitsPerTile` commun à
/// toutes les pièces de l'item), mais le remplissage est fait région par
/// région avec les couleurs de la palette de l'item — une pièce peut donc
/// être bicolore, exactement comme dans le subtest réel.
class RegionedPolygonPainter extends CustomPainter {
  RegionedPolygonPainter({
    required this.polygon,
    required this.regions,
    required this.palette,
    required this.outlineColor,
    this.strokeWidth = 1.6,
    this.padding = 0.06,
    this.unitsPerTile,
  });

  /// Silhouette complète de la pièce (pour le bbox et le contour).
  final Polygon polygon;

  /// Régions colorées, même espace de coordonnées que [polygon].
  final List<ColoredRegion> regions;

  final List<Color> palette;
  final Color outlineColor;
  final double strokeWidth;
  final double padding;
  final double? unitsPerTile;

  @override
  void paint(Canvas canvas, Size size) {
    if (polygon.vertices.length < 3) return;
    final bb = polygon.bbox();

    double scale;
    if (unitsPerTile != null && unitsPerTile! > 0) {
      final side = size.shortestSide * (1 - 2 * padding);
      scale = side / unitsPerTile!;
    } else {
      final usableW = size.width * (1 - 2 * padding);
      final usableH = size.height * (1 - 2 * padding);
      scale = (bb.width > 0 && bb.height > 0)
          ? (usableW / bb.width < usableH / bb.height
              ? usableW / bb.width
              : usableH / bb.height)
          : 1.0;
    }

    final offX = (size.width - bb.width * scale) / 2 - bb.left * scale;
    final offY = (size.height - bb.height * scale) / 2 - bb.top * scale;

    Path makePath(Polygon poly) {
      final path = Path();
      if (poly.vertices.isEmpty) return path;
      final v0 = poly.vertices[0];
      path.moveTo(v0.dx * scale + offX, v0.dy * scale + offY);
      for (int i = 1; i < poly.vertices.length; i++) {
        final v = poly.vertices[i];
        path.lineTo(v.dx * scale + offX, v.dy * scale + offY);
      }
      path.close();
      return path;
    }

    // Régions colorées : aplats + stroke fin de la même couleur (scelle les
    // jointures entre régions d'une pièce bicolore).
    for (final r in regions) {
      if (r.polygon.vertices.length < 3) continue;
      final color = palette[r.colorIndex % palette.length];
      final path = makePath(r.polygon);
      canvas.drawPath(path, Paint()..color = color);
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.9
          ..strokeJoin = StrokeJoin.round,
      );
    }

    // Contour de la pièce entière.
    canvas.drawPath(
      makePath(polygon),
      Paint()
        ..color = outlineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant RegionedPolygonPainter old) =>
      old.polygon != polygon ||
      old.regions != regions ||
      old.palette != palette ||
      old.unitsPerTile != unitsPerTile;
}
