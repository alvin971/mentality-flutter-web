// lib/core/services/token_access.dart
//
// Politique d'acceptation d'un token pour l'accès local (gate splash + écran de
// reconnexion). Source unique de vérité pour décider si un token donne accès.

import 'package:flutter/foundation.dart' show kDebugMode;

import '../constants/app_constants.dart';
import 'token_issuer.dart';
import 'token_signature_verifier.dart';

class TokenAccess {
  TokenAccess._();

  /// `true` si [token] donne accès :
  /// - token SIGNÉ dont la signature Ed25519 est valide, OU
  /// - en debug / mode test (kAllowUnsignedTokenInRelease), un token DEV
  ///   (`M2.…`) décodable. En prod réelle, seule la signature compte.
  static Future<bool> isAcceptable(String? token) async {
    if (token == null || token.isEmpty) return false;
    if (await TokenSignatureVerifier.isValid(token)) return true;
    if ((kDebugMode || AppConstants.kAllowUnsignedTokenInRelease) &&
        TokenIssuer.tryDecode(token) != null) {
      return true;
    }
    return false;
  }
}
