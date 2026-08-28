import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/l10n/l10n_ext.dart';
import '../../../../../core/l10n/locale_notifier.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/kepler_colors.dart';
import '../../../../../core/widgets/test/kepler_test_button.dart';
import '../../../../../core/widgets/test/kepler_test_scaffold.dart';
import '../../domain/similarities_generator.dart';
import '../../../../../core/services/results_sync.dart';
import '../../../../../core/models/complete_test_session.dart';
import '../../../../../core/services/subtest_instrumentation.dart';
import '../../../../../core/services/subtest_progress_store.dart';

/// Page du test des Similitudes (Similarities)
/// 21 items
/// Expliquer la similitude entre deux mots/concepts
/// Scoring : 0, 1, ou 2 points selon le niveau d'abstraction
/// Règle de discontinuation : 3 scores consécutifs de 0
class SimilaritiesTestPage extends StatefulWidget {
  final String? filterLevel;
  const SimilaritiesTestPage({super.key, this.filterLevel});

  @override
  State<SimilaritiesTestPage> createState() => _SimilaritiesTestPageState();
}

class _SimilaritiesTestPageState extends State<SimilaritiesTestPage> {
  int currentLevel = 0;

  int totalTime = 0;
  /// NON-RÉPONSES consécutives. Ce n'est plus le score qui arrête ce sous-test.
  /// La notation algorithmique s'est révélée fausse sur des réponses justes
  /// (« Fruit » refusé parce que la table dit « Des fruits ») et disqualifiait
  /// des gens qui avaient bien répondu. Seul un renoncement explicite arrête.
  int _consecutiveSkips = 0;
  final TextEditingController _answerController = TextEditingController();

  /// Mesure item par item (latence, hésitation, reprises).
  /// Aucune frappe individuelle n'est captée — cf. SubtestInstrumentation.
  final SubtestInstrumentation _instr =
      SubtestInstrumentation('similarities');
  String _prevAnswer = '';
  DateTime? _itemStartTime;
  Timer? _timer;
  int _elapsedSeconds = 0;

  late List<SimilarityItem> _generatedItems;
  final List<ItemResult> _results = [];

  /// Phase d'ENTRAÎNEMENT : un item d'exemple fixe, sans chrono ni score.
  /// Similitudes est un exercice VERBAL à réponse ouverte (score 0/1/2 par
  /// jugement clinique) : il n'y a PAS de correction automatique possible.
  /// La démo se contente donc de montrer l'exercice et de laisser l'usager
  /// s'exercer librement, sans jugement correct/incorrect.
  bool _demoPhase = true;

  /// Item d'exemple FIXE, localisé selon la langue de contenu active. On
  /// utilise une paire de COULEURS : ce thème est absent des banques de
  /// similitudes, donc l'exemple (et sa réponse type) ne divulgue aucun item
  /// réellement noté. Construit dans initState pour suivre `contentTag`.
  late final SimilarityItem _demoItem;

  /// Paire d'exemple localisée (couleurs) pour la démonstration.
  static SimilarityItem _demoItemFor(String tag) {
    switch (tag) {
      case 'en':
        return SimilarityItem(
            word1: 'Red',
            word2: 'Blue',
            level: AbstractionLevel.concrete,
            twoPointAnswers: const ['They are colors'],
            onePointAnswers: const [],
            thetaValue: -1.5);
      case 'en-GB':
        return SimilarityItem(
            word1: 'Red',
            word2: 'Blue',
            level: AbstractionLevel.concrete,
            twoPointAnswers: const ['They are colours'],
            onePointAnswers: const [],
            thetaValue: -1.5);
      case 'es':
        return SimilarityItem(
            word1: 'Rojo',
            word2: 'Azul',
            level: AbstractionLevel.concrete,
            twoPointAnswers: const ['Son colores'],
            onePointAnswers: const [],
            thetaValue: -1.5);
      case 'pt':
        return SimilarityItem(
            word1: 'Vermelho',
            word2: 'Azul',
            level: AbstractionLevel.concrete,
            twoPointAnswers: const ['São cores'],
            onePointAnswers: const [],
            thetaValue: -1.5);
      case 'de':
        return SimilarityItem(
            word1: 'Rot',
            word2: 'Blau',
            level: AbstractionLevel.concrete,
            twoPointAnswers: const ['Es sind Farben'],
            onePointAnswers: const [],
            thetaValue: -1.5);
      case 'fr':
      default:
        return SimilarityItem(
            word1: 'Rouge',
            word2: 'Bleu',
            level: AbstractionLevel.concrete,
            twoPointAnswers: const ['Ce sont des couleurs'],
            onePointAnswers: const [],
            thetaValue: -1.5);
    }
  }

