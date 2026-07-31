// La cotation de l'IPIP-50, en valeurs calculées à la main.
//
// Un scorer est le seul endroit du programme où une erreur ne se voit sur
// AUCUN écran : le questionnaire s'affiche, les réponses se donnent, le
// rapport s'affiche — avec un chiffre faux. D'où des cas dont le résultat est
// posé d'avance plutôt que dérivé du code testé.

import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/features/waiting_event/_shared/data/question_bank/ipip50.dart';
import 'package:mentality/features/waiting_event/personality/domain/services/ipip_scorer.dart';

/// Répond [valeur] à TOUS les items.
Map<String, int> partout(int valeur) => {
      for (final item in ipip50Items) item.id: valeur,
    };

/// Répond [valeur] aux seuls items du facteur [trait].
Map<String, int> surLeTrait(String trait, int valeur) => {
      for (final item in ipip50Items)
        if (item.subscale == trait) item.id: valeur,
    };

void main() {
  group('les golden values', () {
    test('tout au milieu de l\'échelle → 30 partout', () {
      // Dix items à 3, inversions comprises (6 − 3 = 3) : le point fixe de
      // l'inversion. Si un item était coté dans le mauvais sens, ce cas ne le
      // verrait PAS — d'où les deux suivants.
      final profil = scoreIpip50(partout(3));
      for (final trait in IpipTrait.all) {
        expect(profil.byTrait(trait).raw, 30, reason: trait);
        expect(profil.byTrait(trait).band, IpipBand.mid, reason: trait);
      }
      expect(profil.isComplete, isTrue);
      expect(profil.answeredCount, 50);
    });

    test('« très exact » partout → chaque trait vaut sa part d\'inversions',
        () {
      // Cote 5 sur tous les items. Un item direct rapporte 5, un item inversé
      // 6 − 5 = 1. Le total d'un facteur vaut donc 5·directs + 1·inversés.
      final profil = scoreIpip50(partout(5));

      // Extraversion : 5 directs, 5 inversés → 5×5 + 5×1 = 30.
      expect(profil.byTrait(IpipTrait.extraversion).raw, 30);
      // Amabilité : 6 directs, 4 inversés → 30 + 4 = 34.
      expect(profil.byTrait(IpipTrait.agreeableness).raw, 34);
      // Conscience : 6 directs, 4 inversés → 34.
      expect(profil.byTrait(IpipTrait.conscientiousness).raw, 34);
      // Stabilité : 2 directs, 8 inversés → 10 + 8 = 18. C'est la signature
      // du pôle « calme » : dire « très exact » à « je m'irrite facilement »
      // FAIT BAISSER la stabilité.
      expect(profil.byTrait(IpipTrait.stability).raw, 18);
      // Intellect : 7 directs, 3 inversés → 35 + 3 = 38.
      expect(profil.byTrait(IpipTrait.intellect).raw, 38);
    });

    test('« très inexact » partout → le miroir exact du cas précédent', () {
      // Cote 1 partout : direct = 1, inversé = 5. Chaque trait doit valoir
      // 60 − (son total à 5), puisque les deux cas sont symétriques autour de
      // 30 par item.
      final haut = scoreIpip50(partout(5));
      final bas = scoreIpip50(partout(1));
      for (final trait in IpipTrait.all) {
        expect(bas.byTrait(trait).raw, 60 - haut.byTrait(trait).raw,
            reason: trait);
      }
      expect(bas.byTrait(IpipTrait.stability).raw, 42);
      expect(bas.byTrait(IpipTrait.extraversion).raw, 30);
    });

    test('le maximum d\'un trait vaut 50, le minimum 10', () {
      // Le seul chemin vers 50 : « très exact » aux directs, « très inexact »
      // aux inversés. C'est ce que fait ce cas, facteur par facteur.
      for (final trait in IpipTrait.all) {
        final maxi = {
          for (final item in ipip50Items)
            if (item.subscale == trait) item.id: item.reverseScored ? 1 : 5,
        };
        final mini = {
          for (final item in ipip50Items)
            if (item.subscale == trait) item.id: item.reverseScored ? 5 : 1,
        };
        expect(scoreIpip50(maxi).byTrait(trait).raw, IpipTraitScore.maxRaw,
            reason: trait);
        expect(scoreIpip50(mini).byTrait(trait).raw, IpipTraitScore.minRaw,
            reason: trait);
        expect(scoreIpip50(maxi).byTrait(trait).band, IpipBand.high,
            reason: trait);
        expect(scoreIpip50(mini).byTrait(trait).band, IpipBand.low,
            reason: trait);
      }
    });

    test('un facteur ne récupère QUE ses propres items', () {
      // Croisement classique : une somme qui ramasserait des items voisins
      // resterait dans les bornes et ne se verrait nulle part.
      final profil = scoreIpip50(surLeTrait(IpipTrait.extraversion, 5));
      expect(profil.byTrait(IpipTrait.extraversion).answered, 10);
      for (final autre in IpipTrait.all) {
        if (autre == IpipTrait.extraversion) continue;
        expect(profil.byTrait(autre).answered, 0, reason: autre);
        expect(profil.byTrait(autre).raw, 0, reason: autre);
      }
    });
  });

  group('les bornes de bande', () {
    // 30 ± 4. En deçà, la différence tient à deux ou trois clics et ne mérite
    // pas d'être racontée.
    test('26 et 34 basculent, 27 et 33 non', () {
      IpipBand? bandePour(int brut) {
        // Construit un total exact sur l'extraversion : cinq items directs
        // portent la variation, les cinq inversés restent à 3 (donc 3 chacun).
        final directs = ipip50Items
            .where((i) => i.subscale == IpipTrait.extraversion && !i.reverseScored)
            .toList();
        final inverses = ipip50Items
            .where((i) => i.subscale == IpipTrait.extraversion && i.reverseScored)
            .toList();
        // 5 items inversés à 3 → 15. Reste `brut − 15` à répartir sur 5 items
        // directs, chacun entre 1 et 5.
        var reste = brut - 15;
        final reponses = <String, int>{
          for (final i in inverses) i.id: 3,
        };
        for (final i in directs) {
          final part = (reste / (directs.length - directs.indexOf(i))).round();
          final valeur = part.clamp(1, 5);
          reponses[i.id] = valeur;
          reste -= valeur;
        }
        final profil = scoreIpip50(reponses);
        expect(profil.byTrait(IpipTrait.extraversion).raw, brut,
            reason: 'le cas de test lui-même doit produire $brut');
        return profil.byTrait(IpipTrait.extraversion).band;
      }

      expect(bandePour(26), IpipBand.low);
      expect(bandePour(27), IpipBand.mid);
      expect(bandePour(33), IpipBand.mid);
      expect(bandePour(34), IpipBand.high);
    });
  });

  group('ce qui est incomplet est nommé, jamais comparé', () {
    test('un questionnaire abandonné n\'a pas de bande', () {
      final partiel = {
        for (final item in ipip50Items.take(20)) item.id: 4,
      };
      final profil = scoreIpip50(partiel);
      expect(profil.isComplete, isFalse);
      expect(profil.answeredCount, 20);
      for (final trait in IpipTrait.all) {
        final t = profil.byTrait(trait);
        expect(t.isComplete, isFalse, reason: trait);
        expect(t.band, isNull,
            reason: '$trait : situer un total partiel sur une échelle complète '
                'le ferait systématiquement paraître bas');
      }
    });

    test('aucune réponse → cinq facteurs à zéro, aucune bande', () {
      final profil = scoreIpip50(const {});
      expect(profil.traits, hasLength(5));
      expect(profil.answeredCount, 0);
      expect(profil.isComplete, isFalse);
      expect(profil.traits.every((t) => t.band == null), isTrue);
    });
  });

  group('les données corrompues', () {
    test('une valeur hors échelle est ignorée, jamais ramenée à une borne', () {
      // Plaquer 0 ou 9 sur la borne fabriquerait un score à partir de rien.
      // L'ignorer laisse le facteur INCOMPLET, donc sans bande — c'est visible.
      final reponses = partout(3);
      reponses[ipip50Items.first.id] = 0;
      reponses[ipip50Items[5].id] = 9;

      final profil = scoreIpip50(reponses);
      final e = profil.byTrait(IpipTrait.extraversion);
      expect(e.answered, 8, reason: 'les deux valeurs folles ne comptent pas');
      expect(e.raw, 24, reason: '8 items à 3');
      expect(e.isComplete, isFalse);
      expect(e.band, isNull);
      // Les quatre autres facteurs sont intacts.
      expect(profil.byTrait(IpipTrait.stability).raw, 30);
    });

    test('un identifiant inconnu n\'entre nulle part', () {
      final reponses = {...partout(3), 'ipip50_q99': 5, 'gad7_q1': 3};
      final profil = scoreIpip50(reponses);
      expect(profil.answeredCount, 50);
      for (final trait in IpipTrait.all) {
        expect(profil.byTrait(trait).raw, 30, reason: trait);
      }
    });
  });

  test('les cinq facteurs sortent toujours dans l\'ordre déclaré', () {
    // Le rapport (LOT I) affichera cette liste telle quelle : un ordre qui
    // varierait d'une passation à l'autre déplacerait les traits sous les yeux
    // de l'utilisateur.
    final profil = scoreIpip50(partout(3));
    expect(profil.traits.map((t) => t.trait).toList(), IpipTrait.all);
  });
}
