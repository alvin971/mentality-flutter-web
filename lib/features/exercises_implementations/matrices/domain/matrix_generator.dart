import 'dart:math';

/// Générateur de matrices progressives 100% ALÉATOIRES (comme test des cubes)
/// Chaque session génère 26 items complètement uniques
class MatrixGenerator {
  final Random _random;
  final List<MatrixItem> _preGeneratedItems = [];
  final Set<String> _generatedItemsSignatures = {};  // Suivi des exercices générés

  MatrixGenerator({int? seed}) : _random = Random(seed) {
    _initializeAllItems();
  }

  /// Initialise TOUS les 26 items uniques avec génération aléatoire
  void _initializeAllItems() {
    _preGeneratedItems.clear();
    _generatedItemsSignatures.clear();

    // Items 1-5 : Très facile (θ = -2.0 à -1.4)
    for (int i = 0; i < 5; i++) {
      _addUniqueItem(() => _generateVeryEasyItem(-2.0 + i * 0.15));
    }

    // Items 6-12 : Facile (θ = -0.8 à -0.2)
    for (int i = 0; i < 7; i++) {
      _addUniqueItem(() => _generateEasyItem(-0.8 + i * 0.1));
    }

    // Items 13-18 : Moyen (θ = 0.2 à 0.7)
    for (int i = 0; i < 6; i++) {
      _addUniqueItem(() => _generateMediumItem(0.2 + i * 0.1));
    }

    // Items 19-23 : Moyen-Difficile (θ = 1.2 à 1.7)
    for (int i = 0; i < 5; i++) {
      _addUniqueItem(() => _generateMediumHardItem(1.2 + i * 0.125));
    }

    // Items 24-26 : Difficile (θ = 2.2 à 2.8)
    for (int i = 0; i < 3; i++) {
      _addUniqueItem(() => _generateHardItem(2.2 + i * 0.3));
    }
  }

  /// Ajoute un item unique (régénère si duplicate détecté)
  void _addUniqueItem(MatrixItem Function() generator) {
    const maxAttempts = 50;  // Limite de tentatives
    var attempts = 0;
    MatrixItem? item;

    while (attempts < maxAttempts) {
      item = generator();
      final signature = _generateItemSignature(item.matrix, item.correctAnswer);

      if (!_generatedItemsSignatures.contains(signature)) {
        _generatedItemsSignatures.add(signature);
        _preGeneratedItems.add(item);
        return;
      }

      attempts++;
    }

    // Si on ne trouve pas d'item unique après maxAttempts, ajouter quand même
    // (cas très rare avec Random bien configuré)
    if (item != null) {
      _preGeneratedItems.add(item);
    }
  }

  /// Retourne les 26 items générés
  List<MatrixItem> generateComplete26Items() {
    return List.from(_preGeneratedItems);
  }

  // ========== HELPERS DE VALIDATION ==========

  /// Génère une signature unique pour un item de matrice
  String _generateItemSignature(List<List<MatrixCell?>> matrix, MatrixCell correct) {
    final buffer = StringBuffer();

    for (var row in matrix) {
      for (var cell in row) {
        if (cell == null) {
          buffer.write('NULL|');
        } else {
          buffer.write('${cell.shape.index}:${cell.size}:${cell.count}:${cell.color.index}:${cell.rotation.toStringAsFixed(0)}|');
        }
      }
    }

    buffer.write('ANS:${correct.shape.index}:${correct.size}:${correct.count}:${correct.color.index}:${correct.rotation.toStringAsFixed(0)}');

    return buffer.toString();
  }

  /// S'assure que toutes les options sont uniques (pas de duplications)
  List<MatrixCell> _ensureUniqueOptions(MatrixCell correct, List<MatrixCell> distractors) {
    final uniqueOptions = <MatrixCell>[correct];
    final maxAttempts = 20;  // Limite de tentatives pour éviter boucle infinie

    for (var distractor in distractors) {
      var currentDistractor = distractor;
      var attempts = 0;

      // Vérifier si le distracteur est unique
      while (_isDuplicate(currentDistractor, uniqueOptions) && attempts < maxAttempts) {
        // Générer une variation légère pour éviter le duplicate
        currentDistractor = _generateAlternativeDistractor(currentDistractor);
        attempts++;
      }

      if (attempts < maxAttempts) {
        uniqueOptions.add(currentDistractor);
      }
    }

    // S'assurer qu'on a exactement 4 options (1 correcte + 3 distracteurs)
    while (uniqueOptions.length < 4) {
      final newDistractor = _generateAlternativeDistractor(correct);
      if (!_isDuplicate(newDistractor, uniqueOptions)) {
        uniqueOptions.add(newDistractor);
      }
    }

    return uniqueOptions.sublist(1);  // Retourner seulement les 3 distracteurs
  }

