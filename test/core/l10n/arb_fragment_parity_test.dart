// La garde qui manquait au gotcha du 2026-07-27.
//
// `l10n_fragments/_merge.py` ne met pas les ARB à jour : il les RÉGÉNÈRE de
// zéro (`merged = {lang: {"@@locale": lang}}` puis dump). Toute clé qui
// n'existe que dans `lib/l10n/*.arb` — parce qu'un écran a été écrit en
// éditant l'ARB directement — disparaît au merge suivant. Soixante clés ont
// frôlé l'effacement ainsi (tout le gate de déblocage, la carte de partage,
// l'historique verrouillé…), et rien ne l'aurait vu : la CI ne fait que du
// build, et un ARB régénéré compile parfaitement — il lui manque simplement
// des getters, donc la compilation casse APRÈS, loin de la cause.
//
// Ce test rejoue la résolution de `_merge.py` en Dart et compare le résultat
// aux six ARB livrés. Il attrape les deux sens de la dérive :
//
//   · ARB édité à la main       → clé présente dans l'ARB, absente du merge ;
//   · fragment édité sans merge → clé présente au merge, absente de l'ARB.
//
// Il refuse en plus les deux silences que `_merge.py` se contente d'imprimer
// sur la sortie standard (personne ne les lit) : une clé qui se REPLIE sur
// l'anglais faute de traduction, et une clé d'overlay qui ne correspond à
// aucun fragment.
//
// ⚠️ Ce test ne lit JAMAIS l'ARB pour construire l'attendu — sinon il
// vérifierait l'ARB contre lui-même. La source de vérité est
// `l10n_fragments/`, exactement comme pour `_merge.py`.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Les langues produites, dans l'ordre de `_merge.py`.
const _langues = ['fr', 'en', 'es', 'pt', 'de', 'en_GB'];

/// La langue qui porte les métadonnées (`@clé`).
const _gabarit = 'fr';

/// Les langues dont la traduction peut venir d'un fichier d'overlay.
const _languesOverlay = ['es', 'pt', 'de', 'en_GB'];

/// La chaîne de repli de `_merge.py`, à l'identique.
const _repli = ['en', 'fr'];

Map<String, dynamic> _lisJson(String chemin) =>
    jsonDecode(File(chemin).readAsStringSync()) as Map<String, dynamic>;

/// Les fragments dans l'ORDRE de `_merge.py` : `base.json` d'abord, puis A→Z.
///
/// L'ordre compte réellement : à clé dupliquée, la PREMIÈRE occurrence gagne
/// et les suivantes sont ignorées en bloc (y compris leurs traductions
/// inline).
List<String> _fragments() {
  final chemins = Directory('l10n_fragments')
      .listSync()
      .whereType<File>()
      .map((f) => f.path)
      .where((p) => p.endsWith('.json'))
      .where((p) => !p.split('/').last.startsWith('_'))
      .toList()
    ..sort();
  chemins.sort((a, b) {
    final aBase = a.endsWith('/base.json') ? 0 : 1;
    final bBase = b.endsWith('/base.json') ? 0 : 1;
    return aBase != bBase ? aBase - bBase : a.compareTo(b);
  });
  return chemins;
}

/// Une valeur non vide, ou `null`.
String? _texte(Object? valeur) {
  if (valeur is! String || valeur.isEmpty) return null;
  return valeur;
}

/// Le résultat d'une résolution : la valeur retenue, et si elle vient
/// VRAIMENT d'une traduction (par opposition à un repli silencieux).
typedef _Resolution = ({String valeur, bool traduite});

_Resolution _valeurPour(
  Map<String, dynamic> entree,
  String clef,
  String langue,
  Map<String, Map<String, dynamic>> overlays,
) {
  final inline = _texte(entree[langue]);
  if (inline != null) return (valeur: inline, traduite: true);

  final overlay = _texte(overlays[langue]?[clef]);
  if (overlay != null) return (valeur: overlay, traduite: true);

  for (final fb in _repli) {
    final v = _texte(entree[fb]);
    if (v != null) return (valeur: v, traduite: false);
  }
  for (final v in entree.values) {
    final t = _texte(v);
    if (t != null) return (valeur: t, traduite: false);
  }
  return (valeur: '', traduite: false);
}

