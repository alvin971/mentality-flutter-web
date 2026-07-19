// Régression du BLOQUANT trouvé par l'audit d'états : au dernier palier, le
// bouton « Confirmer mon follow » était totalement inerte dès que le serveur
// refusait la saisie (regex `^[A-Za-z0-9._]{1,30}$`). Aucun message, aucun
// changement d'état : l'utilisateur tapait indéfiniment sans savoir pourquoi.
//
// Deux défenses testées ici :
//  1. la saisie est NORMALISÉE (URL de profil, « @ », espaces) — le cas le plus
//     courant devient valide au lieu d'être refusé ;
//  2. ce qui reste invalide est détecté AVANT l'appel réseau, donc affichable.

import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/features/unlock/presentation/pages/unlock_gate_page.dart';

/// Miroir du format accepté par workers/referral (handleInstagram).
final _serveur = RegExp(r'^[A-Za-z0-9._]{1,30}$');

String norm(String s) => normalizeInstagramHandle(s);

void main() {
  group('normalisation du pseudo Instagram', () {
    test('les saisies courantes deviennent un pseudo valide', () {
      const attendu = 'mental_e.t';
      for (final saisie in <String>[
        'mental_e.t',
        '@mental_e.t',
        '  @mental_e.t  ',
        '@@mental_e.t',
        'instagram.com/mental_e.t',
        'www.instagram.com/mental_e.t',
        'https://instagram.com/mental_e.t',
        'https://www.instagram.com/mental_e.t/',
        'https://www.instagram.com/mental_e.t?hl=fr',
        'HTTPS://WWW.INSTAGRAM.COM/mental_e.t',
      ]) {
        final n = norm(saisie);
        expect(n, attendu, reason: 'saisie : « $saisie »');
        expect(_serveur.hasMatch(n), isTrue,
            reason: 'le serveur doit accepter « $n »');
      }
    });

    test('les saisies réellement invalides restent détectables localement', () {
      for (final saisie in <String>[
        '', '   ', '@', 'pseudo avec espaces', 'accentué', 'tiret-interdit',
        'a' * 31,
      ]) {
        expect(_serveur.hasMatch(norm(saisie)), isFalse,
            reason: 'devrait être rejeté AVANT le réseau : « $saisie »');
      }
    });

    test('un pseudo déjà propre n\'est pas altéré', () {
      expect(norm('abc'), 'abc');
      expect(norm('a.b_c123'), 'a.b_c123');
    });

    test('la longueur maximale du serveur est respectée', () {
      expect(_serveur.hasMatch(norm('a' * 30)), isTrue);
      expect(_serveur.hasMatch(norm('a' * 31)), isFalse);
    });
  });
}
