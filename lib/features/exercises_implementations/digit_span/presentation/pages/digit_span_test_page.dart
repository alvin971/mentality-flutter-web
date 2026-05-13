import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';
import '../../../../../core/theme/app_colors.dart';
import '../../domain/digit_span_generator.dart';

/// Page du test Mémoire des Chiffres (Digit Span)
/// 3 parties : Forward, Backward, Sequencing
/// Présentation auditive TTS à 1 chiffre/seconde
class DigitSpanTestPage extends StatefulWidget {
  final String? filterLevel;
  const DigitSpanTestPage({super.key, this.filterLevel});

  @override
  State<DigitSpanTestPage> createState() => _DigitSpanTestPageState();
}

class _DigitSpanTestPageState extends State<DigitSpanTestPage> {
  final DigitSpanGenerator _generator = DigitSpanGenerator();

  // État général
  TestPhase _currentPhase = TestPhase.intro;
  SpanType _currentSpanType = SpanType.forward;

  // Items par partie
  late List<DigitSpanItem> _forwardItems;
  late List<DigitSpanItem> _backwardItems;
  late List<DigitSpanItem> _sequencingItems;

  // Progression
  int _currentItemIndex = 0;
  final List<int> _userAnswer = [];

  // Scoring par partie
  int _forwardScore = 0;
  int _backwardScore = 0;
  int _sequencingScore = 0;

  // Suivi des échecs consécutifs PAR LONGUEUR
  int _currentLength = 0;
  int _failuresAtCurrentLength = 0;

  // Présentation auditive
  bool _isPlayingSequence = false;
  int _currentDigitIndex = 0;
  Timer? _presentationTimer;

  @override
  void initState() {
    super.initState();
    _forwardItems = _generator.getForwardItems();
    _backwardItems = _generator.getBackwardItems();
    _sequencingItems = _generator.getSequencingItems();
  }

  @override
  void dispose() {
    _presentationTimer?.cancel();
    super.dispose();
  }

  List<DigitSpanItem> get _currentItems {
    switch (_currentSpanType) {
      case SpanType.forward:
        return _forwardItems;
      case SpanType.backward:
        return _backwardItems;
      case SpanType.sequencing:
        return _sequencingItems;
    }
  }

  DigitSpanItem get _currentItem => _currentItems[_currentItemIndex];

  void _startTest() {
    setState(() {
      _currentPhase = TestPhase.partIntro;
      _currentSpanType = SpanType.forward;
      _currentItemIndex = 0;
    });
  }

  void _startPart() {
    setState(() {
      _currentPhase = TestPhase.sequencePresentation;
      _currentItemIndex = 0;
      _currentLength = _currentItem.length;
      _failuresAtCurrentLength = 0;
    });
    _playSequence();
  }

