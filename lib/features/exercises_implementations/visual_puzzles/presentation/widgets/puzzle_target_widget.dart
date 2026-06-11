import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../domain/puzzle_generator.dart';
import 'polygon_painter.dart';

/// Silhouette cible : la figure complète, pleine, SANS lignes internes —
/// comme dans le vrai subtest, c'est au sujet de trouver la décomposition.
///
/// NOTE : dimensionné en pixels logiques (pas de ScreenUtil) pour rester
/// stable sur desktop comme sur mobile.
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
                      painter: PolygonPainter(
                        polygon: item.targetPolygon,
                        fillColor: accent.withValues(alpha: 0.30),
                        strokeColor: accent,
                        strokeWidth: 2.5,
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
