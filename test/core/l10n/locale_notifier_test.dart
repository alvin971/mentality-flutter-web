import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mentality/core/l10n/locale_notifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocaleNotifier.tagFor', () {
    test('encode les locales simples et régionales', () {
      expect(LocaleNotifier.tagFor(const Locale('fr')), 'fr');
      expect(LocaleNotifier.tagFor(const Locale('en')), 'en');
      expect(LocaleNotifier.tagFor(const Locale('en', 'GB')), 'en-GB');
      expect(LocaleNotifier.tagFor(const Locale('es')), 'es');
      expect(LocaleNotifier.tagFor(const Locale('pt')), 'pt');
      expect(LocaleNotifier.tagFor(const Locale('de')), 'de');
    });
  });

  group('LocaleNotifier.localeFromTag', () {
    test('reconstruit les locales depuis un tag', () {
      expect(LocaleNotifier.localeFromTag('fr'), const Locale('fr'));
      expect(LocaleNotifier.localeFromTag('en-GB'), const Locale('en', 'GB'));
      expect(LocaleNotifier.localeFromTag('de'), const Locale('de'));
    });

    test('round-trip tag <-> locale pour toutes les langues supportées', () {
      for (final l in LocaleNotifier.supportedLocales) {
        expect(
          LocaleNotifier.localeFromTag(LocaleNotifier.tagFor(l)),
          l,
          reason: 'round-trip cassé pour $l',
        );
      }
    });
  });

  group('supportedLocales', () {
    test('contient les 6 langues dont en-US et en-GB distincts', () {
      expect(LocaleNotifier.supportedLocales, contains(const Locale('en')));
      expect(LocaleNotifier.supportedLocales,
          contains(const Locale('en', 'GB')));
      expect(LocaleNotifier.supportedLocales.length, 6);
    });
  });

  group('setLocale / load', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('persiste et restaure en-GB (countryCode préservé)', () async {
      final notifier = LocaleNotifier();
      await notifier.setLocale(const Locale('en', 'GB'));
      expect(notifier.value, const Locale('en', 'GB'));
      expect(notifier.contentTag, 'en-GB');
      // languageCode reste 'en' (variante régionale).
      expect(notifier.languageCode, 'en');

      final restored = LocaleNotifier();
      await restored.load();
      expect(restored.value, const Locale('en', 'GB'));
      expect(restored.contentTag, 'en-GB');
    });

    test('ignore une locale non supportée', () async {
      final notifier = LocaleNotifier();
      await notifier.setLocale(const Locale('it'));
      expect(notifier.value, const Locale('fr')); // inchangé (défaut)
    });

    test('restaure un ancien tag simple (rétro-compatibilité)', () async {
      SharedPreferences.setMockInitialValues({'app_locale': 'es'});
      final notifier = LocaleNotifier();
      await notifier.load();
      expect(notifier.value, const Locale('es'));
      expect(notifier.contentTag, 'es');
    });
  });
}
