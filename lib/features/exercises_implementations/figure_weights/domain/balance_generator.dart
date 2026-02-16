import 'dart:math';

/// Générateur de Balances Quantitatives 100% ALÉATOIRES (comme test des cubes)
/// Chaque session génère 27 items complètement uniques
class BalanceGenerator {
  final Random _random;
  final List<BalanceItem> _preGeneratedItems = [];

  BalanceGenerator({int? seed}) : _random = Random(seed) {
    _initializeAllItems();
  }

  /// Initialise TOUS les 27 items uniques avec génération aléatoire
  void _initializeAllItems() {
    _preGeneratedItems.clear();

    // Items 1-5 : Très facile (θ = -1.8 à -1.2)
    for (int i = 0; i < 5; i++) {
      _preGeneratedItems.add(_generateLevel1Item(-1.8 + i * 0.15));
    }

    // Items 6-10 : Facile (θ = -0.8 à -0.2)
    for (int i = 0; i < 5; i++) {
      _preGeneratedItems.add(_generateLevel2Item(-0.8 + i * 0.15));
    }

    // Items 11-16 : Moyen (θ = 0.2 à 0.8)
    for (int i = 0; i < 6; i++) {
      _preGeneratedItems.add(_generateLevel3Item(0.2 + i * 0.12));
    }

    // Items 17-22 : Moyen-Difficile (θ = 1.2 à 1.8)
    for (int i = 0; i < 6; i++) {
      _preGeneratedItems.add(_generateLevel4Item(1.2 + i * 0.12));
    }

    // Items 23-27 : Difficile (θ = 2.2 à 2.9)
    for (int i = 0; i < 5; i++) {
      _preGeneratedItems.add(_generateLevel5Item(2.2 + i * 0.175));
    }
  }

  /// Retourne les 27 items générés
  List<BalanceItem> generateComplete27Items() {
    return List.from(_preGeneratedItems);
  }

  // ========== HELPERS DE VALIDATION ==========

  /// S'assure que toutes les options sont uniques (pas de duplications)
  List<List<Token>> _ensureUniqueOptions(List<Token> correct, List<List<Token>> distractors) {
    final uniqueOptions = <List<Token>>[correct];
    final maxAttempts = 20;  // Limite de tentatives pour éviter boucle infinie

    for (var distractor in distractors) {
      var currentDistractor = distractor;
      var attempts = 0;

      // Vérifier si le distracteur est unique
      while (_isDuplicateOption(currentDistractor, uniqueOptions) && attempts < maxAttempts) {
        // Générer une variation légère pour éviter le duplicate
        currentDistractor = _generateAlternativeOption(currentDistractor, correct);
        attempts++;
      }

      if (attempts < maxAttempts) {
        uniqueOptions.add(currentDistractor);
      }
    }

    // S'assurer qu'on a exactement 4 options (1 correcte + 3 distracteurs)
    while (uniqueOptions.length < 4) {
      final newDistractor = _generateAlternativeOption(correct, correct);
      if (!_isDuplicateOption(newDistractor, uniqueOptions)) {
        uniqueOptions.add(newDistractor);
      }
    }

    return uniqueOptions.sublist(1);  // Retourner seulement les 3 distracteurs
  }

  /// Vérifie si une option est un duplicate
  bool _isDuplicateOption(List<Token> option, List<List<Token>> existingOptions) {
    for (var existing in existingOptions) {
      if (_areTokenListsEqual(option, existing)) {
        return true;
      }
    }
    return false;
  }

  /// Compare deux listes de tokens pour égalité
  bool _areTokenListsEqual(List<Token> list1, List<Token> list2) {
    if (list1.length != list2.length) return false;

    for (int i = 0; i < list1.length; i++) {
      if (list1[i].shape != list2[i].shape || list1[i].count != list2[i].count) {
        return false;
      }

      // Comparer les fractions si elles existent
      final frac1 = list1[i].fraction ?? 1.0;
      final frac2 = list2[i].fraction ?? 1.0;
      if ((frac1 - frac2).abs() > 0.001) {
        return false;
      }
    }
    return true;
  }

  /// Génère une option alternative en modifiant légèrement les attributs
  List<Token> _generateAlternativeOption(List<Token> base, List<Token> correct) {
    if (base.isEmpty) return [Token(shape: TokenShape.circle, count: 1)];

    final baseToken = base[0];
    final correctCount = correct.isNotEmpty ? correct[0].count : 1;

    // Créer des variations différentes du count correct
    final variations = [
      [Token(shape: baseToken.shape, count: max(1, correctCount - 2))],
      [Token(shape: baseToken.shape, count: correctCount + 2)],
      [Token(shape: baseToken.shape, count: max(1, correctCount - 3))],
      [Token(shape: baseToken.shape, count: correctCount + 3)],
    ];

    return variations[_random.nextInt(variations.length)];
  }

  // ========== GÉNÉRATEURS PAR NIVEAU ==========

  /// Niveau 1: Équivalence simple avec 1-2 balances
  BalanceItem _generateLevel1Item(double theta) {
    final variant = _random.nextInt(3);

    if (variant == 0) {
      // Type A: Matching direct (2 cercles = 2 cercles)
      return _generateDirectMatchingItem(theta);
    } else if (variant == 1) {
      // Type B: Égalité avec différentes formes (3 carrés = 1 triangle, trouve ? carrés pour 2 triangles)
      return _generateSimpleRatioItem(theta);
    } else {
      // Type C: Addition simple (2 cercles + 1 carré = ?, sachant que 1 cercle = 1 carré)
      return _generateSimpleAdditionItem(theta);
    }
  }

  BalanceItem _generateDirectMatchingItem(double theta) {
    final shapes = [TokenShape.circle, TokenShape.square, TokenShape.triangle,
                    TokenShape.diamond, TokenShape.star];
    final shape = shapes[_random.nextInt(shapes.length)];
    final count = _random.nextInt(3) + 2; // 2-4 objets

    final balance = Balance(
      leftSide: [Token(shape: shape, count: count)],
      rightSide: [Token(shape: shape, count: count)],
    );

    final answer = [Token(shape: shape, count: count)];

    final options = _generateOptions(
      correct: answer,
      baseShape: shape,
      correctCount: count,
      difficulty: 1,
      context: BalanceContext(
        questionType: QuestionType.findEquivalent,
        ratio: 1,
        multiplier: count,
      ),
    );

    return BalanceItem(
      balances: [balance],
      question: BalanceQuestion(
        type: QuestionType.findEquivalent,
        targetSide: [Token(shape: shape, count: count)],
      ),
      correctAnswer: answer,
      options: options..shuffle(_random),
      timeLimitSeconds: 20,
      thetaValue: theta,
    );
  }

