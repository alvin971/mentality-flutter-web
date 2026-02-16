/// Générateur de séquences pour Mémoire des Chiffres (Digit Span - WAIS-IV)
/// 3 parties : Empan Direct, Empan Inverse, Séquençage
/// Mesure la mémoire de travail, l'attention auditive et le contrôle exécutif
class DigitSpanGenerator {
  final List<DigitSpanItem> _forwardItems = [];
  final List<DigitSpanItem> _backwardItems = [];
  final List<DigitSpanItem> _sequencingItems = [];

  DigitSpanGenerator() {
    _initializeAllItems();
  }

  /// Initialise TOUTES les séquences (46 items au total)
  void _initializeAllItems() {
    _forwardItems.clear();
    _backwardItems.clear();
    _sequencingItems.clear();

    // Partie A : Empan Direct (2-9 chiffres, 2 essais chacun = 16 items)
    _forwardItems.addAll(_createForwardItems());

    // Partie B : Empan Inverse (2-8 chiffres, 2 essais chacun = 14 items)
    _backwardItems.addAll(_createBackwardItems());

    // Partie C : Séquençage (2-9 chiffres, 2 essais chacun = 16 items)
    _sequencingItems.addAll(_createSequencingItems());
  }

  /// Retourne les items de la partie Forward
  List<DigitSpanItem> getForwardItems() => List.from(_forwardItems);

  /// Retourne les items de la partie Backward
  List<DigitSpanItem> getBackwardItems() => List.from(_backwardItems);

  /// Retourne les items de la partie Sequencing
  List<DigitSpanItem> getSequencingItems() => List.from(_sequencingItems);

  // ========== PARTIE A : EMPAN DIRECT (Forward) ==========
  List<DigitSpanItem> _createForwardItems() {
    return [
      // Longueur 2 (2 essais)
      DigitSpanItem(
        sequence: [5, 8],
        length: 2,
        trial: 1,
        type: SpanType.forward,
        thetaValue: -2.0,
      ),
      DigitSpanItem(
        sequence: [6, 3],
        length: 2,
        trial: 2,
        type: SpanType.forward,
        thetaValue: -2.0,
      ),

      // Longueur 3 (2 essais)
      DigitSpanItem(
        sequence: [5, 8, 2],
        length: 3,
        trial: 1,
        type: SpanType.forward,
        thetaValue: -1.5,
      ),
      DigitSpanItem(
        sequence: [6, 9, 4],
        length: 3,
        trial: 2,
        type: SpanType.forward,
        thetaValue: -1.5,
      ),

      // Longueur 4 (2 essais)
      DigitSpanItem(
        sequence: [7, 2, 8, 6],
        length: 4,
        trial: 1,
        type: SpanType.forward,
        thetaValue: -1.0,
      ),
      DigitSpanItem(
        sequence: [4, 9, 3, 1],
        length: 4,
        trial: 2,
        type: SpanType.forward,
        thetaValue: -1.0,
      ),

      // Longueur 5 (2 essais)
      DigitSpanItem(
        sequence: [3, 8, 2, 9, 5],
        length: 5,
        trial: 1,
        type: SpanType.forward,
        thetaValue: -0.5,
      ),
      DigitSpanItem(
        sequence: [7, 1, 4, 9, 3],
        length: 5,
        trial: 2,
        type: SpanType.forward,
        thetaValue: -0.5,
      ),

      // Longueur 6 (2 essais)
      DigitSpanItem(
        sequence: [5, 9, 1, 7, 4, 2],
        length: 6,
        trial: 1,
        type: SpanType.forward,
        thetaValue: 0.0,
      ),
      DigitSpanItem(
        sequence: [4, 1, 7, 9, 3, 8],
        length: 6,
        trial: 2,
        type: SpanType.forward,
        thetaValue: 0.0,
      ),

      // Longueur 7 (2 essais)
      DigitSpanItem(
        sequence: [5, 8, 2, 9, 1, 6, 4],
        length: 7,
        trial: 1,
        type: SpanType.forward,
        thetaValue: 0.5,
      ),
      DigitSpanItem(
        sequence: [3, 9, 2, 4, 8, 7, 1],
        length: 7,
        trial: 2,
        type: SpanType.forward,
        thetaValue: 0.5,
      ),

      // Longueur 8 (2 essais)
      DigitSpanItem(
        sequence: [5, 9, 1, 7, 4, 2, 8, 3],
        length: 8,
        trial: 1,
        type: SpanType.forward,
        thetaValue: 1.0,
      ),
      DigitSpanItem(
        sequence: [3, 8, 2, 9, 5, 1, 7, 4],
        length: 8,
        trial: 2,
        type: SpanType.forward,
        thetaValue: 1.0,
      ),

      // Longueur 9 (2 essais)
      DigitSpanItem(
        sequence: [2, 7, 5, 8, 6, 3, 1, 9, 4],
        length: 9,
        trial: 1,
        type: SpanType.forward,
        thetaValue: 1.5,
      ),
      DigitSpanItem(
        sequence: [7, 1, 3, 9, 4, 2, 5, 6, 8],
        length: 9,
        trial: 2,
        type: SpanType.forward,
        thetaValue: 1.5,
      ),
    ];
  }

