import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/assessment/presentation/pages/assessment_intro_page.dart';
import '../../features/complete_test/presentation/pages/complete_test_orchestrator_page.dart';
import '../../features/chat/presentation/pages/mentality_chat_page.dart';
import '../../features/results_history/presentation/pages/results_history_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/data_collection/oral_test_flow.dart';
import '../../features/exercises_implementations/cubes/presentation/pages/cubes_test_page.dart';
import '../../features/exercises_implementations/matrices/presentation/pages/matrices_test_page.dart';
import '../../features/exercises_implementations/figure_weights/presentation/pages/figure_weights_test_page.dart';
import '../../features/exercises_implementations/visual_puzzles/presentation/pages/visual_puzzles_test_page.dart';
import '../../features/exercises_implementations/similarities/presentation/pages/similarities_test_page.dart';
import '../../features/exercises_implementations/vocabulary/presentation/pages/vocabulary_test_page.dart';
import '../../features/exercises_implementations/information/presentation/pages/information_test_page.dart';
import '../../features/exercises_implementations/digit_span/presentation/pages/digit_span_test_page.dart';
import '../../features/exercises_implementations/arithmetic/presentation/pages/arithmetic_test_page.dart';
import '../../features/exercises_implementations/picture_span/presentation/pages/picture_span_test_page.dart';
import '../../features/exercises_implementations/coding/presentation/pages/coding_test_page.dart';
import '../../features/exercises_implementations/symbol_search/presentation/pages/symbol_search_test_page.dart';
import '../constants/app_constants.dart';

/// Configuration centrale de la navigation avec GoRouter.
///
/// Toutes les routes nommées de l'application sont définies ici,
/// ce qui permet le deep linking et la navigation déclarative.
final GoRouter appRouter = GoRouter(
  initialLocation: AppConstants.routeSplash,
  routes: [
    // Écran de démarrage / splash
    GoRoute(
      path: AppConstants.routeSplash,
      name: 'splash',
      builder: (_, __) => const _SplashRedirect(),
    ),

    // Onboarding (premier lancement)
    GoRoute(
      path: AppConstants.routeOnboarding,
      name: 'onboarding',
      builder: (_, __) => const OnboardingPage(),
    ),

    // Accueil
    GoRoute(
      path: AppConstants.routeHome,
      name: 'home',
      builder: (_, __) => const HomePage(),
    ),

    // Évaluation
    GoRoute(
      path: AppConstants.routeAssessment,
      name: 'assessment',
      builder: (_, __) => const AssessmentIntroPage(),
    ),

    // Test complet WAIS-IV
    GoRoute(
      path: '/test/complete',
      name: 'test-complete',
      builder: (_, __) => const CompleteTestOrchestratorPage(),
    ),

    // Tests individuels
    GoRoute(
      path: '/test/cubes',
      name: 'test-cubes',
      builder: (_, __) => const CubesTestPage(),
    ),
    GoRoute(
      path: '/test/matrices',
      name: 'test-matrices',
      builder: (_, __) => const MatricesTestPage(),
    ),
    GoRoute(
      path: '/test/figure-weights',
      name: 'test-figure-weights',
      builder: (_, __) => const FigureWeightsTestPage(),
    ),
    GoRoute(
      path: '/test/visual-puzzles',
      name: 'test-visual-puzzles',
      builder: (_, __) => const VisualPuzzlesTestPage(),
    ),
    GoRoute(
      path: '/test/similarities',
      name: 'test-similarities',
      builder: (_, __) => const SimilaritiesTestPage(),
    ),
    GoRoute(
      path: '/test/vocabulary',
      name: 'test-vocabulary',
      builder: (_, __) => const VocabularyTestPage(),
    ),
    GoRoute(
      path: '/test/information',
      name: 'test-information',
      builder: (_, __) => const InformationTestPage(),
    ),
    GoRoute(
      path: '/test/digit-span',
      name: 'test-digit-span',
      builder: (_, __) => const DigitSpanTestPage(),
    ),
    GoRoute(
      path: '/test/arithmetic',
      name: 'test-arithmetic',
      builder: (_, __) => const ArithmeticTestPage(),
    ),
    GoRoute(
      path: '/test/picture-span',
      name: 'test-picture-span',
      builder: (_, __) => const PictureSpanTestPage(),
    ),
    GoRoute(
      path: '/test/coding',
      name: 'test-coding',
      builder: (_, __) => const CodingTestPage(),
    ),
    GoRoute(
      path: '/test/symbol-search',
      name: 'test-symbol-search',
      builder: (_, __) => const SymbolSearchTestPage(),
    ),
    GoRoute(
      path: '/test/oral',
      name: 'test-oral',
      builder: (_, __) => const OralTestFlow(),
    ),

    // Chat IA
    GoRoute(
      path: '/chat',
      name: 'chat',
      builder: (_, __) => const MentalityChatPage(),
    ),

    // Historique résultats
    GoRoute(
      path: AppConstants.routeResults,
      name: 'results',
      builder: (_, __) => const ResultsHistoryPage(),
    ),
  ],

  // Page d'erreur par défaut
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text(
        'Page introuvable : ${state.uri.path}',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    ),
  ),
);

/// Redirige immédiatement vers /home après le splash (3 secondes).
class _SplashRedirect extends StatefulWidget {
  const _SplashRedirect();

  @override
  State<_SplashRedirect> createState() => _SplashRedirectState();
}

class _SplashRedirectState extends State<_SplashRedirect> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) context.go(AppConstants.routeHome);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.psychology, size: 120, color: Colors.white),
              const SizedBox(height: 24),
              const Text(
                'Mentality',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Évaluation cognitive adaptative',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

