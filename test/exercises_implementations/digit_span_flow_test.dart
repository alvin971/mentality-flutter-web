import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/core/l10n/gen/app_localizations.dart';
import 'package:mentality/features/exercises_implementations/digit_span/presentation/pages/digit_span_test_page.dart';

/// Tests de FLUX du test Mémoire des Chiffres, pilotés en boîte noire :
/// on lit les chiffres réellement présentés à l'écran, puis on répond
/// correctement ou volontairement faux, comme un utilisateur réel.
///
/// Ils rejouent les deux bugs rapportés sur le « séquençage » :
/// 1. Échouer les 2 essais d'une même longueur doit ARRÊTER la partie et
///    passer à la suivante (puis rendre la main avec un score), jamais
///    laisser l'utilisateur bloqué à recommencer.
/// 2. En séquençage, la bonne réponse est l'ordre croissant — et la séquence
///    présentée ne doit jamais être l'inverse exact de la bonne réponse
///    (vécu comme « c'est l'inverse qui est correct »).
void main() {
  int? poppedScore;
  bool popped = false;

  Widget host() {
    poppedScore = null;
    popped = false;
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
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
        home: Builder(
          builder: (ctx) => Scaffold(
            body: Center(
              child: ElevatedButton(
                key: const Key('launch'),
                onPressed: () async {
                  final s = await Navigator.push<int>(
                    ctx,
                    MaterialPageRoute(
                        builder: (_) => const DigitSpanTestPage()),
                  );
                  popped = true;
                  poppedScore = s;
                },
                child: const Text('go'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> launchToPartIntro(WidgetTester tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(host());
    await tester.tap(find.byKey(const Key('launch')));
    // Pompes bornées : le scaffold Kepler anime en continu, pumpAndSettle
    // ne convergerait jamais.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    // Écran d'intro global.
    await tester.tap(find.text('Commencer le test'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> startPart(WidgetTester tester) async {
    expect(find.byKey(const Key('dsStartPart')), findsOneWidget);
    await tester.tap(find.byKey(const Key('dsStartPart')));
    await tester.pump();
  }

  /// Regarde la présentation et retourne la séquence réellement affichée.
  Future<List<int>> watchSequence(WidgetTester tester) async {
    final seq = <int>[];
    for (int i = 0; i < 15; i++) {
      await tester.pump(const Duration(seconds: 1));
      if (find.byKey(const Key('dsValidate')).evaluate().isNotEmpty) {
        expect(seq, isNotEmpty, reason: 'aucun chiffre présenté');
        return seq;
      }
      final digit = find.byKey(const Key('dsDigit'));
      if (digit.evaluate().isNotEmpty) {
        final d = int.parse(tester.widget<Text>(digit).data!);
        if (seq.isEmpty || seq.last != d) seq.add(d);
      }
    }
    fail('la présentation ne se termine jamais');
  }

  Future<void> enterAndSubmit(WidgetTester tester, List<int> answer) async {
    for (final d in answer) {
      await tester.tap(find.byKey(Key('dsKey$d')));
      await tester.pump();
    }
    await tester.tap(find.byKey(const Key('dsValidate')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  List<int> sortedAsc(List<int> s) => List<int>.from(s)..sort();
  List<int> sortedDesc(List<int> s) =>
      (List<int>.from(s)..sort()).reversed.toList();

  /// Réponse volontairement fausse quel que soit le type de partie.
  List<int> wrongAnswer(SpanTypeUi part, List<int> seq) {
    switch (part) {
      case SpanTypeUi.forward:
        return seq.reversed.toList(); // jamais égal (chiffres distincts)
      case SpanTypeUi.backward:
        return List<int>.from(seq); // l'attendu est l'inverse
      case SpanTypeUi.sequencing:
        return sortedDesc(seq); // l'attendu est croissant
    }
  }

  Future<void> failItem(WidgetTester tester, SpanTypeUi part) async {
    final seq = await watchSequence(tester);
    await enterAndSubmit(tester, wrongAnswer(part, seq));
    // Plus aucun pop-up « Incorrect » : la soumission enchaîne directement
    // (test de QI non noté à l'écran).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets(
      'BUG 1 — 2 échecs à la même longueur arrêtent chaque partie, '
      'et le test rend la main avec un score (pas de recommencement forcé)',
      (tester) async {
    await launchToPartIntro(tester);

    // Partie 1 : Empan Direct — échouer les 2 essais de longueur 2.
    expect(find.text('Empan Direct'), findsWidgets);
    await startPart(tester);
    await failItem(tester, SpanTypeUi.forward);
    await failItem(tester, SpanTypeUi.forward);

    // Discontinuation → intro de l'Empan Inverse (pas un 3e essai direct).
    expect(find.text('Empan Inverse'), findsWidgets,
        reason: 'après 2 échecs à la même longueur, la partie doit s\'arrêter');
    await startPart(tester);
    await failItem(tester, SpanTypeUi.backward);
    await failItem(tester, SpanTypeUi.backward);

    // Discontinuation → intro du Séquençage.
    expect(find.text('Séquençage'), findsWidgets);
    await startPart(tester);
    await failItem(tester, SpanTypeUi.sequencing);
    await failItem(tester, SpanTypeUi.sequencing);

    // Fin du test : dialogue de fin SANS métriques (test non noté à l'écran),
    // puis retour AVEC un score.
    expect(find.text('Résultats par partie :'), findsNothing);
    await tester.tap(find.byKey(const Key('dsResultsBack')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(popped, isTrue, reason: 'le test doit rendre la main');
    expect(poppedScore, 0,
        reason: 'tout raté => score 0, mais un score quand même '
            '(sinon l\'orchestrateur propose de recommencer)');
  });

  testWidgets(
      'BUG 2 — en séquençage, l\'ordre croissant est correct et la séquence '
      'présentée n\'est jamais l\'inverse exact de la réponse', (tester) async {
    await launchToPartIntro(tester);

    // Traverser vite les parties 1 et 2 par discontinuation.
    await startPart(tester);
    await failItem(tester, SpanTypeUi.forward);
    await failItem(tester, SpanTypeUi.forward);
    await startPart(tester);
    await failItem(tester, SpanTypeUi.backward);
    await failItem(tester, SpanTypeUi.backward);

    expect(find.text('Séquençage'), findsWidgets);
    await startPart(tester);

    // Longueur 2, essai 1 : présentée croissante => répondre ce qu'on a
    // entendu est CORRECT (fini le « c'est l'inverse qui est correct »).
    final seq1 = await watchSequence(tester);
    expect(seq1, hasLength(2));
    expect(seq1, sortedAsc(seq1),
        reason: 'longueur 2 : présentation croissante attendue');
    await enterAndSubmit(tester, sortedAsc(seq1));
    // Plus de pop-up « Correct ! » : la soumission enchaîne directement.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Longueur 2, essai 2 : idem.
    final seq2 = await watchSequence(tester);
    await enterAndSubmit(tester, sortedAsc(seq2));
    // Plus de pop-up « Correct ! » : la soumission enchaîne directement.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Longueur 3 : ni déjà triée, ni triée en décroissant (l'inverse exact),
    // et l'ordre croissant est la bonne réponse.
    final seq3 = await watchSequence(tester);
    expect(seq3, hasLength(3));
    expect(seq3, isNot(equals(sortedAsc(seq3))),
        reason: 'longueur >= 3 : jamais présentée déjà triée');
    expect(seq3, isNot(equals(sortedDesc(seq3))),
        reason: 'longueur >= 3 : jamais l\'inverse exact de la réponse');
    await enterAndSubmit(tester, sortedAsc(seq3));
    // Plus de pop-up « Correct ! » : la soumission enchaîne directement.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets(
      'Aucun pop-up de correction : soumettre une réponse enchaîne '
      'directement sur l\'essai suivant (test non noté à l\'écran)',
      (tester) async {
    await launchToPartIntro(tester);
    await startPart(tester);

    final seq = await watchSequence(tester);
    await enterAndSubmit(tester, seq.reversed.toList()); // faux exprès
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Aucun retour « juste/faux », aucun bouton « Continuer » de feedback :
    // le test enchaîne tout seul sur la présentation de l'essai suivant.
    expect(find.text('Incorrect'), findsNothing);
    expect(find.text('Correct !'), findsNothing);
    expect(find.byKey(const Key('dsContinue')), findsNothing);
    expect(find.text('Écoutez attentivement'), findsOneWidget,
        reason: 'la soumission doit faire avancer, pas afficher un pop-up');
  });
}

/// Doublon local de SpanType pour piloter les helpers sans dépendre du domaine.
enum SpanTypeUi { forward, backward, sequencing }