  // ========== PARTIE B : EMPAN INVERSE (Backward) ==========
  List<DigitSpanItem> _createBackwardItems() {
    return [
      // Longueur 2 (2 essais)
      DigitSpanItem(
        sequence: [2, 4],
        length: 2,
        trial: 1,
        type: SpanType.backward,
        thetaValue: -1.5,
      ),
      DigitSpanItem(
        sequence: [5, 7],
        length: 2,
        trial: 2,
        type: SpanType.backward,
        thetaValue: -1.5,
      ),

      // Longueur 3 (2 essais)
      DigitSpanItem(
        sequence: [6, 2, 9],
        length: 3,
        trial: 1,
        type: SpanType.backward,
        thetaValue: -1.0,
      ),
      DigitSpanItem(
        sequence: [4, 1, 5],
        length: 3,
        trial: 2,
        type: SpanType.backward,
        thetaValue: -1.0,
      ),

      // Longueur 4 (2 essais)
      DigitSpanItem(
        sequence: [3, 9, 1, 6],
        length: 4,
        trial: 1,
        type: SpanType.backward,
        thetaValue: -0.5,
      ),
      DigitSpanItem(
        sequence: [7, 4, 2, 8],
        length: 4,
        trial: 2,
        type: SpanType.backward,
        thetaValue: -0.5,
      ),

      // Longueur 5 (2 essais)
      DigitSpanItem(
        sequence: [1, 5, 2, 8, 6],
        length: 5,
        trial: 1,
        type: SpanType.backward,
        thetaValue: 0.0,
      ),
      DigitSpanItem(
        sequence: [6, 1, 9, 4, 7],
        length: 5,
        trial: 2,
        type: SpanType.backward,
        thetaValue: 0.0,
      ),

      // Longueur 6 (2 essais)
      DigitSpanItem(
        sequence: [5, 3, 9, 4, 1, 8],
        length: 6,
        trial: 1,
        type: SpanType.backward,
        thetaValue: 0.5,
      ),
      DigitSpanItem(
        sequence: [7, 2, 4, 8, 5, 9],
        length: 6,
        trial: 2,
        type: SpanType.backward,
        thetaValue: 0.5,
      ),

      // Longueur 7 (2 essais)
      DigitSpanItem(
        sequence: [8, 1, 2, 9, 3, 6, 5],
        length: 7,
        trial: 1,
        type: SpanType.backward,
        thetaValue: 1.0,
      ),
      DigitSpanItem(
        sequence: [4, 7, 3, 9, 1, 2, 8],
        length: 7,
        trial: 2,
        type: SpanType.backward,
        thetaValue: 1.0,
      ),

      // Longueur 8 (2 essais)
      DigitSpanItem(
        sequence: [9, 4, 3, 7, 6, 2, 5, 8],
        length: 8,
        trial: 1,
        type: SpanType.backward,
        thetaValue: 1.5,
      ),
      DigitSpanItem(
        sequence: [7, 2, 8, 1, 9, 6, 5, 3],
        length: 8,
        trial: 2,
        type: SpanType.backward,
        thetaValue: 1.5,
      ),
    ];
  }

