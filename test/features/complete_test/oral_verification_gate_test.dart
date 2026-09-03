// POUR UN PASSE GRATUIT, LES RÉSULTATS NE S'AFFICHENT QU'UNE FOIS
// L'ENREGISTREMENT VÉRIFIÉ PAR LE SERVEUR — décision fondateur, 2026-09-03.
//
// L'enregistrement vocal est la contrepartie du passe Gratuit. Jusqu'ici, la
// fin de l'étape orale déclenchait un `POST /validate` silencieux dont
// personne ne lisait la réponse : un enregistrement absent, vide ou sans
// rapport avec les textes donnait quand même les résultats. Désormais le
// serveur transcrit les lectures, et sa réponse commande l'affichage :
//
//   · 200 {ok:true}                     ⇒ vérifié : résultats
//   · 409 VERIFICATION_PENDING          ⇒ on attend (2 s, 4 s, 8 s… ≤ 90 s)
//   · 400 VERIFICATION_FAILED           ⇒ page « Résultats en attente », avec
//                                         « Reprendre l'enregistrement »
//
// Un passe Payant n'enregistre rien et voit ses résultats sans validation ;
// un passe sans plan (`sv: 2`) garde le comportement d'avant.
//
// Comme oral_plan_gate_test, ce fichier pilote le VRAI code : vrai BLoC, vrai
// orchestrateur, vraie étape orale, requêtes HTTP interceptées. Seuls les 5
// cycles d'enregistrement sont sautés (`debugSauterLesEnregistrements`) : le
// banc d'essai n'a pas de micro, et ce qui compte ici est ce que l'app fait
// DU VERDICT du serveur.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mentality/core/consent/consent_service.dart';
import 'package:mentality/core/services/auth_local_store.dart';
import 'package:mentality/features/complete_test/bloc/complete_test_bloc.dart';
import 'package:mentality/features/complete_test/bloc/complete_test_state.dart';
import 'package:mentality/features/complete_test/presentation/pages/complete_test_orchestrator_page.dart';
import 'package:mentality/features/complete_test/presentation/pages/complete_test_results_page.dart';
import 'package:mentality/features/complete_test/presentation/pages/resultats_en_attente_page.dart';
import 'package:mentality/features/data_collection/oral_test_flow.dart';
import 'package:mentality/services/session_history_service.dart';
import 'package:mentality/services/session_persistence_service.dart';

