import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/test/kepler_test_button.dart';
import '../../../../../core/widgets/test/kepler_test_scaffold.dart';
import '../../domain/puzzle_generator.dart';
import '../widgets/puzzle_piece_widget.dart';
import '../widgets/puzzle_slot_indicator.dart';
import '../widgets/puzzle_target_widget.dart';

/// Page du test "Puzzles Visuels" (inspiré du subtest VP, indice VSI).
///
/// Déroulement fidèle au protocole :
/// - 26 items à difficulté croissante (générés aléatoirement → banque
///   virtuellement illimitée) ;
/// - pour chaque item : 1 figure cible pleine + 6 pièces numérotées,
///   sélectionner exactement les 3 qui la reconstituent (rotations mentales
///   permises, retournements interdits) ;
/// - temps limite : 20 s (items 1-7) puis 30 s (items 8-26), auto-validation
///   à 0 ;
/// - arrêt après 3 échecs consécutifs (règle de discontinuation) ;
/// - score dichotomique 0/1 par item, pas de feedback détaillé pendant le
///   test (bref indicateur visuel puis item suivant).
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
  Timer? _advanceTimer;
  bool _submitted = false;

  static const String _labels = '123456';

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
    _advanceTimer?.cancel();
    super.dispose();
  }

  void _togglePiece(String pieceId) {
    if (_submitted) return;
    setState(() {
      if (_selectedIds.contains(pieceId)) {
        _selectedIds.remove(pieceId);
      } else {
        if (_selectedIds.length >= 3) {
          // Déjà 3 : on remplace la plus ancienne sélection.
          _selectedIds.remove(_selectedIds.first);
        }
        _selectedIds.add(pieceId);
      }
    });
    HapticFeedback.lightImpact();
  }

  void _submit({bool autoSubmit = false}) {
    if (_submitted) return;
    _timer?.cancel();
    HapticFeedback.mediumImpact();

    final isCorrect = _selectedIds.length == 3 &&
        setEquals(_selectedIds, _currentItem.correctIds);

    setState(() {
      _submitted = true;
      if (isCorrect) {
        _score++;
        _consecutiveFailures = 0;
      } else {
        _consecutiveFailures++;
      }
    });

    // Bref retour visuel (bordures vert/rouge) puis item suivant — pas de
    // dialog révélant la réponse, comme dans le protocole réel.
    _advanceTimer = Timer(const Duration(milliseconds: 1100), () {
      if (!mounted) return;
      _next();
    });
  }

  void _next() {
    if (_consecutiveFailures >= 3 || _currentItemIndex >= _items.length - 1) {
      _finish();
      return;
    }
    setState(() {
      _currentItemIndex++;
    });
    _startItem();
  }

  void _finish() {
    Navigator.of(context).pop(_score);
  }

  @override
  Widget build(BuildContext context) {
    final item = _currentItem;
    final accent = AppColors.indexVSI;
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    return KeplerTestScaffold(
      testName: 'Puzzles Visuels',
      eyebrow: 'VISUO-SPATIAL · VSI',
      accentColor: accent,
      currentItem: _currentItemIndex + 1,
      totalItems: _items.length,
      // Aucun défilement : cible et pièces se redimensionnent pour tenir
      // dans la hauteur de n'importe quel écran (test chronométré).
      scrollable: false,
      trailing: [_TimerBadge(seconds: _remainingSeconds, accent: accent)],
      bottomBar: KeplerTestButton.primary(
        label: _submitted
            ? (setEquals(_selectedIds, item.correctIds)
                ? 'Correct'
                : 'Incorrect')
            : (_selectedIds.length == 3
                ? 'Valider'
                : '${_selectedIds.length} / 3 sélectionnées'),
        accentColor: accent,
        onPressed:
            (_selectedIds.length == 3 && !_submitted) ? () => _submit() : null,
      ),
      child: isWide ? _buildWide(item) : _buildNarrow(item),
    );
  }

  /// Mobile / fenêtre étroite : tout en colonne, dimensionné pour tenir
  /// dans la hauteur disponible (cible flexible + grille bornée).
  Widget _buildNarrow(PuzzleItem item) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Hauteur consommée par les éléments fixes (slots + consigne + gaps).
        const fixedChrome = 110.0;
        // Hauteur minimale réservée à la cible.
        const minTarget = 120.0;
        // Budget hauteur pour la grille d'options (2 rangées de 3).
        final gridHeightBudget =
            (constraints.maxHeight - fixedChrome - minTarget)
                .clamp(150.0, 320.0);
        // Largeur de grille correspondante : 2 rangées + espacement 10.
        final gridWidth = ((gridHeightBudget - 10) / 2) * 3 + 20;
        final effectiveGridWidth =
            gridWidth.clamp(210.0, constraints.maxWidth).toDouble();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 4),
            // La cible absorbe l'espace restant et se réduit si besoin.
            Expanded(
              child: PuzzleTargetWidget(item: item, maxWidth: 400),
            ),
            const SizedBox(height: 8),
            PuzzleSlotIndicator(filled: _selectedIds.length, total: 3),
            const SizedBox(height: 6),
            _instruction(),
            const SizedBox(height: 8),
            Center(child: _optionsGrid(item, maxWidth: effectiveGridWidth)),
            const SizedBox(height: 4),
          ],
        );
      },
    );
  }

  /// Desktop / fenêtre large : cible à gauche, pièces à droite —
  /// tout visible sans défilement (important pour un test chronométré).
  /// FittedBox : sur fenêtre basse, l'ensemble est réduit plutôt que coupé.
  Widget _buildWide(PuzzleItem item) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 430,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PuzzleTargetWidget(
                          item: item, maxWidth: 400, maxHeight: 320),
                      const SizedBox(height: 16),
                      PuzzleSlotIndicator(
                          filled: _selectedIds.length, total: 3),
                      const SizedBox(height: 12),
                      _instruction(),
                    ],
                  ),
                ),
                const SizedBox(width: 32),
                SizedBox(width: 470, child: _optionsGrid(item, maxWidth: 470)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _instruction() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        'Choisissez les 3 pièces qui forment la figure '
        '(rotations permises, retournements interdits).',
        style: AppText.body().copyWith(fontSize: 13.5),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _optionsGrid(PuzzleItem item, {required double maxWidth}) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.0,
        children: List.generate(item.options.length, (i) {
          final piece = item.options[i];
          final isSelected = _selectedIds.contains(piece.id);
          final showCorrect =
              _submitted && item.correctIds.contains(piece.id);
          final showIncorrect = _submitted && isSelected && !showCorrect;
          return PuzzlePieceWidget(
            piece: piece,
            label: _labels[i],
            unitsPerTile: item.maxPieceExtent,
            palette: item.palette,
            isSelected: isSelected,
            showCorrect: showCorrect,
            showIncorrect: showIncorrect,
            onTap: () => _togglePiece(piece.id),
          );
        }),
      ),
    );
  }
}

// ============================================================
// SUB-WIDGETS
// ============================================================

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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, color: color, size: 14),
          const SizedBox(width: 4),
          Text('$mm:$ss', style: AppText.mono(color: color, size: 12)),
        ],
      ),
    );
  }
}

/// Utilitaire pour comparer 2 sets (équivalent à setEquals de collection.dart).
bool setEquals<T>(Set<T> a, Set<T> b) {
  if (a.length != b.length) return false;
  for (final e in a) {
    if (!b.contains(e)) return false;
  }
  return true;
}
