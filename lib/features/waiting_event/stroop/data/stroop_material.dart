// LE MATÉRIEL DU TEST : trois encres et leurs trois noms, en six langues.
//
// Pourquoi ce contenu ne va PAS dans les ARB, alors qu'il n'y a que trois mots.
// Un nom de couleur n'est pas du chrome : c'est le stimulus lui-même. Il suit
// donc la règle des items d'instrument — il vit en `data/`, sous `QText`, avec
// sa garde de parité six langues. Le chrome du jeu (consigne, boutons de
// navigation, libellés de résultat) reste, lui, dans les ARB.
//
// C'est aussi le seul contenu de ce lot, et il n'est sous AUCUNE licence : le
// matériel du Stroop, ce sont les couleurs. C'est ce qui rend ce jeu livrable
// pendant que les instruments validés attendent leurs items.
//
// ── Les encres ───────────────────────────────────────────────────────────────
//
// Elles sont posées sur `KeplerStimulusSurface` (fond #F2F1ED constant, quel
// que soit le thème), et choisies pour deux contraintes simultanées :
//
// · CONTRASTE sur ce fond clair. Un jaune y serait presque illisible ; le
//   temps de réaction mesurerait alors l'effort de voir, pas celui d'inhiber.
// · SÉPARABILITÉ EN VISION DICHROMATE. L'axe rouge-vert est écarté (voir
//   [StroopInk]) : les trois encres se distinguent sur l'axe bleu-jaune ou par
//   la seule luminance, donc restent nommables sans discrimination fine des
//   teintes.
//
// Deux gardes de test tiennent ces contraintes — l'une sur le contraste APCA
// contre le fond du panneau, l'autre sur l'écart entre encres.

import 'package:flutter/painting.dart' show Color;

import '../../_shared/domain/models/q_text.dart';
import '../domain/models/stroop_trial.dart';

abstract final class StroopMaterial {
  /// La couleur d'encre effectivement peinte à l'écran.
  static Color colorOf(StroopInk ink) => switch (ink) {
        StroopInk.rouge => const Color(0xFFC62828),
        StroopInk.bleu => const Color(0xFF1565C0),
        StroopInk.noir => const Color(0xFF16181A),
      };

  /// Le NOM de la couleur — affiché comme mot en condition de conflit, et
  /// comme libellé des trois boutons de réponse.
  ///
  /// Les majuscules sont dans la donnée, pas appliquées à l'affichage : en
  /// turc ou en allemand, une mise en majuscules automatique ne donne pas
  /// toujours ce qu'on croit, et le mot est ici du matériel — il s'écrit comme
  /// il a été écrit.
  static QText nameOf(StroopInk ink) => switch (ink) {
        StroopInk.rouge => const QText(
            fr: 'ROUGE',
            en: 'RED',
            enGB: 'RED',
            de: 'ROT',
            es: 'ROJO',
            pt: 'VERMELHO',
          ),
        StroopInk.bleu => const QText(
            fr: 'BLEU',
            en: 'BLUE',
            enGB: 'BLUE',
            de: 'BLAU',
            es: 'AZUL',
            pt: 'AZUL',
          ),
        StroopInk.noir => const QText(
            fr: 'NOIR',
            en: 'BLACK',
            enGB: 'BLACK',
            de: 'SCHWARZ',
            es: 'NEGRO',
            pt: 'PRETO',
          ),
      };
}
