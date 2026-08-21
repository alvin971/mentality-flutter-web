import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/core/services/subtest_instrumentation.dart';

void main() {
  group('SubtestInstrumentation', () {
    test('un item sans startItem ne produit rien', () {
      final i = SubtestInstrumentation('vocabulary')
        ..onInput(previous: '', current: 'a')
        ..endItem(response: 'a');
      expect(i.itemCount, 0);
      expect(i.toPayload()['items'], isEmpty);
    });

    test('compte les éditions et distingue les retours arrière', () {
      final i = SubtestInstrumentation('vocabulary')
        ..startItem(index: 0, itemId: 'voc_01')
        ..onInput(previous: '', current: 'ch')      // ajout
        ..onInput(previous: 'ch', current: 'cha')   // ajout
        ..onInput(previous: 'cha', current: 'ch')   // retour arrière
        ..endItem(response: 'ch', isCorrect: false, score: 0);

      final item = (i.toPayload()['items'] as List).single as Map;
      expect(item['editsCount'], 3);
      expect(item['backspacesCount'], 1);
      expect(item['index'], 0);
      expect(item['itemId'], 'voc_01');
      expect(item['isCorrect'], false);
    });

    test("firstInputMs n'est posé qu'une fois, à la première frappe", () {
      final i = SubtestInstrumentation('similarities')
        ..startItem(index: 0)
        ..onInput(previous: '', current: 'a')
        ..onInput(previous: 'a', current: 'ab')
        ..endItem(response: 'ab');
      final item = (i.toPayload()['items'] as List).single as Map;
      expect(item['firstInputMs'], isNotNull);
      expect(item['firstInputMs'], lessThanOrEqualTo(item['latencyMs'] as int));
    });

    test('un item sans aucune saisie n\'a pas de firstInputMs', () {
      final i = SubtestInstrumentation('matrices')
        ..startItem(index: 0)
        ..endItem(skipped: true);
      final item = (i.toPayload()['items'] as List).single as Map;
      expect(item.containsKey('firstInputMs'), isFalse);
      expect(item['skipped'], true);
    });

    test('médiane : impair prend le milieu, pair fait la moyenne', () {
      final i = SubtestInstrumentation('coding');
      // On ne peut pas forcer le chrono ; on vérifie la cohérence structurelle.
      for (var k = 0; k < 4; k++) {
        i..startItem(index: k)..endItem(response: '$k', isCorrect: k.isEven);
      }
      final p = i.toPayload(rawScore: 2, maxScore: 4);
      expect(p['itemsAdministered'], 4);
      expect(p['itemsCorrect'], 2);          // k = 0 et 2
      expect(p['medianLatencyMs'], isNotNull);
      expect(p['subtest'], 'coding');
      expect(p['rawScore'], 2);
    });

    test('la liste rendue est immuable', () {
      final i = SubtestInstrumentation('information')
        ..startItem(index: 0)
        ..endItem(response: 'x');
      final items = i.toPayload()['items'] as List;
      expect(() => items.add(<String, dynamic>{}), throwsUnsupportedError);
    });

    test('le contenu saisi ne fuit pas via onInput', () {
      final i = SubtestInstrumentation('vocabulary')
        ..startItem(index: 0)
        ..onInput(previous: '', current: 'secret')
        ..endItem(isCorrect: true);
      final item = (i.toPayload()['items'] as List).single as Map;
      // Aucune réponse transmise ici : seul endItem(response:) la transmet.
      expect(item.containsKey('response'), isFalse);
      expect(item.toString(), isNot(contains('secret')));
    });
  });
}
