// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Mental E.T.';

  @override
  String get languageSwitcherTooltip => 'Change language';

  @override
  String get commonValidate => 'Confirm';

  @override
  String get commonNext => 'Next';

  @override
  String get commonBack => 'Back';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonStart => 'Start';

  @override
  String get commonSkip => 'Skip';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonClose => 'Close';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonLoading => 'Loading...';

  @override
  String get commonError => 'An error occurred';

  @override
  String get commonYes => 'Yes';

  @override
  String get commonNo => 'No';

  @override
  String get commonOk => 'OK';

  @override
  String get commonFinish => 'Finish';

  @override
  String commonSeconds(int count) {
    return '$count s';
  }

  @override
  String get oralConsentRequiredCheckbox =>
      'I allow my voice to be recorded and analyzed for the duration of this test. (required)';

  @override
  String get oralConsentCommercialCheckbox =>
      'I also allow my recordings to be reused, in anonymized form, for research and commercial purposes — including transfer to third parties. (optional)';

  @override
  String get oralConsentRequiredHint => 'Tick the first box to start the test.';

  @override
  String get oralConsentPrivacyLink => 'Read the privacy policy';

  @override
  String get matDiscontinue3 => '3 consecutive failures — exercise ended.';

  @override
  String get assessIntroTitle => 'New assessment';

  @override
  String get assessIntroEyebrow => 'COGNITIVE ASSESSMENT';

  @override
  String get assessIntroHero1 => 'Five indices,';

  @override
  String get assessIntroHero2 => 'one measure.';

  @override
  String get assessIntroDescription =>
      'This assessment explores your cognitive abilities across six domains of the CHC (Cattell-Horn-Carroll) model. A full-scale score is its synthesis.';

  @override
  String get assessDomainsHeader => 'DOMAINS MEASURED';

  @override
  String get assessDomainVci => 'Verbal Comprehension';

  @override
  String get assessDomainVsi => 'Visual-Spatial Reasoning';

  @override
  String get assessDomainFri => 'Fluid Reasoning';

  @override
  String get assessDomainWmi => 'Working Memory';

  @override
  String get assessDomainPsi => 'Processing Speed';

  @override
  String get assessDomainLo => 'Oral Language';

  @override
  String get assessBeforeStartHeader => 'BEFORE YOU START';

  @override
  String get assessBeforeStartBody =>
      'Estimated duration 60 to 90 minutes. Quiet and focus required.';

  @override
  String get assessLaunchFullAssessment => 'Start the full assessment';

  @override
  String get assessOrIndividualSubtest => 'OR INDIVIDUAL SUBTEST';

  @override
  String get assessSubtestCubes => 'Blocks';

  @override
  String get assessSubtestMatrices => 'Matrix Reasoning';

  @override
  String get assessSubtestFigureWeights => 'Equilibrium';

  @override
  String get assessSubtestVisualPuzzles => 'Assembly';

  @override
  String get assessSubtestSimilarities => 'Common Ground';

  @override
  String get assessSubtestVocabulary => 'Vocabulary';

  @override
  String get assessSubtestInformation => 'Information';

  @override
  String get assessSubtestDigitSpan => 'Digit Sequences';

  @override
  String get assessSubtestArithmetic => 'Arithmetic';

  @override
  String get assessSubtestPictureSpan => 'Picture Span';

  @override
  String get assessSubtestCoding => 'Transcription';

  @override
  String get assessSubtestSymbolSearch => 'Symbol Detection';

  @override
  String get assessSubtestOralComprehension => 'Oral Comprehension';

  @override
  String get authLoginTitle => 'Sign in';

  @override
  String get authCreateAccount => 'Create account';

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authHeaderSubtitleRegister =>
      'Create an account to save your results';

  @override
  String get authHeaderSubtitleLogin => 'Sign in to access your history';

  @override
  String get authEmailLabel => 'Email address';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authFieldRequired => 'Required field';

  @override
  String get authEmailInvalid => 'Invalid email address';

  @override
  String get authPasswordMinLength => 'Minimum 8 characters';

  @override
  String get authOrDivider => 'or';

  @override
  String get authContinueWithGoogle => 'Continue with Google';

  @override
  String get authToggleToLogin => 'Already have an account? Sign in';

  @override
  String get authToggleToRegister => 'No account yet? Sign up';

  @override
  String get authFirebaseNotConfiguredFull =>
      'Firebase is not configured yet. Follow the instructions in firebase_config.dart.';

  @override
  String get authFirebaseNotConfigured => 'Firebase is not configured yet.';

  @override
  String get histTitle => 'My results';

  @override
  String get histEyebrow => 'HISTORY';

  @override
  String get histDeleteResultTitle => 'Delete this result?';

  @override
  String get histDeleteResultBody => 'This action cannot be undone.';

  @override
  String get histDelete => 'Delete';

  @override
  String histAgeYears(int age) {
    return '$age yrs';
  }

  @override
  String get histScoreFsiq => 'Full Scale IQ';

  @override
  String get histScoreShortIq => 'IQ';

  @override
  String get histScoreVci => 'Verbal Comprehension';

  @override
  String get histScoreVsi => 'Visual-Spatial';

  @override
  String get histScoreFri => 'Fluid Reasoning';

  @override
  String get histScoreWmi => 'Working Memory';

  @override
  String get histScorePsi => 'Processing Speed';

  @override
  String get histEmptyEyebrow => 'NO RESULTS';

  @override
  String get histEmptyHero1 => 'Your history';

  @override
  String get histEmptyHero2 => 'awaits you.';

  @override
  String get histEmptyDescription =>
      'Complete your first assessment to see your results appear here.';

  @override
  String get histStartAssessment => 'Start an assessment';

  @override
  String get ctIntroTitle => 'Full test';

  @override
  String get ctIntroHero1 => 'Twelve subtests,';

  @override
  String get ctIntroHero2 => 'four indices.';

  @override
  String get ctIntroDescription =>
      'Complete standardized cognitive assessment. The subtests run one after another automatically.';

  @override
  String get ctIntroDurationEyebrow => 'DURATION';

  @override
  String get ctIntroDurationTitle => '60 to 90 minutes';

  @override
  String get ctIntroDurationBody => 'Set aside a continuous block of time.';

  @override
  String get ctIntroContentEyebrow => 'CONTENT';

  @override
  String get ctIntroContentTitle => '13 subtests included';

  @override
  String get ctIntroContentBody =>
      'Blocks · Common Ground · Digit Sequences · Matrices · Vocabulary · Arithmetic · Symbols · Assembly · Information · Transcription · Pictures · Equilibrium · Oral language.';

  @override
  String get ctIntroImportantEyebrow => 'IMPORTANT';

  @override
  String get ctIntroImportantTitle => 'Automatic sequence';

  @override
  String get ctIntroImportantBody =>
      'The tests will launch one after another. Make sure you have enough time.';

  @override
  String get ctPatientAgeHeader => 'YOUR AGE';

  @override
  String get ctPatientAgeHint => 'Required for norms (16 to 90 years)';

  @override
  String get ctAgeSuffix => 'YRS';

  @override
  String get ctAgeRangeError => 'Age between 16 and 90 years';

  @override
  String get ctLaunchFullTest => 'Start the full test';

  @override
  String get ctRunningTitle => 'Test in progress';

  @override
  String get ctGlobalProgress => 'OVERALL PROGRESS';

  @override
  String get ctNextSubtest => 'NEXT SUBTEST';

  @override
  String get ctLaunching => 'Launching…';

  @override
  String get ctComputingResultsTitle => 'Computing results';

  @override
  String get ctComputingResultsEyebrow => 'ASSESSMENT';

  @override
  String get ctProcessing => 'PROCESSING';

  @override
  String ctTestNotFound(String testName) {
    return 'Test not found: $testName';
  }

  @override
  String get ctTestCubes => 'Blocks';

  @override
  String get ctTestSimilarities => 'Common Ground';

  @override
  String get ctTestDigitSpan => 'Digit Sequences';

  @override
  String get ctTestMatrices => 'Matrix Reasoning';

  @override
  String get ctTestVocabulary => 'Vocabulary';

  @override
  String get ctTestArithmetic => 'Arithmetic';

  @override
  String get ctTestSymbolSearch => 'Symbol Detection';

  @override
  String get ctTestVisualPuzzles => 'Assembly';

  @override
  String get ctTestInformation => 'Information';

  @override
  String get ctTestCoding => 'Transcription';

  @override
  String get ctTestPictureSpan => 'Picture Span';

  @override
  String get ctTestFigureWeights => 'Equilibrium';

  @override
  String get ctResultsTitle => 'Results';

  @override
  String get ctResultsEyebrow => 'YOUR COGNITIVE PROFILE';

  @override
  String get ctResultsHero1 => 'Assessment';

  @override
  String get ctResultsHero2 => 'complete.';

  @override
  String get ctResultsSummary =>
      'Summary of your cognitive performance across the scored exercises.';

  @override
  String ctAgeYears(int age) {
    return '$age yrs';
  }

  @override
  String get ctMetaDate => 'DATE';

  @override
  String get ctMetaDuration => 'DURATION';

  @override
  String get ctMetaSubtests => 'SUBTESTS';

  @override
  String get ctMetaAge => 'AGE';

  @override
  String get ctFsiqCardLabel => 'OVERALL SCORE';

  @override
  String ctConfidenceInterval95(int lower, int upper) {
    return '95% CI · $lower – $upper';
  }

  @override
  String ctPercentileLabel(int rank) {
    return 'Percentile · $rank';
  }

  @override
  String get ctIndexProfileHeader => 'INDEX PROFILE';

  @override
  String get ctIndexVci => 'Verbal Comprehension';

  @override
  String get ctIndexVsi => 'Visual-Spatial';

  @override
  String get ctIndexFri => 'Fluid Reasoning';

  @override
  String get ctIndexWmi => 'Working Memory';

  @override
  String get ctIndexPsi => 'Processing Speed';

  @override
  String ctIndexCiPercentile(int lower, int upper, int rank) {
    return 'CI $lower–$upper · ${rank}th %ile';
  }

  @override
  String ctIndexPercentile(int rank) {
    return '${rank}th %ile';
  }

  @override
  String get ctStandardizedScoresHeader => 'STANDARDIZED SCORES';

  @override
  String get ctGroupVciVerbal => 'Verbal Comprehension';

  @override
  String get ctGroupVsiVisuoSpatial => 'Visual-Spatial';

  @override
  String get ctGroupFriReasoning => 'Fluid Reasoning';

  @override
  String get ctGroupWmiMemory => 'Working Memory';

  @override
  String get ctGroupPsiSpeed => 'Processing Speed';

  @override
  String ctRawScore(int raw) {
    return 'raw $raw';
  }

  @override
  String get ctCognitiveProfileHeader => 'COGNITIVE PROFILE';

  @override
  String get ctProfileHomogeneous =>
      'Homogeneous profile — the indices are consistent with one another.';

  @override
  String get ctProfileHeterogeneous =>
      'Heterogeneous profile — notable disparities between indices.';

  @override
  String ctMaxDiscrepancy(int points) {
    return 'Max discrepancy · $points pts';
  }

  @override
  String get ctRelativeStrengths => 'Relative strengths';

  @override
  String get ctVigilancePoints => 'Points of vigilance';

  @override
  String get ctIndicativeDisclaimer =>
      'Indicative results. For an official clinical evaluation, consult a neuropsychologist or a qualified psychologist.';

  @override
  String get ctRawScoresHeader => 'RAW SCORES';

  @override
  String get ctMissingAgeHeader => 'AGE MISSING';

  @override
  String get ctMissingAgeBody =>
      'Without your age, only raw scores are shown. Run the test again with the age provided to obtain the standardized IQ, percentiles, and confidence intervals.';

  @override
  String get ctExportPdf => 'Export to PDF';

  @override
  String ctPdfError(String error) {
    return 'PDF error: $error';
  }

  @override
  String get ctBackToHome => 'Back to home';

  @override
  String get ctPdfSubtitle => 'Cognitive profile report';

  @override
  String get ctPdfNotProvided => 'Not provided';

  @override
  String ctPdfDurationMinSec(int min, int sec) {
    return '$min min $sec sec';
  }

  @override
  String get ctPdfAge => 'Age';

  @override
  String get ctPdfDuration => 'Duration';

  @override
  String get ctPdfDate => 'Date';

  @override
  String get ctPdfFsiqLabel => 'OVERALL SCORE';

  @override
  String get ctPdfConfidenceInterval95 => '95% confidence interval';

  @override
  String get ctPdfPercentile => 'Percentile';

  @override
  String ctPercentileValue(int rank) {
    return '${rank}th';
  }

  @override
  String get ctPdfIndexProfileHeader => 'COGNITIVE INDEX PROFILE';

  @override
  String get ctPdfIndexVci => 'Verbal Comprehension';

  @override
  String get ctPdfIndexVsi => 'Visual-Spatial';

  @override
  String get ctPdfIndexFri => 'Fluid Reasoning';

  @override
  String get ctPdfIndexWmi => 'Working Memory';

  @override
  String get ctPdfIndexPsi => 'Processing Speed';

  @override
  String get ctPdfColIndex => 'Index';

  @override
  String get ctPdfColScore => 'Score';

  @override
  String get ctPdfColClassification => 'Classification';

  @override
  String get ctPdfRawScoresHeader => 'SUBTEST RAW SCORES';

  @override
  String get ctPdfColSubtest => 'Subtest';

  @override
  String get ctPdfColRawScore => 'Raw score';

  @override
  String get ctPdfDisclaimer =>
      'DISCLAIMER: This report is generated by an assessment-support application and does not constitute an official clinical diagnosis. It must be interpreted by a qualified health professional. Do not use for medical or legal purposes without additional professional evaluation.';

  @override
  String get ctResumeFullTest => 'Resume the assessment';

  @override
  String get chatEyebrow => 'AI ASSISTANT';

  @override
  String get chatNewConversation => 'New conversation';

  @override
  String get chatAssistantLabel => 'MENTAL E.T.';

  @override
  String get chatUserLabel => 'YOU';

  @override
  String get chatHeroTitle1 => 'Ask';

  @override
  String get chatHeroTitle2 => 'your questions.';

  @override
  String get chatEmptyIntro =>
      'The Mental E.T. AI helps you better understand your cognitive profile. Confidential conversations, non-directive support.';

  @override
  String get chatThinking => 'Thinking…';

  @override
  String get chatInputHint => 'Write a message…';

  @override
  String get chatTimeJustNow => 'just now';

  @override
  String chatTimeMinutes(int count) {
    return '$count min';
  }

  @override
  String chatTimeHours(int count) {
    return '${count}h';
  }

  @override
  String get chatErrorMessage => 'Sorry, an error occurred. Please try again.';

  @override
  String get chatErrorEmptyResponse => 'Empty response from the worker';

  @override
  String get chatErrorAccessDenied =>
      'Access denied by the worker (origin not allowed).';

  @override
  String get chatErrorRateLimit =>
      'Rate limit reached. Please try again shortly.';

  @override
  String chatErrorServer(int code) {
    return 'Server error ($code)';
  }

  @override
  String chatErrorHttp(int code, String body) {
    return 'Error $code: $body';
  }

  @override
  String get coreSplashTitleLine1 => 'Cognitive';

  @override
  String get coreSplashTitleLine2 => 'assessment';

  @override
  String get commonNotAvailable => 'N/A';

  @override
  String get pdfFilenameBase => 'mentality_results';

  @override
  String coreRouteNotFound(String path) {
    return 'Page not found: $path';
  }

  @override
  String get homeHeroTitle => 'Discover';

  @override
  String get homeHeroTitleItalic => 'your cognitive profile.';

  @override
  String get homeHeroBody =>
      'An adaptive cognitive assessment. 13 subtests, 5 indices, one global score.';

  @override
  String get homeActionStartTitle => 'Start an assessment';

  @override
  String get homeActionStartSubtitle => 'Duration: 60 – 90 minutes';

  @override
  String get homeActionResultsTitle => 'My results';

  @override
  String get homeActionResultsSubtitle => 'Assessment history';

  @override
  String get homeActionChatTitle => 'Talk with Mental E.T.';

  @override
  String get homeActionChatSubtitle => 'AI assistant, psychology questions';

  @override
  String get homeComingSoon => 'COMING SOON';

  @override
  String get homeAboutEyebrow => 'ABOUT';

  @override
  String get homeAboutSubtestsTitle => '13 subtests';

  @override
  String get homeAboutSubtestsBody =>
      'A complete assessment of the five CHC cognitive indices.';

  @override
  String get homeAboutAdaptiveTitle => 'Adaptive AI';

  @override
  String get homeAboutAdaptiveBody =>
      'Difficulty adjusted in real time through IRT inference.';

  @override
  String get homeAboutValidationTitle => 'Theoretical framework';

  @override
  String get homeAboutValidationBody =>
      'Original items, written for Mental E.T. and built on the CHC model.';

  @override
  String get homeResumeEyebrow => 'TEST IN PROGRESS';

  @override
  String get homeResumeTitle => 'Resume your assessment';

  @override
  String get homeResumeButton => 'Resume';

  @override
  String get homeLogoutTitle => 'Sign out?';

  @override
  String get homeLogoutBody =>
      'Your token will be removed from this device. Make sure you have saved it: without it, you won\'t be able to reconnect to your data.';

  @override
  String get homeLogoutConfirm => 'Sign out';

  @override
  String homeResumeProgress(int done, int total) {
    return '$done of $total exercises';
  }

  @override
  String homeResumeNext(String name) {
    return 'Next: $name';
  }

  @override
  String get homeResumeFinish =>
      'All exercises are done — only the wrap-up remains.';

  @override
  String get homeResumeRestart => 'Start over';

  @override
  String get homeResumeRestartTitle => 'Start over from the beginning?';

  @override
  String get homeResumeRestartBody =>
      'The exercises you have already taken will be discarded and cannot be resumed. This cannot be undone.';

  @override
  String homeResumeCurrent(String name) {
    return 'In progress: $name';
  }

  @override
  String get infoTestName => 'Information';

  @override
  String get infoEyebrow => 'VERBAL COMPREHENSION';

  @override
  String infoTrailingStatus(int seconds, int score, int attempted) {
    return '${seconds}s · $score/$attempted';
  }

  @override
  String get infoCorrect => 'Correct!';

  @override
  String get infoIncorrect => 'Incorrect';

  @override
  String get infoFeedbackRight => 'Correct answer! +1 point';

  @override
  String get infoFeedbackWrong => 'Wrong answer. 0 points';

  @override
  String infoQuestionLabel(String question) {
    return 'Question: $question';
  }

  @override
  String infoCorrectAnswerLabel(String answer) {
    return 'Correct answer: $answer';
  }

  @override
  String infoTimeLabel(int seconds) {
    return 'Time: ${seconds}s';
  }

  @override
  String infoScoreLabel(int score, int attempted) {
    return 'Score: $score/$attempted';
  }

  @override
  String infoDomainLabel(String domain) {
    return 'Domain: $domain';
  }

  @override
  String get infoDiscontinue3 => '3 consecutive failures — exercise ended.';

  @override
  String get infoSeeResults => 'See results';

  @override
  String get infoResultsTitle => 'Information Test - Results';

  @override
  String infoRawScore(int score, int max) {
    return 'Raw score: $score/$max points';
  }

  @override
  String infoItemsCompleted(int completed, int total) {
    return 'Items completed: $completed/$total';
  }

  @override
  String infoPercentage(int percent) {
    return 'Percentage: $percent%';
  }

  @override
  String infoTotalTime(int seconds) {
    return 'Total time: ${seconds}s';
  }

  @override
  String get infoTestSubtitle => 'Test of acquired general knowledge';

  @override
  String get infoDomainBreakdownTitle => 'Breakdown by domain:';

  @override
  String infoDomainBreakdownRow(String domain, int correct, int total) {
    return '$domain: $correct/$total';
  }

  @override
  String get infoPerfExceptional => 'Exceptional performance (θ > +2.0)';

  @override
  String get infoPerfSuperior => 'Superior performance (θ > +1.0)';

  @override
  String get infoPerfAverage => 'Average performance (θ ≈ 0)';

  @override
  String get infoPerfBelow => 'Below-average performance (θ < 0)';

  @override
  String get infoPerfLow => 'Low performance (θ < -1.0)';

  @override
  String get infoDomainScience => 'Natural sciences';

  @override
  String get infoDomainHistoryGeography => 'History/Geography';

  @override
  String get infoDomainGeneralCulture => 'General knowledge';

  @override
  String get infoDomainMathLogic => 'Mathematics/Logic';

  @override
  String get infoDomainArtsLiterature => 'Arts/Literature';

  @override
  String get infoDifficultyEasy => 'Easy';

  @override
  String get infoDifficultyMedium => 'Medium';

  @override
  String get infoDifficultyHard => 'Hard';

  @override
  String get arithTestName => 'Arithmetic';

  @override
  String get arithEyebrow => 'WORKING MEMORY';

  @override
  String get arithStartTest => 'Start the test';

  @override
  String get arithIntroTitle => 'Arithmetic Test';

  @override
  String get arithIntroDescription =>
      'This test measures your working memory and numerical reasoning.';

  @override
  String get arithInfoMentalTitle => 'Mental calculation only';

  @override
  String get arithInfoMentalSubtitle =>
      'Solve the problems without paper or calculator';

  @override
  String get arithInfoTimeTitle => 'Limited time';

  @override
  String get arithInfoTimeSubtitle =>
      'Each problem has a time limit (15-60 seconds)';

  @override
  String get arithInfoBonusTitle => 'Speed bonus';

  @override
  String get arithInfoBonusSubtitle =>
      'Fast answers on some items = bonus points';

  @override
  String get arithInfoRepeatTitle => 'Repeat available';

  @override
  String get arithInfoRepeatSubtitle =>
      'You can ask to repeat ONCE (timer keeps running)';

  @override
  String get arithIntroDiscontinueNote =>
      '22 problems in total. The test stops after 3 consecutive failures.';

  @override
  String arithProblemCounter(int current, int total) {
    return 'Problem $current/$total';
  }

  @override
  String get arithRepeatTitle => 'Repeat the problem';

  @override
  String get arithUnderstood => 'Got it';

  @override
  String get arithTimeUp => 'Time\'s up!';

  @override
  String arithCorrectAnswerLabel(int answer) {
    return 'Correct answer: $answer';
  }

  @override
  String get arithCorrect => 'Correct!';

  @override
  String get arithIncorrect => 'Incorrect';

  @override
  String arithTimeSpent(int seconds) {
    return 'Time: $seconds seconds';
  }

  @override
  String get arithSpeedBonus => '🎉 Speed bonus! (+1 point)';

  @override
  String get arithTestEnded => 'Test complete!';

  @override
  String arithItemsCompleted(int completed, int total) {
    return 'Items completed: $completed/$total';
  }

  @override
  String arithBaseScore(int score) {
    return 'Base score: $score points';
  }

  @override
  String arithBonusScore(int bonus) {
    return 'Speed bonus: $bonus points';
  }

  @override
  String arithTotalScore(int total) {
    return 'Total Score: $total points';
  }

  @override
  String get arithRepeat => 'Repeat';

  @override
  String get arithAnswerHint => 'Your answer';

  @override
  String get arithDifficultyEasy => 'Easy';

  @override
  String get arithDifficultyMedium => 'Medium';

  @override
  String get arithDifficultyHard => 'Hard';

  @override
  String get arithDifficultyVeryHard => 'Very hard';

  @override
  String get oralMicAccessTitle => 'Microphone access';

  @override
  String get oralReadingPermissionBody1 =>
      'This activity records your voice while you read the text aloud.';

  @override
  String get oralReadingPermissionBody2 =>
      'Your recordings will be anonymized and may contribute to improving speech recognition.';

  @override
  String get oralBrowserWillAskMic =>
      'Your browser will then ask you to allow the microphone.';

  @override
  String get oralCancel => 'Cancel';

  @override
  String get oralAllowMicrophone => 'Allow microphone';

  @override
  String get oralMicDeniedOrUnavailable => 'Microphone denied or unavailable.';

  @override
  String get oralCannotStartRecording =>
      'Unable to start recording on this browser.';

  @override
  String oralCanSkipToNextStep(String message) {
    return '$message You can move on to the next step.';
  }

  @override
  String get oralSkip => 'Skip';

  @override
  String get oralRecordingInProgress => 'Recording in progress';

  @override
  String oralKeepGoingSeconds(int seconds) {
    return 'Keep going for ${seconds}s more...';
  }

  @override
  String get oralSaving => 'Saving...';

  @override
  String get oralReadingInstructions =>
      'Read the following text aloud, clearly and at your natural pace. Press \"Start\" when you are ready.';

  @override
  String get oralStartReading => 'Start reading';

  @override
  String get oralFinish => 'Finish';

  @override
  String get oralSkipThisStep => 'Skip this step';

  @override
  String get oralSummaryPermissionBody1 =>
      'You will now record your oral summary of the text.';

  @override
  String get oralSummaryPermissionBody2 =>
      'Speak naturally, as if you were explaining the text to a friend. Take between 30 and 60 seconds.';

  @override
  String get oralStartSummary => 'Start the summary';

  @override
  String get oralSummaryInstructionLead => 'You have just read this text. ';

  @override
  String get oralSummaryInstructionBody =>
      'Summarize what you understood in your own words. Take between 30 and 60 seconds. Speak naturally, as if you were explaining it to a friend.';

  @override
  String get oralReferenceText => 'Reference text';

  @override
  String get oralFinishSummary => 'Finish the summary';

  @override
  String get oralFlowTitle => 'Audio collection';

  @override
  String get oralConsentTitle => 'Oral Comprehension Test';

  @override
  String get oralConsentRecordTitle => 'What we record';

  @override
  String get oralConsentRecordBody =>
      'Your voice while you read 5 short texts (about 1 min each) and your oral summary (about 40 seconds per text).';

  @override
  String get oralConsentAnonTitle => 'Privacy';

  @override
  String get oralConsentAnonBody =>
      'Your recordings are identified by a random session code, not by your name. They remain linkable to your account, however: they are personal data, encrypted and stored in Europe.';

  @override
  String get oralConsentUsageTitle => 'How it is used';

  @override
  String get oralConsentUsageBody =>
      'These recordings may contribute to improving speech recognition, notably for models such as Whisper or Speechmatics.';

  @override
  String get oralAcceptAndStart => 'I accept and start';

  @override
  String get oralDeclineAndGoBack => 'Decline and go back';

  @override
  String get oralWithdrawConsentNote =>
      'You can withdraw your consent at any time from the app settings.';

  @override
  String oralTextProgress(int current) {
    return 'Text $current of 5';
  }

  @override
  String get oralStepReading => 'Reading';

  @override
  String get oralStepSummary => 'Summary';

  @override
  String get oralPauseWellDone => 'Well done!';

  @override
  String get oralPauseNowSummarize => 'Now, summarize this text aloud.';

  @override
  String get oralPauseStartingIn => 'Starting in...';

  @override
  String get oralCompletedThanks => 'Thank you!';

  @override
  String get oralCompletedBody =>
      'You have completed all 5 texts.\nYour recordings will contribute to improving\nspeech recognition.';

  @override
  String get oralBackToHome => 'Back to home';

  @override
  String get oralExitDialogTitle => 'Leave?';

  @override
  String get oralExitDialogBody =>
      'A recording is in progress. If you leave now, it will not be saved.';

  @override
  String get oralContinue => 'Continue';

  @override
  String get oralQuit => 'Leave';

  @override
  String get preEyebrow => 'Before you start';

  @override
  String get preQ1Title => 'Have you ever taken an IQ test?';

  @override
  String get preQ1Body =>
      'One question, to place what you are about to measure. Your answer changes neither the test nor your score.';

  @override
  String get preQ1Professional => 'Yes, with a psychiatrist or a psychologist';

  @override
  String get preQ1Online => 'Yes, an unreliable test online';

  @override
  String get preQ1Never => 'No, never — but I have always wanted to';

  @override
  String get preLocalNotice =>
      'Your answers stay on your phone, encrypted. Nothing is sent.';

  @override
  String get prePastEyebrow => 'That earlier test';

  @override
  String get prePastTitle => 'Two optional questions';

  @override
  String get prePastBody =>
      'You can continue without answering them. Nothing here goes into your score.';

  @override
  String get prePastAgeLabel => 'How old were you when you took it?';

  @override
  String get prePastAgeError => 'An age between 5 and 90.';

  @override
  String get prePastScoreLabel => 'What score did you get?';

  @override
  String get prePastScoreError => 'A score between 40 and 200.';

  @override
  String get preEstimateEyebrow => 'Before the first exercise';

  @override
  String get preEstimateTitle => 'What do you think your IQ is?';

  @override
  String get preEstimateBody =>
      'Asked now, before the first exercise: once a result is in front of you, your answer would no longer be a belief. 100 is the average.';

  @override
  String get preEstimateHint => 'Slide, or tap − and +, to choose.';

  @override
  String get preEstimateAverage => '100 is the average.';

  @override
  String get preEstimateConfirm => 'Confirm my estimate';

  @override
  String get preEstimateDecline => 'I would rather not answer';

  @override
  String get preEstimateDecrease => 'Decrease by one point';

  @override
  String get preEstimateIncrease => 'Increase by one point';

  @override
  String regStepEyebrow(int step) {
    return 'STEP $step / 4';
  }

  @override
  String get regStepEyebrowSuccess => 'STEP 4 / 4 · SUCCESS';

  @override
  String get regEmailTitle => 'Create my token';

  @override
  String get regEmailHeading => 'Your email';

  @override
  String get regEmailIntro =>
      'We will send you a 6-digit verification code. Your email is not linked to your token and remains private.';

  @override
  String get regEmailFieldLabel => 'Email address';

  @override
  String get regEmailInvalid => 'Invalid email';

  @override
  String get regSendingCode => 'Sending code…';

  @override
  String get regReceiveCode => 'Get the code';

  @override
  String get regEmailPrivacyNote =>
      'No first name, last name or exact address will be stored. Only your sex, age range and postal code are encoded (encrypted) in your anonymous token.';

  @override
  String get regEmailOtpTitle => 'Verify my email';

  @override
  String get regCodeSentTo => 'Code sent to';

  @override
  String get regVerifying => 'Verifying…';

  @override
  String get regResendCode => 'Resend the code';

  @override
  String get regPhoneTitle => 'Your phone';

  @override
  String get regPhoneIntro =>
      'A 6-digit SMS code will be sent to verify your number. Your number is never linked to your token.';

  @override
  String get regPhoneFieldHint => 'Phone number';

  @override
  String get regSendingSms => 'Sending SMS…';

  @override
  String get regReceiveSms => 'Get the SMS';

  @override
  String get regPhoneOtpTitle => 'Verify my phone';

  @override
  String get regSmsSentTo => 'SMS sent to';

  @override
  String get regResendSms => 'Resend the SMS';

  @override
  String get regDemoTitle => 'Your demographic data';

  @override
  String get regDemoIntro =>
      'This information will be encrypted in your token. No exact value is stored (neither your precise age nor your precise address).';

  @override
  String get regSectionSex => 'SEX';

  @override
  String get regSectionAgeBucket => 'AGE RANGE';

  @override
  String get regSectionCountryPostal => 'COUNTRY AND POSTAL CODE';

  @override
  String get regPostalCodeHint => 'Postal code';

  @override
  String get regGeneratingToken => 'Generating token…';

  @override
  String get regGenerateMyToken => 'Generate my token';

  @override
  String get regSuccessTitle => 'Welcome to Mental E.T.';

  @override
  String get regSuccessTokenSaved =>
      'Your anonymous token has been generated and saved on this device.';

  @override
  String get regSuccessTokenDetails =>
      'It contains neither your email, nor your phone number, nor your name. Only your sex, age range and geographic area (encrypted). You can now start your cognitive assessment.';

  @override
  String get regImportantLabel => 'IMPORTANT';

  @override
  String get regSuccessWarning =>
      'Do not uninstall the app before completing your assessment: your token is only stored on this device. If you lose it, you will not be able to create a new account with the same email or phone number.';

  @override
  String get regEmailAlreadyRegistered =>
      'This email already has an account. If it is yours, you already have a token.';

  @override
  String get regEmailUnavailable => 'Email unavailable.';

  @override
  String get regOtpIncorrectOrExpired => 'Incorrect or expired code.';

  @override
  String get regPhoneAlreadyRegistered => 'This number already has an account.';

  @override
  String get regPhoneUnavailable => 'Number unavailable.';

  @override
  String get regEmailAlreadyHasToken => 'This email already has a token.';

  @override
  String get regPhoneAlreadyHasToken => 'This number already has a token.';

  @override
  String get regPostalNotFound =>
      'Postal code not found. Check the country and the code.';

  @override
  String get regNoInternet => 'No internet connection.';

  @override
  String get regGenericRetryError => 'Error — please try again.';

  @override
  String get regSexMale => 'Male';

  @override
  String get regSexFemale => 'Female';

  @override
  String get regSexUndisclosed => 'Prefer not to say';

  @override
  String get regAge1825 => '18 – 25 years';

  @override
  String get regAge2635 => '26 – 35 years';

  @override
  String get regAge3645 => '36 – 45 years';

  @override
  String get regAge4655 => '46 – 55 years';

  @override
  String get regAge5665 => '56 – 65 years';

  @override
  String get regAge66plus => '66 years and over';

  @override
  String get scoringClassificationVerySuperior => 'Very Superior';

  @override
  String get scoringClassificationSuperior => 'Superior';

  @override
  String get scoringClassificationHighAverage => 'High Average';

  @override
  String get scoringClassificationAverage => 'Average';

  @override
  String get scoringClassificationLowAverage => 'Low Average';

  @override
  String get scoringClassificationBorderline => 'Borderline';

  @override
  String get scoringClassificationExtremelyLow => 'Extremely Low';

  @override
  String get scoringNotAvailable => 'N/A';

  @override
  String scoringSummaryFullScaleIq(int score, String classification) {
    return 'Full Scale IQ: $score ($classification)';
  }

  @override
  String scoringSummaryPercentile(int rank) {
    return 'Percentile: $rank';
  }

  @override
  String scoringSummaryConfidenceInterval(int lower, int upper) {
    return '95% confidence interval: $lower - $upper';
  }

  @override
  String get scoringIndexVerbalComprehension => 'Verbal Comprehension';

  @override
  String get scoringIndexVisualSpatial => 'Visual Spatial';

  @override
  String get scoringIndexFluidReasoning => 'Fluid Reasoning';

  @override
  String get scoringIndexWorkingMemory => 'Working Memory';

  @override
  String get scoringIndexProcessingSpeed => 'Processing Speed';

  @override
  String scoringSummaryRelativeStrengths(String list) {
    return 'Relative strengths: $list';
  }

  @override
  String scoringSummaryRelativeWeaknesses(String list) {
    return 'Relative weaknesses: $list';
  }

  @override
  String get scoringSummaryHomogeneousProfile =>
      'Homogeneous cognitive profile';

  @override
  String scoringSummaryHeterogeneousProfile(int points) {
    return 'Heterogeneous cognitive profile (max discrepancy: $points points)';
  }

  @override
  String get simTestName => 'Common Ground';

  @override
  String get simEyebrow => 'VERBAL COMPREHENSION';

  @override
  String simStatusBar(int seconds, int score) {
    return '${seconds}s · $score pts';
  }

  @override
  String get simQuestionPrompt => 'How are these two words alike?';

  @override
  String simLevelLabel(String level) {
    return 'Level: $level';
  }

  @override
  String get simLevelConcrete => 'Concrete';

  @override
  String get simLevelFunctional => 'Functional';

  @override
  String get simLevelCategorical => 'Categorical';

  @override
  String get simLevelAbstract => 'Abstract';

  @override
  String get simAnswerLabel => 'Your answer:';

  @override
  String get simAnswerHint => 'Explain how they are alike...';

  @override
  String get simTipsTitle => 'Tips for getting 2 points:';

  @override
  String get simTipsLine1 => '• Give an abstract or superordinate category';

  @override
  String get simTipsLine2 =>
      '• E.g. \"They are...\", \"Forms of...\", \"Types of...\"';

  @override
  String get simFeedbackExcellent => 'Excellent!';

  @override
  String get simFeedbackCorrect => 'Correct';

  @override
  String get simFeedbackIncomplete => 'Incomplete answer';

  @override
  String get simFeedbackMsg2pts => 'Abstract/categorical answer! +2 points';

  @override
  String get simFeedbackMsg1pt => 'Functional/property answer. +1 point';

  @override
  String get simFeedbackMsg0pt => 'Incorrect or too vague answer. 0 points';

  @override
  String simYourAnswerQuoted(String answer) {
    return 'Your answer: \"$answer\"';
  }

  @override
  String get simExamples2pts => 'Examples of 2-point answers:';

  @override
  String get simExamples1pt => 'Examples of 1-point answers:';

  @override
  String simTimeSeconds(int seconds) {
    return 'Time: ${seconds}s';
  }

  @override
  String simTotalScore(int score) {
    return 'Total score: $score points';
  }

  @override
  String get simDiscontinue => '3 items skipped in a row — exercise ended.';

  @override
  String get simSeeResults => 'See results';

  @override
  String get simResultsTitle => 'Common Ground - Results';

  @override
  String simRawScore(int score, int max) {
    return 'Raw score: $score/$max points';
  }

  @override
  String simItemsCompleted(int completed, int total) {
    return 'Items completed: $completed/$total';
  }

  @override
  String simPercentage(int percent) {
    return 'Percentage: $percent%';
  }

  @override
  String simTotalTime(int seconds) {
    return 'Total time: ${seconds}s';
  }

  @override
  String get simSubtitle =>
      'Test of verbal reasoning and conceptual abstraction';

  @override
  String get simBreakdownTitle => 'Breakdown by level:';

  @override
  String simBreakdownLine(String level, int total, int max) {
    return '$level: $total/$max points';
  }

  @override
  String get simPerfExceptional => 'Exceptional performance (θ > +2.0)';

  @override
  String get simPerfSuperior => 'Superior performance (θ > +1.0)';

  @override
  String get simPerfAverage => 'Average performance (θ ≈ 0)';

  @override
  String get simPerfBelow => 'Below-average performance (θ < 0)';

  @override
  String get simPerfLow => 'Low performance (θ < -1.0)';

  @override
  String get simBack => 'Back';

  @override
  String get matTestName => 'Progressive Matrices';

  @override
  String get matEyebrow => 'IQ TEST';

  @override
  String get matCorrect => 'Correct!';

  @override
  String get matIncorrect => 'Incorrect';

  @override
  String matResponseTime(int seconds) {
    return 'Response time: ${seconds}s';
  }

  @override
  String matScoreFraction(int score, int total) {
    return 'Score: $score/$total';
  }

  @override
  String get matDiscontinue4 => '4 consecutive failures — exercise ended.';

  @override
  String get matSeeResultsEnded => 'See results (test ended)';

  @override
  String get matNextItem => 'Next item';

  @override
  String get matSeeResults => 'See results';

  @override
  String get matFinishedTitle => 'Matrix test completed!';

  @override
  String get matRawScore => 'Raw score';

  @override
  String get matSuccessRate => 'Success rate';

  @override
  String get matAvgTimePerItem => 'Avg time/item';

  @override
  String get matEvaluation => 'Evaluation:';

  @override
  String get matPerfExcellent => 'Excellent! Very superior fluid reasoning.';

  @override
  String get matPerfVeryGood => 'Very good! Strong logical analysis skills.';

  @override
  String get matPerfGood => 'Good. Average to good abilities.';

  @override
  String get matPerfAverage => 'Average. Improvements are possible.';

  @override
  String get matPerfBelowAverage =>
      'Below-average results. Practice recommended.';

  @override
  String matPoints(int score) {
    return '$score pts';
  }

  @override
  String get matValidateAnswer => 'Submit answer';

  @override
  String get matRestart => 'Restart';

  @override
  String matRulesTheta(int rules, String theta) {
    return 'Rules: $rules | θ = $theta';
  }

  @override
  String get matInstruction =>
      'Find the missing piece that logically completes the matrix';

  @override
  String get matChooseAnswer => 'Choose your answer:';

  @override
  String get matDiffEasy => 'Easy';

  @override
  String get matDiffMediumEasy => 'Medium-Easy';

  @override
  String get matDiffMedium => 'Medium';

  @override
  String get matDiffMediumHard => 'Medium-Hard';

  @override
  String get matDiffHard => 'Hard';

  @override
  String get cubesTestName => 'Blocks';

  @override
  String get cubesBravo => 'Well done!';

  @override
  String cubesElapsedTime(String time) {
    return 'Elapsed time: $time';
  }

  @override
  String cubesPointsEarned(int points) {
    return 'Points earned: $points';
  }

  @override
  String cubesTotalScore(int score) {
    return 'Total score: $score';
  }

  @override
  String get cubesFinishedTitle => 'Test completed!';

  @override
  String get cubesTotalScoreLabel => 'Total score';

  @override
  String cubesTotalScoreValue(int score, int max) {
    return '$score/$max pts';
  }

  @override
  String get cubesItemsCompletedLabel => 'Items completed';

  @override
  String cubesItemsCompletedValue(int count) {
    return '$count/14';
  }

  @override
  String get cubesAvgTime => 'Avg time';

  @override
  String get cubesPerfExcellent =>
      'Excellent! Very superior visuospatial abilities.';

  @override
  String get cubesPerfVeryGood => 'Very good! Strong visual analysis skills.';

  @override
  String get cubesDiffExample => 'Example';

  @override
  String get cubesDiffVeryHard => 'Very hard';

  @override
  String get cubesDescExample =>
      'Example item - Does not count toward the score';

  @override
  String get cubesDesc2x2 => 'Simple 2×2 pattern';

  @override
  String get cubesDesc3x3Diagonals => '3×3 pattern with diagonals';

  @override
  String get cubesDesc3x3Complex => 'Complex 3×3 pattern - High cohesion';

  @override
  String cubesCohesion(int score) {
    return 'Cohesion: $score';
  }

  @override
  String cubesRemaining(String time) {
    return 'Left: $time';
  }

  @override
  String get cubesReproduceInstruction =>
      'Reproduce the pattern below by tapping on the cubes';

  @override
  String get cubesPatternToReproduce => 'Pattern to reproduce:';

  @override
  String get cubesYourAnswer => 'Your answer:';

  @override
  String get cubesReset => 'Reset';

  @override
  String get fwTestName => 'Equilibrium';

  @override
  String get fwEyebrow => 'FLUID REASONING';

  @override
  String get fwCorrectAnswerPoint => 'Correct answer! +1 point';

  @override
  String get fwWrongAnswer => 'Wrong answer. The correct answer was:';

  @override
  String fwTime(int seconds) {
    return 'Time: ${seconds}s';
  }

  @override
  String get fwDiscontinue3 => '3 consecutive failures — exercise ended.';

  @override
  String get fwSeeResults => 'See results';

  @override
  String get fwResultsTitle => 'Equilibrium - Results';

  @override
  String fwRawScorePoints(int score) {
    return 'Raw score: $score/27 points';
  }

  @override
  String fwItemsCompleted(int count) {
    return 'Items completed: $count/27';
  }

  @override
  String fwPercentage(int percent) {
    return 'Percentage: $percent%';
  }

  @override
  String fwTotalTime(int seconds) {
    return 'Total time: ${seconds}s';
  }

  @override
  String get fwGLoading =>
      'This exercise is strongly linked to general reasoning.';

  @override
  String get fwPerfExceptional => 'Exceptional performance (θ > +2.0)';

  @override
  String get fwPerfSuperior => 'Superior performance (θ > +1.0)';

  @override
  String get fwPerfAverage => 'Average performance (θ ≈ 0)';

  @override
  String get fwPerfInferior => 'Below-average performance (θ < 0)';

  @override
  String get fwPerfLow => 'Low performance (θ < -1.0)';

  @override
  String fwScoreFraction(int score, int total) {
    return '$score/$total';
  }

  @override
  String get fwInstruction => 'Find the missing value that balances the scale.';

  @override
  String get fwWhatIs => 'What is ';

  @override
  String fwSeconds(int seconds) {
    return '${seconds}s';
  }

  @override
  String get vpTestName => 'Assembly';

  @override
  String get vpEyebrow => 'VISUOSPATIAL';

  @override
  String get vpCorrect => 'Correct';

  @override
  String get vpIncorrect => 'Incorrect';

  @override
  String get vpValidate => 'Submit';

  @override
  String vpSelectedCount(int count) {
    return '$count / 3 selected';
  }

  @override
  String get vpInstruction =>
      'Choose the 3 pieces that form the figure (rotations allowed, flips not allowed).';

  @override
  String vpSelectionSemantics(int filled, int total) {
    return 'Selection: $filled of $total pieces';
  }

  @override
  String get vpSelectionLabel => 'SELECTION';

  @override
  String vpPieceSemantics(String label) {
    return 'Piece $label';
  }

  @override
  String get vpTargetTitle => 'FIGURE TO REBUILD';

  @override
  String get codingTestName => 'Transcription';

  @override
  String get codingEyebrow => 'PROCESSING SPEED';

  @override
  String get codingStartTraining => 'Start training';

  @override
  String get codingTitle => 'Transcription';

  @override
  String get codingDescription =>
      'This test measures your processing speed and visuomotor coordination.';

  @override
  String get codingReferenceKey => 'Reference key:';

  @override
  String get codingTaskTitle => 'Your task';

  @override
  String get codingTaskDesc =>
      'For each displayed digit, select the matching symbol';

  @override
  String get codingTimeLimitTitle => 'Time limit';

  @override
  String get codingTimeLimitDesc =>
      '120 seconds to complete as many cells as possible (135 total)';

  @override
  String get codingScoringTitle => 'Scoring';

  @override
  String get codingScoringDesc =>
      '1 point per correct cell, no penalty for errors';

  @override
  String get codingTrainingDoneTitle => 'Training complete';

  @override
  String get codingTrainingDoneBody =>
      'You are ready to start the test. You will have 120 seconds to complete as many cells as possible.';

  @override
  String get codingStartTest => 'Start test';

  @override
  String get codingTestDoneTitle => 'Test complete!';

  @override
  String get codingTimeElapsed => 'Time elapsed: 120 seconds';

  @override
  String codingCellsCompleted(int count) {
    return 'Cells completed: $count/135';
  }

  @override
  String codingCellsCorrect(int count) {
    return 'Correct cells: $count';
  }

  @override
  String codingScorePoints(int count) {
    return 'Score: $count points';
  }

  @override
  String get codingPerfExceptional => 'Exceptional performance!';

  @override
  String get codingPerfVeryGood => 'Very good performance';

  @override
  String get codingPerfAboveAverage => 'Above-average performance';

  @override
  String get codingPerfAverage => 'Average performance';

  @override
  String get codingPerfBelowAverage => 'Below-average performance';

  @override
  String get codingTrainingTab => 'Training';

  @override
  String get codingReferenceShort => 'Reference:';

  @override
  String codingCellProgress(int current, int total) {
    return 'Cell $current/$total';
  }

  @override
  String codingCompletedProgress(int count, int total) {
    return 'Completed: $count/$total';
  }

  @override
  String get codingSelectSymbol => 'Select a symbol:';

  @override
  String get codingClear => 'Clear';

  @override
  String get codingFinishTraining => 'Finish training';

  @override
  String get ssTestName => 'Symbol Detection';

  @override
  String get ssDescription =>
      'This test measures your visual processing speed and discrimination ability.';

  @override
  String get ssExampleLabel => 'Example item:';

  @override
  String get ssTargets => 'TARGETS';

  @override
  String get ssGroup => 'GROUP';

  @override
  String get ssExampleAnswer => '→ Answer: YES (┴ is present)';

  @override
  String get ssTaskTitle => 'Your task';

  @override
  String get ssTaskDesc =>
      'Check whether one of the target symbols appears in the group';

  @override
  String get ssQuickAnswerTitle => 'Quick answer';

  @override
  String get ssQuickAnswerDesc => 'Tap YES or NO as fast as possible';

  @override
  String get ssScoringPenaltyTitle => 'Scoring with penalty';

  @override
  String get ssScoringPenaltyDesc =>
      'Score = Correct answers - Incorrect answers';

  @override
  String get ssTimeLimitTitle => 'Time limit';

  @override
  String get ssTimeLimitDesc => '120 seconds for 60 items';

  @override
  String get ssTrainingDoneBody =>
      'You are ready! You will have 120 seconds to complete as many items as possible.\n\nReminder: Score = Correct answers - Incorrect answers';

  @override
  String ssItemsAnswered(int count) {
    return 'Items answered: $count/60';
  }

  @override
  String ssCorrectAnswers(int count) {
    return 'Correct answers: $count';
  }

  @override
  String ssIncorrectAnswers(int count) {
    return 'Incorrect answers: $count';
  }

  @override
  String ssNotAnswered(int count) {
    return 'Not answered: $count';
  }

  @override
  String ssRawScore(int count) {
    return 'Raw score: $count';
  }

  @override
  String get ssScoreFormulaShort => '(Correct - Incorrect)';

  @override
  String get ssPerfGood => 'Good performance';

  @override
  String ssItemProgress(int current, int total) {
    return 'Item $current/$total';
  }

  @override
  String ssAnsweredProgress(int count) {
    return 'Answered: $count/60';
  }

  @override
  String get ssTargetSymbols => 'TARGET SYMBOLS';

  @override
  String get ssSearchGroup => 'SEARCH GROUP';

  @override
  String get ssNo => 'NO';

  @override
  String get ssYes => 'YES';

  @override
  String get dsTestName => 'Digit Sequences';

  @override
  String get dsEyebrow => 'WORKING MEMORY';

  @override
  String get dsDescription =>
      'This test measures your working memory across 3 distinct parts:';

  @override
  String get dsForwardTitle => 'Part 1: Forward Span';

  @override
  String get dsForwardInstruction => 'Repeat the digits in the same order';

  @override
  String get dsBackwardTitle => 'Part 2: Backward Span';

  @override
  String get dsBackwardInstruction => 'Repeat the digits in reverse order';

  @override
  String get dsSequencingTitle => 'Part 3: Sequencing';

  @override
  String get dsSequencingInstruction => 'Repeat the digits in ascending order';

  @override
  String get dsPresentationInfo =>
      'The digits will be presented at a rate of 1 digit per second.';

  @override
  String get dsTypeForward => 'Forward Span';

  @override
  String get dsTypeBackward => 'Backward Span';

  @override
  String get dsTypeSequencing => 'Sequencing';

  @override
  String get dsStartPart => 'Start';

  @override
  String dsLengthTrial(int length, int trial) {
    return 'Length $length - Trial $trial';
  }

  @override
  String get dsListenCarefully => 'Listen carefully';

  @override
  String get dsCorrect => 'Correct!';

  @override
  String get dsIncorrect => 'Incorrect';

  @override
  String dsPointsEarned(int count) {
    return 'Points earned: $count';
  }

  @override
  String dsCorrectAnswer(String answer) {
    return 'Correct answer: $answer';
  }

  @override
  String dsYourAnswer(String answer) {
    return 'Your answer: $answer';
  }

  @override
  String get dsResultsByPart => 'Results by part:';

  @override
  String dsForwardScore(int count) {
    return 'Forward Span: $count points';
  }

  @override
  String dsBackwardScore(int count) {
    return 'Backward Span: $count points';
  }

  @override
  String dsSequencingScore(int count) {
    return 'Sequencing: $count points';
  }

  @override
  String dsTotalScore(int count) {
    return 'Total score: $count points';
  }

  @override
  String get dsEnterAnswer => 'Enter your answer...';

  @override
  String dsValidateProgress(int count, int total) {
    return 'Submit ($count/$total)';
  }

  @override
  String get psTestName => 'Picture Span';

  @override
  String get psDescription =>
      'This test measures your visual working memory and selective attention.';

  @override
  String get psPhase1Title => 'Phase 1: Memorization';

  @override
  String get psPhase1Desc =>
      'Images will be presented one by one (3 seconds each)';

  @override
  String get psPhase2Title => 'Phase 2: Recall';

  @override
  String get psPhase2Desc =>
      'Select the images in the exact order they were presented';

  @override
  String get psProgressionTitle => 'Progression';

  @override
  String get psProgressionDesc =>
      'Difficulty increases: 1 to 6 images to memorize';

  @override
  String get psTrialsInfo =>
      '12 trials in total. The test stops after 2 failures at the same level.';

  @override
  String get psMemorizationTab => 'Memorization';

  @override
  String get psRecallTab => 'Recall';

  @override
  String psLevelTrial(int level, int trial) {
    return 'Level $level - Trial $trial';
  }

  @override
  String get psMemorizeImages => 'Memorize the images';

  @override
  String psImageProgress(int current, int total) {
    return 'Image $current / $total';
  }

  @override
  String psSelectInOrder(int count) {
    return 'Select the $count images in order';
  }

  @override
  String get psNoSelection => 'No selection';

  @override
  String get psClearLast => 'Clear last selection';

  @override
  String psCorrectOrder(String names) {
    return 'Correct order: $names';
  }

  @override
  String psYourOrder(String names) {
    return 'Your order: $names';
  }

  @override
  String psTrialsCompleted(int count) {
    return 'Trials completed: $count/12';
  }

  @override
  String psScorePoints(int count) {
    return 'Total score: $count points';
  }

  @override
  String psMaxLevel(int level) {
    return 'Highest level reached: Level $level';
  }

  @override
  String get psImgChat => 'Cat';

  @override
  String get psImgInsecte => 'Insect';

  @override
  String get psImgLapin => 'Rabbit';

  @override
  String get psImgOiseau => 'Bird';

  @override
  String get psImgPoisson => 'Fish';

  @override
  String get psImgTortue => 'Turtle';

  @override
  String get psImgPapillon => 'Butterfly';

  @override
  String get psImgCoccinelle => 'Ladybug';

  @override
  String get psImgChaise => 'Chair';

  @override
  String get psImgLampe => 'Lamp';

  @override
  String get psImgMontre => 'Watch';

  @override
  String get psImgParapluie => 'Umbrella';

  @override
  String get psImgSac => 'Bag';

  @override
  String get psImgLit => 'Bed';

  @override
  String get psImgPorte => 'Door';

  @override
  String get psImgFenetre => 'Window';

  @override
  String get psImgGateau => 'Cake';

  @override
  String get psImgCafe => 'Coffee';

  @override
  String get psImgPizza => 'Pizza';

  @override
  String get psImgPomme => 'Apple';

  @override
  String get psImgGlace => 'Ice cream';

  @override
  String get psImgBurger => 'Burger';

  @override
  String get psImgSandwich => 'Sandwich';

  @override
  String get psImgOeuf => 'Egg';

  @override
  String get psImgMarteau => 'Hammer';

  @override
  String get psImgCle => 'Wrench';

  @override
  String get psImgCiseaux => 'Scissors';

  @override
  String get psImgPinceau => 'Brush';

  @override
  String get psImgCrayon => 'Pencil';

  @override
  String get psImgCouteau => 'Knife';

  @override
  String get psImgTournevis => 'Screwdriver';

  @override
  String get psImgEngrenage => 'Gear';

  @override
  String get psImgVoiture => 'Car';

  @override
  String get psImgVelo => 'Bike';

  @override
  String get psImgAvion => 'Plane';

  @override
  String get psImgTrain => 'Train';

  @override
  String get psImgBateau => 'Boat';

  @override
  String get psImgBus => 'Bus';

  @override
  String get psImgMoto => 'Motorcycle';

  @override
  String get psImgFusee => 'Rocket';

  @override
  String get speedNoPauseTitle => '2 uninterrupted minutes';

  @override
  String get speedNoPauseBody =>
      'This exercise measures your speed over a continuous stretch. It cannot be paused: if you leave it, it will have to be retaken from the start. Get settled before you begin.';

  @override
  String get speedNoPauseConfirm => 'I am ready';

  @override
  String get ctShareScore => 'Share my score';

  @override
  String get ctSubtestExitBody =>
      'You left this exercise before finishing it. The exercises you have already completed are saved: you can resume the assessment right here, at this exercise.';

  @override
  String get ctSubtestExitResume => 'Resume exercise';

  @override
  String get ctSubtestExitTitle => 'Subtest interrupted';

  @override
  String get demoBadge => 'PRACTICE';

  @override
  String get demoContinue => 'Continue';

  @override
  String get demoNotice => 'Practice — this attempt does not count.';

  @override
  String get demoRetry => 'Try again';

  @override
  String get demoStart => 'Start the test';

  @override
  String get demoTryAgain => 'Not quite — try again';

  @override
  String get demoWellDone => 'Correct!';

  @override
  String get histLockedBody =>
      'Your result is saved, but it stays blurred until every mission is validated.';

  @override
  String get histLockedBodyNoResult =>
      'Your missions and your invite link are here. Finish your assessment to unlock your result.';

  @override
  String get histLockedCta => 'See my missions';

  @override
  String get histLockedTitle => 'Missions to complete';

  @override
  String get inviteLandingBody =>
      'A friend invited you to take the free Mentality IQ test. By finishing your test, you get your own result and help your friend unlock theirs.';

  @override
  String get inviteLandingCta => 'Start the free test';

  @override
  String get inviteLandingTitle => 'Invitation';

  @override
  String get shareCancel => 'Cancel';

  @override
  String get shareCodeLabel => 'Invite code';

  @override
  String get shareConfirm => 'Share this image';

  @override
  String get shareError => 'Could not prepare the image. Please try again.';

  @override
  String get shareEyebrow => 'Preview';

  @override
  String get shareIntro =>
      'This is the image that will be shared. Nothing is posted until you confirm.';

  @override
  String get shareLinkCopied =>
      'Your link is copied — add it as a Link sticker on your story';

  @override
  String sharePercentile(int rank) {
    return 'Higher than $rank% of participants';
  }

  @override
  String get shareScoreLabel => 'Overall score';

  @override
  String get shareTitle => 'Share my score';

  @override
  String get ugCopied => 'Link copied!';

  @override
  String get ugCopyLink => 'Copy my invite link';

  @override
  String get ugErrorBody =>
      'Could not fetch your unlock status. Check your connection and try again.';

  @override
  String get ugEyebrow => 'Final steps';

  @override
  String get ugFreeNotice =>
      'The test is 100% free. To receive your result, a few simple steps remain — they are validated automatically.';

  @override
  String ugFriendDone(int n) {
    return 'Friend $n: test completed';
  }

  @override
  String ugFriendPending(int n) {
    return 'Friend $n: test in progress';
  }

  @override
  String ugInviteCounter(int joined, int required) {
    return '$joined/$required friends have finished their test';
  }

  @override
  String get ugRefresh => 'Refresh';

  @override
  String get ugRefreshFailed =>
      'Could not refresh. Check your connection — the numbers shown are from your last successful update.';

  @override
  String get ugResultsHubNotice =>
      'Everything lives in “My results”: your missions, your invite link and your result (blurred until every mission is validated). You can leave this page and come back anytime.';

  @override
  String get ugRetry => 'Retry';

  @override
  String get ugStep1Body =>
      'Share your personal link with 3 friends. This step advances when they FINISH their test — not just when they sign up. Feel free to remind them.';

  @override
  String get ugStep1Title => 'Invite 3 friends';

  @override
  String get ugStep2Body =>
      'Your friends now need to finish their IQ test. We are waiting for their results — feel free to remind them!';

  @override
  String get ugStep2Title => 'Your friends are taking their test';

  @override
  String get ugTitle => 'Your result is ready';

  @override
  String ugWaitBody(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other:
          'Your result is being prepared. It will be published in $days days, automatically — there is nothing left for you to do.',
      one:
          'Your result is being prepared. It will be published in $days day, automatically — there is nothing left for you to do.',
      zero:
          'Your result is being prepared. It will be published automatically — there is nothing left for you to do.',
    );
    return '$_temp0';
  }

  @override
  String get ugWaitConfirming =>
      'Your result unlocks as soon as the server confirms — this screen refreshes on its own.';

  @override
  String ugWaitCountdownDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days left',
      one: '$days day left',
    );
    return '$_temp0';
  }

  @override
  String get ugWaitCountdownDone => 'The wait is over.';

  @override
  String ugWaitCountdownHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours hours left',
      one: '$hours hour left',
    );
    return '$_temp0';
  }

  @override
  String ugWaitCountdownMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes left',
      one: '$minutes minute left',
    );
    return '$_temp0';
  }

  @override
  String get ugWaitTitle => 'Your results are on the way';

  @override
  String get vpDemoEyebrow => 'DEMONSTRATION';

  @override
  String get vpDemoInstruction =>
      'Untimed practice: choose the 3 pieces that form the figure, then confirm.';

  @override
  String get vpDemoRetry => 'Try again';

  @override
  String get vpDemoStart => 'Start the test';

  @override
  String vpReadyBody(int count) {
    return 'Practice is over. The test begins: $count puzzles, each with its own timer. The clock starts as soon as you press the button.';
  }

  @override
  String get vpReadyStart => 'Start now';

  @override
  String get vpReadyTitle => 'Ready?';

  @override
  String get vpRecorded => 'Answer recorded';

  @override
  String get completionPendingNotice =>
      'Your test completion hasn\'t been confirmed by the server yet. We keep retrying — stay connected and reopen the app if needed.';

  @override
  String get completionRejectedNotice =>
      'This attempt could not be validated: it was too short. It does not count towards the referral mission.';

  @override
  String get ctSubtestExitPause => 'Pause';

  @override
  String get vocabTestName => 'Vocabulary';

  @override
  String get vocabEyebrow => 'VERBAL COMPREHENSION';

  @override
  String vocabTimerScore(int seconds, int score) {
    return '${seconds}s · $score pts';
  }

  @override
  String get vocabFeedbackExcellent => 'Excellent!';

  @override
  String get vocabFeedbackCorrect => 'Correct';

  @override
  String get vocabFeedbackIncomplete => 'Incomplete answer';

  @override
  String get vocabFeedbackTwoPoints =>
      'Complete and precise definition! +2 points';

  @override
  String get vocabFeedbackOnePoint =>
      'Partial but correct definition. +1 point';

  @override
  String get vocabFeedbackZeroPoint =>
      'Incorrect or too vague an answer. 0 points';

  @override
  String vocabWordLabel(String word) {
    return 'Word: “$word”';
  }

  @override
  String vocabYourAnswerLabel(String answer) {
    return 'Your answer: “$answer”';
  }

  @override
  String get vocabEmptyAnswer => '(empty)';

  @override
  String get vocabTwoPointExamples => 'Examples of 2-point answers:';

  @override
  String get vocabOnePointExamples => 'Examples of 1-point answers:';

  @override
  String vocabTimeSeconds(int seconds) {
    return 'Time: ${seconds}s';
  }

  @override
  String vocabTotalScore(int score) {
    return 'Total score: $score points';
  }

  @override
  String get vocabDiscontinued => '3 items skipped in a row — exercise ended.';

  @override
  String get vocabViewResults => 'View results';

  @override
  String get vocabResultsTitle => 'Vocabulary Test - Results';

  @override
  String vocabRawScore(int score, int max) {
    return 'Raw score: $score/$max points';
  }

  @override
  String vocabItemsCompleted(int completed, int total) {
    return 'Items completed: $completed/$total';
  }

  @override
  String vocabPercentage(int percent) {
    return 'Percentage: $percent%';
  }

  @override
  String vocabTotalTime(int seconds) {
    return 'Total time: ${seconds}s';
  }

  @override
  String get vocabTestCaption =>
      'Test of lexical knowledge and verbal comprehension';

  @override
  String get vocabFrequencyBreakdownTitle => 'Breakdown by frequency:';

  @override
  String vocabFrequencyBreakdownRow(String name, int score, int max) {
    return '$name: $score/$max points';
  }

  @override
  String get vocabPerfExceptional => 'Exceptional performance (θ > +2.0)';

  @override
  String get vocabPerfSuperior => 'Superior performance (θ > +1.0)';

  @override
  String get vocabPerfAverage => 'Average performance (θ ≈ 0)';

  @override
  String get vocabPerfBelowAverage => 'Below-average performance (θ < 0)';

  @override
  String get vocabPerfLow => 'Low performance (θ < -1.0)';

  @override
  String get vocabFreqVeryHigh => 'Very frequent';

  @override
  String get vocabFreqHigh => 'Frequent';

  @override
  String get vocabFreqMedium => 'Medium';

  @override
  String get vocabFreqLow => 'Rare';

  @override
  String get vocabFreqVeryLow => 'Very rare';

  @override
  String get vocabInstruction => 'Define the following word';

  @override
  String get vocabYourDefinitionLabel => 'Your definition:';

  @override
  String get vocabDefinitionHint => 'Write the definition of the word...';

  @override
  String get vocabTipsTitle => 'Tips to earn 2 points:';

  @override
  String get vocabTipComplete => '• Give a complete and precise definition';

  @override
  String get vocabTipSynonyms => '• Use exact synonyms';

  @override
  String get vocabTipContext => '• Explain the meaning with context';

  @override
  String get weGateCta => 'See today\'s programme';

  @override
  String get weHubEyebrow => 'While you wait';

  @override
  String weHubTitle(int day) {
    return 'Day $day';
  }

  @override
  String get weHubTitleDone => 'Programme complete';

  @override
  String get weHubIntro =>
      'Each day reveals a part of your results, along with an optional activity. Nothing here speeds up the unlock: time alone unlocks it.';

  @override
  String get weTodayTag => 'Today';

  @override
  String get wePastTag => 'Catch up';

  @override
  String weLockedTag(int day) {
    return 'Opens on day $day';
  }

  @override
  String get wePlaceholderTitle => 'Coming soon';

  @override
  String get wePlaceholderBody =>
      'This day\'s content is coming in a future update.';

  @override
  String get weAnnouncedTag => 'Today\'s test — with your result';

  @override
  String get weContributionTag => 'Contribution — help us build our test';

  @override
  String get weShareTag => 'Final reward';

  @override
  String get weDay1Title => 'Your personality';

  @override
  String get weDay2Title => 'Build our reading test';

  @override
  String get weDay3Title => 'Your balance';

  @override
  String get weDay4Title => 'Build our attention test (1/2)';

  @override
  String get weDay5Title => 'Build our attention test (2/2)';

  @override
  String get weDay6Title => 'Your energy';

  @override
  String get weDay7Title => 'Autism profile';

  @override
  String get weDay8Title => 'Your overall IQ';

  @override
  String get weRevealVci => 'Your verbal index';

  @override
  String get weRevealPsi => 'Your processing speed';

  @override
  String get weRevealWmi => 'Your working memory';

  @override
  String get weRevealFri => 'Your reasoning';

  @override
  String get weRevealVsi => 'Your spatial index';

  @override
  String get weRevealStrengths => 'Your strengths and weaknesses';

  @override
  String get weRevealFullIq => 'Your overall IQ';

  @override
  String get weGameStroop => 'Game: Stroop';

  @override
  String get weGameDelayChoice => 'Game: delay tolerance';

  @override
  String get weGameTimeEstimation => 'Game: time estimation';

  @override
  String get weGameConfidence => 'Game: confidence calibration';

  @override
  String get weRunnerNext => 'Next';

  @override
  String get weRunnerFinish => 'Finish';

  @override
  String get weRunnerBack => 'Back';

  @override
  String get weRunnerScoredLabel => 'Today\'s test';

  @override
  String get weRunnerContributionLabel => 'Contribution';

  @override
  String get weRunnerResumed => 'You\'re picking up where you left off.';

  @override
  String get weRunnerNoScoreNotice =>
      'These questions don\'t calculate any score for you: they help build the tool for those who come next.';

  @override
  String get weRunnerQuitTitle => 'Leave the questionnaire?';

  @override
  String get weRunnerQuitBody =>
      'Your answers are saved. You can pick up again at the question where you stop.';

  @override
  String get weRunnerQuitStay => 'Keep going';

  @override
  String get weRunnerQuitLeave => 'Leave';

  @override
  String get weRunnerTransitionCta => 'Continue';

  @override
  String get weRunnerDoneTitle => 'All done';

  @override
  String get weRunnerDoneBody => 'Thank you — your answers are saved.';

  @override
  String get weRunnerDoneContributionBody =>
      'Thank you — your answers will help build our test. No score is calculated for you.';

  @override
  String get weRunnerDoneCta => 'Back to the programme';

  @override
  String get weRvEyebrow => 'Today\'s reveal';

  @override
  String get weRvContinue => 'Continue';

  @override
  String get weRvBackToHub => 'Back to the programme';

  @override
  String get weRvScoreLabel => 'SCORE';

  @override
  String weRvCi(int low, int high) {
    return '95% confidence interval · $low – $high';
  }

  @override
  String get weRvCaveat =>
      'An index is a measurement, with its margin of error — not a verdict. Taking the same assessment again would not give exactly the same number.';

  @override
  String get weRvUnavailableTitle => 'No assessment to reveal';

  @override
  String get weRvUnavailableBody =>
      'No completed assessment is attached to this pass on this device. Nothing is lost: the reveal will appear as soon as your results are readable here again.';

  @override
  String get weRvMissingTitle => 'This index was not calculated';

  @override
  String get weRvMissingBody =>
      'Your saved assessment does not include this index — a subtest was missing. The other reveals remain available.';

  @override
  String get weRvVciBody =>
      'What you know about words and ideas, and how you connect them: defining, explaining, finding what brings two notions together. It is the part of the profile that changes least over the years.';

  @override
  String get weRvVsiBody =>
      'How you handle shapes and space: rebuilding a pattern, seeing how pieces fit together before you have even laid them down.';

  @override
  String get weRvFriBody =>
      'How you find a rule nobody gave you, from what you observe. It is the reasoning that owes nothing to what you were taught.';

  @override
  String get weRvWmiBody =>
      'What you can hold in mind AND handle at the same time: keeping a sequence while reordering it. It is the index most sensitive to tiredness and stress.';

  @override
  String get weRvPsiBody =>
      'How fast you process simple information without making mistakes. It is not “thinking fast”: it is a throughput, and it is paid for in attention.';

  @override
  String get weRvStrengthsTitle => 'Your strengths and points of vigilance';

  @override
  String get weRvStrengthsIntro =>
      'Today the five indices are compared with one another. A strength is not an absolute talent: it is what exceeds your own average level by more than 10 points.';

  @override
  String get weRvStrengthsNone =>
      'No index departs from your average level by more than 10 points: your profile is even, and that is a result in itself.';

  @override
  String get weRvFullIqLabel => 'Full-scale IQ';

  @override
  String get weRvFullIqBody =>
      'The full-scale IQ sums up the five indices in a single number. When they differ widely from one another, that summary loses its meaning: it is then the detail that describes you, not the total.';

  @override
  String get weRvEstimateTitle => 'YOUR ESTIMATE VS THE MEASUREMENT';

  @override
  String weRvEstimateLine(int estimate, int measured) {
    return 'You estimated $estimate. The measurement gives $measured.';
  }

  @override
  String weRvEstimateOver(int points) {
    return 'That is $points points above the measurement.';
  }

  @override
  String weRvEstimateUnder(int points) {
    return 'That is $points points below the measurement.';
  }

  @override
  String get weRvEstimateClose =>
      'Less than 5 points apart: your estimate and the measurement say the same thing.';

  @override
  String get weRvEstimateMissing =>
      'You did not give an estimate — there is nothing to compare.';

  @override
  String get weRvSelfEyebrow => 'Before any reveal';

  @override
  String get weRvSelfTitle => 'What do you think your IQ is?';

  @override
  String get weRvSelfBody =>
      'A single question, asked now: after a first reveal, your answer would be influenced by the number you had just read. 100 is the average. Your answer stays on your phone and comes back to you on day 8.';

  @override
  String get weRvSelfHint => 'Slide, or tap − and +, to choose.';

  @override
  String get weRvSelfAverage => '100 is the average.';

  @override
  String get weRvSelfConfirm => 'Confirm my estimate';

  @override
  String get weRvSelfDecline => 'I\'d rather not answer';

  @override
  String get weRvSelfDecrease => 'Decrease by one point';

  @override
  String get weRvSelfIncrease => 'Increase by one point';

  @override
  String get weDcEyebrow => 'Game';

  @override
  String get weDcTitle => 'Now or later';

  @override
  String get weDcIntroTitle => 'Some money right now, or more of it later';

  @override
  String get weDcIntroBody =>
      'You\'ll be offered the same kind of choice twenty times: a sum available right now, or a bigger sum after a wait. Just tap whichever one you\'d rather have.';

  @override
  String get weDcIntroImaginary =>
      'These sums are imaginary. There is nothing to win, nothing to pay and nothing to receive: these are questions, not offers.';

  @override
  String get weDcIntroNoRightAnswer =>
      'There is no right answer. Taking the money right away is neither better nor worse than waiting.';

  @override
  String get weDcStart => 'Start';

  @override
  String get weDcLater => 'Later';

  @override
  String get weDcProgressTag => 'Choice';

  @override
  String get weDcPrompt => 'Which would you rather have?';

  @override
  String get weDcImaginaryTag => 'Imaginary sums — there is nothing to win.';

  @override
  String get weDcResultTitle => 'Your patience';

  @override
  String weDcPatienceScore(int score) {
    return '$score / 100';
  }

  @override
  String get weDcResultCaption =>
      'The higher the number, the more willing you are to wait. It isn\'t a grade: both ends of the scale are equally valid.';

  @override
  String weDcIndifference(String delayed, String immediate) {
    return 'Waiting a month for $delayed amounts, for you, to getting $immediate right now.';
  }

  @override
  String get weDcCurveTitle => 'What the wait was worth';

  @override
  String weDcPrevious(int score) {
    return 'Last time: $score / 100';
  }

  @override
  String get weDcNoBetterEnd =>
      'This number doesn\'t say whether you played well. Preferring the money right away is a trade-off, not a mistake — and it shifts with the moment, the mood and each person\'s situation.';

  @override
  String get weDcNotClinical =>
      'This is a game, not a clinical measure: no threshold, no ranking, nothing to conclude about you.';

  @override
  String get weDcIncoherentTitle =>
      'Answers too scattered to draw anything from';

  @override
  String get weDcIncoherentBody =>
      'Your answers pull in opposite directions from one delay to the next: the same sum ends up worth more further away than it is close by. Nothing was saved. Play again whenever you like.';

  @override
  String get weDcReplay => 'Play again';

  @override
  String get weDcDone => 'Done';

  @override
  String get weCsEyebrow => 'Before going further';

  @override
  String get weCsTitle => 'Send your answers?';

  @override
  String get weCsIntro =>
      'The questions that follow are about your mental health and your neurodevelopment. The law protects these answers separately: they can only leave your phone if you explicitly agree here.';

  @override
  String get weCsWhatTitle => 'What is sent';

  @override
  String get weCsWhat =>
      'Your answers, exactly as you gave them. Without your name, your number, or any precise date or time. Never your scores: they are calculated on your phone and stay there.';

  @override
  String get weCsPurposeTitle => 'What they are used for';

  @override
  String get weCsPurpose =>
      'To build and improve our own screening tests, and to compare what people report with what the test battery measures. These tools are part of what we sell — it would be wrong not to say so.';

  @override
  String get weCsWhoTitle => 'Where they go';

  @override
  String get weCsWho =>
      'To our servers, in Europe. Filed under your anonymous pass, never under your name or your number.';

  @override
  String get weCsRightsTitle => 'You stay in control';

  @override
  String get weCsRights =>
      'You can withdraw your agreement at any time: further sending stops immediately. You can also ask to access your data or have it erased.';

  @override
  String get weCsOptional =>
      'This is optional and changes nothing else: neither your unlock, nor your results, nor the programme\'s tests depend on this answer.';

  @override
  String get weCsAccept => 'I agree to send my answers';

  @override
  String get weCsDecline => 'No, keep my answers here';

  @override
  String get weDxDeclinedTitle => 'Nothing will be sent';

  @override
  String get weDxDeclinedBody =>
      'These questions only serve our own research: without your agreement, we don\'t ask them. You can come back whenever you like — it changes nothing about the rest of the programme.';

  @override
  String get weDxEyebrow => 'Asked only once';

  @override
  String get weDxListTitle => 'Your history';

  @override
  String get weDxListQuestion =>
      'Have you been diagnosed — or do you think you may be affected — with any of these?';

  @override
  String get weDxListBody =>
      'These answers change nothing about your results. They are used to build our tools: without knowing who is affected, it is impossible to spot which questions actually tell anything apart.';

  @override
  String get weDxListHint => 'Tick everything that applies.';

  @override
  String get weDxAdhd => 'ADHD';

  @override
  String get weDxAutism => 'Autism / ASD';

  @override
  String get weDxDyslexia => 'Dyslexia';

  @override
  String get weDxDyspraxia => 'Dyspraxia';

  @override
  String get weDxDyscalculia => 'Dyscalculia';

  @override
  String get weDxHpi => 'Giftedness';

  @override
  String get weDxDepression => 'Depression';

  @override
  String get weDxAnxiety => 'Anxiety disorder';

  @override
  String get weDxBipolar => 'Bipolar disorder';

  @override
  String get weDxOcd => 'OCD';

  @override
  String get weDxSleep => 'Sleep disorder';

  @override
  String get weDxBurnout => 'Burnout';

  @override
  String get weDxOther => 'Another condition';

  @override
  String get weDxNone => 'None';

  @override
  String get weDxPreferNotToSay => 'I\'d rather not say';

  @override
  String get weDxDetailTitle => 'Details';

  @override
  String weDxDetailProgress(int current, int total) {
    return '$current of $total';
  }

  @override
  String get weDxSourceQuestion => 'Who identified it?';

  @override
  String get weDxSourcePsychiatrist => 'A psychiatrist or neuropsychologist';

  @override
  String get weDxSourceGp => 'A general practitioner';

  @override
  String get weDxSourcePsychologist => 'A psychologist';

  @override
  String get weDxSourceSelf => 'Nobody — I think so, without a diagnosis';

  @override
  String get weDxWhenQuestion => 'How long ago was that?';

  @override
  String get weDxWhenUnder1 => 'Less than a year';

  @override
  String get weDxWhen1to3 => 'Between 1 and 3 years';

  @override
  String get weDxWhen3to10 => 'Between 3 and 10 years';

  @override
  String get weDxWhenOver10 => 'More than 10 years';

  @override
  String get weDxWhenUnknown => 'I can\'t remember';

  @override
  String get weDxTreatmentQuestion => 'Any treatment or follow-up?';

  @override
  String get weDxTreatmentYes => 'Yes, currently';

  @override
  String get weDxTreatmentNo => 'No';

  @override
  String get weDxTreatmentPast => 'In the past';

  @override
  String get weDxAssessmentQuestion => 'Was a full assessment carried out?';

  @override
  String get weDxAssessmentYes => 'Yes';

  @override
  String get weDxAssessmentNo => 'No';

  @override
  String get weDxAssessmentUnknown => 'I don\'t know';

  @override
  String get weDxDoneTitle => 'Noted';

  @override
  String get weDxDoneBody =>
      'Thank you. You won\'t be asked this again — it is only asked once. It changes nothing about your results or your unlock.';

  @override
  String get weDxAlreadyTitle => 'Already answered';

  @override
  String get weDxAlreadyBody =>
      'You have already filled this in. It is only asked once, so that your answer isn\'t influenced by the tests of the following days.';

  @override
  String get weDxFailedTitle => 'Nothing could be saved';

  @override
  String get weDxFailedBody =>
      'Your answers were not kept, and nothing was sent. You can try again from the programme — the question is still open.';

  @override
  String get weDxQuitTitle => 'Leave now?';

  @override
  String get weDxQuitBody =>
      'What you have ticked will not be kept: this block is saved in one go, at the end. You can start it again from the programme.';

  @override
  String get weGameCardSubtitle => 'Today\'s game · 2 minutes · replayable';

  @override
  String get weStroopEyebrow => 'Game';

  @override
  String get weStroopTitle => 'Color clash';

  @override
  String get weStroopIntroTitle => 'Name the color, not the word';

  @override
  String get weStroopIntroBody =>
      'A word will appear in a certain color. Tap the color of the INK, not what the word says. Reading happens automatically: that is exactly what you will have to set aside.';

  @override
  String get weStroopIntroPractice =>
      'We start with three trials that don\'t count, just to get the hang of it.';

  @override
  String get weStroopIntroExample =>
      'Here the word says one color and the ink says another: the ink is what counts.';

  @override
  String get weStroopStart => 'Start';

  @override
  String get weStroopLater => 'Later';

  @override
  String get weStroopPracticeTag => 'Practice';

  @override
  String get weStroopScoredTag => 'Counted';

  @override
  String get weStroopPrompt => 'What color is this written in?';

  @override
  String get weStroopBlockScoredTitle => 'Here we go';

  @override
  String get weStroopBlockScoredBody =>
      'From now on, the trials count. Go fast, but aim true: a mistake earns you nothing.';

  @override
  String get weStroopBlockConflictTitle => 'Now the words contradict you';

  @override
  String get weStroopBlockConflictBody =>
      'The instruction doesn\'t change: it is still the color of the ink. The words will simply say something else.';

  @override
  String get weStroopBlockCta => 'Continue';

  @override
  String get weStroopResultTitle => 'Your gap';

  @override
  String weStroopMilliseconds(int ms) {
    return '$ms ms';
  }

  @override
  String get weStroopResultCaption =>
      'That\'s the extra time you needed, on each trial, when the word said the opposite of the ink.';

  @override
  String weStroopAccuracy(int correct, int total) {
    return '$correct correct out of $total';
  }

  @override
  String weStroopBest(int ms) {
    return 'Your best gap: $ms ms';
  }

  @override
  String get weStroopNewBest => 'New best gap';

  @override
  String get weStroopNotSpeed =>
      'This number is not your speed. It is the difference between two runs: someone slower overall can perfectly well have a smaller gap.';

  @override
  String get weStroopNotClinical =>
      'This is a game, not a clinical measure: no threshold, no ranking, nothing to conclude about you.';

  @override
  String get weStroopUnreliableTitle => 'Too few answers to count';

  @override
  String get weStroopUnreliableBody =>
      'There aren\'t enough answers that were both correct and given in time to work out an honest gap. Your previous best gap is untouched. Play again whenever you like.';

  @override
  String get weStroopReplay => 'Play again';

  @override
  String get weStroopDone => 'Done';

  @override
  String get weTeEyebrow => 'Game';

  @override
  String get weTeTitle => 'The longer of the two';

  @override
  String get weTeIntroTitle => 'Two panels, one after the other';

  @override
  String get weTeIntroBody =>
      'A panel will light up, go dark, then light up a second time. Say which of the two stayed lit for longer. The gaps get tighter as the game goes on.';

  @override
  String get weTeIntroTooShortToCount =>
      'The durations are around a second long: too short to count. Your perception alone does the answering.';

  @override
  String get weTeIntroExample =>
      'This is the panel that will light up. Nothing else on screen will move.';

  @override
  String get weTeStart => 'Start';

  @override
  String get weTeLater => 'Later';

  @override
  String get weTeProgressTag => 'Trial';

  @override
  String get weTeWatch => 'Watch closely…';

  @override
  String get weTePrompt => 'Which one stayed lit for longer?';

  @override
  String get weTeFirst => 'The first one';

  @override
  String get weTeSecond => 'The second one';

  @override
  String get weTeResultTitle => 'Your resolution';

  @override
  String weTeThreshold(int percent) {
    return '$percent%';
  }

  @override
  String get weTeResultCaption =>
      'That\'s the smallest gap you can still tell apart between two durations. The smaller the number, the more finely your perception separates two close moments.';

  @override
  String weTeAccuracyNote(int percent) {
    return '$percent% correct — that\'s expected: the game tightens the gaps until you start hesitating.';
  }

  @override
  String weTeBest(int percent) {
    return 'Your best resolution: $percent%';
  }

  @override
  String get weTeNewBest => 'New best resolution';

  @override
  String get weTeNotSpeed =>
      'This number is not your speed: nothing timed your answers, you could take as long as you liked to decide.';

  @override
  String get weTeNotClinical =>
      'This is a game, not a clinical measure: no threshold, no ranking, nothing to conclude about you.';

  @override
  String get weTeUnreliableTitle => 'Not enough to measure a resolution';

  @override
  String get weTeUnreliableBody =>
      'The game never hesitated enough for a threshold to mean anything. Your previous best resolution is untouched. Play again whenever you like.';

  @override
  String get weTeReplay => 'Play again';

  @override
  String get weTeDone => 'Done';
}

