// La séquence d'essais — l'ordre dans lequel le jeu se déroule.
//
// Trois propriétés font toute la validité de la comparaison neutre/conflit, et
// aucune ne se voit à l'écran. C'est pourquoi elles vivent ici, sous garde de
// test, plutôt que dans la boucle d'affichage.
//
// 1. ENCRES ÉQUILIBRÉES. Chaque encre apparaît le même nombre de fois dans
//    chaque bloc. Sans cela, un bloc où le noir domine se compare à un bloc où
//    domine le bleu : l'écart mesuré contiendrait la différence de vitesse
//    entre deux couleurs, pas seulement le coût du conflit.
// 2. PAS DE LONGUE RÉPÉTITION. Trois fois la même encre d'affilée, et l'on
//    répond sans regarder — le bouton est déjà sous le doigt. La contrainte
//    borne les séries à deux.
// 3. ENTRAÎNEMENT NON COMPTÉ. Les premiers essais mesurent la découverte de
//    l'écran. Ils sont présentés en neutre, et marqués `scored: false`.
//
// L'ORDRE DES BLOCS EST FIXE : neutre d'abord, conflit ensuite. Il n'est pas
// contrebalancé d'une personne à l'autre, et c'est un choix assumé — les deux
// blocs sont si courts que l'alternance produirait surtout de la confusion de
// consigne. La conséquence est connue : l'entraînement accumulé pendant le
// bloc neutre rend le bloc de conflit un peu plus rapide qu'il ne l'aurait été
// isolément, ce qui SOUS-estime légèrement l'écart. Le biais va donc dans le
// sens prudent — il ne fabrique pas d'interférence, il en rabote.
//
// SEMÉE, DONC REJOUABLE À L'IDENTIQUE. Un test qui vérifie l'équilibre des
// encres a besoin d'une séquence reproductible ; une séquence tirée d'un
// hasard non semé ne se vérifierait que par échantillonnage.

import 'dart:math';

import '../models/stroop_trial.dart';

abstract final class StroopSequence {
  /// Essais d'entraînement, non comptés.
  static const int practiceCount = 3;

  /// Essais scorés par bloc. Multiple de 3 pour que les trois encres se
  /// partagent le bloc exactement.
  static const int blockLength = 18;

  /// Longueur maximale d'une série de la même encre.
  static const int maxRun = 2;

  /// Total présenté : entraînement + neutre + conflit.
  static const int totalTrials = practiceCount + blockLength * 2;

  /// Construit la passation complète.
  static List<StroopTrial> build({required int seed}) {
    final alea = Random(seed);
    return [
      for (final ink in _encresEquilibrees(alea, practiceCount))
        StroopTrial.neutral(ink, scored: false),
      for (final ink in _encresEquilibrees(alea, blockLength))
        StroopTrial.neutral(ink),
      ..._blocConflit(alea),
    ];
  }

  /// [count] encres, réparties aussi également que possible et sans série de
  /// plus de [maxRun].
  static List<StroopInk> _encresEquilibrees(Random alea, int count) {
    final urne = <StroopInk>[
      for (var i = 0; i < count; i++) StroopInk.values[i % StroopInk.values.length],
    ];
    return _melangerSansSerie(alea, urne);
  }

  /// Le bloc de conflit : mêmes encres équilibrées, et pour chacune un mot
  /// tiré parmi les DEUX autres — jamais le sien, sinon l'essai serait
  /// congruent.
  ///
  /// Les mots sont eux aussi équilibrés, encre par encre : si le rouge était
  /// systématiquement habillé du mot « BLEU », l'écart mesuré vaudrait pour
  /// cette paire-là et pour aucune autre.
  static List<StroopTrial> _blocConflit(Random alea) {
    final encres = _encresEquilibrees(alea, blockLength);
    final motsRestants = <StroopInk, List<StroopInk>>{};

    return [
      for (final encre in encres)
        StroopTrial.conflict(
          ink: encre,
          word: _prochainMot(alea, motsRestants, encre),
        ),
    ];
  }

  /// Tire le mot du prochain essai en encre [encre], en épuisant la réserve
  /// des deux autres couleurs avant de la reconstituer. C'est ce qui rend la
  /// répartition régulière plutôt que seulement aléatoire.
  static StroopInk _prochainMot(
    Random alea,
    Map<StroopInk, List<StroopInk>> reserves,
    StroopInk encre,
  ) {
    final reserve = reserves.putIfAbsent(encre, () => []);
    if (reserve.isEmpty) {
      reserve.addAll(StroopInk.values.where((i) => i != encre));
      reserve.shuffle(alea);
    }
    return reserve.removeLast();
  }

  /// Mélange [urne] jusqu'à ce qu'aucune encre n'y apparaisse plus de [maxRun]
  /// fois d'affilée.
  ///
  /// Le tirage est réessayé plutôt que corrigé après coup : déplacer l'élément
  /// fautif introduirait un biais systématique de position, invisible et bien
  /// pire que quelques tirages perdus. Un plafond d'essais garde la fonction
  /// terminante — avec trois encres équilibrées, la contrainte est satisfaite
  /// presque à chaque tirage, et le dernier tirage est rendu tel quel.
  static List<StroopInk> _melangerSansSerie(Random alea, List<StroopInk> urne) {
    var tirage = [...urne];
    for (var essai = 0; essai < 50; essai++) {
      tirage = [...urne]..shuffle(alea);
      if (!_aUneSerieTropLongue(tirage)) return tirage;
    }
    return tirage;
  }

  static bool _aUneSerieTropLongue(List<StroopInk> encres) {
    var serie = 1;
    for (var i = 1; i < encres.length; i++) {
      serie = encres[i] == encres[i - 1] ? serie + 1 : 1;
      if (serie > maxRun) return true;
    }
    return false;
  }
}
