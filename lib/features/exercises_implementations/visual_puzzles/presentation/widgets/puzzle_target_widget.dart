import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../domain/puzzle_generator.dart';
import 'polygon_painter.dart';

/// Affiche la silhouette cible (forme entière).
class PuzzleTargetWidget extends StatelessWidget {
  const PuzzleTargetWidget({super.key, required this.item});
  final PuzzleItem item;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = AppColors.accentForBrightness(
        AppColors.indexVSI, Theme.of(context).brightness);

    return Semantics(
      label:
          'Silhouette cible — ${item.baseShape.label}, niveau ${item.level.label}, item ${item.index}',
      child: AspectRatio(
        aspectRatio: 1.0,
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
              Positioned(
                top: 10.h,
                left: 12.w,
                child: Text('CIBLE',
                    style: AppText.monoLabel(color: accent)),
              ),
              Positioned(
                top: 10.h,
                right: 12.w,
                child: Text(item.level.label.toUpperCase(),
                    style: AppText.monoLabel(color: cs.outline)),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(24.w, 36.h, 24.w, 24.h),
                child: CustomPaint(
                  size: Size.infinite,
                  painter: PolygonPainter(
                    polygon: item.targetPolygon,
                    fillColor: accent.withValues(alpha: 0.20),
                    strokeColor: accent,
                    strokeWidth: 2.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
