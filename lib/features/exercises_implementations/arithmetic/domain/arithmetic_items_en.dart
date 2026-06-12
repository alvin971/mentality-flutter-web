import 'arithmetic_generator.dart';

/// Banque d'items ANGLAIS du test d'Arithmétique (WAIS-IV).
///
/// Psychométriquement IDENTIQUE à la banque FR : mêmes nombres, mêmes
/// opérations, mêmes réponses correctes, mêmes limites de temps, mêmes bonus
/// et mêmes [thetaValue] par position. Seul l'habillage textuel (prénoms,
/// objets, devise) est traduit/adapté pour un public anglophone.
List<ArithmeticItem> buildArithmeticItemsEn() {
  return [
    // ===== NIVEAU FACILE : Addition/Soustraction simple (4 items) =====
    // Item 1
    ArithmeticItem(
      problem: 'If you have 3 apples and I add 2 more, how many do you have?',
      correctAnswer: 5,
      difficulty: DifficultyLevel.easy,
      timeLimitSeconds: 15,
      hasTimeBonus: false,
      thetaValue: -2.0,
    ),

    // Item 2
    ArithmeticItem(
      problem: 'What is 8 plus 7?',
      correctAnswer: 15,
      difficulty: DifficultyLevel.easy,
      timeLimitSeconds: 15,
      hasTimeBonus: false,
      thetaValue: -1.8,
    ),

    // Item 3
    ArithmeticItem(
      problem:
          'If you have 12 dollars and you spend 5 dollars, how much do you have left?',
      correctAnswer: 7,
      difficulty: DifficultyLevel.easy,
      timeLimitSeconds: 20,
      hasTimeBonus: false,
      thetaValue: -1.5,
    ),

    // Item 4
    ArithmeticItem(
      problem: 'What is 20 minus 8?',
      correctAnswer: 12,
      difficulty: DifficultyLevel.easy,
      timeLimitSeconds: 15,
      hasTimeBonus: false,
      thetaValue: -1.3,
    ),

    // ===== NIVEAU MOYEN : Multiplication/Division (8 items) =====
    // Item 5
    ArithmeticItem(
      problem: 'How much do 4 notebooks cost at 3 dollars each?',
      correctAnswer: 12,
      difficulty: DifficultyLevel.medium,
      timeLimitSeconds: 25,
      hasTimeBonus: false,
      thetaValue: -1.0,
    ),

    // Item 6
    ArithmeticItem(
      problem: 'What is 6 times 7?',
      correctAnswer: 42,
      difficulty: DifficultyLevel.medium,
      timeLimitSeconds: 20,
      hasTimeBonus: false,
      thetaValue: -0.8,
    ),

    // Item 7
    ArithmeticItem(
      problem:
          'If you divide 24 cookies equally among 6 children, how many does each child get?',
      correctAnswer: 4,
      difficulty: DifficultyLevel.medium,
      timeLimitSeconds: 25,
      hasTimeBonus: false,
      thetaValue: -0.5,
    ),

    // Item 8
    ArithmeticItem(
      problem: 'What is 9 times 8?',
      correctAnswer: 72,
      difficulty: DifficultyLevel.medium,
      timeLimitSeconds: 25,
      hasTimeBonus: false,
      thetaValue: -0.3,
    ),

    // Item 9
    ArithmeticItem(
      problem: 'A dozen eggs cost 6 dollars. How much do 2 dozen cost?',
      correctAnswer: 12,
      difficulty: DifficultyLevel.medium,
      timeLimitSeconds: 30,
      hasTimeBonus: false,
      thetaValue: 0.0,
    ),

    // Item 10
    ArithmeticItem(
      problem: 'What is 56 divided by 8?',
      correctAnswer: 7,
      difficulty: DifficultyLevel.medium,
      timeLimitSeconds: 25,
      hasTimeBonus: false,
      thetaValue: 0.2,
    ),

    // Item 11
    ArithmeticItem(
      problem:
          'If a book costs 15 dollars and you buy 3 of them, how much do you pay?',
      correctAnswer: 45,
      difficulty: DifficultyLevel.medium,
      timeLimitSeconds: 30,
      hasTimeBonus: false,
      thetaValue: 0.5,
    ),

    // Item 12
    ArithmeticItem(
      problem: 'What is 12 times 11?',
      correctAnswer: 132,
      difficulty: DifficultyLevel.medium,
      timeLimitSeconds: 30,
      hasTimeBonus: false,
      thetaValue: 0.8,
    ),

    // ===== NIVEAU DIFFICILE : Multi-étapes (6 items) =====
    // Item 13
    ArithmeticItem(
      problem: 'John has 24 dollars. He spends a third of it. How much does he have left?',
      correctAnswer: 16,
      difficulty: DifficultyLevel.hard,
      timeLimitSeconds: 40,
      hasTimeBonus: true,
      timeBonusThreshold: 25,
      thetaValue: 1.0,
    ),

    // Item 14
    ArithmeticItem(
      problem: 'If 3 pens cost 9 dollars, how much do 5 pens cost?',
      correctAnswer: 15,
      difficulty: DifficultyLevel.hard,
      timeLimitSeconds: 40,
      hasTimeBonus: true,
      timeBonusThreshold: 25,
      thetaValue: 1.2,
    ),

    // Item 15
    ArithmeticItem(
      problem:
          'Mary buys 4 books at 12 dollars each. She pays with a 100-dollar bill. How much change does she receive?',
      correctAnswer: 52,
      difficulty: DifficultyLevel.hard,
      timeLimitSeconds: 45,
      hasTimeBonus: true,
      timeBonusThreshold: 30,
      thetaValue: 1.4,
    ),

    // Item 16
    ArithmeticItem(
      problem:
          'A train travels 120 kilometers in 2 hours. What is its average speed in kilometers per hour?',
      correctAnswer: 60,
      difficulty: DifficultyLevel.hard,
      timeLimitSeconds: 40,
      hasTimeBonus: true,
      timeBonusThreshold: 25,
      thetaValue: 1.6,
    ),

    // Item 17
    ArithmeticItem(
      problem:
          'Sophie has 48 candies. She gives half to her brother, then eats a quarter of what remains. How many does she have left?',
      correctAnswer: 18,
      difficulty: DifficultyLevel.hard,
      timeLimitSeconds: 50,
      hasTimeBonus: true,
      timeBonusThreshold: 35,
      thetaValue: 1.8,
    ),

    // Item 18
    ArithmeticItem(
      problem:
          'A rectangle is 8 meters long and 5 meters wide. What is its area in square meters?',
      correctAnswer: 40,
      difficulty: DifficultyLevel.hard,
      timeLimitSeconds: 35,
      hasTimeBonus: true,
      timeBonusThreshold: 20,
      thetaValue: 2.0,
    ),

    // ===== NIVEAU TRÈS DIFFICILE : Proportions/Pourcentages (4 items) =====
    // Item 19
    ArithmeticItem(
      problem: 'What is 10 percent of 50?',
      correctAnswer: 5,
      difficulty: DifficultyLevel.veryHard,
      timeLimitSeconds: 45,
      hasTimeBonus: true,
      timeBonusThreshold: 30,
      thetaValue: 2.2,
    ),

    // Item 20
    ArithmeticItem(
      problem: 'What is 25 percent of 80?',
      correctAnswer: 20,
      difficulty: DifficultyLevel.veryHard,
      timeLimitSeconds: 50,
      hasTimeBonus: true,
      timeBonusThreshold: 35,
      thetaValue: 2.4,
    ),

    // Item 21
    ArithmeticItem(
      problem:
          'An item costs 60 dollars. Its price increases by 20 percent. What is its new price?',
      correctAnswer: 72,
      difficulty: DifficultyLevel.veryHard,
      timeLimitSeconds: 60,
      hasTimeBonus: true,
      timeBonusThreshold: 40,
      thetaValue: 2.6,
    ),

    // Item 22
    ArithmeticItem(
      problem:
          'If 5 workers build a wall in 12 days, how many days would it take 3 workers to build the same wall?',
      correctAnswer: 20,
      difficulty: DifficultyLevel.veryHard,
      timeLimitSeconds: 60,
      hasTimeBonus: true,
      timeBonusThreshold: 45,
      thetaValue: 2.8,
    ),
  ];
}
