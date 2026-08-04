import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart' show GlobalKey;

import '../../presentation/widgets/score_share_card.dart';

/// Capture d'un [ScoreShareCard] déjà monté dans l'arbre, en PNG 1080 × 1920.
///
/// La carte n'est pas rendue hors écran : elle est affichée dans l'écran
/// d'aperçu, sous une [RepaintBoundary]. C'est cette même frontière qu'on
/// capture — ce que l'utilisateur valide est donc littéralement ce qui part.
///
/// [RenderRepaintBoundary.toImage] rend le sous-arbre dans SON PROPRE repère :
/// une mise à l'échelle appliquée par un ancêtre pour l'aperçu (la carte fait
/// 360 × 640 en logique, l'écran est plus petit) n'affecte pas la capture.
class ScoreCardRenderer {
  const ScoreCardRenderer();

  /// Capture la frontière portée par [key].
  ///
  /// Renvoie `null` si la frontière n'est pas (encore) montée — l'appelant
  /// affiche alors une erreur plutôt que de partager une image vide.
  Future<Uint8List?> capturePng(GlobalKey key) async {
    final object = key.currentContext?.findRenderObject();
    if (object is! RenderRepaintBoundary) return null;

    final image = await object.toImage(
      pixelRatio: ScoreShareCard.capturePixelRatio,
    );
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data?.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }
}
