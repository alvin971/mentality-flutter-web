// lib/core/consent/consent_service.dart
// Service de gestion du consentement RGPD : recueil, preuve, retrait.
//
// Le consentement est stocké en clair dans SharedPreferences sous forme de
// JSON (donnée non sensible : ce sont des métadonnées de consentement, pas le
// contenu audio). Il est volontairement séparé du DataCollectionService chiffré
// pour rester lisible/auditable et survivre indépendamment des boxes Hive.
//
// Garanties RGPD couvertes :
//   - art. 7 (preuve) : version + horodatage + portée stockés
//   - granularité      : recordingAndAnalysis (requis) vs commercialReuse (opt.)
//   - retrait          : withdraw() efface l'enregistrement
//   - ré-information    : hasValidConsent() invalide une version périmée

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'consent_record.dart';

class ConsentService {
  static final ConsentService instance = ConsentService._();
  ConsentService._();

  static const String _key = 'gdpr_consent_record';

  ConsentRecord? _cached;

  /// Charge le consentement persisté (ou null si absent).
  Future<ConsentRecord?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return _cached = null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return _cached = ConsentRecord.fromMap(map);
    } catch (_) {
      return _cached = null;
    }
  }

  /// Dernier consentement chargé en mémoire (sans relire le disque).
  ConsentRecord? get current => _cached;

  /// `true` si un consentement valide ET à jour (bonne version) existe.
  /// Un consentement sur une version périmée du texte est considéré invalide
  /// → l'utilisateur sera re-sollicité.
  Future<bool> hasValidConsent() async {
    final record = await load();
    return record != null &&
        record.recordingAndAnalysis &&
        record.isCurrentVersion;
  }

  /// Enregistre un consentement granulaire et horodaté.
  /// [recordingAndAnalysis] doit être `true` (sinon il n'y a pas de test).
  Future<ConsentRecord> grant({
    required String sessionId,
    required String locale,
    required bool recordingAndAnalysis,
    required bool commercialReuse,
    bool? parentalConsent,
    DateTime? grantedAt,
  }) async {
    final record = ConsentRecord(
      sessionId: sessionId,
      version: kConsentVersion,
      grantedAt: grantedAt ?? DateTime.now().toUtc(),
      locale: locale,
      recordingAndAnalysis: recordingAndAnalysis,
      commercialReuse: commercialReuse,
      parentalConsent: parentalConsent,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(record.toMap()));
    return _cached = record;
  }

  /// Retrait du consentement (droit RGPD art. 7-3). Efface l'enregistrement.
  /// Note : le retrait ne vaut que pour le futur ; la purge des données déjà
  /// collectées relève d'une demande d'effacement séparée (art. 17).
  Future<void> withdraw() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    _cached = null;
  }
}
