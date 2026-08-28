/// Générateur de 30 items UNIQUES de Vocabulaire (Vocabulary)
/// Tous les items créés en UNE SEULE FOIS au démarrage
/// Mesure la connaissance lexicale et la compréhension verbale
///
/// La banque d'items est choisie selon [languageCode] ('fr' par défaut, 'en').
/// Les deux banques sont psychométriquement équivalentes : item i partage la
/// même WordFrequency et la même thetaValue dans les deux langues.
import 'dart:math';

import '../../_shared/stratified_draw.dart';
import 'vocabulary_items_en.dart';
import 'vocabulary_items_en_gb.dart';
import 'vocabulary_items_es.dart';
import 'vocabulary_items_fr.dart';
import 'vocabulary_items_de.dart';
import 'vocabulary_items_pt.dart';

class VocabularyGenerator {
  final Random _random;
  final String languageCode;
  final List<VocabularyItem> _preGeneratedItems = [];

  /// Nombre d'items tirés par bande de fréquence (total = 30).
  /// veryHigh / high / medium / low / veryLow.
  static const List<int> _itemsPerBand = [5, 7, 8, 7, 3];

  /// [languageCode] : 'fr' (défaut) ou 'en'. Toute autre valeur retombe sur 'fr'.
  /// [seed] optionnel : tirage reproductible (tests). null = aléatoire réel.
  VocabularyGenerator({this.languageCode = 'fr', int? seed})
      : _random = seed != null ? Random(seed) : Random() {
    _initializeAllItems();
  }

  /// Tire 30 items dans une banque élargie (~150 mots, 5 bandes de fréquence).
  /// Le `thetaValue` dépend du SLOT (position), pas du mot tiré : l'échelle de
  /// difficulté reste identique d'une passation à l'autre, seul le CONTENU
  /// change. La fréquence vient de la bande d'origine (banques disjointes).
  void _initializeAllItems() {
    _preGeneratedItems.clear();
    final banks = _banksFor(languageCode);
    final drawn = stratifiedDraw<VocabularyItem>(banks, _itemsPerBand, _random);
    for (var i = 0; i < drawn.length; i++) {
      final src = drawn[i];
      _preGeneratedItems.add(VocabularyItem(
        word: src.word,
        frequency: src.frequency,
        twoPointAnswers: src.twoPointAnswers,
        onePointAnswers: src.onePointAnswers,
        thetaValue: thetaForSlot(i),
      ));
    }
  }

  /// Banques (par bande) correspondant au tag de langue de contenu
  /// (`fr`, `en`, `en-GB`, `es`, `pt`, `de`). en-GB partage la banque anglaise
  /// tant qu'une banque britannique dédiée n'existe pas ; es/pt/de seront
  /// branchées en Phase 2. Repli : tout tag inconnu → français.
  List<List<VocabularyItem>> _banksFor(String tag) {
    switch (tag) {
      case 'en':
        return buildEnglishVocabularyBanks();
      case 'en-GB':
        return buildBritishVocabularyBanks();
      case 'es':
        return buildSpanishVocabularyBanks();
      case 'pt':
        return buildPortugueseVocabularyBanks();
      case 'de':
        return buildGermanVocabularyBanks();
      case 'fr':
      default:
        return buildFrenchVocabularyBanks();
    }
  }

  /// Retourne les 30 items tirés pour cette passation.
  List<VocabularyItem> generateComplete30Items() {
    return List.from(_preGeneratedItems);
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

  /// Vérifie si une réponse correspond, par comparaison de MOTS ENTIERS.
  ///
  /// La correspondance par sous-chaîne (ancienne implémentation) était
  /// trivialement exploitable : « rui » validait « fruit », « a » validait
  /// « animaux ». On compare désormais des ensembles de mots significatifs :
  /// aucune sous-chaîne n'est acceptée.
  bool _matchesAnswer(String userAnswer, String expectedAnswer) {
    // Correspondance exacte
    if (userAnswer == expectedAnswer) return true;

    final userWords = _significantWords(userAnswer);
    final expectedWords = _significantWords(expectedAnswer);
    if (expectedWords.isEmpty || userWords.isEmpty) return false;

    // La réponse attendue est entièrement présente (tous ses mots clés comme
    // mots entiers) dans la réponse de l'utilisateur.
    if (expectedWords.every(userWords.contains)) return true;

    // Sinon : au moins 60% des mots clés attendus présents comme mots entiers.
    final matchCount = expectedWords.where(userWords.contains).length;
    return matchCount >= (expectedWords.length * 0.6);
  }

  /// Mots significatifs (≥ 3 lettres) d'une chaîne, en ensemble — comparaison
  /// par mot entier, jamais par sous-chaîne.
  Set<String> _significantWords(String s) => s
      .split(_wordSplit)
      .where((w) => w.length >= 3)
      .toSet();

  static final RegExp _wordSplit =
      RegExp(r'[^0-9a-zàâäéèêëïîôöùûüÿçñ]+');

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
  veryHigh, // Top 1000
  high, // Top 5000
  medium, // Top 10,000
  low, // Top 20,000
  veryLow, // >20,000
}
