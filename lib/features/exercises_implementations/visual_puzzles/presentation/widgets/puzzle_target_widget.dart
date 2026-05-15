import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../domain/puzzle_generator.dart';
import 'puzzle_piece_widget.dart' show PuzzlePiecePainterFacade;

/// Widget affichant la silhouette cible que les 3 pièces doivent former.
///
/// Layout : carte 1:1 ratio responsive (s'adapte à la largeur du parent),
/// contour Kepler VSI, fond surfaceContainerHighest pour adaptation dark mode.
class PuzzleTargetWidget extends StatelessWidget {
  const PuzzleTargetWidget({super.key, required this.item});

  final PuzzleItem item;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = AppColors.accentForBrightness(
        AppColors.indexVSI, Theme.of(context).brightness);

    // Ratio adaptatif selon le layout : rangée 3×1 → 3:1.4, colonne 1×3 → 1:2.2,
    // carré 2×2 → 1:1. On compresse les ratios extrêmes pour éviter une cible
    // trop fine sur mobile.
    final rawRatio = item.gridCols / item.gridRows;
    final aspect = rawRatio >= 1 ? math.min(rawRatio, 2.0) : math.max(rawRatio, 0.5);

    return Semantics(
      label: 'Silhouette cible — niveau ${item.level.label}, item ${item.index} sur 26',
      child: AspectRatio(
        aspectRatio: aspect,
        child: Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: accent.withValues(alpha: 0.35),
              width: 1.5,
            ),
          ),
          child: Stack(
            children: [
              // Eyebrow "CIBLE" en haut-gauche
              Positioned(
                top: 10.h,
                left: 12.w,
                child: Text('CIBLE',
                    style: AppText.monoLabel(color: accent)),
              ),
              // Compteur niveau en haut-droite
              Positioned(
                top: 10.h,
                right: 12.w,
                child: Text(item.level.label.toUpperCase(),
                    style: AppText.monoLabel(color: cs.outline)),
              ),
              // Silhouette dessinée par CustomPaint, occupe la zone centrale
              Padding(
                padding: EdgeInsets.fromLTRB(24.w, 36.h, 24.w, 24.h),
                child: CustomPaint(
                  painter: _TargetPainter(
                    item: item,
                    fillColor: accent.withValues(alpha: 0.18),
                    strokeColor: accent,
                  ),
                  size: Size.infinite,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Painter qui compose les 3 targetPieces dans une grille gridCols × gridRows.
/// Chaque pièce est dessinée à sa position (gridX, gridY) avec ses arêtes,
/// pour que la silhouette finale soit l'union interlock des 3 pièces.
class _TargetPainter extends CustomPainter {
  _TargetPainter({
    required this.item,
    required this.fillColor,
    required this.strokeColor,
  });

  final PuzzleItem item;
  final Color fillColor;
  final Color strokeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final cols = item.gridCols;
    final rows = item.gridRows;
    final cellW = size.width / cols;
    final cellH = size.height / rows;

    // Pour la silhouette globale, on dessine chaque pièce dans sa cellule.
    // Les arêtes complémentaires entre pièces adjacentes créent l'illusion
    // de pièces qui s'emboîtent.
    for (final piece in item.targetPieces) {
      final dx = piece.gridX * cellW;
      final dy = piece.gridY * cellH;
      final pieceRect = Rect.fromLTWH(dx, dy, cellW * piece.gridW, cellH * piece.gridH);
      canvas.save();
      canvas.translate(pieceRect.left, pieceRect.top);
      PuzzlePiecePainterFacade.paintPiece(
        canvas: canvas,
        piece: piece,
        size: pieceRect.size,
        fillColor: fillColor,
        strokeColor: strokeColor,
        // Pour la cible, on étire la pièce à toute la cellule (pas de scale individuel)
        forceFullCell: true,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _TargetPainter old) => old.item != item;
}
