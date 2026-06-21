/// Bibliothèque de TEMPLATES d'énoncés du sous-test Arithmétique (WAIS-IV).
///
/// Chaque template est un « moule à trous » bilingue (FR/EN). Le générateur
/// tire des opérandes aléatoires dans des plages dépendant de la bande de
/// difficulté, remplit les tokens, puis CALCULE la réponse par code (aucune
/// réponse n'est écrite à la main). La variété = templates × combinaisons
/// d'opérandes → des millions de problèmes distincts.
///
/// Tokens autorisés par [ArithKind] (à respecter STRICTEMENT) :
/// - add / sub / mul : {a} et {b}
/// - div            : {dividend} et {divisor}  (réponse = dividend / divisor)
/// - percent        : {percent} et {whole}     (réponse = percent % de whole)
/// - twoStep        : {a}, {b}, {c}            (réponse = a × b + c)
enum ArithKind { add, sub, mul, div, percent, twoStep }

class ArithTemplate {
  final ArithKind kind;
  final String fr;
  final String en;
  const ArithTemplate(this.kind, this.fr, this.en);
}

/// Templates regroupés par bande de difficulté :
/// index 0 = easy, 1 = medium, 2 = hard, 3 = veryHard.
List<List<ArithTemplate>> arithmeticTemplatesByBand() => const [
      // ===================== EASY (add, sub) =====================
      [
        ArithTemplate(ArithKind.add,
            'Marie a {a} billes et en gagne {b}. Combien en a-t-elle en tout ?',
            'Marie has {a} marbles and wins {b} more. How many does she have in total?'),
        ArithTemplate(ArithKind.add,
            'Dans un panier il y a {a} pommes. On en ajoute {b}. Combien y a-t-il de pommes ?',
            'A basket has {a} apples. {b} more are added. How many apples are there?'),
        ArithTemplate(ArithKind.add, 'Combien font {a} plus {b} ?',
            'What is {a} plus {b}?'),
        ArithTemplate(ArithKind.sub,
            'Paul avait {a} bonbons et en mange {b}. Combien lui en reste-t-il ?',
            'Paul had {a} candies and eats {b}. How many are left?'),
        ArithTemplate(ArithKind.sub,
            'Il y a {a} oiseaux sur un arbre, {b} s\'envolent. Combien en reste-t-il ?',
            'There are {a} birds in a tree; {b} fly away. How many remain?'),
        ArithTemplate(ArithKind.sub, 'Combien font {a} moins {b} ?',
            'What is {a} minus {b}?'),
      ],
      // ===================== MEDIUM (add, sub, mul, div) =====================
      [
        ArithTemplate(ArithKind.add,
            'Un livre coûte {a} euros et un stylo {b} euros. Combien coûtent-ils ensemble ?',
            'A book costs {a} euros and a pen {b} euros. How much do they cost together?'),
        ArithTemplate(ArithKind.add, 'Combien font {a} plus {b} ?',
            'What is {a} plus {b}?'),
        ArithTemplate(ArithKind.sub,
            'Un réservoir contient {a} litres ; on en retire {b}. Combien reste-t-il ?',
            'A tank holds {a} liters; {b} are removed. How many liters remain?'),
        ArithTemplate(ArithKind.sub, 'Combien font {a} moins {b} ?',
            'What is {a} minus {b}?'),
        ArithTemplate(ArithKind.mul,
            'Une boîte contient {b} œufs. Combien d\'œufs dans {a} boîtes ?',
            'A box holds {b} eggs. How many eggs are in {a} boxes?'),
        ArithTemplate(ArithKind.mul, 'Combien font {a} fois {b} ?',
            'What is {a} times {b}?'),
        ArithTemplate(ArithKind.mul,
            'Un billet coûte {b} euros. Combien coûtent {a} billets ?',
            'A ticket costs {b} euros. How much do {a} tickets cost?'),
        ArithTemplate(ArithKind.div,
            'On partage {dividend} bonbons entre {divisor} enfants. Combien chacun en reçoit-il ?',
            '{dividend} candies are shared equally among {divisor} children. How many does each get?'),
        ArithTemplate(ArithKind.div, 'Combien font {dividend} divisé par {divisor} ?',
            'What is {dividend} divided by {divisor}?'),
        ArithTemplate(ArithKind.div,
            '{dividend} fleurs sont réparties en {divisor} bouquets égaux. Combien de fleurs par bouquet ?',
            '{dividend} flowers are split into {divisor} equal bouquets. How many flowers per bouquet?'),
      ],
      // ===================== HARD (mul, div, percent) =====================
      [
        ArithTemplate(ArithKind.mul,
            'Une salle a {a} rangées de {b} chaises. Combien de chaises au total ?',
            'A room has {a} rows of {b} chairs. How many chairs in total?'),
        ArithTemplate(ArithKind.mul, 'Combien font {a} fois {b} ?',
            'What is {a} times {b}?'),
        ArithTemplate(ArithKind.div, 'Combien font {dividend} divisé par {divisor} ?',
            'What is {dividend} divided by {divisor}?'),
        ArithTemplate(ArithKind.div,
            'Une usine produit {dividend} pièces en {divisor} jours. Combien de pièces par jour ?',
            'A factory makes {dividend} parts in {divisor} days. How many parts per day?'),
        ArithTemplate(ArithKind.percent, 'Combien font {percent} % de {whole} ?',
            'What is {percent}% of {whole}?'),
        ArithTemplate(ArithKind.percent,
            'Un article à {whole} euros est réduit de {percent} %. Quel est le montant de la réduction ?',
            'An item priced {whole} euros is reduced by {percent}%. What is the discount amount?'),
        ArithTemplate(ArithKind.percent,
            'Dans une classe de {whole} élèves, {percent} % font du sport. Combien d\'élèves ?',
            'In a class of {whole} students, {percent}% play sports. How many students is that?'),
        ArithTemplate(ArithKind.mul,
            'Un cahier a {b} pages. Combien de pages dans {a} cahiers ?',
            'A notebook has {b} pages. How many pages in {a} notebooks?'),
      ],
      // ===================== VERYHARD (percent, twoStep) =====================
      [
        ArithTemplate(ArithKind.percent, 'Combien font {percent} % de {whole} ?',
            'What is {percent}% of {whole}?'),
        ArithTemplate(ArithKind.percent,
            'Un capital de {whole} euros rapporte {percent} % d\'intérêts. Combien d\'intérêts ?',
            'A capital of {whole} euros earns {percent}% interest. How much interest is that?'),
        ArithTemplate(ArithKind.twoStep,
            'Un magasin vend {a} cartons de {b} bouteilles, plus {c} bouteilles à l\'unité. Combien de bouteilles en tout ?',
            'A shop sells {a} cases of {b} bottles, plus {c} single bottles. How many bottles in total?'),
        ArithTemplate(ArithKind.twoStep,
            'Marie achète {a} paquets de {b} stylos et reçoit {c} stylos en cadeau. Combien de stylos a-t-elle ?',
            'Marie buys {a} packs of {b} pens and gets {c} pens as a gift. How many pens does she have?'),
        ArithTemplate(ArithKind.twoStep,
            'Un théâtre a {a} rangées de {b} sièges, plus {c} strapontins. Combien de places au total ?',
            'A theater has {a} rows of {b} seats, plus {c} folding seats. How many seats in total?'),
        ArithTemplate(ArithKind.percent,
            'Sur {whole} candidats, {percent} % réussissent l\'examen. Combien réussissent ?',
            'Of {whole} candidates, {percent}% pass the exam. How many pass?'),
      ],
    ];
