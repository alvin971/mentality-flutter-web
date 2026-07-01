import 'package:flutter/material.dart';

/// Générateur de Mémoire des Images (Picture Span - WISC-V)
/// 6 niveaux avec 2 essais chacun = 12 essais au total
/// Mesure la mémoire de travail visuelle et l'attention sélective
class PictureSpanGenerator {
  final List<PictureSpanItem> _preGeneratedItems = [];
  final List<ImageStimulus> _imageBank = [];

  PictureSpanGenerator() {
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

  /// Initialise tous les 12 essais (6 niveaux × 2 essais)
  void _initializeAllItems() {
    _preGeneratedItems.clear();

    // Niveau 1 : 1 image (2 essais)
    _preGeneratedItems.addAll(_createLevel1Items());

    // Niveau 2 : 2 images (2 essais)
    _preGeneratedItems.addAll(_createLevel2Items());

    // Niveau 3 : 3 images (2 essais)
    _preGeneratedItems.addAll(_createLevel3Items());

    // Niveau 4 : 4 images (2 essais)
    _preGeneratedItems.addAll(_createLevel4Items());

    // Niveau 5 : 5 images (2 essais)
    _preGeneratedItems.addAll(_createLevel5Items());

    // Niveau 6 : 6 images (2 essais)
    _preGeneratedItems.addAll(_createLevel6Items());
  }

  /// Retourne tous les items
  List<PictureSpanItem> generateComplete12Items() {
    return List.from(_preGeneratedItems);
  }

  /// Retourne la banque d'images complète
  List<ImageStimulus> getImageBank() {
    return List.from(_imageBank);
  }

  // ========== NIVEAU 1 : 1 image ==========
  List<PictureSpanItem> _createLevel1Items() {
    return [
      PictureSpanItem(
        level: 1,
        trial: 1,
        targetImageIds: [1], // Chat
        distractorImageIds: [2, 3, 4, 5, 6, 7, 8, 9], // 8 distracteurs
        presentationSeconds: 3,
        thetaValue: -2.0,
      ),
      PictureSpanItem(
        level: 1,
        trial: 2,
        targetImageIds: [10], // Lampe
        distractorImageIds: [9, 11, 12, 13, 14, 15, 16, 17],
        presentationSeconds: 3,
        thetaValue: -2.0,
      ),
    ];
  }

  // ========== NIVEAU 2 : 2 images ==========
  List<PictureSpanItem> _createLevel2Items() {
    return [
      PictureSpanItem(
        level: 2,
        trial: 1,
        targetImageIds: [18, 20], // Café, Pomme
        distractorImageIds: [17, 19, 21, 22, 23, 24, 25, 26],
        presentationSeconds: 6,
        thetaValue: -1.5,
      ),
      PictureSpanItem(
        level: 2,
        trial: 2,
        targetImageIds: [33, 35], // Voiture, Avion
        distractorImageIds: [34, 36, 37, 38, 39, 40, 1, 2],
        presentationSeconds: 6,
        thetaValue: -1.5,
      ),
    ];
  }

  // ========== NIVEAU 3 : 3 images ==========
  List<PictureSpanItem> _createLevel3Items() {
    return [
      PictureSpanItem(
        level: 3,
        trial: 1,
        targetImageIds: [5, 12, 19], // Poisson, Parapluie, Pizza
        distractorImageIds: [3, 4, 11, 13, 18, 20, 21, 22],
        presentationSeconds: 9,
        thetaValue: -1.0,
      ),
      PictureSpanItem(
        level: 3,
        trial: 2,
        targetImageIds: [25, 28, 33], // Marteau, Pinceau, Voiture
        distractorImageIds: [26, 27, 29, 30, 34, 35, 36, 37],
        presentationSeconds: 9,
        thetaValue: -1.0,
      ),
    ];
  }

  // ========== NIVEAU 4 : 4 images ==========
  List<PictureSpanItem> _createLevel4Items() {
    return [
      PictureSpanItem(
        level: 4,
        trial: 1,
        targetImageIds: [2, 14, 21, 36], // Insecte, Lit, Glace, Train
        distractorImageIds: [1, 3, 13, 15, 20, 22, 35, 37],
        presentationSeconds: 12,
        thetaValue: -0.5,
      ),
      PictureSpanItem(
        level: 4,
        trial: 2,
        targetImageIds: [7, 16, 24, 31], // Papillon, Fenêtre, Œuf, Tournevis
        distractorImageIds: [6, 8, 15, 17, 23, 25, 30, 32],
        presentationSeconds: 12,
        thetaValue: -0.5,
      ),
    ];
  }

  // ========== NIVEAU 5 : 5 images ==========
  List<PictureSpanItem> _createLevel5Items() {
    return [
      PictureSpanItem(
        level: 5,
        trial: 1,
        targetImageIds: [4, 11, 17, 27, 38], // Oiseau, Montre, Gâteau, Ciseaux, Bus
        distractorImageIds: [3, 5, 10, 12, 18, 26, 28, 37],
        presentationSeconds: 15,
        thetaValue: 0.0,
      ),
      PictureSpanItem(
        level: 5,
        trial: 2,
        targetImageIds: [8, 13, 22, 29, 40], // Coccinelle, Sac, Burger, Crayon, Fusée
        distractorImageIds: [7, 9, 12, 14, 21, 28, 30, 39],
        presentationSeconds: 15,
        thetaValue: 0.0,
      ),
    ];
  }

  // ========== NIVEAU 6 : 6 images ==========
  List<PictureSpanItem> _createLevel6Items() {
    return [
      PictureSpanItem(
        level: 6,
        trial: 1,
        targetImageIds: [6, 9, 18, 26, 34, 39], // Tortue, Chaise, Café, Clé, Vélo, Moto
        distractorImageIds: [5, 7, 10, 17, 19, 25, 33, 40],
        presentationSeconds: 18,
        thetaValue: 0.5,
      ),
      PictureSpanItem(
        level: 6,
        trial: 2,
        targetImageIds: [3, 15, 20, 30, 32, 37], // Lapin, Porte, Pomme, Couteau, Engrenage, Bateau
        distractorImageIds: [2, 4, 14, 16, 19, 29, 31, 36],
        presentationSeconds: 18,
        thetaValue: 0.5,
      ),
    ];
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
  final int presentationSeconds; // Temps total de présentation
  final double thetaValue;

  PictureSpanItem({
    required this.level,
    required this.trial,
    required this.targetImageIds,
    required this.distractorImageIds,
    required this.presentationSeconds,
    required this.thetaValue,
  });

  /// Nombre d'images à mémoriser
  int get numberOfImages => targetImageIds.length;

  /// Temps par image (3 secondes)
  int get secondsPerImage => 3;

  /// Grille complète pour le rappel (cibles + distracteurs)
  List<int> get recallGridIds {
    final combined = [...targetImageIds, ...distractorImageIds];
    combined.shuffle(); // Mélanger pour la présentation
    return combined;
  }

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

  /// Chemin de l'asset image réel (WISC-V : stimulus visuel sans texte).
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
