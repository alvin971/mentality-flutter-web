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

    // On simule le vieillissement du texte : la version stockée n'est plus la
    // courante.
    final perime = ConsentRecord.fromMap({
      ...record!.toMap(),
      'version': 'version-perimee',
    });

    expect(perime.eventHealthData, isTrue);
    expect(perime.isCurrentVersion, isFalse);
    // hasEventDataConsent exige les DEUX : la finalité et une version à jour.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gdpr_consent_record', _json(perime));
    expect(await service.hasEventDataConsent(), isFalse,
        reason: 'changer le texte re-sollicite : on ne parle plus de la même '
            'chose');
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
