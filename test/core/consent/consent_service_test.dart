// Le consentement art. 9 : accordé explicitement, ou pas du tout.
//
// Les réponses de l'événement des 8 jours sont des données de SANTÉ. Le RGPD
// (art. 9) exige pour elles un consentement explicite et propre — jamais
// déduit d'un autre. Ce fichier verrouille les quatre façons dont ce
// consentement pourrait, par inadvertance, se mettre à valoir « oui » :
//
//   · en héritant de celui de l'audio ;
//   · en apparaissant par défaut sur un enregistrement neuf ;
//   · en survivant à un retrait ;
//   · en revenant d'un enregistrement écrit avant que la finalité n'existe.
//
// Chacune de ces quatre erreurs se traduirait par un envoi de données de santé
// sans base légale. Le défaut, partout, est `false`.

import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/core/consent/consent_record.dart';
import 'package:mentality/core/consent/consent_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final service = ConsentService.instance;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await service.withdraw();
  });

  test('le consentement AUDIO n\'emporte pas celui de l\'art. 9', () async {
    await service.grant(
      sessionId: 's1',
      locale: 'fr',
      recordingAndAnalysis: true,
      commercialReuse: true, // même le plus large des consentements audio
    );

    expect(await service.hasValidConsent(), isTrue);
    expect(await service.hasEventDataConsent(), isFalse,
        reason: 'une donnée de santé exige un consentement PROPRE : accepter '
            'l\'enregistrement de sa voix n\'est pas accepter d\'envoyer ses '
            'réponses de santé');
  });

  test('sans aucun enregistrement, rien ne peut partir', () async {
    expect(await service.hasEventDataConsent(), isFalse);
  });

  test('accordé explicitement, il vaut — et lui seul bouge', () async {
    await service.grant(
      sessionId: 's1',
      locale: 'fr',
      recordingAndAnalysis: true,
      commercialReuse: false,
    );

    await service.setEventHealthData(true);

    expect(await service.hasEventDataConsent(), isTrue);
    final record = await service.load();
    expect(record!.recordingAndAnalysis, isTrue,
        reason: 'les autres finalités sont intactes');
    expect(record.commercialReuse, isFalse,
        reason: 'accorder l\'art. 9 n\'accorde pas la cession commerciale');
  });

  test('accordé sans enregistrement préalable, il n\'accorde QUE lui-même',
      () async {
    await service.setEventHealthData(true, sessionId: 's2', locale: 'de');

    final record = await service.load();
    expect(record!.eventHealthData, isTrue);
    expect(record.recordingAndAnalysis, isFalse,
        reason: 'l\'art. 9 ne dit rien de l\'audio');
    expect(record.commercialReuse, isFalse);
  });

  test('retiré, il cesse immédiatement de valoir', () async {
    await service.setEventHealthData(true);
    expect(await service.hasEventDataConsent(), isTrue);

    await service.setEventHealthData(false);
    expect(await service.hasEventDataConsent(), isFalse,
        reason: 'art. 7-3 : le retrait doit être aussi simple que l\'octroi');
  });

  test('withdraw() efface aussi la finalité art. 9', () async {
    await service.setEventHealthData(true);

    await service.withdraw();

    expect(await service.hasEventDataConsent(), isFalse);
    expect(await service.load(), isNull);
  });

  test('un enregistrement écrit AVANT que la finalité existe vaut « non »',
      () {
    // La forme exacte d'un enregistrement stocké par une version antérieure :
    // aucune clé `event_health_data`.
    final ancien = ConsentRecord.fromMap({
      'session_id': 's1',
      'version': kConsentVersion,
      'granted_at': '2026-06-20T10:00:00.000Z',
      'locale': 'fr',
      'recording_and_analysis': true,
      'commercial_reuse': true,
    });

    expect(ancien.eventHealthData, isFalse,
        reason: 'fail-closed : une clé absente ne doit jamais se relire en '
            '« oui », sinon d\'anciens utilisateurs verraient leurs réponses '
            'de santé partir sans avoir rien accepté');
  });

  test('un consentement art. 9 sur une version périmée ne vaut plus', () async {
    await service.setEventHealthData(true);
    final record = await service.load();

    // On simule le vieillissement du TEXTE ART. 9 : la version stockée pour
    // cette finalité-là n'est plus la courante.
    final perime = ConsentRecord.fromMap({
      ...record!.toMap(),
      'event_health_data_version': 'version-perimee',
    });

    expect(perime.eventHealthData, isTrue);
    expect(perime.isCurrentEventConsent, isFalse);
    // hasEventDataConsent exige les DEUX : la finalité et sa preuve de version.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gdpr_consent_record', _json(perime));
    expect(await service.hasEventDataConsent(), isFalse,
        reason: 'changer le texte re-sollicite : on ne parle plus de la même '
            'chose');
    expect(await service.eventConsentVersion(), isNull);
  });

  test('un « oui » art. 9 SANS preuve de version ne vaut pas', () async {
    // La forme qu'aurait un enregistrement trafiqué, ou écrit par une version
    // du code où la preuve n'existait pas encore : le booléen dit oui, mais
    // rien ne dit à QUOI.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'gdpr_consent_record',
      '{"session_id":"s1","version":"$kConsentVersion",'
          '"granted_at":"2026-07-01T10:00:00.000Z","locale":"fr",'
          '"recording_and_analysis":true,"commercial_reuse":false,'
          '"event_health_data":true}',
    );

    expect(await service.hasEventDataConsent(), isFalse,
        reason: 'sans savoir quel texte a été lu, il n\'y a pas de '
            'consentement éclairé — donc pas de consentement');
  });

  group('les deux textes vieillissent séparément', () {
    test('périmer le texte AUDIO ne périme pas l\'art. 9', () async {
      await service.grant(
        sessionId: 's1',
        locale: 'fr',
        recordingAndAnalysis: true,
        commercialReuse: false,
      );
      await service.setEventHealthData(true);

      final record = await service.load();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'gdpr_consent_record',
        _json(ConsentRecord.fromMap({
          ...record!.toMap(),
          'version': 'ancien-texte-audio',
        })),
      );

      expect(await service.hasValidConsent(), isFalse,
          reason: 'le texte audio a changé : il faut re-solliciter POUR LUI');
      expect(await service.hasEventDataConsent(), isTrue,
          reason: 'le texte art. 9, lui, n\'a pas bougé — le lier à la '
              'version audio re-solliciterait tout le monde pour une phrase '
              'ajoutée ailleurs');
    });

    test('accorder l\'art. 9 ne rafraîchit pas la version du texte audio',
        () async {
      // Un consentement audio recueilli sur un texte ANCIEN, comme il en
      // existe sur les téléphones.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'gdpr_consent_record',
        '{"session_id":"s1","version":"ancien-texte-audio",'
            '"granted_at":"2026-01-01T10:00:00.000Z","locale":"fr",'
            '"recording_and_analysis":true,"commercial_reuse":false,'
            '"event_health_data":false}',
      );

      await service.setEventHealthData(true);
      final record = await service.load();

      expect(record!.version, 'ancien-texte-audio',
          reason: 'accepter le texte santé ne prouve rien sur le texte audio, '
              'qui n\'a pas été re-présenté');
      // Et pourtant l'art. 9 vaut : c'est tout l'intérêt de la séparation.
      // Avec une version unique, ce cas donnait un consentement « accordé »
      // que chaque envoi aurait jugé périmé — rien ne serait jamais parti.
      expect(await service.hasEventDataConsent(), isTrue);
      expect(await service.eventConsentVersion(), kEventConsentVersion);
    });

    test('le retrait efface la preuve, pas seulement le booléen', () async {
      await service.setEventHealthData(true);
      await service.setEventHealthData(false);

      final record = await service.load();
      expect(record!.eventHealthDataVersion, isNull,
          reason: 'une preuve qui survit au retrait ferait re-valoir le '
              'consentement au prochain octroi sans que le texte soit relu');
    });
  });

  test('la finalité voyage jusqu\'au worker sous son nom exact', () {
    expect(kEventDataPurpose, 'event-health-research',
        reason: 'valeur figée : workers/event/index.js refuse (403) toute '
            'autre chaîne. La garde de parité vit dans '
            'test/features/waiting_event/event_transport_wire_test.dart');
  });
}

String _json(ConsentRecord r) {
  final map = r.toMap();
  final entrees = map.entries.map((e) {
    final v = e.value;
    return '"${e.key}":${v is String ? '"$v"' : v}';
  }).join(',');
  return '{$entrees}';
}
