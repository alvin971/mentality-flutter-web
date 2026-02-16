/// Générateur de 21 items UNIQUES de Similitudes (Similarities - WAIS-IV)
/// Tous les items créés en UNE SEULE FOIS au démarrage
/// Mesure l'abstraction conceptuelle et le raisonnement verbal
class SimilaritiesGenerator {
  final List<SimilarityItem> _preGeneratedItems = [];

  SimilaritiesGenerator() {
    _initializeAllItems();
  }

  /// Initialise TOUS les 21 items uniques dès la création du générateur
  void _initializeAllItems() {
    _preGeneratedItems.clear();

    // Items 1-4 : Niveau CONCRET (objets physiques tangibles)
    _preGeneratedItems.addAll(_createConcreteItems());

    // Items 5-10 : Niveau FONCTIONNEL (usage commun)
    _preGeneratedItems.addAll(_createFunctionalItems());

    // Items 11-16 : Niveau CATÉGORIEL (catégorie abstraite)
    _preGeneratedItems.addAll(_createCategoricalItems());

    // Items 17-21 : Niveau ABSTRAIT (concepts non tangibles)
    _preGeneratedItems.addAll(_createAbstractItems());
  }

  /// Retourne les 21 items pré-générés
  List<SimilarityItem> generateComplete21Items() {
    return List.from(_preGeneratedItems);
  }

  // ========== NIVEAU 1 : CONCRET (Items 1-4) ==========
  // Objets physiques tangibles à haute imageabilité
  List<SimilarityItem> _createConcreteItems() {
    return [
      // Item 1 : Fruits très communs
      SimilarityItem(
        word1: 'Orange',
        word2: 'Banane',
        level: AbstractionLevel.concrete,
        twoPointAnswers: [
          'Ce sont des fruits',
          'Des fruits',
          'Fruits',
          'Aliments naturels',
        ],
        onePointAnswers: [
          'On les mange',
          'Elles sont comestibles',
          'Elles sont sucrées',
          'Elles ont une peau',
          'Elles poussent sur des arbres',
          'Nourriture',
        ],
        thetaValue: -1.5,
      ),

      // Item 2 : Animaux familiers
      SimilarityItem(
        word1: 'Chien',
        word2: 'Chat',
        level: AbstractionLevel.concrete,
        twoPointAnswers: [
          'Ce sont des animaux',
          'Des animaux domestiques',
          'Animaux',
          'Mammifères',
          'Animaux de compagnie',
        ],
        onePointAnswers: [
          'Ils ont quatre pattes',
          'On les garde à la maison',
          'Ils ont de la fourrure',
          'Ce sont des compagnons',
          'Ils sont mignons',
        ],
        thetaValue: -1.3,
      ),

      // Item 3 : Objets vestimentaires
      SimilarityItem(
        word1: 'Chaussure',
        word2: 'Chapeau',
        level: AbstractionLevel.concrete,
        twoPointAnswers: [
          'Ce sont des vêtements',
          'Des habits',
          'Vêtements',
          'Articles vestimentaires',
          'Accessoires vestimentaires',
        ],
        onePointAnswers: [
          'On les porte',
          'Ils protègent',
          'On les met sur soi',
          'Ils nous couvrent',
        ],
        thetaValue: -1.1,
      ),

      // Item 4 : Meubles
      SimilarityItem(
        word1: 'Table',
        word2: 'Chaise',
        level: AbstractionLevel.concrete,
        twoPointAnswers: [
          'Ce sont des meubles',
          'Du mobilier',
          'Meubles',
          'Objets de maison',
        ],
        onePointAnswers: [
          'On les utilise pour manger',
          'Ils sont en bois',
          'On s\'assoit près d\'eux',
          'Ils sont dans la maison',
        ],
        thetaValue: -0.9,
      ),
    ];
  }

