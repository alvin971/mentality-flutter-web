/// ENGLISH item bank for the Vocabulary subtest (Vocabulary - WAIS-IV).
/// 30 unique items, psychometrically equivalent to the French bank:
/// item i shares the SAME WordFrequency and the SAME thetaValue as FR item i,
/// so the difficulty / lexical-frequency curve is identical across languages.
/// Words are genuine English frequency equivalents (not literal translations
/// when the literal translation would shift frequency band).
import 'vocabulary_generator.dart';

/// Returns the 30 English items in ascending difficulty order.
List<VocabularyItem> buildEnglishVocabularyItems() {
  return [
    // ========== LEVEL 1: VERY EASY (Items 1-5) ==========
    // Top 1000 - very frequent words, concrete objects

    // Item 1: very familiar object
    VocabularyItem(
      word: 'Table',
      frequency: WordFrequency.veryHigh,
      twoPointAnswers: [
        'A piece of furniture with a flat horizontal top',
        'A flat surface on legs used to eat or work at',
        'Furniture with a top supported by legs',
        'A flat surface you put things on',
      ],
      onePointAnswers: [
        'Furniture',
        'To eat on',
        'You eat on it',
        'It is flat',
        'It has four legs',
      ],
      thetaValue: -2.0,
    ),

    // Item 2: familiar animal
    VocabularyItem(
      word: 'Cat',
      frequency: WordFrequency.veryHigh,
      twoPointAnswers: [
        'A small domestic feline animal',
        'A small pet mammal that meows',
        'A domesticated feline',
        'A furry pet that purrs and meows',
      ],
      onePointAnswers: [
        'An animal',
        'A pet',
        'It meows',
        'It has fur',
        'An animal with whiskers',
      ],
      thetaValue: -1.8,
    ),

    // Item 3: everyday object
    VocabularyItem(
      word: 'Book',
      frequency: WordFrequency.veryHigh,
      twoPointAnswers: [
        'A set of printed pages bound together that you read',
        'A bound printed work',
        'A collection of pages put together for reading',
        'A bound publication containing text',
      ],
      onePointAnswers: [
        'For reading',
        'It has pages',
        'You read it',
        'An object with text',
      ],
      thetaValue: -1.6,
    ),

    // Item 4: common quality
    VocabularyItem(
      word: 'Fast',
      frequency: WordFrequency.veryHigh,
      twoPointAnswers: [
        'Moving at high speed',
        'Able to move very quickly',
        'Doing something in very little time',
        'Having great speed',
      ],
      onePointAnswers: [
        'Quick',
        'Not slow',
        'Speedy',
        'Takes little time',
      ],
      thetaValue: -1.4,
    ),

    // Item 5: simple emotion
    VocabularyItem(
      word: 'Happy',
      frequency: WordFrequency.veryHigh,
      twoPointAnswers: [
        'Feeling joy or pleasure',
        'Pleased and content',
        'Experiencing a feeling of happiness',
        'In a state of contentment',
      ],
      onePointAnswers: [
        'Glad',
        'Joyful',
        'Smiling',
        'Not sad',
      ],
      thetaValue: -1.2,
    ),

    // ========== LEVEL 2: EASY (Items 6-12) ==========
    // Top 5000 - common objects and familiar concepts

    // Item 6
    VocabularyItem(
      word: 'Desk',
      frequency: WordFrequency.high,
      twoPointAnswers: [
        'A piece of furniture you work and write at',
        'A work table with drawers',
        'Furniture used for working',
        'A workstation with a surface and storage',
      ],
      onePointAnswers: [
        'Furniture',
        'A table',
        'For working',
        'Where you write',
      ],
      thetaValue: -1.0,
    ),

    // Item 7
    VocabularyItem(
      word: 'Brave',
      frequency: WordFrequency.high,
      twoPointAnswers: [
        'Not afraid of danger',
        'Showing courage in the face of difficulty',
        'Willing to face danger without fear',
        'Acting with courage',
      ],
      onePointAnswers: [
        'Courageous',
        'Not scared',
        'Strong',
        'Has no fear',
      ],
      thetaValue: -0.8,
    ),

    // Item 8
    VocabularyItem(
      word: 'Hesitate',
      frequency: WordFrequency.high,
      twoPointAnswers: [
        'To be unsure before making a choice',
        'To pause because you cannot decide',
        'To show uncertainty before acting',
        'To waver before deciding',
      ],
      onePointAnswers: [
        'To be unsure',
        'To doubt',
        'Not decided',
        'To wait before choosing',
      ],
      thetaValue: -0.6,
    ),

    // Item 9
    VocabularyItem(
      word: 'Fragile',
      frequency: WordFrequency.high,
      twoPointAnswers: [
        'Easily broken',
        'Lacking strength or solidity',
        'Delicate and easily damaged',
        'Likely to break if handled roughly',
      ],
      onePointAnswers: [
        'Breakable',
        'Not solid',
        'Delicate',
        'Weak',
      ],
      thetaValue: -0.4,
    ),

    // Item 10
    VocabularyItem(
      word: 'Huge',
      frequency: WordFrequency.high,
      twoPointAnswers: [
        'Extremely large',
        'Of very great size',
        'Enormous',
        'Of exceptional dimensions',
      ],
      onePointAnswers: [
        'Very big',
        'Large',
        'Gigantic',
        'Not small',
      ],
      thetaValue: -0.2,
    ),

    // Item 11
    VocabularyItem(
      word: 'Generous',
      frequency: WordFrequency.high,
      twoPointAnswers: [
        'Willing to give freely',
        'Glad to share and give to others',
        'Showing generosity',
        'Giving a lot to others',
      ],
      onePointAnswers: [
        'Giving',
        'Kind',
        'Sharing',
        'Good-hearted',
      ],
      thetaValue: 0.0,
    ),

    // Item 12
    VocabularyItem(
      word: 'Obstacle',
      frequency: WordFrequency.high,
      twoPointAnswers: [
        'Something that prevents progress',
        'A difficulty that blocks the way',
        'A thing that gets in the way of advancing',
        'A barrier that hinders movement',
      ],
      onePointAnswers: [
        'Something that blocks',
        'A problem',
        'A difficulty',
        'A barrier',
      ],
      thetaValue: 0.2,
    ),

    // ========== LEVEL 3: MEDIUM (Items 13-20) ==========
    // Top 10,000 - abstract concepts and broader vocabulary

    // Item 13
    VocabularyItem(
      word: 'Transparent',
      frequency: WordFrequency.medium,
      twoPointAnswers: [
        'Allowing light to pass through',
        'Able to be seen through',
        'Not opaque',
        'Clear so that you can see through it',
      ],
      onePointAnswers: [
        'You can see through it',
        'Clear',
        'Like glass',
        'Not opaque',
      ],
      thetaValue: 0.4,
    ),

    // Item 14
    VocabularyItem(
      word: 'Concept',
      frequency: WordFrequency.medium,
      twoPointAnswers: [
        'An abstract and general idea',
        'An abstract mental representation',
        'A theoretical notion',
        'A general idea of something',
      ],
      onePointAnswers: [
        'An idea',
        'A thought',
        'A notion',
        'Something abstract',
      ],
      thetaValue: 0.6,
    ),

    // Item 15
    VocabularyItem(
      word: 'Absurd',
      frequency: WordFrequency.medium,
      twoPointAnswers: [
        'Contrary to reason and common sense',
        'Unreasonable and illogical',
        'Having no logical sense',
        'Irrational and senseless',
      ],
      onePointAnswers: [
        'Foolish',
        'Silly',
        'Not logical',
        'Makes no sense',
      ],
      thetaValue: 0.8,
    ),

    // Item 16
    VocabularyItem(
      word: 'Ethical',
      frequency: WordFrequency.medium,
      twoPointAnswers: [
        'Relating to moral principles',
        'Concerned with morality and values',
        'In keeping with rules of moral conduct',
        'Guided by principles of right and wrong',
      ],
      onePointAnswers: [
        'Moral',
        'About values',
        'About right and wrong',
        'Rules of conduct',
      ],
      thetaValue: 1.0,
    ),

    // Item 17
    VocabularyItem(
      word: 'Concise',
      frequency: WordFrequency.medium,
      twoPointAnswers: [
        'Brief and to the point',
        'Expressed in few words',
        'Short and precise',
        'Succinct',
      ],
      onePointAnswers: [
        'Short',
        'Brief',
        'Not long',
        'Summed up',
      ],
      thetaValue: 1.2,
    ),

    // Item 18
    VocabularyItem(
      word: 'Nuance',
      frequency: WordFrequency.medium,
      twoPointAnswers: [
        'A subtle difference between two things',
        'A slight variation in meaning or tone',
        'A fine and delicate distinction',
        'A small, barely noticeable difference',
      ],
      onePointAnswers: [
        'A difference',
        'A variation',
        'A shade',
        'A small change',
      ],
      thetaValue: 1.4,
    ),

    // Item 19
    VocabularyItem(
      word: 'Dilemma',
      frequency: WordFrequency.medium,
      twoPointAnswers: [
        'A difficult choice between two options',
        'A situation requiring a choice between alternatives',
        'A hard decision between two undesirable options',
        'Having to choose between two solutions',
      ],
      onePointAnswers: [
        'A problem',
        'A hard choice',
        'A decision to make',
        'A tough situation',
      ],
      thetaValue: 1.6,
    ),

    // Item 20
    VocabularyItem(
      word: 'Perceptive',
      frequency: WordFrequency.medium,
      twoPointAnswers: [
        'Quick to understand things keenly',
        'Having sharp insight and awareness',
        'Able to notice and grasp things clearly',
        'Showing keen mental penetration',
      ],
      onePointAnswers: [
        'Smart',
        'Quick to understand',
        'Sharp',
        'Insightful',
      ],
      thetaValue: 1.8,
    ),

    // ========== LEVEL 4: DIFFICULT (Items 21-27) ==========
    // Top 20,000 - rich and sophisticated vocabulary

    // Item 21
    VocabularyItem(
      word: 'Ambivalent',
      frequency: WordFrequency.low,
      twoPointAnswers: [
        'Having contradictory feelings about something',
        'Holding two opposing attitudes at once',
        'Marked by a duality of feelings',
        'Feeling both positive and negative at the same time',
      ],
      onePointAnswers: [
        'Contradictory',
        'Torn',
        'Unsure',
        'Of two minds',
      ],
      thetaValue: 2.0,
    ),

    // Item 22
    VocabularyItem(
      word: 'Pragmatic',
      frequency: WordFrequency.low,
      twoPointAnswers: [
        'Oriented toward practical action',
        'Focused on what works in practice',
        'Dealing with things realistically and practically',
        'Practical rather than idealistic',
      ],
      onePointAnswers: [
        'Practical',
        'Realistic',
        'Down to earth',
        'Concrete',
      ],
      thetaValue: 2.2,
    ),

    // Item 23
    VocabularyItem(
      word: 'Eloquent',
      frequency: WordFrequency.low,
      twoPointAnswers: [
        'Speaking fluently and persuasively',
        'Expressing oneself in a convincing way',
        'Skilled in the art of speaking well',
        'Fluent and expressive in speech',
      ],
      onePointAnswers: [
        'Speaks well',
        'A good speaker',
        'Persuasive',
        'Well-spoken',
      ],
      thetaValue: 2.4,
    ),

    // Item 24
    VocabularyItem(
      word: 'Meticulous',
      frequency: WordFrequency.low,
      twoPointAnswers: [
        'Paying careful attention to the smallest details',
        'Extremely careful and precise',
        'Showing great thoroughness and care',
        'Scrupulous and exact in every detail',
      ],
      onePointAnswers: [
        'Precise',
        'Careful',
        'Thorough',
        'A perfectionist',
      ],
      thetaValue: 2.6,
    ),

    // Item 25
    VocabularyItem(
      word: 'Dogmatic',
      frequency: WordFrequency.low,
      twoPointAnswers: [
        'Asserting opinions as if they were certain truths',
        'Insisting on beliefs without allowing contradiction',
        'Authoritarian about one\'s convictions',
        'Presenting ideas as absolute and beyond question',
      ],
      onePointAnswers: [
        'Stubborn',
        'Rigid',
        'Inflexible',
        'Authoritarian',
      ],
      thetaValue: 2.8,
    ),

    // Item 26
    VocabularyItem(
      word: 'Paradox',
      frequency: WordFrequency.low,
      twoPointAnswers: [
        'An apparent contradiction that may still be true',
        'A statement contrary to common opinion',
        'A seemingly contradictory proposition',
        'A statement that seems absurd yet may be true',
      ],
      onePointAnswers: [
        'A contradiction',
        'A contrary idea',
        'An opposite',
        'Something strange',
      ],
      thetaValue: 3.0,
    ),

    // Item 27
    VocabularyItem(
      word: 'Resilience',
      frequency: WordFrequency.low,
      twoPointAnswers: [
        'The capacity to recover from hardship',
        'The ability to bounce back after a setback',
        'The ability to withstand and adapt to adversity',
        'Strength to recover quickly from difficulties',
      ],
      onePointAnswers: [
        'Strength',
        'Toughness',
        'Recovery',
        'Bouncing back',
      ],
      thetaValue: 3.2,
    ),

    // ========== LEVEL 5: VERY DIFFICULT (Items 28-30) ==========
    // >20,000 - rare and highly specialized vocabulary

    // Item 28
    VocabularyItem(
      word: 'Ubiquitous',
      frequency: WordFrequency.veryLow,
      twoPointAnswers: [
        'Present everywhere at the same time',
        'Found in all places',
        'Existing or being everywhere at once',
        'Constantly encountered; omnipresent',
      ],
      onePointAnswers: [
        'Everywhere',
        'Present everywhere',
        'Common',
        'Widespread',
      ],
      thetaValue: 3.4,
    ),

    // Item 29
    VocabularyItem(
      word: 'Verbose',
      frequency: WordFrequency.veryLow,
      twoPointAnswers: [
        'Using far more words than necessary',
        'Wordy and overly long',
        'Expressing oneself with an excess of words',
        'Long-winded and rambling',
      ],
      onePointAnswers: [
        'Wordy',
        'Long-winded',
        'Talks too much',
        'Uses many words',
      ],
      thetaValue: 3.6,
    ),

    // Item 30
    VocabularyItem(
      word: 'Exacerbate',
      frequency: WordFrequency.veryLow,
      twoPointAnswers: [
        'To make something worse or more intense',
        'To aggravate or intensify',
        'To increase the severity of something',
        'To make a bad situation more severe',
      ],
      onePointAnswers: [
        'To worsen',
        'To increase',
        'To make worse',
        'To intensify',
      ],
      thetaValue: 3.8,
    ),
  ];
}
