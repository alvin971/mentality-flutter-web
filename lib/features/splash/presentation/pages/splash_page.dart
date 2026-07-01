import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/l10n/l10n_ext.dart';
import '../../../../core/services/auth_local_store.dart';
import '../../../../core/services/token_access.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/et_logo_animated.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();

    // Gate d'authentification : redirige vers /register si aucun token local
    Future.delayed(const Duration(milliseconds: 2600), () async {
      if (!mounted) return;
      if (AppConstants.kSkipRegistrationGate) {
        // Mode bypass temporaire (config SMTP non finalisée)
        context.go(AppConstants.routeHome);
        return;
      }
      // Gate durci : on n'accepte pas la simple PRÉSENCE d'un token, mais sa
      // VALIDITÉ (signature Ed25519). Un token altéré/forgé localement est purgé.
      final token = await AuthLocalStore.instance.getToken();
      final accepted = await _isTokenAccepted(token);
      if (!mounted) return;
      if (!accepted && token != null) {
        await AuthLocalStore.instance.clear();
        if (!mounted) return;
      }
      context.go(accepted
          ? AppConstants.routeHome
          : AppConstants.routeRegister);
    });
  }

  /// Accepte un token signé valide. En debug uniquement, tolère un token DEV
  /// non signé (`M2.…`) pour permettre les tests sans Worker déployé.
  Future<bool> _isTokenAccepted(String? token) => TokenAccess.isAcceptable(token);

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                EtLogoAnimated(size: 140.w),
                SizedBox(height: 36.h),
                Text('MENTAL E.T.',
                    style: AppText.monoLabel(color: AppColors.primary)),
                SizedBox(height: 14.h),
                Text(context.l10n.coreSplashTitleLine1, style: AppText.h1()),
                Text(context.l10n.coreSplashTitleLine2,
                    style: AppText.h1Italic()),
                SizedBox(height: 28.h),
                Container(
                  width: 32.w,
                  height: 1,
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
                SizedBox(height: 14.h),
                Text('WAIS-IV · WISC-V · WPPSI-IV',
                    style: AppText.monoLabel(
                        color: Theme.of(context).colorScheme.outline)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
