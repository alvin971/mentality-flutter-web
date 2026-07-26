// Machine à états du palier 3 : autorité serveur et migration des lignes KV.
//
// Réplique Dart de `buildProgressResponse()` de workers/referral/index.js.
// Même parti pris que unlock_authority_test.dart : pas de mock HTTP, pas de
// worker simulé — la règle est réécrite ici, lisiblement, et confrontée à des
// cas nommés. Si la règle change dans le worker, ce fichier doit changer avec.
//
// Ce qui est verrouillé ici :
//   · 3→4 ne se produit QUE par écoulement du délai côté serveur ;
//   · un déblocage acquis (stage 4) n'est jamais repris ;
//   · les trois cas de migration des lignes déjà en production ;
//   · l'ancre du délai n'est posée qu'une seule fois ;
//   · la dérivation du nombre de jours annoncé.

import 'package:flutter_test/flutter_test.dart';

/// Ligne KV `progress:<account>`, réduite à ce qui pilote les paliers.
class Ligne {
  Ligne({
    required this.stage,
    this.stage3StartedAt,
    this.unlockedAt,
    this.instagramSubmittedAt,
  });

  int stage;
  String? stage3StartedAt;
  String? unlockedAt;

  /// Champ HÉRITÉ, présent uniquement sur les lignes antérieures à la purge.
  String? instagramSubmittedAt;
}

/// État renvoyé au client, en plus des mutations appliquées à la ligne.
typedef Reponse = ({int stage, int secondsRemaining, String? unlockAt});

bool _isValidIso(String? s) => s != null && DateTime.tryParse(s) != null;

/// Réplique de `buildProgressResponse` (workers/referral/index.js).
Reponse avancer(
  Ligne row, {
  required int filleulsTermines,
  required int requis,
  required int delaiMinutes,
  required DateTime maintenant,
}) {
  // (a) Le stage 4 est DÉFINITIF : rien n'est recalculé au-delà.
  if (row.stage < 4) {
    if (row.stage < 3 && filleulsTermines >= requis) {
      row.stage = 3;
    }
    // Point d'ancrage unique — le garde `!_isValidIso` en assure l'unicité.
    if (row.stage == 3 && !_isValidIso(row.stage3StartedAt)) {
      row.stage3StartedAt = _isValidIso(row.instagramSubmittedAt)
          ? row.instagramSubmittedAt
          : maintenant.toIso8601String();
    }
    if (row.stage == 3) {
      final debut = DateTime.parse(row.stage3StartedAt!);
      if (!maintenant.difference(debut).isNegative &&
          maintenant.difference(debut).inMilliseconds >= delaiMinutes * 60000) {
        row.stage = 4;
        row.unlockedAt = maintenant.toIso8601String();
      }
    }
  }

  if (row.stage == 3) {
    final fin = DateTime.parse(row.stage3StartedAt!)
        .add(Duration(minutes: delaiMinutes));
    final restantMs = fin.difference(maintenant).inMilliseconds;
    return (
      stage: row.stage,
      secondsRemaining: restantMs <= 0 ? 0 : (restantMs / 1000).ceil(),
      unlockAt: fin.toIso8601String(),
    );
  }
  return (stage: row.stage, secondsRemaining: 0, unlockAt: row.unlockedAt);
}

/// Réplique de `delayConfig()` (workers/referral/index.js).
({int displayDelayDays, bool debugDelayOverride}) configDelai({
  required int minutes,
  int? debugJours,
}) {
  if (debugJours != null && debugJours >= 0) {
    return (displayDelayDays: debugJours, debugDelayOverride: true);
  }
  // Arrondi AU SUPÉRIEUR : le nombre de jours annoncé ne doit jamais être
  // inférieur au délai réel, sinon il contredit le compteur affiché en dessous.
  return (
    displayDelayDays: (minutes / 1440).ceil(),
    debugDelayOverride: false,
  );
}

const _t0 = '2026-07-26T12:00:00.000Z';
const _huitJoursMin = 11520;