/// The translations for English, as used in the United Kingdom (`en_GB`).
class AppLocalizationsEnGb extends AppLocalizationsEn {
  AppLocalizationsEnGb() : super('en_GB');

  @override
  String get appTitle => 'Mental E.T.';

  @override
  String get languageSwitcherTooltip => 'Change language';

  @override
  String get commonValidate => 'Confirm';

  @override
  String get commonNext => 'Next';

  @override
  String get commonBack => 'Back';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonStart => 'Start';

  @override
  String get commonSkip => 'Skip';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonClose => 'Close';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonLoading => 'Loading...';

  @override
  String get commonError => 'An error has occurred';

  @override
  String get commonYes => 'Yes';

  @override
  String get commonNo => 'No';

  @override
  String get commonOk => 'OK';

  @override
  String get commonFinish => 'Finish';

  @override
  String commonSeconds(int count) {
    return '$count s';
  }

  @override
  String get oralConsentRequiredCheckbox =>
      'I consent to my voice being recorded and analysed for the duration of this test. (required)';

  @override
  String get oralConsentCommercialCheckbox =>
      'I also consent to my recordings being reused, in anonymised form, for research and commercial purposes — including their transfer to third parties. (optional)';

  @override
  String get oralConsentRequiredHint => 'Tick the first box to begin the test.';

