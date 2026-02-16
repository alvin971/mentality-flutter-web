import 'package:equatable/equatable.dart';
import 'dart:math' as math;

/// Estimation bayésienne de la capacité (θ) dans le cadre IRT
///
/// Cette classe implémente l'algorithme d'estimation adaptative de la capacité
/// cognitive basée sur la théorie de réponse aux items (IRT)
class ThetaEstimate extends Equatable {
  /// Valeur actuelle de θ (capacité estimée)
  final double theta;

  /// Erreur standard de l'estimation
  final double standardError;

  /// Nombre de réponses utilisées pour l'estimation
  final int responsesCount;

  /// Historique des réponses (item ID + correct/incorrect)
  final List<ResponseRecord> responseHistory;

  /// Information cumulée
  final double cumulativeInformation;

  /// Distribution a posteriori (optionnelle, pour visualisation)
  final Map<double, double>? posteriorDistribution;

  const ThetaEstimate({
    required this.theta,
    required this.standardError,
    required this.responsesCount,
    required this.responseHistory,
    required this.cumulativeInformation,
    this.posteriorDistribution,
  });

  /// Estimation initiale (avant toute réponse)
  factory ThetaEstimate.initial() {
    return const ThetaEstimate(
      theta: 0.0,
      standardError: 1.0,
      responsesCount: 0,
      responseHistory: [],
      cumulativeInformation: 0.0,
    );
  }

  /// Vérifie si le critère d'arrêt est atteint
  bool hasReachedStoppingCriterion(double seThreshold) {
    return standardError <= seThreshold;
  }

  /// Calcule l'intervalle de confiance à 95%
  ConfidenceInterval95 get confidenceInterval {
    final margin = 1.96 * standardError;
    return ConfidenceInterval95(
      lowerBound: theta - margin,
      upperBound: theta + margin,
    );
  }

  /// Met à jour θ après une nouvelle réponse (Maximum Likelihood Estimation)
  ///
  /// Utilise l'algorithme de Newton-Raphson pour trouver le θ qui maximise
  /// la vraisemblance des réponses observées
  ThetaEstimate updateWithResponse({
    required String itemId,
    required double itemDifficulty,
    required double itemDiscrimination,
    required bool isCorrect,
    int maxIterations = 20,
    double convergenceThreshold = 0.001,
  }) {
    final newResponse = ResponseRecord(
      itemId: itemId,
      difficulty: itemDifficulty,
      discrimination: itemDiscrimination,
      isCorrect: isCorrect,
      timestamp: DateTime.now(),
    );

    final updatedHistory = [...responseHistory, newResponse];

    // Estimation par Newton-Raphson
    double currentTheta = theta;

    for (int iteration = 0; iteration < maxIterations; iteration++) {
      double firstDerivative = 0.0;
      double secondDerivative = 0.0;

      // Calcul des dérivées de la log-vraisemblance
      for (final response in updatedHistory) {
        final prob = _calculateProbability(
          currentTheta,
          response.difficulty,
          response.discrimination,
        );

        final weight = response.discrimination * response.discrimination * prob * (1 - prob);

        if (response.isCorrect) {
          firstDerivative += response.discrimination * (1 - prob);
          secondDerivative -= weight;
        } else {
          firstDerivative -= response.discrimination * prob;
          secondDerivative -= weight;
        }
      }

      // Mise à jour de θ
      final delta = -firstDerivative / secondDerivative;
      currentTheta += delta;

      // Vérification de convergence
      if (delta.abs() < convergenceThreshold) break;
    }

    // Calcul de l'information et de l'erreur standard
    double totalInformation = 0.0;

    for (final response in updatedHistory) {
      final prob = _calculateProbability(
        currentTheta,
        response.difficulty,
        response.discrimination,
      );
      final information =
          response.discrimination * response.discrimination * prob * (1 - prob);
      totalInformation += information;
    }

    final newSE = totalInformation > 0 ? 1 / math.sqrt(totalInformation) : 1.0;

    return ThetaEstimate(
      theta: currentTheta,
      standardError: newSE,
      responsesCount: updatedHistory.length,
      responseHistory: updatedHistory,
      cumulativeInformation: totalInformation,
    );
  }

