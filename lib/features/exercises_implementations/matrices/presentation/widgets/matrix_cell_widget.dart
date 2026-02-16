import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../domain/matrix_generator.dart';

/// Widget pour afficher une cellule de matrice
class MatrixCellWidget extends StatelessWidget {
  final MatrixCell? cell;
  final double size;
  final bool isOption;
  final bool isSelected;
  final VoidCallback? onTap;

  const MatrixCellWidget({
    super.key,
    this.cell,
    this.size = 80,
    this.isOption = false,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.blue : (isOption ? Colors.grey.shade400 : Colors.grey.shade600),
            width: isSelected ? 3 : (isOption ? 2 : 1),
          ),
          color: isOption
              ? (isSelected ? Colors.blue.shade50 : Colors.white)
              : Colors.grey.shade100,
        ),
        child: cell == null || cell!.isEmpty
            ? _buildEmptyCell()
            : _buildCellContent(),
      ),
    );
  }

  Widget _buildEmptyCell() {
    return cell == null
        ? Center(
            child: Text(
              '?',
              style: TextStyle(
                fontSize: size * 0.5,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade400,
              ),
            ),
          )
        : const SizedBox.shrink();
  }

  Widget _buildCellContent() {
    // Gérer plusieurs formes si count > 1
    if (cell!.count > 1) {
      return _buildMultipleShapes();
    }

    return Center(
      child: Transform.rotate(
        angle: cell!.rotation * math.pi / 180,
        child: CustomPaint(
          size: Size(size * 0.6 * cell!.size / 3, size * 0.6 * cell!.size / 3),
          painter: ShapePainter(
            shape: cell!.shape,
            color: _getCellColor(),
          ),
        ),
      ),
    );
  }

  Widget _buildMultipleShapes() {
    final shapeSize = size * 0.3 * cell!.size / 3;
    final spacing = 4.0;

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      alignment: WrapAlignment.center,
      runAlignment: WrapAlignment.center,
      children: List.generate(cell!.count, (index) {
        return Transform.rotate(
          angle: cell!.rotation * math.pi / 180,
          child: CustomPaint(
            size: Size(shapeSize, shapeSize),
            painter: ShapePainter(
              shape: cell!.shape,
              color: _getCellColor(),
            ),
          ),
        );
      }),
    );
  }

  Color _getCellColor() {
    switch (cell!.color) {
      case CellColor.black:
        return Colors.black;
      case CellColor.white:
        return Colors.white;
      case CellColor.gray:
        return Colors.grey;
    }
  }
}

/// Painter pour dessiner les formes géométriques
class ShapePainter extends CustomPainter {
  final MatrixShape shape;
  final Color color;

  ShapePainter({required this.shape, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    switch (shape) {
      case MatrixShape.circle:
        canvas.drawCircle(center, radius, paint);
        canvas.drawCircle(center, radius, strokePaint);
        break;

      case MatrixShape.square:
        final rect = Rect.fromCenter(center: center, width: size.width, height: size.height);
        canvas.drawRect(rect, paint);
        canvas.drawRect(rect, strokePaint);
        break;

      case MatrixShape.triangle:
        final path = Path()
          ..moveTo(center.dx, center.dy - radius)
          ..lineTo(center.dx - radius, center.dy + radius)
          ..lineTo(center.dx + radius, center.dy + radius)
          ..close();
        canvas.drawPath(path, paint);
        canvas.drawPath(path, strokePaint);
        break;

      case MatrixShape.diamond:
        final path = Path()
          ..moveTo(center.dx, center.dy - radius)
          ..lineTo(center.dx + radius, center.dy)
          ..lineTo(center.dx, center.dy + radius)
          ..lineTo(center.dx - radius, center.dy)
          ..close();
        canvas.drawPath(path, paint);
        canvas.drawPath(path, strokePaint);
        break;

      case MatrixShape.star:
        _drawStar(canvas, center, radius, paint, strokePaint);
        break;

      case MatrixShape.hexagon:
        _drawHexagon(canvas, center, radius, paint, strokePaint);
        break;
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint fillPaint, Paint strokePaint) {
    final path = Path();
    const numPoints = 5;
    final angleStep = 2 * math.pi / numPoints;

    for (int i = 0; i < numPoints * 2; i++) {
      final angle = i * angleStep / 2 - math.pi / 2;
      final r = i % 2 == 0 ? radius : radius * 0.4;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
  }

  void _drawHexagon(Canvas canvas, Offset center, double radius, Paint fillPaint, Paint strokePaint) {
    final path = Path();
    const numSides = 6;
    final angleStep = 2 * math.pi / numSides;

    for (int i = 0; i < numSides; i++) {
      final angle = i * angleStep - math.pi / 2;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(ShapePainter oldDelegate) {
    return oldDelegate.shape != shape || oldDelegate.color != color;
  }
}
