import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Indicateur de progression Kepler — barre fine + compteur mono "01 / 12".
class KeplerProgress extends StatelessWidget {
  const KeplerProgress({
    super.key,
    required this.value,
    this.current,
    this.total,
    this.label,
  });

  /// Valeur entre 0.0 et 1.0.
  final double value;

  /// Index courant (1-based) à afficher en compteur (optionnel).
  final int? current;

  /// Total d'items (optionnel).
  final int? total;

  /// Label de section (eyebrow §).
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (label != null)
              Text('§ ${label!.toUpperCase()} §',
                  style: AppText.monoLabel(color: AppColors.primary))
            else
              const SizedBox.shrink(),
            if (current != null && total != null)
              Text(
                '${current.toString().padLeft(2, '0')} / ${total.toString().padLeft(2, '0')}',
                style: AppText.monoLabel(color: AppColors.textTertiary),
              ),
          ],
        ),
        SizedBox(height: 8.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(2.r),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            minHeight: 3.h,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }
}
