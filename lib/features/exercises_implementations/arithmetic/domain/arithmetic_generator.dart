import 'arithmetic_items_en.dart';

/// Générateur de 22 problèmes d'Arithmétique (WAIS-IV)
/// Mesure la mémoire de travail, le raisonnement numérique et l'attention
/// Résolution mentale sous contrainte de temps
class ArithmeticGenerator {
  final List<ArithmeticItem> _preGeneratedItems = [];

  /// Langue de la banque d'items ('fr' par défaut, 'en' disponible).
  final String languageCode;

  ArithmeticGenerator({this.languageCode = 'fr'}) {
    _initializeAllItems();
  }

  /// Initialise TOUS les 22 items uniques
  void _initializeAllItems() {
    _preGeneratedItems.clear();

    if (languageCode == 'en') {
      _preGeneratedItems.addAll(buildArithmeticItemsEn());
      return;
    }

    // Items 1-4 : Facile (addition/soustraction simple)
    _preGeneratedItems.addAll(_createEasyItems());

    // Items 5-12 : Moyen (multiplication/division)
    _preGeneratedItems.addAll(_createMediumItems());

    // Items 13-18 : Difficile (multi-étapes)
    _preGeneratedItems.addAll(_createHardItems());

    // Items 19-22 : Très difficile (proportions/pourcentages)
    _preGeneratedItems.addAll(_createVeryHardItems());
  }

  /// Retourne les 22 items pré-générés
  List<ArithmeticItem> generateComplete22Items() {
    return List.from(_preGeneratedItems);
  }

  // ========== NIVEAU FACILE : Addition/Soustraction simple (4 items) ==========
  List<ArithmeticItem> _createEasyItems() {
    return [
      // Item 1
      ArithmeticItem(
        problem: 'Si vous avez 3 pommes et que j\'en ajoute 2, combien en avez-vous ?',
        correctAnswer: 5,
        difficulty: DifficultyLevel.easy,
        timeLimitSeconds: 15,
        hasTimeBonus: false,
        thetaValue: -2.0,
      ),

      // Item 2
      ArithmeticItem(
        problem: 'Combien font 8 plus 7 ?',
        correctAnswer: 15,
        difficulty: DifficultyLevel.easy,
        timeLimitSeconds: 15,
        hasTimeBonus: false,
        thetaValue: -1.8,
      ),

      // Item 3
      ArithmeticItem(
        problem: 'Si vous avez 12 euros et que vous dépensez 5 euros, combien vous reste-t-il ?',
        correctAnswer: 7,
        difficulty: DifficultyLevel.easy,
        timeLimitSeconds: 20,
        hasTimeBonus: false,
        thetaValue: -1.5,
      ),

      // Item 4
      ArithmeticItem(
        problem: 'Combien font 20 moins 8 ?',
        correctAnswer: 12,
        difficulty: DifficultyLevel.easy,
        timeLimitSeconds: 15,
        hasTimeBonus: false,
        thetaValue: -1.3,
      ),
    ];
  }

  // ========== NIVEAU MOYEN : Multiplication/Division (8 items) ==========
  List<ArithmeticItem> _createMediumItems() {
    return [
      // Item 5
      ArithmeticItem(
        problem: 'Combien coûtent 4 cahiers à 3 euros pièce ?',
        correctAnswer: 12,
        difficulty: DifficultyLevel.medium,
        timeLimitSeconds: 25,
        hasTimeBonus: false,
        thetaValue: -1.0,
      ),

      // Item 6
      ArithmeticItem(
        problem: 'Combien font 6 fois 7 ?',
        correctAnswer: 42,
        difficulty: DifficultyLevel.medium,
        timeLimitSeconds: 20,
        hasTimeBonus: false,
        thetaValue: -0.8,
      ),

      // Item 7
      ArithmeticItem(
        problem: 'Si vous divisez 24 cookies également entre 6 enfants, combien chaque enfant en reçoit-il ?',
        correctAnswer: 4,
        difficulty: DifficultyLevel.medium,
        timeLimitSeconds: 25,
        hasTimeBonus: false,
        thetaValue: -0.5,
      ),

      // Item 8
      ArithmeticItem(
        problem: 'Combien font 9 fois 8 ?',
        correctAnswer: 72,
        difficulty: DifficultyLevel.medium,
        timeLimitSeconds: 25,
        hasTimeBonus: false,
        thetaValue: -0.3,
      ),

      // Item 9
      ArithmeticItem(
        problem: 'Une douzaine d\'œufs coûte 6 euros. Combien coûtent 2 douzaines ?',
        correctAnswer: 12,
        difficulty: DifficultyLevel.medium,
        timeLimitSeconds: 30,
        hasTimeBonus: false,
        thetaValue: 0.0,
      ),

      // Item 10
      ArithmeticItem(
        problem: 'Combien font 56 divisé par 8 ?',
        correctAnswer: 7,
        difficulty: DifficultyLevel.medium,
        timeLimitSeconds: 25,
        hasTimeBonus: false,
        thetaValue: 0.2,
      ),

      // Item 11
      ArithmeticItem(
        problem: 'Si un livre coûte 15 euros et que vous en achetez 3, combien payez-vous ?',
        correctAnswer: 45,
        difficulty: DifficultyLevel.medium,
        timeLimitSeconds: 30,
        hasTimeBonus: false,
        thetaValue: 0.5,
      ),

      // Item 12
      ArithmeticItem(
        problem: 'Combien font 12 fois 11 ?',
        correctAnswer: 132,
        difficulty: DifficultyLevel.medium,
        timeLimitSeconds: 30,
        hasTimeBonus: false,
        thetaValue: 0.8,
      ),
    ];
  }

