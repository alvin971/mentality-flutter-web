import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/l10n/gen/app_localizations.dart';
import 'core/l10n/locale_notifier.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_typography.dart';
import 'core/theme/theme_notifier.dart';
import 'core/router/app_router.dart';
import 'core/constants/app_constants.dart';
import 'core/services/remote_config_service.dart';
import 'features/waiting_event/_shared/data/event_upload_service.dart';
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

  // Rejeu des réponses de l'événement que le serveur n'a pas encore
  // confirmées. Lancé APRÈS la config (le stockage chiffré doit être prêt) et
  // sans être attendu : le démarrage ne dépend pas du réseau. Sans
  // consentement, ou sans worker déployé, l'appel ne fait rien.
  EventUploadService.instance.retryPending().catchError(
        (_) => const <String, EventUploadOutcome>{},
      );

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

  // Charger le thème et la langue sauvegardés
  await themeNotifier.load();
  await localeNotifier.load();

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
          builder: (_, themeMode, __) => ValueListenableBuilder<Locale>(
            valueListenable: localeNotifier,
            builder: (_, locale, __) => MaterialApp.router(
              onGenerateTitle: (context) =>
                  AppLocalizations.of(context).appTitle,
              debugShowCheckedModeBanner: false,
              locale: locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: themeMode,
              routerConfig: appRouter,
            ),
          ),
        );
      },
    );
  }



}
