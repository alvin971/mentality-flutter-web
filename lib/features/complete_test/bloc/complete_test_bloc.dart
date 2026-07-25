import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/complete_test_session.dart';
import '../../../services/session_persistence_service.dart';
import 'complete_test_event.dart';
import 'complete_test_state.dart';

/// BLoC qui orchestre le déroulement du test complet WAIS-IV.
///
/// Gère :
/// - La séquence des 12 sous-tests NOTÉS (la 13e épreuve, le langage oral,
///   n'est pas notée : elle est orchestrée par la page, pas par ce BLoC)
/// - L'accumulation des scores
/// - La transition vers la page de résultats
class CompleteTestBloc extends Bloc<CompleteTestEvent, CompleteTestState> {
  CompleteTestBloc() : super(const CompleteTestIntroState()) {
    on<StartTestEvent>(_onStart);
    on<SubmitSubtestScoreEvent>(_onSubmitScore);
    on<FinalizeTestEvent>(_onFinalize);
  }

  late int _ageInMonths;

  Future<void> _onStart(
      StartTestEvent event, Emitter<CompleteTestState> emit) async {
    _ageInMonths = event.ageInMonths;
    final session = CompleteTestSession(startTime: DateTime.now());

    // Sauvegarder immédiatement la session de départ
    await SessionPersistenceService.instance
        .saveSession(session, _ageInMonths);

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
