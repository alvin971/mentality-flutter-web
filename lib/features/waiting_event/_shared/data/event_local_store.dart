// Stockage local des réponses de l'événement — chiffré et cloisonné.
//
// Reprend trait pour trait le patron d'`AuthLocalStore` :
//   · box Hive chiffrée AES-256 avec le cipher PARTAGÉ de DataCollectionService
//     (une seule clé pour toutes les données locales de l'app) ;
//   · clés préfixées par l'`account` dérivé du passe courant.
//
// Le cloisonnement n'est pas cosmétique. Une clé globale ferait hériter un
// passe neuf des réponses d'un autre sur le même téléphone : on reprendrait le
// questionnaire de quelqu'un d'autre, et ses réponses de santé partiraient
// sous notre identité. Sans passe exploitable, on n'écrit et on ne lit RIEN
// (fail-closed) — c'est la même règle que le cache de déblocage.

import 'dart:convert';

import 'package:hive/hive.dart';

import '../../../../core/services/auth_local_store.dart';
import '../../../../core/services/token_account.dart';
import '../../../../services/data_collection_service.dart'
    show DataCollectionService;
import '../domain/models/event_submission.dart';
import '../domain/models/q_answer_set.dart';

/// Ce dont le moteur de questionnaire a besoin — et rien de plus.
///
/// L'interface existe pour que le moteur soit testable sans Hive ni
/// SharedPreferences : les tests injectent une implémentation en mémoire.
abstract interface class EventAnswerStore {
  /// Les réponses déjà données pour [moduleId], ou `null` si le module n'a
  /// jamais été ouvert (ou si aucun passe n'est exploitable).
  Future<QAnswerSet?> load(String moduleId);

  Future<void> save(QAnswerSet answers);

  Future<void> clear(String moduleId);
}

/// La file d'attente des envois — ce qui rend le rejeu possible.
///
/// Une soumission y est DÉPOSÉE AVANT toute tentative réseau, et n'en sort que
/// sur confirmation du serveur (ou sur refus définitif). C'est la leçon du
/// parrainage perdu : une action critique qui ne survit pas à la fermeture de
/// l'app finit par ne jamais être émise.
///
/// La file est indexée par module : une soumission plus récente pour le même
/// module remplace la précédente. Un abandon suivi d'une reprise complète
/// n'envoie donc pas deux fois — sauf si le partiel avait déjà abouti, auquel
/// cas les deux existent côté serveur et c'est voulu (voir workers/event).
abstract interface class EventOutbox {
  /// `true` si la soumission est bien sur le disque. `false` (dépôt refusé,
  /// faute de passe exploitable, ou écriture en échec) doit être DIT : sans
  /// cela l'appelant croirait une soumission déposée alors qu'elle n'est nulle
  /// part, et interpréterait son absence comme une confirmation.
  Future<bool> enqueue(EventSubmission submission);

  /// Tout ce qui attend encore une confirmation, pour le passe courant.
  Future<List<EventSubmission>> pending();

  /// Retire [envoyee] de la file — MAIS SEULEMENT si c'est encore elle qui y
  /// est. Renvoie `true` si la file ne la contient plus.
  ///
  /// La comparaison porte sur le CONTENU, jamais sur le seul identifiant de
  /// module. Sans elle : un rejeu lent envoie un jeu partiel, l'utilisateur
  /// termine le même questionnaire entre-temps (le jeu complet remplace le
  /// partiel dans la file), la confirmation du partiel arrive et effacerait le
  /// jeu COMPLET — 45 réponses perdues, sans trace, en croyant les avoir
  /// transmises.
  Future<bool> removeIf(EventSubmission envoyee);

  /// Mémorise un refus DÉFINITIF du serveur. Sans cette trace, un refus
  /// disparaîtrait à la fermeture de l'app et l'utilisateur croirait ses
  /// réponses transmises.
  Future<void> markRefused(String moduleId);

  Future<Set<String>> refusedModules();
}

class EventLocalStore implements EventAnswerStore, EventOutbox {
  static const _boxName = 'mentality_waiting_event';

  EventLocalStore._();
  static final EventLocalStore instance = EventLocalStore._();

