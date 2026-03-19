// lib/services/session_manager.dart
// Singleton qui génère et conserve un UUID v4 pour toute la durée de la session.
// Le session_id est partagé entre OralReadingTest et OralSummaryTest du même cycle.

import 'package:uuid/uuid.dart';

class SessionManager {
  static final SessionManager instance = SessionManager._();
  SessionManager._();

  final Uuid _uuid = const Uuid();

  /// UUID v4 généré une seule fois à la première lecture, valide jusqu'à
  /// la fermeture de l'app (late final = initialisé au premier accès).
  late final String _sessionId = _uuid.v4();

  /// Retourne le session_id courant.
  String get currentSessionId => _sessionId;

  /// Génère un UUID v4 ponctuel (ex. pour un identifiant d'enregistrement).
  String generateId() => _uuid.v4();
}
