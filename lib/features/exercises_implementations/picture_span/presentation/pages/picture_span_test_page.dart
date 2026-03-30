import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';
import '../../../../../core/theme/app_colors.dart';
import '../../domain/picture_span_generator.dart';

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
  late List<ImageStimulus> _imageBank;

  int _currentItemIndex = 0;
  int _score = 0;
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
    _imageBank = _generator.getImageBank();
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
      _currentItemIndex = 0;
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

    setState(() {
      if (isCorrect) {
        _score++;
        _consecutiveFailuresAtLevel = 0;
      } else {
        _consecutiveFailuresAtLevel++;
      }
    });

    _showFeedback(isCorrect);
  }

  void _showFeedback(bool isCorrect) {
    final targetImages = _currentItem.targetImageIds
        .map((id) => _generator.getImageById(id)?.name ?? '')
        .join(', ');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isCorrect ? Icons.check_circle : Icons.cancel,
              color: isCorrect ? AppColors.success : AppColors.error,
              size: 32.sp,
            ),
            SizedBox(width: 12.w),
            Text(isCorrect ? 'Correct !' : 'Incorrect'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ordre correct : $targetImages'),
            if (!isCorrect) ...[
              SizedBox(height: 8.h),
              Text(
                'Votre ordre : ${_userSelectedImageIds.map((id) => _generator.getImageById(id)?.name ?? '').join(', ')}',
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _nextItem();
            },
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
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

  void _showFinalResults() {
    _presentationTimer?.cancel();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Test terminé !'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Essais complétés : ${_currentItemIndex + 1}/12',
              style: TextStyle(fontSize: 16.sp),
            ),
            SizedBox(height: 12.h),
            Text(
              'Score Total : $_score points',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.indexWMI,
              ),
            ),
            SizedBox(height: 12.h),
            Text('Niveau maximal atteint : Niveau $_currentLevel'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, _score);
            },
            child: const Text('Retour'),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mémoire des Images'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
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
                'Mémoire des Images',
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.indexWMI,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Ce test mesure votre mémoire de travail visuelle et votre attention sélective.',
                style: TextStyle(fontSize: 16.sp),
              ),
              SizedBox(height: 24.h),
              _buildInfoCard(
                'Phase 1 : Mémorisation',
                'Des images seront présentées une par une (3 secondes chacune)',
                Icons.visibility_outlined,
              ),
              SizedBox(height: 12.h),
              _buildInfoCard(
                'Phase 2 : Rappel',
                'Sélectionnez les images dans l\'ordre exact de présentation',
                Icons.touch_app_outlined,
              ),
              SizedBox(height: 12.h),
              _buildInfoCard(
                'Progression',
                'La difficulté augmente : 1 à 6 images à mémoriser',
                Icons.trending_up_outlined,
              ),
              SizedBox(height: 24.h),
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.info, size: 24.sp),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        '12 essais au total. Le test s\'arrête après 2 échecs au même niveau.',
                        style: TextStyle(color: AppColors.info, fontSize: 14.sp),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: _startTest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.indexWMI,
                  ),
                  child: Text(
                    'Commencer le test',
                    style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresentationScreen() {
    final currentImageId = _currentImageIndex > 0 && _currentImageIndex <= _currentItem.targetImageIds.length
        ? _currentItem.targetImageIds[_currentImageIndex - 1]
        : null;
    final currentImage = currentImageId != null ? _generator.getImageById(currentImageId) : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mémorisation'),
        actions: [
          Center(
            child: Padding(
              padding: EdgeInsets.only(right: 16.w),
              child: Text(
                'Niveau ${_currentItem.level} - Essai ${_currentItem.trial}',
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
                'Mémorisez les images',
                style: TextStyle(fontSize: 20.sp, color: AppColors.grey600),
              ),
              SizedBox(height: 16.h),
              Text(
                'Image $_currentImageIndex / ${_currentItem.numberOfImages}',
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
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              currentImage.icon,
                              size: 100.sp,
                              color: AppColors.indexWMI,
                            ),
                            SizedBox(height: 12.h),
                            Text(
                              currentImage.name,
                              style: TextStyle(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.indexWMI,
                              ),
                            ),
                          ],
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
                    color: AppColors.grey200,
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
      appBar: AppBar(
        title: const Text('Rappel'),
        actions: [
          Center(
            child: Padding(
              padding: EdgeInsets.only(right: 16.w),
              child: Text(
                'Niveau ${_currentItem.level} - Essai ${_currentItem.trial}',
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
                    'Sélectionnez les ${_currentItem.numberOfImages} images dans l\'ordre',
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
                              'Aucune sélection',
                              style: TextStyle(fontSize: 14.sp, color: AppColors.grey500),
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
                                    Icon(img?.icon ?? Icons.help, size: 24.sp, color: AppColors.indexWMI),
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
            // Grille d'images
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.all(16.w),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12.w,
                  mainAxisSpacing: 12.h,
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
                            : AppColors.grey100,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: isSelected ? AppColors.indexWMI : AppColors.grey300,
                          width: isSelected ? 3 : 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            image.icon,
                            size: 48.sp,
                            color: isSelected ? AppColors.indexWMI : AppColors.grey600,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            image.name,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? AppColors.indexWMI : AppColors.grey700,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
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
                    'Effacer la dernière sélection',
                    style: TextStyle(fontSize: 16.sp),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    disabledBackgroundColor: AppColors.grey300,
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
                  style: TextStyle(fontSize: 13.sp, color: AppColors.grey700),
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
