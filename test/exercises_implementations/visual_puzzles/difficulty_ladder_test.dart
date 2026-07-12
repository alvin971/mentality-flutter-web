// Invariants de l'échelle de difficulté des Puzzles Visuels (kLadder).
//
// L'échelle encode les RADICAUX de chaque item — si un invariant casse ici,
// c'est la comparabilité des passations entre patients qui casse.

import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/features/exercises_implementations/visual_puzzles/domain/puzzle_generator.dart';

void main() {
  group('kLadder', () {
    test('26 recettes, paliers 1→8 contigus aux effectifs attendus', () {
      expect(kLadder.length, 26);
      final expectedPaliers = [
        1, 1, 1, 1, // P1 items 1-4
        2, 2, 2, // P2 items 5-7
        3, 3, 3, // P3 items 8-10
        4, 4, 4, 4, // P4 items 11-14
        5, 5, 5, // P5 items 15-17
        6, 6, 6, // P6 items 18-20
        7, 7, 7, // P7 items 21-23
        8, 8, 8, // P8 items 24-26
      ];
      expect(kLadder.map((r) => r.palier).toList(), expectedPaliers);
    });

    test('temps WAIS : 20 s pour les items 1-7, 30 s ensuite', () {
      for (int i = 0; i < kLadder.length; i++) {
        expect(kLadder[i].timeLimitSeconds, i < 7 ? 20 : 30,
            reason: 'item ${i + 1}');
      }
    });

    test('subtilité strictement croissante sur toute l\'échelle', () {
      for (int i = 1; i < kLadder.length; i++) {
        expect(kLadder[i].subtlety, greaterThan(kLadder[i - 1].subtlety),
            reason: 'item ${i + 1} vs $i');
      }
    });

    test('budget de jumeaux décroissant : 3 (P1) → 0 (P7-P8)', () {
      for (int i = 1; i < kLadder.length; i++) {
        expect(kLadder[i].maxTwins, lessThanOrEqualTo(kLadder[i - 1].maxTwins),
            reason: 'item ${i + 1}');
      }
      expect(kLadder.first.maxTwins, 3);
      for (final r in kLadder.where((r) => r.palier >= 7)) {
        expect(r.maxTwins, 0);
      }
    });

    test('rotations minimales croissantes, diagonales à partir de P5', () {
      for (int i = 1; i < kLadder.length; i++) {
        expect(kLadder[i].minRotatedPieces,
            greaterThanOrEqualTo(kLadder[i - 1].minRotatedPieces),
            reason: 'item ${i + 1}');
      }
      for (final r in kLadder) {
        final hasDiagonals = r.rotationAngles.any((a) => a % 90 != 0);
        if (r.palier < 5) {
          expect(hasDiagonals, isFalse,
              reason: 'P${r.palier} ne doit pas avoir d\'angles diagonaux');
          expect(r.minDiagonalPieces, 0);
        } else {
          expect(hasDiagonals, isTrue,
              reason: 'P${r.palier} doit proposer des angles diagonaux');
          expect(r.minDiagonalPieces, greaterThanOrEqualTo(1));
        }
        // Les minimums doivent être satisfiables sur 3 pièces.
        expect(r.minRotatedPieces, lessThanOrEqualTo(3));
        expect(r.minDiagonalPieces, lessThanOrEqualTo(r.minRotatedPieces));
      }
    });

    test('monochrome uniquement en P7-P8 ; placement déterministe', () {
      for (int i = 0; i < kLadder.length; i++) {
        final r = kLadder[i];
        if (r.colorMode == ColorMode.monochrome) {
          expect(r.palier, greaterThanOrEqualTo(7),
              reason: 'item ${i + 1} monochrome hors P7-P8');
        }
      }
      // 1 monochrome sur 3 en P7, 2 sur 3 en P8 (mêmes positions pour tous).
      expect(
          kLadder
              .where((r) =>
                  r.palier == 7 && r.colorMode == ColorMode.monochrome)
              .length,
          1);
      expect(
          kLadder
              .where((r) =>
                  r.palier == 8 && r.colorMode == ColorMode.monochrome)
              .length,
          2);
    });

    test('cohérence des slots de pièges avec le palier', () {
      for (int i = 0; i < kLadder.length; i++) {
        final r = kLadder[i];
        final kinds = r.trapSlots.expand((s) => s).toSet();
        // alternativeCut réservé aux paliers ≥ 5 (trop dur avant).
        if (r.palier < 5) {
          expect(kinds.contains(TrapKind.alternativeCut), isFalse,
              reason: 'item ${i + 1} : alternativeCut interdit avant P5');
        }
        // wrongColors impossible sans budget de jumeau (géométrie d'une
        // vraie pièce par construction) et sans couleurs.
        if (r.maxTwins == 0 || r.colorMode == ColorMode.monochrome) {
          expect(kinds.contains(TrapKind.wrongColors), isFalse,
              reason: 'item ${i + 1} : wrongColors sans jumeau/couleurs');
        }
        expect(r.trapSlots.length, 3, reason: 'item ${i + 1}');
      }
    });
  });
}
