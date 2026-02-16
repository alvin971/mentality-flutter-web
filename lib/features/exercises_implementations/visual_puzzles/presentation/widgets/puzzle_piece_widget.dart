import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:math' as math;
import '../../domain/puzzle_generator.dart';

/// Widget pour afficher une pièce de puzzle
class PuzzlePieceWidget extends StatelessWidget {
  final PuzzlePiece piece;
  final double size;
  final bool isSelected;
  final VoidCallback? onTap;

  const PuzzlePieceWidget({
    super.key,
    required this.piece,
    this.size = 80,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size.w,
        height: size.w,
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isSelected ? Colors.blue.shade600 : Colors.grey.shade300,
            width: isSelected ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: CustomPaint(
          painter: _PuzzlePiecePainter(
            shape: piece.shape,
            rotation: piece.rotation,
            isMirrored: piece.isMirrored,
            scale: piece.scale,
          ),
        ),
      ),
    );
  }
}

/// Painter pour dessiner les formes de pièces de puzzle
class _PuzzlePiecePainter extends CustomPainter {
  final PieceShape shape;
  final double rotation;
  final bool isMirrored;
  final double scale;

  _PuzzlePiecePainter({
    required this.shape,
    required this.rotation,
    required this.isMirrored,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.shade400
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final center = Offset(size.width / 2, size.height / 2);

    // Appliquer les transformations (ordre: rotation, miroir, échelle)
    canvas.save();
    canvas.translate(center.dx, center.dy);

    // Rotation
    canvas.rotate(rotation * math.pi / 180);

    // Miroir horizontal (WAIS-IV REF error)
    if (isMirrored) {
      canvas.scale(-1.0, 1.0);
    }

    // Échelle (WAIS-IV SCALE error: 0.7-1.3)
    canvas.scale(scale, scale);

    canvas.translate(-center.dx, -center.dy);

    switch (shape) {
      case PieceShape.square:
        _drawSquare(canvas, size, paint, strokePaint);
        break;
      case PieceShape.rectangleHorizontal:
        _drawRectangleHorizontal(canvas, size, paint, strokePaint);
        break;
      case PieceShape.rectangleVertical:
        _drawRectangleVertical(canvas, size, paint, strokePaint);
        break;
      case PieceShape.triangle:
        _drawTriangle(canvas, size, paint, strokePaint);
        break;
      case PieceShape.triangleSmall:
        _drawTriangleSmall(canvas, size, paint, strokePaint);
        break;
      case PieceShape.circle:
        _drawCircle(canvas, size, paint, strokePaint);
        break;
      case PieceShape.circleSector:
        _drawCircleSector(canvas, size, paint, strokePaint);
        break;
      case PieceShape.diamond:
        _drawDiamond(canvas, size, paint, strokePaint);
        break;
      case PieceShape.lShape:
        _drawLShape(canvas, size, paint, strokePaint);
        break;
      case PieceShape.tShape:
        _drawTShape(canvas, size, paint, strokePaint);
        break;
      case PieceShape.trapezoid:
        _drawTrapezoid(canvas, size, paint, strokePaint);
        break;
      case PieceShape.irregular:
        _drawIrregular(canvas, size, paint, strokePaint);
        break;
    }

    canvas.restore();
  }

  void _drawSquare(Canvas canvas, Size size, Paint paint, Paint strokePaint) {
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.6,
      height: size.width * 0.6,
    );
    canvas.drawRect(rect, paint);
    canvas.drawRect(rect, strokePaint);
  }

  void _drawRectangleHorizontal(Canvas canvas, Size size, Paint paint, Paint strokePaint) {
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.7,
      height: size.width * 0.4,
    );
    canvas.drawRect(rect, paint);
    canvas.drawRect(rect, strokePaint);
  }

  void _drawRectangleVertical(Canvas canvas, Size size, Paint paint, Paint strokePaint) {
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.4,
      height: size.width * 0.7,
    );
    canvas.drawRect(rect, paint);
    canvas.drawRect(rect, strokePaint);
  }

  void _drawTriangle(Canvas canvas, Size size, Paint paint, Paint strokePaint) {
    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.35;

    path.moveTo(center.dx, center.dy - radius);
    path.lineTo(center.dx - radius, center.dy + radius);
    path.lineTo(center.dx + radius, center.dy + radius);
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, strokePaint);
  }

  void _drawTriangleSmall(Canvas canvas, Size size, Paint paint, Paint strokePaint) {
    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.25;

    path.moveTo(center.dx, center.dy - radius);
    path.lineTo(center.dx - radius, center.dy + radius);
    path.lineTo(center.dx + radius, center.dy + radius);
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, strokePaint);
  }

  void _drawCircle(Canvas canvas, Size size, Paint paint, Paint strokePaint) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.3;

    canvas.drawCircle(center, radius, paint);
    canvas.drawCircle(center, radius, strokePaint);
  }

  void _drawCircleSector(Canvas canvas, Size size, Paint paint, Paint strokePaint) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.35;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final path = Path();
    path.moveTo(center.dx, center.dy);
    path.arcTo(rect, -math.pi / 2, 2 * math.pi / 3, false);
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, strokePaint);
  }

  void _drawDiamond(Canvas canvas, Size size, Paint paint, Paint strokePaint) {
    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.35;

    path.moveTo(center.dx, center.dy - radius);
    path.lineTo(center.dx + radius, center.dy);
    path.lineTo(center.dx, center.dy + radius);
    path.lineTo(center.dx - radius, center.dy);
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, strokePaint);
  }

  void _drawLShape(Canvas canvas, Size size, Paint paint, Paint strokePaint) {
    final path = Path();
    final unit = size.width * 0.2;
    final center = Offset(size.width / 2, size.height / 2);

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

  void _drawTShape(Canvas canvas, Size size, Paint paint, Paint strokePaint) {
    final path = Path();
    final unit = size.width * 0.15;
    final center = Offset(size.width / 2, size.height / 2);

    // Barre horizontale du T
    path.moveTo(center.dx - 1.5 * unit, center.dy - unit);
    path.lineTo(center.dx + 1.5 * unit, center.dy - unit);
    path.lineTo(center.dx + 1.5 * unit, center.dy);
    // Barre verticale du T
    path.lineTo(center.dx + 0.5 * unit, center.dy);
    path.lineTo(center.dx + 0.5 * unit, center.dy + unit);
    path.lineTo(center.dx - 0.5 * unit, center.dy + unit);
    path.lineTo(center.dx - 0.5 * unit, center.dy);
    path.lineTo(center.dx - 1.5 * unit, center.dy);
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, strokePaint);
  }

  void _drawTrapezoid(Canvas canvas, Size size, Paint paint, Paint strokePaint) {
    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final width = size.width * 0.35;
    final height = size.width * 0.3;

    path.moveTo(center.dx - width * 0.6, center.dy - height);
    path.lineTo(center.dx + width * 0.6, center.dy - height);
    path.lineTo(center.dx + width, center.dy + height);
    path.lineTo(center.dx - width, center.dy + height);
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, strokePaint);
  }

  void _drawIrregular(Canvas canvas, Size size, Paint paint, Paint strokePaint) {
    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final unit = size.width * 0.15;

    // Forme irrégulière à 5 côtés
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
