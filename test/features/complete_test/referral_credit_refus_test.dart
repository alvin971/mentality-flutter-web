// Que fait l'app quand le serveur REFUSE la déclaration de fin de test ?
//
// Le worker referral écarte les sessions « non plausibles » : moins de 10
// sous-tests ou moins du plancher de durée (workers/referral/index.js).
//
// LE BUG : ce refus était avalé en silence (`if (statusCode != 200) return
// null;`). L'utilisateur voyait ses résultats, croyait sa mission validée, et
// son parrain n'était jamais crédité — sans que personne ne puisse le savoir.
//
// CE QUE CE TEST VERROUILLE : un refus est mémorisé, il n'est PAS rejoué en
// boucle (rejouer la même charge utile donnerait éternellement le même refus),
// et il devient visible à l'écran.
//
// Fichier séparé À DESSEIN : Flutter isole chaque fichier de test dans son
// propre processus, à l'abri de l'état résiduel des lourds tests de widgets
// de referral_credit_flow_test.dart.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mentality/core/services/auth_local_store.dart';
import 'package:mentality/features/complete_test/presentation/pages/complete_test_results_page.dart';
import 'package:mentality/features/unlock/data/completion_reporter.dart';
import 'package:mentality/features/unlock/data/unlock_service.dart';
import 'package:mentality/services/session_history_service.dart';
import 'package:mentality/services/session_persistence_service.dart';

import 'referral_credit_kit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    Hive.init(Directory.systemTemp.createTempSync('mentality_refus').path);
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
    await AuthLocalStore.instance.clearPendingCompletion();
    await AuthLocalStore.instance.clearCompletionRejected();
  });

  test('RÉGRESSION — un refus serveur est mémorisé, pas avalé', () async {
    completeStatus = 400; // « Session non plausible »

    final issue = await CompletionReporter.instance.declare(
      subtestsCompleted: 12,
      durationSeconds: 240, // sous le plancher
    );

    expect(issue, CompletionOutcome.rejected);
    final corps = jsonDecode(declarationsDeFin.first.body) as Map;
    expect(corps['durationSeconds'], 240);
    expect(await CompletionReporter.instance.wasRejected(), isTrue,
        reason: 'le refus est mémorisé pour être EXPLIQUÉ à l\'utilisateur');
  });

  test('un refus n\'est pas rejoué en boucle', () async {
    completeStatus = 400;
    await CompletionReporter.instance.declare(
      subtestsCompleted: 12,
      durationSeconds: 240,
    );
    final apresPremierEnvoi = declarationsDeFin.length;

    // Occasions de rattrapage suivantes (démarrage de l'app, missions…).
    await CompletionReporter.instance.retryPending();
    await CompletionReporter.instance.retryPending();

    expect(declarationsDeFin.length, apresPremierEnvoi,
        reason: 'la même charge utile donnerait éternellement le même refus');
    expect(await CompletionReporter.instance.hasPending(), isFalse);
  });

  testWidgets('RÉGRESSION — le refus devient VISIBLE à l\'écran',
      (tester) async {
    completeStatus = 400;
    // runAsync obligatoire : E/S disque réelle sous horloge simulée.
    await tester.runAsync(() => CompletionReporter.instance.declare(
          subtestsCompleted: 12,
          durationSeconds: 240,
        ));

    ecranTelephone(tester);
    ignoreDebordementsDeMiseEnPage();
    await tester.pumpWidget(
      hote(CompleteTestResultsPage(
          session: sessionTerminee(const Duration(minutes: 4)),
          ageInMonths: 300)),
    );
    await tester.pump();
    await attendLeReseau(tester);
    await tester.pump(const Duration(seconds: 1));

    // Le texte exact vient des ARB (6 langues) ; on cherche son début, qui
    // suffit à prouver que l'avertissement est bien rendu.
    expect(
      find.textContaining('n\'a pas pu être validée', findRichText: true),
      findsOneWidget,
      reason: 'l\'utilisateur doit savoir que sa passation ne compte pas',
    );
  });
}
