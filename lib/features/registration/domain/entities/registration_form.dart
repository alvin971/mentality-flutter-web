import 'package:equatable/equatable.dart';
import '../../../../core/l10n/l10n_ext.dart';

enum Sex { masculine, feminine, undisclosed }

enum AgeBucket { b1825, b2635, b3645, b4655, b5665, b66plus }

extension AgeBucketX on AgeBucket {
  String get code => switch (this) {
        AgeBucket.b1825 => '18-25',
        AgeBucket.b2635 => '26-35',
        AgeBucket.b3645 => '36-45',
        AgeBucket.b4655 => '46-55',
        AgeBucket.b5665 => '56-65',
        AgeBucket.b66plus => '66+',
      };

  String label(AppLocalizations l10n) => switch (this) {
        AgeBucket.b1825 => l10n.regAge1825,
        AgeBucket.b2635 => l10n.regAge2635,
        AgeBucket.b3645 => l10n.regAge3645,
        AgeBucket.b4655 => l10n.regAge4655,
        AgeBucket.b5665 => l10n.regAge5665,
        AgeBucket.b66plus => l10n.regAge66plus,
      };
}

extension SexX on Sex {
  String get code => switch (this) {
        Sex.masculine => 'M',
        Sex.feminine => 'F',
        Sex.undisclosed => 'X',
      };

  String label(AppLocalizations l10n) => switch (this) {
        Sex.masculine => l10n.regSexMale,
        Sex.feminine => l10n.regSexFemale,
        Sex.undisclosed => l10n.regSexUndisclosed,
      };
}

/// Données saisies dans le formulaire d'inscription.
///
/// Email et téléphone sont conservés côté serveur (table verified_contacts)
/// pour empêcher les multi-comptes. Sexe + tranche d'âge + pays + code postal
/// sont encodés dans le token AES-GCM. Aucun autre champ n'est persisté.
class RegistrationForm extends Equatable {
  final String? email;
  final String? phoneE164;
  final Sex? sex;
  final AgeBucket? ageBucket;
  final String? countryCode; // ISO 3166-1 alpha-2
  final String? postalCode;

  const RegistrationForm({
    this.email,
    this.phoneE164,
    this.sex,
    this.ageBucket,
    this.countryCode,
    this.postalCode,
  });

  RegistrationForm copyWith({
    String? email,
    String? phoneE164,
    Sex? sex,
    AgeBucket? ageBucket,
    String? countryCode,
    String? postalCode,
  }) =>
      RegistrationForm(
        email: email ?? this.email,
        phoneE164: phoneE164 ?? this.phoneE164,
        sex: sex ?? this.sex,
        ageBucket: ageBucket ?? this.ageBucket,
        countryCode: countryCode ?? this.countryCode,
        postalCode: postalCode ?? this.postalCode,
      );

  bool get isDemographicComplete =>
      sex != null && ageBucket != null && countryCode != null && postalCode != null;

  @override
  List<Object?> get props => [email, phoneE164, sex, ageBucket, countryCode, postalCode];
}
