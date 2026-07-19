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
}
