// Le stockage du questionnaire préalable — au niveau de la donnée.
//
// Ce qui se vérifie ici et nulle part ailleurs : l'écriture unique (la question
// ne se repose jamais), le cloisonnement des deux branches (un score rapporté
// ne doit JAMAIS finir dans la case de l'estimation), l'absence de sentinelle
// pour une question passée, et la garde art. 9 — rien de tout cela n'entre
// dans la file d'envoi.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/features/complete_test/data/pretest_store.dart';
import 'package:mentality/features/complete_test/domain/models/pretest_answers.dart';
import 'package:mentality/features/waiting_event/_shared/data/event_local_store.dart';
import 'package:mentality/features/waiting_event/_shared/domain/models/event_submission.dart';
import 'package:mentality/features/waiting_event/_shared/domain/models/q_answer_set.dart';
import 'package:mentality/features/waiting_event/reveals/data/self_estimate_store.dart';

/// Stockage en mémoire — réponses ET file d'envoi, pour pouvoir vérifier que
/// la seconde reste vide.
class StoreMemoire implements EventAnswerStore, EventOutbox {
  final Map<String, QAnswerSet> data = {};
  final Map<String, EventSubmission> file = {};
  final Set<String> refuses = {};
  int ecritures = 0;

  @override
  Future<QAnswerSet?> load(String moduleId) async => data[moduleId];

  @override
  Future<void> save(QAnswerSet answers) async {
    data[answers.moduleId] = answers;
    ecritures++;
  }

  @override
  Future<void> clear(String moduleId) async => data.remove(moduleId);

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

/// Stockage qui refuse d'écrire — le disque plein, la box verrouillée.
class StorePanne implements EventAnswerStore {
  @override
  Future<QAnswerSet?> load(String moduleId) async => null;

  @override
  Future<void> save(QAnswerSet answers) async =>
      throw StateError('disque indisponible');

  @override
  Future<void> clear(String moduleId) async {}
}

/// Stockage dont la LECTURE échoue — le cas où l'on ne sait pas si la question
/// a déjà été posée.
class StoreLectureCassee implements EventAnswerStore {
  @override
  Future<QAnswerSet?> load(String moduleId) async =>
      throw StateError('box illisible');

  @override
  Future<void> save(QAnswerSet answers) async {}

