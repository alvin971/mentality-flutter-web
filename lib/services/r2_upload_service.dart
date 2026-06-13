// lib/services/r2_upload_service.dart
// Upload des enregistrements audio vers Cloudflare R2 via le worker r2-upload.
//
// Le client n'a JAMAIS de clé R2 : il envoie les octets + métadonnées au worker
// (workers/r2-upload/), qui écrit dans le bucket côté serveur. Voir ce worker
// pour l'organisation des clés (reusable/ vs internal/) et le garde-fou RGPD.
//
// Robustesse : tout échec est non bloquant. Si le worker n'est pas configuré
// (URL placeholder) ou injoignable, l'upload est sauté et le parcours continue ;
// l'enregistrement reste en local (Hive) avec son blob.

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

import '../core/constants/app_constants.dart';
import '../core/services/auth_local_store.dart';

class R2UploadResult {
  final String key;
  final int size;
  final bool reusable;
  const R2UploadResult(
      {required this.key, required this.size, required this.reusable});
}

class R2UploadService {
  static final R2UploadService instance = R2UploadService._();
  R2UploadService._();

  /// `true` si une URL de worker réelle est configurée (pas le placeholder).
  bool get isConfigured =>
      !AppConstants.r2UploadWorkerUrl.contains('YOUR_SUBDOMAIN');

  /// Récupère les octets d'un blob web (`blob:https://...`) renvoyé par le
  /// recorder, puis les envoie au worker R2. Renvoie la clé R2 ou `null`.
  ///
  /// [blobUrl]       URL renvoyée par `recorder.stop()` (web).
  /// [contentType]   type MIME réel de l'encodeur (audio/webm, audio/mp4, …).
  /// [meta]          en-têtes métier (session, consentement, durée, langue…).
  Future<R2UploadResult?> uploadBlob({
    required String blobUrl,
    required String contentType,
    required Map<String, String> meta,
  }) async {
    if (!isConfigured || blobUrl.isEmpty) return null;
    try {
      // 1. Lire les octets du blob (XHR/fetch supporte les URLs blob: sur web).
      final blobResp = await http.get(Uri.parse(blobUrl));
      if (blobResp.statusCode != 200 || blobResp.bodyBytes.isEmpty) return null;
      return uploadBytes(
        bytes: blobResp.bodyBytes,
        contentType: contentType,
        meta: meta,
      );
    } catch (_) {
      return null; // non bloquant
    }
  }

  /// Envoie des octets déjà en mémoire au worker R2.
  Future<R2UploadResult?> uploadBytes({
    required Uint8List bytes,
    required String contentType,
    required Map<String, String> meta,
  }) async {
    if (!isConfigured || bytes.isEmpty) return null;
    // Le worker exige un token signé valide ; sans token, inutile d'uploader.
    final token = await AuthLocalStore.instance.getToken();
    if (token == null || token.isEmpty) return null;
    try {
      final resp = await http.post(
        Uri.parse(AppConstants.r2UploadWorkerUrl),
        headers: {
          'Content-Type': contentType,
          'X-Mentality-Token': token,
          'X-Session-Id': meta['session_id'] ?? '',
          'X-Text-Id': meta['text_id'] ?? '',
          'X-Layer': meta['layer'] ?? 'C',
          'X-Record-Type': meta['record_type'] ?? 'audio',
          'X-Consent-Version': meta['consent_version'] ?? '',
          'X-Commercial-Reuse': meta['commercial_reuse'] ?? 'false',
          'X-Duration-Seconds': meta['duration_seconds'] ?? '',
          'X-Language': meta['language'] ?? 'fr',
        },
        body: bytes,
      );
      if (resp.statusCode != 200) return null;
      // Réponse : {"key": "...", "size": N, "reusable": bool}
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final key = data['key'] as String?;
      if (key == null) return null;
      return R2UploadResult(
        key: key,
        size: (data['size'] as num?)?.toInt() ?? bytes.length,
        reusable: data['reusable'] as bool? ?? false,
      );
    } catch (_) {
      return null; // non bloquant
    }
  }
}
