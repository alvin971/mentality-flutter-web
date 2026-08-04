// Une échelle de réponse — les boutons que l'on propose sous une question.
//
// L'échelle appartient au BLOC (`QInstrument`), jamais à l'item : un
// instrument validé a été calibré avec ses propres ancrages, et mélanger deux
// échelles dans un même bloc changerait silencieusement ce que mesure le
// score. Quand l'échelle doit changer (RAADS-14 à 4 choix → CAT-Q à 7 niveaux),
// la couture est ASSUMÉE par un écran de transition déclaré.

import 'package:equatable/equatable.dart';

import 'q_text.dart';

/// Une modalité de réponse : ce que l'utilisateur lit, et ce que ça vaut.
class QScaleOption extends Equatable {
  const QScaleOption({required this.value, required this.label});

  /// La valeur BRUTE de cotation, telle que publiée par l'instrument. On ne la
  /// renumérote pas : un GAD-7 se cote 0-1-2-3, un CAT-Q 1..7, et c'est ce que
  /// les seuils publiés attendent.
  final int value;

  final QText label;

  @override
  List<Object?> get props => [value, label];
}

class QScale extends Equatable {
  const QScale({required this.id, required this.options});

  /// Identifiant stable, écrit dans les réponses stockées.
  final String id;

  /// Les modalités, dans l'ordre d'affichage.
  final List<QScaleOption> options;

  /// Les bornes de cotation, lues sur les modalités déclarées plutôt que
  /// posées en constante : l'inversion d'item en dépend, et une échelle
  /// modifiée doit emporter son inversion avec elle.
  int get minValue =>
      options.map((o) => o.value).reduce((a, b) => a < b ? a : b);

  int get maxValue =>
      options.map((o) => o.value).reduce((a, b) => a > b ? a : b);

  /// La contribution de [value] au score.
  ///
  /// [reversed] applique l'inversion canonique `min + max − valeur` (celle
  /// qu'attend par exemple l'item 6 du RAADS-14). Toute autre formule
  /// casserait le seuil publié.
  int score(int value, {bool reversed = false}) =>
      reversed ? (minValue + maxValue - value) : value;

  /// True si [value] est une modalité réellement proposée. Une réponse stockée
  /// hors échelle est une donnée corrompue, pas une réponse.
  bool accepts(int value) => options.any((o) => o.value == value);

  @override
  List<Object?> get props => [id, options];
}
