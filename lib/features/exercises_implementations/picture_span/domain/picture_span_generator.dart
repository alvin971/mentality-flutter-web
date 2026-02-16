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
      ImageStimulus(id: 1, category: ImageCategory.animals, icon: Icons.pets, name: 'Chat'),
      ImageStimulus(id: 2, category: ImageCategory.animals, icon: Icons.bug_report, name: 'Insecte'),
      ImageStimulus(id: 3, category: ImageCategory.animals, icon: Icons.cruelty_free, name: 'Lapin'),
      ImageStimulus(id: 4, category: ImageCategory.animals, icon: Icons.wb_sunny, name: 'Oiseau'),
      ImageStimulus(id: 5, category: ImageCategory.animals, icon: Icons.flutter_dash, name: 'Poisson'),
      ImageStimulus(id: 6, category: ImageCategory.animals, icon: Icons.eco, name: 'Tortue'),
      ImageStimulus(id: 7, category: ImageCategory.animals, icon: Icons.stars, name: 'Papillon'),
      ImageStimulus(id: 8, category: ImageCategory.animals, icon: Icons.coronavirus, name: 'Coccinelle'),
    ]);

    // Objets quotidiens (8 images)
    _imageBank.addAll([
      ImageStimulus(id: 9, category: ImageCategory.objects, icon: Icons.chair, name: 'Chaise'),
      ImageStimulus(id: 10, category: ImageCategory.objects, icon: Icons.light, name: 'Lampe'),
      ImageStimulus(id: 11, category: ImageCategory.objects, icon: Icons.watch, name: 'Montre'),
      ImageStimulus(id: 12, category: ImageCategory.objects, icon: Icons.umbrella, name: 'Parapluie'),
      ImageStimulus(id: 13, category: ImageCategory.objects, icon: Icons.backpack, name: 'Sac'),
      ImageStimulus(id: 14, category: ImageCategory.objects, icon: Icons.bed, name: 'Lit'),
      ImageStimulus(id: 15, category: ImageCategory.objects, icon: Icons.meeting_room, name: 'Porte'),
      ImageStimulus(id: 16, category: ImageCategory.objects, icon: Icons.window, name: 'Fenêtre'),
    ]);

    // Nourriture (8 images)
    _imageBank.addAll([
      ImageStimulus(id: 17, category: ImageCategory.food, icon: Icons.cake, name: 'Gâteau'),
      ImageStimulus(id: 18, category: ImageCategory.food, icon: Icons.coffee, name: 'Café'),
      ImageStimulus(id: 19, category: ImageCategory.food, icon: Icons.local_pizza, name: 'Pizza'),
      ImageStimulus(id: 20, category: ImageCategory.food, icon: Icons.apple, name: 'Pomme'),
      ImageStimulus(id: 21, category: ImageCategory.food, icon: Icons.icecream, name: 'Glace'),
      ImageStimulus(id: 22, category: ImageCategory.food, icon: Icons.fastfood, name: 'Burger'),
      ImageStimulus(id: 23, category: ImageCategory.food, icon: Icons.lunch_dining, name: 'Sandwich'),
      ImageStimulus(id: 24, category: ImageCategory.food, icon: Icons.egg, name: 'Œuf'),
    ]);

    // Outils (8 images)
    _imageBank.addAll([
      ImageStimulus(id: 25, category: ImageCategory.tools, icon: Icons.build, name: 'Marteau'),
      ImageStimulus(id: 26, category: ImageCategory.tools, icon: Icons.construction, name: 'Clé'),
      ImageStimulus(id: 27, category: ImageCategory.tools, icon: Icons.cut, name: 'Ciseaux'),
      ImageStimulus(id: 28, category: ImageCategory.tools, icon: Icons.brush, name: 'Pinceau'),
      ImageStimulus(id: 29, category: ImageCategory.tools, icon: Icons.edit, name: 'Crayon'),
      ImageStimulus(id: 30, category: ImageCategory.tools, icon: Icons.content_cut, name: 'Couteau'),
      ImageStimulus(id: 31, category: ImageCategory.tools, icon: Icons.handyman, name: 'Tournevis'),
      ImageStimulus(id: 32, category: ImageCategory.tools, icon: Icons.settings, name: 'Engrenage'),
    ]);

    // Transport (8 images)
    _imageBank.addAll([
      ImageStimulus(id: 33, category: ImageCategory.transport, icon: Icons.directions_car, name: 'Voiture'),
      ImageStimulus(id: 34, category: ImageCategory.transport, icon: Icons.directions_bike, name: 'Vélo'),
      ImageStimulus(id: 35, category: ImageCategory.transport, icon: Icons.flight, name: 'Avion'),
      ImageStimulus(id: 36, category: ImageCategory.transport, icon: Icons.train, name: 'Train'),
      ImageStimulus(id: 37, category: ImageCategory.transport, icon: Icons.directions_boat, name: 'Bateau'),
      ImageStimulus(id: 38, category: ImageCategory.transport, icon: Icons.directions_bus, name: 'Bus'),
      ImageStimulus(id: 39, category: ImageCategory.transport, icon: Icons.motorcycle, name: 'Moto'),
      ImageStimulus(id: 40, category: ImageCategory.transport, icon: Icons.rocket_launch, name: 'Fusée'),
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
  final String name;

  ImageStimulus({
    required this.id,
    required this.category,
    required this.icon,
    required this.name,
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