  /// Calcule la probabilité de réponse correcte selon le modèle 2PL
  ///
  /// P(θ) = 1 / (1 + exp(-a(θ - b)))
  double _calculateProbability(double theta, double difficulty, double discrimination) {
    final exponent = -discrimination * (theta - difficulty);
    return 1 / (1 + math.exp(exponent));
  }

  /// Calcule l'information apportée par un item hypothétique
  double calculateItemInformation(double itemDifficulty, double itemDiscrimination) {
    final prob = _calculateProbability(theta, itemDifficulty, itemDiscrimination);
    return itemDiscrimination * itemDiscrimination * prob * (1 - prob);
  }

  /// Convertit θ en score standard (moyenne 10, écart-type 3)
  int toScaledScore() {
    return (10 + theta * 3).round().clamp(1, 19);
  }

  /// Convertit θ en QI (moyenne 100, écart-type 15)
  int toIQScore() {
    return (100 + theta * 15).round().clamp(40, 160);
  }

  /// Copie avec modifications
  ThetaEstimate copyWith({
    double? theta,
    double? standardError,
    int? responsesCount,
    List<ResponseRecord>? responseHistory,
    double? cumulativeInformation,
    Map<double, double>? posteriorDistribution,
  }) {
    return ThetaEstimate(
      theta: theta ?? this.theta,
      standardError: standardError ?? this.standardError,
      responsesCount: responsesCount ?? this.responsesCount,
      responseHistory: responseHistory ?? this.responseHistory,
      cumulativeInformation: cumulativeInformation ?? this.cumulativeInformation,
      posteriorDistribution: posteriorDistribution ?? this.posteriorDistribution,
    );
  }

  @override
  List<Object?> get props => [
        theta,
        standardError,
        responsesCount,
        responseHistory,
        cumulativeInformation,
        posteriorDistribution,
      ];

  @override
  String toString() {
    return 'ThetaEstimate(θ: ${theta.toStringAsFixed(3)}, SE: ${standardError.toStringAsFixed(3)}, '
        'Responses: $responsesCount, Info: ${cumulativeInformation.toStringAsFixed(2)})';
  }
}

/// Enregistrement d'une réponse individuelle
class ResponseRecord extends Equatable {
  /// ID de l'item
  final String itemId;

  /// Difficulté de l'item
  final double difficulty;

  /// Discrimination de l'item
  final double discrimination;

  /// Réponse correcte ?
  final bool isCorrect;

  /// Horodatage de la réponse
  final DateTime timestamp;

  const ResponseRecord({
    required this.itemId,
    required this.difficulty,
    required this.discrimination,
    required this.isCorrect,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [itemId, difficulty, discrimination, isCorrect, timestamp];
}

/// Intervalle de confiance à 95%
class ConfidenceInterval95 extends Equatable {
  final double lowerBound;
  final double upperBound;

  const ConfidenceInterval95({
    required this.lowerBound,
    required this.upperBound,
  });

  double get width => upperBound - lowerBound;

  @override
  List<Object?> get props => [lowerBound, upperBound];

  @override
  String toString() => '[${lowerBound.toStringAsFixed(2)}, ${upperBound.toStringAsFixed(2)}]';
}

/// Critère d'arrêt pour le testing adaptatif
class StoppingCriterion extends Equatable {
  /// Erreur standard maximale acceptable
  final double maxStandardError;

  /// Nombre minimum d'items
  final int minItems;

  /// Nombre maximum d'items
  final int maxItems;

  /// Temps maximum (secondes)
  final int? maxTimeSeconds;

  const StoppingCriterion({
    this.maxStandardError = 0.3,
    this.minItems = 5,
    this.maxItems = 15,
    this.maxTimeSeconds,
  });

  /// Vérifie si le critère est atteint
  bool isReached(ThetaEstimate estimate, int elapsedSeconds) {
    // Minimum d'items requis
    if (estimate.responsesCount < minItems) return false;

    // Maximum d'items atteint
    if (estimate.responsesCount >= maxItems) return true;

    // Temps maximum dépassé
    if (maxTimeSeconds != null && elapsedSeconds >= maxTimeSeconds!) return true;

    // Précision suffisante atteinte
    if (estimate.standardError <= maxStandardError) return true;

    return false;
  }

  @override
  List<Object?> get props => [maxStandardError, minItems, maxItems, maxTimeSeconds];
}
