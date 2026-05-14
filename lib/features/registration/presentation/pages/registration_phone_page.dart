import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/kepler_button.dart';
import '../../../../core/widgets/kepler_card.dart';
import '../../../../core/widgets/kepler_scaffold.dart';
import '../bloc/registration_bloc.dart';
import 'registration_phone_otp_page.dart';

class RegistrationPhonePage extends StatefulWidget {
  const RegistrationPhonePage({super.key});

  @override
  State<RegistrationPhonePage> createState() => _RegistrationPhonePageState();
}

class _RegistrationPhonePageState extends State<RegistrationPhonePage> {
  final _controller = TextEditingController();
  String _dialCode = '+33';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _toE164() {
    final digits = _controller.text.replaceAll(RegExp(r'[^0-9]'), '');
    // retire un 0 de tête si présent (format national FR / BE…)
    final trimmed = digits.startsWith('0') ? digits.substring(1) : digits;
    return '$_dialCode$trimmed';
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RegistrationBloc, RegistrationState>(
      listenWhen: (a, b) => a.step != b.step,
      listener: (context, state) {
        if (state.step == RegistrationStep.phoneVerifying) {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const RegistrationPhoneOtpPage()));
        }
      },
      builder: (context, state) {
        return KeplerScaffold(
          title: 'Votre téléphone',
          eyebrow: 'ÉTAPE 2 / 4',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 12.h),
              Text(
                'Un code SMS à 6 chiffres sera envoyé pour vérifier votre '
                'numéro. Aucun lien entre votre numéro et votre token.',
                style: AppText.body(),
              ),
              SizedBox(height: 20.h),
              KeplerCard(
                child: Row(
                  children: [
                    CountryCodePicker(
                      initialSelection: 'FR',
                      favorite: const ['FR', 'BE', 'CH', 'US', 'GB'],
                      showFlag: true,
                      onChanged: (c) =>
                          setState(() => _dialCode = c.dialCode ?? '+33'),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        autofocus: true,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          hintText: 'Numéro',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (state.errorMessage != null) ...[
                SizedBox(height: 12.h),
                Text(state.errorMessage!,
                    style: AppText.bodySmall(color: AppColors.error)),
              ],
              SizedBox(height: 24.h),
              KeplerButton(
                label: state.busy ? 'Envoi du SMS…' : 'Recevoir le SMS',
                expand: true,
                onPressed: state.busy
                    ? null
                    : () {
                        final e164 = _toE164();
                        if (e164.length >= 8) {
                          context
                              .read<RegistrationBloc>()
                              .add(SubmitPhone(e164));
                        }
                      },
              ),
            ],
          ),
        );
      },
    );
  }
}
