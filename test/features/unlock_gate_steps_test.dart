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
  Paliers({
    required this.completed,
    required this.required,
    required this.stage,
    this.dayIndex,
  });
  final int completed;
  final int required;
  final int stage;

  /// Jour de l'événement tel que le serveur l'annonce. `null` face à un worker
  /// qui ne connaît pas encore le champ.
  final int? dayIndex;

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

  /// Bouton « voir le programme du jour », dans la carte du palier 3.
  /// Subordonné à `dayIndex` : sans jour serveur, il n'y a pas de programme à
  /// ouvrir, et un bouton mènerait à un écran vide.
  bool get afficheBoutonHub => afficheAttenteFinale && dayIndex != null;
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

  // L'entrée vers le programme des 8 jours vit dans la carte du palier 3. Elle
  // n'apparaît que si le serveur sait dire quel jour on est : c'est ce qui
  // permet de livrer le client avant le worker sans afficher de bouton mort.
  group('entrée vers le programme des 8 jours', () {
    test('en attente avec un jour serveur : le bouton est là', () {
      final p = Paliers(completed: 3, required: 3, stage: 3, dayIndex: 3);
      expect(p.afficheAttenteFinale, isTrue);
      expect(p.afficheBoutonHub, isTrue);
    });

    test('WORKER PLUS ANCIEN : la carte d\'attente reste, sans bouton', () {
      final p = Paliers(completed: 3, required: 3, stage: 3);
      expect(p.afficheAttenteFinale, isTrue, reason: 'la carte ne change pas');
      expect(p.afficheBoutonHub, isFalse);
      expect(p.peutAvancer, isTrue, reason: 'aucune impasse pour autant');
    });

    test('une fois débloqué, plus de carte d\'attente donc plus de bouton', () {
      final p = Paliers(completed: 3, required: 3, stage: 4, dayIndex: 9);
      expect(p.afficheAttenteFinale, isFalse);
      expect(p.afficheBoutonHub, isFalse);
    });

    test('parrainage acquis mais stage non promu : carte oui, bouton non', () {
      // L'état incohérent que la carte du palier 3 gère volontairement — le
      // serveur n'a pas encore promu, donc il n'annonce aucun jour.
      final p = Paliers(completed: 3, required: 3, stage: 1);
      expect(p.afficheAttenteFinale, isTrue);
      expect(p.afficheBoutonHub, isFalse,
          reason: 'sans jour serveur, aucun programme à ouvrir');
    });
  });
}
