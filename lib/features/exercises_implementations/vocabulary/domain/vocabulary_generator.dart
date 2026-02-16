/// Générateur de 30 items UNIQUES de Vocabulaire (Vocabulary - WAIS-IV)
/// Tous les items créés en UNE SEULE FOIS au démarrage
/// Mesure la connaissance lexicale et la compréhension verbale
class VocabularyGenerator {
  final List<VocabularyItem> _preGeneratedItems = [];

  VocabularyGenerator() {
    _initializeAllItems();
  }

  /// Initialise TOUS les 30 items uniques dès la création du générateur
  void _initializeAllItems() {
    _preGeneratedItems.clear();

    // Items 1-5 : Très facile (Top 1000 - fréquence très élevée)
    _preGeneratedItems.addAll(_createVeryEasyItems());

    // Items 6-12 : Facile (Top 5000 - objets courants)
    _preGeneratedItems.addAll(_createEasyItems());

    // Items 13-20 : Moyen (Top 10,000 - concepts abstraits)
    _preGeneratedItems.addAll(_createMediumItems());

    // Items 21-27 : Difficile (Top 20,000 - vocabulaire riche)
    _preGeneratedItems.addAll(_createDifficultItems());

    // Items 28-30 : Très difficile (>20,000 - vocabulaire rare)
    _preGeneratedItems.addAll(_createVeryDifficultItems());
  }

  /// Retourne les 30 items pré-générés
  List<VocabularyItem> generateComplete30Items() {
    return List.from(_preGeneratedItems);
  }

  // ========== NIVEAU 1 : TRÈS FACILE (Items 1-5) ==========
  // Top 1000 - Mots très fréquents, objets concrets
  List<VocabularyItem> _createVeryEasyItems() {
    return [
      // Item 1 : Objet très familier
      VocabularyItem(
        word: 'Table',
        frequency: WordFrequency.veryHigh,
        twoPointAnswers: [
          'Un meuble avec un plateau horizontal',
          'Meuble sur lequel on mange ou travaille',
          'Surface plate sur pieds pour poser des choses',
          'Meuble avec plateau',
        ],
        onePointAnswers: [
          'Meuble',
          'Pour manger',
          'On mange dessus',
          'C\'est plat',
          'Ça a quatre pieds',
        ],
        thetaValue: -2.0,
      ),

      // Item 2 : Animal familier
      VocabularyItem(
        word: 'Chat',
        frequency: WordFrequency.veryHigh,
        twoPointAnswers: [
          'Animal domestique félin',
          'Petit mammifère carnivore domestique',
          'Félin domestique',
          'Animal de compagnie qui miaule',
        ],
        onePointAnswers: [
          'Animal',
          'Animal de compagnie',
          'Il miaule',
          'Il a des poils',
          'Un animal avec des moustaches',
        ],
        thetaValue: -1.8,
      ),

      // Item 3 : Objet quotidien
      VocabularyItem(
        word: 'Livre',
        frequency: WordFrequency.veryHigh,
        twoPointAnswers: [
          'Ensemble de pages reliées qu\'on lit',
          'Ouvrage imprimé relié',
          'Recueil de pages pour lire',
          'Publication reliée contenant du texte',
        ],
        onePointAnswers: [
          'Pour lire',
          'Ça a des pages',
          'On lit dedans',
          'Objet avec du texte',
        ],
        thetaValue: -1.6,
      ),

      // Item 4 : Action courante
      VocabularyItem(
        word: 'Rapide',
        frequency: WordFrequency.veryHigh,
        twoPointAnswers: [
          'Qui va vite',
          'Qui se déplace à grande vitesse',
          'Qui fait quelque chose en peu de temps',
          'Qui a de la vitesse',
        ],
        onePointAnswers: [
          'Vite',
          'Pas lent',
          'Qui court',
          'Qui ne prend pas de temps',
        ],
        thetaValue: -1.4,
      ),

      // Item 5 : Émotion simple
      VocabularyItem(
        word: 'Content',
        frequency: WordFrequency.veryHigh,
        twoPointAnswers: [
          'Qui éprouve de la joie',
          'Satisfait et heureux',
          'Qui ressent du bonheur',
          'État de satisfaction',
        ],
        onePointAnswers: [
          'Heureux',
          'Joyeux',
          'Qui sourit',
          'Pas triste',
        ],
        thetaValue: -1.2,
      ),
    ];
  }

