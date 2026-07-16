// Outillage d'audit visuel WIDGET-FIDÈLE des Puzzles Visuels.
//
// Contrairement à render_items_audit_test.dart (reproduction canvas), on pompe
// ici les VRAIS widgets (PuzzleTargetWidget + 6 × PuzzlePieceWidget) avec le
// câblage exact du layout large de visual_puzzles_test_page.dart (cases de
// 180 px, pont d'échelle PuzzlePieceWidget.pixelsPerUnit) : c'est le seul
// moyen d'attraper les dérives de painters (clamp du cadre cible, paddings,
// rotation d'affichage) que la reproduction canvas ne voit pas.
//
// L'image produite ne révèle PAS les réponses (protocole de résolution à
// l'aveugle par les inspecteurs) : les vérités terrain vivent dans le sidecar
// JSON par seed, à consulter APRÈS le premier passage.

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mentality/core/l10n/gen/app_localizations.dart';
import 'package:mentality/features/exercises_implementations/visual_puzzles/domain/geometry.dart';
import 'package:mentality/features/exercises_implementations/visual_puzzles/domain/puzzle_generator.dart';
import 'package:mentality/features/exercises_implementations/visual_puzzles/presentation/widgets/puzzle_piece_widget.dart';
import 'package:mentality/features/exercises_implementations/visual_puzzles/presentation/widgets/puzzle_target_widget.dart';

/// Constantes du layout LARGE réel (visual_puzzles_test_page.dart, _buildWide).
const double kAuditTileSide = 180;
const double kAuditTargetMaxWidth = 470;
const double kAuditTargetMaxHeight = 380;

/// Géométrie interne des widgets, répliquée pour les pré-checks déterministes.
/// DOIT rester alignée sur puzzle_target_widget.dart / puzzle_piece_widget.dart.
const double _targetPadH = 24; // padding LTRB(12,24,12,10) → 12+12
const double _targetPadV = 34; // 24+10
const double _tileInnerW = kAuditTileSide - 8 - 8; // container 4×2 + LTRB 4/4
const double _tileInnerH = kAuditTileSide - 8 - 24; // LTRB 20 haut + 4 bas

/// Charge une vraie fonte (Roboto du SDK) sous les familles utilisées par les
/// widgets — sinon TOUT texte rend en blocs Ahem dans `flutter test`.
/// À appeler depuis `setUpAll` (I/O réel, hors FakeAsync).
Future<void> loadRealFonts() async {
  final dir =
      Directory('/home/ubuntu/flutter/bin/cache/artifacts/material_fonts');
  final regular = File('${dir.path}/Roboto-Regular.ttf');
  final ttf = regular.existsSync()
      ? regular
      : dir
          .listSync()
          .whereType<File>()
          .firstWhere((f) => f.path.endsWith('.ttf'));
  final bytes = ttf.readAsBytesSync();

  // Famille résolue par google_fonts pour AppText.mono (pastilles 1-6 et
  // cartouche « CIBLE ») + 'Roboto' pour nos bandeaux de métadonnées.
  // La résolution déclenche un fetch réseau voué à l'échec en test → isolé
  // dans une zone gardée (les glyphes viennent de NOTRE FontLoader, pas du
  // fetch ; seul le bruit d'erreur async doit être avalé).
  // google_fonts enregistre UNE famille PAR VARIANTE de graisse
  // ('RobotoMono_medium' pour w500, etc.) : couvrir toutes les graisses
  // utilisées par AppText (mono w500, monoLabel w600, …).
  final families = <String>{'Roboto', 'RobotoMono'};
  runZonedGuarded(() {
    for (final w in [
      FontWeight.w400,
      FontWeight.w500,
      FontWeight.w600,
      FontWeight.w700,
    ]) {
      final fam = GoogleFonts.robotoMono(fontWeight: w).fontFamily;
      if (fam != null) families.add(fam);
    }
  }, (e, s) => _swallowFontNoise(e, s));
  for (final fam in families) {
    final loader = FontLoader(fam)
      ..addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
  }
}

