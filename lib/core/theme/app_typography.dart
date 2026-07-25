import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'app_colors.dart';
import 'kepler_colors.dart';

/// Typographie Kepler — Mental E.T.
///
/// Trois familles :
/// - Source Serif 4 → titres éditoriaux, italiques d'accent
/// - DM Sans       → corps de texte, UI
/// - Roboto Mono   → labels mono, scores psychométriques
///
/// ## ⚠️ Utiliser `AppText.of(context)`, pas les méthodes statiques
///
/// Les méthodes statiques ci-dessous portent une couleur par défaut du mode
/// CLAIR. Appelées telles quelles depuis une page (`AppText.body()`), elles
/// gravent cette couleur dans le style : en mode sombre le texte devenait
/// invisible (Lc 1.04 mesuré sur `bodyStrong` avant correction du 2026-07-25).
///
/// Dans un widget, toujours passer par le résolveur contextuel :
/// ```dart
/// Text(label, style: AppText.of(context).bodyStrong())
/// ```
/// Les statiques restent publiques pour `buildTextTheme()` et pour les rares
/// appels qui fournissent déjà une couleur résolue.
class AppText {
  AppText._();

  /// Résolveur contextuel : les couleurs par défaut suivent le thème.
  static KeplerText of(BuildContext context) =>
      KeplerText._(KeplerColors.of(context));


  // ---- Fabriques de familles ----
  //
  // Les trois familles sont EMBARQUÉES (cf. `pubspec.yaml`) et variables :
  // un seul fichier par famille, la graisse étant pilotée par l'axe `wght`.
  // On renseigne donc `fontVariations` en plus de `fontWeight` — le second
  // seul ne suffit pas à instancier l'axe sur toutes les plateformes.
  //
  // Ne pas revenir à `GoogleFonts.*` : cela réintroduirait le téléchargement
  // au lancement, la police système en secours hors réseau et la requête à
  // fonts.gstatic.com.

  static TextStyle _face(
    String family, {
    required double fontSize,
    required FontWeight fontWeight,
    double? height,
    double? letterSpacing,
    FontStyle? fontStyle,
    Color? color,
  }) =>
      TextStyle(
        fontFamily: family,
        fontSize: fontSize,
        height: height,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        letterSpacing: letterSpacing,
        color: color,
        fontVariations: [FontVariation('wght', fontWeight.value.toDouble())],
      );

  /// Source Serif 4 — titres éditoriaux.
  static TextStyle _serif({
    required double fontSize,
    required FontWeight fontWeight,
    double? height,
    double? letterSpacing,
    FontStyle? fontStyle,
    Color? color,
  }) =>
      _face('SourceSerif4',
          fontSize: fontSize,
          fontWeight: fontWeight,
          height: height,
          letterSpacing: letterSpacing,
          fontStyle: fontStyle,
          color: color);

  /// DM Sans — corps de texte et UI.
  static TextStyle _sans({
    required double fontSize,
    required FontWeight fontWeight,
    double? height,
    double? letterSpacing,
    Color? color,
  }) =>
      _face('DMSans',
          fontSize: fontSize,
          fontWeight: fontWeight,
          height: height,
          letterSpacing: letterSpacing,
          color: color);

  /// Roboto Mono — labels mono et scores psychométriques.
  static TextStyle _mono({
    required double fontSize,
    required FontWeight fontWeight,
    double? letterSpacing,
    Color? color,
  }) =>
      _face('RobotoMono',
          fontSize: fontSize,
          fontWeight: fontWeight,
          letterSpacing: letterSpacing,
          color: color);

  // ---- Source Serif 4 : titres éditoriaux ----

