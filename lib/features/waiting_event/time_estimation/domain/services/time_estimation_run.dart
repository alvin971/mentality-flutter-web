// La partie entière — vingt-quatre essais, un escalier, et rien d'autre.
//
// Ce type est PUR et IMMUABLE : chaque réponse rend une nouvelle partie. Toute la
// logique du jeu tient donc hors de l'écran et se vérifie sans monter le moindre
// widget ; l'écran ne garde qu'une variable et une minuterie.
//
// ═══ CE QUI EST TIRÉ D'AVANCE, ET CE QUI NE PEUT PAS L'ÊTRE ═══
//
// Les standards et les positions sont tirés à l'ouverture, d'une graine : ils ne
// dépendent d'aucune réponse, et les fixer à l'avance rend la partie
// reproductible pour un test.
//
// L'ÉCART, lui, ne peut pas être tiré d'avance — il dépend de ce qui vient d'être
// répondu. C'est toute la différence avec le jeu du délai, où l'escalier de
// chaque délai avance seul : ici un seul escalier traverse la partie, et l'essai
// à venir n'existe qu'une fois le précédent tranché.
//
// ═══ LES DEUX ÉQUILIBRAGES ═══
//
// · STANDARDS. Les quatre valeurs reviennent le même nombre de fois, sans série
//   de plus de deux. Sans quoi une partie où le standard le plus court domine se
//   comparerait à une partie où domine le plus long, et le seuil contiendrait la
//   différence entre les deux échelles de durée plutôt que la seule acuité.
// · POSITIONS. Autant de fois en premier qu'en second, sans série de plus de
//   trois. Une bonne réponse toujours du même côté se répondrait sans regarder.

import 'dart:math';

import '../models/duration_trial.dart';
import '../models/time_acuity_score.dart';
import 'time_staircase.dart';

class TimeEstimationRun {
  const TimeEstimationRun._({
    required this.standards,
    required this.comparisonFirst,
    required this.staircase,
    required this.answered,
    required this.correct,
  });

  /// Les quatre durées de référence, en millisecondes.
  ///
  /// Toutes de l'ordre de la seconde : au-dessus, l'attente devient pénible sur
  /// vingt-quatre essais ; en dessous de ~400 ms, l'écart le plus fin qu'on
  /// puisse afficher se réduit à un ou deux battements d'image et la mesure
  /// mesurerait surtout l'affichage.
  static const List<int> standardsMs = [600, 800, 1000, 1200];

  /// Nombre d'essais. Assez pour que l'escalier se pose (une descente rapide
  /// puis six à huit inversions), assez peu pour tenir dans deux minutes.
  static const int trials = 24;

  /// Longueur maximale d'une série du même standard.
  static const int maxStandardRun = 2;

  /// Longueur maximale d'une série de positions identiques.
  static const int maxSideRun = 3;

  /// Ouvre une partie ; [seed] fixe les standards et les positions.
  factory TimeEstimationRun.start({required int seed}) {
    final alea = Random(seed);
    return TimeEstimationRun._(
      standards: _standards(alea),
      comparisonFirst: _positions(alea),
      staircase: TimeStaircase.start(),
      answered: 0,
      correct: 0,
    );
  }

  /// La durée de référence de chaque essai, dans l'ordre.
  final List<int> standards;

  /// La position de la comparaison à chaque essai.
  final List<bool> comparisonFirst;

  /// L'escalier, unique pour toute la partie.
  final TimeStaircase staircase;

  final int answered;
  final int correct;

  bool get isDone => answered >= trials;

  /// L'essai à présenter, ou `null` quand la partie est finie.
  ///
  /// La comparaison est arrondie au-dessus du standard : sur un standard court
  /// et un écart au plancher, un arrondi ordinaire pourrait rendre les deux
  /// durées ÉGALES — l'essai n'aurait alors plus de bonne réponse, et la personne
  /// serait comptée fausse une fois sur deux pour une raison qui n'a rien à voir
  /// avec sa perception.
  DurationTrial? get trial {
    if (isDone) return null;
    final standard = standards[answered];
    final comparaison =
        max(standard + 1, (standard * (1 + staircase.delta)).round());
    return DurationTrial(
      standardMs: standard,
      comparisonMs: comparaison,
      comparisonFirst: comparisonFirst[answered],
    );
  }

  /// Enregistre une réponse (« le premier » ou non) et rend la partie suivante.
  TimeEstimationRun answer({required bool choseFirst}) {
    assert(!isDone, 'réponse de trop sur une partie terminée');
    final juste = trial!.isCorrect(choseFirst: choseFirst);
    return TimeEstimationRun._(
      standards: standards,
      comparisonFirst: comparisonFirst,
      staircase: staircase.answer(juste),
      answered: answered + 1,
      correct: correct + (juste ? 1 : 0),
    );
  }

  /// Le score de la partie, à tout moment.
  TimeAcuityScore get score => TimeAcuityScore(
        reversals: staircase.reversals,
        correctCount: correct,
        answeredCount: answered,
      );

  /// Les standards, équilibrés et sans longue série.
  static List<int> _standards(Random alea) {
    final urne = [
      for (var i = 0; i < trials; i++)
        standardsMs[i % standardsMs.length],
    ];
    return _melangerSansSerie(alea, urne, maxStandardRun);
  }

  /// Les positions, équilibrées et sans longue série.
  static List<bool> _positions(Random alea) {
    final urne = [for (var i = 0; i < trials; i++) i.isEven];
    return _melangerSansSerie(alea, urne, maxSideRun);
  }

  /// Mélange [urne] jusqu'à ce qu'aucune valeur n'y apparaisse plus de [maxRun]
  /// fois d'affilée.
  ///
  /// Le tirage est REJOUÉ plutôt que corrigé après coup : déplacer l'élément
  /// fautif introduirait un biais de position systématique, invisible et bien
  /// pire que quelques tirages perdus. Un plafond d'essais garde la fonction
  /// terminante ; le dernier tirage est rendu tel quel.
  static List<T> _melangerSansSerie<T>(Random alea, List<T> urne, int maxRun) {
    var tirage = [...urne];
    for (var essai = 0; essai < 50; essai++) {
      tirage = [...urne]..shuffle(alea);
      if (!_aUneSerieTropLongue(tirage, maxRun)) return tirage;
    }
    return tirage;
  }

  static bool _aUneSerieTropLongue<T>(List<T> valeurs, int maxRun) {
    var serie = 1;
    for (var i = 1; i < valeurs.length; i++) {
      serie = valeurs[i] == valeurs[i - 1] ? serie + 1 : 1;
      if (serie > maxRun) return true;
    }
    return false;
  }
}