import 'referral_credit_kit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    Hive.init(Directory.systemTemp.createTempSync('mentality_verif_test').path);
    await AuthLocalStore.instance.saveToken(tokenDeTest);
    await SessionPersistenceService.instance.initialize();
    await SessionHistoryService.instance.initialize();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    installeFauxReseau();
    await ConsentService.instance.debugReset();
    await SessionPersistenceService.instance.clearSession();
    await AuthLocalStore.instance.clearPendingCompletion();
    await AuthLocalStore.instance.clearCompletionRejected();

    OralTestFlow.debugSauterLesEnregistrements = true;
    // La minuterie de reprise est FAUSSE (horloge simulée) : elle ne part
    // que si le test avance l'horloge d'au moins sa durée. Avancer de 2 s
    // réveillerait aussi les minuteries de 500 ms de l'orchestrateur, qui
    // lanceraient de vraies pages de sous-test par-dessus l'étape orale.
    // Une milliseconde suffit, et l'horloge ne doit JAMAIS dépasser 500 ms
    // tant que l'orchestrateur est monté.
    OralTestFlow.debugDelaiDeReprise = const Duration(milliseconds: 1);
    addTearDown(() {
      OralTestFlow.debugSauterLesEnregistrements = false;
      OralTestFlow.debugDelaiDeReprise = null;
    });
  });

  /// Démonte l'arbre en fin de test (minuteries de l'orchestrateur) et REND
  /// LES COFFRES HIVE UTILISABLES par le test suivant.
  ///
  /// LE PIÈGE (deux bilans complets dans un même fichier — une première :
  /// oral_plan_gate_test n'en joue qu'un, en dernier) : Hive sérialise les
  /// écritures d'une box en chaînant des futures (`ReadWriteSync`), et un
  /// future garde la ZONE qui l'a créé. Quand la dernière écriture d'une box
  /// vient de l'app — donc de la zone à horloge simulée du test — le future
  /// conservé appartient à cette zone. Au test suivant, la première écriture
  /// fait `.then` dessus : Dart planifie la continuation dans la zone du
  /// future, c'est-à-dire dans la file d'une horloge simulée qui n'existe
  /// plus. L'écriture ne démarre jamais, le BLoC attend son `saveSession`
  /// pour toujours, et le test ne finit pas — sans message.
  ///
  /// D'où la SONDE : une écriture RÉELLE de test sur chaque box, lancée en
  /// zone réelle (`runAsync`), dont le future survit au test. Un `delete` sur
  /// une box vide ne suffit pas (aucune écriture, aucun future), d'où le
  /// `saveSession` avant le `clearSession`. On alterne temps réel et
  /// reconstruction jusqu'à ce qu'elle passe : tant qu'elle attend, une
  /// écriture de l'app est encore en vol et a besoin d'un tour de plus.
  Future<void> demonte(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await attendLeReseau(tester, tours: 12);
    await tester.pump(const Duration(seconds: 1));
    Future<bool> ecrit() async {
      final token = await AuthLocalStore.instance.getToken();
      await AuthLocalStore.instance.saveToken(token ?? tokenDeTest);
      await SessionPersistenceService.instance
          .saveSession(sessionTerminee(Duration.zero), 300);
      await SessionPersistenceService.instance.clearSession();
      // Compactage ICI, en zone réelle : sinon Hive le déclenche de lui-même
      // au milieu d'un test suivant, dans la zone simulée, et ses dizaines
      // d'E/S retardent d'autant le démarrage du bilan.
      await Hive.box('mentality_auth').compact();
      await Hive.box('session_persistence').compact();
      return true;
    }

    for (var i = 0; i < 60; i++) {
      final libre = await tester.runAsync(() => ecrit().timeout(
          const Duration(milliseconds: 300),
          onTimeout: () => false));
      if (libre == true) return;
      await tester.pump();
    }
    fail('le coffre Hive n\'a jamais rendu son verrou d\'écriture');
  }

  /// Attend (temps réel + reconstruction, SANS avancer l'horloge simulée)
  /// qu'un widget apparaisse.
  Future<void> attendQue(WidgetTester tester, Finder f,
      {int tours = 60}) async {
    for (var i = 0; i < tours && f.evaluate().isEmpty; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 30)));
      await tester.pump();
    }
  }

  /// Joue le bilan complet (12 épreuves notées) avec le passe donné, puis
  /// laisse l'orchestrateur enchaîner sur ce qui suit.
  Future<void> termineLeBilan(WidgetTester tester, String token) async {
    await tester.runAsync(() => AuthLocalStore.instance.saveToken(token));
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

    // Temps réel seulement : aucune avance de l'horloge simulée ici, elle
    // ferait partir la minuterie de reprise avant que le test n'ait observé
    // l'écran d'attente. Les transitions de route n'ont pas besoin d'être
    // jouées jusqu'au bout pour que les widgets soient trouvables.
    await tester.pump();
    await attendLeReseau(tester, tours: 24);
  }

  const titreVerification = 'Vérification de ton enregistrement…';
  const titreRefus = 'Ton enregistrement n\'a pas pu être vérifié';
  const boutonReprendre = 'Reprendre l\'enregistrement';

  group('passe GRATUIT', () {
    testWidgets('(a) /validate → 200 : les résultats s\'affichent',
        (tester) async {
      validateStatuts = [200];
      await termineLeBilan(tester, tokenDeTestPlan(cc: true));
      await attendQue(tester, find.byType(CompleteTestResultsPage));

      expect(find.byType(CompleteTestResultsPage), findsOneWidget,
          reason: 'vérifié par le serveur ⇒ résultats');
      expect(find.byType(OralTestFlow), findsNothing,
          reason: 'l\'étape orale s\'est refermée d\'elle-même');
      expect(find.byType(ResultatsEnAttentePage), findsNothing);

      expect(validations, hasLength(1),
          reason: 'une seule demande de vérification a suffi');
      final corps = jsonDecode(validations.first.body) as Map;
      expect(corps['token'], tokenDeTestPlan(cc: true),
          reason: 'c\'est bien CE passe que le serveur vérifie');

      // Le crédit du parrain est parti AVANT l'étape orale, comme toujours.
      expect(declarationsDeFin, isNotEmpty);

      await demonte(tester);
    });

    testWidgets('(b) 409 puis 200 : on attend, puis les résultats',
        (tester) async {
      validateStatuts = [409, 200];
      await termineLeBilan(tester, tokenDeTestPlan(cc: true));
      await attendQue(tester, find.text(titreVerification));

      // Premier verdict : « en cours ». L'écran d'attente est là, les
      // résultats ne le sont pas, et l'étape n'a pas été refermée.
      expect(find.text(titreVerification), findsOneWidget);
      expect(find.byType(CompleteTestResultsPage), findsNothing,
          reason: 'tant que le serveur n\'a pas vérifié, pas de résultats');
      expect(find.byType(ResultatsEnAttentePage), findsNothing,
          reason: 'un « en cours » n\'est pas un refus : on attend sur place');
      expect(validations, hasLength(1));

      // La minuterie de reprise (2 s nominales, 1 ms ici) se déclenche.
      await tester.pump(const Duration(milliseconds: 1));
      await attendQue(tester, find.byType(CompleteTestResultsPage));

      expect(validations, hasLength(2),
          reason: 'une seconde demande est partie après le délai');
      expect(find.byType(CompleteTestResultsPage), findsOneWidget,
          reason: 'le second verdict est « vérifié » ⇒ résultats');
      expect(find.byType(OralTestFlow), findsNothing);

      await demonte(tester);
    });

    testWidgets(
        '(c) 400 refusé : page d\'attente, pas de résultats, « Reprendre »',
        (tester) async {
      validateStatuts = [400];
      await termineLeBilan(tester, tokenDeTestPlan(cc: true));
      await attendQue(tester, find.text(titreRefus));

      // L'étape orale explique le refus et propose de réenregistrer.
      expect(find.text(titreRefus), findsOneWidget);
      expect(find.text('Réenregistrer'), findsOneWidget);
      expect(find.text('Réessayer la vérification'), findsOneWidget);
      expect(find.byType(CompleteTestResultsPage), findsNothing,
          reason: 'un enregistrement refusé ne donne pas droit aux résultats');
      expect(validations, hasLength(1),
          reason: 'un refus est définitif : on ne réessaie pas tout seul');

      // L'utilisateur quitte l'étape pour l'instant…
      await tester.tap(find.text('Quitter pour l\'instant'));
      await tester.pump();
      await attendQue(tester, find.byType(ResultatsEnAttentePage));

      // … et tombe sur la page d'attente, PAS sur les résultats.
      expect(find.byType(ResultatsEnAttentePage), findsOneWidget);
      expect(find.byType(CompleteTestResultsPage), findsNothing);
      expect(find.text(boutonReprendre), findsOneWidget,
          reason: 'la page propose de reprendre l\'enregistrement');
      expect(find.text('Vérifier à nouveau'), findsOneWidget);

      // Le bilan, lui, est bien déclaré : le crédit du parrain ne dépend
      // pas de la vérification.
      expect(declarationsDeFin, isNotEmpty);

      // « Reprendre l'enregistrement » rouvre l'étape orale.
      await tester.tap(find.text(boutonReprendre));
      await tester.pump();
      await attendQue(tester, find.byType(OralTestFlow));
      expect(find.byType(OralTestFlow), findsOneWidget);

      await demonte(tester);
    });
  });

  group('autres passes', () {
    testWidgets('(d) passe PAYANT : résultats directs, aucune validation',
        (tester) async {
      validateStatuts = [400]; // ne doit jamais être consommé
      await termineLeBilan(
          tester, tokenDeTestPlan(p: 'paid', cc: false));
      await attendQue(tester, find.byType(CompleteTestResultsPage));

      expect(find.byType(CompleteTestResultsPage), findsOneWidget);
      expect(find.byType(OralTestFlow), findsNothing);
      expect(find.byType(ResultatsEnAttentePage), findsNothing);
      expect(validations, isEmpty,
          reason: 'rien à vérifier : un passe Payant n\'enregistre rien');
      expect(declarationsDeFin, isNotEmpty);

      await demonte(tester);
    });

    testWidgets(
        '(e) passe SANS plan (sv 2) : comportement d\'avant — consentement '
        'in-app, et un refus mène quand même aux résultats', (tester) async {
      validateStatuts = [400]; // ne doit jamais être consommé
      await termineLeBilan(tester, tokenDeTest);
      await attendQue(tester, find.byType(CheckboxListTile));

      // Repli intégral : l'écran de consentement in-app, comme avant.
      expect(find.byType(OralTestFlow), findsOneWidget);
      expect(find.byType(CheckboxListTile), findsWidgets);
      expect(find.byType(CompleteTestResultsPage), findsNothing);

      // Refuser fait sauter l'étape… (le bouton est sous la ligne de
      // flottaison de l'écran de consentement : on le fait défiler d'abord)
      await tester.ensureVisible(find.text('Refuser et revenir en arrière'));
      await tester.pump();
      await tester.tap(find.text('Refuser et revenir en arrière'));
      await tester.pump();
      await attendQue(tester, find.byType(CompleteTestResultsPage));

      // … et l'on est sur les résultats, sans page d'attente ni validation.
      expect(find.byType(CompleteTestResultsPage), findsOneWidget);
      expect(find.byType(ResultatsEnAttentePage), findsNothing,
          reason: 'la vérification bloquante ne concerne que le passe '
              'Gratuit : un sv 2 n\'y est pas soumis');
      expect(validations, isEmpty);

      await demonte(tester);
    });
  });
}
