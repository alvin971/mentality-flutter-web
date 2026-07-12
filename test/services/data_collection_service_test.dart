// Garantie structurelle de séparation des boxes de DataCollectionService :
// les données cognitives (mentality_keep) ne partent JAMAIS dans les chemins
// d'export (exportForUpload / getSessionData ne lisent que mentality_sell).

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mentality/services/data_collection_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    final tempDir = Directory.systemTemp.createTempSync('dcs_test_');
    Hive.init(tempDir.path);
    await DataCollectionService.instance.initialize();
  });

  test('saveCognitiveRecord écrit dans la box keep, lisible par session',
      () async {
    final svc = DataCollectionService.instance;
    final before = svc.cognitiveRecordCount;

    await svc.saveCognitiveRecord({
      'type': 'vp_item',
      'session_id': 'session-keep',
      'seed': 42,
      'palier': 3,
      'is_correct': true,
      'rt_ms': 12345,
    });

    expect(svc.cognitiveRecordCount, before + 1);
    final records = await svc.getCognitiveSessionData('session-keep');
    expect(records, hasLength(1));
    expect(records.first['seed'], 42);
    expect(records.first['palier'], 3);
  });

  test('les données cognitives ne fuient JAMAIS dans les chemins d\'export',
      () async {
    final svc = DataCollectionService.instance;

    await svc.saveCognitiveRecord({
      'type': 'vp_item',
      'session_id': 'session-mixte',
      'secret': 'donnée-cognitive-locale',
    });
    await svc.saveAudioRecord({
      'layer': 'C',
      'session_id': 'session-mixte',
      'audio_path': 'exportable.webm',
    });

    // exportForUpload : uniquement la box sell.
    final export = jsonDecode(await svc.exportForUpload()) as List<dynamic>;
    expect(
      export.where((r) => (r as Map)['secret'] != null),
      isEmpty,
      reason: 'un enregistrement cognitif est présent dans l\'export !',
    );
    expect(
      export.where((r) => (r as Map)['audio_path'] == 'exportable.webm'),
      hasLength(1),
    );

    // getSessionData (chemin d'upload par session) : uniquement la box sell.
    final sessionData = await svc.getSessionData('session-mixte');
    expect(
      sessionData.where((r) => r['secret'] != null),
      isEmpty,
      reason: 'un enregistrement cognitif fuit par getSessionData !',
    );
    expect(sessionData, hasLength(1));

    // Et la donnée cognitive reste bien lisible LOCALEMENT.
    final keep = await svc.getCognitiveSessionData('session-mixte');
    expect(keep, hasLength(1));
    expect(keep.first['secret'], 'donnée-cognitive-locale');
  });
}
