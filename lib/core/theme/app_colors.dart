import 'package:flutter/material.dart';

/// Palette de couleurs de l'application Mentality
///
/// Utilise Material Design 3 avec des couleurs accessibles
/// et adaptées à tous les groupes d'âge
class AppColors {
  AppColors._();

  // ========================================
  // COULEURS PRIMAIRES
  // ========================================

  /// Couleur primaire principale (violet/indigo pour intelligence)
  static const Color primary = Color(0xFF6366F1); // Indigo-500

  /// Variante plus claire de la couleur primaire
  static const Color primaryLight = Color(0xFF818CF8); // Indigo-400

  /// Variante plus foncée de la couleur primaire
  static const Color primaryDark = Color(0xFF4F46E5); // Indigo-600

  /// Couleur primaire conteneur
  static const Color primaryContainer = Color(0xFFE0E7FF); // Indigo-100

  // ========================================
  // COULEURS SECONDAIRES
  // ========================================

  /// Couleur secondaire (turquoise pour créativité)
  static const Color secondary = Color(0xFF06B6D4); // Cyan-500

  /// Variante claire
  static const Color secondaryLight = Color(0xFF22D3EE); // Cyan-400

  /// Variante foncée
  static const Color secondaryDark = Color(0xFF0891B2); // Cyan-600

  /// Couleur secondaire conteneur
  static const Color secondaryContainer = Color(0xFFCFFAFE); // Cyan-100

  // ========================================
  // COULEURS TERTIAIRES
  // ========================================

  /// Couleur tertiaire (rose pour engagement émotionnel)
  static const Color tertiary = Color(0xFFEC4899); // Pink-500

  /// Variante claire
  static const Color tertiaryLight = Color(0xFFF472B6); // Pink-400

  /// Variante foncée
  static const Color tertiaryDark = Color(0xFFDB2777); // Pink-600

  // ========================================
  // COULEURS DE FEEDBACK
  // ========================================

  /// Succès (vert)
  static const Color success = Color(0xFF10B981); // Green-500
  static const Color successLight = Color(0xFF34D399); // Green-400
  static const Color successContainer = Color(0xFFD1FAE5); // Green-100

  /// Erreur (rouge)
  static const Color error = Color(0xFFEF4444); // Red-500
  static const Color errorLight = Color(0xFFF87171); // Red-400
  static const Color errorContainer = Color(0xFFFEE2E2); // Red-100

  /// Avertissement (orange)
  static const Color warning = Color(0xFFF59E0B); // Amber-500
  static const Color warningLight = Color(0xFFFBBF24); // Amber-400
  static const Color warningContainer = Color(0xFFFEF3C7); // Amber-100

  /// Information (bleu)
  static const Color info = Color(0xFF3B82F6); // Blue-500
  static const Color infoLight = Color(0xFF60A5FA); // Blue-400
  static const Color infoContainer = Color(0xFFDBEAFE); // Blue-100

  // ========================================
  // COULEURS NEUTRES
  // ========================================

  /// Blanc pur
  static const Color white = Color(0xFFFFFFFF);

  /// Noir pur
  static const Color black = Color(0xFF000000);

  /// Échelle de gris
  static const Color grey50 = Color(0xFFF9FAFB);
  static const Color grey100 = Color(0xFFF3F4F6);
  static const Color grey200 = Color(0xFFE5E7EB);
  static const Color grey300 = Color(0xFFD1D5DB);
  static const Color grey400 = Color(0xFF9CA3AF);
  static const Color grey500 = Color(0xFF6B7280);
  static const Color grey600 = Color(0xFF4B5563);
  static const Color grey700 = Color(0xFF374151);
  static const Color grey800 = Color(0xFF1F2937);
  static const Color grey900 = Color(0xFF111827);

