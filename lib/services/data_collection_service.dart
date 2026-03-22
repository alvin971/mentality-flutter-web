// lib/services/data_collection_service.dart
// Singleton gérant la persistance Hive pour la collecte de données audio.
//
// Architecture des boxes :
//   mentality_sell → couches C (audio) et D (paires NLU) — données licenciables
//   mentality_keep → réservé aux données cognitives secrètes (ouvert, jamais écrit ici)
//
// CONTRAINTE : aucune méthode publique n'écrit dans _keepBox.
// La séparation est garantie structurellement, pas seulement par convention.
//
// Sécurité : les deux boxes sont chiffrées avec HiveAesCipher (AES-256-CBC).
// La clé est générée aléatoirement au premier lancement et stockée dans
// SharedPreferences sous la clé 'hive_aes_key' (base64-encodée).
// Sur mobile, envisager flutter_secure_storage pour davantage de sécurité.

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DataCollectionService {
  static final DataCollectionService instance = DataCollectionService._();
  DataCollectionService._();

  static const String _sellBoxName = 'mentality_sell';
  static const String _keepBoxName = 'mentality_keep';
  static const String _aesKeyPref = 'hive_aes_key';

  late Box<dynamic> _sellBox;
  // _keepBox is opened to reserve the name and apply encryption,
  // but never written to from public API (structural separation guarantee).
  // ignore: unused_field
  late Box<dynamic> _keepBox;
  bool _initialized = false;

  /// À appeler une fois au démarrage de l'app, après Hive.initFlutter().
  Future<void> initialize() async {
    if (_initialized) return;
    final cipher = await _buildCipher();
    _sellBox = await Hive.openBox<dynamic>(_sellBoxName, encryptionCipher: cipher);
    _keepBox = await Hive.openBox<dynamic>(_keepBoxName, encryptionCipher: cipher);
    _initialized = true;
  }

  /// Retourne le cipher AES-256 à utiliser pour d'autres boxes (ex: session_history).
  static Future<HiveCipher> buildSharedCipher() => _buildCipher();

  /// Génère (ou charge depuis SharedPreferences) la clé AES-256 de 32 octets.
  static Future<HiveAesCipher> _buildCipher() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_aesKeyPref);

    final Uint8List keyBytes;
    if (existing != null) {
      keyBytes = Uint8List.fromList(base64Decode(existing));
    } else {
      keyBytes = Uint8List.fromList(
        List<int>.generate(32, (_) => Random.secure().nextInt(256)),
      );
      await prefs.setString(_aesKeyPref, base64Encode(keyBytes));
    }

    return HiveAesCipher(keyBytes);
  }

  void _assertReady() {
    assert(_initialized, 'DataCollectionService.initialize() n\'a pas été appelé.');
  }

  // ─── Écriture — couche C (audio) ────────────────────────────────────────────

  /// Sauvegarde les métadonnées d'un enregistrement audio (lecture ou résumé).
  /// Champ [layer] doit valoir 'C'.
  Future<void> saveAudioRecord(Map<String, dynamic> record) async {
    _assertReady();
    await _sellBox.add(Map<String, dynamic>.from(record));
  }

  // ─── Écriture — couche D (paires NLU) ───────────────────────────────────────

  /// Sauvegarde une paire NLU (texte original + chemin audio du résumé).
  /// Champ [layer] doit valoir 'D'.
  Future<void> saveNluRecord(Map<String, dynamic> record) async {
    _assertReady();
    await _sellBox.add(Map<String, dynamic>.from(record));
  }

  // ─── Lecture ─────────────────────────────────────────────────────────────────

  /// Retourne tous les enregistrements d'une session donnée.
  Future<List<Map<String, dynamic>>> getSessionData(String sessionId) async {
    _assertReady();
    final results = <Map<String, dynamic>>[];
    for (final value in _sellBox.values) {
      if (value is Map && value['session_id'] == sessionId) {
        results.add(Map<String, dynamic>.from(value as Map));
      }
    }
    return results;
  }

  /// Retourne toutes les données en attente d'upload sous forme de JSON.
  Future<String> exportForUpload() async {
    _assertReady();
    final all = _sellBox.values
        .map((v) => Map<String, dynamic>.from(v as Map<dynamic, dynamic>))
        .toList();
    return jsonEncode(all);
  }

  /// Nombre total d'enregistrements dans mentality_sell.
  int get recordCount {
    _assertReady();
    return _sellBox.length;
  }
}
