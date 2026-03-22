/// Tables de conversion pour scores composites et QI Total
/// Basé sur les paramètres psychométriques du WAIS-IV
///
/// Contient :
///   - Paramètres de fidélité (rxx) et d'erreur standard (SEM) par indice
///   - Table de correspondance QI → percentile
///   - Facteurs de correction pour le calcul des indices composites
class CompositeScoreTables {
  CompositeScoreTables._();

  // ─────────────────────────────────────────────────────────────────────────
  // PARAMÈTRES DE FIDÉLITÉ ET SEM PAR INDICE
  // rxx = coefficient de fidélité test-retest (WAIS-IV manuel)
  // sem = erreur standard de mesure en points QI
  // ─────────────────────────────────────────────────────────────────────────

  static const Map<String, double> _reliabilityCoefficients = {
    'FSIQ': 0.97,
    'VCI': 0.96,
    'VSI': 0.94,
    'FRI': 0.93,
    'WMI': 0.93,
    'PSI': 0.90,
  };

  static const Map<String, double> _standardErrorsOfMeasurement = {
    'FSIQ': 2.6,
    'VCI': 3.0,
    'VSI': 3.7,
    'FRI': 3.9,
    'WMI': 3.9,
    'PSI': 4.7,
  };

  // ─────────────────────────────────────────────────────────────────────────
  // FACTEURS DE CORRECTION POUR CALCUL DES INDICES COMPOSITES
  // Ajuste pour les corrélations inter-sous-tests (méthode WAIS-IV)
  //
  // La formule est : composite = 100 + 15 * (sum - mu) / sigma_corrigé
  // où sigma_corrigé tient compte des corrélations entre sous-tests
  // ─────────────────────────────────────────────────────────────────────────

  /// Paramètres de distribution pour chaque indice composite
  /// (espérance de la somme des notes standardisées, écart-type corrigé)
  static const Map<String, Map<String, double>> _indexDistributions = {
    // VCI : SI + VO + IN (3 sous-tests, corrélation inter ≈ 0.65)
    // mu_somme = 30, sigma_somme_corrigée ≈ 8.2
    'VCI': {'mu': 30.0, 'sigma': 8.2},

    // VSI : BD + VP (2 sous-tests, corrélation inter ≈ 0.58)
    // mu_somme = 20, sigma_somme_corrigée ≈ 5.4
    'VSI': {'mu': 20.0, 'sigma': 5.4},

    // FRI : MR + FW (2 sous-tests, corrélation inter ≈ 0.55)
    // mu_somme = 20, sigma_somme_corrigée ≈ 5.5
    'FRI': {'mu': 20.0, 'sigma': 5.5},

    // WMI : DS + AR (2 sous-tests, corrélation inter ≈ 0.52)
    // mu_somme = 20, sigma_somme_corrigée ≈ 5.7
    'WMI': {'mu': 20.0, 'sigma': 5.7},

    // PSI : CD + SS (2 sous-tests, corrélation inter ≈ 0.48)
    // mu_somme = 20, sigma_somme_corrigée ≈ 5.8
    'PSI': {'mu': 20.0, 'sigma': 5.8},
  };

  /// Paramètres pour le calcul du FSIQ
  /// Basé sur les 10 sous-tests primaires (BD+SI+DS+MR+VO+AR+SS+VP+IN+CD)
  /// mu = 100, sigma corrigée ≈ 18.5 (forte corrélation due au facteur g)
  static const Map<String, double> _fsiqDistribution = {
    'mu': 100.0,
    'sigma': 18.5,
  };

  // ─────────────────────────────────────────────────────────────────────────
  // TABLE QI → PERCENTILE
  // Basé sur la distribution normale N(100, 15)
  // ─────────────────────────────────────────────────────────────────────────