/// Erreurs async inattendues remontées par [guardedFontZone] (les échecs de
/// fetch google_fonts, attendus hors ligne, sont ignorés).
final List<Object> unexpectedZoneErrors = <Object>[];

void _swallowFontNoise(Object e, StackTrace s) {
  final msg = e.toString();
  final isFontNoise = msg.contains('google_fonts') ||
      msg.contains('Failed to load font') ||
      msg.contains('fonts.gstatic.com');
  if (!isFontNoise) unexpectedZoneErrors.add(e);
}

/// Exécute [body] dans une zone qui avale UNIQUEMENT le bruit réseau
/// google_fonts (toute autre erreur est collectée dans
/// [unexpectedZoneErrors], à vérifier en fin de test).
Future<T?> guardedFontZone<T>(Future<T> Function() body) =>
    runZonedGuarded(body, _swallowFontNoise) ?? Future.value(null);

/// Carte d'audit : cible + grille 3×2 des 6 options, câblage IDENTIQUE au
/// layout large de la page réelle (échelle unifiée incluse).
class AuditCard extends StatelessWidget {
  const AuditCard({super.key, required this.item, required this.captureKey});

  final PuzzleItem item;
  final GlobalKey captureKey;

  @override
  Widget build(BuildContext context) {
    final ppu =
        PuzzlePieceWidget.pixelsPerUnit(kAuditTileSide, item.maxPieceExtent);

    Widget tile(int i) => SizedBox(
          width: kAuditTileSide,
          height: kAuditTileSide,
          child: PuzzlePieceWidget(
            piece: item.options[i],
            label: '${i + 1}',
            unitsPerTile: item.maxPieceExtent,
            palette: item.palette,
          ),
        );

    Widget row(int from) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = from; i < from + 3; i++) ...[
              if (i != from) const SizedBox(width: 10),
              tile(i),
            ],
          ],
        );

    return RepaintBoundary(
      key: captureKey,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PuzzleTargetWidget(
              item: item,
              maxWidth: kAuditTargetMaxWidth,
              maxHeight: kAuditTargetMaxHeight,
              pixelsPerUnit: ppu,
            ),
            const SizedBox(height: 12),
            row(0),
            const SizedBox(height: 10),
            row(3),
          ],
        ),
      ),
    );
  }
}

/// Enrobage minimal (thème clair + l10n fr), même pattern que vp_flow_test.
Widget wrapCard(Widget card) {
  // designSize == taille de surface du test → facteur .sp = 1.0 : les textes
  // ScreenUtil (pastilles, cartouche) gardent leur taille logique nominale.
  return ScreenUtilInit(
    designSize: const Size(760, 900),
    minTextAdapt: true,
    splitScreenMode: true,
    builder: (context, child) => MaterialApp(
      theme: ThemeData(brightness: Brightness.light, useMaterial3: true),
      locale: const Locale('fr'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Align(alignment: Alignment.topLeft, child: card),
      ),
    ),
  );
}

/// Capture le RepaintBoundary de la carte (à appeler DANS tester.runAsync).
Future<ui.Image> captureCard(GlobalKey key, {double pixelRatio = 1.6}) {
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  return boundary.toImage(pixelRatio: pixelRatio);
}

