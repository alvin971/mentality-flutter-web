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
  // Énoncés par langue ajoutés en Phase 2 (null = repli vers l'anglais).
  final String? es;
  final String? pt;
  final String? de;
  final String? enGB;
  const ArithTemplate(this.kind, this.fr, this.en,
      {this.es, this.pt, this.de, this.enGB});

  /// Énoncé pour le tag de langue de contenu, avec repli vers EN puis FR.
  String text(String tag) {
    switch (tag) {
      case 'fr':
        return fr;
      case 'en':
        return en;
      case 'en-GB':
        return enGB ?? en;
      case 'es':
        return es ?? en;
      case 'pt':
        return pt ?? en;
      case 'de':
        return de ?? en;
      default:
        return en;
    }
  }
}

/// Templates regroupés par bande de difficulté :
/// index 0 = easy, 1 = medium, 2 = hard, 3 = veryHard.
List<List<ArithTemplate>> arithmeticTemplatesByBand() => const [
      // ===================== EASY (add, sub) =====================
      [
        ArithTemplate(ArithKind.add, 'Marie a {a} billes et en gagne {b}. Combien en a-t-elle en tout ?', 'Marie has {a} marbles and wins {b} more. How many does she have in total?', es: 'María tiene {a} canicas y gana {b} más. ¿Cuántas tiene en total?', pt: 'A Maria tem {a} berlindes e ganha mais {b}. Quantos tem ao todo?', de: 'Marie hat {a} Murmeln und gewinnt {b} weitere dazu. Wie viele hat sie insgesamt?', enGB: 'Marie has {a} marbles and wins {b} more. How many does she have altogether?'),
        ArithTemplate(ArithKind.add, 'Dans un panier il y a {a} pommes. On en ajoute {b}. Combien y a-t-il de pommes ?', 'A basket has {a} apples. {b} more are added. How many apples are there?', es: 'En una cesta hay {a} manzanas. Se añaden {b} más. ¿Cuántas manzanas hay?', pt: 'Num cesto há {a} maçãs. Juntam-se mais {b}. Quantas maçãs há?', de: 'In einem Korb liegen {a} Äpfel. Es werden {b} weitere hinzugefügt. Wie viele Äpfel sind es jetzt?', enGB: 'A basket has {a} apples. {b} more are added. How many apples are there?'),
        ArithTemplate(ArithKind.add, 'Combien font {a} plus {b} ?', 'What is {a} plus {b}?', es: '¿Cuánto es {a} más {b}?', pt: 'Quanto é {a} mais {b}?', de: 'Was ergibt {a} plus {b}?', enGB: 'What is {a} plus {b}?'),
        ArithTemplate(ArithKind.sub, 'Paul avait {a} bonbons et en mange {b}. Combien lui en reste-t-il ?', 'Paul had {a} candies and eats {b}. How many are left?', es: 'Pablo tenía {a} caramelos y se come {b}. ¿Cuántos le quedan?', pt: 'O Paulo tinha {a} rebuçados e come {b}. Quantos lhe restam?', de: 'Paul hatte {a} Bonbons und isst {b} davon. Wie viele hat er noch übrig?', enGB: 'Paul had {a} sweets and eats {b}. How many are left?'),
        ArithTemplate(ArithKind.sub, 'Il y a {a} oiseaux sur un arbre, {b} s\'envolent. Combien en reste-t-il ?', 'There are {a} birds in a tree; {b} fly away. How many remain?', es: 'Hay {a} pájaros en un árbol; {b} salen volando. ¿Cuántos quedan?', pt: 'Há {a} pássaros numa árvore; {b} vão-se embora a voar. Quantos ficam?', de: 'Auf einem Baum sitzen {a} Vögel; {b} fliegen weg. Wie viele bleiben?', enGB: 'There are {a} birds in a tree; {b} fly away. How many remain?'),
        ArithTemplate(ArithKind.sub, 'Combien font {a} moins {b} ?', 'What is {a} minus {b}?', es: '¿Cuánto es {a} menos {b}?', pt: 'Quanto é {a} menos {b}?', de: 'Was ergibt {a} minus {b}?', enGB: 'What is {a} minus {b}?'),
      ],
      // ===================== MEDIUM (add, sub, mul, div) =====================
      [
        ArithTemplate(ArithKind.add, 'Un livre coûte {a} euros et un stylo {b} euros. Combien coûtent-ils ensemble ?', 'A book costs {a} euros and a pen {b} euros. How much do they cost together?', es: 'Un libro cuesta {a} € y un bolígrafo {b} €. ¿Cuánto cuestan juntos?', pt: 'Um livro custa {a} € e uma caneta {b} €. Quanto custam os dois juntos?', de: 'Ein Buch kostet {a} € und ein Stift {b} €. Wie viel kosten beide zusammen?', enGB: 'A book costs £{a} and a pen costs £{b}. How much do they cost altogether?'),
        ArithTemplate(ArithKind.add, 'Combien font {a} plus {b} ?', 'What is {a} plus {b}?', es: '¿Cuánto es {a} más {b}?', pt: 'Quanto é {a} mais {b}?', de: 'Was ergibt {a} plus {b}?', enGB: 'What is {a} plus {b}?'),
        ArithTemplate(ArithKind.sub, 'Un réservoir contient {a} litres ; on en retire {b}. Combien reste-t-il ?', 'A tank holds {a} liters; {b} are removed. How many liters remain?', es: 'Un depósito contiene {a} litros; se extraen {b}. ¿Cuántos litros quedan?', pt: 'Um reservatório tem {a} litros; retiram-se {b}. Quantos litros ficam?', de: 'Ein Tank enthält {a} Liter; {b} Liter werden entnommen. Wie viele Liter verbleiben?', enGB: 'A tank holds {a} litres; {b} are removed. How many litres remain?'),
        ArithTemplate(ArithKind.sub, 'Combien font {a} moins {b} ?', 'What is {a} minus {b}?', es: '¿Cuánto es {a} menos {b}?', pt: 'Quanto é {a} menos {b}?', de: 'Was ergibt {a} minus {b}?', enGB: 'What is {a} minus {b}?'),
        ArithTemplate(ArithKind.mul, 'Une boîte contient {b} œufs. Combien d\'œufs dans {a} boîtes ?', 'A box holds {b} eggs. How many eggs are in {a} boxes?', es: 'Una caja contiene {b} huevos. ¿Cuántos huevos hay en {a} cajas?', pt: 'Uma caixa tem {b} ovos. Quantos ovos há em {a} caixas?', de: 'Eine Schachtel enthält {b} Eier. Wie viele Eier sind in {a} Schachteln?', enGB: 'A box holds {b} eggs. How many eggs are in {a} boxes?'),
        ArithTemplate(ArithKind.mul, 'Combien font {a} fois {b} ?', 'What is {a} times {b}?', es: '¿Cuánto es {a} por {b}?', pt: 'Quanto é {a} vezes {b}?', de: 'Was ergibt {a} mal {b}?', enGB: 'What is {a} times {b}?'),
        ArithTemplate(ArithKind.mul, 'Un billet coûte {b} euros. Combien coûtent {a} billets ?', 'A ticket costs {b} euros. How much do {a} tickets cost?', es: 'Una entrada cuesta {b} €. ¿Cuánto cuestan {a} entradas?', pt: 'Um bilhete custa {b} €. Quanto custam {a} bilhetes?', de: 'Eine Eintrittskarte kostet {b} €. Wie viel kosten {a} Eintrittskarten?', enGB: 'A ticket costs £{b}. How much do {a} tickets cost?'),
        ArithTemplate(ArithKind.div, 'On partage {dividend} bonbons entre {divisor} enfants. Combien chacun en reçoit-il ?', '{dividend} candies are shared equally among {divisor} children. How many does each get?', es: 'Se reparten {dividend} caramelos entre {divisor} niños. ¿Cuántos recibe cada uno?', pt: 'Distribuem-se {dividend} rebuçados por {divisor} crianças em partes iguais. Quantos recebe cada uma?', de: '{dividend} Bonbons werden gleichmäßig auf {divisor} Kinder verteilt. Wie viele bekommt jedes Kind?', enGB: '{dividend} sweets are shared equally among {divisor} children. How many does each child get?'),
        ArithTemplate(ArithKind.div, 'Combien font {dividend} divisé par {divisor} ?', 'What is {dividend} divided by {divisor}?', es: '¿Cuánto es {dividend} dividido entre {divisor}?', pt: 'Quanto é {dividend} dividido por {divisor}?', de: 'Was ergibt {dividend} geteilt durch {divisor}?', enGB: 'What is {dividend} divided by {divisor}?'),
        ArithTemplate(ArithKind.div, '{dividend} fleurs sont réparties en {divisor} bouquets égaux. Combien de fleurs par bouquet ?', '{dividend} flowers are split into {divisor} equal bouquets. How many flowers per bouquet?', es: '{dividend} flores se distribuyen en {divisor} ramos iguales. ¿Cuántas flores hay por ramo?', pt: '{dividend} flores são distribuídas em {divisor} ramos iguais. Quantas flores há em cada ramo?', de: '{dividend} Blumen werden auf {divisor} gleich große Sträuße verteilt. Wie viele Blumen hat jeder Strauß?', enGB: '{dividend} flowers are arranged into {divisor} equal bouquets. How many flowers are in each bouquet?'),
      ],
      // ===================== HARD (mul, div, percent) =====================
      [
        ArithTemplate(ArithKind.mul, 'Une salle a {a} rangées de {b} chaises. Combien de chaises au total ?', 'A room has {a} rows of {b} chairs. How many chairs in total?', es: 'Una sala tiene {a} filas de {b} sillas. ¿Cuántas sillas hay en total?', pt: 'Uma sala tem {a} filas de {b} cadeiras. Quantas cadeiras há ao todo?', de: 'Ein Saal hat {a} Reihen mit je {b} Stühlen. Wie viele Stühle gibt es insgesamt?', enGB: 'A hall has {a} rows of {b} chairs. How many chairs are there in total?'),
        ArithTemplate(ArithKind.mul, 'Combien font {a} fois {b} ?', 'What is {a} times {b}?', es: '¿Cuánto es {a} por {b}?', pt: 'Quanto é {a} vezes {b}?', de: 'Was ergibt {a} mal {b}?', enGB: 'What is {a} times {b}?'),
        ArithTemplate(ArithKind.div, 'Combien font {dividend} divisé par {divisor} ?', 'What is {dividend} divided by {divisor}?', es: '¿Cuánto es {dividend} dividido entre {divisor}?', pt: 'Quanto é {dividend} dividido por {divisor}?', de: 'Was ergibt {dividend} geteilt durch {divisor}?', enGB: 'What is {dividend} divided by {divisor}?'),
        ArithTemplate(ArithKind.div, 'Une usine produit {dividend} pièces en {divisor} jours. Combien de pièces par jour ?', 'A factory makes {dividend} parts in {divisor} days. How many parts per day?', es: 'Una fábrica produce {dividend} piezas en {divisor} días. ¿Cuántas piezas produce al día?', pt: 'Uma fábrica produz {dividend} peças em {divisor} dias. Quantas peças produz por dia?', de: 'Eine Fabrik stellt {dividend} Teile in {divisor} Tagen her. Wie viele Teile werden pro Tag produziert?', enGB: 'A factory produces {dividend} parts in {divisor} days. How many parts does it make per day?'),
        ArithTemplate(ArithKind.percent, 'Combien font {percent} % de {whole} ?', 'What is {percent}% of {whole}?', es: '¿Cuánto es el {percent} % de {whole}?', pt: 'Quanto é {percent}% de {whole}?', de: 'Wie viel sind {percent} % von {whole}?', enGB: 'What is {percent}% of {whole}?'),
        ArithTemplate(ArithKind.percent, 'Un article à {whole} euros est réduit de {percent} %. Quel est le montant de la réduction ?', 'An item priced {whole} euros is reduced by {percent}%. What is the discount amount?', es: 'Un artículo que cuesta {whole} € tiene un descuento del {percent} %. ¿Cuál es el importe del descuento?', pt: 'Um artigo que custa {whole} € é reduzido em {percent}%. Qual é o valor do desconto?', de: 'Ein Artikel kostet {whole} € und wird um {percent} % reduziert. Wie hoch ist der Rabattbetrag?', enGB: 'An item priced at £{whole} is reduced by {percent}%. What is the amount of the discount?'),
        ArithTemplate(ArithKind.percent, 'Dans une classe de {whole} élèves, {percent} % font du sport. Combien d\'élèves ?', 'In a class of {whole} students, {percent}% play sports. How many students is that?', es: 'En una clase de {whole} alumnos, el {percent} % practica deporte. ¿Cuántos alumnos son?', pt: 'Numa turma de {whole} alunos, {percent}% praticam desporto. Quantos alunos são?', de: 'In einer Klasse mit {whole} Schülern treiben {percent} % Sport. Wie viele Schüler sind das?', enGB: 'In a class of {whole} pupils, {percent}% play sport. How many pupils is that?'),
        ArithTemplate(ArithKind.mul, 'Un cahier a {b} pages. Combien de pages dans {a} cahiers ?', 'A notebook has {b} pages. How many pages in {a} notebooks?', es: 'Un cuaderno tiene {b} páginas. ¿Cuántas páginas tienen {a} cuadernos?', pt: 'Um caderno tem {b} páginas. Quantas páginas têm {a} cadernos?', de: 'Ein Heft hat {b} Seiten. Wie viele Seiten haben {a} Hefte?', enGB: 'A notebook has {b} pages. How many pages are in {a} notebooks?'),
      ],
      // ===================== VERYHARD (percent, twoStep) =====================
      [
        ArithTemplate(ArithKind.percent, 'Combien font {percent} % de {whole} ?', 'What is {percent}% of {whole}?', es: '¿Cuánto es el {percent} % de {whole}?', pt: 'Quanto é {percent}% de {whole}?', de: 'Wie viel sind {percent} % von {whole}?', enGB: 'What is {percent}% of {whole}?'),
        ArithTemplate(ArithKind.percent, 'Un capital de {whole} euros rapporte {percent} % d\'intérêts. Combien d\'intérêts ?', 'A capital of {whole} euros earns {percent}% interest. How much interest is that?', es: 'Un capital de {whole} € genera un interés del {percent} %. ¿Cuánto interés produce?', pt: 'Um capital de {whole} € rende {percent}% de juros. Quanto são os juros?', de: 'Ein Kapital von {whole} € wirft {percent} % Zinsen ab. Wie viel Zinsen sind das?', enGB: 'A sum of £{whole} earns {percent}% interest. How much interest does it earn?'),
        ArithTemplate(ArithKind.twoStep, 'Un magasin vend {a} cartons de {b} bouteilles, plus {c} bouteilles à l\'unité. Combien de bouteilles en tout ?', 'A shop sells {a} cases of {b} bottles, plus {c} single bottles. How many bottles in total?', es: 'Una tienda vende {a} cajas de {b} botellas, más {c} botellas sueltas. ¿Cuántas botellas hay en total?', pt: 'Uma loja vende {a} caixas de {b} garrafas, mais {c} garrafas avulsas. Quantas garrafas há ao todo?', de: 'Ein Geschäft verkauft {a} Kartons mit je {b} Flaschen sowie {c} Einzelflaschen. Wie viele Flaschen sind es insgesamt?', enGB: 'A shop sells {a} crates of {b} bottles, plus {c} individual bottles. How many bottles are there in total?'),
        ArithTemplate(ArithKind.twoStep, 'Marie achète {a} paquets de {b} stylos et reçoit {c} stylos en cadeau. Combien de stylos a-t-elle ?', 'Marie buys {a} packs of {b} pens and gets {c} pens as a gift. How many pens does she have?', es: 'María compra {a} paquetes de {b} bolígrafos y recibe {c} bolígrafos de regalo. ¿Cuántos bolígrafos tiene?', pt: 'A Maria compra {a} embalagens de {b} canetas e recebe {c} canetas de oferta. Quantas canetas tem?', de: 'Marie kauft {a} Packungen mit je {b} Stiften und bekommt {c} Stifte geschenkt. Wie viele Stifte hat sie?', enGB: 'Marie buys {a} packs of {b} pens and receives {c} pens as a gift. How many pens does she have?'),
        ArithTemplate(ArithKind.twoStep, 'Un théâtre a {a} rangées de {b} sièges, plus {c} strapontins. Combien de places au total ?', 'A theater has {a} rows of {b} seats, plus {c} folding seats. How many seats in total?', es: 'Un teatro tiene {a} filas de {b} asientos, más {c} butacas plegables. ¿Cuántos asientos hay en total?', pt: 'Um teatro tem {a} filas de {b} lugares, mais {c} lugares rebatíveis. Quantos lugares há ao todo?', de: 'Ein Theater hat {a} Reihen mit je {b} Sitzen sowie {c} Klappsitze. Wie viele Plätze gibt es insgesamt?', enGB: 'A theatre has {a} rows of {b} seats, plus {c} folding seats. How many seats are there in total?'),
        ArithTemplate(ArithKind.percent, 'Sur {whole} candidats, {percent} % réussissent l\'examen. Combien réussissent ?', 'Of {whole} candidates, {percent}% pass the exam. How many pass?', es: 'De {whole} candidatos, el {percent} % aprueba el examen. ¿Cuántos aprueban?', pt: 'De {whole} candidatos, {percent}% passam no exame. Quantos passam?', de: 'Von {whole} Bewerbern bestehen {percent} % die Prüfung. Wie viele bestehen?', enGB: 'Out of {whole} candidates, {percent}% pass the exam. How many pass?'),
      ],
    ];
