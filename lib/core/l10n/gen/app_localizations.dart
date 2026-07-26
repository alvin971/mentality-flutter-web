import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('en', 'GB'),
    Locale('es'),
    Locale('fr'),
    Locale('pt')
  ];

  /// No description provided for @appTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mental E.T.'**
  String get appTitle;

  /// No description provided for @languageSwitcherTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Changer de langue'**
  String get languageSwitcherTooltip;

  /// No description provided for @commonValidate.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get commonValidate;

  /// No description provided for @commonNext.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get commonNext;

  /// No description provided for @commonBack.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get commonBack;

  /// No description provided for @commonContinue.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get commonContinue;

  /// No description provided for @commonStart.
  ///
  /// In fr, this message translates to:
  /// **'Commencer'**
  String get commonStart;

  /// No description provided for @commonSkip.
  ///
  /// In fr, this message translates to:
  /// **'Passer'**
  String get commonSkip;

  /// No description provided for @commonCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get commonCancel;

  /// No description provided for @commonClose.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get commonClose;

  /// No description provided for @commonRetry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get commonRetry;

  /// No description provided for @commonLoading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement...'**
  String get commonLoading;

  /// No description provided for @commonError.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue'**
  String get commonError;

  /// No description provided for @commonYes.
  ///
  /// In fr, this message translates to:
  /// **'Oui'**
  String get commonYes;

  /// No description provided for @commonNo.
  ///
  /// In fr, this message translates to:
  /// **'Non'**
  String get commonNo;

  /// No description provided for @commonOk.
  ///
  /// In fr, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonFinish.
  ///
  /// In fr, this message translates to:
  /// **'Terminer'**
  String get commonFinish;

  /// No description provided for @commonSeconds.
  ///
  /// In fr, this message translates to:
  /// **'{count} s'**
  String commonSeconds(int count);

  /// Case à cocher OBLIGATOIRE du consentement audio
  ///
  /// In fr, this message translates to:
  /// **'J\'autorise l\'enregistrement de ma voix et son analyse, le temps de réaliser ce test. (obligatoire)'**
  String get oralConsentRequiredCheckbox;

  /// Case à cocher OPTIONNELLE du consentement à la réutilisation commerciale
  ///
  /// In fr, this message translates to:
  /// **'J\'autorise aussi la réutilisation de mes enregistrements, sous forme anonymisée, à des fins de recherche et commerciales — y compris leur cession à des tiers. (facultatif)'**
  String get oralConsentCommercialCheckbox;

  /// Indice affiché tant que la case obligatoire n'est pas cochée
  ///
  /// In fr, this message translates to:
  /// **'Cochez la première case pour pouvoir commencer le test.'**
  String get oralConsentRequiredHint;

  /// Lien vers la politique de confidentialité sur l'écran de consentement
  ///
  /// In fr, this message translates to:
  /// **'Lire la politique de confidentialité'**
  String get oralConsentPrivacyLink;

  /// Matrices — message de règle de discontinuation après 3 échecs
  ///
  /// In fr, this message translates to:
  /// **'3 échecs consécutifs - Test terminé (WAIS-IV)'**
  String get matDiscontinue3;

  /// Titre de la page d'introduction au bilan cognitif
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle évaluation'**
  String get assessIntroTitle;

  /// Eyebrow (sur-titre) de la page d'introduction au bilan
  ///
  /// In fr, this message translates to:
  /// **'BILAN COGNITIF'**
  String get assessIntroEyebrow;

  /// Titre hero ligne 1 de la page d'intro évaluation
  ///
  /// In fr, this message translates to:
  /// **'Cinq indices,'**
  String get assessIntroHero1;

  /// Titre hero ligne 2 (italique) de la page d'intro évaluation
  ///
  /// In fr, this message translates to:
  /// **'une mesure.'**
  String get assessIntroHero2;

  /// Paragraphe descriptif de l'intro évaluation
  ///
  /// In fr, this message translates to:
  /// **'Cette évaluation mesure vos capacités cognitives à travers six domaines issus du WAIS-IV. Un score global (FSIQ) en est la synthèse.'**
  String get assessIntroDescription;

  /// En-tête de la carte listant les domaines mesurés
  ///
  /// In fr, this message translates to:
  /// **'DOMAINES MESURÉS'**
  String get assessDomainsHeader;

  /// Libellé du domaine VCI
  ///
  /// In fr, this message translates to:
  /// **'Compréhension Verbale'**
  String get assessDomainVci;

  /// Libellé du domaine VSI
  ///
  /// In fr, this message translates to:
  /// **'Raisonnement Visuo-Spatial'**
  String get assessDomainVsi;

  /// Libellé du domaine FRI
  ///
  /// In fr, this message translates to:
  /// **'Raisonnement Fluide'**
  String get assessDomainFri;

  /// Libellé du domaine WMI
  ///
  /// In fr, this message translates to:
  /// **'Mémoire de Travail'**
  String get assessDomainWmi;

  /// Libellé du domaine PSI
  ///
  /// In fr, this message translates to:
  /// **'Vitesse de Traitement'**
  String get assessDomainPsi;

  /// Libellé du domaine Langage Oral (LO)
  ///
  /// In fr, this message translates to:
  /// **'Langage Oral'**
  String get assessDomainLo;

  /// En-tête de la carte de consignes avant le bilan
  ///
  /// In fr, this message translates to:
  /// **'AVANT DE COMMENCER'**
  String get assessBeforeStartHeader;

  /// Texte de consigne avant le bilan
  ///
  /// In fr, this message translates to:
  /// **'Durée estimée 60 à 90 minutes. Calme et concentration requis.'**
  String get assessBeforeStartBody;

  /// Bouton pour lancer le bilan complet
  ///
  /// In fr, this message translates to:
  /// **'Lancer le bilan complet'**
  String get assessLaunchFullAssessment;

  /// Séparateur entre bilan complet et subtests individuels
  ///
  /// In fr, this message translates to:
  /// **'OU SUBTEST INDIVIDUEL'**
  String get assessOrIndividualSubtest;

  /// Libellé du subtest Cubes dans la liste des tests individuels
  ///
  /// In fr, this message translates to:
  /// **'Cubes (Block Design)'**
  String get assessSubtestCubes;

  /// Libellé du subtest Matrices dans la liste des tests individuels
  ///
  /// In fr, this message translates to:
  /// **'Matrices Progressives'**
  String get assessSubtestMatrices;

  /// Libellé du subtest Balances dans la liste des tests individuels
  ///
  /// In fr, this message translates to:
  /// **'Balances Quantitatives'**
  String get assessSubtestFigureWeights;

  /// Libellé du subtest Puzzles Visuels
  ///
  /// In fr, this message translates to:
  /// **'Puzzles Visuels'**
  String get assessSubtestVisualPuzzles;

  /// Libellé du subtest Similitudes
  ///
  /// In fr, this message translates to:
  /// **'Similitudes'**
  String get assessSubtestSimilarities;

  /// Libellé du subtest Vocabulaire
  ///
  /// In fr, this message translates to:
  /// **'Vocabulaire'**
  String get assessSubtestVocabulary;

  /// Libellé du subtest Information
  ///
  /// In fr, this message translates to:
  /// **'Information'**
  String get assessSubtestInformation;

  /// Libellé du subtest Mémoire des Chiffres
  ///
  /// In fr, this message translates to:
  /// **'Mémoire des Chiffres'**
  String get assessSubtestDigitSpan;

  /// Libellé du subtest Arithmétique
  ///
  /// In fr, this message translates to:
  /// **'Arithmétique'**
  String get assessSubtestArithmetic;

  /// Libellé du subtest Mémoire des Images
  ///
  /// In fr, this message translates to:
  /// **'Mémoire des Images'**
  String get assessSubtestPictureSpan;

  /// Libellé du subtest Code
  ///
  /// In fr, this message translates to:
  /// **'Code'**
  String get assessSubtestCoding;

  /// Libellé du subtest Recherche de Symboles
  ///
  /// In fr, this message translates to:
  /// **'Recherche de Symboles'**
  String get assessSubtestSymbolSearch;

  /// Libellé du subtest Compréhension Orale
  ///
  /// In fr, this message translates to:
  /// **'Compréhension Orale'**
  String get assessSubtestOralComprehension;

  /// Titre AppBar de la page de connexion (mode connexion)
  ///
  /// In fr, this message translates to:
  /// **'Connexion'**
  String get authLoginTitle;

  /// Titre/bouton mode création de compte
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte'**
  String get authCreateAccount;

  /// Bouton de soumission en mode connexion
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get authSignIn;

  /// Sous-titre d'en-tête en mode inscription
  ///
  /// In fr, this message translates to:
  /// **'Créez un compte pour sauvegarder vos résultats'**
  String get authHeaderSubtitleRegister;

  /// Sous-titre d'en-tête en mode connexion
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous pour accéder à votre historique'**
  String get authHeaderSubtitleLogin;

  /// Libellé du champ e-mail
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail'**
  String get authEmailLabel;

  /// Libellé du champ mot de passe
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get authPasswordLabel;

  /// Message de validation pour un champ vide
  ///
  /// In fr, this message translates to:
  /// **'Champ obligatoire'**
  String get authFieldRequired;

  /// Message de validation pour e-mail invalide
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail invalide'**
  String get authEmailInvalid;

  /// Message de validation pour mot de passe trop court
  ///
  /// In fr, this message translates to:
  /// **'Minimum 8 caractères'**
  String get authPasswordMinLength;

  /// Séparateur 'ou' entre connexion email et Google
  ///
  /// In fr, this message translates to:
  /// **'ou'**
  String get authOrDivider;

  /// Bouton de connexion via Google
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec Google'**
  String get authContinueWithGoogle;

  /// Lien pour basculer vers le mode connexion
  ///
  /// In fr, this message translates to:
  /// **'Déjà un compte ? Se connecter'**
  String get authToggleToLogin;

  /// Lien pour basculer vers le mode inscription
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de compte ? S\'inscrire'**
  String get authToggleToRegister;

  /// Message d'erreur quand Firebase n'est pas configuré (formulaire e-mail)
  ///
  /// In fr, this message translates to:
  /// **'Firebase n\'est pas encore configuré. Suivez les instructions dans firebase_config.dart.'**
  String get authFirebaseNotConfiguredFull;

  /// Message d'erreur court quand Firebase n'est pas configuré (Google)
  ///
  /// In fr, this message translates to:
  /// **'Firebase n\'est pas encore configuré.'**
  String get authFirebaseNotConfigured;

  /// Titre de la page d'historique des résultats
  ///
  /// In fr, this message translates to:
  /// **'Mes résultats'**
  String get histTitle;

  /// Eyebrow de la page d'historique
  ///
  /// In fr, this message translates to:
  /// **'HISTORIQUE'**
  String get histEyebrow;

  /// Titre du dialogue de confirmation de suppression
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce résultat ?'**
  String get histDeleteResultTitle;

  /// Corps du dialogue de confirmation de suppression
  ///
  /// In fr, this message translates to:
  /// **'Cette action est irréversible.'**
  String get histDeleteResultBody;

  /// Bouton de confirmation de suppression
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get histDelete;

  /// Âge en années affiché dans l'historique
  ///
  /// In fr, this message translates to:
  /// **'{age} ans'**
  String histAgeYears(int age);

  /// Libellé de la ligne du QI total dans le détail d'un résultat
  ///
  /// In fr, this message translates to:
  /// **'QI Total (FSIQ)'**
  String get histScoreFsiq;

  /// Libellé de la ligne VCI dans le détail d'un résultat
  ///
  /// In fr, this message translates to:
  /// **'VCI — Verbal'**
  String get histScoreVci;

  /// Libellé de la ligne VSI dans le détail d'un résultat
  ///
  /// In fr, this message translates to:
  /// **'VSI — Visuo-Spatial'**
  String get histScoreVsi;

  /// Libellé de la ligne FRI dans le détail d'un résultat
  ///
  /// In fr, this message translates to:
  /// **'FRI — Raisonnement'**
  String get histScoreFri;

  /// Libellé de la ligne WMI dans le détail d'un résultat
  ///
  /// In fr, this message translates to:
  /// **'WMI — Mémoire'**
  String get histScoreWmi;

  /// Libellé de la ligne PSI dans le détail d'un résultat
  ///
  /// In fr, this message translates to:
  /// **'PSI — Vitesse'**
  String get histScorePsi;

  /// Eyebrow de l'état vide de l'historique
  ///
  /// In fr, this message translates to:
  /// **'AUCUN RÉSULTAT'**
  String get histEmptyEyebrow;

  /// Titre hero ligne 1 de l'état vide
  ///
  /// In fr, this message translates to:
  /// **'Votre historique'**
  String get histEmptyHero1;

  /// Titre hero ligne 2 (italique) de l'état vide
  ///
  /// In fr, this message translates to:
  /// **'vous attend.'**
  String get histEmptyHero2;

  /// Texte descriptif de l'état vide de l'historique
  ///
  /// In fr, this message translates to:
  /// **'Complétez votre première évaluation WAIS-IV pour voir vos résultats apparaître ici.'**
  String get histEmptyDescription;

  /// Bouton pour démarrer une évaluation depuis l'état vide
  ///
  /// In fr, this message translates to:
  /// **'Commencer une évaluation'**
  String get histStartAssessment;

  /// Titre de l'écran d'introduction au test complet
  ///
  /// In fr, this message translates to:
  /// **'Test complet'**
  String get ctIntroTitle;

  /// Titre hero ligne 1 de l'intro test complet
  ///
  /// In fr, this message translates to:
  /// **'Douze subtests,'**
  String get ctIntroHero1;

  /// Titre hero ligne 2 (italique) de l'intro test complet
  ///
  /// In fr, this message translates to:
  /// **'quatre indices.'**
  String get ctIntroHero2;

  /// Paragraphe descriptif de l'intro test complet
  ///
  /// In fr, this message translates to:
  /// **'Évaluation cognitive complète standardisée. Les sous-tests s\'enchaînent automatiquement.'**
  String get ctIntroDescription;

  /// Eyebrow de la carte durée
  ///
  /// In fr, this message translates to:
  /// **'DURÉE'**
  String get ctIntroDurationEyebrow;

  /// Titre de la carte durée
  ///
  /// In fr, this message translates to:
  /// **'60 à 90 minutes'**
  String get ctIntroDurationTitle;

  /// Corps de la carte durée
  ///
  /// In fr, this message translates to:
  /// **'Prévoyez une plage de temps continue.'**
  String get ctIntroDurationBody;

  /// Eyebrow de la carte contenu
  ///
  /// In fr, this message translates to:
  /// **'CONTENU'**
  String get ctIntroContentEyebrow;

  /// Titre de la carte contenu
  ///
  /// In fr, this message translates to:
  /// **'12 subtests inclus'**
  String get ctIntroContentTitle;

  /// Liste des subtests dans la carte contenu
  ///
  /// In fr, this message translates to:
  /// **'Cubes · Similitudes · Mémoire · Matrices · Vocabulaire · Arithmétique · Symboles · Puzzles · Information · Code · Images · Balances.'**
  String get ctIntroContentBody;

  /// Eyebrow de la carte avertissement
  ///
  /// In fr, this message translates to:
  /// **'IMPORTANT'**
  String get ctIntroImportantEyebrow;

  /// Titre de la carte avertissement
  ///
  /// In fr, this message translates to:
  /// **'Enchaînement automatique'**
  String get ctIntroImportantTitle;

  /// Corps de la carte avertissement
  ///
  /// In fr, this message translates to:
  /// **'Les tests se lanceront l\'un après l\'autre. Assurez-vous d\'avoir suffisamment de temps.'**
  String get ctIntroImportantBody;

  /// En-tête de la carte de saisie de l'âge
  ///
  /// In fr, this message translates to:
  /// **'ÂGE DU PATIENT'**
  String get ctPatientAgeHeader;

  /// Indication sous le champ d'âge
  ///
  /// In fr, this message translates to:
  /// **'Requis pour les normes (16 à 90 ans)'**
  String get ctPatientAgeHint;

  /// Suffixe du champ de saisie de l'âge
  ///
  /// In fr, this message translates to:
  /// **'ANS'**
  String get ctAgeSuffix;

  /// Message d'erreur quand l'âge saisi est hors plage
  ///
  /// In fr, this message translates to:
  /// **'Âge entre 16 et 90 ans'**
  String get ctAgeRangeError;

  /// Bouton pour lancer le test complet
  ///
  /// In fr, this message translates to:
  /// **'Lancer le test complet'**
  String get ctLaunchFullTest;

  /// Titre de l'écran de progression du test complet
  ///
  /// In fr, this message translates to:
  /// **'Test en cours'**
  String get ctRunningTitle;

  /// Libellé de la barre de progression globale
  ///
  /// In fr, this message translates to:
  /// **'PROGRESSION GLOBALE'**
  String get ctGlobalProgress;

  /// Libellé indiquant le prochain subtest
  ///
  /// In fr, this message translates to:
  /// **'PROCHAIN SUBTEST'**
  String get ctNextSubtest;

  /// Texte affiché pendant le lancement du prochain subtest
  ///
  /// In fr, this message translates to:
  /// **'Lancement…'**
  String get ctLaunching;

  /// Titre de l'écran de calcul des résultats
  ///
  /// In fr, this message translates to:
  /// **'Calcul des résultats'**
  String get ctComputingResultsTitle;

  /// Eyebrow de l'écran de calcul des résultats
  ///
  /// In fr, this message translates to:
  /// **'BILAN'**
  String get ctComputingResultsEyebrow;

  /// Texte affiché pendant le traitement des résultats
  ///
  /// In fr, this message translates to:
  /// **'TRAITEMENT'**
  String get ctProcessing;

  /// Message d'erreur quand un subtest n'est pas reconnu
  ///
  /// In fr, this message translates to:
  /// **'Test non trouvé : {testName}'**
  String ctTestNotFound(String testName);

  /// Nom affiché du subtest Cubes
  ///
  /// In fr, this message translates to:
  /// **'Cubes'**
  String get ctTestCubes;

  /// Nom affiché du subtest Similitudes
  ///
  /// In fr, this message translates to:
  /// **'Similitudes'**
  String get ctTestSimilarities;

  /// Nom affiché du subtest Mémoire des Chiffres
  ///
  /// In fr, this message translates to:
  /// **'Mémoire des Chiffres'**
  String get ctTestDigitSpan;

  /// Nom affiché du subtest Matrices
  ///
  /// In fr, this message translates to:
  /// **'Matrices'**
  String get ctTestMatrices;

  /// Nom affiché du subtest Vocabulaire
  ///
  /// In fr, this message translates to:
  /// **'Vocabulaire'**
  String get ctTestVocabulary;

  /// Nom affiché du subtest Arithmétique
  ///
  /// In fr, this message translates to:
  /// **'Arithmétique'**
  String get ctTestArithmetic;

  /// Nom affiché du subtest Recherche de Symboles
  ///
  /// In fr, this message translates to:
  /// **'Recherche de Symboles'**
  String get ctTestSymbolSearch;

  /// Nom affiché du subtest Puzzles Visuels
  ///
  /// In fr, this message translates to:
  /// **'Puzzles Visuels'**
  String get ctTestVisualPuzzles;

  /// Nom affiché du subtest Information
  ///
  /// In fr, this message translates to:
  /// **'Information'**
  String get ctTestInformation;

  /// Nom affiché du subtest Code
  ///
  /// In fr, this message translates to:
  /// **'Code'**
  String get ctTestCoding;

  /// Nom affiché du subtest Mémoire des Images
  ///
  /// In fr, this message translates to:
  /// **'Mémoire des Images'**
  String get ctTestPictureSpan;

  /// Nom affiché du subtest Balances
  ///
  /// In fr, this message translates to:
  /// **'Balances'**
  String get ctTestFigureWeights;

  /// Titre de la page de résultats du test complet
  ///
  /// In fr, this message translates to:
  /// **'Résultats'**
  String get ctResultsTitle;

  /// Eyebrow de la page de résultats
  ///
  /// In fr, this message translates to:
  /// **'BILAN WAIS-IV'**
  String get ctResultsEyebrow;

  /// Titre hero ligne 1 de la page de résultats
  ///
  /// In fr, this message translates to:
  /// **'Bilan'**
  String get ctResultsHero1;

  /// Titre hero ligne 2 (italique) de la page de résultats
  ///
  /// In fr, this message translates to:
  /// **'terminé.'**
  String get ctResultsHero2;

  /// Paragraphe de synthèse en tête de page de résultats
  ///
  /// In fr, this message translates to:
  /// **'Synthèse de vos performances cognitives sur les douze subtests WAIS-IV.'**
  String get ctResultsSummary;

  /// Âge en années affiché dans les résultats
  ///
  /// In fr, this message translates to:
  /// **'{age} ans'**
  String ctAgeYears(int age);

  /// Libellé méta : date de la session
  ///
  /// In fr, this message translates to:
  /// **'DATE'**
  String get ctMetaDate;

  /// Libellé méta : durée de la session
  ///
  /// In fr, this message translates to:
  /// **'DURÉE'**
  String get ctMetaDuration;

  /// Libellé méta : nombre de subtests complétés
  ///
  /// In fr, this message translates to:
  /// **'SUBTESTS'**
  String get ctMetaSubtests;

  /// Libellé méta : âge du patient
  ///
  /// In fr, this message translates to:
  /// **'ÂGE'**
  String get ctMetaAge;

  /// Libellé de la carte du QI total
  ///
  /// In fr, this message translates to:
  /// **'QI TOTAL · FSIQ'**
  String get ctFsiqCardLabel;

  /// Intervalle de confiance à 95% du QI total
  ///
  /// In fr, this message translates to:
  /// **'IC 95% · {lower} – {upper}'**
  String ctConfidenceInterval95(int lower, int upper);

  /// Rang percentile du QI total (suffixe ordinal 'e' en FR)
  ///
  /// In fr, this message translates to:
  /// **'Percentile · {rank}e'**
  String ctPercentileLabel(int rank);

  /// En-tête de la carte profil des indices
  ///
  /// In fr, this message translates to:
  /// **'PROFIL DES INDICES'**
  String get ctIndexProfileHeader;

  /// Libellé complet de l'indice VCI
  ///
  /// In fr, this message translates to:
  /// **'Compréhension Verbale'**
  String get ctIndexVci;

  /// Libellé complet de l'indice VSI
  ///
  /// In fr, this message translates to:
  /// **'Visuo-Spatial'**
  String get ctIndexVsi;

  /// Libellé complet de l'indice FRI
  ///
  /// In fr, this message translates to:
  /// **'Raisonnement Fluide'**
  String get ctIndexFri;

  /// Libellé complet de l'indice WMI
  ///
  /// In fr, this message translates to:
  /// **'Mémoire de Travail'**
  String get ctIndexWmi;

  /// Libellé complet de l'indice PSI
  ///
  /// In fr, this message translates to:
  /// **'Vitesse de Traitement'**
  String get ctIndexPsi;

  /// Intervalle de confiance et percentile d'un indice
  ///
  /// In fr, this message translates to:
  /// **'IC {lower}–{upper} · {rank}e %ile'**
  String ctIndexCiPercentile(int lower, int upper, int rank);

  /// Percentile d'un indice (sans IC)
  ///
  /// In fr, this message translates to:
  /// **'{rank}e %ile'**
  String ctIndexPercentile(int rank);

  /// En-tête de la carte des notes standardisées par subtest
  ///
  /// In fr, this message translates to:
  /// **'NOTES STANDARDISÉES'**
  String get ctStandardizedScoresHeader;

  /// Titre du groupe VCI dans le détail des subtests
  ///
  /// In fr, this message translates to:
  /// **'VCI · Verbal'**
  String get ctGroupVciVerbal;

  /// Titre du groupe VSI dans le détail des subtests
  ///
  /// In fr, this message translates to:
  /// **'VSI · Visuo-Spatial'**
  String get ctGroupVsiVisuoSpatial;

  /// Titre du groupe FRI dans le détail des subtests
  ///
  /// In fr, this message translates to:
  /// **'FRI · Raisonnement'**
  String get ctGroupFriReasoning;

  /// Titre du groupe WMI dans le détail des subtests
  ///
  /// In fr, this message translates to:
  /// **'WMI · Mémoire'**
  String get ctGroupWmiMemory;

  /// Titre du groupe PSI dans le détail des subtests
  ///
  /// In fr, this message translates to:
  /// **'PSI · Vitesse'**
  String get ctGroupPsiSpeed;

  /// Note brute d'un subtest dans le détail
  ///
  /// In fr, this message translates to:
  /// **'brut {raw}'**
  String ctRawScore(int raw);

  /// En-tête de la carte profil cognitif (forces/faiblesses)
  ///
  /// In fr, this message translates to:
  /// **'PROFIL COGNITIF'**
  String get ctCognitiveProfileHeader;

  /// Description d'un profil cognitif homogène
  ///
  /// In fr, this message translates to:
  /// **'Profil homogène — les indices sont cohérents entre eux.'**
  String get ctProfileHomogeneous;

  /// Description d'un profil cognitif hétérogène
  ///
  /// In fr, this message translates to:
  /// **'Profil hétérogène — disparités notables entre indices.'**
  String get ctProfileHeterogeneous;

  /// Écart maximal entre indices, en points
  ///
  /// In fr, this message translates to:
  /// **'Écart max · {points} pts'**
  String ctMaxDiscrepancy(int points);

  /// En-tête de la liste des forces relatives
  ///
  /// In fr, this message translates to:
  /// **'Forces relatives'**
  String get ctRelativeStrengths;

  /// En-tête de la liste des faiblesses relatives
  ///
  /// In fr, this message translates to:
  /// **'Points de vigilance'**
  String get ctVigilancePoints;

  /// Avertissement sous le profil cognitif
  ///
  /// In fr, this message translates to:
  /// **'Résultats indicatifs. Pour une évaluation clinique officielle, consultez un neuropsychologue ou un psychologue qualifié.'**
  String get ctIndicativeDisclaimer;

  /// En-tête de la carte de repli affichant les scores bruts (âge manquant)
  ///
  /// In fr, this message translates to:
  /// **'SCORES BRUTS'**
  String get ctRawScoresHeader;

  /// En-tête de l'avis 'âge manquant'
  ///
  /// In fr, this message translates to:
  /// **'ÂGE MANQUANT'**
  String get ctMissingAgeHeader;

  /// Corps de l'avis 'âge manquant'
  ///
  /// In fr, this message translates to:
  /// **'Sans l\'âge du patient, seuls les scores bruts sont affichés. Relancez le test en renseignant l\'âge pour obtenir le QI standardisé, les percentiles et les intervalles de confiance.'**
  String get ctMissingAgeBody;

  /// Bouton d'export PDF des résultats
  ///
  /// In fr, this message translates to:
  /// **'Exporter en PDF'**
  String get ctExportPdf;

  /// Message d'erreur affiché si la génération du PDF échoue
  ///
  /// In fr, this message translates to:
  /// **'Erreur PDF : {error}'**
  String ctPdfError(String error);

  /// Bouton de retour à l'accueil depuis les résultats
  ///
  /// In fr, this message translates to:
  /// **'Retour à l\'accueil'**
  String get ctBackToHome;

  /// Titre du dialogue affiché quand l'utilisateur quitte un sous-test sans le terminer
  ///
  /// In fr, this message translates to:
  /// **'Sous-test interrompu'**
  String get ctSubtestExitTitle;

  /// Corps du dialogue de sortie d'un sous-test
  ///
  /// In fr, this message translates to:
  /// **'Vous avez quitté ce sous-test avant de le terminer. Voulez-vous le reprendre ou arrêter l\'évaluation ?'**
  String get ctSubtestExitBody;

  /// Bouton pour reprendre le sous-test interrompu
  ///
  /// In fr, this message translates to:
  /// **'Reprendre le sous-test'**
  String get ctSubtestExitResume;

  /// Sous-titre du rapport PDF (sous le titre de marque)
  ///
  /// In fr, this message translates to:
  /// **'Rapport d\'évaluation cognitive WAIS-IV'**
  String get ctPdfSubtitle;

  /// Valeur affichée dans le PDF quand l'âge n'est pas renseigné
  ///
  /// In fr, this message translates to:
  /// **'Non renseigné'**
  String get ctPdfNotProvided;

  /// Durée de la session dans le PDF (minutes et secondes)
  ///
  /// In fr, this message translates to:
  /// **'{min} min {sec} sec'**
  String ctPdfDurationMinSec(int min, int sec);

  /// Libellé 'Âge' dans le bandeau d'info du PDF
  ///
  /// In fr, this message translates to:
  /// **'Âge'**
  String get ctPdfAge;

  /// Libellé 'Durée' dans le bandeau d'info du PDF
  ///
  /// In fr, this message translates to:
  /// **'Durée'**
  String get ctPdfDuration;

  /// Libellé 'Date' dans le bandeau d'info du PDF
  ///
  /// In fr, this message translates to:
  /// **'Date'**
  String get ctPdfDate;

  /// Libellé du bloc FSIQ dans le PDF
  ///
  /// In fr, this message translates to:
  /// **'SCORE QI GLOBAL (FSIQ)'**
  String get ctPdfFsiqLabel;

  /// Libellé de l'intervalle de confiance dans le PDF
  ///
  /// In fr, this message translates to:
  /// **'Intervalle de confiance 95%'**
  String get ctPdfConfidenceInterval95;

  /// Libellé 'Percentile' dans le PDF
  ///
  /// In fr, this message translates to:
  /// **'Percentile'**
  String get ctPdfPercentile;

  /// Valeur du percentile avec suffixe ordinal dans le PDF
  ///
  /// In fr, this message translates to:
  /// **'{rank}e'**
  String ctPercentileValue(int rank);

  /// En-tête du tableau des indices dans le PDF
  ///
  /// In fr, this message translates to:
  /// **'PROFIL DES INDICES COGNITIFS'**
  String get ctPdfIndexProfileHeader;

  /// Libellé de l'indice VCI dans le tableau PDF
  ///
  /// In fr, this message translates to:
  /// **'VCI — Compréhension Verbale'**
  String get ctPdfIndexVci;

  /// Libellé de l'indice VSI dans le tableau PDF
  ///
  /// In fr, this message translates to:
  /// **'VSI — Visuo-Spatial'**
  String get ctPdfIndexVsi;

  /// Libellé de l'indice FRI dans le tableau PDF
  ///
  /// In fr, this message translates to:
  /// **'FRI — Raisonnement Fluide'**
  String get ctPdfIndexFri;

  /// Libellé de l'indice WMI dans le tableau PDF
  ///
  /// In fr, this message translates to:
  /// **'WMI — Mémoire de Travail'**
  String get ctPdfIndexWmi;

  /// Libellé de l'indice PSI dans le tableau PDF
  ///
  /// In fr, this message translates to:
  /// **'PSI — Vitesse de Traitement'**
  String get ctPdfIndexPsi;

  /// En-tête de colonne 'Indice' dans le tableau PDF des indices
  ///
  /// In fr, this message translates to:
  /// **'Indice'**
  String get ctPdfColIndex;

  /// En-tête de colonne 'Score' dans le tableau PDF des indices
  ///
  /// In fr, this message translates to:
  /// **'Score'**
  String get ctPdfColScore;

  /// En-tête de colonne 'Classification' dans le tableau PDF des indices
  ///
  /// In fr, this message translates to:
  /// **'Classification'**
  String get ctPdfColClassification;

  /// En-tête du tableau des scores bruts par subtest dans le PDF
  ///
  /// In fr, this message translates to:
  /// **'SCORES BRUTS DES SUBTESTS'**
  String get ctPdfRawScoresHeader;

  /// En-tête de colonne 'Subtest' dans le tableau PDF des scores bruts
  ///
  /// In fr, this message translates to:
  /// **'Subtest'**
  String get ctPdfColSubtest;

  /// En-tête de colonne 'Score brut' dans le tableau PDF des scores bruts
  ///
  /// In fr, this message translates to:
  /// **'Score brut'**
  String get ctPdfColRawScore;

  /// Avertissement en bas du rapport PDF
  ///
  /// In fr, this message translates to:
  /// **'AVERTISSEMENT : Ce rapport est généré par une application d\'aide à l\'évaluation et ne constitue pas un diagnostic clinique officiel. Il doit être interprété par un professionnel de santé qualifié. Ne pas utiliser à des fins médicales ou légales sans évaluation professionnelle complémentaire.'**
  String get ctPdfDisclaimer;

  /// App bar eyebrow on chat screen
  ///
  /// In fr, this message translates to:
  /// **'ASSISTANT IA'**
  String get chatEyebrow;

  /// Tooltip to clear the chat
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle conversation'**
  String get chatNewConversation;

  /// Label above assistant messages (brand)
  ///
  /// In fr, this message translates to:
  /// **'MENTAL E.T.'**
  String get chatAssistantLabel;

  /// Label above user messages
  ///
  /// In fr, this message translates to:
  /// **'VOUS'**
  String get chatUserLabel;

  /// Empty-state hero, line 1
  ///
  /// In fr, this message translates to:
  /// **'Posez'**
  String get chatHeroTitle1;

  /// Empty-state hero, line 2 (italic)
  ///
  /// In fr, this message translates to:
  /// **'vos questions.'**
  String get chatHeroTitle2;

  /// No description provided for @chatEmptyIntro.
  ///
  /// In fr, this message translates to:
  /// **'L\'IA Mental E.T. vous aide à mieux comprendre votre profil cognitif. Discussions confidentielles, accompagnement non-directif.'**
  String get chatEmptyIntro;

  /// Loading bubble label
  ///
  /// In fr, this message translates to:
  /// **'Réflexion…'**
  String get chatThinking;

  /// Chat input placeholder
  ///
  /// In fr, this message translates to:
  /// **'Écrire un message…'**
  String get chatInputHint;

  /// Message timestamp, under 1 min
  ///
  /// In fr, this message translates to:
  /// **'à l\'instant'**
  String get chatTimeJustNow;

  /// Message timestamp in minutes
  ///
  /// In fr, this message translates to:
  /// **'{count} min'**
  String chatTimeMinutes(int count);

  /// Message timestamp in hours
  ///
  /// In fr, this message translates to:
  /// **'{count}h'**
  String chatTimeHours(int count);

  /// Generic chat error bubble
  ///
  /// In fr, this message translates to:
  /// **'Désolé, une erreur s\'est produite. Veuillez réessayer.'**
  String get chatErrorMessage;

  /// Network error (not user-facing prose)
  ///
  /// In fr, this message translates to:
  /// **'Réponse vide du worker'**
  String get chatErrorEmptyResponse;

  /// 403 network error
  ///
  /// In fr, this message translates to:
  /// **'Accès refusé par le worker (origine non autorisée).'**
  String get chatErrorAccessDenied;

  /// 429 network error
  ///
  /// In fr, this message translates to:
  /// **'Limite de requêtes atteinte. Réessayez dans quelques instants.'**
  String get chatErrorRateLimit;

  /// 500 network error fallback
  ///
  /// In fr, this message translates to:
  /// **'Erreur serveur ({code})'**
  String chatErrorServer(int code);

  /// Generic HTTP error fallback
  ///
  /// In fr, this message translates to:
  /// **'Erreur {code} : {body}'**
  String chatErrorHttp(int code, String body);

  /// Splash title, line 1
  ///
  /// In fr, this message translates to:
  /// **'Évaluation'**
  String get coreSplashTitleLine1;

  /// Splash title, line 2 (italic)
  ///
  /// In fr, this message translates to:
  /// **'cognitive'**
  String get coreSplashTitleLine2;

  /// Abréviation 'non disponible' (cellules PDF compactes)
  ///
  /// In fr, this message translates to:
  /// **'N/D'**
  String get commonNotAvailable;

  /// Base du nom de fichier PDF (ASCII, sans accents)
  ///
  /// In fr, this message translates to:
  /// **'mentality_resultats'**
  String get pdfFilenameBase;

  /// Message affiché par le routeur quand une route demandée n'existe pas. {path} est le chemin de l'URL.
  ///
  /// In fr, this message translates to:
  /// **'Page introuvable : {path}'**
  String coreRouteNotFound(String path);

  /// Home hero, line 1
  ///
  /// In fr, this message translates to:
  /// **'Découvrez'**
  String get homeHeroTitle;

  /// Home hero, line 2 (italic)
  ///
  /// In fr, this message translates to:
  /// **'votre profil cognitif.'**
  String get homeHeroTitleItalic;

  /// No description provided for @homeHeroBody.
  ///
  /// In fr, this message translates to:
  /// **'Une évaluation scientifique adaptative, inspirée des échelles Wechsler. 12 sous-tests, 5 indices, un score global.'**
  String get homeHeroBody;

  /// Home action card 1 title
  ///
  /// In fr, this message translates to:
  /// **'Commencer une évaluation'**
  String get homeActionStartTitle;

  /// Home action card 1 subtitle
  ///
  /// In fr, this message translates to:
  /// **'Durée : 60 – 90 minutes'**
  String get homeActionStartSubtitle;

  /// Home action card 2 title
  ///
  /// In fr, this message translates to:
  /// **'Mes résultats'**
  String get homeActionResultsTitle;

  /// Home action card 2 subtitle
  ///
  /// In fr, this message translates to:
  /// **'Historique des évaluations'**
  String get homeActionResultsSubtitle;

  /// Home action card 3 title
  ///
  /// In fr, this message translates to:
  /// **'Parler avec Mental E.T.'**
  String get homeActionChatTitle;

  /// Home action card 3 subtitle
  ///
  /// In fr, this message translates to:
  /// **'Assistant IA, questions psychologiques'**
  String get homeActionChatSubtitle;

  /// Badge on disabled action
  ///
  /// In fr, this message translates to:
  /// **'BIENTÔT DISPONIBLE'**
  String get homeComingSoon;

  /// About section eyebrow
  ///
  /// In fr, this message translates to:
  /// **'À PROPOS'**
  String get homeAboutEyebrow;

  /// About tile 1 title
  ///
  /// In fr, this message translates to:
  /// **'12 sous-tests'**
  String get homeAboutSubtestsTitle;

  /// No description provided for @homeAboutSubtestsBody.
  ///
  /// In fr, this message translates to:
  /// **'Évaluation complète des cinq indices cognitifs WAIS-IV.'**
  String get homeAboutSubtestsBody;

  /// About tile 2 title
  ///
  /// In fr, this message translates to:
  /// **'IA adaptative'**
  String get homeAboutAdaptiveTitle;

  /// No description provided for @homeAboutAdaptiveBody.
  ///
  /// In fr, this message translates to:
  /// **'Difficulté ajustée en temps réel via inférence IRT.'**
  String get homeAboutAdaptiveBody;

  /// About tile 3 title
  ///
  /// In fr, this message translates to:
  /// **'Validation scientifique'**
  String get homeAboutValidationTitle;

  /// No description provided for @homeAboutValidationBody.
  ///
  /// In fr, this message translates to:
  /// **'Items inspirés des échelles Wechsler (WPPSI / WISC / WAIS).'**
  String get homeAboutValidationBody;

  /// Resume banner eyebrow
  ///
  /// In fr, this message translates to:
  /// **'TEST EN COURS'**
  String get homeResumeEyebrow;

  /// Resume banner title
  ///
  /// In fr, this message translates to:
  /// **'Reprendre votre évaluation'**
  String get homeResumeTitle;

  /// Resume banner button
  ///
  /// In fr, this message translates to:
  /// **'Reprendre'**
  String get homeResumeButton;

  /// Logout confirmation dialog title
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter ?'**
  String get homeLogoutTitle;

  /// Logout confirmation dialog body
  ///
  /// In fr, this message translates to:
  /// **'Ton token sera retiré de cet appareil. Assure-toi de l\'avoir sauvegardé : sans lui, tu ne pourras pas te reconnecter à tes données.'**
  String get homeLogoutBody;

  /// Logout confirm/tooltip label
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get homeLogoutConfirm;

  /// Information — nom du test affiché dans le scaffold
  ///
  /// In fr, this message translates to:
  /// **'Information'**
  String get infoTestName;

  /// Information — sur-titre (indice mesuré)
  ///
  /// In fr, this message translates to:
  /// **'COMPRÉHENSION VERBALE · VCI'**
  String get infoEyebrow;

  /// Information — statut en AppBar : temps écoulé · score/items tentés
  ///
  /// In fr, this message translates to:
  /// **'{seconds}s · {score}/{attempted}'**
  String infoTrailingStatus(int seconds, int score, int attempted);

  /// Information — titre du dialogue de feedback quand la réponse est juste
  ///
  /// In fr, this message translates to:
  /// **'Correct !'**
  String get infoCorrect;

  /// Information — titre du dialogue de feedback quand la réponse est fausse
  ///
  /// In fr, this message translates to:
  /// **'Incorrect'**
  String get infoIncorrect;

  /// Information — corps du feedback quand la réponse est juste
  ///
  /// In fr, this message translates to:
  /// **'Bonne réponse ! +1 point'**
  String get infoFeedbackRight;

  /// Information — corps du feedback quand la réponse est fausse
  ///
  /// In fr, this message translates to:
  /// **'Mauvaise réponse. 0 point'**
  String get infoFeedbackWrong;

  /// Information — rappel de l'énoncé dans le feedback
  ///
  /// In fr, this message translates to:
  /// **'Question : {question}'**
  String infoQuestionLabel(String question);

  /// Information — affiche la bonne réponse après un échec
  ///
  /// In fr, this message translates to:
  /// **'Bonne réponse : {answer}'**
  String infoCorrectAnswerLabel(String answer);

  /// Information — temps passé sur l'item
  ///
  /// In fr, this message translates to:
  /// **'Temps : {seconds}s'**
  String infoTimeLabel(int seconds);

  /// Information — score courant
  ///
  /// In fr, this message translates to:
  /// **'Score : {score}/{attempted}'**
  String infoScoreLabel(int score, int attempted);

  /// Information — domaine de connaissance de l'item
  ///
  /// In fr, this message translates to:
  /// **'Domaine : {domain}'**
  String infoDomainLabel(String domain);

  /// Information — message de règle de discontinuation après 3 échecs
  ///
  /// In fr, this message translates to:
  /// **'3 échecs consécutifs - Test terminé (WAIS-IV)'**
  String get infoDiscontinue3;

  /// Information — bouton qui ouvre l'écran de résultats final
  ///
  /// In fr, this message translates to:
  /// **'Voir les résultats'**
  String get infoSeeResults;

  /// Information — titre du dialogue de résultats final
  ///
  /// In fr, this message translates to:
  /// **'Test d\'Information - Résultats'**
  String get infoResultsTitle;

  /// Information — score brut final
  ///
  /// In fr, this message translates to:
  /// **'Score brut : {score}/{max} points'**
  String infoRawScore(int score, int max);

  /// Information — nombre d'items complétés
  ///
  /// In fr, this message translates to:
  /// **'Items complétés : {completed}/{total}'**
  String infoItemsCompleted(int completed, int total);

  /// Information — pourcentage de réussite
  ///
  /// In fr, this message translates to:
  /// **'Pourcentage : {percent}%'**
  String infoPercentage(int percent);

  /// Information — temps total du test
  ///
  /// In fr, this message translates to:
  /// **'Temps total : {seconds}s'**
  String infoTotalTime(int seconds);

  /// Information — sous-titre descriptif sous le niveau de performance
  ///
  /// In fr, this message translates to:
  /// **'Test de connaissances générales acquises'**
  String get infoTestSubtitle;

  /// Information — titre de la section répartition par domaine
  ///
  /// In fr, this message translates to:
  /// **'Répartition par domaine :'**
  String get infoDomainBreakdownTitle;

  /// Information — ligne de répartition par domaine
  ///
  /// In fr, this message translates to:
  /// **'{domain}: {correct}/{total}'**
  String infoDomainBreakdownRow(String domain, int correct, int total);

  /// Information — niveau de performance exceptionnel
  ///
  /// In fr, this message translates to:
  /// **'Performance exceptionnelle (θ > +2.0)'**
  String get infoPerfExceptional;

  /// Information — niveau de performance supérieur
  ///
  /// In fr, this message translates to:
  /// **'Performance supérieure (θ > +1.0)'**
  String get infoPerfSuperior;

  /// Information — niveau de performance moyen
  ///
  /// In fr, this message translates to:
  /// **'Performance moyenne (θ ≈ 0)'**
  String get infoPerfAverage;

  /// Information — niveau de performance inférieur
  ///
  /// In fr, this message translates to:
  /// **'Performance inférieure (θ < 0)'**
  String get infoPerfBelow;

  /// Information — niveau de performance faible
  ///
  /// In fr, this message translates to:
  /// **'Performance faible (θ < -1.0)'**
  String get infoPerfLow;

  /// Information — domaine : sciences naturelles
  ///
  /// In fr, this message translates to:
  /// **'Sciences naturelles'**
  String get infoDomainScience;

  /// Information — domaine : histoire/géographie
  ///
  /// In fr, this message translates to:
  /// **'Histoire/Géographie'**
  String get infoDomainHistoryGeography;

  /// Information — domaine : culture générale
  ///
  /// In fr, this message translates to:
  /// **'Culture générale'**
  String get infoDomainGeneralCulture;

  /// Information — domaine : mathématiques/logique
  ///
  /// In fr, this message translates to:
  /// **'Mathématiques/Logique'**
  String get infoDomainMathLogic;

  /// Information — domaine : arts/littérature
  ///
  /// In fr, this message translates to:
  /// **'Arts/Littérature'**
  String get infoDomainArtsLiterature;

  /// Information — difficulté : facile
  ///
  /// In fr, this message translates to:
  /// **'Facile'**
  String get infoDifficultyEasy;

  /// Information — difficulté : moyen
  ///
  /// In fr, this message translates to:
  /// **'Moyen'**
  String get infoDifficultyMedium;

  /// Information — difficulté : difficile
  ///
  /// In fr, this message translates to:
  /// **'Difficile'**
  String get infoDifficultyHard;

  /// Arithmétique — nom du test affiché dans le scaffold/AppBar
  ///
  /// In fr, this message translates to:
  /// **'Arithmétique'**
  String get arithTestName;

  /// Arithmétique — sur-titre (indice mesuré)
  ///
  /// In fr, this message translates to:
  /// **'MÉMOIRE DE TRAVAIL · WMI'**
  String get arithEyebrow;

  /// Arithmétique — bouton de démarrage du test
  ///
  /// In fr, this message translates to:
  /// **'Commencer le test'**
  String get arithStartTest;

  /// Arithmétique — titre de l'écran d'introduction
  ///
  /// In fr, this message translates to:
  /// **'Test d\'Arithmétique'**
  String get arithIntroTitle;

  /// Arithmétique — description sur l'écran d'introduction
  ///
  /// In fr, this message translates to:
  /// **'Ce test mesure votre mémoire de travail et votre raisonnement numérique.'**
  String get arithIntroDescription;

  /// Arithmétique — carte info : titre calcul mental
  ///
  /// In fr, this message translates to:
  /// **'Calcul mental uniquement'**
  String get arithInfoMentalTitle;

  /// Arithmétique — carte info : sous-titre calcul mental
  ///
  /// In fr, this message translates to:
  /// **'Résolvez les problèmes sans papier ni calculatrice'**
  String get arithInfoMentalSubtitle;

  /// Arithmétique — carte info : titre temps limité
  ///
  /// In fr, this message translates to:
  /// **'Temps limité'**
  String get arithInfoTimeTitle;

  /// Arithmétique — carte info : sous-titre temps limité
  ///
  /// In fr, this message translates to:
  /// **'Chaque problème a une limite de temps (15-60 secondes)'**
  String get arithInfoTimeSubtitle;

  /// Arithmétique — carte info : titre bonus rapidité
  ///
  /// In fr, this message translates to:
  /// **'Bonus de rapidité'**
  String get arithInfoBonusTitle;

  /// Arithmétique — carte info : sous-titre bonus rapidité
  ///
  /// In fr, this message translates to:
  /// **'Réponses rapides sur certains items = points bonus'**
  String get arithInfoBonusSubtitle;

  /// Arithmétique — carte info : titre répétition
  ///
  /// In fr, this message translates to:
  /// **'Répétition possible'**
  String get arithInfoRepeatTitle;

  /// Arithmétique — carte info : sous-titre répétition
  ///
  /// In fr, this message translates to:
  /// **'Vous pouvez demander de répéter UNE fois (chrono continue)'**
  String get arithInfoRepeatSubtitle;

  /// Arithmétique — note d'information sur la discontinuation
  ///
  /// In fr, this message translates to:
  /// **'22 problèmes au total. Le test s\'arrête après 3 échecs consécutifs.'**
  String get arithIntroDiscontinueNote;

  /// Arithmétique — compteur de problème en AppBar
  ///
  /// In fr, this message translates to:
  /// **'Problème {current}/{total}'**
  String arithProblemCounter(int current, int total);

  /// Arithmétique — titre du dialogue de répétition
  ///
  /// In fr, this message translates to:
  /// **'Répétition du problème'**
  String get arithRepeatTitle;

  /// Arithmétique — bouton de fermeture du dialogue de répétition
  ///
  /// In fr, this message translates to:
  /// **'Compris'**
  String get arithUnderstood;

  /// Arithmétique — titre du dialogue de temps écoulé
  ///
  /// In fr, this message translates to:
  /// **'Temps écoulé !'**
  String get arithTimeUp;

  /// Arithmétique — affiche la bonne réponse
  ///
  /// In fr, this message translates to:
  /// **'Réponse correcte : {answer}'**
  String arithCorrectAnswerLabel(int answer);

  /// Arithmétique — titre du feedback quand la réponse est juste
  ///
  /// In fr, this message translates to:
  /// **'Correct !'**
  String get arithCorrect;

  /// Arithmétique — titre du feedback quand la réponse est fausse
  ///
  /// In fr, this message translates to:
  /// **'Incorrect'**
  String get arithIncorrect;

  /// Arithmétique — temps passé sur l'item
  ///
  /// In fr, this message translates to:
  /// **'Temps : {seconds} secondes'**
  String arithTimeSpent(int seconds);

  /// Arithmétique — message de bonus de rapidité
  ///
  /// In fr, this message translates to:
  /// **'🎉 Bonus de rapidité ! (+1 point)'**
  String get arithSpeedBonus;

  /// Arithmétique — titre du dialogue de résultats final
  ///
  /// In fr, this message translates to:
  /// **'Test terminé !'**
  String get arithTestEnded;

  /// Arithmétique — nombre d'items complétés
  ///
  /// In fr, this message translates to:
  /// **'Items complétés : {completed}/{total}'**
  String arithItemsCompleted(int completed, int total);

  /// Arithmétique — score de base
  ///
  /// In fr, this message translates to:
  /// **'Score de base : {score} points'**
  String arithBaseScore(int score);

  /// Arithmétique — points de bonus
  ///
  /// In fr, this message translates to:
  /// **'Bonus de rapidité : {bonus} points'**
  String arithBonusScore(int bonus);

  /// Arithmétique — score total final
  ///
  /// In fr, this message translates to:
  /// **'Score Total : {total} points'**
  String arithTotalScore(int total);

  /// Arithmétique — bouton de répétition de l'énoncé
  ///
  /// In fr, this message translates to:
  /// **'Répéter'**
  String get arithRepeat;

  /// Arithmétique — hint du champ de réponse
  ///
  /// In fr, this message translates to:
  /// **'Votre réponse'**
  String get arithAnswerHint;

  /// Arithmétique — difficulté : facile
  ///
  /// In fr, this message translates to:
  /// **'Facile'**
  String get arithDifficultyEasy;

  /// Arithmétique — difficulté : moyen
  ///
  /// In fr, this message translates to:
  /// **'Moyen'**
  String get arithDifficultyMedium;

  /// Arithmétique — difficulté : difficile
  ///
  /// In fr, this message translates to:
  /// **'Difficile'**
  String get arithDifficultyHard;

  /// Arithmétique — difficulté : très difficile
  ///
  /// In fr, this message translates to:
  /// **'Très difficile'**
  String get arithDifficultyVeryHard;

  /// Titre du dialogue de permission micro (lecture et résumé)
  ///
  /// In fr, this message translates to:
  /// **'Accès au microphone'**
  String get oralMicAccessTitle;

  /// Dialogue permission micro — test de lecture, paragraphe 1
  ///
  /// In fr, this message translates to:
  /// **'Cette activité enregistre votre voix pendant que vous lisez le texte à voix haute.'**
  String get oralReadingPermissionBody1;

  /// Dialogue permission micro — test de lecture, paragraphe 2. EN omet volontairement « en français » (les textes lus sont dans la langue de l'app)
  ///
  /// In fr, this message translates to:
  /// **'Vos enregistrements seront anonymisés et pourront contribuer à l\'amélioration de la reconnaissance vocale en français.'**
  String get oralReadingPermissionBody2;

  /// Dialogue permission micro — note italique sur la demande navigateur
  ///
  /// In fr, this message translates to:
  /// **'Votre navigateur vous demandera ensuite d\'autoriser le microphone.'**
  String get oralBrowserWillAskMic;

  /// Bouton annuler des dialogues de permission micro
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get oralCancel;

  /// Bouton de confirmation du dialogue de permission micro (lecture)
  ///
  /// In fr, this message translates to:
  /// **'Autoriser le microphone'**
  String get oralAllowMicrophone;

  /// Message d'erreur quand la permission micro est refusée
  ///
  /// In fr, this message translates to:
  /// **'Microphone refusé ou indisponible.'**
  String get oralMicDeniedOrUnavailable;

  /// Message d'erreur quand le démarrage de l'enregistrement échoue
  ///
  /// In fr, this message translates to:
  /// **'Impossible de démarrer l\'enregistrement sur ce navigateur.'**
  String get oralCannotStartRecording;

  /// Contenu du SnackBar d'erreur micro ; message = erreur déjà localisée
  ///
  /// In fr, this message translates to:
  /// **'{message} Vous pouvez passer à l\'étape suivante.'**
  String oralCanSkipToNextStep(String message);

  /// Action du SnackBar d'erreur micro pour passer l'étape
  ///
  /// In fr, this message translates to:
  /// **'Passer'**
  String get oralSkip;

  /// Indicateur clignotant rouge pendant l'enregistrement
  ///
  /// In fr, this message translates to:
  /// **'Enregistrement en cours'**
  String get oralRecordingInProgress;

  /// Compte à rebours avant que le bouton Terminer ne s'active
  ///
  /// In fr, this message translates to:
  /// **'Continuez encore {seconds}s...'**
  String oralKeepGoingSeconds(int seconds);

  /// Libellé du bouton pendant la sauvegarde de l'audio
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarde...'**
  String get oralSaving;

  /// Bandeau d'instructions du test de lecture à voix haute
  ///
  /// In fr, this message translates to:
  /// **'Lisez le texte suivant à voix haute, clairement et à votre rythme naturel. Appuyez sur \"Démarrer\" quand vous êtes prêt.'**
  String get oralReadingInstructions;

  /// Bouton principal pour démarrer l'enregistrement de la lecture
  ///
  /// In fr, this message translates to:
  /// **'Démarrer la lecture'**
  String get oralStartReading;

  /// Bouton pour arrêter l'enregistrement de la lecture
  ///
  /// In fr, this message translates to:
  /// **'Terminer'**
  String get oralFinish;

  /// Bouton texte affiché si le micro est refusé
  ///
  /// In fr, this message translates to:
  /// **'Passer cette étape'**
  String get oralSkipThisStep;

  /// Dialogue permission micro — test de résumé, paragraphe 1
  ///
  /// In fr, this message translates to:
  /// **'Vous allez maintenant enregistrer votre résumé oral du texte.'**
  String get oralSummaryPermissionBody1;

  /// Dialogue permission micro — test de résumé, paragraphe 2
  ///
  /// In fr, this message translates to:
  /// **'Parlez naturellement, comme si vous expliquiez le texte à un ami. Prenez entre 30 et 60 secondes.'**
  String get oralSummaryPermissionBody2;

  /// Bouton pour démarrer l'enregistrement du résumé (dialogue et écran)
  ///
  /// In fr, this message translates to:
  /// **'Démarrer le résumé'**
  String get oralStartSummary;

  /// Début (en gras) du bandeau d'instructions du résumé — l'espace final est volontaire
  ///
  /// In fr, this message translates to:
  /// **'Vous venez de lire ce texte. '**
  String get oralSummaryInstructionLead;

  /// Suite du bandeau d'instructions du résumé
  ///
  /// In fr, this message translates to:
  /// **'Résumez ce que vous avez compris avec vos propres mots. Prenez entre 30 et 60 secondes. Parlez naturellement, comme si vous l\'expliquiez à un ami.'**
  String get oralSummaryInstructionBody;

  /// Étiquette de la carte grisée montrant le texte original pendant le résumé
  ///
  /// In fr, this message translates to:
  /// **'Texte de référence'**
  String get oralReferenceText;

  /// Bouton pour arrêter l'enregistrement du résumé
  ///
  /// In fr, this message translates to:
  /// **'Terminer le résumé'**
  String get oralFinishSummary;

  /// Titre de l'AppBar du flux de test oral
  ///
  /// In fr, this message translates to:
  /// **'Collecte audio'**
  String get oralFlowTitle;

  /// Titre de l'écran de consentement
  ///
  /// In fr, this message translates to:
  /// **'Test de Compréhension Orale'**
  String get oralConsentTitle;

  /// Écran de consentement — titre de la section enregistrements
  ///
  /// In fr, this message translates to:
  /// **'Ce que nous enregistrons'**
  String get oralConsentRecordTitle;

  /// Écran de consentement — corps de la section enregistrements
  ///
  /// In fr, this message translates to:
  /// **'Votre voix pendant la lecture de 5 courts textes (environ 1 min chacun) et votre résumé oral (environ 40 secondes par texte).'**
  String get oralConsentRecordBody;

  /// Écran de consentement — titre de la section anonymisation
  ///
  /// In fr, this message translates to:
  /// **'Confidentialité'**
  String get oralConsentAnonTitle;

  /// Écran de consentement — corps de la section anonymisation
  ///
  /// In fr, this message translates to:
  /// **'Vos enregistrements sont identifiés par un code de session aléatoire, et non par votre nom. Ils restent toutefois rattachables à votre compte : ce sont des données personnelles protégées, chiffrées et stockées en Europe.'**
  String get oralConsentAnonBody;

  /// Écran de consentement — titre de la section utilisation
  ///
  /// In fr, this message translates to:
  /// **'Utilisation'**
  String get oralConsentUsageTitle;

  /// Écran de consentement — corps de la section utilisation. EN omet volontairement « du français »
  ///
  /// In fr, this message translates to:
  /// **'Ces enregistrements pourront contribuer à l\'amélioration de la reconnaissance vocale du français, notamment pour des modèles comme Whisper ou Speechmatics.'**
  String get oralConsentUsageBody;

  /// Bouton principal de l'écran de consentement
  ///
  /// In fr, this message translates to:
  /// **'J\'accepte et je commence'**
  String get oralAcceptAndStart;

  /// Bouton texte de refus du consentement
  ///
  /// In fr, this message translates to:
  /// **'Refuser et revenir en arrière'**
  String get oralDeclineAndGoBack;

  /// Note légale en bas de l'écran de consentement
  ///
  /// In fr, this message translates to:
  /// **'Vous pouvez retirer votre consentement à tout moment depuis les paramètres de l\'application.'**
  String get oralWithdrawConsentNote;

  /// En-tête de progression du flux (5 textes au total)
  ///
  /// In fr, this message translates to:
  /// **'Texte {current} sur 5'**
  String oralTextProgress(int current);

  /// Étiquette d'étape courante dans l'en-tête de progression
  ///
  /// In fr, this message translates to:
  /// **'Lecture'**
  String get oralStepReading;

  /// Étiquette d'étape courante dans l'en-tête de progression
  ///
  /// In fr, this message translates to:
  /// **'Résumé'**
  String get oralStepSummary;

  /// Titre de l'écran de pause entre lecture et résumé
  ///
  /// In fr, this message translates to:
  /// **'Bien !'**
  String get oralPauseWellDone;

  /// Consigne de l'écran de pause
  ///
  /// In fr, this message translates to:
  /// **'Maintenant, résumez oralement ce texte.'**
  String get oralPauseNowSummarize;

  /// Libellé au-dessus du compte à rebours de la pause
  ///
  /// In fr, this message translates to:
  /// **'Début dans...'**
  String get oralPauseStartingIn;

  /// Titre de l'écran de fin
  ///
  /// In fr, this message translates to:
  /// **'Merci !'**
  String get oralCompletedThanks;

  /// Corps de l'écran de fin (retours à la ligne volontaires). EN omet volontairement « en français »
  ///
  /// In fr, this message translates to:
  /// **'Vous avez complété les 5 textes.\nVos enregistrements contribueront à l\'amélioration\nde la reconnaissance vocale en français.'**
  String get oralCompletedBody;

  /// Bouton de l'écran de fin
  ///
  /// In fr, this message translates to:
  /// **'Retour à l\'accueil'**
  String get oralBackToHome;

  /// Titre du dialogue de confirmation de sortie pendant un enregistrement
  ///
  /// In fr, this message translates to:
  /// **'Quitter ?'**
  String get oralExitDialogTitle;

  /// Corps du dialogue de confirmation de sortie
  ///
  /// In fr, this message translates to:
  /// **'Un enregistrement est en cours. Si vous quittez maintenant, il ne sera pas sauvegardé.'**
  String get oralExitDialogBody;

  /// Bouton pour rester dans le test (dialogue de sortie)
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get oralContinue;

  /// Bouton pour quitter le test (dialogue de sortie)
  ///
  /// In fr, this message translates to:
  /// **'Quitter'**
  String get oralQuit;

  /// Eyebrow label showing the current registration step out of 4
  ///
  /// In fr, this message translates to:
  /// **'ÉTAPE {step} / 4'**
  String regStepEyebrow(int step);

  /// Eyebrow label on the registration success page
  ///
  /// In fr, this message translates to:
  /// **'ÉTAPE 4 / 4 · SUCCÈS'**
  String get regStepEyebrowSuccess;

  /// Title of the email entry page (step 1 of registration)
  ///
  /// In fr, this message translates to:
  /// **'Créer mon token'**
  String get regEmailTitle;

  /// Heading next to the logo on the email entry page
  ///
  /// In fr, this message translates to:
  /// **'Votre email'**
  String get regEmailHeading;

  /// Introductory text on the email entry page
  ///
  /// In fr, this message translates to:
  /// **'Nous vous envoyons un code de vérification à 6 chiffres. Votre email n\'est pas lié à votre token et reste privé.'**
  String get regEmailIntro;

  /// Label of the email text field
  ///
  /// In fr, this message translates to:
  /// **'Adresse email'**
  String get regEmailFieldLabel;

  /// Validation error when the email format is invalid
  ///
  /// In fr, this message translates to:
  /// **'Email invalide'**
  String get regEmailInvalid;

  /// Button label while the email OTP is being sent
  ///
  /// In fr, this message translates to:
  /// **'Envoi du code…'**
  String get regSendingCode;

  /// Button to request the email verification code
  ///
  /// In fr, this message translates to:
  /// **'Recevoir le code'**
  String get regReceiveCode;

  /// Privacy note at the bottom of the email entry page
  ///
  /// In fr, this message translates to:
  /// **'Aucun nom, prénom ou adresse précise ne sera stocké. Seuls votre sexe, tranche d\'âge et code postal sont encodés (chiffrés) dans votre token anonyme.'**
  String get regEmailPrivacyNote;

  /// Title of the email OTP verification page
  ///
  /// In fr, this message translates to:
  /// **'Vérifier mon email'**
  String get regEmailOtpTitle;

  /// Label above the email address the OTP was sent to
  ///
  /// In fr, this message translates to:
  /// **'Code envoyé à'**
  String get regCodeSentTo;

  /// Button label while an OTP code is being verified
  ///
  /// In fr, this message translates to:
  /// **'Vérification…'**
  String get regVerifying;

  /// Button to resend the email verification code
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer le code'**
  String get regResendCode;

  /// Title of the phone entry page (step 2 of registration)
  ///
  /// In fr, this message translates to:
  /// **'Votre téléphone'**
  String get regPhoneTitle;

  /// Introductory text on the phone entry page
  ///
  /// In fr, this message translates to:
  /// **'Un code SMS à 6 chiffres sera envoyé pour vérifier votre numéro. Aucun lien entre votre numéro et votre token.'**
  String get regPhoneIntro;

  /// Hint of the phone number text field
  ///
  /// In fr, this message translates to:
  /// **'Numéro'**
  String get regPhoneFieldHint;

  /// Button label while the SMS OTP is being sent
  ///
  /// In fr, this message translates to:
  /// **'Envoi du SMS…'**
  String get regSendingSms;

  /// Button to request the SMS verification code
  ///
  /// In fr, this message translates to:
  /// **'Recevoir le SMS'**
  String get regReceiveSms;

  /// Title of the phone OTP verification page
  ///
  /// In fr, this message translates to:
  /// **'Vérifier mon téléphone'**
  String get regPhoneOtpTitle;

  /// Label above the phone number the SMS OTP was sent to
  ///
  /// In fr, this message translates to:
  /// **'SMS envoyé au'**
  String get regSmsSentTo;

  /// Button to resend the SMS verification code
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer le SMS'**
  String get regResendSms;

  /// Title of the demographics page (step 3 of registration)
  ///
  /// In fr, this message translates to:
  /// **'Vos données démographiques'**
  String get regDemoTitle;

  /// Introductory text on the demographics page
  ///
  /// In fr, this message translates to:
  /// **'Ces informations seront chiffrées dans votre token. Aucune valeur exacte n\'est stockée (ni âge précis, ni adresse précise).'**
  String get regDemoIntro;

  /// Section label (uppercase) for the sex selection
  ///
  /// In fr, this message translates to:
  /// **'SEXE'**
  String get regSectionSex;

  /// Section label (uppercase) for the age range selection
  ///
  /// In fr, this message translates to:
  /// **'TRANCHE D\'ÂGE'**
  String get regSectionAgeBucket;

  /// Section label (uppercase) for the country and postal code inputs
  ///
  /// In fr, this message translates to:
  /// **'PAYS ET CODE POSTAL'**
  String get regSectionCountryPostal;

  /// Hint of the postal code text field
  ///
  /// In fr, this message translates to:
  /// **'Code postal'**
  String get regPostalCodeHint;

  /// Button label while the anonymous token is being generated
  ///
  /// In fr, this message translates to:
  /// **'Génération du token…'**
  String get regGeneratingToken;

  /// Button to submit demographics and generate the anonymous token
  ///
  /// In fr, this message translates to:
  /// **'Générer mon token'**
  String get regGenerateMyToken;

  /// Title of the registration success page
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue dans Mental E.T.'**
  String get regSuccessTitle;

  /// Confirmation message on the success page
  ///
  /// In fr, this message translates to:
  /// **'Votre token anonyme a été généré et sauvegardé sur cet appareil.'**
  String get regSuccessTokenSaved;

  /// Details about the token content on the success page
  ///
  /// In fr, this message translates to:
  /// **'Il ne contient ni votre email, ni votre numéro de téléphone, ni votre nom. Uniquement votre sexe, votre tranche d\'âge et votre zone géographique (chiffrés). Vous pouvez maintenant commencer votre évaluation cognitive.'**
  String get regSuccessTokenDetails;

  /// Uppercase warning label on the success page
  ///
  /// In fr, this message translates to:
  /// **'IMPORTANT'**
  String get regImportantLabel;

  /// Warning about token being stored only on the device
  ///
  /// In fr, this message translates to:
  /// **'Ne désinstallez pas l\'application sans avoir terminé votre évaluation : votre token est uniquement stocké sur cet appareil. Si vous le perdez, vous ne pourrez plus créer de nouveau compte avec le même email ou téléphone.'**
  String get regSuccessWarning;

  /// Error when the email is already linked to an account
  ///
  /// In fr, this message translates to:
  /// **'Cet email a déjà un compte. Si c\'est le vôtre, vous avez déjà un token.'**
  String get regEmailAlreadyRegistered;

  /// Generic error when the email cannot be used
  ///
  /// In fr, this message translates to:
  /// **'Email indisponible.'**
  String get regEmailUnavailable;

  /// Error when an OTP code (email or SMS) is wrong or expired
  ///
  /// In fr, this message translates to:
  /// **'Code incorrect ou expiré.'**
  String get regOtpIncorrectOrExpired;

  /// Error when the phone number is already linked to an account
  ///
  /// In fr, this message translates to:
  /// **'Ce numéro a déjà un compte.'**
  String get regPhoneAlreadyRegistered;

  /// Generic error when the phone number cannot be used
  ///
  /// In fr, this message translates to:
  /// **'Numéro indisponible.'**
  String get regPhoneUnavailable;

  /// Error at token generation when the email already has a token
  ///
  /// In fr, this message translates to:
  /// **'Cet email a déjà un token.'**
  String get regEmailAlreadyHasToken;

  /// Error at token generation when the phone already has a token
  ///
  /// In fr, this message translates to:
  /// **'Ce numéro a déjà un token.'**
  String get regPhoneAlreadyHasToken;

  /// Error when the submitted postal code is unknown
  ///
  /// In fr, this message translates to:
  /// **'Code postal introuvable. Vérifiez le pays et le code.'**
  String get regPostalNotFound;

  /// Error when the network is unreachable
  ///
  /// In fr, this message translates to:
  /// **'Pas de connexion internet.'**
  String get regNoInternet;

  /// Generic fallback error during registration
  ///
  /// In fr, this message translates to:
  /// **'Erreur — merci de réessayer.'**
  String get regGenericRetryError;

  /// Displayed label for the male sex option
  ///
  /// In fr, this message translates to:
  /// **'Masculin'**
  String get regSexMale;

  /// Displayed label for the female sex option
  ///
  /// In fr, this message translates to:
  /// **'Féminin'**
  String get regSexFemale;

  /// Displayed label for the undisclosed sex option
  ///
  /// In fr, this message translates to:
  /// **'Préfère ne pas dire'**
  String get regSexUndisclosed;

  /// Displayed label for the 18-25 age range
  ///
  /// In fr, this message translates to:
  /// **'18 – 25 ans'**
  String get regAge1825;

  /// Displayed label for the 26-35 age range
  ///
  /// In fr, this message translates to:
  /// **'26 – 35 ans'**
  String get regAge2635;

  /// Displayed label for the 36-45 age range
  ///
  /// In fr, this message translates to:
  /// **'36 – 45 ans'**
  String get regAge3645;

  /// Displayed label for the 46-55 age range
  ///
  /// In fr, this message translates to:
  /// **'46 – 55 ans'**
  String get regAge4655;

  /// Displayed label for the 56-65 age range
  ///
  /// In fr, this message translates to:
  /// **'56 – 65 ans'**
  String get regAge5665;

  /// Displayed label for the 66+ age range
  ///
  /// In fr, this message translates to:
  /// **'66 ans et plus'**
  String get regAge66plus;

  /// Classification Wechsler pour un score composite >= 130 ou note standard >= 16
  ///
  /// In fr, this message translates to:
  /// **'Très supérieur'**
  String get scoringClassificationVerySuperior;

  /// Classification Wechsler pour un score composite 120-129 ou note standard 13-15
  ///
  /// In fr, this message translates to:
  /// **'Supérieur'**
  String get scoringClassificationSuperior;

  /// Classification Wechsler pour un score composite 110-119 ou note standard 11-12
  ///
  /// In fr, this message translates to:
  /// **'Moyen fort'**
  String get scoringClassificationHighAverage;

  /// Classification Wechsler pour un score composite 90-109 ou note standard 8-10
  ///
  /// In fr, this message translates to:
  /// **'Moyen'**
  String get scoringClassificationAverage;

  /// Classification Wechsler pour un score composite 80-89 ou note standard 6-7
  ///
  /// In fr, this message translates to:
  /// **'Moyen faible'**
  String get scoringClassificationLowAverage;

  /// Classification Wechsler pour un score composite 70-79 ou note standard 4-5
  ///
  /// In fr, this message translates to:
  /// **'Limite'**
  String get scoringClassificationBorderline;

  /// Classification Wechsler pour un score composite < 70 ou note standard < 4
  ///
  /// In fr, this message translates to:
  /// **'Extrêmement bas'**
  String get scoringClassificationExtremelyLow;

  /// Classification affichée quand la note standardisée d'un sous-test est absente
  ///
  /// In fr, this message translates to:
  /// **'N/A'**
  String get scoringNotAvailable;

  /// Ligne du résumé de profil : QI total avec sa classification
  ///
  /// In fr, this message translates to:
  /// **'QI Total: {score} ({classification})'**
  String scoringSummaryFullScaleIq(int score, String classification);

  /// Ligne du résumé de profil : rang percentile du QI total (suffixe ordinal 'e' en FR)
  ///
  /// In fr, this message translates to:
  /// **'Percentile: {rank}e'**
  String scoringSummaryPercentile(int rank);

  /// Ligne du résumé de profil : intervalle de confiance à 95% du QI total
  ///
  /// In fr, this message translates to:
  /// **'Intervalle de confiance 95%: {lower} - {upper}'**
  String scoringSummaryConfidenceInterval(int lower, int upper);

  /// Nom affiché de l'indice VCI (WAIS-IV)
  ///
  /// In fr, this message translates to:
  /// **'Compréhension Verbale'**
  String get scoringIndexVerbalComprehension;

  /// Nom affiché de l'indice VSI (WAIS-IV)
  ///
  /// In fr, this message translates to:
  /// **'Visuo-Spatial'**
  String get scoringIndexVisualSpatial;

  /// Nom affiché de l'indice FRI (WAIS-IV)
  ///
  /// In fr, this message translates to:
  /// **'Raisonnement Fluide'**
  String get scoringIndexFluidReasoning;

  /// Nom affiché de l'indice WMI (WAIS-IV)
  ///
  /// In fr, this message translates to:
  /// **'Mémoire de Travail'**
  String get scoringIndexWorkingMemory;

  /// Nom affiché de l'indice PSI (WAIS-IV)
  ///
  /// In fr, this message translates to:
  /// **'Vitesse de Traitement'**
  String get scoringIndexProcessingSpeed;

  /// Ligne du résumé de profil : liste des indices significativement au-dessus du QI total
  ///
  /// In fr, this message translates to:
  /// **'Forces relatives: {list}'**
  String scoringSummaryRelativeStrengths(String list);

  /// Ligne du résumé de profil : liste des indices significativement en dessous du QI total
  ///
  /// In fr, this message translates to:
  /// **'Faiblesses relatives: {list}'**
  String scoringSummaryRelativeWeaknesses(String list);

  /// Conclusion du résumé de profil quand les indices sont homogènes (écarts < 1 écart-type)
  ///
  /// In fr, this message translates to:
  /// **'Profil cognitif homogène'**
  String get scoringSummaryHomogeneousProfile;

  /// Conclusion du résumé de profil quand les indices sont hétérogènes, avec l'écart maximal en points
  ///
  /// In fr, this message translates to:
  /// **'Profil cognitif hétérogène (écart max: {points} points)'**
  String scoringSummaryHeterogeneousProfile(int points);

  /// Similitudes — nom du test affiché dans le scaffold
  ///
  /// In fr, this message translates to:
  /// **'Similitudes'**
  String get simTestName;

  /// Similitudes — sur-titre (catégorie d'indice) dans le scaffold
  ///
  /// In fr, this message translates to:
  /// **'COMPRÉHENSION VERBALE · VCI'**
  String get simEyebrow;

  /// Similitudes — barre d'état (temps écoulé + score) dans l'AppBar
  ///
  /// In fr, this message translates to:
  /// **'{seconds} s · {score} pts'**
  String simStatusBar(int seconds, int score);

  /// Similitudes — consigne affichée au-dessus de la paire de mots
  ///
  /// In fr, this message translates to:
  /// **'En quoi ces deux mots sont-ils similaires ?'**
  String get simQuestionPrompt;

  /// Similitudes — badge indiquant le niveau d'abstraction de l'item
  ///
  /// In fr, this message translates to:
  /// **'Niveau : {level}'**
  String simLevelLabel(String level);

  /// Similitudes — nom du niveau d'abstraction concret
  ///
  /// In fr, this message translates to:
  /// **'Concret'**
  String get simLevelConcrete;

  /// Similitudes — nom du niveau d'abstraction fonctionnel
  ///
  /// In fr, this message translates to:
  /// **'Fonctionnel'**
  String get simLevelFunctional;

  /// Similitudes — nom du niveau d'abstraction catégoriel
  ///
  /// In fr, this message translates to:
  /// **'Catégoriel'**
  String get simLevelCategorical;

  /// Similitudes — nom du niveau d'abstraction abstrait
  ///
  /// In fr, this message translates to:
  /// **'Abstrait'**
  String get simLevelAbstract;

  /// Similitudes — libellé au-dessus du champ de saisie de la réponse
  ///
  /// In fr, this message translates to:
  /// **'Votre réponse :'**
  String get simAnswerLabel;

  /// Similitudes — texte d'invite (hint) du champ de réponse
  ///
  /// In fr, this message translates to:
  /// **'Expliquez en quoi ils sont similaires...'**
  String get simAnswerHint;

  /// Similitudes — titre du bloc d'aide au scoring
  ///
  /// In fr, this message translates to:
  /// **'Conseils pour obtenir 2 points :'**
  String get simTipsTitle;

  /// Similitudes — premier conseil d'aide au scoring
  ///
  /// In fr, this message translates to:
  /// **'• Donnez une catégorie abstraite ou superordonnée'**
  String get simTipsLine1;

  /// Similitudes — deuxième conseil d'aide au scoring (exemples)
  ///
  /// In fr, this message translates to:
  /// **'• Ex: \"Ce sont des...\", \"Formes de...\", \"Types de...\"'**
  String get simTipsLine2;

  /// Similitudes — titre du dialogue de feedback pour une réponse à 2 points
  ///
  /// In fr, this message translates to:
  /// **'Excellent !'**
  String get simFeedbackExcellent;

  /// Similitudes — titre du dialogue de feedback pour une réponse à 1 point
  ///
  /// In fr, this message translates to:
  /// **'Correct'**
  String get simFeedbackCorrect;

  /// Similitudes — titre du dialogue de feedback pour une réponse à 0 point
  ///
  /// In fr, this message translates to:
  /// **'Réponse incomplète'**
  String get simFeedbackIncomplete;

  /// Similitudes — message de feedback pour une réponse à 2 points
  ///
  /// In fr, this message translates to:
  /// **'Réponse abstraite/catégorielle ! +2 points'**
  String get simFeedbackMsg2pts;

  /// Similitudes — message de feedback pour une réponse à 1 point
  ///
  /// In fr, this message translates to:
  /// **'Réponse fonctionnelle/propriété. +1 point'**
  String get simFeedbackMsg1pt;

  /// Similitudes — message de feedback pour une réponse à 0 point
  ///
  /// In fr, this message translates to:
  /// **'Réponse incorrecte ou trop vague. 0 point'**
  String get simFeedbackMsg0pt;

  /// Similitudes — rappel de la réponse saisie par l'utilisateur
  ///
  /// In fr, this message translates to:
  /// **'Votre réponse : \"{answer}\"'**
  String simYourAnswerQuoted(String answer);

  /// Similitudes — titre de la liste d'exemples de réponses à 2 points
  ///
  /// In fr, this message translates to:
  /// **'Exemples de réponses à 2 points :'**
  String get simExamples2pts;

  /// Similitudes — titre de la liste d'exemples de réponses à 1 point
  ///
  /// In fr, this message translates to:
  /// **'Exemples de réponses à 1 point :'**
  String get simExamples1pt;

  /// Similitudes — temps passé sur l'item dans le dialogue de feedback
  ///
  /// In fr, this message translates to:
  /// **'Temps : {seconds} s'**
  String simTimeSeconds(int seconds);

  /// Similitudes — score total dans le dialogue de feedback
  ///
  /// In fr, this message translates to:
  /// **'Score total : {score} points'**
  String simTotalScore(int score);

  /// Similitudes — message de règle de discontinuation après 3 échecs
  ///
  /// In fr, this message translates to:
  /// **'3 scores de 0 consécutifs - Test terminé (WAIS-IV)'**
  String get simDiscontinue;

  /// Similitudes — bouton du dialogue de feedback lorsque le test est terminé
  ///
  /// In fr, this message translates to:
  /// **'Voir les résultats'**
  String get simSeeResults;

  /// Similitudes — titre du dialogue de résultats finaux
  ///
  /// In fr, this message translates to:
  /// **'Test des Similitudes - Résultats'**
  String get simResultsTitle;

  /// Similitudes — score brut dans le dialogue de résultats
  ///
  /// In fr, this message translates to:
  /// **'Score brut : {score}/{max} points'**
  String simRawScore(int score, int max);

  /// Similitudes — nombre d'items complétés dans le dialogue de résultats
  ///
  /// In fr, this message translates to:
  /// **'Items complétés : {completed}/{total}'**
  String simItemsCompleted(int completed, int total);

  /// Similitudes — pourcentage de réussite dans le dialogue de résultats
  ///
  /// In fr, this message translates to:
  /// **'Pourcentage : {percent}%'**
  String simPercentage(int percent);

  /// Similitudes — temps total dans le dialogue de résultats
  ///
  /// In fr, this message translates to:
  /// **'Temps total : {seconds} s'**
  String simTotalTime(int seconds);

  /// Similitudes — sous-titre descriptif dans le dialogue de résultats
  ///
  /// In fr, this message translates to:
  /// **'Test de raisonnement verbal et abstraction conceptuelle'**
  String get simSubtitle;

  /// Similitudes — titre de la répartition des scores par niveau
  ///
  /// In fr, this message translates to:
  /// **'Répartition par niveau :'**
  String get simBreakdownTitle;

  /// Similitudes — ligne de répartition du score pour un niveau
  ///
  /// In fr, this message translates to:
  /// **'{level}: {total}/{max} points'**
  String simBreakdownLine(String level, int total, int max);

  /// Similitudes — niveau de performance exceptionnel
  ///
  /// In fr, this message translates to:
  /// **'Performance exceptionnelle (θ > +2.0)'**
  String get simPerfExceptional;

  /// Similitudes — niveau de performance supérieur
  ///
  /// In fr, this message translates to:
  /// **'Performance supérieure (θ > +1.0)'**
  String get simPerfSuperior;

  /// Similitudes — niveau de performance moyen
  ///
  /// In fr, this message translates to:
  /// **'Performance moyenne (θ ≈ 0)'**
  String get simPerfAverage;

  /// Similitudes — niveau de performance inférieur
  ///
  /// In fr, this message translates to:
  /// **'Performance inférieure (θ < 0)'**
  String get simPerfBelow;

  /// Similitudes — niveau de performance faible
  ///
  /// In fr, this message translates to:
  /// **'Performance faible (θ < -1.0)'**
  String get simPerfLow;

  /// Similitudes — bouton de retour du dialogue de résultats
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get simBack;

  /// Matrices — nom du test affiché dans le scaffold
  ///
  /// In fr, this message translates to:
  /// **'Matrices Progressives'**
  String get matTestName;

  /// Matrices — sur-titre (catégorie d'indice) dans le scaffold
  ///
  /// In fr, this message translates to:
  /// **'TEST DE QI · FSIQ'**
  String get matEyebrow;

  /// Matrices — titre du dialogue de feedback quand la réponse est juste
  ///
  /// In fr, this message translates to:
  /// **'Correct !'**
  String get matCorrect;

  /// Matrices/Balances — titre du dialogue de feedback quand la réponse est fausse
  ///
  /// In fr, this message translates to:
  /// **'Incorrect'**
  String get matIncorrect;

  /// Matrices — temps de réponse à l'item
  ///
  /// In fr, this message translates to:
  /// **'Temps de réponse : {seconds} s'**
  String matResponseTime(int seconds);

  /// Matrices/Balances — score courant (réussites sur items tentés)
  ///
  /// In fr, this message translates to:
  /// **'Score : {score}/{total}'**
  String matScoreFraction(int score, int total);

  /// Matrices — message de règle de discontinuation après 4 échecs
  ///
  /// In fr, this message translates to:
  /// **'4 échecs consécutifs - Test terminé (WAIS-IV)'**
  String get matDiscontinue4;

  /// Matrices/Cubes — bouton dialogue lorsque le test est terminé par discontinuation
  ///
  /// In fr, this message translates to:
  /// **'Voir résultats (test terminé)'**
  String get matSeeResultsEnded;

  /// Matrices/Cubes — bouton dialogue pour passer à l'item suivant
  ///
  /// In fr, this message translates to:
  /// **'Item suivant'**
  String get matNextItem;

  /// Matrices/Cubes — bouton dialogue pour voir les résultats au dernier item
  ///
  /// In fr, this message translates to:
  /// **'Voir résultats'**
  String get matSeeResults;

  /// Matrices — titre du dialogue de résultats finaux
  ///
  /// In fr, this message translates to:
  /// **'Test des Matrices terminé !'**
  String get matFinishedTitle;

  /// Matrices — libellé ligne résultat : score brut
  ///
  /// In fr, this message translates to:
  /// **'Score brut'**
  String get matRawScore;

  /// Matrices/Cubes — libellé ligne résultat : taux de réussite
  ///
  /// In fr, this message translates to:
  /// **'Taux de réussite'**
  String get matSuccessRate;

  /// Matrices — libellé ligne résultat : temps moyen par item
  ///
  /// In fr, this message translates to:
  /// **'Temps moyen/item'**
  String get matAvgTimePerItem;

  /// Matrices/Cubes — en-tête du bloc d'évaluation de performance
  ///
  /// In fr, this message translates to:
  /// **'Évaluation :'**
  String get matEvaluation;

  /// Matrices — niveau de performance ≥ 90%
  ///
  /// In fr, this message translates to:
  /// **'Excellent ! Raisonnement fluide très supérieur.'**
  String get matPerfExcellent;

  /// Matrices — niveau de performance ≥ 75%
  ///
  /// In fr, this message translates to:
  /// **'Très bien ! Bonnes capacités d\'analyse logique.'**
  String get matPerfVeryGood;

  /// Matrices/Cubes — niveau de performance ≥ 60%
  ///
  /// In fr, this message translates to:
  /// **'Bien. Capacités moyennes à bonnes.'**
  String get matPerfGood;

  /// Matrices/Cubes — niveau de performance ≥ 40%
  ///
  /// In fr, this message translates to:
  /// **'Moyen. Des améliorations sont possibles.'**
  String get matPerfAverage;

  /// Matrices/Cubes — niveau de performance < 40%
  ///
  /// In fr, this message translates to:
  /// **'Résultats en-dessous de la moyenne. Entraînement recommandé.'**
  String get matPerfBelowAverage;

  /// Matrices/Cubes — badge de score en pts dans l'AppBar
  ///
  /// In fr, this message translates to:
  /// **'{score} pts'**
  String matPoints(int score);

  /// Matrices — libellé du bouton de validation
  ///
  /// In fr, this message translates to:
  /// **'Valider la réponse'**
  String get matValidateAnswer;

  /// Matrices/Cubes — bouton pour relancer le test depuis le début
  ///
  /// In fr, this message translates to:
  /// **'Recommencer'**
  String get matRestart;

  /// Matrices — métadonnées techniques de l'item (nombre de règles et thêta IRT)
  ///
  /// In fr, this message translates to:
  /// **'Règles : {rules} | θ = {theta}'**
  String matRulesTheta(int rules, String theta);

  /// Matrices — consigne au-dessus de la grille
  ///
  /// In fr, this message translates to:
  /// **'Trouvez la pièce manquante qui complète logiquement la matrice'**
  String get matInstruction;

  /// Matrices/Balances — libellé au-dessus des options de réponse
  ///
  /// In fr, this message translates to:
  /// **'Choisissez la réponse :'**
  String get matChooseAnswer;

  /// Matrices/Cubes — étiquette de difficulté : facile
  ///
  /// In fr, this message translates to:
  /// **'Facile'**
  String get matDiffEasy;

  /// Matrices — étiquette de difficulté : moyen-facile
  ///
  /// In fr, this message translates to:
  /// **'Moyen-Facile'**
  String get matDiffMediumEasy;

  /// Matrices/Cubes — étiquette de difficulté : moyen
  ///
  /// In fr, this message translates to:
  /// **'Moyen'**
  String get matDiffMedium;

  /// Matrices — étiquette de difficulté : moyen-difficile
  ///
  /// In fr, this message translates to:
  /// **'Moyen-Difficile'**
  String get matDiffMediumHard;

  /// Matrices/Cubes — étiquette de difficulté : difficile
  ///
  /// In fr, this message translates to:
  /// **'Difficile'**
  String get matDiffHard;

  /// Cubes — nom du test affiché dans le scaffold
  ///
  /// In fr, this message translates to:
  /// **'Test des Cubes'**
  String get cubesTestName;

  /// Cubes — titre du dialogue de feedback quand la réponse est juste
  ///
  /// In fr, this message translates to:
  /// **'Bravo !'**
  String get cubesBravo;

  /// Cubes — temps écoulé (format mm:ss)
  ///
  /// In fr, this message translates to:
  /// **'Temps écoulé : {time}'**
  String cubesElapsedTime(String time);

  /// Cubes — points gagnés sur l'item
  ///
  /// In fr, this message translates to:
  /// **'Points gagnés : {points}'**
  String cubesPointsEarned(int points);

  /// Cubes — score total dans le dialogue de feedback
  ///
  /// In fr, this message translates to:
  /// **'Score total : {score}'**
  String cubesTotalScore(int score);

  /// Cubes — titre du dialogue de résultats finaux
  ///
  /// In fr, this message translates to:
  /// **'Test terminé !'**
  String get cubesFinishedTitle;

  /// Cubes — libellé ligne résultat : score total
  ///
  /// In fr, this message translates to:
  /// **'Score total'**
  String get cubesTotalScoreLabel;

  /// Cubes — valeur du score total sur le maximum
  ///
  /// In fr, this message translates to:
  /// **'{score}/{max} pts'**
  String cubesTotalScoreValue(int score, int max);

  /// Cubes — libellé ligne résultat : items complétés
  ///
  /// In fr, this message translates to:
  /// **'Items complétés'**
  String get cubesItemsCompletedLabel;

  /// Cubes — valeur items complétés sur 14
  ///
  /// In fr, this message translates to:
  /// **'{count}/14'**
  String cubesItemsCompletedValue(int count);

  /// Cubes — libellé ligne résultat : temps moyen
  ///
  /// In fr, this message translates to:
  /// **'Temps moyen'**
  String get cubesAvgTime;

  /// Cubes — niveau de performance ≥ 90%
  ///
  /// In fr, this message translates to:
  /// **'Excellent ! Capacités visuospatiales très supérieures.'**
  String get cubesPerfExcellent;

  /// Cubes — niveau de performance ≥ 75%
  ///
  /// In fr, this message translates to:
  /// **'Très bien ! Bonnes capacités d\'analyse visuelle.'**
  String get cubesPerfVeryGood;

  /// Cubes — étiquette de difficulté : item exemple
  ///
  /// In fr, this message translates to:
  /// **'Exemple'**
  String get cubesDiffExample;

  /// Cubes — étiquette de difficulté : très difficile
  ///
  /// In fr, this message translates to:
  /// **'Très difficile'**
  String get cubesDiffVeryHard;

  /// Cubes — description métadonnée de l'item exemple
  ///
  /// In fr, this message translates to:
  /// **'Item exemple - Ne compte pas pour le score'**
  String get cubesDescExample;

  /// Cubes — description métadonnée : pattern 2×2 simple
  ///
  /// In fr, this message translates to:
  /// **'Pattern 2×2 simple'**
  String get cubesDesc2x2;

  /// Cubes — description métadonnée : pattern 3×3 avec diagonales
  ///
  /// In fr, this message translates to:
  /// **'Pattern 3×3 avec diagonales'**
  String get cubesDesc3x3Diagonals;

  /// Cubes — description métadonnée : pattern 3×3 complexe haute cohésion
  ///
  /// In fr, this message translates to:
  /// **'Pattern 3×3 complexe - Haute cohésion'**
  String get cubesDesc3x3Complex;

  /// Cubes — métadonnée score de cohésion de l'item
  ///
  /// In fr, this message translates to:
  /// **'Cohésion: {score}'**
  String cubesCohesion(int score);

  /// Cubes — temps restant dans l'en-tête de l'exercice (format mm:ss)
  ///
  /// In fr, this message translates to:
  /// **'Reste: {time}'**
  String cubesRemaining(String time);

  /// Cubes — consigne de l'exercice
  ///
  /// In fr, this message translates to:
  /// **'Reproduisez le pattern ci-dessous en tapant sur les cubes'**
  String get cubesReproduceInstruction;

  /// Cubes — libellé de la grille cible
  ///
  /// In fr, this message translates to:
  /// **'Pattern à reproduire :'**
  String get cubesPatternToReproduce;

  /// Cubes — libellé de la grille de l'utilisateur
  ///
  /// In fr, this message translates to:
  /// **'Votre réponse :'**
  String get cubesYourAnswer;

  /// Cubes — bouton de réinitialisation de la grille
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser'**
  String get cubesReset;

  /// Balances — nom du test affiché dans le scaffold
  ///
  /// In fr, this message translates to:
  /// **'Balances Quantitatives'**
  String get fwTestName;

  /// Balances/Cubes — sur-titre (catégorie d'indice FRI) dans le scaffold
  ///
  /// In fr, this message translates to:
  /// **'RAISONNEMENT FLUIDE · FRI'**
  String get fwEyebrow;

  /// Balances — message de feedback réponse juste
  ///
  /// In fr, this message translates to:
  /// **'Bonne réponse ! +1 point'**
  String get fwCorrectAnswerPoint;

  /// Balances — message de feedback réponse fausse
  ///
  /// In fr, this message translates to:
  /// **'Mauvaise réponse. La bonne réponse était :'**
  String get fwWrongAnswer;

  /// Balances — temps passé sur l'item
  ///
  /// In fr, this message translates to:
  /// **'Temps : {seconds} s'**
  String fwTime(int seconds);

  /// Balances — message de règle de discontinuation après 3 échecs
  ///
  /// In fr, this message translates to:
  /// **'3 échecs consécutifs - Test terminé (WAIS-IV)'**
  String get fwDiscontinue3;

  /// Balances — bouton dialogue pour voir les résultats
  ///
  /// In fr, this message translates to:
  /// **'Voir les résultats'**
  String get fwSeeResults;

  /// Balances — titre du dialogue de résultats finaux
  ///
  /// In fr, this message translates to:
  /// **'Test des Balances Quantitatives - Résultats'**
  String get fwResultsTitle;

  /// Balances — score brut sur 27
  ///
  /// In fr, this message translates to:
  /// **'Score brut : {score}/27 points'**
  String fwRawScorePoints(int score);

  /// Balances — items complétés sur 27
  ///
  /// In fr, this message translates to:
  /// **'Items complétés : {count}/27'**
  String fwItemsCompleted(int count);

  /// Balances — pourcentage de réussite
  ///
  /// In fr, this message translates to:
  /// **'Pourcentage : {percent}%'**
  String fwPercentage(int percent);

  /// Balances — temps total
  ///
  /// In fr, this message translates to:
  /// **'Temps total : {seconds} s'**
  String fwTotalTime(int seconds);

  /// Balances — note technique sur la saturation en facteur g
  ///
  /// In fr, this message translates to:
  /// **'g-loading : 0.78 (le plus élevé du WAIS-IV)'**
  String get fwGLoading;

  /// Balances — niveau de performance score ≥ 23
  ///
  /// In fr, this message translates to:
  /// **'Performance exceptionnelle (θ > +2.0)'**
  String get fwPerfExceptional;

  /// Balances — niveau de performance score ≥ 18
  ///
  /// In fr, this message translates to:
  /// **'Performance supérieure (θ > +1.0)'**
  String get fwPerfSuperior;

  /// Balances — niveau de performance score ≥ 12
  ///
  /// In fr, this message translates to:
  /// **'Performance moyenne (θ ≈ 0)'**
  String get fwPerfAverage;

  /// Balances — niveau de performance score ≥ 7
  ///
  /// In fr, this message translates to:
  /// **'Performance inférieure (θ < 0)'**
  String get fwPerfInferior;

  /// Balances — niveau de performance score < 7
  ///
  /// In fr, this message translates to:
  /// **'Performance faible (θ < -1.0)'**
  String get fwPerfLow;

  /// Balances — badge score/total dans l'AppBar
  ///
  /// In fr, this message translates to:
  /// **'{score}/{total}'**
  String fwScoreFraction(int score, int total);

  /// Balances — consigne en haut de l'écran
  ///
  /// In fr, this message translates to:
  /// **'Trouvez la valeur manquante qui équilibre la balance.'**
  String get fwInstruction;

  /// Balances — début de la question (suivi des jetons cibles puis « ? »)
  ///
  /// In fr, this message translates to:
  /// **'Que vaut '**
  String get fwWhatIs;

  /// Balances — badge de compte à rebours du timer
  ///
  /// In fr, this message translates to:
  /// **'{seconds} s'**
  String fwSeconds(int seconds);

  /// Puzzles visuels — nom du test affiché dans le scaffold
  ///
  /// In fr, this message translates to:
  /// **'Puzzles Visuels'**
  String get vpTestName;

  /// Puzzles visuels — sur-titre (catégorie d'indice VSI) dans le scaffold
  ///
  /// In fr, this message translates to:
  /// **'VISUO-SPATIAL · VSI'**
  String get vpEyebrow;

  /// Puzzles visuels — état du bouton après validation correcte
  ///
  /// In fr, this message translates to:
  /// **'Correct'**
  String get vpCorrect;

  /// Puzzles visuels — état du bouton après validation incorrecte
  ///
  /// In fr, this message translates to:
  /// **'Incorrect'**
  String get vpIncorrect;

  /// Puzzles visuels — libellé du bouton de validation (3 pièces sélectionnées)
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get vpValidate;

  /// Puzzles visuels — libellé du bouton tant que moins de 3 pièces sont sélectionnées
  ///
  /// In fr, this message translates to:
  /// **'{count} / 3 sélectionnées'**
  String vpSelectedCount(int count);

  /// Puzzles visuels — consigne sous la figure cible
  ///
  /// In fr, this message translates to:
  /// **'Choisissez les 3 pièces qui forment la figure (rotations permises, retournements interdits).'**
  String get vpInstruction;

  /// Puzzles visuels — eyebrow de la phase de démonstration non chronométrée
  ///
  /// In fr, this message translates to:
  /// **'DÉMONSTRATION'**
  String get vpDemoEyebrow;

  /// Puzzles visuels — consigne de l'item de démonstration
  ///
  /// In fr, this message translates to:
  /// **'Entraînement sans chrono : choisissez les 3 pièces qui forment la figure, puis validez.'**
  String get vpDemoInstruction;

  /// Puzzles visuels — bouton après une démo réussie, lance les items chronométrés
  ///
  /// In fr, this message translates to:
  /// **'Commencer le test'**
  String get vpDemoStart;

  /// Puzzles visuels — bouton après une démo ratée, réinitialise la démo
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get vpDemoRetry;

  /// Puzzles visuels — libellé neutre du bouton après validation d'un item réel (aucun feedback correct/incorrect pendant le test, conforme au protocole)
  ///
  /// In fr, this message translates to:
  /// **'Réponse enregistrée'**
  String get vpRecorded;

  /// Puzzles visuels — titre de l'écran intermédiaire entre la démonstration et le premier item chronométré
  ///
  /// In fr, this message translates to:
  /// **'Prêt ?'**
  String get vpReadyTitle;

  /// Puzzles visuels — texte de l'écran Prêt ; le chrono ne démarre qu'à l'appui sur le bouton
  ///
  /// In fr, this message translates to:
  /// **'L\'entraînement est terminé. Le test commence : {count} puzzles, chacun avec son propre chrono. Le temps démarre dès que vous appuyez sur le bouton.'**
  String vpReadyBody(int count);

  /// Puzzles visuels — bouton de l'écran Prêt qui démarre l'item 1 et son chrono
  ///
  /// In fr, this message translates to:
  /// **'Lancer le test'**
  String get vpReadyStart;

  /// Puzzles visuels — étiquette d'accessibilité de l'indicateur de sélection
  ///
  /// In fr, this message translates to:
  /// **'Sélection : {filled} sur {total} pièces'**
  String vpSelectionSemantics(int filled, int total);

  /// Puzzles visuels — libellé en capitales de l'indicateur de sélection
  ///
  /// In fr, this message translates to:
  /// **'SÉLECTION'**
  String get vpSelectionLabel;

  /// Puzzles visuels — étiquette d'accessibilité d'une pièce (le label est un chiffre)
  ///
  /// In fr, this message translates to:
  /// **'Pièce {label}'**
  String vpPieceSemantics(String label);

  /// Puzzles visuels — titre en capitales au-dessus de la figure cible
  ///
  /// In fr, this message translates to:
  /// **'FIGURE À RECONSTITUER'**
  String get vpTargetTitle;

  /// Coding test name (scaffold header)
  ///
  /// In fr, this message translates to:
  /// **'Code (Digit Symbol)'**
  String get codingTestName;

  /// Coding test eyebrow label
  ///
  /// In fr, this message translates to:
  /// **'VITESSE DE TRAITEMENT · PSI'**
  String get codingEyebrow;

  /// Coding/Symbol Search start training button
  ///
  /// In fr, this message translates to:
  /// **'Commencer l\'entraînement'**
  String get codingStartTraining;

  /// Coding intro title
  ///
  /// In fr, this message translates to:
  /// **'Test de Code'**
  String get codingTitle;

  /// Coding intro description
  ///
  /// In fr, this message translates to:
  /// **'Ce test mesure votre vitesse de traitement et votre coordination visuomotrice.'**
  String get codingDescription;

  /// Coding reference key label (intro)
  ///
  /// In fr, this message translates to:
  /// **'Clé de référence :'**
  String get codingReferenceKey;

  /// Coding info card title - task
  ///
  /// In fr, this message translates to:
  /// **'Votre tâche'**
  String get codingTaskTitle;

  /// Coding info card subtitle - task
  ///
  /// In fr, this message translates to:
  /// **'Pour chaque chiffre affiché, sélectionnez le symbole correspondant'**
  String get codingTaskDesc;

  /// Coding info card title - time limit
  ///
  /// In fr, this message translates to:
  /// **'Temps limité'**
  String get codingTimeLimitTitle;

  /// Coding info card subtitle - time limit
  ///
  /// In fr, this message translates to:
  /// **'120 secondes pour compléter le maximum de cases (135 au total)'**
  String get codingTimeLimitDesc;

  /// Coding info card title - scoring
  ///
  /// In fr, this message translates to:
  /// **'Scoring'**
  String get codingScoringTitle;

  /// Coding info card subtitle - scoring
  ///
  /// In fr, this message translates to:
  /// **'1 point par case correcte, pas de pénalité pour les erreurs'**
  String get codingScoringDesc;

  /// Coding training-finished dialog title
  ///
  /// In fr, this message translates to:
  /// **'Entraînement terminé'**
  String get codingTrainingDoneTitle;

  /// Coding training-finished dialog body
  ///
  /// In fr, this message translates to:
  /// **'Vous êtes prêt à commencer le test. Vous aurez 120 secondes pour compléter le maximum de cases.'**
  String get codingTrainingDoneBody;

  /// Coding/Symbol Search/Digit Span start test button
  ///
  /// In fr, this message translates to:
  /// **'Commencer le test'**
  String get codingStartTest;

  /// Test finished dialog title (Coding/Symbol Search/Digit Span/Picture Span)
  ///
  /// In fr, this message translates to:
  /// **'Test terminé !'**
  String get codingTestDoneTitle;

  /// Coding result - time elapsed
  ///
  /// In fr, this message translates to:
  /// **'Temps écoulé : 120 secondes'**
  String get codingTimeElapsed;

  /// Coding result - completed cells
  ///
  /// In fr, this message translates to:
  /// **'Cases complétées : {count}/135'**
  String codingCellsCompleted(int count);

  /// Coding result - correct cells
  ///
  /// In fr, this message translates to:
  /// **'Cases correctes : {count}'**
  String codingCellsCorrect(int count);

  /// Coding result - score points
  ///
  /// In fr, this message translates to:
  /// **'Score : {count} points'**
  String codingScorePoints(int count);

  /// Coding/Symbol Search performance message - exceptional
  ///
  /// In fr, this message translates to:
  /// **'Performance exceptionnelle !'**
  String get codingPerfExceptional;

  /// Coding/Symbol Search performance message - very good
  ///
  /// In fr, this message translates to:
  /// **'Très bonne performance'**
  String get codingPerfVeryGood;

  /// Coding performance message - above average
  ///
  /// In fr, this message translates to:
  /// **'Performance moyenne-haute'**
  String get codingPerfAboveAverage;

  /// Coding/Symbol Search performance message - average
  ///
  /// In fr, this message translates to:
  /// **'Performance moyenne'**
  String get codingPerfAverage;

  /// Coding/Symbol Search performance message - below average
  ///
  /// In fr, this message translates to:
  /// **'Performance en-dessous de la moyenne'**
  String get codingPerfBelowAverage;

  /// Coding/Symbol Search app bar title in training mode
  ///
  /// In fr, this message translates to:
  /// **'Entraînement'**
  String get codingTrainingTab;

  /// Coding reference key label (test screen)
  ///
  /// In fr, this message translates to:
  /// **'Référence :'**
  String get codingReferenceShort;

  /// Coding cell progress
  ///
  /// In fr, this message translates to:
  /// **'Case {current}/{total}'**
  String codingCellProgress(int current, int total);

  /// Coding completed-cells progress
  ///
  /// In fr, this message translates to:
  /// **'Complétées : {count}/{total}'**
  String codingCompletedProgress(int count, int total);

  /// Coding palette label
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez un symbole :'**
  String get codingSelectSymbol;

  /// Coding clear-cell button
  ///
  /// In fr, this message translates to:
  /// **'Effacer'**
  String get codingClear;

  /// Coding finish-training button
  ///
  /// In fr, this message translates to:
  /// **'Terminer l\'entraînement'**
  String get codingFinishTraining;

  /// Symbol Search test name / title / app bar title
  ///
  /// In fr, this message translates to:
  /// **'Recherche de Symboles'**
  String get ssTestName;

  /// Symbol Search intro description
  ///
  /// In fr, this message translates to:
  /// **'Ce test mesure votre vitesse de traitement visuelle et votre capacité de discrimination.'**
  String get ssDescription;

  /// Symbol Search example label
  ///
  /// In fr, this message translates to:
  /// **'Exemple d\'item :'**
  String get ssExampleLabel;

  /// Symbol Search targets label (example)
  ///
  /// In fr, this message translates to:
  /// **'CIBLES'**
  String get ssTargets;

  /// Symbol Search group label (example)
  ///
  /// In fr, this message translates to:
  /// **'GROUPE'**
  String get ssGroup;

  /// Symbol Search example answer line
  ///
  /// In fr, this message translates to:
  /// **'→ Réponse : OUI (┴ est présent)'**
  String get ssExampleAnswer;

  /// Symbol Search info card title - task
  ///
  /// In fr, this message translates to:
  /// **'Votre tâche'**
  String get ssTaskTitle;

  /// Symbol Search info card subtitle - task
  ///
  /// In fr, this message translates to:
  /// **'Cherchez si l\'un des symboles cibles apparaît dans le groupe'**
  String get ssTaskDesc;

  /// Symbol Search info card title - quick answer
  ///
  /// In fr, this message translates to:
  /// **'Réponse rapide'**
  String get ssQuickAnswerTitle;

  /// Symbol Search info card subtitle - quick answer
  ///
  /// In fr, this message translates to:
  /// **'Cliquez OUI ou NON aussi vite que possible'**
  String get ssQuickAnswerDesc;

  /// Symbol Search info card title - scoring
  ///
  /// In fr, this message translates to:
  /// **'Scoring avec pénalité'**
  String get ssScoringPenaltyTitle;

  /// Symbol Search scoring formula
  ///
  /// In fr, this message translates to:
  /// **'Score = Réponses correctes - Réponses incorrectes'**
  String get ssScoringPenaltyDesc;

  /// Symbol Search info card title - time limit
  ///
  /// In fr, this message translates to:
  /// **'Temps limité'**
  String get ssTimeLimitTitle;

  /// Symbol Search info card subtitle - time limit
  ///
  /// In fr, this message translates to:
  /// **'120 secondes pour 60 items'**
  String get ssTimeLimitDesc;

  /// Symbol Search training-finished dialog body
  ///
  /// In fr, this message translates to:
  /// **'Vous êtes prêt ! Vous aurez 120 secondes pour compléter le maximum d\'items.\n\nRappel : Score = Réponses correctes - Réponses incorrectes'**
  String get ssTrainingDoneBody;

  /// Symbol Search result - items answered
  ///
  /// In fr, this message translates to:
  /// **'Items répondus : {count}/60'**
  String ssItemsAnswered(int count);

  /// Symbol Search result - correct answers
  ///
  /// In fr, this message translates to:
  /// **'Réponses correctes : {count}'**
  String ssCorrectAnswers(int count);

  /// Symbol Search result - incorrect answers
  ///
  /// In fr, this message translates to:
  /// **'Réponses incorrectes : {count}'**
  String ssIncorrectAnswers(int count);

  /// Symbol Search result - not answered
  ///
  /// In fr, this message translates to:
  /// **'Non répondus : {count}'**
  String ssNotAnswered(int count);

  /// Symbol Search result - raw score
  ///
  /// In fr, this message translates to:
  /// **'Score brut : {count}'**
  String ssRawScore(int count);

  /// Symbol Search raw-score formula caption
  ///
  /// In fr, this message translates to:
  /// **'(Corrects - Incorrects)'**
  String get ssScoreFormulaShort;

  /// Symbol Search performance message - good
  ///
  /// In fr, this message translates to:
  /// **'Bonne performance'**
  String get ssPerfGood;

  /// Symbol Search item progress
  ///
  /// In fr, this message translates to:
  /// **'Item {current}/{total}'**
  String ssItemProgress(int current, int total);

  /// Symbol Search answered progress
  ///
  /// In fr, this message translates to:
  /// **'Répondus : {count}/60'**
  String ssAnsweredProgress(int count);

  /// Symbol Search target symbols section label
  ///
  /// In fr, this message translates to:
  /// **'SYMBOLES CIBLES'**
  String get ssTargetSymbols;

  /// Symbol Search search group section label
  ///
  /// In fr, this message translates to:
  /// **'GROUPE DE RECHERCHE'**
  String get ssSearchGroup;

  /// Symbol Search NO answer button
  ///
  /// In fr, this message translates to:
  /// **'NON'**
  String get ssNo;

  /// Symbol Search YES answer button
  ///
  /// In fr, this message translates to:
  /// **'OUI'**
  String get ssYes;

  /// Digit Span test name / title
  ///
  /// In fr, this message translates to:
  /// **'Mémoire des Chiffres'**
  String get dsTestName;

  /// Digit Span / Picture Span eyebrow label
  ///
  /// In fr, this message translates to:
  /// **'MÉMOIRE DE TRAVAIL · WMI'**
  String get dsEyebrow;

  /// Digit Span intro description
  ///
  /// In fr, this message translates to:
  /// **'Ce test mesure votre mémoire de travail à travers 3 parties distinctes :'**
  String get dsDescription;

  /// Digit Span intro card - forward title
  ///
  /// In fr, this message translates to:
  /// **'Partie 1 : Empan Direct'**
  String get dsForwardTitle;

  /// Digit Span forward instruction
  ///
  /// In fr, this message translates to:
  /// **'Répétez les chiffres dans le même ordre'**
  String get dsForwardInstruction;

  /// Digit Span intro card - backward title
  ///
  /// In fr, this message translates to:
  /// **'Partie 2 : Empan Inverse'**
  String get dsBackwardTitle;

  /// Digit Span backward instruction
  ///
  /// In fr, this message translates to:
  /// **'Répétez les chiffres en ordre inverse'**
  String get dsBackwardInstruction;

  /// Digit Span intro card - sequencing title
  ///
  /// In fr, this message translates to:
  /// **'Partie 3 : Séquençage'**
  String get dsSequencingTitle;

  /// Digit Span sequencing instruction
  ///
  /// In fr, this message translates to:
  /// **'Répétez les chiffres en ordre croissant'**
  String get dsSequencingInstruction;

  /// Digit Span presentation rate info
  ///
  /// In fr, this message translates to:
  /// **'Les chiffres seront présentés à raison de 1 chiffre par seconde.'**
  String get dsPresentationInfo;

  /// Digit Span type label - forward (app bar / part title)
  ///
  /// In fr, this message translates to:
  /// **'Empan Direct'**
  String get dsTypeForward;

  /// Digit Span type label - backward
  ///
  /// In fr, this message translates to:
  /// **'Empan Inverse'**
  String get dsTypeBackward;

  /// Digit Span type label - sequencing
  ///
  /// In fr, this message translates to:
  /// **'Séquençage'**
  String get dsTypeSequencing;

  /// Digit Span start-part button
  ///
  /// In fr, this message translates to:
  /// **'Commencer'**
  String get dsStartPart;

  /// Digit Span length/trial header
  ///
  /// In fr, this message translates to:
  /// **'Longueur {length} - Essai {trial}'**
  String dsLengthTrial(int length, int trial);

  /// Digit Span presentation prompt
  ///
  /// In fr, this message translates to:
  /// **'Écoutez attentivement'**
  String get dsListenCarefully;

  /// Digit Span / Picture Span feedback - correct
  ///
  /// In fr, this message translates to:
  /// **'Correct !'**
  String get dsCorrect;

  /// Digit Span / Picture Span feedback - incorrect
  ///
  /// In fr, this message translates to:
  /// **'Incorrect'**
  String get dsIncorrect;

  /// Digit Span feedback - points earned
  ///
  /// In fr, this message translates to:
  /// **'Points gagnés : {count}'**
  String dsPointsEarned(int count);

  /// Digit Span feedback - correct answer
  ///
  /// In fr, this message translates to:
  /// **'Réponse correcte : {answer}'**
  String dsCorrectAnswer(String answer);

  /// Digit Span feedback - your answer
  ///
  /// In fr, this message translates to:
  /// **'Votre réponse : {answer}'**
  String dsYourAnswer(String answer);

  /// Digit Span final results header
  ///
  /// In fr, this message translates to:
  /// **'Résultats par partie :'**
  String get dsResultsByPart;

  /// Digit Span final - forward score
  ///
  /// In fr, this message translates to:
  /// **'Empan Direct : {count} points'**
  String dsForwardScore(int count);

  /// Digit Span final - backward score
  ///
  /// In fr, this message translates to:
  /// **'Empan Inverse : {count} points'**
  String dsBackwardScore(int count);

  /// Digit Span final - sequencing score
  ///
  /// In fr, this message translates to:
  /// **'Séquençage : {count} points'**
  String dsSequencingScore(int count);

  /// Digit Span / Picture Span final - total score
  ///
  /// In fr, this message translates to:
  /// **'Score Total : {count} points'**
  String dsTotalScore(int count);

  /// Digit Span input placeholder
  ///
  /// In fr, this message translates to:
  /// **'Saisissez votre réponse...'**
  String get dsEnterAnswer;

  /// Digit Span submit button with progress
  ///
  /// In fr, this message translates to:
  /// **'Valider ({count}/{total})'**
  String dsValidateProgress(int count, int total);

  /// Picture Span test name / title
  ///
  /// In fr, this message translates to:
  /// **'Mémoire des Images'**
  String get psTestName;

  /// Picture Span intro description
  ///
  /// In fr, this message translates to:
  /// **'Ce test mesure votre mémoire de travail visuelle et votre attention sélective.'**
  String get psDescription;

  /// Picture Span intro card - phase 1 title
  ///
  /// In fr, this message translates to:
  /// **'Phase 1 : Mémorisation'**
  String get psPhase1Title;

  /// Picture Span intro card - phase 1 subtitle
  ///
  /// In fr, this message translates to:
  /// **'Des images seront présentées une par une (3 secondes chacune)'**
  String get psPhase1Desc;

  /// Picture Span intro card - phase 2 title
  ///
  /// In fr, this message translates to:
  /// **'Phase 2 : Rappel'**
  String get psPhase2Title;

  /// Picture Span intro card - phase 2 subtitle
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez les images dans l\'ordre exact de présentation'**
  String get psPhase2Desc;

  /// Picture Span intro card - progression title
  ///
  /// In fr, this message translates to:
  /// **'Progression'**
  String get psProgressionTitle;

  /// Picture Span intro card - progression subtitle
  ///
  /// In fr, this message translates to:
  /// **'La difficulté augmente : 1 à 6 images à mémoriser'**
  String get psProgressionDesc;

  /// Picture Span trials info
  ///
  /// In fr, this message translates to:
  /// **'12 essais au total. Le test s\'arrête après 2 échecs au même niveau.'**
  String get psTrialsInfo;

  /// Picture Span presentation app bar title
  ///
  /// In fr, this message translates to:
  /// **'Mémorisation'**
  String get psMemorizationTab;

  /// Picture Span recall app bar title
  ///
  /// In fr, this message translates to:
  /// **'Rappel'**
  String get psRecallTab;

  /// Picture Span level/trial header
  ///
  /// In fr, this message translates to:
  /// **'Niveau {level} - Essai {trial}'**
  String psLevelTrial(int level, int trial);

  /// Picture Span presentation prompt
  ///
  /// In fr, this message translates to:
  /// **'Mémorisez les images'**
  String get psMemorizeImages;

  /// Picture Span image progress
  ///
  /// In fr, this message translates to:
  /// **'Image {current} / {total}'**
  String psImageProgress(int current, int total);

  /// Picture Span recall instruction
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez les {count} images dans l\'ordre'**
  String psSelectInOrder(int count);

  /// Picture Span recall - empty selection
  ///
  /// In fr, this message translates to:
  /// **'Aucune sélection'**
  String get psNoSelection;

  /// Picture Span clear-last-selection button
  ///
  /// In fr, this message translates to:
  /// **'Effacer la dernière sélection'**
  String get psClearLast;

  /// Picture Span feedback - correct order
  ///
  /// In fr, this message translates to:
  /// **'Ordre correct : {names}'**
  String psCorrectOrder(String names);

  /// Picture Span feedback - your order
  ///
  /// In fr, this message translates to:
  /// **'Votre ordre : {names}'**
  String psYourOrder(String names);

  /// Picture Span final - trials completed
  ///
  /// In fr, this message translates to:
  /// **'Essais complétés : {count}/12'**
  String psTrialsCompleted(int count);

  /// Picture Span final - total score
  ///
  /// In fr, this message translates to:
  /// **'Score Total : {count} points'**
  String psScorePoints(int count);

  /// Picture Span final - max level
  ///
  /// In fr, this message translates to:
  /// **'Niveau maximal atteint : Niveau {level}'**
  String psMaxLevel(int level);

  /// Picture Span image name - cat
  ///
  /// In fr, this message translates to:
  /// **'Chat'**
  String get psImgChat;

  /// Picture Span image name - insect
  ///
  /// In fr, this message translates to:
  /// **'Insecte'**
  String get psImgInsecte;

  /// Picture Span image name - rabbit
  ///
  /// In fr, this message translates to:
  /// **'Lapin'**
  String get psImgLapin;

  /// Picture Span image name - bird
  ///
  /// In fr, this message translates to:
  /// **'Oiseau'**
  String get psImgOiseau;

  /// Picture Span image name - fish
  ///
  /// In fr, this message translates to:
  /// **'Poisson'**
  String get psImgPoisson;

  /// Picture Span image name - turtle
  ///
  /// In fr, this message translates to:
  /// **'Tortue'**
  String get psImgTortue;

  /// Picture Span image name - butterfly
  ///
  /// In fr, this message translates to:
  /// **'Papillon'**
  String get psImgPapillon;

  /// Picture Span image name - ladybug
  ///
  /// In fr, this message translates to:
  /// **'Coccinelle'**
  String get psImgCoccinelle;

  /// Picture Span image name - chair
  ///
  /// In fr, this message translates to:
  /// **'Chaise'**
  String get psImgChaise;

  /// Picture Span image name - lamp
  ///
  /// In fr, this message translates to:
  /// **'Lampe'**
  String get psImgLampe;

  /// Picture Span image name - watch
  ///
  /// In fr, this message translates to:
  /// **'Montre'**
  String get psImgMontre;

  /// Picture Span image name - umbrella
  ///
  /// In fr, this message translates to:
  /// **'Parapluie'**
  String get psImgParapluie;

  /// Picture Span image name - bag
  ///
  /// In fr, this message translates to:
  /// **'Sac'**
  String get psImgSac;

  /// Picture Span image name - bed
  ///
  /// In fr, this message translates to:
  /// **'Lit'**
  String get psImgLit;

  /// Picture Span image name - door
  ///
  /// In fr, this message translates to:
  /// **'Porte'**
  String get psImgPorte;

  /// Picture Span image name - window
  ///
  /// In fr, this message translates to:
  /// **'Fenêtre'**
  String get psImgFenetre;

  /// Picture Span image name - cake
  ///
  /// In fr, this message translates to:
  /// **'Gâteau'**
  String get psImgGateau;

  /// Picture Span image name - coffee
  ///
  /// In fr, this message translates to:
  /// **'Café'**
  String get psImgCafe;

  /// Picture Span image name - pizza
  ///
  /// In fr, this message translates to:
  /// **'Pizza'**
  String get psImgPizza;

  /// Picture Span image name - apple
  ///
  /// In fr, this message translates to:
  /// **'Pomme'**
  String get psImgPomme;

  /// Picture Span image name - ice cream
  ///
  /// In fr, this message translates to:
  /// **'Glace'**
  String get psImgGlace;

  /// Picture Span image name - burger
  ///
  /// In fr, this message translates to:
  /// **'Burger'**
  String get psImgBurger;

  /// Picture Span image name - sandwich
  ///
  /// In fr, this message translates to:
  /// **'Sandwich'**
  String get psImgSandwich;

  /// Picture Span image name - egg
  ///
  /// In fr, this message translates to:
  /// **'Œuf'**
  String get psImgOeuf;

  /// Picture Span image name - hammer
  ///
  /// In fr, this message translates to:
  /// **'Marteau'**
  String get psImgMarteau;

  /// Picture Span image name - wrench
  ///
  /// In fr, this message translates to:
  /// **'Clé'**
  String get psImgCle;

  /// Picture Span image name - scissors
  ///
  /// In fr, this message translates to:
  /// **'Ciseaux'**
  String get psImgCiseaux;

  /// Picture Span image name - brush
  ///
  /// In fr, this message translates to:
  /// **'Pinceau'**
  String get psImgPinceau;

  /// Picture Span image name - pencil
  ///
  /// In fr, this message translates to:
  /// **'Crayon'**
  String get psImgCrayon;

  /// Picture Span image name - knife
  ///
  /// In fr, this message translates to:
  /// **'Couteau'**
  String get psImgCouteau;

  /// Picture Span image name - screwdriver
  ///
  /// In fr, this message translates to:
  /// **'Tournevis'**
  String get psImgTournevis;

  /// Picture Span image name - gear
  ///
  /// In fr, this message translates to:
  /// **'Engrenage'**
  String get psImgEngrenage;

  /// Picture Span image name - car
  ///
  /// In fr, this message translates to:
  /// **'Voiture'**
  String get psImgVoiture;

  /// Picture Span image name - bike
  ///
  /// In fr, this message translates to:
  /// **'Vélo'**
  String get psImgVelo;

  /// Picture Span image name - plane
  ///
  /// In fr, this message translates to:
  /// **'Avion'**
  String get psImgAvion;

  /// Picture Span image name - train
  ///
  /// In fr, this message translates to:
  /// **'Train'**
  String get psImgTrain;

  /// Picture Span image name - boat
  ///
  /// In fr, this message translates to:
  /// **'Bateau'**
  String get psImgBateau;

  /// Picture Span image name - bus
  ///
  /// In fr, this message translates to:
  /// **'Bus'**
  String get psImgBus;

  /// Picture Span image name - motorcycle
  ///
  /// In fr, this message translates to:
  /// **'Moto'**
  String get psImgMoto;

  /// Picture Span image name - rocket
  ///
  /// In fr, this message translates to:
  /// **'Fusée'**
  String get psImgFusee;

  /// Vocabulaire — nom du test affiché dans le scaffold
  ///
  /// In fr, this message translates to:
  /// **'Vocabulaire'**
  String get vocabTestName;

  /// Vocabulaire — sur-titre (catégorie d'indice) dans le scaffold
  ///
  /// In fr, this message translates to:
  /// **'COMPRÉHENSION VERBALE · VCI'**
  String get vocabEyebrow;

  /// Vocabulaire — chrono et score affichés dans l'AppBar
  ///
  /// In fr, this message translates to:
  /// **'{seconds} s · {score} pts'**
  String vocabTimerScore(int seconds, int score);

  /// Vocabulaire — titre du feedback pour une réponse à 2 points
  ///
  /// In fr, this message translates to:
  /// **'Excellent !'**
  String get vocabFeedbackExcellent;

  /// Vocabulaire — titre du feedback pour une réponse à 1 point
  ///
  /// In fr, this message translates to:
  /// **'Correct'**
  String get vocabFeedbackCorrect;

  /// Vocabulaire — titre du feedback pour une réponse à 0 point
  ///
  /// In fr, this message translates to:
  /// **'Réponse incomplète'**
  String get vocabFeedbackIncomplete;

  /// Vocabulaire — message de feedback pour 2 points
  ///
  /// In fr, this message translates to:
  /// **'Définition complète et précise ! +2 points'**
  String get vocabFeedbackTwoPoints;

  /// Vocabulaire — message de feedback pour 1 point
  ///
  /// In fr, this message translates to:
  /// **'Définition partielle mais correcte. +1 point'**
  String get vocabFeedbackOnePoint;

  /// Vocabulaire — message de feedback pour 0 point
  ///
  /// In fr, this message translates to:
  /// **'Réponse incorrecte ou trop vague. 0 point'**
  String get vocabFeedbackZeroPoint;

  /// Vocabulaire — rappel du mot évalué dans le feedback
  ///
  /// In fr, this message translates to:
  /// **'Mot : « {word} »'**
  String vocabWordLabel(String word);

  /// Vocabulaire — rappel de la réponse de l'utilisateur dans le feedback
  ///
  /// In fr, this message translates to:
  /// **'Votre réponse : « {answer} »'**
  String vocabYourAnswerLabel(String answer);

  /// Vocabulaire — placeholder quand la réponse de l'utilisateur est vide
  ///
  /// In fr, this message translates to:
  /// **'(vide)'**
  String get vocabEmptyAnswer;

  /// Vocabulaire — en-tête de la liste d'exemples de réponses à 2 points
  ///
  /// In fr, this message translates to:
  /// **'Exemples de réponses à 2 points :'**
  String get vocabTwoPointExamples;

  /// Vocabulaire — en-tête de la liste d'exemples de réponses à 1 point
  ///
  /// In fr, this message translates to:
  /// **'Exemples de réponses à 1 point :'**
  String get vocabOnePointExamples;

  /// Vocabulaire — temps passé sur l'item dans le feedback
  ///
  /// In fr, this message translates to:
  /// **'Temps : {seconds} s'**
  String vocabTimeSeconds(int seconds);

  /// Vocabulaire — score cumulé affiché dans le feedback
  ///
  /// In fr, this message translates to:
  /// **'Score total : {score} points'**
  String vocabTotalScore(int score);

  /// Vocabulaire — message de règle d'arrêt après 3 échecs consécutifs
  ///
  /// In fr, this message translates to:
  /// **'3 scores de 0 consécutifs - Test terminé (WAIS-IV)'**
  String get vocabDiscontinued;

  /// Vocabulaire — bouton du feedback qui mène à l'écran de résultats
  ///
  /// In fr, this message translates to:
  /// **'Voir les résultats'**
  String get vocabViewResults;

  /// Vocabulaire — titre du dialogue de résultats finaux
  ///
  /// In fr, this message translates to:
  /// **'Test de Vocabulaire - Résultats'**
  String get vocabResultsTitle;

  /// Vocabulaire — score brut dans les résultats
  ///
  /// In fr, this message translates to:
  /// **'Score brut : {score}/{max} points'**
  String vocabRawScore(int score, int max);

  /// Vocabulaire — nombre d'items complétés dans les résultats
  ///
  /// In fr, this message translates to:
  /// **'Items complétés : {completed}/{total}'**
  String vocabItemsCompleted(int completed, int total);

  /// Vocabulaire — pourcentage de réussite dans les résultats
  ///
  /// In fr, this message translates to:
  /// **'Pourcentage : {percent}%'**
  String vocabPercentage(int percent);

  /// Vocabulaire — temps total dans les résultats
  ///
  /// In fr, this message translates to:
  /// **'Temps total : {seconds} s'**
  String vocabTotalTime(int seconds);

  /// Vocabulaire — légende sous le niveau de performance dans les résultats
  ///
  /// In fr, this message translates to:
  /// **'Test de connaissance lexicale et compréhension verbale'**
  String get vocabTestCaption;

  /// Vocabulaire — en-tête de la répartition des scores par fréquence
  ///
  /// In fr, this message translates to:
  /// **'Répartition par fréquence :'**
  String get vocabFrequencyBreakdownTitle;

  /// Vocabulaire — ligne de répartition score par niveau de fréquence
  ///
  /// In fr, this message translates to:
  /// **'{name} : {score}/{max} points'**
  String vocabFrequencyBreakdownRow(String name, int score, int max);

  /// Vocabulaire — niveau de performance le plus élevé
  ///
  /// In fr, this message translates to:
  /// **'Performance exceptionnelle (θ > +2.0)'**
  String get vocabPerfExceptional;

  /// Vocabulaire — niveau de performance supérieur
  ///
  /// In fr, this message translates to:
  /// **'Performance supérieure (θ > +1.0)'**
  String get vocabPerfSuperior;

  /// Vocabulaire — niveau de performance moyen
  ///
  /// In fr, this message translates to:
  /// **'Performance moyenne (θ ≈ 0)'**
  String get vocabPerfAverage;

  /// Vocabulaire — niveau de performance inférieur
  ///
  /// In fr, this message translates to:
  /// **'Performance inférieure (θ < 0)'**
  String get vocabPerfBelowAverage;

  /// Vocabulaire — niveau de performance le plus faible
  ///
  /// In fr, this message translates to:
  /// **'Performance faible (θ < -1.0)'**
  String get vocabPerfLow;

  /// Vocabulaire — nom du niveau de fréquence : très fréquent (Top 1000)
  ///
  /// In fr, this message translates to:
  /// **'Très fréquent'**
  String get vocabFreqVeryHigh;

  /// Vocabulaire — nom du niveau de fréquence : fréquent (Top 5000)
  ///
  /// In fr, this message translates to:
  /// **'Fréquent'**
  String get vocabFreqHigh;

  /// Vocabulaire — nom du niveau de fréquence : moyen (Top 10 000)
  ///
  /// In fr, this message translates to:
  /// **'Moyen'**
  String get vocabFreqMedium;

  /// Vocabulaire — nom du niveau de fréquence : rare (Top 20 000)
  ///
  /// In fr, this message translates to:
  /// **'Rare'**
  String get vocabFreqLow;

  /// Vocabulaire — nom du niveau de fréquence : très rare (>20 000)
  ///
  /// In fr, this message translates to:
  /// **'Très rare'**
  String get vocabFreqVeryLow;

  /// Vocabulaire — instruction au-dessus du mot à définir
  ///
  /// In fr, this message translates to:
  /// **'Définissez le mot suivant'**
  String get vocabInstruction;

  /// Vocabulaire — libellé au-dessus du champ de saisie
  ///
  /// In fr, this message translates to:
  /// **'Votre définition :'**
  String get vocabYourDefinitionLabel;

  /// Vocabulaire — texte indicatif dans le champ de définition
  ///
  /// In fr, this message translates to:
  /// **'Écrivez la définition du mot...'**
  String get vocabDefinitionHint;

  /// Vocabulaire — en-tête de l'encart de conseils de scoring
  ///
  /// In fr, this message translates to:
  /// **'Conseils pour obtenir 2 points :'**
  String get vocabTipsTitle;

  /// Vocabulaire — conseil 1 de l'encart
  ///
  /// In fr, this message translates to:
  /// **'• Donnez une définition complète et précise'**
  String get vocabTipComplete;

  /// Vocabulaire — conseil 2 de l'encart
  ///
  /// In fr, this message translates to:
  /// **'• Utilisez des synonymes exacts'**
  String get vocabTipSynonyms;

  /// Vocabulaire — conseil 3 de l'encart
  ///
  /// In fr, this message translates to:
  /// **'• Expliquez le sens avec contexte'**
  String get vocabTipContext;

  /// Phase d'entraînement — libellé d'en-tête générique (partagé entre exercices)
  ///
  /// In fr, this message translates to:
  /// **'ENTRAÎNEMENT'**
  String get demoBadge;

  /// Phase d'entraînement — bandeau expliquant que l'essai n'est pas noté
  ///
  /// In fr, this message translates to:
  /// **'Entraînement — cet essai ne compte pas.'**
  String get demoNotice;

  /// Phase d'entraînement — bouton pour passer au test réel
  ///
  /// In fr, this message translates to:
  /// **'Commencer le test'**
  String get demoStart;

  /// Phase d'entraînement — bouton pour refaire l'essai
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get demoRetry;

  /// Phase d'entraînement — bouton neutre pour poursuivre (exercices sans bonne/mauvaise réponse automatique)
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get demoContinue;

  /// Phase d'entraînement — retour positif après un essai correct
  ///
  /// In fr, this message translates to:
  /// **'Bonne réponse !'**
  String get demoWellDone;

  /// Phase d'entraînement — retour après un essai incorrect
  ///
  /// In fr, this message translates to:
  /// **'Pas tout à fait — réessayez'**
  String get demoTryAgain;

  /// No description provided for @ugTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ton résultat est prêt'**
  String get ugTitle;

  /// No description provided for @ugEyebrow.
  ///
  /// In fr, this message translates to:
  /// **'Dernières étapes'**
  String get ugEyebrow;

  /// No description provided for @ugFreeNotice.
  ///
  /// In fr, this message translates to:
  /// **'Le test est 100 % gratuit. Pour recevoir ton résultat, il te reste quelques étapes simples : elles se valident automatiquement.'**
  String get ugFreeNotice;

  /// No description provided for @ugErrorBody.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de récupérer l\'état de ton déblocage. Vérifie ta connexion puis réessaie.'**
  String get ugErrorBody;

  /// No description provided for @ugRetry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get ugRetry;

  /// No description provided for @ugRefresh.
  ///
  /// In fr, this message translates to:
  /// **'Actualiser'**
  String get ugRefresh;

  /// No description provided for @ugStep1Title.
  ///
  /// In fr, this message translates to:
  /// **'Invite 3 amis'**
  String get ugStep1Title;

  /// No description provided for @ugStep1Body.
  ///
  /// In fr, this message translates to:
  /// **'Partage ton lien personnel avec 3 amis. Cette étape avance quand ils TERMINENT leur test — pas seulement quand ils s\'inscrivent. Pense à les relancer.'**
  String get ugStep1Body;

  /// No description provided for @ugCopyLink.
  ///
  /// In fr, this message translates to:
  /// **'Copier mon lien d\'invitation'**
  String get ugCopyLink;

  /// No description provided for @ugCopied.
  ///
  /// In fr, this message translates to:
  /// **'Lien copié !'**
  String get ugCopied;

  /// No description provided for @ugInviteCounter.
  ///
  /// In fr, this message translates to:
  /// **'{joined}/{required} amis ont terminé leur test'**
  String ugInviteCounter(int joined, int required);

  /// No description provided for @ugStep2Title.
  ///
  /// In fr, this message translates to:
  /// **'Tes amis passent leur test'**
  String get ugStep2Title;

  /// No description provided for @ugStep2Body.
  ///
  /// In fr, this message translates to:
  /// **'Tes amis doivent maintenant terminer leur test de QI. On attend leurs résultats — n\'hésite pas à les relancer !'**
  String get ugStep2Body;

  /// No description provided for @ugFriendDone.
  ///
  /// In fr, this message translates to:
  /// **'Ami {n} : test terminé'**
  String ugFriendDone(int n);

  /// No description provided for @ugFriendPending.
  ///
  /// In fr, this message translates to:
  /// **'Ami {n} : test en cours'**
  String ugFriendPending(int n);

  /// No description provided for @ugWaitTitle.
  ///
  /// In fr, this message translates to:
  /// **'Tes résultats arrivent'**
  String get ugWaitTitle;

  /// No description provided for @ugWaitBody.
  ///
  /// In fr, this message translates to:
  /// **'{days, plural, =0{Ton résultat est en préparation. Il sera publié automatiquement — tu n\'as plus rien à faire.} one{Ton résultat est en préparation. Il sera publié dans {days} jour, automatiquement — tu n\'as plus rien à faire.} other{Ton résultat est en préparation. Il sera publié dans {days} jours, automatiquement — tu n\'as plus rien à faire.}}'**
  String ugWaitBody(int days);

  /// No description provided for @ugWaitCountdownDays.
  ///
  /// In fr, this message translates to:
  /// **'{days, plural, one{Encore {days} jour} other{Encore {days} jours}}'**
  String ugWaitCountdownDays(int days);

  /// No description provided for @ugWaitCountdownHours.
  ///
  /// In fr, this message translates to:
  /// **'{hours, plural, one{Encore {hours} heure} other{Encore {hours} heures}}'**
  String ugWaitCountdownHours(int hours);

  /// No description provided for @ugWaitCountdownMinutes.
  ///
  /// In fr, this message translates to:
  /// **'{minutes, plural, one{Encore {minutes} minute} other{Encore {minutes} minutes}}'**
  String ugWaitCountdownMinutes(int minutes);

  /// No description provided for @ugWaitCountdownDone.
  ///
  /// In fr, this message translates to:
  /// **'Le délai est écoulé.'**
  String get ugWaitCountdownDone;

  /// No description provided for @ugWaitConfirming.
  ///
  /// In fr, this message translates to:
  /// **'Ton résultat se débloque dès la confirmation du serveur — cet écran s\'actualise tout seul.'**
  String get ugWaitConfirming;

  /// No description provided for @ugRefreshFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'actualiser. Vérifie ta connexion — les chiffres affichés datent de ta dernière connexion.'**
  String get ugRefreshFailed;

  /// No description provided for @ugResultsHubNotice.
  ///
  /// In fr, this message translates to:
  /// **'Tout se trouve dans « Mes résultats » : tes missions, ton lien d\'invitation et ton résultat (flouté tant que toutes les missions ne sont pas validées). Tu peux quitter cette page et revenir quand tu veux.'**
  String get ugResultsHubNotice;

  /// No description provided for @histLockedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Missions à valider'**
  String get histLockedTitle;

  /// No description provided for @histLockedBody.
  ///
  /// In fr, this message translates to:
  /// **'Ton résultat est enregistré, mais il reste flouté tant que toutes les missions ne sont pas validées.'**
  String get histLockedBody;

  /// No description provided for @histLockedBodyNoResult.
  ///
  /// In fr, this message translates to:
  /// **'Tes missions et ton lien d\'invitation sont ici. Termine ton évaluation pour débloquer ton résultat.'**
  String get histLockedBodyNoResult;

  /// No description provided for @histLockedCta.
  ///
  /// In fr, this message translates to:
  /// **'Voir mes missions'**
  String get histLockedCta;

  /// No description provided for @inviteLandingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Invitation'**
  String get inviteLandingTitle;

  /// No description provided for @inviteLandingBody.
  ///
  /// In fr, this message translates to:
  /// **'Un ami t\'invite à passer le test de QI gratuit Mentality. En terminant ton test, tu obtiens ton propre résultat et tu aides ton ami à débloquer le sien.'**
  String get inviteLandingBody;

  /// No description provided for @inviteLandingCta.
  ///
  /// In fr, this message translates to:
  /// **'Commencer le test gratuit'**
  String get inviteLandingCta;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'es', 'fr', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'en':
      {
        switch (locale.countryCode) {
          case 'GB':
            return AppLocalizationsEnGb();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
