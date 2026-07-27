// Le stockage des réponses de l'événement — chiffré, et cloisonné par passe.
//
// Même invariant que l'historique des sessions, sur une donnée plus sensible
// encore : ce sont des réponses de santé. Un passe ne doit JAMAIS voir celles
// d'un autre sur le même téléphone — sans quoi on reprendrait le questionnaire
// de quelqu'un d'autre, et ses réponses partiraient sous notre identité.
//
// Et sans passe exploitable : rien n'est lu, rien n'est écrit (fail-closed).

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mentality/core/services/auth_local_store.dart';
import 'package:mentality/features/waiting_event/_shared/data/event_local_store.dart';
import 'package:mentality/features/waiting_event/_shared/domain/models/q_answer_set.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Un passe DEV non signé (`M2.<claims>`), la forme que `TokenAccount` accepte
/// sans vérification de signature.
String passe(String nonce) =>
    'M2.${base64Url.encode(utf8.encode(jsonEncode({'n': nonce})))}';

void main() {
  late Directory tempDir;
  final store = EventLocalStore.instance;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('mentality_event_test');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  setUp(() async => AuthLocalStore.instance.clear());

  test('aller-retour : ce qu\'on écrit est ce qu\'on relit', () async {
    await AuthLocalStore.instance.saveToken(passe('nonce-aller-retour'));

    final reponses = const QAnswerSet(moduleId: 'm1')
        .withAnswer('i1', 3)
        .withAnswer('i2', 0);
    await store.save(reponses);

    expect(await store.load('m1'), reponses);
  });

  test('le statut « terminé » survit au stockage', () async {
    await AuthLocalStore.instance.saveToken(passe('nonce-statut'));

    await store.save(
        const QAnswerSet(moduleId: 'm2').withAnswer('i1', 1).markCompleted());

    final relu = await store.load('m2');
    expect(relu!.isPartial, isFalse);
    expect(relu.valueOf('i1'), 1);
  });

  test('un abandon se relit partiel, jamais terminé', () async {
    await AuthLocalStore.instance.saveToken(passe('nonce-abandon'));

    await store.save(const QAnswerSet(moduleId: 'm3').withAnswer('i1', 2));

    expect((await store.load('m3'))!.isPartial, isTrue);
  });

  test('les modules ne se mélangent pas entre eux', () async {
    await AuthLocalStore.instance.saveToken(passe('nonce-modules'));

    await store.save(const QAnswerSet(moduleId: 'jour1').withAnswer('a', 1));
    await store.save(const QAnswerSet(moduleId: 'jour3').withAnswer('b', 2));

    expect((await store.load('jour1'))!.valueOf('a'), 1);
    expect((await store.load('jour1'))!.valueOf('b'), isNull);
    expect((await store.load('jour3'))!.valueOf('b'), 2);
  });

  test('CLOISONNEMENT : un passe ne voit pas les réponses d\'un autre',
      () async {
    await AuthLocalStore.instance.saveToken(passe('nonce-A'));
    await store.save(const QAnswerSet(moduleId: 'partage').withAnswer('i1', 3));
    expect((await store.load('partage'))!.valueOf('i1'), 3);

    // Changement de passe sur le même téléphone.
    await AuthLocalStore.instance.saveToken(passe('nonce-B'));
    expect(await store.load('partage'), isNull,
        reason: 'B hériterait des réponses de santé de A');

    // B écrit les siennes, sans écraser celles de A.
    await store.save(const QAnswerSet(moduleId: 'partage').withAnswer('i1', 0));
    expect((await store.load('partage'))!.valueOf('i1'), 0);

    await AuthLocalStore.instance.saveToken(passe('nonce-A'));
    expect((await store.load('partage'))!.valueOf('i1'), 3,
        reason: 'les réponses de A doivent être intactes');
  });

  group('fail-closed — sans passe exploitable', () {
    test('aucune lecture', () async {
      expect(await store.load('m1'), isNull);
    });

    test('aucune écriture, et rien n\'apparaît au passe suivant', () async {
      await store
          .save(const QAnswerSet(moduleId: 'orphelin').withAnswer('i1', 2));

      await AuthLocalStore.instance.saveToken(passe('nonce-apres'));
      expect(await store.load('orphelin'), isNull,
          reason: 'une écriture sans passe ne doit être attribuée à personne');
    });

    test('un passe malformé ne vaut pas un passe', () async {
      await AuthLocalStore.instance.saveToken('pas-un-token');
      expect(await store.load('m1'), isNull);
    });
  });

  test('une entrée illisible ne bloque pas la journée', () async {
    await AuthLocalStore.instance.saveToken(passe('nonce-abime'));
    // On écrit directement du contenu corrompu sous la clé du passe courant.
    await store.save(const QAnswerSet(moduleId: 'abime').withAnswer('i1', 1));
    final box = Hive.box('mentality_waiting_event');
    final cle = box.keys.firstWhere((k) => k.toString().endsWith(':abime'));
    await box.put(cle, '{ceci n\'est pas du json');

    expect(await store.load('abime'), isNull,
        reason: 'on repart d\'un questionnaire vierge plutôt que de planter');
  });

  test('clear efface le module visé, et lui seul', () async {
    await AuthLocalStore.instance.saveToken(passe('nonce-clear'));
    await store.save(const QAnswerSet(moduleId: 'a').withAnswer('i1', 1));
    await store.save(const QAnswerSet(moduleId: 'b').withAnswer('i1', 1));

    await store.clear('a');
    expect(await store.load('a'), isNull);
    expect(await store.load('b'), isNotNull);
  });
}
