import 'dart:math';

/// Générateur de séquences pour Mémoire des Chiffres (Digit Span)
/// 3 parties : Empan Direct, Empan Inverse, Séquençage
/// Mesure la mémoire de travail, l'attention auditive et le contrôle exécutif
///
/// Les séquences sont générées aléatoirement à chaque passation (contrairement
/// aux banques déterministes des autres sous-tests : ici, des items fixes
/// seraient mémorisables et fausseraient les repassations). La difficulté est
/// portée par la longueur, pas par le contenu, donc le theta par longueur
/// reste valide. Contraintes de qualité : chiffres 1-9 tous distincts, pas de
/// suite de 3 chiffres consécutifs (ex. 3-4-5), et pour le séquençage (longueur
/// >= 3) la séquence présentée n'est jamais déjà triée NI triée en décroissant
/// — sinon la bonne réponse serait l'inverse exact de ce qui a été entendu, ce
/// qui se confond avec l'Empan Inverse et a été vécu comme un bug (« j'entends
/// 2-4-9 mais c'est 9-4-2 qui est correct »). En longueur 2 les deux ordres
/// sont l'un trié, l'autre décroissant : on présente l'ordre croissant (item
/// basal trivial, la réponse est ce qui a été entendu).
class DigitSpanGenerator {
  final Random _random;
  final List<DigitSpanItem> _forwardItems = [];
  final List<DigitSpanItem> _backwardItems = [];
  final List<DigitSpanItem> _sequencingItems = [];

  /// [seed] est optionnel et n'est destiné qu'aux tests/diagnostics.
  DigitSpanGenerator({int? seed}) : _random = Random(seed) {
    _initializeAllItems();
  }

  /// Génère TOUTES les séquences (46 items au total)
  void _initializeAllItems() {
    _forwardItems.clear();
    _backwardItems.clear();
    _sequencingItems.clear();

    // Partie A : Empan Direct (2-9 chiffres, 2 essais chacun = 16 items)
    _forwardItems.addAll(_createItems(
      type: SpanType.forward,
      lengths: const [2, 3, 4, 5, 6, 7, 8, 9],
      thetaByLength: const {
        2: -2.0, 3: -1.5, 4: -1.0, 5: -0.5,
        6: 0.0, 7: 0.5, 8: 1.0, 9: 1.5,
      },
    ));

    // Partie B : Empan Inverse (2-8 chiffres, 2 essais chacun = 14 items)
    _backwardItems.addAll(_createItems(
      type: SpanType.backward,
      lengths: const [2, 3, 4, 5, 6, 7, 8],
      thetaByLength: const {
        2: -1.5, 3: -1.0, 4: -0.5, 5: 0.0,
        6: 0.5, 7: 1.0, 8: 1.5,
      },
    ));

    // Partie C : Séquençage (2-9 chiffres, 2 essais chacun = 16 items)
    _sequencingItems.addAll(_createItems(
      type: SpanType.sequencing,
      lengths: const [2, 3, 4, 5, 6, 7, 8, 9],
      thetaByLength: const {
        2: -1.5, 3: -1.0, 4: -0.5, 5: 0.0,
        6: 0.5, 7: 1.0, 8: 1.5, 9: 2.0,
      },
    ));
  }

  List<DigitSpanItem> _createItems({
    required SpanType type,
    required List<int> lengths,
    required Map<int, double> thetaByLength,
  }) {
    final items = <DigitSpanItem>[];
    for (final length in lengths) {
      for (int trial = 1; trial <= 2; trial++) {
        items.add(DigitSpanItem(
          sequence: _generateSequence(length, type),
          length: length,
          trial: trial,
          type: type,
          thetaValue: thetaByLength[length]!,
        ));
      }
    }
    return items;
  }

  /// Tire une séquence de [length] chiffres distincts (1-9) satisfaisant les
  /// contraintes de qualité.
  List<int> _generateSequence(int length, SpanType type) {
    while (true) {
      final digits = [1, 2, 3, 4, 5, 6, 7, 8, 9]..shuffle(_random);
      final sequence = digits.sublist(0, length);
      if (_hasConsecutiveRun(sequence)) continue;
      if (type == SpanType.sequencing) {
        if (length == 2) {
          // Longueur 2 : tout ordre non trié est exactement l'inverse de la
          // réponse attendue — on présente donc l'ordre croissant.
          sequence.sort();
          return sequence;
        }
        if (_isSorted(sequence)) continue;
        if (_isReverseSorted(sequence)) continue;
      }
      return sequence;
    }
  }

  /// Vrai si la séquence contient 3 chiffres consécutifs (montants ou
  /// descendants, ex. 3-4-5 ou 7-6-5) — trop faciles à retenir.
  bool _hasConsecutiveRun(List<int> sequence) {
    for (int i = 0; i + 2 < sequence.length; i++) {
      final d1 = sequence[i + 1] - sequence[i];
      final d2 = sequence[i + 2] - sequence[i + 1];
      if ((d1 == 1 && d2 == 1) || (d1 == -1 && d2 == -1)) return true;
    }
    return false;
  }

  bool _isSorted(List<int> sequence) {
    for (int i = 0; i + 1 < sequence.length; i++) {
      if (sequence[i] > sequence[i + 1]) return false;
    }
    return true;
  }

  /// Vrai si la séquence est strictement décroissante : la réponse attendue
  /// (tri croissant) serait alors l'inverse exact de la présentation.
  bool _isReverseSorted(List<int> sequence) {
    for (int i = 0; i + 1 < sequence.length; i++) {
      if (sequence[i] < sequence[i + 1]) return false;
    }
    return true;
  }

  /// Retourne les items de la partie Forward
  List<DigitSpanItem> getForwardItems() => List.from(_forwardItems);

  /// Retourne les items de la partie Backward
  List<DigitSpanItem> getBackwardItems() => List.from(_backwardItems);

  /// Retourne les items de la partie Sequencing
  List<DigitSpanItem> getSequencingItems() => List.from(_sequencingItems);

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
