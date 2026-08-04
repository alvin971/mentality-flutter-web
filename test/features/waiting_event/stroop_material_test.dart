// Le matériel du test : trois encres, trois noms, six langues.
//
// Deux familles de gardes, pour deux erreurs qui ne se verraient pas :
//
// · PARITÉ SIX LANGUES. Un nom de couleur manquant ne casserait rien — `QText`
//   se replie sur l'anglais. Le bouton afficherait « BLACK » au milieu d'un
//   écran allemand, et la personne répondrait quand même. Seul le temps de
//   réaction en garderait la trace.
// · SÉPARABILITÉ DES ENCRES. Le jour où quelqu'un remplacera le noir par un
//   vert « plus joli », le rouge-vert reviendra, et 8 % des joueurs mesureront
//   leur daltonisme au lieu de leur inhibition.

import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/core/widgets/test/kepler_stimulus_surface.dart';
import 'package:mentality/features/waiting_event/_shared/domain/models/q_text.dart';
import 'package:mentality/features/waiting_event/stroop/data/stroop_material.dart';
import 'package:mentality/features/waiting_event/stroop/domain/models/stroop_trial.dart';

// --- constantes APCA 0.1.9 (W3 mode), recopiées de palette_contrast_test ---
// Les helpers de test ne sont pas partagés dans ce dépôt : chaque fichier
// redéfinit les siens.
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

/// Simulation grossière de la vision dichromate, dans l'esprit de Viénot,
/// Brettel & Mollon : les deux cônes confondus ramènent la couleur sur un plan.
/// Une approximation suffit ici — on ne cherche pas à rendre l'image telle
/// qu'elle est perçue, seulement à repérer deux teintes qui s'effondreraient
/// l'une sur l'autre.
Color _deuteranope(Color c) {
  final r = c.r, g = c.g, b = c.b;
  final r2 = 0.625 * r + 0.375 * g;
  final g2 = 0.700 * r + 0.300 * g;
  return Color.fromARGB(255, (r2 * 255).round().clamp(0, 255),
      (g2 * 255).round().clamp(0, 255), (b * 255).round().clamp(0, 255));
}

Color _protanope(Color c) {
  final r = c.r, g = c.g, b = c.b;
  final r2 = 0.567 * r + 0.433 * g;
  final g2 = 0.558 * r + 0.442 * g;
  return Color.fromARGB(255, (r2 * 255).round().clamp(0, 255),
      (g2 * 255).round().clamp(0, 255), (b * 255).round().clamp(0, 255));
}

/// Distance euclidienne dans un espace RVB pondéré à l'œil — assez pour dire
/// « ces deux-là ne sont plus distinguables ».
double _ecart(Color a, Color b) {
  final dr = (a.r - b.r) * 255, dg = (a.g - b.g) * 255, db = (a.b - b.b) * 255;
  return math.sqrt(2 * dr * dr + 4 * dg * dg + 3 * db * db);
}

void main() {
  group('parité six langues', () {
    test('chaque nom de couleur existe dans les six langues', () {
      for (final encre in StroopInk.values) {
        final nom = StroopMaterial.nameOf(encre);
        expect(nom.missingLocales, isEmpty,
            reason: '$encre : ${nom.missingLocales} manquantes — le repli sur '
                'l\'anglais afficherait un mot étranger dont seul le temps de '
                'réaction garderait la trace');
      }
    });

    test('dans une langue donnée, les trois noms sont distincts', () {
      for (final tag in QText.locales) {
        final noms = {
          for (final encre in StroopInk.values)
            StroopMaterial.nameOf(encre).raw(tag)
        };
        expect(noms, hasLength(StroopInk.values.length),
            reason: 'deux boutons au même libellé en « $tag » : la réponse '
                'devient ambiguë');
      }
    });

    test('aucun nom n\'est vide ni bourré d\'espaces', () {
      for (final encre in StroopInk.values) {
        for (final tag in QText.locales) {
          final mot = StroopMaterial.nameOf(encre).raw(tag)!;
          expect(mot.trim(), mot);
          expect(mot, isNotEmpty);
        }
      }
    });
  });

  group('les encres restent lisibles et distinctes', () {
    test('chaque encre contraste assez sur le panneau de stimulus', () {
      for (final encre in StroopInk.values) {
        final lc = apca(StroopMaterial.colorOf(encre),
                KeplerStimulusSurface.surface)
            .abs();
        // Seuil « grand texte » : le stimulus est rendu en heroDisplay.
        expect(lc, greaterThanOrEqualTo(60.0),
            reason: '$encre : Lc ${lc.toStringAsFixed(1)}. Sous ce seuil, le '
                'temps de réaction mesure l\'effort de VOIR, pas celui '
                'd\'inhiber');
      }
    });

    test('★ aucune paire d\'encres ne s\'effondre en vision dichromate', () {
      final paires = [
        for (var i = 0; i < StroopInk.values.length; i++)
          for (var j = i + 1; j < StroopInk.values.length; j++)
            (StroopInk.values[i], StroopInk.values[j])
      ];

      for (final (a, b) in paires) {
        final ca = StroopMaterial.colorOf(a), cb = StroopMaterial.colorOf(b);
        for (final (nom, filtre) in <(String, Color Function(Color))>[
          ('vision normale', (c) => c),
          ('deutéranopie', _deuteranope),
          ('protanopie', _protanope),
        ]) {
          expect(_ecart(filtre(ca), filtre(cb)), greaterThan(120.0),
              reason: '$a et $b se confondent en $nom. C\'est exactement ce '
                  'que le couple rouge/vert du Stroop classique provoque : la '
                  'personne mesure alors son daltonisme, pas son inhibition');
        }
      }
    });
  });

  test('le motif neutre ne ressemble à aucun nom de couleur', () {
    for (final encre in StroopInk.values) {
      for (final tag in QText.locales) {
        expect(StroopMaterial.nameOf(encre).raw(tag),
            isNot(kStroopNeutralGlyphs),
            reason: 'la condition neutre doit être SANS mot à lire');
      }
    }
  });
}
