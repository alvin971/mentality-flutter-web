library;

/// Lecture des octets d'un enregistrement, SELON LA PLATEFORME.
///
/// POURQUOI CE FICHIER EXISTE. `record` ne rend pas la même chose partout :
///   - sur le web, `stop()` rend une URL `blob:https://…` ;
///   - sur iOS et Android, il rend un CHEMIN DE FICHIER (`/var/mobile/…/x.m4a`).
///
/// L'ancien code faisait un `http.get` sur cette valeur dans les deux cas. Sur
/// mobile, `http.get` ne sait pas lire un chemin de fichier : l'exception était
/// capturée, l'envoi rendait `null` — silencieusement, puisque l'envoi est
/// « non bloquant ». Conséquence : depuis le pivot mobile, AUCUN enregistrement
/// ne partait vers R2, et rien ne le signalait.
///
/// L'implémentation est choisie à la compilation : `dart:io` quand il existe
/// (mobile, bureau), la version web sinon.
export 'recording_bytes_web.dart' if (dart.library.io) 'recording_bytes_io.dart';