  // ========== NIVEAU 2 : FACILE (Items 6-12) ==========
  // Top 5000 - Objets courants et concepts familiers
  List<VocabularyItem> _createEasyItems() {
    return [
      // Item 6
      VocabularyItem(
        word: 'Bureau',
        frequency: WordFrequency.high,
        twoPointAnswers: [
          'Meuble où on travaille et écrit',
          'Table de travail avec tiroirs',
          'Meuble pour travailler',
          'Poste de travail avec surface et rangements',
        ],
        onePointAnswers: [
          'Meuble',
          'Table',
          'Pour travailler',
          'Où on écrit',
        ],
        thetaValue: -1.0,
      ),

      // Item 7
      VocabularyItem(
        word: 'Courageux',
        frequency: WordFrequency.high,
        twoPointAnswers: [
          'Qui n\'a pas peur du danger',
          'Brave face aux difficultés',
          'Qui fait preuve de courage',
          'Qui affronte les dangers sans crainte',
        ],
        onePointAnswers: [
          'Brave',
          'Pas peureux',
          'Fort',
          'Qui n\'a pas peur',
        ],
        thetaValue: -0.8,
      ),

      // Item 8
      VocabularyItem(
        word: 'Hésiter',
        frequency: WordFrequency.high,
        twoPointAnswers: [
          'Être indécis avant de choisir',
          'Ne pas savoir quelle décision prendre',
          'Manifester de l\'incertitude',
          'Douter avant d\'agir',
        ],
        onePointAnswers: [
          'Ne pas être sûr',
          'Douter',
          'Pas décidé',
          'Attendre avant de choisir',
        ],
        thetaValue: -0.6,
      ),

      // Item 9
      VocabularyItem(
        word: 'Fragile',
        frequency: WordFrequency.high,
        twoPointAnswers: [
          'Qui se casse facilement',
          'Qui manque de solidité',
          'Délicat et facilement cassable',
          'Qui peut être facilement endommagé',
        ],
        onePointAnswers: [
          'Cassable',
          'Pas solide',
          'Délicat',
          'Faible',
        ],
        thetaValue: -0.4,
      ),

      // Item 10
      VocabularyItem(
        word: 'Énorme',
        frequency: WordFrequency.high,
        twoPointAnswers: [
          'Extrêmement grand',
          'De très grande taille',
          'Immense',
          'D\'une dimension exceptionnelle',
        ],
        onePointAnswers: [
          'Très grand',
          'Gros',
          'Gigantesque',
          'Pas petit',
        ],
        thetaValue: -0.2,
      ),

      // Item 11
      VocabularyItem(
        word: 'Généreux',
        frequency: WordFrequency.high,
        twoPointAnswers: [
          'Qui donne sans compter',
          'Qui aime partager et offrir',
          'Qui fait preuve de générosité',
          'Qui donne beaucoup aux autres',
        ],
        onePointAnswers: [
          'Qui donne',
          'Gentil',
          'Qui partage',
          'Bon',
        ],
        thetaValue: 0.0,
      ),

      // Item 12
      VocabularyItem(
        word: 'Obstacle',
        frequency: WordFrequency.high,
        twoPointAnswers: [
          'Ce qui empêche d\'avancer',
          'Difficulté qui bloque le passage',
          'Élément qui entrave la progression',
          'Barrière qui gêne',
        ],
        onePointAnswers: [
          'Quelque chose qui bloque',
          'Problème',
          'Difficulté',
          'Mur',
        ],
        thetaValue: 0.2,
      ),
    ];
  }

