// lib/features/complete_test/presentation/pages/resultats_en_attente_page.dart
//
// Affichée À LA PLACE des résultats quand un passe GRATUIT termine le bilan
// sans que son enregistrement vocal ait été vérifié par le serveur (refus,
// délai dépassé, réseau, ou étape orale quittée).
//
// Décision fondateur (2026-09-03) : l'enregistrement est la contrepartie du
// passe Gratuit, et un enregistrement absent, vide ou sans rapport avec les
// textes ne donne pas droit aux résultats. Le bilan, lui, est bien terminé —
// déclaré et envoyé dès la fin de la batterie (voir l'orchestrateur) — et
// cette page ne fait que retenir l'AFFICHAGE : la session reste en mémoire ici,
// et, l'app fermée, une passation complète reste récupérable depuis l'accueil
// (reprise), qui rejoue l'étape orale puis la vérification.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/l10n/l10n_ext.dart';
import '../../../../core/models/complete_test_session.dart';
import '../../../../core/services/auth_local_store.dart';
import '../../../../core/services/token_issuer.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/kepler_colors.dart';
import '../../../../core/widgets/kepler_button.dart';
import '../../../../core/widgets/kepler_card.dart';
import '../../../../core/widgets/kepler_scaffold.dart';
import '../../../../services/tokeniser_service.dart';
import '../../../data_collection/oral_test_flow.dart';
import 'complete_test_results_page.dart';

class ResultatsEnAttentePage extends StatefulWidget {
  const ResultatsEnAttentePage({
    super.key,
    required this.session,
    required this.ageInMonths,
  });

  /// La session terminée, gardée telle quelle pour l'écran de résultats.
  final CompleteTestSession session;
  final int ageInMonths;

  @override
  State<ResultatsEnAttentePage> createState() => _ResultatsEnAttentePageState();
}

class _ResultatsEnAttentePageState extends State<ResultatsEnAttentePage> {
  bool _verificationEnCours = false;

  /// Rouvre l'épreuve orale ; si elle revient vérifiée, on passe aux
  /// résultats. Sinon on reste ici, prêt à recommencer.
  Future<void> _reprendreLEnregistrement() async {
    final verifie = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const OralTestFlow()),
    );
    if (!mounted) return;
    if (verifie == true) _afficherLesResultats();
  }

  /// Redemande le verdict au serveur sans réenregistrer — utile quand la
  /// transcription n'avait simplement pas fini.
  Future<void> _verifierANouveau() async {
    if (_verificationEnCours) return;
    setState(() => _verificationEnCours = true);

    TokenValidationResult resultat;
    try {
      final token = await AuthLocalStore.instance.getToken();
      resultat = token == null
          ? const TokenValidationResult.failed(message: 'aucun token')
          : await TokenIssuer.verifyCompletion(token);
    } catch (e) {
      resultat = TokenValidationResult.network('$e');
    }
    if (!mounted) return;
    setState(() => _verificationEnCours = false);

    if (resultat.isOk) {
      _afficherLesResultats();
      return;
    }
    final message = switch (resultat.status) {
      TokenValidationStatus.pending => context.l10n.rpaStillPending,
      TokenValidationStatus.failed => context.l10n.rpaStillFailed,
      _ => context.l10n.rpaNetwork,
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _afficherLesResultats() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CompleteTestResultsPage(
          session: widget.session,
          ageInMonths: widget.ageInMonths,
        ),
      ),
    );
  }

  /// Retour à l'accueil — même précaution que l'étape orale : cette page peut
  /// être la seule de la pile.
  void _retourAccueil() {
    final navigateur = Navigator.of(context);
    if (navigateur.canPop()) {
      navigateur.pop();
      return;
    }
    GoRouter.maybeOf(context)?.go(AppConstants.routeHome);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = KeplerColors.of(context);
    return KeplerScaffold(
      title: l10n.rpaTitle,
      eyebrow: l10n.rpaEyebrow,
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.rpaHero, style: AppText.of(context).heroDisplay()),
          SizedBox(height: 16.h),
          Container(
              width: 36.w,
              height: 1,
              color: colors.primary.withValues(alpha: 0.4)),
          SizedBox(height: 16.h),
          Text(l10n.rpaBody, style: AppText.of(context).body()),
          SizedBox(height: 24.h),
          KeplerCard(
            surface: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.mic_none, size: 22.sp, color: colors.primary),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    l10n.oralVerifRequiredHint,
                    style: AppText.of(context).bodySmall(),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 28.h),
          KeplerButton(
            label: l10n.rpaResume,
            icon: Icons.mic,
            expand: true,
            onPressed: _verificationEnCours ? null : _reprendreLEnregistrement,
          ),
          SizedBox(height: 12.h),
          KeplerButton(
            label: l10n.rpaCheckAgain,
            icon: Icons.refresh,
            variant: KeplerButtonVariant.secondary,
            expand: true,
            onPressed: _verificationEnCours ? null : _verifierANouveau,
          ),
          SizedBox(height: 12.h),
          KeplerButton(
            label: l10n.oralBackToHome,
            variant: KeplerButtonVariant.ghost,
            expand: true,
            onPressed: _retourAccueil,
          ),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }
}
