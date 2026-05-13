import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
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

    Future.delayed(const Duration(milliseconds: 2600), () {
      if (mounted) context.go(AppConstants.routeHome);
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                EtLogoAnimated(size: 140.w),
                SizedBox(height: 36.h),
                Text('§ MENTAL E.T. §',
                    style: AppText.monoLabel(color: AppColors.primary)),
                SizedBox(height: 14.h),
                Text('Évaluation', style: AppText.h1()),
                Text('cognitive', style: AppText.h1Italic()),
                SizedBox(height: 28.h),
                Container(
                  width: 32.w,
                  height: 1,
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
                SizedBox(height: 14.h),
                Text('WAIS-IV · WISC-V · WPPSI-IV',
                    style: AppText.monoLabel(
                        color: AppColors.textTertiary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