  BalanceItem _generateSimpleRatioItem(double theta) {
    final shapes = [TokenShape.circle, TokenShape.square, TokenShape.triangle, TokenShape.diamond];
    shapes.shuffle(_random);

    final shapeA = shapes[0];
    final shapeB = shapes[1];

    final ratio = _random.nextInt(2) + 2; // 2-3

    // Balance: ratio*A = 1*B
    final balance = Balance(
      leftSide: [Token(shape: shapeA, count: ratio)],
      rightSide: [Token(shape: shapeB, count: 1)],
    );

    // Question: 2*B = ? A
    final questionB = 2;
    final answerA = ratio * questionB;

    final answer = [Token(shape: shapeA, count: answerA)];

    final options = _generateOptions(
      correct: answer,
      baseShape: shapeA,
      correctCount: answerA,
      difficulty: 1,
      context: BalanceContext(
        questionType: QuestionType.findEquivalent,
        ratio: ratio,
        multiplier: questionB,
      ),
    );

    return BalanceItem(
      balances: [balance],
      question: BalanceQuestion(
        type: QuestionType.findEquivalent,
        targetSide: [Token(shape: shapeB, count: questionB)],
      ),
      correctAnswer: answer,
      options: options..shuffle(_random),
      timeLimitSeconds: 20,
      thetaValue: theta,
    );
  }

  BalanceItem _generateSimpleAdditionItem(double theta) {
    final shapes = [TokenShape.circle, TokenShape.square, TokenShape.triangle];
    shapes.shuffle(_random);

    final shapeA = shapes[0];
    final shapeB = shapes[1];

    // Balance: A = B (valeur égale)
    final balance = Balance(
      leftSide: [Token(shape: shapeA, count: 1)],
      rightSide: [Token(shape: shapeB, count: 1)],
    );

    // Question: 2A + 1B = ?
    final countA = 2;
    final countB = 1;
    final totalValue = countA + countB; // tous valent 1

    final answer = [Token(shape: shapeA, count: totalValue)];

    final options = _generateOptions(
      correct: answer,
      baseShape: shapeA,
      correctCount: totalValue,
      difficulty: 1,
      context: BalanceContext(
        questionType: QuestionType.findSum,
        addend1: countA,
        addend2: countB,
      ),
    );

    return BalanceItem(
      balances: [balance],
      question: BalanceQuestion(
        type: QuestionType.findSum,
        targetSide: [
          Token(shape: shapeA, count: countA),
          Token(shape: shapeB, count: countB),
        ],
      ),
      correctAnswer: answer,
      options: options..shuffle(_random),
      timeLimitSeconds: 20,
      thetaValue: theta,
    );
  }

  /// Niveau 2: Ratios et additions avec 2 balances
  BalanceItem _generateLevel2Item(double theta) {
    final variant = _random.nextInt(3);

    if (variant == 0) {
      // Type A: Multiplication avec ratio (3A = B, trouve 6A en B)
      return _generateMultiplicationRatioItem(theta);
    } else if (variant == 1) {
      // Type B: Addition avec 2 formes (A = 2C, B = 3C, trouve A + B)
      return _generateTwoShapeAdditionItem(theta);
    } else {
      // Type C: Soustraction simple (4A = B, 2A = ?)
      return _generateSimpleSubtractionItem(theta);
    }
  }

  BalanceItem _generateMultiplicationRatioItem(double theta) {
    final shapes = [TokenShape.circle, TokenShape.square, TokenShape.triangle, TokenShape.diamond];
    shapes.shuffle(_random);

    final shapeA = shapes[0];
    final shapeB = shapes[1];

    final ratio = _random.nextInt(3) + 2; // 2-4
    final multiplier = _random.nextInt(2) + 2; // 2-3

    // Balance: ratio*A = B
    final balance = Balance(
      leftSide: [Token(shape: shapeA, count: ratio)],
      rightSide: [Token(shape: shapeB, count: 1)],
    );

    // Question: (ratio * multiplier) * A = ?
    final questionCount = ratio * multiplier;
    final answerCount = multiplier;

    final answer = [Token(shape: shapeB, count: answerCount)];

    final options = _generateOptions(
      correct: answer,
      baseShape: shapeB,
      correctCount: answerCount,
      difficulty: 2,
      context: BalanceContext(
        questionType: QuestionType.findEquivalent,
        ratio: ratio,
        multiplier: multiplier,
      ),
    );

    return BalanceItem(
      balances: [balance],
      question: BalanceQuestion(
        type: QuestionType.findEquivalent,
        targetSide: [Token(shape: shapeA, count: questionCount)],
      ),
      correctAnswer: answer,
      options: options..shuffle(_random),
      timeLimitSeconds: 25,
      thetaValue: theta,
    );
  }

  BalanceItem _generateTwoShapeAdditionItem(double theta) {
    final shapes = [TokenShape.circle, TokenShape.square, TokenShape.triangle, TokenShape.diamond, TokenShape.star];
    shapes.shuffle(_random);

    final shapeC = shapes[0]; // Base
    final shapeA = shapes[1];
    final shapeB = shapes[2];

    final ratioA = _random.nextInt(2) + 2; // 2-3
    final ratioB = _random.nextInt(2) + 2; // 2-3

    // Balance 1: ratioA*C = A
    final balance1 = Balance(
      leftSide: [Token(shape: shapeC, count: ratioA)],
      rightSide: [Token(shape: shapeA, count: 1)],
    );

    // Balance 2: ratioB*C = B
    final balance2 = Balance(
      leftSide: [Token(shape: shapeC, count: ratioB)],
      rightSide: [Token(shape: shapeB, count: 1)],
    );

    // Question: A + B = ? C
    final answerCount = ratioA + ratioB;
    final answer = [Token(shape: shapeC, count: answerCount)];

    final options = _generateOptions(
      correct: answer,
      baseShape: shapeC,
      correctCount: answerCount,
      difficulty: 2,
      context: BalanceContext(
        questionType: QuestionType.findSum,
        addend1: ratioA,
        addend2: ratioB,
      ),
    );

    return BalanceItem(
      balances: [balance1, balance2],
      question: BalanceQuestion(
        type: QuestionType.findSum,
        targetSide: [
          Token(shape: shapeA, count: 1),
          Token(shape: shapeB, count: 1),
        ],
      ),
      correctAnswer: answer,
      options: options..shuffle(_random),
      timeLimitSeconds: 25,
      thetaValue: theta,
    );
  }

