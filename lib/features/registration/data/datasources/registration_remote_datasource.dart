import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/registration_form.dart';
import '../../domain/entities/token_claims.dart';

class UniquenessConflict implements Exception {
  final String reason; // 'email_taken' | 'phone_taken'
  UniquenessConflict(this.reason);
  @override
  String toString() => 'UniquenessConflict($reason)';
}

class RegistrationFailure implements Exception {
  final String reason;
  RegistrationFailure(this.reason);
  @override
  String toString() => 'RegistrationFailure($reason)';
}

class PostalCodeSuggestion {
  final String postalCode;
  final String placeName;
  final String? admin1;
  PostalCodeSuggestion({
    required this.postalCode,
    required this.placeName,
    this.admin1,
  });
}

/// Datasource d'inscription — appelle Supabase Auth (OTP email / phone)
/// et les 3 Edge Functions (verify-uniqueness, register-and-issue-token,
/// decode-token).
class RegistrationRemoteDataSource {
  RegistrationRemoteDataSource({SupabaseClient? client, http.Client? http})
      : _supabase = client ?? Supabase.instance.client,
        _http = http ?? Client();

  final SupabaseClient _supabase;
  final http.Client _http;

  String get _functionsBase => '${AppConstants.supabaseUrl}/functions/v1';

  Map<String, String> get _commonHeaders => {
        'apikey': AppConstants.supabaseAnonKey,
        'Content-Type': 'application/json',
      };

  /// Vérifie qu'un email et/ou téléphone n'est pas déjà pris.
  /// Lance [UniquenessConflict] si non disponible.
  Future<void> verifyUniqueness({String? email, String? phoneE164}) async {
    final resp = await _http.post(
      Uri.parse('$_functionsBase/verify-uniqueness'),
      headers: _commonHeaders,
      body: jsonEncode({
        if (email != null) 'email': email,
        if (phoneE164 != null) 'phoneE164': phoneE164,
      }),
    );
    if (resp.statusCode >= 400) {
      throw RegistrationFailure('verify-uniqueness HTTP ${resp.statusCode}');
    }
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    if (body['available'] != true) {
      throw UniquenessConflict(body['reason'] as String? ?? 'unknown');
    }
  }

  /// Envoie un OTP email via Supabase Auth.
  Future<void> sendEmailOtp(String email) async {
    await _supabase.auth.signInWithOtp(email: email);
  }

  /// Vérifie l'OTP email. Retourne le user vérifié.
  Future<User> verifyEmailOtp(String email, String code) async {
    final resp = await _supabase.auth.verifyOTP(
      email: email,
      token: code,
      type: OtpType.email,
    );
    final user = resp.user;
    if (user == null || user.emailConfirmedAt == null) {
      throw RegistrationFailure('email_otp_failed');
    }
    return user;
  }

  /// Envoie un OTP SMS via Supabase Auth (Twilio en backend).
  /// Doit être appelé après email vérifié (user déjà signed in).
  Future<void> sendPhoneOtp(String phoneE164) async {
    await _supabase.auth.updateUser(UserAttributes(phone: phoneE164));
  }

  /// Vérifie l'OTP SMS. Retourne le user mis à jour avec phone confirmé.
  Future<User> verifyPhoneOtp(String phoneE164, String code) async {
    final resp = await _supabase.auth.verifyOTP(
      phone: phoneE164,
      token: code,
      type: OtpType.phoneChange,
    );
    final user = resp.user;
    if (user == null || user.phoneConfirmedAt == null) {
      throw RegistrationFailure('phone_otp_failed');
    }
    return user;
  }

  /// Recherche d'autocomplétion sur les codes postaux (REST Supabase).
  Future<List<PostalCodeSuggestion>> searchPostalCodes({
    required String countryCode,
    required String query,
    int limit = 10,
  }) async {
    if (query.trim().isEmpty) return [];
    final rows = await _supabase
        .from('postal_codes')
        .select('postal_code, place_name, admin_name1')
        .eq('country_code', countryCode)
        .ilike('postal_code', '${query.trim()}%')
        .limit(limit);
    return (rows as List)
        .map((r) => PostalCodeSuggestion(
              postalCode: r['postal_code'] as String,
              placeName: (r['place_name'] as String?) ?? '',
              admin1: r['admin_name1'] as String?,
            ))
        .toList();
  }

  /// Appel final : génère le token AES-GCM et l'insère.
  /// Retourne le token chiffré base64url.
  Future<String> registerAndIssueToken(RegistrationForm form) async {
    final session = _supabase.auth.currentSession;
    if (session == null) {
      throw RegistrationFailure('not_authenticated');
    }

    final resp = await _http.post(
      Uri.parse('$_functionsBase/register-and-issue-token'),
      headers: {
        ..._commonHeaders,
        'Authorization': 'Bearer ${session.accessToken}',
      },
      body: jsonEncode({
        'email': form.email,
        'phoneE164': form.phoneE164,
        'sex': form.sex!.code,
        'ageBucket': form.ageBucket!.code,
        'countryCode': form.countryCode,
        'postalCode': form.postalCode,
      }),
    );

    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    if (resp.statusCode == 200) {
      return body['token'] as String;
    }
    final reason = body['error'] as String? ?? 'internal';
    if (reason == 'email_taken' || reason == 'phone_taken') {
      throw UniquenessConflict(reason);
    }
    throw RegistrationFailure(reason);
  }

  /// Déchiffre un token et retourne les claims.
  Future<TokenClaims> decodeToken(String token) async {
    final resp = await _http.post(
      Uri.parse('$_functionsBase/decode-token'),
      headers: _commonHeaders,
      body: jsonEncode({'token': token}),
    );
    if (resp.statusCode != 200) {
      throw RegistrationFailure('decode_failed');
    }
    return TokenClaims.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
  }

  /// Déconnecte le user Supabase Auth (le token Mental E.T. local
  /// reste, c'est lui qui sert d'identité).
  Future<void> signOutSupabaseAuth() async {
    try {
      await _supabase.auth.signOut();
    } catch (_) {
      // ignore
    }
  }
}

// Alias pour http.Client (évite collision noms d'import)
class Client extends http.BaseClient {
  final http.Client _inner = http.Client();
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      _inner.send(request);
  @override
  void close() => _inner.close();
}
