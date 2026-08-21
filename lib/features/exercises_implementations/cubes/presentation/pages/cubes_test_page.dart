import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/l10n/l10n_ext.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/test/kepler_test_button.dart';
import '../../../../../core/widgets/test/kepler_test_scaffold.dart';
import '../widgets/cubes_exercise_widget.dart';
import '../../domain/pattern_generator.dart';
import '../../../../../core/theme/kepler_colors.dart';
import '../../../../../core/services/results_sync.dart';
import '../../../../../core/services/subtest_instrumentation.dart';

/// Page de test des Cubes avec progression par niveaux
class CubesTestPage extends StatefulWidget {
  final String? filterLevel;
  const CubesTestPage({super.key, this.filterLevel});

  @override
  State<CubesTestPage> createState() => _CubesTestPageState();
}

class _CubesTestPageState extends State<CubesTestPage> {
  int currentLevel = 0;
  int score = 0;

  /// Mesure item par item (latence, hésitation, reprises).
  /// Aucune frappe individuelle n'est captée — cf. SubtestInstrumentation.
  final SubtestInstrumentation _instr =
      SubtestInstrumentation('block_design');
  int totalTime = 0;
  bool showResult = false;
  bool? lastAnswerCorrect;

  late final CubePatternGenerator _patternGenerator;
  late List<CubePattern> _generatedPatterns;

  // 14 items selon WAIS-IV : 2 exemples + 3 faciles + 4 moyens + 5 difficiles.
  // L'ordre canonique (figé, versionné) est défini une seule fois dans le
  // générateur → source unique de vérité pour la banque déterministe.
  final List<DifficultyLevel> _difficultyProgression =
      CubePatternGenerator.kDifficultyProgression;

  int _consecutiveFailures = 0;

  /// Phase de DÉMONSTRATION : TROIS items d'exemple fixes, sans chrono ni
  /// score, chacun rejouable jusqu'à réussite — comme la démonstration du
  /// protocole réel.
  ///
  /// Trois et non un : le deuxième item est le seul endroit où le sujet peut
  /// découvrir que les faces DIAGONALES existent et s'atteignent en appuyant
  /// plusieurs fois sur la même case. Un entraînement 2×2 en aplats seuls
  /// laissait croire qu'un appui = une case terminée, et la découverte se
  /// faisait à l'item 6, chronométré et coté.
  bool _demoPhase = true;
  final List<CubePattern> _demoPatterns = CubePatternGenerator.demoPatterns();
  int _demoIndex = 0;
  bool? _demoLastCorrect;

  /// Clé du widget d'exercice pendant la démo : on l'incrémente à chaque
  /// réessai pour forcer une reconstruction complète de
  /// [CubesExerciseWidget] (son état d'assemblage — grille utilisateur,
  /// chrono interne, isCompleted — est privé, donc on repart d'un widget
  /// neuf plutôt que d'exposer une méthode de reset publique).
  int _demoAttempt = 0;

  /// Vrai sur le dernier item d'entraînement : le bouton propose alors de
  /// commencer le test, et non de passer à l'entraînement suivant.
  bool get _isLastDemo => _demoIndex >= _demoPatterns.length - 1;

  @override
  void initState() {
    super.initState();
    // Sans seed → tirage aléatoire par passation : les motifs changent à
    // chaque session, seule la progression de difficulté est fixe.
    _patternGenerator = CubePatternGenerator();
    _generateLevels();
    // La démonstration n'est pas chronométrée : le chrono (interne au
    // widget d'exercice) ne démarre qu'au passage au premier item réel
    // (_startRealTest), car on passe timeLimitSeconds: null pendant la démo.
  }

  void _generateLevels() {
    final level = widget.filterLevel;
    final progression = level != null
        ? _difficultyProgression.where((d) => d.name == level).toList()
        : _difficultyProgression;
    final effectiveProgression = progression.isNotEmpty ? progression : _difficultyProgression;
    _generatedPatterns = effectiveProgression
        .map((difficulty) => _patternGenerator.generatePattern(difficulty))
        .toList();
  }

