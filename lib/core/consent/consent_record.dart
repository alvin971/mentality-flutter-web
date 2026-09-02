// lib/core/consent/consent_record.dart
// Enregistrement auditable d'un consentement RGPD.
//
// Le RGPD (art. 7) impose de pouvoir PROUVER le consentement : qui, quand,
// pour quoi, et sur quelle version de la politique. Un simple booléen ne
// suffit pas. Cette structure capture chaque dimension et voyage avec les
// données uploadées (chaque enregistrement audio porte sa preuve de consentement).

/// Version courante du texte de consentement AUDIO (enregistrement, analyse,
/// réutilisation commerciale).
/// À INCRÉMENTER à chaque modification matérielle de CES finalités ou de leur
/// texte : les utilisateurs ayant consenti à une version antérieure seront
/// re-sollicités.
const String kConsentVersion = '2026-06-12.v1';

/// Version courante du texte de consentement ART. 9 (réponses de l'événement
/// des 8 jours). VOLONTAIREMENT DISTINCTE de [kConsentVersion].
///
/// Les deux finalités ont des textes différents, présentés à des moments
/// différents, et n'ont aucune raison de vieillir ensemble. Une seule version
/// partagée forcerait un choix impossible le jour où l'un des deux textes
/// change : ou bien re-solliciter tout le monde pour l'audio à cause d'une
/// phrase ajoutée au texte santé, ou bien laisser un consentement art. 9 se
/// réclamer d'une version de texte qu'il n'a jamais lue — c'est-à-dire une
/// preuve fausse au sens de l'art. 7.
const String kEventConsentVersion = '2026-07-28.e1';

/// Finalité art. 9 des réponses de l'événement des 8 jours, telle qu'elle
/// voyage jusqu'au worker (`X-Consent-Purpose`).
///
/// ⚠️ Doit rester identique à `EXPECTED_PURPOSE` dans workers/event/index.js.
/// Le worker REFUSE (403) un envoi qui ne porte pas exactement cette chaîne :
/// c'est ce qui empêche un consentement recueilli pour l'audio d'autoriser un
/// envoi de données de santé.
const String kEventDataPurpose = 'event-health-research';

/// D'où vient le consentement AUDIO consigné.
///
/// La distinction est juridique, pas cosmétique : depuis le 2026-09-02, le
/// consentement au corpus vocal est recueilli SUR LE SITE, avant l'émission du
/// passe, et voyage dans le token signé. Sa preuve, c'est le token ; sa
/// version, c'est celle des textes légaux du site (`cv`), qui n'a aucune
/// raison de coïncider avec [kConsentVersion], la version du texte de l'écran
/// in-app. Sans ce champ, un consentement porté par le token serait jugé
/// périmé à la première comparaison de version — et l'étape orale
/// re-demanderait un accord déjà donné.
enum ConsentSource {
  /// Recueilli par l'écran de consentement de l'application (chemin
  /// historique, toujours en service pour les passes `sv: 2`).
  inApp,

