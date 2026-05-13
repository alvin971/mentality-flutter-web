import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// AppBar Kepler — transparente, titre serif italique optionnel,
/// signature § en eyebrow mono, fine ligne sous le titre.
class KeplerAppBar extends StatelessWidget implements PreferredSizeWidget {
  const KeplerAppBar({
    super.key,
    this.title,
    this.eyebrow,
    this.actions,
    this.leading,
    this.elevated = false,
  });

  final String? title;
  final String? eyebrow;
  final List<Widget>? actions;
  final Widget? leading;

  /// Si true, dessine une fine ligne de séparation sous l'app bar.
  final bool elevated;

  @override
  Size get preferredSize => Size.fromHeight(72.h);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      child: Container(
        decoration: elevated
            ? BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.black.withValues(alpha: 0.07),
                  ),
                ),
              )
            : null,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (leading != null) leading!,
                if (leading == null && Navigator.of(context).canPop())
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new,
                        size: 18.sp, color: AppColors.textPrimary),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (eyebrow != null)
                        Text('§ ${eyebrow!.toUpperCase()} §',
                            style: AppText.monoLabel(
                                color: AppColors.primary)),
                      if (title != null) ...[
                        if (eyebrow != null) SizedBox(height: 2.h),
                        Text(title!,
                            style: AppText.h2Italic(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ],
                  ),
                ),
                if (actions != null) ...actions!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
