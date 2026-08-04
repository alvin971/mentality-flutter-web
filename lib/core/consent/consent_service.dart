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
// DEUX TEXTES, DEUX VERSIONS. L'écran de recueil art. 9 existe désormais, et
// il présente son PROPRE texte : sa version est donc suivie à part
// (`kEventConsentVersion`, stampée dans `eventHealthDataVersion`), et non par
// l'incrément de `kConsentVersion` qu'on avait d'abord envisagé. Deux raisons
// l'ont emporté :
//   · incrémenter la version partagée aurait re-sollicité TOUS les
//     utilisateurs pour l'AUDIO, dont le texte n'a pas changé d'une virgule ;
//   · une version unique laisse un piège silencieux. Accorder l'art. 9 sur un
//     enregistrement audio plus ancien reconduisait sa version : le
//     consentement se serait affiché « accordé » tout en étant jugé périmé à
//     chaque envoi, et rien ne serait jamais parti — sans un mot.

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
  Future<bool> hasEventDataConsent() async =>
      await eventConsentVersion() != null;

  /// La version du texte art. 9 réellement acceptée — ce qui voyage dans
  /// l'en-tête `X-Consent-Version` de chaque envoi —, ou `null` s'il n'y a pas
  /// de consentement exploitable.
  ///
  /// C'est bien la version DE CE TEXTE-LÀ qui part, pas celle du texte audio :
  /// une preuve de consentement qui désigne le mauvais document ne prouve
  /// rien.
  Future<String?> eventConsentVersion() async {
    final record = await load();
    return (record != null && record.isCurrentEventConsent)
        ? record.eventHealthDataVersion
        : null;
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
      eventHealthDataVersion: eventHealthData ? kEventConsentVersion : null,
    );
    return _persist(record);
  }

  /// Accorde ou retire la SEULE finalité art. 9 de l'événement, sans toucher
  /// aux autres. Recueillie à part parce qu'elle arrive à un autre moment (le
  /// gate de l'événement) et porte sur d'autres données.
  ///
  /// L'octroi stampe [kEventConsentVersion] ; le retrait l'efface. Le
  /// consentement audio, lui, garde sa propre version : elle n'a pas été
  /// re-présentée, donc elle n'a pas à être rafraîchie.
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
    final record = existant?.withEventHealthData(granted) ??
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
          eventHealthDataVersion: granted ? kEventConsentVersion : null,
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