  BalanceItem _generateSimpleSubtractionItem(double theta) {
    final shapes = [TokenShape.circle, TokenShape.square, TokenShape.triangle, TokenShape.diamond];
    shapes.shuffle(_random);

    final shapeA = shapes[0];
    final shapeB = shapes[1];

    final totalRatio = _random.nextInt(2) + 4; // 4-5
    final partRatio = _random.nextInt(2) + 2; // 2-3

    // Balance: totalRatio*A = B
    final balance = Balance(
      leftSide: [Token(shape: shapeA, count: totalRatio)],
      rightSide: [Token(shape: shapeB, count: 1)],
    );

    // Question: partRatio*A = ?
    // On cherche l'équivalent en fraction de B
    final numerator = partRatio;
    final denominator = totalRatio;

    final answer = [Token(shape: shapeB, count: 1, fraction: numerator / denominator)];

    final options = _generateOptions(
      correct: answer,
      baseShape: shapeB,
      correctCount: 1,
      difficulty: 2,
      context: BalanceContext(
        questionType: QuestionType.findEquivalent,
        ratio: totalRatio,
        multiplier: partRatio,
      ),
    );

    return BalanceItem(
      balances: [balance],
      question: BalanceQuestion(
        type: QuestionType.findEquivalent,
        targetSide: [Token(shape: shapeA, count: partRatio)],
      ),
      correctAnswer: answer,
      options: options..shuffle(_random),
      timeLimitSeconds: 30,
      thetaValue: theta,
    );
  }

  /// Niveau 3: Substitutions complexes avec 2-3 balances
  BalanceItem _generateLevel3Item(double theta) {
    final variant = _random.nextInt(4);

    if (variant == 0) {
      // Type A: Addition de 2 formes (A=2B, C=3B, trouve A+C)
      return _generateTwoFormAdditionItem(theta);
    } else if (variant == 1) {
      // Type B: Soustraction (A=5B, C=2B, trouve A-C)
      return _generateSubtractionWithSubstitutionItem(theta);
    } else if (variant == 2) {
      // Type C: Combinaison mixte (A=2B, B=3C, trouve A+B en C)
      return _generateMixedCombinationItem(theta);
    } else {
      // Type D: Multiple de somme (A=2C, B=3C, trouve 2A+B)
      return _generateMultipleSumItem(theta);
    }
  }

  BalanceItem _generateTwoFormAdditionItem(double theta) {
    final shapes = [TokenShape.circle, TokenShape.square, TokenShape.triangle,
                    TokenShape.diamond, TokenShape.star];
    shapes.shuffle(_random);

    final baseShape = shapes[0]; // B
    final shape1 = shapes[1];    // A
    final shape2 = shapes[2];    // C

    final ratio1 = _random.nextInt(3) + 2; // A = 2-4 B
    final ratio2 = _random.nextInt(3) + 2; // C = 2-4 B

    final balance1 = Balance(
      leftSide: [Token(shape: baseShape, count: ratio1)],
      rightSide: [Token(shape: shape1, count: 1)],
    );

    final balance2 = Balance(
      leftSide: [Token(shape: baseShape, count: ratio2)],
      rightSide: [Token(shape: shape2, count: 1)],
    );

    final answerCount = ratio1 + ratio2;
    final answer = [Token(shape: baseShape, count: answerCount)];

    final options = _generateOptions(
      correct: answer,
      baseShape: baseShape,
      correctCount: answerCount,
      difficulty: 3,
      context: BalanceContext(
        questionType: QuestionType.findSum,
        addend1: ratio1,
        addend2: ratio2,
      ),
    );

    return BalanceItem(
      balances: [balance1, balance2],
      question: BalanceQuestion(
        type: QuestionType.findSum,
        targetSide: [
          Token(shape: shape1, count: 1),
          Token(shape: shape2, count: 1),
        ],
      ),
      correctAnswer: answer,
      options: options..shuffle(_random),
      timeLimitSeconds: 30,
      thetaValue: theta,
    );
  }

  BalanceItem _generateSubtractionWithSubstitutionItem(double theta) {
    final shapes = [TokenShape.circle, TokenShape.square, TokenShape.triangle,
                    TokenShape.diamond, TokenShape.star];
    shapes.shuffle(_random);

    final baseShape = shapes[0];
    final shapeA = shapes[1];
    final shapeC = shapes[2];

    final ratioA = _random.nextInt(2) + 4; // A = 4-5 B
    final ratioC = _random.nextInt(2) + 2; // C = 2-3 B

    final balance1 = Balance(
      leftSide: [Token(shape: baseShape, count: ratioA)],
      rightSide: [Token(shape: shapeA, count: 1)],
    );

    final balance2 = Balance(
      leftSide: [Token(shape: baseShape, count: ratioC)],
      rightSide: [Token(shape: shapeC, count: 1)],
    );

    // Question: A - C = ? B
    final answerCount = ratioA - ratioC;
    final answer = [Token(shape: baseShape, count: answerCount)];

    final options = _generateOptions(
      correct: answer,
      baseShape: baseShape,
      correctCount: answerCount,
      difficulty: 3,
      context: BalanceContext(
        questionType: QuestionType.findDifference,
        addend1: ratioA,
        addend2: ratioC,
      ),
    );

    return BalanceItem(
      balances: [balance1, balance2],
      question: BalanceQuestion(
        type: QuestionType.findDifference,
        targetSide: [
          Token(shape: shapeA, count: 1),
          Token(shape: shapeC, count: 1),
        ],
      ),
      correctAnswer: answer,
      options: options..shuffle(_random),
      timeLimitSeconds: 30,
      thetaValue: theta,
    );
  }

