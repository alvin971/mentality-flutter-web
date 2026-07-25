import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/kepler_colors.dart';
import '../../../../core/widgets/kepler_button.dart';

/// Onboarding Kepler — 3 slides éditoriales (serif + mono).
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  static const _slides = [
    _Slide(
      eyebrow: 'CONFIDENTIALITÉ',
      titleA: 'Vos données',
      titleB: 'vous appartiennent.',
      body:
          'Les évaluations restent stockées localement et chiffrées. '
          'Aucune donnée n\'est partagée sans votre consentement explicite. '
          'Les enregistrements audio ne quittent l\'appareil qu\'après votre accord.',
    ),
    _Slide(
      eyebrow: 'DURÉE',
      titleA: '30 à 60 minutes,',
      titleB: 'à votre rythme.',
      body:
          'Vous pouvez faire une pause et reprendre à tout moment — '
          'votre progression est sauvegardée automatiquement. '
          'Choisissez un moment calme, sans distractions.',
    ),
    _Slide(
      eyebrow: 'MESURE',
      titleA: 'Cinq indices,',
      titleB: 'un score global.',
      body:
          'Mental E.T. évalue les cinq domaines cognitifs du WAIS-IV : '
          'compréhension verbale (VCI), raisonnement visuo-spatial (VSI), '
          'raisonnement fluide (FRI), mémoire de travail (WMI), '
          'et vitesse de traitement (PSI). Le score FSIQ en est la synthèse.',
    ),
  ];

  void _next() {
    if (_currentPage < _slides.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } else {
      context.go(AppConstants.routeHome);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _slides.length - 1;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(_currentPage + 1).toString().padLeft(2, '0')} / ${_slides.length.toString().padLeft(2, '0')}',
                    style: AppText.of(context).monoLabel(color: Theme.of(context).colorScheme.outline),
                  ),
                  TextButton(
                    onPressed: () => context.go(AppConstants.routeHome),
                    child: Text('Passer',
                        style: AppText.of(context).bodySmall(
                            color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _slides.length,
                itemBuilder: (_, i) => _SlideView(slide: _slides[i]),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: EdgeInsets.symmetric(horizontal: 3.w),
                  width: _currentPage == i ? 24.w : 6.w,
                  height: 2.h,
                  color: _currentPage == i
                      ? AppColors.primary
                      : AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
            ),
            SizedBox(height: 24.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: KeplerButton(
                label: isLast ? 'Commencer' : 'Continuer',
                onPressed: _next,
                expand: true,
              ),
            ),
            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }
}

class _Slide {
  const _Slide({
    required this.eyebrow,
    required this.titleA,
    required this.titleB,
    required this.body,
  });

  final String eyebrow;
  final String titleA;
  final String titleB;
  final String body;
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});
  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('${slide.eyebrow}',
              style: AppText.of(context).monoLabel(color: KeplerColors.of(context).primary)),
          SizedBox(height: 24.h),
          Text(slide.titleA, style: AppText.of(context).heroDisplay()),
          Text(slide.titleB, style: AppText.of(context).heroItalic()),
          SizedBox(height: 28.h),
          Container(
              width: 40.w,
              height: 1,
              color: KeplerColors.of(context).primary.withValues(alpha: 0.4)),
          SizedBox(height: 28.h),
          Text(slide.body, style: AppText.of(context).body()),
        ],
      ),
    );
  }
}
