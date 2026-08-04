// Ouverture des journées de l'événement — autorité serveur.
//
// La propriété centrale : le jour de référence vient du serveur, et RIEN
// d'autre n'entre dans le calcul. `statusOfDay` n'a aucun paramètre d'horloge,
// ce qui rend la règle inmanipulable par construction — il n'y a pas de date à
// avancer. C'est la même défense que l'ancrage monotone du décompte, poussée
// un cran plus loin : ici il n'existe même pas de temps local.
//
// Verrouillé aussi : le rattrapage est OUVERT (une journée manquée reste
// jouable) et aucune activité n'ouvre quoi que ce soit — seul le jour serveur
// le fait.

import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/features/waiting_event/_shared/domain/models/day_status.dart';
import 'package:mentality/features/waiting_event/_shared/domain/services/event_schedule.dart';

void main() {
  const jours = EventSchedule.totalDays;

  group('statut d\'une journée', () {
    test('la journée du jour est ouverte, une seule à la fois', () {
      for (var serveur = 1; serveur <= jours; serveur++) {
        final ouvertes = [
          for (var d = 1; d <= jours; d++)
            if (statusOfDay(day: d, serverDayIndex: serveur) == DayStatus.open)
              d
        ];
        expect(ouvertes, [serveur],
            reason: 'jour serveur $serveur : exactement une journée courante');
      }
    });

    test('RATTRAPAGE OUVERT : tout jour passé reste accessible', () {
      for (var serveur = 1; serveur <= jours; serveur++) {
        for (var d = 1; d < serveur; d++) {
          expect(statusOfDay(day: d, serverDayIndex: serveur), DayStatus.past,
              reason: 'jour $d manqué au jour serveur $serveur : il doit '
                  'rester rattrapable, rien ne se perd');
        }
      }
    });

    test('les journées à venir sont verrouillées', () {
      for (var serveur = 1; serveur <= jours; serveur++) {
        for (var d = serveur + 1; d <= jours; d++) {
          expect(statusOfDay(day: d, serverDayIndex: serveur), DayStatus.locked,
              reason: 'jour $d au jour serveur $serveur');
        }
      }
    });

    test('une fois débloqué (9), plus rien n\'est verrouillé', () {
      final statuts = [
        for (var d = 1; d <= jours; d++) statusOfDay(day: d, serverDayIndex: 9)
      ];
      expect(statuts.contains(DayStatus.locked), isFalse,
          reason: 'l\'événement se termine, il ne se ferme pas');
      expect(statuts.every((s) => s == DayStatus.past), isTrue);
    });
  });

  group('autorité serveur', () {
    test('balayage exhaustif : 8 journées × 9 jours serveur', () {
      // Aucun couple ne doit produire d'état imprévu, et le résultat est
      // entièrement déterminé par la comparaison des deux entiers.
      for (var serveur = 1; serveur <= 9; serveur++) {
        for (var d = 1; d <= jours; d++) {
          final attendu = d > serveur
              ? DayStatus.locked
              : (d == serveur ? DayStatus.open : DayStatus.past);
          expect(statusOfDay(day: d, serverDayIndex: serveur), attendu,
              reason: 'jour $d, serveur $serveur');
        }
      }
    });

    test('même entrée, même sortie : aucune source de temps cachée', () {
      // Si la fonction consultait une horloge, deux appels identiques
      // pourraient diverger. Ils ne le peuvent pas.
      final premier = statusOfDay(day: 4, serverDayIndex: 4);
      final second = statusOfDay(day: 4, serverDayIndex: 4);
      expect(premier, second);
      expect(premier, DayStatus.open);
    });

    test('le jour serveur seul décide de l\'ouverture', () {
      // Le même jour du programme change de statut UNIQUEMENT quand le jour
      // serveur bouge — jamais par une action de l'utilisateur.
      expect(statusOfDay(day: 5, serverDayIndex: 4), DayStatus.locked);
      expect(statusOfDay(day: 5, serverDayIndex: 5), DayStatus.open);
      expect(statusOfDay(day: 5, serverDayIndex: 6), DayStatus.past);
    });
  });
}