/// Ce que `_merge.py` écrirait, calculé depuis les fragments seuls.
class _Merge {
  final Map<String, Map<String, String>> parLangue = {
    for (final l in _langues) l: {},
  };

  /// `@clé` → métadonnées, pour le seul gabarit.
  final Map<String, Map<String, dynamic>> metadonnees = {};

  /// clé → fichier, pour les clés vues deux fois avec un texte `fr` différent
  /// (`_merge.py` sort en erreur 2 dans ce cas).
  final List<String> collisions = [];

  /// « clé (langue) » pour toute clé qui se replie faute de traduction.
  final List<String> replis = [];

  /// « clé (langue) » pour toute clé d'overlay sans fragment correspondant.
  final List<String> overlaysOrphelins = [];
}

_Merge _rejoueLeMerge() {
  final overlays = <String, Map<String, dynamic>>{
    for (final l in _languesOverlay)
      l: File('l10n_fragments/translations/$l.json').existsSync()
          ? _lisJson('l10n_fragments/translations/$l.json')
          : <String, dynamic>{},
  };

  final out = _Merge();
  final vues = <String, String>{}; // clé → texte fr, pour les collisions

  for (final chemin in _fragments()) {
    final fragment = _lisJson(chemin);
    fragment.forEach((clef, brut) {
      if (clef.isEmpty || clef == 'maCle' || clef.startsWith('@')) return;
      final entree = brut as Map<String, dynamic>;
      final fr = (entree['fr'] ?? entree['en'] ?? '') as String;

      if (vues.containsKey(clef)) {
        if (vues[clef] != fr) {
          out.collisions.add('$clef (${chemin.split('/').last})');
        }
        return; // première occurrence gagne — le reste est ignoré en bloc
      }
      vues[clef] = fr;

      for (final langue in _langues) {
        final r = _valeurPour(entree, clef, langue, overlays);
        out.parLangue[langue]![clef] = r.valeur;
        if (langue != _gabarit && !r.traduite) {
          out.replis.add('$clef ($langue)');
        }
      }

      final placeholders = entree['placeholders'] as Map<String, dynamic>?;
      final desc = entree['desc'] as String?;
      if (placeholders != null || (desc != null && desc.isNotEmpty)) {
        out.metadonnees['@$clef'] = {
          if (desc != null && desc.isNotEmpty) 'description': desc,
          if (placeholders != null)
            'placeholders': {
              for (final e in placeholders.entries) e.key: {'type': e.value},
            },
        };
      }
    });
  }

  for (final langue in _languesOverlay) {
    for (final clef in overlays[langue]!.keys) {
      if (!vues.containsKey(clef)) {
        out.overlaysOrphelins.add('$clef ($langue)');
      }
    }
  }

  return out;
}