  @override
  String get oralConsentPrivacyLink => 'Read the privacy policy';

  @override
  String get matDiscontinue3 => '3 consecutive failures — exercise ended.';

  @override
  String get assessIntroTitle => 'New assessment';

  @override
  String get assessIntroEyebrow => 'COGNITIVE ASSESSMENT';

  @override
  String get assessIntroHero1 => 'Five indices,';

  @override
  String get assessIntroHero2 => 'one measure.';

  @override
  String get assessIntroDescription =>
      'This assessment measures your cognitive abilities across six domains of the CHC (Cattell-Horn-Carroll) model. A full-scale score brings them together.';

  @override
  String get assessDomainsHeader => 'DOMAINS MEASURED';

  @override
  String get assessDomainVci => 'Verbal Comprehension';

  @override
  String get assessDomainVsi => 'Visual-Spatial Reasoning';

  @override
  String get assessDomainFri => 'Fluid Reasoning';

  @override
  String get assessDomainWmi => 'Working Memory';

  @override
  String get assessDomainPsi => 'Processing Speed';

  @override
  String get assessDomainLo => 'Oral Language';

  @override
  String get assessBeforeStartHeader => 'BEFORE YOU START';

  @override
  String get assessBeforeStartBody =>
      'Estimated duration 60 to 90 minutes. A quiet setting and full concentration are required.';

