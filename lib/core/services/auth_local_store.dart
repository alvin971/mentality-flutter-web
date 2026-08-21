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

  // ───── Identité de la passation en cours ─────
  //
  // UUID généré au premier sous-test et conservé jusqu'à la fin du test. C'est
  // la clé d'idempotence des envois incrémentaux : l'app peut fermer, planter ou
  // perdre le réseau, elle reprendra la MÊME session côté serveur au lieu d'en
  // ouvrir une seconde. C'est aussi ce qui rendra la pause/reprise possible.
  static const _testSessionKey = 'test_session_id_v1';

  Future<void> saveTestSessionId(String id) async {
    final box = await _openBox();
    await box.put(_testSessionKey, id);
  }

  Future<String?> getTestSessionId() async {
    final box = await _openBox();
    return box.get(_testSessionKey) as String?;
  }

  Future<void> clearTestSessionId() async {
    final box = await _openBox();
    await box.delete(_testSessionKey);
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
