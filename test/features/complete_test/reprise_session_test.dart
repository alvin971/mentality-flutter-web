// LA REPRISE — croiser ce que sait le serveur et ce que sait l'appareil.
//
// Ce que ces tests protègent, c'est la promesse elle-même : « reprendre où on
// s'est arrêté ». Avant, l'accueil affichait une bannière « Reprendre » dont le
// bouton menait au lancement standard — celui qui repart de zéro. Rien ne
// signalait l'écart, parce que rien ne relisait la progression.
//
// Fichier sans widget À DESSEIN (cf. referral_credit_reprise_test.dart) : un
// test simple placé après un test de widget se fige.

import 'package:flutter_test/flutter_test.dart';

import 'package:mentality/core/models/complete_test_session.dart';
import 'package:mentality/core/services/resume_service.dart';
import 'package:mentality/features/unlock/data/unlock_service.dart';

/// Session locale portant les scores donnés, dans l'ordre de la séquence.
CompleteTestSession locale(Map<String, int> scoresParCode, {DateTime? debut}) {
  final faits = [
    for (final l in CompleteTestSession.testSequence)
      if (scoresParCode.containsKey(CompleteTestSession.subtestCodes[l])) l,
  ];
  return ResumableSession(
    scoresByCode: scoresParCode,
    completedTests: faits,
    nextIndex: faits.length,
    startTime: debut ?? DateTime.now(),
    serverStartedOn: null,
    clientSessionId: null,
    knownToServer: false,
  ).toSession();
}

RemoteResumableSession distante(
  Map<String, int> scores, {
  String id = '6c0ac833-fb7f-4450-9e52-6721cdd6a498',
  int? durationS,
  DateTime? startedOn,
}) =>
    RemoteResumableSession(
      clientSessionId: id,
      scoresByCode: scores,
      durationS: durationS,
      startedOn: startedOn,
    );

