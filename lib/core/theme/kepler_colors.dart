import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Palette Kepler dynamique selon `Theme.of(context).brightness`.
///
/// Permet à un widget de récupérer en un seul appel les couleurs neutres
/// (fonds, surfaces, textes, bordures) adaptées au mode light ou dark sans
/// référencer en dur `AppColors.background` / `AppColors.white` etc.
///
/// Les couleurs sémantiques (index cognitifs, success, error, primary)
/// restent dans `AppColors.*` car elles ne changent pas entre les modes.
@immutable
class KeplerColors {
  const KeplerColors._({
    required this.background,
    required this.surface,
    required this.cardSurface,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.border,
    required this.primary,
    required this.divider,
  });

  final Color background;
  final Color surface;
  final Color cardSurface;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color border;
  final Color primary;
  final Color divider;

  static KeplerColors of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? _dark : _light;
  }

  static const _light = KeplerColors._(
    background: AppColors.background,
    surface: AppColors.surfaceVariant,
    cardSurface: AppColors.white,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textTertiary: AppColors.textTertiary,
    border: Color(0x12000000), // black 7%
    primary: AppColors.primary,
    divider: Color(0x0F000000), // black 6%
  );

  static const _dark = KeplerColors._(
    background: AppColors.backgroundDark,         // #121212
    surface: AppColors.surfaceDark,               // #1C1C1C
    cardSurface: AppColors.cardDark,              // #1F1F1F
    textPrimary: AppColors.textPrimaryDark,       // #EEEEEE — 14.5:1 (AAA)
    textSecondary: AppColors.textSecondaryDark,   // #C0C0C0 — 8.4:1 (AA)
    textTertiary: AppColors.textTertiaryDark,     // #888888 — 4.6:1 (AA)
    border: Color(0x33FFFFFF),                    // white 20%
    primary: AppColors.primaryLightDark,          // #7CB58A — 9.4:1
    divider: Color(0x1FFFFFFF),                   // white 12%
  );
}
