import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/datasources/registration_remote_datasource.dart';
import '../../data/repositories/registration_repository.dart';
import '../../domain/entities/registration_form.dart';

// ===================== EVENTS =====================

abstract class RegistrationEvent extends Equatable {
  const RegistrationEvent();
  @override
  List<Object?> get props => [];
}

class StartRegistration extends RegistrationEvent {
  const StartRegistration();
}

class SubmitEmail extends RegistrationEvent {
  final String email;
  const SubmitEmail(this.email);
  @override
  List<Object?> get props => [email];
}

class SubmitEmailOtp extends RegistrationEvent {
  final String code;
  const SubmitEmailOtp(this.code);
  @override
  List<Object?> get props => [code];
}

class SubmitPhone extends RegistrationEvent {
  final String phoneE164;
  const SubmitPhone(this.phoneE164);
  @override
  List<Object?> get props => [phoneE164];
}

class SubmitPhoneOtp extends RegistrationEvent {
  final String code;
  const SubmitPhoneOtp(this.code);
  @override
  List<Object?> get props => [code];
}

class SubmitDemographics extends RegistrationEvent {
  final Sex sex;
  final AgeBucket ageBucket;
  final String countryCode;
  final String postalCode;
  const SubmitDemographics({
    required this.sex,
    required this.ageBucket,
    required this.countryCode,
    required this.postalCode,
  });
  @override
  List<Object?> get props => [sex, ageBucket, countryCode, postalCode];
}

class ResetRegistration extends RegistrationEvent {
  const ResetRegistration();
}

// ===================== STATES =====================

enum RegistrationStep {
  initial,
  emailEntering,
  emailVerifying,
  phoneEntering,
  phoneVerifying,
  demographicEntering,
  generatingToken,
  success,
  failure,
}

class RegistrationState extends Equatable {
  final RegistrationStep step;
  final RegistrationForm form;
  final bool busy;
  final String? errorMessage;
  final String? generatedToken;

  const RegistrationState({
    required this.step,
    required this.form,
    this.busy = false,
    this.errorMessage,
    this.generatedToken,
  });

  factory RegistrationState.initial() => const RegistrationState(
        step: RegistrationStep.initial,
        form: RegistrationForm(),
      );

  RegistrationState copyWith({
    RegistrationStep? step,
    RegistrationForm? form,
    bool? busy,
    String? errorMessage,
    String? generatedToken,
    bool clearError = false,
  }) =>
      RegistrationState(
        step: step ?? this.step,
        form: form ?? this.form,
        busy: busy ?? this.busy,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        generatedToken: generatedToken ?? this.generatedToken,
      );

  @override
  List<Object?> get props => [step, form, busy, errorMessage, generatedToken];
}

// ===================== BLOC =====================

class RegistrationBloc extends Bloc<RegistrationEvent, RegistrationState> {
  RegistrationBloc({RegistrationRepository? repository})
      : _repo = repository ?? RegistrationRepository(),
        super(RegistrationState.initial()) {
    on<StartRegistration>(_onStart);
    on<SubmitEmail>(_onSubmitEmail);
    on<SubmitEmailOtp>(_onSubmitEmailOtp);
    on<SubmitPhone>(_onSubmitPhone);
    on<SubmitPhoneOtp>(_onSubmitPhoneOtp);
    on<SubmitDemographics>(_onSubmitDemographics);
    on<ResetRegistration>(
        (e, emit) => emit(RegistrationState.initial()));
  }

  final RegistrationRepository _repo;

  void _onStart(StartRegistration e, Emitter<RegistrationState> emit) {
    emit(RegistrationState.initial()
        .copyWith(step: RegistrationStep.emailEntering));
  }