  // ========== NIVEAU 2 : FONCTIONNEL (Items 5-10) ==========
  // Identification d'usage commun
  List<SimilarityItem> _createFunctionalItems() {
    return [
      // Item 5 : Outils
      SimilarityItem(
        word1: 'Marteau',
        word2: 'Tournevis',
        level: AbstractionLevel.functional,
        twoPointAnswers: [
          'Ce sont des outils',
          'Outils',
          'Instruments de travail',
          'Équipement de bricolage',
        ],
        onePointAnswers: [
          'On les utilise pour réparer',
          'Ils servent à construire',
          'On les tient à la main',
          'Pour le bricolage',
        ],
        thetaValue: -0.7,
      ),

      // Item 6 : Instruments d'écriture
      SimilarityItem(
        word1: 'Crayon',
        word2: 'Stylo',
        level: AbstractionLevel.functional,
        twoPointAnswers: [
          'Ce sont des instruments d\'écriture',
          'Outils d\'écriture',
          'Fournitures scolaires',
          'Instruments pour écrire',
        ],
        onePointAnswers: [
          'On écrit avec',
          'Ils laissent une marque',
          'Pour dessiner',
          'Ils contiennent de l\'encre ou du graphite',
        ],
        thetaValue: -0.5,
      ),

      // Item 7 : Moyens de transport
      SimilarityItem(
        word1: 'Voiture',
        word2: 'Train',
        level: AbstractionLevel.functional,
        twoPointAnswers: [
          'Ce sont des moyens de transport',
          'Véhicules',
          'Transports',
          'Moyens de déplacement',
        ],
        onePointAnswers: [
          'Ils nous déplacent',
          'On voyage avec',
          'Ils ont des roues',
          'Pour aller d\'un endroit à un autre',
        ],
        thetaValue: -0.3,
      ),

      // Item 8 : Ustensiles de cuisine
      SimilarityItem(
        word1: 'Fourchette',
        word2: 'Cuillère',
        level: AbstractionLevel.functional,
        twoPointAnswers: [
          'Ce sont des couverts',
          'Ustensiles de cuisine',
          'Couverts',
          'Instruments pour manger',
        ],
        onePointAnswers: [
          'On mange avec',
          'Pour prendre la nourriture',
          'Ils sont en métal',
          'Sur la table',
        ],
        thetaValue: -0.1,
      ),

      // Item 9 : Instruments de mesure du temps
      SimilarityItem(
        word1: 'Montre',
        word2: 'Horloge',
        level: AbstractionLevel.functional,
        twoPointAnswers: [
          'Ce sont des instruments de mesure du temps',
          'Montres le temps',
          'Horloges',
          'Instruments horaires',
        ],
        onePointAnswers: [
          'Elles indiquent l\'heure',
          'Pour savoir le temps',
          'Elles ont des aiguilles',
          'Pour ne pas être en retard',
        ],
        thetaValue: 0.1,
      ),

      // Item 10 : Supports de communication
      SimilarityItem(
        word1: 'Téléphone',
        word2: 'Radio',
        level: AbstractionLevel.functional,
        twoPointAnswers: [
          'Ce sont des moyens de communication',
          'Appareils de communication',
          'Technologies de communication',
          'Moyens d\'information',
        ],
        onePointAnswers: [
          'On écoute avec',
          'Ils transmettent des sons',
          'Ils sont électroniques',
          'Pour recevoir des messages',
        ],
        thetaValue: 0.3,
      ),
    ];
  }