/// Compose l'image finale : bandeau méta (sans réponses !) + carte + bandeau
/// rotations, puis écrit le PNG (à appeler DANS tester.runAsync).
Future<void> compositeAndSave({
  required ui.Image card,
  required PuzzleItem item,
  required int seed,
  required double ppu,
  required String outPath,
}) async {
  final w = card.width.toDouble();
  const pad = 12.0;

  TextPainter tp(String text, double size, {FontWeight? weight}) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: const Color(0xFF111111),
          fontSize: size,
          fontWeight: weight ?? FontWeight.w400,
          fontFamily: 'Roboto',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: w - 2 * pad);
    return painter;
  }

  final header1 = tp(
    'seed $seed · item ${item.index.toString().padLeft(2, '0')}/26 · '
    'palier ${item.palier} · ${item.cutStrategy.name}'
    '${item.fallbackUsed ? ' · FALLBACK' : ''}',
    26,
    weight: FontWeight.w700,
  );
  final header2 = tp(
    'échelle unifiée : ${ppu.toStringAsFixed(1)} px/unité · '
    'extent ${item.maxPieceExtent.toStringAsFixed(2)} · '
    'temps ${item.timeLimitSeconds}s',
    20,
  );
  final footer = tp(
    'rotations affichées — ${List.generate(6, (i) => '${i + 1}: '
        '${item.options[i].displayRotationDeg.round()}°').join(' · ')}',
    20,
  );

  final headerH = header1.height + header2.height + 3 * pad;
  final footerH = footer.height + 2 * pad;
  final totalH = headerH + card.height + footerH;

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(Rect.fromLTWH(0, 0, w, totalH),
      Paint()..color = const Color(0xFFFFFFFF));
  header1.paint(canvas, const Offset(pad, pad));
  header2.paint(canvas, Offset(pad, pad * 2 + header1.height));
  canvas.drawImage(card, Offset(0, headerH), Paint());
  canvas.drawRect(
      Rect.fromLTWH(0, headerH + card.height, w, footerH),
      Paint()..color = const Color(0xFFF2F2F2));
  footer.paint(canvas, Offset(pad, headerH + card.height + pad));

  final img = await recorder
      .endRecording()
      .toImage(w.round(), totalH.round());
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  File(outPath)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes!.buffer.asUint8List());
}

// ---------------------------------------------------------------------------
// Pré-checks déterministes (sidecar JSON) — détecteurs des angles morts.
// ---------------------------------------------------------------------------

/// Rééchantillonne le contour fermé en [n] points à abscisse curviligne
/// uniforme (insensible au nombre de sommets).
List<Offset> _resampleClosed(Polygon p, int n) {
  final v = p.vertices;
  final lens = <double>[];
  double perim = 0;
  for (int i = 0; i < v.length; i++) {
    final d = (v[(i + 1) % v.length] - v[i]).distance;
    lens.add(d);
    perim += d;
  }
  if (perim < kGeomEps) return List.filled(n, v.isEmpty ? Offset.zero : v[0]);
  final out = <Offset>[];
  double target = 0;
  int seg = 0;
  double acc = 0;
  final step = perim / n;
  for (int k = 0; k < n; k++) {
    while (seg < v.length - 1 && acc + lens[seg] < target - kGeomEps) {
      acc += lens[seg];
      seg++;
    }
    final segLen = lens[seg];
    final t = segLen < kGeomEps ? 0.0 : (target - acc) / segLen;
    final a = v[seg];
    final b = v[(seg + 1) % v.length];
    out.add(Offset(a.dx + (b.dx - a.dx) * t, a.dy + (b.dy - a.dy) * t));
    target += step;
  }
  return out;
}

/// Distance de forme À ORIENTATION FIXE (telle qu'affichée) : centrage sur le
/// centroïde, AUCUN alignement en rotation (contrairement à
/// perceptuallyIdentical qui est invariant par rotation). Min sur les
/// décalages cycliques du point de départ et le sens de parcours.
/// Résultat relatif à la taille (rayon RMS moyen) : 0 = identique à l'écran.
double screenShapeDistance(Polygon a, Polygon b, {int samples = 64}) {
  final ca = a.centroid();
  final cb = b.centroid();
  final sa = _resampleClosed(a, samples).map((p) => p - ca).toList();
  var sb0 = _resampleClosed(b, samples).map((p) => p - cb).toList();

  double rms(List<Offset> pts) => math.sqrt(
      pts.fold<double>(0, (s, p) => s + p.distanceSquared) / pts.length);
  final size = math.max((rms(sa) + rms(sb0)) / 2, kGeomEps);

  double best = double.infinity;
  for (final reversed in [false, true]) {
    final sb = reversed ? sb0.reversed.toList() : sb0;
    for (int shift = 0; shift < samples; shift++) {
      double sum = 0;
      for (int i = 0; i < samples; i++) {
        sum += (sa[i] - sb[(i + shift) % samples]).distanceSquared;
      }
      final d = math.sqrt(sum / samples) / size;
      if (d < best) best = d;
    }
  }
  return best;
}

