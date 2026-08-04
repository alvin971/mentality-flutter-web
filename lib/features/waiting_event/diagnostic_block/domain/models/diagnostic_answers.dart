// Le bloc diagnostic — ce que la personne déclare d'elle-même.
//
// C'est la donnée la plus sensible de l'app, et aussi la plus structurante :
// sans elle, aucune échelle maison ne peut être construite. La méthode
// retenue (keying empirique par critère) ne sait rien faire d'autre que
// comparer un groupe DIAGNOSTIQUÉ à un groupe témoin — d'où la finesse
// demandée ici, et d'où les trois catégories qu'il ne faut jamais confondre :
//
//   · diagnostiqué par un spécialiste — le critère dur ;
//   · « je le pense, sans diagnostic » — une TROISIÈME catégorie, jamais
//     mélangée à la première : elle mesure une croyance, pas un diagnostic ;
//   · « je préfère ne pas répondre » — exclu de l'analyse, et c'est
//     exactement pourquoi la case existe. Sans elle, qui ne veut pas se
//     déclarer coche « aucun » et pollue silencieusement le groupe témoin.
//
// DEUX ABSENCES ASSUMÉES, par rapport à la spec produit §6 :
//
// · AUCUN CHAMP LIBRE. « Autre » est une case à cocher, sans zone de texte.
//   Un champ libre dans une charge utile art. 9 est le pire vecteur de
//   ré-identification qui soit — les gens y écrivent des troubles rares, des
//   noms de médecins, parfois le leur —, et le format de fil est entier par
//   construction. Ce qu'on y aurait gagné (savoir QUEL autre trouble) ne
//   vaut pas ce qu'on y aurait risqué.
// · AUCUNE ANNÉE EXACTE, mais une ANCIENNETÉ par tranches. Une année précise
//   croisée au trouble et à l'âge est un quasi-identifiant, et l'analyse
//   n'en a pas besoin : ce qu'elle exploite, c'est la récence. Accessoirement,
//   une tranche ne demande pas de connaître la date du jour — or ce code ne
//   lit jamais l'horloge locale.

import 'package:equatable/equatable.dart';

/// Les troubles proposés, dans l'ordre d'affichage (spec produit §6).
///
/// Les noms de ces valeurs sont un CONTRAT DE DONNÉES : ils forment les clés
/// envoyées au serveur. Les renommer désaligne les réponses déjà collectées de
/// celles à venir, sans qu'aucun écran ne change.
enum DxCondition {
  adhd,
  autism,
  dyslexia,
  dyspraxia,
  dyscalculia,
  hpi,
  depression,
  anxiety,
  bipolar,
  ocd,
  sleep,
  burnout,
  other,
}

/// Qui a posé le diagnostic. `selfSuspected` n'est PAS un diagnostic — c'est
/// la troisième catégorie, et elle doit rester séparable à l'analyse.
enum DxSource { psychiatrist, gp, psychologist, selfSuspected }

/// Depuis combien de temps. Par tranches, jamais en année exacte.
enum DxRecency { under1Year, from1to3Years, from3to10Years, over10Years, unknown }

enum DxTreatment { current, none, past }

enum DxAssessment { yes, no, unknown }

/// Les cotations partent à 1, jamais à 0 : dans une carte d'entiers, un 0 ne
/// se distingue pas d'une valeur par défaut qu'on aurait laissée passer.
int _code(Enum value) => value.index + 1;

T? _byCode<T extends Enum>(List<T> values, int? code) =>
    (code == null || code < 1 || code > values.length)
        ? null
        : values[code - 1];

/// Le détail demandé pour CHAQUE trouble coché. Les quatre réponses sont
/// requises : un détail à trous laisserait une déclaration à moitié
/// interprétable, ce qui est pire qu'aucune.
class DiagnosticDetail extends Equatable {
  const DiagnosticDetail({
    required this.source,
    required this.recency,
    required this.treatment,
    required this.assessment,
  });

  final DxSource source;
  final DxRecency recency;
  final DxTreatment treatment;
  final DxAssessment assessment;

  @override
  List<Object?> get props => [source, recency, treatment, assessment];
}

/// Un détail en cours de saisie — les quatre champs, chacun encore facultatif.
class DiagnosticDetailDraft {
  DxSource? source;
  DxRecency? recency;
  DxTreatment? treatment;
  DxAssessment? assessment;

  bool get isComplete =>
      source != null &&
      recency != null &&
      treatment != null &&
      assessment != null;

