import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../domain/geometry.dart';
import '../../domain/puzzle_generator.dart';

/// Silhouette cible colorée par sections.
///
/// Affiche la figure DÉCOUPÉE en 3 zones colorées (couleur de la pièce
/// correspondante) séparées par des lignes blanches. L'apprenant voit
/// exactement comment la figure est découpée ; la difficulté vient de
/// devoir trouver LAQUELLE parmi les 6 options correspond à chaque zone
/// (surtout quand les pièces sont pivotées aux niveaux difficiles).
class PuzzleTargetWidget extends StatelessWidget {
  const PuzzleTargetWidget({
    super.key,
    required this.item,
    required this.sectionColors,
    this.maxWidth = 330,
    this.maxHeight = 250,
  });

  final PuzzleItem item;

  /// Couleur de chaque pièce correcte (même ordre que item.correctPieces).
  final List<Color> sectionColors;

  final double maxWidth;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = AppColors.accentForBrightness(
        AppColors.indexVSI, Theme.of(context).brightness);

    return Semantics(
      label: 'Figure cible, item ${item.index}',
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: Container(
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: accent.withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 8,
                    left: 12,
                    child: Text('FIGURE À RECONSTITUER',
                        style: AppText.mono(color: accent, size: 10)),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 28, 18, 14),
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: _SectionsPainter(
                        target: item.targetPolygon,
                        sections: item.correctPieces
                            .map((p) => p.polygon)
                            .toList(),
                        sectionColors: sectionColors,
                        borderColor: accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dessine la figure cible découpée en sections colorées.
///
/// Toutes les pièces sont dans l'espace normalisé [0,1]² de la cible —
/// le même transform (scale + offset centré) est appliqué à toutes pour
/// qu'elles s'assemblent parfaitement.
class _SectionsPainter extends CustomPainter {
  const _SectionsPainter({
    required this.target,
    required this.sections,
    required this.sectionColors,
    required this.borderColor,
  });

  final Polygon target;
  final List<Polygon> sections;
  final List<Color> sectionColors;
  final Color borderColor;

  static const double _padding = 0.09;

  @override
  void paint(Canvas canvas, Size size) {
    if (target.vertices.isEmpty) return;

    // ---- Transform commun : bbox de la cible → canvas centré ----
    final bbox = target.bbox();
    final polyW = bbox.width;
    final polyH = bbox.height;
    if (polyW < kGeomEps || polyH < kGeomEps) return;

    final availW = size.width * (1 - 2 * _padding);
    final availH = size.height * (1 - 2 * _padding);
    final scale = math.min(availW / polyW, availH / polyH);

    final ox = size.width / 2 - (bbox.left + bbox.right) / 2 * scale;
    final oy = size.height / 2 - (bbox.top + bbox.bottom) / 2 * scale;

    Offset t(Offset p) => Offset(p.dx * scale + ox, p.dy * scale + oy);

    Path makePath(Polygon poly) {
      final path = Path();
      if (poly.vertices.isEmpty) return path;
      final first = t(poly.vertices.first);
      path.moveTo(first.dx, first.dy);
      for (int i = 1; i < poly.vertices.length; i++) {
        final pt = t(poly.vertices[i]);
        path.lineTo(pt.dx, pt.dy);
      }
      path.close();
      return path;
    }

    // ---- 1. Sections colorées (fill + ligne de découpe) ----
    for (int i = 0; i < sections.length && i < sectionColors.length; i++) {
      final path = makePath(sections[i]);
      final color = sectionColors[i];

      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: 0.72)
          ..style = PaintingStyle.fill,
      );

      // Ligne de découpe visible entre les sections
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.92)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeJoin = StrokeJoin.round,
      );
    }

    // ---- 2. Contour extérieur de la figure ----
    canvas.drawPath(
      makePath(target),
      Paint()
        ..color = borderColor.withValues(alpha: 0.90)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_SectionsPainter old) =>
      old.target != target ||
      old.sections != sections ||
      old.sectionColors != sectionColors;
}