/// Identité « à l'écran » : aires proches (porte 16 %, comme les gardes
/// géométriques) ET contours quasi superposables à l'orientation affichée.
bool screenIdentical(Polygon a, Polygon b, {double tol = kPerceptualTol}) {
  final areaA = a.area();
  final areaB = b.area();
  final maxArea = math.max(areaA, areaB);
  if (maxArea < kGeomEps) return true;
  if ((areaA - areaB).abs() / maxArea > 2 * tol) return false;
  return screenShapeDistance(a, b) <= tol;
}

/// Histogramme de couleurs d'une option : part de l'aire de la pièce par
/// index de palette (le motif fait partie de l'identité visuelle — une paire
/// wrongColors ↔ source partage la géométrie mais PAS l'histogramme).
Map<int, double> _colorHistogram(PuzzlePiece o) {
  final total = math.max(o.polygon.area(), kGeomEps);
  final m = <int, double>{};
  for (final r in o.regions) {
    m[r.colorIndex] = (m[r.colorIndex] ?? 0) + r.polygon.area() / total;
  }
  return m;
}

/// Distance L1/2 entre histogrammes de couleurs (0 = même habillage).
double colorHistDistance(PuzzlePiece a, PuzzlePiece b) {
  final ha = _colorHistogram(a);
  final hb = _colorHistogram(b);
  final keys = {...ha.keys, ...hb.keys};
  double sum = 0;
  for (final k in keys) {
    sum += ((ha[k] ?? 0) - (hb[k] ?? 0)).abs();
  }
  return sum / 2;
}

double _minPaletteRgbDistance(List<Color> palette) {
  double best = double.infinity;
  for (int i = 0; i < palette.length; i++) {
    for (int j = i + 1; j < palette.length; j++) {
      final a = palette[i];
      final b = palette[j];
      final d = math.sqrt(
          math.pow((a.r - b.r) * 255, 2) +
              math.pow((a.g - b.g) * 255, 2) +
              math.pow((a.b - b.b) * 255, 2));
      if (d < best) best = d;
    }
  }
  return best.isFinite ? best : 999;
}

