import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:math' as math;
import '../../domain/puzzle_generator.dart';

/// Widget pour afficher la forme cible du puzzle (silhouette)
class PuzzleTargetWidget extends StatelessWidget {
  final List<PuzzlePiece> targetPieces;

  const PuzzleTargetWidget({
    super.key,
    required this.targetPieces,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 200.h,
      margin: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade300, width: 2),
      ),
      child: CustomPaint(
        painter: _PuzzleTargetPainter(pieces: targetPieces),
      ),
    );
  }
}

/// Painter pour dessiner la silhouette combinée de toutes les pièces cibles
class _PuzzleTargetPainter extends CustomPainter {
  final List<PuzzlePiece> pieces;

  _PuzzleTargetPainter({required this.pieces});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Centre de la zone de dessin
    final center = Offset(size.width / 2, size.height / 2);
    final scale = size.width * 0.08; // Échelle pour positionner les pièces

    // Dessiner toutes les pièces
    for (final piece in pieces) {
      canvas.save();

      // Calculer la position de la pièce
      final pieceCenter = Offset(
        center.dx + (piece.position.dx * scale),
        center.dy + (piece.position.dy * scale),
      );

      // Appliquer les transformations (ordre: rotation, miroir, échelle)
      canvas.translate(pieceCenter.dx, pieceCenter.dy);

      // Rotation
      canvas.rotate(piece.rotation * math.pi / 180);

      // Miroir horizontal (WAIS-IV REF error)
      if (piece.isMirrored) {
        canvas.scale(-1.0, 1.0);
      }

      // Échelle (WAIS-IV SCALE error: 0.7-1.3)
      canvas.scale(piece.scale, piece.scale);

      canvas.translate(-pieceCenter.dx, -pieceCenter.dy);

      // Dessiner la forme
      _drawShape(canvas, piece.shape, pieceCenter, scale, paint, strokePaint);

      canvas.restore();
    }
  }

  void _drawShape(
    Canvas canvas,
    PieceShape shape,
    Offset center,
    double scale,
    Paint paint,
    Paint strokePaint,
  ) {
    switch (shape) {
      case PieceShape.square:
        _drawSquare(canvas, center, scale, paint, strokePaint);
        break;
      case PieceShape.rectangleHorizontal:
        _drawRectangleHorizontal(canvas, center, scale, paint, strokePaint);
        break;
      case PieceShape.rectangleVertical:
        _drawRectangleVertical(canvas, center, scale, paint, strokePaint);
        break;
      case PieceShape.triangle:
        _drawTriangle(canvas, center, scale, paint, strokePaint);
        break;
      case PieceShape.triangleSmall:
        _drawTriangleSmall(canvas, center, scale, paint, strokePaint);
        break;
      case PieceShape.circle:
        _drawCircle(canvas, center, scale, paint, strokePaint);
        break;
      case PieceShape.circleSector:
        _drawCircleSector(canvas, center, scale, paint, strokePaint);
        break;
      case PieceShape.diamond:
        _drawDiamond(canvas, center, scale, paint, strokePaint);
        break;
      case PieceShape.lShape:
        _drawLShape(canvas, center, scale, paint, strokePaint);
        break;
      case PieceShape.tShape:
        _drawTShape(canvas, center, scale, paint, strokePaint);
        break;
      case PieceShape.trapezoid:
        _drawTrapezoid(canvas, center, scale, paint, strokePaint);
        break;
      case PieceShape.irregular:
        _drawIrregular(canvas, center, scale, paint, strokePaint);
        break;
    }
  }

  void _drawSquare(Canvas canvas, Offset center, double scale, Paint paint, Paint strokePaint) {
    final rect = Rect.fromCenter(
      center: center,
      width: scale * 1.2,
      height: scale * 1.2,
    );
    canvas.drawRect(rect, paint);
    canvas.drawRect(rect, strokePaint);
  }

  void _drawRectangleHorizontal(Canvas canvas, Offset center, double scale, Paint paint, Paint strokePaint) {
    final rect = Rect.fromCenter(
      center: center,
      width: scale * 1.4,
      height: scale * 0.8,
    );
    canvas.drawRect(rect, paint);
    canvas.drawRect(rect, strokePaint);
  }

  void _drawRectangleVertical(Canvas canvas, Offset center, double scale, Paint paint, Paint strokePaint) {
    final rect = Rect.fromCenter(
      center: center,
      width: scale * 0.8,
      height: scale * 1.4,
    );
    canvas.drawRect(rect, paint);
    canvas.drawRect(rect, strokePaint);
  }

  void _drawTriangle(Canvas canvas, Offset center, double scale, Paint paint, Paint strokePaint) {
    final path = Path();
    final radius = scale * 0.7;

    path.moveTo(center.dx, center.dy - radius);
    path.lineTo(center.dx - radius, center.dy + radius);
    path.lineTo(center.dx + radius, center.dy + radius);
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, strokePaint);
  }

  void _drawTriangleSmall(Canvas canvas, Offset center, double scale, Paint paint, Paint strokePaint) {
    final path = Path();
    final radius = scale * 0.5;

    path.moveTo(center.dx, center.dy - radius);
    path.lineTo(center.dx - radius, center.dy + radius);
    path.lineTo(center.dx + radius, center.dy + radius);
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, strokePaint);
  }

  void _drawCircle(Canvas canvas, Offset center, double scale, Paint paint, Paint strokePaint) {
    final radius = scale * 0.6;
    canvas.drawCircle(center, radius, paint);
    canvas.drawCircle(center, radius, strokePaint);
  }

  void _drawCircleSector(Canvas canvas, Offset center, double scale, Paint paint, Paint strokePaint) {
    final radius = scale * 0.7;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final path = Path();
    path.moveTo(center.dx, center.dy);
    path.arcTo(rect, -math.pi / 2, 2 * math.pi / 3, false);
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, strokePaint);
  }

  void _drawDiamond(Canvas canvas, Offset center, double scale, Paint paint, Paint strokePaint) {
    final path = Path();
    final radius = scale * 0.7;

    path.moveTo(center.dx, center.dy - radius);
    path.lineTo(center.dx + radius, center.dy);
    path.lineTo(center.dx, center.dy + radius);
    path.lineTo(center.dx - radius, center.dy);
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, strokePaint);
  }

  void _drawLShape(Canvas canvas, Offset center, double scale, Paint paint, Paint strokePaint) {
    final path = Path();
    final unit = scale * 0.4;

    path.moveTo(center.dx - unit, center.dy - unit);
    path.lineTo(center.dx + unit, center.dy - unit);
    path.lineTo(center.dx + unit, center.dy);
    path.lineTo(center.dx, center.dy);
    path.lineTo(center.dx, center.dy + unit);
    path.lineTo(center.dx - unit, center.dy + unit);
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, strokePaint);
  }

  void _drawTShape(Canvas canvas, Offset center, double scale, Paint paint, Paint strokePaint) {
    final path = Path();
    final unit = scale * 0.3;

    path.moveTo(center.dx - 1.5 * unit, center.dy - unit);
    path.lineTo(center.dx + 1.5 * unit, center.dy - unit);
    path.lineTo(center.dx + 1.5 * unit, center.dy);
    path.lineTo(center.dx + 0.5 * unit, center.dy);
    path.lineTo(center.dx + 0.5 * unit, center.dy + unit);
    path.lineTo(center.dx - 0.5 * unit, center.dy + unit);
    path.lineTo(center.dx - 0.5 * unit, center.dy);
    path.lineTo(center.dx - 1.5 * unit, center.dy);
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, strokePaint);
  }

  void _drawTrapezoid(Canvas canvas, Offset center, double scale, Paint paint, Paint strokePaint) {
    final path = Path();
    final width = scale * 0.7;
    final height = scale * 0.6;

    path.moveTo(center.dx - width * 0.6, center.dy - height);
    path.lineTo(center.dx + width * 0.6, center.dy - height);
    path.lineTo(center.dx + width, center.dy + height);
    path.lineTo(center.dx - width, center.dy + height);
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, strokePaint);
  }

  void _drawIrregular(Canvas canvas, Offset center, double scale, Paint paint, Paint strokePaint) {
    final path = Path();
    final unit = scale * 0.3;

    path.moveTo(center.dx, center.dy - 1.5 * unit);
    path.lineTo(center.dx + 1.2 * unit, center.dy - 0.5 * unit);
    path.lineTo(center.dx + unit, center.dy + unit);
    path.lineTo(center.dx - 0.8 * unit, center.dy + 1.2 * unit);
    path.lineTo(center.dx - 1.3 * unit, center.dy - 0.3 * unit);
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
