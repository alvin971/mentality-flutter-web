// Une offre du jeu de tolérance au délai — le choix posé à l'écran.
//
// LES SOMMES SONT IMAGINAIRES. Rien n'est versé, rien n'est dû, rien n'est
// gagné : ce sont des questions, pas des transactions. L'écran le dit à
// l'ouverture, et le rappelle à chaque essai. Ce n'est pas une précaution
// juridique de façade — l'app vend un bilan par ailleurs, et un utilisateur qui
// lirait « 150 € » comme une promesse répondrait pour toucher l'argent plutôt
// que selon sa préférence. Le malentendu ne coûterait pas seulement de la
// confiance : il fausserait la mesure.
//
// ═══ CE QUE LE PARADIGME MESURE ═══
//
// Le choix intertemporel oppose une somme disponible TOUT DE SUITE à une somme
// PLUS GRANDE mais plus tard. Il n'y a pas de bonne réponse : préférer
// l'immédiat n'est pas une erreur de calcul, c'est un arbitrage. Ce qu'on
// observe est le point de bascule — à partir de quel montant immédiat quelqu'un
// cesse d'attendre.
//
// Ce point ne se demande pas directement (« combien faudrait-il pour que… ? »
// obtient un chiffre inventé sur place, pas une préférence). Il se cerne par
// une suite de choix simples : c'est le rôle de [DelayChoiceStaircase].
//
// ═══ POURQUOI DE L'ARGENT, ET PAS DES POINTS ═══
//
// Une unité neutre (« 100 points maintenant ou 150 points dans un mois »)
// supprimerait tout risque de croire à un paiement — et supprimerait aussi
// l'enjeu. Arbitrer entre deux nombres sans référent ne fait rien ressentir :
// les réponses se tassent au hasard, et le point de bascule mesuré n'est plus
// celui de personne. L'argent imaginaire, lui, convoque une expérience réelle
// du compromis. C'est le support sur lequel le paradigme est étalonné.

import 'package:equatable/equatable.dart';

class DelayChoiceOffer extends Equatable {
  const DelayChoiceOffer({
    required this.immediateAmount,
    required this.delayedAmount,
    required this.delayDays,
    required this.immediateOnTop,
  });

  /// Ce qu'on propose tout de suite. Toujours strictement inférieur à
  /// [delayedAmount] : une offre immédiate qui vaudrait autant ou plus
  /// dominerait l'autre, et le choix ne dirait plus rien.
  final int immediateAmount;

  /// Ce qu'on propose plus tard. FIXE pendant toute la partie — c'est le
  /// montant immédiat qui s'ajuste. Faire varier les deux rendrait chaque
  /// choix incomparable au précédent.
  final int delayedAmount;

  /// Le délai de l'offre différée, en jours.
  final int delayDays;

  /// L'offre immédiate est-elle affichée EN HAUT ?
  ///
  /// La position alterne d'un essai à l'autre, et c'est le contraire de ce que
  /// fait le Stroop — où l'ordre des boutons est fixe pour toute la partie. La
  /// différence n'est pas une inconséquence : les deux jeux se protègent de
  /// deux choses opposées.
  ///
  /// · Au Stroop, on mesure un TEMPS. Des boutons qui changeraient de place
  ///   feraient mesurer la recherche visuelle du bouton plutôt que
  ///   l'inhibition ; l'ordre y est donc figé.
  /// · Ici, on mesure une PRÉFÉRENCE, et le temps ne compte pas. Une position
  ///   figée laisserait s'installer une habitude de doigt — vingt fois le même
  ///   côté, et l'on répond à l'endroit plutôt qu'à la question. L'alternance
  ///   est ce qui oblige à relire l'offre.
  final bool immediateOnTop;

  @override
  List<Object?> get props =>
      [immediateAmount, delayedAmount, delayDays, immediateOnTop];
}
