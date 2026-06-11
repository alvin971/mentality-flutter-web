import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../domain/balance_generator.dart';

/// Widget pour afficher un jeton de forme géométrique
class TokenWidget extends StatelessWidget {
  final Token token;
  final double size;

  const TokenWidget({
    super.key,
    required this.token,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    // Si count > 4, afficher la forme avec un multiplicateur (ex: "5×●")
    if (token.count > 4) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${token.count}×',
            style: TextStyle(
              fontSize: size.sp * 0.6,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(width: 2.w),
          _buildSingleToken(),
        ],
      );
    }

    // Afficher plusieurs formes si count 2-4
    if (token.count > 1) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          token.count,
          (index) => Padding(
            padding: EdgeInsets.only(right: index < token.count - 1 ? 4.w : 0),
            child: _buildSingleToken(),
          ),
        ),
      );
    }

    return _buildSingleToken();
  }

  Widget _buildSingleToken() {
    return SizedBox(
      width: size.w,
      height: size.w,
      child: CustomPaint(
        painter: _TokenPainter(
          shape: token.shape,
          fraction: token.fraction ?? 1.0,
        ),
      ),
    );
  }
}

/// Painter pour dessiner les formes géométriques
class _TokenPainter extends CustomPainter {
  final TokenShape shape;
  final double fraction;

  _TokenPainter({
    required this.shape,
    required this.fraction,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _getColor()
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * 0.8;

    switch (shape) {
      case TokenShape.circle:
        canvas.drawCircle(center, radius, paint);
        canvas.drawCircle(center, radius, strokePaint);
        break;

      case TokenShape.square:
        final rect = Rect.fromCenter(
          center: center,
          width: radius * 2,
          height: radius * 2,
        );
        canvas.drawRect(rect, paint);
        canvas.drawRect(rect, strokePaint);
        break;

      case TokenShape.triangle:
        final path = Path();
        path.moveTo(center.dx, center.dy - radius);
        path.lineTo(center.dx - radius, center.dy + radius);
        path.lineTo(center.dx + radius, center.dy + radius);
        path.close();
        canvas.drawPath(path, paint);
        canvas.drawPath(path, strokePaint);
        break;

      case TokenShape.diamond:
        final path = Path();
        path.moveTo(center.dx, center.dy - radius);
        path.lineTo(center.dx + radius, center.dy);
        path.lineTo(center.dx, center.dy + radius);
        path.lineTo(center.dx - radius, center.dy);
        path.close();
        canvas.drawPath(path, paint);
        canvas.drawPath(path, strokePaint);
        break;

      case TokenShape.star:
        final path = _createStarPath(center, radius, 5);
        canvas.drawPath(path, paint);
        canvas.drawPath(path, strokePaint);
        break;

      case TokenShape.hexagon:
        final path = _createHexagonPath(center, radius);
        canvas.drawPath(path, paint);
        canvas.drawPath(path, strokePaint);
        break;
    }

    // Afficher la fraction réelle si < 1.0 (ex: ½, ⅖, ⅙)
    if (fraction < 1.0 && fraction > 0) {
      final label = _fractionLabel(fraction);
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: Colors.black,
            fontSize: size.width * (label.length > 1 ? 0.32 : 0.4),
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          center.dx - textPainter.width / 2,
          center.dy - textPainter.height / 2,
        ),
      );
    }
  }

  /// Retrouve la fraction n/d la plus proche du double stocké et la formate
  /// (caractère unicode si disponible, sinon "n/d").
  String _fractionLabel(double fraction) {
    const vulgars = {
      '1/2': '½',
      '1/3': '⅓',
      '2/3': '⅔',
      '1/4': '¼',
      '3/4': '¾',
      '1/5': '⅕',
      '2/5': '⅖',
      '3/5': '⅗',
      '4/5': '⅘',
      '1/6': '⅙',
      '5/6': '⅚',
    };
    for (int d = 2; d <= 12; d++) {
      final n = (fraction * d).round();
      if (n >= 1 && n < d && ((n / d) - fraction).abs() < 0.001) {
        final g = _gcd(n, d);
        final key = '${n ~/ g}/${d ~/ g}';
        return vulgars[key] ?? key;
      }
    }
    return fraction.toStringAsFixed(2);
  }

  int _gcd(int a, int b) => b == 0 ? a : _gcd(b, a % b);

  Color _getColor() {
    switch (shape) {
      case TokenShape.circle:
        return Colors.blue.shade400;
      case TokenShape.square:
        return Colors.red.shade400;
      case TokenShape.triangle:
        return Colors.green.shade400;
      case TokenShape.diamond:
        return Colors.orange.shade400;
      case TokenShape.star:
        return Colors.purple.shade400;
      case TokenShape.hexagon:
        return Colors.teal.shade400;
    }
  }

  Path _createStarPath(Offset center, double radius, int points) {
    final path = Path();
    final step = math.pi / points;
    final innerRadius = radius * 0.5;

    for (int i = 0; i < points * 2; i++) {
      final r = i % 2 == 0 ? radius : innerRadius;
      final x = center.dx + r * math.cos(i * step - math.pi / 2);
      final y = center.dy + r * math.sin(i * step - math.pi / 2);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  Path _createHexagonPath(Offset center, double radius) {
    final path = Path();
    const points = 6;
    final angle = math.pi * 2 / points;

    for (int i = 0; i < points; i++) {
      final x = center.dx + radius * math.cos(i * angle - math.pi / 2);
      final y = center.dy + radius * math.sin(i * angle - math.pi / 2);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
