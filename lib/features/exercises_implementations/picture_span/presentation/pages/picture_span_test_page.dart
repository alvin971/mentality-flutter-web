import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';
import '../../../../../core/l10n/l10n_ext.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/test/kepler_test_button.dart';
import '../../../../../core/widgets/test/kepler_test_scaffold.dart';
import '../../domain/picture_span_generator.dart';
import '../../../../../core/theme/kepler_colors.dart';
import '../../../../../core/services/results_sync.dart';
import '../../../../../core/services/subtest_instrumentation.dart';
import '../../../../../core/services/subtest_progress_store.dart';

/// Page du test Mémoire des Images (Picture Span)
/// Présentation séquentielle puis rappel ordonné sur grille
class PictureSpanTestPage extends StatefulWidget {
  final String? filterLevel;
  const PictureSpanTestPage({super.key, this.filterLevel});

  @override
  State<PictureSpanTestPage> createState() => _PictureSpanTestPageState();
}

class _PictureSpanTestPageState extends State<PictureSpanTestPage> {
  final PictureSpanGenerator _generator = PictureSpanGenerator();
  late List<PictureSpanItem> _generatedItems;

  /// Rang restauré par une reprise, consommé par `_startTest`. `null` = départ
  /// normal.
  int? _rangRepris;

  int _currentItemIndex = 0;
  int _score = 0;

  /// Mesure item par item (latence, hésitation, reprises).
  /// Aucune frappe individuelle n'est captée — cf. SubtestInstrumentation.
  final SubtestInstrumentation _instr =
      SubtestInstrumentation('picture_span');
  int _consecutiveFailuresAtLevel = 0;
  int _currentLevel = 1;

  // Phase de test
  TestPhase _currentPhase = TestPhase.intro;

  // Présentation séquentielle
  int _currentImageIndex = 0;
  Timer? _presentationTimer;

  // Rappel
  final List<int> _userSelectedImageIds = [];

  @override
  void initState() {
    super.initState();
    _generatedItems = _generator.generateComplete12Items();
      _reprendreSiInterrompu();
  }

  @override
  void dispose() {
    _presentationTimer?.cancel();
    super.dispose();
  }

  PictureSpanItem get _currentItem => _generatedItems[_currentItemIndex];

  void _startTest() {
    setState(() {
      _currentPhase = TestPhase.presentation;
      // Une reprise a restauré le rang : le remettre à zéro ici ferait
      // recommencer l'exercice entier, ce que la pause doit justement éviter.
      _currentItemIndex = _rangRepris ?? 0;
      _rangRepris = null;
      _currentLevel = _currentItem.level;
    });
    _startPresentation();
  }

  void _startPresentation() {
    setState(() {
      _currentImageIndex = 0;
      _userSelectedImageIds.clear();
      _currentPhase = TestPhase.presentation;
    });
    _instr.startItem(index: _currentItemIndex);

    _showNextImage();
  }

  void _showNextImage() {
    if (_currentImageIndex < _currentItem.targetImageIds.length) {
      setState(() {
        _currentImageIndex++;
      });

      // Afficher l'image pendant 3 secondes
      _presentationTimer = Timer(const Duration(seconds: 3), () {
        _showNextImage();
      });
    } else {
      // Fin de la présentation, passer au rappel
      setState(() {
        _currentPhase = TestPhase.recall;
      });
    }
  }