  BalanceItem _generateMixedCombinationItem(double theta) {
    final shapes = [TokenShape.circle, TokenShape.square, TokenShape.triangle,
                    TokenShape.diamond, TokenShape.star, TokenShape.hexagon];
    shapes.shuffle(_random);

    final shapeC = shapes[0]; // Base
    final shapeB = shapes[1]; // Intermédiaire
    final shapeA = shapes[2]; // Final

    final ratioBC = _random.nextInt(2) + 2; // B = 2-3 C
    final ratioAB = _random.nextInt(2) + 2; // A = 2-3 B

    final balance1 = Balance(
      leftSide: [Token(shape: shapeC, count: ratioBC)],
      rightSide: [Token(shape: shapeB, count: 1)],
    );

    final balance2 = Balance(
      leftSide: [Token(shape: shapeB, count: ratioAB)],
      rightSide: [Token(shape: shapeA, count: 1)],
    );

    // Question: A + B = ? C
    // A = ratioAB * ratioBC * C
    // B = ratioBC * C
    final answerCount = (ratioAB * ratioBC) + ratioBC;
    final answer = [Token(shape: shapeC, count: answerCount)];

    final options = _generateOptions(
      correct: answer,
      baseShape: shapeC,
      correctCount: answerCount,
      difficulty: 3,
      context: BalanceContext(
        questionType: QuestionType.findSum,
        addend1: ratioAB * ratioBC,
        addend2: ratioBC,
      ),
    );

    return BalanceItem(
      balances: [balance1, balance2],
      question: BalanceQuestion(
        type: QuestionType.findSum,
        targetSide: [
          Token(shape: shapeA, count: 1),
          Token(shape: shapeB, count: 1),
        ],
      ),
      correctAnswer: answer,
      options: options..shuffle(_random),
      timeLimitSeconds: 35,
      thetaValue: theta,
    );
  }

  BalanceItem _generateMultipleSumItem(double theta) {
    final shapes = [TokenShape.circle, TokenShape.square, TokenShape.triangle,
                    TokenShape.diamond, TokenShape.star];
    shapes.shuffle(_random);

    final baseShape = shapes[0];
    final shapeA = shapes[1];
    final shapeB = shapes[2];

    final ratioA = _random.nextInt(2) + 2; // A = 2-3 C
    final ratioB = _random.nextInt(2) + 3; // B = 3-4 C

    final balance1 = Balance(
      leftSide: [Token(shape: baseShape, count: ratioA)],
      rightSide: [Token(shape: shapeA, count: 1)],
    );

    final balance2 = Balance(
      leftSide: [Token(shape: baseShape, count: ratioB)],
      rightSide: [Token(shape: shapeB, count: 1)],
    );

    // Question: 2A + B = ? C
    final multiplierA = 2;
    final answerCount = (multiplierA * ratioA) + ratioB;
    final answer = [Token(shape: baseShape, count: answerCount)];

    final options = _generateOptions(
      correct: answer,
      baseShape: baseShape,
      correctCount: answerCount,
      difficulty: 3,
      context: BalanceContext(
        questionType: QuestionType.findSum,
        addend1: multiplierA * ratioA,
        addend2: ratioB,
      ),
    );

    return BalanceItem(
      balances: [balance1, balance2],
      question: BalanceQuestion(
        type: QuestionType.findSum,
        targetSide: [
          Token(shape: shapeA, count: multiplierA),
          Token(shape: shapeB, count: 1),
        ],
      ),
      correctAnswer: answer,
      options: options..shuffle(_random),
      timeLimitSeconds: 35,
      thetaValue: theta,
    );
  }

  /// Niveau 4: Chaînes complexes et systèmes à 3 balances
  BalanceItem _generateLevel4Item(double theta) {
    final variant = _random.nextInt(4);

    if (variant == 0) {
      // Type A: Chaîne multiplicative (A=2B, B=3C, trouve 2A en C)
      return _generateMultiplicativeChainItem(theta);
    } else if (variant == 1) {
      // Type B: Système avec fraction (3A=B, 2B=C, trouve A en fraction de C)
      return _generateFractionSystemItem(theta);
    } else if (variant == 2) {
      // Type C: Combinaison complexe (A+B=C, B=2D, A=3D, trouve C)
      return _generateComplexCombinationItem(theta);
    } else {
      // Type D: Système inversé (2A+B=10C, A=3C, trouve B)
      return _generateInverseSystemItem(theta);
    }
  }

  BalanceItem _generateMultiplicativeChainItem(double theta) {
    final shapes = [TokenShape.circle, TokenShape.square, TokenShape.triangle,
                    TokenShape.diamond, TokenShape.star, TokenShape.hexagon];
    shapes.shuffle(_random);

    final shapeC = shapes[0]; // Base
    final shapeB = shapes[1]; // Intermédiaire
    final shapeA = shapes[2]; // Final

    final ratioBC = _random.nextInt(2) + 2; // B = 2-3 C
    final ratioAB = _random.nextInt(2) + 2; // A = 2-3 B

    final balance1 = Balance(
      leftSide: [Token(shape: shapeC, count: ratioBC)],
      rightSide: [Token(shape: shapeB, count: 1)],
    );

    final balance2 = Balance(
      leftSide: [Token(shape: shapeB, count: ratioAB)],
      rightSide: [Token(shape: shapeA, count: 1)],
    );

    final questionCountA = _random.nextInt(2) + 2; // 2-3 A
    final answerCount = questionCountA * ratioAB * ratioBC;

    final answer = [Token(shape: shapeC, count: answerCount)];

    final options = _generateOptions(
      correct: answer,
      baseShape: shapeC,
      correctCount: answerCount,
      difficulty: 4,
      context: BalanceContext(
        questionType: QuestionType.findEquivalent,
        chainRatios: [ratioAB, ratioBC],
        multiplier: questionCountA,
      ),
    );

    return BalanceItem(
      balances: [balance1, balance2],
      question: BalanceQuestion(
        type: QuestionType.findEquivalent,
        targetSide: [Token(shape: shapeA, count: questionCountA)],
      ),
      correctAnswer: answer,
      options: options..shuffle(_random),
      timeLimitSeconds: 35,
      thetaValue: theta,
    );
  }

