// Ouverture d'une journée de l'événement.
//
// Toute la règle tient dans `statusOfDay`, et elle est VOLONTAIREMENT une
// fonction pure sans aucun paramètre d'horloge : le jour de référence vient du
// serveur (`UnlockProgress.dayIndex`) et de nulle part ailleurs. Avancer la
// date du téléphone ne peut donc rien ouvrir — il n'y a pas de date à avancer.

/// Ce que l'utilisateur peut faire d'une journée donnée.
enum DayStatus {
  /// La journée du jour.
  open,

  /// Journée passée — RATTRAPABLE : rien ne se perd, on peut y revenir.
  past,

  /// Journée à venir : elle s'ouvrira d'elle-même, aucune action ne l'avance.
  locked,
}

/// Statut de [day] (1..8) sachant que le serveur annonce [serverDayIndex]
/// (1..8 pendant l'attente, 9 une fois le déblocage acquis).
///
/// Une valeur de 9 laisse les huit journées rattrapables : l'événement se
/// termine, il ne se ferme pas.
DayStatus statusOfDay({required int day, required int serverDayIndex}) {
  if (day > serverDayIndex) return DayStatus.locked;
  if (day == serverDayIndex) return DayStatus.open;
  return DayStatus.past;
}
