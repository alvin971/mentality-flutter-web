import 'package:flutter/foundation.dart';

/// Constantes globales de l'application
class AppConstants {
  AppConstants._();

  // ========================================
  // APPLICATION INFO
  // ========================================

  static const String appName = 'Mental E.T.';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Évaluation cognitive adaptative par IA';

  // ========================================
  // STORAGE KEYS
  // ========================================

  static const String keyUserProfile = 'user_profile';
  static const String keyAssessmentHistory = 'assessment_history';
  static const String keySettings = 'app_settings';
  static const String keyConsent = 'gdpr_consent';
  static const String keyLastAssessmentDate = 'last_assessment_date';
  static const String keyAuthToken = 'auth_token';
  static const String keyThemeMode = 'theme_mode';
  static const String keyLanguage = 'language';

  // ========================================
  // DATABASE
  // ========================================

  static const String databaseName = 'mentality.db';
  static const int databaseVersion = 1;

  // Tables
  static const String tableUsers = 'users';
  static const String tableAssessments = 'assessments';
  static const String tableResponses = 'responses';
  static const String tableItems = 'items';
  static const String tableResults = 'results';

  // ========================================
  // SUPABASE (admin backend)
  // ========================================

  /// URL du projet Supabase admin (visible dans Supabase Dashboard → Settings → API)
  /// Laisser vide pour désactiver la configuration distante.
  static const String supabaseUrl = 'https://supabase.0for0.com';

  /// Clé anon publique Supabase (safe à inclure côté client — RLS contrôle l'accès)
  static const String supabaseAnonKey =
      'eyJhbGciOiAiSFMyNTYiLCAidHlwIjogIkpXVCJ9.eyJyb2xlIjogImFub24iLCAiaXNzIjogInN1cGFiYXNlIiwgImlhdCI6IDE3NzM5NjE0NTIsICJleHAiOiAyMDg5MzIxNDUyfQ.zU4lqg55i1aUG-SEIz_SeVCdMI5twUyqK4W1eyVMXYo';

  // ========================================
  // API ENDPOINTS
  // ========================================

  static const String baseUrl = 'https://api.mentality.app/v1';

  /// URL du Cloudflare Worker qui proxie les appels Claude.
  /// Déployer workers/claude-proxy/ et remplacer cette valeur.
  static const String claudeWorkerUrl =
      'https://claude-proxy.YOUR_SUBDOMAIN.workers.dev';

  /// URL du Cloudflare Worker qui écrit les enregistrements audio dans R2.
  /// Déployer workers/r2-upload/ et remplacer cette valeur. Tant que l'URL
  /// reste le placeholder, l'upload est désactivé (no-op) et l'app fonctionne
  /// normalement en stockage local seulement.
  static const String r2UploadWorkerUrl =
      'https://mentality-r2-upload.YOUR_SUBDOMAIN.workers.dev';

  /// URL du Cloudflare Worker qui SIGNE le token anonyme (Ed25519).
  /// Déployer workers/tokeniser/ et remplacer cette valeur.
  /// Tant que l'URL reste le placeholder, l'émission utilise le fallback DEV
  /// local NON signé (autorisé en debug uniquement — voir TokenIssuer).
  static const String tokeniserWorkerUrl =
      'https://mentality-tokeniser.YOUR_SUBDOMAIN.workers.dev';

  /// URL du Cloudflare Worker referral (déblocage des résultats par paliers).
  /// Déployer workers/referral/ et remplacer cette valeur. Tant que l'URL
  /// reste le placeholder, le gate est désactivé (résultats affichés
  /// directement, comportement historique).
  static const String referralWorkerUrl =
      'https://mentality-referral.devgreenpro.workers.dev';

  /// Active le déblocage des résultats par paliers (parrainage + Instagram).
  /// Nécessite aussi une [referralWorkerUrl] réelle pour être effectif.
  static const bool unlockGateEnabled = true;

