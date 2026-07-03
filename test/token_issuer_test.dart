// Tests du chemin DEV/fallback de TokenIssuer (Worker non configuré dans
// l'environnement de test → isConfigured == false, cf. TokeniserService).
//
// Couvre : format compact (sv: 2), validation stricte des claims avant
// émission (miroir des allow-lists du Worker), et décodage strict.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/core/services/token_issuer.dart';
import 'package:mentality/services/tokeniser_service.dart';

TokenDemographics _validDemo() => const TokenDemographics(
      sexCode: 'F',
      birthYear: 1998,
      birthMonth: 7,
      regionCode: 'IDF',
    );

void main() {
  // Ces tests valident le FALLBACK DEV local (token M2. non signé) : on force
  // le chemin « Worker non configuré » pour ne jamais appeler le réseau.
  setUpAll(() => TokeniserService.debugForceUnconfigured = true);
  tearDownAll(() => TokeniserService.debugForceUnconfigured = false);

  test('issue() produit un token préfixé M2 avec des claims compactes',
      () async {
    final now = DateTime.utc(2026, 7, 1);
    final token = await TokenIssuer.issue(_validDemo(), now: now);

    expect(token, startsWith('M2.'));

    final claims = TokenIssuer.tryDecode(token);
    expect(claims, isNotNull);
    expect(claims!['s'], 'F');
    expect(claims['y'], 1998);
    expect(claims['m'], 7);
    expect(claims['r'], 'IDF');
    expect(claims['sv'], kTokenSchemaVersion);
    expect(claims['n'], isA<String>());
    expect((claims['n'] as String).isNotEmpty, isTrue);
    // Pas de champ status : la complétion vit côté serveur, pas dans le token.
    expect(claims.containsKey('status'), isFalse);
    expect(claims.containsKey('st'), isFalse);
  });

  test('issue() encode signup_day en jours depuis epoch (pas une chaîne date)',
      () async {
    final now = DateTime.utc(2026, 7, 1);
    final token = await TokenIssuer.issue(_validDemo(), now: now);
    final claims = TokenIssuer.tryDecode(token)!;
    final expectedDays =
        DateTime.utc(2026, 7, 1).difference(DateTime.utc(1970)).inDays;
    expect(claims['d'], expectedDays);
  });

  test('issue() est plus court que l\'ancien format verbeux équivalent',
      () async {
    final now = DateTime.utc(2026, 7, 1);
    final token = await TokenIssuer.issue(_validDemo(), now: now);

    // Ancien format (sv:1) pour comparaison de taille : clés verbeuses,
    // status, nonce 256 bits.
    final legacyClaims = {
      'sex': 'F',
      'birth_year': 1998,
      'birth_month': 7,
      'region': 'IDF',
      'signup_day': '2026-07-01',
      'status': 'provisional',
      'sv': 1,
    };
    final legacyToken = 'MENTA1.'
        '${base64Url.encode(utf8.encode(jsonEncode(legacyClaims)))}';

    expect(token.length, lessThan(legacyToken.length));
  });

  test('rejette un sexCode hors allow-list', () async {
    const demo = TokenDemographics(
      sexCode: 'Z',
      birthYear: 1998,
      birthMonth: 7,
      regionCode: 'IDF',
    );
    expect(
      () => TokenIssuer.issue(demo, now: DateTime.utc(2026, 7, 1)),
      throwsArgumentError,
    );
  });

  test('rejette un regionCode inconnu', () async {
    const demo = TokenDemographics(
      sexCode: 'F',
      birthYear: 1998,
      birthMonth: 7,
      regionCode: 'ZZZ',
    );
    expect(
      () => TokenIssuer.issue(demo, now: DateTime.utc(2026, 7, 1)),
      throwsArgumentError,
    );
  });

  test('rejette un birthMonth hors 1-12', () async {
    const demo = TokenDemographics(
      sexCode: 'F',
      birthYear: 1998,
      birthMonth: 13,
      regionCode: 'IDF',
    );
    expect(
      () => TokenIssuer.issue(demo, now: DateTime.utc(2026, 7, 1)),
      throwsArgumentError,
    );
  });

  test('rejette un birthYear implausible (trop récent)', () async {
    final now = DateTime.utc(2026, 7, 1);
    const demo = TokenDemographics(
      sexCode: 'F',
      birthYear: 2024, // < nowYear - 5 requis
      birthMonth: 7,
      regionCode: 'IDF',
    );
    expect(() => TokenIssuer.issue(demo, now: now), throwsArgumentError);
  });

  test('rejette un birthYear implausible (trop ancien)', () async {
    final now = DateTime.utc(2026, 7, 1);
    const demo = TokenDemographics(
      sexCode: 'F',
      birthYear: 1900, // < nowYear - 100
      birthMonth: 7,
      regionCode: 'IDF',
    );
    expect(() => TokenIssuer.issue(demo, now: now), throwsArgumentError);
  });

  group('tryDecode', () {
    test('refuse un préfixe inconnu', () {
      expect(TokenIssuer.tryDecode('MENTA1.abc'), isNull);
    });

    test('refuse un JSON valide mais de forme incomplète', () {
      final payload =
          base64Url.encode(utf8.encode(jsonEncode({'s': 'F', 'sv': 2})));
      expect(TokenIssuer.tryDecode('M2.$payload'), isNull);
    });

    test('refuse une version de schéma non supportée', () {
      final payload = base64Url.encode(utf8.encode(jsonEncode({
        's': 'F',
        'y': 1998,
        'm': 7,
        'r': 'IDF',
        'd': 20635,
        'n': 'abc',
        'sv': 1,
      })));
      expect(TokenIssuer.tryDecode('M2.$payload'), isNull);
    });

    test('refuse du charabia non-JSON', () {
      expect(TokenIssuer.tryDecode('M2.not-valid-base64!!'), isNull);
    });
  });
}
