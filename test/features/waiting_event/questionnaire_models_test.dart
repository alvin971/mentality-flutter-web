// Les règles du moteur de questionnaire, vérifiées sans monter d'écran.
//
// Ce fichier tient les propriétés qui décident de la VALIDITÉ des données :
// l'ordre des items, l'intégrité des blocs validés, la cotation inversée, et
// le fait qu'un abandon ne puisse jamais passer pour un questionnaire complet.
// Une régression sur l'une d'elles ne se verrait sur aucun écran — elle
// produirait simplement un score faux.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/features/waiting_event/_shared/domain/models/event_day.dart';
import 'package:mentality/features/waiting_event/_shared/domain/models/q_answer_set.dart';
import 'package:mentality/features/waiting_event/_shared/domain/models/q_instrument.dart';
import 'package:mentality/features/waiting_event/_shared/domain/models/q_item.dart';
import 'package:mentality/features/waiting_event/_shared/domain/models/q_module.dart';
import 'package:mentality/features/waiting_event/_shared/domain/models/q_scale.dart';
import 'package:mentality/features/waiting_event/_shared/domain/models/q_text.dart';

QText six(String s) =>
    QText(fr: s, en: s, enGB: s, de: s, es: s, pt: s);

QScale echelle(String id, int premier, int dernier) => QScale(
      id: id,
      options: [
        for (var v = premier; v <= dernier; v++)
          QScaleOption(value: v, label: six('$id-$v')),
      ],
    );

QInstrument bloc(
  String id,
  QItemOrigin origine,
  QScale scale,
  int combien, {
  QTransition? transition,
}) =>
    QInstrument(
      id: id,
      origin: origine,
      scale: scale,
      transition: transition,
      items: [
        for (var i = 1; i <= combien; i++)
          QItem(id: '$id-i$i', text: six('$id question $i')),
      ],
    );

