import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  // Logo : fade-in + scale
  late final AnimationController _logoController;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;

  // Texte : fade-in décalé
  late final AnimationController _textController;
  late final Animation<double> _textFade;

  // Dots : rotation continue
  late final AnimationController _dotsController;

  @override
  void initState() {
    super.initState();

    // --- Logo ---
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _logoScale = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );

    // --- Texte ---
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    // --- Dots ---
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    // Séquence de démarrage
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _textController.forward();
    });

    // Navigation après 3s
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) context.go(AppConstants.routeHome);
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo + dots en orbite
              SizedBox(
                width: 180,
                height: 180,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Dots en orbite
                    AnimatedBuilder(
                      animation: _dotsController,
                      builder: (context, _) {
                        return _OrbitingDots(
                          progress: _dotsController.value,
                          radius: 78,
                          dotCount: 3,
                        );
                      },
                    ),

                    // Logo animé
                    ScaleTransition(
                      scale: _logoScale,
                      child: FadeTransition(
                        opacity: _logoFade,
                        child: Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(28),
                          ),
                          padding: const EdgeInsets.all(14),
                          child: Image.asset(
                            'icons/Icon-512.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // Texte
              FadeTransition(
                opacity: _textFade,
                child: Column(
                  children: [
                    const Text(
                      'Mental E.T.',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Évaluation cognitive adaptative',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withOpacity(0.80),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dessine N dots en orbite circulaire autour du centre.
class _OrbitingDots extends StatelessWidget {
  const _OrbitingDots({
    required this.progress,
    required this.radius,
    required this.dotCount,
  });

  final double progress; // 0.0 → 1.0 (rotation continue)
  final double radius;
  final int dotCount;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DotsPainter(
        progress: progress,
        radius: radius,
        dotCount: dotCount,
      ),
      size: Size(radius * 2 + 20, radius * 2 + 20),
    );
  }
}

class _DotsPainter extends CustomPainter {
  _DotsPainter({
    required this.progress,
    required this.radius,
    required this.dotCount,
  });

  final double progress;
  final double radius;
  final int dotCount;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final angleStep = (2 * pi) / dotCount;
    final baseAngle = 2 * pi * progress;

    for (int i = 0; i < dotCount; i++) {
      final angle = baseAngle + angleStep * i;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);

      // Taille et opacité variables selon la position (effet de profondeur)
      final normalizedAngle = (angle % (2 * pi)) / (2 * pi);
      final depthFactor = 0.6 + 0.4 * sin(normalizedAngle * pi);
      final dotRadius = 5.0 * depthFactor + 1.0;
      final opacity = 0.5 + 0.5 * depthFactor;

      final paint = Paint()
        ..color = Colors.white.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), dotRadius, paint);
    }
  }

  @override
  bool shouldRepaint(_DotsPainter old) => old.progress != progress;
}
