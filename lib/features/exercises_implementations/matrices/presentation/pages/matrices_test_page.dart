import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/l10n/l10n_ext.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/test/kepler_test_button.dart';
import '../../../../../core/widgets/test/kepler_test_scaffold.dart';
import '../../domain/matrix_generator.dart';
import '../widgets/matrix_cell_widget.dart';
import '../../../../../core/theme/kepler_colors.dart';
import '../../../../../core/services/results_sync.dart';
import '../../../../../core/services/subtest_instrumentation.dart';
import '../../../../../core/services/subtest_progress_store.dart';

/// Page de test des Matrices Progressives (WAIS-IV: 26 items, WISC-V: 32 items)
class MatricesTestPage extends StatefulWidget {
  final String? filterLevel;
  const MatricesTestPage({super.key, this.filterLevel});

  @override
  State<MatricesTestPage> createState() => _MatricesTestPageState();
}

class _MatricesTestPageState extends State<MatricesTestPage> {
  int currentLevel = 0;
  int score = 0;
  int totalTime = 0;
  int _consecutiveFailures = 0;
  MatrixCell? _selectedAnswer;

  /// Mesure item par item (latence, hésitation, changements d'avis).
  final SubtestInstrumentation _instr = SubtestInstrumentation('matrix_reasoning');
  DateTime? _itemStartTime;

  late List<MatrixItem> _generatedItems;

  /// Phase de DÉMONSTRATION : TROIS items d'exemple fixes, sans chrono ni
  /// score, chacun rejouable jusqu'à réussite — comme la démonstration du
  /// protocole réel. Une matrice ne se comprend pas sur un seul exemple : la
  /// règle change d'un item à l'autre (progression, alternance, rotation), et
  /// c'est cette variété que l'entraînement doit montrer.
  bool _demoPhase = true;
  late final List<MatrixItem> _demoItems;

  /// Item d'entraînement courant.
  int _demoIndex = 0;

  /// Seed FIXE des items d'entraînement : tout le monde s'entraîne sur les
  /// mêmes matrices, quelle que soit la passation qui suit.
  static const int _demoSeed = 42;

  /// Nombre d'items d'entraînement.
  static const int _demoCount = 3;

  bool get _isLastDemo => _demoIndex >= _demoItems.length - 1;

  /// Vrai une fois la réponse de démo soumise (affiche le feedback et bascule
  /// le bouton bas sur « Commencer »/« Réessayer »). Sans effet hors démo :
  /// le vrai test affiche un dialog de feedback immédiat à la place.
  bool _demoSubmitted = false;

  @override
  void initState() {
    super.initState();
    _generateItems();
    // Les items d'entraînement viennent d'un tirage SÉPARÉ et graine fixe :
    // les 3 slots les plus faciles d'une banque qui n'est pas celle de la
    // passation. L'entraînement empruntait jusqu'ici le premier item du test,
    // que le sujet retrouvait ensuite à l'identique — première réponse
    // connue d'avance, et un item coté de moins en pratique.
    _demoItems = MatrixGenerator(seed: _demoSeed)
        .generateComplete26Items()
        .take(_demoCount)
        .toList();
    // La démonstration n'est pas chronométrée : le chrono d'item ne démarre
    // qu'au passage au premier item réel (_startRealTest).
      _reprendreSiInterrompu();
  }

  void _generateItems() {
    // Génération des 26 items UNIQUES en une seule fois
    final generator = MatrixGenerator();
    final all = generator.generateComplete26Items();
    final level = widget.filterLevel;
    if (level != null) {
      final filtered = all.where((item) => item.difficulty.name == level).toList();
      _generatedItems = filtered.isNotEmpty ? filtered : all;
    } else {
      _generatedItems = all;
    }
  }

  MatrixItem get _currentItem =>
      _demoPhase ? _demoItems[_demoIndex] : _generatedItems[currentLevel];

  void _startRealTest() {
    setState(() {
      _demoPhase = false;
      _demoSubmitted = false;
      _selectedAnswer = null;
      _itemStartTime = DateTime.now();
      if (!_demoPhase && currentLevel < _generatedItems.length) {
        _instr.startItem(index: currentLevel);
      }
    });
  }

  /// Item d'entraînement suivant : même remise à zéro qu'un réessai, sur
  /// l'item d'après.
  void _nextDemo() {
    setState(() {
      _demoIndex++;
      _selectedAnswer = null;
      _demoSubmitted = false;
    });
  }