  @override
  String get assessLaunchFullAssessment => 'Start the full assessment';

  @override
  String get assessOrIndividualSubtest => 'OR AN INDIVIDUAL SUBTEST';

  @override
  String get assessSubtestCubes => 'Blocks';

  @override
  String get assessSubtestMatrices => 'Matrix Reasoning';

  @override
  String get assessSubtestFigureWeights => 'Equilibrium';

  @override
  String get assessSubtestVisualPuzzles => 'Assembly';

  @override
  String get assessSubtestSimilarities => 'Common Ground';

  @override
  String get assessSubtestVocabulary => 'Vocabulary';

  @override
  String get assessSubtestInformation => 'Information';

  @override
  String get assessSubtestDigitSpan => 'Digit Sequences';

  @override
  String get assessSubtestArithmetic => 'Arithmetic';

  @override
  String get assessSubtestPictureSpan => 'Picture Span';

  @override
  String get assessSubtestCoding => 'Transcription';

  @override
  String get assessSubtestSymbolSearch => 'Symbol Detection';

  @override
  String get assessSubtestOralComprehension => 'Oral Comprehension';

  @override
  String get authLoginTitle => 'Sign in';

  @override
  String get authCreateAccount => 'Create account';

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authHeaderSubtitleRegister =>
      'Create an account to save your results';