  Future<Box> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) return Hive.box(_boxName);
    final cipher = await DataCollectionService.buildSharedCipher();
    return Hive.openBox(_boxName, encryptionCipher: cipher);
  }

  /// Clé CLOISONNÉE PAR PASSE, ou `null` s'il n'y a pas de passe exploitable —
  /// auquel cas on ne touche pas au stockage.
  Future<String?> _key(String moduleId) async => _prefixe('answers', moduleId);

  /// Même cloisonnement pour la file d'attente : les envois d'un passe ne
  /// doivent pas partir sous l'identité d'un autre.
  Future<String?> _outboxKey(String moduleId) async =>
      _prefixe('outbox', moduleId);

  Future<String?> _prefixe(String espace, String moduleId) async {
    final account =
        await TokenAccount.fromToken(await AuthLocalStore.instance.getToken());
    return account == null ? null : '$espace:$account:$moduleId';
  }

  @override
  Future<QAnswerSet?> load(String moduleId) async {
    final key = await _key(moduleId);
    if (key == null) return null;
    final box = await _openBox();
    final brut = box.get(key);
    if (brut is! String || brut.isEmpty) return null;
    try {
      final json = jsonDecode(brut);
      if (json is! Map<String, dynamic>) return null;
      return QAnswerSet.fromJson(json);
    } catch (_) {
      // Une entrée illisible ne doit pas bloquer la journée : on repart d'un
      // questionnaire vierge plutôt que de faire planter l'écran.
      return null;
    }
  }

  @override
  Future<void> save(QAnswerSet answers) async {
    final key = await _key(answers.moduleId);
    if (key == null) return;
    final box = await _openBox();
    await box.put(key, jsonEncode(answers.toJson()));
  }

  @override
  Future<void> clear(String moduleId) async {
    final key = await _key(moduleId);
    if (key == null) return;
    final box = await _openBox();
    await box.delete(key);
  }

  // ─── File d'attente des envois ─────────────────────────────────────────────

  @override
  Future<bool> enqueue(EventSubmission submission) async {
    final key = await _outboxKey(submission.moduleId);
    if (key == null) return false; // pas de passe exploitable : on n'écrit rien
    final box = await _openBox();
    await box.put(key, jsonEncode(submission.toJson()));
    return true;
  }

  @override
  Future<List<EventSubmission>> pending() async {
    final prefixe = await _outboxKey('');
    if (prefixe == null) return const [];
    final box = await _openBox();
    final attente = <EventSubmission>[];
    for (final cle in box.keys) {
      if (cle is! String || !cle.startsWith(prefixe)) continue;
      final brut = box.get(cle);
      if (brut is! String || brut.isEmpty) continue;
      try {
        final json = jsonDecode(brut);
        if (json is! Map<String, dynamic>) continue;
        final submission = EventSubmission.fromJson(json);
        // Une entrée illisible ne partira jamais : on la retire plutôt que de
        // la rejouer indéfiniment sans espoir d'aboutir.
        if (submission == null) {
          await box.delete(cle);
          continue;
        }
        attente.add(submission);
      } catch (_) {
        await box.delete(cle);
      }
    }
    return attente;
  }

  @override
  Future<bool> removeIf(EventSubmission envoyee) async {
    final key = await _outboxKey(envoyee.moduleId);
    if (key == null) return false;
    final box = await _openBox();
    final brut = box.get(key);
    if (brut is! String || brut.isEmpty) return true; // déjà partie
    EventSubmission? stockee;
    try {
      final json = jsonDecode(brut);
      if (json is Map<String, dynamic>) stockee = EventSubmission.fromJson(json);
    } catch (_) {
      stockee = null;
    }
    // Une entrée illisible n'aurait de toute façon jamais pu partir : on la
    // retire. Une entrée DIFFÉRENTE est une soumission plus récente — on la
    // laisse, c'est elle qui doit partir maintenant.
    if (stockee != null && stockee != envoyee) return false;
    await box.delete(key);
    return true;
  }

  @override
  Future<void> markRefused(String moduleId) async {
    final key = await _prefixe('refused', moduleId);
    if (key == null) return;
    final box = await _openBox();
    await box.put(key, '1');
  }

  @override
  Future<Set<String>> refusedModules() async {
    final prefixe = await _prefixe('refused', '');
    if (prefixe == null) return const {};
    final box = await _openBox();
    return {
      for (final cle in box.keys)
        if (cle is String && cle.startsWith(prefixe))
          cle.substring(prefixe.length),
    };
  }
}
