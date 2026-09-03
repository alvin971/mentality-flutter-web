// `TokeniserService.validateToken` renvoie un RÉSULTAT TYPÉ, plus un booléen.
//
// Depuis 2026-09-03, `POST /validate` ne dit plus seulement « oui/non » : il
// dit si la transcription des lectures a fini (409 VERIFICATION_PENDING), si
// le seuil est atteint (200) ou non (400 VERIFICATION_FAILED). Trois parcours
// utilisateur différents — attendre, voir ses résultats, réenregistrer — qu'un
// booléen ne pouvait pas porter. Ce fichier verrouille la lecture de chaque
// réponse, réseau compris.

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:mentality/services/tokeniser_service.dart';

void main() {
  /// Un tokeniseur dont le réseau est remplacé par [handler].
  TokeniserService avec(Future<http.Response> Function(http.Request) handler) =>
      TokeniserService(client: MockClient(handler));

  setUp(() => TokeniserService.debugForceUnconfigured = false);
  tearDown(() => TokeniserService.debugForceUnconfigured = false);

  test('200 {ok:true} → vérifié, et la requête vise bien /validate', () async {
    http.Request? recue;
    final svc = avec((req) async {
      recue = req;
      return http.Response('{"ok":true}', 200);
    });

    final r = await svc.validateToken('M2.abc');

    expect(r.status, TokenValidationStatus.ok);
    expect(r.isOk, isTrue);
    expect(r.httpStatus, 200);
    expect(recue!.method, 'POST');
    expect(recue!.url.path, endsWith('/validate'));
    expect(recue!.body, contains('"token":"M2.abc"'));
  });

  test('409 VERIFICATION_PENDING → en cours, compteurs relus', () async {
    final svc = avec((_) async => http.Response(
          '{"ok":false,"code":"VERIFICATION_PENDING","verified":2,"pending":3}',
          409,
        ));

    final r = await svc.validateToken('M2.abc');

    expect(r.status, TokenValidationStatus.pending);
    expect(r.isPending, isTrue);
    expect(r.isOk, isFalse);
    expect(r.code, 'VERIFICATION_PENDING');
    expect(r.verified, 2);
    expect(r.pending, 3);
    expect(r.failed, isNull);
    expect(r.httpStatus, 409);
  });

  test('400 VERIFICATION_FAILED → refusé, compteurs relus', () async {
    final svc = avec((_) async => http.Response(
          '{"ok":false,"code":"VERIFICATION_FAILED","verified":1,"failed":4}',
          400,
        ));

    final r = await svc.validateToken('M2.abc');

    expect(r.status, TokenValidationStatus.failed);
    expect(r.isFailed, isTrue);
    expect(r.code, 'VERIFICATION_FAILED');
    expect(r.verified, 1);
    expect(r.failed, 4);
    expect(r.httpStatus, 400);
  });

  test('erreur réseau → network, sans lever', () async {
    final svc = avec((_) async => throw http.ClientException('coupé'));

    final r = await svc.validateToken('M2.abc');

    expect(r.status, TokenValidationStatus.network);
    expect(r.isNetwork, isTrue);
    expect(r.httpStatus, isNull);
    expect(r.message, contains('coupé'));
  });

  test('5xx et 429 → network (réessayable) ; autres 4xx → refusé', () async {
    expect(
      (await avec((_) async => http.Response('boom', 503))
              .validateToken('M2.abc'))
          .status,
      TokenValidationStatus.network,
    );
    expect(
      (await avec((_) async => http.Response('{"error":"slow"}', 429))
              .validateToken('M2.abc'))
          .status,
      TokenValidationStatus.network,
    );
    expect(
      (await avec((_) async => http.Response('{"error":"invalide"}', 401))
              .validateToken('M2.abc'))
          .status,
      TokenValidationStatus.failed,
      reason: 'un token refusé par le serveur ne s\'arrangera pas en '
          'réessayant',
    );
  });

  test('le code métier prime sur le statut HTTP ; 200 {ok:false} = refus', () {
    expect(
      TokenValidationResult.fromResponse(
              200, '{"ok":false,"code":"VERIFICATION_PENDING"}')
          .status,
      TokenValidationStatus.pending,
      reason: 'un serveur qui dirait « en cours » avec un autre statut que '
          '409 doit quand même être compris',
    );
    expect(
      TokenValidationResult.fromResponse(200, '{"ok":false}').status,
      TokenValidationStatus.failed,
      reason: 'un 200 sans ok:true n\'est pas une confirmation',
    );
    expect(
      TokenValidationResult.fromResponse(200, 'pas du json').status,
      TokenValidationStatus.ok,
      reason: 'corps illisible : on tranche sur le statut seul',
    );
    expect(
      TokenValidationResult.fromResponse(409, '').status,
      TokenValidationStatus.pending,
    );
  });

  test('sans tokeniseur configuré → unconfigured, aucune requête', () async {
    TokeniserService.debugForceUnconfigured = true;
    var appels = 0;
    final svc = avec((_) async {
      appels++;
      return http.Response('{"ok":true}', 200);
    });

    final r = await svc.validateToken('M2.abc');

    expect(r.status, TokenValidationStatus.unconfigured);
    expect(r.isOk, isFalse);
    expect(appels, 0);
  });
}
