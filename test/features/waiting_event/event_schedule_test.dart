// Le programme des 8 jours, verrouillé sur le plan produit.
//
// Ce fichier teste le VRAI code (aucune réplique) : la table est une donnée,
// elle se vérifie directement. Ce qu'il empêche, c'est une dérive silencieuse
// du programme — un jour qui changerait de cadrage, un volume de questions qui
// sortirait des clous, une révélation déplacée. Chacune de ces règles vient du
// plan produit et a une raison d'être ; elles sont rappelées cas par cas.

import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/features/waiting_event/_shared/domain/models/event_day.dart';
import 'package:mentality/features/waiting_event/_shared/domain/services/event_schedule.dart';

void main() {
  group('structure du programme', () {
    test('8 journées, numérotées de 1 à 8 dans l\'ordre', () {
      expect(EventSchedule.days.length, EventSchedule.totalDays);
      expect(
        [for (final j in EventSchedule.days) j.day],
        [1, 2, 3, 4, 5, 6, 7, 8],
      );
    });

    test('byDay rend bien la journée demandée', () {
      for (var d = 1; d <= EventSchedule.totalDays; d++) {
        expect(EventSchedule.byDay(d).day, d);
      }
    });
  });

  group('conformité au tableau maître', () {
    test('révélation, cadrage, jeu et volume de chaque journée', () {
      // Comparaison en BLOC : un échec montre d'emblée toute la table, pas la
      // première ligne fautive.
      final table = {
        for (final j in EventSchedule.days)
          j.day: (j.reveal, j.activityKind, j.game, j.questionCount),
      };
      expect(table, {
        1: (RevealKind.vci, DayActivityKind.announced, null, 50),
        2: (
          RevealKind.psi,
          DayActivityKind.contribution,
          GameKind.stroop,
          40,
        ),
        3: (RevealKind.wmi, DayActivityKind.announced, null, 45),
        4: (
          RevealKind.fri,
          DayActivityKind.contribution,
          GameKind.delayChoice,
          45,
        ),
        5: (
          RevealKind.vsi,
          DayActivityKind.contribution,
          GameKind.timeEstimation,
          40,
        ),
        6: (
          RevealKind.strengths,
          DayActivityKind.announced,
          GameKind.confidenceCalibration,
          44,
        ),
        7: (null, DayActivityKind.announced, null, 49),
        8: (RevealKind.fullIq, DayActivityKind.share, null, 0),
      });
    });

    test('le jour vedette est le seul sans révélation', () {
      final sansRevelation = [
        for (final j in EventSchedule.days)
          if (j.reveal == null) j.day
      ];
      expect(sansRevelation, [7],
          reason: 'le bilan autisme ferme la série : rien ne lui fait '
              'concurrence ce jour-là');
    });

    test('les journées de contribution sont exactement J2, J4 et J5', () {
      final contributions = [
        for (final j in EventSchedule.days)
          if (j.activityKind == DayActivityKind.contribution) j.day
      ];
      expect(contributions, [2, 4, 5],
          reason: 'ce sont les seules journées sans score à afficher — le '
              'cadrage « aide-nous à construire » en dépend');
    });

    test('chaque jeu n\'apparaît qu\'une fois', () {
      final jeux = [
        for (final j in EventSchedule.days)
          if (j.game != null) j.game!
      ];
      expect(jeux.toSet().length, jeux.length);
    });
  });

  group('garde du volume de questions', () {
    test('tout questionnaire tient entre 40 et 50 questions', () {
      for (final j in EventSchedule.days) {
        if (j.activityKind == DayActivityKind.share) continue;
        expect(j.questionCount, inInclusiveRange(40, 50),
            reason: 'jour ${j.day} : la règle du programme est de 40 à 50 '
                'questions par test');
      }
    });

    test('le dernier jour ne pose aucune question', () {
      final j8 = EventSchedule.byDay(8);
      expect(j8.activityKind, DayActivityKind.share);
      expect(j8.questionCount, 0,
          reason: 'J8 est une récompense, pas un test de plus');
    });
  });
}