  // ========== NIVEAU 3 : MOYEN (Items 13-20) ==========
  // Top 10,000 - Concepts abstraits et vocabulaire élargi
  List<VocabularyItem> _createMediumItems() {
    return [
      // Item 13
      VocabularyItem(
        word: 'Transparent',
        frequency: WordFrequency.medium,
        twoPointAnswers: [
          'Qui laisse passer la lumière',
          'À travers lequel on peut voir',
          'Qui n\'est pas opaque',
          'Clair et qui permet de voir au travers',
        ],
        onePointAnswers: [
          'On voit à travers',
          'Clair',
          'Comme le verre',
          'Pas opaque',
        ],
        thetaValue: 0.4,
      ),

      // Item 14
      VocabularyItem(
        word: 'Concept',
        frequency: WordFrequency.medium,
        twoPointAnswers: [
          'Idée abstraite et générale',
          'Représentation mentale abstraite',
          'Notion théorique',
          'Idée générale d\'une chose',
        ],
        onePointAnswers: [
          'Idée',
          'Pensée',
          'Notion',
          'Quelque chose d\'abstrait',
        ],
        thetaValue: 0.6,
      ),

      // Item 15
      VocabularyItem(
        word: 'Absurde',
        frequency: WordFrequency.medium,
        twoPointAnswers: [
          'Contraire à la raison et au bon sens',
          'Déraisonnable et illogique',
          'Qui n\'a aucun sens logique',
          'Irrationnel et insensé',
        ],
        onePointAnswers: [
          'Stupide',
          'Bête',
          'Pas logique',
          'Qui n\'a pas de sens',
        ],
        thetaValue: 0.8,
      ),

      // Item 16
      VocabularyItem(
        word: 'Éthique',
        frequency: WordFrequency.medium,
        twoPointAnswers: [
          'Ensemble de principes moraux',
          'Qui concerne la morale et les valeurs',
          'Relatif aux règles de conduite morale',
          'Principes qui guident le comportement',
        ],
        onePointAnswers: [
          'Moral',
          'Valeurs',
          'Ce qui est bien ou mal',
          'Règles de conduite',
        ],
        thetaValue: 1.0,
      ),

      // Item 17
      VocabularyItem(
        word: 'Concis',
        frequency: WordFrequency.medium,
        twoPointAnswers: [
          'Bref et allant à l\'essentiel',
          'Exprimé en peu de mots',
          'Court et précis',
          'Succinct',
        ],
        onePointAnswers: [
          'Court',
          'Bref',
          'Pas long',
          'Résumé',
        ],
        thetaValue: 1.2,
      ),

      // Item 18
      VocabularyItem(
        word: 'Nuance',
        frequency: WordFrequency.medium,
        twoPointAnswers: [
          'Différence subtile entre deux choses',
          'Légère variation de sens ou de ton',
          'Distinction fine et délicate',
          'Petite différence peu perceptible',
        ],
        onePointAnswers: [
          'Différence',
          'Variation',
          'Teinte',
          'Petit changement',
        ],
        thetaValue: 1.4,
      ),

      // Item 19
      VocabularyItem(
        word: 'Dilemme',
        frequency: WordFrequency.medium,
        twoPointAnswers: [
          'Choix difficile entre deux options',
          'Situation où il faut choisir entre deux alternatives',
          'Alternative contraignante',
          'Obligation de choisir entre deux solutions',
        ],
        onePointAnswers: [
          'Problème',
          'Choix difficile',
          'Décision à prendre',
          'Hésitation',
        ],
        thetaValue: 1.6,
      ),

      // Item 20
      VocabularyItem(
        word: 'Perspicace',
        frequency: WordFrequency.medium,
        twoPointAnswers: [
          'Qui comprend rapidement et finement',
          'Doué d\'une grande pénétration d\'esprit',
          'Qui voit avec clairvoyance',
          'Qui a une intelligence vive et pénétrante',
        ],
        onePointAnswers: [
          'Intelligent',
          'Qui comprend vite',
          'Malin',
          'Astucieux',
        ],
        thetaValue: 1.8,
      ),
    ];
  }

