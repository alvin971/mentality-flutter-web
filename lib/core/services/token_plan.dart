// lib/core/services/token_plan.dart
//
// Le PLAN porté par le token (`sv: 3`) et ce qui l'accompagne.
//
// Depuis le 2026-09-02, le passe est créé sur mental-et.com/inscription et
// porte le choix de l'utilisateur : passe Gratuit (le bilan est financé par un
// enregistrement vocal) ou passe Payant (même bilan, aucun enregistrement).
// Le consentement au corpus vocal est recueilli SUR LE SITE, avant l'émission,
// et voyage dans le token signé : c'est lui la preuve (art. 7 RGPD), pas un
// écran in-app.
//
// Miroir Dart de `readPlan()` dans workers/_shared/token_plan.js.
//
// ⚠️ Un `TokenPlanInfo` ne vaut que s'il a été dérivé de claims dont la
//    SIGNATURE a été vérifiée (ou d'un token DEV `M2.` en debug). Voir
//    `TokenClaimsReader.planFromToken` : le payload non vérifié n'est jamais
//    une source de plan.

/// Plan porté par le token.
///
/// [unknown] couvre tout ce qui n'est pas un plan lisible et digne de foi :
/// token `sv: 2` (antérieur au plan), claims de plan mal formés, token absent,
/// signature non vérifiable. Le repli est alors le comportement historique :
/// l'écran de consentement in-app.
enum TokenPlan { free, paid, unknown }

/// Ce que le token dit du plan, du consentement au corpus et du texte légal
/// accepté. Immuable : c'est une lecture, jamais un état modifiable.
class TokenPlanInfo {
  /// Plan choisi à l'inscription.
  final TokenPlan plan;

  /// Consentement au corpus vocal (claim `cc`). Toujours `false` hors du plan
  /// Gratuit : un passe Payant n'enregistre rien, donc ne cède rien.
  final bool corpusConsent;

  /// Version des textes légaux acceptée à l'inscription (claim `cv`), telle
  /// qu'elle doit être consignée comme preuve. `null` hors `sv: 3`.
  final String? legalVersion;

  /// Jour d'émission du passe (claim `d`, jours depuis l'epoch UTC). Sert à
  /// dater le consentement sans jamais lire l'horloge locale — c'est ce qui
  /// rend `ConsentService.syncFromToken` idempotente. `null` si absent.
  final int? issuedDay;

  const TokenPlanInfo({
    required this.plan,
    this.corpusConsent = false,
    this.legalVersion,
    this.issuedDay,
  });

  /// Aucune information exploitable : repli sur l'écran in-app.
  static const TokenPlanInfo unknown = TokenPlanInfo(plan: TokenPlan.unknown);

  /// `true` si le token porte réellement un plan (`sv: 3` bien formé).
  bool get isKnown => plan != TokenPlan.unknown;

  /// `true` si l'étape orale doit être jouée pour ce passe.
  /// Le passe Payant la saute ; un plan inconnu retombe sur l'écran in-app,
  /// qui décide lui-même.
  bool get allowsOralStep => plan != TokenPlan.paid;

  @override
  String toString() => 'TokenPlanInfo(plan: ${plan.name}, '
      'corpusConsent: $corpusConsent, legalVersion: $legalVersion, '
      'issuedDay: $issuedDay)';
}
