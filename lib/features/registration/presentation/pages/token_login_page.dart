// lib/features/registration/presentation/pages/token_login_page.dart
//
// Écran de « connexion » au DÉBUT du parcours : petit formulaire démographique
// (sexe, mois/année, région) → à la soumission, crée le token PROVISOIRE,
// le sauvegarde localement, puis donne accès à l'app. Le token passe à VALIDÉ
// quand un test est soumis (cf. OralTestFlow). Voir PLAN_TOKEN_FIN_DE_TEST.md.
//
// Remplace l'ancien flux d'inscription par téléphone/OTP (RegistrationEmailPage).
//
// TODO(i18n) : titres en dur (FR) pour itérer vite, à migrer vers l'ARB.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../data_collection/token_issuance_step.dart';

class TokenLoginPage extends StatelessWidget {
  const TokenLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bienvenue'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: TokenIssuanceStep(
          // Le token provisoire est créé à la soumission du formulaire ; une fois
          // l'utilisateur invité à le sauvegarder, on entre dans l'app.
          onIssued: (_) {
            if (context.mounted) context.go(AppConstants.routeHome);
          },
        ),
      ),
    );
  }
}
