import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

enum KeplerButtonVariant { primary, secondary, ghost }

/// Bouton Kepler — sobre, sage-green, radius 6px.
///
/// - `primary`   → fond accent vert, texte crème
/// - `secondary` → fond crème, bordure accent
/// - `ghost`     → transparent, label uniquement
class KeplerButton extends StatelessWidget {
  const KeplerButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = KeplerButtonVariant.primary,
    this.icon,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final KeplerButtonVariant variant;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;

    final Color bg;
    final Color fg;
    final BorderSide side;

    switch (variant) {
      case KeplerButtonVariant.primary:
        bg = disabled ? AppColors.primary.withValues(alpha: 0.4) : AppColors.primary;
        fg = AppColors.background;
        side = BorderSide.none;
        break;
      case KeplerButtonVariant.secondary:
        bg = AppColors.background;
        fg = AppColors.textPrimary;
        side = BorderSide(color: AppColors.primary.withValues(alpha: 0.5), width: 1);
        break;
      case KeplerButtonVariant.ghost:
        bg = Colors.transparent;
        fg = AppColors.primary;
        side = BorderSide.none;
        break;
    }

    final child = Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, color: fg, size: 18.sp),
            SizedBox(width: 8.w),
          ],
          Text(label, style: AppText.button(color: fg)),
        ],
      ),
    );

    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        side: side,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6.r),
        child: expand ? SizedBox(width: double.infinity, child: child) : child,
      ),
    );
  }
}