  // ========== NIVEAU 4 : DIFFICILE (Items 21-27) ==========
  // Top 20,000 - Vocabulaire riche et sophistiqué
  List<VocabularyItem> _createDifficultItems() {
    return [
      // Item 21
      VocabularyItem(
        word: 'Ambivalent',
        frequency: WordFrequency.low,
        twoPointAnswers: [
          'Qui éprouve des sentiments contradictoires',
          'Qui présente deux aspects opposés',
          'Caractérisé par une dualité de sentiments',
          'Qui manifeste des émotions contraires',
        ],
        onePointAnswers: [
          'Contradictoire',
          'Partagé',
          'Hésitant',
          'Qui a deux faces',
        ],
        thetaValue: 2.0,
      ),

      // Item 22
      VocabularyItem(
        word: 'Pragmatique',
        frequency: WordFrequency.low,
        twoPointAnswers: [
          'Orienté vers l\'action pratique',
          'Qui privilégie l\'efficacité concrète',
          'Qui s\'attache aux réalités pratiques',
          'Réaliste et pratique',
        ],
        onePointAnswers: [
          'Pratique',
          'Réaliste',
          'Efficace',
          'Concret',
        ],
        thetaValue: 2.2,
      ),

      // Item 23
      VocabularyItem(
        word: 'Éloquent',
        frequency: WordFrequency.low,
        twoPointAnswers: [
          'Qui parle avec aisance et persuasion',
          'Qui s\'exprime de façon convaincante',
          'Doué d\'éloquence',
          'Qui maîtrise l\'art de bien parler',
        ],
        onePointAnswers: [
          'Qui parle bien',
          'Bon orateur',
          'Convaincant',
          'Qui sait parler',
        ],
        thetaValue: 2.4,
      ),

      // Item 24
      VocabularyItem(
        word: 'Méticuleux',
        frequency: WordFrequency.low,
        twoPointAnswers: [
          'Qui soigne les moindres détails',
          'Extrêmement attentif aux détails',
          'Qui fait preuve de minutie',
          'Scrupuleux et précis',
        ],
        onePointAnswers: [
          'Précis',
          'Soigneux',
          'Attentif',
          'Perfectionniste',
        ],
        thetaValue: 2.6,
      ),

      // Item 25
      VocabularyItem(
        word: 'Dogmatique',
        frequency: WordFrequency.low,
        twoPointAnswers: [
          'Qui impose ses opinions comme vérités',
          'Qui affirme sans admettre la contradiction',
          'Autoritaire dans ses convictions',
          'Qui présente ses idées comme absolues',
        ],
        onePointAnswers: [
          'Têtu',
          'Strict',
          'Rigide',
          'Autoritaire',
        ],
        thetaValue: 2.8,
      ),

      // Item 26
      VocabularyItem(
        word: 'Paradoxe',
        frequency: WordFrequency.low,
        twoPointAnswers: [
          'Contradiction apparente qui peut être vraie',
          'Idée contraire à l\'opinion commune',
          'Proposition apparemment contradictoire',
          'Énoncé qui semble absurde mais peut être vrai',
        ],
        onePointAnswers: [
          'Contradiction',
          'Contraire',
          'Opposé',
          'Bizarre',
        ],
        thetaValue: 3.0,
      ),

      // Item 27
      VocabularyItem(
        word: 'Résilience',
        frequency: WordFrequency.low,
        twoPointAnswers: [
          'Capacité à surmonter les épreuves',
          'Faculté de rebondir après un choc',
          'Aptitude à résister aux traumatismes',
          'Capacité d\'adaptation face à l\'adversité',
        ],
        onePointAnswers: [
          'Force',
          'Résistance',
          'Courage',
          'Capacité à se relever',
        ],
        thetaValue: 3.2,
      ),
    ];
  }