  /// Pattern courant : item de démonstration fixe pendant la phase
  /// d'entraînement, sinon l'item réel généré pour le niveau courant.
  CubePattern get _currentPattern =>
      _demoPhase ? _demoPatterns[_demoIndex] : _generatedPatterns[currentLevel];

  void _startRealTest() {
    setState(() => _demoPhase = false);
  }

  /// Item d'entraînement suivant. Comme [_retryDemo], on incrémente
  /// [_demoAttempt] : la clé du widget change, donc la grille repart vide.
  void _nextDemo() {
    setState(() {
      _demoIndex++;
      _demoLastCorrect = null;
      _demoAttempt++;
    });
  }

  void _retryDemo() {
    setState(() {
      _demoLastCorrect = null;
      _demoAttempt++;
    });
  }

  void _handleComplete(bool isCorrect, int timeSeconds) {
    // Cubes n'a pas d'ouverture d'item explicite : on ouvre et on ferme
    // au même endroit, la durée réelle venant du widget de construction.
    if (!_demoPhase) _instr.startItem(index: currentLevel);
    if (_demoPhase) {
      // Démo : feedback visuel seulement — ni score, ni règle d'arrêt, ni
      // avance automatique (le bouton bas devient « Commencer » / « Réessayer »).
      setState(() => _demoLastCorrect = isCorrect);
      return;
    }

    setState(() {
      showResult = true;
      lastAnswerCorrect = isCorrect;
      totalTime += timeSeconds;

    _instr.endItem(isCorrect: isCorrect, score: isCorrect ? 1 : 0);

      // Gestion des échecs consécutifs
      if (isCorrect) {
        _consecutiveFailures = 0;
        // Calcul du score (pas de points pour les exemples)
        if (currentLevel >= 2) {
          int points = _calculatePoints(timeSeconds);
          score += points;
        }
      } else {
        _consecutiveFailures++;
      }
    });

    // Test non noté à l'écran : aucun retour « juste/faux », on enchaîne.
    // Discontinuation : 2 échecs consécutifs.
    if (_consecutiveFailures >= 2 ||
        currentLevel >= _generatedPatterns.length - 1) {
      _showFinalResults();
    } else {
      setState(() {
        currentLevel++;
        showResult = false;
        lastAnswerCorrect = null;
      });
    }
  }

  int _calculatePoints(int timeSeconds) {
    // Barème harmonisé : précision pure, AUCUN bonus de temps.
    // Items 3-5 (indices 2-4) : 2 points ; items 6-14 (indices 5-13) : 4 points.
    if (currentLevel >= 2 && currentLevel <= 4) {
      return 2;
    }
    return 4;
  }

