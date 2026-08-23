// lib/core/services/subtest_instrumentation.dart
//
// Mesure, item par item, ce qu'un score brut ne dit pas : combien de temps la
// personne a hésité avant de commencer, combien de fois elle s'est reprise,
// si elle a quitté l'écran. Ces signaux sont le matériau de la calibration et
// du contrôle de plausibilité — un score seul ne distingue pas une réponse
// trouvée en deux secondes d'une réponse arrachée en trois minutes.
//
// TOUS LES TEMPS SONT RELATIFS À L'ITEM, en millisecondes. Jamais d'horodatage
// mural : `test_sessions.completed_on` est délibérément une DATE, et y adjoindre
// des timestamps fins rouvrirait la corrélation temporelle qu'on a fermée.
// Un offset dit COMMENT la personne a répondu, jamais QUAND elle a passé le test.
//
// Ce que cette classe ne fait PAS, volontairement : capter les frappes une à une.
// Les intervalles entre frappes sont une signature biométrique — ils
// permettraient de reconnaître la même personne d'un token à l'autre, donc de
// défaire l'anonymat que le reste de l'architecture construit. Les agrégats
// ci-dessous portent l'essentiel du signal cognitif sans ce coût. Le flux brut a
// sa table séparée (`test_events`), à n'alimenter qu'après arbitrage explicite.
//
// Usage dans une page d'exercice :
//   final _instr = SubtestInstrumentation('vocabulary');
//   _instr.startItem(index: i, itemId: item.id);          // à l'affichage
//   _instr.onInput(previous: avant, current: apres);      // dans onChanged
//   _instr.endItem(response: saisie, isCorrect: ok, score: 2);
//   ... puis, en fin de sous-test : _instr.toPayload()
class SubtestInstrumentation {
  SubtestInstrumentation(this.subtest);

  final String subtest;
  final List<Map<String, dynamic>> _items = [];

  Stopwatch? _chrono;
  int? _index;
  String? _itemId;
  int? _firstInputMs;
  int _edits = 0;
  int _backspaces = 0;
  int _focusLost = 0;

  /// À appeler quand l'item devient visible et actionnable.
  void startItem({required int index, String? itemId}) {
    _chrono = Stopwatch()..start();
    _index = index;
    _itemId = itemId;
    _firstInputMs = null;
    _edits = 0;
    _backspaces = 0;
    _focusLost = 0;
  }

  /// À appeler à chaque modification de la réponse.
  ///
  /// [previous] et [current] servent uniquement à distinguer un ajout d'un
  /// retour arrière — le CONTENU n'est ni conservé ni transmis ici.
  void onInput({String previous = '', String current = ''}) {
    final c = _chrono;
    if (c == null) return;
    _firstInputMs ??= c.elapsedMilliseconds;
    _edits++;
    if (current.length < previous.length) _backspaces++;
  }

  /// À appeler quand l'app passe en arrière-plan ou perd le focus.
  void onFocusLost() => _focusLost++;

  /// Clôt l'item courant. Sans [startItem] préalable, ne fait rien.
  ///
  /// [latencyMs] permet d'imposer la durée quand l'exercice la mesure lui-même.
  /// C'est le cas des épreuves de construction (Cubes) : l'item s'ouvre dans un
  /// widget enfant et ne revient à la page qu'une fois terminé, si bien que le
  /// chronomètre local mesurerait zéro. Sans cette porte, la latence de ces
  /// exercices serait fausse — et une latence fausse est pire qu'absente,
  /// puisqu'elle entrerait telle quelle dans la calibration.
  void endItem({
    String? response,
    bool? isCorrect,
    int? score,
    int? latencyMs,
    bool timedOut = false,
    bool skipped = false,
  }) {
    final c = _chrono;
    if (c == null || _index == null) return;
    c.stop();
    _items.add(<String, dynamic>{
      'index': _index,
      if (_itemId != null) 'itemId': _itemId,
      if (response != null) 'response': response,
      if (isCorrect != null) 'isCorrect': isCorrect,
      if (score != null) 'score': score,
      'latencyMs': latencyMs ?? c.elapsedMilliseconds,
      if (_firstInputMs != null) 'firstInputMs': _firstInputMs,
      'editsCount': _edits,
      'backspacesCount': _backspaces,
      'focusLostCount': _focusLost,
      if (timedOut) 'timedOut': true,
      if (skipped) 'skipped': true,
    });
    _chrono = null;
    _index = null;
  }

  int get itemCount => _items.length;

  /// Latence médiane, pour `test_results.median_latency_ms`.
  int? get medianLatencyMs {
    final l = _items
        .map((e) => e['latencyMs'] as int?)
        .whereType<int>()
        .toList()
      ..sort();
    if (l.isEmpty) return null;
    return l.length.isOdd
        ? l[l.length ~/ 2]
        : ((l[l.length ~/ 2 - 1] + l[l.length ~/ 2]) / 2).round();
  }

  /// Bloc `subtests[]` attendu par `UnlockService.uploadTestResults`.
  Map<String, dynamic> toPayload({int? rawScore, int? maxScore}) =>
      <String, dynamic>{
        'subtest': subtest,
        if (rawScore != null) 'rawScore': rawScore,
        if (maxScore != null) 'maxScore': maxScore,
        'itemsAdministered': _items.length,
        'itemsCorrect': _items.where((e) => e['isCorrect'] == true).length,
        if (medianLatencyMs != null) 'medianLatencyMs': medianLatencyMs,
        'items': List<Map<String, dynamic>>.unmodifiable(_items),
      };
}
