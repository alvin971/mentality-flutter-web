import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/features/exercises_implementations/vocabulary/domain/vocabulary_generator.dart';

void main() {
  group('VocabularyGenerator — structure WAIS conservée', () {
    test('génère exactement 30 items', () {
      final items = VocabularyGenerator(seed: 1).generateComplete30Items();
      expect(items.length, 30);
    });

    test('répartition 5/7/8/7/3 par fréquence, dans l\'ordre', () {
      for (var seed = 0; seed < 20; seed++) {
        final items = VocabularyGenerator(seed: seed).generateComplete30Items();
        final frequencies = items.map((i) => i.frequency).toList();
        expect(
          frequencies,
          [
            ...List.filled(5, WordFrequency.veryHigh),
            ...List.filled(7, WordFrequency.high),
            ...List.filled(8, WordFrequency.medium),
            ...List.filled(7, WordFrequency.low),
            ...List.filled(3, WordFrequency.veryLow),
          ],
          reason: 'seed $seed',
        );
      }
    });

    test('échelle theta croissante de -2.0 à +3.8 par pas de 0.2', () {
      final items = VocabularyGenerator(seed: 3).generateComplete30Items();
      for (var i = 0; i < items.length; i++) {
        expect(items[i].thetaValue, closeTo(-2.0 + 0.2 * i, 0.001),
            reason: 'theta du slot $i');
      }
      expect(items.first.thetaValue, closeTo(-2.0, 0.001));
      expect(items.last.thetaValue, closeTo(3.8, 0.001));
    });

    test('aucun mot dupliqué dans une même passation (50 seeds)', () {
      for (var seed = 0; seed < 50; seed++) {
        final items = VocabularyGenerator(seed: seed).generateComplete30Items();
        final words = items.map((i) => i.word).toSet();
        expect(words.length, 30, reason: 'seed $seed');
      }
    });

    test('chaque item a des réponses 2 points et 1 point non vides', () {
      final items = VocabularyGenerator(seed: 4).generateComplete30Items();
      for (final item in items) {
        expect(item.twoPointAnswers, isNotEmpty, reason: item.word);
        expect(item.onePointAnswers, isNotEmpty, reason: item.word);
        expect(item.word.trim(), isNotEmpty);
      }
    });
  });

  group('VocabularyGenerator — variabilité entre passations', () {
    test('même seed → mêmes items (reproductible)', () {
      final a = VocabularyGenerator(seed: 42).generateComplete30Items();
      final b = VocabularyGenerator(seed: 42).generateComplete30Items();
      expect(a.map((i) => i.word).toList(), b.map((i) => i.word).toList());
    });

    test('deux seeds différents → sélections de mots différentes', () {
      final a = VocabularyGenerator(seed: 1)
          .generateComplete30Items()
          .map((i) => i.word)
          .toSet();
      final b = VocabularyGenerator(seed: 2)
          .generateComplete30Items()
          .map((i) => i.word)
          .toSet();
      expect(a.difference(b), isNotEmpty,
          reason: 'deux passations ne doivent pas tirer les mêmes 30 mots');
    });

    test('sur 30 passations, au moins 90 mots distincts apparaissent', () {
      final allWords = <String>{};
      for (var seed = 0; seed < 30; seed++) {
        allWords.addAll(VocabularyGenerator(seed: seed)
            .generateComplete30Items()
            .map((i) => i.word));
      }
      expect(allWords.length, greaterThanOrEqualTo(90),
          reason: '${allWords.length} mots distincts vus sur 30 passations');
    });

    test('un mot garde toujours sa fréquence (banques disjointes)', () {
      final wordToFrequency = <String, WordFrequency>{};
      for (var seed = 0; seed < 50; seed++) {
        for (final item
            in VocabularyGenerator(seed: seed).generateComplete30Items()) {
          final previous = wordToFrequency[item.word];
          if (previous != null) {
            expect(previous, item.frequency, reason: item.word);
          }
          wordToFrequency[item.word] = item.frequency;
        }
      }
    });
  });

  group('VocabularyItem.scoreAnswer — matching par mot entier (anti-exploit)', () {
    final item = VocabularyItem(
      word: 'fruit',
      frequency: WordFrequency.veryHigh,
      twoPointAnswers: const ['aliment sucré', 'produit comestible'],
      onePointAnswers: const ['nourriture'],
      thetaValue: -2.0,
    );

    test('réponse exacte à 2 points → 2', () {
      expect(item.scoreAnswer('aliment sucré'), 2);
    });

    test('définition contenant les mots clés entiers → 2', () {
      expect(item.scoreAnswer('un aliment sucré que l\'on mange'), 2);
    });

    test('réponse partielle 1 point → 1', () {
      expect(item.scoreAnswer('nourriture'), 1);
    });

    test('fragment de sous-chaîne ne score plus (exploit corrigé)', () {
      // « men » est une sous-chaîne de « aliment »/« comestible » : ne doit
      // plus scorer (l'ancien contains bidirectionnel donnait des points).
      expect(item.scoreAnswer('men'), 0);
      // Un mot hors-sujet, même contenant une sous-chaîne d'un mot clé.
      expect(item.scoreAnswer('alimentation'), 0);
      // Réponse absurde.
      expect(item.scoreAnswer('xyz'), 0);
    });
  });

  group('VocabularyGenerator — banque anglaise', () {
    test('génère 30 items EN avec la même structure', () {
      final items =
          VocabularyGenerator(languageCode: 'en', seed: 7).generateComplete30Items();
      expect(items.length, 30);
      for (final item in items) {
        expect(item.word.trim(), isNotEmpty);
        expect(item.twoPointAnswers, isNotEmpty);
        expect(item.onePointAnswers, isNotEmpty);
      }
      expect(items.first.thetaValue, closeTo(-2.0, 0.001));
      expect(items.last.thetaValue, closeTo(3.8, 0.001));
    });
  });
}
