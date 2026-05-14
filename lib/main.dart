import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_typography.dart';
import 'core/theme/theme_notifier.dart';
import 'core/router/app_router.dart';
import 'core/constants/app_constants.dart';
import 'core/services/remote_config_service.dart';
import 'services/data_collection_service.dart';
import 'services/session_history_service.dart';
import 'services/session_persistence_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Capture les erreurs Flutter non gérées pour éviter l'écran blanc.
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };

  try {
    await _configureApp();
  } catch (_) {
    // Ne pas bloquer le démarrage si la config échoue
  }

  runApp(const MentalityApp());
}

Future<void> _configureApp() async {
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
  try {
    await Hive.initFlutter();
    await DataCollectionService.instance.initialize();
    // Les autres boxes partagent la même clé AES générée par DataCollectionService
    final cipher = await DataCollectionService.buildSharedCipher();
    await SessionPersistenceService.instance.initialize(encryptionCipher: cipher);
    await SessionHistoryService.instance.initialize(encryptionCipher: cipher);
  } catch (_) {
    // Ne pas bloquer le démarrage si Hive échoue
  }

  // Initialiser Supabase (auth OTP email + phone)
  try {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
  } catch (_) {
    // Ne pas bloquer le démarrage si l'init Supabase échoue
  }

  // Charger le thème sauvegardé
  await themeNotifier.load();

  // Charger la configuration distante depuis Supabase admin
  // Fallback automatique sur les valeurs locales si inaccessible
  await RemoteConfigService.instance.loadConfig(
    supabaseUrl: AppConstants.supabaseUrl,
    supabaseAnonKey: AppConstants.supabaseAnonKey,
  );

  // TODO (Batch 12): Initialiser Firebase
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class MentalityApp extends StatelessWidget {
  const MentalityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: themeNotifier,
          builder: (_, themeMode, __) => MaterialApp.router(
            title: 'Mental E.T.',
            debugShowCheckedModeBanner: false,
            theme: _buildLightTheme(),
            darkTheme: _buildDarkTheme(),
            themeMode: themeMode,
            routerConfig: appRouter,
          ),
        );
      },
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        onPrimary: AppColors.background,
        secondary: AppColors.secondary,
        tertiary: AppColors.tertiary,
        error: AppColors.error,
        onError: AppColors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        onSurfaceVariant: AppColors.textSecondary,
        outline: AppColors.textTertiary,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: AppText.h3(),
        toolbarHeight: 56,
        iconTheme: const IconThemeData(
          color: AppColors.textPrimary,
          size: 20,
        ),
      ),
      textTheme: AppText.buildTextTheme(),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary, // Vert sauge Kepler
          foregroundColor: AppColors.background,
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 14.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6.r),
          ),
          textStyle: AppText.button(),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.07)),
        ),
        color: AppColors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4.r),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4.r),
          borderSide: BorderSide(color: AppColors.grey200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4.r),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4.r),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.grey200,
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
        primary: AppColors.primaryLightDark,
        onPrimary: AppColors.backgroundDark,
        secondary: AppColors.indexWMIDark,
        tertiary: AppColors.indexPSIDark,
        error: AppColors.errorDark,
        onError: AppColors.backgroundDark,
        surface: AppColors.surfaceDark,
        onSurface: AppColors.textPrimaryDark,
        onSurfaceVariant: AppColors.textSecondaryDark,
        outline: AppColors.textTertiaryDark,
      ),
      scaffoldBackgroundColor: AppColors.backgroundDark,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.textPrimaryDark,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: AppText.h3(color: AppColors.textPrimaryDark),
        toolbarHeight: 56,
        iconTheme: const IconThemeData(
          color: AppColors.textPrimaryDark,
          size: 20,
        ),
      ),
      textTheme: AppText.buildTextTheme().apply(
        bodyColor: AppColors.textPrimaryDark,
        displayColor: AppColors.textPrimaryDark,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryLightDark,
          foregroundColor: AppColors.backgroundDark,
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 14.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6.r),
          ),
          textStyle: AppText.button(color: AppColors.backgroundDark),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryLightDark,
          side: const BorderSide(color: AppColors.primaryLightDark, width: 1.5),
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6.r),
          ),
          textStyle: AppText.button(color: AppColors.primaryLightDark),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        color: AppColors.cardDark,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDark,
        hintStyle: AppText.body(color: AppColors.textSecondaryDark),
        labelStyle: AppText.body(color: AppColors.textSecondaryDark),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4.r),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4.r),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4.r),
          borderSide:
              const BorderSide(color: AppColors.primaryLightDark, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4.r),
          borderSide: const BorderSide(color: AppColors.errorDark),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: 0.12),
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.primaryLightDark,
        linearTrackColor: Colors.white.withValues(alpha: 0.12),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceDark,
        titleTextStyle: AppText.h3(color: AppColors.textPrimaryDark),
        contentTextStyle: AppText.body(color: AppColors.textPrimaryDark),
      ),
    );
  }

}
