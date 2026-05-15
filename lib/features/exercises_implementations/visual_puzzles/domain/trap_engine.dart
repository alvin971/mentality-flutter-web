import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'geometry.dart';

/// Génère des distracteurs (pièces piège) à partir d'une vraie pièce.
///
/// L'API centrale est `distract(source, similarity)` : `similarity ∈ [0, 1]`
/// contrôle à quel point le distracteur ressemble à la pièce d'origine.
///
///   similarity = 0.95  → 1 sommet décalé de ~3% (très subtil)
///   similarity = 0.80  → 1 sommet décalé ~8% / scale ±5%
///   similarity = 0.65  → 2 sommets décalés ~12% / scale ±10%
///   similarity = 0.50  → rotation 15-25° / scale ±15%
///   similarity = 0.35  → rotation 45° / mirror sur asymétrique
///   similarity = 0.20  → mirror + rotation / déformation forte
///   similarity = 0.05  → polygone aléatoire (totalement différent)
///
/// La progression de similarité au sein du test (item 1 → item 26) rend
/// le test progressivement plus difficile : au début, les distracteurs sont
/// faciles à éliminer ; à la fin, ils sont presque indistinguables.
class TrapEngine {
  TrapEngine({math.Random? rng}) : _rng = rng ?? math.Random();
  final math.Random _rng;

  /// Génère un distracteur du polygone `source` avec un niveau de similarité.
  /// `similarity` est clampé dans [0.05, 0.95].
  Polygon distract(Polygon source, double similarity) {
    final s = similarity.clamp(0.05, 0.95);

    if (s > 0.88) {
      // Très subtil : 1 sommet à 2-5% du bbox
      return _nudgeVertices(source, count: 1, minRel: 0.02, maxRel: 0.05);
    }
    if (s > 0.75) {
      // Subtil : 1 sommet à 5-10% OU scale ±4%
      if (_rng.nextBool()) {
        return _nudgeVertices(source, count: 1, minRel: 0.05, maxRel: 0.10);
      }
      return source.transform(scale: _rng.nextBool() ? 0.96 : 1.04);
    }
    if (s > 0.60) {
      // Moyen : 2 sommets à 8-15% OU scale ±8%
      if (_rng.nextBool()) {
        return _nudgeVertices(source, count: 2, minRel: 0.08, maxRel: 0.15);
      }
      return source.transform(scale: _rng.nextBool() ? 0.92 : 1.08);
    }
    if (s > 0.45) {
      // Visible : rotation 12-25° OU scale ±15% OU 3 vertex nudge
      final choice = _rng.nextInt(3);
      if (choice == 0) {
        return source.transform(rotationDeg: (_rng.nextBool() ? 1 : -1) * (12 + _rng.nextDouble() * 13));
      }
      if (choice == 1) {
        return source.transform(scale: _rng.nextBool() ? 0.85 : 1.15);
      }
      return _nudgeVertices(source, count: 3, minRel: 0.10, maxRel: 0.18);
    }
    if (s > 0.30) {
      // Très visible : rotation 45-60° OU mirror sur asymétrique
      if (_rng.nextBool()) {
        return source.transform(rotationDeg: (_rng.nextBool() ? 1 : -1) * (45.0 + _rng.nextDouble() * 15));
      }
      return source.transform(mirrored: true, rotationDeg: 15);
    }
    if (s > 0.15) {
      // Très différent : mirror + rotation 90° OU déformation forte
      if (_rng.nextBool()) {
        return source.transform(mirrored: true, rotationDeg: 90);
      }
      return _heavyDeformation(source);
    }
    // s ≤ 0.15 : polygone aléatoire complet
    return _randomShape(source.bbox());
  }

  Polygon _nudgeVertices(Polygon source,
      {required int count, required double minRel, required double maxRel}) {
    if (source.vertices.isEmpty) return source;
    final bb = source.bbox();
    final scale = math.max(bb.width, bb.height);
    var current = source;
    final indices = List<int>.generate(source.vertices.length, (i) => i)
      ..shuffle(_rng);
    for (int i = 0; i < count && i < indices.length; i++) {
      final idx = indices[i];
      final rel = minRel + _rng.nextDouble() * (maxRel - minRel);
      final ang = _rng.nextDouble() * 2 * math.pi;
      current = current.withVertexNudged(
        idx,
        math.cos(ang) * rel * scale,
        math.sin(ang) * rel * scale,
      );
    }
    return current;
  }

  /// Déforme fortement : nudge 4-6 sommets à 15-25%.
  Polygon _heavyDeformation(Polygon source) {
    return _nudgeVertices(source,
        count: math.min(source.vertices.length, 4 + _rng.nextInt(3)),
        minRel: 0.15,
        maxRel: 0.25);
  }

  /// Polygone totalement aléatoire dans le bbox (étoile 3-7 branches).
  Polygon _randomShape(Rect bb) {
    final c = bb.center;
    final r = math.min(bb.width, bb.height) / 2;
    final sides = 3 + _rng.nextInt(5);
    final verts = <Offset>[];
    for (int i = 0; i < sides; i++) {
      final ang = 2 * math.pi * i / sides + _rng.nextDouble() * 0.4;
      final rad = r * (0.55 + _rng.nextDouble() * 0.45);
      verts.add(Offset(c.dx + rad * math.cos(ang), c.dy + rad * math.sin(ang)));
    }
    return Polygon(verts);
  }
}
