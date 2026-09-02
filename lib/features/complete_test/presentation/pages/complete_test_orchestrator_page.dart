import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/kepler_colors.dart';
import '../../../../core/widgets/kepler_button.dart';
import '../../../../core/widgets/kepler_card.dart';
import '../../../../core/widgets/kepler_progress.dart';
import '../../../../core/widgets/kepler_scaffold.dart';
import '../../bloc/complete_test_bloc.dart';
import '../../bloc/complete_test_event.dart';
import '../../bloc/complete_test_state.dart';
import '../../../exercises_implementations/cubes/presentation/pages/cubes_test_page.dart';
import '../../../exercises_implementations/similarities/presentation/pages/similarities_test_page.dart';
import '../../../exercises_implementations/digit_span/presentation/pages/digit_span_test_page.dart';
import '../../../exercises_implementations/matrices/presentation/pages/matrices_test_page.dart';
import '../../../exercises_implementations/vocabulary/presentation/pages/vocabulary_test_page.dart';
import '../../../exercises_implementations/arithmetic/presentation/pages/arithmetic_test_page.dart';
import '../../../exercises_implementations/symbol_search/presentation/pages/symbol_search_test_page.dart';
import '../../../exercises_implementations/visual_puzzles/presentation/pages/visual_puzzles_test_page.dart';
import '../../../exercises_implementations/information/presentation/pages/information_test_page.dart';
import '../../../exercises_implementations/coding/presentation/pages/coding_test_page.dart';
import '../../../exercises_implementations/picture_span/presentation/pages/picture_span_test_page.dart';
import '../../../exercises_implementations/figure_weights/presentation/pages/figure_weights_test_page.dart';
import '../../../data_collection/oral_test_flow.dart';
import '../../../unlock/data/completion_reporter.dart';
import '../../../../core/services/results_sync.dart';
import '../../../../core/services/resume_service.dart';
import '../../../../core/services/token_claims_reader.dart';
import '../../../../core/services/token_plan.dart';
import '../../data/pretest_store.dart';
import '../pretest_chain.dart';
import 'complete_test_results_page.dart';
import '../../../../core/l10n/l10n_ext.dart';

/// Traduit la clé technique d'un sous-test (français, issue de
/// [CompleteTestSession.testSequence]) en libellé localisé pour l'affichage.
/// La clé elle-même reste inchangée (elle sert d'identifiant dans les `switch`).
String localizedSubtestName(BuildContext context, String key) {
  switch (key) {
    case 'Cubes':
      return context.l10n.ctTestCubes;
    case 'Similitudes':
      return context.l10n.ctTestSimilarities;
    case 'Mémoire des Chiffres':
      return context.l10n.ctTestDigitSpan;
    case 'Matrices':
      return context.l10n.ctTestMatrices;
    case 'Vocabulaire':
      return context.l10n.ctTestVocabulary;
    case 'Arithmétique':
      return context.l10n.ctTestArithmetic;
    case 'Recherche de Symboles':
      return context.l10n.ctTestSymbolSearch;
    case 'Puzzles Visuels':
      return context.l10n.ctTestVisualPuzzles;
    case 'Information':
      return context.l10n.ctTestInformation;
    case 'Code':
      return context.l10n.ctTestCoding;
    case 'Mémoire des Images':
      return context.l10n.ctTestPictureSpan;
    case 'Balances':
      return context.l10n.ctTestFigureWeights;
    default:
      return key;
  }
}

class CompleteTestOrchestratorPage extends StatelessWidget {
  const CompleteTestOrchestratorPage({
    super.key,
    this.pretestStore,
    this.reprise,
  });

  /// Injectable pour les tests uniquement : en production, le stockage réel
  /// (box Hive chiffrée) est celui par défaut.
  final PretestStore? pretestStore;

  /// Bilan interrompu à poursuivre. `null` = première passation, on part de
  /// l'écran d'introduction comme avant.
  final ResumableSession? reprise;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CompleteTestBloc(),
      child: _OrchestratorView(pretestStore: pretestStore, reprise: reprise),
    );
  }
}

class _OrchestratorView extends StatefulWidget {
  const _OrchestratorView({this.pretestStore, this.reprise});

  final PretestStore? pretestStore;
  final ResumableSession? reprise;

  @override
  State<_OrchestratorView> createState() => _OrchestratorViewState();
}

class _OrchestratorViewState extends State<_OrchestratorView> {
  /// Champ de secours UNIQUEMENT : sert si le token est indécodable (cas qui
  /// ne devrait pas arriver, l'accès étant déjà verrouillé par un token
  /// valide). En temps normal l'âge vient du token, sans aucune saisie.
  final TextEditingController _ageController = TextEditingController();
  int? _ageInMonths;

