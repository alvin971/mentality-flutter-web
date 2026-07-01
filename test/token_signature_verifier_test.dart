// Test d'interopérabilité de la vérification de signature Ed25519.
//
// On SIGNE un token avec la seed du keypair DEV (celle dont la clé publique est
// pinnée dans AppConstants.tokenSigningPublicKeys['k1']), puis on vérifie via
// TokenSignatureVerifier. Cela valide à la fois la logique de vérif ET que la
// clé publique pinnée correspond bien à la clé privée DEV.

import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/core/services/token_signature_verifier.dart';

/// Seed raw 32 octets du keypair DEV (= 32 derniers octets du DER PKCS#8).
/// Voir workers/tokeniser/README.md pour la génération.
const String _devSeedB64 = 'qV13eS2BZTNM/yqlNhByezXrk5cYFtvdOO/8TzNI7to=';

String _b64url(List<int> bytes) =>
    base64Url.encode(bytes).replaceAll('=', '');

Future<SimpleKeyPair> _devKeyPair() =>
    Ed25519().newKeyPairFromSeed(base64.decode(_devSeedB64));

/// Reproduit le format du Worker : header.payload.signature (JWS compact EdDSA).
Future<String> _makeToken({
  required Map<String, dynamic> header,
  required Map<String, dynamic> payload,
  SimpleKeyPair? signWith,
}) async {
  final headerB64 = _b64url(utf8.encode(jsonEncode(header)));
  final payloadB64 = _b64url(utf8.encode(jsonEncode(payload)));
  final signingInput = utf8.encode('$headerB64.$payloadB64');
  final kp = signWith ?? await _devKeyPair();
  final sig = await Ed25519().sign(signingInput, keyPair: kp);
  return '$headerB64.$payloadB64.${_b64url(sig.bytes)}';
}

/// Header compact (sv: 2) — plus de `typ`, cf. workers/tokeniser/index.js.
Map<String, dynamic> _validHeader() => {'alg': 'EdDSA', 'kid': 'k1'};

/// Payload compact (sv: 2) — clés courtes s/y/m/r/d/n/sv, nonce 128 bits,
/// plus de `status`. Miroir de lib/core/services/token_issuer.dart.
Map<String, dynamic> _validPayload() => {
      's': 'M',
      'y': 1998,
      'm': 7,
      'r': 'IDF',
      'd': 20613,
      'n': _b64url(List<int>.generate(16, (i) => i)),
      'sv': 2,
    };