  // ========== PARTIE C : SÉQUENÇAGE (Sequencing) ==========
  List<DigitSpanItem> _createSequencingItems() {
    return [
      // Longueur 2 (2 essais)
      DigitSpanItem(
        sequence: [8, 3],
        length: 2,
        trial: 1,
        type: SpanType.sequencing,
        thetaValue: -1.5,
      ),
      DigitSpanItem(
        sequence: [5, 1],
        length: 2,
        trial: 2,
        type: SpanType.sequencing,
        thetaValue: -1.5,
      ),

      // Longueur 3 (2 essais)
      DigitSpanItem(
        sequence: [7, 2, 9],
        length: 3,
        trial: 1,
        type: SpanType.sequencing,
        thetaValue: -1.0,
      ),
      DigitSpanItem(
        sequence: [4, 8, 1],
        length: 3,
        trial: 2,
        type: SpanType.sequencing,
        thetaValue: -1.0,
      ),

      // Longueur 4 (2 essais)
      DigitSpanItem(
        sequence: [7, 2, 8, 6],
        length: 4,
        trial: 1,
        type: SpanType.sequencing,
        thetaValue: -0.5,
      ),
      DigitSpanItem(
        sequence: [5, 9, 1, 3],
        length: 4,
        trial: 2,
        type: SpanType.sequencing,
        thetaValue: -0.5,
      ),

      // Longueur 5 (2 essais)
      DigitSpanItem(
        sequence: [6, 1, 9, 4, 7],
        length: 5,
        trial: 1,
        type: SpanType.sequencing,
        thetaValue: 0.0,
      ),
      DigitSpanItem(
        sequence: [3, 8, 2, 9, 5],
        length: 5,
        trial: 2,
        type: SpanType.sequencing,
        thetaValue: 0.0,
      ),

      // Longueur 6 (2 essais)
      DigitSpanItem(
        sequence: [5, 9, 1, 7, 4, 2],
        length: 6,
        trial: 1,
        type: SpanType.sequencing,
        thetaValue: 0.5,
      ),
      DigitSpanItem(
        sequence: [8, 3, 6, 1, 9, 4],
        length: 6,
        trial: 2,
        type: SpanType.sequencing,
        thetaValue: 0.5,
      ),

      // Longueur 7 (2 essais)
      DigitSpanItem(
        sequence: [4, 7, 3, 9, 1, 2, 8],
        length: 7,
        trial: 1,
        type: SpanType.sequencing,
        thetaValue: 1.0,
      ),
      DigitSpanItem(
        sequence: [6, 1, 8, 4, 3, 9, 5],
        length: 7,
        trial: 2,
        type: SpanType.sequencing,
        thetaValue: 1.0,
      ),

      // Longueur 8 (2 essais)
      DigitSpanItem(
        sequence: [9, 4, 3, 7, 6, 2, 5, 8],
        length: 8,
        trial: 1,
        type: SpanType.sequencing,
        thetaValue: 1.5,
      ),
      DigitSpanItem(
        sequence: [5, 8, 1, 3, 9, 6, 2, 7],
        length: 8,
        trial: 2,
        type: SpanType.sequencing,
        thetaValue: 1.5,
      ),

      // Longueur 9 (2 essais)
      DigitSpanItem(
        sequence: [2, 7, 5, 8, 6, 3, 1, 9, 4],
        length: 9,
        trial: 1,
        type: SpanType.sequencing,
        thetaValue: 2.0,
      ),
      DigitSpanItem(
        sequence: [7, 1, 3, 9, 4, 2, 5, 6, 8],
        length: 9,
        trial: 2,
        type: SpanType.sequencing,
        thetaValue: 2.0,
      ),
    ];
  }
}

// ========== MODÈLES DE DONNÉES ==========

class DigitSpanItem {
  final List<int> sequence;
  final int length;
  final int trial; // 1 or 2
  final SpanType type;
  final double thetaValue;

  DigitSpanItem({
    required this.sequence,
    required this.length,
    required this.trial,
    required this.type,
    required this.thetaValue,
  });

  /// Retourne la réponse correcte selon le type de test
  List<int> getCorrectAnswer() {
    switch (type) {
      case SpanType.forward:
        // Répéter dans l'ordre
        return List.from(sequence);
      case SpanType.backward:
        // Répéter en ordre inverse
        return sequence.reversed.toList();
      case SpanType.sequencing:
        // Répéter en ordre croissant
        final sorted = List<int>.from(sequence);
        sorted.sort();
        return sorted;
    }
  }

  /// Vérifie si la réponse utilisateur est correcte
  bool isCorrect(List<int> userAnswer) {
    final correctAnswer = getCorrectAnswer();
    if (userAnswer.length != correctAnswer.length) return false;
    for (int i = 0; i < correctAnswer.length; i++) {
      if (userAnswer[i] != correctAnswer[i]) return false;
    }
    return true;
  }

  String get typeDescription {
    switch (type) {
      case SpanType.forward:
        return 'Empan Direct';
      case SpanType.backward:
        return 'Empan Inverse';
      case SpanType.sequencing:
        return 'Séquençage';
    }
  }

  String get instruction {
    switch (type) {
      case SpanType.forward:
        return 'Répétez les chiffres dans le même ordre';
      case SpanType.backward:
        return 'Répétez les chiffres en ordre inverse';
      case SpanType.sequencing:
        return 'Répétez les chiffres en ordre croissant';
    }
  }
}

enum SpanType {
  forward,    // Empan direct : répétition identique
  backward,   // Empan inverse : inversion mentale
  sequencing, // Séquençage : tri croissant
}