  static TextStyle heroDisplay({Color? color}) => _serif(
        fontSize: 40.sp,
        height: 1.1,
        fontWeight: FontWeight.w500,
        letterSpacing: -1.2,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle heroItalic({Color? color}) => _serif(
        fontSize: 40.sp,
        height: 1.1,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w500,
        letterSpacing: -1.2,
        color: color ?? AppColors.primary,
      );

  static TextStyle h1({Color? color}) => _serif(
        fontSize: 30.sp,
        height: 1.15,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.6,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle h1Italic({Color? color}) => _serif(
        fontSize: 30.sp,
        height: 1.15,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.6,
        color: color ?? AppColors.primary,
      );

  static TextStyle h2({Color? color}) => _serif(
        fontSize: 24.sp,
        height: 1.2,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.3,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle h2Italic({Color? color}) => _serif(
        fontSize: 24.sp,
        height: 1.2,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.3,
        color: color ?? AppColors.primary,
      );

  static TextStyle h3({Color? color}) => _serif(
        fontSize: 19.sp,
        height: 1.25,
        fontWeight: FontWeight.w500,
        color: color ?? AppColors.textPrimary,
      );

  // ---- DM Sans : corps & UI ----

  static TextStyle body({Color? color}) => _sans(
        fontSize: 15.sp,
        height: 1.65,
        fontWeight: FontWeight.w400,
        color: color ?? AppColors.textSecondary,
      );

  static TextStyle bodyStrong({Color? color}) => _sans(
        fontSize: 15.sp,
        height: 1.55,
        fontWeight: FontWeight.w500,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle bodySmall({Color? color}) => _sans(
        fontSize: 13.sp,
        height: 1.55,
        fontWeight: FontWeight.w400,
        color: color ?? AppColors.textSecondary,
      );

  static TextStyle button({Color? color}) => _sans(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: color ?? AppColors.background,
      );

  // ---- DM Mono : labels mono, scores ----

  static TextStyle mono({Color? color, double? size}) => _mono(
        fontSize: size ?? 11.sp,
        fontWeight: FontWeight.w500,
        letterSpacing: 2.0,
        color: color ?? AppColors.textTertiary,
      );

  static TextStyle monoLabel({Color? color}) => _mono(
        fontSize: 11.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: 2.4,
        color: color ?? AppColors.textTertiary,
      );

  static TextStyle monoScore({Color? color, double? size}) =>
      _mono(
        fontSize: size ?? 28.sp,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.5,
        color: color ?? AppColors.textPrimary,
      );

  /// TextTheme Material 3 dérivé de Kepler — appliqué globalement via ThemeData.
  ///
  /// Note : ce TextTheme ne couvre QUE les widgets qui lisent
  /// `Theme.of(context).textTheme`. Un `Text(style: AppText.body())` explicite
  /// ne passe pas par là — d'où l'existence de [AppText.of].
  static TextTheme buildTextTheme() {
    return TextTheme(
      displayLarge: heroDisplay(),
      displayMedium: h1(),
      displaySmall: h2(),
      headlineLarge: h2(),
      headlineMedium: h3(),
      headlineSmall: h3(),
      titleLarge: bodyStrong(),
      titleMedium: bodyStrong(),
      titleSmall: bodyStrong(),
      bodyLarge: body(),
      bodyMedium: body(),
      bodySmall: bodySmall(),
      labelLarge: button(color: AppColors.textPrimary),
      labelMedium: monoLabel(),
      labelSmall: mono(),
    );
  }
}

/// Typographie Kepler résolue pour le thème courant.
///
/// Obtenue via `AppText.of(context)`. Chaque méthode reprend la statique
/// correspondante mais substitue une couleur par défaut issue de
/// [KeplerColors] — donc correcte en clair comme en sombre.
///
/// Une couleur explicite reste possible et prioritaire :
/// `AppText.of(context).body(color: colors.error)`.
@immutable
class KeplerText {
  const KeplerText._(this.colors);

  /// Palette résolue — évite un second `KeplerColors.of(context)` sur place.
  final KeplerColors colors;

  // ---- Source Serif 4 : titres éditoriaux ----

  TextStyle heroDisplay({Color? color}) =>
      AppText.heroDisplay(color: color ?? colors.textPrimary);

  TextStyle heroItalic({Color? color}) =>
      AppText.heroItalic(color: color ?? colors.primary);

  TextStyle h1({Color? color}) => AppText.h1(color: color ?? colors.textPrimary);

  TextStyle h1Italic({Color? color}) =>
      AppText.h1Italic(color: color ?? colors.primary);

  TextStyle h2({Color? color}) => AppText.h2(color: color ?? colors.textPrimary);

  TextStyle h2Italic({Color? color}) =>
      AppText.h2Italic(color: color ?? colors.primary);

  TextStyle h3({Color? color}) => AppText.h3(color: color ?? colors.textPrimary);

  // ---- DM Sans : corps & UI ----

  TextStyle body({Color? color}) =>
      AppText.body(color: color ?? colors.textSecondary);

  TextStyle bodyStrong({Color? color}) =>
      AppText.bodyStrong(color: color ?? colors.textPrimary);

  TextStyle bodySmall({Color? color}) =>
      AppText.bodySmall(color: color ?? colors.textSecondary);

  /// Label de bouton : par défaut, la couleur du texte posé sur un fond accent.
  TextStyle button({Color? color}) =>
      AppText.button(color: color ?? colors.onAccentFill);

  // ---- Mono : labels, scores ----

  TextStyle mono({Color? color, double? size}) =>
      AppText.mono(color: color ?? colors.textTertiary, size: size);

  TextStyle monoLabel({Color? color}) =>
      AppText.monoLabel(color: color ?? colors.textTertiary);

  TextStyle monoScore({Color? color, double? size}) =>
      AppText.monoScore(color: color ?? colors.textPrimary, size: size);
}
