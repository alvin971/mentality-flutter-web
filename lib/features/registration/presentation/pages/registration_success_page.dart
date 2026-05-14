import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/et_logo_animated.dart';
import '../../../../core/widgets/kepler_button.dart';
import '../../../../core/widgets/kepler_card.dart';
import '../../../../core/widgets/kepler_scaffold.dart';
import '../../../../core/constants/app_constants.dart';

class RegistrationSuccessPage extends StatelessWidget {
  const RegistrationSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return KeplerScaffold(
      eyebrow: 'ÉTAPE 4 / 4 · SUCCÈS',
      title: 'Bienvenue dans Mental E.T.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 24.h),
          Center(child: EtLogoAnimated(size: 140.w)),
          SizedBox(height: 24.h),
          Text(
            'Votre token anonyme a été généré et sauvegardé sur cet appareil.',
            style: AppText.bodyStrong(),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12.h),
          Text(
            'Il ne contient ni votre email, ni votre numéro de téléphone, '
            'ni votre nom. Uniquement votre sexe, votre tranche d\'âge et '
            'votre zone géographique (chiffrés). Vous pouvez maintenant '
            'commencer votre évaluation cognitive.',
            style: AppText.body(),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          KeplerCard(
            surface: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('IMPORTANT',
                    style: AppText.monoLabel(color: AppColors.warning)),
                SizedBox(height: 8.h),
                Text(
                  'Ne désinstallez pas l\'application sans avoir terminé '
                  'votre évaluation : votre token est uniquement stocké '
                  'sur cet appareil. Si vous le perdez, vous ne pourrez '
                  'plus créer de nouveau compte avec le même email ou '
                  'téléphone.',
                  style: AppText.bodySmall(),
                ),
              ],
            ),
          ),
          SizedBox(height: 32.h),
          KeplerButton(
            label: 'Commencer',
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
