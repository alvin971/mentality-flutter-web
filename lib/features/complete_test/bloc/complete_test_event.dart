import 'package:equatable/equatable.dart';

abstract class CompleteTestEvent extends Equatable {
  const CompleteTestEvent();
  @override
  List<Object?> get props => [];
}

/// L'utilisateur a saisi son âge et démarre le test.
class StartTestEvent extends CompleteTestEvent {
  final int ageInMonths;
  const StartTestEvent(this.ageInMonths);
  @override
  List<Object?> get props => [ageInMonths];
}

/// Un sous-test s'est terminé avec un score donné.
class SubmitSubtestScoreEvent extends CompleteTestEvent {
  final String testName;
  final int score;
  const SubmitSubtestScoreEvent({required this.testName, required this.score});
  @override
  List<Object?> get props => [testName, score];
}

/// Tous les sous-tests sont complétés — calculer les résultats finaux.
class FinalizeTestEvent extends CompleteTestEvent {
  const FinalizeTestEvent();
}
