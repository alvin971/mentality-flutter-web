import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Mobile et bureau : `record` rend un CHEMIN DE FICHIER. On lit le fichier.
///
/// Le repli `http` couvre le cas où la source porte malgré tout un schéma
/// réseau — jamais observé sur mobile, mais gratuit et sans risque.
Future<Uint8List?> lireOctetsEnregistrement(String source) async {
  if (source.isEmpty) return null;
  final uri = Uri.tryParse(source);
  if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
    final resp = await http.get(uri);
    if (resp.statusCode != 200 || resp.bodyBytes.isEmpty) return null;
    return resp.bodyBytes;
  }
  // `file:///chemin` comme `/chemin` : on retombe sur un chemin lisible.
  final chemin = uri != null && uri.scheme == 'file' ? uri.toFilePath() : source;
  final fichier = File(chemin);
  if (!await fichier.exists()) return null;
  final octets = await fichier.readAsBytes();
  return octets.isEmpty ? null : octets;
}

/// Mobile : le chemin doit être RÉEL et inscriptible.
///
/// Un nom relatif (« mentality_reading.webm ») ne l'est pas : dans le bac à
/// sable iOS, le répertoire courant n'est pas ouvert en écriture, et le fichier
/// n'est jamais créé — `stop()` rend alors un chemin qui ne mène à rien. C'est
/// ce qui a fait échouer tous les envois mobiles en silence.
Future<String> cheminEnregistrement(String base, String extension) async {
  final dossier = await getTemporaryDirectory();
  final unique = DateTime.now().microsecondsSinceEpoch;
  return '${dossier.path}/${base}_$unique.$extension';
}