  /// Vérifie si une option est un duplicate
  bool _isDuplicate(MatrixCell cell, List<MatrixCell> existingOptions) {
    for (var option in existingOptions) {
      if (cell == option) {
        return true;
      }
    }
    return false;
  }

  /// Génère un distracteur alternatif en modifiant légèrement les attributs
  MatrixCell _generateAlternativeDistractor(MatrixCell base) {
    final variations = [
      // Variation de taille
      MatrixCell(
        shape: base.shape,
        size: (base.size % 3) + 1,
        color: base.color,
        rotation: base.rotation,
        count: base.count,
      ),
      // Variation de forme
      MatrixCell(
        shape: _cycleShape(base.shape),
        size: base.size,
        color: base.color,
        rotation: base.rotation,
        count: base.count,
      ),
      // Variation de couleur
      MatrixCell(
        shape: base.shape,
        size: base.size,
        color: _cycleColor(base.color),
        rotation: base.rotation,
        count: base.count,
      ),
      // Variation de rotation
      MatrixCell(
        shape: base.shape,
        size: base.size,
        color: base.color,
        rotation: (base.rotation + 45) % 360,
        count: base.count,
      ),
    ];

    return variations[_random.nextInt(variations.length)];
  }

  // ========== GÉNÉRATEURS PAR NIVEAU ==========

  /// Niveau 1 (Très Facile): Grille 2×2, 1 règle (répétition), formes simples
  MatrixItem _generateVeryEasyItem(double theta) {
    final shapes = [MatrixShape.circle, MatrixShape.square, MatrixShape.triangle];
    final shape = shapes[_random.nextInt(shapes.length)];
    final size = _random.nextInt(3) + 1;
    final color = CellColor.black;

    final cell = MatrixCell(shape: shape, size: size, color: color);

    final matrix = [
      [cell, cell],
      [cell, null],
    ];

    // Forme alternative pour WP (alternance au lieu de constante)
    final alternateShape = shapes.firstWhere((s) => s != shape);

    final context = MatrixContext(
      rules: [MatrixRule.constantRow],
      matrix: matrix,
      correct: cell,
      alternateShape: alternateShape,
    );
    final distractors = _generateContextualDistractors(context);

    return MatrixItem(
      gridSize: 2,
      matrix: matrix,
      correctAnswer: cell,
      options: [cell, ...distractors]..shuffle(_random),
      rules: [MatrixRule.constantRow],
      difficulty: DifficultyLevel.veryEasy,
      thetaValue: theta,
    );
  }

  /// Niveau 2 (Facile): Grille 2×2, 1-2 règles, formes variées
  MatrixItem _generateEasyItem(double theta) {
    final ruleType = _random.nextInt(3);

    if (ruleType == 0) {
      // Progression de taille
      return _generateSizeProgressionItem(theta);
    } else if (ruleType == 1) {
      // Alternance de forme
      return _generateShapeAlternationItem(theta);
    } else {
      // Rotation
      return _generateSimpleRotationItem(theta);
    }
  }

  MatrixItem _generateSizeProgressionItem(double theta) {
    final shapes = [MatrixShape.circle, MatrixShape.square, MatrixShape.triangle];
    final shape = shapes[_random.nextInt(shapes.length)];

    final sizes = [1, 2, 2, 3];

    final matrix = [
      [MatrixCell(shape: shape, size: sizes[0]), MatrixCell(shape: shape, size: sizes[1])],
      [MatrixCell(shape: shape, size: sizes[2]), null],
    ];

    final answer = MatrixCell(shape: shape, size: sizes[3]);

    final context = MatrixContext(
      rules: [MatrixRule.quantitativeProgression],
      matrix: matrix,
      correct: answer,
      previousSize: sizes[2],  // Pour DIF (mauvaise progression)
    );
    final distractors = _generateContextualDistractors(context);

    return MatrixItem(
      gridSize: 2,
      matrix: matrix,
      correctAnswer: answer,
      options: [answer, ...distractors]..shuffle(_random),
      rules: [MatrixRule.quantitativeProgression],
      difficulty: DifficultyLevel.easy,
      thetaValue: theta,
    );
  }

