import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Logo Mental E.T. — tête silhouette + 3 orbites elliptiques + 6 dots animés.
///
/// Le canvas est en coordonnées 32×32, automatiquement scalé par `size`.
class EtLogoAnimated extends StatefulWidget {
  const EtLogoAnimated({super.key, this.size = 64, this.color});

  final double size;
  final Color? color;

  @override
  State<EtLogoAnimated> createState() => _EtLogoAnimatedState();
}

class _EtLogoAnimatedState extends State<EtLogoAnimated>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => CustomPaint(
          painter: _OrbitPainter(
            progress: _c.value,
            color: widget.color ?? AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  _OrbitPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  Offset _dotOnOrbit(
      double cx, double cy, double a, double b, double theta, double angle) {
    final xLocal = a * math.cos(angle);
    final yLocal = b * math.sin(angle);
    final xWorld =
        xLocal * math.cos(theta) - yLocal * math.sin(theta) + cx;
    final yWorld =
        xLocal * math.sin(theta) + yLocal * math.cos(theta) + cy;
    return Offset(xWorld, yWorld);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 32.0;
    canvas.scale(scale);

    const cx = 16.0;
    const cy = 16.0;

    final headPath = Path()
      ..moveTo(cx, cy - 8.0)
      ..cubicTo(cx + 9.0, cy - 8.5, cx + 9.5, cy - 2.0, cx + 8.0, cy + 1.5)
      ..cubicTo(cx + 6.0, cy + 5.0, cx + 3.5, cy + 7.0, cx, cy + 7.0)
      ..cubicTo(cx - 3.5, cy + 7.0, cx - 6.0, cy + 5.0, cx - 8.0, cy + 1.5)
      ..cubicTo(cx - 9.5, cy - 2.0, cx - 9.0, cy - 8.5, cx, cy - 8.0)
      ..close();

    final headPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(headPath, headPaint);

    final eyePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(const Offset(cx - 6.0, cy - 2.5), 2.5, eyePaint);
    canvas.drawCircle(const Offset(cx + 6.0, cy - 2.5), 2.5, eyePaint);

    final nosePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(cx - 1.5, cy), 0.8, nosePaint);
    canvas.drawCircle(const Offset(cx + 1.5, cy), 0.8, nosePaint);

    final orbitPaint = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;

    const a = 12.0;
    const b = 4.0;
    final orbits = [0.0, math.pi / 3, -math.pi / 3];

    for (final theta in orbits) {
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(theta);
      canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: a * 2, height: b * 2),
          orbitPaint);
      canvas.restore();
    }

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final baseAngles = [
      progress * 2 * math.pi * 1,
      progress * 2 * math.pi * 2 + (2 * math.pi / 3),
      progress * 2 * math.pi * 3 + (4 * math.pi / 3),
    ];

    for (int i = 0; i < 3; i++) {
      final pos1 = _dotOnOrbit(cx, cy, a, b, orbits[i], baseAngles[i]);
      canvas.drawCircle(pos1, 2.0, dotPaint);
      final pos2 =
          _dotOnOrbit(cx, cy, a, b, orbits[i], baseAngles[i] + math.pi);
      canvas.drawCircle(pos2, 2.0, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_OrbitPainter old) =>
      old.progress != progress || old.color != color;
}
