import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/l10n/l10n_ext.dart';
import '../../../../core/services/auth_local_store.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/kepler_button.dart';
import '../../../../core/widgets/kepler_card.dart';
import '../../../../core/widgets/kepler_scaffold.dart';

/// Landing du lien d'invitation `/invite?ref=<code>`.
///
/// Mémorise le code de parrainage en local (consommé à la FIN du test du
/// filleul, moment où il valide son parrain — voir UnlockService.initProgress)
/// puis envoie vers le parcours normal. Best-effort : même si le worker est
/// injoignable, le code est stocké et le filleul peut commencer.
class InviteLandingPage extends StatefulWidget {
  const InviteLandingPage({super.key, required this.referralCode});

  final String? referralCode;

  @override
  State<InviteLandingPage> createState() => _InviteLandingPageState();
}

class _InviteLandingPageState extends State<InviteLandingPage> {
  @override
  void initState() {
    super.initState();
    final code = widget.referralCode?.trim().toLowerCase();
    if (code != null && RegExp(r'^[a-z0-9]{8}$').hasMatch(code)) {
      AuthLocalStore.instance.savePendingReferrerCode(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return KeplerScaffold(
      title: l10n.inviteLandingTitle,
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 24.h),
          KeplerCard(
            child: Column(
              children: [
                Icon(Icons.card_giftcard, size: 48.sp),
                SizedBox(height: 16.h),
                Text(
                  l10n.inviteLandingBody,
                  style: AppText.of(context).body(),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24.h),
                KeplerButton(
                  label: l10n.inviteLandingCta,
                  expand: true,
                  onPressed: () => context.go(AppConstants.routeSplash),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
