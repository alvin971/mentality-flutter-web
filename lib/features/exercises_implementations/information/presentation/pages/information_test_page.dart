import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/l10n/l10n_ext.dart';
import '../../../../../core/l10n/locale_notifier.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/test/kepler_test_button.dart';
import '../../../../../core/widgets/test/kepler_test_scaffold.dart';
import '../../domain/information_generator.dart';

/// Page du test d'Information (Connaissances générales)
/// WAIS-IV : 28 questions
/// QCM à 4 options
/// Scoring dichotomique : 0 ou 1
/// Règle de discontinuation : 3 échecs consécutifs
class InformationTestPage extends StatefulWidget {
  final String? filterLevel;
  const InformationTestPage({super.key, this.filterLevel});

  @override
  State<InformationTestPage> createState() => _InformationTestPageState();
}

class _InformationTestPageState extends State<InformationTestPage> {
  int currentLevel = 0;
  int score = 0;
  int totalTime = 0;
  int _consecutiveFailures = 0;
  int? _selectedAnswer;
  DateTime? _itemStartTime;
  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _submitted = false;

  late List<InformationItem> _generatedItems;
  final List<ItemResult> _results = [];

  /// Phase de DÉMONSTRATION : un item d'exemple fixe, sans chrono ni score,
  /// rejouable jusqu'à réussite — comme la démonstration du protocole réel.
  bool _demoPhase = true;
  late final InformationItem _demoItem;

  /// Seed fixe de l'item de démonstration (tirage reproductible dans
  /// `InformationGenerator` : mêmes options et même bonne réponse à chaque
  /// lancement). On prend le premier item "easy" tiré. Ne pas changer sans
  /// re-vérifier la lisibilité de la question dans toutes les langues.
  static const int _demoSeed = 7;

