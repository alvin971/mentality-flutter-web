// L'auto-estimation du QI : posée une fois, gardée sur l'appareil.
//
// Trois propriétés font toute sa valeur, et chacune se casse silencieusement :
//
// · ÉCRITURE UNIQUE — une seconde estimation serait donnée APRÈS une
//   révélation, donc ancrée par elle. Rien à l'écran ne trahirait la
//   substitution : le nombre du jour 8 serait simplement faux.
// · LE REFUS EST UNE RÉPONSE — sans lui, la question revient à chaque
//   ouverture du jour 1 jusqu'à ce qu'on réponde n'importe quoi.
// · RIEN NE SORT — aucun consentement art. 9 n'a encore été recueilli, donc
//   cette valeur n'a pas le droit de rejoindre la file d'envoi. La dernière
//   garde du fichier le vérifie sur un stockage qui EST aussi une file.

import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/features/waiting_event/_shared/data/event_local_store.dart';
import 'package:mentality/features/waiting_event/_shared/domain/models/event_submission.dart';
import 'package:mentality/features/waiting_event/_shared/domain/models/q_answer_set.dart';
import 'package:mentality/features/waiting_event/_shared/domain/services/event_schedule.dart';
import 'package:mentality/features/waiting_event/_shared/domain/services/q_module_registry.dart';
import 'package:mentality/features/waiting_event/reveals/data/self_estimate_store.dart';

/// Un stockage en mémoire qui est AUSSI une file d'envoi — comme
/// `EventLocalStore` en production. C'est ce cumul qui rend la garde « rien ne
/// sort » significative : si l'estimation touchait la file, elle le ferait ici.
class StoreMemoire implements EventAnswerStore, EventOutbox {
  final Map<String, QAnswerSet> reponses = {};
  final Map<String, EventSubmission> file = {};
  final Set<String> refuses = {};

  @override
  Future<QAnswerSet?> load(String moduleId) async => reponses[moduleId];

  @override
  Future<void> save(QAnswerSet answers) async =>
      reponses[answers.moduleId] = answers;

  @override
  Future<void> clear(String moduleId) async => reponses.remove(moduleId);

  @override
  Future<bool> enqueue(EventSubmission submission) async {
    file[submission.moduleId] = submission;
    return true;
  }

  @override
  Future<List<EventSubmission>> pending() async => file.values.toList();

  @override
  Future<bool> removeIf(EventSubmission envoyee) async =>
      file.remove(envoyee.moduleId) != null;

  @override
  Future<void> markRefused(String moduleId) async => refuses.add(moduleId);

  @override
  Future<Set<String>> refusedModules() async => refuses;
}

