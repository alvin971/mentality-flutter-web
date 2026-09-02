import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/core/services/token_claims_reader.dart';
import 'package:mentality/core/services/token_plan.dart';
import 'package:mentality/core/services/token_signature_verifier.dart';

/// Encode un segment base64url SANS padding, comme un vrai JWT / token signé.
String _seg(Map<String, dynamic> m) =>
    base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');

/// Fabrique un token à 3 segments `header.payload.signature`. La signature est
/// volontairement bidon : on vérifie justement que l'âge reste lisible même
/// quand la signature ne se vérifie pas côté client.
String _fakeSignedToken(Map<String, dynamic> payload) {
  final header = _seg({'alg': 'EdDSA', 'kid': 'k-inconnu'});
  final body = _seg(payload);
  const bogusSig = 'c2lnbmF0dXJlLWJpZG9u'; // "signature-bidon" en base64
  return '$header.$body.$bogusSig';
}

/// Seed raw 32 octets du keypair DEV (cf. test/token_signature_verifier_test.dart).
const String _devSeedB64 = 'qV13eS2BZTNM/yqlNhByezXrk5cYFtvdOO/8TzNI7to=';

/// Clé publique correspondante, injectée via `debugKeysOverride`.
const String _devPubB64url = '-2eBilftJKpyg_NHaQpXDBwuVFMA2z3JaZgXpDF_rCw';

/// Token RÉELLEMENT signé avec la clé DEV : le seul chemin par lequel un plan
/// a le droit d'être cru en production.
Future<String> _signedToken(Map<String, dynamic> payload) async {
  final header = _seg({'alg': 'EdDSA', 'kid': 'k1'});
  final body = _seg(payload);
  final kp = await Ed25519().newKeyPairFromSeed(base64.decode(_devSeedB64));
  final sig = await Ed25519().sign(utf8.encode('$header.$body'), keyPair: kp);
  return '$header.$body.${base64Url.encode(sig.bytes).replaceAll('=', '')}';
}

/// Token DEV `M2.` non signé (accepté en debug uniquement).
String _devToken(Map<String, dynamic> claims) => 'M2.${_seg(claims)}';

/// Claims sv 3 bien formés, modifiables par [surcharge].
Map<String, dynamic> _claimsPlan(Map<String, dynamic> surcharge) => {
      's': 'M',
      'y': 1998,
      'm': 7,
      'r': 'IDF',
      'd': 20613,
      'n': 'nonce16octets',
      'sv': 3,
      'p': 'free',
      'cc': true,
      'cv': '2026-09-02.v1',
      ...surcharge,
    };

