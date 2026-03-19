// lib/services/data_collection_service.dart
// Singleton gérant la persistance Hive pour la collecte de données audio.
//
// Architecture des boxes :
//   mentality_sell → couches C (audio) et D (paires NLU) — données licenciables
//   mentality_keep → réservé aux données cognitives secrètes (ouvert, jamais écrit ici)
//
// CONTRAINTE : aucune méthode publique n'écrit dans _keepBox.
// La séparation est garantie structurellement, pas seulement par convention.

import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

class DataCollectionService {
  static final DataCollectionService instance = DataCollectionService._();
  DataCollectionService._();

  static const String _sellBoxName = 'mentality_sell';
  static const String _keepBoxName = 'mentality_keep';

  late Box<dynamic> _sellBox;
  late Box<dynamic> _keepBox;
  bool _initialized = false;

  /// À appeler une fois au démarrage de l'app, après Hive.initFlutter().
  Future<void> initialize() async {
    if (_initialized) return;
    _sellBox = await Hive.openBox<dynamic>(_sellBoxName);
    _keepBox = await Hive.openBox<dynamic>(_keepBoxName);
    _initialized = true;
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
        .map((v) => Map<String, dynamic>.from(v as Map))
        .toList();
    return jsonEncode(all);
  }

  /// Nombre total d'enregistrements dans mentality_sell.
  int get recordCount {
    _assertReady();
    return _sellBox.length;
  }
}