  void _retryDemo() {
    setState(() {
      _selectedAnswer = null;
      _demoSubmitted = false;
    });
  }

  void _handleAnswerSelected(MatrixCell answer) {
    if (_demoPhase && _demoSubmitted) return;
    // Changer d'avis compte comme une reprise — signal d'incertitude.
    _instr.onInput(
      previous: _selectedAnswer?.toString() ?? '',
      current: answer.toString(),
    );
    setState(() {
      _selectedAnswer = answer;
    });
  }

  void _handleSubmit() {
    if (_selectedAnswer == null) return;

    if (_demoPhase) {
      // Démo : feedback visuel seulement — ni score, ni règle d'arrêt, ni
      // avance automatique (le bouton devient « Commencer » / « Réessayer »).
      setState(() => _demoSubmitted = true);
      return;
    }

    final isCorrect = _selectedAnswer == _generatedItems[currentLevel].correctAnswer;
    final timeSeconds = DateTime.now().difference(_itemStartTime!).inSeconds;

    _instr.endItem(
      response: _selectedAnswer?.toString(),
      isCorrect: isCorrect,
      score: isCorrect ? 1 : 0,
    );

    unawaited(SubtestProgressStore.instance.jalon(
      subtest: 'matrix_reasoning',
      prochainItem: currentLevel + 1,
      score: score,
      instr: _instr,
    ));

    setState(() {
      totalTime += timeSeconds;

      if (isCorrect) {
        score++;
        _consecutiveFailures = 0;
      } else {
        _consecutiveFailures++;
      }
    });

    // Test non noté à l'écran : aucun retour « juste/faux », on enchaîne.
    // Discontinuation WAIS-IV : 3 scores 0 consécutifs.
    if (_consecutiveFailures >= 3 ||
        currentLevel >= _generatedItems.length - 1) {
      _showFinalResults();
    } else {
      setState(() {
        currentLevel++;
        _selectedAnswer = null;
        _itemStartTime = DateTime.now();
      if (!_demoPhase && currentLevel < _generatedItems.length) {
        _instr.startItem(index: currentLevel);
      }
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
    final p = SubtestProgressStore.instance.pour('matrix_reasoning');
    if (p == null) return;
    currentLevel = p.itemIndex;
    score = p.score;
    _consecutiveFailures = 0;
    _instr.rehydrate(p.items);
    _startRealTest();
  }

  void _showFinalResults() {
    // L'exercice est terminé : plus rien à reprendre. Laisser le point de
    // reprise en place le ferait redémarrer au milieu la fois suivante.
    unawaited(SubtestProgressStore.instance.clear());

    // Les mesures partent MAINTENANT, sous-test par sous-test.
    unawaited(ResultsSync.instance.flushSubtest(
      _instr.toPayload(rawScore: score, maxScore: _generatedItems.length),
    ));

    // Test non noté à l'écran : aucun récapitulatif de points/temps/réussite,
    // simple confirmation de fin — le score repart vers l'appelant, sans être montré.
    // Aucune option « Recommencer » : un sous-test WAIS-IV ne se repasse pas
    // (effet d'apprentissage sur des items déjà vus → normes invalidées).
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.matFinishedTitle),
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
    final item = _currentItem;

    return KeplerTestScaffold(
      stimulusSurface: true,
      testName: context.l10n.matTestName,
      eyebrow: _demoPhase ? context.l10n.demoBadge : context.l10n.matEyebrow,
      accentColor: AppColors.indexFSIQ,
      // Pendant l'entraînement, la barre compte les 3 items d'exemple et non
      // les 26 items cotés — l'eyebrow « ENTRAÎNEMENT » lui sert de libellé.
      currentItem: _demoPhase ? _demoIndex + 1 : currentLevel + 1,
      totalItems: _demoPhase ? _demoItems.length : _generatedItems.length,
      // Tout tient à l'écran : matrice redimensionnée à la hauteur disponible,
      // bouton Valider sticky en bas (jamais besoin de scroller).
      scrollable: false,
      // Aucun score visible pendant la passation (protocole WAIS-IV) : seule
      // la progression d'items est affichée, jamais les points obtenus.
      bottomBar: KeplerTestButton.primary(
        label: _bottomBarLabel(context, item),
        accentColor: AppColors.indexFSIQ,
        onPressed: _bottomBarAction(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Infos item (difficulté) — version compacte
          _buildLevelHeader(context, item),
          SizedBox(height: 8.h),

          // Consigne
          _buildInstructions(context),
          if (_demoPhase) ...[
            SizedBox(height: 6.h),
            _buildDemoNotice(context),
          ],

          // Matrice — occupe l'espace restant, réduite si nécessaire
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10.h),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: _buildMatrix(item),
              ),
            ),
          ),

          // Options de réponse — une seule ligne adaptée à la largeur
          _buildOptions(context, item),
          SizedBox(height: 4.h),
        ],
      ),
    );
  }

  String _bottomBarLabel(BuildContext context, MatrixItem item) {
    if (_demoPhase && _demoSubmitted) {
      final ok = _selectedAnswer == item.correctAnswer;
      if (!ok) return context.l10n.demoRetry;
      return _isLastDemo ? context.l10n.demoStart : context.l10n.demoContinue;
    }
    return context.l10n.matValidateAnswer;
  }

  VoidCallback? _bottomBarAction() {
    if (_demoPhase && _demoSubmitted) {
      final ok = _selectedAnswer == _demoItems[_demoIndex].correctAnswer;
      if (!ok) return _retryDemo;
      return _isLastDemo ? _startRealTest : _nextDemo;
    }
    return _selectedAnswer == null ? null : _handleSubmit;
  }

  Widget _buildDemoNotice(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.indexFSIQ.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        context.l10n.demoNotice,
        style: TextStyle(
          fontSize: 11.sp,
          fontStyle: FontStyle.italic,
          color: KeplerColors.of(context).textSecondary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // Version compacte : la progression d'items est déjà affichée par le
  // scaffold (KeplerProgress) — on ne garde ici que la difficulté et les
  // métadonnées de l'item, sur une seule ligne.
  Widget _buildLevelHeader(BuildContext context, MatrixItem item) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Text(
            _getDifficultyLabel(context, item.difficulty),
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
            context.l10n.matRulesTheta(
                item.rules.length, item.thetaValue.toStringAsFixed(1)),
            style: TextStyle(
              fontSize: 11.sp,
              color: KeplerColors.of(context).textSecondary,
              fontStyle: FontStyle.italic,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildInstructions(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: KeplerColors.of(context).info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: KeplerColors.of(context).info.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: KeplerColors.of(context).info, size: 18.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              context.l10n.matInstruction,
              style: TextStyle(fontSize: 12.sp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatrix(MatrixItem item) {
    final cellSize = item.gridSize == 2 ? 90.0 : 70.0;

    return Center(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4.r),
          border: Border.all(color: KeplerColors.of(context).textPrimary, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(4, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(item.gridSize, (row) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(item.gridSize, (col) {
                  return MatrixCellWidget(
                    cell: item.matrix[row][col],
                    size: cellSize,
                  );
                }),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildOptions(BuildContext context, MatrixItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.matChooseAnswer,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8.h),
        // Une seule ligne : la taille des options s'adapte à la largeur de
        // l'écran (jamais de retour à la ligne ni de scroll horizontal).
        LayoutBuilder(
          builder: (context, constraints) {
            final n = item.options.length;
            const gap = 8.0;
            final cellSize =
                ((constraints.maxWidth - gap * (n - 1)) / n).clamp(36.0, 70.0);
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < n; i++) ...[
                  if (i > 0) const SizedBox(width: gap),
                  MatrixCellWidget(
                    cell: item.options[i],
                    size: cellSize,
                    isOption: true,
                    isSelected: _selectedAnswer == item.options[i],
                    onTap: (_demoPhase && _demoSubmitted)
                        ? null
                        : () => _handleAnswerSelected(item.options[i]),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  String _getDifficultyLabel(BuildContext context, DifficultyLevel difficulty) {
    final l10n = context.l10n;
    switch (difficulty) {
      case DifficultyLevel.veryEasy:
        return l10n.matDiffEasy;
      case DifficultyLevel.easy:
        return l10n.matDiffMediumEasy;
      case DifficultyLevel.medium:
        return l10n.matDiffMedium;
      case DifficultyLevel.mediumHard:
        return l10n.matDiffMediumHard;
      case DifficultyLevel.hard:
        return l10n.matDiffHard;
    }
  }
}