  // ========== NIVEAU 3 : CATÉGORIEL (Items 11-16) ==========
  // Catégorie abstraite, abstraction sémantique
  List<SimilarityItem> _createCategoricalItems() {
    return [
      // Item 11 : Œuvres d'art
      SimilarityItem(
        word1: 'Poème',
        word2: 'Statue',
        level: AbstractionLevel.categorical,
        twoPointAnswers: [
          'Ce sont des œuvres d\'art',
          'Formes d\'art',
          'Créations artistiques',
          'Art',
        ],
        onePointAnswers: [
          'On les admire',
          'Faites par des artistes',
          'Elles sont belles',
          'Pour exprimer quelque chose',
        ],
        thetaValue: 0.5,
      ),

      // Item 12 : Professions
      SimilarityItem(
        word1: 'Médecin',
        word2: 'Enseignant',
        level: AbstractionLevel.categorical,
        twoPointAnswers: [
          'Ce sont des professions',
          'Métiers',
          'Emplois',
          'Carrières professionnelles',
        ],
        onePointAnswers: [
          'Ils aident les gens',
          'Ils ont étudié',
          'Ce sont des services',
          'Ils travaillent avec les autres',
        ],
        thetaValue: 0.7,
      ),

      // Item 13 : Émotions
      SimilarityItem(
        word1: 'Joie',
        word2: 'Tristesse',
        level: AbstractionLevel.categorical,
        twoPointAnswers: [
          'Ce sont des émotions',
          'Sentiments',
          'États émotionnels',
          'Affects',
        ],
        onePointAnswers: [
          'On les ressent',
          'Ce sont des humeurs',
          'Elles changent',
          'Ce qu\'on éprouve',
        ],
        thetaValue: 0.9,
      ),

      // Item 14 : Sens biologiques
      SimilarityItem(
        word1: 'Vue',
        word2: 'Ouïe',
        level: AbstractionLevel.categorical,
        twoPointAnswers: [
          'Ce sont des sens',
          'Sens biologiques',
          'Capacités sensorielles',
          'Perceptions sensorielles',
        ],
        onePointAnswers: [
          'On perçoit avec',
          'Pour détecter le monde',
          'Ils nous informent',
          'Sens du corps',
        ],
        thetaValue: 1.1,
      ),

      // Item 15 : Sciences
      SimilarityItem(
        word1: 'Biologie',
        word2: 'Physique',
        level: AbstractionLevel.categorical,
        twoPointAnswers: [
          'Ce sont des sciences',
          'Disciplines scientifiques',
          'Domaines scientifiques',
          'Branches de la science',
        ],
        onePointAnswers: [
          'On les étudie',
          'Pour comprendre le monde',
          'Elles utilisent des expériences',
          'Matières scolaires',
        ],
        thetaValue: 1.3,
      ),

      // Item 16 : Structures gouvernementales
      SimilarityItem(
        word1: 'Démocratie',
        word2: 'Monarchie',
        level: AbstractionLevel.categorical,
        twoPointAnswers: [
          'Ce sont des systèmes politiques',
          'Formes de gouvernement',
          'Régimes politiques',
          'Systèmes de gouvernance',
        ],
        onePointAnswers: [
          'Façons de diriger un pays',
          'Ils organisent la société',
          'Systèmes de pouvoir',
          'Pour gouverner',
        ],
        thetaValue: 1.5,
      ),
    ];
  }

