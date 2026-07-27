// Le contrat de fil : ce que le client envoie VRAIMENT au worker.
//
// `HttpEventTransport.send` est le seul code de production qui parle au worker
// event. Tout le reste de la chaîne peut être parfait, si cette requête part
// sur la mauvaise route ou sans son en-tête de finalité, le worker répond 403
// et la donnée n'arrive jamais. Ce fichier monte donc un faux serveur et
// inspecte la requête réelle, en-tête par en-tête.
//
// C'est aussi une garde de PARITÉ inter-langages : les constantes citées ici
// (route, noms d'en-têtes, finalité, version de schéma) sont dupliquées dans
// workers/event/index.js. Le dernier test les confronte au source du worker —
// une divergence est autrement invisible jusqu'au premier 403 en production.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mentality/core/consent/consent_record.dart';
import 'package:mentality/core/services/auth_local_store.dart';
import 'package:mentality/features/waiting_event/_shared/data/event_upload_service.dart';
import 'package:mentality/features/waiting_event/_shared/domain/models/event_day.dart';
import 'package:mentality/features/waiting_event/_shared/domain/models/event_submission.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kUrlFactice = 'https://event.exemple.test';

String passe(String nonce) =>
    'M2.${base64Url.encode(utf8.encode(jsonEncode({'n': nonce})))}';

final soumission = EventSubmission(
  moduleId: 'j3_wellbeing',
  day: 3,
  kind: DayActivityKind.announced,
  locale: 'en_GB',
  partial: true,
  answers: const {'gad1': 2, 'gad2': 0},
);

void main() {
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('mentality_wire_test');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  setUp(() async {
    await AuthLocalStore.instance.clear();
    await AuthLocalStore.instance.saveToken(passe('nonce-fil'));
  });

  /// Un transport branché sur un faux serveur qui capture la requête.
  (HttpEventTransport, List<http.Request>) transport(
    http.Response Function(http.Request) repond,
  ) {
    final vues = <http.Request>[];
    final client = MockClient((requete) async {
      vues.add(requete);
      return repond(requete);
    });
    return (
      HttpEventTransport(client: client, baseUrl: kUrlFactice),
      vues,
    );
  }

  test('la requête part sur /responses, en POST, avec ses trois en-têtes',
      () async {
    final (t, vues) = transport((_) => http.Response('{"stored":true}', 200));

    final issue = await t.send(soumission, consentVersion: '2026-07-27.v2');

    expect(issue, EventUploadOutcome.confirmed);
    final requete = vues.single;
    expect(requete.method, 'POST');
    expect(requete.url.toString(), '$kUrlFactice/responses');
    expect(requete.headers['X-Mentality-Token'], passe('nonce-fil'),
        reason: 'le worker dérive la partition du passe : sans lui, 401');
    expect(requete.headers['X-Consent-Version'], '2026-07-27.v2',
        reason: 'la preuve art. 7 voyage avec la donnée');
    expect(requete.headers['X-Consent-Purpose'], kEventDataPurpose,
        reason: 'sans la FINALITÉ, un consentement audio suffirait — le worker '
            'répond 403');
  });

  test('le corps est exactement la charge utile du contrat', () async {
    final (t, vues) = transport((_) => http.Response('{"stored":true}', 200));

    await t.send(soumission, consentVersion: '2026-07-27.v2');

    expect(jsonDecode(vues.single.body), {
      'schema': kEventPayloadSchema,
      'moduleId': 'j3_wellbeing',
      'day': 3,
      'kind': 'announced',
      'partial': true,
      'locale': 'en_GB',
      'answers': {'gad1': 2, 'gad2': 0},
    });
  });

  test('sans passe exploitable, rien ne part sur le réseau', () async {
    await AuthLocalStore.instance.clear();
    final (t, vues) = transport((_) => http.Response('{"stored":true}', 200));

    expect(await t.send(soumission, consentVersion: '2026-07-27.v2'),
        EventUploadOutcome.unreachable);
    expect(vues, isEmpty,
        reason: 'le worker refuserait de toute façon : autant garder la donnée');
  });

  test('worker non configuré : aucune requête, et on rejouera', () async {
    final vues = <http.Request>[];
    final t = HttpEventTransport(
      client: MockClient((r) async {
        vues.add(r);
        return http.Response('', 200);
      }),
      baseUrl: 'https://mentality-event.YOUR_SUBDOMAIN.workers.dev',
    );

    expect(await t.send(soumission, consentVersion: '2026-07-27.v2'),
        EventUploadOutcome.unreachable);
    expect(vues, isEmpty);
  });

  test('les statuts du serveur se traduisent en issues', () async {
    for (final cas in {
      200: EventUploadOutcome.confirmed,
      400: EventUploadOutcome.refused,
      401: EventUploadOutcome.unreachable,
      403: EventUploadOutcome.unreachable,
      404: EventUploadOutcome.unreachable,
      502: EventUploadOutcome.unreachable,
    }.entries) {
      final (t, _) = transport((_) => http.Response('{}', cas.key));
      expect(await t.send(soumission, consentVersion: 'v'), cas.value,
          reason: 'statut ${cas.key}');
    }
  });

  test('une panne réseau vaut injoignable, jamais une perte', () async {
    final t = HttpEventTransport(
      client: MockClient((_) async => throw const SocketException('coupé')),
      baseUrl: kUrlFactice,
    );

    expect(await t.send(soumission, consentVersion: 'v'),
        EventUploadOutcome.unreachable);
  });

  // ─── Parité avec le worker ─────────────────────────────────────────────────

  test('les constantes partagées avec le worker sont identiques des deux côtés',
      () {
    // Le contrat est réparti sur deux langages : rien ne relie `kEventDataPurpose`
    // à `EXPECTED_PURPOSE` qu'une bonne intention. Ce test lit le source du
    // worker et confronte les deux.
    final source = File('workers/event/index.js');
    expect(source.existsSync(), isTrue,
        reason: 'lancé depuis la racine du paquet (comme theme_discipline_test)');
    final js = source.readAsStringSync();

    expect(js, contains("const EXPECTED_PURPOSE = '$kEventDataPurpose';"),
        reason: 'une finalité désalignée = 403 sur chaque envoi');
    expect(js, contains('const SUPPORTED_SCHEMA = $kEventPayloadSchema;'),
        reason: 'un schéma désaligné = 400 sur chaque envoi, donc un refus '
            'DÉFINITIF : toutes les réponses seraient perdues');
    expect(js, contains("const KINDS = new Set(['announced', 'contribution']);"),
        reason: 'les cadrages RGPD acceptés doivent être ceux de '
            'DayActivityKind — ${DayActivityKind.values.map((k) => k.name)}');
    expect(js, contains("request.headers.get('X-Consent-Purpose')"));
    expect(js, contains("request.headers.get('X-Consent-Version')"));
    expect(js, contains("request.headers.get('X-Mentality-Token')"));
    expect(js, contains("path !== '/responses'"),
        reason: 'la route attendue par le client');
  });
}
