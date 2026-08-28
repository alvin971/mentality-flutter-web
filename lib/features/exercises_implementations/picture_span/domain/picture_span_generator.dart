import 'dart:math';

import 'package:flutter/material.dart';

/// Générateur de Mémoire des Images (Picture Span)
/// 6 niveaux avec 2 essais chacun = 12 essais au total
/// Mesure la mémoire de travail visuelle et l'attention sélective
///
/// Le tirage est ALÉATOIRE PAR PASSATION : cibles et distracteurs sont tirés
/// de la banque de 40 images à chaque session — deux passations ne présentent
/// pas les mêmes séquences. La difficulté du slot (niveau, nombre d'images,
/// temps de présentation, thêta) reste identique d'une passation à l'autre :
/// seul CHANGE le contenu, pas l'échelle.
class PictureSpanGenerator {
  final Random _random;
  final List<PictureSpanItem> _preGeneratedItems = [];
  final List<ImageStimulus> _imageBank = [];

  /// [seed] optionnel : tirage reproductible (tests). null = aléatoire réel.
  PictureSpanGenerator({int? seed}) : _random = Random(seed) {
    _initializeImageBank();
    _initializeAllItems();
  }

  /// Initialise la banque de 40 images distinctes
  void _initializeImageBank() {
    _imageBank.clear();

    // Animaux (8 images)
    _imageBank.addAll([
      ImageStimulus(id: 1, category: ImageCategory.animals, icon: Icons.pets, imagePath: 'images/picture_span/01_chat.webp', name: 'Chat', nameKey: 'psImgChat'),
      ImageStimulus(id: 2, category: ImageCategory.animals, icon: Icons.bug_report, imagePath: 'images/picture_span/02_insecte.webp', name: 'Insecte', nameKey: 'psImgInsecte'),
      ImageStimulus(id: 3, category: ImageCategory.animals, icon: Icons.cruelty_free, imagePath: 'images/picture_span/03_lapin.webp', name: 'Lapin', nameKey: 'psImgLapin'),
      ImageStimulus(id: 4, category: ImageCategory.animals, icon: Icons.wb_sunny, imagePath: 'images/picture_span/04_oiseau.webp', name: 'Oiseau', nameKey: 'psImgOiseau'),
      ImageStimulus(id: 5, category: ImageCategory.animals, icon: Icons.flutter_dash, imagePath: 'images/picture_span/05_poisson.webp', name: 'Poisson', nameKey: 'psImgPoisson'),
      ImageStimulus(id: 6, category: ImageCategory.animals, icon: Icons.eco, imagePath: 'images/picture_span/06_tortue.webp', name: 'Tortue', nameKey: 'psImgTortue'),
      ImageStimulus(id: 7, category: ImageCategory.animals, icon: Icons.stars, imagePath: 'images/picture_span/07_papillon.webp', name: 'Papillon', nameKey: 'psImgPapillon'),
      ImageStimulus(id: 8, category: ImageCategory.animals, icon: Icons.coronavirus, imagePath: 'images/picture_span/08_coccinelle.webp', name: 'Coccinelle', nameKey: 'psImgCoccinelle'),
    ]);

    // Objets quotidiens (8 images)
    _imageBank.addAll([
      ImageStimulus(id: 9, category: ImageCategory.objects, icon: Icons.chair, imagePath: 'images/picture_span/09_chaise.webp', name: 'Chaise', nameKey: 'psImgChaise'),
      ImageStimulus(id: 10, category: ImageCategory.objects, icon: Icons.light, imagePath: 'images/picture_span/10_lampe.webp', name: 'Lampe', nameKey: 'psImgLampe'),
      ImageStimulus(id: 11, category: ImageCategory.objects, icon: Icons.watch, imagePath: 'images/picture_span/11_montre.webp', name: 'Montre', nameKey: 'psImgMontre'),
      ImageStimulus(id: 12, category: ImageCategory.objects, icon: Icons.umbrella, imagePath: 'images/picture_span/12_parapluie.webp', name: 'Parapluie', nameKey: 'psImgParapluie'),
      ImageStimulus(id: 13, category: ImageCategory.objects, icon: Icons.backpack, imagePath: 'images/picture_span/13_sac.webp', name: 'Sac', nameKey: 'psImgSac'),
      ImageStimulus(id: 14, category: ImageCategory.objects, icon: Icons.bed, imagePath: 'images/picture_span/14_lit.webp', name: 'Lit', nameKey: 'psImgLit'),
      ImageStimulus(id: 15, category: ImageCategory.objects, icon: Icons.meeting_room, imagePath: 'images/picture_span/15_porte.webp', name: 'Porte', nameKey: 'psImgPorte'),
      ImageStimulus(id: 16, category: ImageCategory.objects, icon: Icons.window, imagePath: 'images/picture_span/16_fenetre.webp', name: 'Fenêtre', nameKey: 'psImgFenetre'),
    ]);

    // Nourriture (8 images)
    _imageBank.addAll([
      ImageStimulus(id: 17, category: ImageCategory.food, icon: Icons.cake, imagePath: 'images/picture_span/17_gateau.webp', name: 'Gâteau', nameKey: 'psImgGateau'),
      ImageStimulus(id: 18, category: ImageCategory.food, icon: Icons.coffee, imagePath: 'images/picture_span/18_cafe.webp', name: 'Café', nameKey: 'psImgCafe'),
      ImageStimulus(id: 19, category: ImageCategory.food, icon: Icons.local_pizza, imagePath: 'images/picture_span/19_pizza.webp', name: 'Pizza', nameKey: 'psImgPizza'),
      ImageStimulus(id: 20, category: ImageCategory.food, icon: Icons.apple, imagePath: 'images/picture_span/20_pomme.webp', name: 'Pomme', nameKey: 'psImgPomme'),
      ImageStimulus(id: 21, category: ImageCategory.food, icon: Icons.icecream, imagePath: 'images/picture_span/21_glace.webp', name: 'Glace', nameKey: 'psImgGlace'),
      ImageStimulus(id: 22, category: ImageCategory.food, icon: Icons.fastfood, imagePath: 'images/picture_span/22_burger.webp', name: 'Burger', nameKey: 'psImgBurger'),
      ImageStimulus(id: 23, category: ImageCategory.food, icon: Icons.lunch_dining, imagePath: 'images/picture_span/23_sandwich.webp', name: 'Sandwich', nameKey: 'psImgSandwich'),
      ImageStimulus(id: 24, category: ImageCategory.food, icon: Icons.egg, imagePath: 'images/picture_span/24_oeuf.webp', name: 'Œuf', nameKey: 'psImgOeuf'),
    ]);

    // Outils (8 images)
    _imageBank.addAll([
      ImageStimulus(id: 25, category: ImageCategory.tools, icon: Icons.build, imagePath: 'images/picture_span/25_marteau.webp', name: 'Marteau', nameKey: 'psImgMarteau'),
      ImageStimulus(id: 26, category: ImageCategory.tools, icon: Icons.construction, imagePath: 'images/picture_span/26_cle.webp', name: 'Clé', nameKey: 'psImgCle'),
      ImageStimulus(id: 27, category: ImageCategory.tools, icon: Icons.cut, imagePath: 'images/picture_span/27_ciseaux.webp', name: 'Ciseaux', nameKey: 'psImgCiseaux'),
      ImageStimulus(id: 28, category: ImageCategory.tools, icon: Icons.brush, imagePath: 'images/picture_span/28_pinceau.webp', name: 'Pinceau', nameKey: 'psImgPinceau'),
      ImageStimulus(id: 29, category: ImageCategory.tools, icon: Icons.edit, imagePath: 'images/picture_span/29_crayon.webp', name: 'Crayon', nameKey: 'psImgCrayon'),
      ImageStimulus(id: 30, category: ImageCategory.tools, icon: Icons.content_cut, imagePath: 'images/picture_span/30_couteau.webp', name: 'Couteau', nameKey: 'psImgCouteau'),
      ImageStimulus(id: 31, category: ImageCategory.tools, icon: Icons.handyman, imagePath: 'images/picture_span/31_tournevis.webp', name: 'Tournevis', nameKey: 'psImgTournevis'),
      ImageStimulus(id: 32, category: ImageCategory.tools, icon: Icons.settings, imagePath: 'images/picture_span/32_engrenage.webp', name: 'Engrenage', nameKey: 'psImgEngrenage'),
    ]);

    // Transport (8 images)
    _imageBank.addAll([
      ImageStimulus(id: 33, category: ImageCategory.transport, icon: Icons.directions_car, imagePath: 'images/picture_span/33_voiture.webp', name: 'Voiture', nameKey: 'psImgVoiture'),
      ImageStimulus(id: 34, category: ImageCategory.transport, icon: Icons.directions_bike, imagePath: 'images/picture_span/34_velo.webp', name: 'Vélo', nameKey: 'psImgVelo'),
      ImageStimulus(id: 35, category: ImageCategory.transport, icon: Icons.flight, imagePath: 'images/picture_span/35_avion.webp', name: 'Avion', nameKey: 'psImgAvion'),
      ImageStimulus(id: 36, category: ImageCategory.transport, icon: Icons.train, imagePath: 'images/picture_span/36_train.webp', name: 'Train', nameKey: 'psImgTrain'),
      ImageStimulus(id: 37, category: ImageCategory.transport, icon: Icons.directions_boat, imagePath: 'images/picture_span/37_bateau.webp', name: 'Bateau', nameKey: 'psImgBateau'),
      ImageStimulus(id: 38, category: ImageCategory.transport, icon: Icons.directions_bus, imagePath: 'images/picture_span/38_bus.webp', name: 'Bus', nameKey: 'psImgBus'),
      ImageStimulus(id: 39, category: ImageCategory.transport, icon: Icons.motorcycle, imagePath: 'images/picture_span/39_moto.webp', name: 'Moto', nameKey: 'psImgMoto'),
      ImageStimulus(id: 40, category: ImageCategory.transport, icon: Icons.rocket_launch, imagePath: 'images/picture_span/40_fusee.webp', name: 'Fusée', nameKey: 'psImgFusee'),
    ]);
  }

