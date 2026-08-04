// L'escalier d'ajustement — comment quatre choix suffisent à cerner un point
// de bascule.
//
// ═══ LE PROCÉDÉ ═══
//
// Pour un délai donné, la somme différée ne bouge pas ; c'est la somme
// IMMÉDIATE qui s'ajuste, et de moins en moins fort à chaque réponse.
//
//   · On part à la moitié de la somme différée.
//   · Réponse « tout de suite » → l'offre immédiate était assez attirante :
//     on la BAISSE, pour voir jusqu'où la préférence tient.
//   · Réponse « plus tard » → l'offre immédiate était trop maigre : on la
//     MONTE.
//   · Le pas est chaque fois la moitié du précédent : 38, 19, 10, 5.
//
// Après le dernier choix, le montant qui SERAIT proposé ensuite n'est jamais
// affiché : c'est lui, le point d'indifférence. Il tombe au milieu du dernier
// intervalle où la préférence a hésité.
//
// Ce procédé (« adjusting amount ») est celui de la littérature sur le choix
// intertemporel. Son intérêt ici est le nombre de questions : quatre choix par
// délai au lieu d'une trentaine d'items figés, soit une partie de deux minutes
// au lieu d'un questionnaire.
//
// ═══ CONSÉQUENCE : LA PARTIE N'EST PAS LA MÊME POUR TOUT LE MONDE ═══
//
// L'escalier est ADAPTATIF — les montants proposés dépendent des réponses
// précédentes. Deux personnes ne voient donc pas les mêmes offres, et c'est
// voulu : chacune est mesurée là où sa préférence bascule, pas là où une grille
// commune avait décidé de regarder.
//
// ═══ POURQUOI AUCUN GARDE-FOU DE BORNES ═══
//
// Les montants extrêmes sont bornés par les paramètres eux-mêmes, pas par une
// pince posée après coup. Quelqu'un qui prendrait toujours l'immédiat descend à
// 3 ; quelqu'un qui attendrait toujours monte à 147 — les deux restent dans
// l'intervalle ouvert (0, 150). Un `clamp` masquerait un mauvais réglage de
// [DelayChoiceMaterial.stepsPerDelay] au lieu de le faire voir ; c'est un test
// qui épingle ces deux bornes, et il casse si les paramètres changent.

import 'package:equatable/equatable.dart';

class DelayChoiceStaircase extends Equatable {
  const DelayChoiceStaircase({
    required this.delayDays,
    required this.delayedAmount,
    required this.immediateAmount,
    required this.step,
    required this.answersLeft,
  });

  /// Ouvre l'escalier d'un délai : moitié de la somme différée, premier pas à
  /// la moitié de ce montant.
  factory DelayChoiceStaircase.start({
    required int delayDays,
    required int delayedAmount,
    required int answers,
  }) {
    final depart = (delayedAmount / 2).round();
    return DelayChoiceStaircase(
      delayDays: delayDays,
      delayedAmount: delayedAmount,
      immediateAmount: depart,
      step: (depart / 2).round(),
      answersLeft: answers,
    );
  }

  final int delayDays;
  final int delayedAmount;

  /// Le montant immédiat à proposer maintenant. Quand [isDone], il n'est plus
  /// proposé : il EST le point d'indifférence.
  final int immediateAmount;

  /// De combien le prochain ajustement déplacera [immediateAmount].
  final int step;

  /// Choix restant à poser sur ce délai.
  final int answersLeft;

  bool get isDone => answersLeft <= 0;

  /// Le point d'indifférence, une fois l'escalier terminé : le montant immédiat
  /// qui vaut, pour cette personne, la somme différée.
  ///
  /// Lu avant la fin, il ne serait qu'une étape intermédiaire — d'où
  /// l'assertion, qui transforme une lecture prématurée en échec de test plutôt
  /// qu'en chiffre plausible.
  int get indifferenceAmount {
    assert(isDone, 'point d\'indifférence lu avant la fin de l\'escalier');
    return immediateAmount;
  }

  /// Applique une réponse et rend l'escalier suivant.
  ///
  /// [tookImmediate] : la personne a pris la somme tout de suite.
  DelayChoiceStaircase answer(bool tookImmediate) {
    assert(!isDone, 'réponse de trop sur un escalier terminé');
    final suivant =
        tookImmediate ? immediateAmount - step : immediateAmount + step;
    assert(
      suivant > 0 && suivant < delayedAmount,
      'montant immédiat hors de (0, $delayedAmount) : $suivant',
    );
    return DelayChoiceStaircase(
      delayDays: delayDays,
      delayedAmount: delayedAmount,
      immediateAmount: suivant,
      // Le pas ne descend jamais sous 1 : à zéro, l'escalier cesserait de
      // bouger et les réponses suivantes ne seraient plus lues.
      step: step <= 1 ? 1 : (step / 2).round(),
      answersLeft: answersLeft - 1,
    );
  }

  @override
  List<Object?> get props =>
      [delayDays, delayedAmount, immediateAmount, step, answersLeft];
}
