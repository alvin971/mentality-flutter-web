import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Carte de score prête à publier en story — 1080 × 1920 px une fois capturée.
///
/// ## Deux règles de composition, et pourquoi
///
/// **1. Aucune dépendance au thème.** L'image exportée doit être IDENTIQUE pour
/// tout le monde : deux personnes qui partagent le même score doivent produire
/// la même carte, quel que soit leur réglage d'affichage. Toutes les couleurs
/// sont donc des constantes de ce fichier, jamais `KeplerColors.of(context)`.
/// Même intention que [KeplerStimulusSurface], pour une raison différente : là
/// c'était la difficulté perceptive, ici c'est l'identité de marque.
///
/// **2. Aucune dépendance à l'écran.** Pas de `.w` / `.h` / `.sp`
/// (flutter_screenutil), et donc pas de [AppText] — dont toutes les tailles
/// passent par `.sp`. Ces unités dérivent de la taille de l'appareil : les
/// utiliser ici produirait une image DIFFÉRENTE selon le téléphone, alors que
/// la capture se fait à une taille fixe. Tout est en pixels logiques bruts.
///
/// ## Zone utile
///
/// Instagram recouvre environ 250 px en haut et 250 px en bas d'une story avec
/// sa propre interface. Rien d'important ne doit sortir des 1080 × 1400 px
/// centraux — soit, à l'échelle logique de ce widget, la bande y ∈ [87, 553].
/// Deux zones calmes encadrent le contenu à l'intérieur de cette bande, pour
/// que l'utilisateur puisse y poser son texte ou ses stickers sans rien écraser.
///
/// Aucune donnée démographique (sexe, année de naissance, région) n'apparaît :
/// une story est publique.
class ScoreShareCard extends StatelessWidget {
  const ScoreShareCard({
    super.key,
    required this.iq,
    required this.percentile,
    required this.classification,
    required this.inviteCode,
    required this.scoreLabel,
    required this.percentileLabel,
    required this.codeLabel,
    required this.siteLabel,
  });

  final int iq;
  final int percentile;
  final String classification;
  final String inviteCode;

  // Libellés déjà traduits — le widget ne touche pas à l10n, ce qui le rend
  // rendable tel quel dans un test sans arbre de localisation.
  final String scoreLabel;
  final String percentileLabel;
  final String codeLabel;
  final String siteLabel;

  /// Taille LOGIQUE de la carte. Capturée à `pixelRatio` 3 → 1080 × 1920 px.
  static const double width = 360;
  static const double height = 640;
  static const double capturePixelRatio = 3;

  /// Bandeau réservé à l'interface d'Instagram, en haut comme en bas.
  ///
  /// Instagram en recouvre environ 250 px ; on en réserve 260, ce qui laisse
  /// une zone utile de 1920 − 520 = **1400 px** exactement, et une marge de
  /// sécurité de 10 px de chaque côté.
  static const double unsafeBandPx = 260;
  static const double unsafeBand = unsafeBandPx / capturePixelRatio;

  /// Hauteur, en pixels de l'image finale, de la zone jamais recouverte.
  static const double safeHeightPx = height * capturePixelRatio - 2 * unsafeBandPx;

  /// Poids des zones calmes (haut/bas) dans la répartition de l'espace libre.
  ///
  /// Ce sont des [Spacer], pas des hauteurs fixes : l'espace restant se
  /// redistribue au lieu de déborder. Les métriques de police varient (police
  /// de repli quand les polices Google ne sont pas chargées, réglage
  /// d'accessibilité système) et une composition rigide finirait par rogner du
  /// contenu sur certains appareils — précisément ce qu'on ne peut pas voir
  /// avant que l'image ne soit publiée.
  static const int quietZoneFlex = 2;
  static const int gapFlex = 3;

  // ---- Palette FIXE. Ne pas thématiser : ce serait rouvrir le problème. ----

  /// Fond crème — assez sourd pour ne pas éblouir, assez clair pour ressortir
  /// sur la plupart des fonds de story.
  static const Color paper = Color(0xFFF4F2EC);

  /// Vert forêt de la marque (miroir de AppColors.primary).
  static const Color brand = Color(0xFF446D41);

  /// Encre principale.
  static const Color ink = Color(0xFF16181A);

  /// Encre secondaire, pour les libellés.
  static const Color inkSoft = Color(0xFF5C6360);

  /// Filets et séparateurs.
  static const Color rule = Color(0xFFD9D8D2);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ColoredBox(
        color: paper,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 36,
            vertical: unsafeBand,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Zone calme haute — délibérément vide, pour les stickers.
              const Spacer(flex: quietZoneFlex),
              _wordmark(),
              const Spacer(flex: gapFlex),
              _score(),
              const Spacer(flex: gapFlex),
              _invite(),
              // Zone calme basse — délibérément vide.
              const Spacer(flex: quietZoneFlex),
            ],
          ),
        ),
      ),
    );
  }

  /// Mot-symbole typographique : le dépôt n'a pas d'asset de logo, et un
  /// lettrage net à 1080 px vaut mieux qu'une icône d'application agrandie.
  Widget _wordmark() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'MENTAL E.T.',
          style: GoogleFonts.robotoMono(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: 4.5,
            color: brand,
          ),
        ),
        const SizedBox(height: 12),
        Container(width: 46, height: 1.5, color: brand),
      ],
    );
  }

  Widget _score() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          scoreLabel.toUpperCase(),
          textAlign: TextAlign.center,
          style: GoogleFonts.robotoMono(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 2.4,
            color: inkSoft,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '$iq',
          style: GoogleFonts.robotoMono(
            fontSize: 84,
            height: 1,
            fontWeight: FontWeight.w700,
            letterSpacing: -3,
            color: brand,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          classification,
          textAlign: TextAlign.center,
          style: GoogleFonts.sourceSerif4(
            fontSize: 22,
            height: 1.2,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w500,
            color: ink,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          percentileLabel,
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(
            fontSize: 14,
            height: 1.35,
            color: inkSoft,
          ),
        ),
      ],
    );
  }

  /// Code d'invitation + URL courte. Pas de QR code : celui qui regarde tient
  /// déjà dans la main le téléphone avec lequel il devrait le scanner.
  Widget _invite() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 120, height: 1, color: rule),
        const SizedBox(height: 20),
        Text(
          codeLabel.toUpperCase(),
          textAlign: TextAlign.center,
          style: GoogleFonts.robotoMono(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 2.4,
            color: inkSoft,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: brand, width: 1.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            inviteCode.toUpperCase(),
            style: GoogleFonts.robotoMono(
              fontSize: 28,
              height: 1,
              fontWeight: FontWeight.w700,
              letterSpacing: 5,
              color: brand,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          siteLabel,
          style: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
            color: ink,
          ),
        ),
      ],
    );
  }
}