  @override
  Future<void> clear(String moduleId) async {}
}

const pro = PretestAnswers(
  priorTest: PriorIqTest.professional,
  ageAtTest: 12,
  priorScore: 128,
);

void main() {
  late StoreMemoire disque;
  late PretestStore pretest;

  setUp(() {
    disque = StoreMemoire();
    pretest = PretestStore(store: disque);
  });

  Map<String, int> items() =>
      disque.data[PretestStore.moduleId]?.answers ?? const {};

  group('la question obligatoire', () {
    test('s\'écrit avec un code, jamais avec un 0', () async {
      expect(await pretest.record(const PretestAnswers(priorTest: PriorIqTest.professional)),
          isTrue);
      expect(items()[PretestAnswers.itemPriorTest], 1,
          reason: 'zéro est ce que produit un champ vide ou un parse raté : '
              'aucune modalité réelle ne doit porter cette valeur');
    });

    test('distingue les trois modalités', () async {
      final codes = <int>{};
      for (final choix in PriorIqTest.values) {
        final d = StoreMemoire();
        await PretestStore(store: d).record(PretestAnswers(priorTest: choix));
        codes.add(d.data[PretestStore.moduleId]!
            .answers[PretestAnswers.itemPriorTest]!);
      }
      expect(codes, {1, 2, 3});
    });

    test('se relit telle qu\'elle a été écrite', () async {
      await pretest.record(pro);
      final lu = await pretest.read();
      expect(lu.answers, pro);
      expect(lu.isSettled, isTrue);
    });
  });

  group('les questions facultatives', () {
    test('passées, n\'écrivent AUCUNE clé — pas de sentinelle', () async {
      await pretest.record(const PretestAnswers(priorTest: PriorIqTest.professional));
      expect(items().containsKey(PretestAnswers.itemAgeAtTest), isFalse);
      expect(items().containsKey(PretestAnswers.itemPriorScore), isFalse,
          reason: 'un 0 ou un -1 finirait tôt ou tard dans une moyenne');
    });

    test('hors bornes, sont refusées plutôt que ramenées à la borne', () async {
      await pretest.record(const PretestAnswers(
        priorTest: PriorIqTest.professional,
        ageAtTest: 2,
        priorScore: 999,
      ));
      expect(items().containsKey(PretestAnswers.itemAgeAtTest), isFalse);
      expect(items().containsKey(PretestAnswers.itemPriorScore), isFalse,
          reason: 'ramener 999 à 200 inventerait un score que personne '
              'n\'a obtenu');
    });

    test('aux bornes exactes, passent', () async {
      await pretest.record(const PretestAnswers(
        priorTest: PriorIqTest.professional,
        ageAtTest: PretestAnswers.minAge,
        priorScore: PretestAnswers.maxScore,
      ));
      expect(items()[PretestAnswers.itemAgeAtTest], PretestAnswers.minAge);
      expect(items()[PretestAnswers.itemPriorScore], PretestAnswers.maxScore);
    });
  });

  group('écriture unique', () {
    test('une seconde réponse est refusée et ne modifie rien', () async {
      expect(await pretest.record(pro), isTrue);
      final avant = Map<String, int>.from(items());

      expect(
          await pretest.record(
              const PretestAnswers(priorTest: PriorIqTest.never)),
          isFalse,
          reason: 'la question ne se repose jamais : une seconde réponse '
              'serait postérieure à un score connu');
      expect(items(), avant);
    });

    test('deux appuis concurrents n\'écrivent qu\'une fois', () async {
      final resultats = await Future.wait([
        pretest.record(pro),
        pretest.record(const PretestAnswers(priorTest: PriorIqTest.never)),
      ]);
      expect(resultats.where((ok) => ok).length, 1);
      expect(disque.ecritures, 1);
    });
  });

  group('l\'auto-estimation', () {
    test('part dans SON stockage, jamais dans les items du préalable',
        () async {
      await pretest.record(
        const PretestAnswers(priorTest: PriorIqTest.never),
        askedEstimate: true,
        estimate: 118,
      );

      expect(items().values, isNot(contains(118)),
          reason: 'une croyance et une mesure ne partagent pas une case');
      final estimation = await SelfEstimateStore(disque).read();
      expect(estimation.value, 118);
    });

    test('n\'est pas touchée sur la branche « chez un professionnel »',
        () async {
      await pretest.record(pro);
      expect(disque.data[SelfEstimateStore.moduleId], isNull,
          reason: 'qui connaît son score répondrait avec ce score : la '
              'question n\'a pas été posée, rien ne doit être écrit');
      expect((await pretest.read()).estimate.isSettled, isFalse);
    });

    test('refusée, clôt la question sans inventer de nombre', () async {
      await pretest.record(
        const PretestAnswers(priorTest: PriorIqTest.online),
        askedEstimate: true,
        estimate: null,
      );
      final lu = await pretest.read();
      expect(lu.estimate.value, isNull);
      expect(lu.estimate.declined, isTrue);
      expect(lu.estimate.isSettled, isTrue,
          reason: 'sans refus explicite, la question reviendrait sans fin');
    });

    test('ne se repose pas si elle a déjà été donnée ailleurs', () async {
      // Le programme des 8 jours pose la même question ; s'il est rallumé un
      // jour, il doit trouver la question DÉJÀ close.
      await pretest.record(
        const PretestAnswers(priorTest: PriorIqTest.never),
        askedEstimate: true,
        estimate: 105,
      );
      expect(await SelfEstimateStore(disque).record(130), isFalse);
      expect((await SelfEstimateStore(disque).read()).value, 105);
    });
  });

  group('stockage en panne', () {
    test('une écriture en échec laisse la question ouverte', () async {
      final casse = PretestStore(store: StorePanne());
      expect(await casse.record(pro), isFalse,
          reason: 'mieux vaut reposer la question que faire croire à un '
              'enregistrement qui n\'a pas eu lieu');
      expect((await casse.read()).isSettled, isFalse);
    });

    test('une lecture en échec vaut « question ouverte », pas une erreur',
        () async {
      final lu = await PretestStore(store: StoreLectureCassee()).read();
      expect(lu.isSettled, isFalse,
          reason: 'un stockage indisponible ne doit pas empêcher de passer '
              'le test');
    });
  });

  group('stockage corrompu', () {
    test('une entrée sans la question obligatoire rouvre la question',
        () async {
      await disque.save(QAnswerSet(moduleId: PretestStore.moduleId)
          .withAnswer(PretestAnswers.itemPriorScore, 120)
          .markCompleted());
      expect((await pretest.read()).isSettled, isFalse);
    });

    test('un code de modalité inconnu rouvre la question', () async {
      await disque.save(QAnswerSet(moduleId: PretestStore.moduleId)
          .withAnswer(PretestAnswers.itemPriorTest, 42)
          .markCompleted());
      expect((await pretest.read()).isSettled, isFalse);
    });

    test('une valeur facultative hors bornes déjà sur le disque est ignorée, '
        'sans rouvrir la question', () async {
      await disque.save(QAnswerSet(moduleId: PretestStore.moduleId)
          .withAnswer(PretestAnswers.itemPriorTest, 1)
          .withAnswer(PretestAnswers.itemPriorScore, 9999)
          .markCompleted());
      final lu = await pretest.read();
      expect(lu.isSettled, isTrue);
      expect(lu.answers!.priorScore, isNull);
    });
  });

  group('GARDE art. 9 : rien ne quitte l\'appareil', () {
    test('aucune réponse n\'entre dans la file d\'envoi', () async {
      await pretest.record(pro);
      await PretestStore(store: disque).record(
        const PretestAnswers(priorTest: PriorIqTest.never),
        askedEstimate: true,
        estimate: 118,
      );

      expect(await disque.pending(), isEmpty,
          reason: '« oui, avec un psychiatre ou un psychologue » révèle un '
              'contact avec un professionnel de santé mentale : aucun '
              'consentement art. 9 n\'est recueilli sur le parcours du test, '
              'donc rien n\'a le droit de sortir');
      expect(await disque.refusedModules(), isEmpty);
    });
  });

  group('GARDE : deux fichiers de l\'événement sont devenus obligatoires', () {
    test('ils ne peuvent plus disparaître avec l\'événement', () {
      // `waiting_event/` est ÉTEINT mais pas supprimé, et sa suppression était
      // jusqu'ici sans conséquence pour le reste de l'app. Ce n'est plus vrai :
      // le questionnaire préalable est sur le chemin OBLIGATOIRE du test et
      // s'appuie sur ces deux fichiers. Les effacer casserait le démarrage de
      // la batterie — pas une fonctionnalité mise de côté.
      for (final chemin in const [
        'lib/features/waiting_event/_shared/data/event_local_store.dart',
        'lib/features/waiting_event/reveals/data/self_estimate_store.dart',
      ]) {
        expect(File(chemin).existsSync(), isTrue,
            reason: '$chemin porte le questionnaire préalable : il ne fait '
                'plus partie du code mis de côté');
      }
    });
  });
}
