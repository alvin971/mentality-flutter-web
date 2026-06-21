import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/features/exercises_implementations/information/domain/information_generator.dart';

void main() {
  group('InformationGenerator — structure conservée', () {
    test('génère exactement 28 items', () {
      expect(InformationGenerator(seed: 1).generateComplete28Items().length, 28);
    });

    test('distribution par domaine 6/7/6/5/4', () {
      for (var seed = 0; seed < 20; seed++) {
        final items = InformationGenerator(seed: seed).generateComplete28Items();
        final counts = <KnowledgeDomain, int>{};
        for (final i in items) {
          counts[i.domain] = (counts[i.domain] ?? 0) + 1;
        }
        expect(counts[KnowledgeDomain.science], 6, reason: 'seed $seed');
        expect(counts[KnowledgeDomain.historyGeography], 7, reason: 'seed $seed');
        expect(counts[KnowledgeDomain.generalCulture], 6, reason: 'seed $seed');
        expect(counts[KnowledgeDomain.mathLogic], 5, reason: 'seed $seed');
        expect(counts[KnowledgeDomain.artsLiterature], 4, reason: 'seed $seed');
      }
    });

    test('progression de difficulté 9 faciles → 11 moyens → 8 difficiles', () {
      final items = InformationGenerator(seed: 2).generateComplete28Items();
      expect(
        items.map((i) => i.difficulty).toList(),
        [
          ...List.filled(9, DifficultyLevel.easy),
          ...List.filled(11, DifficultyLevel.medium),
          ...List.filled(8, DifficultyLevel.hard),
        ],
      );
    });

    test('theta croissant par slot (-2.0, pas 0.15)', () {
      final items = InformationGenerator(seed: 3).generateComplete28Items();
      for (var i = 0; i < items.length; i++) {
        expect(items[i].thetaValue, closeTo(-2.0 + 0.15 * i, 0.001));
      }
    });

    test('chaque QCM a 4 options distinctes et un index correct valide', () {
      final items = InformationGenerator(seed: 4).generateComplete28Items();
      for (final i in items) {
        expect(i.options.length, 4, reason: i.question);
        expect(i.options.toSet().length, 4, reason: 'options dupliquées: ${i.question}');
        expect(i.correctAnswer, inInclusiveRange(0, 3), reason: i.question);
        expect(i.options[i.correctAnswer].trim(), isNotEmpty);
      }
    });
  });

  group('InformationGenerator — variabilité & shuffle', () {
    test('même seed → mêmes questions (reproductible)', () {
      final a = InformationGenerator(seed: 42).generateComplete28Items();
      final b = InformationGenerator(seed: 42).generateComplete28Items();
      expect(a.map((i) => i.question).toList(), b.map((i) => i.question).toList());
    });

    test('deux seeds → sélections différentes', () {
      final a = InformationGenerator(seed: 1).generateComplete28Items().map((i) => i.question).toSet();
      final b = InformationGenerator(seed: 2).generateComplete28Items().map((i) => i.question).toSet();
      expect(a.difference(b), isNotEmpty);
    });

    test('sur 30 passations, au moins 60 questions distinctes', () {
      final all = <String>{};
      for (var seed = 0; seed < 30; seed++) {
        all.addAll(InformationGenerator(seed: seed).generateComplete28Items().map((i) => i.question));
      }
      expect(all.length, greaterThanOrEqualTo(60),
          reason: '${all.length} questions distinctes sur 30 passations');
    });

    test('la position de la bonne réponse varie (options mélangées, pas toujours B)', () {
      final positions = <int>{};
      for (var seed = 0; seed < 30; seed++) {
        for (final i in InformationGenerator(seed: seed).generateComplete28Items()) {
          positions.add(i.correctAnswer);
        }
      }
      expect(positions, containsAll([0, 1, 2, 3]),
          reason: 'la bonne réponse devrait apparaître à toutes les positions');
    });

    test('une question garde domaine + difficulté (banques disjointes)', () {
      final qToTag = <String, String>{};
      for (var seed = 0; seed < 40; seed++) {
        for (final i in InformationGenerator(seed: seed).generateComplete28Items()) {
          final tag = '${i.domain}|${i.difficulty}';
          final prev = qToTag[i.question];
          if (prev != null) expect(prev, tag, reason: i.question);
          qToTag[i.question] = tag;
        }
      }
    });
  });

  group('InformationGenerator — banque anglaise', () {
    test('génère 28 items EN avec la même structure', () {
      final items = InformationGenerator(languageCode: 'en', seed: 7).generateComplete28Items();
      expect(items.length, 28);
      for (final i in items) {
        expect(i.options.length, 4);
        expect(i.correctAnswer, inInclusiveRange(0, 3));
      }
    });
  });
}
