// lib/features/data_collection/widgets/adaptive_reading_text.dart
// Texte de lecture adaptatif pour les exercices oraux (lecture + résumé).
//
// Objectif : maximiser la lisibilité sans scroll.
//   1. On mesure (LayoutBuilder + TextPainter) la plus grande taille de police
//      dans [minFontSp, maxFontSp] qui fait tenir TOUT le texte dans la hauteur
//      disponible → rendu statique, sans scroll.
//   2. Si même à la taille minimale le texte déborde (texte très long / petit
//      écran), on rend à la taille mini DANS une zone scrollable avec un
//      indicateur intuitif : dégradé en bas + chevron ↓ animé qui disparaît
//      une fois le bas atteint.
//
// Correction (mesure == rendu) : le corps hérite la police DM Sans du thème
// (AppText.body → GoogleFonts.dmSans, bodyMedium). Le TextPainter de mesure
// construit donc son style via DefaultTextStyle.of(context).style.merge(...),
// et utilise le MÊME MediaQuery.textScaler que le Text peint. La taille retenue
// est arrondie à 0,5sp VERS LE BAS → on ne déborde jamais.

import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AdaptiveReadingText extends StatelessWidget {
  final String text;
  final Color textColor;

  /// Couleur réelle de la Card englobante : cible du dégradé de fondu en mode
  /// scroll (jamais blanc en dur → fonctionne en dark mode).
  final Color surfaceColor;

  /// Bornes de taille de police, en unités .sp (le caller passe `14.sp`, etc.).
  final double minFontSp;
  final double maxFontSp;

  final double height;
  final FontWeight fontWeight;

  const AdaptiveReadingText({
    super.key,
    required this.text,
    required this.textColor,
    required this.surfaceColor,
    required this.minFontSp,
    required this.maxFontSp,
    this.height = 1.55,
    this.fontWeight = FontWeight.w400,
  });

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    final textDirection = Directionality.of(context);
    final baseStyle = DefaultTextStyle.of(context).style.merge(
          TextStyle(height: height, fontWeight: fontWeight, color: textColor),
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final maxH = constraints.maxHeight;

        final fit = _resolveFit(
          text: text,
          baseStyle: baseStyle,
          textScaler: textScaler,
          textDirection: textDirection,
          minFont: minFontSp,
          maxFont: maxFontSp,
          maxW: maxW,
          maxH: maxH,
        );

        final body = Text(
          text,
          textScaler: textScaler,
          style: baseStyle.copyWith(fontSize: fit.fontSize),
        );

        if (!fit.needsScroll) {
          // Tout tient : rendu statique aligné en haut.
          return SizedBox(
            width: double.infinity,
            child: Align(alignment: Alignment.topLeft, child: body),
          );
        }

        // Fallback : taille mini + scroll + dégradé + chevron animé.
        return _ScrollableFadingText(surfaceColor: surfaceColor, child: body);
      },
    );
  }
}

// ─── Résultat + résolution (mémoïsée) ─────────────────────────────────────────

class _FitResult {
  final double fontSize;
  final bool needsScroll;
  const _FitResult(this.fontSize, this.needsScroll);
}

/// Cache LRU : le timer d'enregistrement déclenche un setState chaque seconde,
/// ce qui reconstruit ce sous-arbre. Sans cache on relancerait la recherche
/// binaire à chaque tick.
final LinkedHashMap<String, _FitResult> _fitCache =
    LinkedHashMap<String, _FitResult>();
const int _fitCacheMax = 24;

_FitResult _resolveFit({
  required String text,
  required TextStyle baseStyle,
  required TextScaler textScaler,
  required TextDirection textDirection,
  required double minFont,
  required double maxFont,
  required double maxW,
  required double maxH,
}) {
  // Hauteur non bornée (ne devrait pas arriver dans un Expanded) → tout tient.
  if (!maxH.isFinite || maxH <= 0 || !maxW.isFinite || maxW <= 0) {
    return _FitResult(maxFont, false);
  }

  final key = '${text.hashCode}|${maxW.round()}|${maxH.round()}'
      '|${textScaler.scale(100).round()}|$minFont|$maxFont'
      '|${baseStyle.height}|${baseStyle.fontWeight?.index}';

  final cached = _fitCache.remove(key);
  if (cached != null) {
    _fitCache[key] = cached; // ré-insère en tête (LRU)
    return cached;
  }

  bool fitsAt(double fs) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: baseStyle.copyWith(fontSize: fs)),
      textDirection: textDirection,
      textScaler: textScaler,
      maxLines: null,
    )..layout(maxWidth: maxW);
    final ok = tp.height <= maxH;
    tp.dispose();
    return ok;
  }

  _FitResult result;
  if (fitsAt(maxFont)) {
    result = _FitResult(maxFont, false);
  } else if (!fitsAt(minFont)) {
    result = _FitResult(minFont, true);
  } else {
    double lo = minFont, hi = maxFont;
    while (hi - lo > 0.5) {
      final mid = (lo + hi) / 2;
      if (fitsAt(mid)) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    // On garde la plus grande taille connue comme tenant, arrondie vers le bas.
    result = _FitResult((lo * 2).floorToDouble() / 2, false);
  }

  _fitCache[key] = result;
  if (_fitCache.length > _fitCacheMax) {
    _fitCache.remove(_fitCache.keys.first);
  }
  return result;
}

// ─── Zone scrollable avec dégradé + chevron ───────────────────────────────────

class _ScrollableFadingText extends StatefulWidget {
  final Color surfaceColor;
  final Widget child;

  const _ScrollableFadingText({required this.surfaceColor, required this.child});

  @override
  State<_ScrollableFadingText> createState() => _ScrollableFadingTextState();
}

class _ScrollableFadingTextState extends State<_ScrollableFadingText> {
  final ScrollController _ctrl = ScrollController();
  bool _atBottom = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_ctrl.hasClients) return;
      // Défensif : si finalement rien à scroller, masquer l'indicateur.
      if (_ctrl.position.maxScrollExtent <= 0) {
        setState(() => _atBottom = true);
      }
    });
  }

  void _onScroll() {
    if (!_ctrl.hasClients) return;
    final atBottom = _ctrl.offset >= _ctrl.position.maxScrollExtent - 4;
    if (atBottom != _atBottom) setState(() => _atBottom = atBottom);
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onScroll);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            controller: _ctrl,
            child: Padding(
              padding: EdgeInsets.only(bottom: 30.h),
              child: widget.child,
            ),
          ),
        ),
        // Dégradé de fondu vers la couleur de la carte.
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: _atBottom ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                height: 40.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      widget.surfaceColor.withValues(alpha: 0.0),
                      widget.surfaceColor,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        // Chevron ↓ animé.
        Positioned(
          left: 0,
          right: 0,
          bottom: 2.h,
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: _atBottom ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: const _BouncingChevron(),
            ),
          ),
        ),
      ],
    );
  }
}

class _BouncingChevron extends StatefulWidget {
  const _BouncingChevron();

  @override
  State<_BouncingChevron> createState() => _BouncingChevronState();
}

class _BouncingChevronState extends State<_BouncingChevron>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Center(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, _c.value * 5.h),
          child: child,
        ),
        child: Icon(Icons.keyboard_arrow_down_rounded, size: 26.sp, color: color),
      ),
    );
  }
}
