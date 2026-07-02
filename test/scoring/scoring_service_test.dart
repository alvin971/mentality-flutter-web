import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/core/models/complete_test_session.dart';
import 'package:mentality/features/scoring/data/composite_score_tables.dart';
import 'package:mentality/features/scoring/data/normative_tables.dart';
import 'package:mentality/features/scoring/data/scoring_params.dart';
import 'package:mentality/features/scoring/domain/services/scoring_service.dart';

void main() {
  const service = ScoringService();

  // Session complète avec des scores dans la plage normale (bruts typiques adulte 30 ans)
  CompleteTestSession _buildSession({
    int cubes = 42,
    int similarities = 25,
    int digitSpan = 23,
    int matrices = 18,
    int vocabulary = 30,
    int arithmetic = 14,
    int symbolSearch = 30,
    int visualPuzzles = 14,
    int information = 18,
    int coding = 65,
    int pictureSpan = 18,
    int figureWeights = 12,
  }) {
    return CompleteTestSession(
      startTime: DateTime(2026, 3, 22),
      cubesScore: cubes,
      similaritiesScore: similarities,
      digitSpanScore: digitSpan,
      matricesScore: matrices,
      vocabularyScore: vocabulary,
      arithmeticScore: arithmetic,
      symbolSearchScore: symbolSearch,
      visualPuzzlesScore: visualPuzzles,
      informationScore: information,
      codingScore: coding,
      pictureSpanScore: pictureSpan,
      figureWeightsScore: figureWeights,
      currentTestIndex: 12,
      completedTests: List.from(CompleteTestSession.testSequence),
    );
  }

  group('ScoringService.computeScore', () {
    test('retourne null si un sous-test primaire est manquant', () {
      final incomplete = CompleteTestSession(
        startTime: DateTime.now(),
        cubesScore: 42,
        // les autres sont null
      );
      expect(service.computeScore(incomplete, 360), isNull);
    });

    test('retourne un IQScore complet avec une session valide', () {
      final session = _buildSession();
      final score = service.computeScore(session, 360); // 30 ans = 360 mois

      expect(score, isNotNull);
      expect(score!.fsiq, greaterThan(0));
      expect(score.fsiq, lessThan(200));
    });

    test('le FSIQ est dans la plage raisonnable [40, 160] pour des scores normaux', () {
      final session = _buildSession();
      final score = service.computeScore(session, 360);

      expect(score, isNotNull);
      expect(score!.fsiq, inInclusiveRange(40, 160));
    });

    test('les 5 indices sont calculés et dans la plage [40, 160]', () {
      final session = _buildSession();
      final score = service.computeScore(session, 360);

      expect(score, isNotNull);
      for (final v in [score!.vci, score.vsi, score.fri, score.wmi, score.psi]) {
        if (v != null) {
          expect(v, inInclusiveRange(40, 160),
              reason: 'Indice doit être entre 40 et 160');
        }
      }
    });

    test('le percentile du FSIQ est entre 1 et 99', () {
      final session = _buildSession();
      final score = service.computeScore(session, 360);

      expect(score, isNotNull);
      expect(score!.fsiqPercentile, inInclusiveRange(1, 99));
    });

    test('l\'intervalle de confiance est cohérent (lower < fsiq < upper)', () {
      final session = _buildSession();
      final score = service.computeScore(session, 360);

      expect(score, isNotNull);
      final ci = score!.fsiqCI;
      expect(ci.lowerBound, lessThanOrEqualTo(score.fsiq));
      expect(ci.upperBound, greaterThanOrEqualTo(score.fsiq));
    });

    test('la classification FSIQ est non vide', () {
      final session = _buildSession();
      final score = service.computeScore(session, 360);

      expect(score, isNotNull);
      expect(score!.fsiqClassification, isNotEmpty);
    });

    test('scores élevés produisent un FSIQ élevé', () {
      final highSession = _buildSession(
        cubes: 66, similarities: 33, digitSpan: 30,
        matrices: 26, vocabulary: 45, arithmetic: 22,
        symbolSearch: 60, visualPuzzles: 26, information: 26,
        coding: 135, pictureSpan: 24, figureWeights: 18,
      );
      final lowSession = _buildSession(
        cubes: 10, similarities: 5, digitSpan: 5,
        matrices: 3, vocabulary: 5, arithmetic: 3,
        symbolSearch: 8, visualPuzzles: 3, information: 3,
        coding: 15, pictureSpan: 3, figureWeights: 2,
      );

      final high = service.computeScore(highSession, 360);
      final low = service.computeScore(lowSession, 360);

      expect(high, isNotNull);
      expect(low, isNotNull);
      expect(high!.fsiq, greaterThan(low!.fsiq));
    });
  });

  group('NormativeTables.toScaledScore (âge-relatif)', () {
    const refAge = 300; // 25 ans

    test('un brut ≈ moyenne attendue donne une note ≈ 10 à l\'âge de référence', () {
      expect(NormativeTables.toScaledScore('MR', 14, refAge),
          inInclusiveRange(9, 11));
    });

    test('un brut parfait donne une note élevée (≥ 17)', () {
      expect(NormativeTables.toScaledScore('MR', 26, refAge),
          greaterThanOrEqualTo(17));
    });

    test('un brut nul donne une note basse (≤ 4)', () {
      expect(
          NormativeTables.toScaledScore('MR', 0, refAge), lessThanOrEqualTo(4));
    });

    test('un sous-test inconnu retourne la note moyenne 10', () {
      expect(NormativeTables.toScaledScore('XX', 50, refAge), 10);
    });

    test('un brut négatif (SS) est borné à 0', () {
      expect(NormativeTables.toScaledScore('SS', -20, refAge),
          NormativeTables.toScaledScore('SS', 0, refAge));
    });

    test('à brut égal, un sujet âgé est mieux noté sur la vitesse (CD)', () {
      final young = NormativeTables.toScaledScore('CD', 60, 300); // 25 ans
      final old = NormativeTables.toScaledScore('CD', 60, 840); // 70 ans
      expect(old, greaterThan(young));
    });
  });

  group('CompositeScoreTables (paramétrique)', () {
    test('des notes toutes moyennes (10) donnent un composite de 100', () {
      ScoringParams.indices.forEach((code, idx) {
        expect(CompositeScoreTables.computeCompositeScore(code, 10 * idx.k), 100,
            reason: '$code avec ${idx.k} sous-tests moyens doit donner 100');
      });
    });

    test('les percentiles suivent N(100,15)', () {
      expect(CompositeScoreTables.getPercentile(100), 50);
      expect(CompositeScoreTables.getPercentile(115), inInclusiveRange(83, 85));
      expect(CompositeScoreTables.getPercentile(130), inInclusiveRange(97, 99));
      expect(CompositeScoreTables.getPercentile(85), inInclusiveRange(15, 17));
    });

    test('l\'intervalle de confiance encadre le score', () {
      final (lower, upper) =
          CompositeScoreTables.getConfidenceInterval('FSIQ', 100);
      expect(lower, lessThan(100));
      expect(upper, greaterThan(100));
    });
  });

  group('WMI intègre la Mémoire des images (PM)', () {
    test('augmenter PM augmente le WMI, toutes choses égales par ailleurs', () {
      final low = service.computeScore(_buildSession(pictureSpan: 2), 360);
      final high = service.computeScore(_buildSession(pictureSpan: 12), 360);
      expect(low?.wmi, isNotNull);
      expect(high?.wmi, isNotNull);
      expect(high!.wmi!, greaterThan(low!.wmi!));
    });
  });
}