  @override
  String get authHeaderSubtitleLogin => 'Sign in to access your history';

  @override
  String get authEmailLabel => 'Email address';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authFieldRequired => 'Required field';

  @override
  String get authEmailInvalid => 'Invalid email address';

  @override
  String get authPasswordMinLength => 'Minimum 8 characters';

  @override
  String get authOrDivider => 'or';

  @override
  String get authContinueWithGoogle => 'Continue with Google';

  @override
  String get authToggleToLogin => 'Already have an account? Sign in';

  @override
  String get authToggleToRegister => 'No account yet? Sign up';

  @override
  String get authFirebaseNotConfiguredFull =>
      'Firebase is not configured yet. Follow the instructions in firebase_config.dart.';

  @override
  String get authFirebaseNotConfigured => 'Firebase is not configured yet.';

  @override
  String get histTitle => 'My results';

  @override
  String get histEyebrow => 'HISTORY';

  @override
  String get histDeleteResultTitle => 'Delete this result?';

  @override
  String get histDeleteResultBody => 'This action cannot be undone.';

  @override
  String get histDelete => 'Delete';

  @override
  String histAgeYears(int age) {
    return '$age yrs';
  }

  @override
  String get histScoreFsiq => 'Full Scale IQ';

  @override
  String get histScoreShortIq => 'IQ';

  @override
  String get histScoreVci => 'Verbal Comprehension';

  @override
  String get histScoreVsi => 'Visual-Spatial';

  @override
  String get histScoreFri => 'Fluid Reasoning';

  @override
  String get histScoreWmi => 'Working Memory';

  @override
  String get histScorePsi => 'Processing Speed';

  @override
  String get histEmptyEyebrow => 'NO RESULTS';

  @override
  String get histEmptyHero1 => 'Your history';

  @override
  String get histEmptyHero2 => 'awaits you.';

  @override
  String get histEmptyDescription =>
      'Complete your first assessment to see your results appear here.';

  @override
  String get histStartAssessment => 'Start an assessment';

  @override
  String get ctIntroTitle => 'Full test';

  @override
  String get ctIntroHero1 => 'Twelve subtests,';

  @override
  String get ctIntroHero2 => 'four indices.';

  @override
  String get ctIntroDescription =>
      'A complete, standardised cognitive assessment. The subtests run one after another automatically.';

  @override
  String get ctIntroDurationEyebrow => 'DURATION';

  @override
  String get ctIntroDurationTitle => '60 to 90 minutes';

  @override
  String get ctIntroDurationBody => 'Set aside a continuous block of time.';

  @override
  String get ctIntroContentEyebrow => 'CONTENT';

  @override
  String get ctIntroContentTitle => '13 subtests included';

  @override
  String get ctIntroContentBody =>
      'Blocks · Common Ground · Digit Sequences · Matrices · Vocabulary · Arithmetic · Symbols · Assembly · Information · Transcription · Pictures · Equilibrium · Oral language.';

  @override
  String get ctIntroImportantEyebrow => 'IMPORTANT';

  @override
  String get ctIntroImportantTitle => 'Automatic sequence';

  @override
  String get ctIntroImportantBody =>
      'The tests will launch one after another. Make sure you have enough time.';

  @override
  String get ctPatientAgeHeader => 'YOUR AGE';

  @override
  String get ctPatientAgeHint => 'Required for the norms (16 to 90 years)';

  @override
  String get ctAgeSuffix => 'YRS';

  @override
  String get ctAgeRangeError => 'Age between 16 and 90 years';

  @override
  String get ctLaunchFullTest => 'Start the full test';

  @override
  String get ctRunningTitle => 'Test in progress';

  @override
  String get ctGlobalProgress => 'OVERALL PROGRESS';

  @override
  String get ctNextSubtest => 'NEXT SUBTEST';

  @override
  String get ctLaunching => 'Launching…';

  @override
  String get ctComputingResultsTitle => 'Computing results';

  @override
  String get ctComputingResultsEyebrow => 'ASSESSMENT';

  @override
  String get ctProcessing => 'PROCESSING';

  @override
  String ctTestNotFound(String testName) {
    return 'Test not found: $testName';
  }

  @override
  String get ctTestCubes => 'Blocks';

  @override
  String get ctTestSimilarities => 'Common Ground';

  @override
  String get ctTestDigitSpan => 'Digit Sequences';

  @override
  String get ctTestMatrices => 'Matrix Reasoning';

  @override
  String get ctTestVocabulary => 'Vocabulary';

  @override
  String get ctTestArithmetic => 'Arithmetic';

  @override
  String get ctTestSymbolSearch => 'Symbol Detection';

  @override
  String get ctTestVisualPuzzles => 'Assembly';

  @override
  String get ctTestInformation => 'Information';

  @override
  String get ctTestCoding => 'Transcription';

  @override
  String get ctTestPictureSpan => 'Picture Span';

  @override
  String get ctTestFigureWeights => 'Equilibrium';

  @override
  String get ctResultsTitle => 'Results';

  @override
  String get ctResultsEyebrow => 'YOUR COGNITIVE PROFILE';

  @override
  String get ctResultsHero1 => 'Assessment';

  @override
  String get ctResultsHero2 => 'complete.';

  @override
  String get ctResultsSummary =>
      'A summary of your cognitive performance across the scored exercises.';

  @override
  String ctAgeYears(int age) {
    return '$age yrs';
  }

  @override
  String get ctMetaDate => 'DATE';

  @override
  String get ctMetaDuration => 'DURATION';

  @override
  String get ctMetaSubtests => 'SUBTESTS';

  @override
  String get ctMetaAge => 'AGE';

  @override
  String get ctFsiqCardLabel => 'OVERALL SCORE';

  @override
  String ctConfidenceInterval95(int lower, int upper) {
    return '95% CI · $lower – $upper';
  }

  @override
  String ctPercentileLabel(int rank) {
    return 'Percentile · $rank';
  }

  @override
  String get ctIndexProfileHeader => 'INDEX PROFILE';

  @override
  String get ctIndexVci => 'Verbal Comprehension';

  @override
  String get ctIndexVsi => 'Visual-Spatial';

  @override
  String get ctIndexFri => 'Fluid Reasoning';

  @override
  String get ctIndexWmi => 'Working Memory';

  @override
  String get ctIndexPsi => 'Processing Speed';

  @override
  String ctIndexCiPercentile(int lower, int upper, int rank) {
    return 'CI $lower–$upper · ${rank}th %ile';
  }

  @override
  String ctIndexPercentile(int rank) {
    return '${rank}th %ile';
  }

  @override
  String get ctStandardizedScoresHeader => 'STANDARDISED SCORES';

  @override
  String get ctGroupVciVerbal => 'Verbal Comprehension';

  @override
  String get ctGroupVsiVisuoSpatial => 'Visual-Spatial';

  @override
  String get ctGroupFriReasoning => 'Fluid Reasoning';

  @override
  String get ctGroupWmiMemory => 'Working Memory';

  @override
  String get ctGroupPsiSpeed => 'Processing Speed';

  @override
  String ctRawScore(int raw) {
    return 'raw $raw';
  }

  @override
  String get ctCognitiveProfileHeader => 'COGNITIVE PROFILE';

  @override
  String get ctProfileHomogeneous =>
      'Homogeneous profile — the indices are consistent with one another.';

  @override
  String get ctProfileHeterogeneous =>
      'Heterogeneous profile — notable disparities between the indices.';

  @override
  String ctMaxDiscrepancy(int points) {
    return 'Max discrepancy · $points pts';
  }

  @override
  String get ctRelativeStrengths => 'Relative strengths';

  @override
  String get ctVigilancePoints => 'Points to watch';

  @override
  String get ctIndicativeDisclaimer =>
      'These results are indicative only. For an official clinical evaluation, please consult a neuropsychologist or a qualified psychologist.';

  @override
  String get ctRawScoresHeader => 'RAW SCORES';

  @override
  String get ctMissingAgeHeader => 'AGE MISSING';

  @override
  String get ctMissingAgeBody =>
      'Without your age, only raw scores are shown. Run the test again with the age provided to obtain the standardised IQ, percentiles and confidence intervals.';

  @override
  String get ctExportPdf => 'Export to PDF';

  @override
  String ctPdfError(String error) {
    return 'PDF error: $error';
  }

  @override
  String get ctBackToHome => 'Back to home';

  @override
  String get ctPdfSubtitle => 'Cognitive profile report';

  @override
  String get ctPdfNotProvided => 'Not provided';

  @override
  String ctPdfDurationMinSec(int min, int sec) {
    return '$min min $sec sec';
  }

  @override
  String get ctPdfAge => 'Age';

  @override
  String get ctPdfDuration => 'Duration';

  @override
  String get ctPdfDate => 'Date';

  @override
  String get ctPdfFsiqLabel => 'OVERALL SCORE';

  @override
  String get ctPdfConfidenceInterval95 => '95% confidence interval';

  @override
  String get ctPdfPercentile => 'Percentile';

  @override
  String ctPercentileValue(int rank) {
    return '${rank}th';
  }

  @override
  String get ctPdfIndexProfileHeader => 'COGNITIVE INDEX PROFILE';

  @override
  String get ctPdfIndexVci => 'Verbal Comprehension';

  @override
  String get ctPdfIndexVsi => 'Visual-Spatial';

  @override
  String get ctPdfIndexFri => 'Fluid Reasoning';

  @override
  String get ctPdfIndexWmi => 'Working Memory';

  @override
  String get ctPdfIndexPsi => 'Processing Speed';

  @override
  String get ctPdfColIndex => 'Index';

  @override
  String get ctPdfColScore => 'Score';

  @override
  String get ctPdfColClassification => 'Classification';

  @override
  String get ctPdfRawScoresHeader => 'SUBTEST RAW SCORES';

  @override
  String get ctPdfColSubtest => 'Subtest';

  @override
  String get ctPdfColRawScore => 'Raw score';

  @override
  String get ctPdfDisclaimer =>
      'DISCLAIMER: This report is generated by an assessment-support application and does not constitute an official clinical diagnosis. It must be interpreted by a qualified healthcare professional. Do not use it for medical or legal purposes without further professional evaluation.';

  @override
  String get ctResumeFullTest => 'Resume the assessment';

  @override
  String get chatEyebrow => 'AI ASSISTANT';

  @override
  String get chatNewConversation => 'New conversation';

  @override
  String get chatAssistantLabel => 'MENTAL E.T.';

  @override
  String get chatUserLabel => 'YOU';

  @override
  String get chatHeroTitle1 => 'Ask';

  @override
  String get chatHeroTitle2 => 'your questions.';

  @override
  String get chatEmptyIntro =>
      'The Mental E.T. AI helps you better understand your cognitive profile. Confidential conversations, non-directive support.';

  @override
  String get chatThinking => 'Thinking…';

  @override
  String get chatInputHint => 'Write a message…';

  @override
  String get chatTimeJustNow => 'just now';

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
      'Sorry, something went wrong. Please try again.';

  @override
  String get chatErrorEmptyResponse => 'Empty response from the worker';

  @override
  String get chatErrorAccessDenied =>
      'Access denied by the worker (origin not allowed).';

  @override
  String get chatErrorRateLimit =>
      'Request limit reached. Please try again shortly.';

  @override
  String chatErrorServer(int code) {
    return 'Server error ($code)';
  }

  @override
  String chatErrorHttp(int code, String body) {
    return 'Error $code: $body';
  }

  @override
  String get coreSplashTitleLine1 => 'Cognitive';

  @override
  String get coreSplashTitleLine2 => 'assessment';

  @override
  String get commonNotAvailable => 'N/A';

  @override
  String get pdfFilenameBase => 'mentality_results';

  @override
  String coreRouteNotFound(String path) {
    return 'Page not found: $path';
  }

  @override
  String get homeHeroTitle => 'Discover';

  @override
  String get homeHeroTitleItalic => 'your cognitive profile.';

  @override
  String get homeHeroBody =>
      'An adaptive cognitive assessment. 13 subtests, 5 indices, one overall score.';

  @override
  String get homeActionStartTitle => 'Start an assessment';

  @override
  String get homeActionStartSubtitle => 'Duration: 60 – 90 minutes';

  @override
  String get homeActionResultsTitle => 'My results';

  @override
  String get homeActionResultsSubtitle => 'Assessment history';

  @override
  String get homeActionChatTitle => 'Talk with Mental E.T.';

  @override
  String get homeActionChatSubtitle => 'AI assistant, psychology questions';

  @override
  String get homeComingSoon => 'COMING SOON';

  @override
  String get homeAboutEyebrow => 'ABOUT';

  @override
  String get homeAboutSubtestsTitle => '13 subtests';

  @override
  String get homeAboutSubtestsBody =>
      'A complete assessment of the five CHC cognitive indices.';

  @override
  String get homeAboutAdaptiveTitle => 'Adaptive AI';

  @override
  String get homeAboutAdaptiveBody =>
      'Difficulty adjusted in real time through IRT inference.';

  @override
  String get homeAboutValidationTitle => 'Theoretical framework';

  @override
  String get homeAboutValidationBody =>
      'Original items, written for Mental E.T. and built on the CHC model.';

  @override
  String get homeResumeEyebrow => 'TEST IN PROGRESS';

  @override
  String get homeResumeTitle => 'Resume your assessment';

  @override
  String get homeResumeButton => 'Resume';

  @override
  String get homeLogoutTitle => 'Sign out?';

  @override
  String get homeLogoutBody =>
      'Your token will be removed from this device. Make sure you have saved it: without it, you won\'t be able to reconnect to your data.';

  @override
  String get homeLogoutConfirm => 'Sign out';

  @override
  String homeResumeProgress(int done, int total) {
    return '$done of $total exercises';
  }

  @override
  String homeResumeNext(String name) {
    return 'Next: $name';
  }

  @override
  String get homeResumeFinish =>
      'All exercises are done — only the wrap-up remains.';

  @override
  String get homeResumeRestart => 'Start over';

  @override
  String get homeResumeRestartTitle => 'Start over from the beginning?';

  @override
  String get homeResumeRestartBody =>
      'The exercises you have already taken will be discarded and cannot be resumed. This cannot be undone.';

  @override
  String homeResumeCurrent(String name) {
    return 'In progress: $name';
  }

  @override
  String get infoTestName => 'Information';

  @override
  String get infoEyebrow => 'VERBAL COMPREHENSION';

  @override
  String infoTrailingStatus(int seconds, int score, int attempted) {
    return '${seconds}s · $score/$attempted';
  }

  @override
  String get infoCorrect => 'Correct!';

  @override
  String get infoIncorrect => 'Incorrect';

  @override
  String get infoFeedbackRight => 'Correct answer! +1 point';

  @override
  String get infoFeedbackWrong => 'Wrong answer. 0 points';

  @override
  String infoQuestionLabel(String question) {
    return 'Question: $question';
  }

  @override
  String infoCorrectAnswerLabel(String answer) {
    return 'Correct answer: $answer';
  }

  @override
  String infoTimeLabel(int seconds) {
    return 'Time: ${seconds}s';
  }

  @override
  String infoScoreLabel(int score, int attempted) {
    return 'Score: $score/$attempted';
  }

  @override
  String infoDomainLabel(String domain) {
    return 'Domain: $domain';
  }

  @override
  String get infoDiscontinue3 => '3 consecutive failures — exercise ended.';

  @override
  String get infoSeeResults => 'See results';

  @override
  String get infoResultsTitle => 'Information Test – Results';

  @override
  String infoRawScore(int score, int max) {
    return 'Raw score: $score/$max points';
  }

  @override
  String infoItemsCompleted(int completed, int total) {
    return 'Items completed: $completed/$total';
  }

  @override
  String infoPercentage(int percent) {
    return 'Percentage: $percent%';
  }

  @override
  String infoTotalTime(int seconds) {
    return 'Total time: ${seconds}s';
  }

  @override
  String get infoTestSubtitle => 'Test of acquired general knowledge';

  @override
  String get infoDomainBreakdownTitle => 'Breakdown by domain:';

  @override
  String infoDomainBreakdownRow(String domain, int correct, int total) {
    return '$domain: $correct/$total';
  }

  @override
  String get infoPerfExceptional => 'Exceptional performance (θ > +2.0)';

  @override
  String get infoPerfSuperior => 'Superior performance (θ > +1.0)';

  @override
  String get infoPerfAverage => 'Average performance (θ ≈ 0)';

  @override
  String get infoPerfBelow => 'Below-average performance (θ < 0)';

  @override
  String get infoPerfLow => 'Low performance (θ < -1.0)';

  @override
  String get infoDomainScience => 'Natural sciences';

  @override
  String get infoDomainHistoryGeography => 'History/Geography';

  @override
  String get infoDomainGeneralCulture => 'General knowledge';

  @override
  String get infoDomainMathLogic => 'Mathematics/Logic';

  @override
  String get infoDomainArtsLiterature => 'Arts/Literature';

  @override
  String get infoDifficultyEasy => 'Easy';

  @override
  String get infoDifficultyMedium => 'Medium';

  @override
  String get infoDifficultyHard => 'Hard';

  @override
  String get arithTestName => 'Arithmetic';

  @override
  String get arithEyebrow => 'WORKING MEMORY';

  @override
  String get arithStartTest => 'Start the test';

  @override
  String get arithIntroTitle => 'Arithmetic Test';

  @override
  String get arithIntroDescription =>
      'This test measures your working memory and numerical reasoning.';

  @override
  String get arithInfoMentalTitle => 'Mental arithmetic only';

  @override
  String get arithInfoMentalSubtitle =>
      'Solve the problems without paper or a calculator';

