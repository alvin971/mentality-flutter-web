/// Constantes psychométriques du modèle CHC
/// Respecte les standards internationaux de psychométrie
class PsychometricConstants {
  PsychometricConstants._();

  // ========================================
  // PARAMÈTRES DE STANDARDISATION
  // ========================================

  /// Moyenne des notes standard des sous-tests
  static const int subtestMean = 10;

  /// Écart-type des notes standard des sous-tests
  static const int subtestStdDev = 3;

  /// Plage minimale des notes standard
  static const int subtestMinScore = 1;

  /// Plage maximale des notes standard
  static const int subtestMaxScore = 19;

  /// Moyenne du QI Total et des indices composites
  static const int iqMean = 100;

  /// Écart-type du QI Total et des indices composites
  static const int iqStdDev = 15;

  /// QI minimum possible
  static const int iqMinScore = 40;

  /// QI maximum possible
  static const int iqMaxScore = 160;

  // ========================================
  // INDICES COMPOSITES
  // ========================================

  /// Indice de Compréhension Verbale
  static const String indexVCI = 'VCI';

  /// Indice Visuo-Spatial
  static const String indexVSI = 'VSI';

  /// Indice de Raisonnement Fluide
  static const String indexFRI = 'FRI';

  /// Indice de Mémoire de Travail
  static const String indexWMI = 'WMI';

  /// Indice de Vitesse de Traitement
  static const String indexPSI = 'PSI';

  /// QI Total
  static const String indexFSIQ = 'FSIQ';

  /// Indice d'Aptitude Générale
  static const String indexGAI = 'GAI';

  /// Indice Non-Verbal
  static const String indexNVI = 'NVI';

  /// Indice de Compétence Cognitive
  static const String indexCCI = 'CCI';

  // ========================================
  // NOMS DES SOUS-TESTS
  // ========================================

  // Compréhension Verbale
  static const String subtestSimilarities = 'SI'; // Similitudes
  static const String subtestVocabulary = 'VO'; // Vocabulaire
  static const String subtestInformation = 'IN'; // Information
  static const String subtestComprehension = 'CO'; // Compréhension

  // Visuo-Spatial
  static const String subtestBlockDesign = 'BD'; // Cubes
  static const String subtestVisualPuzzles = 'VP'; // Puzzles Visuels

  // Raisonnement Fluide
  static const String subtestMatrixReasoning = 'MR'; // Matrices
  static const String subtestFigureWeights = 'FW'; // Balances
  static const String subtestArithmetic = 'AR'; // Arithmétique

  // Mémoire de Travail
  static const String subtestDigitSpan = 'DS'; // Mémoire des Chiffres
  static const String subtestPictureMemory = 'PM'; // Mémoire des Images
  static const String subtestLetterNumberSeq = 'LN'; // Séquence Lettres-Chiffres

  // Vitesse de Traitement
  static const String subtestCoding = 'CD'; // Code
  static const String subtestSymbolSearch = 'SS'; // Symboles
  static const String subtestCancellation = 'CA'; // Barrage

  // ========================================
  // PARAMÈTRES IRT (Item Response Theory)
  // ========================================

  /// Valeur initiale de theta (capacité estimée)
  static const double initialTheta = 0.0;

  /// Écart-type initial de theta
  static const double initialSE = 1.0;

  /// Seuil d'erreur standard pour arrêt du test adaptatif
  static const double seStoppingCriterion = 0.3;

  /// Nombre maximum d'items par sous-test en mode adaptatif
  static const int maxAdaptiveItems = 15;

  /// Nombre minimum d'items par sous-test
  static const int minAdaptiveItems = 5;

  /// Paramètre de discrimination minimal pour items IRT
  static const double minDiscrimination = 0.5;

  /// Paramètre de discrimination maximal
  static const double maxDiscrimination = 2.5;

  // ========================================
  // INTERVALLES DE CONFIANCE
  // ========================================

  /// Niveau de confiance (95%)
  static const double confidenceLevel = 0.95;

  /// Z-score pour IC 95%
  static const double zScore95 = 1.96;

  /// Z-score pour IC 90%
  static const double zScore90 = 1.645;

  /// Erreur standard typique du QI Total
  static const double fsiqSEM = 2.5;

  /// Erreur standard typique des indices primaires
  static const double indexSEM = 3.5;

  // ========================================
  // CLASSIFICATIONS DESCRIPTIVES
  // ========================================

