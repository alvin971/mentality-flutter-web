// Ce que les révélations lisent — vérifié sans écran.
//
// Deux gardes de PARITÉ portent l'essentiel de ce fichier, parce que le risque
// n'est pas qu'une règle soit fausse : c'est qu'elle DIVERGE de celle que
// l'écran de résultats applique déjà. Un même profil doit raconter la même
// histoire au jour 6 et sur la page de résultats, sans quoi l'utilisateur
// prend en défaut sa propre application.
//
//   · les forces et faiblesses suivent `IQScore` (±10 autour du QI global) ;
//   · les bandes descriptives suivent `CompositeScoreTables.classify`.

import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/core/l10n/gen/app_localizations.dart';
import 'package:mentality/core/l10n/locale_notifier.dart';
import 'package:mentality/features/scoring/data/composite_score_tables.dart';
import 'package:mentality/features/scoring/domain/entities/iq_score.dart';
import 'package:mentality/features/waiting_event/_shared/domain/models/event_day.dart';
import 'package:mentality/features/waiting_event/reveals/domain/models/reveal_data.dart';
import 'package:mentality/services/session_history_service.dart';

SessionHistoryEntry entree({
  required int fsiq,
  int? vci,
  int? vsi,
  int? fri,
  int? wmi,
  int? psi,
  String classification = 'Moyen',
}) =>
    SessionHistoryEntry(
      id: 'e1',
      account: 'compte',
      date: DateTime(2026, 7, 27),
      ageInMonths: 360,
      fsiq: fsiq,
      vci: vci,
      vsi: vsi,
      fri: fri,
      wmi: wmi,
      psi: psi,
      classification: classification,
    );

IQScore iq({
  required int fsiq,
  int? vci,
  int? vsi,
  int? fri,
  int? wmi,
  int? psi,
}) =>
    IQScore(
      fsiq: fsiq,
      vci: vci,
      vsi: vsi,
      fri: fri,
      wmi: wmi,
      psi: psi,
      confidenceIntervals: const {},
      percentiles: const {},
      classifications: const {},
      ageInMonths: 360,
      assessmentDate: DateTime(2026, 7, 27),
      assessmentId: 'a1',
    );

/// Des profils qui couvrent les cas qui comptent : régulier, très dispersé,
/// pile sur les bornes de ±10, et incomplet.
const _profils = <(int, int?, int?, int?, int?, int?)>[
  (100, 100, 100, 100, 100, 100), // parfaitement plat
  (100, 111, 89, 100, 100, 100), // juste au-delà des bornes des deux côtés
  (100, 110, 90, 100, 100, 100), // PILE sur les bornes : ni force ni faiblesse
  (100, 130, 70, 115, 85, 100), // très dispersé
  (85, 96, 74, 85, 85, 85), // moyenne basse
  (128, 139, 117, 128, 128, 128), // moyenne haute
  (100, 120, null, null, 80, null), // indices manquants
  (100, null, null, null, null, null), // aucun indice
  // Les deux bords de l'homogénéité : l'écart à la moyenne des indices vaut
  // exactement 15 d'un côté, 14 de l'autre. Sans eux, la garde de parité
  // laisserait passer un `<` transformé en `<=`.
  (100, 115, 100, 100, 100, 85), // écart max à la moyenne = 15 → hétérogène
  (100, 114, 100, 100, 100, 86), // écart max à la moyenne = 14 → homogène
];

