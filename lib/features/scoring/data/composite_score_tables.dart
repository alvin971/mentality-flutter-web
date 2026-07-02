import 'dart:math';

import '../../../core/l10n/l10n_ext.dart';
import 'scoring_params.dart';

/// Conversion des sommes de notes standardisées en scores composites (indices,
/// FSIQ), percentiles, intervalles de confiance et classifications.
///
/// Tout est dérivé d'un petit jeu de paramètres explicites ([ScoringParams]) :
///   - l'écart-type d'un composite est CALCULÉ depuis k et la corrélation r,
///   - le percentile est calculé analytiquement depuis N(100,15),
///   - l'IC utilise la régression vers la moyenne avec SEM = 15·√(1−rxx).
class CompositeScoreTables {
  CompositeScoreTables._();

  /// Calcule un score composite (indice ou FSIQ) à partir de la somme des notes
  /// standardisées de ses sous-tests.
  ///
  /// Modèle : k notes (moyenne 10, écart-type 3), corrélation moyenne r.
  ///   µ_somme = 10·k ;  σ_somme = 3·√(k + k(k−1)·r)
  ///   composite = 100 + 15·(somme − µ_somme) / σ_somme   (borné [40, 160])
  static int computeCompositeScore(String indexCode, int sumOfScaledScores) {
    final idx = ScoringParams.indices[indexCode];
    final k = idx?.k ?? 2;
    final r = idx?.r ?? 0.5;

    final muSum = 10.0 * k;
    final sigmaSum = 3.0 * sqrt(k + k * (k - 1) * r);
    final z = (sumOfScaledScores - muSum) / sigmaSum;

    return (100 + 15 * z).round().clamp(40, 160);
  }

  /// Percentile (1-99) correspondant à un score composite, calculé analytiquement
  /// depuis la loi normale N(100, 15).
  static int getPercentile(int iqScore) {
    final z = (iqScore.clamp(40, 160) - 100) / 15.0;
    final p = 100 * _normalCdf(z);
    return p.clamp(1.0, 99.0).round();
  }

  /// Intervalle de confiance à 95 % pour un score composite.
  ///
  /// Régression vers la moyenne : score_vrai = 100 + rxx·(score − 100) ;
  /// marge = 1.96·SEM avec SEM = 15·√(1 − rxx) (cohérent avec la fidélité).
  static (int lower, int upper) getConfidenceInterval(
      String indexCode, int compositeScore) {
    final rxx = ScoringParams.indices[indexCode]?.rxx ?? 0.93;
    final sem = 15 * sqrt(1 - rxx);

    final trueScore = (100 + rxx * (compositeScore - 100)).round();
    final margin = (1.96 * sem).round();

    return (
      (trueScore - margin).clamp(40, 160),
      (trueScore + margin).clamp(40, 160),
    );
  }

  /// Classification descriptive d'un score composite.
  static String classify(int compositeScore) {
    if (compositeScore >= 130) return appL10n.scoringClassificationVerySuperior;
    if (compositeScore >= 120) return appL10n.scoringClassificationSuperior;
    if (compositeScore >= 110) return appL10n.scoringClassificationHighAverage;
    if (compositeScore >= 90) return appL10n.scoringClassificationAverage;
    if (compositeScore >= 80) return appL10n.scoringClassificationLowAverage;
    if (compositeScore >= 70) return appL10n.scoringClassificationBorderline;
    return appL10n.scoringClassificationExtremelyLow;
  }

  // ───────────────────────────────────────────────────────────────────────
  // Loi normale cumulée via la fonction d'erreur (Abramowitz & Stegun 7.1.26)
  // ───────────────────────────────────────────────────────────────────────

  static double _normalCdf(double z) => 0.5 * (1 + _erf(z / sqrt2));

  static double _erf(double x) {
    final sign = x < 0 ? -1.0 : 1.0;
    final ax = x.abs();
    final t = 1.0 / (1.0 + 0.3275911 * ax);
    final y = 1.0 -
        (((((1.061405429 * t - 1.453152027) * t) + 1.421413741) * t -
                    0.284496736) *
                t +
            0.254829592) *
            t *
            exp(-ax * ax);
    return sign * y;
  }
}
