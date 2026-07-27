// La file d'attente des envois — chiffrée, cloisonnée par passe, et durable.
//
// C'est la moitié « qui survit » du rejeu : le service décide QUOI renvoyer,
// mais si la file ne traverse pas la fermeture de l'app, rien n'est jamais
// rejoué et on retombe sur le parrainage perdu. Les tests ci-dessous portent
// donc sur la vraie box Hive, pas sur une doublure mémoire.
//
// Le cloisonnement compte doublement ici : une soumission en attente contient
// des réponses de santé ET partira sous l'identité du passe courant. Un envoi
// déposé par un passe ne doit donc jamais être visible — ni rejouable — par un
// autre passe du même téléphone.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mentality/core/services/auth_local_store.dart';
import 'package:mentality/core/services/token_account.dart';
import 'package:mentality/features/waiting_event/_shared/data/event_local_store.dart';
import 'package:mentality/features/waiting_event/_shared/domain/models/event_day.dart';
import 'package:mentality/features/waiting_event/_shared/domain/models/event_submission.dart';
import 'package:mentality/features/waiting_event/_shared/domain/models/q_answer_set.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Un passe DEV non signé (`M2.<claims>`), la forme que `TokenAccount` accepte
/// sans vérification de signature.
String passe(String nonce) =>
    'M2.${base64Url.encode(utf8.encode(jsonEncode({'n': nonce})))}';

EventSubmission envoi(
  String moduleId, {
  int day = 3,
  bool partial = false,
  Map<String, int> answers = const {'i1': 2},
}) =>
    EventSubmission(
      moduleId: moduleId,
      day: day,
      kind: DayActivityKind.announced,
      locale: 'fr',
      partial: partial,
      answers: answers,
    );

/// La clé Hive EXACTE d'une soumission du passe courant. Chercher par simple
/// préfixe attraperait celle d'un autre passe laissée par un test précédent —
/// la box est partagée par tout le fichier.
Future<String> cleOutbox(String moduleId) async {
  final account =
      await TokenAccount.fromToken(await AuthLocalStore.instance.getToken());
  return 'outbox:$account:$moduleId';
}

