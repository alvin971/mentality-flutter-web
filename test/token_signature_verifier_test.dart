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

Map<String, dynamic> _validHeader() => {'alg': 'EdDSA', 'typ': 'JWT', 'kid': 'k1'};

Map<String, dynamic> _validPayload() => {
      'sex': 'M',
      'birth_year': 1998,
      'birth_month': 7,
      'region': 'IDF',
      'signup_day': '2026-06-13',
      'nonce': _b64url(List<int>.generate(32, (i) => i)),
      'sv': 1,
    };

void main() {
  test('accepte un token correctement signé et renvoie ses claims', () async {
    final token =
        await _makeToken(header: _validHeader(), payload: _validPayload());
    final res = await TokenSignatureVerifier.verifyAndDecode(token);
    expect(res.valid, isTrue, reason: res.reason);
    expect(res.claims!['sex'], 'M');
    expect(res.claims!['region'], 'IDF');
    expect(res.claims!['birth_year'], 1998);
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
      header: {'alg': 'none', 'typ': 'JWT', 'kid': 'k1'},
      payload: _validPayload(),
    );
    final res = await TokenSignatureVerifier.verifyAndDecode(token);
    expect(res.valid, isFalse);
    expect(res.reason, 'alg');
  });

  test('rejette un kid inconnu', () async {
    final token = await _makeToken(
      header: {'alg': 'EdDSA', 'typ': 'JWT', 'kid': 'k999'},
      payload: _validPayload(),
    );
    final res = await TokenSignatureVerifier.verifyAndDecode(token);
    expect(res.valid, isFalse);
    expect(res.reason, 'kid_unknown');
  });

  test('rejette un kid de mauvais type (int)', () async {
    final token = await _makeToken(
      header: {'alg': 'EdDSA', 'typ': 'JWT', 'kid': 42},
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
    final res = await TokenSignatureVerifier.verifyAndDecode('MENTA1.abc');
    expect(res.valid, isFalse);
  });

  test('rejette du charabia', () async {
    expect((await TokenSignatureVerifier.verifyAndDecode('')).valid, isFalse);
    expect((await TokenSignatureVerifier.verifyAndDecode('x')).valid, isFalse);
    expect(
        (await TokenSignatureVerifier.verifyAndDecode('a.b.c.d')).valid, isFalse);
  });

  // INTEROP V8 → Dart : ce token a été signé par WebCrypto (Node/workerd, même
  // moteur que les Cloudflare Workers) avec la clé privée DEV, via
  // workers/_shared/token_verify.js. Qu'il vérifie ici prouve que le Worker
  // tokeniseur (V8) et le vérifieur client (Dart) sont interopérables.
  test('accepte un token signé par WebCrypto V8 (interop Worker→Dart)', () async {
    const v8Token =
        'eyJhbGciOiJFZERTQSIsInR5cCI6IkpXVCIsImtpZCI6ImsxIn0'
        '.eyJzZXgiOiJGIiwiYmlydGhfeWVhciI6MTk5MCwiYmlydGhfbW9udGgiOjMsInJlZ2lvbiI6Ik9DQyIsInNpZ251cF9kYXkiOiIyMDI2LTA2LTEzIiwibm9uY2UiOiJFNWxoWXJhV0ZqU3RyREc1ejRKcWVnSVhJWE9rdGpZdFpvYmhmNDNXOTBzIiwic3YiOjF9'
        '.Mp00iw5CRtvXjsgc-QUV58J__pXxae4AhtvvupGJzLRyxltX5ERflJKRxOy6V7JmxGJ3v5tj7J5UwPMnMeUxBQ';
    final res = await TokenSignatureVerifier.verifyAndDecode(v8Token);
    expect(res.valid, isTrue, reason: res.reason);
    expect(res.claims!['region'], 'OCC');
    expect(res.claims!['nonce'], isNotEmpty);
  });
}
