import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/kepler_colors.dart';
import 'et_logo_animated.dart';

/// AppBar Kepler — transparente, titre serif italique optionnel,
/// eyebrow mono, fine ligne sous le titre, logo optionnel à droite.
class KeplerAppBar extends StatelessWidget implements PreferredSizeWidget {
  const KeplerAppBar({
    super.key,
    this.title,
    this.eyebrow,
    this.actions,
    this.leading,
    this.elevated = false,
    this.showLogo = false,
    this.logoSize = 24,
    this.logoColor,
  });

  final String? title;
  final String? eyebrow;
  final List<Widget>? actions;
  final Widget? leading;

  /// Si true, dessine une fine ligne de séparation sous l'app bar.
  final bool elevated;

  /// Si true, affiche le logo animé Mental E.T. en début de la zone actions
  /// (à droite du titre).
  final bool showLogo;

  final double logoSize;
  final Color? logoColor;

  @override
  Size get preferredSize => Size.fromHeight(72.h);

  @override
  Widget build(BuildContext context) {
    final colors = KeplerColors.of(context);
    return Material(
      color: colors.background,
      child: Container(
        decoration: elevated
            ? BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: colors.border,
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
                        size: 18.sp, color: colors.textPrimary),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (eyebrow != null)
                        // Une seule ligne, comme le titre juste en dessous :
                        // la hauteur de l'AppBar est FIXE (72.h), et un
                        // surtitre qui passe à la ligne la fait déborder. Le
                        // cas arrive dans les langues les plus longues, pas en
                        // français — d'où l'ellipse plutôt qu'un texte court
                        // imposé aux traducteurs.
                        Text(eyebrow!.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.of(context).monoLabel(
                                color: KeplerColors.of(context).primary)),
                      if (title != null) ...[
                        if (eyebrow != null) SizedBox(height: 2.h),
                        Text(title!,
                            style: AppText.of(context).h2Italic()
                                .copyWith(color: colors.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ],
                  ),
                ),
                if (showLogo) ...[
                  SizedBox(width: 8.w),
                  EtLogoAnimated(
                    size: logoSize,
                    color: logoColor ?? AppColors.primary,
                  ),
                ],
                if (actions != null) ...actions!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
