import 'dart:math' as math;
import 'package:equatable/equatable.dart';

/// Entité représentant un item d'exercice individuel
///
/// Chaque item est l'unité de base de l'évaluation, avec ses paramètres IRT,
/// son stimulus, ses options de réponse et ses règles de scoring
class ExerciseItem extends Equatable {
  /// Identifiant unique de l'item
  final String id;

  /// Type d'exercice (matrices, balances, etc.)
  final ExerciseType type;

  /// Code du sous-test auquel appartient l'item
  final String subtestCode;

  /// Paramètre de difficulté IRT (échelle logit)
  final double difficulty;

  /// Paramètre de discrimination IRT
  final double discrimination;

  /// Paramètre de pseudo-chance (pour modèles 3PL)
  final double? guessing;

  /// Niveau de difficulté descriptif
  final DifficultyLevel difficultyLevel;

  /// Données du stimulus (image, texte, audio, etc.)
  final Stimulus stimulus;

  /// Options de réponse (pour choix multiples)
  final List<ResponseOption>? options;

  /// Réponse correcte (ID ou valeur)
  final String correctAnswer;

  /// Type de réponse attendue
  final ResponseType responseType;

  /// Temps limite en secondes (null si non chronométré)
  final int? timeLimit;

  /// Instructions spécifiques à l'item
  final String? instructions;

  /// Métadonnées de génération (pour items générés par IA)
  final ItemMetadata? metadata;

  /// Configuration visuelle et comportementale
  final Map<String, dynamic> configuration;

  /// Règles de scoring spécifiques
  final ScoringRules? scoringRules;

  const ExerciseItem({
    required this.id,
    required this.type,
    required this.subtestCode,
    required this.difficulty,
    required this.discrimination,
    this.guessing,
    required this.difficultyLevel,
    required this.stimulus,
    this.options,
    required this.correctAnswer,
    required this.responseType,
    this.timeLimit,
    this.instructions,
    this.metadata,
    this.configuration = const {},
    this.scoringRules,
  });

  /// Vérifie si l'item a une limite de temps
  bool get isTimed => timeLimit != null;

  /// Vérifie si l'item a des options de choix multiple
  bool get hasOptions => options != null && options!.isNotEmpty;

  /// Calcule la probabilité de réponse correcte selon IRT (modèle 2PL)
  ///
  /// P(θ) = 1 / (1 + exp(-a(θ - b)))
  /// où θ = capacité de la personne, a = discrimination, b = difficulté
  double calculateProbability(double theta) {
    final exponent = -discrimination * (theta - difficulty);
    return 1 / (1 + math.exp(exponent));
  }

  /// Calcule l'information apportée par l'item à un niveau de capacité θ
  ///
  /// I(θ) = a² × P(θ) × [1 - P(θ)]
  double calculateInformation(double theta) {
    final probability = calculateProbability(theta);
    return discrimination * discrimination * probability * (1 - probability);
  }

  /// Copie avec modifications
  ExerciseItem copyWith({
    String? id,
    ExerciseType? type,
    String? subtestCode,
    double? difficulty,
    double? discrimination,
    double? guessing,
    DifficultyLevel? difficultyLevel,
    Stimulus? stimulus,
    List<ResponseOption>? options,
    String? correctAnswer,
    ResponseType? responseType,
    int? timeLimit,
    String? instructions,
    ItemMetadata? metadata,
    Map<String, dynamic>? configuration,
    ScoringRules? scoringRules,
  }) {
    return ExerciseItem(
      id: id ?? this.id,
      type: type ?? this.type,
      subtestCode: subtestCode ?? this.subtestCode,
      difficulty: difficulty ?? this.difficulty,
      discrimination: discrimination ?? this.discrimination,
      guessing: guessing ?? this.guessing,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      stimulus: stimulus ?? this.stimulus,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      responseType: responseType ?? this.responseType,
      timeLimit: timeLimit ?? this.timeLimit,
      instructions: instructions ?? this.instructions,
      metadata: metadata ?? this.metadata,
      configuration: configuration ?? this.configuration,
      scoringRules: scoringRules ?? this.scoringRules,
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        subtestCode,
        difficulty,
        discrimination,
        guessing,
        difficultyLevel,
        stimulus,
        options,
        correctAnswer,
        responseType,
        timeLimit,
        instructions,
        metadata,
        configuration,
        scoringRules,
      ];
}

/// Types d'exercices
enum ExerciseType {
  matrixReasoning,
  figureWeights,
  visualPuzzles,
  blockDesign,
  coding,
  symbolSearch,
  digitSpan,
  pictureMemory,
  letterNumberSequencing,
  vocabularyReceptive,
  vocabularyExpressive,
  similarities,
  information,
  comprehension,
  cancellation,
  arithmetic,
}

/// Niveaux de difficulté descriptifs
enum DifficultyLevel {
  veryEasy,
  easy,
  medium,
  hard,
  veryHard,
}

/// Types de réponse
enum ResponseType {
  multipleChoice,
  textInput,
  voiceInput,
  dragDrop,
  tap,
  draw,
  sequence,
}

/// Représente le stimulus (question/image/son)
class Stimulus extends Equatable {
  /// Type de stimulus
  final StimulusType type;

