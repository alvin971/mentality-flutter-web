// Régression : « bloqué à l'étape 2, je ne vois plus le lien d'invitation ».
//
// L'écran des missions masquait la carte du lien dès qu'UN ami avait terminé
// (condition « !referralsDone && !showWaiting »). À 1/3 et 2/3 — précisément
// quand il faut inviter les amis manquants — l'utilisateur se retrouvait sur un
// écran d'attente sans aucune action possible.
//
// Invariant : le lien d'invitation est visible TANT QUE le palier parrainage
// n'est pas atteint.

import 'package:flutter_test/flutter_test.dart';

/// Réplique des conditions d'affichage de UnlockGatePage._buildSteps.
/// Si ces règles changent dans la page, ce test doit changer avec elles.
class Paliers {
  Paliers({required this.completed, required this.required, required this.stage});
  final int completed;
  final int required;
  final int stage;

  bool get parrainageAcquis => completed >= required;
  bool get afficheAttente => !parrainageAcquis && completed >= 1;
  bool get debloque => stage >= 4;

  /// Carte contenant le lien d'invitation + le bouton copier.
  bool get afficheLien => !parrainageAcquis;

  /// Carte du palier 3 (attente du délai de publication).
  /// Volontairement indépendant de `stage` : s'y fier créait une impasse
  /// (parrainage acquis mais stage non promu ⇒ aucune carte).
  bool get afficheAttenteFinale => parrainageAcquis && !debloque;

  /// Au moins une action possible pour avancer.
  bool get peutAvancer => afficheLien || afficheAttenteFinale;
}

void main() {
  group('paliers de déblocage — le lien reste accessible', () {
    test('LE BUG : à 1/3 le lien d\'invitation est TOUJOURS visible', () {
      final p = Paliers(completed: 1, required: 3, stage: 2);
      expect(p.afficheLien, isTrue);
      expect(p.afficheAttente, isTrue, reason: 'le suivi des amis reste affiché');
      expect(p.peutAvancer, isTrue);
    });

    test('à 2/3 aussi', () {
      final p = Paliers(completed: 2, required: 3, stage: 2);
      expect(p.afficheLien, isTrue);
      expect(p.peutAvancer, isTrue);
    });

    test('à 0/3 : lien seul, pas encore de suivi des amis', () {
      final p = Paliers(completed: 0, required: 3, stage: 1);
      expect(p.afficheLien, isTrue);
      expect(p.afficheAttente, isFalse);
    });

    test('à 3/3 : le lien laisse place au palier d\'attente', () {
      final p = Paliers(completed: 3, required: 3, stage: 3);
      expect(p.afficheLien, isFalse);
      expect(p.afficheAttenteFinale, isTrue);
      expect(p.peutAvancer, isTrue);
    });

    test('IMPASSE : aucun état non débloqué ne laisse l\'utilisateur sans action',
        () {
      // Balayage exhaustif, y compris les états incohérents que le serveur
      // n'est pas censé produire (parrainage acquis mais stage non promu).
      for (var completed = 0; completed <= 5; completed++) {
        for (var stage = 1; stage <= 3; stage++) {
          final p = Paliers(completed: completed, required: 3, stage: stage);
          expect(
            p.peutAvancer,
            isTrue,
            reason: 'impasse à completed=$completed, stage=$stage : '
                'ni lien ni palier d\'attente affiché',
          );
        }
      }
    });

    test('une fois débloqué, plus aucune carte de mission', () {
      final p = Paliers(completed: 3, required: 3, stage: 4);
      expect(p.debloque, isTrue);
      expect(p.afficheAttenteFinale, isFalse);
      expect(p.afficheLien, isFalse);
    });

    test('un seul compteur de progression (celui du palier 1)', () {
      // Le palier 2 n'affiche plus sa propre barre quand le palier 1 est là.
      final p = Paliers(completed: 1, required: 3, stage: 2);
      expect(p.afficheLien && p.afficheAttente, isTrue,
          reason: 'les deux cartes coexistent, une seule barre');
    });
  });
}
