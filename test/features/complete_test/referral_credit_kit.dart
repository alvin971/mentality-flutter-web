// Banc d'essai partagé des tests de CRÉDIT DE PARRAINAGE.
//
// Il intercepte toutes les requêtes HTTP réellement émises par l'app (via
// dart:io, ce que package:http utilise sous le capot) et les journalise, sans
// modifier une seule ligne du code de production.
//
// Ce fichier ne se termine PAS par `_test.dart` : il n'est pas exécuté seul.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mentality/core/l10n/gen/app_localizations.dart';
import 'package:mentality/core/models/complete_test_session.dart';
import 'package:mentality/features/complete_test/bloc/complete_test_bloc.dart';
import 'package:mentality/features/complete_test/bloc/complete_test_event.dart';
import 'package:mentality/features/complete_test/bloc/complete_test_state.dart';
import 'package:mentality/features/unlock/data/completion_reporter.dart';

// ─── Journal des requêtes réellement émises ──────────────────────────────────

class Req {
  final String method;
  final Uri url;
  final String body;
  Req(this.method, this.url, this.body);
  @override
  String toString() => '$method ${url.path} $body';
}

List<Req> journal = [];

/// Code HTTP que le faux serveur renvoie sur /complete (200 par défaut).
int completeStatus = 200;

/// Simule une coupure réseau : toute requête échoue, comme hors-ligne.
bool reseauInjoignable = false;

Iterable<Req> get declarationsDeFin =>
    journal.where((r) => r.url.path.endsWith('/complete'));

void installeFauxReseau() {
  journal = [];
  completeStatus = 200;
  reseauInjoignable = false;
  HttpOverrides.global = _Overrides();
  addTearDown(() => HttpOverrides.global = null);
}

// ─── Faux client HTTP ────────────────────────────────────────────────────────

class _Overrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? _) => _FakeClient();
}

