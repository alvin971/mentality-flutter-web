import 'package:flutter/material.dart';
import '../../domain/geometry.dart';

/// Painter générique pour dessiner un polygone normalisé [0,1] × [0,1]
/// dans une zone arbitraire.
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
  final double padding;

  @override
  void paint(Canvas canvas, Size size) {
    if (polygon.vertices.length < 3) return;
    final bb = polygon.bbox();
    final usableW = size.width * (1 - 2 * padding);
    final usableH = size.height * (1 - 2 * padding);
    final scale = (bb.width > 0 && bb.height > 0)
        ? (usableW / bb.width < usableH / bb.height
            ? usableW / bb.width
            : usableH / bb.height)
        : 1.0;
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
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = strokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant PolygonPainter old) =>
      old.polygon != polygon ||
      old.fillColor != fillColor ||
      old.strokeColor != strokeColor;
}
