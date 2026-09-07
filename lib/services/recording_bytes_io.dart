import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

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
