import 'information_items_en.dart';

/// Générateur de 28 items UNIQUES d'Information (Connaissances générales - WAIS-IV)
/// Tous les items créés en UNE SEULE FOIS au démarrage
/// Mesure les connaissances générales acquises à long terme
class InformationGenerator {
  final List<InformationItem> _preGeneratedItems = [];

  /// Langue de la banque d'items ('fr' par défaut, 'en' disponible).
  final String languageCode;

  InformationGenerator({this.languageCode = 'fr'}) {
    _initializeAllItems();
  }

  /// Initialise TOUS les 28 items uniques dès la création du générateur
  void _initializeAllItems() {
    _preGeneratedItems.clear();

    if (languageCode == 'en') {
      _preGeneratedItems.addAll(buildInformationItemsEn());
      return;
    }

    // Items 1-6 : Sciences naturelles
    _preGeneratedItems.addAll(_createScienceItems());

    // Items 7-13 : Histoire/Géographie
    _preGeneratedItems.addAll(_createHistoryGeographyItems());

    // Items 14-19 : Culture générale
    _preGeneratedItems.addAll(_createGeneralCultureItems());

    // Items 20-24 : Mathématiques/Logique
    _preGeneratedItems.addAll(_createMathLogicItems());

    // Items 25-28 : Arts/Littérature
    _preGeneratedItems.addAll(_createArtsLiteratureItems());
  }

  /// Retourne les 28 items pré-générés
  List<InformationItem> generateComplete28Items() {
    return List.from(_preGeneratedItems);
  }

  // ========== SCIENCES NATURELLES (6 items) ==========
  List<InformationItem> _createScienceItems() {
    return [
      // Item 1 : Facile
      InformationItem(
        question: 'Combien de pattes a une araignée ?',
        options: ['6', '8', '10', '12'],
        correctAnswer: 1, // Index de '8'
        domain: KnowledgeDomain.science,
        difficulty: DifficultyLevel.easy,
        thetaValue: -1.5,
      ),

      // Item 2 : Facile
      InformationItem(
        question: 'Quel organe pompe le sang dans le corps humain ?',
        options: ['Le foie', 'Le cœur', 'Les poumons', 'L\'estomac'],
        correctAnswer: 1,
        domain: KnowledgeDomain.science,
        difficulty: DifficultyLevel.easy,
        thetaValue: -1.2,
      ),

      // Item 3 : Moyen
      InformationItem(
        question: 'Combien d\'os compte le corps humain adulte ?',
        options: ['186', '206', '226', '246'],
        correctAnswer: 1,
        domain: KnowledgeDomain.science,
        difficulty: DifficultyLevel.medium,
        thetaValue: 0.5,
      ),

      // Item 4 : Moyen
      InformationItem(
        question: 'Quelle planète est la plus proche du Soleil ?',
        options: ['Vénus', 'Mars', 'Mercure', 'Terre'],
        correctAnswer: 2,
        domain: KnowledgeDomain.science,
        difficulty: DifficultyLevel.medium,
        thetaValue: 0.8,
      ),

      // Item 5 : Difficile
      InformationItem(
        question: 'Quel est le symbole chimique de l\'or ?',
        options: ['Au', 'Ag', 'Fe', 'Or'],
        correctAnswer: 0,
        domain: KnowledgeDomain.science,
        difficulty: DifficultyLevel.hard,
        thetaValue: 1.5,
      ),

      // Item 6 : Difficile
      InformationItem(
        question: 'Quelle est la vitesse de la lumière dans le vide ?',
        options: [
          '300 000 km/s',
          '150 000 km/s',
          '500 000 km/s',
          '200 000 km/s'
        ],
        correctAnswer: 0,
        domain: KnowledgeDomain.science,
        difficulty: DifficultyLevel.hard,
        thetaValue: 2.0,
      ),
    ];
  }