  static const Map<int, int> _iqToPercentile = {
    40: 0, 41: 0, 42: 0, 43: 0, 44: 0, 45: 0,
    46: 0, 47: 0, 48: 0, 49: 0, 50: 0,
    51: 0, 52: 0, 53: 0, 54: 0, 55: 1,
    56: 1, 57: 1, 58: 1, 59: 1, 60: 1,
    61: 1, 62: 1, 63: 1, 64: 1, 65: 1,
    66: 1, 67: 1, 68: 2, 69: 2, 70: 2,
    71: 3, 72: 3, 73: 4, 74: 4, 75: 5,
    76: 5, 77: 6, 78: 7, 79: 8, 80: 9,
    81: 10, 82: 12, 83: 13, 84: 14, 85: 16,
    86: 18, 87: 19, 88: 21, 89: 23, 90: 25,
    91: 27, 92: 30, 93: 32, 94: 34, 95: 37,
    96: 39, 97: 42, 98: 45, 99: 47, 100: 50,
    101: 53, 102: 55, 103: 58, 104: 61, 105: 63,
    106: 66, 107: 68, 108: 70, 109: 73, 110: 75,
    111: 77, 112: 79, 113: 81, 114: 82, 115: 84,
    116: 86, 117: 87, 118: 88, 119: 90, 120: 91,
    121: 92, 122: 93, 123: 94, 124: 95, 125: 95,
    126: 96, 127: 96, 128: 97, 129: 97, 130: 98,
    131: 98, 132: 98, 133: 99, 134: 99, 135: 99,
    136: 99, 137: 99, 138: 99, 139: 99, 140: 99,
    141: 99, 142: 99, 143: 99, 144: 99, 145: 99,
    146: 99, 147: 99, 148: 99, 149: 99, 150: 99,
    151: 99, 152: 99, 153: 99, 154: 99, 155: 99,
    156: 99, 157: 99, 158: 99, 159: 99, 160: 99,
  };

  // ─────────────────────────────────────────────────────────────────────────
  // MÉTHODES PUBLIQUES
  // ─────────────────────────────────────────────────────────────────────────

  /// Calcule un score composite (indice ou FSIQ) à partir de la somme des notes standardisées
  ///
  /// [indexCode] : 'VCI', 'VSI', 'FRI', 'WMI', 'PSI' ou 'FSIQ'
  /// [sumOfScaledScores] : somme des notes standardisées des sous-tests de l'indice
  static int computeCompositeScore(String indexCode, int sumOfScaledScores) {
    final Map<String, double> params;
    if (indexCode == 'FSIQ') {
      params = _fsiqDistribution;
    } else {
      params = _indexDistributions[indexCode] ?? {'mu': 20.0, 'sigma': 5.7};
    }

    final mu = params['mu']!;
    final sigma = params['sigma']!;
    final z = (sumOfScaledScores - mu) / sigma;
    final composite = (100 + 15 * z).round();
    return composite.clamp(40, 160);
  }

  /// Retourne le percentile correspondant à un score QI
  static int getPercentile(int iqScore) {
    final clamped = iqScore.clamp(40, 160);
    return _iqToPercentile[clamped] ?? 50;
  }

  /// Calcule l'intervalle de confiance à 95% pour un score composite
  ///
  /// Utilise la correction de régression vers la moyenne (standard WAIS-IV) :
  /// Score vrai estimé = 100 + rxx × (score - 100)
  /// Marge = 1.96 × SEM
  ///
  /// [indexCode] : 'FSIQ', 'VCI', 'VSI', 'FRI', 'WMI' ou 'PSI'
  /// [compositeScore] : score composite obtenu
  static (int lower, int upper) getConfidenceInterval(
      String indexCode, int compositeScore) {
    final rxx = _reliabilityCoefficients[indexCode] ?? 0.93;
    final sem = _standardErrorsOfMeasurement[indexCode] ?? 3.5;

    // Correction de régression vers la moyenne
    final trueScore = (100 + rxx * (compositeScore - 100)).round();

    // Marge IC 95% : z = 1.96
    final margin = (1.96 * sem).round();

    return (
      (trueScore - margin).clamp(40, 160),
      (trueScore + margin).clamp(40, 160),
    );
  }

  /// Retourne la classification descriptive pour un score composite
  static String classify(int compositeScore) {
    if (compositeScore >= 130) return 'Très supérieur';
    if (compositeScore >= 120) return 'Supérieur';
    if (compositeScore >= 110) return 'Moyen fort';
    if (compositeScore >= 90) return 'Moyen';
    if (compositeScore >= 80) return 'Moyen faible';
    if (compositeScore >= 70) return 'Limite';
    return 'Extrêmement bas';
  }
}
