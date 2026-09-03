// lib/services/tokeniser_service.dart
//
// Appelle le Cloudflare Worker `tokeniser` (workers/tokeniser/) :
//   - POST /          → SIGNE des claims démographiques → token (immuable).
//   - POST /validate  → enregistre la complétion côté serveur ({ok:true}) ;
//                       le token N'EST PAS re-signé et ne change jamais.
//                       Depuis 2026-09-03, la réponse dit AUSSI où en est la
//                       vérification des lectures par transcription :
//                         200 {ok:true}                            → vérifié
//                         409 {ok:false, code:'VERIFICATION_PENDING'} → en cours
//                         400 {ok:false, code:'VERIFICATION_FAILED'}  → refusé
//                       (voir [TokenValidationResult]).
//
// Le client n'a JAMAIS la clé privée. Si le Worker n'est pas configuré (URL
// placeholder), `isConfigured` est false et l'appelant utilise le fallback DEV
// (voir TokenIssuer).

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/constants/app_constants.dart';

/// Erreur d'émission/validation côté Worker (statut HTTP non-200 ou réseau).
class TokeniserException implements Exception {
  final String message;
  const TokeniserException(this.message);
  @override
  String toString() => 'TokeniserException: $message';
}

/// Où en est la vérification de complétion d'un token, vue du serveur.
enum TokenValidationStatus {
  /// Assez de lectures vérifiées : la complétion est enregistrée.
  ok,

  /// La transcription asynchrone n'a pas fini : réessayer plus tard.
  pending,

  /// Le serveur a tranché : le seuil n'est pas atteint (enregistrement
  /// absent, vide ou sans rapport avec le texte). Réessayer ne changera rien
  /// tant qu'aucun nouvel enregistrement n'arrive.
  failed,

  /// Réseau injoignable, délai dépassé, réponse illisible ou erreur serveur
  /// (5xx, 429) : on ne sait pas. Réessayer a un sens.
  network,

  /// Aucun Worker configuré (URL placeholder ou [debugForceUnconfigured]) :
  /// rien n'a été demandé. L'appelant applique son repli DEV.
  unconfigured,
}

/// Résultat typé de `POST /validate`.
///
/// Remplace l'ancien booléen : `ok` seul ne permettait pas de distinguer « la
/// transcription n'a pas fini » (attendre) de « l'enregistrement est refusé »
/// (réenregistrer) ni de « pas de réseau » (réessayer) — trois parcours
/// utilisateur différents.
class TokenValidationResult {
  final TokenValidationStatus status;

  /// Compteurs renvoyés par le serveur quand il les connaît (409 / 400).
  final int? verified;
  final int? pending;
  final int? failed;

  /// Statut HTTP reçu, `null` si la requête n'a pas abouti.
  final int? httpStatus;

  /// Code métier du serveur (`VERIFICATION_PENDING`, …), s'il y en a un.
  final String? code;

  /// Détail lisible pour les journaux — jamais affiché tel quel.
  final String? message;

  const TokenValidationResult._(
    this.status, {
    this.verified,
    this.pending,
    this.failed,
    this.httpStatus,
    this.code,
    this.message,
  });

  const TokenValidationResult.ok({int? httpStatus})
      : this._(TokenValidationStatus.ok, httpStatus: httpStatus);

  const TokenValidationResult.network(String message)
      : this._(TokenValidationStatus.network, message: message);

  const TokenValidationResult.failed({String? message})
      : this._(TokenValidationStatus.failed, message: message);

  const TokenValidationResult.unconfigured()
      : this._(TokenValidationStatus.unconfigured);

  bool get isOk => status == TokenValidationStatus.ok;
  bool get isPending => status == TokenValidationStatus.pending;
  bool get isFailed => status == TokenValidationStatus.failed;
  bool get isNetwork => status == TokenValidationStatus.network;

  /// Interprète une réponse HTTP du Worker.
  ///
  /// Le CODE MÉTIER prime sur le statut HTTP quand il est présent : un
  /// serveur qui répondrait `VERIFICATION_PENDING` avec un autre statut que
  /// 409 serait quand même compris. Sans code, on se rabat sur le statut :
  /// 409 ⇒ en cours, 4xx ⇒ refusé, 5xx/429 ⇒ réseau (réessayable).
  factory TokenValidationResult.fromResponse(int httpStatus, String body) {
    Map<String, dynamic> data = const {};
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) data = decoded;
    } catch (_) {
      // corps vide ou non-JSON : on tranche sur le statut seul.
    }
    final code = data['code'] is String ? data['code'] as String : null;
    final verified = _entier(data['verified']);
    final pending = _entier(data['pending']);
    final failed = _entier(data['failed']);
    final message = data['error'] is String ? data['error'] as String : null;

    TokenValidationStatus status;
    if (code == 'VERIFICATION_PENDING') {
      status = TokenValidationStatus.pending;
    } else if (code == 'VERIFICATION_FAILED') {
      status = TokenValidationStatus.failed;
    } else if (httpStatus == 200) {
      // `{ok:false}` en 200 n'a pas de sens ; on le lit comme un refus plutôt
      // que d'inventer une confirmation.
      status = data['ok'] == false
          ? TokenValidationStatus.failed
          : TokenValidationStatus.ok;
    } else if (httpStatus == 409) {
      status = TokenValidationStatus.pending;
    } else if (httpStatus == 429 || httpStatus >= 500) {
      status = TokenValidationStatus.network;
    } else {
      status = TokenValidationStatus.failed;
    }
    return TokenValidationResult._(
      status,
      verified: verified,
      pending: pending,
      failed: failed,
      httpStatus: httpStatus,
      code: code,
      message: message,
    );
  }

  static int? _entier(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return null;
  }

  @override
  String toString() =>
      'TokenValidationResult($status, http=$httpStatus, code=$code, '
      'verified=$verified, pending=$pending, failed=$failed)';
}

class TokeniserService {
  TokeniserService({http.Client? client}) : _client = client ?? http.Client();

  static final TokeniserService instance = TokeniserService();

  final http.Client _client;

  /// TESTS UNIQUEMENT : force le chemin « non configuré » (fallback DEV local)
  /// pour que les tests unitaires n'appellent jamais le Worker réel.
  @visibleForTesting
  static bool debugForceUnconfigured = false;

  /// `true` si une URL de Worker réelle est configurée (pas le placeholder).
  bool get isConfigured =>
      !debugForceUnconfigured &&
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

  /// Enregistre côté serveur qu'un token a complété le test (preuve de
  /// complétion vérifiée par le Worker). Le token N'EST PAS re-signé : il ne
  /// change pas, on ne récupère qu'un [TokenValidationResult] — vérifié, en
  /// cours de vérification, refusé, ou injoignable. Ne lève jamais.
  /// [TokenValidationStatus.unconfigured] si aucun Worker n'est configuré
  /// (no-op DEV).
  Future<TokenValidationResult> validateToken(String token) async {
    if (!isConfigured) return const TokenValidationResult.unconfigured();
    return _postForValidation(
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

  /// POST dont la réponse est interprétée par [TokenValidationResult] (pas de
  /// token en retour). Une erreur réseau ou un délai dépassé donnent
  /// [TokenValidationStatus.network] — non bloquant, l'appelant décide de
  /// retenter.
  Future<TokenValidationResult> _postForValidation(Uri uri, Object body) async {
    try {
      final resp = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(AppConstants.connectionTimeout);
      return TokenValidationResult.fromResponse(resp.statusCode, resp.body);
    } catch (e) {
      return TokenValidationResult.network('réseau: $e');
    }
  }
}
