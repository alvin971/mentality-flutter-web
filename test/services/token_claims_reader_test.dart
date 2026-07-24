import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/core/services/token_claims_reader.dart';

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
}