  MatrixItem _generateShapeAlternationItem(double theta) {
    final shapes = [MatrixShape.circle, MatrixShape.square, MatrixShape.triangle];
    shapes.shuffle(_random);

    final shape1 = shapes[0];
    final shape2 = shapes[1];

    final matrix = [
      [MatrixCell(shape: shape1), MatrixCell(shape: shape2)],
      [MatrixCell(shape: shape1), null],
    ];

    final answer = MatrixCell(shape: shape2);

    final context = MatrixContext(
      rules: [MatrixRule.constantRow],
      matrix: matrix,
      correct: answer,
      alternateShape: shape1,  // Pour WP (forme non-alternée)
    );
    final distractors = _generateContextualDistractors(context);

    return MatrixItem(
      gridSize: 2,
      matrix: matrix,
      correctAnswer: answer,
      options: [answer, ...distractors]..shuffle(_random),
      rules: [MatrixRule.constantRow],
      difficulty: DifficultyLevel.easy,
      thetaValue: theta,
    );
  }

  MatrixItem _generateSimpleRotationItem(double theta) {
    final shape = MatrixShape.triangle;
    final rotations = [0.0, 90.0, 0.0, 90.0];

    final matrix = [
      [MatrixCell(shape: shape, rotation: rotations[0]), MatrixCell(shape: shape, rotation: rotations[1])],
      [MatrixCell(shape: shape, rotation: rotations[2]), null],
    ];

    final answer = MatrixCell(shape: shape, rotation: rotations[3]);

    final context = MatrixContext(
      rules: [MatrixRule.quantitativeProgression],
      matrix: matrix,
      correct: answer,
      previousRotation: rotations[2],  // Pour DIF (rotation inversée)
    );
    final distractors = _generateContextualDistractors(context);

    return MatrixItem(
      gridSize: 2,
      matrix: matrix,
      correctAnswer: answer,
      options: [answer, ...distractors]..shuffle(_random),
      rules: [MatrixRule.quantitativeProgression],
      difficulty: DifficultyLevel.easy,
      thetaValue: theta,
    );
  }

  /// Niveau 3 (Moyen): Grille 3×3, Distribution-3 + progression
  MatrixItem _generateMediumItem(double theta) {
    final allShapes = [MatrixShape.circle, MatrixShape.square, MatrixShape.triangle,
                       MatrixShape.diamond, MatrixShape.star, MatrixShape.hexagon];
    allShapes.shuffle(_random);
    final shapes = allShapes.take(3).toList();

    final sizes = [1, 2, 3];

    final matrix = List.generate(3, (row) {
      return List.generate(3, (col) {
        if (row == 2 && col == 2) return null;
        return MatrixCell(
          shape: shapes[col],
          size: sizes[row],
        );
      });
    });

    final answer = MatrixCell(shape: shapes[2], size: sizes[2]);

    final context = MatrixContext(
      rules: [MatrixRule.distribution3, MatrixRule.quantitativeProgression],
      matrix: matrix,
      correct: answer,
      alternateShape: shapes[0],  // Pour IC (mauvaise forme)
    );
    final distractors = _generateContextualDistractors(context);

    return MatrixItem(
      gridSize: 3,
      matrix: matrix,
      correctAnswer: answer,
      options: [answer, ...distractors]..shuffle(_random),
      rules: [MatrixRule.distribution3, MatrixRule.quantitativeProgression],
      difficulty: DifficultyLevel.medium,
      thetaValue: theta,
    );
  }

