import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Notifier qui gère la langue de l'application (français / anglais).
///
/// Le choix est persisté dans SharedPreferences et restauré au démarrage.
class LocaleNotifier extends ValueNotifier<Locale> {
  LocaleNotifier() : super(const Locale('fr'));

  static const String _prefsKey = 'app_locale';

  /// Langues proposées par l'application.
  static const List<Locale> supportedLocales = [
    Locale('fr'),
    Locale('en'),
  ];

  /// Charge la langue sauvegardée depuis les préférences.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefsKey);
    if (stored != null &&
        supportedLocales.any((l) => l.languageCode == stored)) {
      value = Locale(stored);
    }
  }

  /// Change la langue et la persiste.
  Future<void> setLocale(Locale locale) async {
    if (!supportedLocales.any((l) => l.languageCode == locale.languageCode)) {
      return;
    }
    value = Locale(locale.languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, locale.languageCode);
  }

  /// Code langue courant ('fr' ou 'en') — utilisable hors widget tree
  /// (générateurs d'items, services, PDF...).
  String get languageCode => value.languageCode;
}

/// Instance globale accessible depuis toute l'app sans contexte.
final localeNotifier = LocaleNotifier();
