// lib/core/services/token_claims_reader.dart
//
// Lecture des claims démographiques du token COURANT (celui persisté en local).
// Source unique pour dériver l'âge sans le redemander : l'année (`y`) et le
// mois (`m`) de naissance sont déjà encodés dans le token (cf. TokenIssuer /
// TokenDemographics). Le test complet n'a donc plus à saisir l'âge.

import 'dart:convert';

import 'package:flutter/foundation.dart' show kDebugMode, visibleForTesting;

import '../constants/app_constants.dart';
import 'auth_local_store.dart';
import 'token_issuer.dart';
import 'token_signature_verifier.dart';

class TokenClaimsReader {
  TokenClaimsReader._();

  /// Décode les claims du token courant.
  /// - PROD : token signé → vérification Ed25519 + décodage.
  /// - DEV / mode test : token `M2.…` non signé, décodable seulement en debug
  ///   ou si `kAllowUnsignedTokenInRelease`.
  /// Renvoie `null` si aucun token, token invalide, ou schéma non reconnu.
  static Future<Map<String, dynamic>?> currentClaims() async {
    try {
      final token = await AuthLocalStore.instance.getToken();
      if (token == null || token.isEmpty) return null;

      // 1) Chemin nominal : token signé, signature vérifiée.
      final res = await TokenSignatureVerifier.verifyAndDecode(token);
      if (res.valid && res.claims != null) return res.claims;

      // 2) Token DEV non signé « M2.… ».
      if (kDebugMode || AppConstants.kAllowUnsignedTokenInRelease) {
        final dev = TokenIssuer.tryDecode(token);
        if (dev != null) return dev;
      }

      // 3) Dernier recours DÉMOGRAPHIQUE (jamais pour l'accès) : lire le
      //    payload brut d'un token signé dont la signature ne se vérifie pas
      //    côté client — typiquement une clé publique pas encore pinnée pour
      //    ce `kid`, ou un `sv` plus récent que ceux supportés. L'âge ne sert
      //    qu'aux normes de score : le falsifier ne fausserait que son propre
      //    résultat, sans aucun gain d'accès (le verrou reste gouverné par la
      //    vérification complète, ailleurs). Sans ce recours, un simple
      //    décalage de clé/schéma ferait réapparaître la saisie manuelle.
      return payloadClaimsUnverified(token);
    } catch (_) {
      // Store indisponible / token illisible → aucun claim exploitable ;
      // l'appelant retombe sur la saisie manuelle (fail-safe).
      return null;
    }
  }

  /// Décode le payload (2ᵉ segment) d'un token signé à 3 segments SANS vérifier
  /// la signature. Réservé à la lecture démographique (âge) : ne jamais s'en
  /// servir pour une décision d'accès. Renvoie `null` si la forme n'est pas
  /// exploitable (segment absent, base64/JSON invalide, racine non-objet).
  @visibleForTesting
  static Map<String, dynamic>? payloadClaimsUnverified(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    try {
      final json =
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final decoded = jsonDecode(json);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  /// Âge en MOIS calculé depuis (`y`, `m`) du token, au mois près.
  /// [now] est injectable pour les tests. Renvoie `null` si le token est
  /// indécodable ou si les claims d'âge sont absents/mal typés.
  static Future<int?> currentAgeInMonths({DateTime? now}) async {
    final claims = await currentClaims();
    if (claims == null) return null;
    final y = claims['y'];
    final m = claims['m'];
    if (y is! int || m is! int) return null;
    return ageInMonthsFrom(y, m, now ?? DateTime.now());
  }

  /// Calcul PUR (testable) de l'âge en mois depuis l'année/mois de naissance.
  /// Renvoie `null` si le résultat est négatif (date incohérente).
  static int? ageInMonthsFrom(int birthYear, int birthMonth, DateTime now) {
    final months = (now.year - birthYear) * 12 + (now.month - birthMonth);
    return months >= 0 ? months : null;
  }
}
