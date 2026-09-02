// L'ÉTAPE ORALE EST LA CONTREPARTIE DU PASSE GRATUIT — et rien d'autre.
//
// Depuis le 2026-09-02, le passe est créé sur mental-et.com et porte le plan
// choisi (`sv: 3`). Le bilan annoncé, lui, ne bouge pas : 12 épreuves, 5
// domaines, identiques dans les deux plans. Ce qui change est la contrepartie,
// et donc l'étape orale — ~10 minutes de micro, non notées :
//
//   · passe Payant  ⇒ elle n'est JAMAIS jouée : c'est précisément ce qui a été
//     acheté. On passe directement aux résultats.
//   · passe Gratuit ⇒ elle est jouée SANS écran de consentement : celui-ci a
//     été recueilli sur le site, avant l'émission du passe, et voyage dans le
//     token. Le re-présenter dans l'app demanderait deux fois la même chose.
//   · passe sans plan (`sv: 2`, antérieur au 2026-09-02) ⇒ repli intégral sur
//     l'écran de consentement in-app, comme avant.
//
// Comme referral_credit_flow_test, ce fichier pilote le VRAI code : vrai BLoC,
// vrai orchestrateur, vraie page orale, requêtes HTTP interceptées.
//
// DEUX PIÈGES VERROUILLÉS ICI :
//
//   1. Lire le plan touche le disque (token persisté). Placer cette lecture
//      avant `CompletionReporter.declare()` y insérerait un `await`, et une app
//      fermée dans cette fenêtre perdrait le crédit du parrain — exactement le
//      bug de juillet 2026. D'où l'assertion, dans le scénario Payant, que la
//      déclaration part QUAND MÊME alors que l'étape orale est sautée.
//
//   2. L'étape orale a TROIS portes d'entrée : l'orchestrateur de fin de bilan,
//      l'écran d'accueil des épreuves et la route `/test/oral`. Un garde posé
//      sur la seule première laisse les deux autres ouvertes — d'où les
//      scénarios qui montent `OralTestFlow` directement, comme le ferait un
//      lien profond.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mentality/core/consent/consent_record.dart';
import 'package:mentality/core/consent/consent_service.dart';
import 'package:mentality/core/services/auth_local_store.dart';
import 'package:mentality/features/complete_test/bloc/complete_test_bloc.dart';
import 'package:mentality/features/complete_test/bloc/complete_test_state.dart';
import 'package:mentality/features/complete_test/presentation/pages/complete_test_orchestrator_page.dart';
import 'package:mentality/features/complete_test/presentation/pages/complete_test_results_page.dart';
import 'package:mentality/features/data_collection/oral_test_flow.dart';
import 'package:mentality/services/session_history_service.dart';
import 'package:mentality/services/session_persistence_service.dart';

import 'referral_credit_kit.dart';

