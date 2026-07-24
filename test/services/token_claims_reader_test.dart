import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/core/services/token_claims_reader.dart';

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
}
