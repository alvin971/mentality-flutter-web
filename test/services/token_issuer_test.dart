// La FORME d'un token DEV : ce qui est décodable, et ce qui ne l'est pas.
//
// Ce fichier existe à cause d'un écart précis. `_hasValidShape` comparait la
// version de schéma par ÉGALITÉ STRICTE à `kTokenSchemaVersion`. Le jour où
// cette constante passe de 2 à 3 pour émettre le plan, cette égalité rejette
// d'un coup TOUS les passes `sv: 2` — ceux des téléphones en service comme
// ceux des six bancs d'essai qui s'appuient sur `tokenDeTest`. La règle est
// donc un ENSEMBLE de versions supportées, et c'est ce que ces tests
// verrouillent.
//
// Second enjeu : un `sv: 3` à moitié formé ne doit pas se décoder. Mieux vaut
// un token illisible (repli = écran de consentement in-app) qu'un plan cru sur
// parole.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/core/services/token_issuer.dart';

String _token(Map<String, dynamic> claims) =>
    'M2.${base64Url.encode(utf8.encode(jsonEncode(claims))).replaceAll('=', '')}';

Map<String, dynamic> _sv2([Map<String, dynamic> surcharge = const {}]) => {
      's': 'M',
      'y': 2005,
      'm': 4,
      'r': 'GES',
      'd': 20659,
      'n': 'testnonce',
      'sv': 2,
      ...surcharge,
    };

Map<String, dynamic> _sv3([Map<String, dynamic> surcharge = const {}]) => {
      ..._sv2(),
      'sv': 3,
      'p': 'free',
      'cc': true,
      'cv': '2026-09-02.v1',
      ...surcharge,
    };

void main() {
  group('versions de schéma supportées', () {
    test('l\'ensemble contient 2 ET 3 — jamais une égalité stricte', () {
      expect(kTokenSupportedSchemaVersions, containsAll(<int>[2, 3]));
      expect(kTokenSupportedSchemaVersions.contains(kTokenSchemaVersion), isTrue,
          reason: 'la version émise doit évidemment faire partie des lues');
    });

    test('RÉGRESSION — un passe sv 2 reste décodable après la bascule sv 3',
        () {
      final claims = TokenIssuer.tryDecode(_token(_sv2()));
      expect(claims, isNotNull,
          reason: 'ces passes vivent sur des téléphones réels : les rejeter '
              'reviendrait à éteindre l\'app pour leurs porteurs');
      expect(claims!['sv'], 2);
      expect(claims['y'], 2005);
    });

    test('un sv 4 (schéma d\'après-demain) est rejeté', () {
      expect(TokenIssuer.tryDecode(_token(_sv2({'sv': 4}))), isNull);
    });

    test('un sv absent ou de mauvais type est rejeté', () {
      final sansSv = _sv2()..remove('sv');
      expect(TokenIssuer.tryDecode(_token(sansSv)), isNull);
      expect(TokenIssuer.tryDecode(_token(_sv2({'sv': '2'}))), isNull);
    });
  });

  group('claims de plan (sv 3)', () {
    test('un sv 3 complet et bien formé est décodé avec son plan', () {
      final claims = TokenIssuer.tryDecode(_token(_sv3()));
      expect(claims, isNotNull);
      expect(claims!['p'], 'free');
      expect(claims['cc'], isTrue);
      expect(claims['cv'], '2026-09-02.v1');
    });

    test('p:paid est accepté (l\'autre valeur de l\'allow-list)', () {
      final claims =
          TokenIssuer.tryDecode(_token(_sv3({'p': 'paid', 'cc': false})));
      expect(claims, isNotNull);
      expect(claims!['p'], 'paid');
    });

    test('p hors allow-list (gold) → indécodable', () {
      expect(TokenIssuer.tryDecode(_token(_sv3({'p': 'gold'}))), isNull);
    });

    test('p absent sur un sv 3 → indécodable', () {
      final sansP = _sv3()..remove('p');
      expect(TokenIssuer.tryDecode(_token(sansP)), isNull);
    });

    test('cc non booléen → indécodable', () {
      expect(TokenIssuer.tryDecode(_token(_sv3({'cc': 'oui'}))), isNull);
      expect(TokenIssuer.tryDecode(_token(_sv3({'cc': 1}))), isNull);
    });

    test('cv absente ou vide → indécodable (preuve de version manquante)', () {
      expect(TokenIssuer.tryDecode(_token(_sv3({'cv': ''}))), isNull);
      final sansCv = _sv3()..remove('cv');
      expect(TokenIssuer.tryDecode(_token(sansCv)), isNull);
    });

    test('les claims de plan sur un sv 2 sont simplement ignorés', () {
      // Un tokeniseur qui émettrait des claims de plan SANS monter le schéma
      // ne doit pas casser le décodage : c'est `sv` qui commande la lecture.
      final claims =
          TokenIssuer.tryDecode(_token(_sv2({'p': 'gold', 'cc': 'oui'})));
      expect(claims, isNotNull);
      expect(claims!['sv'], 2);
    });
  });

  group('socle démographique (toutes versions)', () {
    test('sexe hors allow-list → indécodable', () {
      expect(TokenIssuer.tryDecode(_token(_sv3({'s': 'Z'}))), isNull);
    });

    test('mois hors 1-12 → indécodable', () {
      expect(TokenIssuer.tryDecode(_token(_sv3({'m': 0}))), isNull);
      expect(TokenIssuer.tryDecode(_token(_sv3({'m': 13}))), isNull);
    });

    test('région inconnue → indécodable', () {
      expect(TokenIssuer.tryDecode(_token(_sv3({'r': 'ZZZ'}))), isNull);
    });

    test('préfixe, nombre de segments et base64 : tout écart → null', () {
      expect(TokenIssuer.tryDecode('M3.${_token(_sv3()).split('.')[1]}'), isNull);
      expect(TokenIssuer.tryDecode('${_token(_sv3())}.sig'), isNull);
      expect(TokenIssuer.tryDecode('M2.!!!pas-du-base64!!!'), isNull);
      expect(TokenIssuer.tryDecode(''), isNull);
    });

    test('base64url avec ET sans bourrage : les deux formes se décodent', () {
      // La forme canonique (celle du Worker et des JWT) n'a pas de `=`. Sans
      // normalisation, elle serait refusée alors qu'elle est la seule émise.
      final brut = utf8.encode(jsonEncode(_sv2()));
      final avec = 'M2.${base64Url.encode(brut)}';
      final sans = 'M2.${base64Url.encode(brut).replaceAll('=', '')}';
      expect(TokenIssuer.tryDecode(avec), isNotNull);
      expect(TokenIssuer.tryDecode(sans), isNotNull);
    });

    test('racine JSON non-objet (tableau) → null', () {
      final arr = base64Url.encode(utf8.encode('[1,2,3]')).replaceAll('=', '');
      expect(TokenIssuer.tryDecode('M2.$arr'), isNull);
    });
  });
}