class _FakeClient implements HttpClient {
  @override
  bool autoUncompress = true;
  @override
  Duration idleTimeout = const Duration(seconds: 15);
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _FakeRequest(method, url);
  @override
  void close({bool force = false}) {}
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _FakeRequest implements HttpClientRequest {
  @override
  final String method;
  @override
  final Uri uri;
  final List<int> _body = [];
  _FakeRequest(this.method, this.uri);

  @override
  final HttpHeaders headers = _FakeHeaders();
  @override
  int contentLength = -1;
  @override
  bool followRedirects = true;
  @override
  int maxRedirects = 5;
  @override
  bool persistentConnection = true;

  @override
  void add(List<int> data) => _body.addAll(data);

  @override
  Future<void> addStream(Stream<List<int>> s) async {
    await for (final chunk in s) {
      _body.addAll(chunk);
    }
  }

  @override
  Future<HttpClientResponse> close() async {
    journal.add(Req(method, uri, utf8.decode(_body)));
    if (reseauInjoignable) return _FakeResponse(503, '{"error":"offline"}');
    final code = uri.path.endsWith('/complete') ? completeStatus : 200;
    final corps = code == 200
        ? jsonEncode({
            'stage': 1,
            'referralCode': 'abcd1234',
            'completedReferrals': 0,
            'requiredReferrals': 3,
            'instagramSubmitted': false,
          })
        : jsonEncode({'error': 'Session non plausible', 'credited': false});
    return _FakeResponse(code, corps);
  }

  @override
  Future<HttpClientResponse> get done =>
      Future.value(_FakeResponse(200, '{}'));

  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _FakeResponse extends Stream<List<int>> implements HttpClientResponse {
  @override
  final int statusCode;
  final String body;
  _FakeResponse(this.statusCode, this.body);

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) =>
      Stream<List<int>>.fromIterable([utf8.encode(body)]).listen(
        onData,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError,
      );

  @override
  final HttpHeaders headers = _FakeHeaders();
  @override
  int get contentLength => utf8.encode(body).length;
  @override
  bool get isRedirect => false;
  @override
  bool get persistentConnection => false;
  @override
  String get reasonPhrase => statusCode == 200 ? 'OK' : 'Bad Request';
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  List<Cookie> get cookies => const [];
  @override
  List<RedirectInfo> get redirects => const [];
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _FakeHeaders implements HttpHeaders {
  final Map<String, List<String>> _m = {};
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) =>
      _m[name.toLowerCase()] = ['$value'];
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) =>
      _m.putIfAbsent(name.toLowerCase(), () => []).add('$value');
  @override
  List<String>? operator [](String name) => _m[name.toLowerCase()];
  @override
  String? value(String name) => _m[name.toLowerCase()]?.first;
  @override
  void forEach(void Function(String, List<String>) f) => _m.forEach(f);
  @override
  int contentLength = -1;
  @override
  bool chunkedTransferEncoding = false;
  @override
  ContentType? contentType;
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

// ─── Utilitaires partagés ────────────────────────────────────────────────────

/// Token DEV exploitable (M2 point claims base64url), né en avril 2005.
String get tokenDeTest {
  final claims = jsonEncode({
    's': 'M',
    'y': 2005,
    'm': 4,
    'r': 'GES',
    'd': 20659,
    'n': 'testnonce',
    'sv': 2,
  });
  final b64 = base64Url.encode(utf8.encode(claims)).replaceAll('=', '');
  return 'M2.$b64';
}

/// Token DEV porteur d'un PLAN (`sv: 3`), tel qu'en émet mental-et.com depuis
/// le 2026-09-02 : le passe dit lui-même s'il est Gratuit (financé par
/// l'enregistrement vocal) ou Payant (aucun enregistrement), et porte la
/// preuve du consentement au corpus recueilli sur le site.
///
/// Mêmes données démographiques que [tokenDeTest] : seul le plan change d'un
/// scénario à l'autre.
String tokenDeTestPlan({
  String p = 'free',
  bool cc = true,
  String cv = '2026-09-02.v1',
}) {
  final claims = jsonEncode({
    's': 'M',
    'y': 2005,
    'm': 4,
    'r': 'GES',
    'd': 20659,
    'n': 'testnonce',
    'sv': 3,
    'p': p,
    'cc': cc,
    'cv': cv,
  });
  final b64 = base64Url.encode(utf8.encode(claims)).replaceAll('=', '');
  return 'M2.$b64';
}

/// Session identique à celle produite par le BLoC en fin de batterie.
CompleteTestSession sessionTerminee(Duration duree) {
  final debut = DateTime.now().subtract(duree);
  return CompleteTestSession(
    startTime: debut,
    endTime: debut.add(duree),
    currentTestIndex: CompleteTestSession.testSequence.length,
    completedTests: List.of(CompleteTestSession.testSequence),
    cubesScore: 20,
    similaritiesScore: 20,
    digitSpanScore: 20,
    matricesScore: 20,
    vocabularyScore: 20,
    arithmeticScore: 20,
    symbolSearchScore: 20,
    visualPuzzlesScore: 20,
    informationScore: 20,
    codingScore: 20,
    pictureSpanScore: 20,
    figureWeightsScore: 20,
  );
}

Widget hote(Widget page) => ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, child) => MaterialApp(
        theme: ThemeData(brightness: Brightness.light, useMaterial3: true),
        locale: const Locale('fr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: page,
      ),
    );

/// Écran de téléphone réel (375 × 812 logiques) : la vue 800 × 600 par défaut
/// des tests fait déborder la barre de titre et pollue le résultat.
void ecranTelephone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1125, 2436);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
}

/// Les tests de widgets utilisent la police Ahem (chaque glyphe = un carré
/// pleine chasse) : les libellés y sont bien plus larges qu'en vrai et font
/// déborder les boutons. Artefact du banc d'essai, pas un défaut de l'app.
void ignoreDebordementsDeMiseEnPage() {
  final origine = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('overflowed by')) return;
    origine?.call(details);
  };
  addTearDown(() => FlutterError.onError = origine);
}

