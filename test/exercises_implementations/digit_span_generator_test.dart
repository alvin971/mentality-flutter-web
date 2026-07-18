import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/features/exercises_implementations/digit_span/domain/digit_span_generator.dart';

void main() {
  group('DigitSpanGenerator — structure', () {
    final gen = DigitSpanGenerator(seed: 42);

    test('16 items forward, 14 backward, 16 sequencing', () {
      expect(gen.getForwardItems(), hasLength(16));
      expect(gen.getBackwardItems(), hasLength(14));
      expect(gen.getSequencingItems(), hasLength(16));
    });

    test('longueurs croissantes 2->9 (2->8 backward), 2 essais par longueur',
        () {
      void check(List<DigitSpanItem> items, int maxLen) {
        int i = 0;
        for (int len = 2; len <= maxLen; len++) {
          for (int trial = 1; trial <= 2; trial++) {
            expect(items[i].length, len);
            expect(items[i].trial, trial);
            expect(items[i].sequence, hasLength(len));
            i++;
          }
        }
      }

      check(gen.getForwardItems(), 9);
      check(gen.getBackwardItems(), 8);
      check(gen.getSequencingItems(), 9);
    });
  });

  group('DigitSpanGenerator — contraintes de qualité', () {
    // Plusieurs graines pour couvrir des tirages variés.
    final allItems = [
      for (int seed = 0; seed < 20; seed++) ...[
        ...DigitSpanGenerator(seed: seed).getForwardItems(),
        ...DigitSpanGenerator(seed: seed).getBackwardItems(),
        ...DigitSpanGenerator(seed: seed).getSequencingItems(),
      ],
    ];

    test('chiffres 1-9, tous distincts dans une séquence', () {
      for (final item in allItems) {
        expect(item.sequence.every((d) => d >= 1 && d <= 9), isTrue);
        expect(item.sequence.toSet(), hasLength(item.sequence.length));
      }
    });

    test('pas de suite de 3 chiffres consécutifs (ex. 3-4-5, 7-6-5)', () {
      for (final item in allItems) {
        final s = item.sequence;
        for (int i = 0; i + 2 < s.length; i++) {
          final d1 = s[i + 1] - s[i];
          final d2 = s[i + 2] - s[i + 1];
          expect(d1 == 1 && d2 == 1, isFalse, reason: 'suite montante: $s');
          expect(d1 == -1 && d2 == -1, isFalse,
              reason: 'suite descendante: $s');
        }
      }
    });

    test('séquençage : jamais présenté déjà trié', () {
      for (final item in allItems) {
        if (item.type != SpanType.sequencing) continue;
        final sorted = List<int>.from(item.sequence)..sort();
        expect(item.sequence, isNot(equals(sorted)),
            reason: 'déjà triée: ${item.sequence}');
      }
    });
  });

  group('DigitSpanGenerator — aléa entre passations', () {
    test('deux générateurs non seedés produisent des séquences différentes',
        () {
      final a = DigitSpanGenerator().getForwardItems();
      final b = DigitSpanGenerator().getForwardItems();
      // Sur les longueurs >= 5, une collision totale est quasi impossible.
      final longA = a.where((i) => i.length >= 5).map((i) => i.sequence.join());
      final longB = b.where((i) => i.length >= 5).map((i) => i.sequence.join());
      expect(longA.toList(), isNot(equals(longB.toList())));
    });

    test('même graine => mêmes séquences (reproductibilité diagnostics)', () {
      final a = DigitSpanGenerator(seed: 7).getForwardItems();
      final b = DigitSpanGenerator(seed: 7).getForwardItems();
      for (int i = 0; i < a.length; i++) {
        expect(a[i].sequence, equals(b[i].sequence));
      }
    });
  });
}
