import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme/app_colors.dart';
import 'services/data_collection_service.dart';
import 'features/exercises_implementations/cubes/presentation/pages/cubes_test_page.dart';
import 'features/exercises_implementations/matrices/presentation/pages/matrices_test_page.dart';
import 'features/exercises_implementations/figure_weights/presentation/pages/figure_weights_test_page.dart';
import 'features/exercises_implementations/visual_puzzles/presentation/pages/visual_puzzles_test_page.dart';
import 'features/exercises_implementations/similarities/presentation/pages/similarities_test_page.dart';
import 'features/exercises_implementations/vocabulary/presentation/pages/vocabulary_test_page.dart';
import 'features/exercises_implementations/information/presentation/pages/information_test_page.dart';
import 'features/exercises_implementations/digit_span/presentation/pages/digit_span_test_page.dart';
import 'features/exercises_implementations/arithmetic/presentation/pages/arithmetic_test_page.dart';
import 'features/exercises_implementations/picture_span/presentation/pages/picture_span_test_page.dart';
import 'features/exercises_implementations/coding/presentation/pages/coding_test_page.dart';
import 'features/exercises_implementations/symbol_search/presentation/pages/symbol_search_test_page.dart';
import 'features/complete_test/presentation/pages/complete_test_orchestrator_page.dart';
import 'features/chat/presentation/pages/mentality_chat_page.dart';
import 'features/data_collection/oral_test_flow.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configuration du système
  await _configureApp();

  runApp(const MentalityApp());
}

/// Configure les paramètres de l'application au démarrage
Future<void> _configureApp() async {
  // Orientation portrait uniquement
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Barre de statut transparente
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Persistance locale (IndexedDB sur web)
  await Hive.initFlutter();
  await DataCollectionService.instance.initialize();

  // TODO: Initialiser Firebase
  // await Firebase.initializeApp();

  // TODO: Initialiser l'injection de dépendances
  // await configureDependencies();
}

class MentalityApp extends StatelessWidget {
  const MentalityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone 11 Pro
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'Mentality',
          debugShowCheckedModeBanner: false,

          // Theme
          theme: _buildLightTheme(),
          darkTheme: _buildDarkTheme(),
          themeMode: ThemeMode.light,

          // Localisation (désactivée temporairement)
          // locale: const Locale('fr', 'FR'),
          // supportedLocales: const [
          //   Locale('fr', 'FR'),
          //   Locale('en', 'US'),
          // ],

          // Navigation
          home: const SplashScreen(),

          // TODO: Configurer GoRouter
          // routerConfig: appRouter,
        );
      },
    );
  }

  /// Construit le thème clair
  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        tertiary: AppColors.tertiary,
        error: AppColors.error,
        surface: AppColors.surface,
        background: AppColors.background,
      ),
      scaffoldBackgroundColor: AppColors.background,

      // App Bar
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.grey900,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),

      // Typography
      textTheme: _buildTextTheme(),

      // Boutons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          textStyle: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Cards
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: BorderSide(color: AppColors.grey200, width: 1),
        ),
        color: AppColors.white,
      ),

      // Input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.grey50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: AppColors.grey200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),

      // Progress Indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.grey200,
      ),
    );
  }

  /// Construit le thème sombre
  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
        primary: AppColors.primaryLight,
        secondary: AppColors.secondaryLight,
        tertiary: AppColors.tertiaryLight,
        error: AppColors.errorLight,
        surface: AppColors.surfaceDark,
        background: AppColors.backgroundDark,
      ),
      scaffoldBackgroundColor: AppColors.backgroundDark,
    );
  }

  /// Construit la typographie
  TextTheme _buildTextTheme() {
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 32.sp,
        fontWeight: FontWeight.bold,
        color: AppColors.grey900,
      ),
      displayMedium: TextStyle(
        fontSize: 28.sp,
        fontWeight: FontWeight.bold,
        color: AppColors.grey900,
      ),
      displaySmall: TextStyle(
        fontSize: 24.sp,
        fontWeight: FontWeight.bold,
        color: AppColors.grey900,
      ),
      headlineLarge: TextStyle(
        fontSize: 22.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.grey900,
      ),
      headlineMedium: TextStyle(
        fontSize: 20.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.grey900,
      ),
      headlineSmall: TextStyle(
        fontSize: 18.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.grey900,
      ),
      titleLarge: TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.grey900,
      ),
      titleMedium: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
        color: AppColors.grey900,
      ),
      titleSmall: TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.w500,
        color: AppColors.grey900,
      ),
      bodyLarge: TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.normal,
        color: AppColors.grey700,
      ),
      bodyMedium: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.normal,
        color: AppColors.grey700,
      ),
      bodySmall: TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.normal,
        color: AppColors.grey600,
      ),
      labelLarge: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
        color: AppColors.grey900,
      ),
      labelMedium: TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.w500,
        color: AppColors.grey700,
      ),
      labelSmall: TextStyle(
        fontSize: 10.sp,
        fontWeight: FontWeight.w500,
        color: AppColors.grey600,
      ),
    );
  }
}

