import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

/// Indicateur visuel des slots à remplir (3 pièces à sélectionner).
///
/// Affiche `total` petites pastilles : pleines pour les `filled` premières,
/// vides pour les autres. UX explicite "il faut 3 pièces".
///
/// NOTE : dimensionné en pixels logiques (pas de ScreenUtil) pour rester
/// stable sur desktop comme sur mobile.
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
          Text('SÉLECTION', style: AppText.mono(color: cs.outline, size: 11)),
          const SizedBox(width: 12),
          for (int i = 0; i < total; i++) ...[
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 16,
              height: 16,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: i < filled ? accent : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      i < filled ? accent : cs.outline.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
            ),
          ],
          const SizedBox(width: 10),
          Text('$filled / $total',
              style: AppText.mono(color: accent, size: 11)),
        ],
      ),
    );
  }
}