  void _selectImage(int imageId) {
    if (_userSelectedImageIds.contains(imageId)) {
      // Déjà sélectionnée, ignorer
      return;
    }

    setState(() {
      _userSelectedImageIds.add(imageId);
    });

    // Si toutes les images sont sélectionnées, valider automatiquement
    if (_userSelectedImageIds.length == _currentItem.numberOfImages) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _validateAnswer();
      });
    }
  }

  void _removeLastSelection() {
    if (_userSelectedImageIds.isNotEmpty) {
      setState(() {
        _userSelectedImageIds.removeLast();
      });
    }
  }

  void _validateAnswer() {
    final isCorrect = _currentItem.isCorrect(_userSelectedImageIds);

    _instr.endItem(
      response: _userSelectedImageIds.join(','),
      isCorrect: isCorrect,
      score: isCorrect ? 1 : 0,
    );

    unawaited(SubtestProgressStore.instance.jalon(
      subtest: 'picture_span',
      prochainItem: _currentItemIndex + 1,
      score: _score,
      instr: _instr,
    ));

    setState(() {
      if (isCorrect) {
        _score++;
        _consecutiveFailuresAtLevel = 0;
      } else {
        _consecutiveFailuresAtLevel++;
      }
    });

    _nextItem();
  }

  void _nextItem() {
    // Vérifier discontinuation : 0 point aux 2 essais d'un niveau
    if (_consecutiveFailuresAtLevel >= 2) {
      _showFinalResults();
      return;
    }

    // Passer à l'item suivant
    if (_currentItemIndex < _generatedItems.length - 1) {
      setState(() {
        _currentItemIndex++;
        // Réinitialiser le compteur si on change de niveau
        if (_currentItem.level != _currentLevel) {
          _currentLevel = _currentItem.level;
          _consecutiveFailuresAtLevel = 0;
        }
      });
      _startPresentation();
    } else {
      _showFinalResults();
    }
  }

  /// Reprend l'exercice au STADE où une pause l'a laissé.
  ///
  /// Le rang transite par `_rangRepris` plutôt que d'être posé directement :
  /// `_startTest`, déclenché ensuite par l'utilisateur, remettait l'index à
  /// zéro et aurait effacé la reprise.
  void _reprendreSiInterrompu() {
    final p = SubtestProgressStore.instance.pour('picture_span');
    if (p == null) return;
    _rangRepris = p.itemIndex;
    _score = p.score;
    _consecutiveFailuresAtLevel = 0;
    _instr.rehydrate(p.items);
  }

  void _showFinalResults() {
    // Terminé : plus rien à reprendre.
    unawaited(SubtestProgressStore.instance.clear());

    _presentationTimer?.cancel();

    // Les mesures partent MAINTENANT, sous-test par sous-test : une app
    // fermée plus loin dans la batterie ne doit pas emporter ce qui a déjà
    // été mesuré. Tir-et-oublie, fail-soft.
    unawaited(ResultsSync.instance.flushSubtest(
      _instr.toPayload(rawScore: _score),
    ));

    // Test non noté à l'écran : aucun récapitulatif de points/temps/réussite,
    // simple confirmation de fin — le score repart vers l'appelant, sans être montré.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.codingTestDoneTitle),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, _score);
            },
            child: Text(context.l10n.commonBack),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentPhase) {
      case TestPhase.intro:
        return _buildIntroScreen();
      case TestPhase.presentation:
        return _buildPresentationScreen();
      case TestPhase.recall:
        return _buildRecallScreen();
    }
  }

  Widget _buildIntroScreen() {
    return KeplerTestScaffold(
      stimulusSurface: true,
      testName: context.l10n.psTestName,
      eyebrow: context.l10n.dsEyebrow,
      accentColor: AppColors.indexWMI,
      // Bouton de démarrage sticky : visible sans scroller.
      bottomBar: KeplerTestButton.primary(
        label: context.l10n.codingStartTest,
        accentColor: AppColors.indexWMI,
        onPressed: _startTest,
      ),
      child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.photo_library_outlined,
                size: 80.sp,
                color: AppColors.indexWMI,
              ),
              SizedBox(height: 24.h),
              Text(
                context.l10n.psTestName,
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.indexWMI,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                context.l10n.psDescription,
                style: TextStyle(fontSize: 16.sp),
              ),
              SizedBox(height: 24.h),
              _buildInfoCard(
                context.l10n.psPhase1Title,
                context.l10n.psPhase1Desc,
                Icons.visibility_outlined,
              ),
              SizedBox(height: 12.h),
              _buildInfoCard(
                context.l10n.psPhase2Title,
                context.l10n.psPhase2Desc,
                Icons.touch_app_outlined,
              ),
              SizedBox(height: 12.h),
              _buildInfoCard(
                context.l10n.psProgressionTitle,
                context.l10n.psProgressionDesc,
                Icons.trending_up_outlined,
              ),
              SizedBox(height: 24.h),
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: KeplerColors.of(context).info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: KeplerColors.of(context).info.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: KeplerColors.of(context).info, size: 24.sp),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        context.l10n.psTrialsInfo,
                        style: TextStyle(color: KeplerColors.of(context).info, fontSize: 14.sp),
                      ),
                    ),
                  ],
                ),
              ),
            ],
      ),
    );
  }

  Widget _buildPresentationScreen() {
    final currentImageId = _currentImageIndex > 0 && _currentImageIndex <= _currentItem.targetImageIds.length
        ? _currentItem.targetImageIds[_currentImageIndex - 1]
        : null;
    final currentImage = currentImageId != null ? _generator.getImageById(currentImageId) : null;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(context.l10n.psMemorizationTab),
        actions: [
          Center(
            child: Padding(
              padding: EdgeInsets.only(right: 16.w),
              child: Text(
                context.l10n.psLevelTrial(_currentItem.level, _currentItem.trial),
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                context.l10n.psMemorizeImages,
                style: TextStyle(fontSize: 20.sp, color: KeplerColors.of(context).textSecondary),
              ),
              SizedBox(height: 16.h),
              Text(
                context.l10n.psImageProgress(_currentImageIndex, _currentItem.numberOfImages),
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.indexWMI,
                ),
              ),
              SizedBox(height: 48.h),
              if (currentImage != null)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.8, end: 1.0),
                  duration: const Duration(milliseconds: 300),
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 200.w,
                        height: 200.w,
                        decoration: BoxDecoration(
                          color: AppColors.indexWMI.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(color: AppColors.indexWMI, width: 4),
                        ),
                        // WISC-V : stimulus visuel seul, sans texte.
                        child: Padding(
                          padding: EdgeInsets.all(10.w),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14.r),
                            child: Image.asset(
                              currentImage.imagePath,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                currentImage.icon,
                                size: 100.sp,
                                color: AppColors.indexWMI,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              if (currentImage == null)
                Container(
                  width: 200.w,
                  height: 200.w,
                  decoration: BoxDecoration(
                    color: KeplerColors.of(context).border,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.indexWMI,
                      strokeWidth: 6.w,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecallScreen() {
    final gridImages = _currentItem.recallGridIds
        .map((id) => _generator.getImageById(id))
        .where((img) => img != null)
        .cast<ImageStimulus>()
        .toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(context.l10n.psRecallTab),
        actions: [
          Center(
            child: Padding(
              padding: EdgeInsets.only(right: 16.w),
              child: Text(
                context.l10n.psLevelTrial(_currentItem.level, _currentItem.trial),
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16.w),
              color: AppColors.indexWMI.withValues(alpha: 0.1),
              child: Column(
                children: [
                  Text(
                    context.l10n.psSelectInOrder(_currentItem.numberOfImages),
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.indexWMI,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12.h),
                  // Affichage des sélections
                  SizedBox(
                    height: 60.h,
                    child: _userSelectedImageIds.isEmpty
                        ? Center(
                            child: Text(
                              context.l10n.psNoSelection,
                              style: TextStyle(fontSize: 14.sp, color: KeplerColors.of(context).textSecondary),
                            ),
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _userSelectedImageIds.length,
                            itemBuilder: (context, index) {
                              final img = _generator.getImageById(_userSelectedImageIds[index]);
                              return Container(
                                margin: EdgeInsets.only(right: 8.w),
                                width: 60.w,
                                decoration: BoxDecoration(
                                  color: AppColors.indexWMI.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(color: AppColors.indexWMI, width: 2),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.indexWMI,
                                      ),
                                    ),
                                    img == null
                                        ? Icon(Icons.help, size: 24.sp, color: AppColors.indexWMI)
                                        : ClipRRect(
                                            borderRadius: BorderRadius.circular(6.r),
                                            child: Image.asset(
                                              img.imagePath,
                                              width: 34.w,
                                              height: 34.w,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  Icon(img.icon, size: 24.sp, color: AppColors.indexWMI),
                                            ),
                                          ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            // Grille d'images — toutes les images tiennent à l'écran sans
            // scroll interne (ratio des tuiles calculé selon la hauteur).
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const crossCount = 3;
                  final rowCount =
                      (gridImages.length / crossCount).ceil().clamp(1, 99);
                  final tileW = (constraints.maxWidth -
                          32.w -
                          12.w * (crossCount - 1)) /
                      crossCount;
                  final tileH = (constraints.maxHeight -
                          32.w -
                          12.h * (rowCount - 1)) /
                      rowCount;
                  final aspectRatio =
                      (tileW / tileH).clamp(0.5, 2.5).toDouble();
                  return GridView.builder(
                padding: EdgeInsets.all(16.w),
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossCount,
                  crossAxisSpacing: 12.w,
                  mainAxisSpacing: 12.h,
                  childAspectRatio: aspectRatio,
                ),
                itemCount: gridImages.length,
                itemBuilder: (context, index) {
                  final image = gridImages[index];
                  final isSelected = _userSelectedImageIds.contains(image.id);

                  return InkWell(
                    onTap: () => _selectImage(image.id),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.indexWMI.withValues(alpha: 0.3)
                            : KeplerColors.of(context).surface,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: isSelected ? AppColors.indexWMI : KeplerColors.of(context).border,
                          width: isSelected ? 3 : 2,
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(6.w),
                        // FittedBox : le contenu se réduit au lieu de
                        // déborder quand les tuiles sont petites.
                        // WISC-V : tuile image seule, sans texte.
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.r),
                          child: Image.asset(
                            image.imagePath,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Icon(
                              image.icon,
                              size: 48.sp,
                              color: isSelected ? AppColors.indexWMI : KeplerColors.of(context).textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
                },
              ),
            ),
            // Bouton effacer
            Padding(
              padding: EdgeInsets.all(16.w),
              child: SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton.icon(
                  onPressed: _userSelectedImageIds.isNotEmpty ? _removeLastSelection : null,
                  icon: Icon(Icons.backspace, size: 20.sp),
                  label: Text(
                    context.l10n.psClearLast,
                    style: TextStyle(fontSize: 16.sp),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    disabledBackgroundColor: KeplerColors.of(context).surface,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String subtitle, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.indexWMI.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.indexWMI.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 28.sp, color: AppColors.indexWMI),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.indexWMI,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 13.sp, color: KeplerColors.of(context).textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum TestPhase {
  intro,
  presentation,
  recall,
}