/// Écran de démarrage avec navigation automatique
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    // Simule un chargement (initialisation app, vérification auth, etc.)
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.psychology,
                size: 120.sp,
                color: Colors.white,
              ),
              SizedBox(height: 24.h),
              Text(
                'Mentality',
                style: TextStyle(
                  fontSize: 48.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Évaluation cognitive adaptative',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              SizedBox(height: 48.h),
              const CircularProgressIndicator(
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Page d'accueil principale
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mentality'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
              Text(
                'Bienvenue',
                style: Theme.of(context).textTheme.displayLarge,
              ),
              SizedBox(height: 8.h),
              Text(
                'Découvrez votre profil cognitif à travers une évaluation scientifique adaptative.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              SizedBox(height: 32.h),

              // Card : Nouvelle évaluation
              Card(
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AssessmentIntroPage(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16.r),
                  child: Padding(
                    padding: EdgeInsets.all(20.w),
                    child: Row(
                      children: [
                        Container(
                          width: 60.w,
                          height: 60.w,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Icon(
                            Icons.play_arrow_rounded,
                            size: 32.sp,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Commencer une évaluation',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'Durée : 30-45 minutes',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.grey600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 20.sp,
                          color: AppColors.grey400,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16.h),

              // Card : Résultats précédents
              Card(
                child: InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(16.r),
                  child: Padding(
                    padding: EdgeInsets.all(20.w),
                    child: Row(
                      children: [
                        Container(
                          width: 60.w,
                          height: 60.w,
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Icon(
                            Icons.bar_chart_rounded,
                            size: 32.sp,
                            color: AppColors.secondary,
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mes résultats',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'Historique des évaluations',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.grey600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 20.sp,
                          color: AppColors.grey400,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16.h),

              // Card : Collecte audio
              Card(
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const OralTestFlow(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16.r),
                  child: Padding(
                    padding: EdgeInsets.all(20.w),
                    child: Row(
                      children: [
                        Container(
                          width: 60.w,
                          height: 60.w,
                          decoration: BoxDecoration(
                            color: Colors.teal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Icon(
                            Icons.record_voice_over,
                            size: 32.sp,
                            color: Colors.teal,
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Contribuer à la recherche',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'Collecte vocale en français · 5 textes',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.grey600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 20.sp,
                          color: AppColors.grey400,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16.h),

              // Card : Parler avec Mentality
              Card(
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MentalityChatPage(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16.r),
                  child: Padding(
                    padding: EdgeInsets.all(20.w),
                    child: Row(
                      children: [
                        Container(
                          width: 60.w,
                          height: 60.w,
                          decoration: BoxDecoration(
                            color: AppColors.tertiary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Icon(
                            Icons.chat_bubble_outline,
                            size: 32.sp,
                            color: AppColors.tertiary,
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Parler avec Mentality',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'Assistant IA pour vos questions',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.grey600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 20.sp,
                          color: AppColors.grey400,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 32.h),

              // Section : À propos
              Text(
                'À propos',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 12.h),
              _InfoTile(
                icon: Icons.psychology_outlined,
                title: '12 types d\'exercices',
                subtitle: 'Évaluation complète des capacités cognitives',
              ),
              SizedBox(height: 8.h),
              _InfoTile(
                icon: Icons.auto_awesome,
                title: 'IA adaptative',
                subtitle: 'Difficulté ajustée en temps réel',
              ),
              SizedBox(height: 8.h),
              _InfoTile(
                icon: Icons.verified_user_outlined,
                title: 'Scientifiquement validé',
                subtitle: 'Inspiré des échelles Wechsler',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget : Tile d'information
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 24.sp,
          color: AppColors.primary,
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Page d'introduction à l'évaluation
class AssessmentIntroPage extends StatelessWidget {
  const AssessmentIntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle évaluation'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image/Illustration
              Center(
                child: Container(
                  width: 200.w,
                  height: 200.w,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(100.r),
                  ),
                  child: Icon(
                    Icons.psychology,
                    size: 100.sp,
                    color: AppColors.primary,
                  ),
                ),
              ),
              SizedBox(height: 32.h),

              // Titre
              Text(
                'Évaluation cognitive',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              SizedBox(height: 16.h),

              // Description
              Text(
                'Cette évaluation mesure vos capacités cognitives à travers 5 domaines :',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              SizedBox(height: 24.h),

              // Liste des domaines
              _DomainTile(
                icon: Icons.chat_bubble_outline,
                title: 'Compréhension Verbale',
                color: AppColors.indexVCI,
              ),
              SizedBox(height: 12.h),
              _DomainTile(
                icon: Icons.view_in_ar_outlined,
                title: 'Raisonnement Visuo-Spatial',
                color: AppColors.indexVSI,
              ),
              SizedBox(height: 12.h),
              _DomainTile(
                icon: Icons.extension_outlined,
                title: 'Raisonnement Fluide',
                color: AppColors.indexFRI,
              ),
              SizedBox(height: 12.h),
              _DomainTile(
                icon: Icons.memory_outlined,
                title: 'Mémoire de Travail',
                color: AppColors.indexWMI,
              ),
              SizedBox(height: 12.h),
              _DomainTile(
                icon: Icons.speed_outlined,
                title: 'Vitesse de Traitement',
                color: AppColors.indexPSI,
              ),
              SizedBox(height: 32.h),

              // Informations
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppColors.info.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.info,
                      size: 24.sp,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        'Durée estimée : 30-45 minutes\nAssurez-vous d\'être dans un environnement calme.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.info,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),

              // Bouton TEST COMPLET (mis en avant)
              Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.success, AppColors.success.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 72.h,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CompleteTestOrchestratorPage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.psychology, size: 28.sp),
                          SizedBox(width: 12.w),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TEST COMPLET WAIS-IV',
                                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Tous les subtests (60-90 min)',
                                style: TextStyle(fontSize: 12.sp),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 24.h),

              // Séparateur
              Row(
                children: [
                  Expanded(child: Divider(color: AppColors.grey300)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Text(
                      'OU tests individuels',
                      style: TextStyle(fontSize: 14.sp, color: AppColors.grey600),
                    ),
                  ),
                  Expanded(child: Divider(color: AppColors.grey300)),
                ],
              ),

              SizedBox(height: 16.h),

              // Boutons de sélection des tests individuels
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CubesTestPage(),
                      ),
                    );
                  },
                  child: const Text('Test des Cubes (Block Design)'),
                ),
              ),
              SizedBox(height: 12.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MatricesTestPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.indexFRI,
                  ),
                  child: const Text('Test des Matrices Progressives'),
                ),
              ),
              SizedBox(height: 12.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FigureWeightsTestPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.indexFRI,
                  ),
                  child: const Text('Test des Balances Quantitatives'),
                ),
              ),
              SizedBox(height: 12.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const VisualPuzzlesTestPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.indexVSI,
                  ),
                  child: const Text('Test des Puzzles Visuels'),
                ),
              ),
              SizedBox(height: 12.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SimilaritiesTestPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.indexVCI,
                  ),
                  child: const Text('Test des Similitudes'),
                ),
              ),
              SizedBox(height: 12.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const VocabularyTestPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.indexVCI,
                  ),
                  child: const Text('Test de Vocabulaire'),
                ),
              ),
              SizedBox(height: 12.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const InformationTestPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.indexVCI,
                  ),
                  child: const Text('Test d\'Information'),
                ),
              ),
              SizedBox(height: 12.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DigitSpanTestPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.indexWMI,
                  ),
                  child: const Text('Test de Mémoire des Chiffres'),
                ),
              ),
              SizedBox(height: 12.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ArithmeticTestPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.indexWMI,
                  ),
                  child: const Text('Test d\'Arithmétique'),
                ),
              ),
              SizedBox(height: 12.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PictureSpanTestPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.indexWMI,
                  ),
                  child: const Text('Test de Mémoire des Images'),
                ),
              ),
              SizedBox(height: 12.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CodingTestPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.indexPSI,
                  ),
                  child: const Text('Test de Code'),
                ),
              ),
              SizedBox(height: 12.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SymbolSearchTestPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.indexPSI,
                  ),
                  child: const Text('Test de Recherche de Symboles'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget : Tile de domaine cognitif
class _DomainTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _DomainTile({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(
            icon,
            size: 20.sp,
            color: color,
          ),
        ),
        SizedBox(width: 12.w),
        Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }
}