  // ========== NIVEAU 4 : ABSTRAIT (Items 17-21) ==========
  // Concepts non tangibles, raisonnement abstrait pur
  List<SimilarityItem> _createAbstractItems() {
    return [
      // Item 17 : Valeurs morales
      SimilarityItem(
        word1: 'Liberté',
        word2: 'Justice',
        level: AbstractionLevel.abstract,
        twoPointAnswers: [
          'Ce sont des valeurs',
          'Principes moraux',
          'Idéaux',
          'Valeurs démocratiques',
          'Droits fondamentaux',
        ],
        onePointAnswers: [
          'Importantes pour la société',
          'Ce qu\'on défend',
          'Principes',
          'Bonnes choses',
        ],
        thetaValue: 1.7,
      ),

      // Item 18 : Concepts intellectuels
      SimilarityItem(
        word1: 'Sagesse',
        word2: 'Intelligence',
        level: AbstractionLevel.abstract,
        twoPointAnswers: [
          'Ce sont des capacités intellectuelles',
          'Qualités mentales',
          'Aptitudes cognitives',
          'Facultés de l\'esprit',
        ],
        onePointAnswers: [
          'Elles aident à penser',
          'Pour résoudre des problèmes',
          'Qualités positives',
          'Ce qui rend intelligent',
        ],
        thetaValue: 1.9,
      ),

      // Item 19 : Concepts temporels
      SimilarityItem(
        word1: 'Passé',
        word2: 'Futur',
        level: AbstractionLevel.abstract,
        twoPointAnswers: [
          'Ce sont des périodes temporelles',
          'Dimensions du temps',
          'Époques',
          'Temps',
        ],
        onePointAnswers: [
          'Moments différents',
          'Parties du temps',
          'Ce qui était et ce qui sera',
          'Temps qui passe',
        ],
        thetaValue: 2.1,
      ),

      // Item 20 : Concepts philosophiques
      SimilarityItem(
        word1: 'Vérité',
        word2: 'Beauté',
        level: AbstractionLevel.abstract,
        twoPointAnswers: [
          'Ce sont des concepts philosophiques',
          'Idéaux abstraits',
          'Valeurs esthétiques et épistémiques',
          'Concepts universels',
        ],
        onePointAnswers: [
          'Choses qu\'on recherche',
          'Importantes pour l\'humanité',
          'Subjectives',
          'Qualités abstraites',
        ],
        thetaValue: 2.3,
      ),

      // Item 21 : Processus mentaux
      SimilarityItem(
        word1: 'Pensée',
        word2: 'Imagination',
        level: AbstractionLevel.abstract,
        twoPointAnswers: [
          'Ce sont des processus mentaux',
          'Fonctions cognitives',
          'Activités de l\'esprit',
          'Capacités intellectuelles',
        ],
        onePointAnswers: [
          'Elles se passent dans la tête',
          'Pour créer des idées',
          'Activités mentales',
          'Ce qu\'on fait avec notre cerveau',
        ],
        thetaValue: 2.5,
      ),
    ];
  }
}

// ========== MODÈLES DE DONNÉES ==========

class SimilarityItem {
  final String word1;
  final String word2;
  final AbstractionLevel level;
  final List<String> twoPointAnswers;
  final List<String> onePointAnswers;
  final double thetaValue;

  SimilarityItem({
    required this.word1,
    required this.word2,
    required this.level,
    required this.twoPointAnswers,
    required this.onePointAnswers,
    required this.thetaValue,
  });

  /// Évalue une réponse et retourne le score (0, 1, ou 2)
  int scoreAnswer(String answer) {
    final normalizedAnswer = answer.trim().toLowerCase();

    // Vérifier les réponses à 2 points
    for (final correctAnswer in twoPointAnswers) {
      if (_matchesAnswer(normalizedAnswer, correctAnswer.toLowerCase())) {
        return 2;
      }
    }

    // Vérifier les réponses à 1 point
    for (final partialAnswer in onePointAnswers) {
      if (_matchesAnswer(normalizedAnswer, partialAnswer.toLowerCase())) {
        return 1;
      }
    }

    // Aucune correspondance = 0 point
    return 0;
  }

  /// Vérifie si une réponse correspond (correspondance flexible)
  bool _matchesAnswer(String userAnswer, String expectedAnswer) {
    // Correspondance exacte
    if (userAnswer == expectedAnswer) return true;

    // Correspondance partielle (contient les mots clés)
    final userWords = userAnswer.split(' ');
    final expectedWords = expectedAnswer.split(' ');

    // Si l'utilisateur a utilisé au moins 70% des mots clés importants
    int matchCount = 0;
    for (final word in expectedWords) {
      if (word.length > 3 && userWords.any((w) => w.contains(word) || word.contains(w))) {
        matchCount++;
      }
    }

    return matchCount >= (expectedWords.length * 0.7);
  }

  String get levelName {
    switch (level) {
      case AbstractionLevel.concrete:
        return 'Concret';
      case AbstractionLevel.functional:
        return 'Fonctionnel';
      case AbstractionLevel.categorical:
        return 'Catégoriel';
      case AbstractionLevel.abstract:
        return 'Abstrait';
    }
  }
}

enum AbstractionLevel {
  concrete,    // Objets physiques tangibles
  functional,  // Usage commun
  categorical, // Catégorie abstraite
  abstract,    // Concepts non tangibles
}
