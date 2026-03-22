import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

/// Notifier qui gère le mode de thème (clair / sombre) de l'application.
///
/// Le choix est persisté dans SharedPreferences et restauré au démarrage.
class ThemeNotifier extends ValueNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.light);

  /// Charge le thème sauvegardé depuis les préférences.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(AppConstants.keyThemeMode);
    if (stored == 'dark') {
      value = ThemeMode.dark;
    } else {
      value = ThemeMode.light;
    }
  }

  /// Bascule entre clair et sombre.
  Future<void> toggle() async {
    value = value == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AppConstants.keyThemeMode,
      value == ThemeMode.dark ? 'dark' : 'light',
    );
  }

  bool get isDark => value == ThemeMode.dark;
}

/// Instance globale accessible depuis toute l'app sans contexte.
final themeNotifier = ThemeNotifier();
