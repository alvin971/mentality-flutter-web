/// Modèle pour une session de test complet WAIS-IV
/// Stocke tous les résultats de tous les subtests
class CompleteTestSession {
  final DateTime startTime;
  DateTime? endTime;

  // Index Compréhension Verbale (ICV)
  int? similaritiesScore;
  int? vocabularyScore;
  int? informationScore;

  // Index Raisonnement Perceptif (IRP)
  int? cubesScore;
  int? matricesScore;
  int? visualPuzzlesScore;

  // Index Mémoire de Travail (IMT)
  int? digitSpanScore;
  int? arithmeticScore;

  // Index Vitesse de Traitement (IVT)
  int? codingScore;
  int? symbolSearchScore;

  // Index supplémentaires
  int? pictureSpanScore;
  int? figureWeightsScore;

  // Métadonnées
  int currentTestIndex;
  List<String> completedTests;

  CompleteTestSession({
    required this.startTime,
    this.endTime,
    this.similaritiesScore,
    this.vocabularyScore,
    this.informationScore,
    this.cubesScore,
    this.matricesScore,
    this.visualPuzzlesScore,
    this.digitSpanScore,
    this.arithmeticScore,
    this.codingScore,
    this.symbolSearchScore,
    this.pictureSpanScore,
    this.figureWeightsScore,
    this.currentTestIndex = 0,
    List<String>? completedTests,
  }) : completedTests = completedTests ?? [];

  /// Liste ordonnée des tests à effectuer
  static const List<String> testSequence = [
    'Cubes',
    'Similitudes',
    'Mémoire des Chiffres',
    'Matrices',
    'Vocabulaire',
    'Arithmétique',
    'Recherche de Symboles',
    'Puzzles Visuels',
    'Information',
    'Code',
    'Mémoire des Images',
    'Balances',
  ];

  /// Retourne le nom du test en cours
  String get currentTestName =>
      currentTestIndex < testSequence.length
          ? testSequence[currentTestIndex]
          : 'Terminé';

  /// Vérifie si tous les tests sont complétés
  bool get isComplete => currentTestIndex >= testSequence.length;

  /// Progression en pourcentage
  double get progressPercentage =>
      (currentTestIndex / testSequence.length) * 100;

  /// Nombre total de tests
  int get totalTests => testSequence.length;

  /// Nombre de tests complétés
  int get completedTestsCount => completedTests.length;

  /// Durée totale de la session
  Duration? get totalDuration =>
      endTime != null ? endTime!.difference(startTime) : null;

  /// Marque le test actuel comme complété et passe au suivant
  void completeCurrentTest() {
    if (currentTestIndex < testSequence.length) {
      completedTests.add(testSequence[currentTestIndex]);
      currentTestIndex++;
    }
  }

  /// Calcule le score brut total ICV (Indice de Compréhension Verbale)
  int? get icvRawScore {
    if (similaritiesScore == null || vocabularyScore == null || informationScore == null) {
      return null;
    }
    return similaritiesScore! + vocabularyScore! + informationScore!;
  }

  /// Calcule le score brut total IRP (Indice de Raisonnement Perceptif)
  int? get irpRawScore {
    if (cubesScore == null || matricesScore == null || visualPuzzlesScore == null) {
      return null;
    }
    return cubesScore! + matricesScore! + visualPuzzlesScore!;
  }

  /// Calcule le score brut total IMT (Indice de Mémoire de Travail)
  int? get imtRawScore {
    if (digitSpanScore == null || arithmeticScore == null) {
      return null;
    }
    return digitSpanScore! + arithmeticScore!;
  }

  /// Calcule le score brut total IVT (Indice de Vitesse de Traitement)
  int? get ivtRawScore {
    if (codingScore == null || symbolSearchScore == null) {
      return null;
    }
    return codingScore! + symbolSearchScore!;
  }

  /// Calcule le QI Total estimé (simplifié)
  /// Note: Dans un vrai test WAIS-IV, il faudrait des tables de conversion normatives
  int? get estimatedIQ {
    final icv = icvRawScore;
    final irp = irpRawScore;
    final imt = imtRawScore;
    final ivt = ivtRawScore;

    if (icv == null || irp == null || imt == null || ivt == null) {
      return null;
    }

    // Formule simplifiée (à remplacer par des tables normatives réelles)
    final totalRaw = icv + irp + imt + ivt;

    // Conversion approximative: moyenne = 100, écart-type = 15
    // Cette formule est une approximation simplifiée
    return 100 + ((totalRaw - 150) ~/ 3);
  }

  /// Copie avec modification
  CompleteTestSession copyWith({
    DateTime? startTime,
    DateTime? endTime,
    int? similaritiesScore,
    int? vocabularyScore,
    int? informationScore,
    int? cubesScore,
    int? matricesScore,
    int? visualPuzzlesScore,
    int? digitSpanScore,
    int? arithmeticScore,
    int? codingScore,
    int? symbolSearchScore,
    int? pictureSpanScore,
    int? figureWeightsScore,
    int? currentTestIndex,
    List<String>? completedTests,
  }) {
    return CompleteTestSession(
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      similaritiesScore: similaritiesScore ?? this.similaritiesScore,
      vocabularyScore: vocabularyScore ?? this.vocabularyScore,
      informationScore: informationScore ?? this.informationScore,
      cubesScore: cubesScore ?? this.cubesScore,
      matricesScore: matricesScore ?? this.matricesScore,
      visualPuzzlesScore: visualPuzzlesScore ?? this.visualPuzzlesScore,
      digitSpanScore: digitSpanScore ?? this.digitSpanScore,
      arithmeticScore: arithmeticScore ?? this.arithmeticScore,
      codingScore: codingScore ?? this.codingScore,
      symbolSearchScore: symbolSearchScore ?? this.symbolSearchScore,
      pictureSpanScore: pictureSpanScore ?? this.pictureSpanScore,
      figureWeightsScore: figureWeightsScore ?? this.figureWeightsScore,
      currentTestIndex: currentTestIndex ?? this.currentTestIndex,
      completedTests: completedTests ?? this.completedTests,
    );
  }
}
