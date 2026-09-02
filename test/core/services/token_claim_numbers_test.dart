// UN PASSE VALIDE POUR LE WORKER DOIT L'ÊTRE POUR L'APPLICATION.
//
// Le tokeniser est écrit en JavaScript, où `3` et `3.0` sont la MÊME valeur :
// `Number.isInteger(3.0)` répond `true`, et un payload sérialisé `{"sv":3.0}`
// est un passe sv 3 parfaitement régulier pour `token_verify.js` comme pour
// `token_plan.js`. Dart, lui, distingue : `jsonDecode` en fait un `double`,
// que les anciens tests `sv is! int` rejetaient.
//
// La conséquence n'était pas théorique : le MÊME passe aurait été accepté par
// le worker et déclaré « schéma inconnu » par l'application — micro refusé,
// plan illisible, repli sur un écran de consentement, sans qu'aucun des deux
// bords ne soit en tort ni ne puisse le diagnostiquer.
//
// Ce fichier verrouille la tolérance des deux côtés — et sa LIMITE : accepter
// 3.0 ne doit pas revenir à accepter 3.5.

import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/core/services/token_claim_numbers.dart';
import 'package:mentality/core/services/token_claims_reader.dart';
import 'package:mentality/core/services/token_issuer.dart';
import 'package:mentality/core/services/token_plan.dart';
import 'package:mentality/core/services/token_signature_verifier.dart';

/// Seed raw 32 octets du keypair DEV (tests uniquement), et sa clé publique.
/// Mêmes valeurs que test/token_signature_verifier_test.dart.
const String _devSeedB64 = 'qV13eS2BZTNM/yqlNhByezXrk5cYFtvdOO/8TzNI7to=';
const String _devPubB64url = '-2eBilftJKpyg_NHaQpXDBwuVFMA2z3JaZgXpDF_rCw';

String _b64url(List<int> bytes) => base64Url.encode(bytes).replaceAll('=', '');

Future<String> _tokenSigne(Map<String, dynamic> payload) async {
  final header = _b64url(utf8.encode(jsonEncode({'alg': 'EdDSA', 'kid': 'k1'})));
  final corps = _b64url(utf8.encode(jsonEncode(payload)));
  final kp = await Ed25519().newKeyPairFromSeed(base64.decode(_devSeedB64));
  final sig =
      await Ed25519().sign(utf8.encode('$header.$corps'), keyPair: kp);
  return '$header.$corps.${_b64url(sig.bytes)}';
}

/// Claims sv 3 complètes, avec les nombres au type demandé.
Map<String, dynamic> _claims({required Object sv, Object? y, Object? d}) => {
      's': 'M',
      'y': y ?? 1998,
      'm': 7,
      'r': 'IDF',
      'd': d ?? 20613,
      'n': 'testnonce',
      'sv': sv,
      'p': 'free',
      'cc': true,
      'cv': '2026-09-02.v1',
    };

