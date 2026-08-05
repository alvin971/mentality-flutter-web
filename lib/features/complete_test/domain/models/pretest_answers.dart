// Ce que l'on demande AVANT le premier sous-test — et rien de plus.
//
// Une seule question obligatoire (« as-tu déjà passé un test de QI ? »), puis
// un embranchement : à qui l'a passé chez un professionnel on demande l'âge et
// le score de l'époque, aux autres on demande ce qu'ils estiment valoir. Les
// deux branches ne mesurent pas la même chose et ne doivent jamais se
// mélanger : un score rapporté est un souvenir de mesure, une estimation est
// une croyance. Les confondre dans un même champ rendrait l'écart
// estimation ↔ score inexploitable.
//
// Trois choix de conception valent d'être écrits noir sur blanc :
//
// · AUCUNE COTATION À ZÉRO. Le code d'un choix vaut `index + 1`, comme dans le
//   bloc diagnostic. Zéro est la valeur que produit un champ vide, un parse
//   raté ou un entier par défaut : le distinguer d'une réponse réelle coûte
//   une ligne ici et évite d'attribuer « oui, avec un psychiatre » à quelqu'un
//   qui n'a rien répondu.
// · AUCUN CHAMP LIBRE, AUCUNE ANNÉE. Ni le nom du praticien, ni l'année exacte
//   du test : un âge de passation suffit à l'analyse, et une année précise
//   croisée avec l'âge du token est un quasi-identifiant.
// · LES BORNES REFUSENT, ELLES NE CORRIGENT PAS. Une valeur hors bornes est une
//   faute de frappe, pas une donnée à ramener au plus proche. On la rejette et
//   on le dit à l'écran ; la ramener silencieusement à 200 inventerait un score
//   que personne n'a obtenu.

import 'package:equatable/equatable.dart';

/// La réponse à l'unique question obligatoire.
///
/// L'ordre est celui de l'écran, et il est FIGÉ : les codes persistés en
/// dépendent (`index + 1`). Insérer une valeur au milieu relirait les réponses
/// déjà données comme une autre modalité.
enum PriorIqTest {
  /// Passé avec un psychiatre ou un psychologue. C'est la seule branche où un
  /// score rapporté a une valeur de mesure.
  professional,

  /// Passé en ligne, sur un test dont la fiabilité n'est pas établie.
  online,

  /// Jamais passé.
  never,
}

extension PriorIqTestCode on PriorIqTest {
  /// Cotation persistée. Jamais 0 — voir l'en-tête de fichier.
  int get code => index + 1;

  /// Vrai quand la branche « âge + score du test passé » s'applique. Les
  /// autres reçoivent la question d'auto-estimation à la place.
  bool get reportsScore => this == PriorIqTest.professional;

  static PriorIqTest? fromCode(int? code) {
    if (code == null) return null;
    final i = code - 1;
    if (i < 0 || i >= PriorIqTest.values.length) return null;
    return PriorIqTest.values[i];
  }
}

/// Les réponses complètes du questionnaire préalable, prêtes à être écrites.
///
/// L'auto-estimation n'est PAS ici : elle a son propre stockage à écriture
/// unique (`SelfEstimateStore`), pour qu'elle ne puisse jamais être posée deux
/// fois — voir `PretestStore`.
class PretestAnswers extends Equatable {
  const PretestAnswers({
    required this.priorTest,
    this.ageAtTest,
    this.priorScore,
  });

  /// Bornes de l'âge de passation. Larges volontairement : les tests de QI se
  /// passent aussi dans l'enfance, et c'est même le cas le plus fréquent d'un
  /// bilan chez un psychologue.
  static const int minAge = 5;
  static const int maxAge = 90;

  /// Bornes du score rapporté. Larges elles aussi : elles n'écartent que ce
  /// qu'aucune échelle de QI publiée ne produit. Elles ne valident pas un
  /// souvenir, elles écartent une faute de frappe.
  static const int minScore = 40;
  static const int maxScore = 200;

  final PriorIqTest priorTest;

  /// Âge (en années) au moment du test passé chez un professionnel.
  /// `null` = question passée, ce qui est un droit explicite.
  final int? ageAtTest;

  /// Score rapporté de ce test. `null` = question passée.
  final int? priorScore;

  static bool isValidAge(int? value) =>
      value != null && value >= minAge && value <= maxAge;

  static bool isValidScore(int? value) =>
      value != null && value >= minScore && value <= maxScore;

  /// Identifiants d'items du stockage. Ce sont des clés de données : les
  /// renommer perd les réponses déjà écrites.
  static const String itemPriorTest = 'prior_iq_test';
  static const String itemAgeAtTest = 'prior_test_age';
  static const String itemPriorScore = 'prior_test_score';

  /// La forme persistée : identifiant d'item → valeur brute.
  ///
  /// Une question passée n'écrit AUCUNE clé — plutôt qu'une sentinelle. Un 0 ou
  /// un -1 finirait tôt ou tard dans une moyenne ; une clé absente, non.
  Map<String, int> toItems() => {
        itemPriorTest: priorTest.code,
        if (isValidAge(ageAtTest)) itemAgeAtTest: ageAtTest!,
        if (isValidScore(priorScore)) itemPriorScore: priorScore!,
      };

  /// Relecture. `null` si la question obligatoire n'est pas lisible : sans
  /// elle, le reste n'a aucun sens et la question doit se reposer.
  static PretestAnswers? fromItems(Map<String, int> items) {
    final prior = PriorIqTestCode.fromCode(items[itemPriorTest]);
    if (prior == null) return null;
    final age = items[itemAgeAtTest];
    final score = items[itemPriorScore];
    return PretestAnswers(
      priorTest: prior,
      // Une valeur hors bornes déjà sur le disque est ignorée plutôt que rendue
      // telle quelle : elle ne peut venir que d'une écriture corrompue.
      ageAtTest: isValidAge(age) ? age : null,
      priorScore: isValidScore(score) ? score : null,
    );
  }

  @override
  List<Object?> get props => [priorTest, ageAtTest, priorScore];
}

/// Brouillon de saisie — l'état de l'écran tant que rien n'est écrit.
///
/// Il existe pour que la page n'ait pas à porter elle-même la règle « quand
/// peut-on continuer ». Fermer l'écran avant [build] n'enregistre rien : la
/// question reste entière.
class PretestDraft {
  PriorIqTest? priorTest;
  int? ageAtTest;
  int? priorScore;

  /// La seule condition obligatoire. Tout le reste est facultatif par décision
  /// produit : forcer un chiffre à qui n'en a pas produit du bruit, pas de la
  /// donnée.
  bool get isComplete => priorTest != null;

  PretestAnswers? build() => priorTest == null
      ? null
      : PretestAnswers(
          priorTest: priorTest!,
          ageAtTest: ageAtTest,
          priorScore: priorScore,
        );
}
