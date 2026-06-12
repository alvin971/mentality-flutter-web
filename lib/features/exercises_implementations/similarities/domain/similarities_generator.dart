/// Générateur de 21 items UNIQUES de Similitudes (Similarities - WAIS-IV)
/// Tous les items créés en UNE SEULE FOIS au démarrage
/// Mesure l'abstraction conceptuelle et le raisonnement verbal
class SimilaritiesGenerator {
  final List<SimilarityItem> _preGeneratedItems = [];

  /// Langue de la banque d'items ('fr' par défaut, 'en' pour l'anglais).
  /// N'affecte QUE le contenu des items (paires + réponses acceptées) ;
  /// la structure, le scoring, les thetaValue et le nombre d'items restent
  /// strictement identiques entre les deux banques.
  final String languageCode;

  SimilaritiesGenerator({this.languageCode = 'fr'}) {
    _initializeAllItems();
  }

  bool get _isEn => languageCode == 'en';

  /// Initialise TOUS les 21 items uniques dès la création du générateur
  void _initializeAllItems() {
    _preGeneratedItems.clear();

    if (_isEn) {
      // Items 1-4 : Niveau CONCRET (objets physiques tangibles)
      _preGeneratedItems.addAll(_createConcreteItemsEn());
      // Items 5-10 : Niveau FONCTIONNEL (usage commun)
      _preGeneratedItems.addAll(_createFunctionalItemsEn());
      // Items 11-16 : Niveau CATÉGORIEL (catégorie abstraite)
      _preGeneratedItems.addAll(_createCategoricalItemsEn());
      // Items 17-21 : Niveau ABSTRAIT (concepts non tangibles)
      _preGeneratedItems.addAll(_createAbstractItemsEn());
      return;
    }

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

  // ============================================================
  // ============== BANQUE ANGLAISE (EN) ========================
  // Psychométriquement équivalente : même nombre d'items (21),
  // mêmes thetaValue/difficulté par position, mêmes niveaux.
  // ============================================================

  // ========== LEVEL 1: CONCRETE (Items 1-4) ==========
  List<SimilarityItem> _createConcreteItemsEn() {
    return [
      // Item 1: Very common fruits
      SimilarityItem(
        word1: 'Orange',
        word2: 'Banana',
        level: AbstractionLevel.concrete,
        twoPointAnswers: [
          'They are fruits',
          'Fruits',
          'They are food',
          'Natural foods',
        ],
        onePointAnswers: [
          'You eat them',
          'They are edible',
          'They are sweet',
          'They have a peel',
          'They grow on trees',
          'Food',
        ],
        thetaValue: -1.5,
      ),

      // Item 2: Familiar animals
      SimilarityItem(
        word1: 'Dog',
        word2: 'Cat',
        level: AbstractionLevel.concrete,
        twoPointAnswers: [
          'They are animals',
          'Domestic animals',
          'Animals',
          'Mammals',
          'Pets',
        ],
        onePointAnswers: [
          'They have four legs',
          'You keep them at home',
          'They have fur',
          'They are companions',
          'They are cute',
        ],
        thetaValue: -1.3,
      ),

      // Item 3: Clothing items
      SimilarityItem(
        word1: 'Shoe',
        word2: 'Hat',
        level: AbstractionLevel.concrete,
        twoPointAnswers: [
          'They are clothing',
          'They are clothes',
          'Clothing',
          'Garments',
          'Items of clothing',
        ],
        onePointAnswers: [
          'You wear them',
          'They protect you',
          'You put them on',
          'They cover you',
        ],
        thetaValue: -1.1,
      ),

      // Item 4: Furniture
      SimilarityItem(
        word1: 'Table',
        word2: 'Chair',
        level: AbstractionLevel.concrete,
        twoPointAnswers: [
          'They are furniture',
          'Furniture',
          'Pieces of furniture',
          'Household objects',
        ],
        onePointAnswers: [
          'You use them to eat',
          'They are made of wood',
          'You sit near them',
          'They are in the house',
        ],
        thetaValue: -0.9,
      ),
    ];
  }

  // ========== LEVEL 2: FUNCTIONAL (Items 5-10) ==========
  List<SimilarityItem> _createFunctionalItemsEn() {
    return [
      // Item 5: Tools
      SimilarityItem(
        word1: 'Hammer',
        word2: 'Screwdriver',
        level: AbstractionLevel.functional,
        twoPointAnswers: [
          'They are tools',
          'Tools',
          'Work instruments',
          'Hardware tools',
        ],
        onePointAnswers: [
          'You use them to repair',
          'They are used to build',
          'You hold them in your hand',
          'For DIY',
        ],
        thetaValue: -0.7,
      ),

      // Item 6: Writing instruments
      SimilarityItem(
        word1: 'Pencil',
        word2: 'Pen',
        level: AbstractionLevel.functional,
        twoPointAnswers: [
          'They are writing instruments',
          'Writing tools',
          'School supplies',
          'Instruments for writing',
        ],
        onePointAnswers: [
          'You write with them',
          'They leave a mark',
          'For drawing',
          'They contain ink or graphite',
        ],
        thetaValue: -0.5,
      ),

      // Item 7: Means of transport
      SimilarityItem(
        word1: 'Car',
        word2: 'Train',
        level: AbstractionLevel.functional,
        twoPointAnswers: [
          'They are means of transport',
          'Vehicles',
          'Transportation',
          'Ways of getting around',
        ],
        onePointAnswers: [
          'They move us around',
          'You travel with them',
          'They have wheels',
          'To go from one place to another',
        ],
        thetaValue: -0.3,
      ),

      // Item 8: Eating utensils
      SimilarityItem(
        word1: 'Fork',
        word2: 'Spoon',
        level: AbstractionLevel.functional,
        twoPointAnswers: [
          'They are cutlery',
          'Kitchen utensils',
          'Utensils',
          'Instruments for eating',
        ],
        onePointAnswers: [
          'You eat with them',
          'To pick up food',
          'They are made of metal',
          'On the table',
        ],
        thetaValue: -0.1,
      ),

      // Item 9: Timekeeping instruments
      SimilarityItem(
        word1: 'Watch',
        word2: 'Clock',
        level: AbstractionLevel.functional,
        twoPointAnswers: [
          'They are timekeeping instruments',
          'They measure time',
          'Timepieces',
          'Instruments for telling time',
        ],
        onePointAnswers: [
          'They show the time',
          'To know the time',
          'They have hands',
          'So you are not late',
        ],
        thetaValue: 0.1,
      ),

      // Item 10: Communication devices
      SimilarityItem(
        word1: 'Telephone',
        word2: 'Radio',
        level: AbstractionLevel.functional,
        twoPointAnswers: [
          'They are means of communication',
          'Communication devices',
          'Communication technologies',
          'Means of information',
        ],
        onePointAnswers: [
          'You listen with them',
          'They transmit sounds',
          'They are electronic',
          'To receive messages',
        ],
        thetaValue: 0.3,
      ),
    ];
  }

  // ========== LEVEL 3: CATEGORICAL (Items 11-16) ==========
  List<SimilarityItem> _createCategoricalItemsEn() {
    return [
      // Item 11: Works of art
      SimilarityItem(
        word1: 'Poem',
        word2: 'Statue',
        level: AbstractionLevel.categorical,
        twoPointAnswers: [
          'They are works of art',
          'Forms of art',
          'Artistic creations',
          'Art',
        ],
        onePointAnswers: [
          'You admire them',
          'Made by artists',
          'They are beautiful',
          'To express something',
        ],
        thetaValue: 0.5,
      ),

      // Item 12: Professions
      SimilarityItem(
        word1: 'Doctor',
        word2: 'Teacher',
        level: AbstractionLevel.categorical,
        twoPointAnswers: [
          'They are professions',
          'Occupations',
          'Jobs',
          'Careers',
        ],
        onePointAnswers: [
          'They help people',
          'They have studied',
          'They are services',
          'They work with others',
        ],
        thetaValue: 0.7,
      ),

      // Item 13: Emotions
      SimilarityItem(
        word1: 'Joy',
        word2: 'Sadness',
        level: AbstractionLevel.categorical,
        twoPointAnswers: [
          'They are emotions',
          'Feelings',
          'Emotional states',
          'Affects',
        ],
        onePointAnswers: [
          'You feel them',
          'They are moods',
          'They change',
          'What you experience',
        ],
        thetaValue: 0.9,
      ),

      // Item 14: Biological senses
      SimilarityItem(
        word1: 'Sight',
        word2: 'Hearing',
        level: AbstractionLevel.categorical,
        twoPointAnswers: [
          'They are senses',
          'Biological senses',
          'Sensory abilities',
          'Sensory perceptions',
        ],
        onePointAnswers: [
          'You perceive with them',
          'To detect the world',
          'They inform us',
          'Senses of the body',
        ],
        thetaValue: 1.1,
      ),

      // Item 15: Sciences
      SimilarityItem(
        word1: 'Biology',
        word2: 'Physics',
        level: AbstractionLevel.categorical,
        twoPointAnswers: [
          'They are sciences',
          'Scientific disciplines',
          'Scientific fields',
          'Branches of science',
        ],
        onePointAnswers: [
          'You study them',
          'To understand the world',
          'They use experiments',
          'School subjects',
        ],
        thetaValue: 1.3,
      ),

      // Item 16: Forms of government
      SimilarityItem(
        word1: 'Democracy',
        word2: 'Monarchy',
        level: AbstractionLevel.categorical,
        twoPointAnswers: [
          'They are political systems',
          'Forms of government',
          'Political regimes',
          'Systems of governance',
        ],
        onePointAnswers: [
          'Ways of running a country',
          'They organize society',
          'Systems of power',
          'To govern',
        ],
        thetaValue: 1.5,
      ),
    ];
  }

  // ========== LEVEL 4: ABSTRACT (Items 17-21) ==========
  List<SimilarityItem> _createAbstractItemsEn() {
    return [
      // Item 17: Moral values
      SimilarityItem(
        word1: 'Freedom',
        word2: 'Justice',
        level: AbstractionLevel.abstract,
        twoPointAnswers: [
          'They are values',
          'Moral principles',
          'Ideals',
          'Democratic values',
          'Fundamental rights',
        ],
        onePointAnswers: [
          'Important for society',
          'What we defend',
          'Principles',
          'Good things',
        ],
        thetaValue: 1.7,
      ),

      // Item 18: Intellectual concepts
      SimilarityItem(
        word1: 'Wisdom',
        word2: 'Intelligence',
        level: AbstractionLevel.abstract,
        twoPointAnswers: [
          'They are intellectual capacities',
          'Mental qualities',
          'Cognitive abilities',
          'Faculties of the mind',
        ],
        onePointAnswers: [
          'They help you think',
          'To solve problems',
          'Positive qualities',
          'What makes you smart',
        ],
        thetaValue: 1.9,
      ),

      // Item 19: Temporal concepts
      SimilarityItem(
        word1: 'Past',
        word2: 'Future',
        level: AbstractionLevel.abstract,
        twoPointAnswers: [
          'They are periods of time',
          'Dimensions of time',
          'Eras',
          'Time',
        ],
        onePointAnswers: [
          'Different moments',
          'Parts of time',
          'What was and what will be',
          'The passing of time',
        ],
        thetaValue: 2.1,
      ),

      // Item 20: Philosophical concepts
      SimilarityItem(
        word1: 'Truth',
        word2: 'Beauty',
        level: AbstractionLevel.abstract,
        twoPointAnswers: [
          'They are philosophical concepts',
          'Abstract ideals',
          'Aesthetic and epistemic values',
          'Universal concepts',
        ],
        onePointAnswers: [
          'Things we seek',
          'Important for humanity',
          'Subjective',
          'Abstract qualities',
        ],
        thetaValue: 2.3,
      ),

      // Item 21: Mental processes
      SimilarityItem(
        word1: 'Thought',
        word2: 'Imagination',
        level: AbstractionLevel.abstract,
        twoPointAnswers: [
          'They are mental processes',
          'Cognitive functions',
          'Activities of the mind',
          'Intellectual capacities',
        ],
        onePointAnswers: [
          'They happen in the head',
          'To create ideas',
          'Mental activities',
          'What we do with our brain',
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
