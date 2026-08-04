// Où les révélations vont chercher le profil à révéler.
//
// Une seule source : l'historique local du PASSE COURANT. Rien ne transite par
// le réseau — les scores ont été calculés sur l'appareil et n'en sont jamais
// sortis. Le déblocage des huit jours ne change donc rien à leur disponibilité :
// ce qui est verrouillé, c'est l'écran de résultats, pas la donnée.

import '../../../../../services/session_history_service.dart';
import '../models/reveal_data.dart';

/// Comment on obtient les bilans du passe courant. Injectable pour que les
/// écrans soient testables sans Hive.
typedef RevealHistoryLoader = Future<List<SessionHistoryEntry>> Function();

Future<List<SessionHistoryEntry>> _historiqueDuPasse() =>
    SessionHistoryService.instance.getAllForCurrentAccount();

class RevealSource {
  const RevealSource({this.load = _historiqueDuPasse});

  final RevealHistoryLoader load;

  /// Le bilan le plus récent du passe courant, ou `null` s'il n'y en a aucun.
  ///
  /// `getAllForCurrentAccount()` rend déjà la liste du plus récent au plus
  /// ancien et exclut les entrées d'un autre passe ; on ne refait donc ni le
  /// tri ni le filtrage, on prend la tête. Une exception de lecture ne fait
  /// pas planter la journée : elle vaut « rien à révéler », et l'écran le dit.
  Future<RevealData?> latest() async {
    try {
      final entries = await load();
      return entries.isEmpty ? null : RevealData.fromHistory(entries.first);
    } catch (_) {
      return null;
    }
  }
}
