import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typographie Kepler — Mental E.T.
///
/// Trois familles :
/// - Source Serif 4 → titres éditoriaux, italiques d'accent
/// - DM Sans       → corps de texte, UI
/// - DM Mono       → labels, signature §, scores psychométriques
class AppText {
  AppText._();

  // ---- Source Serif 4 : titres éditoriaux ----

  static TextStyle heroDisplay({Color? color}) => GoogleFonts.sourceSerif4(
        fontSize: 40.sp,
        height: 1.1,
        fontWeight: FontWeight.w500,
        letterSpacing: -1.2,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle heroItalic({Color? color}) => GoogleFonts.sourceSerif4(
        fontSize: 40.sp,
        height: 1.1,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w500,
        letterSpacing: -1.2,
        color: color ?? AppColors.primary,
      );

  static TextStyle h1({Color? color}) => GoogleFonts.sourceSerif4(
        fontSize: 30.sp,
        height: 1.15,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.6,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle h1Italic({Color? color}) => GoogleFonts.sourceSerif4(
        fontSize: 30.sp,
        height: 1.15,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.6,
        color: color ?? AppColors.primary,
      );

  static TextStyle h2({Color? color}) => GoogleFonts.sourceSerif4(
        fontSize: 24.sp,
        height: 1.2,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.3,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle h2Italic({Color? color}) => GoogleFonts.sourceSerif4(
        fontSize: 24.sp,
        height: 1.2,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.3,
        color: color ?? AppColors.primary,
      );

  static TextStyle h3({Color? color}) => GoogleFonts.sourceSerif4(
        fontSize: 19.sp,
        height: 1.25,
        fontWeight: FontWeight.w500,
        color: color ?? AppColors.textPrimary,
      );

  // ---- DM Sans : corps & UI ----

  static TextStyle body({Color? color}) => GoogleFonts.dmSans(
        fontSize: 15.sp,
        height: 1.65,
        fontWeight: FontWeight.w400,
        color: color ?? AppColors.textSecondary,
      );

  static TextStyle bodyStrong({Color? color}) => GoogleFonts.dmSans(
        fontSize: 15.sp,
        height: 1.55,
        fontWeight: FontWeight.w500,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle bodySmall({Color? color}) => GoogleFonts.dmSans(
        fontSize: 13.sp,
        height: 1.55,
        fontWeight: FontWeight.w400,
        color: color ?? AppColors.textSecondary,
      );

  static TextStyle button({Color? color}) => GoogleFonts.dmSans(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: color ?? AppColors.background,
      );

  // ---- DM Mono : labels, §, scores ----

  static TextStyle mono({Color? color, double? size}) => GoogleFonts.robotoMono(
        fontSize: size ?? 11.sp,
        fontWeight: FontWeight.w500,
        letterSpacing: 2.0,
        color: color ?? AppColors.textTertiary,
      );

  static TextStyle monoLabel({Color? color}) => GoogleFonts.robotoMono(
        fontSize: 11.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: 2.4,
        color: color ?? AppColors.textTertiary,
      );

  static TextStyle monoScore({Color? color, double? size}) =>
      GoogleFonts.robotoMono(
        fontSize: size ?? 28.sp,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.5,
        color: color ?? AppColors.textPrimary,
      );

  /// TextTheme Material 3 dérivé de Kepler — appliqué globalement via ThemeData.
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
