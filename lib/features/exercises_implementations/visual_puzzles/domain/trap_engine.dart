import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'geometry.dart';

/// Types de pièges, ordonnés par subtilité croissante (du plus visible
/// au plus subtil).
enum TrapKind {
  /// Pièce totalement différente (random polygon) — ÉNORME.
  random,

  /// Une autre pièce correcte mais miroir horizontal — visible sur asymétrique.
  mirror,

  /// Rotation 180° — visible sur asymétrique.
  rotate180,

  /// Rotation 90° — visible sur la plupart des shapes.
  rotate90,

  /// Scale ±20% (0.8 ou 1.2) — visible.
  scaleBig,

  /// Scale ±10% (0.9 ou 1.1) — subtil.
  scaleSubtle,

  /// 1 vertex décalé de 8-12% — subtil.
  vertexNudgeMedium,

  /// 1 vertex décalé de 3-5% — très subtil.
  vertexNudgeSmall,
}

/// Génère des distracteurs (pièges) à partir des vraies pièces.
///
/// Selon la difficulté, le pool de pièges varie :
///   - veryEasy : random + rotate180 (TRÈS visibles)
///   - easy : mirror + rotate180 + scaleBig
///   - medium : rotate90 + scaleBig + vertexNudgeMedium
///   - hard : vertexNudgeMedium + vertexNudgeSmall + scaleSubtle (très subtils)
class TrapEngine {
  TrapEngine({math.Random? rng}) : _rng = rng ?? math.Random();

  final math.Random _rng;

  /// Génère un piège du type demandé, à partir d'une vraie pièce de référence.
  Polygon apply(Polygon source, TrapKind kind) {
    switch (kind) {
      case TrapKind.random:
        return _randomShape(source);
      case TrapKind.mirror:
        return source.transform(mirrored: true);
      case TrapKind.rotate180:
        return source.transform(rotationDeg: 180);
      case TrapKind.rotate90:
        return source.transform(rotationDeg: _rng.nextBool() ? 90 : -90);
      case TrapKind.scaleBig:
        return source.transform(scale: _rng.nextBool() ? 0.78 : 1.22);
      case TrapKind.scaleSubtle:
        return source.transform(scale: _rng.nextBool() ? 0.9 : 1.1);
      case TrapKind.vertexNudgeMedium:
        return _nudgeRandomVertex(source, 0.08, 0.12);
      case TrapKind.vertexNudgeSmall:
        return _nudgeRandomVertex(source, 0.03, 0.05);
    }
  }

  /// Polygone aléatoire : forme étoile ou triangle aléatoire dans le bbox.
  Polygon _randomShape(Polygon source) {
    final bb = source.bbox();
    final c = bb.center;
    final r = math.min(bb.width, bb.height) / 2;
    final sides = 3 + _rng.nextInt(5); // 3..7
    final verts = <Offset>[];
    for (int i = 0; i < sides; i++) {
      final ang = 2 * math.pi * i / sides + _rng.nextDouble() * 0.4;
      final rad = r * (0.6 + _rng.nextDouble() * 0.4);
      verts.add(Offset(c.dx + rad * math.cos(ang), c.dy + rad * math.sin(ang)));
    }
    return Polygon(verts);
  }

  Polygon _nudgeRandomVertex(Polygon source, double minRel, double maxRel) {
    if (source.vertices.isEmpty) return source;
    final bb = source.bbox();
    final scale = math.max(bb.width, bb.height);
    final idx = _rng.nextInt(source.vertices.length);
    final rel = minRel + _rng.nextDouble() * (maxRel - minRel);
    final ang = _rng.nextDouble() * 2 * math.pi;
    return source.withVertexNudged(idx, math.cos(ang) * rel * scale,
        math.sin(ang) * rel * scale);
  }
}
