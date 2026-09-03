// lib/core/services/token_issuer.dart
//
// Émission du token anonyme côté client.
// Voir PLAN_TOKEN_FIN_DE_TEST.md à la racine du repo.
//
// Format compact — voir workers/tokeniser/index.js (source de vérité miroir
// côté serveur) :
//   sv 2 : {"s":<sex>,"y":<birth_year>,"m":<birth_month>,"r":<region>,
//           "d":<jours depuis epoch>,"n":<nonce b64url>,"sv":2}
//   sv 3 : les mêmes claims + {"p":"free"|"paid","cc":<bool>,"cv":"<version>"}
//          — le plan choisi à l'inscription, le consentement au corpus vocal
//          et la version des textes légaux acceptée.
// Les deux versions restent valides : un token sv 2 émis avant le 2026-09-02
// ne doit jamais cesser de fonctionner.
// Le token est ÉMIS UNE FOIS et ne change plus jamais ensuite : la
// complétion du test est enregistrée côté serveur (marqueur R2), jamais en
// re-signant un nouveau token (cf. TokenIssuer.markCompleted).

import 'dart:convert';

import 'package:flutter/foundation.dart' show kReleaseMode;

import '../constants/app_constants.dart';
import '../constants/token_regions.dart';
import 'token_claim_numbers.dart';
import '../../services/tokeniser_service.dart';

/// Version de schéma COURANTE des claims (cf. `sv`) : celle qu'un token DEV
/// émis aujourd'hui porterait. Doit rester synchronisée avec
/// `SCHEMA_VERSION_PLAN` dans workers/tokeniser/index.js.
const int kTokenSchemaVersion = 3;

/// Versions de schéma que cette build sait DÉCODER.
///
/// ⚠️ Volontairement un ENSEMBLE, pas une égalité stricte à
/// [kTokenSchemaVersion] : les passes `sv: 2` émis avant le 2026-09-02 vivent
/// sur des téléphones réels et doivent rester lisibles. Une égalité stricte
/// les rejetterait tous du jour au lendemain.
/// Miroir de `SUPPORTED_SCHEMA_VERSIONS` dans workers/_shared/token_verify.js.
const Set<int> kTokenSupportedSchemaVersions = {2, 3};

/// Plans autorisés dans le claim `p` (allow-list fermée, miroir de
/// `ALLOWED_PLANS` côté Worker). Tout autre valeur ⇒ token mal formé.
const Set<String> kTokenPlans = {'free', 'paid'};

/// Sexes autorisés (allow-list fermée, miroir de `ALLOWED_SEX` côté Worker).
const Set<String> _kAllowedSex = {'M', 'F', 'X'};

/// Émet le token anonyme.
///
/// Deux chemins :
/// - PROD (Worker configuré) : le Worker « tokeniseur » SIGNE en Ed25519 (clé
///   privée jamais dans le client), ajoute un nonce 128 bits + le signup_day
///   (UTC, autorité serveur). Le client vérifie la signature à réception
///   (sanity-check de config) avec la clé publique pinnée. Token = 3 segments.
/// - DEV (Worker non configuré, debug uniquement) : token NON signé
///   `M2.base64(claims)`, pour tester sans backend. INTERDIT en release.
///
/// Signer ≠ chiffrer : le contenu (données larges) n'est pas secret, donc non
/// chiffré ; la signature empêche seulement la FORGE. Voir PLAN_TOKEN_FIN_DE_TEST.md.
///
/// Le token est IMMUABLE une fois émis : `markCompleted` ne le modifie pas,
/// il ne fait qu'enregistrer côté serveur que le test a été complété.
/// ⚠️ CETTE CLASSE N'ÉMET PLUS DE TOKEN — et c'est délibéré.
/// L'inscription se fait EXCLUSIVEMENT sur mental-et.com/inscription, via le
/// worker Cloudflare `tokeniser`. L'app REÇOIT un token (écran de connexion),
/// elle n'en crée jamais : `issue()` et `TokenDemographics` ont été retirés le
/// 2026-08-23, avec les écrans qui les appelaient. Ne pas les réintroduire sans
/// revenir sur cette décision produit.
class TokenIssuer {
  /// Préfixe de version du format de token DEV (non signé, 2 segments).
  static const String prefix = 'M2';

