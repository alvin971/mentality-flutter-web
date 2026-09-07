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

  /// TEMPORAIRE (2026-09-07) — RETIRER AVEC L'ENTREE DE TEST DES SOUS-TESTS.
  ///
  /// Pourquoi : tout echec d'envoi est volontairement SILENCIEUX (« non
  /// bloquant ») — un enregistrement qui ne part pas ne doit jamais casser le
  /// parcours de quelqu'un. Mais pendant une campagne de test, ce silence rend
  /// impossible de distinguer « l'audio est parti » de « il n'est jamais
  /// parti ». Ce champ retient la DERNIERE raison, pour l'afficher a l'ecran.
  ///
  /// Ne contient jamais de donnee personnelle : un code de cause, au plus un
  /// code HTTP.
  static String? dernierDiagnostic;

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
    if (!isConfigured) {
      dernierDiagnostic = 'worker non configure (URL placeholder)';
      return null;
    }
    if (blobUrl.isEmpty) {
      dernierDiagnostic = "le micro n'a rien rendu (blob vide)";
      return null;
    }
    try {
      // 1. Lire les octets du blob (XHR/fetch supporte les URLs blob: sur web).
      final blobResp = await http.get(Uri.parse(blobUrl));
      if (blobResp.statusCode != 200 || blobResp.bodyBytes.isEmpty) {
        dernierDiagnostic = 'blob illisible (HTTP ${blobResp.statusCode}, '
            '${blobResp.bodyBytes.length} octets)';
        return null;
      }
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
    if (!isConfigured) {
      dernierDiagnostic = 'worker non configure (URL placeholder)';
      return null;
    }
    if (bytes.isEmpty) {
      dernierDiagnostic = 'enregistrement vide (0 octet)';
      return null;
    }
    // Le worker exige un token signé valide ; sans token, inutile d'uploader.
    final token = await AuthLocalStore.instance.getToken();
    if (token == null || token.isEmpty) {
      dernierDiagnostic = "AUCUN PASSE en memoire : envoi saute. "
          "Passer par l'inscription pour obtenir un passe Gratuit signe.";
      return null;
    }
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
      if (resp.statusCode != 200) {
        dernierDiagnostic = 'worker a refuse : HTTP ${resp.statusCode} '
            '${resp.body.length > 160 ? resp.body.substring(0, 160) : resp.body}';
        return null;
      }
      // Réponse : {"key": "...", "size": N, "reusable": bool}
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final key = data['key'] as String?;
      if (key == null) {
        dernierDiagnostic = 'reponse du worker sans cle';
        return null;
      }
      dernierDiagnostic = 'OK — ${bytes.length} octets envoyes';
      return R2UploadResult(
        key: key,
        size: (data['size'] as num?)?.toInt() ?? bytes.length,
        reusable: data['reusable'] as bool? ?? false,
      );
    } catch (e) {
      dernierDiagnostic = 'reseau : $e';
      return null; // non bloquant
    }
  }
}
