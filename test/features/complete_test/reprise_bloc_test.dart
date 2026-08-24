// Le BLoC sait-il REPRENDRE, ou seulement recommencer ?
//
// C'était le défaut exact : `CompleteTestBloc` n'avait qu'une porte d'entrée,
// `StartTestEvent`, qui fabrique une session vierge à l'index 0. La bannière
// « Reprendre » de l'accueil menait à cette porte-là. Ces tests fixent la
// séparation des deux chemins.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mentality/core/models/complete_test_session.dart';
import 'package:mentality/core/services/auth_local_store.dart';
import 'package:mentality/core/services/resume_service.dart';
import 'package:mentality/features/complete_test/bloc/complete_test_bloc.dart';
import 'package:mentality/features/complete_test/bloc/complete_test_event.dart';
import 'package:mentality/features/complete_test/bloc/complete_test_state.dart';
import 'package:mentality/features/unlock/data/unlock_service.dart';
import 'package:mentality/services/session_persistence_service.dart';

const _age = 28 * 12;

ResumableSession reprise(Map<String, int> scores) => ResumeService.fusionne(
      distant: RemoteResumableSession(
        clientSessionId: '6c0ac833-fb7f-4450-9e52-6721cdd6a498',
        scoresByCode: scores,
      ),
    )!;

Map<String, int> get _lesDouze => {
      for (final l in CompleteTestSession.testSequence)
        CompleteTestSession.subtestCodes[l]!: 10,
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // AuthLocalStore dérive sa clé de chiffrement via SharedPreferences.
    SharedPreferences.setMockInitialValues({});
    Hive.init(Directory.systemTemp.createTempSync('mentality_reprise_bloc').path);
    await SessionPersistenceService.instance.initialize();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SessionPersistenceService.instance.clearSession();
  });

  test('StartTestEvent repart bien de zéro — comportement inchangé', () async {
    final bloc = CompleteTestBloc();
    bloc.add(const StartTestEvent(_age));
    final etat = await bloc.stream.firstWhere((e) => e is CompleteTestRunningState)
        as CompleteTestRunningState;
    expect(etat.session.currentTestIndex, 0);
    expect(etat.nextTestName, 'Cubes');
    expect(etat.session.completedTestsCount, 0);
    await bloc.close();
  });

  test(
      'un départ neuf LIBÈRE la passation précédente — sinon les deux bilans '
      'se mélangeraient dans la même ligne serveur', () async {
    await AuthLocalStore.instance.saveTestSessionId('ancienne-passation');
    final bloc = CompleteTestBloc();
    bloc.add(const StartTestEvent(_age));
    await bloc.stream.firstWhere((e) => e is CompleteTestRunningState);

    final neuf = await AuthLocalStore.instance.getTestSessionId();
    expect(neuf, isNotNull);
    expect(neuf, isNot('ancienne-passation'));
    // Et l'horloge démarre AVEC la batterie : sinon le premier envoi, émis à la
    // fin du premier exercice, porterait une durée nulle.
    final dates = await AuthLocalStore.instance.getTestSessionDates();
    expect(dates.ouverture, isNotNull);
    expect(dates.mesureDepuis, isNotNull);
    await bloc.close();
  });

  test('ResumeTestEvent enchaîne sur l\'exercice suivant, pas sur le premier',
      () async {
    final bloc = CompleteTestBloc();
    bloc.add(ResumeTestEvent(
      ageInMonths: _age,
      reprise: reprise({'block_design': 34, 'similarities': 21}),
    ));
    final etat = await bloc.stream.firstWhere((e) => e is CompleteTestRunningState)
        as CompleteTestRunningState;
    expect(etat.nextTestName, 'Mémoire des Chiffres');
    expect(etat.session.cubesScore, 34);
    expect(etat.session.similaritiesScore, 21);
    expect(etat.session.completedTestsCount, 2);
    await bloc.close();
  });

  test('la reprise est PERSISTÉE : une seconde interruption la retrouve',
      () async {
    final bloc = CompleteTestBloc();
    bloc.add(ResumeTestEvent(
      ageInMonths: _age,
      reprise: reprise({'block_design': 34}),
    ));
    await bloc.stream.firstWhere((e) => e is CompleteTestRunningState);
    final enregistre = SessionPersistenceService.instance.loadSession();
    expect(enregistre, isNotNull);
    expect(enregistre!.session.cubesScore, 34);
    expect(enregistre.session.currentTestIndex, 1);
    expect(enregistre.ageInMonths, _age);
    await bloc.close();
  });

  test(
      'les 12 déjà faits mais la clôture jamais aboutie → on va à la clôture, '
      'pas sur un exercice fantôme', () async {
    // Cas réel : réseau coupé au dernier envoi. Sans cette branche, la reprise
    // n'aurait aucun exercice à lancer et resterait figée sur « Lancement… ».
    final bloc = CompleteTestBloc();
    bloc.add(ResumeTestEvent(ageInMonths: _age, reprise: reprise(_lesDouze)));
    final etat = await bloc.stream.firstWhere((e) => e is CompleteTestDoneState)
        as CompleteTestDoneState;
    expect(etat.session.completedTestsCount, 12);
    expect(etat.ageInMonths, _age);
    expect(etat.session.endTime, isNotNull);
    await bloc.close();
  });

  test('une reprise terminée n\'est plus proposée : le local est effacé',
      () async {
    final bloc = CompleteTestBloc();
    bloc.add(ResumeTestEvent(ageInMonths: _age, reprise: reprise(_lesDouze)));
    await bloc.stream.firstWhere((e) => e is CompleteTestDoneState);
    expect(SessionPersistenceService.instance.hasPendingSession, isFalse);
    await bloc.close();
  });

  test('un sous-test terminé après reprise avance depuis le rang repris',
      () async {
    final bloc = CompleteTestBloc();
    bloc.add(ResumeTestEvent(
      ageInMonths: _age,
      reprise: reprise({'block_design': 34, 'similarities': 21}),
    ));
    await bloc.stream.firstWhere((e) => e is CompleteTestRunningState);
    bloc.add(const SubmitSubtestScoreEvent(
        testName: 'Mémoire des Chiffres', score: 18));
    final etat = await bloc.stream.firstWhere((e) =>
        e is CompleteTestRunningState && e.nextTestName == 'Matrices');
    expect((etat as CompleteTestRunningState).session.digitSpanScore, 18);
    expect(etat.session.completedTestsCount, 3);
    await bloc.close();
  });
}
