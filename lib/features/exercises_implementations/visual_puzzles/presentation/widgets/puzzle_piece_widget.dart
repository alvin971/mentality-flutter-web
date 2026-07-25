import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../../core/l10n/l10n_ext.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../domain/puzzle_generator.dart';
import 'polygon_painter.dart';

/// Case d'option : une pièce numérotée (1-6), dessinée à l'ÉCHELLE COMMUNE
/// de l'item (`item.maxPieceExtent`) — les tailles relatives des 6 pièces
/// sont fidèles, condition indispensable pour repérer les pièges de taille.
///
/// La pièce est remplie avec ses RÉGIONS colorées (fragments du motif de la
/// cible) : la couleur fait partie du problème, pas de la solution.
///
/// NOTE : dimensionné en pixels logiques (pas de ScreenUtil) pour rester
/// stable sur desktop comme sur mobile.
class PuzzlePieceWidget extends StatelessWidget {
  const PuzzlePieceWidget({
    super.key,
    required this.piece,
    required this.label,
    required this.unitsPerTile,
    required this.palette,
    this.isSelected = false,
    this.showCorrect = false,
    this.showIncorrect = false,
    this.onTap,
  });

  final PuzzlePiece piece;
  final String label;

  /// Échelle commune : plus grande dimension affichée parmi les 6 options.
  final double unitsPerTile;

  /// Palette de l'item (colorIndex des régions → couleur réelle).
  final List<Color> palette;

  final bool isSelected;
  final bool showCorrect;
  final bool showIncorrect;
  final VoidCallback? onTap;

  /// Pixels par unité normalisée pour une case CARRÉE de côté [tileSide].
  ///
  /// DOIT rester aligné sur la géométrie interne du widget : padding du
  /// conteneur (4 de chaque côté), zone de dessin LTRB(4, 20, 4, 4) — bande
  /// haute réservée à la pastille — et padding 0.03 du painter.
  ///
  /// Sert à dessiner la FIGURE CIBLE à la MÊME échelle que les pièces
  /// (échelle unifiée : les 3 bonnes pièces s'additionnent visuellement à
  /// la taille affichée de la cible).
  static double pixelsPerUnit(double tileSide, double unitsPerTile) {
    // Côté le plus court de la zone de dessin : hauteur = tile − 8 − 24.
    final paintShortest = math.max(tileSide - 32.0, 1.0);
    return paintShortest * 0.94 / math.max(unitsPerTile, 1e-6);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = AppColors.accentForBrightness(
        AppColors.indexVSI, Theme.of(context).brightness);

    Color borderColor;
    double borderWidth;
    if (showCorrect) {
      borderColor = AppColors.success;
      borderWidth = 3;
    } else if (showIncorrect) {
      borderColor = AppColors.error;
      borderWidth = 3;
    } else if (isSelected) {
      borderColor = accent;
      borderWidth = 3;
    } else {
      borderColor = cs.outline.withValues(alpha: 0.3);
      borderWidth = 1;
    }

    return Semantics(
      button: true,
      label: context.l10n.vpPieceSemantics(label),
      selected: isSelected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isSelected
                  ? accent.withValues(alpha: 0.12)
                  : cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: borderWidth),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.30),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              children: [
                // Bande haute réservée à la pastille (20 px + marge) : le
                // numéro ne recouvre JAMAIS le dessin de la pièce. Padding
                // identique sur les 6 cases → l'échelle commune (et donc la
                // détection des pièges de taille) est préservée.
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 20, 4, 4),
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: RegionedPolygonPainter(
                      polygon: piece.displayPolygon,
                      regions: piece.displayRegions,
                      palette: palette,
                      outlineColor: cs.outline.withValues(alpha: 0.55),
                      padding: 0.03,
                      unitsPerTile: unitsPerTile,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(label,
                        style: AppText.of(context).mono(color: accent, size: 11)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
