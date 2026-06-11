import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../domain/puzzle_generator.dart';
import 'polygon_painter.dart';

/// Case d'option : une pièce numérotée (1-6), dessinée à l'ÉCHELLE COMMUNE
/// de l'item (`item.maxPieceExtent`) — les tailles relatives des 6 pièces
/// sont fidèles, condition indispensable pour repérer les pièges de taille.
///
/// NOTE : dimensionné en pixels logiques (pas de ScreenUtil) pour rester
/// stable sur desktop comme sur mobile.
class PuzzlePieceWidget extends StatelessWidget {
  const PuzzlePieceWidget({
    super.key,
    required this.piece,
    required this.label,
    required this.unitsPerTile,
    this.isSelected = false,
    this.showCorrect = false,
    this.showIncorrect = false,
    this.onTap,
  });

  final PuzzlePiece piece;
  final String label;

  /// Échelle commune : plus grande dimension affichée parmi les 6 options.
  final double unitsPerTile;

  final bool isSelected;
  final bool showCorrect;
  final bool showIncorrect;
  final VoidCallback? onTap;

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
      label: 'Pièce $label',
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
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: PolygonPainter(
                      polygon: piece.displayPolygon,
                      fillColor: accent.withValues(alpha: 0.22),
                      strokeColor: accent,
                      strokeWidth: 2.2,
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
                        style: AppText.mono(color: accent, size: 11)),
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
