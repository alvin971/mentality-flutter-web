import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/features/exercises_implementations/figure_weights/domain/balance_generator.dart';

/// Tests de cohérence mathématique du générateur de Balances Quantitatives.
///
/// Pour chaque item, on vérifie que la bonne réponse est DÉDUCTIBLE des
/// balances affichées : la valeur de la question doit égaler la valeur de la
/// réponse pour TOUTE solution du système d'équations (pas seulement pour des
/// valeurs cachées arbitraires).
void main() {
  const seeds = 50;

  group('BalanceGenerator — invariants structurels', () {
    test('génère 27 items avec 4 options uniques contenant la réponse', () {
      for (int seed = 0; seed < seeds; seed++) {
        final items = BalanceGenerator(seed: seed).generateComplete27Items();
        expect(items.length, 27, reason: 'seed=$seed');

        for (int i = 0; i < items.length; i++) {
          final item = items[i];
          expect(item.options.length, 4, reason: 'seed=$seed item=$i');

          // La bonne réponse figure parmi les options
          expect(
            item.options.where((o) => _tokenListsEqual(o, item.correctAnswer)),
            isNotEmpty,
            reason: 'seed=$seed item=$i : réponse absente des options',
          );

          // Pas de doublons parmi les options
          for (int a = 0; a < item.options.length; a++) {
            for (int b = a + 1; b < item.options.length; b++) {
              expect(
                _tokenListsEqual(item.options[a], item.options[b]),
                isFalse,
                reason: 'seed=$seed item=$i : options $a et $b identiques',
              );
            }
          }
        }
      }
    });

    test('aucun jeton avec count <= 0 ni fraction hors (0,1]', () {
      for (int seed = 0; seed < seeds; seed++) {
        final items = BalanceGenerator(seed: seed).generateComplete27Items();
        for (int i = 0; i < items.length; i++) {
          final item = items[i];
          final allTokens = [
            ...item.correctAnswer,
            ...item.question.targetSide,
            for (final b in item.balances) ...b.leftSide,
            for (final b in item.balances) ...b.rightSide,
            for (final o in item.options) ...o,
          ];
          for (final t in allTokens) {
            expect(t.count, greaterThan(0),
                reason: 'seed=$seed item=$i : count=${t.count}');
            if (t.fraction != null) {
              expect(t.fraction, greaterThan(0),
                  reason: 'seed=$seed item=$i : fraction=${t.fraction}');
              expect(t.fraction, lessThanOrEqualTo(1),
                  reason: 'seed=$seed item=$i : fraction=${t.fraction}');
            }
          }
        }
      }
    });
  });

  group('BalanceGenerator — cohérence mathématique', () {
    test('la réponse est déductible des balances pour toute solution', () {
      for (int seed = 0; seed < seeds; seed++) {
        final items = BalanceGenerator(seed: seed).generateComplete27Items();
        for (int i = 0; i < items.length; i++) {
          final item = items[i];

          // Vecteur question − réponse : doit être dans l'espace ligne des
          // équations des balances (sinon la réponse dépend de valeurs
          // cachées non déductibles → item incohérent).
          final delta = _subtract(
            _sideVector(item.question.targetSide,
                difference: item.question.type == QuestionType.findDifference),
            _sideVector(item.correctAnswer),
          );

          final equations = [
            for (final b in item.balances)
              _subtract(_sideVector(b.leftSide), _sideVector(b.rightSide)),
          ];

          final nullBasis = _nullSpaceBasis(equations);
          for (final w in nullBasis) {
            final residual = _dot(delta, w).abs();
            expect(
              residual,
              lessThan(1e-6),
              reason: 'seed=$seed item=$i (θ=${item.thetaValue}) : la réponse '
                  'n\'est pas déterminée par les balances (résidu=$residual)',
            );
          }
        }
      }
    });
  });
}

// ===== Helpers =====

bool _tokenListsEqual(List<Token> a, List<Token> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i].shape != b[i].shape || a[i].count != b[i].count) return false;
    final f1 = a[i].fraction ?? 1.0;
    final f2 = b[i].fraction ?? 1.0;
    if ((f1 - f2).abs() > 0.001) return false;
  }
  return true;
}

/// Convertit un côté (liste de tokens) en vecteur de coefficients par forme.
/// Si [difference], le premier token est positif et les suivants négatifs
/// (convention des items findDifference : A − C).
List<double> _sideVector(List<Token> tokens, {bool difference = false}) {
  final v = List<double>.filled(TokenShape.values.length, 0);
  for (int i = 0; i < tokens.length; i++) {
    final t = tokens[i];
    final sign = (difference && i > 0) ? -1.0 : 1.0;
    v[t.shape.index] += sign * t.count * (t.fraction ?? 1.0);
  }
  return v;
}

List<double> _subtract(List<double> a, List<double> b) =>
    [for (int i = 0; i < a.length; i++) a[i] - b[i]];

double _dot(List<double> a, List<double> b) {
  double s = 0;
  for (int i = 0; i < a.length; i++) {
    s += a[i] * b[i];
  }
  return s;
}

/// Base de l'espace nul du système homogène (élimination de Gauss).
List<List<double>> _nullSpaceBasis(List<List<double>> rows) {
  final n = TokenShape.values.length;
  final m = [for (final r in rows) List<double>.from(r)];

  final pivotCols = <int>[];
  int row = 0;
  for (int col = 0; col < n && row < m.length; col++) {
    int pivot = -1;
    for (int r = row; r < m.length; r++) {
      if (m[r][col].abs() > 1e-9) {
        pivot = r;
        break;
      }
    }
    if (pivot == -1) continue;
    final tmp = m[row];
    m[row] = m[pivot];
    m[pivot] = tmp;

    final pv = m[row][col];
    for (int c = 0; c < n; c++) {
      m[row][c] /= pv;
    }
    for (int r = 0; r < m.length; r++) {
      if (r != row && m[r][col].abs() > 1e-9) {
        final factor = m[r][col];
        for (int c = 0; c < n; c++) {
          m[r][c] -= factor * m[row][c];
        }
      }
    }
    pivotCols.add(col);
    row++;
  }

  final freeCols = [
    for (int c = 0; c < n; c++)
      if (!pivotCols.contains(c)) c,
  ];

  final basis = <List<double>>[];
  for (final free in freeCols) {
    final v = List<double>.filled(n, 0);
    v[free] = 1;
    for (int r = 0; r < pivotCols.length; r++) {
      v[pivotCols[r]] = -m[r][free];
    }
    basis.add(v);
  }
  return basis;
}