  // ========== NIVEAU 5 : TRÈS DIFFICILE (Items 28-30) ==========
  // >20,000 - Vocabulaire rare et très spécialisé
  List<VocabularyItem> _createVeryDifficultItems() {
    return [
      // Item 28
      VocabularyItem(
        word: 'Ubiquitaire',
        frequency: WordFrequency.veryLow,
        twoPointAnswers: [
          'Qui est présent partout simultanément',
          'Omniprésent',
          'Qui se trouve en tous lieux',
          'Doué d\'ubiquité',
        ],
        onePointAnswers: [
          'Partout',
          'Présent partout',
          'Commun',
          'Répandu',
        ],
        thetaValue: 3.4,
      ),

      // Item 29
      VocabularyItem(
        word: 'Prolixe',
        frequency: WordFrequency.veryLow,
        twoPointAnswers: [
          'Qui parle ou écrit de façon trop abondante',
          'Verbeux et trop long',
          'Qui s\'exprime avec excès de mots',
          'Bavard et diffus',
        ],
        onePointAnswers: [
          'Bavard',
          'Long',
          'Qui parle beaucoup',
          'Verbeux',
        ],
        thetaValue: 3.6,
      ),

      // Item 30
      VocabularyItem(
        word: 'Exacerber',
        frequency: WordFrequency.veryLow,
        twoPointAnswers: [
          'Rendre plus intense ou violent',
          'Aggraver ou intensifier',
          'Porter à un degré extrême',
          'Augmenter l\'intensité de façon excessive',
        ],
        onePointAnswers: [
          'Aggraver',
          'Augmenter',
          'Rendre pire',
          'Intensifier',
        ],
        thetaValue: 3.8,
      ),
    ];
  }
}

// ========== MODÈLES DE DONNÉES ==========

class VocabularyItem {
  final String word;
  final WordFrequency frequency;
  final List<String> twoPointAnswers;
  final List<String> onePointAnswers;
  final double thetaValue;

  VocabularyItem({
    required this.word,
    required this.frequency,
    required this.twoPointAnswers,
    required this.onePointAnswers,
    required this.thetaValue,
  });

  /// Évalue une réponse et retourne le score (0, 1, ou 2)
  int scoreAnswer(String answer) {
    final normalizedAnswer = answer.trim().toLowerCase();

    // Réponse vide = 0
    if (normalizedAnswer.isEmpty || normalizedAnswer.length < 3) {
      return 0;
    }

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

    // Si l'utilisateur a donné une définition contenant les mots clés
    if (userAnswer.contains(expectedAnswer) || expectedAnswer.contains(userAnswer)) {
      return true;
    }

    // Correspondance partielle (contient les mots clés importants)
    final userWords = userAnswer.split(' ').where((w) => w.length > 2).toList();
    final expectedWords = expectedAnswer.split(' ').where((w) => w.length > 2).toList();

    if (expectedWords.isEmpty) return false;

    // Si l'utilisateur a utilisé au moins 60% des mots clés importants
    int matchCount = 0;
    for (final word in expectedWords) {
      if (userWords.any((w) => w.contains(word) || word.contains(w))) {
        matchCount++;
      }
    }

    return matchCount >= (expectedWords.length * 0.6);
  }

  String get frequencyName {
    switch (frequency) {
      case WordFrequency.veryHigh:
        return 'Très fréquent';
      case WordFrequency.high:
        return 'Fréquent';
      case WordFrequency.medium:
        return 'Moyen';
      case WordFrequency.low:
        return 'Rare';
      case WordFrequency.veryLow:
        return 'Très rare';
    }
  }
}

enum WordFrequency {
  veryHigh,  // Top 1000
  high,      // Top 5000
  medium,    // Top 10,000
  low,       // Top 20,000
  veryLow,   // >20,000
}