  @override
  void initState() {
    super.initState();
    _demoItem = _demoItemFor(localeNotifier.contentTag);
    _generateItems();
    // La démonstration n'est pas chronométrée : le chrono ne démarre qu'au
    // passage au premier item réel (_startRealTest).
      _reprendreSiInterrompu();
  }

  SimilarityItem get _currentItem =>
      _demoPhase ? _demoItem : _generatedItems[currentLevel];

  /// Quitte la phase de démonstration et démarre le premier item réel
  /// (chrono inclus). Toujours disponible, même sans réponse saisie : la
  /// démo n'est pas notée, l'usager peut donc l'ignorer et enchaîner.
  void _startRealTest() {
    setState(() => _demoPhase = false);
    _startItem();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _answerController.dispose();
    super.dispose();
  }

  void _generateItems() {
    // Génération des 21 items UNIQUES en une seule fois
    final generator =
        SimilaritiesGenerator(languageCode: localeNotifier.contentTag);
    _generatedItems = generator.generateComplete21Items();
  }

  void _startItem() {
    _itemStartTime = DateTime.now();
    _elapsedSeconds = 0;
    _answerController.clear();
    _prevAnswer = '';
    if (currentLevel < _generatedItems.length) {
      _instr.startItem(
        index: currentLevel,
        // `toString()` sur une classe sans surcharge écrivait
        // « Instance of 'SimilarityItem' » : l'IA qui note en aval n'aurait
        // jamais su QUELLE paire de mots a été présentée.
        itemId: '${_generatedItems[currentLevel].word1}/'
            '${_generatedItems[currentLevel].word2}',
      );
    }

    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  void _submitAnswer() {
    _timer?.cancel();

    final timeSeconds = _itemStartTime != null
        ? DateTime.now().difference(_itemStartTime!).inSeconds
        : 0;

    totalTime += timeSeconds;

    final currentItem = _generatedItems[currentLevel];
    final userAnswer = _answerController.text.trim();

    final renonce = userAnswer.isEmpty;

    // AUCUN jugement ici. On enregistre la réponse telle qu'elle a été écrite ;
    // ni `score` ni `isCorrect` ne partent, une IA les établira en aval à partir
    // de l'item et de la réponse. Poser un « 0 » algorithmique serait un
    // jugement faux, pas une absence de jugement.
    _instr.endItem(response: userAnswer, skipped: renonce);

    unawaited(SubtestProgressStore.instance.jalon(
      subtest: 'similarities',
      prochainItem: currentLevel + 1,
      score: 0,
      instr: _instr,
    ));

    if (renonce) {
      _consecutiveSkips++;
    } else {
      _consecutiveSkips = 0;
    }

    // Enregistrer le résultat
    _results.add(ItemResult(
      word1: currentItem.word1,
      word2: currentItem.word2,
      userAnswer: userAnswer,
      score: 0,
      timeSeconds: timeSeconds,
    ));

    // Arrêt sur RENONCEMENT — 3 items passés d'affilée —, jamais sur un score.
    if (_consecutiveSkips >= 3 ||
        currentLevel >= _generatedItems.length - 1) {
      _showFinalResults();
    } else {
      setState(() {
        currentLevel++;
        _startItem();
      });
    }
  }

  /// Reprend l'exercice au STADE où une pause l'a laissé.
  ///
  /// On restitue le stade — rang, score, progression — jamais l'énoncé : les
  /// items sont regénérés au hasard à chaque lancement, et c'est voulu. Le
  /// compteur d'échecs consécutifs repart à zéro : il porte sur une série en
  /// cours, notion qui ne survit pas à une interruption. Au pire l'exercice
  /// dure un item de plus, jamais un de moins.
  ///
  /// La démonstration est sautée : elle a déjà été vue avant la pause, et la
  /// reposer à chaque reprise en ferait un péage.
  void _reprendreSiInterrompu() {
    final p = SubtestProgressStore.instance.pour('similarities');
    if (p == null) return;
    currentLevel = p.itemIndex;
    _consecutiveSkips = 0;
    _instr.rehydrate(p.items);
    _startRealTest();
  }

  void _showFinalResults() {
    // L'exercice est terminé : plus rien à reprendre. Laisser le point de
    // reprise en place le ferait redémarrer au milieu la fois suivante.
    unawaited(SubtestProgressStore.instance.clear());

    // Les mesures partent MAINTENANT, sous-test par sous-test : une app
    // fermée plus loin dans la batterie ne doit pas emporter ce qui a déjà
    // été mesuré. Tir-et-oublie, fail-soft.
    unawaited(ResultsSync.instance.flushSubtest(
      // Ni `rawScore` ni `maxScore` : le score n'existe pas encore. Le marqueur
      // distingue « en attente de notation » d'un calcul qui aurait échoué.
      _instr.toPayload(scoring: 'ai_pending'),
    ));

    // Test non noté à l'écran : aucun récapitulatif de points/temps/réussite,
    // simple confirmation de fin — le score repart vers l'appelant, sans être montré.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.simResultsTitle),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Terminé, mais délibérément NON NOTÉ (≠ null, qui veut dire
              // « quitté sans finir » et rouvrirait le dialogue de reprise).
              Navigator.of(context).pop(CompleteTestSession.awaitingAiScore);
            },
            child: Text(context.l10n.simBack),
          ),
        ],
      ),
    );
  }

  /// Nom localisé du niveau d'abstraction (remplace [SimilarityItem.levelName]
  /// qui est figé en français).
  String _levelName(AbstractionLevel level) {
    switch (level) {
      case AbstractionLevel.concrete:
        return context.l10n.simLevelConcrete;
      case AbstractionLevel.functional:
        return context.l10n.simLevelFunctional;
      case AbstractionLevel.categorical:
        return context.l10n.simLevelCategorical;
      case AbstractionLevel.abstract:
        return context.l10n.simLevelAbstract;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentItem = _currentItem;

    return KeplerTestScaffold(
      testName: context.l10n.simTestName,
      eyebrow: _demoPhase ? context.l10n.demoBadge : context.l10n.simEyebrow,
      accentColor: AppColors.indexVCI,
      // Pas de barre de progression pendant la démo (hors des 21 items).
      currentItem: _demoPhase ? null : currentLevel + 1,
      totalItems: _demoPhase ? null : _generatedItems.length,
      // Timer + score dans l'AppBar et bouton Valider sticky en bas :
      // visible sans scroller, et il reste au-dessus du clavier.
      // Masqués pendant la démo : ni chrono, ni score en entraînement.
      trailing: _demoPhase
          ? null
          : [
              Padding(
                padding: EdgeInsets.only(left: 8.w),
                child: Text(context.l10n.commonSeconds(_elapsedSeconds),
                    style: AppText.of(context).monoLabel(color: AppColors.indexVCI)),
              ),
            ],
      bottomBar: _demoPhase
          ? KeplerTestButton.primary(
              label: context.l10n.demoStart,
              accentColor: AppColors.indexVCI,
              // Toujours actif : la démo n'est pas notée, une réponse n'est
              // pas requise pour continuer.
              onPressed: _startRealTest,
            )
          : Row(
              children: [
                // Sans « Passer », l'arrêt sur non-réponse serait INATTEIGNABLE :
                // « Valider » est désactivé tant que le champ est vide, donc il
                // était impossible de ne pas répondre.
                Expanded(
                  child: KeplerTestButton.outlined(
                    label: context.l10n.commonSkip,
                    accentColor: AppColors.indexVCI,
                    onPressed: _submitAnswer,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  flex: 2,
                  child: KeplerTestButton.primary(
                    label: context.l10n.commonValidate,
                    accentColor: AppColors.indexVCI,
                    onPressed: _answerController.text.trim().isNotEmpty
                        ? _submitAnswer
                        : null,
                  ),
                ),
              ],
            ),
      child: Column(
crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Bandeau d'entraînement : rappelle que cet essai ne compte pas.
              if (_demoPhase) ...[
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: AppColors.warningContainer,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: AppColors.warningLight),
                  ),
                  child: Text(
                    context.l10n.demoNotice,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 8.h),
              ],
              // Instructions
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColors.infoContainer,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: AppColors.infoLight),
                ),
                child: Text(
                  context.l10n.simQuestionPrompt,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              SizedBox(height: 12.h),

              // Les deux mots
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.indexVCI.withValues(alpha: 0.1),
                      AppColors.indexVCI.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.indexVCI, width: 2),
                ),
                child: Column(
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        currentItem.word1,
                        style: TextStyle(
                          fontSize: 26.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.indexVCI,
                        ),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      '&',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w300,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        currentItem.word2,
                        style: TextStyle(
                          fontSize: 26.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.indexVCI,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 12.h),

              // Niveau d'abstraction
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: _getLevelColor(currentItem.level),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  context.l10n.simLevelLabel(_levelName(currentItem.level)),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              SizedBox(height: 12.h),

              // Champ de réponse
              Text(
                context.l10n.simAnswerLabel,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 6.h),
              TextField(
                controller: _answerController,
                maxLines: 3,
                // Met à jour l'état du bouton Valider à chaque frappe.
                onChanged: (v) {
                  _instr.onInput(previous: _prevAnswer, current: v);
                  _prevAnswer = v;
                  setState(() {});
                },
                // Mobile : la touche Entrée du clavier devient « OK » (au
                // lieu d'un retour à la ligne) et valide la réponse ; taper
                // hors du champ referme le clavier — sinon il masque le
                // bouton Valider.
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {
                  // PENDANT LA DÉMO, « Terminé » doit faire ce que fait le
                  // bouton du bas : démarrer le test. Sans cette garde, la
                  // touche validait un item RÉEL jamais affiché — réponse
                  // perdue, item sauté, zéro injecté dans le compteur d'arrêt.
                  if (_demoPhase) {
                    _startRealTest();
                  } else if (_answerController.text.trim().isNotEmpty) {
                    _submitAnswer();
                  }
                },
                onTapOutside: (_) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
                scrollPadding: EdgeInsets.only(bottom: 140.h),
                decoration: InputDecoration(
                  hintText: context.l10n.simAnswerHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  filled: true,
                  fillColor: KeplerColors.of(context).surface,
                ),
                textCapitalization: TextCapitalization.sentences,
              ),

              SizedBox(height: 16.h),

              // Exemple de bonne réponse (démo uniquement) : pas de jugement
              // automatique correct/incorrect sur ce qui est saisi, on montre
              // simplement à quoi ressemble une réponse complète.
              if (_demoPhase && currentItem.twoPointAnswers.isNotEmpty) ...[
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppColors.infoContainer,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: AppColors.infoLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.simExamples2pts,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.sp,
                          color: KeplerColors.of(context).success,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '• ${currentItem.twoPointAnswers.first}',
                        style: TextStyle(fontSize: 12.sp),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
              ],

              // Aide au scoring
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.warningContainer,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: AppColors.warningLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.simTipsTitle,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.sp,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      context.l10n.simTipsLine1,
                      style: TextStyle(fontSize: 12.sp),
                    ),
                    Text(
                      context.l10n.simTipsLine2,
                      style: TextStyle(fontSize: 12.sp),
                    ),
                  ],
                ),
              ),

            ],
      ),
    );
  }


  Color _getLevelColor(AbstractionLevel level) {
    switch (level) {
      case AbstractionLevel.concrete:
        return AppColors.success;
      case AbstractionLevel.functional:
        return AppColors.info;
      case AbstractionLevel.categorical:
        return AppColors.warning;
      case AbstractionLevel.abstract:
        return AppColors.indexFSIQ;
    }
  }
}

// ========== MODÈLE DE RÉSULTAT ==========

class ItemResult {
  final String word1;
  final String word2;
  final String userAnswer;
  final int score;
  final int timeSeconds;

  ItemResult({
    required this.word1,
    required this.word2,
    required this.userAnswer,
    required this.score,
    required this.timeSeconds,
  });
}
