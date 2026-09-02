// Un essai du jeu des durées — deux panneaux, et lequel est resté le plus
// longtemps.
//
// ═══ POURQUOI COMPARER DEUX DURÉES, ET NON EN ESTIMER UNE ═══
//
// La façon évidente de mesurer la perception du temps serait de faire PRODUIRE
// une durée : « appuie quand tu penses que dix secondes ont passé ». C'est
// écarté, et le motif n'est pas un détail d'implémentation — c'est la seule
// raison pour laquelle ce jeu mesure quelque chose.
//
// On peut COMPTER dix secondes. Quiconque s'y met dans sa tête obtient un
// résultat quasi parfait, et le jeu annonce alors « ta perception du temps est
// excellente » alors qu'il vient de mesurer une capacité à compter. Pire : avec
// un record à battre, la stratégie se découvre en une partie, l'erreur tombe à
// presque zéro, et le jeu est mort — il ne distingue plus personne.
//
// Une comparaison de durées de l'ordre de la seconde n'est pas comptable : on
// ne compte pas 900 millisecondes. Il ne reste que la perception, ce qui est
// exactement l'objet annoncé. La question devient « à partir de quel écart deux
// durées cessent de te sembler identiques ? » — une acuité, mesurable et fine.
//
// ═══ CE QUE ÇA NE RECOUPE PAS ═══
//
// La batterie mesure la vitesse de traitement (indice PSI, deux sous-tests
// chronométrés). Ici RIEN n'est chronométré du côté de la personne : elle répond
// quand elle veut, et aucun temps de réponse n'entre dans le score. Ce qui est
// mesuré est la finesse avec laquelle deux intervalles se distinguent — une
// acuité perceptive, qu'aucun des douze sous-tests n'approche.
//
// ═══ LE STANDARD CHANGE D'UN ESSAI À L'AUTRE ═══
//
// Si tous les essais partaient d'un standard de 1000 ms, il serait possible
// d'apprendre « à quoi ressemble une seconde » et de juger chaque panneau dans
// l'absolu au lieu de comparer. Le standard est donc tiré parmi quatre valeurs :
// la comparaison redevient le seul chemin.

import 'package:equatable/equatable.dart';

class DurationTrial extends Equatable {
  const DurationTrial({
    required this.standardMs,
    required this.comparisonMs,
    required this.comparisonFirst,
  });

  /// La durée de référence de cet essai.
  final int standardMs;

  /// La durée à comparer. TOUJOURS strictement supérieure au standard : c'est
  /// elle, la bonne réponse.
  ///
  /// Un essai aux deux durées égales n'aurait pas de bonne réponse ; un essai
  /// où la comparaison serait parfois la plus courte n'ajouterait qu'une
  /// symétrie sans effet sur la mesure — l'écart se cerne aussi bien d'un seul
  /// côté, en deux fois moins d'essais.
  final int comparisonMs;

  /// La comparaison est-elle présentée EN PREMIER ?
  ///
  /// Sa position alterne, faute de quoi la bonne réponse serait toujours au même
  /// endroit et le jeu se gagnerait sans rien regarder.
  final bool comparisonFirst;

  /// L'écart relatif entre les deux durées — ce que l'escalier ajuste.
  double get delta => (comparisonMs - standardMs) / standardMs;

  /// La durée du premier panneau affiché.
  int get firstMs => comparisonFirst ? comparisonMs : standardMs;

  /// La durée du second panneau affiché.
  int get secondMs => comparisonFirst ? standardMs : comparisonMs;

  /// Répondre « le premier » est-il juste ?
  bool isCorrect({required bool choseFirst}) => choseFirst == comparisonFirst;

  @override
  List<Object?> get props => [standardMs, comparisonMs, comparisonFirst];
}