  BalanceItem _generateFractionSystemItem(double theta) {
    final shapes = [TokenShape.circle, TokenShape.square, TokenShape.triangle,
                    TokenShape.diamond, TokenShape.star];
    shapes.shuffle(_random);

    final shapeC = shapes[0];
    final shapeB = shapes[1];
    final shapeA = shapes[2];

    final ratioAB = 3; // 3A = B
    final ratioBC = 2; // 2B = C

    final balance1 = Balance(
      leftSide: [Token(shape: shapeA, count: ratioAB)],
      rightSide: [Token(shape: shapeB, count: 1)],
    );

    final balance2 = Balance(
      leftSide: [Token(shape: shapeB, count: ratioBC)],
      rightSide: [Token(shape: shapeC, count: 1)],
    );

    // Question: 1A = ? C
    // 3A = B, 2B = C  =>  6A = C  =>  A = C/6
    final numerator = 1;
    final denominator = ratioAB * ratioBC;

    final answer = [Token(shape: shapeC, count: 1, fraction: numerator / denominator)];

    final options = _generateOptions(
      correct: answer,
      baseShape: shapeC,
      correctCount: 1,
      difficulty: 4,
      context: BalanceContext(
        questionType: QuestionType.findEquivalent,
        chainRatios: [ratioAB, ratioBC],
      ),
    );

    return BalanceItem(
      balances: [balance1, balance2],
      question: BalanceQuestion(
        type: QuestionType.findEquivalent,
        targetSide: [Token(shape: shapeA, count: 1)],
      ),
      correctAnswer: answer,
      options: options..shuffle(_random),
      timeLimitSeconds: 40,
      thetaValue: theta,
    );
  }

  BalanceItem _generateComplexCombinationItem(double theta) {
    final shapes = [TokenShape.circle, TokenShape.square, TokenShape.triangle,
                    TokenShape.diamond, TokenShape.star];
    shapes.shuffle(_random);

    final shapeD = shapes[0];
    final shapeB = shapes[1];
    final shapeA = shapes[2];
    final shapeC = shapes[3];

    final ratioB = _random.nextInt(2) + 2; // B = 2-3 D
    final ratioA = _random.nextInt(2) + 3; // A = 3-4 D

    final balance1 = Balance(
      leftSide: [Token(shape: shapeD, count: ratioB)],
      rightSide: [Token(shape: shapeB, count: 1)],
    );

    final balance2 = Balance(
      leftSide: [Token(shape: shapeD, count: ratioA)],
      rightSide: [Token(shape: shapeA, count: 1)],
    );

    final balance3 = Balance(
      leftSide: [
        Token(shape: shapeA, count: 1),
        Token(shape: shapeB, count: 1),
      ],
      rightSide: [Token(shape: shapeC, count: 1)],
    );

    // Question: C = ? D
    final answerCount = ratioA + ratioB;
    final answer = [Token(shape: shapeD, count: answerCount)];

    final options = _generateOptions(
      correct: answer,
      baseShape: shapeD,
      correctCount: answerCount,
      difficulty: 4,
      context: BalanceContext(
        questionType: QuestionType.findEquivalent,
        addend1: ratioA,
        addend2: ratioB,
      ),
    );

    return BalanceItem(
      balances: [balance1, balance2, balance3],
      question: BalanceQuestion(
        type: QuestionType.findEquivalent,
        targetSide: [Token(shape: shapeC, count: 1)],
      ),
      correctAnswer: answer,
      options: options..shuffle(_random),
      timeLimitSeconds: 40,
      thetaValue: theta,
    );
  }

  BalanceItem _generateInverseSystemItem(double theta) {
    final shapes = [TokenShape.circle, TokenShape.square, TokenShape.triangle,
                    TokenShape.diamond, TokenShape.star];
    shapes.shuffle(_random);

    final shapeC = shapes[0];
    final shapeA = shapes[1];
    final shapeB = shapes[2];

    final ratioA = _random.nextInt(2) + 2; // A = 2-3 C
    final totalInC = _random.nextInt(2) + 8; // 8-9 C

    // Balance 1: A = ratioA * C
    final balance1 = Balance(
      leftSide: [Token(shape: shapeC, count: ratioA)],
      rightSide: [Token(shape: shapeA, count: 1)],
    );

    // Balance 2: 2A + B = totalInC * C
    final multiplierA = 2;
    final ratioB = totalInC - (multiplierA * ratioA);

    final balance2 = Balance(
      leftSide: [
        Token(shape: shapeA, count: multiplierA),
        Token(shape: shapeB, count: 1),
      ],
      rightSide: [Token(shape: shapeC, count: totalInC)],
    );

    // Question: B = ? C
    final answer = [Token(shape: shapeC, count: ratioB)];

    final options = _generateOptions(
      correct: answer,
      baseShape: shapeC,
      correctCount: ratioB,
      difficulty: 4,
      context: BalanceContext(
        questionType: QuestionType.findEquivalent,
        ratio: ratioA,
        multiplier: multiplierA,
      ),
    );

    return BalanceItem(
      balances: [balance1, balance2],
      question: BalanceQuestion(
        type: QuestionType.findEquivalent,
        targetSide: [Token(shape: shapeB, count: 1)],
      ),
      correctAnswer: answer,
      options: options..shuffle(_random),
      timeLimitSeconds: 40,
      thetaValue: theta,
    );
  }

  /// Niveau 5: Systèmes complexes à 3-4 balances avec fractions
  BalanceItem _generateLevel5Item(double theta) {
    final variant = _random.nextInt(4);

    if (variant == 0) {
      // Type A: Chaîne longue à 4 balances (A=2B, B=3C, C=2D, trouve 2A+B en D)
      return _generateLongChainItem(theta);
    } else if (variant == 1) {
      // Type B: Système avec fractions complexes (2A+3B=C, 4A=D, 2B=D, trouve C/D)
      return _generateComplexFractionItem(theta);
    } else if (variant == 2) {
      // Type C: Système circulaire (A+B=C, B+C=D, A+D=E, trouve E)
      return _generateCircularSystemItem(theta);
    } else {
      // Type D: Substitution inversée multiple (3X+2Y=12Z, X=4Z, trouve Y)
      return _generateMultipleInverseSubstitutionItem(theta);
    }
  }

