import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../../core/l10n/l10n_ext.dart';
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
///
/// ÉCHELLE UNIFIÉE : si [pixelsPerUnit] est fourni (px par unité normalisée,
/// calculé depuis la taille des cases via [PuzzlePieceWidget.pixelsPerUnit]),
/// la cible est dessinée à la MÊME échelle que les 6 pièces — additionner
/// visuellement les 3 bonnes pièces redonne exactement la taille affichée
/// de la figure. Le cadre se dimensionne alors au contenu.
class PuzzleTargetWidget extends StatelessWidget {
  const PuzzleTargetWidget({
    super.key,
    required this.item,
    this.maxWidth = 330,
    this.maxHeight = 250,
    this.pixelsPerUnit,
  });

  final PuzzleItem item;
  final double maxWidth;
  final double maxHeight;

  /// Échelle commune avec les pièces (px / unité normalisée), ou null pour
  /// l'ancien comportement « remplir le cadre ».
  final double? pixelsPerUnit;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = AppColors.accentForBrightness(
        AppColors.indexVSI, Theme.of(context).brightness);

    // Cadre ajusté au contenu quand l'échelle est unifiée (padding du
    // dessin : 18/28/18/14 ; largeur minimale pour le libellé du cartouche).
    final ppu = pixelsPerUnit;
    final BoxConstraints frame;
    if (ppu != null) {
      final bb = item.targetPolygon.bbox();
      final w = (bb.width * ppu + 40).clamp(150.0, maxWidth).toDouble();
      final h = (bb.height * ppu + 46).clamp(96.0, maxHeight).toDouble();
      frame = BoxConstraints.tightFor(width: w, height: h);
    } else {
      frame = BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight);
    }

    return Semantics(
      label: 'Figure cible, item ${item.index}',
      child: Center(
        child: ConstrainedBox(
          constraints: frame,
          child: AspectRatio(
            aspectRatio: ppu != null
                ? frame.maxWidth / frame.maxHeight
                : 4 / 3,
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
                    child: Text(context.l10n.vpTargetTitle,
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
                        pixelsPerUnit: ppu,
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
    this.pixelsPerUnit,
  });

  final Polygon target;
  final List<ColoredRegion> zones;
  final List<Color> palette;
  final Color outlineColor;

  /// Échelle unifiée avec les pièces ; null = remplir la zone (legacy).
  final double? pixelsPerUnit;

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
    final fitScale = math.min(availW / polyW, availH / polyH);
    // Échelle unifiée : même px/unité que les pièces, bornée par la place
    // disponible (le fit ne sert alors que de garde anti-débordement).
    final scale =
        pixelsPerUnit == null ? fitScale : math.min(fitScale, pixelsPerUnit!);

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
      old.target != target ||
      old.zones != zones ||
      old.palette != palette ||
      old.pixelsPerUnit != pixelsPerUnit;
}
