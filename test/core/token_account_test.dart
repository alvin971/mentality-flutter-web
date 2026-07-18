// Vérifie que la dérivation d'identité de compte côté app est le MIROIR EXACT
// de celle du worker (workers/_shared/token_verify.js) : SHA256(nonce)[:32].
//
// Les comptes attendus ci-dessous sont des VALEURS DE RÉFÉRENCE calculées par
// une implémentation indépendante (Python hashlib) sur des tokens synthétiques.
// Si ce test casse, l'app et le serveur ne partitionnent plus les données de la
// même façon — c'est un bug de sécurité, pas un test à réajuster.

import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/core/services/token_account.dart';

// Fixtures synthétiques (aucun token réel), nonces 'AAA…' et 'BBB…'.
const _payloadA =
    'eyJzIjoiTSIsInkiOjE5OTAsIm0iOjMsInIiOiJJREYiLCJkIjoyMDAwMCwibiI6IkFBQUFBQUFBQUFBQUFBQUFBQUFBQUEiLCJzdiI6Mn0';
const _payloadB =
    'eyJzIjoiRiIsInkiOjE5ODUsIm0iOjcsInIiOiJBUkEiLCJkIjoyMDEwMCwibiI6IkJCQkJCQkJCQkJCQkJCQkJCQkJCQkIiLCJzdiI6Mn0';
const _header = 'eyJhbGciOiJFZERTQSIsImtpZCI6ImsxIn0';

const _tokenDevA = 'M2.$_payloadA';
const _tokenSignedA = '$_header.$_payloadA.SIGNATURE_FACTICE';
const _tokenDevB = 'M2.$_payloadB';

// Références indépendantes (Python : sha256(nonce).hexdigest()[:32]).
const _accountA = '8a5bdb4cc15164126c6ef2668de9dd24';
const _accountB = 'c69fb40feba930717e71f01707a9fccd';

void main() {
  group('TokenAccount — miroir de la dérivation serveur', () {
    test('token DEV non signé → compte de référence', () async {
      expect(await TokenAccount.fromToken(_tokenDevA), _accountA);
    });

    test('token signé → même compte que sa version DEV (même nonce)', () async {
      // La forme du token ne change pas l'identité : seul le nonce compte.
      expect(await TokenAccount.fromToken(_tokenSignedA), _accountA);
    });

    test('deux passes différents → deux comptes différents', () async {
      final a = await TokenAccount.fromToken(_tokenDevA);
      final b = await TokenAccount.fromToken(_tokenDevB);
      expect(b, _accountB);
      expect(a, isNot(b));
    });

    test('longueur = 32 caractères hex (miroir du slice(0,32))', () async {
      final a = await TokenAccount.fromToken(_tokenDevA);
      expect(a, hasLength(32));
      expect(RegExp(r'^[0-9a-f]{32}$').hasMatch(a!), isTrue);
    });

    group('entrées inexploitables → null (jamais d\'exception)', () {
      const cases = <String, String?>{
        'null': null,
        'vide': '',
        'sans point': 'pastoken',
        'préfixe inconnu': 'M1.$_payloadA',
        'payload non base64': 'M2.@@@nonbase64@@@',
        'payload non JSON': 'M2.YWJjZGVmZ2g',
        'trop de segments': 'a.b.c.d',
      };
      cases.forEach((name, token) {
        test(name, () async {
          expect(await TokenAccount.fromToken(token), isNull);
        });
      });

      test('claims sans nonce', () async {
        // {"s":"M","sv":2} — pas de champ n
        expect(await TokenAccount.fromToken('M2.eyJzIjoiTSIsInN2IjoyfQ'),
            isNull);
      });
    });
  });
}
