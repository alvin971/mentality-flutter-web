// Un texte de questionnaire, dans les six langues du produit.
//
// Pourquoi ce type plutôt que les ARB : les items d'un instrument se comptent
// par centaines et changent en bloc (on importe un instrument entier, on le
// traduit entier). Les mettre dans les ARB noierait le chrome de l'app sous le
// contenu. Le chrome reste donc dans les ARB ; les items vivent ici, avec
// EXACTEMENT la même règle de repli que `l10n_fragments/_merge.py` :
//
//     valeur exacte  →  en  →  fr
//
// `fr` et `en` sont obligatoires — c'est ce qui rend le repli total et garantit
// qu'aucun écran ne peut se retrouver vide. Les quatre autres langues sont
// facultatives au compilateur pour que l'app tourne pendant qu'une traduction
// est en cours, et une garde de test (parité 6 langues) refuse de laisser
// partir un instrument incomplet.

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart' show Locale;

class QText extends Equatable {
  const QText({
    required this.fr,
    required this.en,
    this.enGB,
    this.de,
    this.es,
    this.pt,
  });

  /// Les six langues du produit, dans l'ordre où on les nomme partout ailleurs.
  static const List<String> locales = ['fr', 'en', 'en_GB', 'de', 'es', 'pt'];

  final String fr;
  final String en;
  final String? enGB;
  final String? de;
  final String? es;
  final String? pt;

  /// Le texte tel qu'il sera affiché à quelqu'un qui lit en [locale].
  ///
  /// Ne renvoie jamais une chaîne vide : `en` puis `fr` closent la chaîne de
  /// repli, et tous deux sont obligatoires.
  String resolve(Locale locale) {
    final tag = locale.countryCode == null || locale.countryCode!.isEmpty
        ? locale.languageCode
        : '${locale.languageCode}_${locale.countryCode}';
    return raw(tag) ?? raw(locale.languageCode) ?? en;
  }

  /// La valeur BRUTE écrite pour [tag] — `null` si cette langue n'est pas
  /// traduite. Sans repli : c'est ce que regarde la garde de parité.
  String? raw(String tag) {
    final value = switch (tag) {
      'fr' => fr,
      'en' => en,
      'en_GB' => enGB,
      'de' => de,
      'es' => es,
      'pt' => pt,
      _ => null,
    };
    return (value == null || value.isEmpty) ? null : value;
  }

  /// Les langues qu'il reste à traduire. Vide = prêt à partir.
  List<String> get missingLocales =>
      [for (final tag in locales) if (raw(tag) == null) tag];

  @override
  List<Object?> get props => [fr, en, enGB, de, es, pt];
}