  Future<void> _onSubmitEmail(
      SubmitEmail e, Emitter<RegistrationState> emit) async {
    emit(state.copyWith(busy: true, clearError: true));
    try {
      await _repo.checkEmailAvailable(e.email);
      await _repo.sendEmailOtp(e.email);
      emit(state.copyWith(
        step: RegistrationStep.emailVerifying,
        form: state.form.copyWith(email: e.email),
        busy: false,
      ));
    } on UniquenessConflict catch (err) {
      emit(state.copyWith(
        busy: false,
        errorMessage: err.reason == 'email_taken'
            ? 'Cet email a déjà un compte. Si c\'est le vôtre, vous avez déjà un token.'
            : 'Email indisponible.',
      ));
    } catch (err) {
      emit(state.copyWith(busy: false, errorMessage: _friendly(err)));
    }
  }

  Future<void> _onSubmitEmailOtp(
      SubmitEmailOtp e, Emitter<RegistrationState> emit) async {
    final email = state.form.email;
    if (email == null) return;
    emit(state.copyWith(busy: true, clearError: true));
    try {
      await _repo.verifyEmailOtp(email, e.code);
      emit(state.copyWith(
        step: RegistrationStep.phoneEntering,
        busy: false,
      ));
    } catch (err) {
      emit(state.copyWith(
        busy: false,
        errorMessage: 'Code incorrect ou expiré.',
      ));
    }
  }

  Future<void> _onSubmitPhone(
      SubmitPhone e, Emitter<RegistrationState> emit) async {
    emit(state.copyWith(busy: true, clearError: true));
    try {
      await _repo.checkPhoneAvailable(e.phoneE164);
      await _repo.sendPhoneOtp(e.phoneE164);
      emit(state.copyWith(
        step: RegistrationStep.phoneVerifying,
        form: state.form.copyWith(phoneE164: e.phoneE164),
        busy: false,
      ));
    } on UniquenessConflict catch (err) {
      emit(state.copyWith(
        busy: false,
        errorMessage: err.reason == 'phone_taken'
            ? 'Ce numéro a déjà un compte.'
            : 'Numéro indisponible.',
      ));
    } catch (err) {
      emit(state.copyWith(busy: false, errorMessage: _friendly(err)));
    }
  }

  Future<void> _onSubmitPhoneOtp(
      SubmitPhoneOtp e, Emitter<RegistrationState> emit) async {
    final phone = state.form.phoneE164;
    if (phone == null) return;
    emit(state.copyWith(busy: true, clearError: true));
    try {
      await _repo.verifyPhoneOtp(phone, e.code);
      emit(state.copyWith(
        step: RegistrationStep.demographicEntering,
        busy: false,
      ));
    } catch (err) {
      emit(state.copyWith(
        busy: false,
        errorMessage: 'Code incorrect ou expiré.',
      ));
    }
  }

  Future<void> _onSubmitDemographics(
      SubmitDemographics e, Emitter<RegistrationState> emit) async {
    final form = state.form.copyWith(
      sex: e.sex,
      ageBucket: e.ageBucket,
      countryCode: e.countryCode,
      postalCode: e.postalCode,
    );
    emit(state.copyWith(
      form: form,
      step: RegistrationStep.generatingToken,
      busy: true,
      clearError: true,
    ));
    try {
      final token = await _repo.finalizeRegistration(form);
      emit(state.copyWith(
        step: RegistrationStep.success,
        generatedToken: token,
        busy: false,
      ));
    } on UniquenessConflict catch (err) {
      emit(state.copyWith(
        step: RegistrationStep.failure,
        busy: false,
        errorMessage: err.reason == 'email_taken'
            ? 'Cet email a déjà un token.'
            : 'Ce numéro a déjà un token.',
      ));
    } catch (err) {
      emit(state.copyWith(
        step: RegistrationStep.failure,
        busy: false,
        errorMessage: _friendly(err),
      ));
    }
  }

  String _friendly(Object err) {
    final s = err.toString();
    if (s.contains('invalid_postal')) {
      return 'Code postal introuvable. Vérifiez le pays et le code.';
    }
    if (s.contains('SocketException') || s.contains('Failed host lookup')) {
      return 'Pas de connexion internet.';
    }
    return 'Erreur — merci de réessayer.';
  }
}
