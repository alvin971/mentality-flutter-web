import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/l10n/l10n_ext.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/test/kepler_test_button.dart';
import '../../../../../core/widgets/test/kepler_test_scaffold.dart';
import '../../../../../services/data_collection_service.dart';
import '../../../../../services/session_manager.dart';
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

  /// Graine de la banque de cette session — journalisée avec chaque item
  /// (rend la session reproductible pour le debug et la calibration).
  late final int _sessionSeed;

  /// Début de l'item courant, pour le temps de réponse journalisé.
  DateTime _itemStartedAt = DateTime.now();

  /// Phase de DÉMONSTRATION : TROIS items d'exemple fixes, sans chrono ni
  /// score, chacun rejouable jusqu'à réussite — comme la démonstration du
  /// protocole réel. Trois et non un : choisir 3 pièces parmi 6 demande
  /// d'écarter des pièges (échelle, couleurs, symétrie) que le premier item
  /// ne peut pas tous porter à lui seul.
  bool _demoPhase = true;

  /// Écran « Prêt ? » entre la démo réussie et l'item 1 : le chrono du
  /// premier item ne démarre qu'à l'appui explicite du sujet, jamais par
  /// surprise (les 20 s de l'item 1 sont des données comme les autres).
  bool _readyPhase = false;

  late final List<PuzzleItem> _demoItems;

  /// Item d'entraînement courant.
  int _demoIndex = 0;

  /// Seed fixe des items de démonstration (contrôlé visuellement : pièges
  /// évidents, motif bicolore lisible). Ne pas changer sans re-vérifier.
  static const int _demoSeed = 7;

  /// Nombre d'items d'entraînement.
  static const int _demoCount = 3;

  bool get _isLastDemo => _demoIndex >= _demoItems.length - 1;

  static const String _labels = '123456';

  @override
  void initState() {
    super.initState();
    // Les rangs 1 à 3 de l'échelle : les trois recettes les plus faciles,
    // tirées d'un générateur à graine fixe — donc les mêmes pour tout le
    // monde, et indépendants des 26 items de la passation.
    final demoGen = PuzzleGenerator(seed: _demoSeed);
    _demoItems = List.generate(
      _demoCount,
      (i) => demoGen.generateItem(i + 1, DifficultyLevel.veryEasy),
    );
    _generateItems();
    // La démonstration n'est pas chronométrée : le timer ne démarre qu'au
    // passage au premier item réel (_startRealTest).
  }

  void _generateItems() {
    final generator = PuzzleGenerator();
    _sessionSeed = generator.seed;
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

  PuzzleItem get _currentItem =>
      _demoPhase ? _demoItems[_demoIndex] : _items[_currentItemIndex];

  void _goToReady() {
    setState(() {
      _demoPhase = false;
      _readyPhase = true;
      _selectedIds.clear();
      _submitted = false;
    });
  }

  void _startRealTest() {
    setState(() => _readyPhase = false);
    _startItem();
  }

  /// Item d'entraînement suivant : même remise à zéro qu'un réessai, sur
  /// l'item d'après. Aucun chrono — il ne démarre qu'après l'écran « Prêt ? ».
  void _nextDemo() {
    setState(() {
      _demoIndex++;
      _selectedIds.clear();
      _submitted = false;
    });
  }

  void _retryDemo() {
    setState(() {
      _selectedIds.clear();
      _submitted = false;
    });
  }

  void _startItem() {
    _selectedIds.clear();
    _submitted = false;
    _remainingSeconds = _currentItem.timeLimitSeconds;
    _itemStartedAt = DateTime.now();
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
    if (!_selectedIds.contains(pieceId) && _selectedIds.length >= 3) {
      // Déjà 3 pièces : on N'ajoute PAS (remplacer silencieusement la plus
      // ancienne sélection déroutait). Le sujet doit désélectionner d'abord.
      HapticFeedback.mediumImpact();
      return;
    }
    setState(() {
      if (_selectedIds.contains(pieceId)) {
        _selectedIds.remove(pieceId);
      } else {
        _selectedIds.add(pieceId);
      }
    });
    HapticFeedback.lightImpact();
  }

  void _submit({bool autoSubmit = false}) {
    if (_submitted) return;
    _timer?.cancel();
    HapticFeedback.mediumImpact();

    if (_demoPhase) {
      // Démo : feedback visuel seulement — ni score, ni règle d'arrêt, ni
      // avance automatique (le bouton devient « Commencer » / « Réessayer »).
      setState(() => _submitted = true);
      return;
    }

    final isCorrect = _selectedIds.length == 3 &&
        setEquals(_selectedIds, _currentItem.correctIds);
    _logItemResult(isCorrect: isCorrect, autoSubmit: autoSubmit);

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
    _logSummary();
    Navigator.of(context).pop(_score);
  }

  // ---------- Journal par item (box cognitive locale, jamais exportée) ------

  void _logItemResult({required bool isCorrect, required bool autoSubmit}) {
    final item = _currentItem;
    final options = <Map<String, dynamic>>[];
    for (int i = 0; i < item.options.length; i++) {
      final o = item.options[i];
      options.add({
        'label': _labels[i],
        'trap': o.trapKind?.name,
        'twin': o.isTwin,
        'correct': o.isCorrect,
        'selected': _selectedIds.contains(o.id),
        'rotation_deg': o.displayRotationDeg,
      });
    }
    _safeLog({
      'type': 'vp_item',
      'test': 'VP',
      'session_id': SessionManager.instance.currentSessionId,
      'seed': _sessionSeed,
      'filter_level': widget.filterLevel,
      'item_index': item.index,
      'palier': item.palier,
      'level': item.level.name,
      'fallback_used': item.fallbackUsed,
      'base_shape': item.baseShape.name,
      'cut_strategy': item.cutStrategy.name,
      'time_limit_s': item.timeLimitSeconds,
      'rt_ms': DateTime.now().difference(_itemStartedAt).inMilliseconds,
      'auto_submit': autoSubmit,
      'is_correct': isCorrect,
      'n_selected': _selectedIds.length,
      'options': options,
      'recorded_at': DateTime.now().toIso8601String(),
    });
  }

  void _logSummary() {
    _safeLog({
      'type': 'vp_summary',
      'test': 'VP',
      'session_id': SessionManager.instance.currentSessionId,
      'seed': _sessionSeed,
      'filter_level': widget.filterLevel,
      'score': _score,
      'items_attempted': _currentItemIndex + 1,
      'total_items': _items.length,
      'stop_reason': _consecutiveFailures >= 3 ? 'discontinue' : 'completed',
      'recorded_at': DateTime.now().toIso8601String(),
    });
  }

  /// Écriture asynchrone best-effort : un échec de journalisation ne doit en
  /// aucun cas perturber la passation.
  Future<void> _safeLog(Map<String, dynamic> record) async {
    try {
      await DataCollectionService.instance.saveCognitiveRecord(record);
    } catch (_) {
      // Journal best-effort — jamais d'interruption du test pour un log.
    }
  }

  /// Vrai quand un item réel chronométré est en cours (ni démo, ni écran
  /// Prêt).
  bool get _isPlaying => !_demoPhase && !_readyPhase;

  @override
  Widget build(BuildContext context) {
    final item = _currentItem;
    final accent = AppColors.indexVSI;
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    return KeplerTestScaffold(
      stimulusSurface: true,
      testName: context.l10n.vpTestName,
      eyebrow:
          _demoPhase ? context.l10n.vpDemoEyebrow : context.l10n.vpEyebrow,
      accentColor: accent,
      // Pendant l'entraînement, la barre compte les 3 items d'exemple et non
      // les 26 items cotés — l'eyebrow « ENTRAÎNEMENT » lui sert de libellé.
      // Rien sur l'écran « Prêt ? », qui n'est pas un item.
      currentItem: _isPlaying
          ? _currentItemIndex + 1
          : _demoPhase
              ? _demoIndex + 1
              : null,
      totalItems: _isPlaying
          ? _items.length
          : _demoPhase
              ? _demoItems.length
              : null,
      // Aucun défilement : cible et pièces se redimensionnent pour tenir
      // dans la hauteur de n'importe quel écran (test chronométré).
      scrollable: false,
      trailing: _isPlaying
          ? [_TimerBadge(seconds: _remainingSeconds, accent: accent)]
          : null,
      bottomBar: KeplerTestButton.primary(
        label: _bottomBarLabel(context, item),
        accentColor: accent,
        onPressed: _bottomBarAction(item),
      ),
      child: _readyPhase
          ? _buildReady(context)
          : isWide
              ? _buildWide(context, item)
              : _buildNarrow(context, item),
    );
  }

  String _bottomBarLabel(BuildContext context, PuzzleItem item) {
    if (_readyPhase) return context.l10n.vpReadyStart;
    if (_submitted) {
      if (_demoPhase) {
        final ok = setEquals(_selectedIds, item.correctIds);
        if (!ok) return context.l10n.vpDemoRetry;
        return _isLastDemo
            ? context.l10n.vpDemoStart
            : context.l10n.demoContinue;
      }
      // Test réel : libellé NEUTRE — aucun retour correct/incorrect au
      // sujet, conformément au protocole (la démo, elle, garde son
      // feedback pédagogique complet).
      return context.l10n.vpRecorded;
    }
    return _selectedIds.length == 3
        ? context.l10n.vpValidate
        : context.l10n.vpSelectedCount(_selectedIds.length);
  }

  VoidCallback? _bottomBarAction(PuzzleItem item) {
    if (_readyPhase) return _startRealTest;
    if (_submitted) {
      if (!_demoPhase) return null;
      if (!setEquals(_selectedIds, item.correctIds)) return _retryDemo;
      return _isLastDemo ? _goToReady : _nextDemo;
    }
    return _selectedIds.length == 3 ? () => _submit() : null;
  }

  /// Écran « Prêt ? » : l'item 1 n'est PAS affiché (aucune seconde de
  /// prévisualisation gratuite) ; le chrono démarre au bouton.
  Widget _buildReady(BuildContext context) {
    final accent = AppColors.indexVSI;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.timer_outlined, color: accent, size: 44),
              const SizedBox(height: 16),
              Text(
                context.l10n.vpReadyTitle,
                style: AppText.of(context).h2(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                context.l10n.vpReadyBody(_items.length),
                style: AppText.of(context).body(),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Mobile / fenêtre étroite : tout en colonne, dimensionné pour tenir
  /// dans la hauteur disponible (cible flexible + grille bornée).
  Widget _buildNarrow(BuildContext context, PuzzleItem item) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Hauteur consommée par les éléments fixes (slots + consigne + gaps).
        const fixedChrome = 110.0;
        // Hauteur minimale réservée à la cible (réduite depuis l'échelle
        // unifiée : la cible est plus petite, la grille récupère la place —
        // donc TOUT est dessiné plus grand).
        const minTarget = 100.0;
        // Budget hauteur pour la grille d'options (2 rangées de 3).
        final gridHeightBudget =
            (constraints.maxHeight - fixedChrome - minTarget)
                .clamp(150.0, 380.0);
        // Largeur de grille correspondante : 2 rangées + espacement 10.
        final gridWidth = ((gridHeightBudget - 10) / 2) * 3 + 20;
        final effectiveGridWidth =
            gridWidth.clamp(210.0, constraints.maxWidth).toDouble();
        // Échelle UNIFIÉE cible/pièces : additionner les 3 bonnes pièces
        // redonne exactement la taille affichée de la figure.
        final tileSide = (effectiveGridWidth - 20) / 3;
        final ppu =
            PuzzlePieceWidget.pixelsPerUnit(tileSide, item.maxPieceExtent);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 4),
            // La cible absorbe l'espace restant et se réduit si besoin.
            Expanded(
              child: PuzzleTargetWidget(
                  item: item, maxWidth: 440, pixelsPerUnit: ppu),
            ),
            const SizedBox(height: 8),
            PuzzleSlotIndicator(filled: _selectedIds.length, total: 3),
            const SizedBox(height: 6),
            _instruction(context),
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
  Widget _buildWide(BuildContext context, PuzzleItem item) {
    // Échelle UNIFIÉE cible/pièces (cases de (560−20)/3 = 180 px).
    final ppu =
        PuzzlePieceWidget.pixelsPerUnit(180, item.maxPieceExtent);
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 500,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PuzzleTargetWidget(
                          item: item,
                          maxWidth: 470,
                          maxHeight: 380,
                          pixelsPerUnit: ppu),
                      const SizedBox(height: 16),
                      PuzzleSlotIndicator(
                          filled: _selectedIds.length, total: 3),
                      const SizedBox(height: 12),
                      _instruction(context),
                    ],
                  ),
                ),
                const SizedBox(width: 32),
                SizedBox(width: 560, child: _optionsGrid(item, maxWidth: 560)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _instruction(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      // Hauteur plafonnée (≈ 3 lignes) : le layout étroit est calibré au
      // pixel — une consigne plus longue (autre langue, échelle de police)
      // défile au lieu de faire déborder la colonne.
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 56),
        child: SingleChildScrollView(
          child: Text(
            _demoPhase
                ? context.l10n.vpDemoInstruction
                : context.l10n.vpInstruction,
            style: AppText.of(context).body().copyWith(fontSize: 13.5),
            textAlign: TextAlign.center,
          ),
        ),
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
          // Révélation des bonnes pièces UNIQUEMENT en démo (pédagogique).
          // Pendant le test réel, aucun feedback visuel ne trahit la
          // réponse — protocole respecté, pas d'apprentissage en cours de
          // passation.
          final showCorrect = _submitted &&
              _demoPhase &&
              item.correctIds.contains(piece.id);
          final showIncorrect =
              _submitted && _demoPhase && isSelected && !showCorrect;
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
          Text('$mm:$ss', style: AppText.of(context).mono(color: color, size: 12)),
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
