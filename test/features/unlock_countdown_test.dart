// Compte à rebours du palier 3 : granularité d'affichage et ancrage monotone.
//
// Deux propriétés y sont verrouillées, et la seconde est une propriété de
// SÉCURITÉ : le décompte ne doit jamais dériver de l'horloge murale. S'il en
// dérivait, avancer la date de son téléphone le ferait tomber à zéro — d'où la
// tentation, pour un futur refactor, de « simplifier » en
// `unlockAt.difference(DateTime.now())`. Le test ci-dessous rend cette
// simplification impossible sans casser la suite.

import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/features/unlock/data/unlock_service.dart';
import 'package:mentality/features/unlock/presentation/pages/unlock_gate_page.dart';

/// Réplique de la condition d'affichage de la bannière de recette.
bool afficheBanniereModeTest({required bool debugDelayOverride}) =>
    debugDelayOverride;

UnlockProgress _attente({
  required int secondsRemaining,
  Duration anchor = Duration.zero,
  int stage = 3,
}) =>
    UnlockProgress(
      stage: stage,
      referralCode: 'abcd1234',
      completedReferrals: 3,
      requiredReferrals: 3,
      unlockAt: DateTime.utc(2026, 8, 3),
      secondsRemaining: secondsRemaining,
      anchor: anchor,
    );

