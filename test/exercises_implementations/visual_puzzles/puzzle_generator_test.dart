import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/features/exercises_implementations/visual_puzzles/domain/puzzle_generator.dart';

/// Histogramme aire-par-couleur d'une liste de régions.
Map<int, double> _colorHistogram(List<ColoredRegion> regions) {
  final m = <int, double>{};
  for (final r in regions) {
    m[r.colorIndex] = (m[r.colorIndex] ?? 0) + r.polygon.area();
  }
  return m;
}

/// Vrai si les deux motifs diffèrent nettement (> 5 % de variation totale).
bool _patternsDiffer(Map<int, double> a, Map<int, double> b) {
  final keys = {...a.keys, ...b.keys};
  double diff = 0, total = 0;
  for (final k in keys) {
    diff += ((a[k] ?? 0) - (b[k] ?? 0)).abs();
    total += (a[k] ?? 0) + (b[k] ?? 0);
  }
  return total > 0 && diff / total > 0.05;
}

void main() {
  group('PuzzleGenerator — structure du test', () {
    test('génère exactement 26 items avec la bonne répartition de niveaux',
        () {
      final items = PuzzleGenerator(seed: 42).generateComplete26Items();
      expect(items.length, 26);
      expect(
          items.where((i) => i.level == DifficultyLevel.veryEasy).length, 6);
      expect(items.where((i) => i.level == DifficultyLevel.easy).length, 8);
      expect(items.where((i) => i.level == DifficultyLevel.medium).length, 6);
      expect(items.where((i) => i.level == DifficultyLevel.hard).length, 6);
    });

    test('temps limites conformes : 20 s items 1-7, 30 s items 8-26', () {
      final items = PuzzleGenerator(seed: 7).generateComplete26Items();
      for (final item in items) {
        expect(item.timeLimitSeconds, item.index <= 7 ? 20 : 30,
            reason: 'item ${item.index}');
      }
    });

    test('chaque item a 6 options dont exactement 3 correctes', () {
      final items = PuzzleGenerator(seed: 99).generateComplete26Items();
      for (final item in items) {
        expect(item.options.length, 6, reason: 'item ${item.index}');
        expect(item.correctIds.length, 3, reason: 'item ${item.index}');
        expect(item.options.where((o) => o.isCorrect).length, 3,
            reason: 'item ${item.index}');
        final ids = item.options.map((o) => o.id).toSet();
        expect(ids.length, 6, reason: 'ids uniques, item ${item.index}');
        expect(ids.containsAll(item.correctIds), isTrue);
      }
    });
  });

  group('PuzzleGenerator — invariants géométriques (500 items)', () {
    late List<PuzzleItem> allItems;

    setUpAll(() {
      allItems = [
        for (int seed = 0; seed < 20; seed++)
          ...PuzzleGenerator(seed: seed).generateComplete26Items(),
      ];
    });

    test('les 3 vraies pièces reconstituent toujours la cible', () {
      for (final item in allItems) {
        final pieces = item.correctPieces.map((p) => p.polygon).toList();
        expect(
          isReconstruction(pieces, item.targetPolygon,
              areaTolerance: 0.03, minAreaShare: 0.10),
          isTrue,
          reason: 'item ${item.index} (${item.baseShape.name}, '
              '${item.cutStrategy.name})',
        );
      }
    });

    test('aucune pièce minuscule ni dégénérée parmi les options', () {
      for (final item in allItems) {
        final targetArea = item.targetPolygon.area();
        for (final o in item.options) {
          expect(o.polygon.vertices.length, greaterThanOrEqualTo(3));
          expect(o.polygon.area() / targetArea, greaterThan(0.05),
              reason: 'item ${item.index}, piège ${o.trapKind}');
        }
      }
    });

    test(
        'aucun distracteur congruent à une vraie pièce par rotation '
        '(sinon 2 réponses valides) — sauf wrongColors qui doit alors '
        'différer par son MOTIF', () {
      for (final item in allItems) {
        final correct = item.correctPieces;
        for (final o in item.options.where((o) => !o.isCorrect)) {
          for (final c in correct) {
            if (o.trapKind == TrapKind.wrongColors) {
              // Géométrie identique AUTORISÉE : la différence est la couleur.
              if (congruent(o.polygon, c.polygon)) {
                expect(
                  _patternsDiffer(
                      _colorHistogram(o.regions), _colorHistogram(c.regions)),
                  isTrue,
                  reason: 'item ${item.index} : piège wrongColors avec le '
                      'MÊME motif qu\'une vraie pièce → 2 réponses valides',
                );
              }
            } else {
              expect(congruent(o.polygon, c.polygon), isFalse,
                  reason: 'item ${item.index} : piège ${o.trapKind} congruent '
                      'à une vraie pièce');
            }
          }
        }
      }
    });

    test('le piège miroir n\'est jamais une simple rotation de sa source', () {
      for (final item in allItems) {
        for (final o
            in item.options.where((o) => o.trapKind == TrapKind.mirrored)) {
          for (final c in item.correctPieces) {
            expect(congruent(o.polygon, c.polygon), isFalse);
          }
        }
      }
    });

    test('maxPieceExtent couvre bien toutes les options affichées', () {
      for (final item in allItems) {
        for (final o in item.options) {
          final bb = o.displayPolygon.bbox();
          expect(bb.width, lessThanOrEqualTo(item.maxPieceExtent + 1e-6));
          expect(bb.height, lessThanOrEqualTo(item.maxPieceExtent + 1e-6));
        }
      }
    });

    // ---------- Système de couleurs (motif indépendant des découpes) ----------

    test('les zones de couleur recouvrent exactement la cible', () {
      for (final item in allItems) {
        final zoneArea =
            item.colorZones.fold<double>(0, (s, z) => s + z.polygon.area());
        expect(zoneArea / item.targetPolygon.area(), closeTo(1.0, 0.03),
            reason: 'item ${item.index}');
        for (final z in item.colorZones) {
          expect(z.colorIndex, lessThan(item.palette.length),
              reason: 'item ${item.index} : index de couleur hors palette');
        }
      }
    });

    test('chaque option porte des régions qui couvrent sa silhouette', () {
      for (final item in allItems) {
        for (final o in item.options) {
          expect(o.regions, isNotEmpty,
              reason: 'item ${item.index}, piège ${o.trapKind}');
          final regionArea =
              o.regions.fold<double>(0, (s, r) => s + r.polygon.area());
          expect(regionArea / o.polygon.area(), closeTo(1.0, 0.08),
              reason: 'item ${item.index}, piège ${o.trapKind} : régions ne '
                  'couvrent pas la pièce');
          for (final r in o.regions) {
            expect(r.colorIndex, lessThan(item.palette.length));
          }
        }
      }
    });

    test(
        'items multicolores : au moins une vraie pièce BICOLORE '
        '(la couleur ne suffit jamais à identifier les pièces)', () {
      for (final item in allItems) {
        if (item.palette.length < 2) continue; // monochrome (hard) : exempt
        final hasBicolor = item.correctPieces.any((p) {
          final colors = p.regions
              .where((r) => r.polygon.area() / p.polygon.area() >= 0.15)
              .map((r) => r.colorIndex)
              .toSet();
          return colors.length >= 2;
        });
        expect(hasBicolor, isTrue,
            reason: 'item ${item.index} : motif aligné sur les découpes → '
                'résoluble par correspondance de couleurs');
      }
    });

    test('palette : couleurs distinctes par item', () {
      for (final item in allItems) {
        expect(item.palette.toSet().length, item.palette.length,
            reason: 'item ${item.index}');
        expect(item.palette.length, inInclusiveRange(1, 3));
      }
    });

    // ---------- Solvabilité humaine (audit 2026-07-02) ----------
    // Ces invariants verrouillent les correctifs de l'audit : un item peut
    // être difficile, jamais ambigu ni réductible à un jugement au pixel.

    test(
        'aucun piège quasi congruent (seuil perceptuel 6 %) à une vraie '
        'pièce — sinon deux réponses visuellement valides', () {
      for (final item in allItems) {
        for (final o in item.options.where((o) => !o.isCorrect)) {
          if (o.trapKind == TrapKind.wrongColors) continue;
          for (final c in item.correctPieces) {
            expect(congruent(o.polygon, c.polygon, relTol: 0.06), isFalse,
                reason: 'item ${item.index} : piège ${o.trapKind?.name} '
                    'indiscernable d\'une vraie pièce '
                    '(${item.baseShape.name}/${item.cutStrategy.name})');
          }
        }
      }
    });

    test(
        'wrongColors jamais réduit à une discrimination de taille : un piège '
        'UNI ne porte jamais la couleur d\'une vraie pièce unie', () {
      int? uniColor(Map<int, double> histo, double pieceArea) {
        for (final e in histo.entries) {
          if (e.value / pieceArea >= 0.95) return e.key;
        }
        return null;
      }

      for (final item in allItems) {
        for (final o in item.options
            .where((o) => o.trapKind == TrapKind.wrongColors)) {
          final trapUni = uniColor(_colorHistogram(o.regions), o.polygon.area());
          if (trapUni == null) continue;
          for (final c in item.correctPieces) {
            final trueUni =
                uniColor(_colorHistogram(c.regions), c.polygon.area());
            expect(trueUni == trapUni, isFalse,
                reason: 'item ${item.index} : wrongColors uni de la même '
                    'couleur qu\'une vraie pièce unie → pur jugement de '
                    'taille');
          }
        }
      }
    });

    test('palette : toutes les paires de couleurs sont compatibles '
        '(proximité perceptuelle + daltonisme)', () {
      for (final item in allItems) {
        for (int i = 0; i < item.palette.length; i++) {
          for (int j = i + 1; j < item.palette.length; j++) {
            expect(
                PuzzleGenerator.paletteCompatible(
                    item.palette[i], item.palette[j]),
                isTrue,
                reason: 'item ${item.index} : paire interdite dans la '
                    'palette');
          }
        }
      }
    });

    test('aucune option "aiguille" : ratio bbox min/max ≥ 0.155 à l\'écran',
        () {
      for (final item in allItems) {
        for (final o in item.options) {
          final bb = o.displayPolygon.bbox();
          final maxDim = bb.width > bb.height ? bb.width : bb.height;
          final minDim = bb.width < bb.height ? bb.width : bb.height;
          expect(minDim / maxDim, greaterThanOrEqualTo(0.155),
              reason: 'item ${item.index}, piège ${o.trapKind?.name} : '
                  'pièce trop fine pour être comparée');
        }
      }
    });

    test(
        'les gardes perceptuelles n\'étouffent aucun type de piège : '
        'chaque TrapKind reste présent sur 500 items', () {
      final seen = <TrapKind>{};
      for (final item in allItems) {
        for (final o in item.options) {
          if (o.trapKind != null) seen.add(o.trapKind!);
        }
      }
      expect(seen, containsAll(TrapKind.values),
          reason: 'types manquants : '
              '${TrapKind.values.toSet().difference(seen)}');
    });
  });

  group('PuzzleGenerator — progression de difficulté', () {
    test('subtilité des pièges croissante de l\'item 1 à 26', () {
      expect(PuzzleGenerator.subtletyForItem(1), closeTo(0.05, 1e-9));
      expect(PuzzleGenerator.subtletyForItem(26), closeTo(0.95, 1e-9));
      for (int i = 1; i < 26; i++) {
        expect(PuzzleGenerator.subtletyForItem(i + 1),
            greaterThan(PuzzleGenerator.subtletyForItem(i)));
      }
    });

    test('items très faciles : aucune rotation d\'affichage', () {
      final items = PuzzleGenerator(seed: 5).generateComplete26Items();
      for (final item
          in items.where((i) => i.level == DifficultyLevel.veryEasy)) {
        for (final o in item.options) {
          expect(o.displayRotationDeg, 0.0,
              reason: 'item ${item.index} doit rester sans rotation');
        }
      }
    });

    test('items difficiles : des rotations apparaissent', () {
      final items = [
        for (int seed = 0; seed < 5; seed++)
          ...PuzzleGenerator(seed: seed).generateComplete26Items(),
      ];
      final hardRotations = items
          .where((i) => i.level == DifficultyLevel.hard)
          .expand((i) => i.options)
          .where((o) => o.displayRotationDeg != 0)
          .length;
      expect(hardRotations, greaterThan(0));
    });

    test('diversité : 2 générateurs sans seed produisent des items variés',
        () {
      final a = PuzzleGenerator(seed: 1).generateComplete26Items();
      final b = PuzzleGenerator(seed: 2).generateComplete26Items();
      int differing = 0;
      for (int i = 0; i < 26; i++) {
        if (a[i].baseShape != b[i].baseShape ||
            a[i].cutStrategy != b[i].cutStrategy) {
          differing++;
        }
      }
      expect(differing, greaterThan(8));
    });
  });

  group('Géométrie — congruence', () {
    test('un polygone est congruent à sa rotation', () {
      const square = Polygon([
        Offset(0, 0),
        Offset(0.4, 0),
        Offset(0.4, 0.4),
        Offset(0, 0.4),
      ]);
      final rotated = square.transform(rotationDeg: 90);
      expect(congruent(square, rotated), isTrue);
    });

    test('un polygone n\'est pas congruent à sa version agrandie', () {
      const square = Polygon([
        Offset(0, 0),
        Offset(0.4, 0),
        Offset(0.4, 0.4),
        Offset(0, 0.4),
      ]);
      final scaled = square.transform(scale: 1.15);
      expect(congruent(square, scaled), isFalse);
    });

    test('miroir détecté uniquement avec allowMirror', () {
      const tri = Polygon([
        Offset(0, 0),
        Offset(0.5, 0),
        Offset(0, 0.3),
      ]);
      final mirrored = tri.transform(mirrored: true);
      expect(congruent(tri, mirrored), isFalse);
      expect(congruent(tri, mirrored, allowMirror: true), isTrue);
    });
  });
}
