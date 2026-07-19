import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/features/exercises_implementations/symbol_search/domain/symbol_search_generator.dart';

/// Vérifie que les items de Recherche de Symboles sont ALÉATOIRES PAR
/// PASSATION : deux sessions distinctes ne doivent pas produire la même
/// séquence d'items (personne ne rejoue le même test), tandis que la
/// STRUCTURE (60 items, 30 OUI / 30 NON) reste identique pour tous.
///
/// Ce test DOIT échouer si un seed fixe est réintroduit en production.
String _itemSig(SymbolSearchItem it) =>
    '${it.targetSymbols.join(",")}|${it.searchGroup.join(",")}|${it.correctAnswer}';

void main() {
  group('SymbolSearchGenerator — aléa par passation', () {
    test('deux passations sans seed produisent des séquences différentes', () {
      final a = SymbolSearchGenerator().getAllItems().map(_itemSig).toList();
      final b = SymbolSearchGenerator().getAllItems().map(_itemSig).toList();

      expect(a, isNot(equals(b)),
          reason: 'Deux sessions ne doivent jamais présenter le même test '
              '(un seed fixe a probablement été réintroduit).');
    });

    test('un même seed explicite est reproductible (tests/diagnostics)', () {
      final a = SymbolSearchGenerator(seed: 42).getAllItems().map(_itemSig);
      final b = SymbolSearchGenerator(seed: 42).getAllItems().map(_itemSig);
      expect(a.toList(), equals(b.toList()));
    });

    test('structure invariante : 60 items, 30 OUI / 30 NON, quel que soit le tirage', () {
      for (var seed = 0; seed < 30; seed++) {
        final items = SymbolSearchGenerator(seed: seed).getAllItems();
        expect(items.length, 60, reason: 'seed=$seed');
        expect(items.where((it) => it.correctAnswer).length, 30,
            reason: 'seed=$seed : exactement 30 items OUI');
        expect(items.where((it) => !it.correctAnswer).length, 30,
            reason: 'seed=$seed : exactement 30 items NON');
      }
    });

    test('cohérence des items : la réponse OUI/NON correspond au contenu', () {
      for (var seed = 0; seed < 30; seed++) {
        for (final it in SymbolSearchGenerator(seed: seed).getAllItems()) {
          final present =
              it.searchGroup.any((s) => it.targetSymbols.contains(s));
          expect(present, it.correctAnswer,
              reason: 'seed=$seed item ${it.index} : correctAnswer doit '
                  'refléter la présence réelle d\'une cible.');
          expect(it.targetSymbols.length, 2, reason: 'seed=$seed');
          expect(it.searchGroup.length, 5, reason: 'seed=$seed');
        }
      }
    });
  });
}