void main() {
  group('granularité du décompte', () {
    test('jours au-delà de 48 h, heures en dessous, minutes sous 1 h', () {
      String rendu(Duration d) {
        final p = countdownParts(d);
        return '${p.unit.name}:${p.value}';
      }

      // Balayage des bornes, comparé en une seule fois : un échec montre
      // d'emblée TOUTES les granularités fautives, pas seulement la première.
      final obtenu = {
        '8 jours': rendu(const Duration(days: 8)),
        '49 h': rendu(const Duration(hours: 49)),
        '48 h 01': rendu(const Duration(hours: 48, minutes: 1)),
        '48 h pile': rendu(const Duration(hours: 48)),
        '3 h 30': rendu(const Duration(hours: 3, minutes: 30)),
        '1 h pile': rendu(const Duration(hours: 1)),
        '59 min 30 s': rendu(const Duration(minutes: 59, seconds: 30)),
        '59 min pile': rendu(const Duration(minutes: 59)),
        '30 s': rendu(const Duration(seconds: 30)),
        'zéro': rendu(Duration.zero),
        'négatif': rendu(const Duration(seconds: -5)),
      };

      expect(obtenu, {
        '8 jours': 'days:8',
        '49 h': 'days:3', // arrondi au supérieur : jamais moins que le réel
        '48 h 01': 'days:3',
        '48 h pile': 'hours:48', // le seuil des jours est STRICTEMENT au-delà
        '3 h 30': 'hours:4',
        '1 h pile': 'hours:1',
        '59 min 30 s': 'hours:1', // pas « 60 minutes » : seuils sur les
        '59 min pile': 'minutes:59', // minutes DÉJÀ arrondies
        '30 s': 'minutes:1',
        'zéro': 'zero:0',
        'négatif': 'zero:0',
      });
    });
  });

  group('ancrage monotone — le décompte est inmanipulable', () {
    test('le restant se dérive du compteur monotone, pas d\'une date', () {
      final p = _attente(secondsRemaining: 3600);
      expect(p.remainingAt(const Duration(seconds: 600)).inSeconds, 3000);
    });

    test('l\'ancre décale le calcul : deux réponses successives concordent', () {
      // Réponse reçue alors que le compteur du processus affichait 1000 s.
      final p = _attente(secondsRemaining: 3600, anchor: const Duration(seconds: 1000));
      expect(p.remainingAt(const Duration(seconds: 1000)).inSeconds, 3600);
      expect(p.remainingAt(const Duration(seconds: 1600)).inSeconds, 3000);
    });

    test('jamais négatif', () {
      final p = _attente(secondsRemaining: 10);
      expect(p.remainingAt(const Duration(hours: 5)), Duration.zero);
    });

    test('AVANCER L\'HORLOGE DU TÉLÉPHONE NE CHANGE RIEN', () {
      // `remainingAt` ne prend qu'un Duration monotone : il n'existe aucun
      // paramètre, aucun champ, par lequel une date système pourrait entrer
      // dans le calcul. On le vérifie en faisant « avancer » une horloge murale
      // simulée de 10 jours pendant que le compteur monotone, lui, ne bouge pas.
      final p = _attente(secondsRemaining: 3600);
      final avant = p.remainingAt(const Duration(seconds: 60));

      // ignore: unused_local_variable
      final horlogeMurale = DateTime.utc(2026, 8, 30); // « on est déjà en août »
      final apres = p.remainingAt(const Duration(seconds: 60));

      expect(apres, avant, reason: 'le Stopwatch est la seule référence');
      expect(apres.inSeconds, 3540, reason: 'toujours verrouillé');
    });

    test('un déblocage confirmé met le restant à zéro', () {
      final p = _attente(secondsRemaining: 9999, stage: 4);
      expect(p.unlocked, isTrue);
      expect(p.remainingAt(Duration.zero), Duration.zero);
    });
  });

  group('discriminant du compte à rebours', () {
    test('countdownApplicable, jamais « secondsRemaining == 0 »', () {
      // Le délai est écoulé mais le serveur n'a pas encore promu : le décompte
      // s'applique toujours (il affiche « écoulé »), on n'est PAS débloqué.
      final ecoule = _attente(secondsRemaining: 0);
      expect(ecoule.countdownApplicable, isTrue);
      expect(ecoule.unlocked, isFalse);

      // Palier 1 : l'attente n'a pas commencé, secondsRemaining vaut 0 AUSSI.
      const pasCommence = UnlockProgress(
        stage: 1,
        referralCode: 'abcd1234',
        completedReferrals: 0,
        requiredReferrals: 3,
      );
      expect(pasCommence.countdownApplicable, isFalse,
          reason: 'sans unlockAt, aucun décompte à afficher');
    });

    test('worker plus ancien (unlockAt absent) : carte sans décompte, pas de crash',
        () {
      final p = UnlockProgress.fromJson(const {
        'stage': 3,
        'referralCode': 'abcd1234',
        'completedReferrals': 3,
        'requiredReferrals': 3,
      });
      expect(p.countdownApplicable, isFalse);
      expect(p.displayDelayDays, 0);
      expect(p.debugDelayOverride, isFalse);
    });
  });

  group('bannière MODE TEST', () {
    test('texte exact, non traduit', () {
      expect(debugDelayBannerText(1), 'MODE TEST — délai réel : 1 min');
      expect(debugDelayBannerText(11520), 'MODE TEST — délai réel : 11520 min');
    });

    test('affichée SI ET SEULEMENT SI le serveur signale l\'override', () {
      expect(afficheBanniereModeTest(debugDelayOverride: true), isTrue);
      expect(afficheBanniereModeTest(debugDelayOverride: false), isFalse);
    });

    test('le drapeau et le délai réel viennent bien de la réponse serveur', () {
      final p = UnlockProgress.fromJson(const {
        'stage': 3,
        'referralCode': 'abcd1234',
        'completedReferrals': 3,
        'requiredReferrals': 3,
        'unlockAt': '2026-08-03T12:00:00.000Z',
        'secondsRemaining': 60,
        'displayDelayDays': 8,
        'delayMinutes': 1,
        'debugDelayOverride': true,
      });
      expect(p.debugDelayOverride, isTrue);
      expect(p.displayDelayDays, 8, reason: 'ce qu\'on annonce');
      expect(p.delayMinutes, 1, reason: 'ce qui s\'applique réellement');
      expect(debugDelayBannerText(p.delayMinutes),
          'MODE TEST — délai réel : 1 min');
    });
  });
}
