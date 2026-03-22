import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/models/complete_test_session.dart';

/// Service de sauvegarde et restauration d'une session de test en cours.
///
/// Permet à l'utilisateur de fermer l'app et de reprendre le test
/// là où il s'était arrêté.
///
/// Les données sont stockées dans une Hive Box dédiée.
class SessionPersistenceService {
  static const String _boxName = 'session_persistence';
  static const String _sessionKey = 'current_session';
  static const String _ageKey = 'current_age_months';

  static Box? _box;

  static final SessionPersistenceService instance =
      SessionPersistenceService._();
  SessionPersistenceService._();

  Future<void> initialize({HiveCipher? encryptionCipher}) async {
    _box = await Hive.openBox(_boxName, encryptionCipher: encryptionCipher);
  }

  /// Sauvegarde la session en cours.
  Future<void> saveSession(CompleteTestSession session, int ageInMonths) async {
    if (_box == null) return;
    final data = _sessionToJson(session);
    await _box!.put(_sessionKey, data);
    await _box!.put(_ageKey, ageInMonths);
  }

  /// Charge la session en cours si elle existe.
  ({CompleteTestSession session, int ageInMonths})? loadSession() {
    if (_box == null) return null;
    final data = _box!.get(_sessionKey);
    final age = _box!.get(_ageKey);
    if (data == null || age == null) return null;
    try {
      final session = _sessionFromJson(data as Map);
      return (session: session, ageInMonths: age as int);
    } catch (_) {
      return null;
    }
  }

  /// Supprime la session sauvegardée (après complétion ou abandon).
  Future<void> clearSession() async {
    if (_box == null) return;
    await _box!.delete(_sessionKey);
    await _box!.delete(_ageKey);
  }

  /// Indique si une session partielle existe.
  bool get hasPendingSession {
    if (_box == null) return false;
    return _box!.containsKey(_sessionKey);
  }

  // ─── Sérialisation ─────────────────────────────────────────────────────────

  Map<String, dynamic> _sessionToJson(CompleteTestSession s) {
    return {
      'startTime': s.startTime.toIso8601String(),
      'endTime': s.endTime?.toIso8601String(),
      'similaritiesScore': s.similaritiesScore,
      'vocabularyScore': s.vocabularyScore,
      'informationScore': s.informationScore,
      'cubesScore': s.cubesScore,
      'matricesScore': s.matricesScore,
      'visualPuzzlesScore': s.visualPuzzlesScore,
      'digitSpanScore': s.digitSpanScore,
      'arithmeticScore': s.arithmeticScore,
      'codingScore': s.codingScore,
      'symbolSearchScore': s.symbolSearchScore,
      'pictureSpanScore': s.pictureSpanScore,
      'figureWeightsScore': s.figureWeightsScore,
      'currentTestIndex': s.currentTestIndex,
      'completedTests': jsonEncode(s.completedTests),
    };
  }

  CompleteTestSession _sessionFromJson(Map raw) {
    final data = Map<String, dynamic>.from(raw);
    return CompleteTestSession(
      startTime: DateTime.parse(data['startTime'] as String),
      endTime: data['endTime'] != null
          ? DateTime.parse(data['endTime'] as String)
          : null,
      similaritiesScore: data['similaritiesScore'] as int?,
      vocabularyScore: data['vocabularyScore'] as int?,
      informationScore: data['informationScore'] as int?,
      cubesScore: data['cubesScore'] as int?,
      matricesScore: data['matricesScore'] as int?,
      visualPuzzlesScore: data['visualPuzzlesScore'] as int?,
      digitSpanScore: data['digitSpanScore'] as int?,
      arithmeticScore: data['arithmeticScore'] as int?,
      codingScore: data['codingScore'] as int?,
      symbolSearchScore: data['symbolSearchScore'] as int?,
      pictureSpanScore: data['pictureSpanScore'] as int?,
      figureWeightsScore: data['figureWeightsScore'] as int?,
      currentTestIndex: data['currentTestIndex'] as int? ?? 0,
      completedTests: data['completedTests'] != null
          ? List<String>.from(
              jsonDecode(data['completedTests'] as String) as List)
          : [],
    );
  }
}
