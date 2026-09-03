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
  String get matDiscontinue3 => '3 échecs consécutifs — exercice terminé.';

  @override
  String get assessIntroTitle => 'Nouvelle évaluation';

  @override
  String get assessIntroEyebrow => 'ÉVALUATION COGNITIVE';

  @override
  String get assessIntroHero1 => 'Cinq indices,';

  @override
  String get assessIntroHero2 => 'une mesure.';

  @override
  String get assessIntroDescription =>
      'Cette évaluation explore vos capacités cognitives à travers cinq domaines du modèle CHC (Cattell-Horn-Carroll). Un score global en est la synthèse.';

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
  String get assessBeforeStartHeader => 'AVANT DE COMMENCER';

  @override
  String get assessBeforeStartBody =>
      'Durée estimée 60 à 90 minutes. Calme et concentration requis.';

  @override
  String get assessLaunchFullAssessment => 'Lancer l\'évaluation complète';

  @override
  String get assessOrIndividualSubtest => 'OU SUBTEST INDIVIDUEL';

  @override
  String get assessSubtestCubes => 'Cubes';

  @override
  String get assessSubtestMatrices => 'Matrices Progressives';

  @override
  String get assessSubtestFigureWeights => 'Équilibres';

  @override
  String get assessSubtestVisualPuzzles => 'Assemblages';

  @override
  String get assessSubtestSimilarities => 'Points communs';

  @override
  String get assessSubtestVocabulary => 'Vocabulaire';

  @override
  String get assessSubtestInformation => 'Information';

  @override
  String get assessSubtestDigitSpan => 'Suites de chiffres';

  @override
  String get assessSubtestArithmetic => 'Arithmétique';

  @override
  String get assessSubtestPictureSpan => 'Mémoire des Images';

  @override
  String get assessSubtestCoding => 'Transcription';

  @override
  String get assessSubtestSymbolSearch => 'Détection de symboles';

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
  String get histScoreFsiq => 'QI Total';

  @override
  String get histScoreShortIq => 'QI';

  @override
  String get histScoreVci => 'Compréhension Verbale';

  @override
  String get histScoreVsi => 'Visuo-Spatial';

  @override
  String get histScoreFri => 'Raisonnement Fluide';

  @override
  String get histScoreWmi => 'Mémoire de Travail';

  @override
  String get histScorePsi => 'Vitesse de Traitement';

  @override
  String get histEmptyEyebrow => 'AUCUN RÉSULTAT';

  @override
  String get histEmptyHero1 => 'Votre historique';

  @override
  String get histEmptyHero2 => 'vous attend.';

  @override
  String get histEmptyDescription =>
      'Complétez votre première évaluation pour voir vos résultats apparaître ici.';

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
      'Cubes · Points communs · Suites de chiffres · Matrices · Vocabulaire · Arithmétique · Symboles · Assemblages · Information · Transcription · Images · Équilibres.';

  @override
  String get ctIntroImportantEyebrow => 'IMPORTANT';

  @override
  String get ctIntroImportantTitle => 'Enchaînement automatique';

  @override
  String get ctIntroImportantBody =>
      'Les tests se lanceront l\'un après l\'autre. Assurez-vous d\'avoir suffisamment de temps.';

  @override
  String get ctPatientAgeHeader => 'VOTRE ÂGE';

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
  String get ctComputingResultsEyebrow => 'ÉVALUATION';

  @override
  String get ctProcessing => 'TRAITEMENT';

  @override
  String ctTestNotFound(String testName) {
    return 'Test non trouvé : $testName';
  }

  @override
  String get ctTestCubes => 'Cubes';

  @override
  String get ctTestSimilarities => 'Points communs';

  @override
  String get ctTestDigitSpan => 'Suites de chiffres';

  @override
  String get ctTestMatrices => 'Matrices';

  @override
  String get ctTestVocabulary => 'Vocabulaire';

  @override
  String get ctTestArithmetic => 'Arithmétique';

  @override
  String get ctTestSymbolSearch => 'Détection de symboles';

  @override
  String get ctTestVisualPuzzles => 'Assemblages';

  @override
  String get ctTestInformation => 'Information';

  @override
  String get ctTestCoding => 'Transcription';

  @override
  String get ctTestPictureSpan => 'Mémoire des Images';

  @override
  String get ctTestFigureWeights => 'Équilibres';

  @override
  String get ctResultsTitle => 'Résultats';

  @override
  String get ctResultsEyebrow => 'VOTRE PROFIL COGNITIF';

  @override
  String get ctResultsHero1 => 'Évaluation';

  @override
  String get ctResultsHero2 => 'terminée.';

  @override
  String get ctResultsSummary =>
      'Synthèse de vos performances cognitives sur les exercices notés.';

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
  String get ctFsiqCardLabel => 'SCORE GLOBAL';

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
  String get ctGroupVciVerbal => 'Compréhension Verbale';

  @override
  String get ctGroupVsiVisuoSpatial => 'Visuo-Spatial';

  @override
  String get ctGroupFriReasoning => 'Raisonnement Fluide';

  @override
  String get ctGroupWmiMemory => 'Mémoire de Travail';

  @override
  String get ctGroupPsiSpeed => 'Vitesse de Traitement';

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
      'Sans votre âge, seuls les scores bruts sont affichés. Relancez le test en renseignant l\'âge pour obtenir le QI standardisé, les percentiles et les intervalles de confiance.';

  @override
  String get ctExportPdf => 'Exporter en PDF';

  @override
  String ctPdfError(String error) {
    return 'Erreur PDF : $error';
  }

  @override
  String get ctBackToHome => 'Retour à l\'accueil';

  @override
  String get ctPdfSubtitle => 'Rapport de profil cognitif';

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
  String get ctPdfFsiqLabel => 'SCORE GLOBAL';

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
  String get ctPdfIndexVci => 'Compréhension Verbale';

  @override
  String get ctPdfIndexVsi => 'Visuo-Spatial';

  @override
  String get ctPdfIndexFri => 'Raisonnement Fluide';

  @override
  String get ctPdfIndexWmi => 'Mémoire de Travail';

  @override
  String get ctPdfIndexPsi => 'Vitesse de Traitement';

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
  String get ctResumeFullTest => 'Reprendre l\'évaluation';

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
      'Une évaluation cognitive adaptative. 12 sous-tests, 5 indices, un score global.';

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
      'Évaluation complète des cinq indices cognitifs du modèle CHC.';

  @override
  String get homeAboutAdaptiveTitle => 'IA adaptative';

  @override
  String get homeAboutAdaptiveBody =>
      'Difficulté ajustée en temps réel via inférence IRT.';

  @override
  String get homeAboutValidationTitle => 'Cadre théorique';

  @override
  String get homeAboutValidationBody =>
      'Items originaux, écrits pour Mental E.T. et construits sur le modèle CHC.';

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
  String homeResumeProgress(int done, int total) {
    return '$done exercices sur $total';
  }

  @override
  String homeResumeNext(String name) {
    return 'Prochain : $name';
  }

  @override
  String get homeResumeFinish =>
      'Tous les exercices sont faits — il ne reste que la clôture.';

  @override
  String get homeResumeRestart => 'Recommencer';

  @override
  String get homeResumeRestartTitle => 'Recommencer depuis le début ?';

  @override
  String get homeResumeRestartBody =>
      'Les exercices déjà passés seront abandonnés et ne pourront plus être repris. Vous ne pourrez pas revenir en arrière.';

  @override
  String homeResumeCurrent(String name) {
    return 'En cours : $name';
  }

  @override
  String get infoTestName => 'Information';

  @override
  String get infoEyebrow => 'COMPRÉHENSION VERBALE';

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
  String get infoDiscontinue3 => '3 échecs consécutifs — exercice terminé.';

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
  String get arithEyebrow => 'MÉMOIRE DE TRAVAIL';

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
  String get oralVerifTitle => 'Vérification de ton enregistrement…';

  @override
  String get oralVerifBody =>
      'Un instant : nous vérifions que tes lectures ont bien été enregistrées. Cela prend en général moins d\'une minute.';

  @override
  String get oralVerifFailedTitle =>
      'Ton enregistrement n\'a pas pu être vérifié';

  @override
  String get oralVerifFailedBody =>
      'L\'enregistrement est absent, vide ou ne correspond pas aux textes lus. Sans enregistrement vérifié, les résultats du bilan ne peuvent pas s\'afficher.';

  @override
  String get oralVerifReRecord => 'Réenregistrer';

  @override
  String get oralVerifRetryCheck => 'Réessayer la vérification';

  @override
  String get oralVerifUnreachableTitle => 'Impossible de joindre le serveur';

  @override
  String get oralVerifUnreachableBody =>
      'La vérification n\'a pas pu aboutir. Vérifie ta connexion, puis réessaie.';

  @override
  String get oralVerifRetry => 'Réessayer';

  @override
  String get oralVerifTimeoutTitle =>
      'La vérification prend plus de temps que prévu';

  @override
  String get oralVerifTimeoutBody =>
      'Tes enregistrements sont bien arrivés, mais leur analyse n\'est pas terminée. Tu peux réessayer dans un instant.';

  @override
  String get oralVerifLeave => 'Quitter pour l\'instant';

  @override
  String get oralVerifRequiredHint =>
      'L\'enregistrement est indispensable avec un passe Gratuit : sans lui, les résultats ne pourront pas s\'afficher.';

  @override
  String get rpaTitle => 'Résultats en attente';

  @override
  String get rpaEyebrow => 'BILAN TERMINÉ';

  @override
  String get rpaHero => 'Encore une étape';

  @override
  String get rpaBody =>
      'Ton bilan est terminé et tes réponses sont enregistrées. Avec un passe Gratuit, les résultats s\'affichent une fois ton enregistrement vocal vérifié — et il n\'a pas encore pu l\'être.';

  @override
  String get rpaResume => 'Reprendre l\'enregistrement';

  @override
  String get rpaCheckAgain => 'Vérifier à nouveau';

  @override
  String get rpaStillPending =>
      'La vérification est toujours en cours. Réessaie dans un instant.';

  @override
  String get rpaStillFailed =>
      'L\'enregistrement n\'a pas pu être vérifié. Reprends l\'enregistrement.';

  @override
  String get rpaNetwork => 'Serveur injoignable. Vérifie ta connexion.';

  @override
  String get preEyebrow => 'Avant de commencer';

  @override
  String get preQ1Title => 'As-tu déjà passé un test de QI ?';

  @override
  String get preQ1Body =>
      'Une question, pour situer ce que tu t\'apprêtes à mesurer. Ta réponse ne change ni le test ni ton score.';

  @override
  String get preQ1Professional => 'Oui, avec un psychiatre ou un psychologue';

  @override
  String get preQ1Online => 'Oui, un test en ligne peu fiable';

  @override
  String get preQ1Never =>
      'Non, jamais — mais j\'ai toujours voulu en faire un';

  @override
  String get preLocalNotice =>
      'Tes réponses restent sur ton téléphone, chiffrées. Rien n\'est envoyé.';

  @override
  String get prePastEyebrow => 'Ce test passé';

  @override
  String get prePastTitle => 'Deux questions facultatives';

  @override
  String get prePastBody =>
      'Tu peux continuer sans y répondre. Rien ici n\'entre dans le calcul de ton score.';

  @override
  String get prePastAgeLabel => 'À quel âge l\'avais-tu passé ?';

  @override
  String get prePastAgeError => 'Un âge entre 5 et 90 ans.';

  @override
  String get prePastScoreLabel => 'Quel score avais-tu obtenu ?';

  @override
  String get prePastScoreError => 'Un score entre 40 et 200.';

  @override
  String get preEstimateEyebrow => 'Avant le premier exercice';

  @override
  String get preEstimateTitle => 'À combien estimes-tu ton QI ?';

  @override
  String get preEstimateBody =>
      'Posée maintenant, avant le premier exercice : une fois un résultat sous les yeux, ta réponse ne serait plus une croyance. 100 est la moyenne.';

  @override
  String get preEstimateHint => 'Fais glisser, ou touche − et +, pour choisir.';

  @override
  String get preEstimateAverage => '100 est la moyenne.';

  @override
  String get preEstimateConfirm => 'Valider mon estimation';

  @override
  String get preEstimateDecline => 'Je préfère ne pas répondre';

  @override
  String get preEstimateDecrease => 'Diminuer d\'un point';

  @override
  String get preEstimateIncrease => 'Augmenter d\'un point';

  @override
  String get privacyEyebrow => 'DONNÉES PERSONNELLES';

  @override
  String get privacyTitle => 'Confidentialité et consentement';

  @override
  String get privacySubtitle => 'Gérer ou retirer mon consentement';

  @override
  String get privacyIntro =>
      'L\'épreuve orale du bilan enregistre votre voix. Ce consentement vous appartient : vous pouvez le retirer ici, à tout moment, sans avoir à vous justifier.';

  @override
  String get privacyStatusEyebrow => 'ÉTAT ACTUEL';

  @override
  String get privacyStatusActive =>
      'Consentement actif : l\'épreuve orale peut enregistrer votre voix.';

  @override
  String get privacyStatusWithdrawn =>
      'Consentement retiré. Aucun nouvel enregistrement ne sera fait ni envoyé.';

  @override
  String get privacyStatusNone =>
      'Aucun consentement enregistré sur cet appareil : rien n\'autorise le microphone aujourd\'hui.';

  @override
  String get privacySourceToken =>
      'Recueilli lors de la création de votre passe, sur mental-et.com.';

  @override
  String get privacySourceInApp =>
      'Recueilli dans l\'application, avant l\'épreuve orale.';

  @override
  String get privacyReuseYes =>
      'Réutilisation des enregistrements par des tiers : acceptée.';

  @override
  String get privacyReuseNo =>
      'Réutilisation des enregistrements par des tiers : refusée.';

  @override
  String privacyVersionLine(String version, String date) {
    return 'Texte accepté : version $version, le $date.';
  }

  @override
  String get privacyWithdrawAction => 'Retirer mon consentement';

  @override
  String get privacyWithdrawDialogTitle => 'Retirer votre consentement ?';

  @override
  String get privacyWithdrawDialogBody =>
      'Ce que cela change immédiatement :\n\n• L\'épreuve orale ne démarrera plus et aucun nouvel enregistrement ne sera fait.\n• Les enregistrements pas encore envoyés ne partiront pas.\n• Les enregistrements déjà envoyés ne peuvent plus être retrouvés sans votre passe : ils sont anonymes, nous ne savons pas lesquels sont les vôtres.\n\nLe reste du bilan (les 12 épreuves notées) n\'est pas affecté. Vous pourrez consentir de nouveau plus tard si vous le souhaitez.';

  @override
  String get privacyWithdrawConfirm => 'Oui, retirer';

  @override
  String get privacyWithdrawDone =>
      'Consentement retiré. Plus aucun enregistrement ne sera fait ni envoyé.';

  @override
  String privacyWithdrawnOnLine(String date) {
    return 'Retiré le $date.';
  }

  @override
  String get privacyErasureTitle =>
      'Effacement des enregistrements déjà envoyés';

  @override
  String get privacyErasureBody =>
      'Le retrait vaut pour l\'avenir. Pour demander l\'effacement d\'enregistrements déjà envoyés (art. 17 du RGPD), écrivez-nous en joignant votre passe : sans lui, personne — nous compris — ne peut savoir lesquels sont les vôtres.';

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
  String get simTestName => 'Points communs';

  @override
  String get simEyebrow => 'COMPRÉHENSION VERBALE';

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
  String get simDiscontinue => '3 items passés d\'affilée — exercice terminé.';

  @override
  String get simSeeResults => 'Voir les résultats';

  @override
  String get simResultsTitle => 'Points communs - Résultats';

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
  String get matEyebrow => 'TEST DE QI';

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
  String get matDiscontinue4 => '4 échecs consécutifs — exercice terminé.';

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
  String get cubesTestName => 'Cubes';

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
  String get fwTestName => 'Équilibres';

  @override
  String get fwEyebrow => 'RAISONNEMENT FLUIDE';

  @override
  String get fwCorrectAnswerPoint => 'Bonne réponse ! +1 point';

  @override
  String get fwWrongAnswer => 'Mauvaise réponse. La bonne réponse était :';

  @override
  String fwTime(int seconds) {
    return 'Temps : $seconds s';
  }

  @override
  String get fwDiscontinue3 => '3 échecs consécutifs — exercice terminé.';

  @override
  String get fwSeeResults => 'Voir les résultats';

  @override
  String get fwResultsTitle => 'Équilibres - Résultats';

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
  String get fwGLoading =>
      'Cet exercice est fortement lié au raisonnement général.';

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
  String get vpTestName => 'Assemblages';

  @override
  String get vpEyebrow => 'VISUO-SPATIAL';

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
  String get codingTestName => 'Transcription';

  @override
  String get codingEyebrow => 'VITESSE DE TRAITEMENT';

  @override
  String get codingStartTraining => 'Commencer l\'entraînement';

  @override
  String get codingTitle => 'Transcription';

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
  String get ssTestName => 'Détection de symboles';

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
  String get dsTestName => 'Suites de chiffres';

  @override
  String get dsEyebrow => 'MÉMOIRE DE TRAVAIL';

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
  String get speedNoPauseTitle => '2 minutes sans interruption';

  @override
  String get speedNoPauseBody =>
      'Cet exercice mesure votre vitesse sur une plage continue. Il ne peut pas être mis en pause : si vous le quittez, il devra être repassé depuis le début. Installez-vous avant de commencer.';

  @override
  String get speedNoPauseConfirm => 'Je suis prêt';

  @override
  String get ctShareScore => 'Partager mon score';

  @override
  String get ctSubtestExitBody =>
      'Vous avez quitté cet exercice avant de le terminer. Les exercices déjà terminés sont enregistrés : vous pourrez reprendre l\'évaluation ici même, à cet exercice.';

  @override
  String get ctSubtestExitResume => 'Reprendre l\'exercice';

  @override
  String get ctSubtestExitTitle => 'Sous-test interrompu';

  @override
  String get demoBadge => 'ENTRAÎNEMENT';

  @override
  String get demoContinue => 'Continuer';

  @override
  String get demoNotice => 'Entraînement — cet essai ne compte pas.';

  @override
  String get demoRetry => 'Réessayer';

  @override
  String get demoStart => 'Commencer le test';

  @override
  String get demoTryAgain => 'Pas tout à fait — réessayez';

  @override
  String get demoWellDone => 'Bonne réponse !';

  @override
  String get histLockedBody =>
      'Ton résultat est enregistré, mais il reste flouté tant que toutes les missions ne sont pas validées.';

  @override
  String get histLockedBodyNoResult =>
      'Tes missions et ton lien d\'invitation sont ici. Termine ton évaluation pour débloquer ton résultat.';

  @override
  String get histLockedCta => 'Voir mes missions';

  @override
  String get histLockedTitle => 'Missions à valider';

  @override
  String get inviteLandingBody =>
      'Un ami t\'invite à passer le test de QI gratuit Mentality. En terminant ton test, tu obtiens ton propre résultat et tu aides ton ami à débloquer le sien.';

  @override
  String get inviteLandingCta => 'Commencer le test gratuit';

  @override
  String get inviteLandingTitle => 'Invitation';

  @override
  String get shareCancel => 'Annuler';

  @override
  String get shareCodeLabel => 'Code d\'invitation';

  @override
  String get shareConfirm => 'Partager cette image';

  @override
  String get shareError => 'Impossible de préparer l\'image. Réessaie.';

  @override
  String get shareEyebrow => 'Aperçu';

  @override
  String get shareIntro =>
      'Voici l\'image qui sera partagée. Rien n\'est publié tant que tu n\'as pas confirmé.';

  @override
  String get shareLinkCopied =>
      'Ton lien est copié — ajoute-le en sticker Lien sur ta story';

  @override
  String sharePercentile(int rank) {
    return 'Plus élevé que $rank % des participants';
  }

  @override
  String get shareScoreLabel => 'Score global';

  @override
  String get shareTitle => 'Partager mon score';

  @override
  String get ugCopied => 'Lien copié !';

  @override
  String get ugCopyLink => 'Copier mon lien d\'invitation';

  @override
  String get ugErrorBody =>
      'Impossible de récupérer l\'état de ton déblocage. Vérifie ta connexion puis réessaie.';

  @override
  String get ugEyebrow => 'Dernières étapes';

  @override
  String get ugFreeNotice =>
      'Le test est 100 % gratuit. Pour recevoir ton résultat, il te reste quelques étapes simples : elles se valident automatiquement.';

  @override
  String ugFriendDone(int n) {
    return 'Ami $n : test terminé';
  }

  @override
  String ugFriendPending(int n) {
    return 'Ami $n : test en cours';
  }

  @override
  String ugInviteCounter(int joined, int required) {
    return '$joined/$required amis ont terminé leur test';
  }

  @override
  String get ugRefresh => 'Actualiser';

  @override
  String get ugRefreshFailed =>
      'Impossible d\'actualiser. Vérifie ta connexion — les chiffres affichés datent de ta dernière connexion.';

  @override
  String get ugResultsHubNotice =>
      'Tout se trouve dans « Mes résultats » : tes missions, ton lien d\'invitation et ton résultat (flouté tant que toutes les missions ne sont pas validées). Tu peux quitter cette page et revenir quand tu veux.';

  @override
  String get ugRetry => 'Réessayer';

  @override
  String get ugStep1Body =>
      'Partage ton lien personnel avec 3 amis. Cette étape avance quand ils TERMINENT leur test — pas seulement quand ils s\'inscrivent. Pense à les relancer.';

  @override
  String get ugStep1Title => 'Invite 3 amis';

  @override
  String get ugStep2Body =>
      'Tes amis doivent maintenant terminer leur test de QI. On attend leurs résultats — n\'hésite pas à les relancer !';

  @override
  String get ugStep2Title => 'Tes amis passent leur test';

  @override
  String get ugTitle => 'Ton résultat est prêt';

  @override
  String ugWaitBody(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other:
          'Ton résultat est en préparation. Il sera publié dans $days jours, automatiquement — tu n\'as plus rien à faire.',
      one:
          'Ton résultat est en préparation. Il sera publié dans $days jour, automatiquement — tu n\'as plus rien à faire.',
      zero:
          'Ton résultat est en préparation. Il sera publié automatiquement — tu n\'as plus rien à faire.',
    );
    return '$_temp0';
  }

  @override
  String get ugWaitConfirming =>
      'Ton résultat se débloque dès la confirmation du serveur — cet écran s\'actualise tout seul.';

  @override
  String ugWaitCountdownDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Encore $days jours',
      one: 'Encore $days jour',
    );
    return '$_temp0';
  }

  @override
  String get ugWaitCountdownDone => 'Le délai est écoulé.';

  @override
  String ugWaitCountdownHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: 'Encore $hours heures',
      one: 'Encore $hours heure',
    );
    return '$_temp0';
  }

  @override
  String ugWaitCountdownMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'Encore $minutes minutes',
      one: 'Encore $minutes minute',
    );
    return '$_temp0';
  }

  @override
  String get ugWaitTitle => 'Tes résultats arrivent';

  @override
  String get vpDemoEyebrow => 'DÉMONSTRATION';

  @override
  String get vpDemoInstruction =>
      'Entraînement sans chrono : choisissez les 3 pièces qui forment la figure, puis validez.';

  @override
  String get vpDemoRetry => 'Réessayer';

  @override
  String get vpDemoStart => 'Commencer le test';

  @override
  String vpReadyBody(int count) {
    return 'L\'entraînement est terminé. Le test commence : $count puzzles, chacun avec son propre chrono. Le temps démarre dès que vous appuyez sur le bouton.';
  }

  @override
  String get vpReadyStart => 'Lancer le test';

  @override
  String get vpReadyTitle => 'Prêt ?';

  @override
  String get vpRecorded => 'Réponse enregistrée';

  @override
  String get completionPendingNotice =>
      'Fin de test pas encore confirmée par le serveur. Nous réessayons automatiquement — garde une connexion et rouvre l\'app si besoin.';

  @override
  String get completionRejectedNotice =>
      'Cette passation n\'a pas pu être validée : elle a été jugée trop courte. Elle ne compte pas pour la mission de parrainage.';

  @override
  String get ctSubtestExitPause => 'Mettre en pause';

  @override
  String get vocabTestName => 'Vocabulaire';

  @override
  String get vocabEyebrow => 'COMPRÉHENSION VERBALE';

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
      '3 items passés d\'affilée — exercice terminé.';

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
  String get weGateCta => 'Voir le programme du jour';

  @override
  String get weHubEyebrow => 'Pendant l\'attente';

  @override
  String weHubTitle(int day) {
    return 'Jour $day';
  }

  @override
  String get weHubTitleDone => 'Programme terminé';

  @override
  String get weHubIntro =>
      'Chaque jour, une part de tes résultats se dévoile, avec une activité facultative. Rien ici n\'accélère le déblocage : seul le temps débloque.';

  @override
  String get weTodayTag => 'Aujourd\'hui';

  @override
  String get wePastTag => 'À rattraper';

  @override
  String weLockedTag(int day) {
    return 'S\'ouvre au jour $day';
  }

  @override
  String get wePlaceholderTitle => 'En préparation';

  @override
  String get wePlaceholderBody =>
      'Le contenu de cette journée arrive dans une prochaine mise à jour.';

  @override
  String get weAnnouncedTag => 'Test du jour — avec ton résultat';

  @override
  String get weContributionTag =>
      'Contribution — aide-nous à construire notre test';

  @override
  String get weShareTag => 'Récompense finale';

  @override
  String get weDay1Title => 'Ta personnalité';

  @override
  String get weDay2Title => 'Construis notre test de lecture';

  @override
  String get weDay3Title => 'Ton équilibre';

  @override
  String get weDay4Title => 'Construis notre test d\'attention (1/2)';

  @override
  String get weDay5Title => 'Construis notre test d\'attention (2/2)';

  @override
  String get weDay6Title => 'Ton énergie';

  @override
  String get weDay7Title => 'Profil autisme';

  @override
  String get weDay8Title => 'Ton QI global';

  @override
  String get weRevealVci => 'Ton indice verbal';

  @override
  String get weRevealPsi => 'Ta vitesse de traitement';

  @override
  String get weRevealWmi => 'Ta mémoire de travail';

  @override
  String get weRevealFri => 'Ton raisonnement';

  @override
  String get weRevealVsi => 'Ton indice spatial';

  @override
  String get weRevealStrengths => 'Tes forces et tes faiblesses';

  @override
  String get weRevealFullIq => 'Ton QI global';

  @override
  String get weGameStroop => 'Jeu : Stroop';

  @override
  String get weGameDelayChoice => 'Jeu : tolérance au délai';

  @override
  String get weGameTimeEstimation => 'Jeu : estimation du temps';

  @override
  String get weGameConfidence => 'Jeu : calibration de la confiance';

  @override
  String get weRunnerNext => 'Suivant';

  @override
  String get weRunnerFinish => 'Terminer';

  @override
  String get weRunnerBack => 'Précédent';

  @override
  String get weRunnerScoredLabel => 'Test du jour';

  @override
  String get weRunnerContributionLabel => 'Contribution';

  @override
  String get weRunnerResumed => 'Tu reprends là où tu t\'étais arrêté.';

  @override
  String get weRunnerNoScoreNotice =>
      'Ces questions ne calculent aucun score pour toi : elles servent à construire l\'outil pour les suivants.';

  @override
  String get weRunnerQuitTitle => 'Quitter le questionnaire ?';

  @override
  String get weRunnerQuitBody =>
      'Tes réponses sont enregistrées. Tu pourras reprendre à la question où tu t\'arrêtes.';

  @override
  String get weRunnerQuitStay => 'Continuer';

  @override
  String get weRunnerQuitLeave => 'Quitter';

  @override
  String get weRunnerTransitionCta => 'Continuer';

  @override
  String get weRunnerDoneTitle => 'C\'est terminé';

  @override
  String get weRunnerDoneBody => 'Merci — tes réponses sont enregistrées.';

  @override
  String get weRunnerDoneContributionBody =>
      'Merci — tes réponses vont servir à construire notre test. Aucun score n\'est calculé pour toi.';

  @override
  String get weRunnerDoneCta => 'Revenir au programme';

  @override
  String get weRvEyebrow => 'Ta révélation du jour';

  @override
  String get weRvContinue => 'Continuer';

  @override
  String get weRvBackToHub => 'Revenir au programme';

  @override
  String get weRvScoreLabel => 'SCORE';

  @override
  String weRvCi(int low, int high) {
    return 'Intervalle de confiance à 95 % · $low – $high';
  }

  @override
  String get weRvCaveat =>
      'Un indice est une mesure, avec sa marge d\'erreur — pas un verdict. Repasser la même évaluation ne redonnerait pas exactement le même nombre.';

  @override
  String get weRvUnavailableTitle => 'Aucune évaluation à révéler';

  @override
  String get weRvUnavailableBody =>
      'Aucune évaluation terminée n\'est rattachée à ce passe sur cet appareil. Rien n\'est perdu : la révélation s\'affichera dès que tes résultats seront de nouveau lisibles ici.';

  @override
  String get weRvMissingTitle => 'Cet indice n\'a pas été calculé';

  @override
  String get weRvMissingBody =>
      'Ton évaluation enregistrée ne contient pas cet indice — il y manquait un sous-test. Les autres révélations restent disponibles.';

  @override
  String get weRvVciBody =>
      'Ce que tu sais des mots et des idées, et ta façon de les relier : définir, expliquer, retrouver ce qui rapproche deux notions. C\'est la part du profil qui bouge le moins avec les années.';

  @override
  String get weRvVsiBody =>
      'Ta façon de manipuler les formes et l\'espace : reconstruire un motif, voir comment des pièces s\'assemblent avant même de les avoir posées.';

  @override
  String get weRvFriBody =>
      'Ta façon de trouver une règle que personne ne t\'a donnée, à partir de ce que tu observes. C\'est le raisonnement qui ne doit rien à ce que tu as appris.';

  @override
  String get weRvWmiBody =>
      'Ce que tu peux garder en tête ET manipuler en même temps : retenir une suite tout en la réorganisant. C\'est l\'indice le plus sensible à la fatigue et au stress.';

  @override
  String get weRvPsiBody =>
      'La vitesse à laquelle tu traites une information simple sans te tromper. Ce n\'est pas « penser vite » : c\'est un débit, et il se paie en attention.';

  @override
  String get weRvStrengthsTitle => 'Tes forces et tes points de vigilance';

  @override
  String get weRvStrengthsIntro =>
      'Aujourd\'hui, les cinq indices se comparent entre eux. Une force n\'est pas un talent absolu : c\'est ce qui dépasse ton propre niveau moyen de plus de 10 points.';

  @override
  String get weRvStrengthsNone =>
      'Aucun indice ne s\'écarte de plus de 10 points de ton niveau moyen : ton profil est régulier, et c\'est un résultat en soi.';

  @override
  String get weRvFullIqLabel => 'QI global';

  @override
  String get weRvFullIqBody =>
      'Le QI global résume les cinq indices en un seul nombre. Quand ils s\'écartent beaucoup les uns des autres, ce résumé perd de son sens : c\'est alors le détail qui te décrit, pas le total.';

  @override
  String get weRvEstimateTitle => 'TON ESTIMATION FACE À LA MESURE';

  @override
  String weRvEstimateLine(int estimate, int measured) {
    return 'Tu t\'estimais à $estimate. La mesure donne $measured.';
  }

  @override
  String weRvEstimateOver(int points) {
    return 'Soit $points points au-dessus de la mesure.';
  }

  @override
  String weRvEstimateUnder(int points) {
    return 'Soit $points points en dessous de la mesure.';
  }

  @override
  String get weRvEstimateClose =>
      'Moins de 5 points d\'écart : ton estimation et la mesure disent la même chose.';

  @override
  String get weRvEstimateMissing =>
      'Tu n\'avais pas donné d\'estimation — il n\'y a rien à confronter.';

  @override
  String get weRvSelfEyebrow => 'Avant toute révélation';

  @override
  String get weRvSelfTitle => 'À combien estimes-tu ton QI ?';

  @override
  String get weRvSelfBody =>
      'Une seule question, posée maintenant : après une première révélation, ta réponse serait influencée par le chiffre que tu viens de lire. 100 est la moyenne. Ta réponse reste sur ton téléphone et te sera rendue au jour 8.';

  @override
  String get weRvSelfHint => 'Fais glisser, ou touche − et +, pour choisir.';

  @override
  String get weRvSelfAverage => '100 est la moyenne.';

  @override
  String get weRvSelfConfirm => 'Valider mon estimation';

  @override
  String get weRvSelfDecline => 'Je préfère ne pas répondre';

  @override
  String get weRvSelfDecrease => 'Diminuer d\'un point';

  @override
  String get weRvSelfIncrease => 'Augmenter d\'un point';

  @override
  String get weDcEyebrow => 'Jeu';

  @override
  String get weDcTitle => 'Maintenant ou plus tard';

  @override
  String get weDcIntroTitle =>
      'Une somme tout de suite, ou une plus grosse plus tard';

  @override
  String get weDcIntroBody =>
      'On va te proposer vingt fois le même genre de choix : une somme disponible tout de suite, ou une somme plus grande après un délai. Tu appuies simplement sur celle que tu préfères.';

  @override
  String get weDcIntroImaginary =>
      'Ces sommes sont imaginaires. Il n\'y a rien à gagner, rien à payer et rien à recevoir : ce sont des questions, pas des offres.';

  @override
  String get weDcIntroNoRightAnswer =>
      'Il n\'y a pas de bonne réponse. Prendre l\'argent tout de suite n\'est ni mieux ni moins bien qu\'attendre.';

  @override
  String get weDcStart => 'Commencer';

  @override
  String get weDcLater => 'Plus tard';

  @override
  String get weDcProgressTag => 'Choix';

  @override
  String get weDcPrompt => 'Qu\'est-ce que tu préfères ?';

  @override
  String get weDcImaginaryTag => 'Sommes imaginaires — rien n\'est à gagner.';

  @override
  String get weDcResultTitle => 'Ta patience';

  @override
  String weDcPatienceScore(int score) {
    return '$score / 100';
  }

  @override
  String get weDcResultCaption =>
      'Plus le chiffre est haut, plus tu acceptes d\'attendre. Ce n\'est pas une note : les deux bouts de l\'échelle se valent.';

  @override
  String weDcIndifference(String delayed, String immediate) {
    return 'Attendre un mois pour $delayed revient, pour toi, à recevoir $immediate tout de suite.';
  }

  @override
  String get weDcCurveTitle => 'Ce que valait l\'attente';

  @override
  String weDcPrevious(int score) {
    return 'La dernière fois : $score / 100';
  }

  @override
  String get weDcNoBetterEnd =>
      'Ce chiffre ne dit pas si tu as bien joué. Préférer l\'argent tout de suite est un arbitrage, pas une erreur — et il change selon le moment, l\'humeur et la situation de chacun.';

  @override
  String get weDcNotClinical =>
      'C\'est un jeu, pas une mesure clinique : aucun seuil, aucun classement, rien à en conclure sur toi.';

  @override
  String get weDcIncoherentTitle =>
      'Des réponses trop dispersées pour en tirer quelque chose';

  @override
  String get weDcIncoherentBody =>
      'Tes réponses vont dans des sens opposés d\'un délai à l\'autre : une même somme y vaut plus loin qu\'elle ne vaut proche. Rien n\'a été enregistré. Rejoue quand tu veux.';

  @override
  String get weDcReplay => 'Rejouer';

  @override
  String get weDcDone => 'Terminer';

  @override
  String get weCsEyebrow => 'Avant d\'aller plus loin';

  @override
  String get weCsTitle => 'Envoyer tes réponses ?';

  @override
  String get weCsIntro =>
      'Les questions qui suivent portent sur ta santé mentale et ton neurodéveloppement. La loi protège ces réponses à part : elles ne peuvent quitter ton téléphone que si tu l\'acceptes ici, explicitement.';

  @override
  String get weCsWhatTitle => 'Ce qui part';

  @override
  String get weCsWhat =>
      'Tes réponses, telles que tu les as données. Sans ton nom, sans ton numéro, sans date ni heure précises. Jamais tes scores : ils sont calculés sur ton téléphone et y restent.';

  @override
  String get weCsPurposeTitle => 'À quoi elles servent';

  @override
  String get weCsPurpose =>
      'À construire et améliorer nos propres tests de dépistage, et à comparer ce que les gens déclarent avec ce que la batterie mesure. Ces outils font partie de ce que nous vendons — le dire est la moindre des choses.';

  @override
  String get weCsWhoTitle => 'Où elles vont';

  @override
  String get weCsWho =>
      'Sur nos serveurs, en Europe. Rangées sous ton passe anonyme, jamais sous ton nom ni ton numéro.';

  @override
  String get weCsRightsTitle => 'Tu gardes la main';

  @override
  String get weCsRights =>
      'Tu peux retirer ton accord quand tu veux : les envois suivants s\'arrêtent aussitôt. Tu peux aussi demander l\'accès à tes données ou leur effacement.';

  @override
  String get weCsOptional =>
      'C\'est facultatif, et ça ne change rien au reste : ni ton déblocage, ni tes résultats, ni les tests du programme ne dépendent de cette réponse.';

  @override
  String get weCsAccept => 'J\'accepte l\'envoi de mes réponses';

  @override
  String get weCsDecline => 'Non, garder mes réponses ici';

  @override
  String get weDxDeclinedTitle => 'Rien ne partira';

  @override
  String get weDxDeclinedBody =>
      'Ces questions ne servent qu\'à nos travaux : sans ton accord, on ne te les pose pas. Tu peux revenir quand tu veux — ça ne change rien au reste du programme.';

  @override
  String get weDxEyebrow => 'Posé une seule fois';

  @override
  String get weDxListTitle => 'Ton parcours';

  @override
  String get weDxListQuestion =>
      'As-tu reçu un diagnostic — ou penses-tu être concerné — pour l\'un de ces troubles ?';

  @override
  String get weDxListBody =>
      'Ces réponses ne changent rien à tes résultats. Elles servent à construire nos outils : sans savoir qui est concerné, il est impossible de repérer les questions qui distinguent vraiment quelque chose.';

  @override
  String get weDxListHint => 'Coche tout ce qui s\'applique.';

  @override
  String get weDxAdhd => 'TDAH';

  @override
  String get weDxAutism => 'Autisme / TSA';

  @override
  String get weDxDyslexia => 'Dyslexie';

  @override
  String get weDxDyspraxia => 'Dyspraxie';

  @override
  String get weDxDyscalculia => 'Dyscalculie';

  @override
  String get weDxHpi => 'Haut potentiel (HPI)';

  @override
  String get weDxDepression => 'Dépression';

  @override
  String get weDxAnxiety => 'Trouble anxieux';

  @override
  String get weDxBipolar => 'Bipolarité';

  @override
  String get weDxOcd => 'TOC';

  @override
  String get weDxSleep => 'Trouble du sommeil';

  @override
  String get weDxBurnout => 'Burn-out';

  @override
  String get weDxOther => 'Un autre trouble';

  @override
  String get weDxNone => 'Aucun';

  @override
  String get weDxPreferNotToSay => 'Je préfère ne pas répondre';

  @override
  String get weDxDetailTitle => 'Le détail';

  @override
  String weDxDetailProgress(int current, int total) {
    return '$current sur $total';
  }

  @override
  String get weDxSourceQuestion => 'Qui l\'a posé ?';

  @override
  String get weDxSourcePsychiatrist => 'Psychiatre ou neuropsychologue';

  @override
  String get weDxSourceGp => 'Médecin généraliste';

  @override
  String get weDxSourcePsychologist => 'Psychologue';

  @override
  String get weDxSourceSelf => 'Personne — je le pense, sans diagnostic';

  @override
  String get weDxWhenQuestion => 'C\'était il y a combien de temps ?';

  @override
  String get weDxWhenUnder1 => 'Moins d\'un an';

  @override
  String get weDxWhen1to3 => 'Entre 1 et 3 ans';

  @override
  String get weDxWhen3to10 => 'Entre 3 et 10 ans';

  @override
  String get weDxWhenOver10 => 'Plus de 10 ans';

  @override
  String get weDxWhenUnknown => 'Je ne sais plus';

  @override
  String get weDxTreatmentQuestion => 'Un traitement ou un suivi ?';

  @override
  String get weDxTreatmentYes => 'Oui, en ce moment';

  @override
  String get weDxTreatmentNo => 'Non';

  @override
  String get weDxTreatmentPast => 'Par le passé';

  @override
  String get weDxAssessmentQuestion => 'Un bilan complet a-t-il été fait ?';

  @override
  String get weDxAssessmentYes => 'Oui';

  @override
  String get weDxAssessmentNo => 'Non';

  @override
  String get weDxAssessmentUnknown => 'Je ne sais pas';

  @override
  String get weDxDoneTitle => 'C\'est noté';

  @override
  String get weDxDoneBody =>
      'Merci. Cette question ne te sera plus posée — elle ne se pose qu\'une fois. Elle ne change rien à tes résultats ni à ton déblocage.';

  @override
  String get weDxAlreadyTitle => 'Déjà répondu';

  @override
  String get weDxAlreadyBody =>
      'Tu as déjà rempli cette partie. Elle ne se pose qu\'une fois, pour que ta réponse ne soit pas influencée par les tests des jours suivants.';

  @override
  String get weDxFailedTitle => 'Rien n\'a pu être enregistré';

  @override
  String get weDxFailedBody =>
      'Tes réponses n\'ont pas été conservées, et rien n\'a été envoyé. Tu peux réessayer depuis le programme — la question reste ouverte.';

  @override
  String get weDxQuitTitle => 'Quitter maintenant ?';

  @override
  String get weDxQuitBody =>
      'Ce que tu as coché ne sera pas conservé : ce bloc s\'enregistre en une seule fois, à la fin. Tu pourras le reprendre depuis le programme.';

  @override
  String get weGameCardSubtitle => 'Jeu du jour · 2 minutes · rejouable';

  @override
  String get weStroopEyebrow => 'Jeu';

  @override
  String get weStroopTitle => 'Couleurs contrariées';

  @override
  String get weStroopIntroTitle => 'Nomme la couleur, pas le mot';

  @override
  String get weStroopIntroBody =>
      'Un mot va s\'afficher dans une certaine couleur. Appuie sur la couleur de l\'ENCRE, pas sur ce qui est écrit. Lire est automatique : c\'est justement ce qu\'il va falloir mettre de côté.';

  @override
  String get weStroopIntroPractice =>
      'On commence par trois essais pour rien, le temps de prendre la main.';

  @override
  String get weStroopIntroExample =>
      'Ici, le mot dit une couleur et l\'encre en dit une autre : c\'est l\'encre qui compte.';

  @override
  String get weStroopStart => 'Commencer';

  @override
  String get weStroopLater => 'Plus tard';

  @override
  String get weStroopPracticeTag => 'Entraînement';

  @override
  String get weStroopScoredTag => 'Compté';

  @override
  String get weStroopPrompt => 'De quelle couleur est-ce écrit ?';

  @override
  String get weStroopBlockScoredTitle => 'C\'est parti';

  @override
  String get weStroopBlockScoredBody =>
      'À partir de maintenant, les essais comptent. Va vite, mais vise juste : une erreur ne rapporte rien.';

  @override
  String get weStroopBlockConflictTitle =>
      'Maintenant, les mots te contredisent';

  @override
  String get weStroopBlockConflictBody =>
      'La consigne ne change pas : c\'est toujours la couleur de l\'encre. Les mots vont simplement dire autre chose.';

  @override
  String get weStroopBlockCta => 'Continuer';

  @override
  String get weStroopResultTitle => 'Ton écart';

  @override
  String weStroopMilliseconds(int ms) {
    return '$ms ms';
  }

  @override
  String get weStroopResultCaption =>
      'C\'est le temps supplémentaire qu\'il t\'a fallu, à chaque essai, quand le mot disait le contraire de l\'encre.';

  @override
  String weStroopAccuracy(int correct, int total) {
    return '$correct bonnes réponses sur $total';
  }

  @override
  String weStroopBest(int ms) {
    return 'Ton meilleur écart : $ms ms';
  }

  @override
  String get weStroopNewBest => 'Nouveau meilleur écart';

  @override
  String get weStroopNotSpeed =>
      'Ce chiffre n\'est pas ta vitesse. C\'est la différence entre deux séries : quelqu\'un de globalement plus lent peut très bien avoir un écart plus petit.';

  @override
  String get weStroopNotClinical =>
      'C\'est un jeu, pas une mesure clinique : aucun seuil, aucun classement, rien à en conclure sur toi.';

  @override
  String get weStroopUnreliableTitle => 'Trop peu de réponses pour compter';

  @override
  String get weStroopUnreliableBody =>
      'Il n\'y a pas assez de réponses justes et données dans les temps pour calculer un écart honnête. Ton meilleur écart précédent reste intact. Rejoue quand tu veux.';

  @override
  String get weStroopReplay => 'Rejouer';

  @override
  String get weStroopDone => 'Terminer';

  @override
  String get weTeEyebrow => 'Jeu';

  @override
  String get weTeTitle => 'Le plus long des deux';

  @override
  String get weTeIntroTitle => 'Deux panneaux, l\'un après l\'autre';

  @override
  String get weTeIntroBody =>
      'Un panneau va s\'allumer, s\'éteindre, puis s\'allumer une seconde fois. Dis lequel des deux est resté allumé le plus longtemps. Les écarts se resserrent au fil de la partie.';

  @override
  String get weTeIntroTooShortToCount =>
      'Les durées sont de l\'ordre de la seconde : trop courtes pour être comptées. C\'est ta perception seule qui répond.';

  @override
  String get weTeIntroExample =>
      'C\'est ce panneau qui s\'allumera. Rien d\'autre ne bougera à l\'écran.';

  @override
  String get weTeStart => 'Commencer';

  @override
  String get weTeLater => 'Plus tard';

  @override
  String get weTeProgressTag => 'Essai';

  @override
  String get weTeWatch => 'Regarde bien…';

  @override
  String get weTePrompt => 'Lequel est resté allumé le plus longtemps ?';

  @override
  String get weTeFirst => 'Le premier';

  @override
  String get weTeSecond => 'Le second';

  @override
  String get weTeResultTitle => 'Ta finesse';

  @override
  String weTeThreshold(int percent) {
    return '$percent %';
  }

  @override
  String get weTeResultCaption =>
      'C\'est l\'écart le plus fin que tu distingues encore entre deux durées. Plus le chiffre est petit, plus ta perception sépare finement deux instants proches.';

  @override
  String weTeAccuracyNote(int percent) {
    return '$percent % de bonnes réponses — c\'est normal : le jeu resserre les écarts jusqu\'à te faire hésiter.';
  }

  @override
  String weTeBest(int percent) {
    return 'Ta meilleure finesse : $percent %';
  }

  @override
  String get weTeNewBest => 'Nouvelle meilleure finesse';

  @override
  String get weTeNotSpeed =>
      'Ce chiffre n\'est pas ta vitesse : rien n\'a chronométré tes réponses, tu pouvais prendre tout ton temps pour décider.';

  @override
  String get weTeNotClinical =>
      'C\'est un jeu, pas une mesure clinique : aucun seuil, aucun classement, rien à en conclure sur toi.';

  @override
  String get weTeUnreliableTitle => 'Pas de quoi mesurer une finesse';

  @override
  String get weTeUnreliableBody =>
      'La partie n\'a pas assez hésité pour qu\'un seuil veuille dire quelque chose. Ta meilleure finesse précédente reste intacte. Rejoue quand tu veux.';

  @override
  String get weTeReplay => 'Rejouer';

  @override
  String get weTeDone => 'Terminer';
}
