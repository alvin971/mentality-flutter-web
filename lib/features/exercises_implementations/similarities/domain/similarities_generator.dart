import 'dart:math';

import '../../_shared/stratified_draw.dart';
import 'similarities_items_en.dart';
import 'similarities_items_en_gb.dart';
import 'similarities_items_es.dart';
import 'similarities_items_fr.dart';
import 'similarities_items_de.dart';
import 'similarities_items_pt.dart';

/// Générateur de 21 items de Similitudes (Similarities - WAIS-IV).
///
/// Les 21 paires sont TIRÉES ALÉATOIREMENT dans une banque élargie
/// (~100 paires réparties en 4 niveaux d'abstraction) à chaque création du
/// générateur : deux passations ne donnent pas le même test.
/// La structure WAIS est conservée : 4/6/6/5 paires par niveau, échelle theta
/// croissante de -1.5 à +2.5 par pas de 0.2.
/// Mesure l'abstraction conceptuelle et le raisonnement verbal.
class SimilaritiesGenerator {
  final Random _random;
  final String languageCode;
  final List<SimilarityItem> _preGeneratedItems = [];

  /// Nombre de paires tirées par niveau d'abstraction (total = 21).
  /// concrete / functional / categorical / abstract.
  static const List<int> _itemsPerBand = [4, 6, 6, 5];

  /// [languageCode] : 'fr' (défaut) ou 'en'.
  /// [seed] optionnel : tirage reproductible (tests). null = aléatoire réel.
  SimilaritiesGenerator({this.languageCode = 'fr', int? seed})
      : _random = seed != null ? Random(seed) : Random() {
    _initializeAllItems();
  }

  /// Tire 21 paires : pour chaque niveau, mélange la banque et prélève les
  /// slots requis. Le `thetaValue` dépend du SLOT (position), pas de la paire
  /// tirée : l'échelle de difficulté reste identique d'une passation à l'autre.
  void _initializeAllItems() {
    _preGeneratedItems.clear();
    final banks = _banksFor(languageCode);
    final drawn = stratifiedDraw<SimilarityItem>(banks, _itemsPerBand, _random);
    for (var i = 0; i < drawn.length; i++) {
      final src = drawn[i];
      _preGeneratedItems.add(SimilarityItem(
        word1: src.word1,
        word2: src.word2,
        level: src.level,
        twoPointAnswers: src.twoPointAnswers,
        onePointAnswers: src.onePointAnswers,
        thetaValue: thetaForSlot(i, start: -1.5),
      ));
    }
  }

  /// Banques (par niveau d'abstraction) correspondant au tag de langue de
  /// contenu (`fr`, `en`, `en-GB`, `es`, `pt`, `de`). en-GB partage la banque
  /// anglaise ; es/pt/de seront branchées en Phase 2. Repli → français.
  List<List<SimilarityItem>> _banksFor(String tag) {
    switch (tag) {
      case 'en':
        return buildEnglishSimilarityBanks();
      case 'en-GB':
        return buildBritishSimilarityBanks();
      case 'es':
        return buildSpanishSimilarityBanks();
      case 'pt':
        return buildPortugueseSimilarityBanks();
      case 'de':
        return buildGermanSimilarityBanks();
      case 'fr':
      default:
        return buildFrenchSimilarityBanks();
    }
  }

  /// Retourne les 21 items tirés pour cette passation.
  List<SimilarityItem> generateComplete21Items() {
    return List.from(_preGeneratedItems);
  }
}

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
  /// Vérifie si une réponse correspond, par comparaison de MOTS ENTIERS.
  ///
  /// La comparaison par sous-chaîne (ancienne implémentation) était
  /// exploitable : un fragment validait un mot clé plus long. On compare
  /// désormais des ensembles de mots significatifs (≥ 4 lettres).
  bool _matchesAnswer(String userAnswer, String expectedAnswer) {
    // Correspondance exacte
    if (userAnswer == expectedAnswer) return true;

    final userWords = _significantWords(userAnswer);
    final expectedWords = _significantWords(expectedAnswer);
    if (expectedWords.isEmpty || userWords.isEmpty) return false;

    // Au moins 70% des mots clés attendus présents comme mots entiers.
    final matchCount = expectedWords.where(userWords.contains).length;
    return matchCount >= (expectedWords.length * 0.7);
  }

  /// Mots significatifs (≥ 4 lettres) d'une chaîne, en ensemble — comparaison
  /// par mot entier, jamais par sous-chaîne.
  Set<String> _significantWords(String s) => s
      .split(_wordSplit)
      .where((w) => w.length >= 4)
      .toSet();

  static final RegExp _wordSplit =
      RegExp(r'[^0-9a-zàâäéèêëïîôöùûüÿçñ]+');

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
  concrete, // Objets physiques tangibles
  functional, // Usage commun
  categorical, // Catégorie abstraite
  abstract, // Concepts non tangibles
}
