import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/kepler_button.dart';
import '../../../../core/widgets/kepler_card.dart';
import '../../../../core/widgets/kepler_scaffold.dart';
import '../../../../core/widgets/et_logo_animated.dart';
import '../../../../core/l10n/l10n_ext.dart';
import '../bloc/registration_bloc.dart';
import 'registration_email_otp_page.dart';

class RegistrationEmailPage extends StatefulWidget {
  const RegistrationEmailPage({super.key});

  @override
  State<RegistrationEmailPage> createState() => _RegistrationEmailPageState();
}

class _RegistrationEmailPageState extends State<RegistrationEmailPage> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isValidEmail(String s) {
    final re = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return re.hasMatch(s.trim());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RegistrationBloc, RegistrationState>(
      listenWhen: (a, b) => a.step != b.step,
      listener: (context, state) {
        if (state.step == RegistrationStep.emailVerifying) {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const RegistrationEmailOtpPage()));
        }
      },
      builder: (context, state) {
        return KeplerScaffold(
          title: context.l10n.regEmailTitle,
          eyebrow: context.l10n.regStepEyebrow(1),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 12.h),
                Row(
                  children: [
                    EtLogoAnimated(size: 32.w),
                    SizedBox(width: 12.w),
                    Text(context.l10n.regEmailHeading,
                        style: AppText.h2Italic(color: AppColors.primary)),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  context.l10n.regEmailIntro,
                  style: AppText.body(),
                ),
                SizedBox(height: 20.h),
                KeplerCard(
                  child: TextFormField(
                    controller: _controller,
                    keyboardType: TextInputType.emailAddress,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: context.l10n.regEmailFieldLabel,
                      border: InputBorder.none,
                    ),
                    validator: (v) {
                      if (v == null || !_isValidEmail(v)) {
                        return context.l10n.regEmailInvalid;
                      }
                      return null;
                    },
                  ),
                ),
                if (state.errorMessage != null) ...[
                  SizedBox(height: 12.h),
                  Text(state.errorMessage!,
                      style: AppText.bodySmall(color: AppColors.error)),
                ],
                SizedBox(height: 24.h),
                KeplerButton(
                  label: state.busy
                      ? context.l10n.regSendingCode
                      : context.l10n.regReceiveCode,
                  expand: true,
                  onPressed: state.busy
                      ? null
                      : () {
                          if (_formKey.currentState!.validate()) {
                            context
                                .read<RegistrationBloc>()
                                .add(SubmitEmail(_controller.text.trim()));
                          }
                        },
                ),
                SizedBox(height: 16.h),
                Text(
                  context.l10n.regEmailPrivacyNote,
                  style: AppText.bodySmall(color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