  /// Base des liens d'invitation partagés (route /invite?ref=<code>).
  /// Pointe sur le site vitrine (l'app web publique a été retirée) : la page
  /// affiche le code + les liens stores ; le filleul saisit le code à
  /// l'inscription dans l'app mobile.
  static const String inviteBaseUrl = 'https://mental-et.com/invite';

  /// Compte Instagram à suivre pour le dernier palier de déblocage.
  static const String instagramHandle = 'mental_e.t';
  static const String instagramUrl =
      'https://www.instagram.com/mental_e.t?igsh=b3hvM25zdHh2bm0y';

  /// Clés PUBLIQUES Ed25519 (32 octets, base64url) pour vérifier les tokens
  /// signés, indexées par `kid`. Ce n'est PAS un secret.
  /// ⚠️ Doit correspondre à la clé privée déployée dans le Worker tokeniseur.
  /// La valeur ci-dessous est la clé publique du keypair DEV — la REMPLACER si
  /// le keypair est régénéré pour la production.
  static const Map<String, String> tokenSigningPublicKeys = {
    'k1': '-2eBilftJKpyg_NHaQpXDBwuVFMA2z3JaZgXpDF_rCw',
  };

  static const String endpointAuth = '/auth';
  static const String endpointUsers = '/users';
  static const String endpointAssessments = '/assessments';
  static const String endpointItems = '/items';
  static const String endpointGenerate = '/ai/generate';
  static const String endpointSync = '/sync';

  // ========================================
  // TIMEOUTS
  // ========================================

  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // ========================================
  // PAGINATION
  // ========================================

  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // ========================================
  // EXERCISE TYPES
  // ========================================

  static const String exerciseMatrices = 'matrix_reasoning';
  static const String exerciseBalances = 'figure_weights';
  static const String exercisePuzzles = 'visual_puzzles';
  static const String exerciseCubes = 'block_design';
  static const String exerciseCoding = 'coding';
  static const String exerciseSymbols = 'symbol_search';
  static const String exerciseDigitSpan = 'digit_span';
  static const String exercisePictureMemory = 'picture_memory';
  static const String exerciseVocabulary = 'vocabulary';
  static const String exerciseSimilarities = 'similarities';
  static const String exerciseInformation = 'information';
  static const String exerciseCancellation = 'cancellation';

  // ========================================
  // AGE GROUPS
  // ========================================

  static const String ageGroupPreschool = 'preschool'; // 2-5 ans
  static const String ageGroupChild = 'child'; // 6-12 ans
  static const String ageGroupAdolescent = 'adolescent'; // 13-17 ans
  static const String ageGroupAdult = 'adult'; // 18+ ans

  // ========================================
  // UI MODES
  // ========================================

  static const String uiModePreschool = 'ui_preschool';
  static const String uiModeChild = 'ui_child';
  static const String uiModeAdult = 'ui_adult';

  // ========================================
  // ASSESSMENT STATES
  // ========================================

  static const String stateNotStarted = 'not_started';
  static const String stateInProgress = 'in_progress';
  static const String statePaused = 'paused';
  static const String stateCompleted = 'completed';
  static const String stateAbandoned = 'abandoned';

  // ========================================
  // DIFFICULTY LEVELS
  // ========================================

  static const String difficultyVeryEasy = 'very_easy';
  static const String difficultyEasy = 'easy';
  static const String difficultyMedium = 'medium';
  static const String difficultyHard = 'hard';
  static const String difficultyVeryHard = 'very_hard';

  // ========================================
  // RESPONSE TYPES
  // ========================================

  static const String responseTypeChoice = 'multiple_choice';
  static const String responseTypeInput = 'text_input';
  static const String responseTypeVoice = 'voice';
  static const String responseTypeDragDrop = 'drag_drop';
  static const String responseTypeTap = 'tap';
  static const String responseTypeDraw = 'draw';

  // ========================================
  // VALIDATION
  // ========================================

  static const int minAge = 2;
  static const int maxAge = 90;
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int maxUsernameLength = 50;