  /// Niveau 4 (Moyen-Difficile): Grille 3×3, 2-3 règles combinées
  MatrixItem _generateMediumHardItem(double theta) {
    final allShapes = [MatrixShape.circle, MatrixShape.square, MatrixShape.triangle,
                       MatrixShape.diamond, MatrixShape.star, MatrixShape.hexagon];
    allShapes.shuffle(_random);
    final shapes = allShapes.take(3).toList();

    final allColors = [CellColor.black, CellColor.white, CellColor.gray];
    allColors.shuffle(_random);

    final matrix = List.generate(3, (row) {
      return List.generate(3, (col) {
        if (row == 2 && col == 2) return null;
        return MatrixCell(
          shape: shapes[row],
          size: col + 1,
          color: allColors[(row + col) % 3],
        );
      });
    });

    final answer = MatrixCell(
      shape: shapes[2],
      size: 3,
      color: allColors[(2 + 2) % 3],
    );

    final context = MatrixContext(
      rules: [MatrixRule.distribution3, MatrixRule.quantitativeProgression, MatrixRule.additionSubtraction],
      matrix: matrix,
      correct: answer,
      alternateShape: shapes[0],  // Pour IC (mauvaise forme)
      alternateColor: allColors[0],  // Pour IC (mauvaise couleur)
    );
    final distractors = _generateContextualDistractors(context);

    return MatrixItem(
      gridSize: 3,
      matrix: matrix,
      correctAnswer: answer,
      options: [answer, ...distractors]..shuffle(_random),
      rules: [MatrixRule.distribution3, MatrixRule.quantitativeProgression, MatrixRule.additionSubtraction],
      difficulty: DifficultyLevel.mediumHard,
      thetaValue: theta,
    );
  }

  /// Niveau 5 (Difficile): Grille 3×3, Distribution-2 + transformations multiples
  MatrixItem _generateHardItem(double theta) {
    final allShapes = [MatrixShape.circle, MatrixShape.square, MatrixShape.triangle,
                       MatrixShape.diamond, MatrixShape.star, MatrixShape.hexagon];
    allShapes.shuffle(_random);
    final shapes = allShapes.take(3).toList();

    final allColors = [CellColor.black, CellColor.white, CellColor.gray];
    allColors.shuffle(_random);

    final variant = _random.nextInt(3);

    final matrix = List.generate(3, (row) {
      return List.generate(3, (col) {
        if (row == 2 && col == 2) return null;

        final shapeIndex = (row * 3 + col + variant) % 3;
        if (shapeIndex >= 2) {
          return MatrixCell.empty();
        }

        return MatrixCell(
          shape: shapes[shapeIndex],
          size: ((row + col) % 3) + 1,
          color: allColors[(row * col + variant) % 3],
          rotation: ((col + variant) * 45).toDouble(),
          count: ((row + col + variant) % 2) + 1,
        );
      });
    });

    final correctShapeIndex = (2 * 3 + 2 + variant) % 3;
    final MatrixCell answer;

    if (correctShapeIndex >= 2) {
      answer = MatrixCell.empty();
    } else {
      answer = MatrixCell(
        shape: shapes[correctShapeIndex],
        size: ((2 + 2) % 3) + 1,
        color: allColors[(2 * 2 + variant) % 3],
        rotation: ((2 + variant) * 45).toDouble(),
        count: ((2 + 2 + variant) % 2) + 1,
      );
    }

    final context = MatrixContext(
      rules: [MatrixRule.distribution2, MatrixRule.quantitativeProgression, MatrixRule.additionSubtraction],
      matrix: matrix,
      correct: answer,
      alternateShape: shapes[1],  // Pour IC
      alternateColor: allColors[1],  // Pour IC
      previousRotation: ((1 + variant) * 45).toDouble(),  // Pour DIF
    );
    final distractors = _generateContextualDistractors(context);

    return MatrixItem(
      gridSize: 3,
      matrix: matrix,
      correctAnswer: answer,
      options: [answer, ...distractors]..shuffle(_random),
      rules: [MatrixRule.distribution2, MatrixRule.quantitativeProgression, MatrixRule.additionSubtraction],
      difficulty: DifficultyLevel.hard,
      thetaValue: theta,
    );
  }

  // ========== GÉNÉRATEURS DE DISTRACTEURS ==========