void main() {
  group('lecture de l\'historique', () {
    test('sans bilan, il n\'y a rien à révéler (aucun chiffre inventé)', () {
      expect(RevealData.fromHistory(null), isNull);
    });

    test('les six nombres du bilan sont repris tels quels', () {
      final data = RevealData.fromHistory(
        entree(fsiq: 104, vci: 112, vsi: 98, fri: 107, wmi: 95, psi: 101),
      )!;
      expect(data.fsiq, 104);
      expect(data.scoreOf(CognitiveIndex.vci), 112);
      expect(data.scoreOf(CognitiveIndex.vsi), 98);
      expect(data.scoreOf(CognitiveIndex.fri), 107);
      expect(data.scoreOf(CognitiveIndex.wmi), 95);
      expect(data.scoreOf(CognitiveIndex.psi), 101);
    });

    test('un indice absent le reste — il ne se devine pas depuis les autres',
        () {
      final data = RevealData.fromHistory(entree(fsiq: 100, vci: 100))!;
      expect(data.scoreOf(CognitiveIndex.psi), isNull);
      expect(data.measuredIndices, [CognitiveIndex.vci]);
      expect(data.hasDataFor(RevealKind.psi), isFalse);
      expect(data.hasDataFor(RevealKind.vci), isTrue);
    });

    test('les révélations d\'ensemble s\'affichent même sans indice complet',
        () {
      final data = RevealData.fromHistory(entree(fsiq: 100))!;
      expect(data.hasDataFor(RevealKind.strengths), isTrue);
      expect(data.hasDataFor(RevealKind.fullIq), isTrue);
    });

    test('chaque jour à révélation d\'indice sait quel indice il porte', () {
      expect(RevealData.indexFor(RevealKind.vci), CognitiveIndex.vci);
      expect(RevealData.indexFor(RevealKind.psi), CognitiveIndex.psi);
      expect(RevealData.indexFor(RevealKind.wmi), CognitiveIndex.wmi);
      expect(RevealData.indexFor(RevealKind.fri), CognitiveIndex.fri);
      expect(RevealData.indexFor(RevealKind.vsi), CognitiveIndex.vsi);
      // Les deux qui n'en portent pas un seul : l'une compare les cinq,
      // l'autre les résume.
      expect(RevealData.indexFor(RevealKind.strengths), isNull);
      expect(RevealData.indexFor(RevealKind.fullIq), isNull);
    });
  });

  group('GARDE de parité : le jour 6 dit ce que dit l\'écran de résultats', () {
    test('forces, faiblesses, homogénéité et amplitude concordent', () {
      for (final (fsiq, vci, vsi, fri, wmi, psi) in _profils) {
        final data = RevealData(
            fsiq: fsiq, vci: vci, vsi: vsi, fri: fri, wmi: wmi, psi: psi);
        final reference =
            iq(fsiq: fsiq, vci: vci, vsi: vsi, fri: fri, wmi: wmi, psi: psi);
        final contexte = 'profil $fsiq/$vci/$vsi/$fri/$wmi/$psi';

        expect(data.strengths.map((i) => i.code).toSet(),
            reference.strengths.toSet(),
            reason: 'forces divergentes — $contexte');
        expect(data.weaknesses.map((i) => i.code).toSet(),
            reference.weaknesses.toSet(),
            reason: 'faiblesses divergentes — $contexte');
        expect(data.isHomogeneousProfile, reference.isHomogeneousProfile,
            reason: 'homogénéité divergente — $contexte');
        expect(data.maxIndexDiscrepancy, reference.maxIndexDiscrepancy,
            reason: 'amplitude divergente — $contexte');
      }
    });

    test('une force est RELATIVE : elle se lit contre le QI global, pas 100',
        () {
      // Un profil entièrement au-dessus de 100 sans aucune force : c'est le
      // niveau moyen de la personne qui sert de repère.
      final haut = RevealData(
          fsiq: 130, vci: 132, vsi: 128, fri: 130, wmi: 130, psi: 130);
      expect(haut.strengths, isEmpty);
      expect(haut.weaknesses, isEmpty);

      // Et un profil entièrement sous 100 peut avoir une force.
      final bas =
          RevealData(fsiq: 75, vci: 90, vsi: 72, fri: 75, wmi: 75, psi: 75);
      expect(bas.strengths, [CognitiveIndex.vci]);
    });
  });

  group('GARDE de parité : les bandes sont celles du barème de l\'app', () {
    setUp(() => localeNotifier.value = const Locale('fr'));

    test('de 40 à 160, chaque score tombe dans la même bande', () {
      final l10n = lookupAppLocalizations(const Locale('fr'));
      String libelle(RevealBand b) => switch (b) {
            RevealBand.verySuperior => l10n.scoringClassificationVerySuperior,
            RevealBand.superior => l10n.scoringClassificationSuperior,
            RevealBand.highAverage => l10n.scoringClassificationHighAverage,
            RevealBand.average => l10n.scoringClassificationAverage,
            RevealBand.lowAverage => l10n.scoringClassificationLowAverage,
            RevealBand.borderline => l10n.scoringClassificationBorderline,
            RevealBand.extremelyLow => l10n.scoringClassificationExtremelyLow,
          };

      for (var score = 40; score <= 160; score++) {
        expect(libelle(RevealBand.of(score)),
            CompositeScoreTables.classify(score),
            reason: 'bande divergente au score $score');
      }
    });

    test('les six bornes publiées basculent au bon point', () {
      expect(RevealBand.of(129), RevealBand.superior);
      expect(RevealBand.of(130), RevealBand.verySuperior);
      expect(RevealBand.of(119), RevealBand.highAverage);
      expect(RevealBand.of(120), RevealBand.superior);
      expect(RevealBand.of(109), RevealBand.average);
      expect(RevealBand.of(110), RevealBand.highAverage);
      expect(RevealBand.of(89), RevealBand.lowAverage);
      expect(RevealBand.of(90), RevealBand.average);
      expect(RevealBand.of(79), RevealBand.borderline);
      expect(RevealBand.of(80), RevealBand.lowAverage);
      expect(RevealBand.of(69), RevealBand.extremelyLow);
      expect(RevealBand.of(70), RevealBand.borderline);
    });
  });

  group('profil régulier', () {
    test('la bascule se fait à un écart-type, pas avant', () {
      // Écart à la MOYENNE des indices, pas au QI global : la règle est celle
      // d'IQScore, et un `<` changé en `<=` renverserait le verdict affiché
      // au jour 6 sans qu'aucun test de rendu ne s'en aperçoive.
      final pile = RevealData(
          fsiq: 100, vci: 115, vsi: 100, fri: 100, wmi: 100, psi: 85);
      expect(pile.isHomogeneousProfile, isFalse, reason: 'écart de 15 pile');

      final juste = RevealData(
          fsiq: 100, vci: 114, vsi: 100, fri: 100, wmi: 100, psi: 86);
      expect(juste.isHomogeneousProfile, isTrue, reason: 'écart de 14');
    });

    test('un seul indice mesuré ne peut pas être hétérogène', () {
      expect(RevealData(fsiq: 100, vci: 120).isHomogeneousProfile, isTrue);
      expect(const RevealData(fsiq: 100).isHomogeneousProfile, isTrue);
      expect(const RevealData(fsiq: 100).maxIndexDiscrepancy, 0);
    });

    test('l\'amplitude est bien du plus haut au plus bas', () {
      final data = RevealData(
          fsiq: 100, vci: 130, vsi: 70, fri: 100, wmi: 100, psi: 100);
      expect(data.maxIndexDiscrepancy, 60);
    });
  });
}