/// Écran d'où l'on ouvre l'étape orale — le rôle que tiennent, dans l'app, la
/// route `/test/oral` et l'écran d'accueil des épreuves.
class _PorteDEntree extends StatelessWidget {
  const _PorteDEntree();

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Builder(
            builder: (ctx) => TextButton(
              onPressed: () => Navigator.of(ctx).push(
                MaterialPageRoute(builder: (_) => const OralTestFlow()),
              ),
              child: const Text('ouvrir-oral'),
            ),
          ),
        ),
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    Hive.init(Directory.systemTemp.createTempSync('mentality_plan_test').path);
    // Ouvre la box chiffrée UNE fois, hors test de widget : dériver le cipher
    // demande des E/S réelles que l'horloge simulée ne résoudrait pas.
    await AuthLocalStore.instance.saveToken(tokenDeTest);
    await SessionPersistenceService.instance.initialize();
    await SessionHistoryService.instance.initialize();
  });

  setUp(() async {
    // Reposé à chaque test : le binding des tests de widgets réinitialise les
    // simulacres de canaux de plateforme après chaque testWidgets.
    SharedPreferences.setMockInitialValues({});
    installeFauxReseau();
    // `debugReset()` et non `withdraw()` : le retrait pose désormais un
    // marqueur durable que `syncFromToken` respecte volontairement. S'en
    // servir comme remise à zéro ferait partir chaque scénario d'un
    // consentement RETIRÉ, et le passe Gratuit n'y réécrirait plus rien.
    await ConsentService.instance.debugReset();
    await SessionPersistenceService.instance.clearSession();
    await AuthLocalStore.instance.clearPendingCompletion();
    await AuthLocalStore.instance.clearCompletionRejected();
  });

  /// Démonte l'arbre en fin de test. Indispensable après l'orchestrateur : il
  /// arme une minuterie de 500 ms avant chaque lancement de sous-test, et le
  /// banc d'essai refuse (à raison) qu'une minuterie survive à l'arbre.
  Future<void> demonte(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await attendLeReseau(tester, tours: 4);
    await tester.pump(const Duration(seconds: 1));
  }

  /// Ouvre l'étape orale par une porte DIRECTE, avec le passe fourni.
  Future<void> ouvreLEtapeOrale(WidgetTester tester, String token) async {
    await tester.runAsync(() => AuthLocalStore.instance.saveToken(token));
    ecranTelephone(tester);
    ignoreDebordementsDeMiseEnPage();
    await tester.pumpWidget(hote(const _PorteDEntree()));
    await tester.pump();
    await tester.tap(find.text('ouvrir-oral'));
    await tester.pump();
    await attendLeReseau(tester);
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('porte directe (route /test/oral, accueil des épreuves)', () {
    testWidgets('passe PAYANT — l\'étape orale se referme aussitôt',
        (tester) async {
      await ouvreLEtapeOrale(tester, tokenDeTestPlan(p: 'paid', cc: false));

      expect(find.byType(OralTestFlow), findsNothing,
          reason: 'le garde doit vivre DANS l\'étape orale : un garde posé '
              'seulement chez l\'appelant laisserait cette porte ouverte');
      expect(find.text('ouvrir-oral'), findsOneWidget,
          reason: 'on est revenu à l\'écran précédent');

      final record =
          await tester.runAsync(() => ConsentService.instance.load());
      expect(record?.recordingAndAnalysis ?? false, isFalse,
          reason: 'rien n\'autorise le micro pour un passe Payant');

      await demonte(tester);
    });

    testWidgets(
        'passe GRATUIT avec consentement corpus — aucun écran de consentement, '
        'et la preuve vient du token', (tester) async {
      await ouvreLEtapeOrale(tester, tokenDeTestPlan(cc: true));

      expect(find.byType(OralTestFlow), findsOneWidget);
      expect(find.byType(CheckboxListTile), findsNothing,
          reason: 'le consentement a été recueilli sur le site avant '
              'l\'émission du passe : le redemander ici serait demander deux '
              'fois la même chose');

      final record =
          await tester.runAsync(() => ConsentService.instance.load());
      expect(record, isNotNull);
      expect(record!.source, ConsentSource.token);
      expect(record.recordingAndAnalysis, isTrue);
      expect(record.commercialReuse, isTrue,
          reason: 'la case corpus était cochée : l\'audio ira sous reusable/, '
              'et la base doit dire la même chose que R2');
      expect(record.version, '2026-09-02.v1',
          reason: 'la preuve désigne le texte du site, pas celui de l\'écran '
              'in-app');

      await demonte(tester);
    });

    testWidgets(
        'passe GRATUIT sans la case corpus — étape jouée, mais rien à céder',
        (tester) async {
      await ouvreLEtapeOrale(tester, tokenDeTestPlan(cc: false));

      expect(find.byType(OralTestFlow), findsOneWidget);
      expect(find.byType(CheckboxListTile), findsNothing);

      final record =
          await tester.runAsync(() => ConsentService.instance.load());
      expect(record!.recordingAndAnalysis, isTrue);
      expect(record.commercialReuse, isFalse,
          reason: 'sans la case, l\'audio reste sous internal/');

      await demonte(tester);
    });

    testWidgets(
        'passe SANS plan (sv 2) — repli intégral sur l\'écran in-app',
        (tester) async {
      await ouvreLEtapeOrale(tester, tokenDeTest);

      expect(find.byType(OralTestFlow), findsOneWidget);
      expect(find.byType(CheckboxListTile), findsWidgets,
          reason: 'un passe antérieur au plan ne porte aucun consentement : '
              'l\'app doit le recueillir elle-même, comme avant');

      final record =
          await tester.runAsync(() => ConsentService.instance.load());
      expect(record, isNull,
          reason: 'un sv 2 ne crée aucun consentement : rien ne l\'y autorise');

      await demonte(tester);
    });
  });

  group('fin de bilan (orchestrateur)', () {
    testWidgets(
        'passe PAYANT — aucune étape orale, résultats directs, et le parrain '
        'est crédité quand même', (tester) async {
      await tester.runAsync(() =>
          AuthLocalStore.instance.saveToken(tokenDeTestPlan(p: 'paid', cc: false)));
      ecranTelephone(tester);
      ignoreDebordementsDeMiseEnPage();
      await tester.pumpWidget(hote(const CompleteTestOrchestratorPage()));
      await tester.pump();
      await laisseTournerLeVrai(tester);
      await tester.pump();

      final ctx = tester.element(
          find.byType(BlocConsumer<CompleteTestBloc, CompleteTestState>));
      final bloc = BlocProvider.of<CompleteTestBloc>(ctx);

      await joueLaBatterieDansWidget(tester, bloc);
      expect(bloc.state, isA<CompleteTestDoneState>(),
          reason: 'la batterie des 12 épreuves notées est bien terminée');

      await tester.pump();
      await attendLeReseau(tester);
      await tester.pump(const Duration(milliseconds: 100));

      // L'étape orale est intégralement sautée…
      expect(find.byType(OralTestFlow), findsNothing,
          reason: 'le passe Payant a précisément acheté l\'absence '
              'd\'enregistrement');

      // … et l'on est déjà sur les résultats.
      await attendLeReseau(tester);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(CompleteTestResultsPage), findsOneWidget);

      // ET LE CRÉDIT EST PARTI. C'est le cœur du test : la lecture du plan est
      // un accès disque, et la placer avant la déclaration de fin de test
      // réintroduirait la perte de parrainage de juillet 2026.
      expect(declarationsDeFin, isNotEmpty,
          reason: 'la déclaration de fin ne dépend d\'aucune étape '
              'facultative, ni de la lecture du plan');
      final corps = jsonDecode(declarationsDeFin.first.body) as Map;
      expect(corps['subtestsCompleted'], 12);

      await demonte(tester);
    });
  });
}