  /// Génère des distracteurs contextuels basés sur erreurs cognitives documentées
  List<MatrixCell> _generateContextualDistractors(MatrixContext context) {
    final distractors = <MatrixCell>[];

    // Stratégie selon règles actives et niveau de difficulté
    if (context.rules.contains(MatrixRule.constantRow) && context.matrix.length == 2) {
      // Niveau 1: REP, WP, DIF
      distractors.add(_repetitionError(context));
      distractors.add(_wrongPrincipleAlternation(context));
      distractors.add(_differenceError(context));
    } else if (context.rules.contains(MatrixRule.quantitativeProgression) && context.matrix.length == 2) {
      // Niveau 2: WP, DIF, REP
      distractors.add(_wrongMagnitude(context));
      distractors.add(_reverseDifference(context));
      distractors.add(_repetitionError(context));
    } else if (context.rules.contains(MatrixRule.distribution3)) {
      // Niveau 3+: IC (prioritaire), IC, REP
      distractors.add(_incompleteCorrelate(context, ignoreAttribute: 'size'));
      distractors.add(_incompleteCorrelate(context, ignoreAttribute: 'shape'));
      distractors.add(_repetitionError(context));
    } else {
      // Fallback pour items complexes
      distractors.add(_incompleteCorrelate(context, ignoreAttribute: 'color'));
      distractors.add(_incompleteCorrelate(context, ignoreAttribute: 'size'));
      distractors.add(_wrongPrincipleError(context));
    }

    // S'assurer que tous les distracteurs sont uniques (pas de duplications)
    return _ensureUniqueOptions(context.correct, distractors);
  }

  // ========== ERREURS COGNITIVES ==========

  /// REPETITION (REP) - Copier un élément existant
  MatrixCell _repetitionError(MatrixContext context) {
    final matrix = context.matrix;
    final gridSize = matrix.length;

    // Copier cellule précédente logique (dernière ligne, avant-dernière colonne)
    final targetRow = gridSize - 1;
    final targetCol = gridSize - 2;

    if (targetRow >= 0 && targetCol >= 0 && matrix[targetRow][targetCol] != null) {
      return matrix[targetRow][targetCol]!;
    }

    // Fallback: copier première cellule
    return matrix[0][0] ?? context.correct;
  }

  /// INCOMPLETE CORRELATE (IC) - Satisfait 1 règle, ignore 1 autre
  MatrixCell _incompleteCorrelate(MatrixContext context, {required String ignoreAttribute}) {
    final correct = context.correct;

    switch (ignoreAttribute) {
      case 'size':
        // Bonne forme/couleur, mauvaise taille
        return MatrixCell(
          shape: correct.shape,
          size: (correct.size % 3) + 1,  // Cycle 1→2→3→1
          color: correct.color,
          rotation: correct.rotation,
          count: correct.count,
        );

      case 'shape':
        // Bonne taille/couleur, mauvaise forme
        return MatrixCell(
          shape: context.alternateShape ?? _cycleShape(correct.shape),
          size: correct.size,
          color: correct.color,
          rotation: correct.rotation,
          count: correct.count,
        );

      case 'color':
        // Bonne forme/taille, mauvaise couleur
        return MatrixCell(
          shape: correct.shape,
          size: correct.size,
          color: context.alternateColor ?? _cycleColor(correct.color),
          rotation: correct.rotation,
          count: correct.count,
        );

      case 'rotation':
        // Bonne forme/taille, mauvaise rotation
        return MatrixCell(
          shape: correct.shape,
          size: correct.size,
          color: correct.color,
          rotation: 0,  // Reset rotation
          count: correct.count,
        );

      default:
        return correct;
    }
  }

  /// WRONG PRINCIPLE (WP) - Alternance au lieu de constante
  MatrixCell _wrongPrincipleAlternation(MatrixContext context) {
    final correct = context.correct;

    // Si pattern = répétition constante, distracteur = alternance
    return MatrixCell(
      shape: context.alternateShape ?? _cycleShape(correct.shape),
      size: correct.size,
      color: correct.color,
      rotation: correct.rotation,
      count: correct.count,
    );
  }

  /// WRONG PRINCIPLE - Règle incorrecte générique
  MatrixCell _wrongPrincipleError(MatrixContext context) {
    final correct = context.correct;

    // Appliquer transformation inverse ou différente
    return MatrixCell(
      shape: correct.shape,
      size: correct.size,
      color: _cycleColor(correct.color),
      rotation: (correct.rotation + 180) % 360,  // Rotation opposée
      count: correct.count,
    );
  }