/// Token DEV `M2.<claims>` tel que TokenIssuer sait en décoder.
String _tokenDev(Map<String, dynamic> claims) =>
    '${TokenIssuer.prefix}.${_b64url(utf8.encode(jsonEncode(claims)))}';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('claimEntier — la règle de Number.isInteger, sans un pas de plus', () {
    test('accepte un entier et un double à valeur entière', () {
      expect(claimEntier(3), 3);
      expect(claimEntier(3.0), 3);
      expect(claimEntier(-1.0), -1);
      expect(claimEntier(0.0), 0);
    });

    test('refuse tout ce que le bord JS refuse aussi', () {
      expect(claimEntier(3.5), isNull);
      expect(claimEntier('3'), isNull,
          reason: 'une chaîne n\'est pas un nombre en JS non plus');
      expect(claimEntier(null), isNull);
      expect(claimEntier(double.nan), isNull);
      expect(claimEntier(double.infinity), isNull,
          reason: 'l\'infini est égal à sa propre troncature : sans le '
              'contrôle de finitude il passerait pour un entier');
      expect(claimEntier(double.negativeInfinity), isNull);
      expect(claimEntier(true), isNull);
    });
  });

  test('jsonDecode rend bien un double pour 3.0 — la prémisse du bug', () {
    final decode = jsonDecode('{"sv":3.0}') as Map<String, dynamic>;
    // Sur la VM c'est un double ; sur dart2js les entiers SONT des doubles.
    // Dans les deux cas, claimEntier doit répondre 3.
    expect(claimEntier(decode['sv']), 3);
  });

  group('sv: 3.0 traverse toute la chaîne de lecture', () {
    test('planFromVerifiedClaims lit un plan, pas « inconnu »', () {
      final info = TokenClaimsReader.planFromVerifiedClaims(
          jsonDecode(jsonEncode(_claims(sv: 3.0))) as Map<String, dynamic>);

      expect(info.plan, TokenPlan.free,
          reason: 'le worker aurait lu p:free sur ce même passe ; l\'app le '
              'déclarait « pas de plan » et retombait sur l\'écran in-app');
      expect(info.corpusConsent, isTrue);
      expect(info.legalVersion, '2026-09-02.v1');
    });

    test('un `d` sérialisé 20613.0 date quand même la preuve', () {
      final info = TokenClaimsReader.planFromVerifiedClaims(
          jsonDecode(jsonEncode(_claims(sv: 3.0, d: 20613.0)))
              as Map<String, dynamic>);

      expect(info.issuedDay, 20613,
          reason: 'sans cela le consentement se serait daté du 1er janvier '
              '1970 — une preuve fausse au sens de l\'art. 7');
    });

    test('TokenIssuer.tryDecode accepte le token DEV', () {
      final claims = TokenIssuer.tryDecode(_tokenDev(_claims(sv: 3.0)));
      expect(claims, isNotNull,
          reason: 'la forme stricte ne doit pas se briser sur la seule '
              'sérialisation du nombre');
      expect(claimEntier(claims!['sv']), 3);
    });

    test('TokenIssuer.tryDecode accepte aussi y/m/d sérialisés en décimal', () {
      final claims =
          TokenIssuer.tryDecode(_tokenDev(_claims(sv: 3.0, y: 1998.0, d: 20613.0)));
      expect(claims, isNotNull);
    });

    test('la vérification de signature ne rejette plus le schéma', () async {
      TokenSignatureVerifier.debugKeysOverride = {'k1': _devPubB64url};
      addTearDown(() => TokenSignatureVerifier.debugKeysOverride = null);

      final res = await TokenSignatureVerifier.verifyAndDecode(
          await _tokenSigne(_claims(sv: 3.0)));

      expect(res.valid, isTrue,
          reason: 'échec « ${res.reason} » : un passe RÉELLEMENT signé par le '
              'worker était refusé pour cause de schéma inconnu');
    });
  });

  group('la tolérance a une limite', () {
    test('sv: 3.5 reste un schéma inconnu', () async {
      TokenSignatureVerifier.debugKeysOverride = {'k1': _devPubB64url};
      addTearDown(() => TokenSignatureVerifier.debugKeysOverride = null);

      final res = await TokenSignatureVerifier.verifyAndDecode(
          await _tokenSigne(_claims(sv: 3.5)));

      expect(res.valid, isFalse);
      expect(res.reason, 'schema_version');
      expect(TokenIssuer.tryDecode(_tokenDev(_claims(sv: 3.5))), isNull);
      expect(
        TokenClaimsReader.planFromVerifiedClaims(
            jsonDecode(jsonEncode(_claims(sv: 3.5))) as Map<String, dynamic>),
        TokenPlanInfo.unknown,
      );
    });

    test('sv en chaîne « 3 » reste refusé', () {
      expect(TokenIssuer.tryDecode(_tokenDev(_claims(sv: '3'))), isNull);
      expect(
        TokenClaimsReader.planFromVerifiedClaims(
            jsonDecode(jsonEncode(_claims(sv: '3'))) as Map<String, dynamic>),
        TokenPlanInfo.unknown,
      );
    });
  });
}
