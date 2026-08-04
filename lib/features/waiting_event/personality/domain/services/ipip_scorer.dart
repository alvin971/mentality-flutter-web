// La cotation de l'IPIP-50 : cinq sommes, et pas un chiffre de plus.
//
// ## Ce qu'on calcule
//
// Pour chaque facteur, la somme de ses dix items, cotés 1 à 5, les items
// inversés retournés par la formule canonique `min + max − valeur` (soit
// `6 − valeur` sur cette échelle). Un trait vaut donc de 10 à 50, avec 30 au
// milieu EXACT de l'échelle.
//
// ## Ce qu'on ne calcule PAS, et pourquoi
//
// Aucun PERCENTILE. Le plan d'implémentation prévoit « percentiles normes
// publiées », et c'est la bonne cible — mais un percentile est une position
// dans une POPULATION, et nous n'avons pas de table de normes sous la main.
// L'inventer produirait le défaut exact que le champ de provenance existe pour
// rendre visible : un nombre faux sous une étiquette vraie, invisible à
// l'écran et invérifiable par un test.
//
// Ce qui est rendu à la place est une position sur l'ÉCHELLE, qui est une
// propriété de l'instrument et non d'une population : à mi-chemin, au-dessus,
// en dessous. C'est moins joli qu'un « 73ᵉ percentile » et c'est vrai. Le
// jour où le volume de passations le permettra, les normes maison viendront
// s'ajouter — le plan produit §5 prévoit déjà ce chemin (« normes publiées,
// puis normes maison avec le volume ») ; nous en sautons simplement la
// première étape faute de source.
//
// ## Ce qui est un piège
//
// Le quatrième facteur des marqueurs IPIP est la STABILITÉ ÉMOTIONNELLE, pas
// le névrosisme. Huit de ses dix items sont inversés, ce qui est le signe
// qu'on cote bien le pôle « calme ». Un rapport qui titrerait « névrosisme »
// sur ce chiffre dirait exactement le contraire de la mesure.

import '../../../_shared/data/question_bank/ipip50.dart';
import '../../../_shared/domain/models/q_item.dart';
import '../../../_shared/domain/models/q_scale.dart';

/// Où tombe un trait sur l'échelle 10-50. Une position dans l'INSTRUMENT,
/// jamais dans une population — voir l'en-tête.
enum IpipBand {
  /// Nettement sous le milieu de l'échelle.
  low,

  /// Autour du milieu.
  mid,

  /// Nettement au-dessus.
  high,
}

/// Le score d'un facteur.
class IpipTraitScore {
  const IpipTraitScore({
    required this.trait,
    required this.raw,
    required this.answered,
  });

  /// L'un des cinq de [IpipTrait], nommé par son pôle POSITIF.
  final String trait;

  /// Somme des items du facteur, inversions appliquées. 10 à 50 quand les dix
  /// items ont une réponse.
  final int raw;

  /// Nombre d'items réellement répondus (0 à 10). Un questionnaire abandonné
  /// produit un score partiel, et il est nommé tel quel plutôt que comparé.
  final int answered;

  /// Le facteur est-il complet ? Un trait à trous ne se compare à rien.
  bool get isComplete => answered == itemsPerTrait;

  /// Le nombre d'items par facteur — dix, par construction de l'instrument.
  static const int itemsPerTrait = 10;

  /// Bornes de l'échelle quand le facteur est complet.
  static const int minRaw = 10;
  static const int maxRaw = 50;

  /// Le milieu exact de l'échelle : dix items à la modalité centrale.
  static const int midRaw = 30;

  /// Où tombe [raw] par rapport au milieu de l'échelle. `null` si le facteur
  /// est incomplet — situer un total partiel sur une échelle complète le ferait
  /// systématiquement paraître bas.
  ///
  /// Les bornes sont à ± un cinquième de la demi-échelle (30 ± 4), soit un
  /// écart moyen de 0,4 point par item : en deçà, la différence tient à deux
  /// ou trois clics et ne mérite pas d'être racontée.
  IpipBand? get band {
    if (!isComplete) return null;
    if (raw <= midRaw - 4) return IpipBand.low;
    if (raw >= midRaw + 4) return IpipBand.high;
    return IpipBand.mid;
  }
}

/// Le profil complet : les cinq facteurs, toujours dans l'ordre de
/// [IpipTrait.all].
class IpipProfile {
  const IpipProfile(this.traits);

  final List<IpipTraitScore> traits;

  IpipTraitScore byTrait(String trait) =>
      traits.firstWhere((t) => t.trait == trait);

  /// True si les cinquante items ont une réponse. Le rapport ne s'affiche
  /// qu'à cette condition.
  bool get isComplete => traits.every((t) => t.isComplete);

  int get answeredCount =>
      traits.fold(0, (somme, t) => somme + t.answered);
}

/// Cote un jeu de réponses `identifiant d'item → valeur brute`.
///
/// Les valeurs hors échelle sont IGNORÉES plutôt que corrigées ou plaquées sur
/// une borne : une réponse hors échelle est une donnée corrompue, pas une
/// réponse basse. La compter reviendrait à fabriquer un score à partir de rien.
IpipProfile scoreIpip50(Map<String, int> answers) {
  final parTrait = <String, List<QItem>>{
    for (final trait in IpipTrait.all) trait: [],
  };
  for (final item in ipip50Items) {
    parTrait[item.subscale]!.add(item);
  }

  const QScale echelle = ipipAccuracyScale;
  return IpipProfile([
    for (final trait in IpipTrait.all)
      () {
        var somme = 0;
        var repondus = 0;
        for (final item in parTrait[trait]!) {
          final valeur = answers[item.id];
          if (valeur == null || !echelle.accepts(valeur)) continue;
          somme += echelle.score(valeur, reversed: item.reverseScored);
          repondus++;
        }
        return IpipTraitScore(trait: trait, raw: somme, answered: repondus);
      }(),
  ]);
}