  /// Joue la séquence de chiffres avec TTS simulé (1 chiffre/seconde)
  void _playSequence() {
    _presentationTimer?.cancel();

    setState(() {
      _isPlayingSequence = true;
      _currentDigitIndex = 0;
      _userAnswer.clear();
    });

    _presentationTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      if (_currentDigitIndex >= _currentItem.sequence.length) {
        timer.cancel();
        setState(() {
          _isPlayingSequence = false;
          _currentPhase = TestPhase.userInput;
        });
      } else {
        setState(() {
          _currentDigitIndex++;
        });
      }
    });
  }

  void _addDigit(int digit) {
    if (_userAnswer.length < _currentItem.length) {
      setState(() {
        _userAnswer.add(digit);
      });
    }
  }

  void _removeLastDigit() {
    if (_userAnswer.isNotEmpty) {
      setState(() {
        _userAnswer.removeLast();
      });
    }
  }

  void _submitAnswer() {
    final isCorrect = _currentItem.isCorrect(_userAnswer);
    final trial = _currentItem.trial;

    int pointsEarned = 0;

    if (isCorrect) {
      // Succès : 2 points au 1er essai, 1 point au 2e essai
      pointsEarned = trial == 1 ? 2 : 1;
      _failuresAtCurrentLength = 0; // Réinitialiser les échecs
    } else {
      // Échec
      pointsEarned = 0;
      _failuresAtCurrentLength++;
    }

    // Ajouter les points à la partie en cours
    switch (_currentSpanType) {
      case SpanType.forward:
        _forwardScore += pointsEarned;
        break;
      case SpanType.backward:
        _backwardScore += pointsEarned;
        break;
      case SpanType.sequencing:
        _sequencingScore += pointsEarned;
        break;
    }

    _showFeedback(isCorrect, pointsEarned);
  }

  void _showFeedback(bool isCorrect, int points) {
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
            Text('Points gagnés : $points'),
            SizedBox(height: 8.h),
            Text('Réponse correcte : ${_currentItem.getCorrectAnswer().join(' - ')}'),
            Text('Votre réponse : ${_userAnswer.join(' - ')}'),
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
    // Vérifier discontinuation : 0 point aux 2 essais d'une même longueur
    if (_failuresAtCurrentLength >= 2) {
      _endCurrentPart();
      return;
    }

    // Passer à l'item suivant
    if (_currentItemIndex < _currentItems.length - 1) {
      setState(() {
        _currentItemIndex++;
        // Si on change de longueur, réinitialiser le compteur d'échecs
        if (_currentItem.length != _currentLength) {
          _currentLength = _currentItem.length;
          _failuresAtCurrentLength = 0;
        }
        _currentPhase = TestPhase.sequencePresentation;
      });
      _playSequence();
    } else {
      _endCurrentPart();
    }
  }

  void _endCurrentPart() {
    // Passer à la partie suivante ou terminer le test
    if (_currentSpanType == SpanType.forward) {
      setState(() {
        _currentSpanType = SpanType.backward;
        _currentItemIndex = 0;
        _currentPhase = TestPhase.partIntro;
      });
    } else if (_currentSpanType == SpanType.backward) {
      setState(() {
        _currentSpanType = SpanType.sequencing;
        _currentItemIndex = 0;
        _currentPhase = TestPhase.partIntro;
      });
    } else {
      _showFinalResults();
    }
  }

  void _showFinalResults() {
    final totalScore = _forwardScore + _backwardScore + _sequencingScore;

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
              'Résultats par partie :',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12.h),
            Text('Empan Direct : $_forwardScore points'),
            Text('Empan Inverse : $_backwardScore points'),
            Text('Séquençage : $_sequencingScore points'),
            SizedBox(height: 16.h),
            Text(
              'Score Total : $totalScore points',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.indexWMI,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              final totalScore = _forwardScore + _backwardScore + _sequencingScore;
              Navigator.pop(context);
              Navigator.pop(context, totalScore);
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
      case TestPhase.partIntro:
        return _buildPartIntroScreen();
      case TestPhase.sequencePresentation:
        return _buildSequencePresentationScreen();
      case TestPhase.userInput:
        return _buildUserInputScreen();
    }
  }

  Widget _buildIntroScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mémoire des Chiffres'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.memory_outlined,
                size: 80.sp,
                color: AppColors.indexWMI,
              ),
              SizedBox(height: 24.h),
              Text(
                'Mémoire des Chiffres',
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.indexWMI,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Ce test mesure votre mémoire de travail à travers 3 parties distinctes :',
                style: TextStyle(fontSize: 16.sp),
              ),
              SizedBox(height: 24.h),
              _buildInfoCard(
                'Partie 1 : Empan Direct',
                'Répétez les chiffres dans le même ordre',
                Icons.arrow_forward,
              ),
              SizedBox(height: 12.h),
              _buildInfoCard(
                'Partie 2 : Empan Inverse',
                'Répétez les chiffres en ordre inverse',
                Icons.swap_horiz,
              ),
              SizedBox(height: 12.h),
              _buildInfoCard(
                'Partie 3 : Séquençage',
                'Répétez les chiffres en ordre croissant',
                Icons.sort,
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
                        'Les chiffres seront présentés à raison de 1 chiffre par seconde.',
                        style: TextStyle(color: AppColors.info, fontSize: 14.sp),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32.h),
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

  Widget _buildPartIntroScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_currentItem.typeDescription),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getPartIcon(),
                size: 80.sp,
                color: AppColors.indexWMI,
              ),
              SizedBox(height: 24.h),
              Text(
                _currentItem.typeDescription,
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.indexWMI,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                _currentItem.instruction,
                style: TextStyle(fontSize: 18.sp),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 48.h),
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: _startPart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.indexWMI,
                  ),
                  child: Text(
                    'Commencer',
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

  Widget _buildSequencePresentationScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_currentItem.typeDescription),
        actions: [
          Center(
            child: Padding(
              padding: EdgeInsets.only(right: 16.w),
              child: Text(
                'Longueur ${_currentItem.length} - Essai ${_currentItem.trial}',
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
                'Écoutez attentivement',
                style: TextStyle(fontSize: 20.sp, color: AppColors.grey600),
              ),
              SizedBox(height: 48.h),
              if (_currentDigitIndex > 0 && _currentDigitIndex <= _currentItem.sequence.length)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.8, end: 1.2),
                  duration: const Duration(milliseconds: 300),
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 150.w,
                        height: 150.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.indexWMI.withValues(alpha: 0.2),
                          border: Border.all(color: AppColors.indexWMI, width: 4),
                        ),
                        child: Center(
                          child: Text(
                            _currentItem.sequence[_currentDigitIndex - 1].toString(),
                            style: TextStyle(
                              fontSize: 64.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.indexWMI,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              if (_currentDigitIndex == 0)
                Container(
                  width: 150.w,
                  height: 150.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.grey200,
                  ),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.indexWMI,
                      strokeWidth: 6.w,
                    ),
                  ),
                ),
              SizedBox(height: 24.h),
              Text(
                '${_currentDigitIndex} / ${_currentItem.sequence.length}',
                style: TextStyle(
                  fontSize: 18.sp,
                  color: AppColors.grey600,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInputScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_currentItem.typeDescription),
        actions: [
          Center(
            child: Padding(
              padding: EdgeInsets.only(right: 16.w),
              child: Text(
                'Longueur ${_currentItem.length} - Essai ${_currentItem.trial}',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            children: [
              Text(
                _currentItem.instruction,
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32.h),
              // Affichage de la réponse de l'utilisateur
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: AppColors.indexWMI.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.indexWMI, width: 2),
                ),
                child: Wrap(
                  spacing: 12.w,
                  children: _userAnswer.isEmpty
                      ? [
                          Text(
                            'Saisissez votre réponse...',
                            style: TextStyle(fontSize: 18.sp, color: AppColors.grey500),
                          )
                        ]
                      : _userAnswer.map((digit) {
                          return Container(
                            width: 50.w,
                            height: 50.w,
                            decoration: BoxDecoration(
                              color: AppColors.indexWMI,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Center(
                              child: Text(
                                digit.toString(),
                                style: TextStyle(
                                  fontSize: 24.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                ),
              ),
              SizedBox(height: 32.h),
              // Clavier numérique
              Expanded(
                child: GridView.count(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12.h,
                  crossAxisSpacing: 12.w,
                  children: [
                    for (int i = 1; i <= 9; i++)
                      _buildNumberButton(i),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              // Boutons d'action
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50.h,
                      child: ElevatedButton(
                        onPressed: _userAnswer.isNotEmpty ? _removeLastDigit : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          disabledBackgroundColor: AppColors.grey300,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.backspace, size: 20.sp),
                            SizedBox(width: 8.w),
                            Text('Effacer', style: TextStyle(fontSize: 16.sp)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 50.h,
                      child: ElevatedButton(
                        onPressed: _userAnswer.length == _currentItem.length
                            ? _submitAnswer
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.indexWMI,
                          disabledBackgroundColor: AppColors.grey300,
                        ),
                        child: Text(
                          'Valider (${_userAnswer.length}/${_currentItem.length})',
                          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberButton(int number) {
    final isDisabled = _userAnswer.length >= _currentItem.length;
    return ElevatedButton(
      onPressed: isDisabled ? null : () => _addDigit(number),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.indexWMI,
        disabledBackgroundColor: AppColors.grey300,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
      child: Text(
        number.toString(),
        style: TextStyle(
          fontSize: 32.sp,
          fontWeight: FontWeight.bold,
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
          Icon(icon, size: 32.sp, color: AppColors.indexWMI),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.indexWMI,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 14.sp, color: AppColors.grey700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getPartIcon() {
    switch (_currentSpanType) {
      case SpanType.forward:
        return Icons.arrow_forward;
      case SpanType.backward:
        return Icons.swap_horiz;
      case SpanType.sequencing:
        return Icons.sort;
    }
  }
}

enum TestPhase {
  intro,
  partIntro,
  sequencePresentation,
  userInput,
}
