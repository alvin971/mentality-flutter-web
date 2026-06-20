// lib/services/tokeniser_service.dart
//
// Appelle le Cloudflare Worker `tokeniser` (workers/tokeniser/) :
//   - POST /          → SIGNE des claims démographiques → token PROVISOIRE.
//   - POST /validate  → re-signe un token provisoire valide → token VALIDÉ.
//
// Le client n'a JAMAIS la clé privée. Si le Worker n'est pas configuré (URL
// placeholder), `isConfigured` est false et l'appelant utilise le fallback DEV
// (voir TokenIssuer).

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../core/constants/app_constants.dart';

/// Erreur d'émission/validation côté Worker (statut HTTP non-200 ou réseau).
class TokeniserException implements Exception {
  final String message;
  const TokeniserException(this.message);
  @override
  String toString() => 'TokeniserException: $message';
}

class TokeniserService {
  TokeniserService({http.Client? client}) : _client = client ?? http.Client();

  static final TokeniserService instance = TokeniserService();

  final http.Client _client;

  /// `true` si une URL de Worker réelle est configurée (pas le placeholder).
  bool get isConfigured =>
      !AppConstants.tokeniserWorkerUrl.contains('YOUR_SUBDOMAIN');

  /// Demande un token signé PROVISOIRE pour [claims] (claims larges :
  /// sex, birth_year, birth_month, region — signup_day recalculé serveur).
  /// `null` si non configuré (no-op DEV).
  Future<String?> requestSignedToken(Map<String, dynamic> claims) async {
    if (!isConfigured) return null;
    return _postForToken(Uri.parse(AppConstants.tokeniserWorkerUrl), claims);
  }

  /// Suggestion de région large déduite de la géo-IP (Cloudflare), pour
  /// pré-remplir le menu. Indice CORRIGEABLE : aucune donnée stockée, aucune
  /// permission. Renvoie un code région (ex. 'IDF') ou `null` si indisponible.
  Future<String?> suggestRegion() async {
    if (!isConfigured) return null;
    try {
      final resp = await _client
          .get(Uri.parse('${AppConstants.tokeniserWorkerUrl}/geo'))
          .timeout(AppConstants.connectionTimeout);
      if (resp.statusCode != 200) return null;
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final region = data['region'];
      return region is String && region.isNotEmpty ? region : null;
    } catch (_) {
      return null; // non bloquant
    }
  }

  /// Re-signe un token provisoire en token VALIDÉ (à la soumission d'un test).
  /// `null` si non configuré (no-op DEV).
  Future<String?> validateToken(String token) async {
    if (!isConfigured) return null;
    return _postForToken(
      Uri.parse('${AppConstants.tokeniserWorkerUrl}/validate'),
      {'token': token},
    );
  }

  Future<String> _postForToken(Uri uri, Object body) async {
    http.Response resp;
    try {
      resp = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(AppConstants.connectionTimeout);
    } catch (e) {
      throw TokeniserException('réseau: $e');
    }

    if (resp.statusCode == 200) {
      try {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final token = data['token'];
        if (token is String && token.isNotEmpty) return token;
        throw const TokeniserException('réponse sans token');
      } catch (e) {
        if (e is TokeniserException) rethrow;
        throw TokeniserException('réponse invalide: $e');
      }
    }
    switch (resp.statusCode) {
      case 400:
        throw const TokeniserException('requête refusée (400)');
      case 401:
        throw const TokeniserException('token invalide (401)');
      case 403:
        throw const TokeniserException('origine refusée (403)');
      case 429:
        throw const TokeniserException('trop de requêtes (429)');
      default:
        throw TokeniserException('erreur serveur (${resp.statusCode})');
    }
  }
}
