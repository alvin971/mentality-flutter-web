import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/kepler_colors.dart';

/// Carte d'instruction Kepler pour les pages de tests.
///
/// Eyebrow mono optionnel, titre serif italique optionnel, corps DM Sans.
/// Bordure subtile teintée à l'accent du test, fond légèrement teinté.
class KeplerInstructionCard extends StatelessWidget {
  const KeplerInstructionCard({
    super.key,
    required this.body,
    required this.accentColor,
    this.eyebrow,
    this.title,
  });

  final String body;
  final Color accentColor;
  final String? eyebrow;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final colors = KeplerColors.of(context);
    final accent = AppColors.accentForBrightness(
        accentColor, Theme.of(context).brightness);
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: accent.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (eyebrow != null) ...[
            Text(eyebrow!.toUpperCase(),
                style: AppText.monoLabel(color: accent)),
            SizedBox(height: 8.h),
          ],
          if (title != null) ...[
            Text(title!,
                style: AppText.h3(color: colors.textPrimary)),
            SizedBox(height: 8.h),
          ],
          Text(body,
              style: AppText.body(color: colors.textSecondary)),
        ],
      ),
    );
  }
}
