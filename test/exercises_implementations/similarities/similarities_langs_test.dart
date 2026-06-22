import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/features/exercises_implementations/similarities/domain/similarities_generator.dart';

/// Vérifie la calibration du générateur de Similitudes pour CHAQUE langue de
/// contenu (fr, en, en-GB, es, pt, de) : 21 items, distribution par niveau
/// [4,6,6,5], theta croissant par slot, aucune paire dupliquée.
void main() {
  const tags = ['fr', 'en', 'en-GB', 'es', 'pt', 'de'];
  const expectedPerLevel = {
    AbstractionLevel.concrete: 4,
    AbstractionLevel.functional: 6,
    AbstractionLevel.categorical: 6,
    AbstractionLevel.abstract: 5,
  };

  for (final tag in tags) {
    group('SimilaritiesGenerator [$tag]', () {
      final items =
          SimilaritiesGenerator(languageCode: tag, seed: 7).generateComplete21Items();

      test('produit exactement 21 items', () => expect(items.length, 21));

      test('distribution par niveau = [4,6,6,5]', () {
        final counts = <AbstractionLevel, int>{};
        for (final it in items) {
          counts[it.level] = (counts[it.level] ?? 0) + 1;
        }
        expect(counts, expectedPerLevel);
      });

      test('thetaValue non décroissant par slot', () {
        for (var i = 1; i < items.length; i++) {
          expect(items[i].thetaValue,
              greaterThanOrEqualTo(items[i - 1].thetaValue));
        }
      });

      test('aucune paire dupliquée et réponses non vides', () {
        final pairs = items
            .map((e) => ([e.word1.toLowerCase(), e.word2.toLowerCase()]..sort())
                .join('|'))
            .toList();
        expect(pairs.toSet().length, pairs.length, reason: 'doublon ($tag)');
        for (final it in items) {
          expect(it.twoPointAnswers, isNotEmpty);
          expect(it.onePointAnswers, isNotEmpty);
        }
      });
    });
  }
}
