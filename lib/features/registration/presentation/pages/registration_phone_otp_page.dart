import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/kepler_colors.dart';
import '../../../../core/widgets/kepler_button.dart';
import '../../../../core/widgets/kepler_card.dart';
import '../../../../core/widgets/kepler_scaffold.dart';
import '../../../../core/l10n/l10n_ext.dart';
import '../bloc/registration_bloc.dart';
import 'registration_demographics_page.dart';

class RegistrationPhoneOtpPage extends StatefulWidget {
  const RegistrationPhoneOtpPage({super.key});

  @override
  State<RegistrationPhoneOtpPage> createState() =>
      _RegistrationPhoneOtpPageState();
}

class _RegistrationPhoneOtpPageState extends State<RegistrationPhoneOtpPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RegistrationBloc, RegistrationState>(
      listenWhen: (a, b) => a.step != b.step,
      listener: (context, state) {
        if (state.step == RegistrationStep.demographicEntering) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
              builder: (_) => const RegistrationDemographicsPage()));
        }
      },
      builder: (context, state) {
        final phone = state.form.phoneE164 ?? '';
        return KeplerScaffold(
          title: context.l10n.regPhoneOtpTitle,
          eyebrow: context.l10n.regStepEyebrow(2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 12.h),
              Text(context.l10n.regSmsSentTo,
                  style: AppText.of(context).monoLabel(color: KeplerColors.of(context).primary)),
              SizedBox(height: 4.h),
              Text(phone, style: AppText.of(context).h3()),
              SizedBox(height: 24.h),
              KeplerCard(
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: TextStyle(
                    fontSize: 28.sp,
                    letterSpacing: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                    hintText: '••••••',
                  ),
                ),
              ),
              if (state.errorMessage != null) ...[
                SizedBox(height: 12.h),
                Text(state.errorMessage!,
                    style: AppText.of(context).bodySmall(color: KeplerColors.of(context).error)),
              ],
              SizedBox(height: 24.h),
              KeplerButton(
                label: state.busy
                    ? context.l10n.regVerifying
                    : context.l10n.commonValidate,
                expand: true,
                onPressed: state.busy
                    ? null
                    : () {
                        if (_controller.text.length == 6) {
                          context
                              .read<RegistrationBloc>()
                              .add(SubmitPhoneOtp(_controller.text));
                        }
                      },
              ),
              SizedBox(height: 12.h),
              Center(
                child: TextButton(
                  onPressed: state.busy
                      ? null
                      : () => context
                          .read<RegistrationBloc>()
                          .add(SubmitPhone(phone)),
                  child: Text(context.l10n.regResendSms),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