  // ========== HISTOIRE/GÉOGRAPHIE (7 items) ==========
  List<InformationItem> _createHistoryGeographyItems() {
    return [
      // Item 7 : Facile
      InformationItem(
        question: 'Quelle est la capitale de la France ?',
        options: ['Lyon', 'Marseille', 'Paris', 'Nice'],
        correctAnswer: 2,
        domain: KnowledgeDomain.historyGeography,
        difficulty: DifficultyLevel.easy,
        thetaValue: -1.8,
      ),

      // Item 8 : Facile
      InformationItem(
        question: 'Sur quel continent se trouve l\'Égypte ?',
        options: ['Asie', 'Afrique', 'Europe', 'Amérique'],
        correctAnswer: 1,
        domain: KnowledgeDomain.historyGeography,
        difficulty: DifficultyLevel.easy,
        thetaValue: -1.3,
      ),

      // Item 9 : Moyen
      InformationItem(
        question: 'Quelle est la capitale de l\'Italie ?',
        options: ['Milan', 'Rome', 'Naples', 'Florence'],
        correctAnswer: 1,
        domain: KnowledgeDomain.historyGeography,
        difficulty: DifficultyLevel.medium,
        thetaValue: -0.5,
      ),

      // Item 10 : Moyen
      InformationItem(
        question: 'En quelle année Christophe Colomb a-t-il découvert l\'Amérique ?',
        options: ['1492', '1500', '1482', '1520'],
        correctAnswer: 0,
        domain: KnowledgeDomain.historyGeography,
        difficulty: DifficultyLevel.medium,
        thetaValue: 0.3,
      ),

      // Item 11 : Moyen
      InformationItem(
        question: 'Quel océan sépare l\'Amérique de l\'Europe ?',
        options: [
          'Océan Pacifique',
          'Océan Indien',
          'Océan Atlantique',
          'Océan Arctique'
        ],
        correctAnswer: 2,
        domain: KnowledgeDomain.historyGeography,
        difficulty: DifficultyLevel.medium,
        thetaValue: 0.6,
      ),

      // Item 12 : Difficile
      InformationItem(
        question: 'Quelle est la capitale de l\'Australie ?',
        options: ['Sydney', 'Melbourne', 'Canberra', 'Brisbane'],
        correctAnswer: 2,
        domain: KnowledgeDomain.historyGeography,
        difficulty: DifficultyLevel.hard,
        thetaValue: 1.8,
      ),

      // Item 13 : Difficile
      InformationItem(
        question: 'Quel traité a mis fin à la Première Guerre mondiale ?',
        options: [
          'Traité de Paris',
          'Traité de Versailles',
          'Traité de Rome',
          'Traité de Genève'
        ],
        correctAnswer: 1,
        domain: KnowledgeDomain.historyGeography,
        difficulty: DifficultyLevel.hard,
        thetaValue: 2.2,
      ),
    ];
  }

  // ========== CULTURE GÉNÉRALE (6 items) ==========
  List<InformationItem> _createGeneralCultureItems() {
    return [
      // Item 14 : Facile
      InformationItem(
        question: 'Combien de jours compte une semaine ?',
        options: ['5', '6', '7', '8'],
        correctAnswer: 2,
        domain: KnowledgeDomain.generalCulture,
        difficulty: DifficultyLevel.easy,
        thetaValue: -2.0,
      ),

      // Item 15 : Facile
      InformationItem(
        question: 'Quelle couleur obtient-on en mélangeant le bleu et le jaune ?',
        options: ['Orange', 'Vert', 'Violet', 'Rouge'],
        correctAnswer: 1,
        domain: KnowledgeDomain.generalCulture,
        difficulty: DifficultyLevel.easy,
        thetaValue: -1.6,
      ),

      // Item 16 : Moyen
      InformationItem(
        question: 'Qui a peint la Joconde ?',
        options: [
          'Michel-Ange',
          'Léonard de Vinci',
          'Raphaël',
          'Vincent van Gogh'
        ],
        correctAnswer: 1,
        domain: KnowledgeDomain.generalCulture,
        difficulty: DifficultyLevel.medium,
        thetaValue: 0.0,
      ),

      // Item 17 : Moyen
      InformationItem(
        question: 'Quel instrument mesure la température ?',
        options: ['Baromètre', 'Thermomètre', 'Hygromètre', 'Anémomètre'],
        correctAnswer: 1,
        domain: KnowledgeDomain.generalCulture,
        difficulty: DifficultyLevel.medium,
        thetaValue: 0.4,
      ),

      // Item 18 : Difficile
      InformationItem(
        question: 'Quelle est la monnaie officielle du Japon ?',
        options: ['Yuan', 'Won', 'Yen', 'Baht'],
        correctAnswer: 2,
        domain: KnowledgeDomain.generalCulture,
        difficulty: DifficultyLevel.hard,
        thetaValue: 1.6,
      ),

      // Item 19 : Difficile
      InformationItem(
        question: 'Combien de cordes possède une guitare classique ?',
        options: ['4', '5', '6', '7'],
        correctAnswer: 2,
        domain: KnowledgeDomain.generalCulture,
        difficulty: DifficultyLevel.hard,
        thetaValue: 1.9,
      ),
    ];
  }

