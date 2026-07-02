import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/features/exercises_implementations/arithmetic/domain/arithmetic_generator.dart';

void main() {
  group('ArithmeticGenerator — structure conservée', () {
    test('génère exactement 22 items', () {
      expect(ArithmeticGenerator(seed: 1).generateComplete22Items().length, 22);
    });

    test('répartition 4/8/6/4 par difficulté, dans l\'ordre', () {
      for (var seed = 0; seed < 20; seed++) {
        final items = ArithmeticGenerator(seed: seed).generateComplete22Items();
        expect(
          items.map((i) => i.difficulty).toList(),
          [
            ...List.filled(4, DifficultyLevel.easy),
            ...List.filled(8, DifficultyLevel.medium),
            ...List.filled(6, DifficultyLevel.hard),
            ...List.filled(4, DifficultyLevel.veryHard),
          ],
          reason: 'seed $seed',
        );
      }
    });

    test('theta croissant de -2.0 par pas de 0.2', () {
      final items = ArithmeticGenerator(seed: 3).generateComplete22Items();
      for (var i = 0; i < items.length; i++) {
        expect(items[i].thetaValue, closeTo(-2.0 + 0.2 * i, 0.001));
      }
    });

    test('limites de temps croissantes par bande (15/25/40/50)', () {
      final items = ArithmeticGenerator(seed: 5).generateComplete22Items();
      expect(items[0].timeLimitSeconds, 15);
      expect(items[4].timeLimitSeconds, 25);
      expect(items[12].timeLimitSeconds, 40);
      expect(items[18].timeLimitSeconds, 50);
    });
  });

  group('ArithmeticGenerator — calcul & intégrité', () {
    test('réponses positives, tokens tous remplis (50 seeds)', () {
      for (var seed = 0; seed < 50; seed++) {
        for (final i in ArithmeticGenerator(seed: seed).generateComplete22Items()) {
          expect(i.problem.contains('{'), isFalse, reason: 'token non rempli: ${i.problem}');
          expect(i.problem.contains('}'), isFalse, reason: 'token non rempli: ${i.problem}');
          expect(i.problem.trim(), isNotEmpty);
          expect(i.correctAnswer, greaterThan(0),
              reason: 'réponse non positive (${i.correctAnswer}): ${i.problem}');
          expect(i.correctAnswer, lessThanOrEqualTo(1000));
        }
      }
    });

    test('calculateScore : bonne réponse = 1, PAS de bonus de rapidité, 0 si faux', () {
      // Refonte notation (étapes A-C) : la vitesse n'est plus créditée en
      // Arithmétique (elle ne l'est qu'en Coding/Symbol Search). Une bonne
      // réponse vaut 1 point, quel que soit le temps.
      final item = ArithmeticGenerator(seed: 9).generateComplete22Items().first;
      expect(item.calculateScore(item.correctAnswer, 999), 1); // correct, lent
      expect(item.calculateScore(item.correctAnswer, 0), 1); // correct, rapide → toujours 1 (plus de bonus)
      expect(item.calculateScore(item.correctAnswer + 1, 0), 0); // faux
      expect(item.calculateScore(null, 0), 0); // pas de réponse
    });
  });

  group('ArithmeticGenerator — variabilité', () {
    test('même seed → mêmes énoncés (reproductible)', () {
      final a = ArithmeticGenerator(seed: 42).generateComplete22Items();
      final b = ArithmeticGenerator(seed: 42).generateComplete22Items();
      expect(a.map((i) => i.problem).toList(), b.map((i) => i.problem).toList());
    });

    test('deux seeds → énoncés différents', () {
      final a = ArithmeticGenerator(seed: 1).generateComplete22Items().map((i) => i.problem).toSet();
      final b = ArithmeticGenerator(seed: 2).generateComplete22Items().map((i) => i.problem).toSet();
      expect(a.difference(b), isNotEmpty);
    });

    test('sur 30 passations, au moins 200 énoncés distincts', () {
      final all = <String>{};
      for (var seed = 0; seed < 30; seed++) {
        all.addAll(ArithmeticGenerator(seed: seed).generateComplete22Items().map((i) => i.problem));
      }
      expect(all.length, greaterThanOrEqualTo(200),
          reason: '${all.length} énoncés distincts sur 30 passations');
    });

    test('banque anglaise : 22 items, énoncés en anglais', () {
      final items = ArithmeticGenerator(languageCode: 'en', seed: 7).generateComplete22Items();
      expect(items.length, 22);
      for (final i in items) {
        expect(i.problem.contains('{'), isFalse);
        expect(i.correctAnswer, greaterThan(0));
      }
    });
  });
}
