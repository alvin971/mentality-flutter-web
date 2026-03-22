import 'package:equatable/equatable.dart';
import '../../../core/models/complete_test_session.dart';

abstract class CompleteTestState extends Equatable {
  const CompleteTestState();
  @override
  List<Object?> get props => [];
}

/// Écran d'introduction — saisie de l'âge
class CompleteTestIntroState extends CompleteTestState {
  const CompleteTestIntroState();
}

/// Test en cours d'exécution
class CompleteTestRunningState extends CompleteTestState {
  final CompleteTestSession session;
  final String nextTestName;

  const CompleteTestRunningState({
    required this.session,
    required this.nextTestName,
  });

  @override
  List<Object?> get props => [session, nextTestName];
}

/// En attente du lancement du prochain sous-test (délai 500ms)
class CompleteTestAwaitingNextState extends CompleteTestState {
  final CompleteTestSession session;

  const CompleteTestAwaitingNextState(this.session);

  @override
  List<Object?> get props => [session];
}

/// Tous les sous-tests sont terminés — résultats prêts
class CompleteTestDoneState extends CompleteTestState {
  final CompleteTestSession session;
  final int ageInMonths;

  const CompleteTestDoneState({
    required this.session,
    required this.ageInMonths,
  });

  @override
  List<Object?> get props => [session, ageInMonths];
}
