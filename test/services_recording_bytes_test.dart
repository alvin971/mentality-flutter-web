import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/services/recording_bytes.dart';

void main() {
  test('un CHEMIN DE FICHIER (ce que rend record sur mobile) est lu', () async {
    final f = File('${Directory.systemTemp.path}/essai_audio.m4a')
      ..writeAsBytesSync(List<int>.generate(2048, (i) => i % 256));
    final octets = await lireOctetsEnregistrement(f.path);
    expect(octets, isNotNull);
    expect(octets!.length, 2048);
    f.deleteSync();
  });

  test('un chemin file:// est lu aussi', () async {
    final f = File('${Directory.systemTemp.path}/essai_audio2.m4a')
      ..writeAsBytesSync([1, 2, 3, 4]);
    final octets = await lireOctetsEnregistrement(f.uri.toString());
    expect(octets?.length, 4);
    f.deleteSync();
  });

  test('source vide ou fichier absent → null, jamais une exception', () async {
    expect(await lireOctetsEnregistrement(''), isNull);
    expect(await lireOctetsEnregistrement('/inexistant/nulle/part.m4a'), isNull);
  });
}
