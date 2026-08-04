// La partie entière — cinq délais, quatre choix chacun, et rien d'autre.
//
// Ce type est PUR et IMMUABLE : chaque réponse rend une nouvelle partie. Toute
// la logique du jeu tient donc hors de l'écran et se vérifie sans monter le
// moindre widget ; l'écran, lui, ne garde qu'une seule variable.
//
// Les réglages du paradigme vivent ICI et non dans `data/` : ce ne sont pas des
// contenus mais la forme même de la mesure. `DelayChoiceMaterial` ne porte que
// ce qui s'affiche — libellés de délai en six langues et écriture des montants.
//
// ═══ L'ORDRE DES DÉLAIS EST TIRÉ AU SORT ═══
//
// Les cinq délais ne sont pas posés du plus court au plus long. Présentés dans
// l'ordre croissant, ils dessinent une pente que l'on suit sans plus y penser
// (« à une semaine j'ai dit oui, donc là je dis non ») : on répondrait alors à
// une progression, pas à des offres. Un ordre tiré au sort casse la pente.
//
// La monotonie vérifiée ensuite ([DelayChoiceScore.isMonotone]) porte sur les
// points d'indifférence RANGÉS PAR DÉLAI, jamais sur l'ordre de présentation :
// mélanger les questions ne mélange pas la courbe.
//
// ═══ SEMÉE, DONC REJOUABLE À L'IDENTIQUE ═══
//
// Un test qui vérifie l'ordre des délais ou l'alternance des positions a besoin
// d'une partie reproductible. La graine est injectable, et une partie rejouée
// la respecte — sans quoi le second tour d'un test deviendrait indéterminé.

import 'dart:math';

import '../models/delay_choice_offer.dart';
import 'delay_choice_staircase.dart';

class DelayChoiceRun {
  const DelayChoiceRun._({
    required this.stairs,
    required this.immediateOnTop,
    required this.answered,
  });

  /// La somme différée, identique pour tous les délais et toute la partie.
  ///
  /// Le nombre lui-même n'a rien de sacré ; ce qui compte est qu'il reste FIXE
  /// pendant que l'immédiat s'ajuste, et qu'il se divise proprement en quatre
  /// pas entiers (75 → 38 → 19 → 10 → 5).
  static const int delayedAmount = 150;

  /// Les cinq délais interrogés, en jours : une semaine, un mois, trois mois,
  /// six mois, un an.
  ///
  /// Ils sont espacés géométriquement plutôt que régulièrement parce que la
  /// préférence s'effondre vite au début puis se stabilise : cinq points
  /// équidistants sur l'année passeraient à côté de toute la partie intéressante
  /// de la courbe, qui se joue dans les premières semaines.
  static const List<int> delaysDays = [7, 30, 90, 180, 365];

  /// Choix posés par délai. Quatre suffisent à ramener l'incertitude sur le
  /// point d'indifférence à ±5 sur 150, soit environ 3 %. Un cinquième
  /// gagnerait 2 points de précision et coûterait cinq questions de plus —
  /// un quart de partie pour un raffinement qu'aucun affichage n'utilise.
  static const int stepsPerDelay = 4;

  /// Longueur maximale d'une série de positions identiques.
  static const int maxSameSideRun = 3;

  /// Ouvre une partie : un escalier par délai, dans un ordre tiré de [seed].
  factory DelayChoiceRun.start({required int seed}) {
    final alea = Random(seed);
    final delais = [...delaysDays]..shuffle(alea);
    return DelayChoiceRun._(
      stairs: [
        for (final jours in delais)
          DelayChoiceStaircase.start(
            delayDays: jours,
            delayedAmount: delayedAmount,
            answers: stepsPerDelay,
          ),
      ],
      immediateOnTop: _positions(alea, delais.length * stepsPerDelay),
      answered: 0,
    );
  }

  /// Un escalier par délai, dans l'ordre de présentation.
  final List<DelayChoiceStaircase> stairs;

  /// Où s'affiche l'offre immédiate, essai par essai. Fixé à l'ouverture : la
  /// position d'un essai ne doit pas changer si l'écran se reconstruit.
  final List<bool> immediateOnTop;

  /// Choix déjà posés, tous délais confondus.
  final int answered;

  int get totalTrials => immediateOnTop.length;

  bool get isDone => answered >= totalTrials;

  /// L'escalier en cours. Les délais sont traités l'un après l'autre : on
  /// termine les quatre choix d'un délai avant de passer au suivant.
  int get _stairIndex => answered ~/ stepsPerDelay;

  /// L'offre à afficher, ou `null` quand la partie est finie.
  DelayChoiceOffer? get offer {
    if (isDone) return null;
    final escalier = stairs[_stairIndex];
    return DelayChoiceOffer(
      immediateAmount: escalier.immediateAmount,
      delayedAmount: escalier.delayedAmount,
      delayDays: escalier.delayDays,
      immediateOnTop: immediateOnTop[answered],
    );
  }

  /// Enregistre un choix et rend la partie suivante.
  DelayChoiceRun answer(bool tookImmediate) {
    assert(!isDone, 'réponse de trop sur une partie terminée');
    final index = _stairIndex;
    return DelayChoiceRun._(
      stairs: [
        for (var i = 0; i < stairs.length; i++)
          i == index ? stairs[i].answer(tookImmediate) : stairs[i],
      ],
      immediateOnTop: immediateOnTop,
      answered: answered + 1,
    );
  }

  /// Les points d'indifférence des délais TERMINÉS, rangés par délai croissant.
  /// Une partie abandonnée en rend donc moins de cinq — et l'écran de résultat
  /// n'en calcule rien (voir [DelayChoiceScore.minDelays]).
  Map<int, int> get indifferencePoints {
    final finis = stairs.where((e) => e.isDone).toList()
      ..sort((a, b) => a.delayDays.compareTo(b.delayDays));
    return {for (final e in finis) e.delayDays: e.indifferenceAmount};
  }

  /// Autant de « en haut » que de « en bas », mélangés, et jamais plus de
  /// [maxSameSideRun] d'affilée.
  ///
  /// L'urne équilibrée borne le déséquilibre d'ensemble ; la contrainte de
  /// série borne les paquets. Sans la seconde, un tirage parfaitement équilibré
  /// peut encore aligner huit fois « en haut » puis huit fois « en bas » — et
  /// l'habitude de doigt que l'alternance devait empêcher se réinstalle sur
  /// chaque moitié.
  ///
  /// Le tirage est REJOUÉ plutôt que corrigé après coup : déplacer l'élément
  /// fautif introduirait un biais de position systématique, invisible et bien
  /// pire que quelques tirages perdus. Un plafond d'essais garde la fonction
  /// terminante ; le dernier tirage est rendu tel quel.
  static List<bool> _positions(Random alea, int count) {
    final urne = [for (var i = 0; i < count; i++) i.isEven];
    var tirage = [...urne];
    for (var essai = 0; essai < 50; essai++) {
      tirage = [...urne]..shuffle(alea);
      if (!_aUneSerieTropLongue(tirage)) return tirage;
    }
    return tirage;
  }

  static bool _aUneSerieTropLongue(List<bool> positions) {
    var serie = 1;
    for (var i = 1; i < positions.length; i++) {
      serie = positions[i] == positions[i - 1] ? serie + 1 : 1;
      if (serie > maxSameSideRun) return true;
    }
    return false;
  }
}
