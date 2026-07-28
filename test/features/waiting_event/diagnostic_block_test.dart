// Le bloc diagnostic — ce qui est écrit, ce qui part, et ce qui ne part pas.
//
// Ce fichier ne vérifie pas des écrans : il vérifie une DONNÉE. Le bloc n'a
// aucune valeur pour la personne qui le remplit — il n'affiche ni score ni
// résultat —, sa seule justification est la qualité de ce qu'il produit. Une
// clé renommée, une cotation décalée d'un rang, un « aucun » qui coexisterait
// avec un trouble coché : rien de tout cela ne changerait un pixel, et tout
// cela rendrait le corpus inexploitable.

import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/features/waiting_event/_shared/data/event_local_store.dart';
import 'package:mentality/features/waiting_event/_shared/domain/models/event_day.dart';
import 'package:mentality/features/waiting_event/_shared/domain/models/event_submission.dart';
import 'package:mentality/features/waiting_event/_shared/domain/models/q_answer_set.dart';
import 'package:mentality/features/waiting_event/_shared/domain/services/q_module_registry.dart';
import 'package:mentality/features/waiting_event/diagnostic_block/data/diagnostic_block_store.dart';
import 'package:mentality/features/waiting_event/diagnostic_block/domain/models/diagnostic_answers.dart';

class StoreMemoire implements EventAnswerStore {
  final Map<String, QAnswerSet> data = {};

  @override
  Future<QAnswerSet?> load(String moduleId) async => data[moduleId];

  @override
  Future<void> save(QAnswerSet answers) async => data[answers.moduleId] = answers;

