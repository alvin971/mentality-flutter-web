import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/kepler_colors.dart';
import '../../../../core/widgets/et_logo_animated.dart';
import '../../../../core/widgets/kepler_button.dart';
import '../../../../core/widgets/kepler_card.dart';
import '../../../../core/widgets/kepler_scaffold.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/l10n/l10n_ext.dart';

class RegistrationSuccessPage extends StatelessWidget {
  const RegistrationSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return KeplerScaffold(
      eyebrow: context.l10n.regStepEyebrowSuccess,
      title: context.l10n.regSuccessTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 24.h),
          Center(child: EtLogoAnimated(size: 140.w)),
          SizedBox(height: 24.h),
          Text(
            context.l10n.regSuccessTokenSaved,
            style: AppText.of(context).bodyStrong(),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12.h),
          Text(
            context.l10n.regSuccessTokenDetails,
            style: AppText.of(context).body(),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          KeplerCard(
            surface: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.regImportantLabel,
                    style: AppText.of(context).monoLabel(color: KeplerColors.of(context).warning)),
                SizedBox(height: 8.h),
                Text(
                  context.l10n.regSuccessWarning,
                  style: AppText.of(context).bodySmall(),
                ),
              ],
            ),
          ),
          SizedBox(height: 32.h),
          KeplerButton(
            label: context.l10n.commonStart,
            expand: true,
            onPressed: () {
              Navigator.of(context)
                  .pushReplacementNamed(AppConstants.routeHome);
            },
          ),
        ],
      ),
    );
  }
}
