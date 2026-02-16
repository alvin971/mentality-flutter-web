/// Générateur de Code (Coding / Digit Symbol - WAIS-IV)
/// 135 cases à compléter en 120 secondes
/// Mesure la vitesse de traitement et la coordination visuomotrice
class CodingGenerator {
  // Clé de référence : chiffre → symbole
  static const Map<int, String> digitToSymbolKey = {
    1: '│',
    2: '─',
    3: '┴',
    4: '○',
    5: '∨',
    6: '∪',
    7: '┬',
    8: '∩',
    9: '×',
  };

  final List<int> _digitSequence = [];

  CodingGenerator() {
    _generateDigitSequence();
  }

  /// Génère une séquence de 135 chiffres (1-9) aléatoire mais équilibrée
  void _generateDigitSequence() {
    _digitSequence.clear();

    // Assurer que chaque chiffre apparaît au moins 15 fois
    final List<int> balancedSequence = [];
    for (int digit = 1; digit <= 9; digit++) {
      balancedSequence.addAll(List.filled(15, digit));
    }

    // Mélanger la séquence
    balancedSequence.shuffle();

    _digitSequence.addAll(balancedSequence);

    // Vérifier qu'on ne dépasse pas 135 cases
    if (_digitSequence.length > 135) {
      _digitSequence.removeRange(135, _digitSequence.length);
    }
  }

  /// Retourne la séquence de chiffres complète (135 items)
  List<int> getDigitSequence() => List.from(_digitSequence);

  /// Retourne le symbole correspondant à un chiffre
  String getSymbolForDigit(int digit) {
    return digitToSymbolKey[digit] ?? '?';
  }

  /// Retourne la clé de référence complète
  Map<int, String> getReferenceKey() => Map.from(digitToSymbolKey);

  /// Retourne tous les symboles disponibles (pour la palette)
  List<String> getAllSymbols() {
    return digitToSymbolKey.values.toList();
  }

  /// Calcule le score (nombre de réponses correctes)
  int calculateScore(List<String?> userAnswers) {
    int score = 0;
    for (int i = 0; i < userAnswers.length && i < _digitSequence.length; i++) {
      final correctSymbol = getSymbolForDigit(_digitSequence[i]);
      if (userAnswers[i] == correctSymbol) {
        score++;
      }
    }
    return score;
  }

  /// Génère une séquence d'entraînement (7 items)
  List<int> getTrainingSequence() {
    return [1, 3, 5, 2, 7, 4, 9]; // Séquence fixe pour l'entraînement
  }
}

// ========== MODÈLES DE DONNÉES ==========

class CodingItem {
  final int index; // Position dans la séquence (0-134)
  final int digit; // Chiffre cible (1-9)
  final String correctSymbol; // Symbole correct
  String? userSymbol; // Symbole saisi par l'utilisateur
  final DateTime timestamp; // Moment de création

  CodingItem({
    required this.index,
    required this.digit,
    required this.correctSymbol,
    this.userSymbol,
    required this.timestamp,
  });

  /// Vérifie si la réponse est correcte
  bool get isCorrect => userSymbol == correctSymbol;

  /// Copie avec modification
  CodingItem copyWith({String? userSymbol}) {
    return CodingItem(
      index: index,
      digit: digit,
      correctSymbol: correctSymbol,
      userSymbol: userSymbol ?? this.userSymbol,
      timestamp: timestamp,
    );
  }
}
