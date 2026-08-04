// Le stimulus : un mot (ou « XXXX »), peint dans une encre.
//
// POSÉ SUR `KeplerStimulusSurface`, ET C'EST OBLIGATOIRE. Les encres sont
// fixes — c'est le matériel du test. Rendues directement sur le fond de page,
// leur rapport figure/fond changerait avec le thème : le rouge #C62828 se
// détache d'un crème clair, il s'efface presque sur un fond sombre. Deux
// personnes joueraient alors deux jeux différents, l'une devant lire un
// stimulus net, l'autre un stimulus limite — et la différence se retrouverait
// dans les millisecondes, donc dans le score.
//
// Le panneau règle ça sans exemption de charte : il impose son fond ET le
// thème clair à tout son sous-arbre, si bien que `AppText.of(context)` et
// `KeplerColors.of(context)` continuent d'y fonctionner normalement.
//
// LA ZONE EST DE HAUTEUR FIXE. Un mot court (« ROT ») et un mot long
// (« VERMELHO ») n'occupent pas la même place : si le panneau se redimensionnait
// d'un essai à l'autre, les boutons de réponse remonteraient et redescendraient
// sous le doigt. On mesurerait alors la poursuite d'une cible mobile.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/test/kepler_stimulus_surface.dart';
import '../../data/stroop_material.dart';
import '../../domain/models/stroop_trial.dart';

class StroopStimulus extends StatelessWidget {
  const StroopStimulus({super.key, required this.trial});

  final StroopTrial trial;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final mot = trial.condition == StroopCondition.neutral
        ? kStroopNeutralGlyphs
        : StroopMaterial.nameOf(trial.word!).resolve(locale);

    return KeplerStimulusSurface(
      padding: EdgeInsets.symmetric(vertical: 40.h, horizontal: 16.w),
      child: SizedBox(
        height: 72.h,
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              mot,
              maxLines: 1,
              // La couleur du TEXTE est le stimulus ; le style, lui, reste
              // celui de la charte.
              style: AppText.of(context).heroDisplay(
                color: StroopMaterial.colorOf(trial.ink),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
