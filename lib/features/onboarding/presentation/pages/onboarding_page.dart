import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

/// Page d'onboarding — présentée au premier lancement.
///
/// 3 slides :
/// 1. Confidentialité des données
/// 2. Durée et déroulement du test
/// 3. Explication des 5 indices cognitifs
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
      icon: Icons.lock_outline,
      color: AppColors.primary,
      title: 'Vos données restent privées',
      body:
          'Toutes vos évaluations sont stockées localement sur votre appareil. '
          'Aucune donnée n\'est partagée sans votre consentement explicite. '
          'Les enregistrements audio oraux sont chiffrés et ne quittent '
          'votre appareil qu\'après votre accord.',
    ),
    _Slide(
      icon: Icons.timer_outlined,
      color: AppColors.secondary,
      title: 'Durée et déroulement',
      body:
          'Le test complet dure entre 30 et 60 minutes. '
          'Vous pouvez faire une pause et reprendre à tout moment — '
          'votre progression est sauvegardée automatiquement. '
          'Choisissez un moment calme, sans distractions.',
    ),
    _Slide(
      icon: Icons.psychology_outlined,
      color: AppColors.indexFRI,
      title: 'Ce que mesure Mentality',
      body:
          'L\'application évalue 5 domaines cognitifs issus du WAIS-IV :\n\n'
          '• VCI — Compréhension Verbale\n'
          '• VSI — Raisonnement Visuo-Spatial\n'
          '• FRI — Raisonnement Fluide\n'
          '• WMI — Mémoire de Travail\n'
          '• PSI — Vitesse de Traitement\n\n'
          'Un score global FSIQ est calculé à partir de ces 5 indices.',
    ),
  ];

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.go(AppConstants.routeHome);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () => context.go(AppConstants.routeHome),
                child: const Text('Passer'),
              ),
            ),

            // Page view
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _slides.length,
                itemBuilder: (_, i) => _SlideWidget(slide: _slides[i]),
              ),
            ),

            // Indicateurs de page
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: EdgeInsets.symmetric(horizontal: 4.w),
                  width: _currentPage == i ? 24.w : 8.w,
                  height: 8.h,
                  decoration: BoxDecoration(
                    color: _currentPage == i
                        ? _slides[_currentPage].color
                        : AppColors.grey300,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ),
            ),
            SizedBox(height: 24.h),

            // Bouton suivant / commencer
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _slides[_currentPage].color,
                  ),
                  child: Text(
                    _currentPage < _slides.length - 1 ? 'Suivant' : 'Commencer',
                  ),
                ),
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
  final IconData icon;
  final Color color;
  final String title;
  final String body;

  const _Slide({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });
}

class _SlideWidget extends StatelessWidget {
  final _Slide slide;

  const _SlideWidget({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(32.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120.w,
            height: 120.w,
            decoration: BoxDecoration(
              color: slide.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(slide.icon, size: 60.sp, color: slide.color),
          ),
          SizedBox(height: 40.h),
          Text(
            slide.title,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20.h),
          Text(
            slide.body,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.grey600,
                  height: 1.6,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
