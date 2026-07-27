// Une question, et rien de plus.
//
// L'item ne porte NI son échelle NI son cadrage : les deux appartiennent au
// bloc qui le contient. Un item ne sait donc pas s'il compte pour un score —
// c'est la structure du module qui le décide, et c'est ce qui rend impossible
// de coter par accident une question maison avec le barème d'un instrument
// validé.

import 'package:equatable/equatable.dart';

import 'q_text.dart';

class QItem extends Equatable {
  const QItem({
    required this.id,
    required this.text,
    this.reverseScored = false,
    this.subscale,
  });

  /// Identifiant stable — c'est LA clé sous laquelle la réponse est stockée.
  ///
  /// Les réponses sont rangées par identifiant, jamais par position : insérer
  /// une question maison en fin de bloc ne déplace donc aucune réponse déjà
  /// donnée, et une reprise reste valide.
  final String id;

  final QText text;

  /// Cotation inversée (par exemple l'item 6 du RAADS-14). Porté par l'item
  /// parce que c'est une propriété de l'item publié, pas du bloc.
  final bool reverseScored;

  /// Sous-échelle d'appartenance quand l'instrument en a (les trois du CBI,
  /// l'anxiété et l'humeur d'un rapport commun). `null` sinon.
  final String? subscale;

  @override
  List<Object?> get props => [id, text, reverseScored, subscale];
}
