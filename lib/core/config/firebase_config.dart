// lib/core/config/firebase_config.dart
//
// ════════════════════════════════════════════════════════════════════════════
//  CONFIGURATION FIREBASE — À COMPLÉTER AVANT ACTIVATION
// ════════════════════════════════════════════════════════════════════════════
//
// ÉTAPES DE MISE EN SERVICE :
//
// 1. Créer un projet Firebase sur https://console.firebase.google.com
//
// 2. Activer :
//    - Authentication → Email/Password + Google Sign-in
//    - Firestore Database (mode production, région europe-west1)
//    - (Optionnel) Storage pour les fichiers audio
//
// 3. Installer FlutterFire CLI :
//    dart pub global activate flutterfire_cli
//
// 4. Configurer automatiquement :
//    flutterfire configure --project=VOTRE_PROJECT_ID
//    (génère lib/firebase_options.dart automatiquement)
//
// 5. Ajouter les dépendances dans pubspec.yaml :
//    firebase_core: ^3.6.0
//    firebase_auth: ^5.3.1
//    cloud_firestore: ^5.4.4
//
// 6. Dans main.dart, décommenter :
//    import 'package:firebase_core/firebase_core.dart';
//    import 'firebase_options.dart';
//    // et dans _configureApp() :
//    await Firebase.initializeApp(
//      options: DefaultFirebaseOptions.currentPlatform,
//    );
//
// 7. Règles Firestore recommandées :
//    rules_version = '2';
//    service cloud.firestore {
//      match /databases/{database}/documents {
//        match /users/{userId}/results/{resultId} {
//          allow read, write: if request.auth != null
//                             && request.auth.uid == userId;
//        }
//      }
//    }
//
// ════════════════════════════════════════════════════════════════════════════

/// Constantes utilisées dans les features Firebase (Auth + Firestore).
///
/// Ces valeurs sont des noms de collections et de champs — pas des secrets.
/// Les vraies options Firebase (apiKey, appId…) sont dans firebase_options.dart
/// généré par `flutterfire configure`.
class FirebaseConfig {
  FirebaseConfig._();

  // ─── Collections Firestore ─────────────────────────────────────────────────

  /// Collection racine par utilisateur
  static const String usersCollection = 'users';

  /// Sous-collection des résultats
  static const String resultsCollection = 'results';

  // ─── Champs des documents de résultats ────────────────────────────────────

  static const String fieldFsiq = 'fsiq';
  static const String fieldVci = 'vci';
  static const String fieldVsi = 'vsi';
  static const String fieldFri = 'fri';
  static const String fieldWmi = 'wmi';
  static const String fieldPsi = 'psi';
  static const String fieldDate = 'date';
  static const String fieldAgeInMonths = 'ageInMonths';
  static const String fieldClassification = 'classification';

  // ─── Indicateur de disponibilité ──────────────────────────────────────────

  /// Passer à true après avoir configuré Firebase et décommenté l'init.
  static const bool isConfigured = false;
}