  DiagnosticDetail? build() => isComplete
      ? DiagnosticDetail(
          source: source!,
          recency: recency!,
          treatment: treatment!,
          assessment: assessment!,
        )
      : null;
}

/// Les réponses complètes du bloc, prêtes à être écrites.
///
/// Trois formes possibles, et TROIS SEULEMENT — l'invariant est vérifié à la
/// construction parce qu'une quatrième (« aucun » ET des troubles cochés)
/// n'aurait aucune lecture défendable à l'analyse.
class DiagnosticAnswers extends Equatable {
  const DiagnosticAnswers._({
    required this.details,
    required this.isNone,
    required this.isDeclined,
  });

  /// La personne a coché des troubles : un détail complet par trouble.
  factory DiagnosticAnswers.declared(Map<DxCondition, DiagnosticDetail> details) {
    assert(details.isNotEmpty, 'une déclaration sans trouble n\'est pas une déclaration');
    return DiagnosticAnswers._(
      details: Map.unmodifiable(details),
      isNone: false,
      isDeclined: false,
    );
  }

  /// « Aucun » — une information, pas une absence d'information : c'est le
  /// groupe témoin.
  static const DiagnosticAnswers none =
      DiagnosticAnswers._(details: {}, isNone: true, isDeclined: false);

  /// « Je préfère ne pas répondre » — la personne sort de l'analyse, et c'est
  /// son droit le plus strict.
  static const DiagnosticAnswers declined =
      DiagnosticAnswers._(details: {}, isNone: false, isDeclined: true);

  final Map<DxCondition, DiagnosticDetail> details;

  /// « Aucun trouble » — le groupe témoin. Nommé `isNone` et non `none` : la
  /// forme canonique porte déjà ce nom ([DiagnosticAnswers.none]).
  final bool isNone;

  /// « Je préfère ne pas répondre ».
  final bool isDeclined;

  Set<DxCondition> get conditions => details.keys.toSet();

  /// Identifiant de stockage ET d'envoi. Ce n'est pas un module du programme :
  /// il n'entre dans aucune règle de volume (40-50 questions) et n'apparaît
  /// dans `QModuleRegistry` sous aucune forme.
  static const String moduleId = 'diagnostic_block';

  /// Clé du refus global.
  static const String declinedKey = 'declined';

  /// Clé du « aucun trouble ».
  static const String noneKey = 'none';

  /// La forme entière — celle qui va sur le disque et sur le fil.
  ///
  /// Le préfixe `dx.` isole les troubles des deux clés globales : sans lui,
  /// un trouble qui s'appellerait un jour « none » écraserait la réponse
  /// « aucun ».
  Map<String, int> toAnswers() {
    if (isDeclined) return const {declinedKey: 1};
    if (isNone) return const {noneKey: 1};
    final out = <String, int>{};
    // Ordre canonique de l'enum, pas ordre d'insertion : deux personnes ayant
    // coché les mêmes cases produisent la même carte.
    for (final condition in DxCondition.values) {
      final detail = details[condition];
      if (detail == null) continue;
      final base = 'dx.${condition.name}';
      out[base] = 1;
      out['$base.source'] = _code(detail.source);
      out['$base.recency'] = _code(detail.recency);
      out['$base.treatment'] = _code(detail.treatment);
      out['$base.assessment'] = _code(detail.assessment);
    }
    return out;
  }

  /// Relecture. `null` quand la carte ne décrit aucune des trois formes —
  /// une déclaration à moitié lisible n'est pas relue de travers, elle est
  /// rejetée.
  static DiagnosticAnswers? fromAnswers(Map<String, int> answers) {
    if (answers[declinedKey] == 1) return declined;
    if (answers[noneKey] == 1) return none;
    final details = <DxCondition, DiagnosticDetail>{};
    for (final condition in DxCondition.values) {
      final base = 'dx.${condition.name}';
      if (answers[base] != 1) continue;
      final source = _byCode(DxSource.values, answers['$base.source']);
      final recency = _byCode(DxRecency.values, answers['$base.recency']);
      final treatment = _byCode(DxTreatment.values, answers['$base.treatment']);
      final assessment =
          _byCode(DxAssessment.values, answers['$base.assessment']);
      if (source == null ||
          recency == null ||
          treatment == null ||
          assessment == null) {
        return null;
      }
      details[condition] = DiagnosticDetail(
        source: source,
        recency: recency,
        treatment: treatment,
        assessment: assessment,
      );
    }
    return details.isEmpty ? null : DiagnosticAnswers.declared(details);
  }

  @override
  List<Object?> get props => [details, isNone, isDeclined];
}
