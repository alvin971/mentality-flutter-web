// La déclaration de fin de test SURVIT-ELLE à un serveur injoignable ?
//
// C'est le second volet du correctif : la fin de test est persistée localement
// dès le dernier sous-test, puis REJOUÉE (démarrage de l'app, écran des
// missions, page de résultats) jusqu'à confirmation du serveur. Sans ce filet,
// une simple coupure réseau à cet instant perdait le parrainage du filleul —
// définitivement, et sans le moindre message.
//
// Fichier séparé À DESSEIN : ces tests ne touchent aucun widget, et un test
// simple placé APRÈS un test de widget se fige (le binding de test réinitialise
// les canaux de plateforme dont dépendent Hive et SharedPreferences).

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mentality/core/services/auth_local_store.dart';
import 'package:mentality/features/complete_test/bloc/complete_test_bloc.dart';
import 'package:mentality/features/complete_test/bloc/complete_test_state.dart';
import 'package:mentality/features/unlock/data/completion_reporter.dart';
import 'package:mentality/features/unlock/data/unlock_service.dart';
import 'package:mentality/services/session_history_service.dart';
import 'package:mentality/services/session_persistence_service.dart';

import 'referral_credit_kit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    Hive.init(Directory.systemTemp.createTempSync('mentality_reprise').path);
    await AuthLocalStore.instance.saveToken(tokenDeTest);
    await SessionPersistenceService.instance.initialize();
    await SessionHistoryService.instance.initialize();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    installeFauxReseau();
    await SessionPersistenceService.instance.clearSession();
    await AuthLocalStore.instance.clearPendingCompletion();
    await AuthLocalStore.instance.clearCompletionRejected();
  });

  group('quand la déclaration n\'aboutit pas', () {
    test('serveur injoignable ⇒ la déclaration reste EN ATTENTE', () async {
      reseauInjoignable = true;
      final issue = await CompletionReporter.instance.declare(
        subtestsCompleted: 12,
        durationSeconds: 1800,
      );
      expect(issue, CompletionOutcome.unreachable);
      expect(await CompletionReporter.instance.hasPending(), isTrue,
          reason: 'sans ce filet, le parrainage serait perdu définitivement');
    });

    test('… et elle est REJOUÉE avec succès au retour du réseau', () async {
      reseauInjoignable = true;
      await CompletionReporter.instance.declare(
        subtestsCompleted: 12,
        durationSeconds: 1800,
      );
      final tentativesHorsLigne = declarationsDeFin.length;

      reseauInjoignable = false; // le réseau revient
      final issue = await CompletionReporter.instance.retryPending();

      expect(issue, CompletionOutcome.confirmed);
      expect(declarationsDeFin.length, greaterThan(tentativesHorsLigne),
          reason: 'la même fin de test est bien renvoyée');
      expect(await CompletionReporter.instance.hasPending(), isFalse,
          reason: 'confirmée par le serveur → l\'attente est purgée');
    });

    test('rien en attente ⇒ aucun appel réseau inutile', () async {
      final issue = await CompletionReporter.instance.retryPending();
      expect(issue, isNull);
      expect(journal, isEmpty);
    });
  });

  group('la session de reprise', () {
    test('est effacée dès la fin de la batterie — d\'où l\'urgence de '
        'déclarer à cet instant précis', () async {
      final bloc = CompleteTestBloc();
      await joueLaBatterie(bloc);
      expect(bloc.state, isA<CompleteTestDoneState>());

      expect(
        SessionPersistenceService.instance.loadSession(),
        isNull,
        reason: 'le filet de reprise n\'existe plus passé ce point : c\'est '
            'pourquoi la complétion doit être déclarée ET persistée ici',
      );
      await bloc.close();
    });
  });
}
