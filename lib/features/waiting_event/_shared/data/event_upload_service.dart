// Envoi des réponses de l'événement — DURABLE et REJOUÉ jusqu'à confirmation.
//
// LA LEÇON QUE CE FICHIER APPLIQUE. Le crédit de parrainage a été perdu pendant
// des semaines parce que l'unique requête qui le déclenchait partait « tire et
// oublie » depuis un écran facultatif : tout échec (réseau coupé, app fermée
// avant l'écran, refus serveur) perdait l'information POUR TOUJOURS et sans un
// mot. Ici, une réponse de questionnaire coûte à l'utilisateur plusieurs
// minutes de sa vie — la perdre en silence serait pire encore.
//
// La règle tenue par ce service :
//   1. la soumission est ENREGISTRÉE localement (chiffrée, cloisonnée par
//      passe) AVANT toute tentative réseau ;
//   2. elle est tentée aussitôt, puis REJOUÉE à chaque démarrage de l'app
//      (main.dart) et à chaque retour au premier plan du gate d'attente, tant
//      que le serveur n'a pas confirmé — depuis des chemins obligatoires,
//      jamais depuis un écran facultatif ;
//   3. les issues sont DISTINGUÉES : confirmé / refusé / injoignable. Un refus
//      définitif est mémorisé au lieu d'être rejoué en boucle ; un envoi
//      injoignable reste en file.
//
// CE QUI COMPTE COMME « REFUSÉ ». Uniquement ce qui condamne la charge utile
// elle-même : 400, 413, 415, 422. La rejouer telle quelle ne changerait rien.
// Tout le reste reste en file, parce qu'il dépend d'un contexte qui PEUT
// changer : réseau, 5xx, 429, mais aussi 401 (passe pas encore signé), 403
// (consentement pas encore accordé) et même 404/405 — une erreur de route est
// un défaut de DÉPLOIEMENT (worker absent, ancienne version, URL erronée), pas
// un vice de la donnée ; la traiter comme définitive détruirait les réponses de
// tout le monde le jour d'un mauvais déploiement. C'est le sens exact
// d'« injoignable » ici : l'envoi n'a pas abouti, pour une raison susceptible
// de disparaître.
//
// ET « CONFIRMÉ » NE S'INFÈRE JAMAIS D'UNE ABSENCE. Une soumission introuvable
// dans la file n'est pas pour autant transmise : elle peut n'y avoir jamais été
// déposée (pas de passe exploitable, disque en échec) ou appartenir à un autre
// passe. Seule une réponse 200 du serveur vaut confirmation.
//
// CONSENTEMENT ART. 9, VÉRIFIÉ AVANT CHAQUE ENVOI — y compris au rejeu, jamais
// une seule fois au départ : un consentement retiré entre-temps doit arrêter
// les envois suivants. Sans consentement, la soumission est mise en file mais
// AUCUN octet ne quitte l'appareil ; les réponses restent là où elles étaient
// déjà, dans la box chiffrée du module. Le questionnaire reste jouable et son
// score s'affiche : le refus n'ampute que la collecte.

import 'dart:convert';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:http/http.dart' as http;

import '../../../../core/constants/app_constants.dart';
import '../../../../core/consent/consent_record.dart';
import '../../../../core/consent/consent_service.dart';
import '../../../../core/services/auth_local_store.dart';
import '../domain/models/event_day.dart';
import '../domain/models/event_submission.dart';
import 'event_local_store.dart';

/// Ce qu'il est advenu d'un envoi.
enum EventUploadOutcome {
  /// Le serveur a écrit la donnée. La copie en attente peut être oubliée.
  confirmed,

  /// Le serveur a refusé cette charge utile DÉFINITIVEMENT. On cesse de
  /// rejouer, et on garde la trace pour pouvoir l'expliquer.
  refused,

  /// Rien n'a abouti, pour une raison susceptible de changer (réseau, serveur,
  /// passe pas encore signé, consentement pas encore accordé, worker pas encore
  /// déployé). La soumission reste en file.
  unreachable,
}

/// La preuve de consentement à joindre à un envoi — ou son absence.
///
/// Injectable pour que les tests n'aient besoin ni de SharedPreferences ni du
/// texte réel de la politique.
abstract interface class EventConsentGate {
  /// La version du texte consentie POUR LA FINALITÉ art. 9, ou `null` s'il n'y
  /// a pas de consentement valide et à jour.
  Future<String?> consentVersion();
}

class _RealConsentGate implements EventConsentGate {
  const _RealConsentGate();

  @override
  Future<String?> consentVersion() async {
    if (!await ConsentService.instance.hasEventDataConsent()) return null;
    return ConsentService.instance.current?.version;
  }
}