void main() {
  final t0 = DateTime.parse(_t0);

  group('autorité serveur sur le passage 3→4', () {
    test('le parrainage seul ne débloque jamais : il ouvre l\'attente', () {
      final row = Ligne(stage: 1);
      final r = avancer(row,
          filleulsTermines: 3,
          requis: 3,
          delaiMinutes: _huitJoursMin,
          maintenant: t0);
      expect(r.stage, 3, reason: 'promu au palier d\'attente, pas débloqué');
      expect(row.stage3StartedAt, t0.toIso8601String());
      expect(r.secondsRemaining, _huitJoursMin * 60);
    });

    test('à une seconde du terme, TOUJOURS verrouillé', () {
      final row = Ligne(stage: 3, stage3StartedAt: _t0);
      final r = avancer(row,
          filleulsTermines: 3,
          requis: 3,
          delaiMinutes: _huitJoursMin,
          maintenant: t0
              .add(const Duration(minutes: _huitJoursMin))
              .subtract(const Duration(seconds: 1)));
      expect(r.stage, 3);
      expect(r.secondsRemaining, 1);
    });

    test('à l\'échéance exacte, débloqué', () {
      final row = Ligne(stage: 3, stage3StartedAt: _t0);
      final r = avancer(row,
          filleulsTermines: 3,
          requis: 3,
          delaiMinutes: _huitJoursMin,
          maintenant: t0.add(const Duration(minutes: _huitJoursMin)));
      expect(r.stage, 4);
      expect(row.unlockedAt, isNotNull);
      expect(r.secondsRemaining, 0);
    });

    test('HORLOGE CLIENT MANIPULÉE : le serveur ne bouge pas', () {
      // L'utilisateur avance la date de son téléphone de 10 jours. Le serveur
      // calcule sur SA propre horloge : la ligne reste au stage 3 et le client,
      // qui n'a pas d'autre autorité, reste verrouillé.
      final row = Ligne(stage: 3, stage3StartedAt: _t0);
      final r = avancer(row,
          filleulsTermines: 3,
          requis: 3,
          delaiMinutes: _huitJoursMin,
          maintenant: t0.add(const Duration(hours: 1)));
      expect(r.stage, 3, reason: 'seule l\'horloge du serveur compte');
      expect(r.secondsRemaining, greaterThan(0));
    });
  });

  group('un déblocage acquis ne se reprend jamais', () {
    test('stage 4 survit à la perte des filleuls ET à un retour en arrière',
        () {
      final row = Ligne(stage: 4, stage3StartedAt: _t0, unlockedAt: _t0);
      final r = avancer(row,
          filleulsTermines: 0, // les filleuls ont disparu
          requis: 3,
          delaiMinutes: _huitJoursMin,
          maintenant: t0.subtract(const Duration(days: 30)));
      expect(r.stage, 4);
      expect(row.unlockedAt, _t0, reason: 'pas ré-horodaté');
    });
  });

  group('migration des lignes déjà en production', () {
    test('(a) stage 4 avec un vieil horodatage Instagram : intacte', () {
      final row = Ligne(
          stage: 4, unlockedAt: _t0, instagramSubmittedAt: '2026-01-01T00:00:00.000Z');
      final r = avancer(row,
          filleulsTermines: 3,
          requis: 3,
          delaiMinutes: _huitJoursMin,
          maintenant: t0);
      expect(r.stage, 4);
      expect(row.stage3StartedAt, isNull,
          reason: 'aucune ancre posée sur une ligne déjà débloquée');
    });

    test('(b) stage 3 : l\'attente déjà écoulée n\'est PAS perdue', () {
      // 7 jours d'attente déjà faits sur un délai de 8 : il en reste 1.
      final il7Jours = t0.subtract(const Duration(days: 7));
      final row = Ligne(
          stage: 3, instagramSubmittedAt: il7Jours.toIso8601String());
      final r = avancer(row,
          filleulsTermines: 3,
          requis: 3,
          delaiMinutes: _huitJoursMin,
          maintenant: t0);
      expect(row.stage3StartedAt, il7Jours.toIso8601String(),
          reason: 'l\'ancien horodatage devient l\'ancre');
      expect(r.stage, 3);
      expect(r.secondsRemaining, const Duration(days: 1).inSeconds);
    });

    test('(b bis) attente héritée déjà dépassée : débloqué immédiatement', () {
      final il9Jours = t0.subtract(const Duration(days: 9));
      final row = Ligne(
          stage: 3, instagramSubmittedAt: il9Jours.toIso8601String());
      final r = avancer(row,
          filleulsTermines: 3,
          requis: 3,
          delaiMinutes: _huitJoursMin,
          maintenant: t0);
      expect(r.stage, 4);
    });

    test('(c) stage 3 sans rien : l\'ancre est posée à la première lecture', () {
      final row = Ligne(stage: 3);
      final r = avancer(row,
          filleulsTermines: 3,
          requis: 3,
          delaiMinutes: _huitJoursMin,
          maintenant: t0);
      expect(row.stage3StartedAt, t0.toIso8601String());
      expect(r.stage, 3);
      expect(r.secondsRemaining, _huitJoursMin * 60,
          reason: 'le délai complet, pas un délai tronqué');
    });

    test('l\'ancre n\'est posée QU\'UNE FOIS', () {
      final row = Ligne(stage: 3);
      avancer(row,
          filleulsTermines: 3,
          requis: 3,
          delaiMinutes: _huitJoursMin,
          maintenant: t0);
      final ancre = row.stage3StartedAt;
      avancer(row,
          filleulsTermines: 3,
          requis: 3,
          delaiMinutes: _huitJoursMin,
          maintenant: t0.add(const Duration(hours: 1)));
      expect(row.stage3StartedAt, ancre,
          reason: 'sinon chaque consultation relancerait l\'attente à zéro');
    });
  });

  group('nombre de jours annoncé', () {
    test('dérivé du délai réel, arrondi au SUPÉRIEUR', () {
      final obtenu = {
        for (final m in [11520, 11521, 10080, 1, 0])
          m: configDelai(minutes: m).displayDelayDays,
      };
      expect(obtenu, {
        11520: 8, // 8 jours pile : aucune inflation sur la config nominale
        11521: 9, // une minute de plus → on annonce 9, jamais 8
        10080: 7,
        1: 1,
        0: 0,
      });
    });

    test('affichage et exécution ne divergent QUE par l\'override, signalé', () {
      final normal = configDelai(minutes: 1);
      expect(normal.displayDelayDays, 1);
      expect(normal.debugDelayOverride, isFalse);

      // Configuration de recette : 1 minute réelle, « 8 jours » affichés.
      final force = configDelai(minutes: 1, debugJours: 8);
      expect(force.displayDelayDays, 8);
      expect(force.debugDelayOverride, isTrue,
          reason: 'sans ce drapeau, la bannière MODE TEST ne s\'affiche pas '
              'et un délai de recette pourrait passer en production');
    });
  });
}
