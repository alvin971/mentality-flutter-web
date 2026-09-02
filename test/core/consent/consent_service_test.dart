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
import 'package:mentality/core/constants/app_constants.dart';
import 'package:mentality/core/consent/consent_record.dart';
import 'package:mentality/core/consent/consent_service.dart';
import 'package:mentality/core/services/token_plan.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final service = ConsentService.instance;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    // `debugReset()` et non `withdraw()` : depuis que le retrait pose un
    // marqueur durable, se remettre à zéro par un retrait ferait partir tout
    // ce fichier d'un état « consentement RETIRÉ », où syncFromToken est
    // volontairement neutralisée. Ce n'est pas l'état d'un appareil neuf.
    await service.debugReset();
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

  // ─── Le consentement PORTÉ PAR LE TOKEN (passe créé sur le site) ──────────
  //
  // Depuis le 2026-09-02, le consentement au corpus vocal est recueilli sur
  // mental-et.com AVANT l'émission du passe et voyage dans le token signé.
  // L'app ne présente alors aucun écran : elle aligne son enregistrement local
  // sur ce que dit le token. Deux pièges à tenir fermés :
  //   · la version portée est celle des TEXTES LÉGAUX du site, pas celle du
  //     texte in-app — la comparer à kConsentVersion périmerait un
  //     consentement tout juste donné ;
  //   · l'art. 9 (données de santé) n'est jamais concerné : le token ne parle
  //     que de l'audio.

  const cv = '2026-09-02.v1';
  const jourEmission = 20693; // 2026-09-02, jours depuis l'epoch UTC.

  TokenPlanInfo gratuit({required bool corpus}) => TokenPlanInfo(
        plan: TokenPlan.free,
        corpusConsent: corpus,
        legalVersion: cv,
        issuedDay: jourEmission,
      );

  const payant = TokenPlanInfo(
    plan: TokenPlan.paid,
    legalVersion: cv,
    issuedDay: jourEmission,
  );

  group('consentement porté par le token', () {
    test('passe Gratuit + case corpus cochée → audio ET cession accordés',
        () async {
      await service.syncFromToken(gratuit(corpus: true), locale: 'fr');

      expect(await service.hasValidConsent(), isTrue);
      final record = await service.load();
      expect(record!.source, ConsentSource.token);
      expect(record.recordingAndAnalysis, isTrue);
      expect(record.commercialReuse, isTrue);
      expect(record.version, cv,
          reason: 'la preuve désigne le texte réellement lu — celui du site');
      expect(record.grantedAt,
          DateTime.utc(1970, 1, 1).add(const Duration(days: jourEmission)),
          reason: 'la date vient du claim `d`, jamais de l\'horloge locale');
    });

    test('passe Gratuit sans la case corpus → audio oui, cession non',
        () async {
      await service.syncFromToken(gratuit(corpus: false), locale: 'fr');

      expect(await service.hasValidConsent(), isTrue,
          reason: 'l\'épreuve orale reste jouable : la case du corpus est '
              'facultative tant que le passe Payant n\'est pas en vente');
      final record = await service.load();
      expect(record!.commercialReuse, isFalse,
          reason: 'rien ne pourra être cédé : R2 écrira sous internal/');
    });

    test('passe Payant → aucun consentement audio, donc aucun enregistrement',
        () async {
      await service.syncFromToken(payant, locale: 'fr');

      expect(await service.hasValidConsent(), isFalse,
          reason: 'c\'est précisément ce qui a été acheté');
      final record = await service.load();
      expect(record!.recordingAndAnalysis, isFalse);
      expect(record.commercialReuse, isFalse);
    });

    test(
        'une version ≠ kConsentVersion NE périme PAS un consentement du token',
        () async {
      // La version du site (`cv`) et celle du texte in-app n'ont aucune raison
      // de coïncider — c'est tout l'objet de ce test. Elle doit en revanche
      // être RECONNUE par la build : voir le groupe « une version que la build
      // ne connaît pas ne vaut pas consentement » plus bas.
      expect(cv, isNot(kConsentVersion));
      expect(AppConstants.kAcceptedLegalVersions, contains(cv));

      await service.syncFromToken(gratuit(corpus: true), locale: 'fr');

      final record = await service.load();
      expect(record!.isCurrentVersion, isFalse,
          reason: 'les deux textes n\'ont aucune raison de porter le même '
              'numéro');
      expect(await service.hasValidConsent(), isTrue,
          reason: 'comparer à la version in-app re-demanderait un accord '
              'donné une minute plus tôt sur le site');
    });

    test('plan inconnu (sv 2) sur un consentement IN-APP → no-op total',
        () async {
      await service.grant(
        sessionId: 's1',
        locale: 'fr',
        recordingAndAnalysis: true,
        commercialReuse: true,
      );
      final avant = (await service.load())!.toMap();

      await service.syncFromToken(TokenPlanInfo.unknown, locale: 'fr');

      expect((await service.load())!.toMap(), avant,
          reason: 'un passe sv 2 ne dit rien du consentement : il ne doit ni '
              'en créer, ni en effacer');
      expect(await service.hasValidConsent(), isTrue);
    });

    test('plan inconnu sans aucun enregistrement → toujours rien', () async {
      await service.syncFromToken(TokenPlanInfo.unknown, locale: 'fr');
      expect(await service.load(), isNull);
    });

    test(
        'passe remplacé par un sv 2 → l\'audio est NEUTRALISÉ, l\'art. 9 '
        'reconduit', () async {
      await service.syncFromToken(gratuit(corpus: true), locale: 'fr');
      await service.setEventHealthData(true);

      // Le passe qui portait la preuve n'est plus là : plus rien ne l'atteste.
      await service.syncFromToken(TokenPlanInfo.unknown, locale: 'fr');

      final record = await service.load();
      expect(record!.recordingAndAnalysis, isFalse);
      expect(record.commercialReuse, isFalse);
      expect(record.source, ConsentSource.inApp,
          reason: 'l\'écran in-app reprend la main');
      expect(await service.hasValidConsent(), isFalse,
          reason: 'laisser le micro autorisé par une preuve devenue '
              'introuvable serait un consentement sans preuve');
      expect(await service.hasEventDataConsent(), isTrue,
          reason: 'le token n\'a jamais parlé des données de santé : les '
              'retirer par ricochet serait aussi faux que les accorder');
      expect(record.eventHealthDataVersion, kEventConsentVersion);
    });

    test('un art. 9 déjà accordé survit intact à la synchro du token',
        () async {
      await service.setEventHealthData(true, sessionId: 's9', locale: 'fr');

      await service.syncFromToken(gratuit(corpus: true), locale: 'fr');

      expect(await service.hasEventDataConsent(), isTrue);
      expect(await service.hasValidConsent(), isTrue);
      final record = await service.load();
      expect(record!.eventHealthData, isTrue);
      expect(record.eventHealthDataVersion, kEventConsentVersion);
    });

    test('IDEMPOTENCE — deux synchros produisent le même enregistrement',
        () async {
      await service.syncFromToken(gratuit(corpus: true), locale: 'fr');
      final premier = (await service.load())!.toMap();

      await service.syncFromToken(gratuit(corpus: true), locale: 'fr');
      final second = (await service.load())!.toMap();

      expect(second, premier,
          reason: 'la date sort du claim `d` : un DateTime.now() ferait '
              'dériver la preuve à chaque lancement de l\'app');

      // Et la neutralisation l'est aussi : deux passages sur un sv 2 laissent
      // le même état, le second étant devenu un no-op.
      await service.syncFromToken(TokenPlanInfo.unknown, locale: 'fr');
      final neutralise = (await service.load())!.toMap();
      await service.syncFromToken(TokenPlanInfo.unknown, locale: 'fr');
      expect((await service.load())!.toMap(), neutralise);
    });

    test('un enregistrement ancien SANS champ `source` vaut in-app', () async {
      // Fail-safe : tout ce qui a été écrit avant que le token porte le
      // consentement reste jugé par la règle in-app (version courante exigée).
      final ancien = ConsentRecord.fromMap({
        'session_id': 's1',
        'version': 'ancien-texte-audio',
        'granted_at': '2026-06-20T10:00:00.000Z',
        'locale': 'fr',
        'recording_and_analysis': true,
        'commercial_reuse': true,
      });
      expect(ancien.source, ConsentSource.inApp);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('gdpr_consent_record', _json(ancien));
      expect(await service.hasValidConsent(), isFalse,
          reason: 'sans marque d\'origine, la règle historique s\'applique : '
              'un texte périmé re-sollicite');
    });
  });

  // ─── LE RETRAIT (art. 7-3) TIENT VRAIMENT ────────────────────────────────
  //
  // `withdraw()` n'avait aucun appelant dans lib/ alors que les textes
  // promettaient le retrait « à tout moment ». Le câbler ne suffisait pas :
  // effacer l'enregistrement seul, le retrait ne survivait pas à la
  // réouverture de l'étape orale — `syncFromToken` réécrivait le consentement
  // depuis le passe Gratuit, et le micro se rouvrait sans un mot.

  group('le retrait résiste au passe', () {
    test('après withdraw(), le consentement ne vaut plus', () async {
      await service.syncFromToken(gratuit(corpus: true), locale: 'fr');
      expect(await service.hasValidConsent(), isTrue);

      await service.withdraw();

      expect(await service.hasValidConsent(), isFalse);
      expect(await service.load(), isNull);
      expect(await service.isWithdrawn(), isTrue);
    });

    test('LA RÉGRESSION À VERROUILLER : un passe sv 3 « free » ne défait '
        'pas le retrait', () async {
      await service.syncFromToken(gratuit(corpus: true), locale: 'fr');
      await service.withdraw();

      // Exactement ce que fait l'étape orale à chaque ouverture.
      await service.syncFromToken(gratuit(corpus: true), locale: 'fr');

      expect(await service.hasValidConsent(), isFalse,
          reason: 'sans marqueur durable, le passe réécrivait '
              'recordingAndAnalysis: true et le retrait ne durait que jusqu\'à '
              'l\'écran suivant');
      final record = await service.load();
      expect(record?.recordingAndAnalysis ?? false, isFalse);
    });

    test('le retrait n\'est pas une prison : re-consentir le lève', () async {
      await service.syncFromToken(gratuit(corpus: true), locale: 'fr');
      await service.withdraw();

      // Le seul geste qui lève le marqueur : l'écran de consentement in-app.
      await service.grant(
        sessionId: 's1',
        locale: 'fr',
        recordingAndAnalysis: true,
        commercialReuse: false,
      );

      expect(await service.isWithdrawn(), isFalse);
      expect(await service.hasValidConsent(), isTrue,
          reason: 'l\'art. 7-3 protège le retrait, pas l\'impossibilité de '
              'revenir');
    });

    test('withdrawnAt() horodate le retrait', () async {
      final quand = DateTime.utc(2026, 9, 2, 10, 30);
      await service.withdraw(at: quand);
      expect(await service.withdrawnAt(), quand);
    });
  });

  // ─── LA VERSION PORTÉE PAR LE PASSE RESTE VÉRIFIABLE ─────────────────────
  //
  // Le passe ne porte aucune claim d'expiration : le consentement qu'il
  // transporte ne périme jamais tout seul. La seule prise que l'app garde
  // dessus est la liste des versions de textes qu'elle reconnaît.

  group('une version que la build ne connaît pas ne vaut pas consentement', () {
    test('cv hors kAcceptedLegalVersions → repli sur l\'écran in-app',
        () async {
      await service.syncFromToken(
        const TokenPlanInfo(
          plan: TokenPlan.free,
          corpusConsent: true,
          legalVersion: 'version-retiree-ou-jamais-publiee',
          issuedDay: jourEmission,
        ),
        locale: 'fr',
      );

      final record = await service.load();
      expect(record!.source, ConsentSource.token,
          reason: 'l\'enregistrement consigne ce que le passe a dit…');
      expect(await service.hasValidConsent(), isFalse,
          reason: '… mais on ne le croit pas : un texte inconnu de cette '
              'build ne peut pas être le texte qui a été lu, et rien '
              'd\'autre ne périmerait jamais ce consentement');
    });

    test('la version courante du site, elle, vaut', () async {
      await service.syncFromToken(gratuit(corpus: true), locale: 'fr');
      expect(await service.hasValidConsent(), isTrue);
    });

    test('retirer une version de la liste est le levier de révocation', () {
      // Garde de cohérence avec le worker : la valeur figée ici est la même
      // que la LEGAL_VERSIONS des workers. Si l'une bouge sans l'autre, un
      // passe accepté à l'écriture serait refusé à l'usage — ou l'inverse.
      expect(AppConstants.kAcceptedLegalVersions, {'2026-09-02.v1'});
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