  // ========================================
  // COULEURS DE SURFACE (Light Mode)
  // ========================================

  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF3F4F6);

  // ========================================
  // COULEURS DE SURFACE (Dark Mode)
  // ========================================

  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color surfaceVariantDark = Color(0xFF2C2C2C);

  // ========================================
  // COULEURS PAR INDICE COGNITIF
  // ========================================

  /// Compréhension Verbale (bleu-violet)
  static const Color indexVCI = Color(0xFF8B5CF6); // Violet-500

  /// Visuo-Spatial (cyan)
  static const Color indexVSI = Color(0xFF06B6D4); // Cyan-500

  /// Raisonnement Fluide (indigo)
  static const Color indexFRI = Color(0xFF6366F1); // Indigo-500

  /// Mémoire de Travail (vert)
  static const Color indexWMI = Color(0xFF10B981); // Green-500

  /// Vitesse de Traitement (orange)
  static const Color indexPSI = Color(0xFFF59E0B); // Amber-500

  /// QI Total (violet foncé)
  static const Color indexFSIQ = Color(0xFF7C3AED); // Violet-600

  // ========================================
  // COULEURS PAR GROUPE D'ÂGE (UI)
  // ========================================

  /// Préscolaire (couleurs vives et joyeuses)
  static const Color preschoolPrimary = Color(0xFFF59E0B); // Orange vif
  static const Color preschoolSecondary = Color(0xFFEC4899); // Rose
  static const Color preschoolAccent = Color(0xFF10B981); // Vert

  /// Enfant (couleurs énergiques)
  static const Color childPrimary = Color(0xFF3B82F6); // Bleu
  static const Color childSecondary = Color(0xFF8B5CF6); // Violet
  static const Color childAccent = Color(0xFF06B6D4); // Cyan

  /// Adulte (couleurs professionnelles)
  static const Color adultPrimary = Color(0xFF6366F1); // Indigo
  static const Color adultSecondary = Color(0xFF0891B2); // Cyan foncé
  static const Color adultAccent = Color(0xFF64748B); // Slate

  // ========================================
  // GRADIENTS
  // ========================================

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [success, successLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient preschoolGradient = LinearGradient(
    colors: [preschoolPrimary, preschoolSecondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ========================================
  // COULEURS DE CLASSIFICATION QI
  // ========================================

  /// Extrêmement bas (<70)
  static const Color iqExtremelyLow = Color(0xFFDC2626); // Red-600

  /// Limite (70-79)
  static const Color iqBorderline = Color(0xFFF59E0B); // Amber-500

  /// Moyen faible (80-89)
  static const Color iqLowAverage = Color(0xFFFBBF24); // Amber-400

  /// Moyen (90-109)
  static const Color iqAverage = Color(0xFF10B981); // Green-500

  /// Moyen fort (110-119)
  static const Color iqHighAverage = Color(0xFF06B6D4); // Cyan-500

  /// Supérieur (120-129)
  static const Color iqSuperior = Color(0xFF3B82F6); // Blue-500

  /// Très supérieur (130+)
  static const Color iqVerySuperior = Color(0xFF8B5CF6); // Violet-500

  // ========================================
  // OPACITÉS
  // ========================================

  static const double opacityDisabled = 0.38;
  static const double opacityMedium = 0.60;
  static const double opacityHigh = 0.87;

  // ========================================
  // MÉTHODES UTILITAIRES
  // ========================================

  /// Retourne la couleur d'un indice par son code
  static Color getIndexColor(String indexCode) {
    switch (indexCode) {
      case 'VCI':
        return indexVCI;
      case 'VSI':
        return indexVSI;
      case 'FRI':
        return indexFRI;
      case 'WMI':
        return indexWMI;
      case 'PSI':
        return indexPSI;
      case 'FSIQ':
        return indexFSIQ;
      default:
        return grey500;
    }
  }

  /// Retourne la couleur selon le score QI
  static Color getIQClassificationColor(int iq) {
    if (iq < 70) return iqExtremelyLow;
    if (iq < 80) return iqBorderline;
    if (iq < 90) return iqLowAverage;
    if (iq < 110) return iqAverage;
    if (iq < 120) return iqHighAverage;
    if (iq < 130) return iqSuperior;
    return iqVerySuperior;
  }

  /// Retourne les couleurs par groupe d'âge
  static ColorScheme getAgeGroupColors(String ageGroup) {
    switch (ageGroup) {
      case 'preschool':
        return const ColorScheme.light(
          primary: preschoolPrimary,
          secondary: preschoolSecondary,
          tertiary: preschoolAccent,
        );
      case 'child':
        return const ColorScheme.light(
          primary: childPrimary,
          secondary: childSecondary,
          tertiary: childAccent,
        );
      default:
        return const ColorScheme.light(
          primary: adultPrimary,
          secondary: adultSecondary,
          tertiary: adultAccent,
        );
    }
  }
}
