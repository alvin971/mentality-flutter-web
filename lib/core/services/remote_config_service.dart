import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service de configuration distante depuis Supabase.
///
/// Lit la table `remote_config` du projet Supabase admin et expose
/// les valeurs de configuration. Fallback sur les valeurs locales si
/// Supabase n'est pas configuré ou inaccessible.
///
/// La clé anon Supabase est publique par design (RLS en lecture seule
/// pour les utilisateurs anonymes).
///
/// Configuration requise dans app_constants.dart :
///   - `supabaseUrl` : URL du projet Supabase (ex: https://xxx.supabase.co)
///   - `supabaseAnonKey` : Clé anon publique du projet Supabase
class RemoteConfigService {
  RemoteConfigService._();
  static final RemoteConfigService instance = RemoteConfigService._();

  final Map<String, dynamic> _config = {};
  bool _loaded = false;

  /// Charger la configuration distante.
  ///
  /// Appelé dans `_configureApp()` de main.dart.
  /// Si Supabase n'est pas configuré ou inaccessible, utilise les
  /// valeurs locales par défaut sans bloquer le démarrage.
  Future<void> loadConfig({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) async {
    if (supabaseUrl.isEmpty ||
        supabaseUrl.contains('YOUR_PROJECT') ||
        supabaseAnonKey.isEmpty) {
      _loadDefaults();
      return;
    }

    try {
      final uri = Uri.parse('$supabaseUrl/rest/v1/remote_config?select=key,value');
      final response = await http
          .get(
            uri,
            headers: {
              'apikey': supabaseAnonKey,
              'Authorization': 'Bearer $supabaseAnonKey',
            },
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> rows = jsonDecode(response.body) as List<dynamic>;
        for (final row in rows) {
          final key = row['key'] as String;
          final value = row['value'];
          _config[key] = value;
        }
        _loaded = true;
      } else {
        _loadDefaults();
      }
    } catch (_) {
      // Réseau inaccessible ou erreur → fallback local
      _loadDefaults();
    }
  }

  void _loadDefaults() {
    _config.addAll({
      'app_version_required': '1.0.0',
      'test_flow_enabled': true,
      'oral_test_enabled': true,
      'irt_adaptive_enabled': false,
      'scoring_source': 'local',
      'ai_chat_enabled': true,
      'session_save_enabled': true,
    });
    _loaded = true;
  }

  bool get isLoaded => _loaded;

  // ── Accesseurs typés ────────────────────────────────────────────────────

  bool getBool(String key, {bool defaultValue = false}) {
    final v = _config[key];
    if (v == null) return defaultValue;
    if (v is bool) return v;
    if (v == 'true' || v == true) return true;
    if (v == 'false' || v == false) return false;
    return defaultValue;
  }

  String getString(String key, {String defaultValue = ''}) {
    final v = _config[key];
    if (v == null) return defaultValue;
    // Supabase JSONB string values come with quotes when stored as '"value"'
    if (v is String) return v.replaceAll('"', '');
    return v.toString().replaceAll('"', '');
  }

  int getInt(String key, {int defaultValue = 0}) {
    final v = _config[key];
    if (v == null) return defaultValue;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? defaultValue;
  }

  // ── Valeurs spécifiques à l'application ────────────────────────────────

  bool get isTestFlowEnabled => getBool('test_flow_enabled', defaultValue: true);
  bool get isOralTestEnabled => getBool('oral_test_enabled', defaultValue: true);
  bool get isIrtAdaptiveEnabled => getBool('irt_adaptive_enabled', defaultValue: false);
  bool get isAiChatEnabled => getBool('ai_chat_enabled', defaultValue: true);
  bool get isSessionSaveEnabled => getBool('session_save_enabled', defaultValue: true);

  /// Source des tables normatives : 'local' (Dart hardcodé) ou 'remote' (Supabase)
  String get scoringSource => getString('scoring_source', defaultValue: 'local');
  bool get useRemoteScoring => scoringSource == 'remote';

  String get requiredAppVersion => getString('app_version_required', defaultValue: '1.0.0');

  // ── Accès brut ─────────────────────────────────────────────────────────

  dynamic operator [](String key) => _config[key];

  Map<String, dynamic> get all => Map.unmodifiable(_config);
}