  /// Contenu (URL, texte, etc.)
  final String content;

  /// Données supplémentaires (pour stimuli complexes)
  final Map<String, dynamic>? data;

  const Stimulus({
    required this.type,
    required this.content,
    this.data,
  });

  @override
  List<Object?> get props => [type, content, data];
}

/// Types de stimulus
enum StimulusType {
  image,
  text,
  audio,
  video,
  composite, // Combinaison de plusieurs types
}

/// Option de réponse pour choix multiples
class ResponseOption extends Equatable {
  /// Identifiant de l'option
  final String id;

  /// Contenu de l'option
  final String content;

  /// Type de contenu (texte, image, etc.)
  final StimulusType contentType;

  /// Est-ce la réponse correcte ?
  final bool isCorrect;

  /// Est-ce un distracteur plausible ?
  final bool isDistractor;

  const ResponseOption({
    required this.id,
    required this.content,
    required this.contentType,
    required this.isCorrect,
    this.isDistractor = false,
  });

  @override
  List<Object?> get props => [id, content, contentType, isCorrect, isDistractor];
}

/// Métadonnées de l'item
class ItemMetadata extends Equatable {
  /// Date de création
  final DateTime createdAt;

  /// Généré par IA ?
  final bool isAIGenerated;

  /// Modèle d'IA utilisé (si applicable)
  final String? aiModel;

  /// Nombre de fois présenté
  final int timesAdministered;

  /// Nombre de réponses correctes
  final int correctResponses;

  /// Taux de réussite empirique
  double get successRate =>
      timesAdministered > 0 ? correctResponses / timesAdministered : 0.0;

  /// Hash pour détection de doublons
  final String? contentHash;

  /// Tags pour classification
  final List<String> tags;

  const ItemMetadata({
    required this.createdAt,
    required this.isAIGenerated,
    this.aiModel,
    required this.timesAdministered,
    required this.correctResponses,
    this.contentHash,
    this.tags = const [],
  });

  @override
  List<Object?> get props => [
        createdAt,
        isAIGenerated,
        aiModel,
        timesAdministered,
        correctResponses,
        contentHash,
        tags,
      ];
}

/// Règles de scoring spécifiques
class ScoringRules extends Equatable {
  /// Scoring dichotomique (0 ou 1) ?
  final bool isDichotomous;

  /// Points maximum
  final int maxPoints;

  /// Bonus de temps (pour Cubes)
  final Map<int, int>? timeBonus;

  /// Pénalité pour erreur
  final int? errorPenalty;

  /// Scoring partiel autorisé ?
  final bool allowPartialCredit;

  const ScoringRules({
    required this.isDichotomous,
    required this.maxPoints,
    this.timeBonus,
    this.errorPenalty,
    this.allowPartialCredit = false,
  });

  @override
  List<Object?> get props => [
        isDichotomous,
        maxPoints,
        timeBonus,
        errorPenalty,
        allowPartialCredit,
      ];
}

