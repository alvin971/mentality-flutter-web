import 'package:hive/hive.dart';
import '../../services/data_collection_service.dart' show DataCollectionService;
import 'token_account.dart';

/// Stockage local du token Mental E.T. dans une box Hive chiffrée AES-256.
///
/// Le token est l'unique identifiant persisté côté client. Il ne contient
/// aucune donnée personnelle (ni email, ni téléphone, ni nom).
class AuthLocalStore {
  static const _boxName = 'mentality_auth';
  static const _tokenKey = 'token_v1';

  AuthLocalStore._();
  static final instance = AuthLocalStore._();

  Future<Box> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) return Hive.box(_boxName);
    final cipher = await DataCollectionService.buildSharedCipher();
    return Hive.openBox(_boxName, encryptionCipher: cipher);
  }

  /// Sauvegarde le token chiffré en local (AES-256 via Hive cipher).
  Future<void> saveToken(String token) async {
    final box = await _openBox();
    await box.put(_tokenKey, token);
    // Un changement de token change d'IDENTITÉ : la passation en cours
    // appartenait au token précédent. Sans cet effacement, le prochain envoi
    // réutiliserait le même client_session_id sous un compte différent, et le
    // serveur RÉATTRIBUERAIT la session — les mesures partielles de l'ancien
    // compte deviendraient celles du nouveau. C'est le goulot par lequel passe
    // tout changement de token : la garantie est ici, pas chez les appelants.
    await box.delete(_testSessionKey);
    await box.delete(_testSessionOpenedKey);
    await box.delete(_testSessionMeasureKey);
  }

  /// Retourne le token persisté ou `null` si aucun.
  Future<String?> getToken() async {
    final box = await _openBox();
    return box.get(_tokenKey) as String?;
  }

  /// Supprime le token local (logout / réinitialisation).
  Future<void> clear() async {
    final box = await _openBox();
    await box.delete(_tokenKey);
  }

  /// True si un token est présent localement.
  Future<bool> hasToken() async => (await getToken()) != null;

  // ───── File des mesures en attente d'envoi ─────
  //
  // Persistée, et pas seulement gardée en mémoire : entre deux exercices, iOS
  // et Android tuent régulièrement une app passée en arrière-plan. Une file
  // volatile perdrait alors tout ce qui n'était pas encore parti, sans trace ni
  // rejeu possible — et c'est précisément la situation d'une mise en pause au
  // milieu du test.
  static const _pendingResultsKey = 'pending_results_v1';

  Future<void> savePendingResults(String json) async {
    final box = await _openBox();
    await box.put(_pendingResultsKey, json);
  }

  Future<String?> getPendingResults() async {
    final box = await _openBox();
    return box.get(_pendingResultsKey) as String?;
  }

  Future<void> clearPendingResults() async {
    final box = await _openBox();
    await box.delete(_pendingResultsKey);
  }

  // ───── Identité de la passation en cours ─────
  //
  // UUID généré au premier sous-test et conservé jusqu'à la fin du test. C'est
  // la clé d'idempotence des envois incrémentaux : l'app peut fermer, planter ou
  // perdre le réseau, elle reprendra la MÊME session côté serveur au lieu d'en
  // ouvrir une seconde. C'est aussi ce qui rendra la pause/reprise possible.
  static const _testSessionKey = 'test_session_id_v1';

  /// Jour d'ouverture de la passation, et origine de la mesure de durée.
  ///
  /// Persistés parce que l'identifiant seul ne suffit pas : sans eux, l'app
  /// redémarrée en cours de bilan renvoyait `startedAt = maintenant`, l'upsert
  /// déplaçait `started_on` à la date du jour — et la fenêtre de reprise de
  /// 7 jours repartait de zéro en silence. Deux dates et non une : le jour
  /// d'ouverture doit rester CELUI DU DÉBUT (il fixe la péremption), alors que
  /// l'origine de mesure recule d'autant que la durée déjà acquise lors d'une
  /// reprise sur un autre appareil.
  static const _testSessionOpenedKey = 'test_session_opened_at_v1';
  static const _testSessionMeasureKey = 'test_session_measure_from_v1';

  Future<void> saveTestSessionId(String id) async {
    final box = await _openBox();
    await box.put(_testSessionKey, id);
  }

  /// Enregistre les deux dates. Une valeur nulle EFFACE la clé plutôt que
  /// d'écrire un marqueur illisible.
  Future<void> saveTestSessionDates({
    DateTime? ouverture,
    DateTime? mesureDepuis,
  }) async {
    final box = await _openBox();
    for (final e in {
      _testSessionOpenedKey: ouverture,
      _testSessionMeasureKey: mesureDepuis,
    }.entries) {
      if (e.value == null) {
        await box.delete(e.key);
      } else {
        await box.put(e.key, e.value!.toIso8601String());
      }
    }
  }

  /// Les deux dates, ou `null` chacune si absente ou illisible.
  Future<({DateTime? ouverture, DateTime? mesureDepuis})>
      getTestSessionDates() async {
    final box = await _openBox();
    DateTime? lis(String k) {
      final v = box.get(k);
      return v is String ? DateTime.tryParse(v) : null;
    }

    return (
      ouverture: lis(_testSessionOpenedKey),
      mesureDepuis: lis(_testSessionMeasureKey),
    );
  }

  Future<String?> getTestSessionId() async {
    final box = await _openBox();
    return box.get(_testSessionKey) as String?;
  }

  Future<void> clearTestSessionId() async {
    final box = await _openBox();
    await box.delete(_testSessionKey);
    await box.delete(_testSessionOpenedKey);
    await box.delete(_testSessionMeasureKey);
  }

  static const _referrerKey = 'pending_referrer_code';

  /// Mémorise le code de parrainage capté sur le lien /invite?ref=<code>.
  /// Consommé une seule fois à la fin du test (validation du parrain).
  Future<void> savePendingReferrerCode(String code) async {
    final box = await _openBox();
    await box.put(_referrerKey, code);
  }

  /// Code de parrainage en attente, ou `null`.
  Future<String?> getPendingReferrerCode() async {
    final box = await _openBox();
    return box.get(_referrerKey) as String?;
  }

  /// Efface le code de parrainage (après validation côté serveur).
  Future<void> clearPendingReferrerCode() async {
    final box = await _openBox();
    await box.delete(_referrerKey);
  }

  /// Clé du cache de déblocage, CLOISONNÉE PAR PASSE. Une clé globale faisait
  /// hériter un passe neuf du déblocage acquis par un autre sur le même
  /// téléphone : ses résultats s'affichaient en clair sans aucune mission.
  /// `null` si aucun passe exploitable → aucun cache (fail-closed).
  Future<String?> _resultsUnlockedKey() async {
    final account = await TokenAccount.fromToken(await getToken());
    return account == null ? null : 'results_unlocked:$account';
  }

  /// Mémorise que le déblocage des résultats (stage 4) a été confirmé par le
  /// serveur POUR LE PASSE COURANT — un déblocage acquis ne se re-verrouille
  /// jamais, même si le worker devient injoignable ensuite.
  Future<void> saveResultsUnlocked() async {
    final key = await _resultsUnlockedKey();
    if (key == null) return;
    final box = await _openBox();
    await box.put(key, true);
  }

  /// True si le passe courant a déjà vu son déblocage confirmé.
  Future<bool> getResultsUnlocked() async {
    final key = await _resultsUnlockedKey();
    if (key == null) return false;
    final box = await _openBox();
    return box.get(key) == true;
  }

  // ─── Déclaration de fin de test en attente ──────────────────────────────
  //
  // La déclaration de complétion (POST /complete) est la SEULE porte qui
  // crédite le parrain d'un filleul. Elle était émise une fois, sans filet :
  // une coupure réseau, ou l'app fermée avant qu'elle ne parte, et le
  // parrainage était perdu DÉFINITIVEMENT, sans le moindre message.
  //
  // On la persiste donc dès la fin de la batterie et on la rejoue à chaque
  // occasion (ouverture de l'app, écran des missions, page de résultats)
  // jusqu'à confirmation du serveur. Cloisonnée par passe, comme le cache de
  // déblocage : la fin de test d'un passe ne doit jamais créditer un autre.

  Future<String?> _pendingCompletionKey() async {
    final account = await TokenAccount.fromToken(await getToken());
    return account == null ? null : 'pending_completion:$account';
  }

  /// Mémorise une fin de test à déclarer (ou re-déclarer) au serveur.
  Future<void> savePendingCompletion({
    required int subtestsCompleted,
    required int durationSeconds,
  }) async {
    final key = await _pendingCompletionKey();
    if (key == null) return;
    final box = await _openBox();
    await box.put(key, {
      'subtestsCompleted': subtestsCompleted,
      'durationSeconds': durationSeconds,
    });
  }

  /// Fin de test restant à déclarer pour le passe courant, ou `null`.
  Future<({int subtestsCompleted, int durationSeconds})?>
      getPendingCompletion() async {
    final key = await _pendingCompletionKey();
    if (key == null) return null;
    final box = await _openBox();
    final raw = box.get(key);
    if (raw is! Map) return null;
    final subtests = (raw['subtestsCompleted'] as num?)?.toInt();
    final duration = (raw['durationSeconds'] as num?)?.toInt();
    if (subtests == null || duration == null) return null;
    return (subtestsCompleted: subtests, durationSeconds: duration);
  }

  /// Efface la déclaration en attente (confirmée, ou définitivement refusée).
  Future<void> clearPendingCompletion() async {
    final key = await _pendingCompletionKey();
    if (key == null) return;
    final box = await _openBox();
    await box.delete(key);
  }

  /// Mémorise qu'une déclaration a été REFUSÉE par le serveur (session jugée
  /// non plausible). Sert à l'expliquer à l'utilisateur au lieu de le laisser
  /// croire que sa mission est validée.
  Future<void> saveCompletionRejected() async {
    final account = await TokenAccount.fromToken(await getToken());
    if (account == null) return;
    final box = await _openBox();
    await box.put('completion_rejected:$account', true);
  }

  Future<bool> getCompletionRejected() async {
    final account = await TokenAccount.fromToken(await getToken());
    if (account == null) return false;
    final box = await _openBox();
    return box.get('completion_rejected:$account') == true;
  }

  Future<void> clearCompletionRejected() async {
    final account = await TokenAccount.fromToken(await getToken());
    if (account == null) return;
    final box = await _openBox();
    await box.delete('completion_rejected:$account');
  }
}