  @override
  String get arithInfoTimeTitle => 'Limited time';

  @override
  String get arithInfoTimeSubtitle =>
      'Each problem has a time limit (15-60 seconds)';

  @override
  String get arithInfoBonusTitle => 'Speed bonus';

  @override
  String get arithInfoBonusSubtitle =>
      'Quick answers on certain items = bonus points';

  @override
  String get arithInfoRepeatTitle => 'Repeat available';

  @override
  String get arithInfoRepeatSubtitle =>
      'You may ask for ONE repeat (the timer keeps running)';

  @override
  String get arithIntroDiscontinueNote =>
      '22 problems in total. The test stops after 3 consecutive failures.';

  @override
  String arithProblemCounter(int current, int total) {
    return 'Problem $current/$total';
  }

  @override
  String get arithRepeatTitle => 'Repeat the problem';

  @override
  String get arithUnderstood => 'Got it';

  @override
  String get arithTimeUp => 'Time\'s up!';

  @override
  String arithCorrectAnswerLabel(int answer) {
    return 'Correct answer: $answer';
  }

  @override
  String get arithCorrect => 'Correct!';

  @override
  String get arithIncorrect => 'Incorrect';

  @override
  String arithTimeSpent(int seconds) {
    return 'Time: $seconds seconds';
  }

  @override
  String get arithSpeedBonus => '🎉 Speed bonus! (+1 point)';

  @override
  String get arithTestEnded => 'Test complete!';

  @override
  String arithItemsCompleted(int completed, int total) {
    return 'Items completed: $completed/$total';
  }

  @override
  String arithBaseScore(int score) {
    return 'Base score: $score points';
  }

  @override
  String arithBonusScore(int bonus) {
    return 'Speed bonus: $bonus points';
  }

  @override
  String arithTotalScore(int total) {
    return 'Total score: $total points';
  }

  @override
  String get arithRepeat => 'Repeat';

  @override
  String get arithAnswerHint => 'Your answer';

  @override
  String get arithDifficultyEasy => 'Easy';

  @override
  String get arithDifficultyMedium => 'Medium';

  @override
  String get arithDifficultyHard => 'Hard';

  @override
  String get arithDifficultyVeryHard => 'Very hard';

  @override
  String get oralMicAccessTitle => 'Microphone access';

  @override
  String get oralReadingPermissionBody1 =>
      'This activity records your voice while you read the text aloud.';

  @override
  String get oralReadingPermissionBody2 =>
      'Your recordings will be anonymised and may help to improve speech recognition.';

  @override
  String get oralBrowserWillAskMic =>
      'Your browser will then ask you to allow the microphone.';

  @override
  String get oralCancel => 'Cancel';

  @override
  String get oralAllowMicrophone => 'Allow microphone';

  @override
  String get oralMicDeniedOrUnavailable => 'Microphone denied or unavailable.';

  @override
  String get oralCannotStartRecording =>
      'Unable to start recording on this browser.';

  @override
  String oralCanSkipToNextStep(String message) {
    return '$message You can move on to the next step.';
  }

  @override
  String get oralSkip => 'Skip';

  @override
  String get oralRecordingInProgress => 'Recording in progress';

  @override
  String oralKeepGoingSeconds(int seconds) {
    return 'Keep going for ${seconds}s more...';
  }

  @override
  String get oralSaving => 'Saving...';

  @override
  String get oralReadingInstructions =>
      'Read the following text aloud, clearly and at your natural pace. Press \"Start\" when you are ready.';

  @override
  String get oralStartReading => 'Start reading';

  @override
  String get oralFinish => 'Finish';

  @override
  String get oralSkipThisStep => 'Skip this step';

  @override
  String get oralSummaryPermissionBody1 =>
      'You will now record your spoken summary of the text.';

  @override
  String get oralSummaryPermissionBody2 =>
      'Speak naturally, as if you were explaining the text to a friend. Take between 30 and 60 seconds.';

  @override
  String get oralStartSummary => 'Start the summary';

  @override
  String get oralSummaryInstructionLead => 'You have just read this text. ';

  @override
  String get oralSummaryInstructionBody =>
      'Summarise what you understood in your own words. Take between 30 and 60 seconds. Speak naturally, as if you were explaining it to a friend.';

  @override
  String get oralReferenceText => 'Reference text';

  @override
  String get oralFinishSummary => 'Finish the summary';

  @override
  String get oralFlowTitle => 'Audio collection';

  @override
  String get oralConsentTitle => 'Oral Comprehension Test';

  @override
  String get oralConsentRecordTitle => 'What we record';

  @override
  String get oralConsentRecordBody =>
      'Your voice while you read 5 short texts (about 1 min each) and your spoken summary (about 40 seconds per text).';

  @override
  String get oralConsentAnonTitle => 'Privacy';

  @override
  String get oralConsentAnonBody =>
      'Your recordings are identified by a random session code, not by your name. They remain linkable to your account, however: they are personal data, encrypted and stored in Europe.';

  @override
  String get oralConsentUsageTitle => 'How it is used';

  @override
  String get oralConsentUsageBody =>
      'These recordings may help to improve speech recognition, notably for models such as Whisper or Speechmatics.';

  @override
  String get oralAcceptAndStart => 'I accept and start';

  @override
  String get oralDeclineAndGoBack => 'Decline and go back';

  @override
  String get oralWithdrawConsentNote =>
      'You can withdraw your consent at any time from the app settings.';

  @override
  String oralTextProgress(int current) {
    return 'Text $current of 5';
  }

  @override
  String get oralStepReading => 'Reading';

  @override
  String get oralStepSummary => 'Summary';

  @override
  String get oralPauseWellDone => 'Well done!';

  @override
  String get oralPauseNowSummarize => 'Now, summarise this text aloud.';

  @override
  String get oralPauseStartingIn => 'Starting in...';

  @override
  String get oralCompletedThanks => 'Thank you!';

  @override
  String get oralCompletedBody =>
      'You have completed all 5 texts.\nYour recordings will help to improve\nspeech recognition.';

  @override
  String get oralBackToHome => 'Back to home';

  @override
  String get oralExitDialogTitle => 'Leave?';

  @override
  String get oralExitDialogBody =>
      'A recording is in progress. If you leave now, it will not be saved.';

  @override
  String get oralContinue => 'Continue';

  @override
  String get oralQuit => 'Leave';

  @override
  String get preEyebrow => 'Before you start';

  @override
  String get preQ1Title => 'Have you ever taken an IQ test?';

  @override
  String get preQ1Body =>
      'One question, to place what you are about to measure. Your answer changes neither the test nor your score.';

  @override
  String get preQ1Professional => 'Yes, with a psychiatrist or a psychologist';

  @override
  String get preQ1Online => 'Yes, an unreliable test online';

  @override
  String get preQ1Never => 'No, never — but I have always wanted to';

  @override
  String get preLocalNotice =>
      'Your answers stay on your phone, encrypted. Nothing is sent.';

  @override
  String get prePastEyebrow => 'That earlier test';

  @override
  String get prePastTitle => 'Two optional questions';

  @override
  String get prePastBody =>
      'You can continue without answering them. Nothing here goes into your score.';

  @override
  String get prePastAgeLabel => 'How old were you when you took it?';

  @override
  String get prePastAgeError => 'An age between 5 and 90.';

  @override
  String get prePastScoreLabel => 'What score did you get?';

  @override
  String get prePastScoreError => 'A score between 40 and 200.';

  @override
  String get preEstimateEyebrow => 'Before the first exercise';

  @override
  String get preEstimateTitle => 'What do you think your IQ is?';

  @override
  String get preEstimateBody =>
      'Asked now, before the first exercise: once a result is in front of you, your answer would no longer be a belief. 100 is the average.';

  @override
  String get preEstimateHint => 'Slide, or tap − and +, to choose.';

  @override
  String get preEstimateAverage => '100 is the average.';

  @override
  String get preEstimateConfirm => 'Confirm my estimate';

  @override
  String get preEstimateDecline => 'I would rather not answer';

  @override
  String get preEstimateDecrease => 'Decrease by one point';

  @override
  String get preEstimateIncrease => 'Increase by one point';

  @override
  String regStepEyebrow(int step) {
    return 'STEP $step / 4';
  }

  @override
  String get regStepEyebrowSuccess => 'STEP 4 / 4 · SUCCESS';

  @override
  String get regEmailTitle => 'Create my token';

  @override
  String get regEmailHeading => 'Your email';

  @override
  String get regEmailIntro =>
      'We\'ll send you a 6-digit verification code. Your email isn\'t linked to your token and remains private.';

  @override
  String get regEmailFieldLabel => 'Email address';

  @override
  String get regEmailInvalid => 'Invalid email';

  @override
  String get regSendingCode => 'Sending code…';

  @override
  String get regReceiveCode => 'Get the code';

  @override
  String get regEmailPrivacyNote =>
      'No first name, surname or exact address will be stored. Only your sex, age range and postcode are encoded (encrypted) in your anonymous token.';

  @override
  String get regEmailOtpTitle => 'Verify my email';

  @override
  String get regCodeSentTo => 'Code sent to';

  @override
  String get regVerifying => 'Verifying…';

  @override
  String get regResendCode => 'Resend the code';

  @override
  String get regPhoneTitle => 'Your phone';

  @override
  String get regPhoneIntro =>
      'A 6-digit SMS code will be sent to verify your number. Your number is never linked to your token.';

  @override
  String get regPhoneFieldHint => 'Phone number';

  @override
  String get regSendingSms => 'Sending SMS…';

  @override
  String get regReceiveSms => 'Get the SMS';

  @override
  String get regPhoneOtpTitle => 'Verify my phone';

  @override
  String get regSmsSentTo => 'SMS sent to';

  @override
  String get regResendSms => 'Resend the SMS';

  @override
  String get regDemoTitle => 'Your demographic data';

  @override
  String get regDemoIntro =>
      'This information will be encrypted in your token. No exact value is stored (neither your precise age nor your precise address).';

  @override
  String get regSectionSex => 'SEX';

  @override
  String get regSectionAgeBucket => 'AGE RANGE';

  @override
  String get regSectionCountryPostal => 'COUNTRY AND POSTCODE';

  @override
  String get regPostalCodeHint => 'Postcode';

  @override
  String get regGeneratingToken => 'Generating token…';

  @override
  String get regGenerateMyToken => 'Generate my token';

  @override
  String get regSuccessTitle => 'Welcome to Mental E.T.';

  @override
  String get regSuccessTokenSaved =>
      'Your anonymous token has been generated and saved on this device.';

  @override
  String get regSuccessTokenDetails =>
      'It contains neither your email, nor your phone number, nor your name. Only your sex, age range and geographic area (encrypted). You can now begin your cognitive assessment.';

  @override
  String get regImportantLabel => 'IMPORTANT';

  @override
  String get regSuccessWarning =>
      'Do not uninstall the app before completing your assessment: your token is only stored on this device. If you lose it, you won\'t be able to create a new account with the same email or phone number.';

  @override
  String get regEmailAlreadyRegistered =>
      'This email already has an account. If it\'s yours, you already have a token.';

  @override
  String get regEmailUnavailable => 'Email unavailable.';

  @override
  String get regOtpIncorrectOrExpired => 'Incorrect or expired code.';

  @override
  String get regPhoneAlreadyRegistered => 'This number already has an account.';

  @override
  String get regPhoneUnavailable => 'Number unavailable.';

  @override
  String get regEmailAlreadyHasToken => 'This email already has a token.';

  @override
  String get regPhoneAlreadyHasToken => 'This number already has a token.';

  @override
  String get regPostalNotFound =>
      'Postcode not found. Please check the country and the code.';

  @override
  String get regNoInternet => 'No internet connection.';

  @override
  String get regGenericRetryError => 'Error — please try again.';

  @override
  String get regSexMale => 'Male';

  @override
  String get regSexFemale => 'Female';

  @override
  String get regSexUndisclosed => 'Prefer not to say';

  @override
  String get regAge1825 => '18 – 25 years';

  @override
  String get regAge2635 => '26 – 35 years';

  @override
  String get regAge3645 => '36 – 45 years';

  @override
  String get regAge4655 => '46 – 55 years';

  @override
  String get regAge5665 => '56 – 65 years';

  @override
  String get regAge66plus => '66 years and over';

  @override
  String get scoringClassificationVerySuperior => 'Very Superior';

  @override
  String get scoringClassificationSuperior => 'Superior';

  @override
  String get scoringClassificationHighAverage => 'High Average';

  @override
  String get scoringClassificationAverage => 'Average';

  @override
  String get scoringClassificationLowAverage => 'Low Average';

  @override
  String get scoringClassificationBorderline => 'Borderline';

  @override
  String get scoringClassificationExtremelyLow => 'Extremely Low';

  @override
  String get scoringNotAvailable => 'N/A';

  @override
  String scoringSummaryFullScaleIq(int score, String classification) {
    return 'Full Scale IQ: $score ($classification)';
  }

  @override
  String scoringSummaryPercentile(int rank) {
    return 'Percentile: $rank';
  }

  @override
  String scoringSummaryConfidenceInterval(int lower, int upper) {
    return '95% confidence interval: $lower - $upper';
  }

  @override
  String get scoringIndexVerbalComprehension => 'Verbal Comprehension';

  @override
  String get scoringIndexVisualSpatial => 'Visual Spatial';

  @override
  String get scoringIndexFluidReasoning => 'Fluid Reasoning';

  @override
  String get scoringIndexWorkingMemory => 'Working Memory';

  @override
  String get scoringIndexProcessingSpeed => 'Processing Speed';

  @override
  String scoringSummaryRelativeStrengths(String list) {
    return 'Relative strengths: $list';
  }

  @override
  String scoringSummaryRelativeWeaknesses(String list) {
    return 'Relative weaknesses: $list';
  }

  @override
  String get scoringSummaryHomogeneousProfile =>
      'Homogeneous cognitive profile';

  @override
  String scoringSummaryHeterogeneousProfile(int points) {
    return 'Heterogeneous cognitive profile (maximum discrepancy: $points points)';
  }

  @override
  String get simTestName => 'Common Ground';

  @override
  String get simEyebrow => 'VERBAL COMPREHENSION';

  @override
  String simStatusBar(int seconds, int score) {
    return '${seconds}s · $score pts';
  }

  @override
  String get simQuestionPrompt => 'How are these two words alike?';

  @override
  String simLevelLabel(String level) {
    return 'Level: $level';
  }

  @override
  String get simLevelConcrete => 'Concrete';

  @override
  String get simLevelFunctional => 'Functional';

  @override
  String get simLevelCategorical => 'Categorical';

  @override
  String get simLevelAbstract => 'Abstract';

  @override
  String get simAnswerLabel => 'Your answer:';

  @override
  String get simAnswerHint => 'Explain how they are alike...';

  @override
  String get simTipsTitle => 'Tips for scoring 2 points:';

  @override
  String get simTipsLine1 => '• Give an abstract or superordinate category';

  @override
  String get simTipsLine2 =>
      '• E.g. \"They are...\", \"Forms of...\", \"Types of...\"';

  @override
  String get simFeedbackExcellent => 'Excellent!';

  @override
  String get simFeedbackCorrect => 'Correct';

  @override
  String get simFeedbackIncomplete => 'Incomplete answer';

  @override
  String get simFeedbackMsg2pts => 'Abstract/categorical answer! +2 points';

  @override
  String get simFeedbackMsg1pt => 'Functional/property answer. +1 point';

  @override
  String get simFeedbackMsg0pt => 'Incorrect or overly vague answer. 0 points';

  @override
  String simYourAnswerQuoted(String answer) {
    return 'Your answer: \"$answer\"';
  }

  @override
  String get simExamples2pts => 'Examples of 2-point answers:';

  @override
  String get simExamples1pt => 'Examples of 1-point answers:';

  @override
  String simTimeSeconds(int seconds) {
    return 'Time: ${seconds}s';
  }

  @override
  String simTotalScore(int score) {
    return 'Total score: $score points';
  }

  @override
  String get simDiscontinue => '3 items skipped in a row — exercise ended.';

  @override
  String get simSeeResults => 'View results';

  @override
  String get simResultsTitle => 'Common Ground — Results';

  @override
  String simRawScore(int score, int max) {
    return 'Raw score: $score/$max points';
  }

  @override
  String simItemsCompleted(int completed, int total) {
    return 'Items completed: $completed/$total';
  }

  @override
  String simPercentage(int percent) {
    return 'Percentage: $percent%';
  }

  @override
  String simTotalTime(int seconds) {
    return 'Total time: ${seconds}s';
  }

  @override
  String get simSubtitle =>
      'A test of verbal reasoning and conceptual abstraction';

  @override
  String get simBreakdownTitle => 'Breakdown by level:';

  @override
  String simBreakdownLine(String level, int total, int max) {
    return '$level: $total/$max points';
  }

  @override
  String get simPerfExceptional => 'Exceptional performance (θ > +2.0)';

  @override
  String get simPerfSuperior => 'Superior performance (θ > +1.0)';

  @override
  String get simPerfAverage => 'Average performance (θ ≈ 0)';

  @override
  String get simPerfBelow => 'Below-average performance (θ < 0)';

  @override
  String get simPerfLow => 'Low performance (θ < -1.0)';

  @override
  String get simBack => 'Back';

  @override
  String get matTestName => 'Progressive Matrices';

  @override
  String get matEyebrow => 'IQ TEST';

  @override
  String get matCorrect => 'Correct!';

  @override
  String get matIncorrect => 'Incorrect';

  @override
  String matResponseTime(int seconds) {
    return 'Response time: ${seconds}s';
  }

  @override
  String matScoreFraction(int score, int total) {
    return 'Score: $score/$total';
  }

  @override
  String get matDiscontinue4 => '4 consecutive failures — exercise ended.';

  @override
  String get matSeeResultsEnded => 'See results (test ended)';

  @override
  String get matNextItem => 'Next item';

  @override
  String get matSeeResults => 'See results';

  @override
  String get matFinishedTitle => 'Matrix test completed!';

  @override
  String get matRawScore => 'Raw score';

  @override
  String get matSuccessRate => 'Success rate';

  @override
  String get matAvgTimePerItem => 'Avg time/item';

  @override
  String get matEvaluation => 'Assessment:';

  @override
  String get matPerfExcellent => 'Excellent! Very superior fluid reasoning.';

  @override
  String get matPerfVeryGood => 'Very good! Strong logical analysis skills.';

  @override
  String get matPerfGood => 'Good. Average to good ability.';

  @override
  String get matPerfAverage => 'Average. There is room for improvement.';

  @override
  String get matPerfBelowAverage =>
      'Below-average results. Practice recommended.';

  @override
  String matPoints(int score) {
    return '$score pts';
  }

  @override
  String get matValidateAnswer => 'Submit answer';

  @override
  String get matRestart => 'Restart';

  @override
  String matRulesTheta(int rules, String theta) {
    return 'Rules: $rules | θ = $theta';
  }

  @override
  String get matInstruction =>
      'Find the missing piece that logically completes the matrix';

  @override
  String get matChooseAnswer => 'Choose your answer:';

  @override
  String get matDiffEasy => 'Easy';

  @override
  String get matDiffMediumEasy => 'Medium-Easy';

  @override
  String get matDiffMedium => 'Medium';

  @override
  String get matDiffMediumHard => 'Medium-Hard';

  @override
  String get matDiffHard => 'Hard';

  @override
  String get cubesTestName => 'Blocks';

  @override
  String get cubesBravo => 'Well done!';

  @override
  String cubesElapsedTime(String time) {
    return 'Elapsed time: $time';
  }

  @override
  String cubesPointsEarned(int points) {
    return 'Points earned: $points';
  }

  @override
  String cubesTotalScore(int score) {
    return 'Total score: $score';
  }

  @override
  String get cubesFinishedTitle => 'Test completed!';

  @override
  String get cubesTotalScoreLabel => 'Total score';

  @override
  String cubesTotalScoreValue(int score, int max) {
    return '$score/$max pts';
  }

  @override
  String get cubesItemsCompletedLabel => 'Items completed';

  @override
  String cubesItemsCompletedValue(int count) {
    return '$count/14';
  }

  @override
  String get cubesAvgTime => 'Avg time';

  @override
  String get cubesPerfExcellent =>
      'Excellent! Very superior visuospatial ability.';

  @override
  String get cubesPerfVeryGood => 'Very good! Strong visual analysis skills.';

  @override
  String get cubesDiffExample => 'Example';

  @override
  String get cubesDiffVeryHard => 'Very hard';

  @override
  String get cubesDescExample =>
      'Example item — does not count towards the score';

  @override
  String get cubesDesc2x2 => 'Simple 2×2 pattern';

  @override
  String get cubesDesc3x3Diagonals => '3×3 pattern with diagonals';

  @override
  String get cubesDesc3x3Complex => 'Complex 3×3 pattern — high cohesion';

  @override
  String cubesCohesion(int score) {
    return 'Cohesion: $score';
  }

  @override
  String cubesRemaining(String time) {
    return 'Left: $time';
  }

  @override
  String get cubesReproduceInstruction =>
      'Reproduce the pattern below by tapping on the blocks';

  @override
  String get cubesPatternToReproduce => 'Pattern to reproduce:';

  @override
  String get cubesYourAnswer => 'Your answer:';

