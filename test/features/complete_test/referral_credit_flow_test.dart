// À QUEL MOMENT EXACT le crédit de parrainage part-il vers le serveur ?
//
// Contrairement aux autres tests du dossier (qui RÉPLIQUENT une règle dans le
// fichier de test et ne touchent jamais le code de l'app), celui-ci pilote le
// VRAI code : vrai BLoC, vraie page de résultats, vrai orchestrateur. Toutes
// les requêtes HTTP réellement émises sont interceptées et journalisées.
//
// LE BUG (2026-07-25) : `POST /complete` est la SEULE porte qui crédite le
// parrain d'un filleul, et elle n'était émise que depuis l'écran de RÉSULTATS.
// Depuis que l'étape orale (~10 min) s'intercale entre le dernier sous-test et
// cet écran, tout abandon dans cette fenêtre perdait le parrainage —
// définitivement et sans un mot. Observé en production : le 3ᵉ filleul avait
// bien sa clé `referee:` mais aucune clé `completed:`.
//
// CE QUE CES TESTS VERROUILLENT MAINTENANT :
//   1. la déclaration part dès le dernier sous-test, AVANT l'étape orale ;
//   2. fermer l'app pendant l'étape orale ne perd plus rien ;
//   3. un serveur injoignable laisse une déclaration EN ATTENTE, rejouée
//      ensuite jusqu'à confirmation.
//
// Le cas « le serveur refuse la déclaration » vit dans son propre fichier
// (referral_credit_refus_test.dart) : Flutter exécute chaque fichier dans un
// isolat séparé, ce qui le met à l'abri de l'état résiduel des lourds tests
// de widgets ci-dessous.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mentality/core/services/auth_local_store.dart';
import 'package:mentality/features/complete_test/bloc/complete_test_bloc.dart';
import 'package:mentality/features/complete_test/bloc/complete_test_state.dart';
import 'package:mentality/features/complete_test/presentation/pages/complete_test_orchestrator_page.dart';
import 'package:mentality/features/complete_test/presentation/pages/complete_test_results_page.dart';
import 'package:mentality/features/data_collection/oral_test_flow.dart';
import 'package:mentality/services/session_history_service.dart';
import 'package:mentality/services/session_persistence_service.dart';

import 'referral_credit_kit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Les services Hive sont des singletons : on les ouvre UNE fois pour tout le
  // fichier (les refermer entre deux tests laisserait une box fermée derrière
  // un `_initialized = true`).
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    Hive.init(Directory.systemTemp.createTempSync('mentality_test').path);
    await AuthLocalStore.instance.saveToken(tokenDeTest);
    await SessionPersistenceService.instance.initialize();
    await SessionHistoryService.instance.initialize();
  });

  setUp(() async {
    // À REPOSER À CHAQUE TEST : le binding des tests de widgets réinitialise
    // les simulacres de canaux de plateforme après chaque testWidgets. Sans
    // ça, le premier test suivant se fige indéfiniment sur SharedPreferences.
    SharedPreferences.setMockInitialValues({});
    installeFauxReseau();
    await SessionPersistenceService.instance.clearSession();
    await AuthLocalStore.instance.clearPendingCompletion();
    await AuthLocalStore.instance.clearCompletionRejected();
  });

  group('le crédit part dès la fin de la batterie', () {
    testWidgets(
        'RÉGRESSION — la déclaration est envoyée AVANT l\'étape orale',
        (tester) async {
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
          reason: 'la batterie est bien terminée');

      await tester.pump();
      await attendLeReseau(tester);
      await tester.pump(const Duration(milliseconds: 100));

      // On est bien sur l'étape orale (l'app n'a pas changé de parcours)…
      expect(find.byType(OralTestFlow), findsOneWidget);
      expect(find.byType(CompleteTestResultsPage), findsNothing);

      // … et le crédit est DÉJÀ parti : c'est tout l'objet du correctif.
      expect(declarationsDeFin, isNotEmpty,
          reason: 'le parrain est crédité dès la fin du test, sans dépendre '
              'de la traversée de l\'étape orale');
      final corps = jsonDecode(declarationsDeFin.first.body) as Map;
      expect(corps['subtestsCompleted'], 12);

      // … et l'utilisateur ferme l'app en plein milieu de l'étape orale
      // (bouton « Retour à l'accueil », OS qui tue le process, appel entrant).
      // Avant le correctif, tout était perdu ici. (Ce démontage purge aussi
      // les minuteries de lancement de sous-test restées en attente.)
      final avantFermeture = declarationsDeFin.length;
      await tester.pumpWidget(const SizedBox());
      await attendLeReseau(tester, tours: 4);
      await tester.pump(const Duration(seconds: 1));

      expect(declarationsDeFin.length, avantFermeture,
          reason: 'rien de plus n\'est nécessaire : c\'était déjà acquis');
      expect(await resteEnAttente(tester), isFalse,
          reason: 'le serveur a confirmé → plus aucune perte possible');
    });

  });


  group('la page de résultats n\'est plus le point d\'émission', () {
    testWidgets('elle n\'envoie RIEN quand tout est déjà confirmé',
        (tester) async {
      ecranTelephone(tester);
      ignoreDebordementsDeMiseEnPage();
      await tester.pumpWidget(
        hote(CompleteTestResultsPage(
            session: sessionTerminee(const Duration(minutes: 25)),
            ageInMonths: 300)),
      );
      await tester.pump();
      await attendLeReseau(tester);
      await tester.pump(const Duration(seconds: 1));

      expect(declarationsDeFin, isEmpty,
          reason: 'plus de déclaration à l\'aveugle : la fin de test a déjà '
              'été déclarée par l\'orchestrateur');
    });

    // NOTE — le rattrapage d'une déclaration en attente PAR CET ÉCRAN n'est
    // pas testé ici : monter la page tout en pilotant des E/S disque depuis la
    // zone à horloge simulée d'un test de widget fige le banc d'essai. Le
    // comportement lui-même est couvert au niveau du service, sans widget,
    // dans referral_credit_reprise_test.dart (« REJOUÉE au retour du réseau »).
  });
}