  /// Enregistre côté serveur que le test a été complété (soumission).
  ///
  /// Le token local NE CHANGE PAS : rien à re-persister après cet appel. Le
  /// Worker vérifie une preuve de complétion (enregistrements présents) puis
  /// pose un marqueur permanent côté serveur — voir workers/tokeniser/index.js.
  static Future<void> markCompleted(String token) async {
    final resultat = await verifyCompletion(token);
    if (!resultat.isOk) {
      throw TokeniserException(
          'validation refusée par le tokeniseur ($resultat)');
    }
  }

  /// Demande au serveur où en est la vérification de la complétion, sans
  /// lever : c'est le [TokenValidationResult] qui porte le verdict (vérifié,
  /// en cours, refusé, injoignable). C'est ce qu'attend l'étape d'attente de
  /// l'épreuve orale, qui doit distinguer « attendre » de « réenregistrer ».
  ///
  /// Sans tokeniseur configuré (DEV/TEST), il n'y a rien à vérifier côté
  /// serveur : un token DEV bien formé vaut « vérifié », un token illisible
  /// vaut « refusé ».
  static Future<TokenValidationResult> verifyCompletion(String token) async {
    final tokeniser = TokeniserService.instance;

    if (tokeniser.isConfigured) return tokeniser.validateToken(token);

    // FALLBACK DEV/TEST — aucun backend pour enregistrer la complétion ; le
    // token DEV reste tel quel, on vérifie juste qu'il est bien formé.
    if (kReleaseMode && !AppConstants.kAllowUnsignedTokenInRelease) {
      throw StateError(
        "Validation indisponible en release sans tokeniseur configuré.",
      );
    }
    if (tryDecode(token) == null) {
      return const TokenValidationResult.failed(message: 'token DEV invalide');
    }
    return const TokenValidationResult.ok();
  }

  /// Décode les claims d'un token DEV (utilitaire de debug / vérification).
  /// Valide STRICTEMENT la forme (présence + type de chaque claim, version de
  /// schéma) : un JSON bien formé mais incomplet/mal typé est rejeté, pas
  /// seulement un JSON invalide.
  static Map<String, dynamic>? tryDecode(String token) {
    final parts = token.split('.');
    if (parts.length != 2 || parts[0] != prefix) return null;
    try {
      // `normalize` remet le bourrage `=` : la forme canonique base64url d'un
      // token (celle du Worker, celle des JWT) n'en porte pas, et
      // `base64Url.decode` seul la refuserait.
      final decoded = jsonDecode(
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      if (decoded is! Map<String, dynamic>) return null;
      if (!_hasValidShape(decoded)) return null;
      return decoded;
    } catch (_) {
      return null;
    }
  }

  /// Forme stricte des claims d'un token DEV.
  ///
  /// Socle commun à toutes les versions (s/y/m/r/d/n), puis, à partir de
  /// `sv: 3`, les claims de plan. Un `sv: 3` qui annonce `p: 'gold'`, un `cc`
  /// non booléen ou un `cv` vide est REJETÉ ici même : mieux vaut un token
  /// illisible (repli = écran in-app) qu'un plan à moitié cru.
  static bool _hasValidShape(Map<String, dynamic> claims) {
    // Tous les claims numériques passent par [claimEntier] : côté JS, `3` et
    // `3.0` sont indiscernables, et un passe parfaitement valide pour le
    // worker ne doit pas devenir illisible ici sur cette seule différence de
    // sérialisation.
    final sv = claimEntier(claims['sv']);
    if (sv == null || !kTokenSupportedSchemaVersions.contains(sv)) return false;

    final y = claimEntier(claims['y']);
    final m = claimEntier(claims['m']);
    final d = claimEntier(claims['d']);
    final socleOk = claims['s'] is String &&
        _kAllowedSex.contains(claims['s']) &&
        y != null &&
        m != null &&
        m >= 1 &&
        m <= 12 &&
        claims['r'] is String &&
        kTokenRegionCodes.contains(claims['r']) &&
        d != null &&
        claims['n'] is String;
    if (!socleOk) return false;
    if (sv < 3) return true;

    final p = claims['p'];
    final cv = claims['cv'];
    return p is String &&
        kTokenPlans.contains(p) &&
        claims['cc'] is bool &&
        cv is String &&
        cv.isNotEmpty;
  }
}
