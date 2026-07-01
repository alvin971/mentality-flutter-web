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
import 'dart:math';

import 'package:flutter/foundation.dart' show kReleaseMode;

import '../constants/app_constants.dart';
import '../constants/token_regions.dart';
import '../../services/tokeniser_service.dart';
import 'token_signature_verifier.dart';

/// Version de schéma courante des claims (cf. `sv`). Doit rester synchronisée
/// avec `SCHEMA_VERSION` dans workers/tokeniser/index.js et
/// `SUPPORTED_SCHEMA_VERSIONS` dans workers/_shared/token_verify.js.
const int kTokenSchemaVersion = 2;

/// Sexes autorisés (allow-list fermée, miroir de `ALLOWED_SEX` côté Worker).
const Set<String> _kAllowedSex = {'M', 'F', 'X'};

/// Données démographiques LARGES encodées dans le token anonyme.
///
/// Granularité volontairement grossière (c'est le SEUL garde-fou de l'anonymat) :
/// sexe + mois/année de naissance + région + jour d'inscription.
/// AUCUNE donnée fine (jour de naissance, adresse précise, téléphone, nom) →
/// le token est anonyme par construction (aucun lien vers une identité).
///
/// Règle d'or : plus l'âge est précis, plus la région doit être large.
class TokenDemographics {
  /// 'M' | 'F' | 'X' (cf. SexX.code dans registration_form.dart).
  final String sexCode;

  /// Année de naissance (ex. 1998).
  final int birthYear;

  /// Mois de naissance 1–12. JAMAIS le jour.
  final int birthMonth;

  /// Code région large (ex. 'IDF', 'OCC', 'OTHER'). JAMAIS code postal/commune.
  final String regionCode;

  const TokenDemographics({
    required this.sexCode,
    required this.birthYear,
    required this.birthMonth,
    required this.regionCode,
  });

  /// Valide les claims AVANT émission — miroir exact des règles appliquées
  /// côté Worker (`validateClaims` dans workers/tokeniser/index.js), pour
  /// que le chemin DEV/fallback n'accepte jamais des données que le Worker
  /// aurait rejetées. Lève [ArgumentError] si une valeur est invalide.
  void validate({DateTime? now}) {
    if (!_kAllowedSex.contains(sexCode)) {
      throw ArgumentError.value(sexCode, 'sexCode', 'sexe non autorisé');
    }
    if (!kTokenRegionCodes.contains(regionCode)) {
      throw ArgumentError.value(regionCode, 'regionCode', 'région non autorisée');
    }
    if (birthMonth < 1 || birthMonth > 12) {
      throw ArgumentError.value(birthMonth, 'birthMonth', 'mois invalide (1-12)');
    }
    final nowYear = (now ?? DateTime.now()).year;
    if (birthYear < nowYear - 100 || birthYear > nowYear - 5) {
      throw ArgumentError.value(
          birthYear, 'birthYear', 'année de naissance implausible');
    }
  }

  Map<String, dynamic> toClaims() => {
        's': sexCode,
        'y': birthYear,
        'm': birthMonth,
        'r': regionCode,
      };
}

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
class TokenIssuer {
  /// Préfixe de version du format de token DEV (non signé, 2 segments).
  static const String prefix = 'M2';

  /// Émet le token. [now] permet d'injecter la date dans les tests (chemin DEV).
  /// Le jour d'inscription est au JOUR (jamais l'heure : l'instant précis
  /// redeviendrait un quasi-identifiant).
  static Future<String> issue(TokenDemographics demo, {DateTime? now}) async {
    demo.validate(now: now);
    final tokeniser = TokeniserService.instance;

    if (tokeniser.isConfigured) {
      // N'envoyer QUE les claims larges : le Worker rejette tout champ en plus
      // et fixe lui-même signup_day (UTC) + nonce + sv.
      final token = await tokeniser.requestSignedToken(demo.toClaims());
      if (token == null) {
        throw const TokeniserException('tokeniseur non configuré');
      }
      final res = await TokenSignatureVerifier.verifyAndDecode(token);
      if (!res.valid) {
        throw TokeniserException('token signé invalide (${res.reason})');
      }
      return token;
    }

    // FALLBACK DEV/TEST — token local non signé. Refusé en release SAUF en mode
    // test explicite (kAllowUnsignedTokenInRelease), pour ne jamais émettre un
    // faux token non signé en production réelle.
    if (kReleaseMode && !AppConstants.kAllowUnsignedTokenInRelease) {
      throw StateError(
        "Tokeniser non configuré en release : refus d'émettre un token non signé.",
      );
    }
    final d = now ?? DateTime.now();
    final claims = <String, dynamic>{
      ...demo.toClaims(),
      'd': _daysSinceEpoch(d),
      'n': _randomNonce(),
      'sv': kTokenSchemaVersion,
    };
    final payload = base64Url.encode(utf8.encode(jsonEncode(claims)));
    return '$prefix.$payload';
  }

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

  static int _daysSinceEpoch(DateTime d) {
    final utcDay = DateTime.utc(d.year, d.month, d.day);
    return utcDay.difference(DateTime.utc(1970, 1, 1)).inDays;
  }

  /// Nonce 128 bits (16 octets), base64url sans padding — identifiant de
  /// partition, pas un secret (miroir du nonce généré côté Worker).
  static String _randomNonce() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }
}