  BalanceItem _generateLongChainItem(double theta) {
    final shapes = [TokenShape.circle, TokenShape.square, TokenShape.triangle,
                    TokenShape.diamond, TokenShape.star, TokenShape.hexagon];
    shapes.shuffle(_random);

    final shapeD = shapes[0]; // Base
    final shapeC = shapes[1];
    final shapeB = shapes[2];
    final shapeA = shapes[3];

    final ratioCD = _random.nextInt(2) + 2; // C = 2-3 D
    final ratioBC = _random.nextInt(2) + 2; // B = 2-3 C
    final ratioAB = _random.nextInt(2) + 2; // A = 2-3 B

    final balance1 = Balance(
      leftSide: [Token(shape: shapeD, count: ratioCD)],
      rightSide: [Token(shape: shapeC, count: 1)],
    );

    final balance2 = Balance(
      leftSide: [Token(shape: shapeC, count: ratioBC)],
      rightSide: [Token(shape: shapeB, count: 1)],
    );

    final balance3 = Balance(
      leftSide: [Token(shape: shapeB, count: ratioAB)],
      rightSide: [Token(shape: shapeA, count: 1)],
    );

    // Question: 2A + B = ? D
    final multiplierA = 2;
    final answerCount = (multiplierA * ratioAB * ratioBC * ratioCD) + (ratioBC * ratioCD);

    final answer = [Token(shape: shapeD, count: answerCount)];

    final options = _generateOptions(
      correct: answer,
      baseShape: shapeD,
      correctCount: answerCount,
      difficulty: 5,
      context: BalanceContext(
        questionType: QuestionType.findSum,
        chainRatios: [ratioAB, ratioBC, ratioCD],
        addend1: multiplierA,
      ),
    );

    return BalanceItem(
      balances: [balance1, balance2, balance3],
      question: BalanceQuestion(
        type: QuestionType.findSum,
        targetSide: [
          Token(shape: shapeA, count: multiplierA),
          Token(shape: shapeB, count: 1),
        ],
      ),
      correctAnswer: answer,
      options: options..shuffle(_random),
      timeLimitSeconds: 50,
      thetaValue: theta,
    );
  }

  BalanceItem _generateComplexFractionItem(double theta) {
    final shapes = [TokenShape.circle, TokenShape.square, TokenShape.triangle,
                    TokenShape.diamond, TokenShape.star];
    shapes.shuffle(_random);

    final shapeD = shapes[0]; // Base
    final shapeA = shapes[1];
    final shapeB = shapes[2];
    final shapeC = shapes[3];

    // 4A = D
    final ratioAD = 4;
    // 2B = D
    final ratioBD = 2;

    final balance1 = Balance(
      leftSide: [Token(shape: shapeA, count: ratioAD)],
      rightSide: [Token(shape: shapeD, count: 1)],
    );

    final balance2 = Balance(
      leftSide: [Token(shape: shapeB, count: ratioBD)],
      rightSide: [Token(shape: shapeD, count: 1)],
    );

    // 2A + 3B = C
    final multiplierA = 2;
    final multiplierB = 3;

    final balance3 = Balance(
      leftSide: [
        Token(shape: shapeA, count: multiplierA),
        Token(shape: shapeB, count: multiplierB),
      ],
      rightSide: [Token(shape: shapeC, count: 1)],
    );

    // Question: C = ? D
    // A = D/4, B = D/2
    // C = 2(D/4) + 3(D/2) = D/2 + 3D/2 = 2D
    final numerator = (multiplierA * ratioBD) + (multiplierB * ratioAD);
    final denominator = ratioAD * ratioBD;
    final simplified = numerator ~/ denominator; // Should be 2

    final answer = [Token(shape: shapeD, count: simplified)];

    final options = _generateOptions(
      correct: answer,
      baseShape: shapeD,
      correctCount: simplified,
      difficulty: 5,
      context: BalanceContext(
        questionType: QuestionType.findEquivalent,
        addend1: multiplierA * ratioBD,
        addend2: multiplierB * ratioAD,
      ),
    );

    return BalanceItem(
      balances: [balance1, balance2, balance3],
      question: BalanceQuestion(
        type: QuestionType.findEquivalent,
        targetSide: [Token(shape: shapeC, count: 1)],
      ),
      correctAnswer: answer,
      options: options..shuffle(_random),
      timeLimitSeconds: 50,
      thetaValue: theta,
    );
  }

  BalanceItem _generateCircularSystemItem(double theta) {
    final shapes = [TokenShape.circle, TokenShape.square, TokenShape.triangle,
                    TokenShape.diamond, TokenShape.star, TokenShape.hexagon];
    shapes.shuffle(_random);

    final shapeA = shapes[0];
    final shapeB = shapes[1];
    final shapeC = shapes[2];
    final shapeD = shapes[3];
    final shapeE = shapes[4];

    // Système circulaire avec valeurs fixes pour cohérence
    // A = 2, B = 3, C = 5, D = 7, E = 9
    final valueA = 2;
    final valueB = 3;

    // A + B = C (implicite, C vaut 5)
    final balance1 = Balance(
      leftSide: [
        Token(shape: shapeA, count: 1),
        Token(shape: shapeB, count: 1),
      ],
      rightSide: [Token(shape: shapeC, count: 1)],
    );

    // B + C = D  (3 + 5 = 8, mais on va utiliser ratio)
    // Pour rendre aléatoire, on utilise: valueB + valueC = valueD
    final valueC = valueA + valueB; // 5
    final valueD = valueB + valueC; // 8

    final balance2 = Balance(
      leftSide: [
        Token(shape: shapeB, count: 1),
        Token(shape: shapeC, count: 1),
      ],
      rightSide: [Token(shape: shapeD, count: 1)],
    );

    // A + D = E  (2 + 8 = 10)
    final valueE = valueA + valueD;

    final balance3 = Balance(
      leftSide: [
        Token(shape: shapeA, count: 1),
        Token(shape: shapeD, count: 1),
      ],
      rightSide: [Token(shape: shapeE, count: 1)],
    );

    // Question: E = ? (en combinaison de formes de base, convertir en unités A)
    // Comme nous n'avons pas de forme de base, utilisons un token neutre
    // Alternative: Question: E = combien si A=2 et B=3?
    // Simplifions: E = ? A
    final ratioEtoA = valueE ~/ valueA; // 10/2 = 5

    final answer = [Token(shape: shapeA, count: ratioEtoA)];

    final options = _generateOptions(
      correct: answer,
      baseShape: shapeA,
      correctCount: ratioEtoA,
      difficulty: 5,
      context: BalanceContext(
        questionType: QuestionType.findEquivalent,
        addend1: valueA,
        addend2: valueB,
      ),
    );

    return BalanceItem(
      balances: [balance1, balance2, balance3],
      question: BalanceQuestion(
        type: QuestionType.findEquivalent,
        targetSide: [Token(shape: shapeE, count: 1)],
      ),
      correctAnswer: answer,
      options: options..shuffle(_random),
      timeLimitSeconds: 50,
      thetaValue: theta,
    );
  }

