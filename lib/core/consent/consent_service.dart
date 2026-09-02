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
//   - retrait          : withdraw() efface l'enregistrement ET pose un
//                        marqueur durable, que syncFromToken respecte. Le
//                        parcours utilisateur qui l'appelle : accueil →
//                        « Confidentialité et consentement » (carte 04) →
//                        « Retirer mon consentement » → confirmation.
//                        Voir features/privacy/.../privacy_consent_page.dart.
//   - ré-information    : hasValidConsent() invalide une version périmée —
//                        pour les consentements recueillis DANS l'app. Ceux
//                        portés par le token (recueillis sur le site avant
//                        l'émission du passe) portent la version des textes
//                        légaux du site : voir ConsentSource et syncFromToken.
//                        Cette version-là est confrontée à
//                        AppConstants.kAcceptedLegalVersions — un texte que la
//                        build ne connaît pas ne vaut pas consentement.
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
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../services/token_plan.dart';
import 'consent_record.dart';

class ConsentService {
  static final ConsentService instance = ConsentService._();
  ConsentService._();

  static const String _key = 'gdpr_consent_record';

  /// Marqueur de RETRAIT EXPLICITE (art. 7-3), horodaté en ISO 8601 UTC.
  ///
  /// Effacer l'enregistrement ne suffisait pas. À la réouverture de l'étape
  /// orale, [syncFromToken] réécrivait le consentement depuis le passe et le
  /// retrait était défait sans un mot : le bouton aurait promis un retrait qui
  /// ne durait que jusqu'à l'écran suivant. Le marqueur SURVIT au passe et ne
  /// se lève que par un consentement de nouveau EXPLICITE ([grant]) — c'est
  /// exactement la symétrie qu'exige l'art. 7-3.
  static const String _cleRetrait = 'gdpr_consent_withdrawn_at';

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

  /// `true` si un consentement AUDIO valide couvre l'enregistrement.
  ///
  /// Deux régimes, selon l'origine :
  ///   · [ConsentSource.inApp] — règle historique inchangée : la version du
  ///     texte doit être la courante, sinon l'utilisateur est re-sollicité ;
  ///   · [ConsentSource.token] — le consentement a été recueilli sur le site
  ///     avant l'émission du passe et porte la version des TEXTES LÉGAUX
  ///     (`cv`), qui n'a aucune raison d'être égale à [kConsentVersion].
  ///     La comparer à celle du texte in-app déclarerait périmé un
  ///     consentement tout juste donné, et ferait réapparaître un écran que la
  ///     personne vient de traverser sur le site.
  ///
  /// Dans les deux cas, [ConsentRecord.recordingAndAnalysis] reste la
  /// condition sine qua non : c'est lui qui autorise le micro.
  ///
  /// DEUX GARDES S'AJOUTENT, toutes deux fail-closed :
  ///   · un RETRAIT explicite encore en vigueur ferme la porte quoi qu'il y
  ///     ait sur le disque — le retrait ne se laisse contredire par aucun
  ///     enregistrement, si valide soit-il ;
  ///   · la version portée par un consentement d'origine token doit
  ///     appartenir à [AppConstants.kAcceptedLegalVersions]. Le `cv` n'est
  ///     comparé à rien tant qu'on ne le confronte pas à une liste : un passe
  ///     se réclamant d'un texte que cette build ne connaît pas — retiré
  ///     depuis, ou jamais publié — autoriserait sinon le micro pour toujours.
  ///     Version inconnue ⇒ repli sur l'écran in-app, qui re-sollicite sur le
  ///     texte courant.
  Future<bool> hasValidConsent() async {
    if (await isWithdrawn()) return false;
    final record = await load();
    if (record == null || !record.recordingAndAnalysis) return false;
    if (record.source == ConsentSource.token) {
      return AppConstants.kAcceptedLegalVersions.contains(record.version);
    }
    return record.isCurrentVersion;
  }

