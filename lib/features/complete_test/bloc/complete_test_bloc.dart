import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/complete_test_session.dart';
import '../../../core/services/results_sync.dart';
import '../../../services/session_persistence_service.dart';
import 'complete_test_event.dart';
import 'complete_test_state.dart';

/// BLoC qui orchestre le déroulement du test complet.
///
/// Gère :
/// - La séquence des 12 sous-tests NOTÉS (la 13e épreuve, le langage oral,
///   n'est pas notée : elle est orchestrée par la page, pas par ce BLoC)
/// - L'accumulation des scores
/// - La transition vers la page de résultats
class CompleteTestBloc extends Bloc<CompleteTestEvent, CompleteTestState> {
  CompleteTestBloc() : super(const CompleteTestIntroState()) {
    on<StartTestEvent>(_onStart);
    on<ResumeTestEvent>(_onResume);
    on<SubmitSubtestScoreEvent>(_onSubmitScore);
    on<FinalizeTestEvent>(_onFinalize);
  }

  late int _ageInMonths;

  Future<void> _onStart(
      StartTestEvent event, Emitter<CompleteTestState> emit) async {
    _ageInMonths = event.ageInMonths;

    // Un DÉPART est un départ : on libère l'identifiant de la passation
    // précédente. Sans ça, l'app rouvrait la passation encore en cours — son
    // identifiant est persisté dans le coffre — et les sous-tests du nouveau
    // bilan venaient écraser ceux de l'ancien, un par un, dans la MÊME ligne
    // serveur. Deux passations mélangées, et rien pour les distinguer après
    // coup. L'ancienne reste `in_progress` jusqu'à ce que /results/session la
    // close (une seule passation ouverte par compte).
    await ResultsSync.instance.reset();
    // L'horloge de la passation démarre ICI, avec la batterie — pas au premier
    // envoi, qui n'a lieu qu'à la FIN du premier exercice.
    await ResultsSync.instance.demarrer();

    final session = CompleteTestSession(startTime: DateTime.now());

    // Sauvegarder immédiatement la session de départ
    await SessionPersistenceService.instance
        .saveSession(session, _ageInMonths);

    emit(CompleteTestRunningState(
      session: session,
      nextTestName: session.currentTestName,
    ));
  }

  /// Reprise d'un bilan interrompu.
  ///
  /// La session est reconstruite avec les scores déjà connus et l'index posé sur
  /// le premier exercice ABSENT — pas sur un compteur : la séquence peut avoir
  /// des trous, et un compteur en sauterait un silencieusement.
  Future<void> _onResume(
      ResumeTestEvent event, Emitter<CompleteTestState> emit) async {
    _ageInMonths = event.ageInMonths;
    // Sans identifiant à réadopter (reprise purement locale), la passation
    // s'ouvre ici. Sinon `ResumeService.adopt` l'a déjà fait et ceci ne fait
    // rien.
    await ResultsSync.instance.demarrer();
    final session = event.reprise.toSession();

    if (session.isComplete) {
      // Les 12 sous-tests sont faits, mais la clôture n'a jamais abouti (réseau
      // coupé au dernier envoi, app tuée entre la batterie et l'épreuve orale).
      // Sans cette branche, la reprise n'aurait aucun exercice à lancer et
      // resterait bloquée sur « Lancement… ». On enchaîne sur la clôture.
      await SessionPersistenceService.instance.clearSession();
      emit(CompleteTestAwaitingNextState(session));
      add(const FinalizeTestEvent());
      return;
    }

    await SessionPersistenceService.instance.saveSession(session, _ageInMonths);
    emit(CompleteTestRunningState(
      session: session,
      nextTestName: session.currentTestName,
    ));
  }

  Future<void> _onSubmitScore(
    SubmitSubtestScoreEvent event,
    Emitter<CompleteTestState> emit,
  ) async {
    if (state is! CompleteTestRunningState) return;

    final current = (state as CompleteTestRunningState).session;
    var updated = _applyScore(current, event.testName, event.score);

    // Avancer manuellement l'index (évite la mutation in-place du modèle)
    final nextIndex = updated.currentTestIndex + 1;
    final newCompleted = [...updated.completedTests, event.testName];
    updated = updated.copyWith(
      currentTestIndex: nextIndex,
      completedTests: newCompleted,
    );

    if (updated.isComplete) {
      // Supprimer la session sauvegardée car le test est terminé
      await SessionPersistenceService.instance.clearSession();
      emit(CompleteTestAwaitingNextState(updated));
      add(const FinalizeTestEvent());
    } else {
      // Sauvegarder la progression en cours
      await SessionPersistenceService.instance
          .saveSession(updated, _ageInMonths);
      emit(CompleteTestRunningState(
        session: updated,
        nextTestName: updated.currentTestName,
      ));
    }
  }

  void _onFinalize(
    FinalizeTestEvent event,
    Emitter<CompleteTestState> emit,
  ) {
    if (state is! CompleteTestAwaitingNextState) return;
    final session = (state as CompleteTestAwaitingNextState)
        .session
        .copyWith(endTime: DateTime.now());

    emit(CompleteTestDoneState(session: session, ageInMonths: _ageInMonths));
  }

  /// Applique le score d'un sous-test au modèle de session.
  CompleteTestSession _applyScore(
    CompleteTestSession session,
    String testName,
    int score,
  ) {
    // Sous-test administré mais non noté : le champ reste NUL. Il compte
    // néanmoins comme terminé — c'est `completedTests` qui porte la
    // progression, pas la présence d'un score.
    if (score == CompleteTestSession.awaitingAiScore) return session;
    switch (testName) {
      case 'Cubes':
        return session.copyWith(cubesScore: score);
      case 'Similitudes':
        return session.copyWith(similaritiesScore: score);
      case 'Mémoire des Chiffres':
        return session.copyWith(digitSpanScore: score);
      case 'Matrices':
        return session.copyWith(matricesScore: score);
      case 'Vocabulaire':
        return session.copyWith(vocabularyScore: score);
      case 'Arithmétique':
        return session.copyWith(arithmeticScore: score);
      case 'Recherche de Symboles':
        return session.copyWith(symbolSearchScore: score);
      case 'Puzzles Visuels':
        return session.copyWith(visualPuzzlesScore: score);
      case 'Information':
        return session.copyWith(informationScore: score);
      case 'Code':
        return session.copyWith(codingScore: score);
      case 'Mémoire des Images':
        return session.copyWith(pictureSpanScore: score);
      case 'Balances':
        return session.copyWith(figureWeightsScore: score);
      default:
        return session;
    }
  }
}