  // ========================================
  // ANIMATIONS
  // ========================================

  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 400);
  static const Duration longAnimationDuration = Duration(milliseconds: 600);

  // ========================================
  // CACHE
  // ========================================

  static const Duration cacheValidityDuration = Duration(days: 7);
  static const int maxCacheSize = 100 * 1024 * 1024; // 100 MB

  // ========================================
  // ASSETS PATHS
  // ========================================

  static const String imagesPath = 'assets/images/';
  static const String exercisesPath = 'assets/images/exercises/';
  static const String iconsPath = 'assets/images/icons/';
  static const String animationsPath = 'assets/animations/';
  static const String audioPath = 'assets/audio/';
  static const String dataPath = 'assets/data/';
  static const String normsPath = 'assets/data/norms/';
  static const String itemsPath = 'assets/data/items/';

  // ========================================
  // AUDIO
  // ========================================

  static const double defaultVolume = 0.8;
  static const double ttsRate = 0.9; // Vitesse TTS (0.5 - 2.0)
  static const double ttsPitch = 1.0; // Tonalité TTS (0.5 - 2.0)

  // ========================================
  // ACCESSIBILITY
  // ========================================

  static const double minTapTargetSize = 48.0; // Points
  static const double childTapTargetSize = 80.0; // Pour enfants

  // ========================================
  // GDPR
  // ========================================

  static const int dataRetentionDays = 365;
  static const int exportRequestProcessingDays = 30;
  static const int deletionRequestProcessingDays = 30;

  // ========================================
  // ERROR MESSAGES
  // ========================================

  static const String errorNetwork = 'Erreur de connexion réseau';
  static const String errorServer = 'Erreur serveur';
  static const String errorUnknown = 'Erreur inconnue';
  static const String errorValidation = 'Données invalides';
  static const String errorPermission = 'Permission refusée';
  static const String errorNotFound = 'Ressource introuvable';

  // ========================================
  // SUCCESS MESSAGES
  // ========================================

  static const String successSaved = 'Sauvegardé avec succès';
  static const String successCompleted = 'Complété avec succès';
  static const String successDeleted = 'Supprimé avec succès';

  // ========================================
  // ROUTES
  // ========================================

  static const String routeSplash = '/';
  static const String routeOnboarding = '/onboarding';
  static const String routeLogin = '/login';
  static const String routeRegister = '/register';
  static const String routeHome = '/home';
  static const String routeProfile = '/profile';
  static const String routeAssessment = '/assessment';
  static const String routeExercise = '/exercise';
  static const String routeResults = '/results';
  static const String routeSettings = '/settings';
  static const String routeGDPR = '/gdpr';

  // ========================================
  // FEATURE FLAGS
  // ========================================

  static const bool enableAIGeneration = true;

  /// Gate d'accès par token anonyme.
  /// `true` = le splash route directement vers /home (accès libre).
  /// `false` = vérifie la VALIDITÉ du token local (signature), route vers
  ///           /register (écran de connexion démographique) si absent/invalide.
  ///
  /// `false` = le formulaire de connexion (TokenLoginPage) s'affiche au début.
  /// Le flux téléphone/OTP est supprimé (remplacé par le token anonyme).
  static const bool kSkipRegistrationGate = false;

  /// MODE TEST : autorise un token LOCAL NON SIGNÉ en release tant que le worker
  /// tokeniseur n'est pas déployé — permet de tester l'onboarding (le formulaire
  /// + le flux) sur TestFlight sans backend. ⚠️ Repasser à `false` AVANT la prod
  /// (une fois les workers déployés) pour n'accepter que des tokens signés.
  static const bool kAllowUnsignedTokenInRelease = true;
  static const bool enableVoiceRecognition = true;
  static const bool enable3DCubes = true;
  static const bool enableAnalytics = true;
  static const bool enableCrashReporting = true;

  // ========================================
  // DEVELOPMENT
  // ========================================

  /// Automatiquement false en release build (flutter build web).
  static bool get isDebugMode => kDebugMode;
  static bool get enableLogging => kDebugMode;
  static const bool enablePerformanceMonitoring = false;
}