  BalanceItem _generateMultipleInverseSubstitutionItem(double theta) {
    final shapes = [TokenShape.circle, TokenShape.square, TokenShape.triangle,
                    TokenShape.diamond, TokenShape.star];
    shapes.shuffle(_random);

    final shapeZ = shapes[0]; // Base
    final shapeX = shapes[1];
    final shapeY = shapes[2];

    final ratioX = _random.nextInt(2) + 3; // X = 3-4 Z
    final totalZ = _random.nextInt(3) + 10; // Total = 10-12 Z
    final multiplierX = _random.nextInt(2) + 2; // 2-3 X

    // Balance 1: X = ratioX * Z
    final balance1 = Balance(
      leftSide: [Token(shape: shapeZ, count: ratioX)],
      rightSide: [Token(shape: shapeX, count: 1)],
    );

    // Balance 2: multiplierX*X + Y = totalZ*Z
    // Donc Y = totalZ*Z - multiplierX*ratioX*Z
    final ratioY = totalZ - (multiplierX * ratioX);

    final balance2 = Balance(
      leftSide: [
        Token(shape: shapeX, count: multiplierX),
        Token(shape: shapeY, count: 1),
      ],
      rightSide: [Token(shape: shapeZ, count: totalZ)],
    );

    // Question: Y = ? Z
    final answer = [Token(shape: shapeZ, count: ratioY)];

    final options = _generateOptions(
      correct: answer,
      baseShape: shapeZ,
      correctCount: ratioY,
      difficulty: 5,
      context: BalanceContext(
        questionType: QuestionType.findEquivalent,
        addend1: multiplierX * ratioX,
        addend2: totalZ,
      ),
    );

    return BalanceItem(
      balances: [balance1, balance2],
      question: BalanceQuestion(
        type: QuestionType.findEquivalent,
        targetSide: [Token(shape: shapeY, count: 1)],
      ),
      correctAnswer: answer,
      options: options..shuffle(_random),
      timeLimitSeconds: 45,
      thetaValue: theta,
    );
  }

  // ========== GÉNÉRATEURS DE DISTRACTEURS ==========

  /// Génère des distracteurs contextuels basés sur la difficulté et le contexte mathématique
  List<List<Token>> _generateContextualDistractors({
    required int correctCount,
    required TokenShape baseShape,
    required int difficulty,
    required BalanceContext context,
  }) {
    final distractors = <List<Token>>[];

    switch (difficulty) {
      case 1: // Niveau 1: comptage -1, comptage +1, additif
        distractors.add(_countingErrorMinus(correctCount, baseShape));
        distractors.add(_countingErrorPlus(correctCount, baseShape));
        distractors.add(_additiveError(context, baseShape));
        break;

      case 2: // Niveau 2: ratio direct, inversion, comptage
        distractors.add(_ratioDirectError(context, baseShape));
        distractors.add(_inversionError(correctCount, context, baseShape));
        distractors.add(_countingErrorPlus(correctCount, baseShape));
        break;

      case 3: // Niveau 3: ignorer terme 1, ignorer terme 2, comptage
        distractors.add(_termOmissionError(context, baseShape, first: true));
        distractors.add(_termOmissionError(context, baseShape, first: false));
        distractors.add(_countingErrorPlus(correctCount, baseShape));
        break;

      case 4: // Niveau 4: chaîne additive, substitution partielle, fraction
        distractors.add(_chainAdditiveError(context, baseShape));
        distractors.add(_partialSubstitutionError(context, baseShape));
        distractors.add(_fractionConfusionError(correctCount, context, baseShape));
        break;

      case 5: // Niveau 5: système partiel, circulaire, additif ratios
        distractors.add(_partialSystemError(context, baseShape));
        distractors.add(_circularOrderError(context, baseShape, correctCount));
        distractors.add(_ratioAdditiveError(context, baseShape));
        break;

      default:
        // Fallback vers distracteurs simples
        distractors.add([Token(shape: baseShape, count: max(1, correctCount - 1))]);
        distractors.add([Token(shape: baseShape, count: correctCount + 1)]);
        distractors.add([Token(shape: baseShape, count: correctCount + 2)]);
    }

    return distractors;
  }

  // ========== FONCTIONS D'AIDE POUR ERREURS COGNITIVES ==========

  // NIVEAU 1

  /// Erreur de comptage -1 : sous-estimation
  List<Token> _countingErrorMinus(int correctCount, TokenShape baseShape) {
    final errorCount = max(1, correctCount - 1);
    return [Token(shape: baseShape, count: errorCount)];
  }

  /// Erreur de comptage +1 : sur-estimation
  List<Token> _countingErrorPlus(int correctCount, TokenShape baseShape) {
    final errorCount = correctCount + 1;
    return [Token(shape: baseShape, count: errorCount)];
  }

  /// Erreur additive : ajouter au lieu de multiplier (raisonnement additif vs multiplicatif)
  List<Token> _additiveError(BalanceContext context, TokenShape baseShape) {
    if (context.ratio != null && context.multiplier != null) {
      // Exemple: ratio=2, multiplier=3 → 2+3=5 au lieu de 2×3=6
      final errorCount = context.ratio! + context.multiplier!;
      return [Token(shape: baseShape, count: errorCount)];
    }
    // Fallback
    return [Token(shape: baseShape, count: 2)];
  }

  // NIVEAU 2

  /// Erreur de ratio direct : utiliser le ratio sans le multiplier par le multiplicateur
  List<Token> _ratioDirectError(BalanceContext context, TokenShape baseShape) {
    if (context.ratio != null) {
      return [Token(shape: baseShape, count: context.ratio!)];
    }
    return [Token(shape: baseShape, count: 1)];
  }

  /// Erreur d'inversion : inverser les termes de la relation (confusion de ratio)
  List<Token> _inversionError(int correctCount, BalanceContext context, TokenShape baseShape) {
    if (context.ratio != null && correctCount > 1) {
      final inverted = max(1, correctCount ~/ context.ratio!);
      return [Token(shape: baseShape, count: inverted)];
    }
    return [Token(shape: baseShape, count: 1)];
  }

  // NIVEAU 3

