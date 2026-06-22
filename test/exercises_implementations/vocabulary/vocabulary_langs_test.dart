import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/features/exercises_implementations/vocabulary/domain/vocabulary_generator.dart';

/// Vérifie que le générateur de Vocabulaire produit un test calibré pour
/// CHAQUE langue de contenu (fr, en, en-GB, es, pt, de), banques natives
/// comprises. La calibration (30 items, distribution par bande [5,7,8,7,3],
/// theta croissant par slot) doit être identique quelle que soit la langue.
void main() {
  const tags = ['fr', 'en', 'en-GB', 'es', 'pt', 'de'];
  const expectedPerBand = {
    WordFrequency.veryHigh: 5,
    WordFrequency.high: 7,
    WordFrequency.medium: 8,
    WordFrequency.low: 7,
    WordFrequency.veryLow: 3,
  };

  for (final tag in tags) {
    group('VocabularyGenerator [$tag]', () {
      final items =
          VocabularyGenerator(languageCode: tag, seed: 42).generateComplete30Items();

      test('produit exactement 30 items', () {
        expect(items.length, 30);
      });

      test('distribution par bande de fréquence = [5,7,8,7,3]', () {
        final counts = <WordFrequency, int>{};
        for (final it in items) {
          counts[it.frequency] = (counts[it.frequency] ?? 0) + 1;
        }
        expect(counts, expectedPerBand);
      });

      test('thetaValue non décroissant par slot', () {
        for (var i = 1; i < items.length; i++) {
          expect(items[i].thetaValue,
              greaterThanOrEqualTo(items[i - 1].thetaValue),
              reason: 'theta décroît au slot $i ($tag)');
        }
      });

      test('aucun mot dupliqué et réponses non vides', () {
        final words = items.map((e) => e.word.toLowerCase()).toList();
        expect(words.toSet().length, words.length, reason: 'doublon ($tag)');
        for (final it in items) {
          expect(it.twoPointAnswers, isNotEmpty);
          expect(it.onePointAnswers, isNotEmpty);
        }
      });
    });
  }
}