void main() {
  final merge = _rejoueLeMerge();

  test('les fragments se mergent sans collision', () {
    // `_merge.py` sort en code 2 sur une collision et n'écrit AUCUN ARB : la
    // même clé avec deux textes français différents laisse donc les six ARB
    // dans leur état précédent, sans que rien ne le signale.
    expect(merge.collisions, isEmpty,
        reason: 'même clé, texte fr différent :\n'
            '${merge.collisions.join("\n")}');
  });

  for (final langue in _langues) {
    group('app_$langue.arb', () {
      final arb = _lisJson('lib/l10n/app_$langue.arb');
      final attendu = merge.parLangue[langue]!;
      final reelles = arb.keys.where((k) => !k.startsWith('@')).toSet();

      test('aucune clé ne vit QUE dans l\'ARB (le prochain merge l\'effacerait)',
          () {
        final orphelines = reelles.difference(attendu.keys.toSet()).toList()
          ..sort();
        expect(orphelines, isEmpty,
            reason: '${orphelines.length} clé(s) absentes de '
                'l\'l10n_fragments/ : le prochain `_merge.py` les supprimerait '
                'en silence et la compilation casserait sur des getters '
                'disparus. Rapatrie-les dans un fragment (fr + en + desc + '
                'placeholders) puis dans les overlays.\n'
                '${orphelines.take(20).join(", ")}');
      });

      test('aucune clé des fragments ne manque à l\'ARB (merge non rejoué)',
          () {
        final manquantes = attendu.keys.toSet().difference(reelles).toList()
          ..sort();
        expect(manquantes, isEmpty,
            reason: '${manquantes.length} clé(s) présentes dans les fragments '
                'mais absentes de l\'ARB : lance `python3 '
                'l10n_fragments/_merge.py` puis `flutter gen-l10n`.\n'
                '${manquantes.take(20).join(", ")}');
      });

      test('chaque valeur livrée est exactement celle que le merge produirait',
          () {
        // Le cas le plus vicieux du gotcha : la clé existe des deux côtés,
        // mais l'ARB livré dit « 60 à 90 minutes » là où le fragment dit
        // encore « 30 à 45 ». Le merge REGRESSERAIT la durée affichée du
        // bilan sans rien casser.
        final divergentes = <String>[];
        for (final clef in reelles.intersection(attendu.keys.toSet())) {
          if (arb[clef] != attendu[clef]) {
            divergentes.add(
                '$clef : ARB « ${arb[clef]} » ≠ fragment « ${attendu[clef]} »');
          }
        }
        expect(divergentes, isEmpty,
            reason: '${divergentes.length} valeur(s) divergentes — la valeur '
                'LIVRÉE fait foi : réaligne le fragment ou l\'overlay dessus.'
                '\n${divergentes.take(10).join("\n")}');
      });
    });
  }

  test('les métadonnées du gabarit sont celles des fragments', () {
    // `desc` et `placeholders` ne vivent que dans app_fr.arb. Un placeholder
    // perdu ne casse pas le merge : il casse `flutter gen-l10n`, plus tard.
    final arb = _lisJson('lib/l10n/app_$_gabarit.arb');
    final reelles = {
      for (final e in arb.entries)
        if (e.key.startsWith('@') && e.key != '@@locale') e.key: e.value,
    };
    expect(reelles.keys.toSet(), merge.metadonnees.keys.toSet(),
        reason: 'métadonnées en trop ou manquantes dans app_fr.arb');
    for (final clef in merge.metadonnees.keys) {
      expect(reelles[clef], merge.metadonnees[clef], reason: 'métadonnées $clef');
    }
  });

  test('aucune clé ne se replie sur une autre langue', () {
    // Un repli est INVISIBLE : l'écran s'affiche, en anglais, au milieu d'une
    // app allemande. `_merge.py` l'imprime dans un rapport que personne ne
    // lit. C'est la même faille que la garde de parité des révélations
    // (reveal_page_test), généralisée aux 1034 clés.
    expect(merge.replis, isEmpty,
        reason: '${merge.replis.length} clé(s) non traduites — ajoute-les à '
            'l\'overlay de leur langue (l10n_fragments/translations/) :\n'
            '${merge.replis.take(30).join("\n")}');
  });

  test('aucune clé d\'overlay ne pointe dans le vide', () {
    // Une clé d'overlay sans fragment est une traduction MORTE : `_merge.py`
    // l'ignore avec un simple warning. C'est presque toujours une faute de
    // frappe sur le nom de la clé — donc une langue silencieusement repliée.
    expect(merge.overlaysOrphelins, isEmpty,
        reason: '${merge.overlaysOrphelins.length} clé(s) d\'overlay sans '
            'fragment correspondant :\n'
            '${merge.overlaysOrphelins.take(20).join("\n")}');
  });

  test('les six langues portent exactement le même jeu de clés', () {
    final reference = merge.parLangue[_gabarit]!.keys.toSet();
    for (final langue in _langues) {
      final arb = _lisJson('lib/l10n/app_$langue.arb');
      final clefs = arb.keys.where((k) => !k.startsWith('@')).toSet();
      expect(clefs, reference, reason: 'app_$langue.arb dérive du gabarit');
    }
  });
}