/// Fait avancer le VRAI temps (les services Hive font des E/S disque réelles,
/// que l'horloge simulée des tests de widgets ne résoudrait jamais).
Future<void> laisseTournerLeVrai(WidgetTester tester,
        [Duration d = const Duration(milliseconds: 50)]) =>
    tester.runAsync(() => Future<void>.delayed(d));

/// Attend qu'un aller-retour réseau déclenché par l'app aboutisse : il faut
/// alterner temps RÉEL (E/S Hive + requête) et reconstruction de l'arbre, un
/// simple `pump` ne résoudrait jamais les futures réelles.
Future<void> attendLeReseau(WidgetTester tester, {int tours = 12}) async {
  for (var i = 0; i < tours; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump();
  }
}

/// Reste-t-il une déclaration en attente ? À utiliser DANS un test de widget :
/// la lecture touche le disque, donc elle doit passer par runAsync.
Future<bool> resteEnAttente(WidgetTester tester) async =>
    (await tester.runAsync(() => CompletionReporter.instance.hasPending())) ??
    false;

/// Joue les 12 sous-tests NOTÉS dans le VRAI BLoC (hors test de widget) —
/// soit le bilan annoncé en entier. L'épreuve orale n'en fait plus partie :
/// sortie du décompte (12 épreuves, pas 13) tout en restant dans le code, elle
/// n'est ni notée ni pilotée par le BLoC, et c'est l'orchestrateur qui la
/// lance, en contrepartie du passe Gratuit.
// ignore: unintended_html_in_doc_comment
Future<void> joueLaBatterie(CompleteTestBloc bloc) async {
  bloc.add(const StartTestEvent(300));
  for (var i = 0; i < 200 && bloc.state is CompleteTestIntroState; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  for (final nom in CompleteTestSession.testSequence) {
    bloc.add(SubmitSubtestScoreEvent(testName: nom, score: 20));
    await Future<void>.delayed(const Duration(milliseconds: 15));
  }
  for (var i = 0; i < 400 && bloc.state is! CompleteTestDoneState; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

/// Même chose (les 12 sous-tests notés), mais DANS un test de widget. Deux horloges coexistent : celle,
/// simulée, qui fait tourner les widgets et le BLoC (avancee par `pump`), et le
/// temps réel dont les écritures Hive du BLoC ont besoin (`runAsync`). On
/// alterne les deux SANS jamais avancer l'horloge simulée, pour ne pas
/// déclencher les 500 ms qui lanceraient les vraies pages de sous-test.
Future<void> joueLaBatterieDansWidget(
    WidgetTester tester, CompleteTestBloc bloc) async {
  Future<void> respire() async {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 25)));
    await tester.pump();
  }

  bloc.add(const StartTestEvent(300));
  for (var i = 0; i < 60 && bloc.state is CompleteTestIntroState; i++) {
    await respire();
  }
  final seq = CompleteTestSession.testSequence;
  for (var k = 0; k < seq.length; k++) {
    bloc.add(SubmitSubtestScoreEvent(testName: seq[k], score: 20));
    for (var i = 0; i < 100 && nbSousTestsTermines(bloc) <= k; i++) {
      await respire();
    }
  }
  for (var i = 0; i < 100 && bloc.state is! CompleteTestDoneState; i++) {
    await respire();
  }
}

int nbSousTestsTermines(CompleteTestBloc bloc) {
  final s = bloc.state;
  if (s is CompleteTestRunningState) return s.session.completedTests.length;
  if (s is CompleteTestAwaitingNextState) return s.session.completedTests.length;
  if (s is CompleteTestDoneState) return s.session.completedTests.length;
  return 0;
}
