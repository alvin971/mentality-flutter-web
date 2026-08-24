// La durée d'une passation part-elle DÈS le premier sous-test ?
//
// Défaut constaté sur la première passation réelle (2026-08-24) : après Cubes,
// `test_sessions.duration_s` valait `null`. La durée était publiée par le BLoC,
// qui n'apprend la fin d'un sous-test qu'après le `pop` de sa page — donc APRÈS
// que la page ait déjà appelé `flushSubtest`. Elle arrivait systématiquement un
// sous-test trop tard, et jamais du tout sur le premier envoi.
//
// L'horloge vit désormais dans ResultsSync. Ces tests la tiennent : ils
// n'émettent AUCUN événement de BLoC, exactement comme une page d'exercice.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mentality/core/services/auth_local_store.dart';
import 'package:mentality/core/services/results_sync.dart';

import 'referral_credit_kit.dart';

const _csid = '6c0ac833-fb7f-4450-9e52-6721cdd6a498';

/// Corps du dernier `POST /results` réellement émis.
Map<String, dynamic> dernierEnvoi() {
  final r = journal.lastWhere((r) => r.url.path.endsWith('/results'));
  return jsonDecode(r.body) as Map<String, dynamic>;
}

String jourDe(String iso8601) => iso8601.substring(0, 10);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    Hive.init(Directory.systemTemp.createTempSync('mentality_duree').path);
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    installeFauxReseau();
    await ResultsSync.instance.reset();
    await AuthLocalStore.instance.saveToken(tokenDeTest);
  });

  test(
      'le PREMIER envoi porte déjà la durée — aucun événement de BLoC '
      "n'est nécessaire", () async {
    // Passation ouverte il y a 20 min : l'app a pu être tuée et relancée entre
    // deux exercices, les dates sont relues du coffre.
    final mesure = DateTime.now().subtract(const Duration(minutes: 20));
    await AuthLocalStore.instance.saveTestSessionId(_csid);
    await AuthLocalStore.instance
        .saveTestSessionDates(ouverture: mesure, mesureDepuis: mesure);

    await ResultsSync.instance
        .flushSubtest({'subtest': 'block_design', 'rawScore': 42});

    final c = dernierEnvoi();
    expect(c['clientSessionId'], _csid);
    expect(c['durationS'], isA<int>());
    expect(c['durationS'] as int, greaterThanOrEqualTo(1195));
  });

  test(
      "le jour d'ouverture ne se déplace PAS à la date du jour après un "
      'redémarrage', () async {
    // Sans dates persistées, l'envoi suivant renvoyait `startedAt = maintenant`,
    // l'upsert déplaçait `started_on`, et la fenêtre de reprise de 7 jours
    // repartait de zéro en silence.
    final ouverture = DateTime.now().subtract(const Duration(days: 3));
    await AuthLocalStore.instance.saveTestSessionId(_csid);
    await AuthLocalStore.instance.saveTestSessionDates(
      ouverture: ouverture,
      mesureDepuis: ouverture,
    );

    await ResultsSync.instance
        .flushSubtest({'subtest': 'similarities', 'rawScore': 21});

    expect(jourDe(dernierEnvoi()['startedAt'] as String),
        jourDe(ouverture.toUtc().toIso8601String()));
  });

  test(
      'à la reprise, les deux dates sont indépendantes : le jour reste, '
      "l'horloge recule", () async {
    // Cas de l'appareil neuf : le jour d'ouverture date la péremption et ne
    // doit pas bouger ; l'origine de mesure, elle, recule de la durée acquise
    // pour que `duration_s` reste continu d'un appareil à l'autre.
    final jour = DateTime.now().subtract(const Duration(days: 2));
    final mesure = DateTime.now().subtract(const Duration(seconds: 3000));
    await ResultsSync.instance.adopterSession(
      _csid,
      jourOuverture: jour,
      mesureDepuis: mesure,
    );

    await ResultsSync.instance
        .flushSubtest({'subtest': 'digit_span', 'rawScore': 18});

    final c = dernierEnvoi();
    expect(jourDe(c['startedAt'] as String), jourDe(jour.toUtc().toIso8601String()));
    expect(c['durationS'] as int, greaterThanOrEqualTo(2995));
  });

  test('la durée explicite de la clôture prime sur l\'horloge', () async {
    await ResultsSync.instance.adopterSession(
      _csid,
      jourOuverture: DateTime.now(),
      mesureDepuis: DateTime.now().subtract(const Duration(seconds: 10)),
    );
    await ResultsSync.instance.complete(durationSeconds: 4242);
    expect(dernierEnvoi()['durationS'], 4242);
  });

  test('changer de token efface AUSSI les dates, pas seulement l\'identifiant',
      () async {
    // Un changement de token change d'IDENTITÉ. Laisser l'horloge derrière
    // ferait démarrer la passation du nouveau compte avec la durée de l'ancien.
    await AuthLocalStore.instance.saveTestSessionId(_csid);
    await AuthLocalStore.instance.saveTestSessionDates(
      ouverture: DateTime.now().subtract(const Duration(days: 1)),
      mesureDepuis: DateTime.now().subtract(const Duration(days: 1)),
    );

    await AuthLocalStore.instance.saveToken(tokenDeTest);

    expect(await AuthLocalStore.instance.getTestSessionId(), isNull);
    final d = await AuthLocalStore.instance.getTestSessionDates();
    expect(d.ouverture, isNull);
    expect(d.mesureDepuis, isNull);
  });
}