void main() {
  group('TokenClaimsReader.ageInMonthsFrom', () {
    test('âge au mois près : anniversaire déjà passé dans l\'année', () {
      // Né en janvier 1990, on est en juillet 2026 → 36 ans + 6 mois = 438 mois.
      final age = TokenClaimsReader.ageInMonthsFrom(1990, 1, DateTime(2026, 7));
      expect(age, 36 * 12 + 6);
    });

    test('âge au mois près : mois de naissance postérieur au mois courant', () {
      // Né en décembre 2000, on est en juillet 2026 → 25 ans + 7 mois = 307 mois.
      final age = TokenClaimsReader.ageInMonthsFrom(2000, 12, DateTime(2026, 7));
      expect(age, (2026 - 2000) * 12 + (7 - 12));
      expect(age, 307);
    });

    test('même année et même mois → 0 mois', () {
      expect(TokenClaimsReader.ageInMonthsFrom(2026, 7, DateTime(2026, 7)), 0);
    });

    test('date de naissance dans le futur → null (incohérent)', () {
      expect(TokenClaimsReader.ageInMonthsFrom(2030, 1, DateTime(2026, 7)), isNull);
    });

    test('correspond à la plage acceptée du test complet (16–90 ans)', () {
      final at16 = TokenClaimsReader.ageInMonthsFrom(2010, 7, DateTime(2026, 7));
      expect(at16, 16 * 12);
      final at90 = TokenClaimsReader.ageInMonthsFrom(1936, 7, DateTime(2026, 7));
      expect(at90, 90 * 12);
    });
  });

  group('TokenClaimsReader.payloadClaimsUnverified', () {
    test(
        'token signé (3 segments) à signature NON vérifiable → l\'âge (y, m) '
        'reste lisible : plus de saisie manuelle par simple décalage de clé', () {
      final token = _fakeSignedToken({
        's': 'F',
        'y': 1990,
        'm': 3,
        'r': 'FR',
        'd': 20000,
        'n': 'nonce',
        'sv': 2,
      });

      final claims = TokenClaimsReader.payloadClaimsUnverified(token);
      expect(claims, isNotNull);
      expect(claims!['y'], 1990);
      expect(claims['m'], 3);

      // Et l'âge se dérive correctement depuis ces claims.
      final age = TokenClaimsReader.ageInMonthsFrom(
          claims['y'] as int, claims['m'] as int, DateTime(2026, 7));
      expect(age, (2026 - 1990) * 12 + (7 - 3));
    });

    test('payload base64url SANS padding → décodé quand même (normalisation)',
        () {
      // {"y":2001,"m":11} encodé sans '=' final.
      final token = _fakeSignedToken({'y': 2001, 'm': 11});
      final claims = TokenClaimsReader.payloadClaimsUnverified(token);
      expect(claims, isNotNull);
      expect(claims!['y'], 2001);
      expect(claims['m'], 11);
    });

    test('token à 2 segments (M2 non signé) → null (géré par l\'autre chemin)',
        () {
      final body = _seg({'y': 1995, 'm': 5});
      expect(TokenClaimsReader.payloadClaimsUnverified('M2.$body'), isNull);
    });

    test('payload illisible (base64/JSON invalide) → null', () {
      expect(
          TokenClaimsReader.payloadClaimsUnverified('aaa.!!!not-base64!!!.bbb'),
          isNull);
    });

    test('payload JSON non-objet (tableau) → null', () {
      final arr = base64Url.encode(utf8.encode('[1,2,3]')).replaceAll('=', '');
      expect(TokenClaimsReader.payloadClaimsUnverified('h.$arr.s'), isNull);
    });
  });

  // ─── Le PLAN porté par le token (sv 3) ─────────────────────────────────────

  group('TokenClaimsReader.planFromVerifiedClaims', () {
    test('sv 2 → unknown : ces passes ne portent aucun plan', () {
      final info = TokenClaimsReader.planFromVerifiedClaims({
        's': 'M',
        'y': 1998,
        'm': 7,
        'r': 'IDF',
        'd': 20613,
        'n': 'nonce',
        'sv': 2,
      });
      expect(info.plan, TokenPlan.unknown);
      expect(info.corpusConsent, isFalse);
      expect(info.legalVersion, isNull);
    });

    test('sv 3 free + cc true → Gratuit AVEC cession au corpus', () {
      final info =
          TokenClaimsReader.planFromVerifiedClaims(_claimsPlan({'cc': true}));
      expect(info.plan, TokenPlan.free);
      expect(info.corpusConsent, isTrue);
      expect(info.legalVersion, '2026-09-02.v1');
      expect(info.issuedDay, 20613);
      expect(info.allowsOralStep, isTrue);
    });

    test('sv 3 free + cc false → Gratuit SANS cession (case facultative)', () {
      final info =
          TokenClaimsReader.planFromVerifiedClaims(_claimsPlan({'cc': false}));
      expect(info.plan, TokenPlan.free);
      expect(info.corpusConsent, isFalse,
          reason: 'tant que le passe Payant n\'est pas en vente, la case du '
              'corpus est facultative : le passe Gratuit est émis sans elle');
      expect(info.allowsOralStep, isTrue);
    });

    test('sv 3 paid → Payant, et cc:true ne ressuscite PAS la cession', () {
      final info = TokenClaimsReader.planFromVerifiedClaims(
          _claimsPlan({'p': 'paid', 'cc': true}));
      expect(info.plan, TokenPlan.paid);
      expect(info.corpusConsent, isFalse,
          reason: 'un passe Payant n\'enregistre rien : il n\'y a rien à '
              'céder, quoi que dise le claim');
      expect(info.allowsOralStep, isFalse);
    });

    test('plan hors allow-list (p: gold) → unknown', () {
      final info =
          TokenClaimsReader.planFromVerifiedClaims(_claimsPlan({'p': 'gold'}));
      expect(info.plan, TokenPlan.unknown);
    });

    test('cc non booléen, cv vide ou absente → unknown (forme non fiable)', () {
      expect(
          TokenClaimsReader.planFromVerifiedClaims(_claimsPlan({'cc': 'oui'}))
              .plan,
          TokenPlan.unknown);
      expect(
          TokenClaimsReader.planFromVerifiedClaims(_claimsPlan({'cv': ''})).plan,
          TokenPlan.unknown);
      final sansCv = _claimsPlan({})..remove('cv');
      expect(TokenClaimsReader.planFromVerifiedClaims(sansCv).plan,
          TokenPlan.unknown);
    });
  });

  group('TokenClaimsReader.planFromToken', () {
    setUpAll(() {
      TokenSignatureVerifier.debugKeysOverride = {'k1': _devPubB64url};
    });
    tearDownAll(() {
      TokenSignatureVerifier.debugKeysOverride = null;
    });

    test(
        'SÉCURITÉ — un token à SIGNATURE BIDON annonçant p:paid → unknown, '
        'jamais cru', () async {
      // Le payload NON vérifié sert à lire un ÂGE : le falsifier ne fausse que
      // son propre score. Il ne doit JAMAIS servir à lire un plan — `p:"paid"`
      // supprimerait l'enregistrement vocal qui finance le passe Gratuit.
      final header = _seg({'alg': 'EdDSA', 'kid': 'k1'});
      final body = _seg(_claimsPlan({'p': 'paid', 'cc': false}));
      const bogus = 'c2lnbmF0dXJlLWJpZG9u';
      final token = '$header.$body.$bogus';

      expect((await TokenClaimsReader.planFromToken(token)).plan,
          TokenPlan.unknown);

      // Et le payload EST pourtant parfaitement lisible : le refus vient de la
      // règle, pas d'un décodage impossible.
      expect(TokenClaimsReader.payloadClaimsUnverified(token)?['p'], 'paid');
    });

    test(
        'SÉCURITÉ — un cc:true à signature bidon ne fabrique aucun consentement',
        () async {
      final header = _seg({'alg': 'EdDSA', 'kid': 'k1'});
      final body = _seg(_claimsPlan({'p': 'free', 'cc': true}));
      const bogus = 'c2lnbmF0dXJlLWJpZG9u';
      final info =
          await TokenClaimsReader.planFromToken('$header.$body.$bogus');
      expect(info.plan, TokenPlan.unknown);
      expect(info.corpusConsent, isFalse);
    });

    test('token RÉELLEMENT signé sv 3 free → Gratuit', () async {
      final token = await _signedToken(_claimsPlan({'cc': true}));
      final info = await TokenClaimsReader.planFromToken(token);
      expect(info.plan, TokenPlan.free);
      expect(info.corpusConsent, isTrue);
      expect(info.legalVersion, '2026-09-02.v1');
    });

    test('token DEV M2. sv 3 paid → Payant (debug uniquement)', () async {
      final info = await TokenClaimsReader.planFromToken(
          _devToken(_claimsPlan({'p': 'paid', 'cc': false})));
      expect(info.plan, TokenPlan.paid);
    });

    test('token DEV M2. sv 3 mal formé (p: gold) → unknown', () async {
      final info = await TokenClaimsReader.planFromToken(
          _devToken(_claimsPlan({'p': 'gold'})));
      expect(info.plan, TokenPlan.unknown);
    });

    test('token DEV M2. sv 2 → unknown (repli sur l\'écran in-app)', () async {
      final info = await TokenClaimsReader.planFromToken(_devToken({
        's': 'M',
        'y': 2005,
        'm': 4,
        'r': 'GES',
        'd': 20659,
        'n': 'testnonce',
        'sv': 2,
      }));
      expect(info.plan, TokenPlan.unknown);
    });

    test('charabia → unknown, sans exception', () async {
      expect(
          (await TokenClaimsReader.planFromToken('')).plan, TokenPlan.unknown);
      expect((await TokenClaimsReader.planFromToken('a.b.c.d')).plan,
          TokenPlan.unknown);
    });
  });
}
