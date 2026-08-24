// lib/core/services/subtest_progress_store.dart
//
// L'EXERCICE EN COURS — pour que la pause puisse tomber n'importe quand.
//
// Jusqu'ici un exercice n'existait qu'une fois TERMINÉ : `flushSubtest` n'est
// appelé que par `_showFinalResults`. Quitter au milieu de Mémoire des Chiffres
// ne laissait donc aucune trace, ni en local ni en base, et la reprise rejouait
// l'exercice entier depuis son premier item. Tout le travail déjà fourni était
// perdu, sans un mot.
//
// Ce magasin garde l'état du seul exercice en cours — la batterie n'en présente
// jamais deux à la fois. Lecture SYNCHRONE : les pages d'exercice le consultent
// depuis `initState`, où l'on ne peut pas attendre.
import 'dart:async' show unawaited;
import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import 'results_sync.dart';
import 'subtest_instrumentation.dart';

/// Où en est l'exercice interrompu.
class SubtestProgress {
  const SubtestProgress({
    required this.subtest,
    required this.itemIndex,
    required this.score,
    required this.items,
    this.etat = const {},
  });

  /// Code WAIS-IV stable de l'exercice (`digit_span`, jamais son libellé).
  final String subtest;

  /// Rang du PROCHAIN item à présenter. C'est un point de reprise, pas un
  /// compteur d'items faits — les deux coïncident tant qu'aucun item n'est
  /// sauté, et diverger silencieusement serait pire que de le dire.
  final int itemIndex;

  /// Score accumulé jusque-là, pour les exercices que l'app note encore.
  final int score;

  /// Mesures par item déjà collectées, telles que `SubtestInstrumentation`
  /// les produit.
  final List<Map<String, dynamic>> items;

  /// État PROPRE à l'exercice, qu'un rang générique ne peut pas porter.
  ///
  /// Mémoire des Chiffres, par exemple, enchaîne trois parties (ordre direct,
  /// inverse, croissant) avec un score et un compteur d'échecs par partie :
  /// reprendre au bon endroit exige de restituer tout cela. Chaque page décide
  /// de son contenu ; le magasin ne fait que le transporter.
  final Map<String, dynamic> etat;

  Map<String, dynamic> toJson() => {
        'subtest': subtest,
        'itemIndex': itemIndex,
        'score': score,
        'items': items,
        if (etat.isNotEmpty) 'etat': etat,
      };

  static SubtestProgress? fromJson(Map<String, dynamic> j) {
    final code = j['subtest'];
    final index = j['itemIndex'];
    if (code is! String || code.isEmpty || index is! int || index < 0) return null;
    return SubtestProgress(
      subtest: code,
      itemIndex: index,
      score: j['score'] is int ? j['score'] as int : 0,
      items: [
        for (final e in (j['items'] as List? ?? const []))
          if (e is Map) Map<String, dynamic>.from(e),
      ],
      etat: j['etat'] is Map
          ? Map<String, dynamic>.from(j['etat'] as Map)
          : const {},
    );
  }
}

class SubtestProgressStore {
  SubtestProgressStore._();
  static final SubtestProgressStore instance = SubtestProgressStore._();

  static const String _boxName = 'subtest_progress';
  static const String _key = 'current_v1';

  Box? _box;

  Future<void> initialize({HiveCipher? encryptionCipher}) async {
    _box = await Hive.openBox(_boxName, encryptionCipher: encryptionCipher);
  }

  /// L'exercice interrompu, ou `null`. Synchrone à dessein : appelé depuis
  /// `initState`, qui ne peut pas attendre.
  SubtestProgress? enCours() {
    final brut = _box?.get(_key);
    if (brut is! String || brut.isEmpty) return null;
    try {
      return SubtestProgress.fromJson(
          jsonDecode(brut) as Map<String, dynamic>);
    } catch (_) {
      // Format changé, coffre abîmé : on repart de l'exercice entier plutôt
      // que d'échouer. Une reprise ratée ne doit jamais bloquer le bilan.
      return null;
    }
  }

  /// Celui de [subtest] uniquement — évite qu'un exercice reprenne l'état d'un
  /// autre si le magasin n'a pas été purgé.
  SubtestProgress? pour(String subtest) {
    final p = enCours();
    return (p != null && p.subtest == subtest) ? p : null;
  }

  /// À appeler après CHAQUE item : pose le point de reprise en local, et
  /// pousse l'état vers le serveur de temps en temps.
  ///
  /// Le local à chaque item parce qu'il ne coûte rien ; le serveur seulement
  /// tous les [_tousLesNItems] parce qu'une requête par item ferait une
  /// cinquantaine d'allers-retours par exercice pour un gain nul — la file
  /// d'envoi est elle-même persistée, donc rien ne se perd entre deux.
  Future<void> jalon({
    required String subtest,
    required int prochainItem,
    required int score,
    required SubtestInstrumentation instr,
    Map<String, dynamic> etat = const {},
  }) async {
    await save(SubtestProgress(
      subtest: subtest,
      itemIndex: prochainItem,
      score: score,
      items: instr.itemsBruts,
      etat: etat,
    ));
    if (instr.itemCount % _tousLesNItems == 0) {
      unawaited(ResultsSync.instance.flushSubtest(
        instr.toPayload(partial: true, resumeItemIndex: prochainItem),
      ));
    }
  }

  static const int _tousLesNItems = 3;

  Future<void> save(SubtestProgress p) async {
    try {
      await _box?.put(_key, jsonEncode(p.toJson()));
    } catch (_) {/* la passation continue sans point de reprise */}
  }

  /// À appeler dès qu'un exercice est TERMINÉ : il n'y a plus rien à reprendre,
  /// et laisser l'état en place le ferait reprendre au milieu la fois suivante.
  Future<void> clear() async {
    try {
      await _box?.delete(_key);
    } catch (_) {/* sans conséquence */}
  }
}