  // ========== NIVEAU DIFFICILE : Multi-étapes (6 items) ==========
  List<ArithmeticItem> _createHardItems() {
    return [
      // Item 13
      ArithmeticItem(
        problem: 'Jean a 24 euros. Il dépense un tiers de cette somme. Combien lui reste-t-il ?',
        correctAnswer: 16,
        difficulty: DifficultyLevel.hard,
        timeLimitSeconds: 40,
        hasTimeBonus: true,
        timeBonusThreshold: 25,
        thetaValue: 1.0,
      ),

      // Item 14
      ArithmeticItem(
        problem: 'Si 3 stylos coûtent 9 euros, combien coûtent 5 stylos ?',
        correctAnswer: 15,
        difficulty: DifficultyLevel.hard,
        timeLimitSeconds: 40,
        hasTimeBonus: true,
        timeBonusThreshold: 25,
        thetaValue: 1.2,
      ),

      // Item 15
      ArithmeticItem(
        problem: 'Marie achète 4 livres à 12 euros chacun. Elle paie avec un billet de 100 euros. Combien reçoit-elle en monnaie ?',
        correctAnswer: 52,
        difficulty: DifficultyLevel.hard,
        timeLimitSeconds: 45,
        hasTimeBonus: true,
        timeBonusThreshold: 30,
        thetaValue: 1.4,
      ),

      // Item 16
      ArithmeticItem(
        problem: 'Un train parcourt 120 kilomètres en 2 heures. Quelle est sa vitesse moyenne en kilomètres par heure ?',
        correctAnswer: 60,
        difficulty: DifficultyLevel.hard,
        timeLimitSeconds: 40,
        hasTimeBonus: true,
        timeBonusThreshold: 25,
        thetaValue: 1.6,
      ),

      // Item 17
      ArithmeticItem(
        problem: 'Sophie a 48 bonbons. Elle en donne la moitié à son frère, puis mange un quart du reste. Combien lui en reste-t-il ?',
        correctAnswer: 18,
        difficulty: DifficultyLevel.hard,
        timeLimitSeconds: 50,
        hasTimeBonus: true,
        timeBonusThreshold: 35,
        thetaValue: 1.8,
      ),

      // Item 18
      ArithmeticItem(
        problem: 'Un rectangle mesure 8 mètres de long et 5 mètres de large. Quelle est son aire en mètres carrés ?',
        correctAnswer: 40,
        difficulty: DifficultyLevel.hard,
        timeLimitSeconds: 35,
        hasTimeBonus: true,
        timeBonusThreshold: 20,
        thetaValue: 2.0,
      ),
    ];
  }

  // ========== NIVEAU TRÈS DIFFICILE : Proportions/Pourcentages (4 items) ==========
  List<ArithmeticItem> _createVeryHardItems() {
    return [
      // Item 19
      ArithmeticItem(
        problem: 'Quel est 10 pour cent de 50 ?',
        correctAnswer: 5,
        difficulty: DifficultyLevel.veryHard,
        timeLimitSeconds: 45,
        hasTimeBonus: true,
        timeBonusThreshold: 30,
        thetaValue: 2.2,
      ),

      // Item 20
      ArithmeticItem(
        problem: 'Quel est 25 pour cent de 80 ?',
        correctAnswer: 20,
        difficulty: DifficultyLevel.veryHard,
        timeLimitSeconds: 50,
        hasTimeBonus: true,
        timeBonusThreshold: 35,
        thetaValue: 2.4,
      ),

      // Item 21
      ArithmeticItem(
        problem: 'Un article coûte 60 euros. Son prix augmente de 20 pour cent. Quel est son nouveau prix ?',
        correctAnswer: 72,
        difficulty: DifficultyLevel.veryHard,
        timeLimitSeconds: 60,
        hasTimeBonus: true,
        timeBonusThreshold: 40,
        thetaValue: 2.6,
      ),

      // Item 22
      ArithmeticItem(
        problem: 'Si 5 ouvriers construisent un mur en 12 jours, combien de jours faudrait-il à 3 ouvriers pour construire le même mur ?',
        correctAnswer: 20,
        difficulty: DifficultyLevel.veryHard,
        timeLimitSeconds: 60,
        hasTimeBonus: true,
        timeBonusThreshold: 45,
        thetaValue: 2.8,
      ),
    ];
  }
}

// ========== MODÈLES DE DONNÉES ==========

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

  /// Calcule le score obtenu (0 ou 1).
  ///
  /// Barème harmonisé : précision pure, AUCUN bonus de temps (la vitesse ne
  /// compte que pour les sous-tests Code et Recherche de symboles).
  /// [timeElapsed] est ignoré (conservé pour la compatibilité de signature).
  int calculateScore(int? userAnswer, int timeElapsed) {
    if (userAnswer == null || userAnswer != correctAnswer) {
      return 0; // Réponse incorrecte
    }
    return 1; // Réponse correcte
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
