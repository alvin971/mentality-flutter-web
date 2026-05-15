import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/test/kepler_test_button.dart';
import '../../../../../core/widgets/test/kepler_test_scaffold.dart';
import '../../domain/puzzle_generator.dart';
import '../widgets/puzzle_piece_widget.dart';
import '../widgets/puzzle_slot_indicator.dart';
import '../widgets/puzzle_target_widget.dart';

/// Page WAIS-IV Visual Puzzles — version polygone.
class VisualPuzzlesTestPage extends StatefulWidget {
  const VisualPuzzlesTestPage({super.key, this.filterLevel});

  final String? filterLevel;

  @override
  State<VisualPuzzlesTestPage> createState() => _VisualPuzzlesTestPageState();
}

class _VisualPuzzlesTestPageState extends State<VisualPuzzlesTestPage> {
  late List<PuzzleItem> _items;
  int _currentItemIndex = 0;
  int _score = 0;
  int _consecutiveFailures = 0;

  final Set<String> _selectedIds = {};
  int _remainingSeconds = 0;
  Timer? _timer;
  DateTime? _itemStartTime;
  bool _submitted = false;

  static const String _label = 'ABCDEF';

  @override
  void initState() {
    super.initState();
    _generateItems();
    _startItem();
  }

  void _generateItems() {
    final generator = PuzzleGenerator();
    final all = generator.generateComplete26Items();
    final filter = widget.filterLevel;
    if (filter != null) {
      final f = all
          .where((it) =>
              it.level.name == filter ||
              it.level.label.toLowerCase() == filter.toLowerCase())
          .toList();
      _items = f.isNotEmpty ? f : all;
    } else {
      _items = all;
    }
  }

  PuzzleItem get _currentItem => _items[_currentItemIndex];

