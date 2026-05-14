import 'package:hive/hive.dart';
import '../../services/data_collection_service.dart' show DataCollectionService;

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
}
