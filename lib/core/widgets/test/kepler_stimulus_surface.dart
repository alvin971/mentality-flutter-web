import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../theme/app_theme.dart';
import '../../theme/kepler_colors.dart';

/// Panneau de présentation du matériel de test, à luminance **constante**.
///
/// ## Pourquoi ce widget existe
///
/// Cubes, Matrices, Puzzles Visuels, Balances et Mémoire des Images sont des
/// épreuves **perceptives** : leur difficulté tient à la finesse avec laquelle
/// on distingue des formes. Or leurs stimuli sont dessinés en couleurs fixes
/// (cellules blanches, tracés noirs, palette de pièces) — volontairement, car
/// les thématiser modifierait le matériel normé.
///
/// Conséquence si on les pose directement sur le fond de page : le rapport
/// figure/fond change avec le thème. Une cellule blanche vaut Lc 47 sur le
/// crème du mode clair et **Lc 107 sur le fond sombre** — soit le contraste
/// maximum possible. Deux personnes passant le même item avec des réglages
/// différents ne passent alors plus tout à fait la même épreuve, alors que les
/// normes supposent une passation unique.
///
/// Ce panneau isole donc la zone de mesure : son fond ne dépend pas du thème.
/// Le chrome autour (titre, progression, bouton) continue, lui, de suivre le
/// mode choisi.
///
/// ## Choix de la teinte
///
/// Ni blanc pur ni crème : un neutre très légèrement chaud, un cran sous le
/// blanc. Assez clair pour préserver le rapport figure/fond d'origine, assez
/// sourd pour limiter l'éblouissement quand la page autour est sombre. Le
/// liseré et les coins arrondis évitent la rupture brutale avec le fond.
class KeplerStimulusSurface extends StatelessWidget {
  const KeplerStimulusSurface({
    super.key,
    required this.child,
    this.padding,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  /// Fond du panneau — **identique en clair et en sombre**, par conception.
  /// Ne pas thématiser : ce serait rouvrir exactement le problème que ce
  /// widget corrige.
  static const Color surface = Color(0xFFF2F1ED);

  /// Liseré du panneau, lui aussi constant.
  static const Color edge = Color(0xFFD9D8D2);

  /// Couleur de tracé recommandée pour un stimulus posé sur ce panneau.
  static const Color ink = Color(0xFF16181A);

  @override
  Widget build(BuildContext context) {
    // Le panneau impose le thème CLAIR à tout son sous-arbre.
    //
    // Sans ça, le fond serait clair mais les textes de consigne resteraient
    // ceux du mode sombre (#E2E9E5) : clair sur clair, donc invisibles. En
    // basculant le thème, consignes, compteurs et stimuli se rendent tous
    // dans les mêmes conditions — ce qui est précisément le but : la zone de
    // mesure ne doit pas dépendre du réglage d'affichage.
    return Theme(
      data: AppTheme.light(),
      child: Builder(
        builder: (context) => Container(
          width: double.infinity,
          padding: padding ?? EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: edge),
          ),
          child: DefaultTextStyle.merge(
            style: TextStyle(color: KeplerColors.of(context).textPrimary),
            child: child,
          ),
        ),
      ),
    );
  }
}
