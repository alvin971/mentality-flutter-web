// L'envoi des réponses de l'événement : durable, rejoué, et jamais sans
// consentement.
//
// Ce fichier existe à cause d'un bug réel. Le crédit de parrainage partait
// « tire et oublie » depuis un écran facultatif : toute panne le perdait POUR
// TOUJOURS, en silence, et personne ne s'en apercevait. Une réponse de
// questionnaire coûte plus cher encore à celui qui l'a donnée. Les tests
// ci-dessous verrouillent donc les trois propriétés qui empêchent ce scénario
// de se reproduire :
//
//   1. la soumission est DÉPOSÉE avant toute tentative réseau, et ne sort de
//      la file que sur confirmation (ou sur refus définitif) ;
//   2. les issues sont DISTINGUÉES — confirmé / refusé / injoignable — et une
//      seule des trois efface la donnée sans laisser de trace ;
//   3. le consentement art. 9 est relu AVANT CHAQUE envoi, rejeu compris.
//
// Aucun réseau : le transport est une interface étroite, et ce que les tests
// scénarisent, c'est la SUITE DES ISSUES, pas des enveloppes HTTP.

import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/features/waiting_event/_shared/data/event_local_store.dart';
import 'package:mentality/features/waiting_event/_shared/data/event_upload_service.dart';
import 'package:mentality/features/waiting_event/_shared/domain/models/event_day.dart';
import 'package:mentality/features/waiting_event/_shared/domain/models/event_submission.dart';
import 'package:mentality/features/waiting_event/_shared/domain/models/q_answer_set.dart';
import 'package:mentality/features/waiting_event/_shared/domain/models/q_instrument.dart';
import 'package:mentality/features/waiting_event/_shared/domain/models/q_item.dart';
import 'package:mentality/features/waiting_event/_shared/domain/models/q_module.dart';
import 'package:mentality/features/waiting_event/_shared/domain/models/q_scale.dart';
import 'package:mentality/features/waiting_event/_shared/domain/models/q_text.dart';

// ─── Doublures ───────────────────────────────────────────────────────────────

QText t(String s) => QText(fr: s, en: s, enGB: s, de: s, es: s, pt: s);

final echelle = QScale(
  id: 'e4',
  options: [for (var v = 0; v <= 3; v++) QScaleOption(value: v, label: t('o$v'))],
);

QModule moduleFactice({
  int day = 3,
  DayActivityKind kind = DayActivityKind.announced,
}) =>
    QModule(
      id: 'j${day}_factice',
      day: day,
      kind: kind,
      instruments: [
        QInstrument(
          id: 'bloc',
          origin: QItemOrigin.validated,
          scale: echelle,
          items: [for (var i = 1; i <= 3; i++) QItem(id: 'i$i', text: t('Q$i'))],
        ),
      ],
    );

/// File d'attente en mémoire — le service ne doit rien savoir de Hive.
class OutboxMemoire implements EventOutbox {
  final Map<String, EventSubmission> file = {};
  final Set<String> refuses = {};
  int depots = 0;

  @override
  Future<bool> enqueue(EventSubmission submission) async {
    file[submission.moduleId] = submission;
    depots++;
    return true;
  }

  @override
  Future<List<EventSubmission>> pending() async => file.values.toList();

  @override
  Future<bool> removeIf(EventSubmission envoyee) async {
    // Compare-and-delete, comme la vraie file : on n'efface que si c'est
    // encore CETTE soumission qui attend.
    final stockee = file[envoyee.moduleId];
    if (stockee != null && stockee != envoyee) return false;
    file.remove(envoyee.moduleId);
    return true;
  }

  @override
  Future<void> markRefused(String moduleId) async => refuses.add(moduleId);

  @override
  Future<Set<String>> refusedModules() async => refuses;
}

/// Transport scénarisé : rend les issues dans l'ordre, puis répète la dernière.
class TransportScripte implements EventUploadTransport {
  TransportScripte(this.issues);

  final List<EventUploadOutcome> issues;
  final List<Map<String, dynamic>> envois = [];
  final List<String> versions = [];

  int get tentatives => envois.length;

