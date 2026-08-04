// L'escalier adaptatif — comment vingt-quatre essais trouvent un seuil.
//
// ═══ CE QU'ON CHERCHE ═══
//
// Le plus petit écart entre deux durées que la personne distingue encore. Il ne
// se demande pas (« quel écart perçois-tu ? » n'a pas de réponse), il se cerne :
// on présente des écarts de plus en plus fins tant qu'elle a bon, on les
// relâche dès qu'elle se trompe, et le seuil est le niveau autour duquel elle
// oscille.
//
// ═══ UNE BONNE POUR DESCENDRE, PUIS DEUX ═══
//
// La règle change après la première inversion, et ce n'est pas une complication
// gratuite.
//
// · AVANT la première inversion, une seule bonne réponse suffit à durcir, et le
//   pas est GROSSIER (÷2). L'écart de départ est énorme (60 %) : personne ne s'y
//   trompe, et y consacrer deux essais par palier gâcherait un tiers de la
//   partie à descendre une pente que tout le monde descend.
// · APRÈS, il faut DEUX bonnes de suite pour durcir, et le pas devient FIN
//   (÷1,4). Cette asymétrie est ce qui fait converger l'escalier vers un niveau
//   de justesse stable plutôt que vers le niveau où l'on répond juste une fois
//   sur deux — c'est-à-dire vers le hasard, qu'on atteint aussi en tapant au
//   hasard.
//
// ═══ POURQUOI DES BORNES, ICI, ALORS QUE LE JEU DU DÉLAI S'EN PASSE ═══
//
// Au jeu du délai, les montants restent dans leur intervalle par construction :
// le nombre de pas et leur taille le garantissent, et une pince n'aurait fait
// que masquer un mauvais réglage. Ici c'est différent — le mouvement dépend des
// RÉPONSES, pas d'un compte fixe. Une série de coups de chance ferait plonger
// l'écart vers l'imperceptible, et l'escalier annoncerait un seuil que le hasard
// suffit à expliquer. Les bornes sont donc à leur place, et elles sont
// documentées comme telles plutôt que subies.

import 'package:equatable/equatable.dart';

class TimeStaircase extends Equatable {
  const TimeStaircase({
    required this.delta,
    required this.streak,
    required this.goingDown,
    required this.reversals,
  });

  /// Écart de départ : 60 %. Assez grossier pour que la réponse soit évidente —
  /// les premiers essais servent à comprendre la consigne, pas à mesurer.
  static const double startDelta = 0.60;

  /// Pas avant la première inversion : on divise (ou multiplie) par deux.
  static const double coarseFactor = 2.0;

  /// Pas ensuite. Plus fin, pour se poser sur le seuil au lieu de l'enjamber.
  static const double fineFactor = 1.4;

  /// Sous cet écart, on n'est plus dans le mesurable mais dans le coup de
  /// chance : 2 % de 800 ms font 16 ms, soit un battement d'image.
  static const double minDelta = 0.02;

  /// Au-delà, la comparaison devient grotesque (800 ms contre 1520 ms) et il n'y
  /// a plus rien à affiner.
  static const double maxDelta = 0.90;

  /// L'écart courant, en proportion du standard.
  final double delta;

  /// Bonnes réponses consécutives depuis le dernier mouvement.
  final int streak;

  /// Sens du dernier mouvement : `true` on a durci, `false` on a relâché,
  /// `null` on n'a pas encore bougé.
  final bool? goingDown;

  /// L'écart relevé à chaque changement de sens. C'est de cette liste, et
  /// d'elle seule, que sort le seuil.
  final List<double> reversals;

  factory TimeStaircase.start() => const TimeStaircase(
        delta: startDelta,
        streak: 0,
        goingDown: null,
        reversals: [],
      );

  /// Tant qu'aucune inversion n'a eu lieu, la descente est rapide et une seule
  /// bonne réponse suffit.
  bool get _phaseGrossiere => reversals.isEmpty;

  double get _facteur => _phaseGrossiere ? coarseFactor : fineFactor;

  int get _bonnesPourDurcir => _phaseGrossiere ? 1 : 2;

  /// Applique une réponse et rend l'escalier suivant.
  TimeStaircase answer(bool correct) {
    if (correct && streak + 1 < _bonnesPourDurcir) {
      // Bonne réponse, mais pas encore de quoi durcir : on ne bouge pas.
      return TimeStaircase(
        delta: delta,
        streak: streak + 1,
        goingDown: goingDown,
        reversals: reversals,
      );
    }

    final versLeBas = correct;
    final suivant = versLeBas ? delta / _facteur : delta * _facteur;
    final estInversion = goingDown != null && goingDown != versLeBas;

    return TimeStaircase(
      delta: suivant.clamp(minDelta, maxDelta),
      streak: 0,
      goingDown: versLeBas,
      // L'écart relevé est celui d'AVANT le mouvement : le point de
      // retournement est là où la personne a basculé, pas là où l'escalier
      // l'emmène ensuite.
      reversals: estInversion ? [...reversals, delta] : reversals,
    );
  }

  @override
  List<Object?> get props => [delta, streak, goingDown, reversals];
}