  /// Thêta par niveau (échelle FIXE, indépendante du tirage).
  static const List<double> _thetaByLevel = [-2.0, -1.5, -1.0, -0.5, 0.0, 0.5];

  /// Nombre de distracteurs dans la grille de rappel (comme le protocole
  /// d'origine : grille = cibles + 8 distracteurs).
  static const int _distractorCount = 8;

  /// Initialise tous les 12 essais (6 niveaux × 2 essais), tirés au hasard.
  void _initializeAllItems() {
    _preGeneratedItems.clear();
    for (var level = 1; level <= 6; level++) {
      for (var trial = 1; trial <= 2; trial++) {
        _preGeneratedItems.add(_createItem(level: level, trial: trial));
      }
    }
  }

  /// Tire un essai : [level] cibles + 8 distracteurs, tous distincts.
  ///
  /// Les distracteurs sont pris EN PRIORITÉ dans les catégories des cibles
  /// (confusion sémantique — même exigence que les items historiques), puis
  /// complétés par le reste de la banque si besoin.
  PictureSpanItem _createItem({required int level, required int trial}) {
    final pool = List<ImageStimulus>.of(_imageBank)..shuffle(_random);
    final targets = pool.take(level).toList();
    final targetCategories = targets.map((t) => t.category).toSet();

    final remaining = pool.skip(level).toList();
    final sameCategory =
        remaining.where((i) => targetCategories.contains(i.category)).toList();
    final otherCategory =
        remaining.where((i) => !targetCategories.contains(i.category)).toList();
    final distractors =
        [...sameCategory, ...otherCategory].take(_distractorCount).toList();

    final targetIds = targets.map((t) => t.id).toList();
    final distractorIds = distractors.map((d) => d.id).toList();

    // Grille de rappel mélangée UNE SEULE FOIS ici : son ordre ne doit plus
    // changer pendant l'essai (un rebuild du widget ne remélange rien).
    final gridIds = [...targetIds, ...distractorIds]..shuffle(_random);

    return PictureSpanItem(
      level: level,
      trial: trial,
      targetImageIds: targetIds,
      distractorImageIds: distractorIds,
      recallGridIds: gridIds,
      presentationSeconds: level * 3,
      thetaValue: _thetaByLevel[level - 1],
    );
  }