void main() {
  late Directory tempDir;
  final store = EventLocalStore.instance;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('mentality_outbox_test');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  setUp(() async => AuthLocalStore.instance.clear());

  test('aller-retour : ce qui est déposé est ce qui sera rejoué', () async {
    await AuthLocalStore.instance.saveToken(passe('nonce-depot'));
    final depose = envoi('m1', partial: true, answers: {'i1': 3, 'i2': 0});

    await store.enqueue(depose);

    expect(await store.pending(), [depose],
        reason: 'la soumission relue doit être IDENTIQUE — un rejeu ne '
            're-dérive rien');
  });

  test('une soumission plus récente remplace la précédente du même module',
      () async {
    await AuthLocalStore.instance.saveToken(passe('nonce-remplace'));

    await store.enqueue(envoi('m1', partial: true, answers: {'i1': 1}));
    await store.enqueue(envoi('m1', answers: {'i1': 1, 'i2': 2, 'i3': 3}));

    final attente = await store.pending();
    expect(attente.length, 1,
        reason: 'un abandon suivi d\'une reprise complète ne doit pas envoyer '
            'deux fois');
    expect(attente.single.partial, isFalse);
    expect(attente.single.answers.length, 3);
  });

  test('plusieurs modules cohabitent dans la file', () async {
    await AuthLocalStore.instance.saveToken(passe('nonce-multi'));

    await store.enqueue(envoi('m1', day: 1));
    await store.enqueue(envoi('m3', day: 3));
    await store.enqueue(envoi('m6', day: 6));

    expect((await store.pending()).map((s) => s.moduleId).toSet(),
        {'m1', 'm3', 'm6'});
  });

  test('retirer un module ne touche pas les autres', () async {
    await AuthLocalStore.instance.saveToken(passe('nonce-retrait'));
    final m1 = envoi('m1');
    await store.enqueue(m1);
    await store.enqueue(envoi('m2'));

    expect(await store.removeIf(m1), isTrue);

    expect((await store.pending()).map((s) => s.moduleId), ['m2']);
  });

  test('removeIf REFUSE d\'effacer une soumission qui a été remplacée',
      () async {
    await AuthLocalStore.instance.saveToken(passe('nonce-compare'));
    final partiel = envoi('m1', partial: true, answers: {'i1': 1});
    final complet = envoi('m1', answers: {'i1': 1, 'i2': 2, 'i3': 3});

    await store.enqueue(partiel);
    await store.enqueue(complet); // l'utilisateur a terminé entre-temps

    expect(await store.removeIf(partiel), isFalse,
        reason: 'la confirmation du PARTIEL ne doit pas emporter le COMPLET');
    expect((await store.pending()).single, complet,
        reason: 'le jeu complet attend toujours son tour');

    expect(await store.removeIf(complet), isTrue);
    expect(await store.pending(), isEmpty);
  });

  test('removeIf d\'une entrée déjà absente réussit', () async {
    await AuthLocalStore.instance.saveToken(passe('nonce-absente'));

    expect(await store.removeIf(envoi('m1')), isTrue,
        reason: 'rien à retirer : la file est bien dans l\'état voulu');
  });

  test('enqueue DIT qu\'il n\'a rien écrit faute de passe', () async {
    expect(await store.enqueue(envoi('m1')), isFalse,
        reason: 'sans passe exploitable, l\'appelant doit savoir que sa '
            'soumission n\'est nulle part — sinon il prendrait son absence '
            'pour une confirmation');

    await AuthLocalStore.instance.saveToken(passe('nonce-enqueue-ok'));
    expect(await store.enqueue(envoi('m1')), isTrue);
  });

  test('la file d\'un passe est INVISIBLE pour un autre', () async {
    await AuthLocalStore.instance.saveToken(passe('nonce-alice'));
    await store.enqueue(envoi('m1', answers: {'i1': 3}));

    await AuthLocalStore.instance.saveToken(passe('nonce-bob'));
    expect(await store.pending(), isEmpty,
        reason: 'les réponses de santé d\'un passe ne doivent jamais partir '
            'sous l\'identité d\'un autre');

    await store.enqueue(envoi('m1', answers: {'i1': 0}));

    await AuthLocalStore.instance.saveToken(passe('nonce-alice'));
    expect((await store.pending()).single.answers, {'i1': 3},
        reason: 'chacun retrouve la sienne, intacte');
  });

  test('sans passe exploitable : rien n\'est écrit, rien n\'est lu', () async {
    await store.enqueue(envoi('m1'));

    expect(await store.pending(), isEmpty, reason: 'fail-closed');

    await AuthLocalStore.instance.saveToken(passe('nonce-apres'));
    expect(await store.pending(), isEmpty,
        reason: 'le dépôt sans passe n\'a été attribué à personne');
  });

  test('une entrée illisible est retirée, pas rejouée indéfiniment', () async {
    await AuthLocalStore.instance.saveToken(passe('nonce-abime'));
    await store.enqueue(envoi('m1'));
    await store.enqueue(envoi('m2'));

    // On abîme une entrée en place, comme le ferait une écriture interrompue.
    final box = Hive.box('mentality_waiting_event');
    final cle = await cleOutbox('m1');
    await box.put(cle, '{ceci n\'est pas du json');

    expect((await store.pending()).map((s) => s.moduleId), ['m2'],
        reason: 'ce qui ne partira jamais ne doit pas encombrer la file');
    expect(box.get(cle), isNull, reason: 'l\'entrée illisible a été purgée');
  });

  test('une entrée au cadrage inconnu est purgée, jamais devinée', () async {
    await AuthLocalStore.instance.saveToken(passe('nonce-cadrage'));
    await store.enqueue(envoi('m1'));

    final box = Hive.box('mentality_waiting_event');
    final cle = await cleOutbox('m1');
    final json = jsonDecode(box.get(cle) as String) as Map<String, dynamic>;
    await box.put(cle, jsonEncode({...json, 'kind': 'inventé'}));

    expect(await store.pending(), isEmpty,
        reason: 'envoyer un module sous un mauvais cadrage RGPD serait pire '
            'que ne pas l\'envoyer');
  });

  test('un refus est mémorisé et survit — sinon il disparaîtrait en silence',
      () async {
    await AuthLocalStore.instance.saveToken(passe('nonce-refus'));

    await store.markRefused('m1');

    expect(await store.refusedModules(), {'m1'});
  });

  test('les refus sont cloisonnés par passe, comme le reste', () async {
    await AuthLocalStore.instance.saveToken(passe('nonce-refus-alice'));
    await store.markRefused('m1');

    await AuthLocalStore.instance.saveToken(passe('nonce-refus-bob'));
    expect(await store.refusedModules(), isEmpty);
  });

  test('la file et les réponses du moteur ne se marchent pas dessus',
      () async {
    await AuthLocalStore.instance.saveToken(passe('nonce-espaces'));

    final reponses = const QAnswerSet(moduleId: 'm1').withAnswer('i1', 3);
    await store.save(reponses);
    final depot = envoi('m1');
    await store.enqueue(depot);

    expect(await store.load('m1'), reponses,
        reason: 'déposer un envoi n\'écrase pas le questionnaire en cours');

    await store.removeIf(depot);

    expect(await store.pending(), isEmpty);
    expect(await store.load('m1'), reponses,
        reason: 'vider la file d\'envoi n\'efface pas les réponses de '
            'l\'utilisateur : ce sont deux espaces de clés distincts');
  });
}