  /// Vrai tant qu'on lit l'âge depuis le token (spinner court à l'écran).
  bool _ageLoading = true;

  /// Vrai si l'âge a pu être dérivé du token → aucune saisie demandée.
  bool _ageFromToken = false;

  /// Garde anti-double-lancement de l'étape orale finale (le listener BLoC
  /// peut se déclencher plusieurs fois pour un même état).
  bool _postBatteryStarted = false;

  /// Verrou du lancement. Entre l'appui sur « Lancer » et le `StartTestEvent`
  /// il y a désormais un `await` (lecture du stockage, puis éventuellement le
  /// questionnaire préalable) : sans ce verrou, un second appui pendant cette
  /// fenêtre empilerait un deuxième questionnaire par-dessus le premier.
  bool _launching = false;

  @override
  void initState() {
    super.initState();
    _loadAgeFromToken();
  }

  /// Vrai quand cet écran poursuit un bilan interrompu.
  bool get _estReprise => widget.reprise != null;

  /// Dérive l'âge (en mois) depuis l'année/mois de naissance du token.
  /// Plage acceptée identique à l'ancienne saisie (16–90 ans) pour rester
  /// cohérent avec les tables normatives.
  Future<void> _loadAgeFromToken() async {
    final months = await TokenClaimsReader.currentAgeInMonths();
    if (!mounted) return;
    setState(() {
      if (months != null) {
        // L'âge du token est TOUJOURS accepté — l'émetteur borne déjà la
        // naissance à 5–100 ans, et rejeter ici (ex. <16 ans) faisait
        // réapparaître la saisie manuelle alors qu'un token valide existe.
        // On le ramène aux bornes des tables normatives (16–90) pour le
        // scoring ; la saisie ne sert plus qu'au cas sans token exploitable.
        _ageInMonths = months.clamp(16 * 12, 90 * 12);
        _ageFromToken = true;
      }
      _ageLoading = false;
    });

    // Une reprise a déjà été confirmée par l'utilisateur sur l'accueil : lui
    // réafficher l'écran d'introduction (« Lancer le test complet ») serait au
    // mieux redondant, au pire trompeur — c'est le bouton qui repart de zéro.
    // On enchaîne donc directement, dès que l'âge est connu.
    if (_estReprise && _ageInMonths != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _startBattery(context, _ageInMonths!);
      });
    }
  }

  @override
  void dispose() {
    _ageController.dispose();
    super.dispose();
  }

  /// Le seul chemin vers la batterie. Le questionnaire préalable s'intercale
  /// ici, et pas dans les écrans appelants : ce bouton est le goulot par lequel
  /// passent aussi bien une première passation que la reprise d'un test
  /// interrompu depuis l'accueil.
  ///
  /// Ressortir du questionnaire sans répondre NE lance PAS le test : la
  /// question est obligatoire, on revient à cet écran.
  Future<void> _startBattery(BuildContext context, int ageInMonths) async {
    if (_launching) return;
    setState(() => _launching = true);
    // Capturé AVANT l'await : après, `context.read` traverserait un arbre qui
    // a pu changer pendant l'affichage du questionnaire.
    final bloc = context.read<CompleteTestBloc>();
    try {
      // RÉADOPTION AVANT TOUTE MESURE. La passation reprise a déjà un
      // identifiant côté serveur ; sans l'adopter ici, le premier exercice
      // terminé ouvrirait une SECONDE passation et la première resterait
      // ouverte à jamais. C'est le seul endroit où la batterie démarre, donc
      // le seul où cette garantie tient.
      final reprise = widget.reprise;
      if (reprise != null) await ResumeService.instance.adopt(reprise);
      // `context.mounted` et non `mounted` : c'est le contexte PASSÉ EN
      // PARAMÈTRE qui traverse l'await, pas celui de l'État.
      if (!context.mounted) return;

      final ok = await ensurePretest(
        context,
        store: widget.pretestStore ?? const PretestStore(),
      );
      if (!mounted || !ok) return;
      bloc.add(reprise != null
          ? ResumeTestEvent(ageInMonths: ageInMonths, reprise: reprise)
          : StartTestEvent(ageInMonths));
    } finally {
      if (mounted) setState(() => _launching = false);
    }
  }

  void _launchTest(BuildContext context, String testName) {
    final page = _getTestPage(context, testName);
    Navigator.push<int>(
      context,
      MaterialPageRoute(builder: (_) => page),
    ).then((score) {
      if (!context.mounted) return;
      if (score != null) {
        context.read<CompleteTestBloc>().add(
              SubmitSubtestScoreEvent(testName: testName, score: score),
            );
      } else {
        // L'utilisateur a quitté le sous-test sans le terminer (retour
        // arrière). Sans ce garde-fou, aucun événement n'est émis et
        // l'orchestrateur reste bloqué indéfiniment sur « Lancement… ».
        // On propose de reprendre le sous-test ou d'arrêter l'évaluation.
        _handleSubtestAbandon(context, testName);
      }
    });
  }

  Future<void> _handleSubtestAbandon(
      BuildContext context, String testName) async {
    final resume = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.l10n.ctSubtestExitTitle),
        content: Text(dialogContext.l10n.ctSubtestExitBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(dialogContext.l10n.ctSubtestExitPause),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(dialogContext.l10n.ctSubtestExitResume),
          ),
        ],
      ),
    );
    if (!context.mounted) return;
    if (resume == true) {
      _launchTest(context, testName); // relance le même sous-test
    } else {
      // PAUSE. Rien à sauvegarder ici : tout exercice terminé est déjà écrit,
      // en local à chaque score et côté serveur au fil de l'eau. Quitter est
      // donc sans perte, et l'accueil proposera de reprendre à cet exercice.
      Navigator.of(context).maybePop();
    }
  }

  /// Collecte audio de fin de parcours — HORS du bilan annoncé.
  ///
  /// Le bilan, c'est **12 épreuves réparties en 5 domaines** : c'est ce que
  /// l'écran d'entrée promet, c'est ce qui est noté, c'est ce qui entre dans le
  /// calcul du QI. L'étape orale n'en fait pas partie : elle ne produit aucun
  /// score et n'apparaît nulle part dans les résultats.
  ///
  /// Elle est la CONTREPARTIE du passe Gratuit — le bilan y est financé par un
  /// enregistrement vocal destiné au corpus. Elle n'est donc jouée que pour ce
  /// plan-là : un passe Payant passe directement aux résultats, et un passe
  /// sans plan lisible (`sv: 2`, antérieur au 2026-09-02) retombe sur l'écran
  /// de consentement in-app géré par [OralTestFlow], dont un refus fait
  /// simplement sauter l'étape (pop immédiat).
  ///
  /// Le plan est relu APRÈS la déclaration de fin de test — voir plus bas :
  /// aucun `await` ne doit s'intercaler avant elle.
  Future<void> _finishWithOralThenResults(
    BuildContext context,
    CompleteTestDoneState state,
  ) async {
    if (_postBatteryStarted) return;
    _postBatteryStarted = true;

    // LE TEST EST TERMINÉ ICI : on le déclare au serveur MAINTENANT, avant
    // toute étape facultative. Cette déclaration est la seule porte qui
    // crédite le parrain d'un filleul ; tant qu'elle vivait sur l'écran de
    // résultats, l'étape orale ci-dessous (~10 min, micro, consentement)
    // s'intercalait entre la fin du test et le crédit : une app fermée là et
    // le parrainage était perdu définitivement, sans aucun message.
    // Elle est persistée et rejouée jusqu'à confirmation (CompletionReporter).
    final session = state.session;
    final duree = session.totalDuration ??
        DateTime.now().difference(session.startTime);
    unawaited(CompletionReporter.instance.declare(
      subtestsCompleted: session.completedTestsCount,
      durationSeconds: duree.inSeconds,
    ));

    // Les résultats partent séparément, et VOLONTAIREMENT hors du gate de
    // déblocage : `declare()` sort tôt quand le gate est éteint, alors que les
    // scores doivent être conservés dans tous les cas — ils sont ce qui rend la
    // passation portable d'un appareil à l'autre (/login-token retrouve le même
    // `account`) et ce qui alimentera la calibration.
    //
    // Rattachés au token, donc à personne. Tir-et-oublie : un échec de
    // téléversement ne doit jamais retarder l'écran de résultats, les scores
    // restant de toute façon en local.
    unawaited(ResultsSync.instance.complete(
      durationSeconds: duree.inSeconds,
      subtests: session.toResultsPayload(),
    ));

    // LE PLAN SE LIT ICI, PAS PLUS HAUT. Cette lecture touche le disque
    // (token persisté) : la placer avant `declare()` y insérerait un `await`,
    // et une app fermée dans cette fenêtre perdrait définitivement le crédit
    // du parrain — exactement le bug de juillet 2026, réintroduit par la
    // bande. Les deux envois ci-dessus sont déjà partis (tir-et-oublie,
    // rejoués jusqu'à confirmation), on peut prendre notre temps.
    final plan = await TokenClaimsReader.currentPlan();
    if (!context.mounted) return;

    if (plan.plan != TokenPlan.paid) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const OralTestFlow()),
      );
      if (!context.mounted) return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CompleteTestResultsPage(
          session: state.session,
          ageInMonths: state.ageInMonths,
        ),
      ),
    );
  }

  Widget _getTestPage(BuildContext context, String testName) {
    switch (testName) {
      case 'Cubes':
        return const CubesTestPage();
      case 'Similitudes':
        return const SimilaritiesTestPage();
      case 'Mémoire des Chiffres':
        return const DigitSpanTestPage();
      case 'Matrices':
        return const MatricesTestPage();
      case 'Vocabulaire':
        return const VocabularyTestPage();
      case 'Arithmétique':
        return const ArithmeticTestPage();
      case 'Recherche de Symboles':
        return const SymbolSearchTestPage();
      case 'Puzzles Visuels':
        return const VisualPuzzlesTestPage();
      case 'Information':
        return const InformationTestPage();
      case 'Code':
        return const CodingTestPage();
      case 'Mémoire des Images':
        return const PictureSpanTestPage();
      case 'Balances':
        return const FigureWeightsTestPage();
      default:
        return KeplerScaffold(
          title: context.l10n.commonError,
          child: Center(child: Text(context.l10n.ctTestNotFound(testName))),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CompleteTestBloc, CompleteTestState>(
      listener: (context, state) {
        if (state is CompleteTestRunningState) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (context.mounted) _launchTest(context, state.nextTestName);
          });
        } else if (state is CompleteTestDoneState) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) _finishWithOralThenResults(context, state);
          });
        }
      },
      builder: (context, state) {
        if (state is CompleteTestIntroState) {
          // En reprise avec un âge lisible dans le token, l'intro n'est qu'un
          // clignotement avant le lancement automatique : on montre directement
          // l'écran d'attente, qui porte la vraie progression.
          return (_estReprise && (_ageLoading || _ageFromToken))
              ? _buildProgressScreen(context, state)
              : _buildIntroScreen(context);
        }
        if (state is CompleteTestDoneState) {
          return KeplerScaffold(
            title: context.l10n.ctComputingResultsTitle,
            eyebrow: context.l10n.ctComputingResultsEyebrow,
            scroll: false,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: KeplerColors.of(context).primary),
                  SizedBox(height: 20.h),
                  Text(context.l10n.ctProcessing,
                      style: AppText.of(context).monoLabel(color: KeplerColors.of(context).primary)),
                ],
              ),
            ),
          );
        }
        return _buildProgressScreen(context, state);
      },
    );
  }

  Widget _buildIntroScreen(BuildContext context) {
    return KeplerScaffold(
      title: context.l10n.ctIntroTitle,
      eyebrow: context.l10n.assessIntroEyebrow,
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.ctIntroHero1, style: AppText.of(context).heroDisplay()),
          Text(context.l10n.ctIntroHero2, style: AppText.of(context).heroItalic()),
          SizedBox(height: 16.h),
          Container(
              width: 36.w,
              height: 1,
              color: KeplerColors.of(context).primary.withValues(alpha: 0.4)),
          SizedBox(height: 16.h),
          Text(
            context.l10n.ctIntroDescription,
            style: AppText.of(context).body(),
          ),
          SizedBox(height: 24.h),
          _InfoCard(
              eyebrow: context.l10n.ctIntroDurationEyebrow,
              title: context.l10n.ctIntroDurationTitle,
              body: context.l10n.ctIntroDurationBody),
          SizedBox(height: 12.h),
          _InfoCard(
              eyebrow: context.l10n.ctIntroContentEyebrow,
              title: context.l10n.ctIntroContentTitle,
              body: context.l10n.ctIntroContentBody),
          SizedBox(height: 12.h),
          _InfoCard(
              eyebrow: context.l10n.ctIntroImportantEyebrow,
              title: context.l10n.ctIntroImportantTitle,
              body: context.l10n.ctIntroImportantBody),
          // L'âge n'est plus SAISI : il est dérivé du token (année + mois de
          // naissance). Le champ manuel ne réapparaît qu'en secours si le
          // token est indécodable — situation anormale, l'accès étant déjà
          // verrouillé par un token valide en amont.
          if (_ageLoading) ...[
            SizedBox(height: 24.h),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: CircularProgressIndicator(color: KeplerColors.of(context).primary),
              ),
            ),
          ] else if (!_ageFromToken) ...[
            SizedBox(height: 24.h),
            KeplerCard(
              surface: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.l10n.ctPatientAgeHeader,
                      style: AppText.of(context).monoLabel(color: KeplerColors.of(context).primary)),
                  SizedBox(height: 12.h),
                  Text(context.l10n.ctPatientAgeHint,
                      style: AppText.of(context).bodySmall()),
                  SizedBox(height: 12.h),
                  TextField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    style: AppText.of(context).monoScore(size: 22.sp),
                    decoration: InputDecoration(
                      hintText: '00',
                      hintStyle: AppText.of(context).monoScore(
                          color: Theme.of(context).colorScheme.outline,
                          size: 22.sp),
                      suffixText: context.l10n.ctAgeSuffix,
                      suffixStyle: AppText.of(context).monoLabel(
                          color: Theme.of(context).colorScheme.outline),
                      filled: true,
                      fillColor: Theme.of(context).scaffoldBackgroundColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6.r),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6.r),
                        borderSide: BorderSide(
                            color: Colors.black.withValues(alpha: 0.07)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6.r),
                        borderSide: BorderSide(
                            color: KeplerColors.of(context).primary, width: 2),
                      ),
                    ),
                    onChanged: (v) {
                      final years = int.tryParse(v);
                      setState(() {
                        _ageInMonths =
                            (years != null && years >= 16 && years <= 90)
                                ? years * 12
                                : null;
                      });
                    },
                  ),
                  if (_ageController.text.isNotEmpty && _ageInMonths == null)
                    Padding(
                      padding: EdgeInsets.only(top: 8.h),
                      child: Text(context.l10n.ctAgeRangeError,
                          style: AppText.of(context).bodySmall(color: KeplerColors.of(context).error)),
                    ),
                ],
              ),
            ),
          ],
          SizedBox(height: 24.h),
          KeplerButton(
            label: _estReprise
                ? context.l10n.ctResumeFullTest
                : context.l10n.ctLaunchFullTest,
            icon: Icons.east,
            expand: true,
            onPressed: (_ageInMonths != null && !_launching)
                ? () => _startBattery(context, _ageInMonths!)
                : null,
          ),
          SizedBox(height: 12.h),
          KeplerButton(
            label: context.l10n.commonCancel,
            variant: KeplerButtonVariant.ghost,
            expand: true,
            onPressed: () => Navigator.pop(context),
          ),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  Widget _buildProgressScreen(BuildContext context, CompleteTestState state) {
    final session = state is CompleteTestRunningState
        ? state.session
        : state is CompleteTestAwaitingNextState
            ? state.session
            : null;

    // Pendant la reprise, la session du BLoC n'existe pas encore (l'âge se lit
    // d'abord depuis le token). Afficher 0/12 à ce moment-là ferait croire à un
    // redémarrage : on montre la progression réelle, connue avant même le BLoC.
    final reprise = widget.reprise;
    final total = session?.totalTests ?? reprise?.totalTests ?? 12;
    final completed = session?.completedTestsCount ?? reprise?.completedCount ?? 0;
    final progress = total == 0 ? 0.0 : completed / total;
    final next = state is CompleteTestRunningState ? state.nextTestName : null;

    return KeplerScaffold(
      title: context.l10n.ctRunningTitle,
      eyebrow: context.l10n.assessIntroEyebrow,
      scroll: false,
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          KeplerProgress(
            value: progress,
            current: completed,
            total: total,
            label: context.l10n.ctGlobalProgress,
          ),
          SizedBox(height: 40.h),
          if (next != null) ...[
            Text(context.l10n.ctNextSubtest,
                style: AppText.of(context).monoLabel(color: KeplerColors.of(context).primary)),
            SizedBox(height: 8.h),
            Text(localizedSubtestName(context, next), style: AppText.of(context).h1Italic()),
            SizedBox(height: 24.h),
          ],
          Row(
            children: [
              SizedBox(
                width: 18.w,
                height: 18.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: KeplerColors.of(context).primary,
                ),
              ),
              SizedBox(width: 12.w),
              Text(context.l10n.ctLaunching,
                  style: AppText.of(context).monoLabel(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard(
      {required this.eyebrow, required this.title, required this.body});
  final String eyebrow;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return KeplerCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 3.w, height: 36.h, color: KeplerColors.of(context).primary),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(eyebrow,
                    style: AppText.of(context).monoLabel(color: KeplerColors.of(context).primary)),
                SizedBox(height: 4.h),
                Text(title, style: AppText.of(context).bodyStrong()),
                SizedBox(height: 4.h),
                Text(body, style: AppText.of(context).bodySmall()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