/// Métadonnées + pré-checks d'un item, pour le sidecar JSON par seed.
Map<String, dynamic> itemMetadata(PuzzleItem item,
    {required int seed, double tileSide = kAuditTileSide}) {
  final ppu = PuzzlePieceWidget.pixelsPerUnit(tileSide, item.maxPieceExtent);
  final targetArea = item.targetPolygon.area();

  // Dérive d'échelle de la CIBLE : cadre réel du widget (unifiedFrameSize)
  // + réplique du min(fitScale, ppu) de _TargetPainter. 1.0 = aucune dérive.
  final bb = item.targetPolygon.bbox();
  final frame = PuzzleTargetWidget.unifiedFrameSize(bb, ppu,
      maxWidth: kAuditTargetMaxWidth, maxHeight: kAuditTargetMaxHeight);
  final pad = PuzzleTargetWidget.painterPadding;
  final availW = (frame.width - _targetPadH) * (1 - 2 * pad);
  final availH = (frame.height - _targetPadV) * (1 - 2 * pad);
  final fitScale = math.min(availW / bb.width, availH / bb.height);
  final targetScale = math.min(fitScale, ppu);
  final targetScaleDrift = ppu / targetScale;

  double maxUnrotatedExtent = 0;
  final options = <Map<String, dynamic>>[];
  for (int i = 0; i < item.options.length; i++) {
    final o = item.options[i];
    final raw = o.polygon.bbox();
    maxUnrotatedExtent =
        math.max(maxUnrotatedExtent, math.max(raw.width, raw.height));
    final disp = o.displayPolygon.bbox();
    final clipped = disp.width * ppu > _tileInnerW + 0.5 ||
        disp.height * ppu > _tileInnerH + 0.5;
    options.add({
      'label': i + 1,
      'correct': o.isCorrect,
      'trap': o.trapKind?.name,
      'twin': o.isTwin,
      'rotationDeg': o.displayRotationDeg,
      'areaShare': o.polygon.area() / targetArea,
      'clipped': clipped,
    });
  }

  final screenIdenticalPairs = <List<int>>[];
  final screenNearPairs = <Map<String, dynamic>>[];
  final sameShapeColorTrapPairs = <Map<String, dynamic>>[];
  final geomConfusablePairs = <List<int>>[];
  for (int i = 0; i < item.options.length; i++) {
    for (int j = i + 1; j < item.options.length; j++) {
      final a = item.options[i];
      final b = item.options[j];
      final d = screenShapeDistance(a.displayPolygon, b.displayPolygon);
      final areaOk = (a.polygon.area() - b.polygon.area()).abs() /
              math.max(math.max(a.polygon.area(), b.polygon.area()),
                  kGeomEps) <=
          2 * kPerceptualTol;
      final dColor = colorHistDistance(a, b);
      if (areaOk && d <= kPerceptualTol) {
        if (dColor <= 0.10) {
          // Même forme À L'ÉCRAN et même habillage → indiscernable.
          screenIdenticalPairs.add([i + 1, j + 1]);
        } else {
          // Même forme mais motif différent : piège wrongColors voulu —
          // la couleur doit suffire à discriminer (à juger visuellement, H).
          sameShapeColorTrapPairs.add({
            'pair': [i + 1, j + 1],
            'colorDistance': double.parse(dColor.toStringAsFixed(3)),
          });
        }
      } else if (areaOk && d <= 0.18 && dColor <= 0.10) {
        screenNearPairs.add({
          'pair': [i + 1, j + 1],
          'distance': double.parse(d.toStringAsFixed(3)),
        });
      }
      if (visuallyConfusable(a.polygon, b.polygon, allowMirror: true)) {
        geomConfusablePairs.add([i + 1, j + 1]);
      }
    }
  }

  final trueAreaSumRel = item.correctPieces
          .fold<double>(0, (s, p) => s + p.polygon.area()) /
      targetArea;
  final rotationInflation =
      item.maxPieceExtent / math.max(maxUnrotatedExtent, kGeomEps);

  bool cvdPair = false;
  for (int i = 0; i < item.palette.length && !cvdPair; i++) {
    for (int j = i + 1; j < item.palette.length; j++) {
      if (!PuzzleGenerator.paletteCompatible(
          item.palette[i], item.palette[j])) {
        cvdPair = true;
        break;
      }
    }
  }

  final flags = <String>[
    if (screenIdenticalPairs.isNotEmpty) 'A_screenIdentical',
    if ((trueAreaSumRel - 1).abs() > 0.03) 'C_areaSumOff',
    if (targetScaleDrift > 1.02) 'D_targetScaleDrift',
    if (cvdPair) 'E_cvdPair',
    if (options.any((o) => o['clipped'] == true)) 'K_clipped',
    if (rotationInflation > 1.4) 'L_rotationInflation',
    if (item.fallbackUsed) 'M_fallback',
  ];

  return {
    'seed': seed,
    'item': item.index,
    'palier': item.palier,
    'level': item.level.name,
    'strategy': item.cutStrategy.name,
    'fallbackUsed': item.fallbackUsed,
    'timeLimitSeconds': item.timeLimitSeconds,
    'maxPieceExtent': double.parse(item.maxPieceExtent.toStringAsFixed(4)),
    'ppu': double.parse(ppu.toStringAsFixed(2)),
    'targetScaleDrift': double.parse(targetScaleDrift.toStringAsFixed(4)),
    'trueAreaSumRel': double.parse(trueAreaSumRel.toStringAsFixed(4)),
    'rotationInflation': double.parse(rotationInflation.toStringAsFixed(3)),
    'paletteMinRgbDist':
        double.parse(_minPaletteRgbDistance(item.palette).toStringAsFixed(1)),
    'cvdPairPresent': cvdPair,
    'correctLabels': [
      for (int i = 0; i < item.options.length; i++)
        if (item.options[i].isCorrect) i + 1,
    ],
    'options': options,
    'screenIdenticalPairs': screenIdenticalPairs,
    'screenNearIdenticalPairs': screenNearPairs,
    'sameShapeColorTrapPairs': sameShapeColorTrapPairs,
    'geomConfusablePairs': geomConfusablePairs,
    'flags': flags,
  };
}
