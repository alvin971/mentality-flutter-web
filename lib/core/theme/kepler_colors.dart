import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Palette Kepler résolue selon `Theme.of(context).brightness`.
///
/// **C'est le seul point d'entrée couleur autorisé dans les pages.** Référencer
/// directement `AppColors.textPrimary`, `AppColors.grey200` ou `Colors.white`
/// dans un widget grave la valeur du mode clair et casse le mode sombre — c'est
/// exactement la cause de la régression corrigée le 2026-07-25.
///
/// Les valeurs sombres sont calibrées en APCA (voir `app_colors.dart`) et
/// verrouillées par `test/core/theme/dark_palette_contrast_test.dart`.
@immutable
class KeplerColors {
  const KeplerColors._({
    required this.background,
    required this.surface,
    required this.cardSurface,
    required this.raised,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.border,
    required this.divider,
    required this.primary,
    required this.accentFill,
    required this.onAccentFill,
    required this.success,
    required this.error,
    required this.warning,
    required this.info,
  });

  // ---- Surfaces ----
  final Color background;
  final Color surface;
  final Color cardSurface;

  /// Surface haute : dialogues, bottom sheets, menus.
  final Color raised;

  // ---- Texte ----
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  // ---- Traits ----
  final Color border;
  final Color divider;

  // ---- Marque ----
  /// Accent pour texte et icônes.
  final Color primary;

  /// Fond de bouton / pastille accent.
  final Color accentFill;

  /// Couleur du label posé sur [accentFill].
  final Color onAccentFill;

  // ---- Feedback ----
  final Color success;
  final Color error;
  final Color warning;
  final Color info;

  static KeplerColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _dark : _light;

  /// Variante correspondant à une [Brightness] explicite — utile en test et
  /// dans les rares widgets construits hors arbre.
  static KeplerColors forBrightness(Brightness brightness) =>
      brightness == Brightness.dark ? _dark : _light;

  static const _light = KeplerColors._(
    background: AppColors.background,
    surface: AppColors.surfaceVariant,
    cardSurface: AppColors.white,
    raised: AppColors.white,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textTertiary: AppColors.textTertiary,
    border: Color(0x12000000), // noir 7 %
    divider: Color(0x0F000000), // noir 6 %
    primary: AppColors.primary,
    accentFill: AppColors.primary,
    onAccentFill: AppColors.background,
    success: AppColors.success,
    error: AppColors.error,
    warning: AppColors.warning,
    info: AppColors.info,
  );

  static const _dark = KeplerColors._(
    background: AppColors.backgroundDark, // #101312
    surface: AppColors.surfaceDark, // #181C1A
    cardSurface: AppColors.cardDark, // #1E2321
    raised: AppColors.raisedDark, // #272D2A
    textPrimary: AppColors.textPrimaryDark, // Lc 90
    textSecondary: AppColors.textSecondaryDark, // Lc 78
    textTertiary: AppColors.textTertiaryDark, // Lc 72
    border: AppColors.borderDark, // Lc 32
    divider: AppColors.dividerDark, // Lc 30
    primary: AppColors.primaryLightDark, // Lc 76
    accentFill: AppColors.accentFillDark, // label à Lc 80
    onAccentFill: AppColors.backgroundDark,
    success: AppColors.successDark, // Lc 76
    error: AppColors.errorDark, // Lc 76
    warning: AppColors.warningDark, // Lc 76
    info: AppColors.infoDark, // Lc 76
  );
}