  // ========== MATHÉMATIQUES/LOGIQUE (5 items) ==========
  List<InformationItem> _createMathLogicItems() {
    return [
      // Item 20 : Facile
      InformationItem(
        question: 'Combien de jours compte une année normale (non bissextile) ?',
        options: ['364', '365', '366', '360'],
        correctAnswer: 1,
        domain: KnowledgeDomain.mathLogic,
        difficulty: DifficultyLevel.easy,
        thetaValue: -1.4,
      ),

      // Item 21 : Facile
      InformationItem(
        question: 'Combien font 12 × 12 ?',
        options: ['124', '134', '144', '154'],
        correctAnswer: 2,
        domain: KnowledgeDomain.mathLogic,
        difficulty: DifficultyLevel.easy,
        thetaValue: -0.8,
      ),

      // Item 22 : Moyen
      InformationItem(
        question: 'Combien de minutes y a-t-il dans 2 heures ?',
        options: ['100', '110', '120', '130'],
        correctAnswer: 2,
        domain: KnowledgeDomain.mathLogic,
        difficulty: DifficultyLevel.medium,
        thetaValue: 0.2,
      ),

      // Item 23 : Moyen
      InformationItem(
        question: 'Quelle est la valeur de π (pi) arrondie à deux décimales ?',
        options: ['3.12', '3.14', '3.16', '3.18'],
        correctAnswer: 1,
        domain: KnowledgeDomain.mathLogic,
        difficulty: DifficultyLevel.medium,
        thetaValue: 0.9,
      ),

      // Item 24 : Difficile
      InformationItem(
        question: 'Combien de degrés compte un angle droit ?',
        options: ['45°', '60°', '90°', '180°'],
        correctAnswer: 2,
        domain: KnowledgeDomain.mathLogic,
        difficulty: DifficultyLevel.hard,
        thetaValue: 1.3,
      ),
    ];
  }

  // ========== ARTS/LITTÉRATURE (4 items) ==========
  List<InformationItem> _createArtsLiteratureItems() {
    return [
      // Item 25 : Moyen
      InformationItem(
        question: 'Qui a écrit "Roméo et Juliette" ?',
        options: ['Molière', 'Shakespeare', 'Victor Hugo', 'Racine'],
        correctAnswer: 1,
        domain: KnowledgeDomain.artsLiterature,
        difficulty: DifficultyLevel.medium,
        thetaValue: 0.7,
      ),

      // Item 26 : Moyen
      InformationItem(
        question: 'Quel compositeur a écrit "La 9e Symphonie" ?',
        options: ['Mozart', 'Bach', 'Beethoven', 'Chopin'],
        correctAnswer: 2,
        domain: KnowledgeDomain.artsLiterature,
        difficulty: DifficultyLevel.medium,
        thetaValue: 1.1,
      ),

      // Item 27 : Difficile
      InformationItem(
        question: 'Qui a écrit "Hamlet" ?',
        options: ['Shakespeare', 'Molière', 'Cervantes', 'Goethe'],
        correctAnswer: 0,
        domain: KnowledgeDomain.artsLiterature,
        difficulty: DifficultyLevel.hard,
        thetaValue: 2.1,
      ),

      // Item 28 : Difficile
      InformationItem(
        question: 'Quel peintre est connu pour ses "Tournesols" ?',
        options: [
          'Claude Monet',
          'Pablo Picasso',
          'Vincent van Gogh',
          'Paul Cézanne'
        ],
        correctAnswer: 2,
        domain: KnowledgeDomain.artsLiterature,
        difficulty: DifficultyLevel.hard,
        thetaValue: 2.4,
      ),
    ];
  }
}

// ========== MODÈLES DE DONNÉES ==========

class InformationItem {
  final String question;
  final List<String> options;
  final int correctAnswer; // Index de la bonne réponse (0-3)
  final KnowledgeDomain domain;
  final DifficultyLevel difficulty;
  final double thetaValue;

  InformationItem({
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.domain,
    required this.difficulty,
    required this.thetaValue,
  });

  /// Vérifie si la réponse sélectionnée est correcte
  bool isCorrect(int selectedIndex) {
    return selectedIndex == correctAnswer;
  }

  String get domainName {
    switch (domain) {
      case KnowledgeDomain.science:
        return 'Sciences naturelles';
      case KnowledgeDomain.historyGeography:
        return 'Histoire/Géographie';
      case KnowledgeDomain.generalCulture:
        return 'Culture générale';
      case KnowledgeDomain.mathLogic:
        return 'Mathématiques/Logique';
      case KnowledgeDomain.artsLiterature:
        return 'Arts/Littérature';
    }
  }

  String get difficultyName {
    switch (difficulty) {
      case DifficultyLevel.easy:
        return 'Facile';
      case DifficultyLevel.medium:
        return 'Moyen';
      case DifficultyLevel.hard:
        return 'Difficile';
    }
  }
}

enum KnowledgeDomain {
  science,           // Sciences naturelles (6 items)
  historyGeography,  // Histoire/Géographie (7 items)
  generalCulture,    // Culture générale (6 items)
  mathLogic,         // Mathématiques/Logique (5 items)
  artsLiterature,    // Arts/Littérature (4 items)
}

enum DifficultyLevel {
  easy,
  medium,
  hard,
}
