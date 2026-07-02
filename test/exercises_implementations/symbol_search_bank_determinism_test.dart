import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/features/exercises_implementations/symbol_search/domain/symbol_search_generator.dart';

/// Détermine si la banque d'items de Recherche de Symboles (Symbol Search)
/// est DETERMINISTE et versionnée : deux passations distinctes doivent produire
/// EXACTEMENT les mêmes items dans le même ordre (comparabilité CTT).
///
/// Ce test DOIT échouer si une source d'aléa non seedée fuit à nouveau
/// (Random() implicite, shuffle() sans argument, ordre de Set/Map, etc.).
void main() {
  group('SymbolSearchGenerator - déterminisme de la banque', () {
    test('deux générateurs produisent une banque identique (mêmes items, même ordre)', () {
      final itemsA = SymbolSearchGenerator().getAllItems();
      final itemsB = SymbolSearchGenerator().getAllItems();

      // Le nombre d'items doit rester de 60 (30 OUI + 30 NON).
      expect(itemsA.length, 60);
      expect(itemsB.length, 60);

      for (int i = 0; i < itemsA.length; i++) {
        final a = itemsA[i];
        final b = itemsB[i];

        // Champs identifiants : symboles cibles, groupe de recherche, réponse.
        expect(b.targetSymbols, a.targetSymbols,
            reason: 'targetSymbols divergents à la position $i');
        expect(b.searchGroup, a.searchGroup,
            reason: 'searchGroup divergent à la position $i');
        expect(b.correctAnswer, a.correctAnswer,
            reason: 'correctAnswer divergent à la position $i');
      }
    });

    test('équilibre OUI/NON préservé (30 OUI, 30 NON)', () {
      final items = SymbolSearchGenerator().getAllItems();
      final oui = items.where((it) => it.correctAnswer).length;
      final non = items.where((it) => !it.correctAnswer).length;

      expect(oui, 30, reason: 'doit contenir exactement 30 items OUI');
      expect(non, 30, reason: 'doit contenir exactement 30 items NON');
    });

    test('la graine de banque est figée et versionnée', () {
      expect(SymbolSearchGenerator.kBankSeed, 20260616);
    });
  });
}
