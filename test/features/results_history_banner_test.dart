// Régression : « le lien d'affiliation n'est plus affiché dans Mes résultats ».
//
// La carte « Missions » (seul accès au lien d'invitation et à la progression)
// vivait DANS la liste des résultats. Quand la liste devenait vide — ce qui est
// arrivé dès que l'historique a été cloisonné par passe — l'écran « aucun
// résultat » s'affichait à la place et le lien devenait inatteignable.
//
// Invariant : tant que le verrou est actif, la liste (donc la carte Missions)
// est affichée, même sans aucun résultat.

import 'package:flutter_test/flutter_test.dart';

/// Réplique exacte de la condition d'aiguillage de ResultsHistoryPage.build.
/// Si cette règle change dans la page, ce test doit changer avec elle.
bool montreEcranAucunResultat({
  required bool listeVide,
  required bool verrouille,
}) =>
    listeVide && !verrouille;

bool montreCarteMissions({
  required bool listeVide,
  required bool verrouille,
}) =>
    verrouille &&
    !montreEcranAucunResultat(listeVide: listeVide, verrouille: verrouille);

void main() {
  group('accès aux missions depuis « Mes résultats »', () {
    test('LE BUG : verrouillé SANS résultat → la carte Missions reste visible',
        () {
      expect(montreCarteMissions(listeVide: true, verrouille: true), isTrue);
      expect(
          montreEcranAucunResultat(listeVide: true, verrouille: true), isFalse);
    });

    test('verrouillé AVEC résultats → carte Missions + résultats floutés', () {
      expect(montreCarteMissions(listeVide: false, verrouille: true), isTrue);
      expect(montreEcranAucunResultat(listeVide: false, verrouille: true),
          isFalse);
    });

    test('déverrouillé SANS résultat → écran « aucun résultat », pas de carte',
        () {
      expect(montreEcranAucunResultat(listeVide: true, verrouille: false),
          isTrue);
      expect(montreCarteMissions(listeVide: true, verrouille: false), isFalse);
    });

    test('déverrouillé AVEC résultats → résultats seuls, pas de carte', () {
      expect(montreEcranAucunResultat(listeVide: false, verrouille: false),
          isFalse);
      expect(montreCarteMissions(listeVide: false, verrouille: false), isFalse);
    });
  });
}
