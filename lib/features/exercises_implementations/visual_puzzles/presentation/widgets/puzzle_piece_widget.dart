import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../domain/puzzle_generator.dart';
import 'polygon_painter.dart';

class PuzzlePieceWidget extends StatelessWidget {
  const PuzzlePieceWidget({
    super.key,
    required this.piece,
    required this.label,
    this.isSelected = false,
    this.showCorrect = false,
    this.showIncorrect = false,
    this.onTap,
  });

  final PuzzlePiece piece;
  final String label;
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
          borderRadius: BorderRadius.circular(12.r),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: isSelected
                  ? accent.withValues(alpha: 0.12)
                  : cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12.r),
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
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(label,
                      style: AppText.monoLabel(color: accent)),
                ),
                SizedBox(height: 4.h),
                Expanded(
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: PolygonPainter(
                      polygon: piece.polygon,
                      fillColor: accent.withValues(alpha: 0.22),
                      strokeColor: accent,
                    ),
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
