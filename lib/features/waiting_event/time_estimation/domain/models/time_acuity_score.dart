// Le score du jeu des durées — un SEUIL, en pourcentage.
//
// « Tu distingues encore deux durées qui diffèrent de 11 %. » C'est tout, et
// c'est déjà beaucoup : le chiffre dit à quelle finesse la perception du temps
// cesse de séparer deux intervalles.
//
// ═══ MOYENNE GÉOMÉTRIQUE, PAS ARITHMÉTIQUE ═══
//
// Les points de retournement s'échelonnent de façon MULTIPLICATIVE : l'escalier
// divise et multiplie, il n'ajoute pas. Sur une telle échelle, la moyenne
// arithmétique de 5 % et 45 % donne 25 % — une valeur qui n'est au milieu de
// rien : elle est cinq fois le premier et deux fois moins que le second. La
// moyenne géométrique rend 15 %, à égale distance des deux en proportion. C'est
// l'usage en psychophysique, et ici c'est ce qui empêche une seule inversion
// haute d'emporter le seuil.
//
// ═══ LA PREMIÈRE INVERSION EST JETÉE ═══
//
// Elle survient au bout de la descente rapide, à un écart encore grossier : elle
// dit où la personne a cessé de tout réussir, pas où elle hésite. La garder
// tirerait chaque seuil vers le haut, d'autant plus que la partie a été courte.
//
// ═══ DEUX RAISONS DE NE RIEN ANNONCER ═══
//
//  1. TROP PEU D'INVERSIONS. Sous [minUsableReversals], le seuil repose sur deux
//     ou trois points : l'escalier n'a pas eu le temps de se poser, et le chiffre
//     serait un accident de parcours.
//  2. UN SEUIL AU PLAFOND. Au-delà de [maxMeaningfulDelta], la personne ne
//     distingue même pas 800 ms de 1500 ms — ce qui n'arrive pas en regardant
//     l'écran. C'est le signe d'une partie tapée au hasard ou abandonnée en
//     cours. Annoncer « tu distingues des durées qui diffèrent de 78 % »
//     donnerait à ce non-résultat l'apparence d'une mesure.
//
// Dans les deux cas le record précédent reste intact, et la partie ne compte même
// pas comme partie jouée.
//
// ═══ POURQUOI UN RECORD EST LÉGITIME ICI, ALORS QUE LE JEU DU DÉLAI EN REFUSE ═══
//
// Au jeu du délai, les deux bouts de l'échelle se valent : préférer l'argent tout
// de suite est un arbitrage, pas une erreur, et désigner un bout comme meilleur
// serait un jugement déguisé en mesure.
//
// Un seuil de discrimination, lui, a un sens orienté : plus fin, c'est
// objectivement plus fin, exactement comme l'écart du Stroop est objectivement
// plus petit. Chercher à le réduire est un effort honnête, pas une distorsion de
// la réponse. Le record se prend donc par MINIMUM, et le jeu l'assume.

import 'dart:math' as math;

import 'package:equatable/equatable.dart';

class TimeAcuityScore extends Equatable {
  const TimeAcuityScore({
    required this.reversals,
    required this.correctCount,
    required this.answeredCount,
  });

  /// Inversions écartées en tête de liste — voir l'en-tête.
  static const int dropFirst = 1;

  /// Inversions exploitables nécessaires pour annoncer un seuil.
  static const int minUsableReversals = 4;

  /// Au-delà de ce seuil, il n'y a pas eu de mesure.
  static const double maxMeaningfulDelta = 0.70;

  /// Les écarts relevés à chaque changement de sens, dans l'ordre.
  final List<double> reversals;

  /// Réponses justes de la partie.
  final int correctCount;

  /// Essais répondus.
  final int answeredCount;

  /// Les inversions qui comptent.
  List<double> get usableReversals =>
      reversals.length <= dropFirst ? const [] : reversals.sublist(dropFirst);

  /// ★ LE SCORE, en proportion du standard. Plus il est petit, plus la
  /// perception sépare finement deux durées.
  ///
  /// `0` sur une partie sans inversion exploitable — la fiabilité se lit dans
  /// [isReliable], jamais dans une valeur sentinelle.
  double get thresholdDelta {
    final points = usableReversals;
    if (points.isEmpty) return 0;
    // Moyenne géométrique : exp de la moyenne des logarithmes. Les écarts sont
    // bornés au-dessus de zéro par l'escalier, donc aucun log(0) possible.
    final somme = points.fold<double>(0, (acc, d) => acc + math.log(d));
    return math.exp(somme / points.length);
  }

  /// Le même seuil en pourcentage entier — la forme sous laquelle il s'affiche.
  int get thresholdPercent => (thresholdDelta * 100).round();

  /// Y a-t-il de quoi annoncer un seuil ?
  bool get isReliable =>
      usableReversals.length >= minUsableReversals &&
      thresholdDelta <= maxMeaningfulDelta;

  /// Justesse en pourcentage entier, rapportée à part et jamais fondue dans le
  /// seuil.
  ///
  /// Elle ne dit pas la même chose que le seuil, et surtout elle ne varie
  /// presque pas : l'escalier PILOTE la justesse pour la maintenir autour de
  /// 70 %. Quelqu'un de très fin et quelqu'un de très grossier finissent donc
  /// avec la même justesse — à des écarts très différents. C'est pour cela
  /// qu'elle est affichée comme information et non comme performance.
  int get accuracyPercent => answeredCount == 0
      ? 0
      : ((correctCount * 100) / answeredCount).round();

  @override
  List<Object?> get props => [reversals, correctCount, answeredCount];
}
