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
    background: AppColors.backgroundDark,
    surface: AppColors.surfaceDark,
    cardSurface: AppColors.surfaceVariantDark,
    textPrimary: Color(0xFFF1F4F0), // off-white légèrement vert
    textSecondary: Color(0xFFB8C5BD),
    textTertiary: Color(0xFF7A9488),
    border: Color(0x33FFFFFF), // white 20%
    primary: AppColors.primaryLight,
    divider: Color(0x1FFFFFFF), // white 12%
  );
}
