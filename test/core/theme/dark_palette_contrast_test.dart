import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/core/theme/app_colors.dart';
import 'package:mentality/core/theme/kepler_colors.dart';

/// Verrou de contraste de la palette sombre.
///
/// ## Pourquoi APCA et pas le ratio WCAG 2.x
///
/// Le ratio WCAG est symétrique : il traite « texte clair sur fond sombre »
/// comme « texte sombre sur fond clair ». La perception, elle, ne l'est pas.
/// WCAG 2.x SURESTIME donc systématiquement le contraste en mode sombre.
///
/// Concrètement, avant la refonte du 2026-07-25 la palette affichait des
/// valeurs « conformes AA » qui étaient en réalité sous le seuil de lecture :
///
/// | jeton               | WCAG 2.x | APCA réel | verdict           |
/// |---------------------|----------|-----------|-------------------|
/// | textTertiaryDark    | 4.65:1   | Lc 37     | illisible en 11sp |
/// | textSecondaryDark   | 9.06:1   | Lc 67     | sous le seuil     |
/// | primaryLightDark    | 6.93:1   | Lc 53     | sous le seuil     |
/// | bordure blanc 20 %  | 1.72:1   | Lc 0      | invisible         |
///
/// Un test basé sur WCAG aurait laissé passer les quatre. C'est pour ça que
/// ce fichier implémente APCA.
///
/// ## Seuils appliqués (|Lc|)
///
/// * 90 — corps de texte, cible préférée
/// * 75 — corps de texte, minimum
/// * 60 — texte de grande taille
/// * 30 — éléments non textuels : bordures, filets, fills
/// * 15 — seuil d'invisibilité
///
/// Toucher une constante de `AppColors.*Dark` sans faire tourner ce test,
/// c'est rouvrir la régression.

// --- constantes APCA 0.1.9 (W3 mode) ---
const _mainTrc = 2.4;
const _rCo = 0.2126729, _gCo = 0.7151522, _bCo = 0.0721750;
const _normBg = 0.56, _normTxt = 0.57;
const _revTxt = 0.62, _revBg = 0.65;
const _blkThrs = 0.022, _blkClmp = 1.414;
const _scale = 1.14, _loOffset = 0.027;
const _deltaYMin = 0.0005, _loClip = 0.1;

double _luminance(Color c) {
  double ch(int v) => math.pow(v / 255.0, _mainTrc).toDouble();
  final y = _rCo * ch((c.r * 255).round()) +
      _gCo * ch((c.g * 255).round()) +
      _bCo * ch((c.b * 255).round());
  return y < _blkThrs ? y + math.pow(_blkThrs - y, _blkClmp).toDouble() : y;
}

/// Lc APCA signé. Négatif = texte clair sur fond sombre (polarité inverse).
double apca(Color text, Color background) {
  final yTxt = _luminance(text);
  final yBg = _luminance(background);
  if ((yBg - yTxt).abs() < _deltaYMin) return 0;
  if (yBg > yTxt) {
    final s = (math.pow(yBg, _normBg) - math.pow(yTxt, _normTxt)) * _scale;
    return s < _loClip ? 0 : (s - _loOffset) * 100;
  }
  final s = (math.pow(yBg, _revBg) - math.pow(yTxt, _revTxt)) * _scale;
  return s > -_loClip ? 0 : (s + _loOffset) * 100;
}

/// Usage d'un couple, qui détermine le seuil exigé.
enum Usage {
  /// Corps de texte : 75.
  body(75),

  /// Texte de grande taille (titres, gros scores) : 60.
  large(60),

  /// Élément non textuel : bordure, filet, fill : 30.
  ui(30);

  const Usage(this.minLc);
  final int minLc;
}

void expectContrast(String label, Color text, Color bg, Usage usage) {
  final lc = apca(text, bg).abs();
  expect(
    lc,
    greaterThanOrEqualTo(usage.minLc.toDouble()),
    reason: '$label : Lc ${lc.toStringAsFixed(1)} < seuil ${usage.minLc} '
        '(${usage.name}). Une couleur de la palette sombre est repassée sous '
        'le seuil de perception — voir app_colors.dart.',
  );
}

