import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/kepler_colors.dart';

enum KeplerTestButtonVariant { primary, outlined, ghost }

/// Bouton Kepler pour pages de tests — accent par index cognitif.
class KeplerTestButton extends StatelessWidget {
  const KeplerTestButton({
    super.key,
    required this.label,
    required this.accentColor,
    this.onPressed,
    this.variant = KeplerTestButtonVariant.primary,
    this.icon,
    this.expand = true,
  });

  factory KeplerTestButton.primary({
    Key? key,
    required String label,
    required Color accentColor,
    VoidCallback? onPressed,
    IconData? icon,
    bool expand = true,
  }) =>
      KeplerTestButton(
        key: key,
        label: label,
        accentColor: accentColor,
        onPressed: onPressed,
        icon: icon,
        expand: expand,
      );

  factory KeplerTestButton.outlined({
    Key? key,
    required String label,
    required Color accentColor,
    VoidCallback? onPressed,
    IconData? icon,
    bool expand = true,
  }) =>
      KeplerTestButton(
        key: key,
        label: label,
        accentColor: accentColor,
        onPressed: onPressed,
        icon: icon,
        expand: expand,
        variant: KeplerTestButtonVariant.outlined,
      );

  final String label;
  final Color accentColor;
  final VoidCallback? onPressed;
  final KeplerTestButtonVariant variant;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final colors = KeplerColors.of(context);
    final accent = AppColors.accentForBrightness(
        accentColor, Theme.of(context).brightness);
    final disabled = onPressed == null;

    Color bg;
    Color fg;
    BorderSide side;

    switch (variant) {
      case KeplerTestButtonVariant.primary:
        bg = disabled ? accent.withValues(alpha: 0.4) : accent;
        fg = colors.background;
        side = BorderSide.none;
        break;
      case KeplerTestButtonVariant.outlined:
        bg = Colors.transparent;
        fg = accent;
        side = BorderSide(color: accent, width: 1.5);
        break;
      case KeplerTestButtonVariant.ghost:
        bg = Colors.transparent;
        fg = accent;
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
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8.r),
        child: expand ? SizedBox(width: double.infinity, child: child) : child,
      ),
    );
  }
}
