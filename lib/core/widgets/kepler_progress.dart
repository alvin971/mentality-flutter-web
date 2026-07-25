import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_typography.dart';
import '../theme/kepler_colors.dart';

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

  /// Label de section (eyebrow mono).
  final String? label;

  @override
  Widget build(BuildContext context) {
    final colors = KeplerColors.of(context);
    final accent = colors.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (label != null)
              // Flexible + ellipsis : les eyebrows longs ne débordent pas
              // sur les écrans étroits.
              Flexible(
                child: Text(label!.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.of(context).monoLabel(color: accent)),
              )
            else
              const SizedBox.shrink(),
            if (current != null && total != null) ...[
              SizedBox(width: 8.w),
              Text(
                '${current.toString().padLeft(2, '0')} / ${total.toString().padLeft(2, '0')}',
                style: AppText.of(context).monoLabel(color: colors.textTertiary),
              ),
            ],
          ],
        ),
        SizedBox(height: 8.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(2.r),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            minHeight: 3.h,
            backgroundColor: accent.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(accent),
          ),
        ),
      ],
    );
  }
}