void main() {
  final dark = KeplerColors.forBrightness(Brightness.dark);

  group('Palette sombre — texte', () {
    test('corps principal atteint la cible préférée (Lc 90)', () {
      expect(apca(dark.textPrimary, dark.cardSurface).abs(),
          greaterThanOrEqualTo(88.0));
      expect(apca(dark.textPrimary, dark.background).abs(),
          greaterThanOrEqualTo(88.0));
      expect(apca(dark.textPrimary, dark.raised).abs(),
          greaterThanOrEqualTo(85.0));
    });

    test('corps secondaire lisible sur les trois surfaces', () {
      expectContrast('secondaire/carte', dark.textSecondary, dark.cardSurface,
          Usage.body);
      expectContrast(
          'secondaire/fond', dark.textSecondary, dark.background, Usage.body);
      expectContrast(
          'secondaire/raised', dark.textSecondary, dark.raised, Usage.body);
    });

    test('tertiaire tient le seuil grand texte — régression Lc 37', () {
      expectContrast(
          'tertiaire/carte', dark.textTertiary, dark.cardSurface, Usage.large);
      expectContrast(
          'tertiaire/fond', dark.textTertiary, dark.background, Usage.large);
    });
  });

  group('Palette sombre — marque et feedback', () {
    test('accent lisible en texte', () {
      expectContrast('accent/carte', dark.primary, dark.cardSurface, Usage.body);
      expectContrast('accent/fond', dark.primary, dark.background, Usage.body);
    });

    test('label de bouton lisible sur le fill accent', () {
      expectContrast('label/fill', dark.onAccentFill, dark.accentFill, Usage.body);
    });

    test('couleurs de feedback lisibles sur carte', () {
      expectContrast('success', dark.success, dark.cardSurface, Usage.body);
      expectContrast('error', dark.error, dark.cardSurface, Usage.body);
      expectContrast('warning', dark.warning, dark.cardSurface, Usage.body);
      expectContrast('info', dark.info, dark.cardSurface, Usage.body);
    });
  });

  group('Palette sombre — structure', () {
    test('bordures et filets existent pour l\'œil — régression Lc 0', () {
      expectContrast('bordure/carte', dark.border, dark.cardSurface, Usage.ui);
      expectContrast('bordure/fond', dark.border, dark.background, Usage.ui);
      expectContrast('divider/fond', dark.divider, dark.background, Usage.ui);
    });

    test('le fond n\'est jamais du noir pur (halation OLED)', () {
      expect(dark.background, isNot(equals(const Color(0xFF000000))));
      expect(_luminance(dark.background), greaterThan(0.0));
    });

    test('le texte principal n\'est jamais du blanc pur (halation)', () {
      expect(dark.textPrimary, isNot(equals(const Color(0xFFFFFFFF))));
    });
  });

  group('Indices cognitifs', () {
    final indices = <String, Color>{
      'VCI': AppColors.indexVCIDark,
      'VSI': AppColors.indexVSIDark,
      'FRI': AppColors.indexFRIDark,
      'WMI': AppColors.indexWMIDark,
      'PSI': AppColors.indexPSIDark,
      'FSIQ': AppColors.indexFSIQDark,
    };

    test('chaque indice est lisible sur carte et sur fond', () {
      indices.forEach((code, color) {
        expectContrast('$code/carte', color, AppColors.cardDark, Usage.body);
        expectContrast('$code/fond', color, AppColors.backgroundDark, Usage.body);
      });
    });

    test('accentForBrightness renvoie bien la variante sombre', () {
      expect(
        AppColors.accentForBrightness(AppColors.indexVCI, Brightness.dark),
        AppColors.indexVCIDark,
      );
      expect(
        AppColors.accentForBrightness(AppColors.indexVCI, Brightness.light),
        AppColors.indexVCI,
      );
    });
  });
}
