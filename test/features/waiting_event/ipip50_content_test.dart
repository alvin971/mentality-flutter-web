// L'IPIP-50 tel qu'il doit rester.
//
// Ce fichier vérifie la STRUCTURE de l'instrument — celle dont on répond, par
// opposition au libellé exact de chaque item, dont on ne répond pas (voir
// `QModuleRegistry.recalled` et la garde qui l'énumère). La distinction est
// tout l'enjeu du lot : ce qui est sûr est verrouillé par des tests, ce qui ne
// l'est pas est déclaré.
//
// Ce qui est verrouillé ici :
//
// · dix items par facteur, cinquante en tout ;
// · l'ORDRE entrelacé de la publication (1 = extraversion, 2 = amabilité,
//   3 = conscience, 4 = stabilité, 5 = ouverture, puis on recommence) ;
// · le SENS de cotation de chacun des cinquante items, nommément ;
// · le libellé anglais figé par empreinte — non pas parce qu'il est prouvé
//   juste, mais pour qu'une modification accidentelle ne passe pas inaperçue.

import 'dart:convert';

import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/features/waiting_event/_shared/data/question_bank/ipip50.dart';
import 'package:mentality/features/waiting_event/_shared/domain/models/q_instrument.dart';
import 'package:mentality/features/waiting_event/_shared/domain/models/q_provenance.dart';

/// FNV-1a 64 bits, écrit ici plutôt qu'importé : `String.hashCode` n'est pas
/// stable d'une version de Dart à l'autre, et faire dépendre une garde de
/// contenu d'un paquet transitif serait la fragiliser pour rien.
String empreinte(String texte) {
  var h = BigInt.parse('14695981039346656037');
  final masque = (BigInt.one << 64) - BigInt.one;
  final prime = BigInt.parse('1099511628211');
  for (final octet in utf8.encode(texte)) {
    h = (h ^ BigInt.from(octet)) * prime & masque;
  }
  return h.toRadixString(16).padLeft(16, '0');
}