  void _startItem() {
    _selectedIds.clear();
    _submitted = false;
    _remainingSeconds = _currentItem.timeLimitSeconds;
    _itemStartTime = DateTime.now();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _remainingSeconds--);
      if (_remainingSeconds <= 0) {
        timer.cancel();
        HapticFeedback.heavyImpact();
        _submit(autoSubmit: true);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _togglePiece(String pieceId) {
    if (_submitted) return;
    setState(() {
      if (_selectedIds.contains(pieceId)) {
        _selectedIds.remove(pieceId);
      } else {
        if (_selectedIds.length >= 3) {
          final oldest = _selectedIds.first;
          _selectedIds.remove(oldest);
        }
        _selectedIds.add(pieceId);
      }
    });
    HapticFeedback.lightImpact();
  }

  bool _setEqualsLocal(Set<String> a, Set<String> b) {
    if (a.length != b.length) return false;
    for (final e in a) {
      if (!b.contains(e)) return false;
    }
    return true;
  }

  void _submit({bool autoSubmit = false}) {
    if (_submitted) return;
    _timer?.cancel();
    _submitted = true;
    HapticFeedback.mediumImpact();

    final time = _itemStartTime != null
        ? DateTime.now().difference(_itemStartTime!).inSeconds
        : _currentItem.timeLimitSeconds;

    final isCorrect = _selectedIds.length == 3 &&
        _setEqualsLocal(_selectedIds, _currentItem.correctIds);

    setState(() {
      if (isCorrect) {
        _score++;
        _consecutiveFailures = 0;
      } else {
        _consecutiveFailures++;
      }
    });

    _showFeedbackDialog(isCorrect, time, autoSubmit);
  }

  void _showFeedbackDialog(bool isCorrect, int timeSeconds, bool autoSubmit) {
    final accent = AppColors.indexVSI;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          backgroundColor: cs.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          title: Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                color: isCorrect ? AppColors.success : AppColors.error,
                size: 28.sp,
              ),
              SizedBox(width: 10.w),
              Text(
                isCorrect
                    ? 'Correct !'
                    : (autoSubmit ? 'Temps écoulé' : 'Incorrect'),
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: isCorrect ? AppColors.success : AppColors.error,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isCorrect
                    ? 'Bonne combinaison de pièces !'
                    : 'Les 3 pièces correctes étaient :',
                style: TextStyle(fontSize: 14.sp, color: cs.onSurface),
              ),
              if (!isCorrect) ...[
                SizedBox(height: 10.h),
                _CorrectAnswerHint(item: _currentItem, accent: accent),
              ],
              SizedBox(height: 12.h),
              Text('Temps : ${timeSeconds}s',
                  style: TextStyle(fontSize: 13.sp, color: cs.onSurfaceVariant)),
              Text('Score : $_score / ${_currentItemIndex + 1}',
                  style: TextStyle(fontSize: 13.sp, color: cs.onSurfaceVariant)),
              if (_consecutiveFailures >= 3) ...[
                SizedBox(height: 8.h),
                Text(
                  '3 échecs consécutifs — test terminé',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _next();
              },
              child: Text(
                _consecutiveFailures >= 3 ||
                        _currentItemIndex >= _items.length - 1
                    ? 'Voir les résultats'
                    : 'Continuer',
              ),
            ),
          ],
        );
      },
    );
  }

  void _next() {
    if (_consecutiveFailures >= 3 ||
        _currentItemIndex >= _items.length - 1) {
      Navigator.of(context).pop(_score);
      return;
    }
    setState(() {
      _currentItemIndex++;
    });
    _startItem();
  }

  @override
  Widget build(BuildContext context) {
    final item = _currentItem;
    final accent = AppColors.indexVSI;
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final crossAxisCount = isMobile ? 2 : 3;

    return KeplerTestScaffold(
      testName: 'Puzzles Visuels',
      eyebrow: 'VISUO-SPATIAL · VSI',
      accentColor: accent,
      currentItem: _currentItemIndex + 1,
      totalItems: _items.length,
      trailing: [_TimerBadge(seconds: _remainingSeconds, accent: accent)],
      bottomBar: KeplerTestButton.primary(
        label: _selectedIds.length == 3
            ? 'Valider'
            : '${_selectedIds.length} / 3 sélectionnées',
        accentColor: accent,
        onPressed: (_selectedIds.length == 3 && !_submitted) ? () => _submit() : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 8.h),
          PuzzleTargetWidget(item: item),
          SizedBox(height: 20.h),
          PuzzleSlotIndicator(filled: _selectedIds.length, total: 3),
          SizedBox(height: 16.h),
          Text(
            'Choisissez les 3 pièces qui reconstituent la cible.',
            style: AppText.body(),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          GridView.count(
            crossAxisCount: crossAxisCount,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12.h,
            crossAxisSpacing: 12.w,
            childAspectRatio: 0.95,
            children: List.generate(item.options.length, (i) {
              final piece = item.options[i];
              final isSelected = _selectedIds.contains(piece.id);
              final showCorrect =
                  _submitted && _currentItem.correctIds.contains(piece.id);
              final showIncorrect =
                  _submitted && isSelected && !showCorrect;
              return PuzzlePieceWidget(
                piece: piece,
                label: _label[i],
                isSelected: isSelected,
                showCorrect: showCorrect,
                showIncorrect: showIncorrect,
                onTap: () => _togglePiece(piece.id),
              );
            }),
          ),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }
}

class _TimerBadge extends StatelessWidget {
  const _TimerBadge({required this.seconds, required this.accent});
  final int seconds;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final danger = seconds <= 5;
    final color = danger ? AppColors.error : accent;
    final mm = (seconds ~/ 60).toString().padLeft(2, '0');
    final ss = (seconds % 60).toString().padLeft(2, '0');
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, color: color, size: 14.sp),
          SizedBox(width: 4.w),
          Text('$mm:$ss', style: AppText.mono(color: color, size: 12.sp)),
        ],
      ),
    );
  }
}

class _CorrectAnswerHint extends StatelessWidget {
  const _CorrectAnswerHint({required this.item, required this.accent});
  final PuzzleItem item;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final correctPieces = item.options
        .where((p) => item.correctIds.contains(p.id))
        .toList();
    return SizedBox(
      height: 80.h,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: correctPieces.map((p) {
          final i = item.options.indexOf(p);
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: SizedBox(
              width: 70.w,
              child: PuzzlePieceWidget(
                piece: p,
                label: 'ABCDEF'[i],
                isSelected: true,
                showCorrect: true,
                onTap: null,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
