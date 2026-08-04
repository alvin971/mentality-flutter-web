// Le score du jeu de délai — l'aire sous la courbe, et la partie qu'on refuse.
//
// Ce que ces tests protègent, dans l'ordre d'importance :
//
// 1. AUCUN CLASSEMENT. C'est la propriété qui distingue ce jeu du Stroop, et la
//    seule qu'un futur lot pourrait défaire sans s'en apercevoir : rien dans le
//    type ne rend un score « meilleur » qu'un autre.
// 2. L'AIRE NE SUPPOSE AUCUN MODÈLE. Elle se calcule sur les points répondus,
//    pas sur une courbe ajustée.
// 3. LA MONOTONIE EST LE SEUL REFUS. Et le critère « pas de remontée » se lit
//    par délai croissant, jamais dans l'ordre des questions.

import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/features/waiting_event/delay_choice/domain/models/delay_choice_score.dart';

DelayChoiceScore score(Map<int, int> points, {int delayed = 150}) =>
    DelayChoiceScore(indifferenceByDelay: points, delayedAmount: delayed);

/// Les cinq délais du jeu, tous au même montant — une courbe plate.
Map<int, int> plate(int montant) =>
    {for (final j in [7, 30, 90, 180, 365]) j: montant};

void main() {
  group('aire sous la courbe', () {
    test('quelqu\'un qui attend toujours frôle 100', () {
      // Escalier « toujours plus tard » : 147 à chaque délai.
      expect(score(plate(147)).patiencePercent, greaterThanOrEqualTo(97));
    });

    test('quelqu\'un qui prend toujours l\'immédiat frôle 0', () {
      // Escalier « toujours tout de suite » : 3 à chaque délai.
      expect(score(plate(3)).patiencePercent, lessThanOrEqualTo(3));
    });

    test('★ l\'index vit toujours entre 0 et 100', () {
      for (final montant in [1, 3, 40, 75, 120, 147, 149]) {
        final index = score(plate(montant)).patiencePercent;
        expect(index, inInclusiveRange(0, 100), reason: 'montant $montant');
      }
    });

    test('une courbe plus haute donne un index plus haut', () {
      expect(
        score(plate(120)).patienceIndex,
        greaterThan(score(plate(40)).patienceIndex),
      );
    });

    test('le point (0 ; 1) est une définition, pas une mesure', () {
      // Une courbe plate à la moitié de la somme différée : l'aire vaut un peu
      // PLUS que 0,5, parce que le segment initial part de 1 à délai nul. Un
      // calcul qui oublierait ce point rendrait exactement 0,5.
      final index = score(plate(75)).patienceIndex;
      expect(index, greaterThan(0.5));
      expect(index, lessThan(0.55));
    });

    test('l\'axe des délais est normalisé par le plus long', () {
      // Deux courbes de MÊME FORME, l'une étalée sur 90 jours et l'autre sur
      // 900, donnent le même index : l'abscisse est une proportion du délai
      // maximal, jamais une durée absolue. C'est ce qui rend l'index lisible
      // sans dire sur quelle échéance il porte.
      final courte = score({7: 100, 30: 80, 90: 60});
      final longue = score({70: 100, 300: 80, 900: 60});
      expect(longue.patienceIndex, closeTo(courte.patienceIndex, 1e-9));
    });
  });

  group('la partie qu\'on refuse', () {
    test('une courbe décroissante est cohérente', () {
      expect(
        score({7: 130, 30: 100, 90: 70, 180: 40, 365: 20}).isReliable,
        isTrue,
      );
    });

    test('une petite remontée reste tolérée', () {
      // 20 € de remontée sur 150, soit 13 % — sous la tolérance de 20 %.
      expect(score({7: 130, 30: 100, 90: 120, 180: 40, 365: 20}).isMonotone,
          isTrue);
    });

    test('★ une remontée franche fait tout refuser', () {
      // 60 € de remontée, soit 40 % : des réponses posées au hasard.
      final incoherent = score({7: 60, 30: 120, 90: 70, 180: 40, 365: 20});
      expect(incoherent.isMonotone, isFalse);
      expect(incoherent.isReliable, isFalse);
    });

    test('la remontée se juge par délai croissant, pas dans l\'ordre reçu', () {
      // Les mêmes points, écrits dans le désordre : le verdict ne bouge pas.
      final range = score({7: 130, 30: 100, 90: 70, 180: 40, 365: 20});
      final desordre = score({365: 20, 90: 70, 7: 130, 180: 40, 30: 100});
      expect(desordre.isReliable, range.isReliable);
      expect(desordre.patienceIndex, closeTo(range.patienceIndex, 1e-9));
    });

    test('★ attendre toujours reste un résultat valable', () {
      // Le second critère de Johnson & Bickel écarterait cette personne : elle
      // n'escompte pas. On le refuse — c'est une préférence cohérente, pas une
      // anomalie, et lui cacher son résultat n'aurait aucun sens dans un jeu.
      expect(score(plate(147)).isReliable, isTrue);
    });

    test('sous trois délais, rien n\'est annoncé', () {
      expect(score({7: 130, 30: 100}).isReliable, isFalse);
      expect(score({7: 130, 30: 100, 90: 70}).isReliable, isTrue);
    });

    test('une partie vide ne casse pas le calcul', () {
      final vide = score(const {});
      expect(vide.isReliable, isFalse);
      expect(vide.patiencePercent, 0);
    });
  });

  group('la phrase concrète', () {
    test('le point de référence est rendu tel quel', () {
      expect(score({7: 130, 30: 100, 90: 70}).indifferenceAt(30), 100);
    });

    test('un délai non mené à terme ne rend rien', () {
      expect(score({7: 130, 90: 70, 180: 40}).indifferenceAt(30), isNull);
    });
  });
}
