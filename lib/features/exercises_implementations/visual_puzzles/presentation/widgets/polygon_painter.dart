import 'package:flutter/material.dart';
import '../../domain/geometry.dart';

/// Painter générique pour dessiner un polygone (suite de sommets) dans une
/// zone normalisée [0,1]×[0,1] mappée sur la `size` de la zone de dessin.
class PolygonPainter extends CustomPainter {
  PolygonPainter({
    required this.polygon,
    required this.fillColor,
    required this.strokeColor,
    this.strokeWidth = 2.4,
    this.padding = 0.05,
  });

  final Polygon polygon;
  final Color fillColor;
  final Color strokeColor;
  final double strokeWidth;
  final double padding; // marge intérieure normalisée

  @override
  void paint(Canvas canvas, Size size) {
    if (polygon.vertices.length < 3) return;
    // Calcule l'échelle pour que le polygone (en coords [0,1]) occupe
    // (1 - 2*padding) × (1 - 2*padding) de la taille
    final bbox = polygon.bbox();
    final usableW = size.width * (1 - 2 * padding);
    final usableH = size.height * (1 - 2 * padding);
    final scale = (bbox.width > 0 && bbox.height > 0)
        ? (usableW / bbox.width < usableH / bbox.height
            ? usableW / bbox.width
            : usableH / bbox.height)
        : 1.0;
    final offX = (size.width - bbox.width * scale) / 2 - bbox.left * scale;
    final offY = (size.height - bbox.height * scale) / 2 - bbox.top * scale;

    final path = Path();
    final v0 = polygon.vertices[0];
    path.moveTo(v0.dx * scale + offX, v0.dy * scale + offY);
    for (int i = 1; i < polygon.vertices.length; i++) {
      final v = polygon.vertices[i];
      path.lineTo(v.dx * scale + offX, v.dy * scale + offY);
    }
    path.close();

    final fill = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fill);

    final stroke = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant PolygonPainter old) =>
      old.polygon != polygon ||
      old.fillColor != fillColor ||
      old.strokeColor != strokeColor ||
      old.strokeWidth != strokeWidth;
}
