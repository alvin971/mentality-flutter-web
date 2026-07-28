// Le chronomètre d'un essai — injectable, parce qu'un test ne peut pas
// attendre 600 ms de vrai temps par essai.
//
// Le banc d'essai des widgets fait avancer une horloge FICTIVE : `pump()`
// n'attend rien réellement, et un `Stopwatch` (qui lit l'horloge du système)
// y renverrait quelques millisecondes pour chaque essai. Toute la passation
// tomberait alors sous le seuil d'anticipation, donc hors médiane : le jeu
// serait « non fiable » dans chacun de ses tests, et la seule chose qu'ils
// vérifieraient serait ce message d'échec.
//
// D'où cette interface étroite. Ce qu'un test a besoin de scénariser, ce sont
// des TEMPS DE RÉPONSE (600 ms en neutre, 800 ms en conflit), pas le
// fonctionnement d'un compteur.

/// Mesure le temps écoulé depuis l'apparition du stimulus courant.
abstract interface class StroopChrono {
  /// Remet à zéro et repart. Appelé à chaque nouvel essai affiché.
  void start();

  /// Millisecondes depuis le dernier [start].
  int get elapsedMs;
}

class RealStroopChrono implements StroopChrono {
  final Stopwatch _stopwatch = Stopwatch();

  @override
  void start() {
    _stopwatch
      ..reset()
      ..start();
  }

  @override
  int get elapsedMs => _stopwatch.elapsedMilliseconds;
}