void main() {
  late StoreMemoire store;
  late SelfEstimateStore estimation;

  setUp(() {
    store = StoreMemoire();
    estimation = SelfEstimateStore(store);
  });

  group('état initial', () {
    test('tant que rien n\'a été demandé, la question est ouverte', () async {
      final lue = await estimation.read();
      expect(lue.value, isNull);
      expect(lue.declined, isFalse);
      expect(lue.isSettled, isFalse);
    });
  });

  group('une estimation donnée', () {
    test('se relit à l\'identique', () async {
      expect(await estimation.record(118), isTrue);
      final lue = await estimation.read();
      expect(lue.value, 118);
      expect(lue.declined, isFalse);
      expect(lue.isSettled, isTrue);
    });

    test('ne peut PAS être remplacée — la seconde serait ancrée', () async {
      await estimation.record(118);
      expect(await estimation.record(95), isFalse,
          reason: 'une réécriture doit être refusée, pas silencieusement '
              'acceptée');
      expect((await estimation.read()).value, 118);
    });

    test('ne peut pas être effacée par un refus tardif', () async {
      await estimation.record(118);
      expect(await estimation.record(null), isFalse);
      final lue = await estimation.read();
      expect(lue.value, 118);
      expect(lue.declined, isFalse);
    });

    test('est refusée hors des bornes de l\'échelle proposée', () async {
      expect(await estimation.record(SelfEstimateStore.minValue - 1), isFalse);
      expect(await estimation.record(SelfEstimateStore.maxValue + 1), isFalse);
      expect(await estimation.record(0), isFalse);
      expect((await estimation.read()).isSettled, isFalse,
          reason: 'une valeur aberrante ne doit pas clore la question');
    });

    test('accepte les deux bornes elles-mêmes', () async {
      expect(await estimation.record(SelfEstimateStore.minValue), isTrue);
      expect((await estimation.read()).value, SelfEstimateStore.minValue);

      final autre = SelfEstimateStore(StoreMemoire());
      expect(await autre.record(SelfEstimateStore.maxValue), isTrue);
      expect((await autre.read()).value, SelfEstimateStore.maxValue);
    });
  });

  group('un refus', () {
    test('clôt la question sans inventer de nombre', () async {
      expect(await estimation.record(null), isTrue);
      final lue = await estimation.read();
      expect(lue.value, isNull);
      expect(lue.declined, isTrue);
      expect(lue.isSettled, isTrue,
          reason: 'sans cela, la question reviendrait indéfiniment');
    });

    test('ne se transforme pas en estimation par une seconde ouverture',
        () async {
      await estimation.record(null);
      expect(await estimation.record(130), isFalse);
      expect((await estimation.read()).value, isNull);
    });

    test('n\'est jamais relu comme une valeur', () async {
      await estimation.record(null);
      final brut = store.reponses[SelfEstimateStore.moduleId]!;
      expect(brut.valueOf(SelfEstimateStore.estimateItemId), isNull,
          reason: 'le refus doit vivre sous SA propre clé');
      expect(brut.valueOf(SelfEstimateStore.declinedItemId), isNotNull);
    });
  });

  group('stockage corrompu', () {
    test('une valeur hors bornes déjà sur le disque ne se lit pas', () async {
      await store.save(QAnswerSet(moduleId: SelfEstimateStore.moduleId)
          .withAnswer(SelfEstimateStore.estimateItemId, 9999)
          .markCompleted());
      final lue = await estimation.read();
      expect(lue.value, isNull);
      expect(lue.isSettled, isFalse,
          reason: 'une donnée corrompue rouvre la question, elle ne la fige pas');
    });
  });

  group('GARDE art. 9 : l\'estimation ne quitte pas l\'appareil', () {
    test('ni une estimation ni un refus n\'entrent dans la file d\'envoi',
        () async {
      await estimation.record(118);
      expect(await store.pending(), isEmpty,
          reason: 'aucun consentement santé n\'a été recueilli à ce stade');

      final autreStore = StoreMemoire();
      await SelfEstimateStore(autreStore).record(null);
      expect(await autreStore.pending(), isEmpty);
      expect(await autreStore.refusedModules(), isEmpty);
    });

    test('elle ne se déclare pas comme un module du programme', () {
      // L'identifiant de stockage n'est pas une journée. S'il était un jour
      // enregistré dans le registre, il deviendrait le questionnaire d'une
      // journée : le hub l'ouvrirait dans le moteur, la garde de volume
      // (40-50 questions) le refuserait, et surtout ses réponses partiraient
      // dans la file d'envoi. Cette garde interroge le VRAI registre plutôt
      // que la forme du slug.
      expect(
        QModuleRegistry.modules.map((m) => m.id),
        isNot(contains(SelfEstimateStore.moduleId)),
      );
      for (var jour = 1; jour <= EventSchedule.totalDays; jour++) {
        expect(QModuleRegistry.forDay(jour)?.id,
            isNot(SelfEstimateStore.moduleId),
            reason: 'le jour $jour ouvrirait l\'auto-estimation comme un test');
      }
    });
  });

  group('GARDE écriture unique : deux appels simultanés', () {
    test('le second n\'écrase pas le premier', () async {
      // Sans sérialisation, les deux `record` lisent une question ouverte
      // AVANT que l'un ait sauvegardé, et le second écrase le premier : la
      // valeur rendue au jour 8 serait la seconde, sans que rien ne le
      // signale. Un stockage lent rend la fenêtre observable.
      final lent = StoreLent(const Duration(milliseconds: 20));
      final store = SelfEstimateStore(lent);

      final resultats =
          await Future.wait([store.record(118), store.record(95)]);

      expect(resultats.where((ok) => ok).length, 1,
          reason: 'un seul des deux appels doit avoir écrit');
      expect((await store.read()).value, 118,
          reason: 'la PREMIÈRE réponse est la seule — la seconde serait ancrée');
    });

    test('une écriture en échec laisse la question ouverte, et le dit',
        () async {
      final casse = StorePanne();
      final store = SelfEstimateStore(casse);

      expect(await store.record(118), isFalse,
          reason: 'rien n\'a été écrit : l\'appelant doit l\'apprendre');
      expect((await store.read()).isSettled, isFalse);

      // La file ne doit pas rester bloquée par l'échec précédent.
      casse.enPanne = false;
      expect(await store.record(118), isTrue);
      expect((await store.read()).value, 118);
    });
  });
}

/// Stockage volontairement lent : c'est la latence qui ouvre la fenêtre entre
/// la lecture et l'écriture de `record`.
class StoreLent implements EventAnswerStore {
  StoreLent(this.delai);

  final Duration delai;
  final Map<String, QAnswerSet> data = {};

  @override
  Future<QAnswerSet?> load(String moduleId) async {
    await Future<void>.delayed(delai);
    return data[moduleId];
  }

  @override
  Future<void> save(QAnswerSet answers) async {
    await Future<void>.delayed(delai);
    data[answers.moduleId] = answers;
  }

  @override
  Future<void> clear(String moduleId) async => data.remove(moduleId);
}

/// Stockage qui refuse d'écrire — l'incident de disque, pas l'hypothèse.
class StorePanne implements EventAnswerStore {
  bool enPanne = true;
  final Map<String, QAnswerSet> data = {};

  @override
  Future<QAnswerSet?> load(String moduleId) async => data[moduleId];

  @override
  Future<void> save(QAnswerSet answers) async {
    if (enPanne) throw StateError('disque indisponible');
    data[answers.moduleId] = answers;
  }

  @override
  Future<void> clear(String moduleId) async => data.remove(moduleId);
}