/// Le fil qui porte une soumission jusqu'au worker.
///
/// Interface étroite plutôt qu'un `http.Client` injecté : ce que le test doit
/// pouvoir scénariser, c'est la SUITE DES ISSUES (injoignable, injoignable,
/// confirmé), pas des enveloppes HTTP.
abstract interface class EventUploadTransport {
  Future<EventUploadOutcome> send(
    EventSubmission submission, {
    required String consentVersion,
  });
}

class HttpEventTransport implements EventUploadTransport {
  HttpEventTransport({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConstants.eventWorkerUrl;

  final http.Client _client;

  /// Injectable pour que le contrat de fil (route, en-têtes, corps) soit
  /// vérifiable par un test — c'est le SEUL code qui parle vraiment au worker.
  final String _baseUrl;

  bool get isConfigured => !_baseUrl.contains('YOUR_SUBDOMAIN');

  @override
  Future<EventUploadOutcome> send(
    EventSubmission submission, {
    required String consentVersion,
  }) async {
    if (!isConfigured) return EventUploadOutcome.unreachable;
    final token = await AuthLocalStore.instance.getToken();
    // Sans passe, le worker ne saurait pas dans quel compartiment écrire — et
    // c'est bien lui, pas nous, qui en décide. On garde et on rejouera.
    if (token == null || token.isEmpty) return EventUploadOutcome.unreachable;

    try {
      final resp = await _client
          .post(
            Uri.parse('$_baseUrl/responses'),
            headers: {
              'Content-Type': 'application/json',
              'X-Mentality-Token': token,
              'X-Consent-Version': consentVersion,
              'X-Consent-Purpose': kEventDataPurpose,
            },
            body: jsonEncode(submission.toWire()),
          )
          // Sans délai maximal, une requête suspendue bloquerait la chaîne
          // d'envois : plus rien ne partirait de la session. Le dépassement
          // vaut « injoignable » — la soumission reste en file.
          .timeout(AppConstants.connectionTimeout);
      return outcomeForStatus(resp.statusCode);
    } catch (_) {
      return EventUploadOutcome.unreachable;
    }
  }

  /// La table de lecture des statuts, isolée pour être vérifiable telle quelle.
  /// Miroir de la table du README de workers/event/.
  static EventUploadOutcome outcomeForStatus(int status) {
    if (status == 200) return EventUploadOutcome.confirmed;
    // Le serveur juge la charge utile elle-même inacceptable : la rejouer à
    // l'identique ne changerait rien.
    const definitifs = {400, 413, 415, 422};
    if (definitifs.contains(status)) return EventUploadOutcome.refused;
    // Tout le reste est récupérable : 401 (passe pas encore signé), 403
    // (consentement/origine), 404 et 405 (route absente = worker mal déployé),
    // 429 et 5xx. Un passe signé, un consentement accordé ou un déploiement
    // corrigé font aboutir le MÊME envoi.
    return EventUploadOutcome.unreachable;
  }
}

class EventUploadService {
  EventUploadService({
    EventOutbox? outbox,
    EventUploadTransport? transport,
    EventConsentGate? consent,
  })  : _outbox = outbox ?? EventLocalStore.instance,
        _transport = transport ?? HttpEventTransport(),
        _consent = consent ?? const _RealConsentGate();

  static EventUploadService instance = EventUploadService();

  /// Remplace le service le temps d'un test. Le branchement de production —
  /// le moteur de questionnaire qui appelle CE service — ne se prouve pas
  /// autrement qu'en le traversant : c'est exactement ce câblage jamais
  /// exercé qui avait fait perdre les parrainages.
  @visibleForTesting
  static void debugSetInstance(EventUploadService service) =>
      instance = service;

  final EventOutbox _outbox;
  final EventUploadTransport _transport;
  final EventConsentGate _consent;

  /// Les envois sont SÉRIALISÉS, pas concurrents. Sans cela, un retour au
  /// premier plan pendant qu'une fin de questionnaire s'envoie posterait deux
  /// fois la même soumission. Sérialiser plutôt que refuser : aucun envoi n'est
  /// perdu, ils attendent simplement leur tour.
  Future<void> _file = Future<void>.value();

  Future<T> _serialise<T>(Future<T> Function() action) {
    final suivant = _file.then((_) => action());
    _file = suivant.then((_) {}, onError: (_) {});
    return suivant;
  }

  /// Enregistre la soumission puis tente de l'envoyer immédiatement.
  ///
  /// À appeler DÈS que les réponses existent — à la dernière question comme à
  /// l'abandon —, jamais après un écran facultatif : c'est précisément ce
  /// report qui avait fait perdre les parrainages.
  Future<EventUploadOutcome> submit(EventSubmission submission) async {
    // Rien à envoyer : un module sans réponse, ou la journée de partage qui
    // n'a pas de questions (le worker la refuserait, à raison).
    if (submission.isEmpty || submission.kind == DayActivityKind.share) {
      return EventUploadOutcome.confirmed;
    }
    // Déposé AVANT toute tentative réseau, et AVANT d'attendre notre tour dans
    // la file d'envoi : c'est ce dépôt qui survit à la fermeture de l'app.
    var depose = false;
    try {
      depose = await _outbox.enqueue(submission);
    } catch (_) {
      // Le stockage local a échoué : on tente quand même l'envoi direct plutôt
      // que d'abandonner la donnée. Rien ne la rejouera, mais elle aura eu sa
      // chance.
    }
    return _serialise(() => _envoie(submission, deposee: depose));
  }

  /// Rejoue tout ce qui attend encore une confirmation pour le passe courant.
  ///
  /// Sans objet et sans coût réseau quand la file est vide. Renvoie l'issue par
  /// module, pour que l'appelant puisse expliquer un refus.
  Future<Map<String, EventUploadOutcome>> retryPending() =>
      _serialise(() async {
        List<EventSubmission> attente;
        try {
          attente = await _outbox.pending();
        } catch (_) {
          return const <String, EventUploadOutcome>{};
        }
        final issues = <String, EventUploadOutcome>{};
        for (final submission in attente) {
          issues[submission.moduleId] = await _envoie(submission);
        }
        return issues;
      });

  /// Reste-t-il des réponses non confirmées par le serveur ?
  Future<bool> hasPending() async {
    try {
      return (await _outbox.pending()).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Les modules dont le serveur a refusé les réponses définitivement.
  Future<Set<String>> refusedModules() async {
    try {
      return await _outbox.refusedModules();
    } catch (_) {
      return const {};
    }
  }

  /// [deposee] : la soumission a-t-elle bien été écrite dans la file ? Quand
  /// oui, la file fait foi sur ce qu'il reste à envoyer. Quand non (pas de
  /// passe exploitable, disque en échec), il n'y a rien à consulter et on tente
  /// quand même — c'est la seule chance de cette donnée.
  Future<EventUploadOutcome> _envoie(
    EventSubmission submission, {
    bool deposee = true,
  }) async {
    if (deposee) {
      final inutile = await _sansObjet(submission);
      if (inutile != null) return inutile;
    }

    // ─── Garde art. 9, re-vérifiée à CHAQUE envoi ────────────────────────────
    String? version;
    try {
      version = await _consent.consentVersion();
    } catch (_) {
      version = null;
    }
    // Pas de consentement = pas un octet. La soumission reste en file : si le
    // consentement est accordé plus tard, elle partira alors.
    if (version == null || version.isEmpty) {
      return EventUploadOutcome.unreachable;
    }

    try {
      final issue = await _transport.send(submission, consentVersion: version);
      switch (issue) {
        case EventUploadOutcome.confirmed:
          // N'efface QUE si la file contient encore cette soumission-là : une
          // version plus récente a pu la remplacer pendant l'envoi.
          await _outbox.removeIf(submission);
        case EventUploadOutcome.refused:
          // La trace D'ABORD : tué entre les deux écritures, on garde une
          // soumission en file (rejouée une fois, refusée à nouveau, la
          // séquence converge) plutôt qu'un refus disparu sans laisser de mot.
          await _outbox.markRefused(submission.moduleId);
          await _outbox.removeIf(submission);
        case EventUploadOutcome.unreachable:
          break; // reste en file, on rejouera
      }
      return issue;
    } catch (_) {
      return EventUploadOutcome.unreachable;
    }
  }

  /// L'issue à rendre quand il n'y a PLUS LIEU d'envoyer [submission] — parce
  /// qu'un envoi concurrent l'a déjà traitée, ou qu'une soumission plus récente
  /// l'a remplacée pendant qu'on attendait son tour. `null` = il faut envoyer.
  ///
  /// Ne rend JAMAIS `confirmed` : seul un 200 du serveur confirme. Une
  /// soumission introuvable peut aussi bien avoir été effacée par une
  /// confirmation que n'avoir jamais existé sous ce passe — le dire
  /// « confirmée » inventerait une transmission.
  Future<EventUploadOutcome?> _sansObjet(EventSubmission submission) async {
    try {
      final attente = await _outbox.pending();
      // Toujours elle, telle quelle : on envoie.
      if (attente.contains(submission)) return null;
      if (attente.any((s) => s.moduleId == submission.moduleId)) {
        // Remplacée par une version plus récente : envoyer celle-ci écrirait
        // une donnée périmée. C'est la nouvelle qui partira.
        return EventUploadOutcome.unreachable;
      }
      return (await _outbox.refusedModules()).contains(submission.moduleId)
          ? EventUploadOutcome.refused
          : EventUploadOutcome.unreachable;
    } catch (_) {
      // File illisible : on tente l'envoi, quitte à produire un doublon —
      // le worker les assume, une donnée perdue non.
      return null;
    }
  }
}