void main() {
  group('QText — six langues et repli', () {
    test('chaque langue rend sa propre valeur', () {
      const t = QText(
        fr: 'FR',
        en: 'EN',
        enGB: 'GB',
        de: 'DE',
        es: 'ES',
        pt: 'PT',
      );
      expect(t.resolve(const Locale('fr')), 'FR');
      expect(t.resolve(const Locale('en')), 'EN');
      expect(t.resolve(const Locale('en', 'GB')), 'GB');
      expect(t.resolve(const Locale('de')), 'DE');
      expect(t.resolve(const Locale('es')), 'ES');
      expect(t.resolve(const Locale('pt')), 'PT');
    });

    test('une langue non traduite retombe sur l\'anglais, jamais sur du vide',
        () {
      const t = QText(fr: 'FR', en: 'EN');
      for (final l in [
        const Locale('de'),
        const Locale('es'),
        const Locale('pt'),
        const Locale('en', 'GB'),
        const Locale('it'), // langue non prévue
      ]) {
        expect(t.resolve(l), 'EN', reason: 'repli pour $l');
      }
    });

    test('la garde de parité voit exactement ce qui manque', () {
      const partiel = QText(fr: 'FR', en: 'EN', de: 'DE');
      expect(partiel.missingLocales, ['en_GB', 'es', 'pt']);
      expect(six('x').missingLocales, isEmpty);
    });

    test('une chaîne vide compte comme non traduite', () {
      const vide = QText(fr: 'FR', en: 'EN', es: '');
      expect(vide.raw('es'), isNull);
      expect(vide.missingLocales, contains('es'));
    });
  });

  group('QScale — cotation', () {
    test('les bornes se lisent sur les modalités déclarées', () {
      final gad = echelle('gad', 0, 3);
      expect(gad.minValue, 0);
      expect(gad.maxValue, 3);
    });

    test('l\'inversion est la formule canonique min + max − valeur', () {
      final raads = echelle('raads', 0, 3);
      expect(raads.score(0, reversed: true), 3);
      expect(raads.score(3, reversed: true), 0);
      expect(raads.score(1, reversed: true), 2);
      // Sans inversion, la valeur brute passe telle quelle.
      expect(raads.score(2), 2);
    });

    test('une échelle qui ne commence pas à zéro s\'inverse aussi bien', () {
      final catq = echelle('catq', 1, 7);
      expect(catq.score(1, reversed: true), 7);
      expect(catq.score(7, reversed: true), 1);
      expect(catq.score(4, reversed: true), 4);
    });

    test('une valeur hors échelle est refusée', () {
      final gad = echelle('gad', 0, 3);
      expect(gad.accepts(0), isTrue);
      expect(gad.accepts(3), isTrue);
      expect(gad.accepts(4), isFalse);
      expect(gad.accepts(-1), isFalse);
    });
  });

  group('QModule — structure et ordre', () {
    final quatre = echelle('quatre', 0, 3);
    final sept = echelle('sept', 1, 7);
    final module = QModule(
      id: 'demo',
      day: 7,
      kind: DayActivityKind.announced,
      instruments: [
        bloc('valide', QItemOrigin.validated, quatre, 3),
        bloc('camouflage', QItemOrigin.validated, sept, 2,
            transition: QTransition(title: six('Partie 2'), body: six('...'))),
        bloc('maison', QItemOrigin.candidate, sept, 2),
      ],
    );

    test('les items sortent à plat, dans l\'ordre des blocs', () {
      expect(module.questionCount, 7);
      expect(module.items.map((i) => i.id).toList(), [
        'valide-i1', 'valide-i2', 'valide-i3', //
        'camouflage-i1', 'camouflage-i2', //
        'maison-i1', 'maison-i2',
      ]);
    });

    test('chaque indice retrouve son bloc et son échelle', () {
      expect(module.instrumentAt(0).id, 'valide');
      expect(module.instrumentAt(2).id, 'valide');
      expect(module.instrumentAt(3).id, 'camouflage');
      expect(module.instrumentAt(6).id, 'maison');
      expect(module.scaleAt(0).id, 'quatre');
      expect(module.scaleAt(3).id, 'sept');
    });

    test('un indice hors module lève plutôt que de renvoyer n\'importe quoi',
        () {
      expect(() => module.instrumentAt(7), throwsRangeError);
    });

    test('les débuts de bloc sont repérés', () {
      expect([for (var i = 0; i < 7; i++) module.startsBlockAt(i)],
          [true, false, false, true, false, true, false]);
    });

    test('un changement d\'échelle est signalé, une échelle identique non', () {
      // Indice 3 : quatre → sept, c'est une couture.
      expect(module.startsNewScaleAt(3), isTrue);
      // Indice 5 : nouveau bloc, mais MÊME échelle — rien à annoncer.
      expect(module.startsNewScaleAt(5), isFalse);
      expect(module.startsNewScaleAt(0), isFalse, reason: 'rien avant le début');
    });

    test('GARDE : tout changement d\'échelle a son écran de transition', () {
      expect(module.undeclaredScaleChanges, isEmpty);

      final sansTransition = QModule(
        id: 'x',
        day: 1,
        kind: DayActivityKind.announced,
        instruments: [
          bloc('a', QItemOrigin.validated, quatre, 2),
          bloc('b', QItemOrigin.validated, sept, 2), // échelle changée, muette
        ],
      );
      expect(sansTransition.undeclaredScaleChanges, [2],
          reason: 'les boutons changeraient sous les doigts sans un mot');
    });

    test('GARDE : les blocs validés passent avant nos questions', () {
      expect(module.validatedBlocksComeFirst, isTrue);

      final inverse = QModule(
        id: 'x',
        day: 1,
        kind: DayActivityKind.announced,
        instruments: [
          bloc('maison', QItemOrigin.candidate, quatre, 2),
          bloc('valide', QItemOrigin.validated, quatre, 2),
        ],
      );
      expect(inverse.validatedBlocksComeFirst, isFalse,
          reason: 'nos questions avant l\'instrument fausseraient son seuil');
    });
  });

  group('QModule — reprise', () {
    final module = QModule(
      id: 'reprise',
      day: 1,
      kind: DayActivityKind.announced,
      instruments: [bloc('a', QItemOrigin.validated, echelle('e', 0, 3), 5)],
    );

    test('sans aucune réponse, on reprend à la première question', () {
      expect(module.resumeIndexFor({}), 0);
    });

    test('on reprend au PREMIER trou, pas après la dernière réponse', () {
      // Cas impossible par l'UI (rien n'est sautable) mais possible sur un
      // stockage abîmé : on redemande le trou plutôt que de l'oublier.
      expect(module.resumeIndexFor({'a-i1', 'a-i2', 'a-i4'}), 2);
    });

    test('tout répondu → l\'indice de reprise sort du module', () {
      final tout = {for (final i in module.items) i.id};
      expect(module.resumeIndexFor(tout), 5);
      expect(module.isCompleteFor(tout), isTrue);
      expect(module.isCompleteFor({'a-i1'}), isFalse);
    });
  });

  group('QAnswerSet — le partiel est nommé', () {
    const vide = QAnswerSet(moduleId: 'm');

    test('un questionnaire commencé est partiel', () {
      expect(vide.isPartial, isTrue);
      expect(vide.answeredCount, 0);
    });

    test('répondre n\'achève rien tout seul', () {
      final avec = vide.withAnswer('i1', 2);
      expect(avec.valueOf('i1'), 2);
      expect(avec.isPartial, isTrue,
          reason: 'seul markCompleted() peut lever le drapeau partiel');
    });

    test('se corriger remplace la réponse sans en ajouter une', () {
      final corrige = vide.withAnswer('i1', 2).withAnswer('i1', 0);
      expect(corrige.valueOf('i1'), 0);
      expect(corrige.answeredCount, 1);
    });

    test('terminé conserve les réponses et lève le drapeau', () {
      final fini = vide.withAnswer('i1', 1).markCompleted();
      expect(fini.isPartial, isFalse);
      expect(fini.status, QAnswerStatus.completed);
      expect(fini.valueOf('i1'), 1);
    });

    test('aller-retour JSON sans perte', () {
      final avant = vide.withAnswer('i1', 3).withAnswer('i2', 0).markCompleted();
      final apres = QAnswerSet.fromJson(avant.toJson());
      expect(apres, avant);
    });

    test('un JSON abîmé ne fait pas perdre les réponses lisibles', () {
      final relu = QAnswerSet.fromJson({
        'moduleId': 'm',
        'answers': {'i1': 2, 'i2': 'bidon', 'i3': 1},
        'status': 'inProgress',
      });
      expect(relu.answers, {'i1': 2, 'i3': 1});
    });

    test('un statut inconnu retombe sur « en cours », jamais sur « terminé »',
        () {
      final relu = QAnswerSet.fromJson(
          {'moduleId': 'm', 'answers': <String, int>{}, 'status': 'n_importe_quoi'});
      expect(relu.isPartial, isTrue,
          reason: 'dans le doute, la donnée part marquée partielle');
    });
  });
}
