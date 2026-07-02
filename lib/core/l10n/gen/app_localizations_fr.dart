// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Mental E.T.';

  @override
  String get languageSwitcherTooltip => 'Changer de langue';

  @override
  String get commonValidate => 'Valider';

  @override
  String get commonNext => 'Suivant';

  @override
  String get commonBack => 'Retour';

  @override
  String get commonContinue => 'Continuer';

  @override
  String get commonStart => 'Commencer';

  @override
  String get commonSkip => 'Passer';

  @override
  String get commonCancel => 'Annuler';

  @override
  String get commonClose => 'Fermer';

  @override
  String get commonRetry => 'Réessayer';

  @override
  String get commonLoading => 'Chargement...';

  @override
  String get commonError => 'Une erreur est survenue';

  @override
  String get commonYes => 'Oui';

  @override
  String get commonNo => 'Non';

  @override
  String get commonOk => 'OK';

  @override
  String get commonFinish => 'Terminer';

  @override
  String commonSeconds(int count) {
    return '$count s';
  }

  @override
  String get oralConsentRequiredCheckbox =>
      'J\'autorise l\'enregistrement de ma voix et son analyse, le temps de réaliser ce test. (obligatoire)';

  @override
  String get oralConsentCommercialCheckbox =>
      'J\'autorise aussi la réutilisation de mes enregistrements, sous forme anonymisée, à des fins de recherche et commerciales — y compris leur cession à des tiers. (facultatif)';

  @override
  String get oralConsentRequiredHint =>
      'Cochez la première case pour pouvoir commencer le test.';

  @override
  String get oralConsentPrivacyLink => 'Lire la politique de confidentialité';

  @override
  String get matDiscontinue3 => '3 échecs consécutifs - Test terminé (WAIS-IV)';

  @override
  String get assessIntroTitle => 'Nouvelle évaluation';

  @override
  String get assessIntroEyebrow => 'BILAN COGNITIF';

  @override
  String get assessIntroHero1 => 'Cinq indices,';

  @override
  String get assessIntroHero2 => 'une mesure.';

  @override
  String get assessIntroDescription =>
      'Cette évaluation mesure vos capacités cognitives à travers six domaines issus du WAIS-IV. Un score global (FSIQ) en est la synthèse.';

  @override
  String get assessDomainsHeader => 'DOMAINES MESURÉS';

  @override
  String get assessDomainVci => 'Compréhension Verbale';

  @override
  String get assessDomainVsi => 'Raisonnement Visuo-Spatial';

  @override
  String get assessDomainFri => 'Raisonnement Fluide';

  @override
  String get assessDomainWmi => 'Mémoire de Travail';

  @override
  String get assessDomainPsi => 'Vitesse de Traitement';

  @override
  String get assessDomainLo => 'Langage Oral';

  @override
  String get assessBeforeStartHeader => 'AVANT DE COMMENCER';

  @override
  String get assessBeforeStartBody =>
      'Durée estimée 60 à 90 minutes. Calme et concentration requis.';

  @override
  String get assessLaunchFullAssessment => 'Lancer le bilan complet';

  @override
  String get assessOrIndividualSubtest => 'OU SUBTEST INDIVIDUEL';

  @override
  String get assessSubtestCubes => 'Cubes (Block Design)';

  @override
  String get assessSubtestMatrices => 'Matrices Progressives';

  @override
  String get assessSubtestFigureWeights => 'Balances Quantitatives';

  @override
  String get assessSubtestVisualPuzzles => 'Puzzles Visuels';

  @override
  String get assessSubtestSimilarities => 'Similitudes';

  @override
  String get assessSubtestVocabulary => 'Vocabulaire';

  @override
  String get assessSubtestInformation => 'Information';

  @override
  String get assessSubtestDigitSpan => 'Mémoire des Chiffres';

  @override
  String get assessSubtestArithmetic => 'Arithmétique';

  @override
  String get assessSubtestPictureSpan => 'Mémoire des Images';

  @override
  String get assessSubtestCoding => 'Code';

  @override
  String get assessSubtestSymbolSearch => 'Recherche de Symboles';

  @override
  String get assessSubtestOralComprehension => 'Compréhension Orale';

  @override
  String get authLoginTitle => 'Connexion';

  @override
  String get authCreateAccount => 'Créer un compte';

  @override
  String get authSignIn => 'Se connecter';

  @override
  String get authHeaderSubtitleRegister =>
      'Créez un compte pour sauvegarder vos résultats';

  @override
  String get authHeaderSubtitleLogin =>
      'Connectez-vous pour accéder à votre historique';

  @override
  String get authEmailLabel => 'Adresse e-mail';

  @override
  String get authPasswordLabel => 'Mot de passe';

  @override
  String get authFieldRequired => 'Champ obligatoire';

  @override
  String get authEmailInvalid => 'Adresse e-mail invalide';

  @override
  String get authPasswordMinLength => 'Minimum 8 caractères';

  @override
  String get authOrDivider => 'ou';

  @override
  String get authContinueWithGoogle => 'Continuer avec Google';

  @override
  String get authToggleToLogin => 'Déjà un compte ? Se connecter';

  @override
  String get authToggleToRegister => 'Pas encore de compte ? S\'inscrire';

  @override
  String get authFirebaseNotConfiguredFull =>
      'Firebase n\'est pas encore configuré. Suivez les instructions dans firebase_config.dart.';

  @override
  String get authFirebaseNotConfigured =>
      'Firebase n\'est pas encore configuré.';

  @override
  String get histTitle => 'Mes résultats';

  @override
  String get histEyebrow => 'HISTORIQUE';

  @override
  String get histDeleteResultTitle => 'Supprimer ce résultat ?';

  @override
  String get histDeleteResultBody => 'Cette action est irréversible.';

  @override
  String get histDelete => 'Supprimer';

  @override
  String histAgeYears(int age) {
    return '$age ans';
  }

  @override
  String get histScoreFsiq => 'QI Total (FSIQ)';

  @override
  String get histScoreVci => 'VCI — Verbal';

  @override
  String get histScoreVsi => 'VSI — Visuo-Spatial';

  @override
  String get histScoreFri => 'FRI — Raisonnement';

  @override
  String get histScoreWmi => 'WMI — Mémoire';

  @override
  String get histScorePsi => 'PSI — Vitesse';

  @override
  String get histEmptyEyebrow => 'AUCUN RÉSULTAT';

  @override
  String get histEmptyHero1 => 'Votre historique';

  @override
  String get histEmptyHero2 => 'vous attend.';

  @override
  String get histEmptyDescription =>
      'Complétez votre première évaluation WAIS-IV pour voir vos résultats apparaître ici.';

  @override
  String get histStartAssessment => 'Commencer une évaluation';

  @override
  String get ctIntroTitle => 'Test complet';

  @override
  String get ctIntroHero1 => 'Douze subtests,';

  @override
  String get ctIntroHero2 => 'quatre indices.';

  @override
  String get ctIntroDescription =>
      'Évaluation cognitive complète standardisée. Les sous-tests s\'enchaînent automatiquement.';

  @override
  String get ctIntroDurationEyebrow => 'DURÉE';

  @override
  String get ctIntroDurationTitle => '60 à 90 minutes';

  @override
  String get ctIntroDurationBody => 'Prévoyez une plage de temps continue.';

  @override
  String get ctIntroContentEyebrow => 'CONTENU';

  @override
  String get ctIntroContentTitle => '12 subtests inclus';

  @override
  String get ctIntroContentBody =>
      'Cubes · Similitudes · Mémoire · Matrices · Vocabulaire · Arithmétique · Symboles · Puzzles · Information · Code · Images · Balances.';

  @override
  String get ctIntroImportantEyebrow => 'IMPORTANT';

  @override
  String get ctIntroImportantTitle => 'Enchaînement automatique';

  @override
  String get ctIntroImportantBody =>
      'Les tests se lanceront l\'un après l\'autre. Assurez-vous d\'avoir suffisamment de temps.';

  @override
  String get ctPatientAgeHeader => 'ÂGE DU PATIENT';

  @override
  String get ctPatientAgeHint => 'Requis pour les normes (16 à 90 ans)';

  @override
  String get ctAgeSuffix => 'ANS';

  @override
  String get ctAgeRangeError => 'Âge entre 16 et 90 ans';

  @override
  String get ctLaunchFullTest => 'Lancer le test complet';

  @override
  String get ctRunningTitle => 'Test en cours';

  @override
  String get ctGlobalProgress => 'PROGRESSION GLOBALE';

  @override
  String get ctNextSubtest => 'PROCHAIN SUBTEST';

  @override
  String get ctLaunching => 'Lancement…';

  @override
  String get ctComputingResultsTitle => 'Calcul des résultats';

  @override
  String get ctComputingResultsEyebrow => 'BILAN';

  @override
  String get ctProcessing => 'TRAITEMENT';

  @override
  String ctTestNotFound(String testName) {
    return 'Test non trouvé : $testName';
  }

  @override
  String get ctTestCubes => 'Cubes';

  @override
  String get ctTestSimilarities => 'Similitudes';

  @override
  String get ctTestDigitSpan => 'Mémoire des Chiffres';

  @override
  String get ctTestMatrices => 'Matrices';

  @override
  String get ctTestVocabulary => 'Vocabulaire';

  @override
  String get ctTestArithmetic => 'Arithmétique';

  @override
  String get ctTestSymbolSearch => 'Recherche de Symboles';

  @override
  String get ctTestVisualPuzzles => 'Puzzles Visuels';

  @override
  String get ctTestInformation => 'Information';

  @override
  String get ctTestCoding => 'Code';

  @override
  String get ctTestPictureSpan => 'Mémoire des Images';

  @override
  String get ctTestFigureWeights => 'Balances';

  @override
  String get ctResultsTitle => 'Résultats';

  @override
  String get ctResultsEyebrow => 'BILAN WAIS-IV';

  @override
  String get ctResultsHero1 => 'Bilan';

  @override
  String get ctResultsHero2 => 'terminé.';

  @override
  String get ctResultsSummary =>
      'Synthèse de vos performances cognitives sur les douze subtests WAIS-IV.';

  @override
  String ctAgeYears(int age) {
    return '$age ans';
  }

  @override
  String get ctMetaDate => 'DATE';

  @override
  String get ctMetaDuration => 'DURÉE';

  @override
  String get ctMetaSubtests => 'SUBTESTS';

  @override
  String get ctMetaAge => 'ÂGE';

  @override
  String get ctFsiqCardLabel => 'QI TOTAL · FSIQ';

  @override
  String ctConfidenceInterval95(int lower, int upper) {
    return 'IC 95% · $lower – $upper';
  }

  @override
  String ctPercentileLabel(int rank) {
    return 'Percentile · ${rank}e';
  }

  @override
  String get ctIndexProfileHeader => 'PROFIL DES INDICES';

  @override
  String get ctIndexVci => 'Compréhension Verbale';

  @override
  String get ctIndexVsi => 'Visuo-Spatial';

  @override
  String get ctIndexFri => 'Raisonnement Fluide';

  @override
  String get ctIndexWmi => 'Mémoire de Travail';

  @override
  String get ctIndexPsi => 'Vitesse de Traitement';

  @override
  String ctIndexCiPercentile(int lower, int upper, int rank) {
    return 'IC $lower–$upper · ${rank}e %ile';
  }

  @override
  String ctIndexPercentile(int rank) {
    return '${rank}e %ile';
  }

  @override
  String get ctStandardizedScoresHeader => 'NOTES STANDARDISÉES';

  @override
  String get ctGroupVciVerbal => 'VCI · Verbal';

  @override
  String get ctGroupVsiVisuoSpatial => 'VSI · Visuo-Spatial';

  @override
  String get ctGroupFriReasoning => 'FRI · Raisonnement';

  @override
  String get ctGroupWmiMemory => 'WMI · Mémoire';

  @override
  String get ctGroupPsiSpeed => 'PSI · Vitesse';

  @override
  String ctRawScore(int raw) {
    return 'brut $raw';
  }

  @override
  String get ctCognitiveProfileHeader => 'PROFIL COGNITIF';

  @override
  String get ctProfileHomogeneous =>
      'Profil homogène — les indices sont cohérents entre eux.';

  @override
  String get ctProfileHeterogeneous =>
      'Profil hétérogène — disparités notables entre indices.';

  @override
  String ctMaxDiscrepancy(int points) {
    return 'Écart max · $points pts';
  }

  @override
  String get ctRelativeStrengths => 'Forces relatives';

  @override
  String get ctVigilancePoints => 'Points de vigilance';

  @override
  String get ctIndicativeDisclaimer =>
      'Résultats indicatifs. Pour une évaluation clinique officielle, consultez un neuropsychologue ou un psychologue qualifié.';

  @override
  String get ctRawScoresHeader => 'SCORES BRUTS';

  @override
  String get ctMissingAgeHeader => 'ÂGE MANQUANT';

  @override
  String get ctMissingAgeBody =>
      'Sans l\'âge du patient, seuls les scores bruts sont affichés. Relancez le test en renseignant l\'âge pour obtenir le QI standardisé, les percentiles et les intervalles de confiance.';

  @override
  String get ctExportPdf => 'Exporter en PDF';

  @override
  String ctPdfError(String error) {
    return 'Erreur PDF : $error';
  }

  @override
  String get ctBackToHome => 'Retour à l\'accueil';

  @override
  String get ctSubtestExitTitle => 'Sous-test interrompu';

  @override
  String get ctSubtestExitBody =>
      'Vous avez quitté ce sous-test avant de le terminer. Voulez-vous le reprendre ou arrêter l\'évaluation ?';

  @override
  String get ctSubtestExitResume => 'Reprendre le sous-test';

  @override
  String get ctPdfSubtitle => 'Rapport d\'évaluation cognitive WAIS-IV';

  @override
  String get ctPdfNotProvided => 'Non renseigné';

  @override
  String ctPdfDurationMinSec(int min, int sec) {
    return '$min min $sec sec';
  }

  @override
  String get ctPdfAge => 'Âge';

  @override
  String get ctPdfDuration => 'Durée';

  @override
  String get ctPdfDate => 'Date';

  @override
  String get ctPdfFsiqLabel => 'SCORE QI GLOBAL (FSIQ)';

  @override
  String get ctPdfConfidenceInterval95 => 'Intervalle de confiance 95%';

  @override
  String get ctPdfPercentile => 'Percentile';

  @override
  String ctPercentileValue(int rank) {
    return '${rank}e';
  }

  @override
  String get ctPdfIndexProfileHeader => 'PROFIL DES INDICES COGNITIFS';

  @override
  String get ctPdfIndexVci => 'VCI — Compréhension Verbale';

  @override
  String get ctPdfIndexVsi => 'VSI — Visuo-Spatial';

  @override
  String get ctPdfIndexFri => 'FRI — Raisonnement Fluide';

  @override
  String get ctPdfIndexWmi => 'WMI — Mémoire de Travail';

  @override
  String get ctPdfIndexPsi => 'PSI — Vitesse de Traitement';

  @override
  String get ctPdfColIndex => 'Indice';

  @override
  String get ctPdfColScore => 'Score';

  @override
  String get ctPdfColClassification => 'Classification';

  @override
  String get ctPdfRawScoresHeader => 'SCORES BRUTS DES SUBTESTS';

  @override
  String get ctPdfColSubtest => 'Subtest';

  @override
  String get ctPdfColRawScore => 'Score brut';

  @override
  String get ctPdfDisclaimer =>
      'AVERTISSEMENT : Ce rapport est généré par une application d\'aide à l\'évaluation et ne constitue pas un diagnostic clinique officiel. Il doit être interprété par un professionnel de santé qualifié. Ne pas utiliser à des fins médicales ou légales sans évaluation professionnelle complémentaire.';

  @override
  String get chatEyebrow => 'ASSISTANT IA';

  @override
  String get chatNewConversation => 'Nouvelle conversation';

  @override
  String get chatAssistantLabel => 'MENTAL E.T.';

  @override
  String get chatUserLabel => 'VOUS';

  @override
  String get chatHeroTitle1 => 'Posez';

  @override
  String get chatHeroTitle2 => 'vos questions.';

  @override
  String get chatEmptyIntro =>
      'L\'IA Mental E.T. vous aide à mieux comprendre votre profil cognitif. Discussions confidentielles, accompagnement non-directif.';

  @override
  String get chatThinking => 'Réflexion…';

  @override
  String get chatInputHint => 'Écrire un message…';

  @override
  String get chatTimeJustNow => 'à l\'instant';

  @override
  String chatTimeMinutes(int count) {
    return '$count min';
  }

  @override
  String chatTimeHours(int count) {
    return '${count}h';
  }

  @override
  String get chatErrorMessage =>
      'Désolé, une erreur s\'est produite. Veuillez réessayer.';

  @override
  String get chatErrorEmptyResponse => 'Réponse vide du worker';

  @override
  String get chatErrorAccessDenied =>
      'Accès refusé par le worker (origine non autorisée).';

  @override
  String get chatErrorRateLimit =>
      'Limite de requêtes atteinte. Réessayez dans quelques instants.';

  @override
  String chatErrorServer(int code) {
    return 'Erreur serveur ($code)';
  }

  @override
  String chatErrorHttp(int code, String body) {
    return 'Erreur $code : $body';
  }

  @override
  String get coreSplashTitleLine1 => 'Évaluation';

  @override
  String get coreSplashTitleLine2 => 'cognitive';

  @override
  String get commonNotAvailable => 'N/D';

  @override
  String get pdfFilenameBase => 'mentality_resultats';

  @override
  String coreRouteNotFound(String path) {
    return 'Page introuvable : $path';
  }

  @override
  String get homeHeroTitle => 'Découvrez';

  @override
  String get homeHeroTitleItalic => 'votre profil cognitif.';

  @override
  String get homeHeroBody =>
      'Une évaluation scientifique adaptative, inspirée des échelles Wechsler. 12 sous-tests, 5 indices, un score global.';

  @override
  String get homeActionStartTitle => 'Commencer une évaluation';

  @override
  String get homeActionStartSubtitle => 'Durée : 60 – 90 minutes';

  @override
  String get homeActionResultsTitle => 'Mes résultats';

  @override
  String get homeActionResultsSubtitle => 'Historique des évaluations';

  @override
  String get homeActionChatTitle => 'Parler avec Mental E.T.';

  @override
  String get homeActionChatSubtitle => 'Assistant IA, questions psychologiques';

  @override
  String get homeComingSoon => 'BIENTÔT DISPONIBLE';

  @override
  String get homeAboutEyebrow => 'À PROPOS';

  @override
  String get homeAboutSubtestsTitle => '12 sous-tests';

  @override
  String get homeAboutSubtestsBody =>
      'Évaluation complète des cinq indices cognitifs WAIS-IV.';

  @override
  String get homeAboutAdaptiveTitle => 'IA adaptative';

  @override
  String get homeAboutAdaptiveBody =>
      'Difficulté ajustée en temps réel via inférence IRT.';

  @override
  String get homeAboutValidationTitle => 'Validation scientifique';

  @override
  String get homeAboutValidationBody =>
      'Items inspirés des échelles Wechsler (WPPSI / WISC / WAIS).';

  @override
  String get homeResumeEyebrow => 'TEST EN COURS';

  @override
  String get homeResumeTitle => 'Reprendre votre évaluation';

  @override
  String get homeResumeButton => 'Reprendre';

  @override
  String get homeLogoutTitle => 'Se déconnecter ?';

  @override
  String get homeLogoutBody =>
      'Ton token sera retiré de cet appareil. Assure-toi de l\'avoir sauvegardé : sans lui, tu ne pourras pas te reconnecter à tes données.';

  @override
  String get homeLogoutConfirm => 'Se déconnecter';

  @override
  String get infoTestName => 'Information';

  @override
  String get infoEyebrow => 'COMPRÉHENSION VERBALE · VCI';

  @override
  String infoTrailingStatus(int seconds, int score, int attempted) {
    return '${seconds}s · $score/$attempted';
  }

  @override
  String get infoCorrect => 'Correct !';

  @override
  String get infoIncorrect => 'Incorrect';

  @override
  String get infoFeedbackRight => 'Bonne réponse ! +1 point';

  @override
  String get infoFeedbackWrong => 'Mauvaise réponse. 0 point';

  @override
  String infoQuestionLabel(String question) {
    return 'Question : $question';
  }

  @override
  String infoCorrectAnswerLabel(String answer) {
    return 'Bonne réponse : $answer';
  }

  @override
  String infoTimeLabel(int seconds) {
    return 'Temps : ${seconds}s';
  }

  @override
  String infoScoreLabel(int score, int attempted) {
    return 'Score : $score/$attempted';
  }

  @override
  String infoDomainLabel(String domain) {
    return 'Domaine : $domain';
  }

  @override
  String get infoDiscontinue3 =>
      '3 échecs consécutifs - Test terminé (WAIS-IV)';

  @override
  String get infoSeeResults => 'Voir les résultats';

  @override
  String get infoResultsTitle => 'Test d\'Information - Résultats';

  @override
  String infoRawScore(int score, int max) {
    return 'Score brut : $score/$max points';
  }

  @override
  String infoItemsCompleted(int completed, int total) {
    return 'Items complétés : $completed/$total';
  }

  @override
  String infoPercentage(int percent) {
    return 'Pourcentage : $percent%';
  }

  @override
  String infoTotalTime(int seconds) {
    return 'Temps total : ${seconds}s';
  }

  @override
  String get infoTestSubtitle => 'Test de connaissances générales acquises';

  @override
  String get infoDomainBreakdownTitle => 'Répartition par domaine :';

  @override
  String infoDomainBreakdownRow(String domain, int correct, int total) {
    return '$domain: $correct/$total';
  }

  @override
  String get infoPerfExceptional => 'Performance exceptionnelle (θ > +2.0)';

  @override
  String get infoPerfSuperior => 'Performance supérieure (θ > +1.0)';

  @override
  String get infoPerfAverage => 'Performance moyenne (θ ≈ 0)';

  @override
  String get infoPerfBelow => 'Performance inférieure (θ < 0)';

  @override
  String get infoPerfLow => 'Performance faible (θ < -1.0)';

  @override
  String get infoDomainScience => 'Sciences naturelles';

  @override
  String get infoDomainHistoryGeography => 'Histoire/Géographie';

  @override
  String get infoDomainGeneralCulture => 'Culture générale';

  @override
  String get infoDomainMathLogic => 'Mathématiques/Logique';

  @override
  String get infoDomainArtsLiterature => 'Arts/Littérature';

  @override
  String get infoDifficultyEasy => 'Facile';

  @override
  String get infoDifficultyMedium => 'Moyen';

  @override
  String get infoDifficultyHard => 'Difficile';

  @override
  String get arithTestName => 'Arithmétique';

  @override
  String get arithEyebrow => 'MÉMOIRE DE TRAVAIL · WMI';

  @override
  String get arithStartTest => 'Commencer le test';

  @override
  String get arithIntroTitle => 'Test d\'Arithmétique';

  @override
  String get arithIntroDescription =>
      'Ce test mesure votre mémoire de travail et votre raisonnement numérique.';

  @override
  String get arithInfoMentalTitle => 'Calcul mental uniquement';

  @override
  String get arithInfoMentalSubtitle =>
      'Résolvez les problèmes sans papier ni calculatrice';

  @override
  String get arithInfoTimeTitle => 'Temps limité';

  @override
  String get arithInfoTimeSubtitle =>
      'Chaque problème a une limite de temps (15-60 secondes)';

  @override
  String get arithInfoBonusTitle => 'Bonus de rapidité';

  @override
  String get arithInfoBonusSubtitle =>
      'Réponses rapides sur certains items = points bonus';

  @override
  String get arithInfoRepeatTitle => 'Répétition possible';

  @override
  String get arithInfoRepeatSubtitle =>
      'Vous pouvez demander de répéter UNE fois (chrono continue)';

  @override
  String get arithIntroDiscontinueNote =>
      '22 problèmes au total. Le test s\'arrête après 3 échecs consécutifs.';

  @override
  String arithProblemCounter(int current, int total) {
    return 'Problème $current/$total';
  }

  @override
  String get arithRepeatTitle => 'Répétition du problème';

  @override
  String get arithUnderstood => 'Compris';

  @override
  String get arithTimeUp => 'Temps écoulé !';

  @override
  String arithCorrectAnswerLabel(int answer) {
    return 'Réponse correcte : $answer';
  }

  @override
  String get arithCorrect => 'Correct !';

  @override
  String get arithIncorrect => 'Incorrect';

  @override
  String arithTimeSpent(int seconds) {
    return 'Temps : $seconds secondes';
  }

  @override
  String get arithSpeedBonus => '🎉 Bonus de rapidité ! (+1 point)';

  @override
  String get arithTestEnded => 'Test terminé !';

  @override
  String arithItemsCompleted(int completed, int total) {
    return 'Items complétés : $completed/$total';
  }

  @override
  String arithBaseScore(int score) {
    return 'Score de base : $score points';
  }

  @override
  String arithBonusScore(int bonus) {
    return 'Bonus de rapidité : $bonus points';
  }

  @override
  String arithTotalScore(int total) {
    return 'Score Total : $total points';
  }

  @override
  String get arithRepeat => 'Répéter';

  @override
  String get arithAnswerHint => 'Votre réponse';

  @override
  String get arithDifficultyEasy => 'Facile';

  @override
  String get arithDifficultyMedium => 'Moyen';

  @override
  String get arithDifficultyHard => 'Difficile';

  @override
  String get arithDifficultyVeryHard => 'Très difficile';

  @override
  String get oralMicAccessTitle => 'Accès au microphone';

  @override
  String get oralReadingPermissionBody1 =>
      'Cette activité enregistre votre voix pendant que vous lisez le texte à voix haute.';

  @override
  String get oralReadingPermissionBody2 =>
      'Vos enregistrements seront anonymisés et pourront contribuer à l\'amélioration de la reconnaissance vocale en français.';

  @override
  String get oralBrowserWillAskMic =>
      'Votre navigateur vous demandera ensuite d\'autoriser le microphone.';

  @override
  String get oralCancel => 'Annuler';

  @override
  String get oralAllowMicrophone => 'Autoriser le microphone';

  @override
  String get oralMicDeniedOrUnavailable => 'Microphone refusé ou indisponible.';

  @override
  String get oralCannotStartRecording =>
      'Impossible de démarrer l\'enregistrement sur ce navigateur.';

  @override
  String oralCanSkipToNextStep(String message) {
    return '$message Vous pouvez passer à l\'étape suivante.';
  }

  @override
  String get oralSkip => 'Passer';

  @override
  String get oralRecordingInProgress => 'Enregistrement en cours';

  @override
  String oralKeepGoingSeconds(int seconds) {
    return 'Continuez encore ${seconds}s...';
  }

  @override
  String get oralSaving => 'Sauvegarde...';

  @override
  String get oralReadingInstructions =>
      'Lisez le texte suivant à voix haute, clairement et à votre rythme naturel. Appuyez sur \"Démarrer\" quand vous êtes prêt.';

  @override
  String get oralStartReading => 'Démarrer la lecture';

  @override
  String get oralFinish => 'Terminer';

  @override
  String get oralSkipThisStep => 'Passer cette étape';

  @override
  String get oralSummaryPermissionBody1 =>
      'Vous allez maintenant enregistrer votre résumé oral du texte.';

  @override
  String get oralSummaryPermissionBody2 =>
      'Parlez naturellement, comme si vous expliquiez le texte à un ami. Prenez entre 30 et 60 secondes.';

  @override
  String get oralStartSummary => 'Démarrer le résumé';

  @override
  String get oralSummaryInstructionLead => 'Vous venez de lire ce texte. ';

  @override
  String get oralSummaryInstructionBody =>
      'Résumez ce que vous avez compris avec vos propres mots. Prenez entre 30 et 60 secondes. Parlez naturellement, comme si vous l\'expliquiez à un ami.';

  @override
  String get oralReferenceText => 'Texte de référence';

  @override
  String get oralFinishSummary => 'Terminer le résumé';

  @override
  String get oralFlowTitle => 'Collecte audio';

  @override
  String get oralConsentTitle => 'Test de Compréhension Orale';

  @override
  String get oralConsentRecordTitle => 'Ce que nous enregistrons';

  @override
  String get oralConsentRecordBody =>
      'Votre voix pendant la lecture de 5 courts textes (environ 1 min chacun) et votre résumé oral (environ 40 secondes par texte).';

  @override
  String get oralConsentAnonTitle => 'Confidentialité';

  @override
  String get oralConsentAnonBody =>
      'Vos enregistrements sont identifiés par un code de session aléatoire, et non par votre nom. Ils restent toutefois rattachables à votre compte : ce sont des données personnelles protégées, chiffrées et stockées en Europe.';

  @override
  String get oralConsentUsageTitle => 'Utilisation';

  @override
  String get oralConsentUsageBody =>
      'Ces enregistrements pourront contribuer à l\'amélioration de la reconnaissance vocale du français, notamment pour des modèles comme Whisper ou Speechmatics.';

  @override
  String get oralAcceptAndStart => 'J\'accepte et je commence';

  @override
  String get oralDeclineAndGoBack => 'Refuser et revenir en arrière';

  @override
  String get oralWithdrawConsentNote =>
      'Vous pouvez retirer votre consentement à tout moment depuis les paramètres de l\'application.';

  @override
  String oralTextProgress(int current) {
    return 'Texte $current sur 5';
  }

  @override
  String get oralStepReading => 'Lecture';

  @override
  String get oralStepSummary => 'Résumé';

  @override
  String get oralPauseWellDone => 'Bien !';

  @override
  String get oralPauseNowSummarize => 'Maintenant, résumez oralement ce texte.';

  @override
  String get oralPauseStartingIn => 'Début dans...';

  @override
  String get oralCompletedThanks => 'Merci !';

  @override
  String get oralCompletedBody =>
      'Vous avez complété les 5 textes.\nVos enregistrements contribueront à l\'amélioration\nde la reconnaissance vocale en français.';

  @override
  String get oralBackToHome => 'Retour à l\'accueil';

  @override
  String get oralExitDialogTitle => 'Quitter ?';

  @override
  String get oralExitDialogBody =>
      'Un enregistrement est en cours. Si vous quittez maintenant, il ne sera pas sauvegardé.';

  @override
  String get oralContinue => 'Continuer';

  @override
  String get oralQuit => 'Quitter';

  @override
  String regStepEyebrow(int step) {
    return 'ÉTAPE $step / 4';
  }

  @override
  String get regStepEyebrowSuccess => 'ÉTAPE 4 / 4 · SUCCÈS';

  @override
  String get regEmailTitle => 'Créer mon token';

  @override
  String get regEmailHeading => 'Votre email';

  @override
  String get regEmailIntro =>
      'Nous vous envoyons un code de vérification à 6 chiffres. Votre email n\'est pas lié à votre token et reste privé.';

  @override
  String get regEmailFieldLabel => 'Adresse email';

  @override
  String get regEmailInvalid => 'Email invalide';

  @override
  String get regSendingCode => 'Envoi du code…';

  @override
  String get regReceiveCode => 'Recevoir le code';

  @override
  String get regEmailPrivacyNote =>
      'Aucun nom, prénom ou adresse précise ne sera stocké. Seuls votre sexe, tranche d\'âge et code postal sont encodés (chiffrés) dans votre token anonyme.';

  @override
  String get regEmailOtpTitle => 'Vérifier mon email';

  @override
  String get regCodeSentTo => 'Code envoyé à';

  @override
  String get regVerifying => 'Vérification…';

  @override
  String get regResendCode => 'Renvoyer le code';

  @override
  String get regPhoneTitle => 'Votre téléphone';

  @override
  String get regPhoneIntro =>
      'Un code SMS à 6 chiffres sera envoyé pour vérifier votre numéro. Aucun lien entre votre numéro et votre token.';

  @override
  String get regPhoneFieldHint => 'Numéro';

  @override
  String get regSendingSms => 'Envoi du SMS…';

  @override
  String get regReceiveSms => 'Recevoir le SMS';

  @override
  String get regPhoneOtpTitle => 'Vérifier mon téléphone';

  @override
  String get regSmsSentTo => 'SMS envoyé au';

  @override
  String get regResendSms => 'Renvoyer le SMS';

  @override
  String get regDemoTitle => 'Vos données démographiques';

  @override
  String get regDemoIntro =>
      'Ces informations seront chiffrées dans votre token. Aucune valeur exacte n\'est stockée (ni âge précis, ni adresse précise).';

  @override
  String get regSectionSex => 'SEXE';

  @override
  String get regSectionAgeBucket => 'TRANCHE D\'ÂGE';

  @override
  String get regSectionCountryPostal => 'PAYS ET CODE POSTAL';

  @override
  String get regPostalCodeHint => 'Code postal';

  @override
  String get regGeneratingToken => 'Génération du token…';

  @override
  String get regGenerateMyToken => 'Générer mon token';

  @override
  String get regSuccessTitle => 'Bienvenue dans Mental E.T.';

  @override
  String get regSuccessTokenSaved =>
      'Votre token anonyme a été généré et sauvegardé sur cet appareil.';

  @override
  String get regSuccessTokenDetails =>
      'Il ne contient ni votre email, ni votre numéro de téléphone, ni votre nom. Uniquement votre sexe, votre tranche d\'âge et votre zone géographique (chiffrés). Vous pouvez maintenant commencer votre évaluation cognitive.';

  @override
  String get regImportantLabel => 'IMPORTANT';

  @override
  String get regSuccessWarning =>
      'Ne désinstallez pas l\'application sans avoir terminé votre évaluation : votre token est uniquement stocké sur cet appareil. Si vous le perdez, vous ne pourrez plus créer de nouveau compte avec le même email ou téléphone.';

  @override
  String get regEmailAlreadyRegistered =>
      'Cet email a déjà un compte. Si c\'est le vôtre, vous avez déjà un token.';

  @override
  String get regEmailUnavailable => 'Email indisponible.';

  @override
  String get regOtpIncorrectOrExpired => 'Code incorrect ou expiré.';

  @override
  String get regPhoneAlreadyRegistered => 'Ce numéro a déjà un compte.';

  @override
  String get regPhoneUnavailable => 'Numéro indisponible.';

  @override
  String get regEmailAlreadyHasToken => 'Cet email a déjà un token.';

  @override
  String get regPhoneAlreadyHasToken => 'Ce numéro a déjà un token.';

  @override
  String get regPostalNotFound =>
      'Code postal introuvable. Vérifiez le pays et le code.';

  @override
  String get regNoInternet => 'Pas de connexion internet.';

  @override
  String get regGenericRetryError => 'Erreur — merci de réessayer.';

  @override
  String get regSexMale => 'Masculin';

  @override
  String get regSexFemale => 'Féminin';

  @override
  String get regSexUndisclosed => 'Préfère ne pas dire';

  @override
  String get regAge1825 => '18 – 25 ans';

  @override
  String get regAge2635 => '26 – 35 ans';

  @override
  String get regAge3645 => '36 – 45 ans';

  @override
  String get regAge4655 => '46 – 55 ans';

  @override
  String get regAge5665 => '56 – 65 ans';

  @override
  String get regAge66plus => '66 ans et plus';

  @override
  String get scoringClassificationVerySuperior => 'Très supérieur';

  @override
  String get scoringClassificationSuperior => 'Supérieur';

  @override
  String get scoringClassificationHighAverage => 'Moyen fort';

  @override
  String get scoringClassificationAverage => 'Moyen';

  @override
  String get scoringClassificationLowAverage => 'Moyen faible';

  @override
  String get scoringClassificationBorderline => 'Limite';

  @override
  String get scoringClassificationExtremelyLow => 'Extrêmement bas';

  @override
  String get scoringNotAvailable => 'N/A';

  @override
  String scoringSummaryFullScaleIq(int score, String classification) {
    return 'QI Total: $score ($classification)';
  }

  @override
  String scoringSummaryPercentile(int rank) {
    return 'Percentile: ${rank}e';
  }

  @override
  String scoringSummaryConfidenceInterval(int lower, int upper) {
    return 'Intervalle de confiance 95%: $lower - $upper';
  }

  @override
  String get scoringIndexVerbalComprehension => 'Compréhension Verbale';

  @override
  String get scoringIndexVisualSpatial => 'Visuo-Spatial';

  @override
  String get scoringIndexFluidReasoning => 'Raisonnement Fluide';

  @override
  String get scoringIndexWorkingMemory => 'Mémoire de Travail';

  @override
  String get scoringIndexProcessingSpeed => 'Vitesse de Traitement';

  @override
  String scoringSummaryRelativeStrengths(String list) {
    return 'Forces relatives: $list';
  }

  @override
  String scoringSummaryRelativeWeaknesses(String list) {
    return 'Faiblesses relatives: $list';
  }

  @override
  String get scoringSummaryHomogeneousProfile => 'Profil cognitif homogène';

  @override
  String scoringSummaryHeterogeneousProfile(int points) {
    return 'Profil cognitif hétérogène (écart max: $points points)';
  }

  @override
  String get simTestName => 'Similitudes';

  @override
  String get simEyebrow => 'COMPRÉHENSION VERBALE · VCI';

  @override
  String simStatusBar(int seconds, int score) {
    return '$seconds s · $score pts';
  }

  @override
  String get simQuestionPrompt => 'En quoi ces deux mots sont-ils similaires ?';

  @override
  String simLevelLabel(String level) {
    return 'Niveau : $level';
  }

  @override
  String get simLevelConcrete => 'Concret';

  @override
  String get simLevelFunctional => 'Fonctionnel';

  @override
  String get simLevelCategorical => 'Catégoriel';

  @override
  String get simLevelAbstract => 'Abstrait';

  @override
  String get simAnswerLabel => 'Votre réponse :';

  @override
  String get simAnswerHint => 'Expliquez en quoi ils sont similaires...';

  @override
  String get simTipsTitle => 'Conseils pour obtenir 2 points :';

  @override
  String get simTipsLine1 =>
      '• Donnez une catégorie abstraite ou superordonnée';

  @override
  String get simTipsLine2 =>
      '• Ex: \"Ce sont des...\", \"Formes de...\", \"Types de...\"';

  @override
  String get simFeedbackExcellent => 'Excellent !';

  @override
  String get simFeedbackCorrect => 'Correct';

  @override
  String get simFeedbackIncomplete => 'Réponse incomplète';

  @override
  String get simFeedbackMsg2pts => 'Réponse abstraite/catégorielle ! +2 points';

  @override
  String get simFeedbackMsg1pt => 'Réponse fonctionnelle/propriété. +1 point';

  @override
  String get simFeedbackMsg0pt => 'Réponse incorrecte ou trop vague. 0 point';

  @override
  String simYourAnswerQuoted(String answer) {
    return 'Votre réponse : \"$answer\"';
  }

  @override
  String get simExamples2pts => 'Exemples de réponses à 2 points :';

  @override
  String get simExamples1pt => 'Exemples de réponses à 1 point :';

  @override
  String simTimeSeconds(int seconds) {
    return 'Temps : $seconds s';
  }

  @override
  String simTotalScore(int score) {
    return 'Score total : $score points';
  }

  @override
  String get simDiscontinue =>
      '3 scores de 0 consécutifs - Test terminé (WAIS-IV)';

  @override
  String get simSeeResults => 'Voir les résultats';

  @override
  String get simResultsTitle => 'Test des Similitudes - Résultats';

  @override
  String simRawScore(int score, int max) {
    return 'Score brut : $score/$max points';
  }

  @override
  String simItemsCompleted(int completed, int total) {
    return 'Items complétés : $completed/$total';
  }

  @override
  String simPercentage(int percent) {
    return 'Pourcentage : $percent%';
  }

  @override
  String simTotalTime(int seconds) {
    return 'Temps total : $seconds s';
  }

  @override
  String get simSubtitle =>
      'Test de raisonnement verbal et abstraction conceptuelle';

  @override
  String get simBreakdownTitle => 'Répartition par niveau :';

  @override
  String simBreakdownLine(String level, int total, int max) {
    return '$level: $total/$max points';
  }

  @override
  String get simPerfExceptional => 'Performance exceptionnelle (θ > +2.0)';

  @override
  String get simPerfSuperior => 'Performance supérieure (θ > +1.0)';

  @override
  String get simPerfAverage => 'Performance moyenne (θ ≈ 0)';

  @override
  String get simPerfBelow => 'Performance inférieure (θ < 0)';

  @override
  String get simPerfLow => 'Performance faible (θ < -1.0)';

  @override
  String get simBack => 'Retour';

  @override
  String get matTestName => 'Matrices Progressives';

  @override
  String get matEyebrow => 'TEST DE QI · FSIQ';

  @override
  String get matCorrect => 'Correct !';

  @override
  String get matIncorrect => 'Incorrect';

  @override
  String matResponseTime(int seconds) {
    return 'Temps de réponse : $seconds s';
  }

  @override
  String matScoreFraction(int score, int total) {
    return 'Score : $score/$total';
  }

  @override
  String get matDiscontinue4 => '4 échecs consécutifs - Test terminé (WAIS-IV)';

  @override
  String get matSeeResultsEnded => 'Voir résultats (test terminé)';

  @override
  String get matNextItem => 'Item suivant';

  @override
  String get matSeeResults => 'Voir résultats';

  @override
  String get matFinishedTitle => 'Test des Matrices terminé !';

  @override
  String get matRawScore => 'Score brut';

  @override
  String get matSuccessRate => 'Taux de réussite';

  @override
  String get matAvgTimePerItem => 'Temps moyen/item';

  @override
  String get matEvaluation => 'Évaluation :';

  @override
  String get matPerfExcellent =>
      'Excellent ! Raisonnement fluide très supérieur.';

  @override
  String get matPerfVeryGood =>
      'Très bien ! Bonnes capacités d\'analyse logique.';

  @override
  String get matPerfGood => 'Bien. Capacités moyennes à bonnes.';

  @override
  String get matPerfAverage => 'Moyen. Des améliorations sont possibles.';

  @override
  String get matPerfBelowAverage =>
      'Résultats en-dessous de la moyenne. Entraînement recommandé.';

  @override
  String matPoints(int score) {
    return '$score pts';
  }

  @override
  String get matValidateAnswer => 'Valider la réponse';

  @override
  String get matRestart => 'Recommencer';

  @override
  String matRulesTheta(int rules, String theta) {
    return 'Règles : $rules | θ = $theta';
  }

  @override
  String get matInstruction =>
      'Trouvez la pièce manquante qui complète logiquement la matrice';

  @override
  String get matChooseAnswer => 'Choisissez la réponse :';

  @override
  String get matDiffEasy => 'Facile';

  @override
  String get matDiffMediumEasy => 'Moyen-Facile';

  @override
  String get matDiffMedium => 'Moyen';

  @override
  String get matDiffMediumHard => 'Moyen-Difficile';

  @override
  String get matDiffHard => 'Difficile';

  @override
  String get cubesTestName => 'Test des Cubes';

  @override
  String get cubesBravo => 'Bravo !';

  @override
  String cubesElapsedTime(String time) {
    return 'Temps écoulé : $time';
  }

  @override
  String cubesPointsEarned(int points) {
    return 'Points gagnés : $points';
  }

  @override
  String cubesTotalScore(int score) {
    return 'Score total : $score';
  }

  @override
  String get cubesFinishedTitle => 'Test terminé !';

  @override
  String get cubesTotalScoreLabel => 'Score total';

  @override
  String cubesTotalScoreValue(int score, int max) {
    return '$score/$max pts';
  }

  @override
  String get cubesItemsCompletedLabel => 'Items complétés';

  @override
  String cubesItemsCompletedValue(int count) {
    return '$count/14';
  }

  @override
  String get cubesAvgTime => 'Temps moyen';

  @override
  String get cubesPerfExcellent =>
      'Excellent ! Capacités visuospatiales très supérieures.';

  @override
  String get cubesPerfVeryGood =>
      'Très bien ! Bonnes capacités d\'analyse visuelle.';

  @override
  String get cubesDiffExample => 'Exemple';

  @override
  String get cubesDiffVeryHard => 'Très difficile';

  @override
  String get cubesDescExample => 'Item exemple - Ne compte pas pour le score';

  @override
  String get cubesDesc2x2 => 'Pattern 2×2 simple';

  @override
  String get cubesDesc3x3Diagonals => 'Pattern 3×3 avec diagonales';

  @override
  String get cubesDesc3x3Complex => 'Pattern 3×3 complexe - Haute cohésion';

  @override
  String cubesCohesion(int score) {
    return 'Cohésion: $score';
  }

  @override
  String cubesRemaining(String time) {
    return 'Reste: $time';
  }

  @override
  String get cubesReproduceInstruction =>
      'Reproduisez le pattern ci-dessous en tapant sur les cubes';

  @override
  String get cubesPatternToReproduce => 'Pattern à reproduire :';

  @override
  String get cubesYourAnswer => 'Votre réponse :';

  @override
  String get cubesReset => 'Réinitialiser';

  @override
  String get fwTestName => 'Balances Quantitatives';

  @override
  String get fwEyebrow => 'RAISONNEMENT FLUIDE · FRI';

  @override
  String get fwCorrectAnswerPoint => 'Bonne réponse ! +1 point';

  @override
  String get fwWrongAnswer => 'Mauvaise réponse. La bonne réponse était :';

  @override
  String fwTime(int seconds) {
    return 'Temps : $seconds s';
  }

  @override
  String get fwDiscontinue3 => '3 échecs consécutifs - Test terminé (WAIS-IV)';

  @override
  String get fwSeeResults => 'Voir les résultats';

  @override
  String get fwResultsTitle => 'Test des Balances Quantitatives - Résultats';

  @override
  String fwRawScorePoints(int score) {
    return 'Score brut : $score/27 points';
  }

  @override
  String fwItemsCompleted(int count) {
    return 'Items complétés : $count/27';
  }

  @override
  String fwPercentage(int percent) {
    return 'Pourcentage : $percent%';
  }

  @override
  String fwTotalTime(int seconds) {
    return 'Temps total : $seconds s';
  }

  @override
  String get fwGLoading => 'g-loading : 0.78 (le plus élevé du WAIS-IV)';

  @override
  String get fwPerfExceptional => 'Performance exceptionnelle (θ > +2.0)';

  @override
  String get fwPerfSuperior => 'Performance supérieure (θ > +1.0)';

  @override
  String get fwPerfAverage => 'Performance moyenne (θ ≈ 0)';

  @override
  String get fwPerfInferior => 'Performance inférieure (θ < 0)';

  @override
  String get fwPerfLow => 'Performance faible (θ < -1.0)';

  @override
  String fwScoreFraction(int score, int total) {
    return '$score/$total';
  }

  @override
  String get fwInstruction =>
      'Trouvez la valeur manquante qui équilibre la balance.';

  @override
  String get fwWhatIs => 'Que vaut ';

  @override
  String fwSeconds(int seconds) {
    return '$seconds s';
  }

  @override
  String get vpTestName => 'Puzzles Visuels';

  @override
  String get vpEyebrow => 'VISUO-SPATIAL · VSI';

  @override
  String get vpCorrect => 'Correct';

  @override
  String get vpIncorrect => 'Incorrect';

  @override
  String get vpValidate => 'Valider';

  @override
  String vpSelectedCount(int count) {
    return '$count / 3 sélectionnées';
  }

  @override
  String get vpInstruction =>
      'Choisissez les 3 pièces qui forment la figure (rotations permises, retournements interdits).';

  @override
  String get vpDemoEyebrow => 'DÉMONSTRATION';

  @override
  String get vpDemoInstruction =>
      'Entraînement sans chrono : choisissez les 3 pièces qui forment la figure, puis validez.';

  @override
  String get vpDemoStart => 'Commencer le test';

  @override
  String get vpDemoRetry => 'Réessayer';

  @override
  String vpSelectionSemantics(int filled, int total) {
    return 'Sélection : $filled sur $total pièces';
  }

  @override
  String get vpSelectionLabel => 'SÉLECTION';

  @override
  String vpPieceSemantics(String label) {
    return 'Pièce $label';
  }

  @override
  String get vpTargetTitle => 'FIGURE À RECONSTITUER';

  @override
  String get codingTestName => 'Code (Digit Symbol)';

  @override
  String get codingEyebrow => 'VITESSE DE TRAITEMENT · PSI';

  @override
  String get codingStartTraining => 'Commencer l\'entraînement';

  @override
  String get codingTitle => 'Test de Code';

  @override
  String get codingDescription =>
      'Ce test mesure votre vitesse de traitement et votre coordination visuomotrice.';

  @override
  String get codingReferenceKey => 'Clé de référence :';

  @override
  String get codingTaskTitle => 'Votre tâche';

  @override
  String get codingTaskDesc =>
      'Pour chaque chiffre affiché, sélectionnez le symbole correspondant';

  @override
  String get codingTimeLimitTitle => 'Temps limité';

  @override
  String get codingTimeLimitDesc =>
      '120 secondes pour compléter le maximum de cases (135 au total)';

  @override
  String get codingScoringTitle => 'Scoring';

  @override
  String get codingScoringDesc =>
      '1 point par case correcte, pas de pénalité pour les erreurs';

  @override
  String get codingTrainingDoneTitle => 'Entraînement terminé';

  @override
  String get codingTrainingDoneBody =>
      'Vous êtes prêt à commencer le test. Vous aurez 120 secondes pour compléter le maximum de cases.';

  @override
  String get codingStartTest => 'Commencer le test';

  @override
  String get codingTestDoneTitle => 'Test terminé !';

  @override
  String get codingTimeElapsed => 'Temps écoulé : 120 secondes';

  @override
  String codingCellsCompleted(int count) {
    return 'Cases complétées : $count/135';
  }

  @override
  String codingCellsCorrect(int count) {
    return 'Cases correctes : $count';
  }

  @override
  String codingScorePoints(int count) {
    return 'Score : $count points';
  }

  @override
  String get codingPerfExceptional => 'Performance exceptionnelle !';

  @override
  String get codingPerfVeryGood => 'Très bonne performance';

  @override
  String get codingPerfAboveAverage => 'Performance moyenne-haute';

  @override
  String get codingPerfAverage => 'Performance moyenne';

  @override
  String get codingPerfBelowAverage => 'Performance en-dessous de la moyenne';

  @override
  String get codingTrainingTab => 'Entraînement';

  @override
  String get codingReferenceShort => 'Référence :';

  @override
  String codingCellProgress(int current, int total) {
    return 'Case $current/$total';
  }

  @override
  String codingCompletedProgress(int count, int total) {
    return 'Complétées : $count/$total';
  }

  @override
  String get codingSelectSymbol => 'Sélectionnez un symbole :';

  @override
  String get codingClear => 'Effacer';

  @override
  String get codingFinishTraining => 'Terminer l\'entraînement';

  @override
  String get ssTestName => 'Recherche de Symboles';

  @override
  String get ssDescription =>
      'Ce test mesure votre vitesse de traitement visuelle et votre capacité de discrimination.';

  @override
  String get ssExampleLabel => 'Exemple d\'item :';

  @override
  String get ssTargets => 'CIBLES';

  @override
  String get ssGroup => 'GROUPE';

  @override
  String get ssExampleAnswer => '→ Réponse : OUI (┴ est présent)';

  @override
  String get ssTaskTitle => 'Votre tâche';

  @override
  String get ssTaskDesc =>
      'Cherchez si l\'un des symboles cibles apparaît dans le groupe';

  @override
  String get ssQuickAnswerTitle => 'Réponse rapide';

  @override
  String get ssQuickAnswerDesc => 'Cliquez OUI ou NON aussi vite que possible';

  @override
  String get ssScoringPenaltyTitle => 'Scoring avec pénalité';

  @override
  String get ssScoringPenaltyDesc =>
      'Score = Réponses correctes - Réponses incorrectes';

  @override
  String get ssTimeLimitTitle => 'Temps limité';

  @override
  String get ssTimeLimitDesc => '120 secondes pour 60 items';

  @override
  String get ssTrainingDoneBody =>
      'Vous êtes prêt ! Vous aurez 120 secondes pour compléter le maximum d\'items.\n\nRappel : Score = Réponses correctes - Réponses incorrectes';

  @override
  String ssItemsAnswered(int count) {
    return 'Items répondus : $count/60';
  }

  @override
  String ssCorrectAnswers(int count) {
    return 'Réponses correctes : $count';
  }

  @override
  String ssIncorrectAnswers(int count) {
    return 'Réponses incorrectes : $count';
  }

  @override
  String ssNotAnswered(int count) {
    return 'Non répondus : $count';
  }

  @override
  String ssRawScore(int count) {
    return 'Score brut : $count';
  }

  @override
  String get ssScoreFormulaShort => '(Corrects - Incorrects)';

  @override
  String get ssPerfGood => 'Bonne performance';

  @override
  String ssItemProgress(int current, int total) {
    return 'Item $current/$total';
  }

  @override
  String ssAnsweredProgress(int count) {
    return 'Répondus : $count/60';
  }

  @override
  String get ssTargetSymbols => 'SYMBOLES CIBLES';

  @override
  String get ssSearchGroup => 'GROUPE DE RECHERCHE';

  @override
  String get ssNo => 'NON';

  @override
  String get ssYes => 'OUI';

  @override
  String get dsTestName => 'Mémoire des Chiffres';

  @override
  String get dsEyebrow => 'MÉMOIRE DE TRAVAIL · WMI';

  @override
  String get dsDescription =>
      'Ce test mesure votre mémoire de travail à travers 3 parties distinctes :';

  @override
  String get dsForwardTitle => 'Partie 1 : Empan Direct';

  @override
  String get dsForwardInstruction => 'Répétez les chiffres dans le même ordre';

  @override
  String get dsBackwardTitle => 'Partie 2 : Empan Inverse';

  @override
  String get dsBackwardInstruction => 'Répétez les chiffres en ordre inverse';

  @override
  String get dsSequencingTitle => 'Partie 3 : Séquençage';

  @override
  String get dsSequencingInstruction =>
      'Répétez les chiffres en ordre croissant';

  @override
  String get dsPresentationInfo =>
      'Les chiffres seront présentés à raison de 1 chiffre par seconde.';

  @override
  String get dsTypeForward => 'Empan Direct';

  @override
  String get dsTypeBackward => 'Empan Inverse';

  @override
  String get dsTypeSequencing => 'Séquençage';

  @override
  String get dsStartPart => 'Commencer';

  @override
  String dsLengthTrial(int length, int trial) {
    return 'Longueur $length - Essai $trial';
  }

  @override
  String get dsListenCarefully => 'Écoutez attentivement';

  @override
  String get dsCorrect => 'Correct !';

  @override
  String get dsIncorrect => 'Incorrect';

  @override
  String dsPointsEarned(int count) {
    return 'Points gagnés : $count';
  }

  @override
  String dsCorrectAnswer(String answer) {
    return 'Réponse correcte : $answer';
  }

  @override
  String dsYourAnswer(String answer) {
    return 'Votre réponse : $answer';
  }

  @override
  String get dsResultsByPart => 'Résultats par partie :';

  @override
  String dsForwardScore(int count) {
    return 'Empan Direct : $count points';
  }

  @override
  String dsBackwardScore(int count) {
    return 'Empan Inverse : $count points';
  }

  @override
  String dsSequencingScore(int count) {
    return 'Séquençage : $count points';
  }

  @override
  String dsTotalScore(int count) {
    return 'Score Total : $count points';
  }

  @override
  String get dsEnterAnswer => 'Saisissez votre réponse...';

  @override
  String dsValidateProgress(int count, int total) {
    return 'Valider ($count/$total)';
  }

  @override
  String get psTestName => 'Mémoire des Images';

  @override
  String get psDescription =>
      'Ce test mesure votre mémoire de travail visuelle et votre attention sélective.';

  @override
  String get psPhase1Title => 'Phase 1 : Mémorisation';

  @override
  String get psPhase1Desc =>
      'Des images seront présentées une par une (3 secondes chacune)';

  @override
  String get psPhase2Title => 'Phase 2 : Rappel';

  @override
  String get psPhase2Desc =>
      'Sélectionnez les images dans l\'ordre exact de présentation';

  @override
  String get psProgressionTitle => 'Progression';

  @override
  String get psProgressionDesc =>
      'La difficulté augmente : 1 à 6 images à mémoriser';

  @override
  String get psTrialsInfo =>
      '12 essais au total. Le test s\'arrête après 2 échecs au même niveau.';

  @override
  String get psMemorizationTab => 'Mémorisation';

  @override
  String get psRecallTab => 'Rappel';

  @override
  String psLevelTrial(int level, int trial) {
    return 'Niveau $level - Essai $trial';
  }

  @override
  String get psMemorizeImages => 'Mémorisez les images';

  @override
  String psImageProgress(int current, int total) {
    return 'Image $current / $total';
  }

  @override
  String psSelectInOrder(int count) {
    return 'Sélectionnez les $count images dans l\'ordre';
  }

  @override
  String get psNoSelection => 'Aucune sélection';

  @override
  String get psClearLast => 'Effacer la dernière sélection';

  @override
  String psCorrectOrder(String names) {
    return 'Ordre correct : $names';
  }

  @override
  String psYourOrder(String names) {
    return 'Votre ordre : $names';
  }

  @override
  String psTrialsCompleted(int count) {
    return 'Essais complétés : $count/12';
  }

  @override
  String psScorePoints(int count) {
    return 'Score Total : $count points';
  }

  @override
  String psMaxLevel(int level) {
    return 'Niveau maximal atteint : Niveau $level';
  }

  @override
  String get psImgChat => 'Chat';

  @override
  String get psImgInsecte => 'Insecte';

  @override
  String get psImgLapin => 'Lapin';

  @override
  String get psImgOiseau => 'Oiseau';

  @override
  String get psImgPoisson => 'Poisson';

  @override
  String get psImgTortue => 'Tortue';

  @override
  String get psImgPapillon => 'Papillon';

  @override
  String get psImgCoccinelle => 'Coccinelle';

  @override
  String get psImgChaise => 'Chaise';

  @override
  String get psImgLampe => 'Lampe';

  @override
  String get psImgMontre => 'Montre';

  @override
  String get psImgParapluie => 'Parapluie';

  @override
  String get psImgSac => 'Sac';

  @override
  String get psImgLit => 'Lit';

  @override
  String get psImgPorte => 'Porte';

  @override
  String get psImgFenetre => 'Fenêtre';

  @override
  String get psImgGateau => 'Gâteau';

  @override
  String get psImgCafe => 'Café';

  @override
  String get psImgPizza => 'Pizza';

  @override
  String get psImgPomme => 'Pomme';

  @override
  String get psImgGlace => 'Glace';

  @override
  String get psImgBurger => 'Burger';

  @override
  String get psImgSandwich => 'Sandwich';

  @override
  String get psImgOeuf => 'Œuf';

  @override
  String get psImgMarteau => 'Marteau';

  @override
  String get psImgCle => 'Clé';

  @override
  String get psImgCiseaux => 'Ciseaux';

  @override
  String get psImgPinceau => 'Pinceau';

  @override
  String get psImgCrayon => 'Crayon';

  @override
  String get psImgCouteau => 'Couteau';

  @override
  String get psImgTournevis => 'Tournevis';

  @override
  String get psImgEngrenage => 'Engrenage';

  @override
  String get psImgVoiture => 'Voiture';

  @override
  String get psImgVelo => 'Vélo';

  @override
  String get psImgAvion => 'Avion';

  @override
  String get psImgTrain => 'Train';

  @override
  String get psImgBateau => 'Bateau';

  @override
  String get psImgBus => 'Bus';

  @override
  String get psImgMoto => 'Moto';

  @override
  String get psImgFusee => 'Fusée';

  @override
  String get vocabTestName => 'Vocabulaire';

  @override
  String get vocabEyebrow => 'COMPRÉHENSION VERBALE · VCI';

  @override
  String vocabTimerScore(int seconds, int score) {
    return '$seconds s · $score pts';
  }

  @override
  String get vocabFeedbackExcellent => 'Excellent !';

  @override
  String get vocabFeedbackCorrect => 'Correct';

  @override
  String get vocabFeedbackIncomplete => 'Réponse incomplète';

  @override
  String get vocabFeedbackTwoPoints =>
      'Définition complète et précise ! +2 points';

  @override
  String get vocabFeedbackOnePoint =>
      'Définition partielle mais correcte. +1 point';

  @override
  String get vocabFeedbackZeroPoint =>
      'Réponse incorrecte ou trop vague. 0 point';

  @override
  String vocabWordLabel(String word) {
    return 'Mot : « $word »';
  }

  @override
  String vocabYourAnswerLabel(String answer) {
    return 'Votre réponse : « $answer »';
  }

  @override
  String get vocabEmptyAnswer => '(vide)';

  @override
  String get vocabTwoPointExamples => 'Exemples de réponses à 2 points :';

  @override
  String get vocabOnePointExamples => 'Exemples de réponses à 1 point :';

  @override
  String vocabTimeSeconds(int seconds) {
    return 'Temps : $seconds s';
  }

  @override
  String vocabTotalScore(int score) {
    return 'Score total : $score points';
  }

  @override
  String get vocabDiscontinued =>
      '3 scores de 0 consécutifs - Test terminé (WAIS-IV)';

  @override
  String get vocabViewResults => 'Voir les résultats';

  @override
  String get vocabResultsTitle => 'Test de Vocabulaire - Résultats';

  @override
  String vocabRawScore(int score, int max) {
    return 'Score brut : $score/$max points';
  }

  @override
  String vocabItemsCompleted(int completed, int total) {
    return 'Items complétés : $completed/$total';
  }

  @override
  String vocabPercentage(int percent) {
    return 'Pourcentage : $percent%';
  }

  @override
  String vocabTotalTime(int seconds) {
    return 'Temps total : $seconds s';
  }

  @override
  String get vocabTestCaption =>
      'Test de connaissance lexicale et compréhension verbale';

  @override
  String get vocabFrequencyBreakdownTitle => 'Répartition par fréquence :';

  @override
  String vocabFrequencyBreakdownRow(String name, int score, int max) {
    return '$name : $score/$max points';
  }

  @override
  String get vocabPerfExceptional => 'Performance exceptionnelle (θ > +2.0)';

  @override
  String get vocabPerfSuperior => 'Performance supérieure (θ > +1.0)';

  @override
  String get vocabPerfAverage => 'Performance moyenne (θ ≈ 0)';

  @override
  String get vocabPerfBelowAverage => 'Performance inférieure (θ < 0)';

  @override
  String get vocabPerfLow => 'Performance faible (θ < -1.0)';

  @override
  String get vocabFreqVeryHigh => 'Très fréquent';

  @override
  String get vocabFreqHigh => 'Fréquent';

  @override
  String get vocabFreqMedium => 'Moyen';

  @override
  String get vocabFreqLow => 'Rare';

  @override
  String get vocabFreqVeryLow => 'Très rare';

  @override
  String get vocabInstruction => 'Définissez le mot suivant';

  @override
  String get vocabYourDefinitionLabel => 'Votre définition :';

  @override
  String get vocabDefinitionHint => 'Écrivez la définition du mot...';

  @override
  String get vocabTipsTitle => 'Conseils pour obtenir 2 points :';

  @override
  String get vocabTipComplete => '• Donnez une définition complète et précise';

  @override
  String get vocabTipSynonyms => '• Utilisez des synonymes exacts';

  @override
  String get vocabTipContext => '• Expliquez le sens avec contexte';

  @override
  String get demoBadge => 'ENTRAÎNEMENT';

  @override
  String get demoNotice => 'Entraînement — cet essai ne compte pas.';

  @override
  String get demoStart => 'Commencer le test';

  @override
  String get demoRetry => 'Réessayer';

  @override
  String get demoContinue => 'Continuer';

  @override
  String get demoWellDone => 'Bonne réponse !';

  @override
  String get demoTryAgain => 'Pas tout à fait — réessayez';

  @override
  String get ugTitle => 'Ton résultat est prêt';

  @override
  String get ugEyebrow => 'Dernières étapes';

  @override
  String get ugFreeNotice =>
      'Le test est 100 % gratuit. Pour recevoir ton résultat, il te reste quelques étapes simples : elles se valident automatiquement.';

  @override
  String get ugErrorBody =>
      'Impossible de récupérer l\'état de ton déblocage. Vérifie ta connexion puis réessaie.';

  @override
  String get ugRetry => 'Réessayer';

  @override
  String get ugRefresh => 'Actualiser';

  @override
  String get ugStep1Title => 'Invite 3 amis';

  @override
  String get ugStep1Body =>
      'Partage ton lien personnel avec 3 amis. Dès qu\'ils rejoignent le test avec ton lien, cette étape avance.';

  @override
  String get ugCopyLink => 'Copier mon lien d\'invitation';

  @override
  String get ugCopied => 'Lien copié !';

  @override
  String ugInviteCounter(int joined, int required) {
    return '$joined/$required amis ont rejoint avec ton lien';
  }

  @override
  String get ugStep2Title => 'Tes amis passent leur test';

  @override
  String get ugStep2Body =>
      'Tes amis doivent maintenant terminer leur test de QI. On attend leurs résultats — n\'hésite pas à les relancer !';

  @override
  String ugFriendDone(int n) {
    return 'Ami $n : test terminé';
  }

  @override
  String ugFriendPending(int n) {
    return 'Ami $n : test en cours';
  }

  @override
  String ugWaitingCounter(int done, int required) {
    return '$done/$required tests terminés';
  }

  @override
  String get ugStep3Title => 'Dernière étape : Instagram';

  @override
  String ugStep3Body(String handle) {
    return 'Abonne-toi à notre compte @$handle puis indique ton pseudo. On vérifie ton abonnement et ton résultat est débloqué.';
  }

  @override
  String ugFollowButton(String handle) {
    return 'Suivre @$handle sur Instagram';
  }

  @override
  String get ugInstaFieldLabel => 'Ton pseudo Instagram';

  @override
  String get ugInstaSubmit => 'Valider mon abonnement';

  @override
  String get ugInstaPending =>
      'Vérification de ton abonnement en cours… Ton résultat sera débloqué d\'ici quelques heures. Tu peux fermer cette page et revenir plus tard.';

  @override
  String get inviteLandingTitle => 'Invitation';

  @override
  String get inviteLandingBody =>
      'Un ami t\'invite à passer le test de QI gratuit Mentality. En terminant ton test, tu obtiens ton propre résultat et tu aides ton ami à débloquer le sien.';

  @override
  String get inviteLandingCta => 'Commencer le test gratuit';
}
