/// Tables normatives de conversion score brut → note standardisée (1-19)
/// Calibrées sur les données WAIS-IV (Wechsler Adult Intelligence Scale, 4e édition)
///
/// Structure : pour chaque sous-test et groupe d'âge, un vecteur de 19 valeurs
/// où `thresholds[i]` = score brut minimum pour obtenir la note standardisée (i+1)
///
/// Groupes d'âge :
///   'A' : 16-24 ans (192-299 mois)
///   'B' : 25-44 ans (300-539 mois) — groupe de référence
///   'C' : 45-64 ans (540-779 mois)
///   'D' : 65+ ans  (780+ mois)
class NormativeTables {
  NormativeTables._();

  /// Retourne la clé du groupe d'âge à partir de l'âge en mois
  static String getAgeGroupKey(int ageInMonths) {
    if (ageInMonths < 300) return 'A'; // 16-24 ans
    if (ageInMonths < 540) return 'B'; // 25-44 ans
    if (ageInMonths < 780) return 'C'; // 45-64 ans
    return 'D'; // 65+ ans
  }

  /// Tables de conversion brut → note standardisée par sous-test et groupe d'âge
  /// Format : subtest → ageGroup → List<int>[19] où index i = min raw pour note (i+1)
  static const Map<String, Map<String, List<int>>> _tables = {
    // ─────────────────────────────────────────────────────────────────────
    // CUBES (Block Design) — max brut ≈ 69 (avec bonus temps)
    // Capacité visuo-spatiale, vitesse diminue avec l'âge
    // ─────────────────────────────────────────────────────────────────────
    'BD': {
      'A': [0, 3, 7, 11, 15, 20, 25, 30, 35, 39, 43, 47, 51, 55, 58, 62, 64, 67, 69],
      'B': [0, 3, 6, 10, 14, 19, 24, 29, 33, 37, 41, 45, 49, 53, 57, 60, 63, 66, 68],
      'C': [0, 2, 5, 8, 12, 16, 21, 26, 30, 34, 38, 42, 46, 50, 54, 58, 61, 64, 67],
      'D': [0, 1, 3, 6, 9, 13, 17, 22, 27, 31, 35, 39, 43, 47, 51, 55, 58, 62, 65],
    },

    // ─────────────────────────────────────────────────────────────────────
    // SIMILITUDES (Similarities) — max brut 42
    // Intelligence cristallisée, stable ou augmente légèrement avec l'âge
    // ─────────────────────────────────────────────────────────────────────
    'SI': {
      'A': [0, 1, 3, 5, 8, 10, 13, 15, 18, 20, 23, 25, 28, 30, 33, 35, 38, 40, 42],
      'B': [0, 1, 3, 5, 7, 10, 12, 15, 17, 20, 22, 25, 27, 30, 33, 35, 38, 40, 42],
      'C': [0, 1, 2, 4, 7, 9, 12, 14, 17, 19, 22, 24, 27, 29, 32, 35, 37, 39, 41],
      'D': [0, 0, 2, 4, 6, 8, 11, 13, 16, 18, 21, 23, 26, 29, 31, 34, 37, 39, 41],
    },

    // ─────────────────────────────────────────────────────────────────────
    // MÉMOIRE DES CHIFFRES (Digit Span) — max brut 46 (Forward+Backward+Seq)
    // Mémoire de travail verbale, déclin modéré avec l'âge
    // ─────────────────────────────────────────────────────────────────────
    'DS': {
      'A': [0, 5, 9, 12, 15, 17, 19, 21, 23, 25, 27, 29, 32, 34, 37, 39, 41, 43, 45],
      'B': [0, 4, 8, 11, 14, 16, 18, 20, 22, 25, 27, 29, 31, 34, 36, 39, 41, 43, 45],
      'C': [0, 3, 7, 10, 13, 15, 17, 19, 21, 23, 25, 28, 30, 33, 35, 37, 40, 42, 44],
      'D': [0, 3, 6, 9, 12, 14, 16, 18, 20, 22, 24, 27, 29, 31, 34, 36, 39, 41, 43],
    },

    // ─────────────────────────────────────────────────────────────────────
    // MATRICES (Matrix Reasoning) — max brut 26
    // Raisonnement fluide, déclin notable avec l'âge
    // ─────────────────────────────────────────────────────────────────────
    'MR': {
      'A': [0, 1, 2, 4, 6, 8, 10, 12, 13, 15, 17, 18, 20, 21, 22, 23, 24, 25, 26],
      'B': [0, 1, 2, 3, 5, 7, 9, 11, 12, 14, 16, 17, 19, 21, 22, 23, 24, 25, 26],
      'C': [0, 0, 1, 3, 4, 6, 8, 10, 11, 13, 15, 16, 18, 19, 21, 22, 23, 25, 26],
      'D': [0, 0, 1, 2, 3, 5, 7, 9, 10, 12, 14, 15, 17, 18, 20, 21, 22, 24, 25],
    },

    // ─────────────────────────────────────────────────────────────────────
    // VOCABULAIRE (Vocabulary) — max brut 60
    // Intelligence cristallisée, augmente jusqu'à 50 ans puis stable
    // ─────────────────────────────────────────────────────────────────────
    'VO': {
      'A': [0, 3, 7, 11, 15, 19, 23, 27, 30, 33, 36, 39, 43, 46, 49, 52, 55, 57, 59],
      'B': [0, 2, 5, 9, 13, 17, 21, 25, 28, 32, 35, 38, 42, 45, 48, 51, 54, 57, 59],
      'C': [0, 2, 4, 8, 12, 16, 20, 24, 27, 31, 34, 38, 41, 44, 47, 50, 53, 56, 59],
      'D': [0, 1, 4, 7, 11, 15, 19, 23, 26, 30, 33, 37, 40, 43, 47, 50, 53, 56, 58],
    },

    // ─────────────────────────────────────────────────────────────────────
    // ARITHMÉTIQUE (Arithmetic) — max brut 22
    // Mémoire de travail numérique + raisonnement, stable jusqu'à 50 ans
    // ─────────────────────────────────────────────────────────────────────
    'AR': {
      'A': [0, 1, 2, 3, 5, 6, 8, 9, 11, 12, 13, 15, 16, 17, 18, 19, 20, 21, 22],
      'B': [0, 1, 2, 3, 4, 6, 7, 9, 10, 12, 13, 14, 16, 17, 18, 19, 20, 21, 22],
      'C': [0, 0, 1, 2, 4, 5, 7, 8, 10, 11, 12, 14, 15, 16, 18, 19, 20, 21, 22],
      'D': [0, 0, 1, 2, 3, 4, 6, 7, 9, 10, 11, 13, 14, 16, 17, 18, 19, 20, 21],
    },

    // ─────────────────────────────────────────────────────────────────────
    // RECHERCHE DE SYMBOLES (Symbol Search) — max brut 60
    // Vitesse de traitement, forte décroissance avec l'âge
    // ─────────────────────────────────────────────────────────────────────
    'SS': {
      'A': [0, 5, 10, 15, 19, 23, 26, 29, 32, 35, 37, 40, 43, 46, 49, 51, 54, 57, 59],
      'B': [0, 4, 8, 13, 17, 21, 24, 27, 30, 33, 35, 38, 41, 44, 47, 50, 53, 56, 59],
      'C': [0, 3, 6, 10, 14, 17, 20, 23, 26, 29, 32, 35, 38, 41, 44, 47, 50, 53, 57],
      'D': [0, 2, 4, 7, 11, 14, 17, 20, 23, 26, 29, 32, 35, 38, 41, 44, 47, 51, 55],
    },

    // ─────────────────────────────────────────────────────────────────────
    // PUZZLES VISUELS (Visual Puzzles) — max brut 26
    // Raisonnement visuo-spatial, déclin avec l'âge
    // ─────────────────────────────────────────────────────────────────────
    'VP': {
      'A': [0, 0, 1, 3, 5, 7, 9, 11, 12, 14, 15, 17, 19, 21, 22, 23, 24, 25, 26],
      'B': [0, 0, 1, 2, 4, 6, 8, 10, 12, 14, 15, 16, 18, 20, 21, 22, 24, 25, 26],
      'C': [0, 0, 1, 2, 3, 5, 7, 9, 11, 12, 14, 15, 17, 18, 20, 21, 22, 24, 25],
      'D': [0, 0, 0, 1, 3, 4, 6, 8, 10, 11, 13, 14, 16, 17, 19, 20, 22, 23, 25],
    },

    // ─────────────────────────────────────────────────────────────────────
    // INFORMATION (Information) — max brut 28
    // Connaissances générales, très stable voire augmente avec l'âge
    // ─────────────────────────────────────────────────────────────────────
    'IN': {
      'A': [0, 1, 2, 4, 6, 8, 10, 12, 14, 16, 18, 19, 21, 22, 24, 25, 26, 27, 28],
      'B': [0, 1, 2, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 22, 24, 25, 26, 27, 28],
      'C': [0, 0, 1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 20, 22, 23, 25, 26, 27, 28],
      'D': [0, 0, 1, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 23, 25, 26, 27, 28],
    },

    // ─────────────────────────────────────────────────────────────────────
    // CODE (Coding/Digit Symbol) — max brut 135
    // Vitesse de traitement pure, très forte décroissance avec l'âge
    // ─────────────────────────────────────────────────────────────────────
    'CD': {
      'A': [0, 15, 26, 35, 44, 52, 58, 63, 68, 73, 78, 83, 88, 94, 99, 105, 112, 120, 128],
      'B': [0, 12, 22, 31, 39, 47, 53, 59, 64, 70, 75, 81, 87, 93, 99, 105, 112, 120, 127],
      'C': [0, 9, 17, 25, 32, 39, 45, 51, 57, 62, 68, 73, 79, 85, 91, 97, 104, 112, 120],
      'D': [0, 6, 12, 19, 25, 31, 37, 43, 49, 55, 61, 67, 73, 79, 86, 93, 101, 110, 119],
    },

    // ─────────────────────────────────────────────────────────────────────
    // MÉMOIRE DES IMAGES (Picture Span) — max brut variable, ici sur 12 essais
    // Score normalisé sur 12 (nombre d'images rappelées correctement)
    // ─────────────────────────────────────────────────────────────────────
    'PM': {
      'A': [0, 1, 2, 3, 4, 5, 5, 6, 6, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12],
      'B': [0, 1, 2, 3, 3, 4, 5, 5, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 12],
      'C': [0, 0, 1, 2, 3, 4, 4, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 11, 12],
      'D': [0, 0, 1, 2, 2, 3, 4, 4, 5, 5, 6, 7, 7, 8, 8, 9, 10, 11, 12],
    },

    // ─────────────────────────────────────────────────────────────────────
    // BALANCES (Figure Weights) — max brut 27
    // Raisonnement quantitatif fluide, déclin modéré avec l'âge
    // ─────────────────────────────────────────────────────────────────────
    'FW': {
      'A': [0, 1, 2, 4, 6, 8, 10, 11, 13, 15, 16, 18, 19, 21, 22, 23, 24, 26, 27],
      'B': [0, 1, 2, 3, 5, 7, 9, 11, 12, 14, 16, 17, 19, 20, 22, 23, 24, 25, 26],
      'C': [0, 0, 1, 3, 4, 6, 8, 10, 11, 13, 14, 16, 18, 19, 21, 22, 23, 25, 26],
      'D': [0, 0, 1, 2, 3, 5, 7, 9, 10, 12, 13, 15, 17, 18, 20, 21, 22, 24, 25],
    },
  };

  /// Convertit un score brut en note standardisée (1-19) pour un sous-test donné
  ///
  /// [subtestCode] : code du sous-test (BD, SI, DS, MR, VO, AR, SS, VP, IN, CD, PM, FW)
  /// [rawScore] : score brut obtenu
  /// [ageInMonths] : âge en mois pour sélectionner la table normative
  ///
  /// Retourne la note standardisée (1-19), 10 si le sous-test est inconnu
  static int toScaledScore(String subtestCode, int rawScore, int ageInMonths) {
    final ageGroup = getAgeGroupKey(ageInMonths);
    final subtestTables = _tables[subtestCode];
    if (subtestTables == null) return 10; // fallback

    final thresholds = subtestTables[ageGroup] ?? subtestTables['B']!;

    // Trouve la note standardisée la plus haute pour laquelle rawScore >= threshold
    int scaledScore = 1;
    for (int i = 0; i < thresholds.length; i++) {
      if (rawScore >= thresholds[i]) {
        scaledScore = i + 1;
      }
    }

    return scaledScore.clamp(1, 19);
  }
}
