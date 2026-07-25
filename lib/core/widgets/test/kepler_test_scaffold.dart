import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/kepler_colors.dart';
import '../et_logo_animated.dart';
import '../kepler_progress.dart';
import 'kepler_stimulus_surface.dart';

/// Scaffold unifié pour les 12 pages de tests cognitifs.
///
/// - Fond Kepler (light/dark via [KeplerColors.of]).
/// - AppBar Kepler : eyebrow mono + titre serif italique
///   + logo animé Mental E.T. à droite + couleur d'accent par index.
/// - Progress bar optionnelle sous l'AppBar.
/// - Bouton "Suivant"/"Valider" sticky en bas (optionnel).
class KeplerTestScaffold extends StatelessWidget {
  const KeplerTestScaffold({
    super.key,
    required this.testName,
    required this.accentColor,
    required this.child,
    this.eyebrow,
    this.currentItem,
    this.totalItems,
    this.bottomBar,
    this.padding,
    this.scrollable = true,
    this.trailing,
    this.stimulusSurface = false,
  });

  /// Nom du test (ex: "Matrices Progressives").
  final String testName;

  /// Couleur d'accent (index cognitif : indexFSIQ, indexVCI, etc.).
  final Color accentColor;

  /// Contenu principal (body).
  final Widget child;

  /// Eyebrow mono optionnel (ex: "TEST 04 / 12"). Affiché en majuscules.
  final String? eyebrow;

  /// Item courant (1-based) pour la progress bar.
  final int? currentItem;

  /// Nombre total d'items pour la progress bar.
  final int? totalItems;

  /// CTA sticky en bas (ex: bouton "Valider"). Si null, pas de bottomBar.
  final Widget? bottomBar;

  /// Padding du contenu. Défaut : 24w × 16h.
  final EdgeInsetsGeometry? padding;

  /// Si true (défaut), enveloppe `child` dans un SingleChildScrollView.
  final bool scrollable;

  /// Actions supplémentaires à droite de l'AppBar (ex: score, fermer).
  /// Apparaissent APRÈS le logo.
  final List<Widget>? trailing;

  /// Pose le contenu sur un [KeplerStimulusSurface] — panneau à luminance
  /// CONSTANTE, identique en clair et en sombre.
  ///
  /// À activer sur les épreuves **perceptives** (Cubes, Matrices, Puzzles
  /// Visuels, Balances, Mémoire des Images), dont les stimuli sont dessinés
  /// en couleurs fixes. Sans ce panneau, le rapport figure/fond varie avec le
  /// thème — une cellule blanche passe de Lc 47 sur crème à Lc 107 sur fond
  /// sombre — et la difficulté perçue de l'item change avec un réglage
  /// d'affichage, ce que les normes ne prévoient pas.
  ///
  /// Laisser à `false` pour les épreuves verbales ou numériques, où le
  /// matériel est du texte : il suit le thème sans conséquence sur la mesure.
  final bool stimulusSurface;

  @override
  Widget build(BuildContext context) {
    final colors = KeplerColors.of(context);
    final hasProgress = currentItem != null && totalItems != null;

    final inner = stimulusSurface
        ? KeplerStimulusSurface(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            child: child,
          )
        : child;

    // Quand le panneau est actif, il REPREND une partie du padding du
    // scaffold au lieu de s'y ajouter : sinon la largeur utile perdue fait
    // déborder les épreuves déjà serrées (cf. responsive_layout_test).
    final defaultPadding = stimulusSurface
        ? EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h)
        : EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h);

    final content = Padding(
      padding: padding ?? defaultPadding,
      child: inner,
    );

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasProgress)
          Padding(
            padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 16.h),
            child: KeplerProgress(
              value: currentItem! / totalItems!,
              current: currentItem,
              total: totalItems,
              label: eyebrow,
            ),
          ),
        // En mode non-scrollable, le contenu occupe toute la hauteur restante
        // (permet aux pages d'utiliser Expanded/FittedBox pour tenir à l'écran).
        if (scrollable) content else Expanded(child: content),
      ],
    );

    return Scaffold(
      backgroundColor: colors.background,
      appBar: _TestAppBar(
        title: testName,
        eyebrow: hasProgress ? null : eyebrow,
        accentColor: accentColor,
        trailing: trailing,
      ),
      bottomNavigationBar: bottomBar != null
          ? SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 12.h),
                child: bottomBar,
              ),
            )
          : null,
      body: SafeArea(
        top: false,
        child: scrollable
            ? SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: body,
              )
            : body,
      ),
    );
  }
}

class _TestAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _TestAppBar({
    required this.title,
    required this.accentColor,
    this.eyebrow,
    this.trailing,
  });

  final String title;
  final Color accentColor;
  final String? eyebrow;
  final List<Widget>? trailing;

  @override
  Size get preferredSize => Size.fromHeight(78.h);

  @override
  Widget build(BuildContext context) {
    final colors = KeplerColors.of(context);
    final effectiveAccent = AppColors.accentForBrightness(
        accentColor, Theme.of(context).brightness);
    return Material(
      color: colors.background,
      child: SafeArea(
        bottom: false,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: colors.border),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (Navigator.of(context).canPop())
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new,
                        size: 18.sp, color: colors.textPrimary),
                    onPressed: () => Navigator.of(context).maybePop(),
                  )
                else
                  SizedBox(width: 12.w),
                Expanded(
                  // FittedBox global borné par la hauteur de l'AppBar :
                  // eyebrow + titre se réduisent ensemble au lieu de
                  // déborder de quelques pixels sur les petits écrans.
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (eyebrow != null)
                            Text(
                              eyebrow!.toUpperCase(),
                              style: AppText.of(context).monoLabel(color: effectiveAccent),
                            ),
                          if (eyebrow != null) SizedBox(height: 2.h),
                          // FittedBox borné en hauteur : ne peut que RÉDUIRE
                          // le titre — corrige l'overflow vertical de
                          // l'AppBar sur desktop sans changer le rendu mobile
                          // (où le titre reste sous 34 px).
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 34),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                title,
                                style: AppText.of(context).h2Italic(
                                    color: colors.textPrimary),
                                maxLines: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                EtLogoAnimated(size: 26.w, color: effectiveAccent),
                if (trailing != null) ...[
                  SizedBox(width: 8.w),
                  ...trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