  static const Map<String, Map<String, dynamic>> iqClassifications = {
    'extremely_low': {
      'range': [0, 69],
      'label': 'Extrêmement bas',
      'percentile': '<2',
      'description': 'Fonctionnement cognitif significativement en-dessous de la moyenne',
    },
    'borderline': {
      'range': [70, 79],
      'label': 'Limite',
      'percentile': '2-8',
      'description': 'Fonctionnement cognitif en-dessous de la moyenne',
    },
    'low_average': {
      'range': [80, 89],
      'label': 'Moyen faible',
      'percentile': '9-24',
      'description': 'Fonctionnement cognitif moyen faible',
    },
    'average': {
      'range': [90, 109],
      'label': 'Moyen',
      'percentile': '25-74',
      'description': 'Fonctionnement cognitif dans la moyenne',
    },
    'high_average': {
      'range': [110, 119],
      'label': 'Moyen fort',
      'percentile': '75-90',
      'description': 'Fonctionnement cognitif moyen fort',
    },
    'superior': {
      'range': [120, 129],
      'label': 'Supérieur',
      'percentile': '91-97',
      'description': 'Fonctionnement cognitif supérieur',
    },
    'very_superior': {
      'range': [130, 200],
      'label': 'Très supérieur',
      'percentile': '98+',
      'description': 'Fonctionnement cognitif très supérieur (douance)',
    },
  };

  // ========================================
  // GROUPES D'ÂGE
  // ========================================
  // Les 5 constantes de bande d'âge héritées d'une version multi-tranches ont
  // été retirées le 2026-08-28 : elles étaient MORTES — aucune référence dans
  // lib/ ni test/ — et leurs valeurs reprenaient la nomenclature d'un test
  // tiers. L'app est aujourd'hui adulte uniquement (16 à 90 ans, cf.
  // ctPatientAgeHint). Voir docs/CHANTIER_LEXIQUE_RESTE.md, LOT M.

  /// Âge minimum en mois (2 ans 6 mois)
  static const int minAgeMonths = 30;

  /// Âge maximum en mois (90 ans)
  static const int maxAgeMonths = 1080;

  // ========================================
  // RÈGLES DE DISCONTINUATION
  // ========================================

  /// Nombre d'échecs consécutifs avant discontinuation
  static const int consecutiveFailures = 3;

  /// Nombre d'échecs sur N derniers items
  static const int failuresInLast = 4;

  /// Nombre d'items pour règle de discontinuation
  static const int discontinuationWindow = 5;

  // ========================================
  // TEMPS LIMITES PAR TYPE D'EXERCICE (secondes)
  // ========================================

  static const Map<String, int> timeLimits = {
    // Vitesse de traitement
    'coding': 120,
    'symbol_search': 120,
    'cancellation': 45,

    // Cubes (bonus de temps)
    'block_design_easy': 30,
    'block_design_medium': 60,
    'block_design_hard': 120,

    // Balances
    'figure_weights': 30,

    // Puzzles visuels
    'visual_puzzles': 30,

    // Matrices (indicatif, non chronométré officiellement)
    'matrix_reasoning': 45,
  };

  // ========================================
  // EFFET FLYNN
  // ========================================

  /// Gain de points de QI par décennie (effet Flynn)
  static const double flynnEffectPerDecade = 2.5;

  /// Nombre d'années maximum avant mise à jour des normes
  static const int normsUpdateYears = 15;

  // ========================================
  // EFFET DE PRATIQUE
  // ========================================

  /// Intervalle minimum recommandé entre deux passations (jours)
  static const int minRetestIntervalDays = 180;

  /// Gain de points attendu si retest trop rapide
  static const int practiceEffectGain = 5;

  // ========================================
  // PARAMÈTRES DE VALIDATION
  // ========================================

  /// Corrélation minimum avec test standardisé pour validation
  static const double validationCorrelation = 0.85;

  /// Coefficient alpha minimum (cohérence interne)
  static const double minAlpha = 0.80;

  /// Coefficient alpha cible
  static const double targetAlpha = 0.90;

  /// Fidélité test-retest minimum
  static const double minTestRetest = 0.80;

  /// Fidélité test-retest cible
  static const double targetTestRetest = 0.92;

  // ========================================
  // TAILLE D'ÉCHANTILLON POUR ÉTUDES
  // ========================================

  /// Taille minimum d'échantillon pour validation par groupe d'âge
  static const int minSamplePerAge = 200;

  /// Taille minimum d'échantillon pour normes nationales
  static const int minNationalSample = 1000;

  /// Nombre minimum de réponses avant calibration item IRT
  static const int minResponsesForCalibration = 100;
}
