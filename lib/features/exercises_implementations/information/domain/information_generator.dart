import 'dart:math';

import '../../_shared/stratified_draw.dart';
import 'information_items_en.dart';
import 'information_items_en_gb.dart';
import 'information_items_es.dart';
import 'information_items_fr.dart';
import 'information_items_de.dart';
import 'information_items_pt.dart';

/// Générateur de 28 items d'Information (Connaissances générales).
///
/// Les 28 questions sont TIRÉES ALÉATOIREMENT dans une banque élargie
/// (~180 QCM répartis en 15 cellules domaine × difficulté) à chaque création :
/// deux passations ne donnent pas le même test. De plus, l'ordre des 4 options
/// de chaque question est MÉLANGÉ (et l'index de la bonne réponse remappé), ce
/// qui casse la mémorisation positionnelle A/B/C/D.
/// Structure conservée : distribution par domaine (6/7/6/5/4) et progression de
/// difficulté (9 faciles → 11 moyens → 8 difficiles), theta croissant par slot.
class InformationGenerator {
  final Random _random;
  final String languageCode;
  final List<InformationItem> _preGeneratedItems = [];

  /// Slots tirés par cellule. Les 15 cellules sont ordonnées en 3 blocs de
  /// difficulté (easy, medium, hard), chacun couvrant les 5 domaines dans
  /// l'ordre science / historyGeography / generalCulture / mathLogic /
  /// artsLiterature. Total = 9 + 11 + 8 = 28.
  static const List<int> _slotsPerCell = [
    2, 2, 2, 2, 1, // EASY  : sci, hist, gen, math, arts
    2, 3, 2, 2, 2, // MEDIUM: sci, hist, gen, math, arts
    2, 2, 2, 1, 1, // HARD  : sci, hist, gen, math, arts
  ];

  /// [languageCode] : 'fr' (défaut) ou 'en'.
  /// [seed] optionnel : tirage reproductible (tests). null = aléatoire réel.
  InformationGenerator({this.languageCode = 'fr', int? seed})
      : _random = seed != null ? Random(seed) : Random() {
    _initializeAllItems();
  }

  /// Tire 28 questions (banque stratifiée 15 cellules), mélange les options de
  /// chaque QCM et remappe l'index de la bonne réponse, puis attribue le
  /// `thetaValue` par SLOT (échelle de difficulté stable entre passations).
  void _initializeAllItems() {
    _preGeneratedItems.clear();
    final banks = _banksFor(languageCode);
    final drawn = stratifiedDraw<InformationItem>(banks, _slotsPerCell, _random);
    for (var i = 0; i < drawn.length; i++) {
      final src = drawn[i];
      final correctText = src.options[src.correctAnswer];
      final opts = List<String>.of(src.options)..shuffle(_random);
      _preGeneratedItems.add(InformationItem(
        question: src.question,
        options: opts,
        correctAnswer: opts.indexOf(correctText),
        domain: src.domain,
        difficulty: src.difficulty,
        thetaValue: thetaForSlot(i, start: -2.0, step: 0.15, decimals: 2),
      ));
    }
  }

  /// Banques (par cellule domaine×difficulté) correspondant au tag de langue
  /// de contenu (`fr`, `en`, `en-GB`, `es`, `pt`, `de`). en-GB partage la
  /// banque anglaise ; es/pt/de (faits adaptés culturellement) seront branchées
  /// en Phase 2. Repli → français.
  List<List<InformationItem>> _banksFor(String tag) {
    switch (tag) {
      case 'en':
        return buildEnglishInformationBanks();
      case 'en-GB':
        return buildBritishInformationBanks();
      case 'es':
        return buildSpanishInformationBanks();
      case 'pt':
        return buildPortugueseInformationBanks();
      case 'de':
        return buildGermanInformationBanks();
      case 'fr':
      default:
        return buildFrenchInformationBanks();
    }
  }

  /// Retourne les 28 items tirés pour cette passation.
  List<InformationItem> generateComplete28Items() {
    return List.from(_preGeneratedItems);
  }
}

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
  science, // Sciences naturelles
  historyGeography, // Histoire/Géographie
  generalCulture, // Culture générale
  mathLogic, // Mathématiques/Logique
  artsLiterature, // Arts/Littérature
}

enum DifficultyLevel {
  easy,
  medium,
  hard,
}
