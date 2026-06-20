// lib/core/services/token_issuer.dart
//
// Émission du token anonyme côté client.
// Voir PLAN_TOKEN_FIN_DE_TEST.md à la racine du repo.

import 'dart:convert';

import 'package:flutter/foundation.dart' show kReleaseMode;

import '../constants/app_constants.dart';
import '../../services/tokeniser_service.dart';
import 'token_signature_verifier.dart';

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

  Map<String, dynamic> toClaims() => {
        'sex': sexCode,
        'birth_year': birthYear,
        'birth_month': birthMonth,
        'region': regionCode,
      };
}

/// Émet le token anonyme.
///
/// Deux chemins :
/// - PROD (Worker configuré) : le Worker « tokeniseur » SIGNE en Ed25519 (clé
///   privée jamais dans le client), ajoute un nonce 256 bits + le signup_day
///   (UTC, autorité serveur). Le client vérifie la signature à réception
///   (sanity-check de config) avec la clé publique pinnée. Token = 3 segments.
/// - DEV (Worker non configuré, debug uniquement) : token NON signé
///   `MENTA1.base64(claims)`, pour tester sans backend. INTERDIT en release.
///
/// Signer ≠ chiffrer : le contenu (données larges) n'est pas secret, donc non
/// chiffré ; la signature empêche seulement la FORGE. Voir PLAN_TOKEN_FIN_DE_TEST.md.
class TokenIssuer {
  /// Préfixe de version du format de token DEV (non signé, 2 segments).
  static const String prefix = 'MENTA1';

  /// Émet le token. [now] permet d'injecter la date dans les tests (chemin DEV).
  /// Le jour d'inscription est au JOUR (jamais l'heure : l'instant précis
  /// redeviendrait un quasi-identifiant).
  static Future<String> issue(TokenDemographics demo, {DateTime? now}) async {
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
    final signupDay = '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
    final claims = <String, dynamic>{
      ...demo.toClaims(),
      'signup_day': signupDay,
      'status': 'provisional',
      'sv': 1,
    };
    final payload = base64Url.encode(utf8.encode(jsonEncode(claims)));
    return '$prefix.$payload';
  }

  /// Fait passer un token PROVISOIRE à VALIDÉ (à la soumission d'un test).
  /// Conserve nonce + démographiques. Retourne le nouveau token (à persister).
  static Future<String> validate(String token) async {
    final tokeniser = TokeniserService.instance;

    if (tokeniser.isConfigured) {
      final newToken = await tokeniser.validateToken(token);
      if (newToken == null) {
        throw const TokeniserException('tokeniseur non configuré');
      }
      final res = await TokenSignatureVerifier.verifyAndDecode(newToken);
      if (!res.valid) {
        throw TokeniserException('token validé invalide (${res.reason})');
      }
      return newToken;
    }

    // FALLBACK DEV/TEST — bascule le statut dans le token non signé.
    if (kReleaseMode && !AppConstants.kAllowUnsignedTokenInRelease) {
      throw StateError(
        "Validation indisponible en release sans tokeniseur configuré.",
      );
    }
    final claims = tryDecode(token);
    if (claims == null) {
      throw const TokeniserException('token DEV invalide');
    }
    final updated = <String, dynamic>{...claims, 'status': 'validated'};
    final payload = base64Url.encode(utf8.encode(jsonEncode(updated)));
    return '$prefix.$payload';
  }

  /// Décode les claims d'un token DEV (utilitaire de debug / vérification).
  static Map<String, dynamic>? tryDecode(String token) {
    final parts = token.split('.');
    if (parts.length != 2 || parts[0] != prefix) return null;
    try {
      return jsonDecode(utf8.decode(base64Url.decode(parts[1])))
          as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
