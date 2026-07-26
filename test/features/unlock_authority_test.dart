// Qui décide si les résultats sont verrouillés : le serveur ou le cache local ?
//
// L'ancienne règle consultait le cache EN PREMIER et sortait aussitôt s'il
// disait « débloqué ». Le serveur n'était alors plus jamais interrogé, ce qui
// avait deux conséquences graves :
//   - un compte remis à zéro côté serveur restait débloqué à vie sur l'appareil ;
//   - re-verrouiller un compte côté serveur (remise à zéro) restait sans effet.
//
// Nouvelle règle : le SERVEUR tranche tant qu'il répond ; le cache n'est qu'un
// secours hors-ligne. Sans l'un ni l'autre → verrouillé (fail-closed).

import 'package:flutter_test/flutter_test.dart';

/// Réplique de UnlockService.isLocked (gate actif).
/// [serveurDit] : true/false = réponse du serveur, null = injoignable.
bool estVerrouille({required bool? serveurDit, required bool cacheDebloque}) {
  if (serveurDit != null) return !serveurDit; // autorité serveur
  return !cacheDebloque; // secours hors-ligne
}

void main() {
  group('autorité du verrou', () {
    test('LE BUG : serveur remis à zéro ⇒ re-verrouillé malgré le cache', () {
      expect(
        estVerrouille(serveurDit: false, cacheDebloque: true),
        isTrue,
        reason: 'le serveur dit « verrouillé » : le cache ne doit pas primer',
      );
    });

    test('tricheur invalidé côté serveur ⇒ re-verrouillé', () {
      // Compte invalidé côté serveur ⇒ le serveur repasse sous stage 4.
      expect(estVerrouille(serveurDit: false, cacheDebloque: true), isTrue);
    });

    test('serveur dit débloqué ⇒ déverrouillé', () {
      expect(estVerrouille(serveurDit: true, cacheDebloque: false), isFalse);
      expect(estVerrouille(serveurDit: true, cacheDebloque: true), isFalse);
    });

    test('hors-ligne AVEC déblocage acquis ⇒ reste débloqué', () {
      // Une coupure réseau ne doit pas re-flouter un résultat légitime.
      expect(estVerrouille(serveurDit: null, cacheDebloque: true), isFalse);
    });

    test('hors-ligne SANS déblocage ⇒ verrouillé (fail-closed)', () {
      expect(estVerrouille(serveurDit: null, cacheDebloque: false), isTrue);
    });

    test('balayage exhaustif des 6 combinaisons', () {
      const attendu = <String, bool>{
        'serveur=débloqué,cache=oui': false,
        'serveur=débloqué,cache=non': false,
        'serveur=verrouillé,cache=oui': true,
        'serveur=verrouillé,cache=non': true,
        'serveur=absent,cache=oui': false,
        'serveur=absent,cache=non': true,
      };
      final obtenu = <String, bool>{
        'serveur=débloqué,cache=oui':
            estVerrouille(serveurDit: true, cacheDebloque: true),
        'serveur=débloqué,cache=non':
            estVerrouille(serveurDit: true, cacheDebloque: false),
        'serveur=verrouillé,cache=oui':
            estVerrouille(serveurDit: false, cacheDebloque: true),
        'serveur=verrouillé,cache=non':
            estVerrouille(serveurDit: false, cacheDebloque: false),
        'serveur=absent,cache=oui':
            estVerrouille(serveurDit: null, cacheDebloque: true),
        'serveur=absent,cache=non':
            estVerrouille(serveurDit: null, cacheDebloque: false),
      };
      expect(obtenu, attendu);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // Le compte à rebours du palier 3 tourne côté client. Il ne doit JAMAIS
  // pouvoir débloquer quoi que ce soit : il ne fait qu'afficher. Ces règles
  // répliquent la logique de UnlockGatePage (_awaitingServer / _syncCountdown).
  // ───────────────────────────────────────────────────────────────────────────

  /// Seul le stage renvoyé par le serveur débloque.
  bool debloque({required int stageServeur}) => stageServeur >= 4;

  /// Compteur local épuisé alors que le serveur n'a pas encore promu.
  bool attenteConfirmation({
    required int stageServeur,
    required Duration restantLocal,
  }) =>
      stageServeur == 3 && restantLocal == Duration.zero;

  group('le compte à rebours ne débloque rien', () {
    test('HORLOGE AVANCÉE : compteur à zéro, serveur à 3 ⇒ reste verrouillé',
        () {
      // C'est ce que voit quelqu'un qui a avancé la date de son téléphone
      // (ou dont le processus a simplement dérivé) : l'écran annonce la fin de
      // l'attente, et rien ne s'ouvre tant que le serveur n'a pas suivi.
      expect(debloque(stageServeur: 3), isFalse);
      expect(
        attenteConfirmation(stageServeur: 3, restantLocal: Duration.zero),
        isTrue,
        reason: 'l\'écran doit dire qu\'il attend le serveur, pas débloquer',
      );
    });

    test('compteur épuisé ET serveur à 4 ⇒ débloqué, plus d\'attente', () {
      expect(debloque(stageServeur: 4), isTrue);
      expect(
        attenteConfirmation(stageServeur: 4, restantLocal: Duration.zero),
        isFalse,
      );
    });

    test('serveur qui redonne du temps ⇒ on quitte l\'état d\'attente', () {
      // Cas du réveil après veille : le compteur monotone avait pris du retard,
      // le serveur fait autorité et le décompte repart de SA valeur.
      expect(
        attenteConfirmation(
            stageServeur: 3, restantLocal: const Duration(minutes: 42)),
        isFalse,
      );
    });
  });
}
