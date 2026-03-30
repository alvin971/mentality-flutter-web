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

/// Mapping des clés admin (English slugs) vers les routes Flutter.
/// Utilisé pour le prévisualisation des tests depuis mentality-admin.
const Map<String, String> _adminTestRoutes = {
  'cubes':          '/test/cubes',
  'matrices':       '/test/matrices',
  'figure-weights': '/test/figure-weights',
  'visual-puzzles': '/test/visual-puzzles',
  'similarities':   '/test/similarities',
  'vocabulary':     '/test/vocabulary',
  'information':    '/test/information',
  'digit-span':     '/test/digit-span',
  'arithmetic':     '/test/arithmetic',
  'picture-span':   '/test/picture-span',
  'coding':         '/test/coding',
  'symbol-search':  '/test/symbol-search',
};

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
      builder: (_, state) => CubesTestPage(filterLevel: state.uri.queryParameters['level']),
    ),
    GoRoute(
      path: '/test/matrices',
      name: 'test-matrices',
      builder: (_, state) => MatricesTestPage(filterLevel: state.uri.queryParameters['level']),
    ),
    GoRoute(
      path: '/test/figure-weights',
      name: 'test-figure-weights',
      builder: (_, state) => FigureWeightsTestPage(filterLevel: state.uri.queryParameters['level']),
    ),
    GoRoute(
      path: '/test/visual-puzzles',
      name: 'test-visual-puzzles',
      builder: (_, state) => VisualPuzzlesTestPage(filterLevel: state.uri.queryParameters['level']),
    ),
    GoRoute(
      path: '/test/similarities',
      name: 'test-similarities',
      builder: (_, state) => SimilaritiesTestPage(filterLevel: state.uri.queryParameters['level']),
    ),
    GoRoute(
      path: '/test/vocabulary',
      name: 'test-vocabulary',
      builder: (_, state) => VocabularyTestPage(filterLevel: state.uri.queryParameters['level']),
    ),
    GoRoute(
      path: '/test/information',
      name: 'test-information',
      builder: (_, state) => InformationTestPage(filterLevel: state.uri.queryParameters['level']),
    ),
    GoRoute(
      path: '/test/digit-span',
      name: 'test-digit-span',
      builder: (_, state) => DigitSpanTestPage(filterLevel: state.uri.queryParameters['level']),
    ),
    GoRoute(
      path: '/test/arithmetic',
      name: 'test-arithmetic',
      builder: (_, state) => ArithmeticTestPage(filterLevel: state.uri.queryParameters['level']),
    ),
    GoRoute(
      path: '/test/picture-span',
      name: 'test-picture-span',
      builder: (_, state) => PictureSpanTestPage(filterLevel: state.uri.queryParameters['level']),
    ),
    GoRoute(
      path: '/test/coding',
      name: 'test-coding',
      builder: (_, state) => CodingTestPage(filterLevel: state.uri.queryParameters['level']),
    ),
    GoRoute(
      path: '/test/symbol-search',
      name: 'test-symbol-search',
      builder: (_, state) => SymbolSearchTestPage(filterLevel: state.uri.queryParameters['level']),
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
    // addPostFrameCallback garantit que GoRouter est monté avant la navigation.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Mode prévisualisation admin : ?adminTest=matrices&level=medium
      final params = Uri.base.queryParameters;
      final testKey = params['adminTest'];
      final level = params['level'];
      final route = testKey != null ? _adminTestRoutes[testKey] : null;
      if (route != null) {
        // Naviguer immédiatement vers le test (skip splash)
        final destination = level != null ? '$route?level=$level' : route;
        if (mounted) context.go(destination);
        return;
      }
      // Comportement normal : splash 2 secondes puis home
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) context.go(AppConstants.routeHome);
      });
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