  /// Retourne tous les items
  List<PictureSpanItem> generateComplete12Items() {
    return List.from(_preGeneratedItems);
  }

  /// Retourne la banque d'images complète
  List<ImageStimulus> getImageBank() {
    return List.from(_imageBank);
  }

  /// Récupère une image par son ID
  ImageStimulus? getImageById(int id) {
    try {
      return _imageBank.firstWhere((img) => img.id == id);
    } catch (e) {
      return null;
    }
  }
}

// ========== MODÈLES DE DONNÉES ==========

class PictureSpanItem {
  final int level; // 1 à 6
  final int trial; // 1 ou 2
  final List<int> targetImageIds; // IDs des images à mémoriser
  final List<int> distractorImageIds; // IDs des distracteurs pour la grille

  /// Grille complète pour le rappel (cibles + distracteurs), mélangée une
  /// seule fois à la GÉNÉRATION : l'ordre reste stable pendant tout l'essai
  /// (un rebuild du widget ne doit pas réordonner la grille sous les doigts
  /// de l'utilisateur).
  final List<int> recallGridIds;

  final int presentationSeconds; // Temps total de présentation
  final double thetaValue;

  PictureSpanItem({
    required this.level,
    required this.trial,
    required this.targetImageIds,
    required this.distractorImageIds,
    required this.recallGridIds,
    required this.presentationSeconds,
    required this.thetaValue,
  });

