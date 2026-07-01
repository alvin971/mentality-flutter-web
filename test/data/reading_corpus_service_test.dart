import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mentality/core/l10n/locale_notifier.dart';
import 'package:mentality/data/reading_corpus_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    localeNotifier.value = const Locale('fr');
  });

  group('ReadingCorpusService', () {
    test('pioche 5 textes distincts dans le corpus français', () async {
      final texts =
          await ReadingCorpusService.instance.pickSessionTexts(count: 5);

      expect(texts.length, 5);
      expect(texts.map((t) => t.id).toSet().length, 5,
          reason: 'les 5 textes doivent être distincts');
      for (final t in texts) {
        expect(t.body.isNotEmpty, isTrue);
        expect(t.approximateWordCount, greaterThan(0));
      }
    });

    test('ne répète pas de texte tant que le corpus n\'est pas épuisé',
        () async {
      final seen = <String>{};
      // Le corpus FR contient 503 textes ; sur 10 sessions de 5 textes
      // (50 textes), aucune répétition ne doit survenir.
      for (var i = 0; i < 10; i++) {
        final texts =
            await ReadingCorpusService.instance.pickSessionTexts(count: 5);
        for (final t in texts) {
          expect(seen.contains(t.id), isFalse,
              reason: 'texte ${t.id} déjà vu à la session $i');
          seen.add(t.id);
        }
      }
      expect(seen.length, 50);
    });

    test('réinitialise l\'historique une fois le corpus épuisé (langue à 50 textes)',
        () async {
      localeNotifier.value = const Locale('de');
      final seenPerRound = <Set<String>>[];

      // Le corpus DE contient 50 textes : 10 sessions de 5 l'épuisent
      // exactement. La 11e doit puiser dans un historique remis à zéro
      // plutôt que planter ou renvoyer moins de 5 textes.
      for (var i = 0; i < 11; i++) {
        final texts =
            await ReadingCorpusService.instance.pickSessionTexts(count: 5);
        expect(texts.length, 5);
        seenPerRound.add(texts.map((t) => t.id).toSet());
      }

      final last = seenPerRound.last;
      final priorRounds = seenPerRound.sublist(0, 10).expand((s) => s).toSet();
      expect(priorRounds.length, 50,
          reason: 'les 10 premières sessions doivent couvrir tout le corpus');
      // Après reset, les textes piochés viennent forcément du corpus déjà vu.
      expect(last.every(priorRounds.contains), isTrue);
    });
  });
}
