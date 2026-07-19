// Qui décide si les résultats sont verrouillés : le serveur ou le cache local ?
//
// L'ancienne règle consultait le cache EN PREMIER et sortait aussitôt s'il
// disait « débloqué ». Le serveur n'était alors plus jamais interrogé, ce qui
// avait deux conséquences graves :
//   - un compte remis à zéro côté serveur restait débloqué à vie sur l'appareil ;
//   - re-verrouiller un tricheur (`instagramVerified:false`) n'avait aucun effet.
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
      // instagramVerified:false ⇒ le serveur repasse sous stage 4.
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
}
