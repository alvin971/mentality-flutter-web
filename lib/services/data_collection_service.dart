// lib/services/data_collection_service.dart
// Singleton gérant la persistance Hive pour la collecte de données.
//
// Architecture des boxes :
//   mentality_sell → couches C (audio) et D (paires NLU) — données licenciables
//   mentality_keep → données cognitives secrètes (résultats par item des
//                    sous-tests : temps de réponse, choix, graine, palier)
//
// CONTRAINTE : les données de _keepBox ne QUITTENT JAMAIS l'appareil via ce
// service — exportForUpload() / getSessionData() ne lisent que _sellBox.
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
  // _keepBox : données cognitives locales — écrite par saveCognitiveRecord,
  // jamais lue par les chemins d'export (exportForUpload / getSessionData).
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

  // ─── Écriture — données cognitives (box keep, jamais exportée) ──────────────

  /// Sauvegarde un enregistrement cognitif par item (résultats de sous-test :
  /// réussite, temps de réponse, choix, graine du générateur, palier…).
  ///
  /// Ces données vont dans `mentality_keep` : elles ne sont JAMAIS incluses
  /// dans [exportForUpload] ni [getSessionData] (qui ne lisent que la box
  /// sell) — elles restent sur l'appareil.
  Future<void> saveCognitiveRecord(Map<String, dynamic> record) async {
    _assertReady();
    await _keepBox.add(Map<String, dynamic>.from(record));
  }

  /// Lecture locale des enregistrements cognitifs d'une session (analyse
  /// on-device, debug). Ne fait partie d'aucun chemin d'export.
  Future<List<Map<String, dynamic>>> getCognitiveSessionData(
      String sessionId) async {
    _assertReady();
    final results = <Map<String, dynamic>>[];
    for (final value in _keepBox.values) {
      if (value is Map && value['session_id'] == sessionId) {
        results.add(Map<String, dynamic>.from(value));
      }
    }
    return results;
  }

  /// Nombre total d'enregistrements cognitifs locaux.
  int get cognitiveRecordCount {
    _assertReady();
    return _keepBox.length;
  }

  // ─── Lecture ─────────────────────────────────────────────────────────────────

  /// Retourne tous les enregistrements d'une session donnée.
  Future<List<Map<String, dynamic>>> getSessionData(String sessionId) async {
    _assertReady();
    final results = <Map<String, dynamic>>[];
    for (final value in _sellBox.values) {
      if (value is Map && value['session_id'] == sessionId) {
        results.add(Map<String, dynamic>.from(value));
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