  @override
  String get cubesReset => 'Reset';

  @override
  String get fwTestName => 'Equilibrium';

  @override
  String get fwEyebrow => 'FLUID REASONING';

  @override
  String get fwCorrectAnswerPoint => 'Correct answer! +1 point';

  @override
  String get fwWrongAnswer => 'Wrong answer. The correct answer was:';

  @override
  String fwTime(int seconds) {
    return 'Time: ${seconds}s';
  }

  @override
  String get fwDiscontinue3 => '3 consecutive failures — exercise ended.';

  @override
  String get fwSeeResults => 'See results';

  @override
  String get fwResultsTitle => 'Equilibrium — Results';

  @override
  String fwRawScorePoints(int score) {
    return 'Raw score: $score/27 points';
  }

  @override
  String fwItemsCompleted(int count) {
    return 'Items completed: $count/27';
  }

  @override
  String fwPercentage(int percent) {
    return 'Percentage: $percent%';
  }

  @override
  String fwTotalTime(int seconds) {
    return 'Total time: ${seconds}s';
  }

  @override
  String get fwGLoading =>
      'This exercise is strongly linked to general reasoning.';

  @override
  String get fwPerfExceptional => 'Exceptional performance (θ > +2.0)';

  @override
  String get fwPerfSuperior => 'Superior performance (θ > +1.0)';

  @override
  String get fwPerfAverage => 'Average performance (θ ≈ 0)';

  @override
  String get fwPerfInferior => 'Below-average performance (θ < 0)';

  @override
  String get fwPerfLow => 'Low performance (θ < -1.0)';

  @override
  String fwScoreFraction(int score, int total) {
    return '$score/$total';
  }

  @override
  String get fwInstruction => 'Find the missing value that balances the scale.';

  @override
  String get fwWhatIs => 'What is ';

  @override
  String fwSeconds(int seconds) {
    return '${seconds}s';
  }

  @override
  String get vpTestName => 'Assembly';

  @override
  String get vpEyebrow => 'VISUOSPATIAL';

  @override
  String get vpCorrect => 'Correct';

  @override
  String get vpIncorrect => 'Incorrect';

  @override
  String get vpValidate => 'Submit';

  @override
  String vpSelectedCount(int count) {
    return '$count / 3 selected';
  }

  @override
  String get vpInstruction =>
      'Choose the 3 pieces that form the figure (rotations allowed, flips not allowed).';

  @override
  String vpSelectionSemantics(int filled, int total) {
    return 'Selection: $filled of $total pieces';
  }

  @override
  String get vpSelectionLabel => 'SELECTION';

  @override
  String vpPieceSemantics(String label) {
    return 'Piece $label';
  }

  @override
  String get vpTargetTitle => 'FIGURE TO REBUILD';

  @override
  String get codingTestName => 'Transcription';

  @override
  String get codingEyebrow => 'PROCESSING SPEED';

  @override
  String get codingStartTraining => 'Start practice';

  @override
  String get codingTitle => 'Transcription';

  @override
  String get codingDescription =>
      'This test measures your processing speed and visuomotor coordination.';

  @override
  String get codingReferenceKey => 'Reference key:';

  @override
  String get codingTaskTitle => 'Your task';

  @override
  String get codingTaskDesc =>
      'For each digit shown, select the matching symbol';

  @override
  String get codingTimeLimitTitle => 'Time limit';

  @override
  String get codingTimeLimitDesc =>
      '120 seconds to complete as many cells as possible (135 in total)';

  @override
  String get codingScoringTitle => 'Scoring';

  @override
  String get codingScoringDesc =>
      '1 point per correct cell, no penalty for errors';

  @override
  String get codingTrainingDoneTitle => 'Practice complete';

  @override
  String get codingTrainingDoneBody =>
      'You are ready to begin the test. You will have 120 seconds to complete as many cells as possible.';

  @override
  String get codingStartTest => 'Start test';

  @override
  String get codingTestDoneTitle => 'Test complete!';

  @override
  String get codingTimeElapsed => 'Time elapsed: 120 seconds';

  @override
  String codingCellsCompleted(int count) {
    return 'Cells completed: $count/135';
  }

  @override
  String codingCellsCorrect(int count) {
    return 'Correct cells: $count';
  }

  @override
  String codingScorePoints(int count) {
    return 'Score: $count points';
  }

  @override
  String get codingPerfExceptional => 'Exceptional performance!';

  @override
  String get codingPerfVeryGood => 'Very good performance';

  @override
  String get codingPerfAboveAverage => 'Above-average performance';

  @override
  String get codingPerfAverage => 'Average performance';

  @override
  String get codingPerfBelowAverage => 'Below-average performance';

  @override
  String get codingTrainingTab => 'Practice';

  @override
  String get codingReferenceShort => 'Reference:';

  @override
  String codingCellProgress(int current, int total) {
    return 'Cell $current/$total';
  }

  @override
  String codingCompletedProgress(int count, int total) {
    return 'Completed: $count/$total';
  }

  @override
  String get codingSelectSymbol => 'Select a symbol:';

  @override
  String get codingClear => 'Clear';

  @override
  String get codingFinishTraining => 'Finish practice';

  @override
  String get ssTestName => 'Symbol Detection';

  @override
  String get ssDescription =>
      'This test measures your visual processing speed and discrimination ability.';

  @override
  String get ssExampleLabel => 'Example item:';

  @override
  String get ssTargets => 'TARGETS';

  @override
  String get ssGroup => 'GROUP';

  @override
  String get ssExampleAnswer => '→ Answer: YES (┴ is present)';

  @override
  String get ssTaskTitle => 'Your task';

  @override
  String get ssTaskDesc =>
      'Check whether one of the target symbols appears in the group';

  @override
  String get ssQuickAnswerTitle => 'Quick answer';

  @override
  String get ssQuickAnswerDesc => 'Tap YES or NO as quickly as possible';

  @override
  String get ssScoringPenaltyTitle => 'Scoring with penalty';

  @override
  String get ssScoringPenaltyDesc =>
      'Score = Correct answers - Incorrect answers';

  @override
  String get ssTimeLimitTitle => 'Time limit';

  @override
  String get ssTimeLimitDesc => '120 seconds for 60 items';

  @override
  String get ssTrainingDoneBody =>
      'You are ready! You will have 120 seconds to complete as many items as possible.\n\nReminder: Score = Correct answers - Incorrect answers';

  @override
  String ssItemsAnswered(int count) {
    return 'Items answered: $count/60';
  }

  @override
  String ssCorrectAnswers(int count) {
    return 'Correct answers: $count';
  }

  @override
  String ssIncorrectAnswers(int count) {
    return 'Incorrect answers: $count';
  }

  @override
  String ssNotAnswered(int count) {
    return 'Not answered: $count';
  }

  @override
  String ssRawScore(int count) {
    return 'Raw score: $count';
  }

  @override
  String get ssScoreFormulaShort => '(Correct - Incorrect)';

  @override
  String get ssPerfGood => 'Good performance';

  @override
  String ssItemProgress(int current, int total) {
    return 'Item $current/$total';
  }

  @override
  String ssAnsweredProgress(int count) {
    return 'Answered: $count/60';
  }

  @override
  String get ssTargetSymbols => 'TARGET SYMBOLS';

  @override
  String get ssSearchGroup => 'SEARCH GROUP';

  @override
  String get ssNo => 'NO';

  @override
  String get ssYes => 'YES';

  @override
  String get dsTestName => 'Digit Sequences';

  @override
  String get dsEyebrow => 'WORKING MEMORY';

  @override
  String get dsDescription =>
      'This test measures your working memory across 3 distinct parts:';

  @override
  String get dsForwardTitle => 'Part 1: Forward Span';

  @override
  String get dsForwardInstruction => 'Repeat the digits in the same order';

  @override
  String get dsBackwardTitle => 'Part 2: Backward Span';

  @override
  String get dsBackwardInstruction => 'Repeat the digits in reverse order';

  @override
  String get dsSequencingTitle => 'Part 3: Sequencing';

  @override
  String get dsSequencingInstruction => 'Repeat the digits in ascending order';

  @override
  String get dsPresentationInfo =>
      'The digits will be presented at a rate of 1 digit per second.';

  @override
  String get dsTypeForward => 'Forward Span';

  @override
  String get dsTypeBackward => 'Backward Span';

  @override
  String get dsTypeSequencing => 'Sequencing';

  @override
  String get dsStartPart => 'Start';

  @override
  String dsLengthTrial(int length, int trial) {
    return 'Length $length - Trial $trial';
  }

  @override
  String get dsListenCarefully => 'Listen carefully';

  @override
  String get dsCorrect => 'Correct!';

  @override
  String get dsIncorrect => 'Incorrect';

  @override
  String dsPointsEarned(int count) {
    return 'Points earned: $count';
  }

  @override
  String dsCorrectAnswer(String answer) {
    return 'Correct answer: $answer';
  }

  @override
  String dsYourAnswer(String answer) {
    return 'Your answer: $answer';
  }

  @override
  String get dsResultsByPart => 'Results by part:';

  @override
  String dsForwardScore(int count) {
    return 'Forward Span: $count points';
  }

  @override
  String dsBackwardScore(int count) {
    return 'Backward Span: $count points';
  }

  @override
  String dsSequencingScore(int count) {
    return 'Sequencing: $count points';
  }

  @override
  String dsTotalScore(int count) {
    return 'Total score: $count points';
  }

  @override
  String get dsEnterAnswer => 'Enter your answer...';

  @override
  String dsValidateProgress(int count, int total) {
    return 'Submit ($count/$total)';
  }

  @override
  String get psTestName => 'Picture Span';

  @override
  String get psDescription =>
      'This test measures your visual working memory and selective attention.';

  @override
  String get psPhase1Title => 'Phase 1: Memorisation';

  @override
  String get psPhase1Desc =>
      'Images will be presented one by one (3 seconds each)';

  @override
  String get psPhase2Title => 'Phase 2: Recall';

  @override
  String get psPhase2Desc =>
      'Select the images in the exact order they were presented';

  @override
  String get psProgressionTitle => 'Progression';

  @override
  String get psProgressionDesc =>
      'Difficulty increases: 1 to 6 images to memorise';

  @override
  String get psTrialsInfo =>
      '12 trials in total. The test stops after 2 failures at the same level.';

  @override
  String get psMemorizationTab => 'Memorisation';

  @override
  String get psRecallTab => 'Recall';

  @override
  String psLevelTrial(int level, int trial) {
    return 'Level $level - Trial $trial';
  }

  @override
  String get psMemorizeImages => 'Memorise the images';

  @override
  String psImageProgress(int current, int total) {
    return 'Image $current / $total';
  }

  @override
  String psSelectInOrder(int count) {
    return 'Select the $count images in order';
  }

  @override
  String get psNoSelection => 'No selection';

  @override
  String get psClearLast => 'Clear last selection';

  @override
  String psCorrectOrder(String names) {
    return 'Correct order: $names';
  }

  @override
  String psYourOrder(String names) {
    return 'Your order: $names';
  }

  @override
  String psTrialsCompleted(int count) {
    return 'Trials completed: $count/12';
  }

  @override
  String psScorePoints(int count) {
    return 'Total score: $count points';
  }

  @override
  String psMaxLevel(int level) {
    return 'Highest level reached: Level $level';
  }

  @override
  String get psImgChat => 'Cat';

  @override
  String get psImgInsecte => 'Insect';

  @override
  String get psImgLapin => 'Rabbit';

  @override
  String get psImgOiseau => 'Bird';

  @override
  String get psImgPoisson => 'Fish';

  @override
  String get psImgTortue => 'Tortoise';

  @override
  String get psImgPapillon => 'Butterfly';

  @override
  String get psImgCoccinelle => 'Ladybird';

  @override
  String get psImgChaise => 'Chair';

  @override
  String get psImgLampe => 'Lamp';

  @override
  String get psImgMontre => 'Watch';

  @override
  String get psImgParapluie => 'Umbrella';

  @override
  String get psImgSac => 'Bag';

  @override
  String get psImgLit => 'Bed';

  @override
  String get psImgPorte => 'Door';

  @override
  String get psImgFenetre => 'Window';

  @override
  String get psImgGateau => 'Cake';

  @override
  String get psImgCafe => 'Coffee';

  @override
  String get psImgPizza => 'Pizza';

  @override
  String get psImgPomme => 'Apple';

  @override
  String get psImgGlace => 'Ice cream';

  @override
  String get psImgBurger => 'Burger';

  @override
  String get psImgSandwich => 'Sandwich';

  @override
  String get psImgOeuf => 'Egg';

  @override
  String get psImgMarteau => 'Hammer';

  @override
  String get psImgCle => 'Spanner';

  @override
  String get psImgCiseaux => 'Scissors';

  @override
  String get psImgPinceau => 'Brush';

  @override
  String get psImgCrayon => 'Pencil';

  @override
  String get psImgCouteau => 'Knife';

  @override
  String get psImgTournevis => 'Screwdriver';

  @override
  String get psImgEngrenage => 'Gear';

  @override
  String get psImgVoiture => 'Car';

  @override
  String get psImgVelo => 'Bike';

  @override
  String get psImgAvion => 'Plane';

  @override
  String get psImgTrain => 'Train';

  @override
  String get psImgBateau => 'Boat';

  @override
  String get psImgBus => 'Bus';

  @override
  String get psImgMoto => 'Motorbike';

  @override
  String get psImgFusee => 'Rocket';

  @override
  String get speedNoPauseTitle => '2 uninterrupted minutes';

  @override
  String get speedNoPauseBody =>
      'This exercise measures your speed over a continuous stretch. It cannot be paused: if you leave it, it will have to be retaken from the start. Get settled before you begin.';

  @override
  String get speedNoPauseConfirm => 'I am ready';

  @override
  String get ctShareScore => 'Share my score';

  @override
  String get ctSubtestExitBody =>
      'You left this exercise before finishing it. The exercises you have already completed are saved: you can resume the assessment right here, at this exercise.';

  @override
  String get ctSubtestExitResume => 'Resume exercise';

  @override
  String get ctSubtestExitTitle => 'Subtest interrupted';

  @override
  String get demoBadge => 'PRACTICE';

  @override
  String get demoContinue => 'Continue';

  @override
  String get demoNotice => 'Practice — this attempt does not count.';

  @override
  String get demoRetry => 'Try again';

  @override
  String get demoStart => 'Start the test';

  @override
  String get demoTryAgain => 'Not quite — try again';

  @override
  String get demoWellDone => 'Correct!';

  @override
  String get histLockedBody =>
      'Your result is saved, but it stays blurred until every mission is validated.';

  @override
  String get histLockedBodyNoResult =>
      'Your missions and your invite link are here. Finish your assessment to unlock your result.';

  @override
  String get histLockedCta => 'See my missions';

  @override
  String get histLockedTitle => 'Missions to complete';

  @override
  String get inviteLandingBody =>
      'A friend invited you to take the free Mentality IQ test. By finishing your test, you get your own result and help your friend unlock theirs.';

  @override
  String get inviteLandingCta => 'Start the free test';

  @override
  String get inviteLandingTitle => 'Invitation';

  @override
  String get shareCancel => 'Cancel';

  @override
  String get shareCodeLabel => 'Invite code';

  @override
  String get shareConfirm => 'Share this image';

  @override
  String get shareError => 'Could not prepare the image. Please try again.';

  @override
  String get shareEyebrow => 'Preview';

  @override
  String get shareIntro =>
      'This is the image that will be shared. Nothing is posted until you confirm.';

  @override
  String get shareLinkCopied =>
      'Your link is copied — add it as a Link sticker on your story';

  @override
  String sharePercentile(int rank) {
    return 'Higher than $rank% of participants';
  }

  @override
  String get shareScoreLabel => 'Overall score';

  @override
  String get shareTitle => 'Share my score';

  @override
  String get ugCopied => 'Link copied!';

  @override
  String get ugCopyLink => 'Copy my invite link';

  @override
  String get ugErrorBody =>
      'Could not fetch your unlock status. Check your connection and try again.';

  @override
  String get ugEyebrow => 'Final steps';

  @override
  String get ugFreeNotice =>
      'The test is 100% free. To receive your result, a few simple steps remain — they are validated automatically.';

  @override
  String ugFriendDone(int n) {
    return 'Friend $n: test completed';
  }

  @override
  String ugFriendPending(int n) {
    return 'Friend $n: test in progress';
  }

  @override
  String ugInviteCounter(int joined, int required) {
    return '$joined/$required friends have finished their test';
  }

  @override
  String get ugRefresh => 'Refresh';

  @override
  String get ugRefreshFailed =>
      'Could not refresh. Check your connection — the numbers shown are from your last successful update.';

  @override
  String get ugResultsHubNotice =>
      'Everything lives in “My results”: your missions, your invite link and your result (blurred until every mission is validated). You can leave this page and come back anytime.';

  @override
  String get ugRetry => 'Retry';

  @override
  String get ugStep1Body =>
      'Share your personal link with 3 friends. This step advances when they FINISH their test — not just when they sign up. Feel free to remind them.';

  @override
  String get ugStep1Title => 'Invite 3 friends';

  @override
  String get ugStep2Body =>
      'Your friends now need to finish their IQ test. We are waiting for their results — feel free to remind them!';

  @override
  String get ugStep2Title => 'Your friends are taking their test';

  @override
  String get ugTitle => 'Your result is ready';