  @override
  Future<EventUploadOutcome> send(
    EventSubmission submission, {
    required String consentVersion,
  }) async {
    envois.add(submission.toWire());
    versions.add(consentVersion);
    final rang = envois.length - 1;
    return rang < issues.length ? issues[rang] : issues.last;
  }
}

/// Consentement art. 9 pilotable, qui compte ses relectures.
class ConsentFactice implements EventConsentGate {
  ConsentFactice([this.version = '2026-07-27.v2']);

  String? version;
  int lectures = 0;

  @override
  Future<String?> consentVersion() async {
    lectures++;
    return version;
  }
}

EventUploadService service(
  OutboxMemoire outbox,
  TransportScripte transport, [
  ConsentFactice? consent,
]) =>
    EventUploadService(
      outbox: outbox,
      transport: transport,
      consent: consent ?? ConsentFactice(),
    );

EventSubmission soumission({
  bool partial = false,
  Map<String, int> answers = const {'i1': 2, 'i2': 0, 'i3': 3},
  int day = 3,
  DayActivityKind kind = DayActivityKind.announced,
}) {
  final module = moduleFactice(day: day, kind: kind);
  var reponses = QAnswerSet(moduleId: module.id);
  answers.forEach((id, v) => reponses = reponses.withAnswer(id, v));
  if (!partial) reponses = reponses.markCompleted();
  return EventSubmission.of(module, reponses, locale: 'fr');
}