  @override
  void initState() {
    super.initState();
    final demoPool = InformationGenerator(
            languageCode: localeNotifier.contentTag, seed: _demoSeed)
        .generateComplete28Items();
    _demoItem = demoPool.firstWhere(
        (item) => item.difficulty == DifficultyLevel.easy,
        orElse: () => demoPool.first);
    _generateItems();
    // La démonstration n'est pas chronométrée : le timer ne démarre qu'au
    // passage au premier item réel (_startRealTest).
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _generateItems() {
    // Génération des 28 items UNIQUES en une seule fois
    final generator =
        InformationGenerator(languageCode: localeNotifier.contentTag);
    final all = generator.generateComplete28Items();
    final level = widget.filterLevel;
    if (level != null) {
      final filtered = all.where((item) => item.difficulty.name == level).toList();
      _generatedItems = filtered.isNotEmpty ? filtered : all;
    } else {
      _generatedItems = all;
    }
  }

  /// Item actif : l'item de démo fixe pendant la démo, sinon l'item réel
  /// courant.
  InformationItem get _currentItem =>
      _demoPhase ? _demoItem : _generatedItems[currentLevel];

  void _startRealTest() {
    setState(() {
      _demoPhase = false;
      _submitted = false;
      _selectedAnswer = null;
    });
    _startItem();
  }

  void _retryDemo() {
    setState(() {
      _selectedAnswer = null;
      _submitted = false;
    });
  }

  void _startItem() {
    _itemStartTime = DateTime.now();
    _elapsedSeconds = 0;
    _selectedAnswer = null;
    _submitted = false;

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

  void _selectAnswer(int index) {
    if (_demoPhase && _submitted) return;
    setState(() {
      _selectedAnswer = index;
    });
  }

  void _submitAnswer() {
    if (_selectedAnswer == null) return;

    if (_demoPhase) {
      // Démo : feedback visuel seulement — ni score, ni dialog, ni règle
      // d'arrêt (le bouton devient « Commencer » / « Réessayer »).
      setState(() => _submitted = true);
      return;
    }

    _timer?.cancel();

    final timeSeconds = _itemStartTime != null
        ? DateTime.now().difference(_itemStartTime!).inSeconds
        : 0;

    totalTime += timeSeconds;

    final currentItem = _generatedItems[currentLevel];
    final isCorrect = currentItem.isCorrect(_selectedAnswer!);

    if (isCorrect) {
      score++;
      _consecutiveFailures = 0;
    } else {
      _consecutiveFailures++;
    }

    // Enregistrer le résultat
    _results.add(ItemResult(
      question: currentItem.question,
      selectedAnswer: _selectedAnswer!,
      correctAnswer: currentItem.correctAnswer,
      isCorrect: isCorrect,
      timeSeconds: timeSeconds,
    ));

    // Test non noté à l'écran : on enchaîne sans retour « juste/faux ».
    // Discontinuation WAIS-IV : 3 échecs consécutifs.
    if (_consecutiveFailures >= 3 ||
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
    // Test non noté à l'écran : aucun récapitulatif de points/temps/réussite,
    // simple confirmation de fin — le score repart vers l'appelant, sans être montré.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.infoResultsTitle),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(score);
            },
            child: Text(context.l10n.commonBack),
          ),
        ],
      ),
    );
  }

  /// Nom localisé du domaine de connaissance.
  String _domainName(KnowledgeDomain domain) {
    switch (domain) {
      case KnowledgeDomain.science:
        return context.l10n.infoDomainScience;
      case KnowledgeDomain.historyGeography:
        return context.l10n.infoDomainHistoryGeography;
      case KnowledgeDomain.generalCulture:
        return context.l10n.infoDomainGeneralCulture;
      case KnowledgeDomain.mathLogic:
        return context.l10n.infoDomainMathLogic;
      case KnowledgeDomain.artsLiterature:
        return context.l10n.infoDomainArtsLiterature;
    }
  }

  /// Nom localisé du niveau de difficulté.
  String _difficultyName(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.easy:
        return context.l10n.infoDifficultyEasy;
      case DifficultyLevel.medium:
        return context.l10n.infoDifficultyMedium;
      case DifficultyLevel.hard:
        return context.l10n.infoDifficultyHard;
    }
  }

  String _bottomBarLabel(BuildContext context) {
    if (_demoPhase && _submitted) {
      final ok = _demoItem.isCorrect(_selectedAnswer!);
      return ok ? context.l10n.demoStart : context.l10n.demoRetry;
    }
    return context.l10n.commonValidate;
  }

  VoidCallback? _bottomBarAction() {
    if (_demoPhase && _submitted) {
      final ok = _demoItem.isCorrect(_selectedAnswer!);
      return ok ? _startRealTest : _retryDemo;
    }
    return _selectedAnswer != null ? _submitAnswer : null;
  }

  @override
  Widget build(BuildContext context) {
    final currentItem = _currentItem;

    return KeplerTestScaffold(
      testName: context.l10n.infoTestName,
      eyebrow: _demoPhase ? context.l10n.demoBadge : context.l10n.infoEyebrow,
      accentColor: AppColors.indexVCI,
      // Pas de barre de progression pendant la démo (hors des 28 items) :
      // le badge « ENTRAÎNEMENT » s'affiche alors dans l'AppBar.
      currentItem: _demoPhase ? null : currentLevel + 1,
      totalItems: _demoPhase ? null : _generatedItems.length,
      // Timer + score dans l'AppBar et bouton Valider sticky en bas :
      // question + 4 options + validation visibles sans scroller.
      // Pendant la démo : ni chrono, ni score (l'essai ne compte pas).
      trailing: _demoPhase
          ? null
          : [
              Padding(
                padding: EdgeInsets.only(left: 8.w),
                child: Text(context.l10n.commonSeconds(_elapsedSeconds),
                    style: AppText.monoLabel(color: AppColors.indexVCI)),
              ),
            ],
      bottomBar: KeplerTestButton.primary(
        label: _bottomBarLabel(context),
        accentColor: AppColors.indexVCI,
        onPressed: _bottomBarAction(),
      ),
      child: Column(
crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_demoPhase) ...[
                Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: Text(
                    context.l10n.demoNotice,
                    style: AppText.body().copyWith(
                      fontSize: 12.5,
                      fontStyle: FontStyle.italic,
                      color: AppColors.grey600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (_submitted)
                  Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: Text(
                      _demoItem.isCorrect(_selectedAnswer!)
                          ? context.l10n.demoWellDone
                          : context.l10n.demoTryAgain,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _demoItem.isCorrect(_selectedAnswer!)
                            ? AppColors.success
                            : AppColors.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
              // Domaine et difficulté
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: _getDomainColor(currentItem.domain),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        _domainName(currentItem.domain),
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.surface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor(currentItem.difficulty),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      _difficultyName(currentItem.difficulty),
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12.h),

              // Question
              Container(
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.indexVCI.withValues(alpha: 0.1),
                      AppColors.indexVCI.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: AppColors.indexVCI, width: 2),
                ),
                child: Text(
                  currentItem.question,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              SizedBox(height: 14.h),

              // Options (QCM)
              ...List.generate(4, (index) {
                final isSelected = _selectedAnswer == index;
                // Pendant la démo soumise : bref feedback visuel vert/rouge
                // (bonne réponse / choix incorrect), comme le protocole réel.
                final showDemoCorrect = _demoPhase &&
                    _submitted &&
                    index == currentItem.correctAnswer;
                final showDemoIncorrect =
                    _demoPhase && _submitted && isSelected && !showDemoCorrect;
                final optionColor = showDemoCorrect
                    ? AppColors.success
                    : showDemoIncorrect
                        ? AppColors.error
                        : isSelected
                            ? AppColors.indexVCI
                            : AppColors.grey300;
                return Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: InkWell(
                    onTap: () => _selectAnswer(index),
                    borderRadius: BorderRadius.circular(12.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 12.w, vertical: 10.h),
                      decoration: BoxDecoration(
                        color: (showDemoCorrect || showDemoIncorrect)
                            ? optionColor.withValues(alpha: 0.15)
                            : isSelected
                                ? AppColors.indexVCI.withValues(alpha: 0.15)
                                : AppColors.grey50,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: optionColor,
                          width: isSelected || showDemoCorrect ? 3 : 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32.w,
                            height: 32.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: (showDemoCorrect || showDemoIncorrect)
                                  ? optionColor
                                  : isSelected
                                      ? AppColors.indexVCI
                                      : AppColors.grey300,
                            ),
                            child: Center(
                              child: Text(
                                String.fromCharCode(65 + index), // A, B, C, D
                                style: TextStyle(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.surface
                                      : Theme.of(context).colorScheme.outline,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.sp,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              currentItem.options[index],
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? AppColors.indexVCI
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

        ],
      ),
    );
  }


  Color _getDomainColor(KnowledgeDomain domain) {
    switch (domain) {
      case KnowledgeDomain.science:
        return AppColors.success;
      case KnowledgeDomain.historyGeography:
        return AppColors.info;
      case KnowledgeDomain.generalCulture:
        return AppColors.warning;
      case KnowledgeDomain.mathLogic:
        return AppColors.indexFSIQ;
      case KnowledgeDomain.artsLiterature:
        return AppColors.indexPSI;
    }
  }

  Color _getDifficultyColor(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.easy:
        return AppColors.success;
      case DifficultyLevel.medium:
        return AppColors.warning;
      case DifficultyLevel.hard:
        return AppColors.error;
    }
  }
}

// ========== MODÈLE DE RÉSULTAT ==========

class ItemResult {
  final String question;
  final int selectedAnswer;
  final int correctAnswer;
  final bool isCorrect;
  final int timeSeconds;

  ItemResult({
    required this.question,
    required this.selectedAnswer,
    required this.correctAnswer,
    required this.isCorrect,
    required this.timeSeconds,
  });
}