void main() {
  group('fusion local × serveur', () {
    test('rien nulle part → aucune reprise proposée', () {
      expect(ResumeService.fusionne(), isNull);
    });

    test('une session vide de tout score ne se reprend pas', () {
      expect(ResumeService.fusionne(local: locale({})), isNull);
    });

    test('le serveur seul suffit — c\'est le cas de l\'appareil neuf', () {
      final r = ResumeService.fusionne(
        distant: distante({'block_design': 34}),
      )!;
      expect(r.completedCount, 1);
      expect(r.nextTestName, 'Similitudes');
      expect(r.knownToServer, isTrue);
      expect(r.clientSessionId, '6c0ac833-fb7f-4450-9e52-6721cdd6a498');
    });

    test('le local seul suffit — c\'est le cas hors ligne', () {
      final r = ResumeService.fusionne(
        local: locale({'block_design': 34, 'similarities': 21}),
        identifiantLocal: 'id-local',
      )!;
      expect(r.completedCount, 2);
      expect(r.nextTestName, 'Mémoire des Chiffres');
      expect(r.knownToServer, isFalse);
      expect(r.clientSessionId, 'id-local');
    });

    test('UNION : ni le local ni le serveur n\'est un sur-ensemble', () {
      // Le local porte un sous-test dont l\'envoi n\'est jamais parti ; le
      // serveur en porte un que cet appareil n\'a jamais vu.
      final r = ResumeService.fusionne(
        local: locale({'block_design': 34, 'digit_span': 18}),
        distant: distante({'block_design': 34, 'similarities': 21}),
      )!;
      expect(r.scoresByCode.keys.toSet(),
          {'block_design', 'similarities', 'digit_span'});
      expect(r.completedCount, 3);
      expect(r.nextTestName, 'Matrices');
    });

    test('scores divergents → le serveur fait autorité', () {
      final r = ResumeService.fusionne(
        local: locale({'block_design': 99}),
        distant: distante({'block_design': 34}),
      )!;
      expect(r.scoresByCode['block_design'], 34);
    });

    test(
        'un TROU dans la séquence est repris au premier ABSENT, '
        'jamais au n-ième', () {
      // Similitudes manque alors que trois sous-tests plus loin sont faits :
      // un simple compteur (`completedTests.length` = 3) désignerait Matrices
      // et sauterait Similitudes en silence.
      final r = ResumeService.fusionne(
        distant: distante({
          'block_design': 34,
          'digit_span': 18,
          'matrix_reasoning': 12,
        }),
      )!;
      expect(r.completedCount, 3);
      expect(r.nextIndex, 1);
      expect(r.nextTestName, 'Similitudes');
    });

    test('les 12 sont faits → il ne reste que la clôture', () {
      final tous = {
        for (final l in CompleteTestSession.testSequence)
          CompleteTestSession.subtestCodes[l]!: 10,
      };
      final r = ResumeService.fusionne(distant: distante(tous))!;
      expect(r.completedCount, 12);
      expect(r.isComplete, isTrue);
      expect(r.nextTestName, isNull);
    });

    test("l'identifiant du serveur prime sur celui de l'appareil", () {
      // Sinon la reprise ouvrirait une SECONDE passation et la première
      // resterait `in_progress` à jamais, ses mesures orphelines.
      final r = ResumeService.fusionne(
        local: locale({'block_design': 34}),
        distant: distante({'block_design': 34}, id: 'id-serveur'),
        identifiantLocal: 'id-local',
      )!;
      expect(r.clientSessionId, 'id-serveur');
    });

    test('un code de sous-test inconnu ne fait pas tomber la reprise', () {
      final r = ResumeService.fusionne(
        distant: distante({'block_design': 34, 'sous_test_du_futur': 7}),
      )!;
      expect(r.completedCount, 1);
      expect(r.nextTestName, 'Similitudes');
      expect(() => r.toSession(), returnsNormally);
    });
  });

  group('durée déjà acquise', () {
    test(
        "sur appareil neuf, le départ recule de la durée serveur — sinon la "
        'clôture tomberait sous le plancher de plausibilité', () {
      final r = ResumeService.fusionne(
        distant: distante({'block_design': 34}, durationS: 1800),
      )!;
      final ecoule = DateTime.now().difference(r.startTime).inSeconds;
      expect(ecoule, greaterThanOrEqualTo(1795));
    });

    test('le début local, quand il existe, reste la référence', () {
      final debut = DateTime.now().subtract(const Duration(minutes: 42));
      final r = ResumeService.fusionne(
        local: locale({'block_design': 34}, debut: debut),
        distant: distante({'block_design': 34}, durationS: 60),
      )!;
      expect(r.startTime, debut);
    });
  });

  group('reconstruction de la session', () {
    test('chaque code stable atterrit dans le bon champ de score', () {
      final r = ResumeService.fusionne(
        distant: distante({
          'block_design': 1,
          'similarities': 2,
          'digit_span': 3,
          'matrix_reasoning': 4,
          'vocabulary': 5,
          'arithmetic': 6,
          'symbol_search': 7,
          'visual_puzzles': 8,
          'information': 9,
          'coding': 10,
          'picture_span': 11,
          'figure_weights': 12,
        }),
      )!;
      final s = r.toSession();
      expect(s.cubesScore, 1);
      expect(s.similaritiesScore, 2);
      expect(s.digitSpanScore, 3);
      expect(s.matricesScore, 4);
      expect(s.vocabularyScore, 5);
      expect(s.arithmeticScore, 6);
      expect(s.symbolSearchScore, 7);
      expect(s.visualPuzzlesScore, 8);
      expect(s.informationScore, 9);
      expect(s.codingScore, 10);
      expect(s.pictureSpanScore, 11);
      expect(s.figureWeightsScore, 12);
      expect(s.isComplete, isTrue);
    });

    test("la session reprise pointe sur l'exercice suivant, pas sur zéro", () {
      final r = ResumeService.fusionne(
        distant: distante({'block_design': 34, 'similarities': 21}),
      )!;
      final s = r.toSession();
      expect(s.currentTestIndex, 2);
      expect(s.currentTestName, 'Mémoire des Chiffres');
      expect(s.completedTests, ['Cubes', 'Similitudes']);
      expect(s.completedTestsCount, 2);
    });
  });

  group('lecture de la réponse serveur', () {
    test('une charge bien formée est acceptée', () {
      final s = RemoteResumableSession.fromJson({
        'clientSessionId': '6c0ac833-fb7f-4450-9e52-6721cdd6a498',
        'startedOn': '2026-08-23',
        'durationS': 1800,
        'subtests': [
          {'subtest': 'block_design', 'rawScore': 34},
          {'subtest': 'similarities', 'rawScore': 21},
        ],
      })!;
      expect(s.scoresByCode, {'block_design': 34, 'similarities': 21});
      expect(s.durationS, 1800);
      expect(s.startedOn, DateTime.parse('2026-08-23'));
    });

    test('sans identifiant, rien n\'est reprenable', () {
      expect(RemoteResumableSession.fromJson({'subtests': []}), isNull);
    });

    test('un sous-test sans score exploitable est ignoré, jamais deviné', () {
      final s = RemoteResumableSession.fromJson({
        'clientSessionId': '6c0ac833-fb7f-4450-9e52-6721cdd6a498',
        'subtests': [
          {'subtest': 'block_design', 'rawScore': null},
          {'subtest': '', 'rawScore': 3},
          {'subtest': 'similarities', 'rawScore': 21},
        ],
      })!;
      expect(s.scoresByCode, {'similarities': 21});
    });
  });
}
