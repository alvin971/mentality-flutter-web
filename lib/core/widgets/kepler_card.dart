import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/kepler_colors.dart';

/// Card Kepler — fond blanc, bordure subtile, ombre légère, radius 12.
class KeplerCard extends StatelessWidget {
  const KeplerCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.surface = false,
    this.radius,
  });

  /// Si `surface=true`, utilise la couleur de surface Kepler (vert très pâle)
  /// au lieu du blanc pur.
  final bool surface;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Widget child;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius ?? 12.r);
    final body = Padding(
      padding: padding ?? EdgeInsets.all(20.w),
      child: child,
    );

    final colors = KeplerColors.of(context);
    final decoration = BoxDecoration(
      color: surface ? colors.surface : colors.cardSurface,
      borderRadius: r,
      border: Border.all(color: colors.border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );

    if (onTap == null) {
      return DecoratedBox(decoration: decoration, child: body);
    }

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: decoration,
        child: InkWell(
          onTap: onTap,
          borderRadius: r,
          child: body,
        ),
      ),
    );
  }
}
