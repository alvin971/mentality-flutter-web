// Le panneau dont la DURÉE est le stimulus.
//
// POSÉ SUR `KeplerStimulusSurface`, ET C'EST OBLIGATOIRE — pour une raison
// différente de celle du Stroop.
//
// Au Stroop, le panneau protège le rapport figure/fond d'encres fixes. Ici il n'y
// a pas d'encre : ce qui est mesuré est un TEMPS. Mais la durée perçue d'un
// stimulus dépend de son intensité — un rectangle éclatant sur fond sombre ne
// « dure » pas subjectivement comme un rectangle discret sur fond clair. Rendu
// directement sur la page, le même intervalle serait donc perçu différemment
// selon le thème choisi, et le record d'une personne changerait le jour où elle
// passe en mode sombre. Le panneau fixe la luminance, donc rend les parties
// comparables entre elles.
//
// LA ZONE EST DE HAUTEUR FIXE, allumée comme éteinte. Un panneau qui se
// redimensionnerait à l'allumage ajouterait un mouvement au début de
// l'intervalle : on daterait alors le début de la durée sur un déplacement, ce
// qui est une autre tâche. Seule la COULEUR change.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/kepler_colors.dart';
import '../../../../../core/widgets/test/kepler_stimulus_surface.dart';

class DurationPanel extends StatelessWidget {
  const DurationPanel({super.key, required this.lit});

  /// Le panneau est-il allumé ?
  final bool lit;

  /// Hauteur de la plaque intérieure. Constante — voir l'en-tête.
  static const double plateHeight = 120;

  @override
  Widget build(BuildContext context) => KeplerStimulusSurface(
        padding: EdgeInsets.all(16.w),
        child: Builder(
          // Le panneau impose le thème clair à son sous-arbre : les couleurs se
          // lisent donc DEDANS, sans quoi la plaque allumée prendrait l'accent
          // du thème de la page et changerait de luminance avec lui.
          builder: (inner) => SizedBox(
            height: plateHeight.h,
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: lit
                    ? KeplerColors.of(inner).primary
                    : KeplerStimulusSurface.surface,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: KeplerStimulusSurface.edge),
              ),
            ),
          ),
        ),
      );
}
