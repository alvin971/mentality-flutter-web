import 'package:equatable/equatable.dart';

import '../../../core/services/resume_service.dart';

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

/// L'utilisateur reprend un bilan interrompu : on repart à l'exercice suivant.
///
/// Distinct de [StartTestEvent] à dessein. Le démarrage crée une session vierge ;
/// la reprise en RECONSTRUIT une à partir de ce que le serveur et le stockage
/// local savent déjà. Confondre les deux, c'est ce que faisait l'app : la
/// bannière « Reprendre » de l'accueil menait au seul chemin existant, celui
/// qui repart de zéro.
class ResumeTestEvent extends CompleteTestEvent {
  final int ageInMonths;
  final ResumableSession reprise;
  const ResumeTestEvent({required this.ageInMonths, required this.reprise});
  @override
  List<Object?> get props => [ageInMonths, reprise];
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