  @override
  String ugWaitBody(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other:
          'Your result is being prepared. It will be published in $days days, automatically — there is nothing left for you to do.',
      one:
          'Your result is being prepared. It will be published in $days day, automatically — there is nothing left for you to do.',
      zero:
          'Your result is being prepared. It will be published automatically — there is nothing left for you to do.',
    );
    return '$_temp0';
  }

  @override
  String get ugWaitConfirming =>
      'Your result unlocks as soon as the server confirms — this screen refreshes on its own.';

  @override
  String ugWaitCountdownDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days left',
      one: '$days day left',
    );
    return '$_temp0';
  }

  @override
  String get ugWaitCountdownDone => 'The wait is over.';

  @override
  String ugWaitCountdownHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours hours left',
      one: '$hours hour left',
    );
    return '$_temp0';
  }

  @override
  String ugWaitCountdownMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes left',
      one: '$minutes minute left',
    );
    return '$_temp0';
  }

  @override
  String get ugWaitTitle => 'Your results are on the way';

  @override
  String get vpDemoEyebrow => 'DEMONSTRATION';

  @override
  String get vpDemoInstruction =>
      'Untimed practice: choose the 3 pieces that form the figure, then confirm.';

  @override
  String get vpDemoRetry => 'Try again';

  @override
  String get vpDemoStart => 'Start the test';

  @override
  String vpReadyBody(int count) {
    return 'Practice is over. The test begins: $count puzzles, each with its own timer. The clock starts as soon as you press the button.';
  }

  @override
  String get vpReadyStart => 'Start now';

  @override
  String get vpReadyTitle => 'Ready?';

  @override
  String get vpRecorded => 'Answer recorded';

  @override
  String get completionPendingNotice =>
      'Your test completion hasn\'t been confirmed by the server yet. We keep retrying — stay connected and reopen the app if needed.';

  @override
  String get completionRejectedNotice =>
      'This attempt could not be validated: it was too short. It does not count towards the referral mission.';

  @override
  String get ctSubtestExitPause => 'Pause';

  @override
  String get vocabTestName => 'Vocabulary';

  @override
  String get vocabEyebrow => 'VERBAL COMPREHENSION';

  @override
  String vocabTimerScore(int seconds, int score) {
    return '${seconds}s · $score pts';
  }

  @override
  String get vocabFeedbackExcellent => 'Excellent!';

  @override
  String get vocabFeedbackCorrect => 'Correct';

  @override
  String get vocabFeedbackIncomplete => 'Incomplete answer';

  @override
  String get vocabFeedbackTwoPoints =>
      'A complete and precise definition! +2 points';

  @override
  String get vocabFeedbackOnePoint =>
      'A partial but correct definition. +1 point';

  @override
  String get vocabFeedbackZeroPoint =>
      'Incorrect or too vague an answer. 0 points';

  @override
  String vocabWordLabel(String word) {
    return 'Word: “$word”';
  }

  @override
  String vocabYourAnswerLabel(String answer) {
    return 'Your answer: “$answer”';
  }

  @override
  String get vocabEmptyAnswer => '(empty)';

  @override
  String get vocabTwoPointExamples => 'Examples of 2-point answers:';

  @override
  String get vocabOnePointExamples => 'Examples of 1-point answers:';

  @override
  String vocabTimeSeconds(int seconds) {
    return 'Time: ${seconds}s';
  }

  @override
  String vocabTotalScore(int score) {
    return 'Total score: $score points';
  }

  @override
  String get vocabDiscontinued => '3 items skipped in a row — exercise ended.';

  @override
  String get vocabViewResults => 'View results';

  @override
  String get vocabResultsTitle => 'Vocabulary Test — Results';

  @override
  String vocabRawScore(int score, int max) {
    return 'Raw score: $score/$max points';
  }

  @override
  String vocabItemsCompleted(int completed, int total) {
    return 'Items completed: $completed/$total';
  }

  @override
  String vocabPercentage(int percent) {
    return 'Percentage: $percent%';
  }

  @override
  String vocabTotalTime(int seconds) {
    return 'Total time: ${seconds}s';
  }

  @override
  String get vocabTestCaption =>
      'A test of lexical knowledge and verbal comprehension';

  @override
  String get vocabFrequencyBreakdownTitle => 'Breakdown by frequency:';

  @override
  String vocabFrequencyBreakdownRow(String name, int score, int max) {
    return '$name: $score/$max points';
  }

  @override
  String get vocabPerfExceptional => 'Exceptional performance (θ > +2.0)';

  @override
  String get vocabPerfSuperior => 'Superior performance (θ > +1.0)';

  @override
  String get vocabPerfAverage => 'Average performance (θ ≈ 0)';

  @override
  String get vocabPerfBelowAverage => 'Below-average performance (θ < 0)';

  @override
  String get vocabPerfLow => 'Low performance (θ < -1.0)';

  @override
  String get vocabFreqVeryHigh => 'Very frequent';

  @override
  String get vocabFreqHigh => 'Frequent';

  @override
  String get vocabFreqMedium => 'Medium';

  @override
  String get vocabFreqLow => 'Rare';

  @override
  String get vocabFreqVeryLow => 'Very rare';

  @override
  String get vocabInstruction => 'Define the following word';

  @override
  String get vocabYourDefinitionLabel => 'Your definition:';

  @override
  String get vocabDefinitionHint => 'Write the definition of the word...';

  @override
  String get vocabTipsTitle => 'Tips to earn 2 points:';

  @override
  String get vocabTipComplete => '• Give a complete and precise definition';

  @override
  String get vocabTipSynonyms => '• Use exact synonyms';

  @override
  String get vocabTipContext => '• Explain the meaning with context';

  @override
  String get weGateCta => 'See today\'s programme';

  @override
  String get weHubEyebrow => 'While you wait';

  @override
  String weHubTitle(int day) {
    return 'Day $day';
  }

  @override
  String get weHubTitleDone => 'Programme complete';

  @override
  String get weHubIntro =>
      'Each day reveals a part of your results, along with an optional activity. Nothing here speeds up the unlock: time alone unlocks it.';

  @override
  String get weTodayTag => 'Today';

  @override
  String get wePastTag => 'Catch up';

  @override
  String weLockedTag(int day) {
    return 'Opens on day $day';
  }

  @override
  String get wePlaceholderTitle => 'Coming soon';

  @override
  String get wePlaceholderBody =>
      'This day\'s content is coming in a future update.';

  @override
  String get weAnnouncedTag => 'Today\'s test — with your result';

  @override
  String get weContributionTag => 'Contribution — help us build our test';

  @override
  String get weShareTag => 'Final reward';

  @override
  String get weDay1Title => 'Your personality';

  @override
  String get weDay2Title => 'Build our reading test';

  @override
  String get weDay3Title => 'Your balance';

  @override
  String get weDay4Title => 'Build our attention test (1/2)';

  @override
  String get weDay5Title => 'Build our attention test (2/2)';

  @override
  String get weDay6Title => 'Your energy';

  @override
  String get weDay7Title => 'Autism profile';

  @override
  String get weDay8Title => 'Your overall IQ';

  @override
  String get weRevealVci => 'Your verbal index';

  @override
  String get weRevealPsi => 'Your processing speed';

  @override
  String get weRevealWmi => 'Your working memory';

  @override
  String get weRevealFri => 'Your reasoning';

  @override
  String get weRevealVsi => 'Your spatial index';

  @override
  String get weRevealStrengths => 'Your strengths and weaknesses';

  @override
  String get weRevealFullIq => 'Your overall IQ';

  @override
  String get weGameStroop => 'Game: Stroop';

  @override
  String get weGameDelayChoice => 'Game: delay tolerance';

  @override
  String get weGameTimeEstimation => 'Game: time estimation';

  @override
  String get weGameConfidence => 'Game: confidence calibration';

  @override
  String get weRunnerNext => 'Next';

  @override
  String get weRunnerFinish => 'Finish';

  @override
  String get weRunnerBack => 'Back';

  @override
  String get weRunnerScoredLabel => 'Today\'s test';

  @override
  String get weRunnerContributionLabel => 'Contribution';

  @override
  String get weRunnerResumed => 'You\'re picking up where you left off.';

  @override
  String get weRunnerNoScoreNotice =>
      'These questions don\'t calculate any score for you: they help build the tool for those who come next.';

  @override
  String get weRunnerQuitTitle => 'Leave the questionnaire?';

  @override
  String get weRunnerQuitBody =>
      'Your answers are saved. You can pick up again at the question where you stop.';

  @override
  String get weRunnerQuitStay => 'Keep going';

  @override
  String get weRunnerQuitLeave => 'Leave';

  @override
  String get weRunnerTransitionCta => 'Continue';

  @override
  String get weRunnerDoneTitle => 'All done';

  @override
  String get weRunnerDoneBody => 'Thank you — your answers are saved.';

  @override
  String get weRunnerDoneContributionBody =>
      'Thank you — your answers will help build our test. No score is calculated for you.';

  @override
  String get weRunnerDoneCta => 'Back to the programme';

  @override
  String get weRvEyebrow => 'Today\'s reveal';

  @override
  String get weRvContinue => 'Continue';

  @override
  String get weRvBackToHub => 'Back to the programme';

  @override
  String get weRvScoreLabel => 'SCORE';

  @override
  String weRvCi(int low, int high) {
    return '95% confidence interval · $low – $high';
  }

  @override
  String get weRvCaveat =>
      'An index is a measurement, with its margin of error — not a verdict. Sitting the same assessment again would not give exactly the same number.';

  @override
  String get weRvUnavailableTitle => 'No assessment to reveal';

  @override
  String get weRvUnavailableBody =>
      'No completed assessment is attached to this pass on this device. Nothing is lost: the reveal will appear as soon as your results are readable here again.';

  @override
  String get weRvMissingTitle => 'This index was not calculated';

  @override
  String get weRvMissingBody =>
      'Your saved assessment does not include this index — a subtest was missing. The other reveals remain available.';

  @override
  String get weRvVciBody =>
      'What you know about words and ideas, and how you connect them: defining, explaining, finding what brings two notions together. It is the part of the profile that changes least over the years.';

  @override
  String get weRvVsiBody =>
      'How you handle shapes and space: rebuilding a pattern, seeing how pieces fit together before you have even laid them down.';

  @override
  String get weRvFriBody =>
      'How you find a rule nobody gave you, from what you observe. It is the reasoning that owes nothing to what you were taught.';

  @override
  String get weRvWmiBody =>
      'What you can hold in mind AND handle at the same time: keeping a sequence while reordering it. It is the index most sensitive to tiredness and stress.';

  @override
  String get weRvPsiBody =>
      'How fast you process simple information without making mistakes. It is not “thinking fast”: it is a throughput, and it is paid for in attention.';

  @override
  String get weRvStrengthsTitle => 'Your strengths and points of vigilance';

  @override
  String get weRvStrengthsIntro =>
      'Today the five indices are compared with one another. A strength is not an absolute talent: it is what exceeds your own average level by more than 10 points.';

  @override
  String get weRvStrengthsNone =>
      'No index departs from your average level by more than 10 points: your profile is even, and that is a result in itself.';

  @override
  String get weRvFullIqLabel => 'Full-scale IQ';

  @override
  String get weRvFullIqBody =>
      'The full-scale IQ sums up the five indices in a single number. When they differ widely from one another, that summary loses its meaning: it is then the detail that describes you, not the total.';

  @override
  String get weRvEstimateTitle => 'YOUR ESTIMATE VS THE MEASUREMENT';

  @override
  String weRvEstimateLine(int estimate, int measured) {
    return 'You estimated $estimate. The measurement gives $measured.';
  }

  @override
  String weRvEstimateOver(int points) {
    return 'That is $points points above the measurement.';
  }

  @override
  String weRvEstimateUnder(int points) {
    return 'That is $points points below the measurement.';
  }

  @override
  String get weRvEstimateClose =>
      'Less than 5 points apart: your estimate and the measurement say the same thing.';

  @override
  String get weRvEstimateMissing =>
      'You did not give an estimate — there is nothing to compare.';

  @override
  String get weRvSelfEyebrow => 'Before any reveal';

  @override
  String get weRvSelfTitle => 'What do you think your IQ is?';

  @override
  String get weRvSelfBody =>
      'A single question, asked now: after a first reveal, your answer would be influenced by the number you had just read. 100 is the average. Your answer stays on your phone and comes back to you on day 8.';

  @override
  String get weRvSelfHint => 'Slide, or tap − and +, to choose.';

  @override
  String get weRvSelfAverage => '100 is the average.';

  @override
  String get weRvSelfConfirm => 'Confirm my estimate';

  @override
  String get weRvSelfDecline => 'I\'d rather not answer';

  @override
  String get weRvSelfDecrease => 'Decrease by one point';

  @override
  String get weRvSelfIncrease => 'Increase by one point';

  @override
  String get weDcEyebrow => 'Game';

  @override
  String get weDcTitle => 'Now or later';

  @override
  String get weDcIntroTitle => 'Some money right now, or more of it later';

  @override
  String get weDcIntroBody =>
      'You\'ll be offered the same kind of choice twenty times: a sum available right now, or a bigger sum after a wait. Just tap whichever one you\'d rather have.';

  @override
  String get weDcIntroImaginary =>
      'These sums are imaginary. There is nothing to win, nothing to pay and nothing to receive: these are questions, not offers.';

  @override
  String get weDcIntroNoRightAnswer =>
      'There is no right answer. Taking the money straight away is neither better nor worse than waiting.';

  @override
  String get weDcStart => 'Start';

  @override
  String get weDcLater => 'Later';

  @override
  String get weDcProgressTag => 'Choice';

  @override
  String get weDcPrompt => 'Which would you rather have?';

  @override
  String get weDcImaginaryTag => 'Imaginary sums — there is nothing to win.';

  @override
  String get weDcResultTitle => 'Your patience';

  @override
  String weDcPatienceScore(int score) {
    return '$score / 100';
  }

  @override
  String get weDcResultCaption =>
      'The higher the number, the more willing you are to wait. It isn\'t a mark: both ends of the scale are equally valid.';

  @override
  String weDcIndifference(String delayed, String immediate) {
    return 'Waiting a month for $delayed amounts, for you, to getting $immediate straight away.';
  }

  @override
  String get weDcCurveTitle => 'What the wait was worth';

  @override
  String weDcPrevious(int score) {
    return 'Last time: $score / 100';
  }

  @override
  String get weDcNoBetterEnd =>
      'This number doesn\'t say whether you played well. Preferring the money straight away is a trade-off, not a mistake — and it shifts with the moment, the mood and each person\'s situation.';

  @override
  String get weDcNotClinical =>
      'This is a game, not a clinical measure: no threshold, no ranking, nothing to conclude about you.';

  @override
  String get weDcIncoherentTitle =>
      'Answers too scattered to draw anything from';

  @override
  String get weDcIncoherentBody =>
      'Your answers pull in opposite directions from one delay to the next: the same sum ends up worth more further away than it is close by. Nothing was saved. Play again whenever you like.';

  @override
  String get weDcReplay => 'Play again';

  @override
  String get weDcDone => 'Done';

  @override
  String get weCsEyebrow => 'Before going further';

  @override
  String get weCsTitle => 'Send your answers?';

  @override
  String get weCsIntro =>
      'The questions that follow are about your mental health and your neurodevelopment. The law protects these answers separately: they can only leave your phone if you explicitly agree here.';

  @override
  String get weCsWhatTitle => 'What is sent';

  @override
  String get weCsWhat =>
      'Your answers, exactly as you gave them. Without your name, your number, or any precise date or time. Never your scores: they are calculated on your phone and stay there.';

  @override
  String get weCsPurposeTitle => 'What they are used for';

  @override
  String get weCsPurpose =>
      'To build and improve our own screening tests, and to compare what people report with what the test battery measures. These tools are part of what we sell — it would be wrong not to say so.';

  @override
  String get weCsWhoTitle => 'Where they go';

  @override
  String get weCsWho =>
      'To our servers, in Europe. Filed under your anonymous pass, never under your name or your phone number.';

  @override
  String get weCsRightsTitle => 'You stay in control';

  @override
  String get weCsRights =>
      'You can withdraw your agreement at any time: further sending stops immediately. You can also ask to access your data or have it erased.';

  @override
  String get weCsOptional =>
      'This is optional and changes nothing else: neither your unlock, nor your results, nor the programme\'s tests depend on this answer.';

  @override
  String get weCsAccept => 'I agree to send my answers';

  @override
  String get weCsDecline => 'No, keep my answers here';

  @override
  String get weDxDeclinedTitle => 'Nothing will be sent';

  @override
  String get weDxDeclinedBody =>
      'These questions only serve our own research: without your agreement, we don\'t ask them. You can come back whenever you like — it changes nothing about the rest of the programme.';

  @override
  String get weDxEyebrow => 'Asked only once';

  @override
  String get weDxListTitle => 'Your history';

  @override
  String get weDxListQuestion =>
      'Have you been diagnosed — or do you think you may be affected — with any of these?';

  @override
  String get weDxListBody =>
      'These answers change nothing about your results. They are used to build our tools: without knowing who is affected, it is impossible to spot which questions actually tell anything apart.';

  @override
  String get weDxListHint => 'Tick everything that applies.';

  @override
  String get weDxAdhd => 'ADHD';

  @override
  String get weDxAutism => 'Autism / ASD';

  @override
  String get weDxDyslexia => 'Dyslexia';

  @override
  String get weDxDyspraxia => 'Dyspraxia';

  @override
  String get weDxDyscalculia => 'Dyscalculia';

  @override
  String get weDxHpi => 'Giftedness (high IQ)';

  @override
  String get weDxDepression => 'Depression';

  @override
  String get weDxAnxiety => 'Anxiety disorder';

  @override
  String get weDxBipolar => 'Bipolar disorder';

  @override
  String get weDxOcd => 'OCD';

  @override
  String get weDxSleep => 'Sleep disorder';

  @override
  String get weDxBurnout => 'Burnout';

  @override
  String get weDxOther => 'Another condition';

  @override
  String get weDxNone => 'None';

  @override
  String get weDxPreferNotToSay => 'I\'d rather not say';

  @override
  String get weDxDetailTitle => 'Details';

  @override
  String weDxDetailProgress(int current, int total) {
    return '$current of $total';
  }

  @override
  String get weDxSourceQuestion => 'Who identified it?';

  @override
  String get weDxSourcePsychiatrist => 'A psychiatrist or neuropsychologist';

  @override
  String get weDxSourceGp => 'A GP';

  @override
  String get weDxSourcePsychologist => 'A psychologist';

  @override
  String get weDxSourceSelf => 'Nobody — I think so, without a diagnosis';

  @override
  String get weDxWhenQuestion => 'How long ago was that?';

  @override
  String get weDxWhenUnder1 => 'Less than a year';

  @override
  String get weDxWhen1to3 => 'Between 1 and 3 years';

  @override
  String get weDxWhen3to10 => 'Between 3 and 10 years';

  @override
  String get weDxWhenOver10 => 'More than 10 years';

  @override
  String get weDxWhenUnknown => 'I can\'t remember';

  @override
  String get weDxTreatmentQuestion => 'Any treatment or follow-up?';

  @override
  String get weDxTreatmentYes => 'Yes, currently';

  @override
  String get weDxTreatmentNo => 'No';

  @override
  String get weDxTreatmentPast => 'In the past';

  @override
  String get weDxAssessmentQuestion => 'Was a full assessment carried out?';

  @override
  String get weDxAssessmentYes => 'Yes';

  @override
  String get weDxAssessmentNo => 'No';

  @override
  String get weDxAssessmentUnknown => 'I don\'t know';

  @override
  String get weDxDoneTitle => 'Noted';

  @override
  String get weDxDoneBody =>
      'Thank you. You won\'t be asked this again — it is only asked once. It changes nothing about your results or your unlock.';

  @override
  String get weDxAlreadyTitle => 'Already answered';

  @override
  String get weDxAlreadyBody =>
      'You have already filled this in. It is only asked once, so that your answer isn\'t influenced by the tests of the following days.';

  @override
  String get weDxFailedTitle => 'Nothing could be saved';

  @override
  String get weDxFailedBody =>
      'Your answers were not kept, and nothing was sent. You can try again from the programme — the question is still open.';

  @override
  String get weDxQuitTitle => 'Leave now?';

  @override
  String get weDxQuitBody =>
      'What you have ticked will not be kept: this block is saved in one go, at the end. You can start it again from the programme.';

  @override
  String get weGameCardSubtitle => 'Today\'s game · 2 minutes · replayable';

  @override
  String get weStroopEyebrow => 'Game';

  @override
  String get weStroopTitle => 'Colour clash';

  @override
  String get weStroopIntroTitle => 'Name the colour, not the word';

  @override
  String get weStroopIntroBody =>
      'A word will appear in a certain colour. Tap the colour of the INK, not what the word says. Reading happens automatically: that is exactly what you will have to set aside.';

  @override
  String get weStroopIntroPractice =>
      'We start with three trials that don\'t count, just to find your feet.';

  @override
  String get weStroopIntroExample =>
      'Here the word says one colour and the ink says another: the ink is what counts.';

  @override
  String get weStroopStart => 'Start';

  @override
  String get weStroopLater => 'Later';

  @override
  String get weStroopPracticeTag => 'Practice';

  @override
  String get weStroopScoredTag => 'Counted';

  @override
  String get weStroopPrompt => 'What colour is this written in?';

  @override
  String get weStroopBlockScoredTitle => 'Here we go';

  @override
  String get weStroopBlockScoredBody =>
      'From now on, the trials count. Go quickly, but aim true: a mistake earns you nothing.';

  @override
  String get weStroopBlockConflictTitle => 'Now the words contradict you';

  @override
  String get weStroopBlockConflictBody =>
      'The instruction doesn\'t change: it is still the colour of the ink. The words will simply say something else.';

  @override
  String get weStroopBlockCta => 'Continue';

  @override
  String get weStroopResultTitle => 'Your gap';

  @override
  String weStroopMilliseconds(int ms) {
    return '$ms ms';
  }

  @override
  String get weStroopResultCaption =>
      'That\'s the extra time you needed, on each trial, when the word said the opposite of the ink.';

  @override
  String weStroopAccuracy(int correct, int total) {
    return '$correct correct out of $total';
  }

  @override
  String weStroopBest(int ms) {
    return 'Your best gap: $ms ms';
  }

  @override
  String get weStroopNewBest => 'New best gap';

  @override
  String get weStroopNotSpeed =>
      'This number is not your speed. It is the difference between two runs: someone slower overall can perfectly well have a smaller gap.';

  @override
  String get weStroopNotClinical =>
      'This is a game, not a clinical measure: no threshold, no ranking, nothing to conclude about you.';

  @override
  String get weStroopUnreliableTitle => 'Too few answers to count';

  @override
  String get weStroopUnreliableBody =>
      'There aren\'t enough answers that were both correct and given in time to work out an honest gap. Your previous best gap is untouched. Play again whenever you like.';

  @override
  String get weStroopReplay => 'Play again';

  @override
  String get weStroopDone => 'Done';

  @override
  String get weTeEyebrow => 'Game';

  @override
  String get weTeTitle => 'The longer of the two';

  @override
  String get weTeIntroTitle => 'Two panels, one after the other';

  @override
  String get weTeIntroBody =>
      'A panel will light up, go dark, then light up a second time. Say which of the two stayed lit for longer. The gaps get tighter as the game goes on.';

  @override
  String get weTeIntroTooShortToCount =>
      'The durations are around a second long: far too short to count. Your perception alone does the answering.';

  @override
  String get weTeIntroExample =>
      'This is the panel that will light up. Nothing else on screen will move.';

  @override
  String get weTeStart => 'Start';

  @override
  String get weTeLater => 'Later';

  @override
  String get weTeProgressTag => 'Trial';

  @override
  String get weTeWatch => 'Watch closely…';

  @override
  String get weTePrompt => 'Which one stayed lit for longer?';

  @override
  String get weTeFirst => 'The first one';

  @override
  String get weTeSecond => 'The second one';

  @override
  String get weTeResultTitle => 'Your resolution';

  @override
  String weTeThreshold(int percent) {
    return '$percent%';
  }

  @override
  String get weTeResultCaption =>
      'That\'s the smallest gap you can still tell apart between two durations. The smaller the number, the more finely your perception separates two close moments.';

  @override
  String weTeAccuracyNote(int percent) {
    return '$percent% correct — that\'s expected: the game tightens the gaps until you start hesitating.';
  }

  @override
  String weTeBest(int percent) {
    return 'Your best resolution: $percent%';
  }

  @override
  String get weTeNewBest => 'New best resolution';

  @override
  String get weTeNotSpeed =>
      'This number is not your speed: nothing timed your answers, you could take as long as you liked to decide.';

  @override
  String get weTeNotClinical =>
      'This is a game, not a clinical measure: no threshold, no ranking, nothing to conclude about you.';

  @override
  String get weTeUnreliableTitle => 'Not enough to measure a resolution';

  @override
  String get weTeUnreliableBody =>
      'The game never hesitated enough for a threshold to mean anything. Your previous best resolution is untouched. Play again whenever you like.';

  @override
  String get weTeReplay => 'Play again';

  @override
  String get weTeDone => 'Done';
}
