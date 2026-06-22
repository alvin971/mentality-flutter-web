import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Notifier qui gère la langue de l'application.
///
/// Langues : français, anglais (US), anglais (UK), espagnol, portugais,
/// allemand. Le choix est persisté dans SharedPreferences (sous forme de
/// « tag » comme `fr`, `en`, `en-GB`, `es`, `pt`, `de`) et restauré au
/// démarrage.
class LocaleNotifier extends ValueNotifier<Locale> {
  LocaleNotifier() : super(const Locale('fr'));

  static const String _prefsKey = 'app_locale';

  /// Langues proposées par l'application. `Locale('en','GB')` est l'anglais
  /// britannique, DISTINCT de `Locale('en')` (anglais US).
  static const List<Locale> supportedLocales = [
    Locale('fr'),
    Locale('en'),
    Locale('en', 'GB'),
    Locale('es'),
    Locale('pt'),
    Locale('de'),
  ];

  /// Tag canonique d'une locale : `fr`, `en`, `en-GB`, `es`, `pt`, `de`.
  /// Sert de clé pour le contenu hors-ARB (générateurs d'items, chat, PDF...)
  /// et pour la persistance.
  static String tagFor(Locale locale) => locale.countryCode == null
      ? locale.languageCode
      : '${locale.languageCode}-${locale.countryCode}';

  /// Reconstruit une [Locale] depuis un tag (`en-GB` → `Locale('en','GB')`).
  static Locale localeFromTag(String tag) {
    final parts = tag.split('-');
    return parts.length == 2 ? Locale(parts[0], parts[1]) : Locale(parts[0]);
  }

  static bool _isSupported(Locale l) => supportedLocales.any((s) =>
      s.languageCode == l.languageCode && s.countryCode == l.countryCode);

  /// Charge la langue sauvegardée depuis les préférences.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefsKey);
    if (stored == null) return;
    final loc = localeFromTag(stored);
    if (_isSupported(loc)) {
      value = loc;
    }
  }

  /// Change la langue et la persiste.
  Future<void> setLocale(Locale locale) async {
    if (!_isSupported(locale)) return;
    value = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, tagFor(locale));
  }

  /// Code langue ISO courant (`fr`, `en`, `es`, `pt`, `de`). ⚠️ Renvoie `en`
  /// aussi bien pour l'anglais US que britannique : pour router du CONTENU
  /// spécifique à une variante régionale, utiliser [contentTag].
  String get languageCode => value.languageCode;

  /// Tag de contenu courant (`fr`, `en`, `en-GB`, `es`, `pt`, `de`).
  /// Clé de routage du contenu hors-ARB qui distingue en-US de en-GB.
  String get contentTag => tagFor(value);
}

/// Instance globale accessible depuis toute l'app sans contexte.
final localeNotifier = LocaleNotifier();
