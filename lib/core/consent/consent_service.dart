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
//                        vs eventHealthData (art. 9, opt., jamais impliqué)
//   - retrait          : withdraw() efface l'enregistrement
//   - ré-information    : hasValidConsent() invalide une version périmée
//
// POURQUOI kConsentVersion N'A PAS BOUGÉ en ajoutant la finalité art. 9 :
// incrémenter la version re-sollicite TOUS les utilisateurs, y compris pour
// l'audio. Or aucun écran ne présente encore le texte de cette finalité — elle
// vaut `false` partout et rien ne peut donc partir. Le texte, et avec lui
// l'incrément de version, arrivent avec l'écran de recueil (LOT F).

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

  /// `true` si un consentement art. 9 VALIDE et À JOUR couvre les réponses de
  /// l'événement des 8 jours (données de santé).
  ///
  /// Volontairement séparé de [hasValidConsent] : le consentement audio
  /// n'implique JAMAIS celui-ci, et le worker event refuse (403) un envoi qui
  /// ne porte pas la finalité [kEventDataPurpose]. Tant que cette méthode
  /// répond `false`, les questionnaires restent jouables et le score
  /// s'affiche — mais rien ne part.
  Future<bool> hasEventDataConsent() async {
    final record = await load();
    return record != null && record.eventHealthData && record.isCurrentVersion;
  }

  /// Enregistre un consentement granulaire et horodaté.
  /// [recordingAndAnalysis] doit être `true` (sinon il n'y a pas de test).
  Future<ConsentRecord> grant({
    required String sessionId,
    required String locale,
    required bool recordingAndAnalysis,
    required bool commercialReuse,
    bool? parentalConsent,
    bool eventHealthData = false,
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
      eventHealthData: eventHealthData,
    );
    return _persist(record);
  }

  /// Accorde ou retire la SEULE finalité art. 9 de l'événement, sans toucher
  /// aux autres. Recueillie à part parce qu'elle arrive à un autre moment (le
  /// gate de l'événement, LOT F) et porte sur d'autres données.
  ///
  /// [sessionId] et [locale] ne servent qu'à créer l'enregistrement quand il
  /// n'en existe aucun (utilisateur qui n'a pas fait l'étape orale) ; ils sont
  /// ignorés s'il en existe déjà un.
  Future<ConsentRecord> setEventHealthData(
    bool granted, {
    String sessionId = '',
    String locale = 'fr',
    DateTime? grantedAt,
  }) async {
    final existant = await load();
    final record = existant?.copyWith(eventHealthData: granted) ??
        ConsentRecord(
          sessionId: sessionId,
          version: kConsentVersion,
          grantedAt: grantedAt ?? DateTime.now().toUtc(),
          locale: locale,
          // Aucune des autres finalités n'est accordée au passage : accorder
          // l'art. 9 ne dit rien de l'audio.
          recordingAndAnalysis: false,
          commercialReuse: false,
          eventHealthData: granted,
        );
    return _persist(record);
  }

  Future<ConsentRecord> _persist(ConsentRecord record) async {
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
