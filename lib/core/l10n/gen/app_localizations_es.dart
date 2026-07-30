// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Mental E.T.';

  @override
  String get languageSwitcherTooltip => 'Cambiar de idioma';

  @override
  String get commonValidate => 'Confirmar';

  @override
  String get commonNext => 'Siguiente';

  @override
  String get commonBack => 'Atrás';

  @override
  String get commonContinue => 'Continuar';

  @override
  String get commonStart => 'Empezar';

  @override
  String get commonSkip => 'Omitir';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonClose => 'Cerrar';

  @override
  String get commonRetry => 'Reintentar';

  @override
  String get commonLoading => 'Cargando...';

  @override
  String get commonError => 'Se ha producido un error';

  @override
  String get commonYes => 'Sí';

  @override
  String get commonNo => 'No';

  @override
  String get commonOk => 'Aceptar';

  @override
  String get commonFinish => 'Finalizar';

  @override
  String commonSeconds(int count) {
    return '$count s';
  }

  @override
  String get oralConsentRequiredCheckbox =>
      'Autorizo la grabación de mi voz y su análisis durante la realización de esta prueba. (obligatorio)';

  @override
  String get oralConsentCommercialCheckbox =>
      'Autorizo también la reutilización de mis grabaciones, de forma anonimizada, con fines de investigación y comerciales, incluida su cesión a terceros. (opcional)';

  @override
  String get oralConsentRequiredHint =>
      'Marque la primera casilla para poder empezar la prueba.';

  @override
  String get oralConsentPrivacyLink => 'Leer la política de privacidad';

  @override
  String get matDiscontinue3 =>
      '3 fallos consecutivos: prueba finalizada (WAIS-IV)';

  @override
  String get assessIntroTitle => 'Nueva evaluación';

  @override
  String get assessIntroEyebrow => 'EVALUACIÓN COGNITIVA';

  @override
  String get assessIntroHero1 => 'Cinco índices,';

  @override
  String get assessIntroHero2 => 'una medida.';

  @override
  String get assessIntroDescription =>
      'Esta evaluación mide tus capacidades cognitivas a través de seis dominios del WAIS-IV. Una puntuación global (CIT) constituye su síntesis.';

  @override
  String get assessDomainsHeader => 'DOMINIOS EVALUADOS';

  @override
  String get assessDomainVci => 'Comprensión Verbal';

  @override
  String get assessDomainVsi => 'Razonamiento Visoespacial';

  @override
  String get assessDomainFri => 'Razonamiento Fluido';

  @override
  String get assessDomainWmi => 'Memoria de Trabajo';

  @override
  String get assessDomainPsi => 'Velocidad de Procesamiento';

  @override
  String get assessDomainLo => 'Lenguaje Oral';

  @override
  String get assessBeforeStartHeader => 'ANTES DE EMPEZAR';

  @override
  String get assessBeforeStartBody =>
      'Duración estimada de 60 a 90 minutos. Se requiere tranquilidad y concentración.';

  @override
  String get assessLaunchFullAssessment => 'Iniciar la evaluación completa';

  @override
  String get assessOrIndividualSubtest => 'O SUBPRUEBA INDIVIDUAL';

  @override
  String get assessSubtestCubes => 'Cubos (Block Design)';

  @override
  String get assessSubtestMatrices => 'Matrices Progresivas';

  @override
  String get assessSubtestFigureWeights => 'Balanzas Cuantitativas';

  @override
  String get assessSubtestVisualPuzzles => 'Rompecabezas Visuales';

  @override
  String get assessSubtestSimilarities => 'Semejanzas';

  @override
  String get assessSubtestVocabulary => 'Vocabulario';

  @override
  String get assessSubtestInformation => 'Información';

  @override
  String get assessSubtestDigitSpan => 'Dígitos';

  @override
  String get assessSubtestArithmetic => 'Aritmética';

  @override
  String get assessSubtestPictureSpan => 'Memoria de Imágenes';

  @override
  String get assessSubtestCoding => 'Clave de Números';

  @override
  String get assessSubtestSymbolSearch => 'Búsqueda de Símbolos';

  @override
  String get assessSubtestOralComprehension => 'Comprensión Oral';

  @override
  String get authLoginTitle => 'Iniciar sesión';

  @override
  String get authCreateAccount => 'Crear una cuenta';

  @override
  String get authSignIn => 'Iniciar sesión';

  @override
  String get authHeaderSubtitleRegister =>
      'Crea una cuenta para guardar tus resultados';

  @override
  String get authHeaderSubtitleLogin =>
      'Inicia sesión para acceder a tu historial';

  @override
  String get authEmailLabel => 'Correo electrónico';

  @override
  String get authPasswordLabel => 'Contraseña';

  @override
  String get authFieldRequired => 'Campo obligatorio';

  @override
  String get authEmailInvalid => 'Correo electrónico no válido';

  @override
  String get authPasswordMinLength => 'Mínimo 8 caracteres';

  @override
  String get authOrDivider => 'o';

  @override
  String get authContinueWithGoogle => 'Continuar con Google';

  @override
  String get authToggleToLogin => '¿Ya tienes una cuenta? Inicia sesión';

  @override
  String get authToggleToRegister => '¿Aún no tienes cuenta? Regístrate';

  @override
  String get authFirebaseNotConfiguredFull =>
      'Firebase aún no está configurado. Sigue las instrucciones de firebase_config.dart.';

  @override
  String get authFirebaseNotConfigured => 'Firebase aún no está configurado.';

  @override
  String get histTitle => 'Mis resultados';

  @override
  String get histEyebrow => 'HISTORIAL';

  @override
  String get histDeleteResultTitle => '¿Eliminar este resultado?';

  @override
  String get histDeleteResultBody => 'Esta acción es irreversible.';

  @override
  String get histDelete => 'Eliminar';

  @override
  String histAgeYears(int age) {
    return '$age años';
  }

  @override
  String get histScoreFsiq => 'CI Total (CIT)';

  @override
  String get histScoreVci => 'ICV — Verbal';

  @override
  String get histScoreVsi => 'IVE — Visoespacial';

  @override
  String get histScoreFri => 'IRF — Razonamiento';

  @override
  String get histScoreWmi => 'IMT — Memoria';

  @override
  String get histScorePsi => 'IVP — Velocidad';

  @override
  String get histEmptyEyebrow => 'SIN RESULTADOS';

  @override
  String get histEmptyHero1 => 'Tu historial';

  @override
  String get histEmptyHero2 => 'te espera.';

  @override
  String get histEmptyDescription =>
      'Completa tu primera evaluación WAIS-IV para que tus resultados aparezcan aquí.';

  @override
  String get histStartAssessment => 'Empezar una evaluación';

  @override
  String get ctIntroTitle => 'Test completo';

  @override
  String get ctIntroHero1 => 'Doce subpruebas,';

  @override
  String get ctIntroHero2 => 'cuatro índices.';

  @override
  String get ctIntroDescription =>
      'Evaluación cognitiva completa y estandarizada. Las subpruebas se suceden de forma automática.';

  @override
  String get ctIntroDurationEyebrow => 'DURACIÓN';

  @override
  String get ctIntroDurationTitle => '60 a 90 minutos';

  @override
  String get ctIntroDurationBody => 'Reserva un intervalo de tiempo continuo.';

  @override
  String get ctIntroContentEyebrow => 'CONTENIDO';

  @override
  String get ctIntroContentTitle => '12 subpruebas incluidas';

  @override
  String get ctIntroContentBody =>
      'Cubos · Semejanzas · Memoria · Matrices · Vocabulario · Aritmética · Símbolos · Rompecabezas · Información · Clave · Imágenes · Balanzas.';

  @override
  String get ctIntroImportantEyebrow => 'IMPORTANTE';

  @override
  String get ctIntroImportantTitle => 'Encadenamiento automático';

  @override
  String get ctIntroImportantBody =>
      'Los tests se iniciarán uno tras otro. Asegúrate de disponer de tiempo suficiente.';

  @override
  String get ctPatientAgeHeader => 'EDAD DEL PACIENTE';

  @override
  String get ctPatientAgeHint => 'Necesaria para los baremos (16 a 90 años)';

  @override
  String get ctAgeSuffix => 'AÑOS';

  @override
  String get ctAgeRangeError => 'Edad entre 16 y 90 años';

  @override
  String get ctLaunchFullTest => 'Iniciar el test completo';

  @override
  String get ctRunningTitle => 'Test en curso';

  @override
  String get ctGlobalProgress => 'PROGRESO GLOBAL';

  @override
  String get ctNextSubtest => 'PRÓXIMA SUBPRUEBA';

  @override
  String get ctLaunching => 'Iniciando…';

  @override
  String get ctComputingResultsTitle => 'Cálculo de resultados';

  @override
  String get ctComputingResultsEyebrow => 'EVALUACIÓN';

  @override
  String get ctProcessing => 'PROCESANDO';

  @override
  String ctTestNotFound(String testName) {
    return 'Test no encontrado: $testName';
  }

  @override
  String get ctTestCubes => 'Cubos';

  @override
  String get ctTestSimilarities => 'Semejanzas';

  @override
  String get ctTestDigitSpan => 'Dígitos';

  @override
  String get ctTestMatrices => 'Matrices';

  @override
  String get ctTestVocabulary => 'Vocabulario';

  @override
  String get ctTestArithmetic => 'Aritmética';

  @override
  String get ctTestSymbolSearch => 'Búsqueda de Símbolos';

  @override
  String get ctTestVisualPuzzles => 'Rompecabezas Visuales';

  @override
  String get ctTestInformation => 'Información';

  @override
  String get ctTestCoding => 'Clave';

  @override
  String get ctTestPictureSpan => 'Memoria de Imágenes';

  @override
  String get ctTestFigureWeights => 'Balanzas';

  @override
  String get ctResultsTitle => 'Resultados';

  @override
  String get ctResultsEyebrow => 'EVALUACIÓN WAIS-IV';

  @override
  String get ctResultsHero1 => 'Evaluación';

  @override
  String get ctResultsHero2 => 'finalizada.';

  @override
  String get ctResultsSummary =>
      'Síntesis de tu rendimiento cognitivo en las doce subpruebas del WAIS-IV.';

  @override
  String ctAgeYears(int age) {
    return '$age años';
  }

  @override
  String get ctMetaDate => 'FECHA';

  @override
  String get ctMetaDuration => 'DURACIÓN';

  @override
  String get ctMetaSubtests => 'SUBPRUEBAS';

  @override
  String get ctMetaAge => 'EDAD';

  @override
  String get ctFsiqCardLabel => 'CI TOTAL · CIT';

  @override
  String ctConfidenceInterval95(int lower, int upper) {
    return 'IC 95 % · $lower – $upper';
  }

  @override
  String ctPercentileLabel(int rank) {
    return 'Percentil · $rank';
  }

  @override
  String get ctIndexProfileHeader => 'PERFIL DE LOS ÍNDICES';

  @override
  String get ctIndexVci => 'Comprensión Verbal';

  @override
  String get ctIndexVsi => 'Visoespacial';

  @override
  String get ctIndexFri => 'Razonamiento Fluido';

  @override
  String get ctIndexWmi => 'Memoria de Trabajo';

  @override
  String get ctIndexPsi => 'Velocidad de Procesamiento';

  @override
  String ctIndexCiPercentile(int lower, int upper, int rank) {
    return 'IC $lower–$upper · percentil $rank';
  }

  @override
  String ctIndexPercentile(int rank) {
    return 'percentil $rank';
  }

  @override
  String get ctStandardizedScoresHeader => 'PUNTUACIONES ESTANDARIZADAS';

  @override
  String get ctGroupVciVerbal => 'ICV · Verbal';

  @override
  String get ctGroupVsiVisuoSpatial => 'IVE · Visoespacial';

  @override
  String get ctGroupFriReasoning => 'IRF · Razonamiento';

  @override
  String get ctGroupWmiMemory => 'IMT · Memoria';

  @override
  String get ctGroupPsiSpeed => 'IVP · Velocidad';

  @override
  String ctRawScore(int raw) {
    return 'bruta $raw';
  }

  @override
  String get ctCognitiveProfileHeader => 'PERFIL COGNITIVO';

  @override
  String get ctProfileHomogeneous =>
      'Perfil homogéneo: los índices son coherentes entre sí.';

  @override
  String get ctProfileHeterogeneous =>
      'Perfil heterogéneo: disparidades notables entre los índices.';

  @override
  String ctMaxDiscrepancy(int points) {
    return 'Discrepancia máx. · $points pts';
  }

  @override
  String get ctRelativeStrengths => 'Fortalezas relativas';

  @override
  String get ctVigilancePoints => 'Aspectos a vigilar';

  @override
  String get ctIndicativeDisclaimer =>
      'Resultados orientativos. Para una evaluación clínica oficial, consulta a un neuropsicólogo o a un psicólogo cualificado.';

  @override
  String get ctRawScoresHeader => 'PUNTUACIONES BRUTAS';

  @override
  String get ctMissingAgeHeader => 'FALTA LA EDAD';

  @override
  String get ctMissingAgeBody =>
      'Sin la edad del paciente solo se muestran las puntuaciones brutas. Repite el test indicando la edad para obtener el CI estandarizado, los percentiles y los intervalos de confianza.';

  @override
  String get ctExportPdf => 'Exportar a PDF';

  @override
  String ctPdfError(String error) {
    return 'Error de PDF: $error';
  }

  @override
  String get ctBackToHome => 'Volver al inicio';

  @override
  String get ctPdfSubtitle => 'Informe de evaluación cognitiva WAIS-IV';

  @override
  String get ctPdfNotProvided => 'No indicada';

  @override
  String ctPdfDurationMinSec(int min, int sec) {
    return '$min min $sec s';
  }

  @override
  String get ctPdfAge => 'Edad';

  @override
  String get ctPdfDuration => 'Duración';

  @override
  String get ctPdfDate => 'Fecha';

  @override
  String get ctPdfFsiqLabel => 'PUNTUACIÓN DE CI GLOBAL (CIT)';

  @override
  String get ctPdfConfidenceInterval95 => 'Intervalo de confianza del 95 %';

  @override
  String get ctPdfPercentile => 'Percentil';

  @override
  String ctPercentileValue(int rank) {
    return '$rank';
  }

  @override
  String get ctPdfIndexProfileHeader => 'PERFIL DE LOS ÍNDICES COGNITIVOS';

  @override
  String get ctPdfIndexVci => 'ICV — Comprensión Verbal';

  @override
  String get ctPdfIndexVsi => 'IVE — Visoespacial';

  @override
  String get ctPdfIndexFri => 'IRF — Razonamiento Fluido';

  @override
  String get ctPdfIndexWmi => 'IMT — Memoria de Trabajo';

  @override
  String get ctPdfIndexPsi => 'IVP — Velocidad de Procesamiento';

  @override
  String get ctPdfColIndex => 'Índice';

  @override
  String get ctPdfColScore => 'Puntuación';

  @override
  String get ctPdfColClassification => 'Clasificación';

  @override
  String get ctPdfRawScoresHeader => 'PUNTUACIONES BRUTAS DE LAS SUBPRUEBAS';

  @override
  String get ctPdfColSubtest => 'Subprueba';

  @override
  String get ctPdfColRawScore => 'Puntuación bruta';

  @override
  String get ctPdfDisclaimer =>
      'AVISO: Este informe ha sido generado por una aplicación de apoyo a la evaluación y no constituye un diagnóstico clínico oficial. Debe ser interpretado por un profesional sanitario cualificado. No utilizar con fines médicos o legales sin una evaluación profesional complementaria.';

  @override
  String get chatEyebrow => 'ASISTENTE IA';

  @override
  String get chatNewConversation => 'Nueva conversación';

  @override
  String get chatAssistantLabel => 'MENTAL E.T.';

  @override
  String get chatUserLabel => 'TÚ';

  @override
  String get chatHeroTitle1 => 'Plantea';

  @override
  String get chatHeroTitle2 => 'tus preguntas.';

  @override
  String get chatEmptyIntro =>
      'La IA de Mental E.T. te ayuda a comprender mejor tu perfil cognitivo. Conversaciones confidenciales, acompañamiento no directivo.';

  @override
  String get chatThinking => 'Pensando…';

  @override
  String get chatInputHint => 'Escribe un mensaje…';

  @override
  String get chatTimeJustNow => 'justo ahora';

  @override
  String chatTimeMinutes(int count) {
    return '$count min';
  }

  @override
  String chatTimeHours(int count) {
    return '$count h';
  }

  @override
  String get chatErrorMessage =>
      'Lo sentimos, se ha producido un error. Inténtalo de nuevo.';

  @override
  String get chatErrorEmptyResponse => 'Respuesta vacía del worker';

  @override
  String get chatErrorAccessDenied =>
      'Acceso denegado por el worker (origen no autorizado).';

  @override
  String get chatErrorRateLimit =>
      'Se ha alcanzado el límite de solicitudes. Inténtalo de nuevo en unos instantes.';

  @override
  String chatErrorServer(int code) {
    return 'Error del servidor ($code)';
  }

  @override
  String chatErrorHttp(int code, String body) {
    return 'Error $code: $body';
  }

  @override
  String get coreSplashTitleLine1 => 'Evaluación';

  @override
  String get coreSplashTitleLine2 => 'cognitiva';

  @override
  String get commonNotAvailable => 'N/D';

  @override
  String get pdfFilenameBase => 'mentality_resultados';

  @override
  String coreRouteNotFound(String path) {
    return 'Página no encontrada: $path';
  }

  @override
  String get homeHeroTitle => 'Descubre';

  @override
  String get homeHeroTitleItalic => 'tu perfil cognitivo.';

  @override
  String get homeHeroBody =>
      'Una evaluación científica y adaptativa, inspirada en las escalas Wechsler. 12 subpruebas, 5 índices, una puntuación global.';

  @override
  String get homeActionStartTitle => 'Comenzar una evaluación';

  @override
  String get homeActionStartSubtitle => 'Duración: 60 – 90 minutos';

  @override
  String get homeActionResultsTitle => 'Mis resultados';

  @override
  String get homeActionResultsSubtitle => 'Historial de evaluaciones';

  @override
  String get homeActionChatTitle => 'Hablar con Mental E.T.';

  @override
  String get homeActionChatSubtitle =>
      'Asistente de IA, preguntas de psicología';

  @override
  String get homeComingSoon => 'PRÓXIMAMENTE';

  @override
  String get homeAboutEyebrow => 'ACERCA DE';

  @override
  String get homeAboutSubtestsTitle => '12 subpruebas';

  @override
  String get homeAboutSubtestsBody =>
      'Una evaluación completa de los cinco índices cognitivos del WAIS-IV.';

  @override
  String get homeAboutAdaptiveTitle => 'IA adaptativa';

  @override
  String get homeAboutAdaptiveBody =>
      'Dificultad ajustada en tiempo real mediante inferencia TRI.';

  @override
  String get homeAboutValidationTitle => 'Validación científica';

  @override
  String get homeAboutValidationBody =>
      'Ítems inspirados en las escalas Wechsler (WPPSI / WISC / WAIS).';

  @override
  String get homeResumeEyebrow => 'TEST EN CURSO';

  @override
  String get homeResumeTitle => 'Reanudar tu evaluación';

  @override
  String get homeResumeButton => 'Reanudar';

  @override
  String get homeLogoutTitle => '¿Cerrar sesión?';

  @override
  String get homeLogoutBody =>
      'Tu token se eliminará de este dispositivo. Asegúrate de haberlo guardado: sin él, no podrás volver a acceder a tus datos.';

  @override
  String get homeLogoutConfirm => 'Cerrar sesión';

  @override
  String get infoTestName => 'Información';

  @override
  String get infoEyebrow => 'COMPRENSIÓN VERBAL · ICV';

  @override
  String infoTrailingStatus(int seconds, int score, int attempted) {
    return '${seconds}s · $score/$attempted';
  }

  @override
  String get infoCorrect => '¡Correcto!';

  @override
  String get infoIncorrect => 'Incorrecto';

  @override
  String get infoFeedbackRight => '¡Respuesta correcta! +1 punto';

  @override
  String get infoFeedbackWrong => 'Respuesta incorrecta. 0 puntos';

  @override
  String infoQuestionLabel(String question) {
    return 'Pregunta: $question';
  }

  @override
  String infoCorrectAnswerLabel(String answer) {
    return 'Respuesta correcta: $answer';
  }

  @override
  String infoTimeLabel(int seconds) {
    return 'Tiempo: ${seconds}s';
  }

  @override
  String infoScoreLabel(int score, int attempted) {
    return 'Puntuación: $score/$attempted';
  }

  @override
  String infoDomainLabel(String domain) {
    return 'Ámbito: $domain';
  }

  @override
  String get infoDiscontinue3 =>
      '3 fallos consecutivos: prueba finalizada (WAIS-IV)';

  @override
  String get infoSeeResults => 'Ver los resultados';

  @override
  String get infoResultsTitle => 'Prueba de Información: resultados';

  @override
  String infoRawScore(int score, int max) {
    return 'Puntuación bruta: $score/$max puntos';
  }

  @override
  String infoItemsCompleted(int completed, int total) {
    return 'Ítems completados: $completed/$total';
  }

  @override
  String infoPercentage(int percent) {
    return 'Porcentaje: $percent%';
  }

  @override
  String infoTotalTime(int seconds) {
    return 'Tiempo total: ${seconds}s';
  }

  @override
  String get infoTestSubtitle => 'Prueba de conocimientos generales adquiridos';

  @override
  String get infoDomainBreakdownTitle => 'Desglose por ámbito:';

  @override
  String infoDomainBreakdownRow(String domain, int correct, int total) {
    return '$domain: $correct/$total';
  }

  @override
  String get infoPerfExceptional => 'Rendimiento excepcional (θ > +2.0)';

  @override
  String get infoPerfSuperior => 'Rendimiento superior (θ > +1.0)';

  @override
  String get infoPerfAverage => 'Rendimiento medio (θ ≈ 0)';

  @override
  String get infoPerfBelow => 'Rendimiento inferior (θ < 0)';

  @override
  String get infoPerfLow => 'Rendimiento bajo (θ < -1.0)';

  @override
  String get infoDomainScience => 'Ciencias naturales';

  @override
  String get infoDomainHistoryGeography => 'Historia/Geografía';

  @override
  String get infoDomainGeneralCulture => 'Cultura general';

  @override
  String get infoDomainMathLogic => 'Matemáticas/Lógica';

  @override
  String get infoDomainArtsLiterature => 'Arte/Literatura';

  @override
  String get infoDifficultyEasy => 'Fácil';

  @override
  String get infoDifficultyMedium => 'Medio';

  @override
  String get infoDifficultyHard => 'Difícil';

  @override
  String get arithTestName => 'Aritmética';

  @override
  String get arithEyebrow => 'MEMORIA DE TRABAJO · IMT';

  @override
  String get arithStartTest => 'Comenzar la prueba';

  @override
  String get arithIntroTitle => 'Prueba de Aritmética';

  @override
  String get arithIntroDescription =>
      'Esta prueba evalúa tu memoria de trabajo y tu razonamiento numérico.';

  @override
  String get arithInfoMentalTitle => 'Solo cálculo mental';

  @override
  String get arithInfoMentalSubtitle =>
      'Resuelve los problemas sin papel ni calculadora';

  @override
  String get arithInfoTimeTitle => 'Tiempo limitado';

  @override
  String get arithInfoTimeSubtitle =>
      'Cada problema tiene un límite de tiempo (15-60 segundos)';

  @override
  String get arithInfoBonusTitle => 'Bonificación por rapidez';

  @override
  String get arithInfoBonusSubtitle =>
      'Respuestas rápidas en ciertos ítems = puntos extra';

  @override
  String get arithInfoRepeatTitle => 'Repetición disponible';

  @override
  String get arithInfoRepeatSubtitle =>
      'Puedes pedir que se repita UNA vez (el cronómetro sigue corriendo)';

  @override
  String get arithIntroDiscontinueNote =>
      '22 problemas en total. La prueba se detiene tras 3 fallos consecutivos.';

  @override
  String arithProblemCounter(int current, int total) {
    return 'Problema $current/$total';
  }

  @override
  String get arithRepeatTitle => 'Repetición del problema';

  @override
  String get arithUnderstood => 'Entendido';

  @override
  String get arithTimeUp => '¡Se acabó el tiempo!';

  @override
  String arithCorrectAnswerLabel(int answer) {
    return 'Respuesta correcta: $answer';
  }

  @override
  String get arithCorrect => '¡Correcto!';

  @override
  String get arithIncorrect => 'Incorrecto';

  @override
  String arithTimeSpent(int seconds) {
    return 'Tiempo: $seconds segundos';
  }

  @override
  String get arithSpeedBonus => '🎉 ¡Bonificación por rapidez! (+1 punto)';

  @override
  String get arithTestEnded => '¡Prueba finalizada!';

  @override
  String arithItemsCompleted(int completed, int total) {
    return 'Ítems completados: $completed/$total';
  }

  @override
  String arithBaseScore(int score) {
    return 'Puntuación base: $score puntos';
  }

  @override
  String arithBonusScore(int bonus) {
    return 'Bonificación por rapidez: $bonus puntos';
  }

  @override
  String arithTotalScore(int total) {
    return 'Puntuación total: $total puntos';
  }

  @override
  String get arithRepeat => 'Repetir';

  @override
  String get arithAnswerHint => 'Tu respuesta';

  @override
  String get arithDifficultyEasy => 'Fácil';

  @override
  String get arithDifficultyMedium => 'Medio';

  @override
  String get arithDifficultyHard => 'Difícil';

  @override
  String get arithDifficultyVeryHard => 'Muy difícil';

  @override
  String get oralMicAccessTitle => 'Acceso al micrófono';

  @override
  String get oralReadingPermissionBody1 =>
      'Esta actividad graba tu voz mientras lees el texto en voz alta.';

  @override
  String get oralReadingPermissionBody2 =>
      'Tus grabaciones se anonimizarán y podrán contribuir a mejorar el reconocimiento de voz.';

  @override
  String get oralBrowserWillAskMic =>
      'A continuación, tu navegador te pedirá que autorices el micrófono.';

  @override
  String get oralCancel => 'Cancelar';

  @override
  String get oralAllowMicrophone => 'Autorizar el micrófono';

  @override
  String get oralMicDeniedOrUnavailable =>
      'Micrófono denegado o no disponible.';

  @override
  String get oralCannotStartRecording =>
      'No se puede iniciar la grabación en este navegador.';

  @override
  String oralCanSkipToNextStep(String message) {
    return '$message Puedes pasar al siguiente paso.';
  }

  @override
  String get oralSkip => 'Omitir';

  @override
  String get oralRecordingInProgress => 'Grabación en curso';

  @override
  String oralKeepGoingSeconds(int seconds) {
    return 'Continúa ${seconds}s más...';
  }

  @override
  String get oralSaving => 'Guardando...';

  @override
  String get oralReadingInstructions =>
      'Lee el siguiente texto en voz alta, con claridad y a tu ritmo natural. Pulsa «Empezar» cuando estés listo.';

  @override
  String get oralStartReading => 'Empezar la lectura';

  @override
  String get oralFinish => 'Finalizar';

  @override
  String get oralSkipThisStep => 'Omitir este paso';

  @override
  String get oralSummaryPermissionBody1 =>
      'Ahora vas a grabar tu resumen oral del texto.';

  @override
  String get oralSummaryPermissionBody2 =>
      'Habla con naturalidad, como si le explicaras el texto a un amigo. Tómate entre 30 y 60 segundos.';

  @override
  String get oralStartSummary => 'Empezar el resumen';

  @override
  String get oralSummaryInstructionLead => 'Acabas de leer este texto. ';

  @override
  String get oralSummaryInstructionBody =>
      'Resume lo que has entendido con tus propias palabras. Tómate entre 30 y 60 segundos. Habla con naturalidad, como si se lo explicaras a un amigo.';

  @override
  String get oralReferenceText => 'Texto de referencia';

  @override
  String get oralFinishSummary => 'Finalizar el resumen';

  @override
  String get oralFlowTitle => 'Recogida de audio';

  @override
  String get oralConsentTitle => 'Test de Comprensión Oral';

  @override
  String get oralConsentRecordTitle => 'Lo que grabamos';

  @override
  String get oralConsentRecordBody =>
      'Tu voz mientras lees 5 textos breves (alrededor de 1 min cada uno) y tu resumen oral (alrededor de 40 segundos por texto).';

  @override
  String get oralConsentAnonTitle => 'Confidencialidad';

  @override
  String get oralConsentAnonBody =>
      'Tus grabaciones se identifican mediante un código de sesión aleatorio, no por tu nombre. No obstante, siguen pudiendo vincularse a tu cuenta: son datos personales protegidos, cifrados y almacenados en Europa.';

  @override
  String get oralConsentUsageTitle => 'Uso';

  @override
  String get oralConsentUsageBody =>
      'Estas grabaciones podrán contribuir a mejorar el reconocimiento de voz, en particular para modelos como Whisper o Speechmatics.';

  @override
  String get oralAcceptAndStart => 'Acepto y empiezo';

  @override
  String get oralDeclineAndGoBack => 'Rechazar y volver atrás';

  @override
  String get oralWithdrawConsentNote =>
      'Puedes retirar tu consentimiento en cualquier momento desde los ajustes de la aplicación.';

  @override
  String oralTextProgress(int current) {
    return 'Texto $current de 5';
  }

  @override
  String get oralStepReading => 'Lectura';

  @override
  String get oralStepSummary => 'Resumen';

  @override
  String get oralPauseWellDone => '¡Bien!';

  @override
  String get oralPauseNowSummarize => 'Ahora, resume oralmente este texto.';

  @override
  String get oralPauseStartingIn => 'Empieza en...';

  @override
  String get oralCompletedThanks => '¡Gracias!';

  @override
  String get oralCompletedBody =>
      'Has completado los 5 textos.\nTus grabaciones contribuirán a mejorar\nel reconocimiento de voz.';

  @override
  String get oralBackToHome => 'Volver al inicio';

  @override
  String get oralExitDialogTitle => '¿Salir?';

  @override
  String get oralExitDialogBody =>
      'Hay una grabación en curso. Si sales ahora, no se guardará.';

  @override
  String get oralContinue => 'Continuar';

  @override
  String get oralQuit => 'Salir';

  @override
  String regStepEyebrow(int step) {
    return 'PASO $step / 4';
  }

  @override
  String get regStepEyebrowSuccess => 'PASO 4 / 4 · COMPLETADO';

  @override
  String get regEmailTitle => 'Crear mi token';

  @override
  String get regEmailHeading => 'Tu correo electrónico';

  @override
  String get regEmailIntro =>
      'Te enviaremos un código de verificación de 6 dígitos. Tu correo electrónico no está vinculado a tu token y se mantiene privado.';

  @override
  String get regEmailFieldLabel => 'Correo electrónico';

  @override
  String get regEmailInvalid => 'Correo electrónico no válido';

  @override
  String get regSendingCode => 'Enviando el código…';

  @override
  String get regReceiveCode => 'Recibir el código';

  @override
  String get regEmailPrivacyNote =>
      'No se almacenará ningún nombre, apellido ni dirección exacta. Solo tu sexo, franja de edad y código postal quedan codificados (cifrados) en tu token anónimo.';

  @override
  String get regEmailOtpTitle => 'Verificar mi correo electrónico';

  @override
  String get regCodeSentTo => 'Código enviado a';

  @override
  String get regVerifying => 'Verificando…';

  @override
  String get regResendCode => 'Reenviar el código';

  @override
  String get regPhoneTitle => 'Tu teléfono';

  @override
  String get regPhoneIntro =>
      'Se enviará un código SMS de 6 dígitos para verificar tu número. No hay ningún vínculo entre tu número y tu token.';

  @override
  String get regPhoneFieldHint => 'Número';

  @override
  String get regSendingSms => 'Enviando el SMS…';

  @override
  String get regReceiveSms => 'Recibir el SMS';

  @override
  String get regPhoneOtpTitle => 'Verificar mi teléfono';

  @override
  String get regSmsSentTo => 'SMS enviado al';

  @override
  String get regResendSms => 'Reenviar el SMS';

  @override
  String get regDemoTitle => 'Tus datos demográficos';

  @override
  String get regDemoIntro =>
      'Esta información se cifrará en tu token. No se almacena ningún valor exacto (ni tu edad precisa ni tu dirección exacta).';

  @override
  String get regSectionSex => 'SEXO';

  @override
  String get regSectionAgeBucket => 'FRANJA DE EDAD';

  @override
  String get regSectionCountryPostal => 'PAÍS Y CÓDIGO POSTAL';

  @override
  String get regPostalCodeHint => 'Código postal';

  @override
  String get regGeneratingToken => 'Generando el token…';

  @override
  String get regGenerateMyToken => 'Generar mi token';

  @override
  String get regSuccessTitle => 'Te damos la bienvenida a Mental E.T.';

  @override
  String get regSuccessTokenSaved =>
      'Tu token anónimo se ha generado y guardado en este dispositivo.';

  @override
  String get regSuccessTokenDetails =>
      'No contiene tu correo electrónico, ni tu número de teléfono, ni tu nombre. Únicamente tu sexo, tu franja de edad y tu zona geográfica (cifrados). Ya puedes comenzar tu evaluación cognitiva.';

  @override
  String get regImportantLabel => 'IMPORTANTE';

  @override
  String get regSuccessWarning =>
      'No desinstales la aplicación sin haber finalizado tu evaluación: tu token solo se almacena en este dispositivo. Si lo pierdes, no podrás crear una nueva cuenta con el mismo correo electrónico o teléfono.';

  @override
  String get regEmailAlreadyRegistered =>
      'Este correo electrónico ya tiene una cuenta. Si es el tuyo, ya dispones de un token.';

  @override
  String get regEmailUnavailable => 'Correo electrónico no disponible.';

  @override
  String get regOtpIncorrectOrExpired => 'Código incorrecto o caducado.';

  @override
  String get regPhoneAlreadyRegistered => 'Este número ya tiene una cuenta.';

  @override
  String get regPhoneUnavailable => 'Número no disponible.';

  @override
  String get regEmailAlreadyHasToken =>
      'Este correo electrónico ya tiene un token.';

  @override
  String get regPhoneAlreadyHasToken => 'Este número ya tiene un token.';

  @override
  String get regPostalNotFound =>
      'Código postal no encontrado. Comprueba el país y el código.';

  @override
  String get regNoInternet => 'Sin conexión a internet.';

  @override
  String get regGenericRetryError => 'Error: vuelve a intentarlo.';

  @override
  String get regSexMale => 'Masculino';

  @override
  String get regSexFemale => 'Femenino';

  @override
  String get regSexUndisclosed => 'Prefiero no decirlo';

  @override
  String get regAge1825 => '18 – 25 años';

  @override
  String get regAge2635 => '26 – 35 años';

  @override
  String get regAge3645 => '36 – 45 años';

  @override
  String get regAge4655 => '46 – 55 años';

  @override
  String get regAge5665 => '56 – 65 años';

  @override
  String get regAge66plus => '66 años o más';

  @override
  String get scoringClassificationVerySuperior => 'Muy superior';

  @override
  String get scoringClassificationSuperior => 'Superior';

  @override
  String get scoringClassificationHighAverage => 'Medio alto';

  @override
  String get scoringClassificationAverage => 'Medio';

  @override
  String get scoringClassificationLowAverage => 'Medio bajo';

  @override
  String get scoringClassificationBorderline => 'Límite';

  @override
  String get scoringClassificationExtremelyLow => 'Extremadamente bajo';

  @override
  String get scoringNotAvailable => 'N/D';

  @override
  String scoringSummaryFullScaleIq(int score, String classification) {
    return 'CI total: $score ($classification)';
  }

  @override
  String scoringSummaryPercentile(int rank) {
    return 'Percentil: $rank';
  }

  @override
  String scoringSummaryConfidenceInterval(int lower, int upper) {
    return 'Intervalo de confianza del 95 %: $lower - $upper';
  }

  @override
  String get scoringIndexVerbalComprehension => 'Comprensión verbal';

  @override
  String get scoringIndexVisualSpatial => 'Visoespacial';

  @override
  String get scoringIndexFluidReasoning => 'Razonamiento fluido';

  @override
  String get scoringIndexWorkingMemory => 'Memoria de trabajo';

  @override
  String get scoringIndexProcessingSpeed => 'Velocidad de procesamiento';

  @override
  String scoringSummaryRelativeStrengths(String list) {
    return 'Fortalezas relativas: $list';
  }

  @override
  String scoringSummaryRelativeWeaknesses(String list) {
    return 'Debilidades relativas: $list';
  }

  @override
  String get scoringSummaryHomogeneousProfile => 'Perfil cognitivo homogéneo';

  @override
  String scoringSummaryHeterogeneousProfile(int points) {
    return 'Perfil cognitivo heterogéneo (diferencia máxima: $points puntos)';
  }

  @override
  String get simTestName => 'Semejanzas';

  @override
  String get simEyebrow => 'COMPRENSIÓN VERBAL · ICV';

  @override
  String simStatusBar(int seconds, int score) {
    return '$seconds s · $score pts';
  }

  @override
  String get simQuestionPrompt => '¿En qué se parecen estas dos palabras?';

  @override
  String simLevelLabel(String level) {
    return 'Nivel: $level';
  }

  @override
  String get simLevelConcrete => 'Concreto';

  @override
  String get simLevelFunctional => 'Funcional';

  @override
  String get simLevelCategorical => 'Categórico';

  @override
  String get simLevelAbstract => 'Abstracto';

  @override
  String get simAnswerLabel => 'Tu respuesta:';

  @override
  String get simAnswerHint => 'Explica en qué se parecen...';

  @override
  String get simTipsTitle => 'Consejos para obtener 2 puntos:';

  @override
  String get simTipsLine1 => '• Da una categoría abstracta o superordinada';

  @override
  String get simTipsLine2 => '• Ej.: «Son...», «Formas de...», «Tipos de...»';

  @override
  String get simFeedbackExcellent => '¡Excelente!';

  @override
  String get simFeedbackCorrect => 'Correcto';

  @override
  String get simFeedbackIncomplete => 'Respuesta incompleta';

  @override
  String get simFeedbackMsg2pts =>
      '¡Respuesta abstracta o categórica! +2 puntos';

  @override
  String get simFeedbackMsg1pt =>
      'Respuesta funcional o de propiedad. +1 punto';

  @override
  String get simFeedbackMsg0pt =>
      'Respuesta incorrecta o demasiado vaga. 0 puntos';

  @override
  String simYourAnswerQuoted(String answer) {
    return 'Tu respuesta: «$answer»';
  }

  @override
  String get simExamples2pts => 'Ejemplos de respuestas de 2 puntos:';

  @override
  String get simExamples1pt => 'Ejemplos de respuestas de 1 punto:';

  @override
  String simTimeSeconds(int seconds) {
    return 'Tiempo: $seconds s';
  }

  @override
  String simTotalScore(int score) {
    return 'Puntuación total: $score puntos';
  }

  @override
  String get simDiscontinue =>
      '3 puntuaciones de 0 consecutivas: prueba finalizada (WAIS-IV)';

  @override
  String get simSeeResults => 'Ver resultados';

  @override
  String get simResultsTitle => 'Prueba de Semejanzas — Resultados';

  @override
  String simRawScore(int score, int max) {
    return 'Puntuación directa: $score/$max puntos';
  }

  @override
  String simItemsCompleted(int completed, int total) {
    return 'Ítems completados: $completed/$total';
  }

  @override
  String simPercentage(int percent) {
    return 'Porcentaje: $percent%';
  }

  @override
  String simTotalTime(int seconds) {
    return 'Tiempo total: $seconds s';
  }

  @override
  String get simSubtitle =>
      'Prueba de razonamiento verbal y abstracción conceptual';

  @override
  String get simBreakdownTitle => 'Desglose por nivel:';

  @override
  String simBreakdownLine(String level, int total, int max) {
    return '$level: $total/$max puntos';
  }

  @override
  String get simPerfExceptional => 'Rendimiento excepcional (θ > +2.0)';

  @override
  String get simPerfSuperior => 'Rendimiento superior (θ > +1.0)';

  @override
  String get simPerfAverage => 'Rendimiento medio (θ ≈ 0)';

  @override
  String get simPerfBelow => 'Rendimiento inferior (θ < 0)';

  @override
  String get simPerfLow => 'Rendimiento bajo (θ < -1.0)';

  @override
  String get simBack => 'Volver';

  @override
  String get matTestName => 'Matrices Progresivas';

  @override
  String get matEyebrow => 'TEST DE CI · CIT';

  @override
  String get matCorrect => '¡Correcto!';

  @override
  String get matIncorrect => 'Incorrecto';

  @override
  String matResponseTime(int seconds) {
    return 'Tiempo de respuesta: $seconds s';
  }

  @override
  String matScoreFraction(int score, int total) {
    return 'Puntuación: $score/$total';
  }

  @override
  String get matDiscontinue4 =>
      '4 fallos consecutivos - Test finalizado (WAIS-IV)';

  @override
  String get matSeeResultsEnded => 'Ver resultados (test finalizado)';

  @override
  String get matNextItem => 'Siguiente ítem';

  @override
  String get matSeeResults => 'Ver resultados';

  @override
  String get matFinishedTitle => '¡Test de Matrices finalizado!';

  @override
  String get matRawScore => 'Puntuación bruta';

  @override
  String get matSuccessRate => 'Tasa de acierto';

  @override
  String get matAvgTimePerItem => 'Tiempo medio/ítem';

  @override
  String get matEvaluation => 'Evaluación:';

  @override
  String get matPerfExcellent =>
      '¡Excelente! Razonamiento fluido muy superior.';

  @override
  String get matPerfVeryGood =>
      '¡Muy bien! Buena capacidad de análisis lógico.';

  @override
  String get matPerfGood => 'Bien. Capacidad media a buena.';

  @override
  String get matPerfAverage => 'Medio. Hay margen de mejora.';

  @override
  String get matPerfBelowAverage =>
      'Resultados por debajo de la media. Se recomienda practicar.';

  @override
  String matPoints(int score) {
    return '$score pts';
  }

  @override
  String get matValidateAnswer => 'Validar la respuesta';

  @override
  String get matRestart => 'Empezar de nuevo';

  @override
  String matRulesTheta(int rules, String theta) {
    return 'Reglas: $rules | θ = $theta';
  }

  @override
  String get matInstruction =>
      'Encuentra la pieza que falta para completar lógicamente la matriz';

  @override
  String get matChooseAnswer => 'Elige tu respuesta:';

  @override
  String get matDiffEasy => 'Fácil';

  @override
  String get matDiffMediumEasy => 'Medio-Fácil';

  @override
  String get matDiffMedium => 'Medio';

  @override
  String get matDiffMediumHard => 'Medio-Difícil';

  @override
  String get matDiffHard => 'Difícil';

  @override
  String get cubesTestName => 'Test de Cubos';

  @override
  String get cubesBravo => '¡Bien hecho!';

  @override
  String cubesElapsedTime(String time) {
    return 'Tiempo transcurrido: $time';
  }

  @override
  String cubesPointsEarned(int points) {
    return 'Puntos obtenidos: $points';
  }

  @override
  String cubesTotalScore(int score) {
    return 'Puntuación total: $score';
  }

  @override
  String get cubesFinishedTitle => '¡Test finalizado!';

  @override
  String get cubesTotalScoreLabel => 'Puntuación total';

  @override
  String cubesTotalScoreValue(int score, int max) {
    return '$score/$max pts';
  }

  @override
  String get cubesItemsCompletedLabel => 'Ítems completados';

  @override
  String cubesItemsCompletedValue(int count) {
    return '$count/14';
  }

  @override
  String get cubesAvgTime => 'Tiempo medio';

  @override
  String get cubesPerfExcellent =>
      '¡Excelente! Capacidad visoespacial muy superior.';

  @override
  String get cubesPerfVeryGood =>
      '¡Muy bien! Buena capacidad de análisis visual.';

  @override
  String get cubesDiffExample => 'Ejemplo';

  @override
  String get cubesDiffVeryHard => 'Muy difícil';

  @override
  String get cubesDescExample =>
      'Ítem de ejemplo - No cuenta para la puntuación';

  @override
  String get cubesDesc2x2 => 'Patrón 2×2 simple';

  @override
  String get cubesDesc3x3Diagonals => 'Patrón 3×3 con diagonales';

  @override
  String get cubesDesc3x3Complex => 'Patrón 3×3 complejo - Alta cohesión';

  @override
  String cubesCohesion(int score) {
    return 'Cohesión: $score';
  }

  @override
  String cubesRemaining(String time) {
    return 'Quedan: $time';
  }

  @override
  String get cubesReproduceInstruction =>
      'Reproduce el patrón de abajo tocando los cubos';

  @override
  String get cubesPatternToReproduce => 'Patrón a reproducir:';

  @override
  String get cubesYourAnswer => 'Tu respuesta:';

  @override
  String get cubesReset => 'Reiniciar';

  @override
  String get fwTestName => 'Balanzas Cuantitativas';

  @override
  String get fwEyebrow => 'RAZONAMIENTO FLUIDO · IRF';

  @override
  String get fwCorrectAnswerPoint => '¡Respuesta correcta! +1 punto';

  @override
  String get fwWrongAnswer =>
      'Respuesta incorrecta. La respuesta correcta era:';

  @override
  String fwTime(int seconds) {
    return 'Tiempo: $seconds s';
  }

  @override
  String get fwDiscontinue3 =>
      '3 fallos consecutivos - Test finalizado (WAIS-IV)';

  @override
  String get fwSeeResults => 'Ver los resultados';

  @override
  String get fwResultsTitle => 'Test de Balanzas Cuantitativas - Resultados';

  @override
  String fwRawScorePoints(int score) {
    return 'Puntuación bruta: $score/27 puntos';
  }

  @override
  String fwItemsCompleted(int count) {
    return 'Ítems completados: $count/27';
  }

  @override
  String fwPercentage(int percent) {
    return 'Porcentaje: $percent%';
  }

  @override
  String fwTotalTime(int seconds) {
    return 'Tiempo total: $seconds s';
  }

  @override
  String get fwGLoading => 'carga en g: 0,78 (la más alta del WAIS-IV)';

  @override
  String get fwPerfExceptional => 'Rendimiento excepcional (θ > +2.0)';

  @override
  String get fwPerfSuperior => 'Rendimiento superior (θ > +1.0)';

  @override
  String get fwPerfAverage => 'Rendimiento medio (θ ≈ 0)';

  @override
  String get fwPerfInferior => 'Rendimiento por debajo de la media (θ < 0)';

  @override
  String get fwPerfLow => 'Rendimiento bajo (θ < -1.0)';

  @override
  String fwScoreFraction(int score, int total) {
    return '$score/$total';
  }

  @override
  String get fwInstruction =>
      'Encuentra el valor que falta para equilibrar la balanza.';

  @override
  String get fwWhatIs => '¿Cuánto vale ';

  @override
  String fwSeconds(int seconds) {
    return '$seconds s';
  }

  @override
  String get vpTestName => 'Puzles Visuales';

  @override
  String get vpEyebrow => 'VISOESPACIAL · IVE';

  @override
  String get vpCorrect => 'Correcto';

  @override
  String get vpIncorrect => 'Incorrecto';

  @override
  String get vpValidate => 'Validar';

  @override
  String vpSelectedCount(int count) {
    return '$count / 3 seleccionadas';
  }

  @override
  String get vpInstruction =>
      'Elige las 3 piezas que forman la figura (se permite girarlas, no voltearlas).';

  @override
  String vpSelectionSemantics(int filled, int total) {
    return 'Selección: $filled de $total piezas';
  }

  @override
  String get vpSelectionLabel => 'SELECCIÓN';

  @override
  String vpPieceSemantics(String label) {
    return 'Pieza $label';
  }

  @override
  String get vpTargetTitle => 'FIGURA A RECONSTRUIR';

  @override
  String get codingTestName => 'Clave de números (Dígitos y Símbolos)';

  @override
  String get codingEyebrow => 'VELOCIDAD DE PROCESAMIENTO · IVP';

  @override
  String get codingStartTraining => 'Empezar el entrenamiento';

  @override
  String get codingTitle => 'Prueba de Clave de Números';

  @override
  String get codingDescription =>
      'Esta prueba mide tu velocidad de procesamiento y tu coordinación visomotora.';

  @override
  String get codingReferenceKey => 'Clave de referencia:';

  @override
  String get codingTaskTitle => 'Tu tarea';

  @override
  String get codingTaskDesc =>
      'Para cada cifra mostrada, selecciona el símbolo correspondiente';

  @override
  String get codingTimeLimitTitle => 'Tiempo límite';

  @override
  String get codingTimeLimitDesc =>
      '120 segundos para completar el máximo de casillas (135 en total)';

  @override
  String get codingScoringTitle => 'Puntuación';

  @override
  String get codingScoringDesc =>
      '1 punto por cada casilla correcta, sin penalización por errores';

  @override
  String get codingTrainingDoneTitle => 'Entrenamiento terminado';

  @override
  String get codingTrainingDoneBody =>
      'Ya puedes empezar la prueba. Dispondrás de 120 segundos para completar el máximo de casillas posibles.';

  @override
  String get codingStartTest => 'Empezar la prueba';

  @override
  String get codingTestDoneTitle => '¡Prueba terminada!';

  @override
  String get codingTimeElapsed => 'Tiempo transcurrido: 120 segundos';

  @override
  String codingCellsCompleted(int count) {
    return 'Casillas completadas: $count/135';
  }

  @override
  String codingCellsCorrect(int count) {
    return 'Casillas correctas: $count';
  }

  @override
  String codingScorePoints(int count) {
    return 'Puntuación: $count puntos';
  }

  @override
  String get codingPerfExceptional => '¡Rendimiento excepcional!';

  @override
  String get codingPerfVeryGood => 'Muy buen rendimiento';

  @override
  String get codingPerfAboveAverage => 'Rendimiento por encima de la media';

  @override
  String get codingPerfAverage => 'Rendimiento medio';

  @override
  String get codingPerfBelowAverage => 'Rendimiento por debajo de la media';

  @override
  String get codingTrainingTab => 'Entrenamiento';

  @override
  String get codingReferenceShort => 'Referencia:';

  @override
  String codingCellProgress(int current, int total) {
    return 'Casilla $current/$total';
  }

  @override
  String codingCompletedProgress(int count, int total) {
    return 'Completadas: $count/$total';
  }

  @override
  String get codingSelectSymbol => 'Selecciona un símbolo:';

  @override
  String get codingClear => 'Borrar';

  @override
  String get codingFinishTraining => 'Terminar el entrenamiento';

  @override
  String get ssTestName => 'Búsqueda de Símbolos';

  @override
  String get ssDescription =>
      'Esta prueba mide tu velocidad de procesamiento visual y tu capacidad de discriminación.';

  @override
  String get ssExampleLabel => 'Ejemplo de ítem:';

  @override
  String get ssTargets => 'OBJETIVOS';

  @override
  String get ssGroup => 'GRUPO';

  @override
  String get ssExampleAnswer => '→ Respuesta: SÍ (┴ está presente)';

  @override
  String get ssTaskTitle => 'Tu tarea';

  @override
  String get ssTaskDesc =>
      'Comprueba si alguno de los símbolos objetivo aparece en el grupo';

  @override
  String get ssQuickAnswerTitle => 'Respuesta rápida';

  @override
  String get ssQuickAnswerDesc => 'Pulsa SÍ o NO lo más rápido posible';

  @override
  String get ssScoringPenaltyTitle => 'Puntuación con penalización';

  @override
  String get ssScoringPenaltyDesc =>
      'Puntuación = Respuestas correctas - Respuestas incorrectas';

  @override
  String get ssTimeLimitTitle => 'Tiempo límite';

  @override
  String get ssTimeLimitDesc => '120 segundos para 60 ítems';

  @override
  String get ssTrainingDoneBody =>
      '¡Ya estás listo! Dispondrás de 120 segundos para completar el máximo de ítems posibles.\n\nRecuerda: Puntuación = Respuestas correctas - Respuestas incorrectas';

  @override
  String ssItemsAnswered(int count) {
    return 'Ítems respondidos: $count/60';
  }

  @override
  String ssCorrectAnswers(int count) {
    return 'Respuestas correctas: $count';
  }

  @override
  String ssIncorrectAnswers(int count) {
    return 'Respuestas incorrectas: $count';
  }

  @override
  String ssNotAnswered(int count) {
    return 'Sin responder: $count';
  }

  @override
  String ssRawScore(int count) {
    return 'Puntuación bruta: $count';
  }

  @override
  String get ssScoreFormulaShort => '(Correctas - Incorrectas)';

  @override
  String get ssPerfGood => 'Buen rendimiento';

  @override
  String ssItemProgress(int current, int total) {
    return 'Ítem $current/$total';
  }

  @override
  String ssAnsweredProgress(int count) {
    return 'Respondidos: $count/60';
  }

  @override
  String get ssTargetSymbols => 'SÍMBOLOS OBJETIVO';

  @override
  String get ssSearchGroup => 'GRUPO DE BÚSQUEDA';

  @override
  String get ssNo => 'NO';

  @override
  String get ssYes => 'SÍ';

  @override
  String get dsTestName => 'Memoria de Dígitos';

  @override
  String get dsEyebrow => 'MEMORIA DE TRABAJO · IMT';

  @override
  String get dsDescription =>
      'Esta prueba mide tu memoria de trabajo a través de 3 partes distintas:';

  @override
  String get dsForwardTitle => 'Parte 1: Orden Directo';

  @override
  String get dsForwardInstruction => 'Repite los dígitos en el mismo orden';

  @override
  String get dsBackwardTitle => 'Parte 2: Orden Inverso';

  @override
  String get dsBackwardInstruction => 'Repite los dígitos en orden inverso';

  @override
  String get dsSequencingTitle => 'Parte 3: Secuenciación';

  @override
  String get dsSequencingInstruction => 'Repite los dígitos en orden creciente';

  @override
  String get dsPresentationInfo =>
      'Los dígitos se presentarán a un ritmo de 1 dígito por segundo.';

  @override
  String get dsTypeForward => 'Orden Directo';

  @override
  String get dsTypeBackward => 'Orden Inverso';

  @override
  String get dsTypeSequencing => 'Secuenciación';

  @override
  String get dsStartPart => 'Empezar';

  @override
  String dsLengthTrial(int length, int trial) {
    return 'Longitud $length - Intento $trial';
  }

  @override
  String get dsListenCarefully => 'Escucha con atención';

  @override
  String get dsCorrect => '¡Correcto!';

  @override
  String get dsIncorrect => 'Incorrecto';

  @override
  String dsPointsEarned(int count) {
    return 'Puntos obtenidos: $count';
  }

  @override
  String dsCorrectAnswer(String answer) {
    return 'Respuesta correcta: $answer';
  }

  @override
  String dsYourAnswer(String answer) {
    return 'Tu respuesta: $answer';
  }

  @override
  String get dsResultsByPart => 'Resultados por parte:';

  @override
  String dsForwardScore(int count) {
    return 'Orden Directo: $count puntos';
  }

  @override
  String dsBackwardScore(int count) {
    return 'Orden Inverso: $count puntos';
  }

  @override
  String dsSequencingScore(int count) {
    return 'Secuenciación: $count puntos';
  }

  @override
  String dsTotalScore(int count) {
    return 'Puntuación total: $count puntos';
  }

  @override
  String get dsEnterAnswer => 'Escribe tu respuesta...';

  @override
  String dsValidateProgress(int count, int total) {
    return 'Validar ($count/$total)';
  }

  @override
  String get psTestName => 'Memoria de Imágenes';

  @override
  String get psDescription =>
      'Esta prueba mide tu memoria de trabajo visual y tu atención selectiva.';

  @override
  String get psPhase1Title => 'Fase 1: Memorización';

  @override
  String get psPhase1Desc =>
      'Las imágenes se presentarán una por una (3 segundos cada una)';

  @override
  String get psPhase2Title => 'Fase 2: Recuerdo';

  @override
  String get psPhase2Desc =>
      'Selecciona las imágenes en el orden exacto en que se presentaron';

  @override
  String get psProgressionTitle => 'Progresión';

  @override
  String get psProgressionDesc =>
      'La dificultad aumenta: de 1 a 6 imágenes que memorizar';

  @override
  String get psTrialsInfo =>
      '12 intentos en total. La prueba se detiene tras 2 fallos en el mismo nivel.';

  @override
  String get psMemorizationTab => 'Memorización';

  @override
  String get psRecallTab => 'Recuerdo';

  @override
  String psLevelTrial(int level, int trial) {
    return 'Nivel $level - Intento $trial';
  }

  @override
  String get psMemorizeImages => 'Memoriza las imágenes';

  @override
  String psImageProgress(int current, int total) {
    return 'Imagen $current / $total';
  }

  @override
  String psSelectInOrder(int count) {
    return 'Selecciona las $count imágenes en orden';
  }

  @override
  String get psNoSelection => 'Sin selección';

  @override
  String get psClearLast => 'Borrar la última selección';

  @override
  String psCorrectOrder(String names) {
    return 'Orden correcto: $names';
  }

  @override
  String psYourOrder(String names) {
    return 'Tu orden: $names';
  }

  @override
  String psTrialsCompleted(int count) {
    return 'Intentos completados: $count/12';
  }

  @override
  String psScorePoints(int count) {
    return 'Puntuación total: $count puntos';
  }

  @override
  String psMaxLevel(int level) {
    return 'Nivel máximo alcanzado: Nivel $level';
  }

  @override
  String get psImgChat => 'Gato';

  @override
  String get psImgInsecte => 'Insecto';

  @override
  String get psImgLapin => 'Conejo';

  @override
  String get psImgOiseau => 'Pájaro';

  @override
  String get psImgPoisson => 'Pez';

  @override
  String get psImgTortue => 'Tortuga';

  @override
  String get psImgPapillon => 'Mariposa';

  @override
  String get psImgCoccinelle => 'Mariquita';

  @override
  String get psImgChaise => 'Silla';

  @override
  String get psImgLampe => 'Lámpara';

  @override
  String get psImgMontre => 'Reloj';

  @override
  String get psImgParapluie => 'Paraguas';

  @override
  String get psImgSac => 'Bolso';

  @override
  String get psImgLit => 'Cama';

  @override
  String get psImgPorte => 'Puerta';

  @override
  String get psImgFenetre => 'Ventana';

  @override
  String get psImgGateau => 'Pastel';

  @override
  String get psImgCafe => 'Café';

  @override
  String get psImgPizza => 'Pizza';

  @override
  String get psImgPomme => 'Manzana';

  @override
  String get psImgGlace => 'Helado';

  @override
  String get psImgBurger => 'Hamburguesa';

  @override
  String get psImgSandwich => 'Sándwich';

  @override
  String get psImgOeuf => 'Huevo';

  @override
  String get psImgMarteau => 'Martillo';

  @override
  String get psImgCle => 'Llave inglesa';

  @override
  String get psImgCiseaux => 'Tijeras';

  @override
  String get psImgPinceau => 'Pincel';

  @override
  String get psImgCrayon => 'Lápiz';

  @override
  String get psImgCouteau => 'Cuchillo';

  @override
  String get psImgTournevis => 'Destornillador';

  @override
  String get psImgEngrenage => 'Engranaje';

  @override
  String get psImgVoiture => 'Coche';

  @override
  String get psImgVelo => 'Bicicleta';

  @override
  String get psImgAvion => 'Avión';

  @override
  String get psImgTrain => 'Tren';

  @override
  String get psImgBateau => 'Barco';

  @override
  String get psImgBus => 'Autobús';

  @override
  String get psImgMoto => 'Motocicleta';

  @override
  String get psImgFusee => 'Cohete';

  @override
  String get ctShareScore => 'Compartir mi puntuación';

  @override
  String get ctSubtestExitBody =>
      'Has salido de esta subprueba antes de terminarla. ¿Quieres reanudarla o detener la evaluación?';

  @override
  String get ctSubtestExitResume => 'Reanudar la subprueba';

  @override
  String get ctSubtestExitTitle => 'Subprueba interrumpida';

  @override
  String get demoBadge => 'PRÁCTICA';

  @override
  String get demoContinue => 'Continuar';

  @override
  String get demoNotice => 'Práctica: este intento no cuenta.';

  @override
  String get demoRetry => 'Reintentar';

  @override
  String get demoStart => 'Comenzar la prueba';

  @override
  String get demoTryAgain => 'Casi… inténtalo de nuevo';

  @override
  String get demoWellDone => '¡Correcto!';

  @override
  String get histLockedBody =>
      'Tu resultado está guardado, pero permanecerá difuminado hasta que todas las misiones estén validadas.';

  @override
  String get histLockedBodyNoResult =>
      'Tus misiones y tu enlace de invitación están aquí. Termina tu evaluación para desbloquear tu resultado.';

  @override
  String get histLockedCta => 'Ver mis misiones';

  @override
  String get histLockedTitle => 'Misiones por validar';

  @override
  String get inviteLandingBody =>
      'Un amigo te invita a hacer el test de CI gratuito de Mentality. Al terminar tu test, obtienes tu propio resultado y ayudas a tu amigo a desbloquear el suyo.';

  @override
  String get inviteLandingCta => 'Empezar el test gratuito';

  @override
  String get inviteLandingTitle => 'Invitación';

  @override
  String get shareCancel => 'Cancelar';

  @override
  String get shareCodeLabel => 'Código de invitación';

  @override
  String get shareConfirm => 'Compartir esta imagen';

  @override
  String get shareError => 'No se pudo preparar la imagen. Inténtalo de nuevo.';

  @override
  String get shareEyebrow => 'Vista previa';

  @override
  String get shareIntro =>
      'Esta es la imagen que se compartirá. No se publica nada hasta que confirmes.';

  @override
  String get shareLinkCopied =>
      'Tu enlace está copiado: añádelo como sticker de Enlace en tu historia';

  @override
  String sharePercentile(int rank) {
    return 'Más alta que la del $rank % de los participantes';
  }

  @override
  String get shareScoreLabel => 'Puntuación global';

  @override
  String get shareTitle => 'Compartir mi puntuación';

  @override
  String get ugCopied => '¡Enlace copiado!';

  @override
  String get ugCopyLink => 'Copiar mi enlace de invitación';

  @override
  String get ugErrorBody =>
      'No se pudo obtener el estado de tu desbloqueo. Comprueba tu conexión e inténtalo de nuevo.';

  @override
  String get ugEyebrow => 'Últimos pasos';

  @override
  String get ugFreeNotice =>
      'El test es 100 % gratuito. Para recibir tu resultado quedan unos pasos sencillos: se validan automáticamente.';

  @override
  String ugFriendDone(int n) {
    return 'Amigo $n: test terminado';
  }

  @override
  String ugFriendPending(int n) {
    return 'Amigo $n: test en curso';
  }

  @override
  String ugInviteCounter(int joined, int required) {
    return '$joined/$required amigos han terminado su test';
  }

  @override
  String get ugRefresh => 'Actualizar';

  @override
  String get ugRefreshFailed =>
      'No se pudo actualizar. Comprueba tu conexión: las cifras mostradas son de la última actualización.';

  @override
  String get ugResultsHubNotice =>
      'Todo está en «Mis resultados»: tus misiones, tu enlace de invitación y tu resultado (difuminado hasta que valides todas las misiones). Puedes salir de esta página y volver cuando quieras.';

  @override
  String get ugRetry => 'Reintentar';

  @override
  String get ugStep1Body =>
      'Comparte tu enlace personal con 3 amigos. Este paso avanza cuando TERMINAN su test, no solo cuando se registran. No dudes en recordárselo.';

  @override
  String get ugStep1Title => 'Invita a 3 amigos';

  @override
  String get ugStep2Body =>
      'Tus amigos deben terminar ahora su test de CI. Esperamos sus resultados: ¡no dudes en recordárselo!';

  @override
  String get ugStep2Title => 'Tus amigos están haciendo su test';

  @override
  String get ugTitle => 'Tu resultado está listo';

  @override
  String ugWaitBody(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other:
          'Tu resultado se está preparando. Se publicará dentro de $days días, automáticamente: no tienes que hacer nada más.',
      one:
          'Tu resultado se está preparando. Se publicará dentro de $days día, automáticamente: no tienes que hacer nada más.',
      zero:
          'Tu resultado se está preparando. Se publicará automáticamente: no tienes que hacer nada más.',
    );
    return '$_temp0';
  }

  @override
  String get ugWaitConfirming =>
      'Tu resultado se desbloquea en cuanto el servidor lo confirme: esta pantalla se actualiza sola.';

  @override
  String ugWaitCountdownDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Quedan $days días',
      one: 'Queda $days día',
    );
    return '$_temp0';
  }

  @override
  String get ugWaitCountdownDone => 'El plazo ha terminado.';

  @override
  String ugWaitCountdownHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: 'Quedan $hours horas',
      one: 'Queda $hours hora',
    );
    return '$_temp0';
  }

  @override
  String ugWaitCountdownMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'Quedan $minutes minutos',
      one: 'Queda $minutes minuto',
    );
    return '$_temp0';
  }

  @override
  String get ugWaitTitle => 'Tus resultados están en camino';

  @override
  String get vpDemoEyebrow => 'DEMOSTRACIÓN';

  @override
  String get vpDemoInstruction =>
      'Práctica sin tiempo: elige las 3 piezas que forman la figura y confirma.';

  @override
  String get vpDemoRetry => 'Reintentar';

  @override
  String get vpDemoStart => 'Comenzar la prueba';

  @override
  String vpReadyBody(int count) {
    return 'La práctica ha terminado. Empieza la prueba: $count puzles, cada uno con su propio cronómetro. El tiempo empieza en cuanto pulses el botón.';
  }

  @override
  String get vpReadyStart => 'Empezar ahora';

  @override
  String get vpReadyTitle => '¿Preparado?';

  @override
  String get vpRecorded => 'Respuesta registrada';

  @override
  String get vocabTestName => 'Vocabulario';

  @override
  String get vocabEyebrow => 'COMPRENSIÓN VERBAL · ICV';

  @override
  String vocabTimerScore(int seconds, int score) {
    return '$seconds s · $score pts';
  }

  @override
  String get vocabFeedbackExcellent => '¡Excelente!';

  @override
  String get vocabFeedbackCorrect => 'Correcto';

  @override
  String get vocabFeedbackIncomplete => 'Respuesta incompleta';

  @override
  String get vocabFeedbackTwoPoints =>
      '¡Definición completa y precisa! +2 puntos';

  @override
  String get vocabFeedbackOnePoint =>
      'Definición parcial pero correcta. +1 punto';

  @override
  String get vocabFeedbackZeroPoint =>
      'Respuesta incorrecta o demasiado vaga. 0 puntos';

  @override
  String vocabWordLabel(String word) {
    return 'Palabra: «$word»';
  }

  @override
  String vocabYourAnswerLabel(String answer) {
    return 'Tu respuesta: «$answer»';
  }

  @override
  String get vocabEmptyAnswer => '(vacío)';

  @override
  String get vocabTwoPointExamples => 'Ejemplos de respuestas de 2 puntos:';

  @override
  String get vocabOnePointExamples => 'Ejemplos de respuestas de 1 punto:';

  @override
  String vocabTimeSeconds(int seconds) {
    return 'Tiempo: $seconds s';
  }

  @override
  String vocabTotalScore(int score) {
    return 'Puntuación total: $score puntos';
  }

  @override
  String get vocabDiscontinued =>
      '3 puntuaciones de 0 consecutivas: prueba finalizada (WAIS-IV)';

  @override
  String get vocabViewResults => 'Ver resultados';

  @override
  String get vocabResultsTitle => 'Prueba de Vocabulario — Resultados';

  @override
  String vocabRawScore(int score, int max) {
    return 'Puntuación directa: $score/$max puntos';
  }

  @override
  String vocabItemsCompleted(int completed, int total) {
    return 'Ítems completados: $completed/$total';
  }

  @override
  String vocabPercentage(int percent) {
    return 'Porcentaje: $percent%';
  }

  @override
  String vocabTotalTime(int seconds) {
    return 'Tiempo total: $seconds s';
  }

  @override
  String get vocabTestCaption =>
      'Prueba de conocimiento léxico y comprensión verbal';

  @override
  String get vocabFrequencyBreakdownTitle => 'Desglose por frecuencia:';

  @override
  String vocabFrequencyBreakdownRow(String name, int score, int max) {
    return '$name: $score/$max puntos';
  }

  @override
  String get vocabPerfExceptional => 'Rendimiento excepcional (θ > +2.0)';

  @override
  String get vocabPerfSuperior => 'Rendimiento superior (θ > +1.0)';

  @override
  String get vocabPerfAverage => 'Rendimiento medio (θ ≈ 0)';

  @override
  String get vocabPerfBelowAverage => 'Rendimiento inferior (θ < 0)';

  @override
  String get vocabPerfLow => 'Rendimiento bajo (θ < -1.0)';

  @override
  String get vocabFreqVeryHigh => 'Muy frecuente';

  @override
  String get vocabFreqHigh => 'Frecuente';

  @override
  String get vocabFreqMedium => 'Medio';

  @override
  String get vocabFreqLow => 'Poco frecuente';

  @override
  String get vocabFreqVeryLow => 'Muy poco frecuente';

  @override
  String get vocabInstruction => 'Define la siguiente palabra';

  @override
  String get vocabYourDefinitionLabel => 'Tu definición:';

  @override
  String get vocabDefinitionHint => 'Escribe la definición de la palabra...';

  @override
  String get vocabTipsTitle => 'Consejos para obtener 2 puntos:';

  @override
  String get vocabTipComplete => '• Da una definición completa y precisa';

  @override
  String get vocabTipSynonyms => '• Utiliza sinónimos exactos';

  @override
  String get vocabTipContext => '• Explica el significado con contexto';

  @override
  String get weGateCta => 'Ver el programa de hoy';

  @override
  String get weHubEyebrow => 'Durante la espera';

  @override
  String weHubTitle(int day) {
    return 'Día $day';
  }

  @override
  String get weHubTitleDone => 'Programa completado';

  @override
  String get weHubIntro =>
      'Cada día se revela una parte de tus resultados, junto con una actividad opcional. Nada de esto acelera el desbloqueo: solo el tiempo desbloquea.';

  @override
  String get weTodayTag => 'Hoy';

  @override
  String get wePastTag => 'Para recuperar';

  @override
  String weLockedTag(int day) {
    return 'Se abre el día $day';
  }

  @override
  String get wePlaceholderTitle => 'En preparación';

  @override
  String get wePlaceholderBody =>
      'El contenido de este día llegará en una próxima actualización.';

  @override
  String get weAnnouncedTag => 'Prueba del día — con tu resultado';

  @override
  String get weContributionTag =>
      'Contribución — ayúdanos a construir nuestra prueba';

  @override
  String get weShareTag => 'Recompensa final';

  @override
  String get weDay1Title => 'Tu personalidad';

  @override
  String get weDay2Title => 'Construye nuestra prueba de lectura';

  @override
  String get weDay3Title => 'Tu equilibrio';

  @override
  String get weDay4Title => 'Construye nuestra prueba de atención (1/2)';

  @override
  String get weDay5Title => 'Construye nuestra prueba de atención (2/2)';

  @override
  String get weDay6Title => 'Tu energía';

  @override
  String get weDay7Title => 'Perfil de autismo';

  @override
  String get weDay8Title => 'Tu CI global';

  @override
  String get weRevealVci => 'Tu Comprensión Verbal';

  @override
  String get weRevealPsi => 'Tu Velocidad de Procesamiento';

  @override
  String get weRevealWmi => 'Tu Memoria de Trabajo';

  @override
  String get weRevealFri => 'Tu razonamiento';

  @override
  String get weRevealVsi => 'Tu índice espacial';

  @override
  String get weRevealStrengths => 'Tus fortalezas y debilidades';

  @override
  String get weRevealFullIq => 'Tu CI global';

  @override
  String get weGameStroop => 'Juego: Stroop';

  @override
  String get weGameDelayChoice => 'Juego: tolerancia a la espera';

  @override
  String get weGameTimeEstimation => 'Juego: estimación del tiempo';

  @override
  String get weGameConfidence => 'Juego: calibración de la confianza';

  @override
  String get weRunnerNext => 'Siguiente';

  @override
  String get weRunnerFinish => 'Finalizar';

  @override
  String get weRunnerBack => 'Anterior';

  @override
  String get weRunnerScoredLabel => 'Test del día';

  @override
  String get weRunnerContributionLabel => 'Contribución';

  @override
  String get weRunnerResumed => 'Continúas donde lo dejaste.';

  @override
  String get weRunnerNoScoreNotice =>
      'Estas preguntas no calculan ninguna puntuación para ti: sirven para construir la herramienta para los siguientes.';

  @override
  String get weRunnerQuitTitle => '¿Salir del cuestionario?';

  @override
  String get weRunnerQuitBody =>
      'Tus respuestas están guardadas. Podrás continuar en la pregunta donde lo dejes.';

  @override
  String get weRunnerQuitStay => 'Continuar';

  @override
  String get weRunnerQuitLeave => 'Salir';

  @override
  String get weRunnerTransitionCta => 'Continuar';

  @override
  String get weRunnerDoneTitle => 'Has terminado';

  @override
  String get weRunnerDoneBody => 'Gracias: tus respuestas están guardadas.';

  @override
  String get weRunnerDoneContributionBody =>
      'Gracias: tus respuestas ayudarán a construir nuestro test. No se calcula ninguna puntuación para ti.';

  @override
  String get weRunnerDoneCta => 'Volver al programa';

  @override
  String get weRvEyebrow => 'Tu revelación del día';

  @override
  String get weRvContinue => 'Continuar';

  @override
  String get weRvBackToHub => 'Volver al programa';

  @override
  String get weRvScoreLabel => 'PUNTUACIÓN';

  @override
  String weRvCi(int low, int high) {
    return 'Intervalo de confianza del 95 % · $low – $high';
  }

  @override
  String get weRvCaveat =>
      'Un índice es una medida, con su margen de error, no un veredicto. Repetir la misma evaluación no daría exactamente el mismo número.';

  @override
  String get weRvUnavailableTitle => 'No hay evaluación que revelar';

  @override
  String get weRvUnavailableBody =>
      'No hay ninguna evaluación completada asociada a este pase en este dispositivo. No se pierde nada: la revelación aparecerá en cuanto tus resultados vuelvan a ser legibles aquí.';

  @override
  String get weRvMissingTitle => 'Este índice no se ha calculado';

  @override
  String get weRvMissingBody =>
      'Tu evaluación guardada no incluye este índice: faltaba una subprueba. Las demás revelaciones siguen disponibles.';

  @override
  String get weRvVciBody =>
      'Lo que sabes sobre las palabras y las ideas, y tu manera de relacionarlas: definir, explicar, encontrar lo que acerca dos nociones. Es la parte del perfil que menos cambia con los años.';

  @override
  String get weRvVsiBody =>
      'Tu manera de manipular las formas y el espacio: reconstruir un motivo, ver cómo encajan las piezas incluso antes de colocarlas.';

  @override
  String get weRvFriBody =>
      'Tu manera de encontrar una regla que nadie te ha dado, a partir de lo que observas. Es el razonamiento que no debe nada a lo aprendido.';

  @override
  String get weRvWmiBody =>
      'Lo que puedes mantener en la cabeza Y manipular al mismo tiempo: retener una serie mientras la reorganizas. Es el índice más sensible al cansancio y al estrés.';

  @override
  String get weRvPsiBody =>
      'La velocidad a la que procesas una información sencilla sin equivocarte. No es «pensar rápido»: es un caudal, y se paga en atención.';

  @override
  String get weRvStrengthsTitle => 'Tus fortalezas y tus puntos de vigilancia';

  @override
  String get weRvStrengthsIntro =>
      'Hoy los cinco índices se comparan entre sí. Una fortaleza no es un talento absoluto: es lo que supera tu propio nivel medio en más de 10 puntos.';

  @override
  String get weRvStrengthsNone =>
      'Ningún índice se aleja más de 10 puntos de tu nivel medio: tu perfil es regular, y eso ya es un resultado.';

  @override
  String get weRvFullIqLabel => 'CI global';

  @override
  String get weRvFullIqBody =>
      'El CI global resume los cinco índices en un solo número. Cuando se separan mucho entre sí, ese resumen pierde sentido: entonces es el detalle lo que te describe, no el total.';

  @override
  String get weRvEstimateTitle => 'TU ESTIMACIÓN FRENTE A LA MEDIDA';

  @override
  String weRvEstimateLine(int estimate, int measured) {
    return 'Te estimaste en $estimate. La medida da $measured.';
  }

  @override
  String weRvEstimateOver(int points) {
    return 'Es decir, $points puntos por encima de la medida.';
  }

  @override
  String weRvEstimateUnder(int points) {
    return 'Es decir, $points puntos por debajo de la medida.';
  }

  @override
  String get weRvEstimateClose =>
      'Menos de 5 puntos de diferencia: tu estimación y la medida dicen lo mismo.';

  @override
  String get weRvEstimateMissing =>
      'No diste ninguna estimación: no hay nada que comparar.';

  @override
  String get weRvSelfEyebrow => 'Antes de cualquier revelación';

  @override
  String get weRvSelfTitle => '¿En cuánto estimas tu CI?';

  @override
  String get weRvSelfBody =>
      'Una sola pregunta, hecha ahora: después de una primera revelación, tu respuesta estaría influida por la cifra que acabas de leer. 100 es la media. Tu respuesta se queda en tu teléfono y te será devuelta el día 8.';

  @override
  String get weRvSelfHint => 'Desliza, o toca − y +, para elegir.';

  @override
  String get weRvSelfAverage => '100 es la media.';

  @override
  String get weRvSelfConfirm => 'Confirmar mi estimación';

  @override
  String get weRvSelfDecline => 'Prefiero no responder';

  @override
  String get weRvSelfDecrease => 'Bajar un punto';

  @override
  String get weRvSelfIncrease => 'Subir un punto';

  @override
  String get weDcEyebrow => 'Juego';

  @override
  String get weDcTitle => 'Ahora o más tarde';

  @override
  String get weDcIntroTitle =>
      'Una cantidad ahora mismo, o una mayor más tarde';

  @override
  String get weDcIntroBody =>
      'Te vamos a proponer veinte veces el mismo tipo de elección: una cantidad disponible ahora mismo, o una cantidad mayor después de una espera. Solo tienes que tocar la que prefieras.';

  @override
  String get weDcIntroImaginary =>
      'Estas cantidades son imaginarias. No hay nada que ganar, nada que pagar y nada que recibir: son preguntas, no ofertas.';

  @override
  String get weDcIntroNoRightAnswer =>
      'No hay respuesta correcta. Coger el dinero ahora mismo no es ni mejor ni peor que esperar.';

  @override
  String get weDcStart => 'Empezar';

  @override
  String get weDcLater => 'Más tarde';

  @override
  String get weDcProgressTag => 'Elección';

  @override
  String get weDcPrompt => '¿Qué prefieres?';

  @override
  String get weDcImaginaryTag =>
      'Cantidades imaginarias: no hay nada que ganar.';

  @override
  String get weDcResultTitle => 'Tu paciencia';

  @override
  String weDcPatienceScore(int score) {
    return '$score / 100';
  }

  @override
  String get weDcResultCaption =>
      'Cuanto más alta es la cifra, más dispuesto estás a esperar. No es una nota: los dos extremos de la escala valen lo mismo.';

  @override
  String weDcIndifference(String delayed, String immediate) {
    return 'Esperar un mes por $delayed equivale, para ti, a recibir $immediate ahora mismo.';
  }

  @override
  String get weDcCurveTitle => 'Lo que valía la espera';

  @override
  String weDcPrevious(int score) {
    return 'La última vez: $score / 100';
  }

  @override
  String get weDcNoBetterEnd =>
      'Esta cifra no dice si has jugado bien. Preferir el dinero ahora mismo es un equilibrio, no un error, y cambia según el momento, el ánimo y la situación de cada uno.';

  @override
  String get weDcNotClinical =>
      'Es un juego, no una medida clínica: ningún umbral, ninguna clasificación, nada que concluir sobre ti.';

  @override
  String get weDcIncoherentTitle =>
      'Respuestas demasiado dispersas para sacar algo en claro';

  @override
  String get weDcIncoherentBody =>
      'Tus respuestas van en sentidos opuestos de un plazo a otro: una misma cantidad acaba valiendo más lejos que cerca. No se ha guardado nada. Vuelve a jugar cuando quieras.';

  @override
  String get weDcReplay => 'Volver a jugar';

  @override
  String get weDcDone => 'Terminar';

  @override
  String get weCsEyebrow => 'Antes de continuar';

  @override
  String get weCsTitle => '¿Enviar tus respuestas?';

  @override
  String get weCsIntro =>
      'Las preguntas que siguen tratan de tu salud mental y tu neurodesarrollo. La ley protege estas respuestas de forma especial: solo pueden salir de tu teléfono si lo aceptas aquí, de forma explícita.';

  @override
  String get weCsWhatTitle => 'Lo que se envía';

  @override
  String get weCsWhat =>
      'Tus respuestas, tal como las has dado. Sin tu nombre, sin tu número, sin fecha ni hora precisas. Nunca tus puntuaciones: se calculan en tu teléfono y ahí se quedan.';

  @override
  String get weCsPurposeTitle => 'Para qué sirven';

  @override
  String get weCsPurpose =>
      'Para construir y mejorar nuestras propias pruebas de detección, y para comparar lo que la gente declara con lo que mide la batería. Estas herramientas forman parte de lo que vendemos — lo justo es decirlo.';

  @override
  String get weCsWhoTitle => 'Adónde van';

  @override
  String get weCsWho =>
      'A nuestros servidores, en Europa. Archivadas bajo tu pase anónimo, nunca bajo tu nombre ni tu número.';

  @override
  String get weCsRightsTitle => 'Sigues teniendo el control';

  @override
  String get weCsRights =>
      'Puedes retirar tu acuerdo cuando quieras: los envíos siguientes se detienen de inmediato. También puedes pedir acceder a tus datos o que se borren.';

  @override
  String get weCsOptional =>
      'Es opcional y no cambia nada más: ni tu desbloqueo, ni tus resultados, ni las pruebas del programa dependen de esta respuesta.';

  @override
  String get weCsAccept => 'Acepto que se envíen mis respuestas';

  @override
  String get weCsDecline => 'No, guardar mis respuestas aquí';

  @override
  String get weDxCardTitle => 'Tu historial';

  @override
  String get weDxCardSubtitle =>
      'Unas preguntas, hechas una sola vez · opcional';

  @override
  String get weDxDeclinedTitle => 'No se enviará nada';

  @override
  String get weDxDeclinedBody =>
      'Estas preguntas solo sirven para nuestro trabajo: sin tu acuerdo, no te las hacemos. Puedes volver cuando quieras — no cambia nada del resto del programa.';

  @override
  String get weDxEyebrow => 'Se pregunta una sola vez';

  @override
  String get weDxListTitle => 'Tu historial';

  @override
  String get weDxListQuestion =>
      '¿Has recibido un diagnóstico — o crees que te afecta — de alguno de estos trastornos?';

  @override
  String get weDxListBody =>
      'Estas respuestas no cambian nada de tus resultados. Sirven para construir nuestras herramientas: sin saber a quién afecta, es imposible detectar qué preguntas distinguen algo de verdad.';

  @override
  String get weDxListHint => 'Marca todo lo que se aplique.';

  @override
  String get weDxAdhd => 'TDAH';

  @override
  String get weDxAutism => 'Autismo / TEA';

  @override
  String get weDxDyslexia => 'Dislexia';

  @override
  String get weDxDyspraxia => 'Dispraxia';

  @override
  String get weDxDyscalculia => 'Discalculia';

  @override
  String get weDxHpi => 'Altas capacidades';

  @override
  String get weDxDepression => 'Depresión';

  @override
  String get weDxAnxiety => 'Trastorno de ansiedad';

  @override
  String get weDxBipolar => 'Trastorno bipolar';

  @override
  String get weDxOcd => 'TOC';

  @override
  String get weDxSleep => 'Trastorno del sueño';

  @override
  String get weDxBurnout => 'Burnout';

  @override
  String get weDxOther => 'Otro trastorno';

  @override
  String get weDxNone => 'Ninguno';

  @override
  String get weDxPreferNotToSay => 'Prefiero no responder';

  @override
  String get weDxDetailTitle => 'El detalle';

  @override
  String weDxDetailProgress(int current, int total) {
    return '$current de $total';
  }

  @override
  String get weDxSourceQuestion => '¿De dónde viene el diagnóstico?';

  @override
  String get weDxSourcePsychiatrist => 'De psiquiatría o neuropsicología';

  @override
  String get weDxSourceGp => 'De medicina general';

  @override
  String get weDxSourcePsychologist => 'De psicología';

  @override
  String get weDxSourceSelf => 'De ningún sitio — lo creo, sin diagnóstico';

  @override
  String get weDxWhenQuestion => '¿Hace cuánto tiempo fue?';

  @override
  String get weDxWhenUnder1 => 'Menos de un año';

  @override
  String get weDxWhen1to3 => 'Entre 1 y 3 años';

  @override
  String get weDxWhen3to10 => 'Entre 3 y 10 años';

  @override
  String get weDxWhenOver10 => 'Más de 10 años';

  @override
  String get weDxWhenUnknown => 'Ya no me acuerdo';

  @override
  String get weDxTreatmentQuestion => '¿Tratamiento o seguimiento?';

  @override
  String get weDxTreatmentYes => 'Sí, actualmente';

  @override
  String get weDxTreatmentNo => 'No';

  @override
  String get weDxTreatmentPast => 'En el pasado';

  @override
  String get weDxAssessmentQuestion => '¿Se hizo una evaluación completa?';

  @override
  String get weDxAssessmentYes => 'Sí';

  @override
  String get weDxAssessmentNo => 'No';

  @override
  String get weDxAssessmentUnknown => 'No lo sé';

  @override
  String get weDxDoneTitle => 'Anotado';

  @override
  String get weDxDoneBody =>
      'Gracias. Esta pregunta no se te volverá a hacer — solo se hace una vez. No cambia nada de tus resultados ni de tu desbloqueo.';

  @override
  String get weDxAlreadyTitle => 'Ya respondido';

  @override
  String get weDxAlreadyBody =>
      'Ya has rellenado esta parte. Solo se pregunta una vez, para que tu respuesta no se vea influida por las pruebas de los días siguientes.';

  @override
  String get weDxFailedTitle => 'No se ha podido guardar nada';

  @override
  String get weDxFailedBody =>
      'Tus respuestas no se han guardado y no se ha enviado nada. Puedes intentarlo de nuevo desde el programa — la pregunta sigue abierta.';

  @override
  String get weDxQuitTitle => '¿Salir ahora?';

  @override
  String get weDxQuitBody =>
      'Lo que has marcado no se guardará: este bloque se registra de una sola vez, al final. Podrás retomarlo desde el programa.';

  @override
  String get weGameCardSubtitle => 'Juego del día · 2 minutos · repetible';

  @override
  String get weStroopEyebrow => 'Juego';

  @override
  String get weStroopTitle => 'Colores en conflicto';

  @override
  String get weStroopIntroTitle => 'Nombra el color, no la palabra';

  @override
  String get weStroopIntroBody =>
      'Aparecerá una palabra en un color determinado. Pulsa el color de la TINTA, no lo que pone. Leer es automático: justamente eso es lo que tendrás que dejar de lado.';

  @override
  String get weStroopIntroPractice =>
      'Empezamos con tres intentos que no cuentan, para coger el ritmo.';

  @override
  String get weStroopIntroExample =>
      'Aquí la palabra dice un color y la tinta dice otro: lo que cuenta es la tinta.';

  @override
  String get weStroopStart => 'Empezar';

  @override
  String get weStroopLater => 'Más tarde';

  @override
  String get weStroopPracticeTag => 'Práctica';

  @override
  String get weStroopScoredTag => 'Cuenta';

  @override
  String get weStroopPrompt => '¿De qué color está escrito?';

  @override
  String get weStroopBlockScoredTitle => 'Allá vamos';

  @override
  String get weStroopBlockScoredBody =>
      'A partir de ahora los intentos cuentan. Ve rápido, pero acierta: un error no te aporta nada.';

  @override
  String get weStroopBlockConflictTitle => 'Ahora las palabras te contradicen';

  @override
  String get weStroopBlockConflictBody =>
      'La consigna no cambia: sigue siendo el color de la tinta. Las palabras simplemente dirán otra cosa.';

  @override
  String get weStroopBlockCta => 'Continuar';

  @override
  String get weStroopResultTitle => 'Tu diferencia';

  @override
  String weStroopMilliseconds(int ms) {
    return '$ms ms';
  }

  @override
  String get weStroopResultCaption =>
      'Es el tiempo de más que necesitaste, en cada intento, cuando la palabra decía lo contrario que la tinta.';

  @override
  String weStroopAccuracy(int correct, int total) {
    return '$correct aciertos de $total';
  }

  @override
  String weStroopBest(int ms) {
    return 'Tu mejor diferencia: $ms ms';
  }

  @override
  String get weStroopNewBest => 'Nueva mejor diferencia';

  @override
  String get weStroopNotSpeed =>
      'Esta cifra no es tu velocidad. Es la diferencia entre dos series: alguien más lento en general puede tener perfectamente una diferencia más pequeña.';

  @override
  String get weStroopNotClinical =>
      'Es un juego, no una medida clínica: ningún umbral, ninguna clasificación, nada que concluir sobre ti.';

  @override
  String get weStroopUnreliableTitle => 'Muy pocas respuestas para contar';

  @override
  String get weStroopUnreliableBody =>
      'No hay suficientes respuestas correctas y dadas a tiempo para calcular una diferencia honesta. Tu mejor diferencia anterior queda intacta. Vuelve a jugar cuando quieras.';

  @override
  String get weStroopReplay => 'Volver a jugar';

  @override
  String get weStroopDone => 'Terminar';

  @override
  String get weTeEyebrow => 'Juego';

  @override
  String get weTeTitle => 'El más largo de los dos';

  @override
  String get weTeIntroTitle => 'Dos paneles, uno después del otro';

  @override
  String get weTeIntroBody =>
      'Un panel se va a encender, se apagará y se encenderá una segunda vez. Di cuál de los dos ha estado encendido más tiempo. Las diferencias se estrechan a lo largo de la partida.';

  @override
  String get weTeIntroTooShortToCount =>
      'Las duraciones son del orden de un segundo: demasiado cortas para contarlas. Responde solo tu percepción.';

  @override
  String get weTeIntroExample =>
      'Este es el panel que se encenderá. Nada más se moverá en la pantalla.';

  @override
  String get weTeStart => 'Empezar';

  @override
  String get weTeLater => 'Más tarde';

  @override
  String get weTeProgressTag => 'Intento';

  @override
  String get weTeWatch => 'Fíjate bien…';

  @override
  String get weTePrompt => '¿Cuál ha estado encendido más tiempo?';

  @override
  String get weTeFirst => 'El primero';

  @override
  String get weTeSecond => 'El segundo';

  @override
  String get weTeResultTitle => 'Tu finura';

  @override
  String weTeThreshold(int percent) {
    return '$percent %';
  }

  @override
  String get weTeResultCaption =>
      'Es la diferencia más pequeña que aún distingues entre dos duraciones. Cuanto menor es la cifra, más finamente separa tu percepción dos instantes cercanos.';

  @override
  String weTeAccuracyNote(int percent) {
    return '$percent % de aciertos: es lo normal, el juego estrecha las diferencias hasta hacerte dudar.';
  }

  @override
  String weTeBest(int percent) {
    return 'Tu mejor finura: $percent %';
  }

  @override
  String get weTeNewBest => 'Nueva mejor finura';

  @override
  String get weTeNotSpeed =>
      'Esta cifra no es tu velocidad: nada ha cronometrado tus respuestas, podías tomarte todo el tiempo que quisieras para decidir.';

  @override
  String get weTeNotClinical =>
      'Es un juego, no una medida clínica: ningún umbral, ninguna clasificación, nada que concluir sobre ti.';

  @override
  String get weTeUnreliableTitle => 'No hay con qué medir una finura';

  @override
  String get weTeUnreliableBody =>
      'La partida no ha dudado lo suficiente para que un umbral signifique algo. Tu mejor finura anterior sigue intacta. Vuelve a jugar cuando quieras.';

  @override
  String get weTeReplay => 'Volver a jugar';

  @override
  String get weTeDone => 'Terminar';
}