  /// Date du retrait explicite encore en vigueur, ou `null` s'il n'y en a pas.
  Future<DateTime?> withdrawnAt() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cleRetrait);
    return raw == null ? null : DateTime.tryParse(raw)?.toUtc();
  }

  /// `true` tant que le retrait n'a pas été levé par un consentement de
  /// nouveau explicite ([grant]).
  Future<bool> isWithdrawn() async => (await withdrawnAt()) != null;

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
  ///
  /// LÈVE le marqueur de retrait : c'est le seul geste qui le lève, parce que
  /// c'est le seul qui vienne de la personne elle-même, face au texte. Un
  /// retrait qu'on ne pourrait plus défaire interdirait de re-consentir —
  /// l'art. 7-3 protège le retrait, pas l'impossibilité de revenir.
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
    if (recordingAndAnalysis) await _leveLeRetrait();
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

  /// Aligne le consentement AUDIO local sur ce que dit le token.
  ///
  /// C'est le pont entre le recueil fait sur mental-et.com (bloc B de la page
  /// d'inscription) et l'app : aucun écran in-app n'est présenté quand le
  /// token porte déjà le plan.
  ///
  /// Trois cas :
  ///   · [TokenPlan.free] / [TokenPlan.paid] — le consentement local est
  ///     RÉÉCRIT depuis le token : `version = cv`, `source = token`,
  ///     `recordingAndAnalysis` seulement pour le Gratuit,
  ///     `commercialReuse = free && cc`.
  ///   · [TokenPlan.unknown] sur un enregistrement d'origine in-app (ou
  ///     absence d'enregistrement) — NO-OP total. Un token `sv: 2` ne dit rien
  ///     du consentement : il ne doit ni en créer, ni en effacer un.
  ///   · [TokenPlan.unknown] sur un enregistrement d'origine token — le passe
  ///     qui portait ce consentement n'est plus là (token remplacé par un
  ///     `sv: 2`, ou collé depuis un autre appareil). La preuve a disparu :
  ///     l'audio est NEUTRALISÉ (`recordingAndAnalysis` et `commercialReuse`
  ///     à `false`, retour à `source: inApp`) et l'écran in-app reprend la
  ///     main. Ne rien faire ici laisserait le micro autorisé par une preuve
  ///     qu'on ne peut plus produire.
  ///
  /// IDEMPOTENTE : la date vient du claim `d` (jour d'émission, epoch UTC),
  /// jamais de `DateTime.now()`. Deux appels successifs produisent exactement
  /// le même `toMap()`.
  ///
  /// L'art. 9 (données de santé de l'événement) est RECONDUIT tel quel dans
  /// tous les cas : le token ne parle que de l'audio, et un consentement de
  /// santé ne s'accorde ni ne se retire par ricochet.
  Future<ConsentRecord?> syncFromToken(
    TokenPlanInfo info, {
    required String locale,
    String sessionId = '',
  }) async {
    final existant = await load();

    // UN PASSE NE DÉFAIT PAS UN RETRAIT. Sans cette garde, le retrait ne
    // survivait pas à l'ouverture suivante de l'étape orale : le passe
    // Gratuit réécrivait `recordingAndAnalysis: true` et le micro se
    // rouvrait tout seul. Re-consentir reste possible, mais par l'écran
    // in-app et rien d'autre — c'est-à-dire par un geste de la personne.
    if (await isWithdrawn()) return existant;

    if (info.plan == TokenPlan.unknown) {
      if (existant == null || existant.source != ConsentSource.token) {
        return existant; // no-op : rien à aligner.
      }
      return _persist(existant.copyAudio(
        recordingAndAnalysis: false,
        commercialReuse: false,
        source: ConsentSource.inApp,
      ));
    }

    final estGratuit = info.plan == TokenPlan.free;
    final base = existant ??
        ConsentRecord(
          sessionId: sessionId,
          version: kConsentVersion,
          grantedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
          locale: locale,
          recordingAndAnalysis: false,
          commercialReuse: false,
        );

    return _persist(base.copyAudio(
      version: info.legalVersion ?? kConsentVersion,
      grantedAt: _jourEmission(info.issuedDay),
      locale: locale,
      recordingAndAnalysis: estGratuit,
      commercialReuse: estGratuit && info.corpusConsent,
      source: ConsentSource.token,
    ));
  }

  /// Date de recueil dérivée du claim `d` (jours depuis l'epoch UTC).
  /// Volontairement sans heure : c'est la granularité que le tokeniseur émet,
  /// et la seule qui rende [syncFromToken] rejouable à l'identique.
  static DateTime _jourEmission(int? issuedDay) =>
      DateTime.utc(1970, 1, 1).add(Duration(days: issuedDay ?? 0));

  Future<ConsentRecord> _persist(ConsentRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(record.toMap()));
    return _cached = record;
  }

  /// Retrait du consentement (droit RGPD art. 7-3).
  ///
  /// Efface l'enregistrement ET pose le marqueur de retrait, qui interdit à
  /// [syncFromToken] de le reconstituer depuis le passe. Sans le marqueur, le
  /// retrait durait jusqu'au prochain passage par l'étape orale.
  ///
  /// Le retrait ne vaut que pour l'AVENIR : les enregistrements déjà envoyés
  /// ne sont pas rappelés (leur effacement relève de l'art. 17, par une
  /// demande séparée). Ce que l'écran de retrait dit à la personne, mot pour
  /// mot.
  Future<void> withdraw({DateTime? at}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    await prefs.setString(
      _cleRetrait,
      (at ?? DateTime.now().toUtc()).toUtc().toIso8601String(),
    );
    _cached = null;
  }

  Future<void> _leveLeRetrait() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cleRetrait);
  }

  /// TESTS UNIQUEMENT : remet le service à l'état « jamais rien vu » —
  /// enregistrement effacé, marqueur de retrait effacé, cache vidé.
  ///
  /// Volontairement distinct de [withdraw] : un banc d'essai qui appelait
  /// `withdraw()` pour se remettre à zéro partirait désormais d'un état où le
  /// consentement a été RETIRÉ, ce qui n'est pas la même chose que de n'avoir
  /// jamais consenti — et neutraliserait [syncFromToken] dans tout le fichier.
  @visibleForTesting
  Future<void> debugReset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    await prefs.remove(_cleRetrait);
    _cached = null;
  }
}