void main() {
  test('accepte un token correctement signé et renvoie ses claims', () async {
    final token =
        await _makeToken(header: _validHeader(), payload: _validPayload());
    final res = await TokenSignatureVerifier.verifyAndDecode(token);
    expect(res.valid, isTrue, reason: res.reason);
    expect(res.claims!['s'], 'M');
    expect(res.claims!['r'], 'IDF');
    expect(res.claims!['y'], 1998);
  });

  test('rejette un payload altéré (1 octet modifié)', () async {
    final token =
        await _makeToken(header: _validHeader(), payload: _validPayload());
    final parts = token.split('.');
    // Modifie le dernier caractère du segment payload.
    final tampered = parts[1].substring(0, parts[1].length - 1) +
        (parts[1].endsWith('A') ? 'B' : 'A');
    final res = await TokenSignatureVerifier.verifyAndDecode(
        '${parts[0]}.$tampered.${parts[2]}');
    expect(res.valid, isFalse);
  });

  test('rejette alg != EdDSA (anti alg confusion)', () async {
    final token = await _makeToken(
      header: {'alg': 'none', 'kid': 'k1'},
      payload: _validPayload(),
    );
    final res = await TokenSignatureVerifier.verifyAndDecode(token);
    expect(res.valid, isFalse);
    expect(res.reason, 'alg');
  });

  test('rejette un kid inconnu', () async {
    final token = await _makeToken(
      header: {'alg': 'EdDSA', 'kid': 'k999'},
      payload: _validPayload(),
    );
    final res = await TokenSignatureVerifier.verifyAndDecode(token);
    expect(res.valid, isFalse);
    expect(res.reason, 'kid_unknown');
  });

  test('rejette un kid de mauvais type (int)', () async {
    final token = await _makeToken(
      header: {'alg': 'EdDSA', 'kid': 42},
      payload: _validPayload(),
    );
    final res = await TokenSignatureVerifier.verifyAndDecode(token);
    expect(res.valid, isFalse);
    expect(res.reason, 'kid');
  });

  test('rejette une version de schéma non supportée', () async {
    final payload = _validPayload()..['sv'] = 99;
    final token = await _makeToken(header: _validHeader(), payload: payload);
    final res = await TokenSignatureVerifier.verifyAndDecode(token);
    expect(res.valid, isFalse);
    expect(res.reason, 'schema_version');
  });

  test('rejette une signature valide mais d\'une AUTRE clé', () async {
    final otherKey = await Ed25519().newKeyPair();
    final token = await _makeToken(
      header: _validHeader(),
      payload: _validPayload(),
      signWith: otherKey,
    );
    final res = await TokenSignatureVerifier.verifyAndDecode(token);
    expect(res.valid, isFalse);
    expect(res.reason, 'signature');
  });

  test('rejette un token DEV non signé (2 segments)', () async {
    final res = await TokenSignatureVerifier.verifyAndDecode('M2.abc');
    expect(res.valid, isFalse);
  });

  test('rejette du charabia', () async {
    expect((await TokenSignatureVerifier.verifyAndDecode('')).valid, isFalse);
    expect((await TokenSignatureVerifier.verifyAndDecode('x')).valid, isFalse);
    expect(
        (await TokenSignatureVerifier.verifyAndDecode('a.b.c.d')).valid, isFalse);
  });

  // RÉGRESSION — changement de format (sv: 1 → sv: 2) : ce token a été
  // RÉELLEMENT signé par WebCrypto (V8/Cloudflare Workers) avec la clé
  // privée DEV, dans l'ANCIEN format verbeux (sv:1, clés longues, nonce 256
  // bits). Il reste cryptographiquement valide (signature correcte) mais
  // DOIT être rejeté : c'est la version de schéma qui coupe la compatibilité,
  // pas la signature. Confirme que la bascule sv:1 → sv:2 est bien étanche.
  test('rejette un ancien token réel (sv:1, WebCrypto V8) après la bascule sv:2', () async {
    const oldV8Token =
        'eyJhbGciOiJFZERTQSIsInR5cCI6IkpXVCIsImtpZCI6ImsxIn0'
        '.eyJzZXgiOiJGIiwiYmlydGhfeWVhciI6MTk5MCwiYmlydGhfbW9udGgiOjMsInJlZ2lvbiI6Ik9DQyIsInNpZ251cF9kYXkiOiIyMDI2LTA2LTEzIiwibm9uY2UiOiJFNWxoWXJhV0ZqU3RyREc1ejRKcWVnSVhJWE9rdGpZdFpvYmhmNDNXOTBzIiwic3YiOjF9'
        '.Mp00iw5CRtvXjsgc-QUV58J__pXxae4AhtvvupGJzLRyxltX5ERflJKRxOy6V7JmxGJ3v5tj7J5UwPMnMeUxBQ';
    final res = await TokenSignatureVerifier.verifyAndDecode(oldV8Token);
    expect(res.valid, isFalse);
    expect(res.reason, 'schema_version');
  });

  // TODO(interop) : après déploiement du Worker mis à jour (sv:2), capturer
  // un NOUVEAU token signé par WebCrypto V8 (cf. README.md §4 « Vérifier
  // l'interop crypto ») et l'ajouter ici pour re-couvrir l'interop
  // Worker(V8) → client(Dart) sur le nouveau format compact.
}
