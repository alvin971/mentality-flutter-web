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
import '../../domain/vocabulary_generator.dart';
import '../../../../../core/services/results_sync.dart';
import '../../../../../core/models/complete_test_session.dart';
import '../../../../../core/services/subtest_instrumentation.dart';

/// Page du test de Vocabulaire (Vocabulary)
/// WAIS-IV : 30 mots
/// Définir le mot présenté
/// Scoring : 0, 1, ou 2 points selon la précision de la définition
/// Règle de discontinuation : 3 scores consécutifs de 0
class VocabularyTestPage extends StatefulWidget {
  final String? filterLevel;
  const VocabularyTestPage({super.key, this.filterLevel});

  @override
  State<VocabularyTestPage> createState() => _VocabularyTestPageState();
}

class _VocabularyTestPageState extends State<VocabularyTestPage> {
  int currentLevel = 0;

  int totalTime = 0;
  /// NON-RÉPONSES consécutives. Ce n'est plus le score qui arrête ce sous-test.
  /// La notation algorithmique s'est révélée fausse sur des réponses justes
  /// (« Fruit » refusé parce que la table dit « Des fruits ») et disqualifiait
  /// des gens qui avaient bien répondu. Seul un renoncement explicite arrête.
  int _consecutiveSkips = 0;
  final TextEditingController _answerController = TextEditingController();

  /// Mesure item par item (latence, hésitation, reprises) — cf.
  /// SubtestInstrumentation. Aucune frappe individuelle n'est captée.
  final SubtestInstrumentation _instr = SubtestInstrumentation('vocabulary');
  String _prevAnswer = '';
  DateTime? _itemStartTime;
  Timer? _timer;
  int _elapsedSeconds = 0;

  late List<VocabularyItem> _generatedItems;
  final List<ItemResult> _results = [];

  /// Phase d'entraînement (« pour bien commencer ») : un mot d'exemple fixe,
  /// hors chrono, hors score, hors progression. L'utilisateur peut saisir
  /// une définition librement mais elle n'est ni jugée ni corrigée — c'est
  /// un exercice verbal ouvert, pas un item à réponse fermée comme les
  /// Puzzles Visuels.
  bool _demoPhase = true;

  /// Mot d'exemple pour la démonstration, localisé selon la langue de contenu
  /// active (« Vélo », « Bicycle », « Bicicleta », « Fahrrad »…). Ce mot est
  /// absent des banques notées : la démo ne divulgue donc aucun item réel. La
  /// définition n'est jamais jugée ni affichée (listes de réponses vides).
  late final VocabularyItem _demoItem;

  /// Mot d'exemple localisé pour la démonstration.
  static VocabularyItem _demoItemFor(String tag) {
    const words = {
      'en': 'Bicycle',
      'en-GB': 'Bicycle',
      'es': 'Bicicleta',
      'pt': 'Bicicleta',
      'de': 'Fahrrad',
      'fr': 'Vélo',
    };
    return VocabularyItem(
      word: words[tag] ?? 'Vélo',
      frequency: WordFrequency.veryHigh,
      twoPointAnswers: const [],
      onePointAnswers: const [],
      thetaValue: -2.0,
    );
  }

  VocabularyItem get _currentItem =>
      _demoPhase ? _demoItem : _generatedItems[currentLevel];

  @override
  void initState() {
    super.initState();
    _demoItem = _demoItemFor(localeNotifier.contentTag);
    _generateItems();
    // La démonstration n'est pas chronométrée : le chrono ne démarre qu'au
    // passage au premier item réel (_startRealTest).
    _answerController.clear();
  }

