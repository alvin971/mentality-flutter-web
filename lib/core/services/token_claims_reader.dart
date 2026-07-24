// lib/core/services/token_claims_reader.dart
//
// Lecture des claims démographiques du token COURANT (celui persisté en local).
// Source unique pour dériver l'âge sans le redemander : l'année (`y`) et le
// mois (`m`) de naissance sont déjà encodés dans le token (cf. TokenIssuer /
// TokenDemographics). Le test complet n'a donc plus à saisir l'âge.

import 'package:flutter/foundation.dart' show kDebugMode;

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

      final res = await TokenSignatureVerifier.verifyAndDecode(token);
      if (res.valid && res.claims != null) return res.claims;

      if (kDebugMode || AppConstants.kAllowUnsignedTokenInRelease) {
        return TokenIssuer.tryDecode(token);
      }
      return null;
    } catch (_) {
      // Lecture/déchiffrement du store indisponible → aucun claim exploitable.
      // L'appelant retombe alors sur la saisie manuelle (fail-safe).
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
