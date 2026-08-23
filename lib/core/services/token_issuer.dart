// lib/core/services/token_issuer.dart
//
// Émission du token anonyme côté client.
// Voir PLAN_TOKEN_FIN_DE_TEST.md à la racine du repo.
//
// Format compact (sv: 2) — voir workers/tokeniser/index.js (source de
// vérité miroir côté serveur) :
//   {"s":<sex>,"y":<birth_year>,"m":<birth_month>,"r":<region>,
//    "d":<jours depuis epoch>,"n":<nonce b64url>,"sv":2}
// Le token est ÉMIS UNE FOIS et ne change plus jamais ensuite : la
// complétion du test est enregistrée côté serveur (marqueur R2), jamais en
// re-signant un nouveau token (cf. TokenIssuer.markCompleted).

import 'dart:convert';

import 'package:flutter/foundation.dart' show kReleaseMode;

import '../constants/app_constants.dart';
import '../constants/token_regions.dart';
import '../../services/tokeniser_service.dart';

/// Version de schéma courante des claims (cf. `sv`). Doit rester synchronisée
/// avec `SCHEMA_VERSION` dans workers/tokeniser/index.js et
/// `SUPPORTED_SCHEMA_VERSIONS` dans workers/_shared/token_verify.js.
const int kTokenSchemaVersion = 2;

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
    final tokeniser = TokeniserService.instance;

    if (tokeniser.isConfigured) {
      final ok = await tokeniser.validateToken(token);
      if (!ok) {
        throw const TokeniserException('validation refusée par le tokeniseur');
      }
      return;
    }

    // FALLBACK DEV/TEST — aucun backend pour enregistrer la complétion ; le
    // token DEV reste tel quel, on vérifie juste qu'il est bien formé.
    if (kReleaseMode && !AppConstants.kAllowUnsignedTokenInRelease) {
      throw StateError(
        "Validation indisponible en release sans tokeniseur configuré.",
      );
    }
    if (tryDecode(token) == null) {
      throw const TokeniserException('token DEV invalide');
    }
  }

  /// Décode les claims d'un token DEV (utilitaire de debug / vérification).
  /// Valide STRICTEMENT la forme (présence + type de chaque claim, version de
  /// schéma) : un JSON bien formé mais incomplet/mal typé est rejeté, pas
  /// seulement un JSON invalide.
  static Map<String, dynamic>? tryDecode(String token) {
    final parts = token.split('.');
    if (parts.length != 2 || parts[0] != prefix) return null;
    try {
      final decoded = jsonDecode(utf8.decode(base64Url.decode(parts[1])));
      if (decoded is! Map<String, dynamic>) return null;
      if (!_hasValidShape(decoded)) return null;
      return decoded;
    } catch (_) {
      return null;
    }
  }

  static bool _hasValidShape(Map<String, dynamic> claims) {
    return claims['s'] is String &&
        _kAllowedSex.contains(claims['s']) &&
        claims['y'] is int &&
        claims['m'] is int &&
        (claims['m'] as int) >= 1 &&
        (claims['m'] as int) <= 12 &&
        claims['r'] is String &&
        kTokenRegionCodes.contains(claims['r']) &&
        claims['d'] is int &&
        claims['n'] is String &&
        claims['sv'] == kTokenSchemaVersion;
  }
}