  /// Quitte la phase de démonstration et démarre le premier item réel
  /// (chrono compris).
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
    // Génération des 30 items UNIQUES en une seule fois
    final generator =
        VocabularyGenerator(languageCode: localeNotifier.contentTag);
    _generatedItems = generator.generateComplete30Items();
  }

  void _startItem() {
    _itemStartTime = DateTime.now();
    _elapsedSeconds = 0;
    _answerController.clear();
    _prevAnswer = '';
    if (currentLevel < _generatedItems.length) {
      _instr.startItem(
        index: currentLevel,
        itemId: _generatedItems[currentLevel].word,
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

    // AUCUN jugement ici — cf. Similitudes. La définition d'un mot ne se juge
    // pas par comparaison de chaînes ; une IA notera en aval.
    _results.add(ItemResult(
      word: currentItem.word,
      userAnswer: userAnswer,
      score: 0,
      timeSeconds: timeSeconds,
    ));

    _instr.endItem(response: userAnswer, skipped: renonce);

    if (renonce) {
      _consecutiveSkips++;
    } else {
      _consecutiveSkips = 0;
    }

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

  void _showFinalResults() {
    // Les mesures partent MAINTENANT, sous-test par sous-test, plutôt qu'en un
    // seul envoi à la fin des 12 : une app fermée plus loin dans la batterie ne
    // doit pas emporter ce qui a déjà été mesuré. Tir-et-oublie, fail-soft.
    unawaited(ResultsSync.instance.flushSubtest(
      // Ni `rawScore` ni `maxScore` : le score n'existe pas encore.
      _instr.toPayload(scoring: 'ai_pending'),
    ));

    // Test non noté à l'écran : aucun récapitulatif de points/temps/réussite,
    // simple confirmation de fin — le score repart vers l'appelant, sans être montré.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.vocabResultsTitle),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Terminé, mais délibérément NON NOTÉ (≠ null, qui veut dire
              // « quitté sans finir »).
              Navigator.of(context).pop(CompleteTestSession.awaitingAiScore);
            },
            child: Text(context.l10n.commonBack),
          ),
        ],
      ),
    );
  }

  /// Nom localisé du niveau de fréquence (FR/EN selon la locale courante).
  String _frequencyName(WordFrequency frequency) {
    final l10n = context.l10n;
    switch (frequency) {
      case WordFrequency.veryHigh:
        return l10n.vocabFreqVeryHigh;
      case WordFrequency.high:
        return l10n.vocabFreqHigh;
      case WordFrequency.medium:
        return l10n.vocabFreqMedium;
      case WordFrequency.low:
        return l10n.vocabFreqLow;
      case WordFrequency.veryLow:
        return l10n.vocabFreqVeryLow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final currentItem = _currentItem;

    return KeplerTestScaffold(
      testName: l10n.vocabTestName,
      eyebrow: _demoPhase ? l10n.demoBadge : l10n.vocabEyebrow,
      accentColor: AppColors.indexVCI,
      // Pas de barre de progression pendant la démo (hors des 30 items) :
      // l'eyebrow « ENTRAÎNEMENT » s'affiche alors dans l'AppBar.
      currentItem: _demoPhase ? null : currentLevel + 1,
      totalItems: _demoPhase ? null : _generatedItems.length,
      // Timer + score dans l'AppBar et bouton Valider sticky en bas :
      // visible sans scroller, et il reste au-dessus du clavier.
      // Masqués pendant la démo : ni chrono ni score ne sont engagés.
      trailing: _demoPhase
          ? null
          : [
              Padding(
                padding: EdgeInsets.only(left: 8.w),
                child: Text(l10n.commonSeconds(_elapsedSeconds),
                    style: AppText.of(context).monoLabel(color: AppColors.indexVCI)),
              ),
            ],
      bottomBar: _demoPhase
          ? KeplerTestButton.primary(
              label: l10n.demoStart,
              accentColor: AppColors.indexVCI,
              onPressed: _startRealTest,
            )
          : Row(
              children: [
                // Sans « Passer », l'arrêt sur non-réponse serait inatteignable.
                Expanded(
                  child: KeplerTestButton.outlined(
                    label: l10n.commonSkip,
                    accentColor: AppColors.indexVCI,
                    onPressed: _submitAnswer,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  flex: 2,
                  child: KeplerTestButton.primary(
                    label: l10n.commonValidate,
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
          // Instructions
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: AppColors.infoContainer,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: AppColors.infoLight),
            ),
            child: Text(
              l10n.vocabInstruction,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          if (_demoPhase) ...[
            SizedBox(height: 8.h),
            Text(
              l10n.demoNotice,
              style: TextStyle(
                fontSize: 12.sp,
                fontStyle: FontStyle.italic,
                color: KeplerColors.of(context).textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],

          SizedBox(height: 12.h),

          // Le mot à définir
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.indexVCI.withValues(alpha: 0.15),
                  AppColors.indexVCI.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: AppColors.indexVCI, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.indexVCI.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              // FittedBox : les mots longs se réduisent au lieu de
              // déborder sur les écrans étroits.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  currentItem.word,
                  style: TextStyle(
                    fontSize: 34.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.indexVCI,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: 12.h),

          // Fréquence du mot
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: _getFrequencyColor(currentItem.frequency),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star,
                      size: 16.sp,
                      color: Theme.of(context).colorScheme.surface,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      _frequencyName(currentItem.frequency),
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 12.h),

          // Champ de réponse
          Text(
            l10n.vocabYourDefinitionLabel,
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
            // Mobile : la touche Entrée du clavier devient « OK » (au lieu
            // d'un retour à la ligne) et valide la réponse ; taper hors du
            // champ referme le clavier — sinon il masque le bouton Valider.
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              // Pendant la démo, « Terminé » démarre le test au lieu de valider
              // un item réel jamais affiché (cf. Similitudes).
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
              hintText: l10n.vocabDefinitionHint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: KeplerColors.of(context).border, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: AppColors.indexVCI, width: 2),
              ),
              filled: true,
              fillColor: KeplerColors.of(context).surface,
              contentPadding: EdgeInsets.all(16.w),
            ),
            textCapitalization: TextCapitalization.sentences,
            style: TextStyle(fontSize: 15.sp),
          ),

          SizedBox(height: 12.h),

          // Aide au scoring
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: AppColors.warningContainer,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.warningLight, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: KeplerColors.of(context).warning,
                      size: 20.sp,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        l10n.vocabTipsTitle,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                          color: AppColors.tertiary,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  l10n.vocabTipComplete,
                  style: TextStyle(fontSize: 13.sp),
                ),
                Text(
                  l10n.vocabTipSynonyms,
                  style: TextStyle(fontSize: 13.sp),
                ),
                Text(
                  l10n.vocabTipContext,
                  style: TextStyle(fontSize: 13.sp),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getFrequencyColor(WordFrequency frequency) {
    switch (frequency) {
      case WordFrequency.veryHigh:
        return AppColors.success;
      case WordFrequency.high:
        return AppColors.info;
      case WordFrequency.medium:
        return AppColors.warning;
      case WordFrequency.low:
        return AppColors.indexPSI;
      case WordFrequency.veryLow:
        return AppColors.error;
    }
  }
}

// ========== MODÈLE DE RÉSULTAT ==========

class ItemResult {
  final String word;
  final String userAnswer;
  final int score;
  final int timeSeconds;

  ItemResult({
    required this.word,
    required this.userAnswer,
    required this.score,
    required this.timeSeconds,
  });
}
