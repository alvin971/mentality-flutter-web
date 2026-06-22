import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/features/exercises_implementations/information/domain/information_generator.dart';

/// Vérifie la calibration du générateur d'Information pour CHAQUE langue de
/// contenu (fr, en, en-GB, es, pt, de) : 28 QCM, distribution de difficulté
/// [9 easy, 11 medium, 8 hard], 4 options par item, index correct valide
/// (après mélange des options), theta croissant par slot.
void main() {
  const tags = ['fr', 'en', 'en-GB', 'es', 'pt', 'de'];
  const expectedPerDifficulty = {
    DifficultyLevel.easy: 9,
    DifficultyLevel.medium: 11,
    DifficultyLevel.hard: 8,
  };

  for (final tag in tags) {
    group('InformationGenerator [$tag]', () {
      final items =
          InformationGenerator(languageCode: tag, seed: 11).generateComplete28Items();

      test('produit exactement 28 items', () => expect(items.length, 28));

      test('distribution de difficulté = [9,11,8]', () {
        final counts = <DifficultyLevel, int>{};
        for (final it in items) {
          counts[it.difficulty] = (counts[it.difficulty] ?? 0) + 1;
        }
        expect(counts, expectedPerDifficulty);
      });

      test('4 options distinctes et index correct valide', () {
        for (final it in items) {
          expect(it.options.length, 4);
          expect(it.options.toSet().length, 4, reason: 'option dupliquée ($tag)');
          expect(it.correctAnswer, inInclusiveRange(0, 3));
          expect(it.options[it.correctAnswer].trim(), isNotEmpty);
        }
      });

      test('thetaValue non décroissant par slot', () {
        for (var i = 1; i < items.length; i++) {
          expect(items[i].thetaValue,
              greaterThanOrEqualTo(items[i - 1].thetaValue));
        }
      });
    });
  }
}
