import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/services/recording_bytes.dart';

/// Non-régression du bug qui a rendu MUETTE toute la collecte audio mobile :
/// `record` rend une URL `blob:` sur le web mais un CHEMIN DE FICHIER sur
/// mobile, et le chemin qu'on lui passait (« mentality_reading.webm ») était
/// relatif, donc non créable dans le bac à sable iOS. L'envoi échouait ensuite
/// en silence, l'upload étant « non bloquant ».
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // `path_provider` passe par un canal de plateforme, absent en test unitaire.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => Directory.systemTemp.path,
    );
  });

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

  test('le chemin donné à record est ABSOLU, pas un nom relatif', () async {
    final chemin = await cheminEnregistrement('mentality_reading', 'm4a');
    expect(chemin.startsWith('/'), isTrue,
        reason: "un nom relatif n'est pas créable dans le bac à sable iOS");
    expect(chemin.endsWith('.m4a'), isTrue);
    final f = File(chemin)..writeAsBytesSync([1, 2, 3]);
    expect(await lireOctetsEnregistrement(chemin), isNotNull);
    f.deleteSync();
  });

  test('deux enregistrements ne se écrasent pas', () async {
    final a = await cheminEnregistrement('mentality_reading', 'm4a');
    await Future<void>.delayed(const Duration(milliseconds: 2));
    final b = await cheminEnregistrement('mentality_reading', 'm4a');
    expect(a, isNot(equals(b)));
  });
}