  /// Erreur d'omission de terme : ignorer un des deux termes dans une somme/différence
  List<Token> _termOmissionError(BalanceContext context, TokenShape baseShape, {required bool first}) {
    if (first && context.addend1 != null) {
      return [Token(shape: baseShape, count: context.addend1!)];
    } else if (!first && context.addend2 != null) {
      return [Token(shape: baseShape, count: context.addend2!)];
    }
    return [Token(shape: baseShape, count: first ? 2 : 3)];
  }

  // NIVEAU 4

  /// Erreur de chaîne multiplicative : additionner les ratios au lieu de les multiplier
  List<Token> _chainAdditiveError(BalanceContext context, TokenShape baseShape) {
    if (context.chainRatios != null && context.chainRatios!.isNotEmpty) {
      final additive = context.chainRatios!.reduce((a, b) => a + b);
      return [Token(shape: baseShape, count: additive)];
    }
    return [Token(shape: baseShape, count: 5)];
  }

  /// Erreur de substitution partielle : ne calculer qu'une partie de la chaîne
  List<Token> _partialSubstitutionError(BalanceContext context, TokenShape baseShape) {
    if (context.chainRatios != null && context.chainRatios!.length >= 2) {
      // Multiplier seulement une partie de la chaîne
      final partial = context.chainRatios![0] * context.chainRatios![1];
      return [Token(shape: baseShape, count: partial)];
    }
    return [Token(shape: baseShape, count: 6)];
  }

  /// Erreur de fraction : mal comprendre les fractions (division/multiplication inversée)
  List<Token> _fractionConfusionError(int correctCount, BalanceContext context, TokenShape baseShape) {
    // Utiliser la moitié ou le double
    final confused = _random.nextBool()
      ? max(1, correctCount ~/ 2)
      : correctCount * 2;
    return [Token(shape: baseShape, count: confused)];
  }

  // NIVEAU 5

  /// Erreur de système partiel : résoudre seulement 1-2 étapes sur 3-4
  List<Token> _partialSystemError(BalanceContext context, TokenShape baseShape) {
    if (context.addend1 != null) {
      // Calculer seulement une partie du système
      final partial = max(1, context.addend1! ~/ 2);
      return [Token(shape: baseShape, count: partial)];
    }
    return [Token(shape: baseShape, count: 1)];
  }

  /// Erreur circulaire : confondre l'ordre des substitutions dans système circulaire
  List<Token> _circularOrderError(BalanceContext context, TokenShape baseShape, int correctCount) {
    if (context.addend1 != null && context.addend2 != null) {
      // Calculer partiellement ou inverser l'ordre
      final confused = max(1, (context.addend1! + context.addend2!) ~/ 2);
      return [Token(shape: baseShape, count: confused)];
    }
    return [Token(shape: baseShape, count: max(1, correctCount - 1))];
  }

  /// Erreur additive de ratios : additionner tous les ratios visibles au lieu de les combiner correctement
  List<Token> _ratioAdditiveError(BalanceContext context, TokenShape baseShape) {
    if (context.addend1 != null && context.addend2 != null) {
      // Additionner directement les coefficients
      final additive = context.addend1! + context.addend2!;
      return [Token(shape: baseShape, count: additive)];
    }
    return [Token(shape: baseShape, count: 5)];
  }

  // ========== GÉNÉRATEUR PRINCIPAL D'OPTIONS ==========

  /// Génère les options de réponse avec distracteurs intelligents basés sur erreurs cognitives
  List<List<Token>> _generateOptions({
    required List<Token> correct,
    required TokenShape baseShape,
    required int correctCount,
    required int difficulty,
    required BalanceContext context,
  }) {
    final options = <List<Token>>[];

    // Option correcte
    options.add(correct);

    // Générer 3 distracteurs basés sur le type d'erreur spécifique au niveau
    final distractors = _generateContextualDistractors(
      correctCount: correctCount,
      baseShape: baseShape,
      difficulty: difficulty,
      context: context,
    );

    // S'assurer que tous les distracteurs sont uniques (pas de duplications)
    final uniqueDistractors = _ensureUniqueOptions(correct, distractors);
    options.addAll(uniqueDistractors);

    return options; // 4 options total (1 correcte + 3 distracteurs)
  }
}

// ========== MODÈLES DE DONNÉES ==========

class BalanceItem {
  final List<Balance> balances;
  final BalanceQuestion question;
  final List<Token> correctAnswer;
  final List<List<Token>> options;
  final int timeLimitSeconds;
  final double thetaValue;

  BalanceItem({
    required this.balances,
    required this.question,
    required this.correctAnswer,
    required this.options,
    required this.timeLimitSeconds,
    required this.thetaValue,
  });
}

class Balance {
  final List<Token> leftSide;
  final List<Token> rightSide;

  Balance({
    required this.leftSide,
    required this.rightSide,
  });
}

class BalanceQuestion {
  final QuestionType type;
  final List<Token> targetSide;

  BalanceQuestion({
    required this.type,
    required this.targetSide,
  });
}

class Token {
  final TokenShape shape;
  final int count;
  final double? fraction;

  Token({
    required this.shape,
    this.count = 1,
    this.fraction,
  });

  @override
  bool operator ==(Object other) {
    if (other is! Token) return false;
    return shape == other.shape &&
        count == other.count &&
        fraction == other.fraction;
  }

  @override
  int get hashCode => Object.hash(shape, count, fraction);
}

enum TokenShape {
  circle,
  square,
  triangle,
  diamond,
  star,
  hexagon,
}

enum QuestionType {
  findEquivalent,
  findSum,
  findDifference,
}

/// Contexte mathématique pour générer des distracteurs intelligents
class BalanceContext {
  final QuestionType questionType;
  final int? ratio;              // Pour erreurs multiplicatives (ex: 2A = B, ratio=2)
  final int? multiplier;         // Pour erreurs de multiplication (ex: 4A = ?, multiplier=4)
  final int? addend1;            // Pour erreurs additives (ex: 2A+3B, addend1=2*ratioA)
  final int? addend2;            // addend2=3*ratioB
  final List<int>? chainRatios;  // Pour erreurs de chaîne (ex: [2, 3, 2] pour A=2B, B=3C, C=2D)

  BalanceContext({
    required this.questionType,
    this.ratio,
    this.multiplier,
    this.addend1,
    this.addend2,
    this.chainRatios,
  });
}