  void _showFinalResults() {
    // Les mesures partent MAINTENANT, sous-test par sous-test : une app
    // fermée plus loin dans la batterie ne doit pas emporter ce qui a déjà
    // été mesuré. Tir-et-oublie, fail-soft.
    unawaited(ResultsSync.instance.flushSubtest(
      _instr.toPayload(rawScore: score, maxScore: _generatedPatterns.length),
    ));

    // Test non noté à l'écran : aucun récapitulatif de points/temps/réussite,
    // simple confirmation de fin — le score repart vers l'appelant, sans être montré.
    // Aucune option « Recommencer » : un sous-test WAIS-IV ne se repasse pas
    // (effet d'apprentissage sur des items déjà vus → normes invalidées).
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.cubesFinishedTitle),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, score); // Retourne le score final
            },
            child: Text(context.l10n.commonFinish),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pattern = _currentPattern;

    return KeplerTestScaffold(
      stimulusSurface: true,
      testName: context.l10n.cubesTestName,
      eyebrow: _demoPhase ? context.l10n.demoBadge : context.l10n.fwEyebrow,
      accentColor: AppColors.indexFRI,
      // Pendant l'entraînement, la barre compte les 3 items d'exemple et non
      // les 14 items cotés — l'eyebrow « ENTRAÎNEMENT » lui sert de libellé,
      // donc « 2/3 » ne peut pas se lire comme une progression dans le test.
      currentItem: _demoPhase ? _demoIndex + 1 : currentLevel + 1,
      totalItems: _demoPhase ? _demoPatterns.length : _generatedPatterns.length,
      // Tout tient à l'écran : les deux grilles se redimensionnent à la
      // hauteur disponible, les boutons restent toujours visibles.
      scrollable: false,
      // Aucun score visible pendant la passation (protocole WAIS-IV) : seule
      // la progression d'items est affichée, jamais les points obtenus.
      bottomBar: _demoPhase && _demoLastCorrect != null
          ? KeplerTestButton.primary(
              label: !_demoLastCorrect!
                  ? context.l10n.demoRetry
                  : _isLastDemo
                      ? context.l10n.demoStart
                      : context.l10n.demoContinue,
              accentColor: AppColors.indexFRI,
              onPressed: !_demoLastCorrect!
                  ? _retryDemo
                  : _isLastDemo
                      ? _startRealTest
                      : _nextDemo,
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Niveau — version compacte (la progression est déjà dans le scaffold)
          _demoPhase
              ? _buildDemoHeader(context)
              : _buildLevelHeader(context, pattern),
          SizedBox(height: 8.h),

          // Exercice — occupe toute la hauteur restante
          Expanded(
            child: CubesExerciseWidget(
              // Pendant la démo, on incrémente la clé à chaque réessai pour
              // forcer un widget neuf (état d'assemblage interne réinitialisé).
              key: _demoPhase
                  ? ValueKey('demo-$_demoIndex-$_demoAttempt')
                  : ValueKey(currentLevel),
              gridSize: pattern.gridSize,
              targetPattern: pattern.pattern,
              // Pas de chrono pendant la démo : le compte à rebours interne
              // du widget ne s'active que si timeLimitSeconds != null.
              timeLimitSeconds: _demoPhase ? null : pattern.timeLimit,
              onComplete: _handleComplete,
            ),
          ),
        ],
      ),
    );
  }

  /// Bandeau compact affiché pendant la démo (remplace _buildLevelHeader,
  /// qui affiche la difficulté/cohésion — non pertinentes hors barème).
  Widget _buildDemoHeader(BuildContext context) {
    return Text(
      context.l10n.demoNotice,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 12.sp,
        color: KeplerColors.of(context).textSecondary,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  // Version compacte : la progression d'items est déjà affichée par le
  // scaffold (KeplerProgress) — on ne garde que difficulté + description.
  Widget _buildLevelHeader(BuildContext context, CubePattern pattern) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Text(
            _getDifficultyLabel(context, pattern.difficulty),
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            _getPatternDescription(context, pattern.difficulty),
            style: TextStyle(
              fontSize: 11.sp,
              color: KeplerColors.of(context).textSecondary,
              fontStyle: FontStyle.italic,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _getDifficultyLabel(BuildContext context, DifficultyLevel difficulty) {
    final l10n = context.l10n;
    switch (difficulty) {
      case DifficultyLevel.example:
        return l10n.cubesDiffExample;
      case DifficultyLevel.veryEasy:
        return l10n.matDiffEasy;
      case DifficultyLevel.easy:
        return l10n.matDiffMedium;
      case DifficultyLevel.medium:
        return l10n.matDiffMedium;
      case DifficultyLevel.mediumHard:
        return l10n.matDiffHard;
      case DifficultyLevel.hard:
        return l10n.matDiffHard;
      case DifficultyLevel.veryHard:
        return l10n.cubesDiffVeryHard;
    }
  }

  String _getPatternDescription(
      BuildContext context, DifficultyLevel difficulty) {
    final l10n = context.l10n;
    switch (difficulty) {
      case DifficultyLevel.example:
        return l10n.cubesDescExample;
      case DifficultyLevel.veryEasy:
        return l10n.cubesDesc2x2;
      case DifficultyLevel.easy:
      case DifficultyLevel.medium:
        return l10n.cubesDesc3x3Diagonals;
      case DifficultyLevel.mediumHard:
      case DifficultyLevel.hard:
      case DifficultyLevel.veryHard:
        return l10n.cubesDesc3x3Complex;
    }
  }
}
