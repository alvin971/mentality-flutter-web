import 'dart:math' as math;

/// Service d'estimation du paramètre theta (niveau cognitif latent)
/// par la Théorie de Réponse à l'Item (IRT) — modèle 2PL.
///
/// Le modèle 2PL (2 paramètres logistiques) prédit la probabilité de réussite :
///   P(θ) = 1 / (1 + exp(−a × (θ − b)))
///
/// où :
///   θ = niveau cognitif de la personne (theta, à estimer)
///   a = discrimination de l'item (pente de la courbe)
///   b = difficulté de l'item (valeur de θ pour P = 0.5)
///
/// L'estimation de θ utilise la méthode de Maximum de Vraisemblance (MLE)
/// avec l'algorithme de Newton-Raphson.
class IrtService {
  const IrtService();

  // ─── Constantes ────────────────────────────────────────────────────────────

  /// Valeur initiale de theta au début de la session
  static const double initialTheta = 0.0;

  /// Plage de theta (−4 à +4 couvre > 99.9% de la population)
  static const double thetaMin = -4.0;
  static const double thetaMax = 4.0;

  /// Critère d'arrêt : erreur standard < 0.3 (soit ~4.5 points QI)
  static const double stoppingCriterion = 0.3;

  /// Nombre maximal d'itérations Newton-Raphson
  static const int maxIterations = 50;

  // ─── Modèle 2PL ────────────────────────────────────────────────────────────

  /// Calcule la probabilité de réussite pour un item donné.
  ///
  /// P(u=1 | θ, a, b) = 1 / (1 + exp(−a × (θ − b)))
  double probability({
    required double theta,
    required double discrimination, // paramètre a
    required double difficulty,     // paramètre b
  }) {
    final z = discrimination * (theta - difficulty);
    return 1.0 / (1.0 + math.exp(-z));
  }

  /// Calcule la quantité d'information de Fisher pour un item.
  ///
  /// I(θ) = a² × P(θ) × (1 − P(θ))
  double information({
    required double theta,
    required double discrimination,
    required double difficulty,
  }) {
    final p = probability(
      theta: theta,
      discrimination: discrimination,
      difficulty: difficulty,
    );
    return discrimination * discrimination * p * (1.0 - p);
  }

  // ─── Estimation MLE par Newton-Raphson ─────────────────────────────────────

  /// Estime theta par Maximum de Vraisemblance à partir des réponses observées.
  ///
  /// [items] : liste de tuples (discrimination a, difficulté b)
  /// [responses] : liste de réponses (1 = correct, 0 = incorrect)
  ///
  /// Retourne un [ThetaEstimate] avec theta estimé et erreur standard.
  ThetaEstimate estimateTheta({
    required List<({double a, double b})> items,
    required List<int> responses,
  }) {
    assert(items.length == responses.length,
        'items et responses doivent avoir la même longueur');

    if (items.isEmpty) {
      return ThetaEstimate(
        theta: initialTheta,
        standardError: double.infinity,
        fisherInformation: 0.0,
      );
    }

    double theta = initialTheta;

    for (int iter = 0; iter < maxIterations; iter++) {
      double firstDerivative = 0.0;
      double secondDerivative = 0.0;

      for (int i = 0; i < items.length; i++) {
        final a = items[i].a;
        final b = items[i].b;
        final u = responses[i];

        final p = probability(theta: theta, discrimination: a, difficulty: b);
        final q = 1.0 - p;

        // Première dérivée de la log-vraisemblance : ∂L/∂θ
        firstDerivative += a * (u - p);

        // Moins la deuxième dérivée (matrice d'information de Fisher observée)
        secondDerivative += a * a * p * q;
      }

      if (secondDerivative.abs() < 1e-10) break;

      // Mise à jour Newton-Raphson : θ_new = θ + (∂L/∂θ) / (∂²L/∂θ²)
      final delta = firstDerivative / secondDerivative;
      theta += delta;

      // Contraindre theta dans les bornes
      theta = theta.clamp(thetaMin, thetaMax);

      // Convergence
      if (delta.abs() < 1e-6) break;
    }

    // Erreur standard = 1 / √I(θ)
    final totalInfo = _totalInformation(theta: theta, items: items);
    final se = totalInfo > 0 ? 1.0 / math.sqrt(totalInfo) : double.infinity;

    return ThetaEstimate(
      theta: theta,
      standardError: se,
      fisherInformation: totalInfo,
    );
  }

  double _totalInformation({
    required double theta,
    required List<({double a, double b})> items,
  }) {
    return items.fold(0.0, (sum, item) {
      return sum +
          information(
            theta: theta,
            discrimination: item.a,
            difficulty: item.b,
          );
    });
  }

  // ─── Critère d'arrêt ───────────────────────────────────────────────────────

  /// Indique si l'estimation est suffisamment précise pour s'arrêter.
  bool shouldStop(ThetaEstimate estimate) {
    return estimate.standardError <= stoppingCriterion;
  }

  // ─── Conversion theta ↔ QI ─────────────────────────────────────────────────

  /// Convertit un theta IRT en score QI (μ=100, σ=15).
  ///
  /// θ suit une loi N(0,1), donc QI = 100 + 15 × θ
  int thetaToIQ(double theta) {
    return (100 + 15 * theta).round().clamp(40, 160);
  }

  /// Convertit un score QI en theta IRT.
  double iqToTheta(int iq) {
    return (iq - 100) / 15.0;
  }

  // ─── Sélection adaptative ──────────────────────────────────────────────────

  /// Sélectionne l'item avec la plus grande information pour le theta actuel.
  ///
  /// [candidates] : items candidats (non encore présentés)
  /// [currentTheta] : estimation courante de theta
  ///
  /// Retourne l'index de l'item le plus informatif dans [candidates].
  int selectNextItem({
    required List<({double a, double b})> candidates,
    required double currentTheta,
  }) {
    assert(candidates.isNotEmpty, 'La liste de candidats ne peut pas être vide');

    int bestIndex = 0;
    double bestInfo = -1.0;

    for (int i = 0; i < candidates.length; i++) {
      final info = information(
        theta: currentTheta,
        discrimination: candidates[i].a,
        difficulty: candidates[i].b,
      );
      if (info > bestInfo) {
        bestInfo = info;
        bestIndex = i;
      }
    }

    return bestIndex;
  }
}

/// Résultat de l'estimation theta.
class ThetaEstimate {
  /// Valeur estimée de theta (trait latent)
  final double theta;

  /// Erreur standard de mesure (SE = 1/√I)
  final double standardError;

  /// Information de Fisher totale accumulée
  final double fisherInformation;

  const ThetaEstimate({
    required this.theta,
    required this.standardError,
    required this.fisherInformation,
  });

  /// Score QI correspondant (μ=100, σ=15)
  int get iq => (100 + 15 * theta).round().clamp(40, 160);

  /// Intervalle de confiance 95% en QI
  ({int lower, int upper}) get confidenceInterval95 {
    final seIQ = 15 * standardError;
    final lower = (iq - 1.96 * seIQ).round().clamp(40, 160);
    final upper = (iq + 1.96 * seIQ).round().clamp(40, 160);
    return (lower: lower, upper: upper);
  }

  @override
  String toString() =>
      'ThetaEstimate(θ=${theta.toStringAsFixed(3)}, SE=${standardError.toStringAsFixed(3)}, IQ=$iq)';
}
