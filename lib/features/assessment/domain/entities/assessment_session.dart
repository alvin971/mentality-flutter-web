import 'package:equatable/equatable.dart';

/// Entité représentant une session d'évaluation complète
///
/// Une session regroupe tous les sous-tests administrés à un utilisateur
/// à une date donnée, avec leur configuration et progression
class AssessmentSession extends Equatable {
  /// Identifiant unique de la session
  final String id;

  /// ID de l'utilisateur évalué
  final String userId;

 /// Groupe d'âge déterminant la batterie de tests
  final String ageGroup;

  /// Âge exact en mois au moment de l'évaluation
  final int ageInMonths;

  /// Date de début de la session
  final DateTime startDate;

  /// Date de fin de la session (null si en cours)
  final DateTime? endDate;

  /// État actuel de la session
  final AssessmentState state;

  /// Liste des sous-tests à administrer
  final List<String> plannedSubtests;

  /// Liste des sous-tests complétés
  final List<String> completedSubtests;

  /// Sous-test actuellement en cours
  final String? currentSubtest;

  /// Durée totale de passation (en secondes)
  final int totalDurationSeconds;

  /// Mode de testing (adaptatif ou standard)
  final TestingMode mode;

  /// Configuration spécifique de la session
  final Map<String, dynamic> configuration;

  /// Métadonnées supplémentaires
  final Map<String, dynamic> metadata;

  const AssessmentSession({
    required this.id,
    required this.userId,
    required this.ageGroup,
    required this.ageInMonths,
    required this.startDate,
    this.endDate,
    required this.state,
    required this.plannedSubtests,
    required this.completedSubtests,
    this.currentSubtest,
    required this.totalDurationSeconds,
    required this.mode,
    required this.configuration,
    this.metadata = const {},
  });

  /// Vérifie si la session est terminée
  bool get isCompleted => state == AssessmentState.completed;

  /// Vérifie si la session est en cours
  bool get isInProgress => state == AssessmentState.inProgress;

  /// Vérifie si la session est en pause
  bool get isPaused => state == AssessmentState.paused;

  /// Calcule le pourcentage de progression
  double get progressPercentage {
    if (plannedSubtests.isEmpty) return 0.0;
    return (completedSubtests.length / plannedSubtests.length) * 100;
  }

  /// Nombre de sous-tests restants
  int get remainingSubtests => plannedSubtests.length - completedSubtests.length;

  /// Vérifie si un sous-test spécifique est complété
  bool isSubtestCompleted(String subtestCode) {
    return completedSubtests.contains(subtestCode);
  }

  /// Copie avec modifications
  AssessmentSession copyWith({
    String? id,
    String? userId,
    String? ageGroup,
    int? ageInMonths,
    DateTime? startDate,
    DateTime? endDate,
    AssessmentState? state,
    List<String>? plannedSubtests,
    List<String>? completedSubtests,
    String? currentSubtest,
    int? totalDurationSeconds,
    TestingMode? mode,
    Map<String, dynamic>? configuration,
    Map<String, dynamic>? metadata,
  }) {
    return AssessmentSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      ageGroup: ageGroup ?? this.ageGroup,
      ageInMonths: ageInMonths ?? this.ageInMonths,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      state: state ?? this.state,
      plannedSubtests: plannedSubtests ?? this.plannedSubtests,
      completedSubtests: completedSubtests ?? this.completedSubtests,
      currentSubtest: currentSubtest ?? this.currentSubtest,
      totalDurationSeconds: totalDurationSeconds ?? this.totalDurationSeconds,
      mode: mode ?? this.mode,
      configuration: configuration ?? this.configuration,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        ageGroup,
        ageInMonths,
        startDate,
        endDate,
        state,
        plannedSubtests,
        completedSubtests,
        currentSubtest,
        totalDurationSeconds,
        mode,
        configuration,
        metadata,
      ];
}

/// États possibles d'une session d'évaluation
enum AssessmentState {
  /// Pas encore démarrée
  notStarted,

  /// En cours
  inProgress,

  /// En pause
  paused,

  /// Terminée avec succès
  completed,

  /// Abandonnée
  abandoned,
}

/// Mode de testing
enum TestingMode {
  /// Testing adaptatif informatisé (CAT)
  adaptive,

  /// Batterie standard complète
  standard,

  /// Screening rapide
  screening,
}