  /// DIFFERENCE (DIF) - Mauvaise magnitude de progression
  MatrixCell _wrongMagnitude(MatrixContext context) {
    final correct = context.correct;

    // Si progression correcte = +1, erreur = +2 ou 0
    final errorSize = _random.nextBool()
      ? ((correct.size + 1) % 4)  // +2 au lieu de +1
      : context.previousSize ?? 1;  // Répète précédent

    return MatrixCell(
      shape: correct.shape,
      size: errorSize,
      color: correct.color,
      rotation: correct.rotation,
      count: correct.count,
    );
  }

  /// DIFFERENCE (DIF) - Taille/comptage incorrect
  MatrixCell _differenceError(MatrixContext context) {
    final correct = context.correct;

    return MatrixCell(
      shape: correct.shape,
      size: (correct.size % 3) + 1,  // Cycle taille
      color: correct.color,
      rotation: correct.rotation,
      count: correct.count,
    );
  }

  /// DIFFERENCE (DIF) - Direction inversée (rotation)
  MatrixCell _reverseDifference(MatrixContext context) {
    final correct = context.correct;

    // Si rotation correcte = +90°, erreur = -90°
    final errorRotation = context.previousRotation != null
      ? ((context.previousRotation! - 90) % 360).toDouble()
      : 0.0;

    return MatrixCell(
      shape: correct.shape,
      size: correct.size,
      color: correct.color,
      rotation: errorRotation,
      count: correct.count,
    );
  }

  // ========== HELPERS ==========

  MatrixShape _cycleShape(MatrixShape current) {
    const shapes = MatrixShape.values;
    final index = shapes.indexOf(current);
    return shapes[(index + 1) % shapes.length];
  }

  CellColor _cycleColor(CellColor current) {
    const colors = CellColor.values;
    final index = colors.indexOf(current);
    return colors[(index + 1) % colors.length];
  }
}

/// Item de matrice progressive
class MatrixItem {
  final int gridSize;
  final List<List<MatrixCell?>> matrix;
  final MatrixCell correctAnswer;
  final List<MatrixCell> options;
  final List<MatrixRule> rules;
  final DifficultyLevel difficulty;
  final double thetaValue;

  MatrixItem({
    required this.gridSize,
    required this.matrix,
    required this.correctAnswer,
    required this.options,
    required this.rules,
    required this.difficulty,
    required this.thetaValue,
  });
}

/// Cellule de matrice
class MatrixCell {
  final MatrixShape shape;
  final int size;
  final int count;
  final CellColor color;
  final double rotation;

  MatrixCell({
    this.shape = MatrixShape.circle,
    this.size = 1,
    this.count = 1,
    this.color = CellColor.black,
    this.rotation = 0,
  });

  factory MatrixCell.empty() {
    return MatrixCell(size: 0, count: 0);
  }

  bool get isEmpty => count == 0 || size == 0;

  @override
  bool operator ==(Object other) {
    if (other is! MatrixCell) return false;
    return shape == other.shape &&
        size == other.size &&
        count == other.count &&
        color == other.color &&
        (rotation - other.rotation).abs() < 1;
  }

  @override
  int get hashCode => Object.hash(shape, size, count, color, rotation);
}

/// Formes géométriques
enum MatrixShape { circle, square, triangle, diamond, star, hexagon }

/// Couleurs de remplissage
enum CellColor { black, white, gray }

/// Règles selon Carpenter
enum MatrixRule {
  constantRow,
  quantitativeProgression,
  additionSubtraction,
  distribution3,
  distribution2,
}

/// Niveaux de difficulté IRT
enum DifficultyLevel {
  veryEasy,
  easy,
  medium,
  mediumHard,
  hard,
}

/// Contexte de génération pour distracteurs intelligents
class MatrixContext {
  final List<MatrixRule> rules;
  final List<List<MatrixCell?>> matrix;
  final MatrixCell correct;

  // Attributs pour génération ciblée d'erreurs
  final MatrixShape? alternateShape;  // Pour WP (alternance)
  final int? previousSize;            // Pour DIF (mauvaise progression)
  final CellColor? alternateColor;    // Pour IC (mauvaise couleur)
  final double? previousRotation;     // Pour DIF (mauvaise rotation)

  MatrixContext({
    required this.rules,
    required this.matrix,
    required this.correct,
    this.alternateShape,
    this.previousSize,
    this.alternateColor,
    this.previousRotation,
  });
}
