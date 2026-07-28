// Le score du jeu de délai — une AIRE SOUS LA COURBE, et surtout : PAS UN
// CLASSEMENT.
//
// ═══ LA RÈGLE QUI SÉPARE CE JEU DU STROOP ═══
//
// Au Stroop, il existe un meilleur et un moins bon : l'écart mesure un COÛT, le
// réduire est une réussite, et l'écran garde un record.
//
// ICI, RIEN DE TEL. Préférer 100 tout de suite à 150 dans un an n'est pas une
// erreur de calcul — c'est un arbitrage, parfaitement rationnel selon la
// situation de chacun. Quelqu'un qui n'a pas de quoi finir le mois a d'excellentes
// raisons de prendre l'argent tout de suite ; sa préférence n'est pas un défaut
// de caractère, et l'appeler « impulsivité » en la notant serait un jugement
// déguisé en mesure.
//
// Trois conséquences, toutes encodées ailleurs dans le lot :
//
//  1. AUCUN RECORD. Le store garde la dernière partie pour qu'on puisse se
//     comparer à soi-même, jamais un « meilleur score ». Un record inviterait à
//     répondre pour le battre plutôt que selon sa préférence — et la seule
//     chose qu'on mesurerait serait l'envie de gagner.
//  2. L'écran de résultat dit explicitement qu'aucun bout de l'échelle n'est
//     meilleur que l'autre.
//  3. Le mot « impulsivité » n'apparaît nulle part à l'écran.
//
// ═══ POURQUOI UNE AIRE, ET PAS UN TAUX D'ESCOMPTE ═══
//
// L'usage historique résume ces courbes par un taux `k` issu du modèle
// hyperbolique `V = A / (1 + k·D)`. Deux raisons de ne pas le retenir :
//
// · Il suppose que la courbe suit ce modèle. Quand elle ne le suit pas, `k` est
//   ajusté quand même et le chiffre rendu ne décrit plus rien.
// · Il s'étale sur plusieurs ordres de grandeur (0,001 à 1), donc ne s'affiche
//   ni ne se compare sans logarithme — illisible dans un jeu.
//
// L'aire sous la courbe des points d'indifférence (Myerson, Green & Warusawitharana,
// 2001) ne suppose AUCUN modèle : elle mesure ce qui a été répondu, tel quel.
// Elle vit entre 0 et 1, ce qui s'affiche sur 100 sans transformation.
//
// Les deux axes sont normalisés — délais divisés par le plus long, montants
// divisés par la somme différée — puis l'aire se calcule en trapèzes depuis le
// point (0 ; 1), qui n'est pas une mesure mais une définition : à délai nul, la
// somme vaut exactement ce qu'elle vaut.
//
// ═══ LA SEULE PARTIE QU'ON REFUSE ═══
//
// Une courbe de préférence peut monter localement sans être absurde ; elle ne
// peut pas monter FRANCHEMENT et durablement, parce qu'une même somme placée
// plus loin ne peut pas valoir davantage. Une remontée marquée signe des
// réponses posées au hasard, pas une préférence.
//
// C'est le premier critère de Johnson & Bickel (2008) : aucun point
// d'indifférence ne doit dépasser le précédent de plus de 20 % de la somme
// différée. Il est repris ici tel quel, et il tient le rôle que le seuil de huit
// essais valides tient au Stroop — sous cette barre, RIEN n'est annoncé.
//
// Leur SECOND critère (« le dernier point doit être inférieur au premier ») est
// délibérément ÉCARTÉ. Il exclut les gens qui n'escomptent pas du tout, c'est-à-
// dire ceux qui attendent toujours. Dans une étude, on les met de côté pour ne
// pas polluer un ajustement de modèle ; ici, ce sont des joueurs, leur réponse
// est cohérente, et leur refuser un résultat au motif qu'ils sont trop patients
// serait absurde.

import 'package:equatable/equatable.dart';

class DelayChoiceScore extends Equatable {
  const DelayChoiceScore({
    required this.indifferenceByDelay,
    required this.delayedAmount,
  });

  /// Une remontée au-delà de cette fraction de la somme différée signe des
  /// réponses incohérentes (Johnson & Bickel 2008, critère 1).
  static const double monotonicityTolerance = 0.20;

  /// Sous trois points, « l'aire sous la courbe » n'est plus une courbe mais un
  /// segment : le chiffre existerait encore, il ne voudrait plus rien dire.
  static const int minDelays = 3;

  /// Délai en jours → montant immédiat jugé équivalent.
  final Map<int, int> indifferenceByDelay;

  /// La somme différée proposée pendant la partie — l'unité des ordonnées.
  final int delayedAmount;

  /// Les délais interrogés, du plus court au plus long.
  List<int> get delays => indifferenceByDelay.keys.toList()..sort();

  /// La courbe monte-t-elle franchement quelque part ?
  ///
  /// Les points sont lus PAR DÉLAI CROISSANT, quel que soit l'ordre dans lequel
  /// les questions ont été posées.
  bool get isMonotone {
    final tolerance = delayedAmount * monotonicityTolerance;
    final ordre = delays;
    for (var i = 1; i < ordre.length; i++) {
      final avant = indifferenceByDelay[ordre[i - 1]]!;
      final apres = indifferenceByDelay[ordre[i]]!;
      if (apres - avant > tolerance) return false;
    }
    return true;
  }

  /// Y a-t-il de quoi annoncer quelque chose ? Sinon l'écran le dit et propose
  /// de rejouer — il n'affiche pas un chiffre en s'excusant.
  bool get isReliable => delays.length >= minDelays && isMonotone;

  /// ★ LE SCORE, entre 0 et 1. Zéro : rien ne vaut la peine d'attendre. Un :
  /// attendre ne coûte rien.
  ///
  /// Ni l'un ni l'autre n'est meilleur — voir l'en-tête du fichier.
  double get patienceIndex {
    final ordre = delays;
    if (ordre.isEmpty) return 0;
    final delaiMax = ordre.last;
    if (delaiMax <= 0 || delayedAmount <= 0) return 0;

    // Le point de départ (0 ; 1) est une définition, pas une mesure : à délai
    // nul, la somme différée EST la somme immédiate.
    var x0 = 0.0;
    var y0 = 1.0;
    var aire = 0.0;
    for (final jours in ordre) {
      final x1 = jours / delaiMax;
      final y1 = indifferenceByDelay[jours]! / delayedAmount;
      aire += (x1 - x0) * (y0 + y1) / 2;
      x0 = x1;
      y0 = y1;
    }
    return aire.clamp(0.0, 1.0);
  }

  /// Le même score sur 100 — la forme sous laquelle il s'affiche.
  int get patiencePercent => (patienceIndex * 100).round();

  /// Le montant immédiat jugé équivalent à [delayedAmount] pour [days], ou
  /// `null` si ce délai n'a pas été mené à son terme.
  ///
  /// Sert la seule phrase concrète de l'écran de résultat — celle qui redit le
  /// chiffre en langue humaine plutôt qu'en index.
  int? indifferenceAt(int days) => indifferenceByDelay[days];

  @override
  List<Object?> get props => [indifferenceByDelay, delayedAmount];
}
