import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/kepler_colors.dart';

/// Timer Kepler pour pages de tests — mono, passe en rouge sous le seuil.
class KeplerTestTimer extends StatelessWidget {
  const KeplerTestTimer({
    super.key,
    required this.secondsRemaining,
    this.accentColor,
    this.warnAt = 5,
    this.compact = false,
  });

  final int secondsRemaining;
  final Color? accentColor;
  final int warnAt;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = KeplerColors.of(context);
    final danger = secondsRemaining <= warnAt;
    final tint = danger ? AppColors.error : (accentColor ?? colors.textPrimary);

    final mm = (secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final ss = (secondsRemaining % 60).toString().padLeft(2, '0');
    final label = '$mm : $ss';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10.w : 14.w,
        vertical: compact ? 6.h : 8.h,
      ),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: tint.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: compact ? 14.sp : 16.sp, color: tint),
          SizedBox(width: 6.w),
          Text(label,
              style: AppText.mono(
                color: tint,
                size: compact ? 12.sp : 14.sp,
              )),
        ],
      ),
    );
  }
}
