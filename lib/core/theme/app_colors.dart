import 'package:flutter/material.dart';

/// Palette de couleurs de l'application Mental E.T.
///
/// Utilise Material Design 3 avec des couleurs accessibles
/// et adaptées à tous les groupes d'âge
class AppColors {
  AppColors._();

  // ========================================
  // COULEURS PRIMAIRES
  // ========================================

  /// Couleur primaire principale (vert forêt — style Kepler)
  static const Color primary = Color(0xFF4D7C4A); // Vert forêt

  /// Variante plus claire de la couleur primaire
  static const Color primaryLight = Color(0xFF6AB060); // Vert clair

  /// Variante plus foncée de la couleur primaire
  static const Color primaryDark = Color(0xFF22805A); // Vert foncé

  /// Couleur primaire conteneur
  static const Color primaryContainer = Color(0xFFD7E8D2); // Vert-crème

  // ========================================
  // COULEURS SECONDAIRES
  // ========================================

  /// Couleur secondaire (vert profond)
  static const Color secondary = Color(0xFF22805A);

  /// Variante claire
  static const Color secondaryLight = Color(0xFF4D7C4A);

  /// Variante foncée
  static const Color secondaryDark = Color(0xFF0B3D2E);

  /// Couleur secondaire conteneur
  static const Color secondaryContainer = Color(0xFFEEF1EC); // Vert-crème clair

  // ========================================
  // COULEURS TERTIAIRES
  // ========================================

  /// Couleur tertiaire (olive chaud — accent analogique)
  static const Color tertiary = Color(0xFF8A7C4A);

  /// Variante claire
  static const Color tertiaryLight = Color(0xFFB8A86A);

  /// Variante foncée
  static const Color tertiaryDark = Color(0xFF5C5030);

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

  static const Color background = Color(0xFFFAF9F6); // Crème chaud Kepler
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFEEF1EC); // Vert-crème Kepler

  // ========================================
  // COULEURS DE SURFACE (Dark Mode)
  // ========================================

  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1C1C1C);
  static const Color surfaceVariantDark = Color(0xFF2C2C2C);
  static const Color cardDark = Color(0xFF1F1F1F);

  // ========================================
  // COULEURS TEXTE DARK (WCAG AA / AAA sur #121212)
  // ========================================

  /// Off-white — 14.5:1 sur #121212 (AAA)
  static const Color textPrimaryDark = Color(0xFFEEEEEE);

  /// Light grey — 8.4:1 (AA)
  static const Color textSecondaryDark = Color(0xFFC0C0C0);

  /// Mid grey — 4.6:1 (AA)
  static const Color textTertiaryDark = Color(0xFF888888);

  // ========================================
  // VARIANTES DARK DES INDICES COGNITIFS (+ luminance pour AA)
  // ========================================

  /// VCI dark — 7.8:1
  static const Color indexVCIDark = Color(0xFFA78BFF);

  /// VSI dark — 8.2:1
  static const Color indexVSIDark = Color(0xFF4EC9DD);

  /// FRI dark — 7.1:1
  static const Color indexFRIDark = Color(0xFF8A8DFF);

  /// WMI dark — 9.2:1
  static const Color indexWMIDark = Color(0xFF48D597);

  /// PSI dark — 12.1:1
  static const Color indexPSIDark = Color(0xFFFBD361);

  /// FSIQ dark — 8.5:1
  static const Color indexFSIQDark = Color(0xFF9D5FFF);

  // ========================================
  // FEEDBACK DARK (AA garanti)
  // ========================================

  static const Color successDark = Color(0xFF5FDD9C);
  static const Color errorDark = Color(0xFFFF9999);
  static const Color warningDark = Color(0xFFFFD580);
  static const Color infoDark = Color(0xFF89B4FF);
  static const Color primaryLightDark = Color(0xFF7CB58A);

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

  /// Adulte (palette verte Kepler)
  static const Color adultPrimary = Color(0xFF4D7C4A); // Vert forêt
  static const Color adultSecondary = Color(0xFF22805A); // Vert profond
  static const Color adultAccent = Color(0xFF7A9488); // Gris-vert

  // ========================================
  // COULEURS TEXTE KEPLER
  // ========================================

  /// Texte principal (vert forêt quasi-noir)
  static const Color textPrimary = Color(0xFF0B1F17);

  /// Texte secondaire
  static const Color textSecondary = Color(0xFF3D5248);

  /// Texte tertiaire (labels, méta)
  static const Color textTertiary = Color(0xFF7A9488);

  /// Fond accent translucide (50%)
  static const Color accentLight = Color(0x80D7E8D2);

  /// Bordure accent subtile (12%)
  static const Color accentDim = Color(0x1F4D7C4A);

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

  /// Retourne la variante dark d'une couleur d'indice cognitif (ou la couleur
  /// inchangée si elle n'a pas de variante dark définie).
  ///
  /// Permet aux pages de tests de rendre leur couleur d'accent avec un
  /// contraste suffisant en mode nuit sans modifier les call sites.
  static Color accentForBrightness(Color lightVariant, Brightness brightness) {
    if (brightness == Brightness.light) return lightVariant;
    if (lightVariant == indexVCI) return indexVCIDark;
    if (lightVariant == indexVSI) return indexVSIDark;
    if (lightVariant == indexFRI) return indexFRIDark;
    if (lightVariant == indexWMI) return indexWMIDark;
    if (lightVariant == indexPSI) return indexPSIDark;
    if (lightVariant == indexFSIQ) return indexFSIQDark;
    if (lightVariant == primary) return primaryLightDark;
    if (lightVariant == success) return successDark;
    if (lightVariant == error) return errorDark;
    if (lightVariant == warning) return warningDark;
    if (lightVariant == info) return infoDark;
    return lightVariant;
  }

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
