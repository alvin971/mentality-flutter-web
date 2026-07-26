// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Mental E.T.';

  @override
  String get languageSwitcherTooltip => 'Sprache ändern';

  @override
  String get commonValidate => 'Bestätigen';

  @override
  String get commonNext => 'Weiter';

  @override
  String get commonBack => 'Zurück';

  @override
  String get commonContinue => 'Fortfahren';

  @override
  String get commonStart => 'Starten';

  @override
  String get commonSkip => 'Überspringen';

  @override
  String get commonCancel => 'Abbrechen';

  @override
  String get commonClose => 'Schließen';

  @override
  String get commonRetry => 'Erneut versuchen';

  @override
  String get commonLoading => 'Wird geladen …';

  @override
  String get commonError => 'Ein Fehler ist aufgetreten';

  @override
  String get commonYes => 'Ja';

  @override
  String get commonNo => 'Nein';

  @override
  String get commonOk => 'OK';

  @override
  String get commonFinish => 'Beenden';

  @override
  String commonSeconds(int count) {
    return '$count s';
  }

  @override
  String get oralConsentRequiredCheckbox =>
      'Ich erlaube, dass meine Stimme für die Dauer dieses Tests aufgezeichnet und analysiert wird. (erforderlich)';

  @override
  String get oralConsentCommercialCheckbox =>
      'Ich erlaube außerdem, dass meine Aufnahmen in anonymisierter Form zu Forschungs- und kommerziellen Zwecken weiterverwendet werden – einschließlich der Weitergabe an Dritte. (optional)';

  @override
  String get oralConsentRequiredHint =>
      'Kreuzen Sie das erste Kästchen an, um den Test zu starten.';

  @override
  String get oralConsentPrivacyLink => 'Datenschutzerklärung lesen';

  @override
  String get matDiscontinue3 => '3 Fehler in Folge – Test beendet (WAIS-IV)';

  @override
  String get assessIntroTitle => 'Neue Untersuchung';

  @override
  String get assessIntroEyebrow => 'KOGNITIVE UNTERSUCHUNG';

  @override
  String get assessIntroHero1 => 'Fünf Indizes,';

  @override
  String get assessIntroHero2 => 'ein Maß.';

  @override
  String get assessIntroDescription =>
      'Diese Untersuchung erfasst Ihre kognitiven Fähigkeiten in sechs Bereichen des WAIS-IV. Ein Gesamtwert (FSIQ) fasst sie zusammen.';

  @override
  String get assessDomainsHeader => 'ERFASSTE BEREICHE';

  @override
  String get assessDomainVci => 'Sprachverständnis';

  @override
  String get assessDomainVsi => 'Visuell-räumliches Denken';

  @override
  String get assessDomainFri => 'Schlussfolgerndes Denken';

  @override
  String get assessDomainWmi => 'Arbeitsgedächtnis';

  @override
  String get assessDomainPsi => 'Verarbeitungsgeschwindigkeit';

  @override
  String get assessDomainLo => 'Mündliche Sprache';

  @override
  String get assessBeforeStartHeader => 'VOR DEM BEGINN';

  @override
  String get assessBeforeStartBody =>
      'Voraussichtliche Dauer 60 bis 90 Minuten. Ruhe und Konzentration erforderlich.';

  @override
  String get assessLaunchFullAssessment => 'Vollständige Untersuchung starten';

  @override
  String get assessOrIndividualSubtest => 'ODER EINZELNER UNTERTEST';

  @override
  String get assessSubtestCubes => 'Mosaik-Test (Block Design)';

  @override
  String get assessSubtestMatrices => 'Matrizen-Test';

  @override
  String get assessSubtestFigureWeights => 'Figurenwaagen';

  @override
  String get assessSubtestVisualPuzzles => 'Visuelle Puzzles';

  @override
  String get assessSubtestSimilarities => 'Gemeinsamkeiten finden';

  @override
  String get assessSubtestVocabulary => 'Wortschatz-Test';

  @override
  String get assessSubtestInformation => 'Allgemeines Wissen';

  @override
  String get assessSubtestDigitSpan => 'Zahlen nachsprechen';

  @override
  String get assessSubtestArithmetic => 'Rechnerisches Denken';

  @override
  String get assessSubtestPictureSpan => 'Bilder merken';

  @override
  String get assessSubtestCoding => 'Zahlen-Symbol-Test';

  @override
  String get assessSubtestSymbolSearch => 'Symbolsuche';

  @override
  String get assessSubtestOralComprehension => 'Mündliches Verständnis';

  @override
  String get authLoginTitle => 'Anmelden';

  @override
  String get authCreateAccount => 'Konto erstellen';

  @override
  String get authSignIn => 'Anmelden';

  @override
  String get authHeaderSubtitleRegister =>
      'Erstellen Sie ein Konto, um Ihre Ergebnisse zu speichern';

  @override
  String get authHeaderSubtitleLogin =>
      'Melden Sie sich an, um auf Ihren Verlauf zuzugreifen';

  @override
  String get authEmailLabel => 'E-Mail-Adresse';

  @override
  String get authPasswordLabel => 'Passwort';

  @override
  String get authFieldRequired => 'Pflichtfeld';

  @override
  String get authEmailInvalid => 'Ungültige E-Mail-Adresse';

  @override
  String get authPasswordMinLength => 'Mindestens 8 Zeichen';

  @override
  String get authOrDivider => 'oder';

  @override
  String get authContinueWithGoogle => 'Mit Google fortfahren';

  @override
  String get authToggleToLogin => 'Bereits ein Konto? Anmelden';

  @override
  String get authToggleToRegister => 'Noch kein Konto? Registrieren';

  @override
  String get authFirebaseNotConfiguredFull =>
      'Firebase ist noch nicht konfiguriert. Folgen Sie den Anweisungen in firebase_config.dart.';

  @override
  String get authFirebaseNotConfigured =>
      'Firebase ist noch nicht konfiguriert.';

  @override
  String get histTitle => 'Meine Ergebnisse';

  @override
  String get histEyebrow => 'VERLAUF';

  @override
  String get histDeleteResultTitle => 'Dieses Ergebnis löschen?';

  @override
  String get histDeleteResultBody =>
      'Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get histDelete => 'Löschen';

  @override
  String histAgeYears(int age) {
    return '$age Jahre';
  }

  @override
  String get histScoreFsiq => 'Gesamt-IQ (FSIQ)';

  @override
  String get histScoreVci => 'VCI — Sprachlich';

  @override
  String get histScoreVsi => 'VSI — Visuell-räumlich';

  @override
  String get histScoreFri => 'FRI — Schlussfolgern';

  @override
  String get histScoreWmi => 'WMI — Gedächtnis';

  @override
  String get histScorePsi => 'PSI — Geschwindigkeit';

  @override
  String get histEmptyEyebrow => 'KEINE ERGEBNISSE';

  @override
  String get histEmptyHero1 => 'Ihr Verlauf';

  @override
  String get histEmptyHero2 => 'wartet auf Sie.';

  @override
  String get histEmptyDescription =>
      'Schließen Sie Ihre erste WAIS-IV-Untersuchung ab, damit Ihre Ergebnisse hier erscheinen.';

  @override
  String get histStartAssessment => 'Eine Untersuchung beginnen';

  @override
  String get ctIntroTitle => 'Vollständiger Test';

  @override
  String get ctIntroHero1 => 'Zwölf Untertests,';

  @override
  String get ctIntroHero2 => 'vier Indizes.';

  @override
  String get ctIntroDescription =>
      'Vollständige standardisierte kognitive Untersuchung. Die Untertests laufen automatisch nacheinander ab.';

  @override
  String get ctIntroDurationEyebrow => 'DAUER';

  @override
  String get ctIntroDurationTitle => '60 bis 90 Minuten';

  @override
  String get ctIntroDurationBody =>
      'Planen Sie einen durchgehenden Zeitraum ein.';

  @override
  String get ctIntroContentEyebrow => 'INHALT';

  @override
  String get ctIntroContentTitle => '12 Untertests enthalten';

  @override
  String get ctIntroContentBody =>
      'Mosaik-Test · Gemeinsamkeiten · Gedächtnis · Matrizen · Wortschatz · Rechnen · Symbole · Puzzles · Wissen · Zahlen-Symbol · Bilder · Figurenwaagen.';

  @override
  String get ctIntroImportantEyebrow => 'WICHTIG';

  @override
  String get ctIntroImportantTitle => 'Automatischer Ablauf';

  @override
  String get ctIntroImportantBody =>
      'Die Tests starten nacheinander. Stellen Sie sicher, dass Sie genügend Zeit haben.';

  @override
  String get ctPatientAgeHeader => 'ALTER DER PERSON';

  @override
  String get ctPatientAgeHint =>
      'Erforderlich für die Normen (16 bis 90 Jahre)';

  @override
  String get ctAgeSuffix => 'JAHRE';

  @override
  String get ctAgeRangeError => 'Alter zwischen 16 und 90 Jahren';

  @override
  String get ctLaunchFullTest => 'Vollständigen Test starten';

  @override
  String get ctRunningTitle => 'Test läuft';

  @override
  String get ctGlobalProgress => 'GESAMTFORTSCHRITT';

  @override
  String get ctNextSubtest => 'NÄCHSTER UNTERTEST';

  @override
  String get ctLaunching => 'Wird gestartet…';

  @override
  String get ctComputingResultsTitle => 'Ergebnisse werden berechnet';

  @override
  String get ctComputingResultsEyebrow => 'AUSWERTUNG';

  @override
  String get ctProcessing => 'VERARBEITUNG';

  @override
  String ctTestNotFound(String testName) {
    return 'Test nicht gefunden: $testName';
  }

  @override
  String get ctTestCubes => 'Mosaik-Test';

  @override
  String get ctTestSimilarities => 'Gemeinsamkeiten';

  @override
  String get ctTestDigitSpan => 'Zahlen nachsprechen';

  @override
  String get ctTestMatrices => 'Matrizen';

  @override
  String get ctTestVocabulary => 'Wortschatz';

  @override
  String get ctTestArithmetic => 'Rechnen';

  @override
  String get ctTestSymbolSearch => 'Symbolsuche';

  @override
  String get ctTestVisualPuzzles => 'Visuelle Puzzles';

  @override
  String get ctTestInformation => 'Wissen';

  @override
  String get ctTestCoding => 'Zahlen-Symbol';

  @override
  String get ctTestPictureSpan => 'Bilder merken';

  @override
  String get ctTestFigureWeights => 'Figurenwaagen';

  @override
  String get ctResultsTitle => 'Ergebnisse';

  @override
  String get ctResultsEyebrow => 'WAIS-IV-AUSWERTUNG';

  @override
  String get ctResultsHero1 => 'Auswertung';

  @override
  String get ctResultsHero2 => 'abgeschlossen.';

  @override
  String get ctResultsSummary =>
      'Zusammenfassung Ihrer kognitiven Leistungen in den zwölf WAIS-IV-Untertests.';

  @override
  String ctAgeYears(int age) {
    return '$age Jahre';
  }

  @override
  String get ctMetaDate => 'DATUM';

  @override
  String get ctMetaDuration => 'DAUER';

  @override
  String get ctMetaSubtests => 'UNTERTESTS';

  @override
  String get ctMetaAge => 'ALTER';

  @override
  String get ctFsiqCardLabel => 'GESAMT-IQ · FSIQ';

  @override
  String ctConfidenceInterval95(int lower, int upper) {
    return '95 % KI · $lower – $upper';
  }

  @override
  String ctPercentileLabel(int rank) {
    return 'Perzentil · $rank.';
  }

  @override
  String get ctIndexProfileHeader => 'INDEXPROFIL';

  @override
  String get ctIndexVci => 'Sprachverständnis';

  @override
  String get ctIndexVsi => 'Visuell-räumlich';

  @override
  String get ctIndexFri => 'Schlussfolgerndes Denken';

  @override
  String get ctIndexWmi => 'Arbeitsgedächtnis';

  @override
  String get ctIndexPsi => 'Verarbeitungsgeschwindigkeit';

  @override
  String ctIndexCiPercentile(int lower, int upper, int rank) {
    return 'KI $lower–$upper · $rank. Perzentil';
  }

  @override
  String ctIndexPercentile(int rank) {
    return '$rank. Perzentil';
  }

  @override
  String get ctStandardizedScoresHeader => 'STANDARDWERTE';

  @override
  String get ctGroupVciVerbal => 'VCI · Sprachlich';

  @override
  String get ctGroupVsiVisuoSpatial => 'VSI · Visuell-räumlich';

  @override
  String get ctGroupFriReasoning => 'FRI · Schlussfolgern';

  @override
  String get ctGroupWmiMemory => 'WMI · Gedächtnis';

  @override
  String get ctGroupPsiSpeed => 'PSI · Geschwindigkeit';

  @override
  String ctRawScore(int raw) {
    return 'roh $raw';
  }

  @override
  String get ctCognitiveProfileHeader => 'KOGNITIVES PROFIL';

  @override
  String get ctProfileHomogeneous =>
      'Homogenes Profil — die Indizes sind untereinander stimmig.';

  @override
  String get ctProfileHeterogeneous =>
      'Heterogenes Profil — deutliche Unterschiede zwischen den Indizes.';

  @override
  String ctMaxDiscrepancy(int points) {
    return 'Max. Differenz · $points Pkt.';
  }

  @override
  String get ctRelativeStrengths => 'Relative Stärken';

  @override
  String get ctVigilancePoints => 'Zu beachtende Punkte';

  @override
  String get ctIndicativeDisclaimer =>
      'Richtwerte. Für eine offizielle klinische Begutachtung wenden Sie sich an eine Neuropsychologin, einen Neuropsychologen oder eine qualifizierte psychologische Fachperson.';

  @override
  String get ctRawScoresHeader => 'ROHWERTE';

  @override
  String get ctMissingAgeHeader => 'ALTER FEHLT';

  @override
  String get ctMissingAgeBody =>
      'Ohne das Alter der Person werden nur die Rohwerte angezeigt. Führen Sie den Test mit Altersangabe erneut durch, um den standardisierten IQ, die Perzentile und die Konfidenzintervalle zu erhalten.';

  @override
  String get ctExportPdf => 'Als PDF exportieren';

  @override
  String ctPdfError(String error) {
    return 'PDF-Fehler: $error';
  }

  @override
  String get ctBackToHome => 'Zurück zur Startseite';

  @override
  String get ctSubtestExitTitle => 'Untertest unterbrochen';

  @override
  String get ctSubtestExitBody =>
      'Sie haben diesen Untertest verlassen, bevor er beendet war. Möchten Sie ihn fortsetzen oder die Bewertung beenden?';

  @override
  String get ctSubtestExitResume => 'Untertest fortsetzen';

  @override
  String get ctPdfSubtitle => 'WAIS-IV-Bericht zur kognitiven Untersuchung';

  @override
  String get ctPdfNotProvided => 'Nicht angegeben';

  @override
  String ctPdfDurationMinSec(int min, int sec) {
    return '$min Min. $sec Sek.';
  }

  @override
  String get ctPdfAge => 'Alter';

  @override
  String get ctPdfDuration => 'Dauer';

  @override
  String get ctPdfDate => 'Datum';

  @override
  String get ctPdfFsiqLabel => 'GESAMT-IQ-WERT (FSIQ)';

  @override
  String get ctPdfConfidenceInterval95 => '95-%-Konfidenzintervall';

  @override
  String get ctPdfPercentile => 'Perzentil';

  @override
  String ctPercentileValue(int rank) {
    return '$rank.';
  }

  @override
  String get ctPdfIndexProfileHeader => 'PROFIL DER KOGNITIVEN INDIZES';

  @override
  String get ctPdfIndexVci => 'VCI — Sprachverständnis';

  @override
  String get ctPdfIndexVsi => 'VSI — Visuell-räumlich';

  @override
  String get ctPdfIndexFri => 'FRI — Schlussfolgerndes Denken';

  @override
  String get ctPdfIndexWmi => 'WMI — Arbeitsgedächtnis';

  @override
  String get ctPdfIndexPsi => 'PSI — Verarbeitungsgeschwindigkeit';

  @override
  String get ctPdfColIndex => 'Index';

  @override
  String get ctPdfColScore => 'Wert';

  @override
  String get ctPdfColClassification => 'Klassifikation';

  @override
  String get ctPdfRawScoresHeader => 'ROHWERTE DER UNTERTESTS';

  @override
  String get ctPdfColSubtest => 'Untertest';

  @override
  String get ctPdfColRawScore => 'Rohwert';

  @override
  String get ctPdfDisclaimer =>
      'HINWEIS: Dieser Bericht wird von einer Anwendung zur Unterstützung der Untersuchung erstellt und stellt keine offizielle klinische Diagnose dar. Er muss von einer qualifizierten medizinischen Fachperson interpretiert werden. Nicht ohne ergänzende fachliche Begutachtung für medizinische oder rechtliche Zwecke verwenden.';

  @override
  String get chatEyebrow => 'KI-ASSISTENT';

  @override
  String get chatNewConversation => 'Neue Unterhaltung';

  @override
  String get chatAssistantLabel => 'MENTAL E.T.';

  @override
  String get chatUserLabel => 'SIE';

  @override
  String get chatHeroTitle1 => 'Stellen Sie';

  @override
  String get chatHeroTitle2 => 'Ihre Fragen.';

  @override
  String get chatEmptyIntro =>
      'Die KI von Mental E.T. hilft Ihnen, Ihr kognitives Profil besser zu verstehen. Vertrauliche Gespräche, nicht-direktive Begleitung.';

  @override
  String get chatThinking => 'Denkt nach…';

  @override
  String get chatInputHint => 'Nachricht schreiben…';

  @override
  String get chatTimeJustNow => 'gerade eben';

  @override
  String chatTimeMinutes(int count) {
    return 'vor $count Min.';
  }

  @override
  String chatTimeHours(int count) {
    return 'vor $count Std.';
  }

  @override
  String get chatErrorMessage =>
      'Es tut uns leid, ein Fehler ist aufgetreten. Bitte versuchen Sie es erneut.';

  @override
  String get chatErrorEmptyResponse => 'Leere Antwort vom Worker';

  @override
  String get chatErrorAccessDenied =>
      'Zugriff vom Worker verweigert (Herkunft nicht zugelassen).';

  @override
  String get chatErrorRateLimit =>
      'Anfragelimit erreicht. Bitte versuchen Sie es in Kürze erneut.';

  @override
  String chatErrorServer(int code) {
    return 'Serverfehler ($code)';
  }

  @override
  String chatErrorHttp(int code, String body) {
    return 'Fehler $code: $body';
  }

  @override
  String get coreSplashTitleLine1 => 'Kognitive';

  @override
  String get coreSplashTitleLine2 => 'Beurteilung';

  @override
  String get commonNotAvailable => 'k.A.';

  @override
  String get pdfFilenameBase => 'mentality_ergebnisse';

  @override
  String coreRouteNotFound(String path) {
    return 'Seite nicht gefunden: $path';
  }

  @override
  String get homeHeroTitle => 'Entdecken Sie';

  @override
  String get homeHeroTitleItalic => 'Ihr kognitives Profil.';

  @override
  String get homeHeroBody =>
      'Eine adaptive, wissenschaftliche Untersuchung, angelehnt an die Wechsler-Skalen. 12 Untertests, 5 Indizes, ein Gesamtwert.';

  @override
  String get homeActionStartTitle => 'Untersuchung beginnen';

  @override
  String get homeActionStartSubtitle => 'Dauer: 60 – 90 Minuten';

  @override
  String get homeActionResultsTitle => 'Meine Ergebnisse';

  @override
  String get homeActionResultsSubtitle => 'Untersuchungsverlauf';

  @override
  String get homeActionChatTitle => 'Mit Mental E.T. sprechen';

  @override
  String get homeActionChatSubtitle => 'KI-Assistent, psychologische Fragen';

  @override
  String get homeComingSoon => 'DEMNÄCHST VERFÜGBAR';

  @override
  String get homeAboutEyebrow => 'ÜBER UNS';

  @override
  String get homeAboutSubtestsTitle => '12 Untertests';

  @override
  String get homeAboutSubtestsBody =>
      'Eine umfassende Untersuchung der fünf kognitiven WAIS-IV-Indizes.';

  @override
  String get homeAboutAdaptiveTitle => 'Adaptive KI';

  @override
  String get homeAboutAdaptiveBody =>
      'Schwierigkeitsgrad wird in Echtzeit mittels IRT-Inferenz angepasst.';

  @override
  String get homeAboutValidationTitle => 'Wissenschaftliche Validierung';

  @override
  String get homeAboutValidationBody =>
      'Aufgaben in Anlehnung an die Wechsler-Skalen (WPPSI / WISC / WAIS).';

  @override
  String get homeResumeEyebrow => 'TEST LÄUFT';

  @override
  String get homeResumeTitle => 'Untersuchung fortsetzen';

  @override
  String get homeResumeButton => 'Fortsetzen';

  @override
  String get homeLogoutTitle => 'Abmelden?';

  @override
  String get homeLogoutBody =>
      'Ihr Token wird von diesem Gerät entfernt. Stellen Sie sicher, dass Sie ihn gespeichert haben: Ohne ihn können Sie nicht mehr auf Ihre Daten zugreifen.';

  @override
  String get homeLogoutConfirm => 'Abmelden';

  @override
  String get infoTestName => 'Allgemeinwissen';

  @override
  String get infoEyebrow => 'SPRACHVERSTÄNDNIS · VCI';

  @override
  String infoTrailingStatus(int seconds, int score, int attempted) {
    return '${seconds}s · $score/$attempted';
  }

  @override
  String get infoCorrect => 'Richtig!';

  @override
  String get infoIncorrect => 'Falsch';

  @override
  String get infoFeedbackRight => 'Richtige Antwort! +1 Punkt';

  @override
  String get infoFeedbackWrong => 'Falsche Antwort. 0 Punkte';

  @override
  String infoQuestionLabel(String question) {
    return 'Frage: $question';
  }

  @override
  String infoCorrectAnswerLabel(String answer) {
    return 'Richtige Antwort: $answer';
  }

  @override
  String infoTimeLabel(int seconds) {
    return 'Zeit: ${seconds}s';
  }

  @override
  String infoScoreLabel(int score, int attempted) {
    return 'Punktzahl: $score/$attempted';
  }

  @override
  String infoDomainLabel(String domain) {
    return 'Bereich: $domain';
  }

  @override
  String get infoDiscontinue3 => '3 Fehler in Folge – Test beendet (WAIS-IV)';

  @override
  String get infoSeeResults => 'Ergebnisse anzeigen';

  @override
  String get infoResultsTitle => 'Allgemeinwissen – Ergebnisse';

  @override
  String infoRawScore(int score, int max) {
    return 'Rohwert: $score/$max Punkte';
  }

  @override
  String infoItemsCompleted(int completed, int total) {
    return 'Bearbeitete Aufgaben: $completed/$total';
  }

  @override
  String infoPercentage(int percent) {
    return 'Prozentsatz: $percent %';
  }

  @override
  String infoTotalTime(int seconds) {
    return 'Gesamtzeit: ${seconds}s';
  }

  @override
  String get infoTestSubtitle => 'Test des erworbenen Allgemeinwissens';

  @override
  String get infoDomainBreakdownTitle => 'Aufschlüsselung nach Bereich:';

  @override
  String infoDomainBreakdownRow(String domain, int correct, int total) {
    return '$domain: $correct/$total';
  }

  @override
  String get infoPerfExceptional => 'Außergewöhnliche Leistung (θ > +2.0)';

  @override
  String get infoPerfSuperior => 'Überdurchschnittliche Leistung (θ > +1.0)';

  @override
  String get infoPerfAverage => 'Durchschnittliche Leistung (θ ≈ 0)';

  @override
  String get infoPerfBelow => 'Unterdurchschnittliche Leistung (θ < 0)';

  @override
  String get infoPerfLow => 'Schwache Leistung (θ < -1.0)';

  @override
  String get infoDomainScience => 'Naturwissenschaften';

  @override
  String get infoDomainHistoryGeography => 'Geschichte/Geografie';

  @override
  String get infoDomainGeneralCulture => 'Allgemeinwissen';

  @override
  String get infoDomainMathLogic => 'Mathematik/Logik';

  @override
  String get infoDomainArtsLiterature => 'Kunst/Literatur';

  @override
  String get infoDifficultyEasy => 'Leicht';

  @override
  String get infoDifficultyMedium => 'Mittel';

  @override
  String get infoDifficultyHard => 'Schwer';

  @override
  String get arithTestName => 'Rechnerisches Denken';

  @override
  String get arithEyebrow => 'ARBEITSGEDÄCHTNIS · WMI';

  @override
  String get arithStartTest => 'Test starten';

  @override
  String get arithIntroTitle => 'Rechentest';

  @override
  String get arithIntroDescription =>
      'Dieser Test misst Ihr Arbeitsgedächtnis und Ihr numerisches Denken.';

  @override
  String get arithInfoMentalTitle => 'Nur Kopfrechnen';

  @override
  String get arithInfoMentalSubtitle =>
      'Lösen Sie die Aufgaben ohne Papier und Taschenrechner';

  @override
  String get arithInfoTimeTitle => 'Begrenzte Zeit';

  @override
  String get arithInfoTimeSubtitle =>
      'Jede Aufgabe hat ein Zeitlimit (15–60 Sekunden)';

  @override
  String get arithInfoBonusTitle => 'Schnelligkeitsbonus';

  @override
  String get arithInfoBonusSubtitle =>
      'Schnelle Antworten bei bestimmten Aufgaben = Bonuspunkte';

  @override
  String get arithInfoRepeatTitle => 'Wiederholung möglich';

  @override
  String get arithInfoRepeatSubtitle =>
      'Sie können EINMAL um Wiederholung bitten (die Zeit läuft weiter)';

  @override
  String get arithIntroDiscontinueNote =>
      'Insgesamt 22 Aufgaben. Der Test endet nach 3 Fehlern in Folge.';

  @override
  String arithProblemCounter(int current, int total) {
    return 'Aufgabe $current/$total';
  }

  @override
  String get arithRepeatTitle => 'Aufgabe wiederholen';

  @override
  String get arithUnderstood => 'Verstanden';

  @override
  String get arithTimeUp => 'Zeit abgelaufen!';

  @override
  String arithCorrectAnswerLabel(int answer) {
    return 'Richtige Antwort: $answer';
  }

  @override
  String get arithCorrect => 'Richtig!';

  @override
  String get arithIncorrect => 'Falsch';

  @override
  String arithTimeSpent(int seconds) {
    return 'Zeit: $seconds Sekunden';
  }

  @override
  String get arithSpeedBonus => '🎉 Schnelligkeitsbonus! (+1 Punkt)';

  @override
  String get arithTestEnded => 'Test abgeschlossen!';

  @override
  String arithItemsCompleted(int completed, int total) {
    return 'Bearbeitete Aufgaben: $completed/$total';
  }

  @override
  String arithBaseScore(int score) {
    return 'Grundpunktzahl: $score Punkte';
  }

  @override
  String arithBonusScore(int bonus) {
    return 'Schnelligkeitsbonus: $bonus Punkte';
  }

  @override
  String arithTotalScore(int total) {
    return 'Gesamtpunktzahl: $total Punkte';
  }

  @override
  String get arithRepeat => 'Wiederholen';

  @override
  String get arithAnswerHint => 'Ihre Antwort';

  @override
  String get arithDifficultyEasy => 'Leicht';

  @override
  String get arithDifficultyMedium => 'Mittel';

  @override
  String get arithDifficultyHard => 'Schwer';

  @override
  String get arithDifficultyVeryHard => 'Sehr schwer';

  @override
  String get oralMicAccessTitle => 'Zugriff auf das Mikrofon';

  @override
  String get oralReadingPermissionBody1 =>
      'Bei dieser Aufgabe wird Ihre Stimme aufgezeichnet, während Sie den Text laut vorlesen.';

  @override
  String get oralReadingPermissionBody2 =>
      'Ihre Aufnahmen werden anonymisiert und können dazu beitragen, die Spracherkennung zu verbessern.';

  @override
  String get oralBrowserWillAskMic =>
      'Anschließend werden Sie von Ihrem Browser gebeten, den Zugriff auf das Mikrofon zu erlauben.';

  @override
  String get oralCancel => 'Abbrechen';

  @override
  String get oralAllowMicrophone => 'Mikrofon erlauben';

  @override
  String get oralMicDeniedOrUnavailable =>
      'Mikrofon verweigert oder nicht verfügbar.';

  @override
  String get oralCannotStartRecording =>
      'Die Aufnahme kann in diesem Browser nicht gestartet werden.';

  @override
  String oralCanSkipToNextStep(String message) {
    return '$message Sie können mit dem nächsten Schritt fortfahren.';
  }

  @override
  String get oralSkip => 'Überspringen';

  @override
  String get oralRecordingInProgress => 'Aufnahme läuft';

  @override
  String oralKeepGoingSeconds(int seconds) {
    return 'Noch $seconds Sek. weitermachen ...';
  }

  @override
  String get oralSaving => 'Wird gespeichert ...';

  @override
  String get oralReadingInstructions =>
      'Lesen Sie den folgenden Text laut vor, deutlich und in Ihrem natürlichen Tempo. Drücken Sie auf „Starten“, wenn Sie bereit sind.';

  @override
  String get oralStartReading => 'Vorlesen starten';

  @override
  String get oralFinish => 'Beenden';

  @override
  String get oralSkipThisStep => 'Diesen Schritt überspringen';

  @override
  String get oralSummaryPermissionBody1 =>
      'Sie nehmen nun Ihre mündliche Zusammenfassung des Textes auf.';

  @override
  String get oralSummaryPermissionBody2 =>
      'Sprechen Sie natürlich, als würden Sie den Text einem Freund erklären. Nehmen Sie sich 30 bis 60 Sekunden Zeit.';

  @override
  String get oralStartSummary => 'Zusammenfassung starten';

  @override
  String get oralSummaryInstructionLead =>
      'Sie haben diesen Text gerade gelesen. ';

  @override
  String get oralSummaryInstructionBody =>
      'Fassen Sie mit eigenen Worten zusammen, was Sie verstanden haben. Nehmen Sie sich 30 bis 60 Sekunden Zeit. Sprechen Sie natürlich, als würden Sie es einem Freund erklären.';

  @override
  String get oralReferenceText => 'Referenztext';

  @override
  String get oralFinishSummary => 'Zusammenfassung beenden';

  @override
  String get oralFlowTitle => 'Audioaufnahme';

  @override
  String get oralConsentTitle => 'Mündlicher Verständnistest';

  @override
  String get oralConsentRecordTitle => 'Was wir aufzeichnen';

  @override
  String get oralConsentRecordBody =>
      'Ihre Stimme beim Vorlesen von 5 kurzen Texten (jeweils etwa 1 Min.) und Ihre mündliche Zusammenfassung (etwa 40 Sekunden pro Text).';

  @override
  String get oralConsentAnonTitle => 'Datenschutz';

  @override
  String get oralConsentAnonBody =>
      'Ihre Aufnahmen werden durch einen zufälligen Sitzungscode gekennzeichnet, nicht durch Ihren Namen. Sie bleiben jedoch mit Ihrem Konto verknüpfbar: Es handelt sich um geschützte personenbezogene Daten, die verschlüsselt und in Europa gespeichert werden.';

  @override
  String get oralConsentUsageTitle => 'Verwendung';

  @override
  String get oralConsentUsageBody =>
      'Diese Aufnahmen können dazu beitragen, die Spracherkennung zu verbessern, insbesondere für Modelle wie Whisper oder Speechmatics.';

  @override
  String get oralAcceptAndStart => 'Ich stimme zu und beginne';

  @override
  String get oralDeclineAndGoBack => 'Ablehnen und zurückgehen';

  @override
  String get oralWithdrawConsentNote =>
      'Sie können Ihre Einwilligung jederzeit in den App-Einstellungen widerrufen.';

  @override
  String oralTextProgress(int current) {
    return 'Text $current von 5';
  }

  @override
  String get oralStepReading => 'Vorlesen';

  @override
  String get oralStepSummary => 'Zusammenfassung';

  @override
  String get oralPauseWellDone => 'Gut gemacht!';

  @override
  String get oralPauseNowSummarize =>
      'Fassen Sie diesen Text nun mündlich zusammen.';

  @override
  String get oralPauseStartingIn => 'Beginn in ...';

  @override
  String get oralCompletedThanks => 'Vielen Dank!';

  @override
  String get oralCompletedBody =>
      'Sie haben alle 5 Texte abgeschlossen.\nIhre Aufnahmen tragen dazu bei,\ndie Spracherkennung zu verbessern.';

  @override
  String get oralBackToHome => 'Zurück zur Startseite';

  @override
  String get oralExitDialogTitle => 'Verlassen?';

  @override
  String get oralExitDialogBody =>
      'Eine Aufnahme läuft gerade. Wenn Sie jetzt verlassen, wird sie nicht gespeichert.';

  @override
  String get oralContinue => 'Fortfahren';

  @override
  String get oralQuit => 'Verlassen';

  @override
  String regStepEyebrow(int step) {
    return 'SCHRITT $step / 4';
  }

  @override
  String get regStepEyebrowSuccess => 'SCHRITT 4 / 4 · ERFOLG';

  @override
  String get regEmailTitle => 'Meinen Token erstellen';

  @override
  String get regEmailHeading => 'Ihre E-Mail';

  @override
  String get regEmailIntro =>
      'Wir senden Ihnen einen sechsstelligen Bestätigungscode. Ihre E-Mail-Adresse ist nicht mit Ihrem Token verknüpft und bleibt privat.';

  @override
  String get regEmailFieldLabel => 'E-Mail-Adresse';

  @override
  String get regEmailInvalid => 'Ungültige E-Mail-Adresse';

  @override
  String get regSendingCode => 'Code wird gesendet…';

  @override
  String get regReceiveCode => 'Code anfordern';

  @override
  String get regEmailPrivacyNote =>
      'Es werden weder Vorname noch Nachname noch eine genaue Adresse gespeichert. In Ihrem anonymen Token werden lediglich Ihr Geschlecht, Ihre Altersgruppe und Ihre Postleitzahl verschlüsselt hinterlegt.';

  @override
  String get regEmailOtpTitle => 'E-Mail bestätigen';

  @override
  String get regCodeSentTo => 'Code gesendet an';

  @override
  String get regVerifying => 'Wird überprüft…';

  @override
  String get regResendCode => 'Code erneut senden';

  @override
  String get regPhoneTitle => 'Ihre Telefonnummer';

  @override
  String get regPhoneIntro =>
      'Zur Bestätigung Ihrer Nummer wird ein sechsstelliger SMS-Code gesendet. Ihre Nummer wird zu keinem Zeitpunkt mit Ihrem Token verknüpft.';

  @override
  String get regPhoneFieldHint => 'Telefonnummer';

  @override
  String get regSendingSms => 'SMS wird gesendet…';

  @override
  String get regReceiveSms => 'SMS anfordern';

  @override
  String get regPhoneOtpTitle => 'Telefonnummer bestätigen';

  @override
  String get regSmsSentTo => 'SMS gesendet an';

  @override
  String get regResendSms => 'SMS erneut senden';

  @override
  String get regDemoTitle => 'Ihre demografischen Daten';

  @override
  String get regDemoIntro =>
      'Diese Angaben werden in Ihrem Token verschlüsselt. Es werden keine exakten Werte gespeichert (weder Ihr genaues Alter noch Ihre genaue Adresse).';

  @override
  String get regSectionSex => 'GESCHLECHT';

  @override
  String get regSectionAgeBucket => 'ALTERSGRUPPE';

  @override
  String get regSectionCountryPostal => 'LAND UND POSTLEITZAHL';

  @override
  String get regPostalCodeHint => 'Postleitzahl';

  @override
  String get regGeneratingToken => 'Token wird generiert…';

  @override
  String get regGenerateMyToken => 'Meinen Token generieren';

  @override
  String get regSuccessTitle => 'Willkommen bei Mental E.T.';

  @override
  String get regSuccessTokenSaved =>
      'Ihr anonymer Token wurde generiert und auf diesem Gerät gespeichert.';

  @override
  String get regSuccessTokenDetails =>
      'Er enthält weder Ihre E-Mail-Adresse noch Ihre Telefonnummer noch Ihren Namen. Nur Ihr Geschlecht, Ihre Altersgruppe und Ihre geografische Region (verschlüsselt). Sie können nun mit Ihrer kognitiven Bewertung beginnen.';

  @override
  String get regImportantLabel => 'WICHTIG';

  @override
  String get regSuccessWarning =>
      'Deinstallieren Sie die App nicht, bevor Sie Ihre Bewertung abgeschlossen haben: Ihr Token wird ausschließlich auf diesem Gerät gespeichert. Wenn Sie ihn verlieren, können Sie mit derselben E-Mail-Adresse oder Telefonnummer kein neues Konto mehr erstellen.';

  @override
  String get regEmailAlreadyRegistered =>
      'Für diese E-Mail-Adresse besteht bereits ein Konto. Wenn es Ihres ist, haben Sie bereits einen Token.';

  @override
  String get regEmailUnavailable => 'E-Mail-Adresse nicht verfügbar.';

  @override
  String get regOtpIncorrectOrExpired => 'Code falsch oder abgelaufen.';

  @override
  String get regPhoneAlreadyRegistered =>
      'Für diese Nummer besteht bereits ein Konto.';

  @override
  String get regPhoneUnavailable => 'Nummer nicht verfügbar.';

  @override
  String get regEmailAlreadyHasToken =>
      'Für diese E-Mail-Adresse besteht bereits ein Token.';

  @override
  String get regPhoneAlreadyHasToken =>
      'Für diese Nummer besteht bereits ein Token.';

  @override
  String get regPostalNotFound =>
      'Postleitzahl nicht gefunden. Bitte überprüfen Sie Land und Postleitzahl.';

  @override
  String get regNoInternet => 'Keine Internetverbindung.';

  @override
  String get regGenericRetryError => 'Fehler – bitte versuchen Sie es erneut.';

  @override
  String get regSexMale => 'Männlich';

  @override
  String get regSexFemale => 'Weiblich';

  @override
  String get regSexUndisclosed => 'Keine Angabe';

  @override
  String get regAge1825 => '18 – 25 Jahre';

  @override
  String get regAge2635 => '26 – 35 Jahre';

  @override
  String get regAge3645 => '36 – 45 Jahre';

  @override
  String get regAge4655 => '46 – 55 Jahre';

  @override
  String get regAge5665 => '56 – 65 Jahre';

  @override
  String get regAge66plus => '66 Jahre und älter';

  @override
  String get scoringClassificationVerySuperior => 'Weit überdurchschnittlich';

  @override
  String get scoringClassificationSuperior => 'Überdurchschnittlich';

  @override
  String get scoringClassificationHighAverage => 'Oberer Durchschnitt';

  @override
  String get scoringClassificationAverage => 'Durchschnittlich';

  @override
  String get scoringClassificationLowAverage => 'Unterer Durchschnitt';

  @override
  String get scoringClassificationBorderline => 'Grenzwertig';

  @override
  String get scoringClassificationExtremelyLow => 'Weit unterdurchschnittlich';

  @override
  String get scoringNotAvailable => 'k. A.';

  @override
  String scoringSummaryFullScaleIq(int score, String classification) {
    return 'Gesamt-IQ: $score ($classification)';
  }

  @override
  String scoringSummaryPercentile(int rank) {
    return 'Prozentrang: $rank';
  }

  @override
  String scoringSummaryConfidenceInterval(int lower, int upper) {
    return '95-%-Konfidenzintervall: $lower – $upper';
  }

  @override
  String get scoringIndexVerbalComprehension => 'Sprachverständnis';

  @override
  String get scoringIndexVisualSpatial => 'Visuell-räumlich';

  @override
  String get scoringIndexFluidReasoning => 'Schlussfolgerndes Denken';

  @override
  String get scoringIndexWorkingMemory => 'Arbeitsgedächtnis';

  @override
  String get scoringIndexProcessingSpeed => 'Verarbeitungsgeschwindigkeit';

  @override
  String scoringSummaryRelativeStrengths(String list) {
    return 'Relative Stärken: $list';
  }

  @override
  String scoringSummaryRelativeWeaknesses(String list) {
    return 'Relative Schwächen: $list';
  }

  @override
  String get scoringSummaryHomogeneousProfile => 'Homogenes kognitives Profil';

  @override
  String scoringSummaryHeterogeneousProfile(int points) {
    return 'Heterogenes kognitives Profil (max. Abweichung: $points Punkte)';
  }

  @override
  String get simTestName => 'Gemeinsamkeiten';

  @override
  String get simEyebrow => 'SPRACHVERSTÄNDNIS · VCI';

  @override
  String simStatusBar(int seconds, int score) {
    return '$seconds s · $score Pkt.';
  }

  @override
  String get simQuestionPrompt => 'Worin ähneln sich diese beiden Wörter?';

  @override
  String simLevelLabel(String level) {
    return 'Stufe: $level';
  }

  @override
  String get simLevelConcrete => 'Konkret';

  @override
  String get simLevelFunctional => 'Funktional';

  @override
  String get simLevelCategorical => 'Kategorial';

  @override
  String get simLevelAbstract => 'Abstrakt';

  @override
  String get simAnswerLabel => 'Ihre Antwort:';

  @override
  String get simAnswerHint => 'Erklären Sie, worin sie sich ähneln …';

  @override
  String get simTipsTitle => 'Tipps für 2 Punkte:';

  @override
  String get simTipsLine1 =>
      '• Nennen Sie eine abstrakte oder übergeordnete Kategorie';

  @override
  String get simTipsLine2 =>
      '• Z. B. „Das sind …“, „Formen von …“, „Arten von …“';

  @override
  String get simFeedbackExcellent => 'Ausgezeichnet!';

  @override
  String get simFeedbackCorrect => 'Richtig';

  @override
  String get simFeedbackIncomplete => 'Unvollständige Antwort';

  @override
  String get simFeedbackMsg2pts => 'Abstrakte/kategoriale Antwort! +2 Punkte';

  @override
  String get simFeedbackMsg1pt => 'Funktionale Antwort/Eigenschaft. +1 Punkt';

  @override
  String get simFeedbackMsg0pt => 'Falsche oder zu vage Antwort. 0 Punkte';

  @override
  String simYourAnswerQuoted(String answer) {
    return 'Ihre Antwort: „$answer“';
  }

  @override
  String get simExamples2pts => 'Beispiele für Antworten mit 2 Punkten:';

  @override
  String get simExamples1pt => 'Beispiele für Antworten mit 1 Punkt:';

  @override
  String simTimeSeconds(int seconds) {
    return 'Zeit: $seconds s';
  }

  @override
  String simTotalScore(int score) {
    return 'Gesamtpunktzahl: $score Punkte';
  }

  @override
  String get simDiscontinue =>
      '3-mal hintereinander 0 Punkte – Test beendet (WAIS-IV)';

  @override
  String get simSeeResults => 'Ergebnisse anzeigen';

  @override
  String get simResultsTitle => 'Gemeinsamkeiten-Test – Ergebnisse';

  @override
  String simRawScore(int score, int max) {
    return 'Rohwert: $score/$max Punkte';
  }

  @override
  String simItemsCompleted(int completed, int total) {
    return 'Bearbeitete Aufgaben: $completed/$total';
  }

  @override
  String simPercentage(int percent) {
    return 'Prozentsatz: $percent %';
  }

  @override
  String simTotalTime(int seconds) {
    return 'Gesamtzeit: $seconds s';
  }

  @override
  String get simSubtitle =>
      'Test des verbalen Denkens und der begrifflichen Abstraktion';

  @override
  String get simBreakdownTitle => 'Aufschlüsselung nach Stufe:';

  @override
  String simBreakdownLine(String level, int total, int max) {
    return '$level: $total/$max Punkte';
  }

  @override
  String get simPerfExceptional => 'Außergewöhnliche Leistung (θ > +2,0)';

  @override
  String get simPerfSuperior => 'Überdurchschnittliche Leistung (θ > +1,0)';

  @override
  String get simPerfAverage => 'Durchschnittliche Leistung (θ ≈ 0)';

  @override
  String get simPerfBelow => 'Unterdurchschnittliche Leistung (θ < 0)';

  @override
  String get simPerfLow => 'Schwache Leistung (θ < -1,0)';

  @override
  String get simBack => 'Zurück';

  @override
  String get matTestName => 'Progressive Matrizen';

  @override
  String get matEyebrow => 'IQ-TEST · FSIQ';

  @override
  String get matCorrect => 'Richtig!';

  @override
  String get matIncorrect => 'Falsch';

  @override
  String matResponseTime(int seconds) {
    return 'Antwortzeit: $seconds s';
  }

  @override
  String matScoreFraction(int score, int total) {
    return 'Punktzahl: $score/$total';
  }

  @override
  String get matDiscontinue4 => '4 Fehler in Folge – Test beendet (WAIS-IV)';

  @override
  String get matSeeResultsEnded => 'Ergebnisse ansehen (Test beendet)';

  @override
  String get matNextItem => 'Nächste Aufgabe';

  @override
  String get matSeeResults => 'Ergebnisse ansehen';

  @override
  String get matFinishedTitle => 'Matrizentest abgeschlossen!';

  @override
  String get matRawScore => 'Rohwert';

  @override
  String get matSuccessRate => 'Erfolgsquote';

  @override
  String get matAvgTimePerItem => 'Durchschnittszeit/Aufgabe';

  @override
  String get matEvaluation => 'Auswertung:';

  @override
  String get matPerfExcellent =>
      'Ausgezeichnet! Weit überdurchschnittliches schlussfolgerndes Denken.';

  @override
  String get matPerfVeryGood =>
      'Sehr gut! Gute Fähigkeiten in der logischen Analyse.';

  @override
  String get matPerfGood => 'Gut. Durchschnittliche bis gute Fähigkeiten.';

  @override
  String get matPerfAverage => 'Durchschnittlich. Verbesserungen sind möglich.';

  @override
  String get matPerfBelowAverage =>
      'Unterdurchschnittliche Ergebnisse. Übung empfohlen.';

  @override
  String matPoints(int score) {
    return '$score Pkt.';
  }

  @override
  String get matValidateAnswer => 'Antwort bestätigen';

  @override
  String get matRestart => 'Neu starten';

  @override
  String matRulesTheta(int rules, String theta) {
    return 'Regeln: $rules | θ = $theta';
  }

  @override
  String get matInstruction =>
      'Finden Sie das fehlende Teil, das die Matrix logisch vervollständigt';

  @override
  String get matChooseAnswer => 'Wählen Sie Ihre Antwort:';

  @override
  String get matDiffEasy => 'Leicht';

  @override
  String get matDiffMediumEasy => 'Mittel-leicht';

  @override
  String get matDiffMedium => 'Mittel';

  @override
  String get matDiffMediumHard => 'Mittel-schwer';

  @override
  String get matDiffHard => 'Schwer';

  @override
  String get cubesTestName => 'Mosaik-Test';

  @override
  String get cubesBravo => 'Sehr gut!';

  @override
  String cubesElapsedTime(String time) {
    return 'Verstrichene Zeit: $time';
  }

  @override
  String cubesPointsEarned(int points) {
    return 'Erzielte Punkte: $points';
  }

  @override
  String cubesTotalScore(int score) {
    return 'Gesamtpunktzahl: $score';
  }

  @override
  String get cubesFinishedTitle => 'Test abgeschlossen!';

  @override
  String get cubesTotalScoreLabel => 'Gesamtpunktzahl';

  @override
  String cubesTotalScoreValue(int score, int max) {
    return '$score/$max Pkt.';
  }

  @override
  String get cubesItemsCompletedLabel => 'Bearbeitete Aufgaben';

  @override
  String cubesItemsCompletedValue(int count) {
    return '$count/14';
  }

  @override
  String get cubesAvgTime => 'Durchschnittszeit';

  @override
  String get cubesPerfExcellent =>
      'Ausgezeichnet! Weit überdurchschnittliche visuell-räumliche Fähigkeiten.';

  @override
  String get cubesPerfVeryGood =>
      'Sehr gut! Gute Fähigkeiten in der visuellen Analyse.';

  @override
  String get cubesDiffExample => 'Beispiel';

  @override
  String get cubesDiffVeryHard => 'Sehr schwer';

  @override
  String get cubesDescExample => 'Beispielaufgabe – Zählt nicht zur Punktzahl';

  @override
  String get cubesDesc2x2 => 'Einfaches 2×2-Muster';

  @override
  String get cubesDesc3x3Diagonals => '3×3-Muster mit Diagonalen';

  @override
  String get cubesDesc3x3Complex => 'Komplexes 3×3-Muster – Hohe Kohäsion';

  @override
  String cubesCohesion(int score) {
    return 'Kohäsion: $score';
  }

  @override
  String cubesRemaining(String time) {
    return 'Rest: $time';
  }

  @override
  String get cubesReproduceInstruction =>
      'Bilden Sie das untenstehende Muster nach, indem Sie auf die Würfel tippen';

  @override
  String get cubesPatternToReproduce => 'Nachzubildendes Muster:';

  @override
  String get cubesYourAnswer => 'Ihre Antwort:';

  @override
  String get cubesReset => 'Zurücksetzen';

  @override
  String get fwTestName => 'Quantitative Waagen';

  @override
  String get fwEyebrow => 'SCHLUSSFOLGERNDES DENKEN · FRI';

  @override
  String get fwCorrectAnswerPoint => 'Richtige Antwort! +1 Punkt';

  @override
  String get fwWrongAnswer => 'Falsche Antwort. Die richtige Antwort war:';

  @override
  String fwTime(int seconds) {
    return 'Zeit: $seconds s';
  }

  @override
  String get fwDiscontinue3 => '3 Fehler in Folge – Test beendet (WAIS-IV)';

  @override
  String get fwSeeResults => 'Ergebnisse ansehen';

  @override
  String get fwResultsTitle => 'Test der quantitativen Waagen – Ergebnisse';

  @override
  String fwRawScorePoints(int score) {
    return 'Rohwert: $score/27 Punkte';
  }

  @override
  String fwItemsCompleted(int count) {
    return 'Bearbeitete Aufgaben: $count/27';
  }

  @override
  String fwPercentage(int percent) {
    return 'Prozentsatz: $percent %';
  }

  @override
  String fwTotalTime(int seconds) {
    return 'Gesamtzeit: $seconds s';
  }

  @override
  String get fwGLoading => 'g-Sättigung: 0,78 (die höchste im WAIS-IV)';

  @override
  String get fwPerfExceptional => 'Außergewöhnliche Leistung (θ > +2.0)';

  @override
  String get fwPerfSuperior => 'Überdurchschnittliche Leistung (θ > +1.0)';

  @override
  String get fwPerfAverage => 'Durchschnittliche Leistung (θ ≈ 0)';

  @override
  String get fwPerfInferior => 'Unterdurchschnittliche Leistung (θ < 0)';

  @override
  String get fwPerfLow => 'Schwache Leistung (θ < -1.0)';

  @override
  String fwScoreFraction(int score, int total) {
    return '$score/$total';
  }

  @override
  String get fwInstruction =>
      'Finden Sie den fehlenden Wert, der die Waage ins Gleichgewicht bringt.';

  @override
  String get fwWhatIs => 'Wie viel ist ';

  @override
  String fwSeconds(int seconds) {
    return '$seconds s';
  }

  @override
  String get vpTestName => 'Visuelle Puzzles';

  @override
  String get vpEyebrow => 'VISUELL-RÄUMLICH · VSI';

  @override
  String get vpCorrect => 'Richtig';

  @override
  String get vpIncorrect => 'Falsch';

  @override
  String get vpValidate => 'Bestätigen';

  @override
  String vpSelectedCount(int count) {
    return '$count / 3 ausgewählt';
  }

  @override
  String get vpInstruction =>
      'Wählen Sie die 3 Teile, die die Figur ergeben (Drehungen erlaubt, Spiegelungen nicht).';

  @override
  String get vpDemoEyebrow => 'DEMONSTRATION';

  @override
  String get vpDemoInstruction =>
      'Übung ohne Zeitlimit: Wählen Sie die 3 Teile, die die Figur ergeben, und bestätigen Sie.';

  @override
  String get vpDemoStart => 'Test starten';

  @override
  String get vpDemoRetry => 'Erneut versuchen';

  @override
  String get vpRecorded => 'Antwort gespeichert';

  @override
  String get vpReadyTitle => 'Bereit?';

  @override
  String vpReadyBody(int count) {
    return 'Das Training ist beendet. Der Test beginnt: $count Puzzles, jedes mit eigenem Zeitlimit. Die Zeit läuft, sobald Sie die Taste drücken.';
  }

  @override
  String get vpReadyStart => 'Jetzt starten';

  @override
  String vpSelectionSemantics(int filled, int total) {
    return 'Auswahl: $filled von $total Teilen';
  }

  @override
  String get vpSelectionLabel => 'AUSWAHL';

  @override
  String vpPieceSemantics(String label) {
    return 'Teil $label';
  }

  @override
  String get vpTargetTitle => 'ZU REKONSTRUIERENDE FIGUR';

  @override
  String get codingTestName => 'Symbol-Zahlen-Test (Digit Symbol)';

  @override
  String get codingEyebrow => 'VERARBEITUNGSGESCHWINDIGKEIT · PSI';

  @override
  String get codingStartTraining => 'Übung starten';

  @override
  String get codingTitle => 'Symbol-Zahlen-Test';

  @override
  String get codingDescription =>
      'Dieser Test misst Ihre Verarbeitungsgeschwindigkeit und Ihre visuomotorische Koordination.';

  @override
  String get codingReferenceKey => 'Referenzschlüssel:';

  @override
  String get codingTaskTitle => 'Ihre Aufgabe';

  @override
  String get codingTaskDesc =>
      'Wählen Sie zu jeder angezeigten Zahl das passende Symbol aus';

  @override
  String get codingTimeLimitTitle => 'Zeitlimit';

  @override
  String get codingTimeLimitDesc =>
      '120 Sekunden, um möglichst viele Felder auszufüllen (135 insgesamt)';

  @override
  String get codingScoringTitle => 'Bewertung';

  @override
  String get codingScoringDesc =>
      '1 Punkt pro korrektem Feld, kein Abzug für Fehler';

  @override
  String get codingTrainingDoneTitle => 'Übung abgeschlossen';

  @override
  String get codingTrainingDoneBody =>
      'Sie sind bereit, den Test zu beginnen. Sie haben 120 Sekunden, um möglichst viele Felder auszufüllen.';

  @override
  String get codingStartTest => 'Test starten';

  @override
  String get codingTestDoneTitle => 'Test abgeschlossen!';

  @override
  String get codingTimeElapsed => 'Verstrichene Zeit: 120 Sekunden';

  @override
  String codingCellsCompleted(int count) {
    return 'Ausgefüllte Felder: $count/135';
  }

  @override
  String codingCellsCorrect(int count) {
    return 'Korrekte Felder: $count';
  }

  @override
  String codingScorePoints(int count) {
    return 'Punktzahl: $count Punkte';
  }

  @override
  String get codingPerfExceptional => 'Außergewöhnliche Leistung!';

  @override
  String get codingPerfVeryGood => 'Sehr gute Leistung';

  @override
  String get codingPerfAboveAverage => 'Überdurchschnittliche Leistung';

  @override
  String get codingPerfAverage => 'Durchschnittliche Leistung';

  @override
  String get codingPerfBelowAverage => 'Unterdurchschnittliche Leistung';

  @override
  String get codingTrainingTab => 'Übung';

  @override
  String get codingReferenceShort => 'Referenz:';

  @override
  String codingCellProgress(int current, int total) {
    return 'Feld $current/$total';
  }

  @override
  String codingCompletedProgress(int count, int total) {
    return 'Ausgefüllt: $count/$total';
  }

  @override
  String get codingSelectSymbol => 'Wählen Sie ein Symbol:';

  @override
  String get codingClear => 'Löschen';

  @override
  String get codingFinishTraining => 'Übung beenden';

  @override
  String get ssTestName => 'Symbolsuche';

  @override
  String get ssDescription =>
      'Dieser Test misst Ihre visuelle Verarbeitungsgeschwindigkeit und Ihre Unterscheidungsfähigkeit.';

  @override
  String get ssExampleLabel => 'Beispielaufgabe:';

  @override
  String get ssTargets => 'ZIELE';

  @override
  String get ssGroup => 'GRUPPE';

  @override
  String get ssExampleAnswer => '→ Antwort: JA (┴ ist vorhanden)';

  @override
  String get ssTaskTitle => 'Ihre Aufgabe';

  @override
  String get ssTaskDesc =>
      'Prüfen Sie, ob eines der Zielsymbole in der Gruppe vorkommt';

  @override
  String get ssQuickAnswerTitle => 'Schnelle Antwort';

  @override
  String get ssQuickAnswerDesc =>
      'Tippen Sie so schnell wie möglich auf JA oder NEIN';

  @override
  String get ssScoringPenaltyTitle => 'Bewertung mit Abzug';

  @override
  String get ssScoringPenaltyDesc =>
      'Punktzahl = Korrekte Antworten - Falsche Antworten';

  @override
  String get ssTimeLimitTitle => 'Zeitlimit';

  @override
  String get ssTimeLimitDesc => '120 Sekunden für 60 Aufgaben';

  @override
  String get ssTrainingDoneBody =>
      'Sie sind bereit! Sie haben 120 Sekunden, um möglichst viele Aufgaben zu bearbeiten.\n\nHinweis: Punktzahl = Korrekte Antworten - Falsche Antworten';

  @override
  String ssItemsAnswered(int count) {
    return 'Beantwortete Aufgaben: $count/60';
  }

  @override
  String ssCorrectAnswers(int count) {
    return 'Korrekte Antworten: $count';
  }

  @override
  String ssIncorrectAnswers(int count) {
    return 'Falsche Antworten: $count';
  }

  @override
  String ssNotAnswered(int count) {
    return 'Nicht beantwortet: $count';
  }

  @override
  String ssRawScore(int count) {
    return 'Rohwert: $count';
  }

  @override
  String get ssScoreFormulaShort => '(Korrekt - Falsch)';

  @override
  String get ssPerfGood => 'Gute Leistung';

  @override
  String ssItemProgress(int current, int total) {
    return 'Aufgabe $current/$total';
  }

  @override
  String ssAnsweredProgress(int count) {
    return 'Beantwortet: $count/60';
  }

  @override
  String get ssTargetSymbols => 'ZIELSYMBOLE';

  @override
  String get ssSearchGroup => 'SUCHGRUPPE';

  @override
  String get ssNo => 'NEIN';

  @override
  String get ssYes => 'JA';

  @override
  String get dsTestName => 'Zahlennachsprechen';

  @override
  String get dsEyebrow => 'ARBEITSGEDÄCHTNIS · WMI';

  @override
  String get dsDescription =>
      'Dieser Test misst Ihr Arbeitsgedächtnis anhand von 3 verschiedenen Teilen:';

  @override
  String get dsForwardTitle => 'Teil 1: Vorwärts';

  @override
  String get dsForwardInstruction =>
      'Wiederholen Sie die Zahlen in derselben Reihenfolge';

  @override
  String get dsBackwardTitle => 'Teil 2: Rückwärts';

  @override
  String get dsBackwardInstruction =>
      'Wiederholen Sie die Zahlen in umgekehrter Reihenfolge';

  @override
  String get dsSequencingTitle => 'Teil 3: Sortieren';

  @override
  String get dsSequencingInstruction =>
      'Wiederholen Sie die Zahlen in aufsteigender Reihenfolge';

  @override
  String get dsPresentationInfo =>
      'Die Zahlen werden im Tempo von 1 Zahl pro Sekunde dargeboten.';

  @override
  String get dsTypeForward => 'Vorwärts';

  @override
  String get dsTypeBackward => 'Rückwärts';

  @override
  String get dsTypeSequencing => 'Sortieren';

  @override
  String get dsStartPart => 'Beginnen';

  @override
  String dsLengthTrial(int length, int trial) {
    return 'Länge $length - Versuch $trial';
  }

  @override
  String get dsListenCarefully => 'Hören Sie aufmerksam zu';

  @override
  String get dsCorrect => 'Korrekt!';

  @override
  String get dsIncorrect => 'Falsch';

  @override
  String dsPointsEarned(int count) {
    return 'Erzielte Punkte: $count';
  }

  @override
  String dsCorrectAnswer(String answer) {
    return 'Korrekte Antwort: $answer';
  }

  @override
  String dsYourAnswer(String answer) {
    return 'Ihre Antwort: $answer';
  }

  @override
  String get dsResultsByPart => 'Ergebnisse nach Teil:';

  @override
  String dsForwardScore(int count) {
    return 'Vorwärts: $count Punkte';
  }

  @override
  String dsBackwardScore(int count) {
    return 'Rückwärts: $count Punkte';
  }

  @override
  String dsSequencingScore(int count) {
    return 'Sortieren: $count Punkte';
  }

  @override
  String dsTotalScore(int count) {
    return 'Gesamtpunktzahl: $count Punkte';
  }

  @override
  String get dsEnterAnswer => 'Geben Sie Ihre Antwort ein...';

  @override
  String dsValidateProgress(int count, int total) {
    return 'Bestätigen ($count/$total)';
  }

  @override
  String get psTestName => 'Bilderspanne';

  @override
  String get psDescription =>
      'Dieser Test misst Ihr visuelles Arbeitsgedächtnis und Ihre selektive Aufmerksamkeit.';

  @override
  String get psPhase1Title => 'Phase 1: Einprägen';

  @override
  String get psPhase1Desc =>
      'Die Bilder werden nacheinander gezeigt (jeweils 3 Sekunden)';

  @override
  String get psPhase2Title => 'Phase 2: Wiedergabe';

  @override
  String get psPhase2Desc =>
      'Wählen Sie die Bilder in genau der gezeigten Reihenfolge aus';

  @override
  String get psProgressionTitle => 'Steigerung';

  @override
  String get psProgressionDesc =>
      'Der Schwierigkeitsgrad steigt: 1 bis 6 Bilder zum Einprägen';

  @override
  String get psTrialsInfo =>
      'Insgesamt 12 Durchgänge. Der Test endet nach 2 Fehlversuchen auf derselben Stufe.';

  @override
  String get psMemorizationTab => 'Einprägen';

  @override
  String get psRecallTab => 'Wiedergabe';

  @override
  String psLevelTrial(int level, int trial) {
    return 'Stufe $level - Versuch $trial';
  }

  @override
  String get psMemorizeImages => 'Prägen Sie sich die Bilder ein';

  @override
  String psImageProgress(int current, int total) {
    return 'Bild $current / $total';
  }

  @override
  String psSelectInOrder(int count) {
    return 'Wählen Sie die $count Bilder der Reihe nach aus';
  }

  @override
  String get psNoSelection => 'Keine Auswahl';

  @override
  String get psClearLast => 'Letzte Auswahl löschen';

  @override
  String psCorrectOrder(String names) {
    return 'Korrekte Reihenfolge: $names';
  }

  @override
  String psYourOrder(String names) {
    return 'Ihre Reihenfolge: $names';
  }

  @override
  String psTrialsCompleted(int count) {
    return 'Abgeschlossene Durchgänge: $count/12';
  }

  @override
  String psScorePoints(int count) {
    return 'Gesamtpunktzahl: $count Punkte';
  }

  @override
  String psMaxLevel(int level) {
    return 'Höchste erreichte Stufe: Stufe $level';
  }

  @override
  String get psImgChat => 'Katze';

  @override
  String get psImgInsecte => 'Insekt';

  @override
  String get psImgLapin => 'Hase';

  @override
  String get psImgOiseau => 'Vogel';

  @override
  String get psImgPoisson => 'Fisch';

  @override
  String get psImgTortue => 'Schildkröte';

  @override
  String get psImgPapillon => 'Schmetterling';

  @override
  String get psImgCoccinelle => 'Marienkäfer';

  @override
  String get psImgChaise => 'Stuhl';

  @override
  String get psImgLampe => 'Lampe';

  @override
  String get psImgMontre => 'Uhr';

  @override
  String get psImgParapluie => 'Regenschirm';

  @override
  String get psImgSac => 'Tasche';

  @override
  String get psImgLit => 'Bett';

  @override
  String get psImgPorte => 'Tür';

  @override
  String get psImgFenetre => 'Fenster';

  @override
  String get psImgGateau => 'Kuchen';

  @override
  String get psImgCafe => 'Kaffee';

  @override
  String get psImgPizza => 'Pizza';

  @override
  String get psImgPomme => 'Apfel';

  @override
  String get psImgGlace => 'Eis';

  @override
  String get psImgBurger => 'Burger';

  @override
  String get psImgSandwich => 'Sandwich';

  @override
  String get psImgOeuf => 'Ei';

  @override
  String get psImgMarteau => 'Hammer';

  @override
  String get psImgCle => 'Schraubenschlüssel';

  @override
  String get psImgCiseaux => 'Schere';

  @override
  String get psImgPinceau => 'Pinsel';

  @override
  String get psImgCrayon => 'Bleistift';

  @override
  String get psImgCouteau => 'Messer';

  @override
  String get psImgTournevis => 'Schraubendreher';

  @override
  String get psImgEngrenage => 'Zahnrad';

  @override
  String get psImgVoiture => 'Auto';

  @override
  String get psImgVelo => 'Fahrrad';

  @override
  String get psImgAvion => 'Flugzeug';

  @override
  String get psImgTrain => 'Zug';

  @override
  String get psImgBateau => 'Boot';

  @override
  String get psImgBus => 'Bus';

  @override
  String get psImgMoto => 'Motorrad';

  @override
  String get psImgFusee => 'Rakete';

  @override
  String get vocabTestName => 'Wortschatz';

  @override
  String get vocabEyebrow => 'SPRACHVERSTÄNDNIS · VCI';

  @override
  String vocabTimerScore(int seconds, int score) {
    return '$seconds s · $score Pkt.';
  }

  @override
  String get vocabFeedbackExcellent => 'Ausgezeichnet!';

  @override
  String get vocabFeedbackCorrect => 'Richtig';

  @override
  String get vocabFeedbackIncomplete => 'Unvollständige Antwort';

  @override
  String get vocabFeedbackTwoPoints =>
      'Vollständige und präzise Definition! +2 Punkte';

  @override
  String get vocabFeedbackOnePoint =>
      'Teilweise, aber richtige Definition. +1 Punkt';

  @override
  String get vocabFeedbackZeroPoint => 'Falsche oder zu vage Antwort. 0 Punkte';

  @override
  String vocabWordLabel(String word) {
    return 'Wort: „$word“';
  }

  @override
  String vocabYourAnswerLabel(String answer) {
    return 'Ihre Antwort: „$answer“';
  }

  @override
  String get vocabEmptyAnswer => '(leer)';

  @override
  String get vocabTwoPointExamples => 'Beispiele für 2-Punkte-Antworten:';

  @override
  String get vocabOnePointExamples => 'Beispiele für 1-Punkt-Antworten:';

  @override
  String vocabTimeSeconds(int seconds) {
    return 'Zeit: $seconds s';
  }

  @override
  String vocabTotalScore(int score) {
    return 'Gesamtpunktzahl: $score Punkte';
  }

  @override
  String get vocabDiscontinued =>
      '3 aufeinanderfolgende Nullwertungen – Test beendet (WAIS-IV)';

  @override
  String get vocabViewResults => 'Ergebnisse ansehen';

  @override
  String get vocabResultsTitle => 'Wortschatztest – Ergebnisse';

  @override
  String vocabRawScore(int score, int max) {
    return 'Rohwert: $score/$max Punkte';
  }

  @override
  String vocabItemsCompleted(int completed, int total) {
    return 'Bearbeitete Items: $completed/$total';
  }

  @override
  String vocabPercentage(int percent) {
    return 'Prozentsatz: $percent %';
  }

  @override
  String vocabTotalTime(int seconds) {
    return 'Gesamtzeit: $seconds s';
  }

  @override
  String get vocabTestCaption =>
      'Test zur Erfassung von Wortwissen und Sprachverständnis';

  @override
  String get vocabFrequencyBreakdownTitle => 'Aufschlüsselung nach Häufigkeit:';

  @override
  String vocabFrequencyBreakdownRow(String name, int score, int max) {
    return '$name: $score/$max Punkte';
  }

  @override
  String get vocabPerfExceptional => 'Außergewöhnliche Leistung (θ > +2,0)';

  @override
  String get vocabPerfSuperior => 'Überdurchschnittliche Leistung (θ > +1,0)';

  @override
  String get vocabPerfAverage => 'Durchschnittliche Leistung (θ ≈ 0)';

  @override
  String get vocabPerfBelowAverage => 'Unterdurchschnittliche Leistung (θ < 0)';

  @override
  String get vocabPerfLow => 'Schwache Leistung (θ < -1,0)';

  @override
  String get vocabFreqVeryHigh => 'Sehr häufig';

  @override
  String get vocabFreqHigh => 'Häufig';

  @override
  String get vocabFreqMedium => 'Mittel';

  @override
  String get vocabFreqLow => 'Selten';

  @override
  String get vocabFreqVeryLow => 'Sehr selten';

  @override
  String get vocabInstruction => 'Definieren Sie das folgende Wort';

  @override
  String get vocabYourDefinitionLabel => 'Ihre Definition:';

  @override
  String get vocabDefinitionHint => 'Schreiben Sie die Definition des Wortes …';

  @override
  String get vocabTipsTitle => 'Tipps, um 2 Punkte zu erreichen:';

  @override
  String get vocabTipComplete =>
      '• Geben Sie eine vollständige und präzise Definition';

  @override
  String get vocabTipSynonyms => '• Verwenden Sie genaue Synonyme';

  @override
  String get vocabTipContext => '• Erklären Sie die Bedeutung mit Kontext';

  @override
  String get demoBadge => 'ÜBUNG';

  @override
  String get demoNotice => 'Übung – dieser Versuch zählt nicht.';

  @override
  String get demoStart => 'Test starten';

  @override
  String get demoRetry => 'Erneut versuchen';

  @override
  String get demoContinue => 'Weiter';

  @override
  String get demoWellDone => 'Richtig!';

  @override
  String get demoTryAgain => 'Nicht ganz – versuchen Sie es erneut';

  @override
  String get ugTitle => 'Dein Ergebnis ist bereit';

  @override
  String get ugEyebrow => 'Letzte Schritte';

  @override
  String get ugFreeNotice =>
      'Der Test ist 100 % kostenlos. Um dein Ergebnis zu erhalten, fehlen noch einige einfache Schritte – sie werden automatisch bestätigt.';

  @override
  String get ugErrorBody =>
      'Der Freischaltstatus konnte nicht geladen werden. Prüfe deine Verbindung und versuche es erneut.';

  @override
  String get ugRetry => 'Erneut versuchen';

  @override
  String get ugRefresh => 'Aktualisieren';

  @override
  String get ugStep1Title => 'Lade 3 Freunde ein';

  @override
  String get ugStep1Body =>
      'Teile deinen persönlichen Link mit 3 Freunden. Dieser Schritt geht weiter, wenn sie ihren Test BEENDEN — nicht schon bei der Anmeldung. Erinnere sie ruhig daran.';

  @override
  String get ugCopyLink => 'Meinen Einladungslink kopieren';

  @override
  String get ugCopied => 'Link kopiert!';

  @override
  String ugInviteCounter(int joined, int required) {
    return '$joined/$required Freunde haben ihren Test beendet';
  }

  @override
  String get ugStep2Title => 'Deine Freunde machen ihren Test';

  @override
  String get ugStep2Body =>
      'Deine Freunde müssen nun ihren IQ-Test abschließen. Wir warten auf ihre Ergebnisse – erinnere sie ruhig daran!';

  @override
  String ugFriendDone(int n) {
    return 'Freund $n: Test abgeschlossen';
  }

  @override
  String ugFriendPending(int n) {
    return 'Freund $n: Test läuft';
  }

  @override
  String get ugWaitTitle => 'Deine Ergebnisse sind unterwegs';

  @override
  String get ugWaitBody =>
      'Dein Ergebnis wird vorbereitet. Es wird automatisch veröffentlicht – du musst nichts weiter tun. Du kannst diese Seite schließen.';

  @override
  String get ugRefreshFailed =>
      'Aktualisierung fehlgeschlagen. Prüfe deine Verbindung — die angezeigten Zahlen stammen vom letzten erfolgreichen Abruf.';

  @override
  String get ugResultsHubNotice =>
      'Alles findest du unter „Meine Ergebnisse“: deine Missionen, deinen Einladungslink und dein Ergebnis (unscharf, bis alle Missionen bestätigt sind). Du kannst diese Seite jederzeit verlassen und später zurückkommen.';

  @override
  String get histLockedTitle => 'Offene Missionen';

  @override
  String get histLockedBody =>
      'Dein Ergebnis ist gespeichert, bleibt aber unscharf, bis alle Missionen bestätigt sind.';

  @override
  String get histLockedBodyNoResult =>
      'Deine Missionen und dein Einladungslink sind hier. Schließe deine Auswertung ab, um dein Ergebnis freizuschalten.';

  @override
  String get histLockedCta => 'Meine Missionen ansehen';

  @override
  String get inviteLandingTitle => 'Einladung';

  @override
  String get inviteLandingBody =>
      'Ein Freund lädt dich zum kostenlosen Mentality-IQ-Test ein. Wenn du deinen Test abschließt, erhältst du dein eigenes Ergebnis und hilfst deinem Freund, seines freizuschalten.';

  @override
  String get inviteLandingCta => 'Kostenlosen Test starten';
}
