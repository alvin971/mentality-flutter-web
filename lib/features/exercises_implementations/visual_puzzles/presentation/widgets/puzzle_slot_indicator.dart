import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

/// Indicateur visuel des slots à remplir (3 pièces à sélectionner).
///
/// Affiche `total` petites pastilles : pleines pour les `filled` premières,
/// vides pour les autres. UX explicite "il faut 3 pièces".
class PuzzleSlotIndicator extends StatelessWidget {
  const PuzzleSlotIndicator({
    super.key,
    required this.filled,
    this.total = 3,
  });

  final int filled;
  final int total;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = AppColors.accentForBrightness(
        AppColors.indexVSI, Theme.of(context).brightness);

    return Semantics(
      label: 'Sélection : $filled sur $total pièces',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('SÉLECTION',
              style: AppText.monoLabel(color: cs.outline)),
          SizedBox(width: 12.w),
          for (int i = 0; i < total; i++) ...[
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 18.w,
              height: 18.w,
              margin: EdgeInsets.symmetric(horizontal: 3.w),
              decoration: BoxDecoration(
                color: i < filled ? accent : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: i < filled ? accent : cs.outline.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
            ),
          ],
          SizedBox(width: 10.w),
          Text('$filled / $total',
              style: AppText.monoLabel(color: accent)),
        ],
      ),
    );
  }
}
