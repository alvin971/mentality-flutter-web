import '../../../../core/services/auth_local_store.dart';
import '../../domain/entities/registration_form.dart';
import '../../domain/entities/token_claims.dart';
import '../datasources/registration_remote_datasource.dart';

/// Façade au-dessus du datasource — orchestre la persistance locale après
/// génération du token et expose une API simple au bloc.
class RegistrationRepository {
  RegistrationRepository({
    RegistrationRemoteDataSource? remote,
    AuthLocalStore? local,
  })  : _remote = remote ?? RegistrationRemoteDataSource(),
        _local = local ?? AuthLocalStore.instance;

  final RegistrationRemoteDataSource _remote;
  final AuthLocalStore _local;

  Future<void> checkEmailAvailable(String email) =>
      _remote.verifyUniqueness(email: email);

  Future<void> sendEmailOtp(String email) => _remote.sendEmailOtp(email);

  Future<void> verifyEmailOtp(String email, String code) =>
      _remote.verifyEmailOtp(email, code);

  Future<void> checkPhoneAvailable(String phoneE164) =>
      _remote.verifyUniqueness(phoneE164: phoneE164);

  Future<void> sendPhoneOtp(String phoneE164) =>
      _remote.sendPhoneOtp(phoneE164);

  Future<void> verifyPhoneOtp(String phoneE164, String code) =>
      _remote.verifyPhoneOtp(phoneE164, code);

  Future<List<PostalCodeSuggestion>> searchPostalCodes({
    required String countryCode,
    required String query,
  }) =>
      _remote.searchPostalCodes(countryCode: countryCode, query: query);

  /// Génère le token, le persiste localement, déconnecte la session Supabase
  /// Auth (anonymat — pas de session persistante côté Supabase Auth).
  Future<String> finalizeRegistration(RegistrationForm form) async {
    final token = await _remote.registerAndIssueToken(form);
    await _local.saveToken(token);
    await _remote.signOutSupabaseAuth();
    return token;
  }

  Future<String?> currentToken() => _local.getToken();

  Future<TokenClaims> decodeCurrentToken() async {
    final token = await _local.getToken();
    if (token == null) throw StateError('no token stored');
    return _remote.decodeToken(token);
  }

  Future<void> logout() => _local.clear();
}
