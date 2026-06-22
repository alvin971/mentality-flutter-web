import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/features/exercises_implementations/arithmetic/domain/arithmetic_generator.dart';

/// Vérifie la calibration du générateur d'Arithmétique pour CHAQUE langue de
/// contenu (fr, en, en-GB, es, pt, de) : 22 problèmes, distribution par bande
/// [4,8,6,4], énoncés natifs SANS token résiduel ({a}, {b}…), theta croissant.
/// La réponse est calculée par code → toujours un entier valide.
void main() {
  const tags = ['fr', 'en', 'en-GB', 'es', 'pt', 'de'];
  const expectedPerBand = {
    DifficultyLevel.easy: 4,
    DifficultyLevel.medium: 8,
    DifficultyLevel.hard: 6,
    DifficultyLevel.veryHard: 4,
  };
  final tokenLeak = RegExp(r'\{(a|b|c|dividend|divisor|percent|whole)\}');

  for (final tag in tags) {
    group('ArithmeticGenerator [$tag]', () {
      final items =
          ArithmeticGenerator(languageCode: tag, seed: 99).generateComplete22Items();

      test('produit exactement 22 problèmes', () => expect(items.length, 22));

      test('distribution par bande = [4,8,6,4]', () {
        final counts = <DifficultyLevel, int>{};
        for (final it in items) {
          counts[it.difficulty] = (counts[it.difficulty] ?? 0) + 1;
        }
        expect(counts, expectedPerBand);
      });

      test('aucun token non substitué dans l\'énoncé', () {
        for (final it in items) {
          expect(it.problem.trim(), isNotEmpty);
          expect(tokenLeak.hasMatch(it.problem), isFalse,
              reason: 'token résiduel dans "${it.problem}" ($tag)');
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