void main() {
  // ─── Rejeu ─────────────────────────────────────────────────────────────────

  group('Rejeu jusqu\'à confirmation', () {
    test('deux pannes puis une confirmation : la donnée finit par passer',
        () async {
      final outbox = OutboxMemoire();
      final transport = TransportScripte([
        EventUploadOutcome.unreachable,
        EventUploadOutcome.unreachable,
        EventUploadOutcome.confirmed,
      ]);
      final s = service(outbox, transport);
      final envoi = soumission();

      expect(await s.submit(envoi), EventUploadOutcome.unreachable,
          reason: '1re tentative : le serveur est injoignable');
      expect(outbox.file.keys, [envoi.moduleId],
          reason: 'un envoi injoignable RESTE en file');

      expect((await s.retryPending())[envoi.moduleId],
          EventUploadOutcome.unreachable,
          reason: '2e tentative : toujours injoignable');
      expect(outbox.file, isNotEmpty, reason: 'toujours en file');

      expect((await s.retryPending())[envoi.moduleId],
          EventUploadOutcome.confirmed,
          reason: '3e tentative : le serveur confirme');
      expect(outbox.file, isEmpty,
          reason: 'confirmé = la copie en attente peut être oubliée');
      expect(transport.tentatives, 3);
    });

    test('la charge utile rejouée est IDENTIQUE à l\'originale', () async {
      final transport = TransportScripte([
        EventUploadOutcome.unreachable,
        EventUploadOutcome.confirmed,
      ]);
      final s = service(OutboxMemoire(), transport);
      await s.submit(soumission());
      await s.retryPending();

      expect(transport.envois.first, transport.envois.last,
          reason: 'un rejeu ne doit rien re-dériver : la donnée déposée EST '
              'celle qui part');
    });

    test('la file est déposée AVANT la tentative réseau', () async {
      final outbox = OutboxMemoire();
      final transport = TransportScripte([EventUploadOutcome.unreachable]);
      await service(outbox, transport).submit(soumission());

      expect(outbox.depots, 1,
          reason: 'même quand rien ne passe, la soumission a été enregistrée');
    });

    test('rejeu sans rien en attente : aucun coût réseau', () async {
      final transport = TransportScripte([EventUploadOutcome.confirmed]);
      final s = service(OutboxMemoire(), transport);

      expect(await s.retryPending(), isEmpty);
      expect(transport.tentatives, 0,
          reason: 'une file vide ne doit déclencher aucun appel');
    });

    test('plusieurs modules en attente partent tous', () async {
      final outbox = OutboxMemoire();
      final transport = TransportScripte([EventUploadOutcome.confirmed]);
      final s = service(outbox, transport);
      await outbox.enqueue(soumission(day: 1));
      await outbox.enqueue(soumission(day: 3));
      await outbox.enqueue(soumission(day: 6));

      final issues = await s.retryPending();
      expect(issues.length, 3);
      expect(issues.values.every((i) => i == EventUploadOutcome.confirmed), isTrue);
      expect(outbox.file, isEmpty);
    });
  });

  // ─── Pertes silencieuses : les scénarios qui ont motivé ce lot ─────────────

  group('Aucune perte silencieuse', () {
    test(
        'une confirmation PÉRIMÉE n\'efface pas le jeu complet arrivé entre-temps',
        () async {
      final outbox = OutboxMemoire();
      final partiel = soumission(partial: true, answers: {'i1': 2});
      final complet = soumission();
      await outbox.enqueue(partiel);

      // Le rejeu part avec le PARTIEL ; pendant qu'il est en vol, l'utilisateur
      // termine le questionnaire et le jeu COMPLET remplace le partiel en file.
      final transport = _TransportLent(
        pendantLEnvoi: () => outbox.enqueue(complet),
        issue: EventUploadOutcome.confirmed,
      );
      final s = service2(outbox, transport);

      await s.retryPending();

      expect(outbox.file[complet.moduleId], complet,
          reason: 'la confirmation du PARTIEL ne doit pas emporter le COMPLET : '
              'ce serait 45 réponses perdues, sans trace, en croyant les avoir '
              'transmises');
    });

    test('un dépôt local impossible n\'est jamais pris pour une confirmation',
        () async {
      final outbox = _OutboxSansPasse();
      final transport = TransportScripte([EventUploadOutcome.confirmed]);
      final s = EventUploadService(
        outbox: outbox,
        transport: transport,
        consent: ConsentFactice(),
      );

      final issue = await s.submit(soumission());

      expect(transport.tentatives, 1,
          reason: 'faute de file, la donnée doit AU MOINS avoir sa chance');
      expect(issue, EventUploadOutcome.confirmed,
          reason: 'ici le serveur a bien répondu 200 : c\'est LUI qui confirme');
    });

    test('une soumission absente de la file ne vaut PAS confirmation',
        () async {
      final outbox = OutboxMemoire();
      final transport = TransportScripte([EventUploadOutcome.confirmed]);
      final s = service(outbox, transport);

      // Jamais déposée sous ce passe (changement de passe, file d'un autre
      // compte, dépôt effacé) : le service ne doit rien inventer.
      final issue = await s.retryPending();
      expect(issue, isEmpty);

      // Et un envoi dont la file ne sait rien reste « injoignable ».
      final orpheline = soumission(day: 6);
      await outbox.enqueue(orpheline);
      await outbox.removeIf(orpheline); // la file oublie
      expect(transport.tentatives, 0,
          reason: 'aucun envoi n\'a eu lieu : rien ne doit être déclaré '
              'confirmé');
    });
  });

  // ─── Issues distinguées ────────────────────────────────────────────────────

  group('Issues distinguées', () {
    test('confirmé : sort de la file, sans marque de refus', () async {
      final outbox = OutboxMemoire();
      final s = service(outbox, TransportScripte([EventUploadOutcome.confirmed]));

      expect(await s.submit(soumission()), EventUploadOutcome.confirmed);
      expect(outbox.file, isEmpty);
      expect(outbox.refuses, isEmpty);
    });

    test('refusé : sort de la file, MAIS la trace reste', () async {
      final outbox = OutboxMemoire();
      final transport = TransportScripte([EventUploadOutcome.refused]);
      final s = service(outbox, transport);
      final envoi = soumission();

      expect(await s.submit(envoi), EventUploadOutcome.refused);
      expect(outbox.file, isEmpty,
          reason: 'rejouer la même charge utile ne changerait rien');
      expect(await s.refusedModules(), {envoi.moduleId},
          reason: 'un refus doit survivre pour être EXPLIQUÉ, pas disparaître');
    });

    test('un refus n\'est jamais rejoué', () async {
      final outbox = OutboxMemoire();
      final transport = TransportScripte([EventUploadOutcome.refused]);
      final s = service(outbox, transport);
      await s.submit(soumission());
      await s.retryPending();
      await s.retryPending();

      expect(transport.tentatives, 1,
          reason: 'une seule tentative : le refus est définitif');
    });

    test('injoignable : reste en file, et hasPending le dit', () async {
      final outbox = OutboxMemoire();
      final s = service(outbox, TransportScripte([EventUploadOutcome.unreachable]));
      await s.submit(soumission());

      expect(await s.hasPending(), isTrue);
      expect(outbox.refuses, isEmpty,
          reason: 'injoignable n\'est pas un refus : rien à expliquer');
    });

    test('un transport qui explose vaut injoignable, pas une perte', () async {
      final outbox = OutboxMemoire();
      final s = EventUploadService(
        outbox: outbox,
        transport: _TransportQuiExplose(),
        consent: ConsentFactice(),
      );

      expect(await s.submit(soumission()), EventUploadOutcome.unreachable);
      expect(outbox.file, isNotEmpty, reason: 'la donnée est toujours là');
    });
  });

  // ─── Table de lecture des statuts HTTP ─────────────────────────────────────

  group('Table des statuts (miroir du README de workers/event)', () {
    test('200 confirme', () {
      expect(HttpEventTransport.outcomeForStatus(200),
          EventUploadOutcome.confirmed);
    });

    test('les refus définitifs portent sur la CHARGE UTILE, et sur elle seule',
        () {
      for (final statut in [400, 413, 415, 422]) {
        expect(HttpEventTransport.outcomeForStatus(statut),
            EventUploadOutcome.refused,
            reason: '$statut : rejouer la même charge utile ne changerait rien');
      }
    });

    test('401, 403, 404 et 405 NE SONT PAS définitifs', () {
      expect(HttpEventTransport.outcomeForStatus(401),
          EventUploadOutcome.unreachable,
          reason: 'un passe signé plus tard fait aboutir le MÊME envoi');
      expect(HttpEventTransport.outcomeForStatus(403),
          EventUploadOutcome.unreachable,
          reason: 'un consentement accordé plus tard fait aboutir le MÊME envoi');
      for (final statut in [404, 405]) {
        expect(HttpEventTransport.outcomeForStatus(statut),
            EventUploadOutcome.unreachable,
            reason: '$statut : une route absente est un défaut de DÉPLOIEMENT '
                '(worker pas encore là, ancienne version, URL erronée). Le '
                'tenir pour définitif ferait perdre les réponses de tout le '
                'monde le jour d\'un mauvais déploiement.');
      }
    });

    test('pannes et limitation de débit : on rejouera', () {
      for (final statut in [429, 500, 502, 503, 504]) {
        expect(HttpEventTransport.outcomeForStatus(statut),
            EventUploadOutcome.unreachable,
            reason: '$statut');
      }
    });
  });

  // ─── Consentement art. 9 ───────────────────────────────────────────────────

  group('Consentement art. 9', () {
    test('sans consentement, PAS UN OCTET ne part', () async {
      final outbox = OutboxMemoire();
      final transport = TransportScripte([EventUploadOutcome.confirmed]);
      final s = service(outbox, transport, ConsentFactice(null));

      expect(await s.submit(soumission()), EventUploadOutcome.unreachable);
      expect(transport.tentatives, 0,
          reason: 'le transport ne doit même pas être sollicité');
      expect(outbox.file, isNotEmpty,
          reason: 'la donnée attend sur l\'appareil : un consentement accordé '
              'plus tard la fera partir');
    });

    test('consentement accordé après coup : la donnée en attente part',
        () async {
      final outbox = OutboxMemoire();
      final transport = TransportScripte([EventUploadOutcome.confirmed]);
      final consent = ConsentFactice(null);
      final s = service(outbox, transport, consent);

      await s.submit(soumission());
      expect(transport.tentatives, 0);

      consent.version = '2026-07-27.v2';
      final issues = await s.retryPending();

      expect(issues.values.single, EventUploadOutcome.confirmed);
      expect(transport.tentatives, 1);
      expect(outbox.file, isEmpty);
    });

    test('le consentement est relu à CHAQUE envoi, pas une seule fois',
        () async {
      final transport = TransportScripte([
        EventUploadOutcome.unreachable,
        EventUploadOutcome.unreachable,
      ]);
      final consent = ConsentFactice();
      final s = service(OutboxMemoire(), transport, consent);

      await s.submit(soumission());
      await s.retryPending();

      expect(consent.lectures, 2,
          reason: 'une relecture par tentative — sinon un retrait de '
              'consentement n\'arrêterait rien');
    });

    test('consentement retiré entre deux tentatives : le rejeu s\'arrête',
        () async {
      final outbox = OutboxMemoire();
      final transport = TransportScripte([EventUploadOutcome.unreachable]);
      final consent = ConsentFactice();
      final s = service(outbox, transport, consent);

      await s.submit(soumission());
      expect(transport.tentatives, 1);

      consent.version = null; // retrait (art. 7-3)
      await s.retryPending();

      expect(transport.tentatives, 1,
          reason: 'aucun envoi supplémentaire après un retrait');
      expect(outbox.file, isNotEmpty,
          reason: 'la donnée reste locale, elle n\'est pas détruite pour '
              'autant — l\'effacement est une demande séparée');
    });

    test('la version consentie voyage avec l\'envoi (preuve art. 7)', () async {
      final transport = TransportScripte([EventUploadOutcome.confirmed]);
      await service(OutboxMemoire(), transport, ConsentFactice('2026-01-01.v9'))
          .submit(soumission());

      expect(transport.versions.single, '2026-01-01.v9');
    });
  });

  // ─── Charge utile ──────────────────────────────────────────────────────────

  group('Charge utile', () {
    test('forme exacte du contrat partagé avec le worker', () async {
      final transport = TransportScripte([EventUploadOutcome.confirmed]);
      await service(OutboxMemoire(), transport).submit(soumission());

      expect(transport.envois.single, {
        'schema': 1,
        'moduleId': 'j3_factice',
        'day': 3,
        'kind': 'announced',
        'partial': false,
        'locale': 'fr',
        'answers': {'i1': 2, 'i2': 0, 'i3': 3},
      });
    });

    test('AUCUN horodatage, ni date, ni durée', () async {
      final transport = TransportScripte([EventUploadOutcome.confirmed]);
      await service(OutboxMemoire(), transport).submit(soumission());

      final cles = transport.envois.single.keys.toSet();
      expect(
        cles.intersection({'timestamp', 'date', 'at', 'createdAt', 'duration'}),
        isEmpty,
        reason: 'le worker pose lui-même une date au JOUR ; l\'instant précis '
            'd\'un envoi de santé serait un quasi-identifiant',
      );
    });

    test('aucun account : la partition est dérivée SERVEUR du passe', () async {
      final transport = TransportScripte([EventUploadOutcome.confirmed]);
      await service(OutboxMemoire(), transport).submit(soumission());

      expect(transport.envois.single.containsKey('account'), isFalse);
    });

    test('les données partielles partent MARQUÉES telles quelles', () async {
      final transport = TransportScripte([EventUploadOutcome.confirmed]);
      await service(OutboxMemoire(), transport)
          .submit(soumission(partial: true, answers: {'i1': 2}));

      expect(transport.envois.single['partial'], isTrue);
      expect(transport.envois.single['answers'], {'i1': 2},
          reason: 'un abandon envoie ce qui existe, pas des trous comblés');
    });

    test('une contribution garde son cadrage RGPD', () async {
      final transport = TransportScripte([EventUploadOutcome.confirmed]);
      await service(OutboxMemoire(), transport)
          .submit(soumission(day: 2, kind: DayActivityKind.contribution));

      expect(transport.envois.single['kind'], 'contribution',
          reason: 'annoncé et contribution n\'ont pas la même finalité');
    });

    test('un module sans réponse n\'est pas envoyé', () async {
      final outbox = OutboxMemoire();
      final transport = TransportScripte([EventUploadOutcome.confirmed]);
      final module = moduleFactice();
      final vide = EventSubmission.of(
        module,
        QAnswerSet(moduleId: module.id),
        locale: 'fr',
      );

      expect(await service(outbox, transport).submit(vide),
          EventUploadOutcome.confirmed);
      expect(transport.tentatives, 0);
      expect(outbox.file, isEmpty, reason: 'rien à mettre en file non plus');
    });

    test('la journée de partage (J8) n\'a rien à envoyer', () async {
      final transport = TransportScripte([EventUploadOutcome.confirmed]);
      await service(OutboxMemoire(), transport)
          .submit(soumission(day: 8, kind: DayActivityKind.share));

      expect(transport.tentatives, 0,
          reason: 'le worker refuserait ce cadrage, à raison');
    });
  });

  // ─── Aller-retour JSON de la file ──────────────────────────────────────────

  group('Persistance d\'une soumission', () {
    test('aller-retour JSON sans perte', () {
      final origine = soumission(partial: true);
      final relue = EventSubmission.fromJson(origine.toJson());

      expect(relue, origine);
    });

    test('la forme persistée EST la charge utile envoyée', () {
      final envoi = soumission();
      expect(envoi.toJson(), envoi.toWire(),
          reason: 'rien à re-dériver au moment du rejeu');
    });

    test('une entrée illisible est rejetée, jamais devinée', () {
      final base = soumission().toJson();
      final cas = <String, Map<String, dynamic>>{
        'cadrage inconnu': {...base, 'kind': 'inconnu'},
        'cadrage absent': {...base}..remove('kind'),
        'journée hors bornes': {...base, 'day': 12},
        'journée absente': {...base}..remove('day'),
        'module vide': {...base, 'moduleId': ''},
        'partiel non booléen': {...base, 'partial': 'oui'},
        'réponses absentes': {...base}..remove('answers'),
        'réponses vides': {...base, 'answers': <String, int>{}},
        'langue absente': {...base}..remove('locale'),
      };
      for (final entree in cas.entries) {
        expect(EventSubmission.fromJson(entree.value), isNull,
            reason: '${entree.key} : envoyer un module sous un mauvais cadrage '
                'serait pire que ne pas l\'envoyer');
      }
    });

    test('les valeurs non entières sont écartées, le reste survit', () {
      final json = {
        ...soumission().toJson(),
        'answers': {'i1': 2, 'i2': 'deux', 'i3': 3},
      };
      expect(EventSubmission.fromJson(json)!.answers, {'i1': 2, 'i3': 3});
    });
  });

  // ─── Sérialisation ─────────────────────────────────────────────────────────

  test('deux envois simultanés n\'envoient pas deux fois le même module',
      () async {
    final outbox = OutboxMemoire();
    final transport = TransportScripte([EventUploadOutcome.confirmed]);
    final s = service(outbox, transport);

    // L'ouverture du hub (rejeu) pendant qu'une fin de questionnaire s'envoie.
    await Future.wait([
      s.submit(soumission()),
      s.retryPending(),
    ]);

    expect(transport.tentatives, 1,
        reason: 'les envois sont sérialisés : le rejeu trouve la file déjà '
            'vidée par la confirmation');
  });
}

