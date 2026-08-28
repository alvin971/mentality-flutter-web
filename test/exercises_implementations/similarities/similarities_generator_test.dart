import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/features/exercises_implementations/similarities/domain/similarities_generator.dart';

String _pairKey(SimilarityItem i) => '${i.word1}|${i.word2}';

void main() {
  group('SimilaritiesGenerator — structure de la banque conservée', () {
    test('génère exactement 21 items', () {
      expect(SimilaritiesGenerator(seed: 1).generateComplete21Items().length, 21);
    });

    test('répartition 4/6/6/5 par niveau, dans l\'ordre', () {
      for (var seed = 0; seed < 20; seed++) {
        final items = SimilaritiesGenerator(seed: seed).generateComplete21Items();
        expect(
          items.map((i) => i.level).toList(),
          [
            ...List.filled(4, AbstractionLevel.concrete),
            ...List.filled(6, AbstractionLevel.functional),
            ...List.filled(6, AbstractionLevel.categorical),
            ...List.filled(5, AbstractionLevel.abstract),
          ],
          reason: 'seed $seed',
        );
      }
    });

    test('échelle theta croissante de -1.5 à +2.5 par pas de 0.2', () {
      final items = SimilaritiesGenerator(seed: 3).generateComplete21Items();
      for (var i = 0; i < items.length; i++) {
        expect(items[i].thetaValue, closeTo(-1.5 + 0.2 * i, 0.001),
            reason: 'theta du slot $i');
      }
      expect(items.first.thetaValue, closeTo(-1.5, 0.001));
      expect(items.last.thetaValue, closeTo(2.5, 0.001));
    });

    test('aucune paire dupliquée dans une même passation (50 seeds)', () {
      for (var seed = 0; seed < 50; seed++) {
        final items = SimilaritiesGenerator(seed: seed).generateComplete21Items();
        expect(items.map(_pairKey).toSet().length, 21, reason: 'seed $seed');
      }
    });

    test('chaque paire a mots + réponses non vides', () {
      for (final item in SimilaritiesGenerator(seed: 4).generateComplete21Items()) {
        expect(item.word1.trim(), isNotEmpty);
        expect(item.word2.trim(), isNotEmpty);
        expect(item.twoPointAnswers, isNotEmpty);
        expect(item.onePointAnswers, isNotEmpty);
      }
    });
  });

  group('SimilaritiesGenerator — variabilité', () {
    test('même seed → mêmes paires (reproductible)', () {
      final a = SimilaritiesGenerator(seed: 42).generateComplete21Items();
      final b = SimilaritiesGenerator(seed: 42).generateComplete21Items();
      expect(a.map(_pairKey).toList(), b.map(_pairKey).toList());
    });

    test('deux seeds différents → sélections différentes', () {
      final a = SimilaritiesGenerator(seed: 1).generateComplete21Items().map(_pairKey).toSet();
      final b = SimilaritiesGenerator(seed: 2).generateComplete21Items().map(_pairKey).toSet();
      expect(a.difference(b), isNotEmpty);
    });

    test('sur 30 passations, au moins 60 paires distinctes apparaissent', () {
      final all = <String>{};
      for (var seed = 0; seed < 30; seed++) {
        all.addAll(SimilaritiesGenerator(seed: seed).generateComplete21Items().map(_pairKey));
      }
      expect(all.length, greaterThanOrEqualTo(60),
          reason: '${all.length} paires distinctes sur 30 passations');
    });

    test('une paire garde toujours son niveau (banques disjointes)', () {
      final pairToLevel = <String, AbstractionLevel>{};
      for (var seed = 0; seed < 50; seed++) {
        for (final item in SimilaritiesGenerator(seed: seed).generateComplete21Items()) {
          final key = _pairKey(item);
          final prev = pairToLevel[key];
          if (prev != null) expect(prev, item.level, reason: key);
          pairToLevel[key] = item.level;
        }
      }
    });
  });

  group('SimilaritiesGenerator — banque anglaise', () {
    test('génère 21 items EN avec la même structure', () {
      final items =
          SimilaritiesGenerator(languageCode: 'en', seed: 7).generateComplete21Items();
      expect(items.length, 21);
      expect(items.first.thetaValue, closeTo(-1.5, 0.001));
      expect(items.last.thetaValue, closeTo(2.5, 0.001));
      for (final item in items) {
        expect(item.word1.trim(), isNotEmpty);
        expect(item.word2.trim(), isNotEmpty);
      }
    });
  });
}
