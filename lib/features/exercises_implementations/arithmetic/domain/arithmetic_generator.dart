import 'dart:math';

import '../../_shared/stratified_draw.dart';
import 'arithmetic_templates.dart';

/// Générateur de 22 problèmes d'Arithmétique (WAIS-IV).
///
/// Contrairement aux autres sous-tests, l'arithmétique est CALCULABLE : le code
/// tire un template d'énoncé + des opérandes aléatoires (plages par bande), puis
/// CALCULE la réponse. Aucune réponse n'est écrite à la main. Deux passations ne
/// donnent jamais le même test (énoncés ET nombres changent).
/// Structure conservée : 4/8/6/4 problèmes par bande (easy → veryHard), theta
/// croissant par slot, limites de temps et bonus par bande.
class ArithmeticGenerator {
  final Random _random;
  final String languageCode;
  final List<ArithmeticItem> _preGeneratedItems = [];

  /// Nombre de problèmes tirés par bande (total = 22).
  static const List<int> _itemsPerBand = [4, 8, 6, 4];
  static const List<DifficultyLevel> _bandDifficulty = [
    DifficultyLevel.easy,
    DifficultyLevel.medium,
    DifficultyLevel.hard,
    DifficultyLevel.veryHard,
  ];
  static const List<int> _bandTimeLimit = [15, 25, 40, 50];
  static const List<int> _bandBonusThreshold = [8, 13, 20, 25];

  /// [languageCode] : 'fr' (défaut) ou 'en'.
  /// [seed] optionnel : tirage reproductible (tests). null = aléatoire réel.
  ArithmeticGenerator({this.languageCode = 'fr', int? seed})
      : _random = seed != null ? Random(seed) : Random() {
    _initializeAllItems();
  }

  void _initializeAllItems() {
    _preGeneratedItems.clear();
    final banks = arithmeticTemplatesByBand();
    final drawn = stratifiedDraw<ArithTemplate>(banks, _itemsPerBand, _random);
    for (var i = 0; i < drawn.length; i++) {
      final band = _bandForSlot(i);
      final t = drawn[i];
      final (tokens, answer) = _instantiate(band, t.kind);
      _preGeneratedItems.add(ArithmeticItem(
        problem: _fill(t.text(languageCode), tokens),
        correctAnswer: answer,
        difficulty: _bandDifficulty[band],
        timeLimitSeconds: _bandTimeLimit[band],
        hasTimeBonus: true,
        timeBonusThreshold: _bandBonusThreshold[band],
        thetaValue: thetaForSlot(i),
      ));
    }
  }

  /// Bande (0..3) du slot, d'après la répartition 4/8/6/4.
  int _bandForSlot(int slot) {
    if (slot < 4) return 0;
    if (slot < 12) return 1;
    if (slot < 18) return 2;
    return 3;
  }

  int _ri(int min, int max) => min + _random.nextInt(max - min + 1);

  /// Tire les opérandes (plages par bande) et calcule la réponse.
  /// Retourne (tokens à injecter, réponse correcte).
  (Map<String, int>, int) _instantiate(int band, ArithKind kind) {
    switch (kind) {
      case ArithKind.add:
        final a = band == 0 ? _ri(1, 9) : _ri(11, 49);
        final b = band == 0 ? _ri(1, 9) : _ri(11, 49);
        return ({'a': a, 'b': b}, a + b);
      case ArithKind.sub:
        final a = band == 0 ? _ri(4, 9) : _ri(20, 60);
        final b = _ri(1, a - 1);
        return ({'a': a, 'b': b}, a - b);
      case ArithKind.mul:
        final a = band == 1 ? _ri(2, 9) : _ri(11, 25);
        final b = band == 1 ? _ri(2, 12) : _ri(3, 12);
        return ({'a': a, 'b': b}, a * b);
      case ArithKind.div:
        final divisor = band == 1 ? _ri(2, 9) : _ri(3, 12);
        final quotient = band == 1 ? _ri(2, 9) : _ri(6, 15);
        return ({'dividend': divisor * quotient, 'divisor': divisor}, quotient);
      case ArithKind.percent:
        final percents = band == 2
            ? const [10, 20, 25, 50, 75]
            : const [5, 15, 25, 40, 60];
        final p = percents[_random.nextInt(percents.length)];
        final whole = 20 * (band == 2 ? _ri(2, 10) : _ri(3, 15));
        return ({'percent': p, 'whole': whole}, p * whole ~/ 100);
      case ArithKind.twoStep:
        final a = _ri(2, 12);
        final b = _ri(2, 12);
        final c = _ri(5, 50);
        return ({'a': a, 'b': b, 'c': c}, a * b + c);
    }
  }

  String _fill(String template, Map<String, int> tokens) {
    var s = template;
    tokens.forEach((k, v) => s = s.replaceAll('{$k}', v.toString()));
    return s;
  }

  /// Retourne les 22 problèmes tirés pour cette passation.
  List<ArithmeticItem> generateComplete22Items() {
    return List.from(_preGeneratedItems);
  }
}

class ArithmeticItem {
  final String problem;
  final int correctAnswer;
  final DifficultyLevel difficulty;
  final int timeLimitSeconds;
  final bool hasTimeBonus;
  final int? timeBonusThreshold; // Si réponse correcte en moins de X secondes, +1 bonus
  final double thetaValue;

  ArithmeticItem({
    required this.problem,
    required this.correctAnswer,
    required this.difficulty,
    required this.timeLimitSeconds,
    required this.hasTimeBonus,
    this.timeBonusThreshold,
    required this.thetaValue,
  });

  /// Calcule le score obtenu (0, 1, ou 2 avec bonus temps)
  int calculateScore(int? userAnswer, int timeElapsed) {
    if (userAnswer == null || userAnswer != correctAnswer) {
      return 0; // Réponse incorrecte
    }

    // Réponse correcte : 1 point de base
    int score = 1;

    // Bonus de temps si applicable
    if (hasTimeBonus && timeBonusThreshold != null) {
      if (timeElapsed <= timeBonusThreshold!) {
        score += 1; // Bonus de rapidité
      }
    }

    return score;
  }

  String get difficultyName {
    switch (difficulty) {
      case DifficultyLevel.easy:
        return 'Facile';
      case DifficultyLevel.medium:
        return 'Moyen';
      case DifficultyLevel.hard:
        return 'Difficile';
      case DifficultyLevel.veryHard:
        return 'Très difficile';
    }
  }
}

enum DifficultyLevel {
  easy,
  medium,
  hard,
  veryHard,
}