class _TransportQuiExplose implements EventUploadTransport {
  @override
  Future<EventUploadOutcome> send(
    EventSubmission submission, {
    required String consentVersion,
  }) async =>
      throw StateError('panne inattendue');
}

/// Un envoi qui traîne, et pendant lequel le monde change.
class _TransportLent implements EventUploadTransport {
  _TransportLent({required this.pendantLEnvoi, required this.issue});

  final Future<void> Function() pendantLEnvoi;
  final EventUploadOutcome issue;
  final List<EventSubmission> envois = [];

  @override
  Future<EventUploadOutcome> send(
    EventSubmission submission, {
    required String consentVersion,
  }) async {
    envois.add(submission);
    await pendantLEnvoi();
    return issue;
  }
}

/// File d'attente qui ne peut RIEN écrire (pas de passe exploitable), et le dit.
class _OutboxSansPasse implements EventOutbox {
  @override
  Future<bool> enqueue(EventSubmission submission) async => false;

  @override
  Future<List<EventSubmission>> pending() async => const [];

  @override
  Future<bool> removeIf(EventSubmission envoyee) async => false;

  @override
  Future<void> markRefused(String moduleId) async {}

  @override
  Future<Set<String>> refusedModules() async => const {};
}

EventUploadService service2(EventOutbox outbox, EventUploadTransport transport) =>
    EventUploadService(
      outbox: outbox,
      transport: transport,
      consent: ConsentFactice(),
    );