  /// Nombre d'images à mémoriser
  int get numberOfImages => targetImageIds.length;

  /// Temps par image (3 secondes)
  int get secondsPerImage => 3;

  /// Vérifie si la réponse utilisateur est correcte
  bool isCorrect(List<int> userSelectedIds) {
    // Doit avoir le même nombre d'images
    if (userSelectedIds.length != targetImageIds.length) return false;

    // Doit être dans le même ordre exact
    for (int i = 0; i < targetImageIds.length; i++) {
      if (userSelectedIds[i] != targetImageIds[i]) return false;
    }

    return true;
  }
}

class ImageStimulus {
  final int id;
  final ImageCategory category;
  final IconData icon;

 /// Chemin de l'asset image réel (stimulus visuel sans texte).
  /// [icon] sert de fallback si l'image ne charge pas.
  final String imagePath;

  /// Nom français (fallback / valeur par défaut). L'affichage localisé passe
  /// par [nameKey] résolu côté page via l10n.
  final String name;

  /// Clé l10n stable et indépendante de la langue (ex: 'psImgChat'),
  /// résolue à l'affichage selon la langue courante.
  final String nameKey;

  ImageStimulus({
    required this.id,
    required this.category,
    required this.icon,
    required this.imagePath,
    required this.name,
    required this.nameKey,
  });

  String get categoryName {
    switch (category) {
      case ImageCategory.animals:
        return 'Animaux';
      case ImageCategory.objects:
        return 'Objets';
      case ImageCategory.food:
        return 'Nourriture';
      case ImageCategory.tools:
        return 'Outils';
      case ImageCategory.transport:
        return 'Transport';
    }
  }
}

enum ImageCategory {
  animals,
  objects,
  food,
  tools,
  transport,
}
