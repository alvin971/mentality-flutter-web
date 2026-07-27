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

class EventLocalStore implements EventAnswerStore {
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
  Future<String?> _key(String moduleId) async {
    final account =
        await TokenAccount.fromToken(await AuthLocalStore.instance.getToken());
    return account == null ? null : 'answers:$account:$moduleId';
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
}
