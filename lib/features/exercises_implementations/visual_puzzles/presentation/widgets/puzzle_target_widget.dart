import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../domain/geometry.dart';
import '../../domain/puzzle_generator.dart';

/// Figure cible : le MOTIF coloré complet, SANS lignes de découpe.
///
/// Comme dans le subtest réel : la figure est montrée intacte (zones de
/// couleur du dessin visibles, frontières de découpe invisibles) — c'est au
/// sujet de décomposer mentalement la figure et de retrouver les 3 pièces,
/// en vérifiant à la fois la GÉOMÉTRIE et la CONTINUITÉ DU MOTIF.
class PuzzleTargetWidget extends StatelessWidget {
  const PuzzleTargetWidget({
    super.key,
    required this.item,
    this.maxWidth = 330,
    this.maxHeight = 250,
  });

  final PuzzleItem item;
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
                      painter: _TargetPainter(
                        target: item.targetPolygon,
                        zones: item.colorZones,
                        palette: item.palette,
                        outlineColor: cs.outline.withValues(alpha: 0.55),
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

/// Dessine le motif coloré de la cible : zones pleines (couleurs franches),
/// AUCUNE ligne interne, fin contour extérieur.
class _TargetPainter extends CustomPainter {
  const _TargetPainter({
    required this.target,
    required this.zones,
    required this.palette,
    required this.outlineColor,
  });

  final Polygon target;
  final List<ColoredRegion> zones;
  final List<Color> palette;
  final Color outlineColor;

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

    Path makePath(Polygon poly) {
      final path = Path();
      if (poly.vertices.isEmpty) return path;
      Offset t(Offset p) => Offset(p.dx * scale + ox, p.dy * scale + oy);
      final first = t(poly.vertices.first);
      path.moveTo(first.dx, first.dy);
      for (int i = 1; i < poly.vertices.length; i++) {
        final pt = t(poly.vertices[i]);
        path.lineTo(pt.dx, pt.dy);
      }
      path.close();
      return path;
    }

    // ---- Zones du motif : aplats pleins, jointures scellées par un léger
    // stroke de la même couleur (évite les fines coutures d'anti-aliasing).
    for (final z in zones) {
      if (z.polygon.vertices.length < 3) continue;
      final color = palette[z.colorIndex % palette.length];
      final path = makePath(z.polygon);
      canvas.drawPath(path, Paint()..color = color);
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..strokeJoin = StrokeJoin.round,
      );
    }

    // ---- Fin contour extérieur (bord "imprimé") ----
    canvas.drawPath(
      makePath(target),
      Paint()
        ..color = outlineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_TargetPainter old) =>
      old.target != target || old.zones != zones || old.palette != palette;
}
