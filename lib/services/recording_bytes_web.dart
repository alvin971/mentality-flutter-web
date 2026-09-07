import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// Web : `record` rend une URL `blob:` que `http.get` sait lire.
Future<Uint8List?> lireOctetsEnregistrement(String source) async {
  if (source.isEmpty) return null;
  final resp = await http.get(Uri.parse(source));
  if (resp.statusCode != 200 || resp.bodyBytes.isEmpty) return null;
  return resp.bodyBytes;
}