  /// Porté par le token signé émis après recueil sur mental-et.com.
  token,
}

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

  /// OPTIONNEL, art. 9 RGPD : réponses aux questionnaires de l'événement des
  /// 8 jours (santé mentale, neurodiversité, bloc diagnostic) envoyées pour
  /// « dépistage informatif + construction/amélioration de nos échelles ».
  ///
  /// Finalité DISTINCTE de [recordingAndAnalysis] et jamais impliquée par lui :
  /// une donnée de santé exige un consentement EXPLICITE et propre. Défaut
  /// `false`, y compris pour tout enregistrement relu d'une version antérieure
  /// — un consentement audio déjà donné ne doit pas se transformer
  /// rétroactivement en consentement de santé.
  ///
  /// Sans lui : les questionnaires restent jouables et le score s'affiche,
  /// mais **rien n'est envoyé**.
  final bool eventHealthData;

  /// Version du texte art. 9 RÉELLEMENT LUE au moment de l'accord — la preuve
  /// que l'art. 7 exige, pour cette finalité-là.
  ///
  /// `null` tant que l'art. 9 n'a pas été accordé, et REMIS À `null` au
  /// retrait : une version qui survivrait à un retrait ferait re-valoir le
  /// consentement au prochain octroi sans que le texte ait été relu.
  final String? eventHealthDataVersion;

  /// Origine du consentement AUDIO ([version] désigne alors le texte de cette
  /// origine-là). Défaut [ConsentSource.inApp] : c'était le seul chemin
  /// possible avant le 2026-09-02.
  final ConsentSource source;

  const ConsentRecord({
    required this.sessionId,
    required this.version,
    required this.grantedAt,
    required this.locale,
    required this.recordingAndAnalysis,
    required this.commercialReuse,
    this.parentalConsent,
    this.eventHealthData = false,
    this.eventHealthDataVersion,
    this.source = ConsentSource.inApp,
  });

  Map<String, dynamic> toMap() => {
        'session_id': sessionId,
        'version': version,
        'granted_at': grantedAt.toUtc().toIso8601String(),
        'locale': locale,
        'recording_and_analysis': recordingAndAnalysis,
        'commercial_reuse': commercialReuse,
        if (parentalConsent != null) 'parental_consent': parentalConsent,
        'event_health_data': eventHealthData,
        if (eventHealthDataVersion != null)
          'event_health_data_version': eventHealthDataVersion,
        'source': source.name,
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
        // Absent = false : fail-closed. Un enregistrement écrit avant que cette
        // finalité n'existe n'autorise aucun envoi de santé.
        eventHealthData: map['event_health_data'] as bool? ?? false,
        // Absente = pas de preuve = pas de consentement exploitable, quoi que
        // dise le booléen ci-dessus (voir [isCurrentEventConsent]).
        eventHealthDataVersion: map['event_health_data_version'] as String?,
        // Absente = in-app : c'est le comportement de TOUS les enregistrements
        // écrits avant que le token ne porte le consentement. Fail-safe — la
        // règle in-app (version courante exigée) reste alors celle qui décide.
        source: _sourceFromName(map['source']),
      );

  static ConsentSource _sourceFromName(Object? raw) {
    for (final s in ConsentSource.values) {
      if (s.name == raw) return s;
    }
    return ConsentSource.inApp;
  }

  /// `true` si le consentement AUDIO correspond à la version courante de SON
  /// texte. Sert à re-solliciter l'utilisateur quand la politique change.
  bool get isCurrentVersion => version == kConsentVersion;

  /// `true` si l'art. 9 a été accordé SUR LE TEXTE COURANT.
  ///
  /// Exige les deux : l'accord et sa preuve de version. Un enregistrement
  /// portant `event_health_data: true` sans version est soit antérieur à cette
  /// preuve, soit trafiqué — dans les deux cas on ne sait pas à quoi la
  /// personne a dit oui, donc c'est non.
  bool get isCurrentEventConsent =>
      eventHealthData && eventHealthDataVersion == kEventConsentVersion;

  /// Accorde ou retire la SEULE finalité art. 9, en stampant (ou en effaçant)
  /// la version du texte lue à cet instant. Les autres finalités sont
  /// reconduites telles quelles : accorder l'art. 9 ne rafraîchit pas le
  /// consentement audio, dont le texte n'a pas été re-présenté.
  ConsentRecord withEventHealthData(bool granted) => ConsentRecord(
        sessionId: sessionId,
        version: version,
        grantedAt: grantedAt,
        locale: locale,
        recordingAndAnalysis: recordingAndAnalysis,
        commercialReuse: commercialReuse,
        parentalConsent: parentalConsent,
        eventHealthData: granted,
        eventHealthDataVersion: granted ? kEventConsentVersion : null,
        source: source,
      );

  /// Remplace la SEULE partie AUDIO du consentement (portée, version, date,
  /// origine) en reconduisant l'art. 9 tel quel.
  ///
  /// Le pendant exact de [withEventHealthData], dans l'autre sens : re-poser
  /// le consentement audio depuis le token ne dit rien des données de santé,
  /// et ne doit donc ni les accorder, ni les retirer, ni les re-dater.
  ConsentRecord copyAudio({
    String? sessionId,
    String? version,
    DateTime? grantedAt,
    String? locale,
    bool? recordingAndAnalysis,
    bool? commercialReuse,
    ConsentSource? source,
  }) =>
      ConsentRecord(
        sessionId: sessionId ?? this.sessionId,
        version: version ?? this.version,
        grantedAt: grantedAt ?? this.grantedAt,
        locale: locale ?? this.locale,
        recordingAndAnalysis: recordingAndAnalysis ?? this.recordingAndAnalysis,
        commercialReuse: commercialReuse ?? this.commercialReuse,
        parentalConsent: parentalConsent,
        eventHealthData: eventHealthData,
        eventHealthDataVersion: eventHealthDataVersion,
        source: source ?? this.source,
      );
}