  @override
  Future<void> clear(String moduleId) async => data.remove(moduleId);
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

/// Stockage lent : la latence est ce qui ouvre la fenêtre du double appui.
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

DiagnosticDetail detail({
  DxSource source = DxSource.psychiatrist,
  DxRecency recency = DxRecency.from1to3Years,
  DxTreatment treatment = DxTreatment.current,
  DxAssessment assessment = DxAssessment.yes,
}) =>
    DiagnosticDetail(
      source: source,
      recency: recency,
      treatment: treatment,
      assessment: assessment,
    );

void main() {
  group('encodage — le contrat de données', () {
    test('une déclaration produit exactement les clés attendues', () {
      final answers = DiagnosticAnswers.declared({
        DxCondition.adhd: detail(
          source: DxSource.psychiatrist,
          recency: DxRecency.from3to10Years,
          treatment: DxTreatment.past,
          assessment: DxAssessment.yes,
        ),
        DxCondition.dyslexia: detail(
          source: DxSource.selfSuspected,
          recency: DxRecency.unknown,
          treatment: DxTreatment.none,
          assessment: DxAssessment.unknown,
        ),
      });

      expect(answers.toAnswers(), {
        'dx.adhd': 1,
        'dx.adhd.source': 1, // psychiatrist
        'dx.adhd.recency': 3, // from3to10Years
        'dx.adhd.treatment': 3, // past
        'dx.adhd.assessment': 1, // yes
        'dx.dyslexia': 1,
        'dx.dyslexia.source': 4, // selfSuspected
        'dx.dyslexia.recency': 5, // unknown
        'dx.dyslexia.treatment': 2, // none
        'dx.dyslexia.assessment': 3, // unknown
      });
    });

    test('aucune cotation ne vaut 0', () {
      // Dans une carte d'entiers, un 0 ne se distingue pas d'une valeur par
      // défaut qu'on aurait laissée passer : toutes les modalités partent à 1.
      final toutes = DiagnosticAnswers.declared({
        for (final c in DxCondition.values) c: detail(),
      }).toAnswers();

      expect(toutes.values.every((v) => v >= 1), isTrue);
      expect(toutes.length, DxCondition.values.length * 5);
    });

    test('la carte ne dépend pas de l\'ordre où les cases ont été cochées', () {
      final a = DiagnosticAnswers.declared({
        DxCondition.burnout: detail(),
        DxCondition.adhd: detail(),
      }).toAnswers();
      final b = DiagnosticAnswers.declared({
        DxCondition.adhd: detail(),
        DxCondition.burnout: detail(),
      }).toAnswers();

      expect(a.keys.toList(), b.keys.toList(),
          reason: 'deux personnes ayant coché les mêmes cases doivent produire '
              'la même carte, sinon rien ne se compare');
    });

    test('« aucun » et le refus sont des réponses, pas des vides', () {
      expect(DiagnosticAnswers.none.toAnswers(), {'none': 1});
      expect(DiagnosticAnswers.declined.toAnswers(), {'declined': 1});
    });

    test('un refus ne se confond jamais avec « aucun »', () {
      // Le distinguo n'est pas une politesse : « aucun » entre dans le groupe
      // témoin, le refus en est exclu. Les confondre remplirait le témoin de
      // personnes concernées, et l'échelle qu'on en tire ne séparerait plus
      // rien.
      expect(
        DiagnosticAnswers.fromAnswers({'declined': 1})!.isNone,
        isFalse,
      );
      expect(
        DiagnosticAnswers.fromAnswers({'none': 1})!.isDeclined,
        isFalse,
      );
    });

    test('la carte se relit à l\'identique', () {
      final origine = DiagnosticAnswers.declared({
        DxCondition.autism: detail(
          source: DxSource.psychologist,
          recency: DxRecency.under1Year,
          treatment: DxTreatment.none,
          assessment: DxAssessment.no,
        ),
      });

      expect(DiagnosticAnswers.fromAnswers(origine.toAnswers()), origine);
    });

    test('une carte à trous est rejetée, pas devinée', () {
      // Un trouble coché dont le détail manque : le relire « à moitié »
      // l'enverrait dans le groupe critère sans qu'on sache si le diagnostic
      // vient d'un spécialiste ou d'une intuition.
      expect(
        DiagnosticAnswers.fromAnswers({'dx.adhd': 1, 'dx.adhd.source': 1}),
        isNull,
      );
      expect(DiagnosticAnswers.fromAnswers(const {}), isNull);
    });

    test('une cotation hors barème est rejetée', () {
      final carte = DiagnosticAnswers.declared({DxCondition.ocd: detail()})
          .toAnswers();
      expect(
        DiagnosticAnswers.fromAnswers({...carte, 'dx.ocd.source': 9}),
        isNull,
      );
      expect(
        DiagnosticAnswers.fromAnswers({...carte, 'dx.ocd.recency': 0}),
        isNull,
      );
    });

    test('rien dans la déclaration ne ressemble à un horodatage', () {
      // Le programme ne lit jamais l'horloge locale, et une donnée de santé
      // horodatée finement est un quasi-identifiant. Seul le worker posera une
      // date, au jour.
      final carte = DiagnosticAnswers.declared({
        for (final c in DxCondition.values) c: detail(),
      }).toAnswers();

      for (final cle in carte.keys) {
        expect(
          RegExp(r'time|date|year|stamp|at$').hasMatch(cle.toLowerCase()),
          isFalse,
          reason: '« $cle » ressemble à un horodatage',
        );
      }
      // L'ancienneté part en TRANCHES, jamais en année : aucune valeur ne peut
      // donc être une année.
      expect(carte.values.every((v) => v < 100), isTrue);
    });
  });

  group('écriture — une seule fois, tout ou rien', () {
    late StoreMemoire disque;
    late List<EventSubmission> envois;
    late DiagnosticBlockStore store;

    setUp(() {
      disque = StoreMemoire();
      envois = [];
      store = DiagnosticBlockStore(
        store: disque,
        submit: (s) async => envois.add(s),
      );
    });

    test('la première déclaration est écrite ET confiée à l\'envoi', () async {
      final ecrit = await store.record(
        DiagnosticAnswers.declared({DxCondition.adhd: detail()}),
        locale: 'fr',
      );

      expect(ecrit, isTrue);
      expect(await store.isRecorded(), isTrue);
      expect(envois, hasLength(1));
    });

    test('la seconde est refusée, sans rien écraser ni rien renvoyer',
        () async {
      await store.record(DiagnosticAnswers.none, locale: 'fr');
      final deuxieme = await store.record(
        DiagnosticAnswers.declared({DxCondition.adhd: detail()}),
        locale: 'fr',
      );

      expect(deuxieme, isFalse);
      expect((await store.read())!.isNone, isTrue,
          reason: 'la première réponse est la seule : posée plus tard, la '
              'seconde serait amorcée par les dépistages des jours suivants');
      expect(envois, hasLength(1));
    });

    test('deux appuis simultanés n\'écrivent qu\'une fois', () async {
      // L'écriture ouvre une box chiffrée : plusieurs centaines de
      // millisecondes pendant lesquelles un second appel voit encore une
      // question ouverte. Le verrou REFUSE, il ne met pas en file.
      final lent = StoreLent(const Duration(milliseconds: 50));
      final concurrent = DiagnosticBlockStore(
        store: lent,
        submit: (s) async => envois.add(s),
      );

      final issues = await Future.wait([
        concurrent.record(DiagnosticAnswers.none, locale: 'fr'),
        concurrent.record(DiagnosticAnswers.declined, locale: 'fr'),
      ]);

      expect(issues.where((ok) => ok), hasLength(1));
      expect(envois, hasLength(1));
    });

    test('une écriture en échec ne renvoie rien et ne dit pas « c\'est fait »',
        () async {
      final casse = DiagnosticBlockStore(
        store: StorePanne(),
        submit: (s) async => envois.add(s),
      );

      final ecrit = await casse.record(
        DiagnosticAnswers.declared({DxCondition.anxiety: detail()}),
        locale: 'fr',
      );

      expect(ecrit, isFalse);
      expect(envois, isEmpty,
          reason: 'envoyer ce qu\'on n\'a pas su garder rendrait le rejeu '
              'impossible : la file serait la seule copie, et elle n\'existe '
              'pas');
    });

    test('un stockage illisible laisse la question ouverte', () async {
      final casse = DiagnosticBlockStore(store: StorePanne());
      expect(await casse.isRecorded(), isFalse);
    });
  });

  group('envoi — le cadrage qui voyage', () {
    test('la déclaration part au jour 1, en contribution, jamais partielle',
        () async {
      final envois = <EventSubmission>[];
      final store = DiagnosticBlockStore(
        store: StoreMemoire(),
        submit: (s) async => envois.add(s),
      );

      await store.record(
        DiagnosticAnswers.declared({DxCondition.hpi: detail()}),
        locale: 'de',
      );

      final envoi = envois.single;
      expect(envoi.moduleId, 'diagnostic_block');
      expect(envoi.day, 1,
          reason: 'posé à la fin du jour 1, il ne peut plus contaminer le '
              'dépistage autisme du jour 7');
      expect(envoi.kind, DayActivityKind.contribution,
          reason: 'aucun score n\'est affiché : le cadrage RGPD qui voyage '
              'doit être celui-là');
      expect(envoi.partial, isFalse);
      expect(envoi.locale, 'de');
    });

    test('la langue de passation ne fuit pas d\'une déclaration à l\'autre',
        () async {
      // Deux stores, deux langues : une langue mémorisée en statique
      // s'échapperait de l'un vers l'autre.
      final envois = <EventSubmission>[];
      Future<void> capter(EventSubmission s) async => envois.add(s);

      await DiagnosticBlockStore(store: StoreMemoire(), submit: capter)
          .record(DiagnosticAnswers.none, locale: 'pt');
      await DiagnosticBlockStore(store: StoreMemoire(), submit: capter)
          .record(DiagnosticAnswers.declined, locale: 'es');

      expect(envois.map((s) => s.locale), ['pt', 'es']);
    });
  });

  group('le bloc n\'est pas un module du programme', () {
    test('il n\'apparaît dans aucune journée du registre', () {
      // S'il y entrait, il compterait dans la règle des 40-50 questions et
      // s'ouvrirait par le moteur de questionnaire — qui ne sait pas poser une
      // liste à cocher.
      expect(
        QModuleRegistry.modules
            .any((m) => m.id == DiagnosticAnswers.moduleId),
        isFalse,
      );
      expect(QModuleRegistry.forDay(DiagnosticBlockStore.day)?.id,
          isNot(DiagnosticAnswers.moduleId));
    });
  });
}
