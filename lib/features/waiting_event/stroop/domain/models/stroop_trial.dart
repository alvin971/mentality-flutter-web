// Un essai de Stroop — ce qui est montré, et ce qui a été répondu.
//
// LA CONSIGNE EST TOUJOURS LA MÊME : nommer la COULEUR DE L'ENCRE, jamais lire
// le mot. Tout l'intérêt du paradigme tient à ce que la lecture est
// automatique : elle s'impose même quand elle nuit. Le coût de la résister est
// ce qu'on mesure.
//
// Deux conditions, et deux seulement :
//
// · NEUTRE — une suite de « XXXX » colorée. Aucun mot à lire, donc rien à
//   inhiber : c'est le temps de nommer une couleur, tout simplement.
// · CONFLIT — un nom de couleur écrit dans une AUTRE encre. La lecture et la
//   dénomination se contredisent.
//
// Pourquoi « XXXX » plutôt que des mots neutres (« table », « chaise ») : la
// ligne de base doit être le même geste sans conflit, et une suite de X n'a
// besoin d'aucune traduction. Elle vaut à l'identique dans les six langues, ce
// qui rend la comparaison neutre/conflit comparable d'une langue à l'autre —
// ce qu'une liste de mots neutres traduits ne garantirait jamais.

import 'package:equatable/equatable.dart';

/// Les trois encres du jeu.
///
/// LES NOMS DE CES VALEURS SONT UN CONTRAT DE DONNÉES : ils forment les clés
/// du record enregistré sur l'appareil. Les renommer rendrait illisible ce qui
/// a déjà été joué, sans qu'aucun écran ne change d'apparence.
///
/// ## Pourquoi trois, et pourquoi celles-là
///
/// Le Stroop classique se joue souvent en rouge/vert/bleu. Ce couple
/// rouge-vert est écarté ici : c'est exactement l'axe que confondent les
/// dichromates (~8 % des hommes). Or ce jeu ne mesure PAS la finesse de
/// discrimination des teintes — il mesure le coût d'inhiber une lecture. Une
/// personne daltonienne qui hésite entre deux boutons produirait un écart
/// gonflé pour une raison qui n'a rien à voir avec l'inhibition : sa mesure
/// serait fausse, et elle le serait silencieusement.
///
/// Les trois encres retenues se séparent donc sur des axes que la dichromatie
/// ne referme pas : le bleu sur l'axe bleu-jaune, le rouge sur l'axe opposé, le
/// noir par la seule luminance. Une garde de test refuse toute paire trop
/// proche.
///
/// Le noir est aussi la couleur d'encre « par défaut » d'un texte, ce qui
/// pourrait lui donner un léger avantage de familiarité. C'est sans effet sur
/// la mesure : cet avantage est le même dans les deux conditions, et le score
/// est leur DIFFÉRENCE — il s'annule.
enum StroopInk { rouge, bleu, noir }

/// Ce que l'essai oppose (ou non) à la dénomination.
enum StroopCondition {
  /// Une suite de « XXXX » : rien à lire, donc rien à inhiber.
  neutral,

  /// Un nom de couleur écrit dans une autre encre.
  conflict,
}

/// Le motif affiché en condition neutre. Constant dans les six langues — c'est
/// tout l'intérêt (voir l'en-tête).
const String kStroopNeutralGlyphs = 'XXXX';

class StroopTrial extends Equatable {
  const StroopTrial({
    required this.ink,
    required this.condition,
    this.word,
    this.scored = true,
  });

  /// Neutre : « XXXX » dans l'encre [ink].
  const StroopTrial.neutral(this.ink, {this.scored = true})
      : condition = StroopCondition.neutral,
        word = null;

  /// Conflit : le nom de [word], écrit dans l'encre [ink]. L'assertion tient
  /// la définition même de la condition — un conflit où le mot coïncide avec
  /// l'encre n'est pas un conflit, c'est un essai congruent, et il abaisserait
  /// la moyenne du bloc sans que rien ne le signale.
  const StroopTrial.conflict({required this.ink, required StroopInk this.word,
      this.scored = true})
      : condition = StroopCondition.conflict,
        assert(ink != word, 'un conflit suppose mot ≠ encre');

  /// L'encre — LA bonne réponse, toujours.
  final StroopInk ink;

  final StroopCondition condition;

  /// Le mot écrit, en condition de conflit. `null` en neutre.
  final StroopInk? word;

  /// Les essais d'entraînement ne comptent pas. Les premiers essais d'une
  /// tâche chronométrée sont systématiquement les plus lents (on cherche
  /// encore ses boutons) ; les compter reviendrait à mesurer la découverte de
  /// l'écran plutôt que l'inhibition.
  final bool scored;

  @override
  List<Object?> get props => [ink, condition, word, scored];
}

/// Ce qu'une personne a répondu à un essai, et en combien de temps.
class StroopResponse extends Equatable {
  const StroopResponse({
    required this.trial,
    required this.chosen,
    required this.elapsedMs,
  });

  final StroopTrial trial;

  /// L'encre désignée. Correcte quand elle vaut [StroopTrial.ink].
  final StroopInk chosen;

  /// Temps écoulé entre l'apparition du stimulus et l'appui, en
  /// millisecondes.
  final int elapsedMs;

  bool get isCorrect => chosen == trial.ink;

  @override
  List<Object?> get props => [trial, chosen, elapsedMs];
}
