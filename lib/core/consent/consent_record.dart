// lib/core/consent/consent_record.dart
// Enregistrement auditable d'un consentement RGPD.
//
// Le RGPD (art. 7) impose de pouvoir PROUVER le consentement : qui, quand,
// pour quoi, et sur quelle version de la politique. Un simple booléen ne
// suffit pas. Cette structure capture chaque dimension et voyage avec les
// données uploadées (chaque enregistrement audio porte sa preuve de consentement).

/// Version courante du texte de consentement.
/// À INCRÉMENTER à chaque modification matérielle des finalités ou du texte :
/// les utilisateurs ayant consenti à une version antérieure seront re-sollicités.
const String kConsentVersion = '2026-06-12.v1';

/// Un consentement granulaire, horodaté et versionné.
class ConsentRecord {
  /// Identifiant de session auquel ce consentement se rattache.
  final String sessionId;

  /// Version du texte de consentement acceptée.
  final String version;

  /// Date/heure exacte du recueil (ISO 8601, UTC).
  final DateTime grantedAt;

  /// Langue dans laquelle le consentement a été présenté ('fr' / 'en').
  final String locale;

  /// OBLIGATOIRE : enregistrement de la voix + analyse interne pour réaliser
  /// le test. Sans ce consentement, le test oral n'est pas possible.
  /// Toujours `true` quand un ConsentRecord existe (sinon il n'est pas créé).
  final bool recordingAndAnalysis;

  /// OPTIONNEL : réutilisation des enregistrements (anonymisés) à des fins de
  /// recherche ET commerciales, y compris cession à des tiers. Indépendant :
  /// l'utilisateur peut faire le test sans l'accorder.
  final bool commercialReuse;

  /// Point d'extension mineurs : `true` si un consentement parental vérifiable
  /// a été recueilli. `null` tant que le flux mineurs n'est pas activé.
  final bool? parentalConsent;

  const ConsentRecord({
    required this.sessionId,
    required this.version,
    required this.grantedAt,
    required this.locale,
    required this.recordingAndAnalysis,
    required this.commercialReuse,
    this.parentalConsent,
  });

  Map<String, dynamic> toMap() => {
        'session_id': sessionId,
        'version': version,
        'granted_at': grantedAt.toUtc().toIso8601String(),
        'locale': locale,
        'recording_and_analysis': recordingAndAnalysis,
        'commercial_reuse': commercialReuse,
        if (parentalConsent != null) 'parental_consent': parentalConsent,
      };

  static ConsentRecord fromMap(Map<dynamic, dynamic> map) => ConsentRecord(
        sessionId: map['session_id'] as String? ?? '',
        version: map['version'] as String? ?? '',
        grantedAt:
            DateTime.tryParse(map['granted_at'] as String? ?? '')?.toUtc() ??
                DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        locale: map['locale'] as String? ?? 'fr',
        recordingAndAnalysis: map['recording_and_analysis'] as bool? ?? false,
        commercialReuse: map['commercial_reuse'] as bool? ?? false,
        parentalConsent: map['parental_consent'] as bool?,
      );

  /// `true` si ce consentement correspond à la version courante du texte.
  /// Sert à re-solliciter l'utilisateur quand la politique change.
  bool get isCurrentVersion => version == kConsentVersion;
}
