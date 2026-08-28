import 'dart:math';

/// Générateur de Recherche de Symboles (Symbol Search)
/// 60 items à compléter en 120 secondes
/// Mesure la vitesse de traitement et la discrimination visuelle
class SymbolSearchGenerator {
  // Pool de symboles disponibles (mêmes que Coding)
  static const List<String> symbolPool = [
    '│', '─', '┴', '○', '∨', '∪', '┬', '∩', '×',
    '◇', '□', '△', '▽', '◁', '▷', '⊕', '⊗', '⊙',
  ];

  final List<SymbolSearchItem> _preGeneratedItems = [];

  /// Unique source d'aléa. Sans seed → items différents à chaque passation
  /// (la structure reste fixe : 60 items, 30 OUI / 30 NON, mêmes règles).
  final Random _random;

  /// [seed] optionnel : tirage reproductible (tests). null = aléatoire réel.
  SymbolSearchGenerator({int? seed}) : _random = Random(seed) {
    _generateAllItems();
  }

  /// Génère 60 items équilibrés (30 OUI, 30 NON)
  void _generateAllItems() {
    _preGeneratedItems.clear();

    // Générer 30 items OUI (cible présente)
    for (int i = 0; i < 30; i++) {
      _preGeneratedItems.add(_generateItem(true, i));
    }

    // Générer 30 items NON (cible absente)
    for (int i = 0; i < 30; i++) {
      _preGeneratedItems.add(_generateItem(false, 30 + i));
    }

    // Mélanger pour éviter patterns prévisibles
    _preGeneratedItems.shuffle(_random);

    // Réassigner les indices après mélange
    for (int i = 0; i < _preGeneratedItems.length; i++) {
      _preGeneratedItems[i] = _preGeneratedItems[i].copyWith(index: i);
    }
  }

  /// Génère un item individuel
  SymbolSearchItem _generateItem(bool targetPresent, int index) {
    // Sélectionner 2 symboles cibles aléatoires
    final availableSymbols = List<String>.from(symbolPool);
    availableSymbols.shuffle(_random);

    final target1 = availableSymbols[0];
    final target2 = availableSymbols[1];
    final targetSymbols = [target1, target2];

    // Construire le groupe de recherche (5 symboles)
    List<String> searchGroup = [];

    if (targetPresent) {
      // Au moins une cible présente
      final targetToInclude = _random.nextBool() ? target1 : target2;
      searchGroup.add(targetToInclude);

      // Compléter avec 4 distracteurs
      final distractors = availableSymbols
          .where((s) => !targetSymbols.contains(s))
          .take(4)
          .toList();
      searchGroup.addAll(distractors);
    } else {
      // Aucune cible présente, que des distracteurs
      final distractors = availableSymbols
          .where((s) => !targetSymbols.contains(s))
          .take(5)
          .toList();
      searchGroup.addAll(distractors);
    }

    // Mélanger le groupe de recherche
    searchGroup.shuffle(_random);

    return SymbolSearchItem(
      index: index,
      targetSymbols: targetSymbols,
      searchGroup: searchGroup,
      correctAnswer: targetPresent,
    );
  }

  /// Retourne tous les items (60)
  List<SymbolSearchItem> getAllItems() => List.from(_preGeneratedItems);

  /// Génère des items d'entraînement (5 items)
  List<SymbolSearchItem> getTrainingItems() {
    return [
      // Item 1 : OUI (facile)
      SymbolSearchItem(
        index: 0,
        targetSymbols: ['○', '─'],
        searchGroup: ['○', '×', '┴', '∨', '∪'],
        correctAnswer: true,
      ),
      // Item 2 : NON (facile)
      SymbolSearchItem(
        index: 1,
        targetSymbols: ['┬', '∩'],
        searchGroup: ['○', '×', '┴', '∨', '∪'],
        correctAnswer: false,
      ),
      // Item 3 : OUI
      SymbolSearchItem(
        index: 2,
        targetSymbols: ['×', '∨'],
        searchGroup: ['┴', '∨', '○', '─', '∪'],
        correctAnswer: true,
      ),
      // Item 4 : NON
      SymbolSearchItem(
        index: 3,
        targetSymbols: ['◇', '□'],
        searchGroup: ['△', '▽', '◁', '▷', '⊕'],
        correctAnswer: false,
      ),
      // Item 5 : OUI
      SymbolSearchItem(
        index: 4,
        targetSymbols: ['△', '⊕'],
        searchGroup: ['△', '∩', '×', '┬', '│'],
        correctAnswer: true,
      ),
    ];
  }

  /// Calcule le score (correct - incorrect)
  SymbolSearchScore calculateScore(List<bool?> userAnswers) {
    int correct = 0;
    int incorrect = 0;
    int notAnswered = 0;

    for (int i = 0; i < userAnswers.length && i < _preGeneratedItems.length; i++) {
      final userAnswer = userAnswers[i];
      final correctAnswer = _preGeneratedItems[i].correctAnswer;

      if (userAnswer == null) {
        notAnswered++;
      } else if (userAnswer == correctAnswer) {
        correct++;
      } else {
        incorrect++;
      }
    }

    // Barème harmonisé : le brut (corrects − erreurs) ne peut pas être négatif.
    final rawScore = (correct - incorrect).clamp(0, _preGeneratedItems.length);

    return SymbolSearchScore(
      correct: correct,
      incorrect: incorrect,
      notAnswered: notAnswered,
      rawScore: rawScore,
    );
  }
}

// ========== MODÈLES DE DONNÉES ==========

class SymbolSearchItem {
  final int index;
  final List<String> targetSymbols; // 2 symboles cibles
  final List<String> searchGroup; // 5 symboles dans le groupe
  final bool correctAnswer; // true = OUI, false = NON

  SymbolSearchItem({
    required this.index,
    required this.targetSymbols,
    required this.searchGroup,
    required this.correctAnswer,
  });

  /// Copie avec modification
  SymbolSearchItem copyWith({int? index}) {
    return SymbolSearchItem(
      index: index ?? this.index,
      targetSymbols: targetSymbols,
      searchGroup: searchGroup,
      correctAnswer: correctAnswer,
    );
  }
}

class SymbolSearchScore {
  final int correct;
  final int incorrect;
  final int notAnswered;
  final int rawScore; // correct - incorrect

  SymbolSearchScore({
    required this.correct,
    required this.incorrect,
    required this.notAnswered,
    required this.rawScore,
  });

  int get totalAnswered => correct + incorrect;
}
