import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/kepler_colors.dart';
import 'kepler_app_bar.dart';

/// Scaffold pré-configuré pour la charte Kepler — fond crème,
/// padding horizontal cohérent, AppBar Kepler optionnelle.
class KeplerScaffold extends StatelessWidget {
  const KeplerScaffold({
    super.key,
    required this.child,
    this.title,
    this.eyebrow,
    this.actions,
    this.appBar,
    this.bottomBar,
    this.padding,
    this.scroll = true,
    this.background,
  });

  final Widget child;
  final String? title;
  final String? eyebrow;
  final List<Widget>? actions;

  /// AppBar custom. Si fourni, `title`/`eyebrow`/`actions` sont ignorés.
  final PreferredSizeWidget? appBar;

  final Widget? bottomBar;
  final EdgeInsetsGeometry? padding;
  final bool scroll;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final bar = appBar ??
        ((title != null || eyebrow != null || actions != null)
            ? KeplerAppBar(title: title, eyebrow: eyebrow, actions: actions)
            : null);

    final p = padding ?? EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h);
    final body = Padding(padding: p, child: child);

    // LE CLAVIER NE POUSSE PAS `bottomNavigationBar`. Flutter le laisse au ras
    // de l'écran, donc SOUS le clavier : sur un écran qui contient un champ de
    // saisie, le bouton de validation devient purement inatteignable. Et le
    // pavé numérique iOS n'offre aucune touche « OK » pour refermer le
    // clavier — il n'existe alors plus aucun moyen de valider.
    //
    // Le décalage vaut 0 sans clavier : hors saisie, rien ne change.
    // Pas de double comptage non plus — `_ScaffoldLayout` réserve
    // `max(insets, hauteur de la barre)` et non leur somme, si bien que la
    // barre remonte exactement de sa propre hauteur au-dessus du clavier.
    final insetsBas = MediaQuery.viewInsetsOf(context).bottom;
    final barreBasse = bottomBar == null
        ? null
        : Padding(
            padding: EdgeInsets.only(bottom: insetsBas),
            child: bottomBar,
          );

    return Scaffold(
      backgroundColor: background ?? KeplerColors.of(context).background,
      appBar: bar,
      bottomNavigationBar: barreBasse,
      body: scroll
          ? SafeArea(
              top: bar == null,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: body,
              ),
            )
          : SafeArea(top: bar == null, child: body),
    );
  }
}
