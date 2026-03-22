// lib/services/session_history_service.dart
// Stockage local des sessions de test terminées (historique des résultats).
//
// Chaque entrée contient les scores finaux pour affichage dans ResultsHistoryPage.
// Utilise la box Hive 'session_history' (chiffrée avec la même clé AES que sell).

import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

/// Un résumé de session sauvegardé dans l'historique.
class SessionHistoryEntry {
  final String id;
  final DateTime date;
  final int ageInMonths;
  final int fsiq;
  final int? vci;
  final int? vsi;
  final int? fri;
  final int? wmi;
  final int? psi;
  final String classification;

  const SessionHistoryEntry({
    required this.id,
    required this.date,
    required this.ageInMonths,
    required this.fsiq,
    this.vci,
    this.vsi,
    this.fri,
    this.wmi,
    this.psi,
    required this.classification,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date.toIso8601String(),
        'ageInMonths': ageInMonths,
        'fsiq': fsiq,
        if (vci != null) 'vci': vci,
        if (vsi != null) 'vsi': vsi,
        if (fri != null) 'fri': fri,
        if (wmi != null) 'wmi': wmi,
        if (psi != null) 'psi': psi,
        'classification': classification,
      };

  static SessionHistoryEntry fromMap(Map<dynamic, dynamic> map) =>
      SessionHistoryEntry(
        id: map['id'] as String,
        date: DateTime.parse(map['date'] as String),
        ageInMonths: map['ageInMonths'] as int,
        fsiq: map['fsiq'] as int,
        vci: map['vci'] as int?,
        vsi: map['vsi'] as int?,
        fri: map['fri'] as int?,
        wmi: map['wmi'] as int?,
        psi: map['psi'] as int?,
        classification: map['classification'] as String,
      );
}

/// Singleton qui gère l'historique des évaluations terminées.
class SessionHistoryService {
  static final SessionHistoryService instance = SessionHistoryService._();
  SessionHistoryService._();

  static const String _boxName = 'session_history';

  Box<dynamic>? _box;
  bool _initialized = false;

  Future<void> initialize({HiveCipher? encryptionCipher}) async {
    if (_initialized) return;
    _box = await Hive.openBox<dynamic>(
      _boxName,
      encryptionCipher: encryptionCipher,
    );
    _initialized = true;
  }

  void _assertReady() {
    assert(_initialized, 'SessionHistoryService.initialize() n\'a pas été appelé.');
  }

  /// Sauvegarde un résultat de session dans l'historique.
  Future<void> saveEntry(SessionHistoryEntry entry) async {
    _assertReady();
    await _box!.put(entry.id, jsonEncode(entry.toMap()));
  }

  /// Retourne toutes les entrées, triées du plus récent au plus ancien.
  List<SessionHistoryEntry> getAll() {
    _assertReady();
    final entries = <SessionHistoryEntry>[];
    for (final value in _box!.values) {
      try {
        final map = jsonDecode(value as String) as Map<String, dynamic>;
        entries.add(SessionHistoryEntry.fromMap(map));
      } catch (_) {
        // Ignorer les entrées corrompues
      }
    }
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  /// Supprime une entrée par son identifiant.
  Future<void> deleteEntry(String id) async {
    _assertReady();
    await _box!.delete(id);
  }

  /// Nombre d'évaluations sauvegardées.
  int get count {
    _assertReady();
    return _box!.length;
  }
}
