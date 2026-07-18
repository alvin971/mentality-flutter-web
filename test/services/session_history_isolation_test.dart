// Régression du bug « Mes résultats affiche les résultats d'un autre passe » :
// l'historique local était lu sans regarder à QUI appartenait chaque entrée, si
// bien qu'après un changement de passe sur le même téléphone, le nouveau passe
// voyait les résultats de l'ancien.
//
// Invariant vérifié ici : un résultat n'est visible que par le passe qui l'a
// produit — et rien n'est visible sans passe (fail-closed).

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mentality/services/session_history_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _accountA = '8a5bdb4cc15164126c6ef2668de9dd24';
const _accountB = 'c69fb40feba930717e71f01707a9fccd';

SessionHistoryEntry _entry(String id, {String? account, int fsiq = 100}) =>
    SessionHistoryEntry(
      id: id,
      account: account,
      date: DateTime(2026, 7, 18),
      ageInMonths: 360,
      fsiq: fsiq,
      classification: 'Moyen',
    );

void main() {
  late Directory tempDir;

  setUpAll(() async {
    // Le tampon lit le passe via un stockage qui passe par SharedPreferences.
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('mentality_history_test');
    Hive.init(tempDir.path);
    await SessionHistoryService.instance.initialize();
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  setUp(() async {
    for (final e in SessionHistoryService.instance.getAll()) {
      await SessionHistoryService.instance.deleteEntry(e.id);
    }
  });

  group('cloisonnement des résultats par passe', () {
    test('le passe A ne voit QUE ses propres résultats', () async {
      await SessionHistoryService.instance
          .saveEntry(_entry('a1', account: _accountA, fsiq: 120));
      await SessionHistoryService.instance
          .saveEntry(_entry('b1', account: _accountB, fsiq: 90));

      final vusParA = SessionHistoryService.instance.entriesForAccount(_accountA);
      expect(vusParA, hasLength(1));
      expect(vusParA.single.id, 'a1');
      expect(vusParA.single.fsiq, 120);
    });

    test('LE BUG : un passe neuf ne voit AUCUN résultat d\'un autre passe',
        () async {
      // L'ancien passe a fait deux tests sur ce téléphone…
      await SessionHistoryService.instance
          .saveEntry(_entry('vieux1', account: _accountA));
      await SessionHistoryService.instance
          .saveEntry(_entry('vieux2', account: _accountA));

      // …puis on se connecte avec un passe tout neuf : zéro test.
      expect(SessionHistoryService.instance.entriesForAccount(_accountB),
          isEmpty);
    });

    test('sans passe connecté, rien n\'est visible (fail-closed)', () async {
      await SessionHistoryService.instance
          .saveEntry(_entry('a1', account: _accountA));
      expect(SessionHistoryService.instance.entriesForAccount(null), isEmpty);
    });

    test('les entrées héritées (sans tampon) ne sont montrées à personne',
        () async {
      // Écrites avant l'introduction du tampon : propriétaire inconnu.
      await SessionHistoryService.instance.saveEntry(_entry('legacy'));

      expect(SessionHistoryService.instance.entriesForAccount(_accountA),
          isEmpty);
      expect(SessionHistoryService.instance.entriesForAccount(_accountB),
          isEmpty);
      // …mais elles restent en base (non détruites).
      expect(SessionHistoryService.instance.getAll(), hasLength(1));
    });

    test('le tampon survit à un aller-retour de sérialisation', () async {
      await SessionHistoryService.instance
          .saveEntry(_entry('a1', account: _accountA));
      final relu = SessionHistoryService.instance.getAll().single;
      expect(relu.account, _accountA);
    });

    test('la suppression n\'affecte que l\'entrée visée', () async {
      await SessionHistoryService.instance
          .saveEntry(_entry('a1', account: _accountA));
      await SessionHistoryService.instance
          .saveEntry(_entry('a2', account: _accountA));

      await SessionHistoryService.instance.deleteEntry('a1');

      final restants =
          SessionHistoryService.instance.entriesForAccount(_accountA);
      expect(restants.map((e) => e.id), ['a2']);
    });
  });
}