void main() {
  group('la forme de l\'instrument', () {
    test('cinquante items, dix par facteur', () {
      expect(ipip50Items, hasLength(50));
      for (final trait in IpipTrait.all) {
        expect(ipip50Items.where((i) => i.subscale == trait).length, 10,
            reason: 'facteur $trait');
      }
      expect(IpipTrait.all, hasLength(5));
    });

    test('l\'ordre entrelacé de la publication', () {
      // Regrouper les dix items d'un même facteur produirait un effet de série
      // (« j'ai déjà dit trois fois que je suis sociable ») que la calibration
      // n'a jamais connu. L'entrelacement est donc un CONTRAT, pas une mise en
      // page.
      for (var i = 0; i < ipip50Items.length; i++) {
        expect(ipip50Items[i].subscale, IpipTrait.all[i % 5],
            reason: 'item ${i + 1} : l\'ordre de passation a glissé');
      }
    });

    test('les identifiants suivent la numérotation publiée', () {
      for (var i = 0; i < ipip50Items.length; i++) {
        final numero = (i + 1).toString().padLeft(2, '0');
        expect(ipip50Items[i].id, 'ipip50_q$numero');
      }
      expect(ipip50Items.map((i) => i.id).toSet(), hasLength(50));
    });

    test('un bloc unique, validé, sans transition', () {
      expect(ipip50.origin, QItemOrigin.validated);
      expect(ipip50.items, same(ipip50Items));
      expect(ipip50.transition, isNull,
          reason: 'un seul bloc, une seule échelle : rien à annoncer');
      expect(ipip50.scale, ipipAccuracyScale);
    });
  });

  group('la cotation', () {
    // Le sens de chaque item, écrit à la main plutôt que dérivé de la banque :
    // un test qui relit la source qu'il vérifie ne vérifie rien.
    const inverses = <int>{
      // Extraversion — les cinq items « je me tais ».
      6, 16, 26, 36, 46,
      // Amabilité.
      2, 12, 22, 32,
      // Conscience.
      8, 18, 28, 38,
      // Stabilité émotionnelle : HUIT items sur dix, ce qui est précisément le
      // signe qu'on cote le pôle « calme » et non le névrosisme.
      4, 14, 24, 29, 34, 39, 44, 49,
      // Intellect / imagination.
      10, 20, 30,
    };

    test('chacun des cinquante items est coté dans le bon sens', () {
      for (var i = 0; i < ipip50Items.length; i++) {
        expect(ipip50Items[i].reverseScored, inverses.contains(i + 1),
            reason: 'item ${i + 1} (${ipip50Items[i].text.en}) : sens de '
                'cotation. L\'inverser ne changerait AUCUN écran — seulement '
                'le score.');
      }
    });

    test('la stabilité émotionnelle est cotée au pôle calme', () {
      // Le piège nommé : les marqueurs IPIP mesurent la STABILITÉ, pas le
      // névrosisme. Huit items inversés sur dix en sont la signature. Un
      // rapport qui titrerait « névrosisme » sur ce chiffre dirait le
      // contraire de la mesure.
      final stabilite =
          ipip50Items.where((i) => i.subscale == IpipTrait.stability);
      expect(stabilite.where((i) => i.reverseScored).length, 8);
      expect(stabilite.where((i) => !i.reverseScored).length, 2);
    });

    test('l\'échelle est celle de l\'IPIP : 1 à 5, exactitude', () {
      expect(ipipAccuracyScale.options.map((o) => o.value), [1, 2, 3, 4, 5]);
      expect(ipipAccuracyScale.minValue, 1);
      expect(ipipAccuracyScale.maxValue, 5);
      // L'inversion canonique `min + max − valeur`, soit 6 − valeur.
      for (var v = 1; v <= 5; v++) {
        expect(ipipAccuracyScale.score(v, reversed: true), 6 - v);
        expect(ipipAccuracyScale.score(v), v);
      }
    });

    test('ce n\'est PAS une échelle de fréquence', () {
      // La règle « échelle de fréquence homogène, ancrage six mois » du plan
      // d'implémentation vaut pour NOS questions candidates. L'imposer à un
      // instrument validé reviendrait à le reformuler — exactement ce que le
      // plan produit §10 déclare mort.
      expect(ipipAccuracyScale.id, 'ipip_accuracy_5');
      expect(ipipAccuracyScale.options.first.label.en, 'Very Inaccurate');
      expect(ipipAccuracyScale.options.last.label.en, 'Very Accurate');
    });
  });

  group('les six langues', () {
    test('chaque item et chaque modalité existent dans les six langues', () {
      for (final item in ipip50Items) {
        expect(item.text.missingLocales, isEmpty,
            reason: '${item.id} (${item.text.en})');
      }
      for (final option in ipipAccuracyScale.options) {
        expect(option.label.missingLocales, isEmpty,
            reason: 'modalité ${option.value}');
      }
    });

    test('aucun repli déguisé : les traductions sont différentes de l\'anglais',
        () {
      // Une traduction copiée-collée de l'anglais passerait la garde de parité
      // sans que personne ne le voie. Les quatre langues non anglaises doivent
      // réellement traduire.
      for (final item in ipip50Items) {
        for (final tag in ['fr', 'de', 'es', 'pt']) {
          expect(item.text.raw(tag), isNot(item.text.en),
              reason: '${item.id} : $tag est resté en anglais');
        }
      }
    });

    test('en_GB ne diffère que là où l\'anglais britannique diffère vraiment',
        () {
      // Pas de précédent « color/colour » à inventer : sur ces cinquante
      // items, un seul mot change réellement.
      final differents = ipip50Items
          .where((i) => i.text.raw('en_GB') != i.text.en)
          .map((i) => i.id)
          .toList();
      expect(differents, ['ipip50_q41']);
      expect(ipip50Items[40].text.en, contains('center of attention'));
      expect(ipip50Items[40].text.raw('en_GB'), contains('centre of attention'));
    });

    test('les traductions évitent les accords en genre', () {
      // L'app ne connaît pas le genre de qui répond. Une double forme
      // « stressé(e) » à chaque item rendrait les cinquante écrans illisibles ;
      // les traductions sont donc tournées pour s'en passer.
      final pieges = <String, List<String>>{
        'fr': ['(e)', '·e', 'stressé ', 'préparé', 'exigeant '],
        'es': ['/a', 'cómodo', 'preparado', 'tranquilo', 'lleno'],
        'pt': ['/a', 'calmo', 'stressado', 'cheio de ideias'],
      };
      for (final item in ipip50Items) {
        pieges.forEach((tag, motifs) {
          final texte = item.text.raw(tag)!;
          for (final motif in motifs) {
            expect(texte.contains(motif), isFalse,
                reason: '${item.id} en $tag : « $motif » impose un genre');
          }
        });
      }
    });

    test('chaque item se résout dans les six locales de l\'app', () {
      const locales = [
        Locale('fr'),
        Locale('en'),
        Locale('en', 'GB'),
        Locale('de'),
        Locale('es'),
        Locale('pt'),
      ];
      for (final item in ipip50Items) {
        for (final locale in locales) {
          final texte = item.text.resolve(locale);
          expect(texte, isNotEmpty, reason: '${item.id} en $locale');
          expect(texte.trim(), texte,
              reason: '${item.id} en $locale : espace parasite');
        }
      }
    });
  });

  group('la provenance — ce dont on ne répond PAS', () {
    test('déclarée restituée de mémoire, avec sa référence primaire', () {
      expect(ipip50.provenance, ipip50Provenance);
      expect(ipip50Provenance.status, QSourceStatus.recalled);
      expect(ipip50Provenance.confidence, QSourceConfidence.high);
      expect(ipip50Provenance.isVerified, isFalse);
      expect(ipip50Provenance.reference, contains('ipip.ori.org'));
      expect(ipip50.isRecalled, isTrue);
    });

    test('la note dit ce qui est tenu ET ce qui ne l\'est pas', () {
      final note = ipip50Provenance.note;
      expect(note, contains('structure'),
          reason: 'ce qui est sûr doit être nommé aussi précisément que ce qui '
              'ne l\'est pas');
      expect(note.toLowerCase(), contains('traductions'),
          reason: 'les cinq autres langues sont à nous — la page Méthodologie '
              'doit le dire');
    });

    test('l\'origine est citée, bien que le domaine public ne l\'exige pas',
        () {
      expect(ipip50.citation, isNotNull);
      expect(ipip50.citation, contains('Goldberg'));
    });
  });

  test('EMPREINTE des cinquante libellés anglais', () {
    // ⚠️ Ce que cette empreinte prouve, et ce qu'elle ne prouve PAS.
    //
    // Elle NE prouve pas que les libellés sont les vrais : elle est calculée
    // sur la même source que celle qu'elle vérifie. Aucun test ne peut faire
    // ça — c'est précisément pourquoi la provenance existe.
    //
    // Elle prouve qu'ils n'ont pas BOUGÉ depuis la livraison. C'est le risque
    // réel du quotidien : une faute de frappe corrigée « au passage », un
    // « don't » modernisé en « do not », une majuscule normalisée. Chacune
    // décale silencieusement un instrument dont le seuil a été calibré sur le
    // libellé d'origine.
    //
    // Si ce test tombe : soit on a confronté l'instrument à sa source et
    // corrigé un item — alors on met l'empreinte à jour ET on revoit la
    // provenance ; soit personne n'a voulu toucher au libellé, et c'est la
    // régression que cette empreinte existe pour attraper.
    final concatene = ipip50Items.map((i) => '${i.id}|${i.text.en}').join('\n');
    expect(empreinte(concatene), '47de8877619720f0',
        reason: 'les libellés anglais de l\'IPIP-50 ont changé');
  });
}
