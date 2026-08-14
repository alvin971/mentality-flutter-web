import 'dart:convert';
import 'dart:ui';

import 'package:flutter/services.dart' show rootBundle;
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
      // Sur 10 sessions de 5 textes, aucune répétition ne doit survenir : le
      // corpus français est très au-dessus de ces 50 textes.
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

    test('les six langues couvrent exactement les mêmes familles', () async {
      // C'est la raison d'être du corpus : un enregistrement allemand et un
      // enregistrement espagnol doivent porter le MÊME contenu pour être
      // comparables. Si une langue dérive, l'alignement est perdu.
      Set<String> familles(String raw) => raw
          .split('\n')
          .where((l) => l.trim().isNotEmpty)
          .map((l) => (jsonDecode(l) as Map<String, dynamic>)['family'] as String)
          .toSet();

      final fr = familles(
          await rootBundle.loadString('assets/reading_corpus/fr.jsonl'));
      expect(fr, isNotEmpty);

      for (final asset in ['en', 'en_GB', 'es', 'pt', 'de']) {
        final autre = familles(
            await rootBundle.loadString('assets/reading_corpus/$asset.jsonl'));
        expect(autre, fr,
            reason: '$asset ne couvre pas les mêmes familles que le français');
      }
    });

    test('réinitialise l\'historique une fois le corpus épuisé', () async {
      localeNotifier.value = const Locale('de');

      // La taille du corpus est DÉRIVÉE de l'asset, jamais codée en dur : elle
      // grandit à chaque cycle de production, et un nombre écrit en dur ferait
      // retomber ce test à la prochaine vague.
      final raw = await rootBundle.loadString('assets/reading_corpus/de.jsonl');
      final total =
          raw.split('\n').where((l) => l.trim().isNotEmpty).length;
      final sessionsPourEpuiser = total ~/ 5;
      expect(sessionsPourEpuiser, greaterThan(1));

      final vus = <String>{};
      for (var i = 0; i < sessionsPourEpuiser; i++) {
        final texts =
            await ReadingCorpusService.instance.pickSessionTexts(count: 5);
        expect(texts.length, 5, reason: 'session $i tronquée');
        vus.addAll(texts.map((t) => t.id));
      }
      expect(vus.length, sessionsPourEpuiser * 5,
          reason: 'aucune répétition avant épuisement du corpus');

      // La session suivante doit puiser dans un historique remis à zéro,
      // plutôt que planter ou renvoyer moins de cinq textes.
      final apresReset =
          await ReadingCorpusService.instance.pickSessionTexts(count: 5);
      expect(apresReset.length, 5);
      expect(apresReset.every((t) => vus.contains(t.id)), isTrue);
    });
  });
}
