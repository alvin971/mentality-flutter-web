import 'information_generator.dart';

/// Banque d'items ANGLAIS du test d'Information (WAIS-IV).
///
/// Psychométriquement équivalente à la banque FR : même nombre d'items (28),
/// mêmes domaines, mêmes difficultés et mêmes [thetaValue] par position.
/// Les questions franco-centrées de la banque FR ont été remplacées par des
/// équivalents de difficulté comparable pour un public anglophone international
/// (cf. items 13 et 16).
List<InformationItem> buildInformationItemsEn() {
  return [
    // ===== SCIENCES NATURELLES (6 items) =====
    // Item 1 : Facile
    InformationItem(
      question: 'How many legs does a spider have?',
      options: ['6', '8', '10', '12'],
      correctAnswer: 1,
      domain: KnowledgeDomain.science,
      difficulty: DifficultyLevel.easy,
      thetaValue: -1.5,
    ),

    // Item 2 : Facile
    InformationItem(
      question: 'Which organ pumps blood through the human body?',
      options: ['The liver', 'The heart', 'The lungs', 'The stomach'],
      correctAnswer: 1,
      domain: KnowledgeDomain.science,
      difficulty: DifficultyLevel.easy,
      thetaValue: -1.2,
    ),

    // Item 3 : Moyen
    InformationItem(
      question: 'How many bones does an adult human body have?',
      options: ['186', '206', '226', '246'],
      correctAnswer: 1,
      domain: KnowledgeDomain.science,
      difficulty: DifficultyLevel.medium,
      thetaValue: 0.5,
    ),

    // Item 4 : Moyen
    InformationItem(
      question: 'Which planet is closest to the Sun?',
      options: ['Venus', 'Mars', 'Mercury', 'Earth'],
      correctAnswer: 2,
      domain: KnowledgeDomain.science,
      difficulty: DifficultyLevel.medium,
      thetaValue: 0.8,
    ),

    // Item 5 : Difficile
    InformationItem(
      question: 'What is the chemical symbol for gold?',
      options: ['Au', 'Ag', 'Fe', 'Go'],
      correctAnswer: 0,
      domain: KnowledgeDomain.science,
      difficulty: DifficultyLevel.hard,
      thetaValue: 1.5,
    ),

    // Item 6 : Difficile
    InformationItem(
      question: 'What is the speed of light in a vacuum?',
      options: [
        '300,000 km/s',
        '150,000 km/s',
        '500,000 km/s',
        '200,000 km/s'
      ],
      correctAnswer: 0,
      domain: KnowledgeDomain.science,
      difficulty: DifficultyLevel.hard,
      thetaValue: 2.0,
    ),

    // ===== HISTOIRE/GÉOGRAPHIE (7 items) =====
    // Item 7 : Facile
    InformationItem(
      question: 'What is the capital of France?',
      options: ['Lyon', 'Marseille', 'Paris', 'Nice'],
      correctAnswer: 2,
      domain: KnowledgeDomain.historyGeography,
      difficulty: DifficultyLevel.easy,
      thetaValue: -1.8,
    ),

    // Item 8 : Facile
    InformationItem(
      question: 'On which continent is Egypt located?',
      options: ['Asia', 'Africa', 'Europe', 'America'],
      correctAnswer: 1,
      domain: KnowledgeDomain.historyGeography,
      difficulty: DifficultyLevel.easy,
      thetaValue: -1.3,
    ),

    // Item 9 : Moyen
    InformationItem(
      question: 'What is the capital of Italy?',
      options: ['Milan', 'Rome', 'Naples', 'Florence'],
      correctAnswer: 1,
      domain: KnowledgeDomain.historyGeography,
      difficulty: DifficultyLevel.medium,
      thetaValue: -0.5,
    ),

    // Item 10 : Moyen
    InformationItem(
      question: 'In which year did Christopher Columbus reach the Americas?',
      options: ['1492', '1500', '1482', '1520'],
      correctAnswer: 0,
      domain: KnowledgeDomain.historyGeography,
      difficulty: DifficultyLevel.medium,
      thetaValue: 0.3,
    ),

    // Item 11 : Moyen
    InformationItem(
      question: 'Which ocean separates America from Europe?',
      options: [
        'Pacific Ocean',
        'Indian Ocean',
        'Atlantic Ocean',
        'Arctic Ocean'
      ],
      correctAnswer: 2,
      domain: KnowledgeDomain.historyGeography,
      difficulty: DifficultyLevel.medium,
      thetaValue: 0.6,
    ),

    // Item 12 : Difficile
    InformationItem(
      question: 'What is the capital of Australia?',
      options: ['Sydney', 'Melbourne', 'Canberra', 'Brisbane'],
      correctAnswer: 2,
      domain: KnowledgeDomain.historyGeography,
      difficulty: DifficultyLevel.hard,
      thetaValue: 1.8,
    ),

    // Item 13 : Difficile
    // Remplace « Quel traité a mis fin à la Première Guerre mondiale ? » :
    // équivalent international de même difficulté (organisation mondiale).
    InformationItem(
      question:
          'In which city is the headquarters of the United Nations located?',
      options: ['Geneva', 'New York', 'Paris', 'Vienna'],
      correctAnswer: 1,
      domain: KnowledgeDomain.historyGeography,
      difficulty: DifficultyLevel.hard,
      thetaValue: 2.2,
    ),

    // ===== CULTURE GÉNÉRALE (6 items) =====
    // Item 14 : Facile
    InformationItem(
      question: 'How many days are there in a week?',
      options: ['5', '6', '7', '8'],
      correctAnswer: 2,
      domain: KnowledgeDomain.generalCulture,
      difficulty: DifficultyLevel.easy,
      thetaValue: -2.0,
    ),

    // Item 15 : Facile
    InformationItem(
      question: 'What color do you get when you mix blue and yellow?',
      options: ['Orange', 'Green', 'Purple', 'Red'],
      correctAnswer: 1,
      domain: KnowledgeDomain.generalCulture,
      difficulty: DifficultyLevel.easy,
      thetaValue: -1.6,
    ),

    // Item 16 : Moyen
    // Remplace « Qui a peint la Joconde ? » par une œuvre tout aussi
    // universellement connue d'un public anglophone (même difficulté).
    InformationItem(
      question: 'Who painted the Mona Lisa?',
      options: [
        'Michelangelo',
        'Leonardo da Vinci',
        'Raphael',
        'Vincent van Gogh'
      ],
      correctAnswer: 1,
      domain: KnowledgeDomain.generalCulture,
      difficulty: DifficultyLevel.medium,
      thetaValue: 0.0,
    ),

    // Item 17 : Moyen
    InformationItem(
      question: 'Which instrument measures temperature?',
      options: ['Barometer', 'Thermometer', 'Hygrometer', 'Anemometer'],
      correctAnswer: 1,
      domain: KnowledgeDomain.generalCulture,
      difficulty: DifficultyLevel.medium,
      thetaValue: 0.4,
    ),

    // Item 18 : Difficile
    InformationItem(
      question: 'What is the official currency of Japan?',
      options: ['Yuan', 'Won', 'Yen', 'Baht'],
      correctAnswer: 2,
      domain: KnowledgeDomain.generalCulture,
      difficulty: DifficultyLevel.hard,
      thetaValue: 1.6,
    ),

    // Item 19 : Difficile
    InformationItem(
      question: 'How many strings does a classical guitar have?',
      options: ['4', '5', '6', '7'],
      correctAnswer: 2,
      domain: KnowledgeDomain.generalCulture,
      difficulty: DifficultyLevel.hard,
      thetaValue: 1.9,
    ),

    // ===== MATHÉMATIQUES/LOGIQUE (5 items) =====
    // Item 20 : Facile
    InformationItem(
      question: 'How many days are there in a normal (non-leap) year?',
      options: ['364', '365', '366', '360'],
      correctAnswer: 1,
      domain: KnowledgeDomain.mathLogic,
      difficulty: DifficultyLevel.easy,
      thetaValue: -1.4,
    ),

    // Item 21 : Facile
    InformationItem(
      question: 'What is 12 × 12?',
      options: ['124', '134', '144', '154'],
      correctAnswer: 2,
      domain: KnowledgeDomain.mathLogic,
      difficulty: DifficultyLevel.easy,
      thetaValue: -0.8,
    ),

    // Item 22 : Moyen
    InformationItem(
      question: 'How many minutes are there in 2 hours?',
      options: ['100', '110', '120', '130'],
      correctAnswer: 2,
      domain: KnowledgeDomain.mathLogic,
      difficulty: DifficultyLevel.medium,
      thetaValue: 0.2,
    ),

    // Item 23 : Moyen
    InformationItem(
      question: 'What is the value of π (pi) rounded to two decimal places?',
      options: ['3.12', '3.14', '3.16', '3.18'],
      correctAnswer: 1,
      domain: KnowledgeDomain.mathLogic,
      difficulty: DifficultyLevel.medium,
      thetaValue: 0.9,
    ),

    // Item 24 : Difficile
    InformationItem(
      question: 'How many degrees are there in a right angle?',
      options: ['45°', '60°', '90°', '180°'],
      correctAnswer: 2,
      domain: KnowledgeDomain.mathLogic,
      difficulty: DifficultyLevel.hard,
      thetaValue: 1.3,
    ),

    // ===== ARTS/LITTÉRATURE (4 items) =====
    // Item 25 : Moyen
    InformationItem(
      question: 'Who wrote "Romeo and Juliet"?',
      options: ['Molière', 'Shakespeare', 'Victor Hugo', 'Racine'],
      correctAnswer: 1,
      domain: KnowledgeDomain.artsLiterature,
      difficulty: DifficultyLevel.medium,
      thetaValue: 0.7,
    ),

    // Item 26 : Moyen
    InformationItem(
      question: 'Which composer wrote the "9th Symphony"?',
      options: ['Mozart', 'Bach', 'Beethoven', 'Chopin'],
      correctAnswer: 2,
      domain: KnowledgeDomain.artsLiterature,
      difficulty: DifficultyLevel.medium,
      thetaValue: 1.1,
    ),

    // Item 27 : Difficile
    InformationItem(
      question: 'Who wrote "Hamlet"?',
      options: ['Shakespeare', 'Molière', 'Cervantes', 'Goethe'],
      correctAnswer: 0,
      domain: KnowledgeDomain.artsLiterature,
      difficulty: DifficultyLevel.hard,
      thetaValue: 2.1,
    ),

    // Item 28 : Difficile
    InformationItem(
      question: 'Which painter is famous for his "Sunflowers"?',
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
