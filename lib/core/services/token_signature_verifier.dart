// lib/core/services/token_signature_verifier.dart
//
// Vérification HORS-LIGNE d'un token signé (JWS compact EdDSA) avec la clé
// publique Ed25519 pinnée dans AppConstants. Pur Dart (package cryptography),
// fonctionne en Flutter Web release (dart2js).
//
// ⚠️ PORTÉE : cette vérification est un CONTRÔLE D'INTÉGRITÉ local (détecte un
//    token altéré / un Worker mal configuré / une mauvaise clé). Ce n'est PAS un
//    contrôle d'accès : un attaquant n'exécute pas cette fonction. Le vrai
//    contrôle d'accès sera la RE-VÉRIFICATION côté serveur au moment de servir
//    les données (à construire). Voir PLAN_TOKEN_FIN_DE_TEST.md.

import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';

/// Versions de schéma de claims (`sv`) que cette build sait interpréter.
/// Miroir de `SUPPORTED_SCHEMA_VERSIONS` dans workers/_shared/token_verify.js.
const Set<int> _kSupportedSchemaVersions = {2};

/// Caractères autorisés dans un segment base64url (anti-octets parasites).
final RegExp _b64urlSegment = RegExp(r'^[A-Za-z0-9\-_]+$');

class TokenVerificationResult {
  final bool valid;
  final Map<String, dynamic>? claims;

  /// Code d'échec lisible (pour le debug / l'UI), null si valide.
  final String? reason;

  const TokenVerificationResult._(this.valid, this.claims, this.reason);

  factory TokenVerificationResult.ok(Map<String, dynamic> claims) =>
      TokenVerificationResult._(true, claims, null);

  factory TokenVerificationResult.fail(String reason) =>
      TokenVerificationResult._(false, null, reason);
}

class TokenSignatureVerifier {
  TokenSignatureVerifier._();

  static final _algo = Ed25519();

  /// TESTS UNIQUEMENT : remplace les clés pinnées de production. Permet aux
  /// tests de signer leurs fixtures avec un keypair de test sans jamais
  /// embarquer la clé privée de prod dans le repo. Null en fonctionnement réel.
  @visibleForTesting
  static Map<String, String>? debugKeysOverride;

  /// Vérifie la signature d'un token signé (3 segments) et renvoie ses claims.
  ///
  /// Tout chemin d'erreur renvoie un échec PROPRE (jamais d'exception).
  /// Un token DEV (2 segments `M2.…`) est considéré « non signé » → échec
  /// (utiliser TokenIssuer.tryDecode pour ces tokens DEV en debug).
  static Future<TokenVerificationResult> verifyAndDecode(String token) async {
    try {
      // Découpe sur le token ORIGINAL (pas de re-jointure) : on signe/vérifie
      // exactement les octets ASCII reçus pour `header.payload`.
      final lastDot = token.lastIndexOf('.');
      if (lastDot <= 0) return TokenVerificationResult.fail('format');
      final signingInputStr = token.substring(0, lastDot);
      final sigSeg = token.substring(lastDot + 1);

      final firstDot = signingInputStr.indexOf('.');
      if (firstDot <= 0) return TokenVerificationResult.fail('format');
      final headerSeg = signingInputStr.substring(0, firstDot);
      final payloadSeg = signingInputStr.substring(firstDot + 1);

      // Exactement 3 segments, tous en alphabet base64url strict.
      if (!_b64urlSegment.hasMatch(headerSeg) ||
          !_b64urlSegment.hasMatch(payloadSeg) ||
          !_b64urlSegment.hasMatch(sigSeg)) {
        return TokenVerificationResult.fail('format');
      }

      // Header : alg EN DUR (anti alg:none / confusion), kid String connu.
      final header = _decodeJson(headerSeg);
      if (header == null) return TokenVerificationResult.fail('header');
      if (header['alg'] != 'EdDSA') {
        return TokenVerificationResult.fail('alg');
      }
      final kid = header['kid'];
      if (kid is! String) return TokenVerificationResult.fail('kid');
      final pubB64 =
          (debugKeysOverride ?? AppConstants.tokenSigningPublicKeys)[kid];
      if (pubB64 == null) return TokenVerificationResult.fail('kid_unknown');

      final pubBytes = _b64urlDecode(pubB64);
      if (pubBytes == null || pubBytes.length != 32) {
        return TokenVerificationResult.fail('pubkey');
      }
      final sigBytes = _b64urlDecode(sigSeg);
      if (sigBytes == null || sigBytes.length != 64) {
        return TokenVerificationResult.fail('sig_len');
      }

      final publicKey = SimplePublicKey(pubBytes, type: KeyPairType.ed25519);
      final ok = await _algo.verify(
        utf8.encode(signingInputStr),
        signature: Signature(sigBytes, publicKey: publicKey),
      );
      if (!ok) return TokenVerificationResult.fail('signature');

      // Payload : décodable + version de schéma supportée.
      final payload = _decodeJson(payloadSeg);
      if (payload == null) return TokenVerificationResult.fail('payload');
      final sv = payload['sv'];
      if (sv is! int || !_kSupportedSchemaVersions.contains(sv)) {
        return TokenVerificationResult.fail('schema_version');
      }
      return TokenVerificationResult.ok(payload);
    } catch (_) {
      return TokenVerificationResult.fail('exception');
    }
  }

  /// `true` si le token est signé et valide. Raccourci pour les gardes simples.
  static Future<bool> isValid(String token) async =>
      (await verifyAndDecode(token)).valid;

  static Map<String, dynamic>? _decodeJson(String seg) {
    final bytes = _b64urlDecode(seg);
    if (bytes == null) return null;
    try {
      final obj = jsonDecode(utf8.decode(bytes));
      return obj is Map<String, dynamic> ? obj : null;
    } catch (_) {
      return null;
    }
  }

  static List<int>? _b64urlDecode(String s) {
    try {
      return base64Url.decode(base64Url.normalize(s));
    } catch (_) {
      return null;
    }
  }
}
