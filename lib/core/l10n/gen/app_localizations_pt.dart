// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Mental E.T.';

  @override
  String get languageSwitcherTooltip => 'Mudar de idioma';

  @override
  String get commonValidate => 'Confirmar';

  @override
  String get commonNext => 'Seguinte';

  @override
  String get commonBack => 'Voltar';

  @override
  String get commonContinue => 'Continuar';

  @override
  String get commonStart => 'Começar';

  @override
  String get commonSkip => 'Ignorar';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonClose => 'Fechar';

  @override
  String get commonRetry => 'Tentar novamente';

  @override
  String get commonLoading => 'A carregar...';

  @override
  String get commonError => 'Ocorreu um erro';

  @override
  String get commonYes => 'Sim';

  @override
  String get commonNo => 'Não';

  @override
  String get commonOk => 'OK';

  @override
  String get commonFinish => 'Terminar';

  @override
  String commonSeconds(int count) {
    return '$count s';
  }

  @override
  String get oralConsentRequiredCheckbox =>
      'Autorizo a gravação da minha voz e a sua análise durante a realização deste teste. (obrigatório)';

  @override
  String get oralConsentCommercialCheckbox =>
      'Autorizo também a reutilização das minhas gravações, de forma anonimizada, para fins de investigação e comerciais — incluindo a sua cedência a terceiros. (facultativo)';

  @override
  String get oralConsentRequiredHint =>
      'Assinale a primeira caixa para poder começar o teste.';

  @override
  String get oralConsentPrivacyLink => 'Ler a política de privacidade';

  @override
  String get matDiscontinue3 =>
      '3 falhas consecutivas - Teste terminado (WAIS-IV)';

  @override
  String get assessIntroTitle => 'Nova avaliação';

  @override
  String get assessIntroEyebrow => 'AVALIAÇÃO COGNITIVA';

  @override
  String get assessIntroHero1 => 'Cinco índices,';

  @override
  String get assessIntroHero2 => 'uma medida.';

  @override
  String get assessIntroDescription =>
      'Esta avaliação mede as suas capacidades cognitivas em seis domínios da WAIS-IV. Um resultado global (FSIQ) constitui a sua síntese.';

  @override
  String get assessDomainsHeader => 'DOMÍNIOS AVALIADOS';

  @override
  String get assessDomainVci => 'Compreensão Verbal';

  @override
  String get assessDomainVsi => 'Raciocínio Visuo-Espacial';

  @override
  String get assessDomainFri => 'Raciocínio Fluido';

  @override
  String get assessDomainWmi => 'Memória de Trabalho';

  @override
  String get assessDomainPsi => 'Velocidade de Processamento';

  @override
  String get assessDomainLo => 'Linguagem Oral';

  @override
  String get assessBeforeStartHeader => 'ANTES DE COMEÇAR';

  @override
  String get assessBeforeStartBody =>
      'Duração estimada de 60 a 90 minutos. Exige-se tranquilidade e concentração.';

  @override
  String get assessLaunchFullAssessment => 'Iniciar a avaliação completa';

  @override
  String get assessOrIndividualSubtest => 'OU SUBTESTE INDIVIDUAL';

  @override
  String get assessSubtestCubes => 'Cubos (Block Design)';

  @override
  String get assessSubtestMatrices => 'Matrizes Progressivas';

  @override
  String get assessSubtestFigureWeights => 'Balanças Quantitativas';

  @override
  String get assessSubtestVisualPuzzles => 'Puzzles Visuais';

  @override
  String get assessSubtestSimilarities => 'Semelhanças';

  @override
  String get assessSubtestVocabulary => 'Vocabulário';

  @override
  String get assessSubtestInformation => 'Informação';

  @override
  String get assessSubtestDigitSpan => 'Memória de Dígitos';

  @override
  String get assessSubtestArithmetic => 'Aritmética';

  @override
  String get assessSubtestPictureSpan => 'Memória de Imagens';

  @override
  String get assessSubtestCoding => 'Código';

  @override
  String get assessSubtestSymbolSearch => 'Pesquisa de Símbolos';

  @override
  String get assessSubtestOralComprehension => 'Compreensão Oral';

  @override
  String get authLoginTitle => 'Iniciar sessão';

  @override
  String get authCreateAccount => 'Criar conta';

  @override
  String get authSignIn => 'Iniciar sessão';

  @override
  String get authHeaderSubtitleRegister =>
      'Crie uma conta para guardar os seus resultados';

  @override
  String get authHeaderSubtitleLogin =>
      'Inicie sessão para aceder ao seu histórico';

  @override
  String get authEmailLabel => 'Endereço de e-mail';

  @override
  String get authPasswordLabel => 'Palavra-passe';

  @override
  String get authFieldRequired => 'Campo obrigatório';

  @override
  String get authEmailInvalid => 'Endereço de e-mail inválido';

  @override
  String get authPasswordMinLength => 'Mínimo de 8 caracteres';

  @override
  String get authOrDivider => 'ou';

  @override
  String get authContinueWithGoogle => 'Continuar com a Google';

  @override
  String get authToggleToLogin => 'Já tem conta? Iniciar sessão';

  @override
  String get authToggleToRegister => 'Ainda não tem conta? Registar-se';

  @override
  String get authFirebaseNotConfiguredFull =>
      'O Firebase ainda não está configurado. Siga as instruções em firebase_config.dart.';

  @override
  String get authFirebaseNotConfigured =>
      'O Firebase ainda não está configurado.';

  @override
  String get histTitle => 'Os meus resultados';

  @override
  String get histEyebrow => 'HISTÓRICO';

  @override
  String get histDeleteResultTitle => 'Eliminar este resultado?';

  @override
  String get histDeleteResultBody => 'Esta ação é irreversível.';

  @override
  String get histDelete => 'Eliminar';

  @override
  String histAgeYears(int age) {
    return '$age anos';
  }

  @override
  String get histScoreFsiq => 'QI Total (FSIQ)';

  @override
  String get histScoreVci => 'VCI — Verbal';

  @override
  String get histScoreVsi => 'VSI — Visuo-Espacial';

  @override
  String get histScoreFri => 'FRI — Raciocínio';

  @override
  String get histScoreWmi => 'WMI — Memória';

  @override
  String get histScorePsi => 'PSI — Velocidade';

  @override
  String get histEmptyEyebrow => 'SEM RESULTADOS';

  @override
  String get histEmptyHero1 => 'O seu histórico';

  @override
  String get histEmptyHero2 => 'aguarda-o.';

  @override
  String get histEmptyDescription =>
      'Conclua a sua primeira avaliação WAIS-IV para ver os seus resultados aparecerem aqui.';

  @override
  String get histStartAssessment => 'Começar uma avaliação';

  @override
  String get ctIntroTitle => 'Teste completo';

  @override
  String get ctIntroHero1 => 'Doze subtestes,';

  @override
  String get ctIntroHero2 => 'quatro índices.';

  @override
  String get ctIntroDescription =>
      'Avaliação cognitiva completa e padronizada. Os subtestes encadeiam-se automaticamente.';

  @override
  String get ctIntroDurationEyebrow => 'DURAÇÃO';

  @override
  String get ctIntroDurationTitle => '60 a 90 minutos';

  @override
  String get ctIntroDurationBody => 'Reserve um período de tempo contínuo.';

  @override
  String get ctIntroContentEyebrow => 'CONTEÚDO';

  @override
  String get ctIntroContentTitle => '12 subtestes incluídos';

  @override
  String get ctIntroContentBody =>
      'Cubos · Semelhanças · Memória · Matrizes · Vocabulário · Aritmética · Símbolos · Puzzles · Informação · Código · Imagens · Balanças.';

  @override
  String get ctIntroImportantEyebrow => 'IMPORTANTE';

  @override
  String get ctIntroImportantTitle => 'Encadeamento automático';

  @override
  String get ctIntroImportantBody =>
      'Os testes serão iniciados um a seguir ao outro. Certifique-se de que dispõe de tempo suficiente.';

  @override
  String get ctPatientAgeHeader => 'IDADE DO PACIENTE';

  @override
  String get ctPatientAgeHint => 'Necessária para as normas (16 a 90 anos)';

  @override
  String get ctAgeSuffix => 'ANOS';

  @override
  String get ctAgeRangeError => 'Idade entre 16 e 90 anos';

  @override
  String get ctLaunchFullTest => 'Iniciar o teste completo';

  @override
  String get ctRunningTitle => 'Teste em curso';

  @override
  String get ctGlobalProgress => 'PROGRESSO GLOBAL';

  @override
  String get ctNextSubtest => 'PRÓXIMO SUBTESTE';

  @override
  String get ctLaunching => 'A iniciar…';

  @override
  String get ctComputingResultsTitle => 'Cálculo dos resultados';

  @override
  String get ctComputingResultsEyebrow => 'AVALIAÇÃO';

  @override
  String get ctProcessing => 'A PROCESSAR';

  @override
  String ctTestNotFound(String testName) {
    return 'Teste não encontrado: $testName';
  }

  @override
  String get ctTestCubes => 'Cubos';

  @override
  String get ctTestSimilarities => 'Semelhanças';

  @override
  String get ctTestDigitSpan => 'Memória de Dígitos';

  @override
  String get ctTestMatrices => 'Matrizes';

  @override
  String get ctTestVocabulary => 'Vocabulário';

  @override
  String get ctTestArithmetic => 'Aritmética';

  @override
  String get ctTestSymbolSearch => 'Pesquisa de Símbolos';

  @override
  String get ctTestVisualPuzzles => 'Puzzles Visuais';

  @override
  String get ctTestInformation => 'Informação';

  @override
  String get ctTestCoding => 'Código';

  @override
  String get ctTestPictureSpan => 'Memória de Imagens';

  @override
  String get ctTestFigureWeights => 'Balanças';

  @override
  String get ctResultsTitle => 'Resultados';

  @override
  String get ctResultsEyebrow => 'AVALIAÇÃO WAIS-IV';

  @override
  String get ctResultsHero1 => 'Avaliação';

  @override
  String get ctResultsHero2 => 'concluída.';

  @override
  String get ctResultsSummary =>
      'Síntese do seu desempenho cognitivo nos doze subtestes da WAIS-IV.';

  @override
  String ctAgeYears(int age) {
    return '$age anos';
  }

  @override
  String get ctMetaDate => 'DATA';

  @override
  String get ctMetaDuration => 'DURAÇÃO';

  @override
  String get ctMetaSubtests => 'SUBTESTES';

  @override
  String get ctMetaAge => 'IDADE';

  @override
  String get ctFsiqCardLabel => 'QI TOTAL · FSIQ';

  @override
  String ctConfidenceInterval95(int lower, int upper) {
    return 'IC 95% · $lower – $upper';
  }

  @override
  String ctPercentileLabel(int rank) {
    return 'Percentil · $rank.º';
  }

  @override
  String get ctIndexProfileHeader => 'PERFIL DOS ÍNDICES';

  @override
  String get ctIndexVci => 'Compreensão Verbal';

  @override
  String get ctIndexVsi => 'Visuo-Espacial';

  @override
  String get ctIndexFri => 'Raciocínio Fluido';

  @override
  String get ctIndexWmi => 'Memória de Trabalho';

  @override
  String get ctIndexPsi => 'Velocidade de Processamento';

  @override
  String ctIndexCiPercentile(int lower, int upper, int rank) {
    return 'IC $lower–$upper · $rank.º %il';
  }

  @override
  String ctIndexPercentile(int rank) {
    return '$rank.º %il';
  }

  @override
  String get ctStandardizedScoresHeader => 'NOTAS PADRONIZADAS';

  @override
  String get ctGroupVciVerbal => 'VCI · Verbal';

  @override
  String get ctGroupVsiVisuoSpatial => 'VSI · Visuo-Espacial';

  @override
  String get ctGroupFriReasoning => 'FRI · Raciocínio';

  @override
  String get ctGroupWmiMemory => 'WMI · Memória';

  @override
  String get ctGroupPsiSpeed => 'PSI · Velocidade';

  @override
  String ctRawScore(int raw) {
    return 'bruto $raw';
  }

  @override
  String get ctCognitiveProfileHeader => 'PERFIL COGNITIVO';

  @override
  String get ctProfileHomogeneous =>
      'Perfil homogéneo — os índices são coerentes entre si.';

  @override
  String get ctProfileHeterogeneous =>
      'Perfil heterogéneo — disparidades notórias entre os índices.';

  @override
  String ctMaxDiscrepancy(int points) {
    return 'Diferença máx. · $points pts';
  }

  @override
  String get ctRelativeStrengths => 'Pontos fortes relativos';

  @override
  String get ctVigilancePoints => 'Pontos de atenção';

  @override
  String get ctIndicativeDisclaimer =>
      'Resultados indicativos. Para uma avaliação clínica oficial, consulte um neuropsicólogo ou um psicólogo qualificado.';

  @override
  String get ctRawScoresHeader => 'RESULTADOS BRUTOS';

  @override
  String get ctMissingAgeHeader => 'IDADE EM FALTA';

  @override
  String get ctMissingAgeBody =>
      'Sem a idade do paciente, apenas são apresentados os resultados brutos. Repita o teste indicando a idade para obter o QI padronizado, os percentis e os intervalos de confiança.';

  @override
  String get ctExportPdf => 'Exportar para PDF';

  @override
  String ctPdfError(String error) {
    return 'Erro de PDF: $error';
  }

  @override
  String get ctBackToHome => 'Voltar ao início';

  @override
  String get ctPdfSubtitle => 'Relatório de avaliação cognitiva WAIS-IV';

  @override
  String get ctPdfNotProvided => 'Não indicado';

  @override
  String ctPdfDurationMinSec(int min, int sec) {
    return '$min min $sec seg';
  }

  @override
  String get ctPdfAge => 'Idade';

  @override
  String get ctPdfDuration => 'Duração';

  @override
  String get ctPdfDate => 'Data';

  @override
  String get ctPdfFsiqLabel => 'RESULTADO DE QI GLOBAL (FSIQ)';

  @override
  String get ctPdfConfidenceInterval95 => 'Intervalo de confiança a 95%';

  @override
  String get ctPdfPercentile => 'Percentil';

  @override
  String ctPercentileValue(int rank) {
    return '$rank.º';
  }

  @override
  String get ctPdfIndexProfileHeader => 'PERFIL DOS ÍNDICES COGNITIVOS';

  @override
  String get ctPdfIndexVci => 'VCI — Compreensão Verbal';

  @override
  String get ctPdfIndexVsi => 'VSI — Visuo-Espacial';

  @override
  String get ctPdfIndexFri => 'FRI — Raciocínio Fluido';

  @override
  String get ctPdfIndexWmi => 'WMI — Memória de Trabalho';

  @override
  String get ctPdfIndexPsi => 'PSI — Velocidade de Processamento';

  @override
  String get ctPdfColIndex => 'Índice';

  @override
  String get ctPdfColScore => 'Resultado';

  @override
  String get ctPdfColClassification => 'Classificação';

  @override
  String get ctPdfRawScoresHeader => 'RESULTADOS BRUTOS DOS SUBTESTES';

  @override
  String get ctPdfColSubtest => 'Subteste';

  @override
  String get ctPdfColRawScore => 'Resultado bruto';

  @override
  String get ctPdfDisclaimer =>
      'AVISO: Este relatório é gerado por uma aplicação de apoio à avaliação e não constitui um diagnóstico clínico oficial. Deve ser interpretado por um profissional de saúde qualificado. Não utilizar para fins médicos ou legais sem avaliação profissional complementar.';

  @override
  String get chatEyebrow => 'ASSISTENTE IA';

  @override
  String get chatNewConversation => 'Nova conversa';

  @override
  String get chatAssistantLabel => 'MENTAL E.T.';

  @override
  String get chatUserLabel => 'VOCÊ';

  @override
  String get chatHeroTitle1 => 'Coloque';

  @override
  String get chatHeroTitle2 => 'as suas questões.';

  @override
  String get chatEmptyIntro =>
      'A IA Mental E.T. ajuda-o a compreender melhor o seu perfil cognitivo. Conversas confidenciais, acompanhamento não diretivo.';

  @override
  String get chatThinking => 'A pensar…';

  @override
  String get chatInputHint => 'Escrever uma mensagem…';

  @override
  String get chatTimeJustNow => 'agora mesmo';

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
      'Lamentamos, ocorreu um erro. Tente novamente.';

  @override
  String get chatErrorEmptyResponse => 'Resposta vazia do worker';

  @override
  String get chatErrorAccessDenied =>
      'Acesso recusado pelo worker (origem não autorizada).';

  @override
  String get chatErrorRateLimit =>
      'Limite de pedidos atingido. Tente novamente dentro de instantes.';

  @override
  String chatErrorServer(int code) {
    return 'Erro do servidor ($code)';
  }

  @override
  String chatErrorHttp(int code, String body) {
    return 'Erro $code: $body';
  }

  @override
  String get coreSplashTitleLine1 => 'Avaliação';

  @override
  String get coreSplashTitleLine2 => 'cognitiva';

  @override
  String get commonNotAvailable => 'N/D';

  @override
  String get pdfFilenameBase => 'mentality_resultados';

  @override
  String coreRouteNotFound(String path) {
    return 'Página não encontrada: $path';
  }

  @override
  String get homeHeroTitle => 'Descubra';

  @override
  String get homeHeroTitleItalic => 'o seu perfil cognitivo.';

  @override
  String get homeHeroBody =>
      'Uma avaliação científica e adaptativa, inspirada nas escalas de Wechsler. 12 subtestes, 5 índices, uma pontuação global.';

  @override
  String get homeActionStartTitle => 'Iniciar uma avaliação';

  @override
  String get homeActionStartSubtitle => 'Duração: 60 – 90 minutos';

  @override
  String get homeActionResultsTitle => 'Os meus resultados';

  @override
  String get homeActionResultsSubtitle => 'Histórico de avaliações';

  @override
  String get homeActionChatTitle => 'Falar com o Mental E.T.';

  @override
  String get homeActionChatSubtitle =>
      'Assistente de IA, perguntas de psicologia';

  @override
  String get homeComingSoon => 'BREVEMENTE';

  @override
  String get homeAboutEyebrow => 'SOBRE';

  @override
  String get homeAboutSubtestsTitle => '12 subtestes';

  @override
  String get homeAboutSubtestsBody =>
      'Uma avaliação completa dos cinco índices cognitivos da WAIS-IV.';

  @override
  String get homeAboutAdaptiveTitle => 'IA adaptativa';

  @override
  String get homeAboutAdaptiveBody =>
      'Dificuldade ajustada em tempo real através de inferência TRI.';

  @override
  String get homeAboutValidationTitle => 'Validação científica';

  @override
  String get homeAboutValidationBody =>
      'Itens inspirados nas escalas de Wechsler (WPPSI / WISC / WAIS).';

  @override
  String get homeResumeEyebrow => 'TESTE EM CURSO';

  @override
  String get homeResumeTitle => 'Retomar a sua avaliação';

  @override
  String get homeResumeButton => 'Retomar';

  @override
  String get homeLogoutTitle => 'Terminar sessão?';

  @override
  String get homeLogoutBody =>
      'O teu token será removido deste dispositivo. Certifica-te de que o guardaste: sem ele, não poderás voltar a aceder aos teus dados.';

  @override
  String get homeLogoutConfirm => 'Terminar sessão';

  @override
  String get infoTestName => 'Informação';

  @override
  String get infoEyebrow => 'COMPREENSÃO VERBAL · VCI';

  @override
  String infoTrailingStatus(int seconds, int score, int attempted) {
    return '${seconds}s · $score/$attempted';
  }

  @override
  String get infoCorrect => 'Certo!';

  @override
  String get infoIncorrect => 'Errado';

  @override
  String get infoFeedbackRight => 'Resposta certa! +1 ponto';

  @override
  String get infoFeedbackWrong => 'Resposta errada. 0 pontos';

  @override
  String infoQuestionLabel(String question) {
    return 'Pergunta: $question';
  }

  @override
  String infoCorrectAnswerLabel(String answer) {
    return 'Resposta certa: $answer';
  }

  @override
  String infoTimeLabel(int seconds) {
    return 'Tempo: ${seconds}s';
  }

  @override
  String infoScoreLabel(int score, int attempted) {
    return 'Pontuação: $score/$attempted';
  }

  @override
  String infoDomainLabel(String domain) {
    return 'Domínio: $domain';
  }

  @override
  String get infoDiscontinue3 =>
      '3 falhas consecutivas - Teste terminado (WAIS-IV)';

  @override
  String get infoSeeResults => 'Ver resultados';

  @override
  String get infoResultsTitle => 'Teste de Informação - Resultados';

  @override
  String infoRawScore(int score, int max) {
    return 'Pontuação bruta: $score/$max pontos';
  }

  @override
  String infoItemsCompleted(int completed, int total) {
    return 'Itens concluídos: $completed/$total';
  }

  @override
  String infoPercentage(int percent) {
    return 'Percentagem: $percent%';
  }

  @override
  String infoTotalTime(int seconds) {
    return 'Tempo total: ${seconds}s';
  }

  @override
  String get infoTestSubtitle => 'Teste de conhecimentos gerais adquiridos';

  @override
  String get infoDomainBreakdownTitle => 'Distribuição por domínio:';

  @override
  String infoDomainBreakdownRow(String domain, int correct, int total) {
    return '$domain: $correct/$total';
  }

  @override
  String get infoPerfExceptional => 'Desempenho excecional (θ > +2.0)';

  @override
  String get infoPerfSuperior => 'Desempenho superior (θ > +1.0)';

  @override
  String get infoPerfAverage => 'Desempenho médio (θ ≈ 0)';

  @override
  String get infoPerfBelow => 'Desempenho inferior (θ < 0)';

  @override
  String get infoPerfLow => 'Desempenho fraco (θ < -1.0)';

  @override
  String get infoDomainScience => 'Ciências naturais';

  @override
  String get infoDomainHistoryGeography => 'História/Geografia';

  @override
  String get infoDomainGeneralCulture => 'Cultura geral';

  @override
  String get infoDomainMathLogic => 'Matemática/Lógica';

  @override
  String get infoDomainArtsLiterature => 'Artes/Literatura';

  @override
  String get infoDifficultyEasy => 'Fácil';

  @override
  String get infoDifficultyMedium => 'Médio';

  @override
  String get infoDifficultyHard => 'Difícil';

  @override
  String get arithTestName => 'Aritmética';

  @override
  String get arithEyebrow => 'MEMÓRIA DE TRABALHO · WMI';

  @override
  String get arithStartTest => 'Iniciar o teste';

  @override
  String get arithIntroTitle => 'Teste de Aritmética';

  @override
  String get arithIntroDescription =>
      'Este teste avalia a sua memória de trabalho e o seu raciocínio numérico.';

  @override
  String get arithInfoMentalTitle => 'Apenas cálculo mental';

  @override
  String get arithInfoMentalSubtitle =>
      'Resolva os problemas sem papel nem calculadora';

  @override
  String get arithInfoTimeTitle => 'Tempo limitado';

  @override
  String get arithInfoTimeSubtitle =>
      'Cada problema tem um limite de tempo (15-60 segundos)';

  @override
  String get arithInfoBonusTitle => 'Bónus de rapidez';

  @override
  String get arithInfoBonusSubtitle =>
      'Respostas rápidas em certos itens = pontos de bónus';

  @override
  String get arithInfoRepeatTitle => 'Repetição possível';

  @override
  String get arithInfoRepeatSubtitle =>
      'Pode pedir para repetir UMA vez (o cronómetro continua)';

  @override
  String get arithIntroDiscontinueNote =>
      '22 problemas no total. O teste termina após 3 falhas consecutivas.';

  @override
  String arithProblemCounter(int current, int total) {
    return 'Problema $current/$total';
  }

  @override
  String get arithRepeatTitle => 'Repetição do problema';

  @override
  String get arithUnderstood => 'Percebi';

  @override
  String get arithTimeUp => 'Tempo esgotado!';

  @override
  String arithCorrectAnswerLabel(int answer) {
    return 'Resposta correta: $answer';
  }

  @override
  String get arithCorrect => 'Certo!';

  @override
  String get arithIncorrect => 'Errado';

  @override
  String arithTimeSpent(int seconds) {
    return 'Tempo: $seconds segundos';
  }

  @override
  String get arithSpeedBonus => '🎉 Bónus de rapidez! (+1 ponto)';

  @override
  String get arithTestEnded => 'Teste concluído!';

  @override
  String arithItemsCompleted(int completed, int total) {
    return 'Itens concluídos: $completed/$total';
  }

  @override
  String arithBaseScore(int score) {
    return 'Pontuação base: $score pontos';
  }

  @override
  String arithBonusScore(int bonus) {
    return 'Bónus de rapidez: $bonus pontos';
  }

  @override
  String arithTotalScore(int total) {
    return 'Pontuação Total: $total pontos';
  }

  @override
  String get arithRepeat => 'Repetir';

  @override
  String get arithAnswerHint => 'A sua resposta';

  @override
  String get arithDifficultyEasy => 'Fácil';

  @override
  String get arithDifficultyMedium => 'Médio';

  @override
  String get arithDifficultyHard => 'Difícil';

  @override
  String get arithDifficultyVeryHard => 'Muito difícil';

  @override
  String get oralMicAccessTitle => 'Acesso ao microfone';

  @override
  String get oralReadingPermissionBody1 =>
      'Esta atividade grava a sua voz enquanto lê o texto em voz alta.';

  @override
  String get oralReadingPermissionBody2 =>
      'As suas gravações serão anonimizadas e poderão contribuir para melhorar o reconhecimento de voz.';

  @override
  String get oralBrowserWillAskMic =>
      'O seu navegador irá depois pedir-lhe autorização para utilizar o microfone.';

  @override
  String get oralCancel => 'Cancelar';

  @override
  String get oralAllowMicrophone => 'Autorizar o microfone';

  @override
  String get oralMicDeniedOrUnavailable =>
      'Microfone recusado ou indisponível.';

  @override
  String get oralCannotStartRecording =>
      'Não foi possível iniciar a gravação neste navegador.';

  @override
  String oralCanSkipToNextStep(String message) {
    return '$message Pode avançar para o passo seguinte.';
  }

  @override
  String get oralSkip => 'Saltar';

  @override
  String get oralRecordingInProgress => 'Gravação em curso';

  @override
  String oralKeepGoingSeconds(int seconds) {
    return 'Continue mais ${seconds}s...';
  }

  @override
  String get oralSaving => 'A guardar...';

  @override
  String get oralReadingInstructions =>
      'Leia o texto seguinte em voz alta, com clareza e ao seu ritmo natural. Carregue em \"Iniciar\" quando estiver pronto.';

  @override
  String get oralStartReading => 'Iniciar a leitura';

  @override
  String get oralFinish => 'Terminar';

  @override
  String get oralSkipThisStep => 'Saltar este passo';

  @override
  String get oralSummaryPermissionBody1 =>
      'Vai agora gravar o seu resumo oral do texto.';

  @override
  String get oralSummaryPermissionBody2 =>
      'Fale com naturalidade, como se estivesse a explicar o texto a um amigo. Demore entre 30 e 60 segundos.';

  @override
  String get oralStartSummary => 'Iniciar o resumo';

  @override
  String get oralSummaryInstructionLead => 'Acabou de ler este texto. ';

  @override
  String get oralSummaryInstructionBody =>
      'Resuma aquilo que compreendeu por palavras suas. Demore entre 30 e 60 segundos. Fale com naturalidade, como se o estivesse a explicar a um amigo.';

  @override
  String get oralReferenceText => 'Texto de referência';

  @override
  String get oralFinishSummary => 'Terminar o resumo';

  @override
  String get oralFlowTitle => 'Recolha de áudio';

  @override
  String get oralConsentTitle => 'Teste de Compreensão Oral';

  @override
  String get oralConsentRecordTitle => 'O que gravamos';

  @override
  String get oralConsentRecordBody =>
      'A sua voz durante a leitura de 5 textos curtos (cerca de 1 min cada) e o seu resumo oral (cerca de 40 segundos por texto).';

  @override
  String get oralConsentAnonTitle => 'Confidencialidade';

  @override
  String get oralConsentAnonBody =>
      'As suas gravações são identificadas por um código de sessão aleatório, e não pelo seu nome. Continuam, no entanto, associáveis à sua conta: são dados pessoais protegidos, cifrados e armazenados na Europa.';

  @override
  String get oralConsentUsageTitle => 'Utilização';

  @override
  String get oralConsentUsageBody =>
      'Estas gravações poderão contribuir para melhorar o reconhecimento de voz, nomeadamente para modelos como o Whisper ou o Speechmatics.';

  @override
  String get oralAcceptAndStart => 'Aceito e começo';

  @override
  String get oralDeclineAndGoBack => 'Recusar e voltar atrás';

  @override
  String get oralWithdrawConsentNote =>
      'Pode retirar o seu consentimento a qualquer momento nas definições da aplicação.';

  @override
  String oralTextProgress(int current) {
    return 'Texto $current de 5';
  }

  @override
  String get oralStepReading => 'Leitura';

  @override
  String get oralStepSummary => 'Resumo';

  @override
  String get oralPauseWellDone => 'Muito bem!';

  @override
  String get oralPauseNowSummarize => 'Agora, resuma este texto em voz alta.';

  @override
  String get oralPauseStartingIn => 'A começar dentro de...';

  @override
  String get oralCompletedThanks => 'Obrigado!';

  @override
  String get oralCompletedBody =>
      'Concluiu os 5 textos.\nAs suas gravações irão contribuir para melhorar\no reconhecimento de voz.';

  @override
  String get oralBackToHome => 'Voltar ao início';

  @override
  String get oralExitDialogTitle => 'Sair?';

  @override
  String get oralExitDialogBody =>
      'Há uma gravação em curso. Se sair agora, não será guardada.';

  @override
  String get oralContinue => 'Continuar';

  @override
  String get oralQuit => 'Sair';

  @override
  String regStepEyebrow(int step) {
    return 'PASSO $step / 4';
  }

  @override
  String get regStepEyebrowSuccess => 'PASSO 4 / 4 · SUCESSO';

  @override
  String get regEmailTitle => 'Criar o meu token';

  @override
  String get regEmailHeading => 'O seu email';

  @override
  String get regEmailIntro =>
      'Vamos enviar-lhe um código de verificação de 6 dígitos. O seu email não fica associado ao seu token e permanece privado.';

  @override
  String get regEmailFieldLabel => 'Endereço de email';

  @override
  String get regEmailInvalid => 'Email inválido';

  @override
  String get regSendingCode => 'A enviar o código…';

  @override
  String get regReceiveCode => 'Receber o código';

  @override
  String get regEmailPrivacyNote =>
      'Não será guardado qualquer nome, apelido ou morada exata. Apenas o seu sexo, faixa etária e código postal são codificados (cifrados) no seu token anónimo.';

  @override
  String get regEmailOtpTitle => 'Verificar o meu email';

  @override
  String get regCodeSentTo => 'Código enviado para';

  @override
  String get regVerifying => 'A verificar…';

  @override
  String get regResendCode => 'Reenviar o código';

  @override
  String get regPhoneTitle => 'O seu telefone';

  @override
  String get regPhoneIntro =>
      'Será enviado um código SMS de 6 dígitos para verificar o seu número. O seu número nunca fica associado ao seu token.';

  @override
  String get regPhoneFieldHint => 'Número';

  @override
  String get regSendingSms => 'A enviar o SMS…';

  @override
  String get regReceiveSms => 'Receber o SMS';

  @override
  String get regPhoneOtpTitle => 'Verificar o meu telefone';

  @override
  String get regSmsSentTo => 'SMS enviado para';

  @override
  String get regResendSms => 'Reenviar o SMS';

  @override
  String get regDemoTitle => 'Os seus dados demográficos';

  @override
  String get regDemoIntro =>
      'Estas informações serão cifradas no seu token. Não é guardado qualquer valor exato (nem idade precisa, nem morada precisa).';

  @override
  String get regSectionSex => 'SEXO';

  @override
  String get regSectionAgeBucket => 'FAIXA ETÁRIA';

  @override
  String get regSectionCountryPostal => 'PAÍS E CÓDIGO POSTAL';

  @override
  String get regPostalCodeHint => 'Código postal';

  @override
  String get regGeneratingToken => 'A gerar o token…';

  @override
  String get regGenerateMyToken => 'Gerar o meu token';

  @override
  String get regSuccessTitle => 'Bem-vindo ao Mental E.T.';

  @override
  String get regSuccessTokenSaved =>
      'O seu token anónimo foi gerado e guardado neste dispositivo.';

  @override
  String get regSuccessTokenDetails =>
      'Não contém o seu email, nem o seu número de telefone, nem o seu nome. Apenas o seu sexo, a sua faixa etária e a sua zona geográfica (cifrados). Pode agora iniciar a sua avaliação cognitiva.';

  @override
  String get regImportantLabel => 'IMPORTANTE';

  @override
  String get regSuccessWarning =>
      'Não desinstale a aplicação antes de concluir a sua avaliação: o seu token está guardado apenas neste dispositivo. Se o perder, deixará de poder criar uma nova conta com o mesmo email ou telefone.';

  @override
  String get regEmailAlreadyRegistered =>
      'Este email já tem uma conta. Se for o seu, já tem um token.';

  @override
  String get regEmailUnavailable => 'Email indisponível.';

  @override
  String get regOtpIncorrectOrExpired => 'Código incorreto ou expirado.';

  @override
  String get regPhoneAlreadyRegistered => 'Este número já tem uma conta.';

  @override
  String get regPhoneUnavailable => 'Número indisponível.';

  @override
  String get regEmailAlreadyHasToken => 'Este email já tem um token.';

  @override
  String get regPhoneAlreadyHasToken => 'Este número já tem um token.';

  @override
  String get regPostalNotFound =>
      'Código postal não encontrado. Verifique o país e o código.';

  @override
  String get regNoInternet => 'Sem ligação à internet.';

  @override
  String get regGenericRetryError => 'Erro — tente novamente.';

  @override
  String get regSexMale => 'Masculino';

  @override
  String get regSexFemale => 'Feminino';

  @override
  String get regSexUndisclosed => 'Prefiro não dizer';

  @override
  String get regAge1825 => '18 – 25 anos';

  @override
  String get regAge2635 => '26 – 35 anos';

  @override
  String get regAge3645 => '36 – 45 anos';

  @override
  String get regAge4655 => '46 – 55 anos';

  @override
  String get regAge5665 => '56 – 65 anos';

  @override
  String get regAge66plus => '66 anos ou mais';

  @override
  String get scoringClassificationVerySuperior => 'Muito superior';

  @override
  String get scoringClassificationSuperior => 'Superior';

  @override
  String get scoringClassificationHighAverage => 'Médio alto';

  @override
  String get scoringClassificationAverage => 'Médio';

  @override
  String get scoringClassificationLowAverage => 'Médio baixo';

  @override
  String get scoringClassificationBorderline => 'Limite';

  @override
  String get scoringClassificationExtremelyLow => 'Extremamente baixo';

  @override
  String get scoringNotAvailable => 'N/D';

  @override
  String scoringSummaryFullScaleIq(int score, String classification) {
    return 'QI total: $score ($classification)';
  }

  @override
  String scoringSummaryPercentile(int rank) {
    return 'Percentil: $rankº';
  }

  @override
  String scoringSummaryConfidenceInterval(int lower, int upper) {
    return 'Intervalo de confiança de 95%: $lower - $upper';
  }

  @override
  String get scoringIndexVerbalComprehension => 'Compreensão verbal';

  @override
  String get scoringIndexVisualSpatial => 'Visuoespacial';

  @override
  String get scoringIndexFluidReasoning => 'Raciocínio fluido';

  @override
  String get scoringIndexWorkingMemory => 'Memória de trabalho';

  @override
  String get scoringIndexProcessingSpeed => 'Velocidade de processamento';

  @override
  String scoringSummaryRelativeStrengths(String list) {
    return 'Pontos fortes relativos: $list';
  }

  @override
  String scoringSummaryRelativeWeaknesses(String list) {
    return 'Pontos fracos relativos: $list';
  }

  @override
  String get scoringSummaryHomogeneousProfile => 'Perfil cognitivo homogéneo';

  @override
  String scoringSummaryHeterogeneousProfile(int points) {
    return 'Perfil cognitivo heterogéneo (diferença máxima: $points pontos)';
  }

  @override
  String get simTestName => 'Semelhanças';

  @override
  String get simEyebrow => 'COMPREENSÃO VERBAL · ICV';

  @override
  String simStatusBar(int seconds, int score) {
    return '$seconds s · $score pts';
  }

  @override
  String get simQuestionPrompt => 'Em que se parecem estas duas palavras?';

  @override
  String simLevelLabel(String level) {
    return 'Nível: $level';
  }

  @override
  String get simLevelConcrete => 'Concreto';

  @override
  String get simLevelFunctional => 'Funcional';

  @override
  String get simLevelCategorical => 'Categorial';

  @override
  String get simLevelAbstract => 'Abstrato';

  @override
  String get simAnswerLabel => 'A sua resposta:';

  @override
  String get simAnswerHint => 'Explique em que se parecem...';

  @override
  String get simTipsTitle => 'Conselhos para obter 2 pontos:';

  @override
  String get simTipsLine1 =>
      '• Indique uma categoria abstrata ou superordenada';

  @override
  String get simTipsLine2 =>
      '• Ex.: \"São...\", \"Formas de...\", \"Tipos de...\"';

  @override
  String get simFeedbackExcellent => 'Excelente!';

  @override
  String get simFeedbackCorrect => 'Correto';

  @override
  String get simFeedbackIncomplete => 'Resposta incompleta';

  @override
  String get simFeedbackMsg2pts => 'Resposta abstrata/categorial! +2 pontos';

  @override
  String get simFeedbackMsg1pt => 'Resposta funcional/de propriedade. +1 ponto';

  @override
  String get simFeedbackMsg0pt =>
      'Resposta incorreta ou demasiado vaga. 0 pontos';

  @override
  String simYourAnswerQuoted(String answer) {
    return 'A sua resposta: \"$answer\"';
  }

  @override
  String get simExamples2pts => 'Exemplos de respostas de 2 pontos:';

  @override
  String get simExamples1pt => 'Exemplos de respostas de 1 ponto:';

  @override
  String simTimeSeconds(int seconds) {
    return 'Tempo: $seconds s';
  }

  @override
  String simTotalScore(int score) {
    return 'Pontuação total: $score pontos';
  }

  @override
  String get simDiscontinue =>
      '3 pontuações de 0 consecutivas - Teste terminado (WAIS-IV)';

  @override
  String get simSeeResults => 'Ver os resultados';

  @override
  String get simResultsTitle => 'Teste das Semelhanças - Resultados';

  @override
  String simRawScore(int score, int max) {
    return 'Pontuação bruta: $score/$max pontos';
  }

  @override
  String simItemsCompleted(int completed, int total) {
    return 'Itens concluídos: $completed/$total';
  }

  @override
  String simPercentage(int percent) {
    return 'Percentagem: $percent%';
  }

  @override
  String simTotalTime(int seconds) {
    return 'Tempo total: $seconds s';
  }

  @override
  String get simSubtitle => 'Teste de raciocínio verbal e abstração conceptual';

  @override
  String get simBreakdownTitle => 'Repartição por nível:';

  @override
  String simBreakdownLine(String level, int total, int max) {
    return '$level: $total/$max pontos';
  }

  @override
  String get simPerfExceptional => 'Desempenho excecional (θ > +2.0)';

  @override
  String get simPerfSuperior => 'Desempenho superior (θ > +1.0)';

  @override
  String get simPerfAverage => 'Desempenho médio (θ ≈ 0)';

  @override
  String get simPerfBelow => 'Desempenho inferior (θ < 0)';

  @override
  String get simPerfLow => 'Desempenho fraco (θ < -1.0)';

  @override
  String get simBack => 'Voltar';

  @override
  String get matTestName => 'Matrizes Progressivas';

  @override
  String get matEyebrow => 'TESTE DE QI · FSIQ';

  @override
  String get matCorrect => 'Correto!';

  @override
  String get matIncorrect => 'Incorreto';

  @override
  String matResponseTime(int seconds) {
    return 'Tempo de resposta: $seconds s';
  }

  @override
  String matScoreFraction(int score, int total) {
    return 'Pontuação: $score/$total';
  }

  @override
  String get matDiscontinue4 =>
      '4 falhas consecutivas - Teste terminado (WAIS-IV)';

  @override
  String get matSeeResultsEnded => 'Ver resultados (teste terminado)';

  @override
  String get matNextItem => 'Item seguinte';

  @override
  String get matSeeResults => 'Ver resultados';

  @override
  String get matFinishedTitle => 'Teste das Matrizes concluído!';

  @override
  String get matRawScore => 'Pontuação bruta';

  @override
  String get matSuccessRate => 'Taxa de sucesso';

  @override
  String get matAvgTimePerItem => 'Tempo médio/item';

  @override
  String get matEvaluation => 'Avaliação:';

  @override
  String get matPerfExcellent => 'Excelente! Raciocínio fluido muito superior.';

  @override
  String get matPerfVeryGood =>
      'Muito bem! Boas capacidades de análise lógica.';

  @override
  String get matPerfGood => 'Bem. Capacidades médias a boas.';

  @override
  String get matPerfAverage => 'Médio. São possíveis melhorias.';

  @override
  String get matPerfBelowAverage =>
      'Resultados abaixo da média. Recomenda-se treino.';

  @override
  String matPoints(int score) {
    return '$score pts';
  }

  @override
  String get matValidateAnswer => 'Validar a resposta';

  @override
  String get matRestart => 'Recomeçar';

  @override
  String matRulesTheta(int rules, String theta) {
    return 'Regras: $rules | θ = $theta';
  }

  @override
  String get matInstruction =>
      'Encontre a peça em falta que completa logicamente a matriz';

  @override
  String get matChooseAnswer => 'Escolha a sua resposta:';

  @override
  String get matDiffEasy => 'Fácil';

  @override
  String get matDiffMediumEasy => 'Médio-Fácil';

  @override
  String get matDiffMedium => 'Médio';

  @override
  String get matDiffMediumHard => 'Médio-Difícil';

  @override
  String get matDiffHard => 'Difícil';

  @override
  String get cubesTestName => 'Teste dos Cubos';

  @override
  String get cubesBravo => 'Parabéns!';

  @override
  String cubesElapsedTime(String time) {
    return 'Tempo decorrido: $time';
  }

  @override
  String cubesPointsEarned(int points) {
    return 'Pontos ganhos: $points';
  }

  @override
  String cubesTotalScore(int score) {
    return 'Pontuação total: $score';
  }

  @override
  String get cubesFinishedTitle => 'Teste concluído!';

  @override
  String get cubesTotalScoreLabel => 'Pontuação total';

  @override
  String cubesTotalScoreValue(int score, int max) {
    return '$score/$max pts';
  }

  @override
  String get cubesItemsCompletedLabel => 'Itens concluídos';

  @override
  String cubesItemsCompletedValue(int count) {
    return '$count/14';
  }

  @override
  String get cubesAvgTime => 'Tempo médio';

  @override
  String get cubesPerfExcellent =>
      'Excelente! Capacidades visuoespaciais muito superiores.';

  @override
  String get cubesPerfVeryGood =>
      'Muito bem! Boas capacidades de análise visual.';

  @override
  String get cubesDiffExample => 'Exemplo';

  @override
  String get cubesDiffVeryHard => 'Muito difícil';

  @override
  String get cubesDescExample => 'Item de exemplo - Não conta para a pontuação';

  @override
  String get cubesDesc2x2 => 'Padrão 2×2 simples';

  @override
  String get cubesDesc3x3Diagonals => 'Padrão 3×3 com diagonais';

  @override
  String get cubesDesc3x3Complex => 'Padrão 3×3 complexo - Alta coesão';

  @override
  String cubesCohesion(int score) {
    return 'Coesão: $score';
  }

  @override
  String cubesRemaining(String time) {
    return 'Resta: $time';
  }

  @override
  String get cubesReproduceInstruction =>
      'Reproduza o padrão abaixo tocando nos cubos';

  @override
  String get cubesPatternToReproduce => 'Padrão a reproduzir:';

  @override
  String get cubesYourAnswer => 'A sua resposta:';

  @override
  String get cubesReset => 'Repor';

  @override
  String get fwTestName => 'Balanças Quantitativas';

  @override
  String get fwEyebrow => 'RACIOCÍNIO FLUIDO · FRI';

  @override
  String get fwCorrectAnswerPoint => 'Resposta correta! +1 ponto';

  @override
  String get fwWrongAnswer => 'Resposta errada. A resposta correta era:';

  @override
  String fwTime(int seconds) {
    return 'Tempo: $seconds s';
  }

  @override
  String get fwDiscontinue3 =>
      '3 falhas consecutivas - Teste terminado (WAIS-IV)';

  @override
  String get fwSeeResults => 'Ver os resultados';

  @override
  String get fwResultsTitle => 'Teste das Balanças Quantitativas - Resultados';

  @override
  String fwRawScorePoints(int score) {
    return 'Pontuação bruta: $score/27 pontos';
  }

  @override
  String fwItemsCompleted(int count) {
    return 'Itens concluídos: $count/27';
  }

  @override
  String fwPercentage(int percent) {
    return 'Percentagem: $percent%';
  }

  @override
  String fwTotalTime(int seconds) {
    return 'Tempo total: $seconds s';
  }

  @override
  String get fwGLoading => 'g-loading: 0.78 (o mais elevado do WAIS-IV)';

  @override
  String get fwPerfExceptional => 'Desempenho excecional (θ > +2.0)';

  @override
  String get fwPerfSuperior => 'Desempenho superior (θ > +1.0)';

  @override
  String get fwPerfAverage => 'Desempenho médio (θ ≈ 0)';

  @override
  String get fwPerfInferior => 'Desempenho abaixo da média (θ < 0)';

  @override
  String get fwPerfLow => 'Desempenho fraco (θ < -1.0)';

  @override
  String fwScoreFraction(int score, int total) {
    return '$score/$total';
  }

  @override
  String get fwInstruction =>
      'Encontre o valor em falta que equilibra a balança.';

  @override
  String get fwWhatIs => 'Quanto vale ';

  @override
  String fwSeconds(int seconds) {
    return '$seconds s';
  }

  @override
  String get vpTestName => 'Puzzles Visuais';

  @override
  String get vpEyebrow => 'VISUOESPACIAL · VSI';

  @override
  String get vpCorrect => 'Correto';

  @override
  String get vpIncorrect => 'Incorreto';

  @override
  String get vpValidate => 'Validar';

  @override
  String vpSelectedCount(int count) {
    return '$count / 3 selecionadas';
  }

  @override
  String get vpInstruction =>
      'Escolha as 3 peças que formam a figura (rotações permitidas, inversões proibidas).';

  @override
  String vpSelectionSemantics(int filled, int total) {
    return 'Seleção: $filled de $total peças';
  }

  @override
  String get vpSelectionLabel => 'SELEÇÃO';

  @override
  String vpPieceSemantics(String label) {
    return 'Peça $label';
  }

  @override
  String get vpTargetTitle => 'FIGURA A RECONSTITUIR';

  @override
  String get codingTestName => 'Código (Símbolos e Dígitos)';

  @override
  String get codingEyebrow => 'VELOCIDADE DE PROCESSAMENTO · PSI';

  @override
  String get codingStartTraining => 'Iniciar o treino';

  @override
  String get codingTitle => 'Teste de Código';

  @override
  String get codingDescription =>
      'Este teste avalia a sua velocidade de processamento e a sua coordenação visuomotora.';

  @override
  String get codingReferenceKey => 'Chave de referência:';

  @override
  String get codingTaskTitle => 'A sua tarefa';

  @override
  String get codingTaskDesc =>
      'Para cada dígito apresentado, selecione o símbolo correspondente';

  @override
  String get codingTimeLimitTitle => 'Tempo limitado';

  @override
  String get codingTimeLimitDesc =>
      '120 segundos para completar o máximo de células (135 no total)';

  @override
  String get codingScoringTitle => 'Pontuação';

  @override
  String get codingScoringDesc =>
      '1 ponto por célula correta, sem penalização por erros';

  @override
  String get codingTrainingDoneTitle => 'Treino concluído';

  @override
  String get codingTrainingDoneBody =>
      'Está pronto para iniciar o teste. Terá 120 segundos para completar o máximo de células.';

  @override
  String get codingStartTest => 'Iniciar o teste';

  @override
  String get codingTestDoneTitle => 'Teste concluído!';

  @override
  String get codingTimeElapsed => 'Tempo decorrido: 120 segundos';

  @override
  String codingCellsCompleted(int count) {
    return 'Células completadas: $count/135';
  }

  @override
  String codingCellsCorrect(int count) {
    return 'Células corretas: $count';
  }

  @override
  String codingScorePoints(int count) {
    return 'Pontuação: $count pontos';
  }

  @override
  String get codingPerfExceptional => 'Desempenho excecional!';

  @override
  String get codingPerfVeryGood => 'Muito bom desempenho';

  @override
  String get codingPerfAboveAverage => 'Desempenho acima da média';

  @override
  String get codingPerfAverage => 'Desempenho médio';

  @override
  String get codingPerfBelowAverage => 'Desempenho abaixo da média';

  @override
  String get codingTrainingTab => 'Treino';

  @override
  String get codingReferenceShort => 'Referência:';

  @override
  String codingCellProgress(int current, int total) {
    return 'Célula $current/$total';
  }

  @override
  String codingCompletedProgress(int count, int total) {
    return 'Completadas: $count/$total';
  }

  @override
  String get codingSelectSymbol => 'Selecione um símbolo:';

  @override
  String get codingClear => 'Apagar';

  @override
  String get codingFinishTraining => 'Terminar o treino';

  @override
  String get ssTestName => 'Pesquisa de Símbolos';

  @override
  String get ssDescription =>
      'Este teste avalia a sua velocidade de processamento visual e a sua capacidade de discriminação.';

  @override
  String get ssExampleLabel => 'Exemplo de item:';

  @override
  String get ssTargets => 'ALVOS';

  @override
  String get ssGroup => 'GRUPO';

  @override
  String get ssExampleAnswer => '→ Resposta: SIM (┴ está presente)';

  @override
  String get ssTaskTitle => 'A sua tarefa';

  @override
  String get ssTaskDesc =>
      'Verifique se algum dos símbolos-alvo aparece no grupo';

  @override
  String get ssQuickAnswerTitle => 'Resposta rápida';

  @override
  String get ssQuickAnswerDesc => 'Toque em SIM ou NÃO o mais rápido possível';

  @override
  String get ssScoringPenaltyTitle => 'Pontuação com penalização';

  @override
  String get ssScoringPenaltyDesc =>
      'Pontuação = Respostas corretas - Respostas incorretas';

  @override
  String get ssTimeLimitTitle => 'Tempo limitado';

  @override
  String get ssTimeLimitDesc => '120 segundos para 60 itens';

  @override
  String get ssTrainingDoneBody =>
      'Está pronto! Terá 120 segundos para completar o máximo de itens.\n\nLembrete: Pontuação = Respostas corretas - Respostas incorretas';

  @override
  String ssItemsAnswered(int count) {
    return 'Itens respondidos: $count/60';
  }

  @override
  String ssCorrectAnswers(int count) {
    return 'Respostas corretas: $count';
  }

  @override
  String ssIncorrectAnswers(int count) {
    return 'Respostas incorretas: $count';
  }

  @override
  String ssNotAnswered(int count) {
    return 'Não respondidos: $count';
  }

  @override
  String ssRawScore(int count) {
    return 'Pontuação bruta: $count';
  }

  @override
  String get ssScoreFormulaShort => '(Corretas - Incorretas)';

  @override
  String get ssPerfGood => 'Bom desempenho';

  @override
  String ssItemProgress(int current, int total) {
    return 'Item $current/$total';
  }

  @override
  String ssAnsweredProgress(int count) {
    return 'Respondidos: $count/60';
  }

  @override
  String get ssTargetSymbols => 'SÍMBOLOS-ALVO';

  @override
  String get ssSearchGroup => 'GRUPO DE PESQUISA';

  @override
  String get ssNo => 'NÃO';

  @override
  String get ssYes => 'SIM';

  @override
  String get dsTestName => 'Memória de Dígitos';

  @override
  String get dsEyebrow => 'MEMÓRIA DE TRABALHO · WMI';

  @override
  String get dsDescription =>
      'Este teste avalia a sua memória de trabalho através de 3 partes distintas:';

  @override
  String get dsForwardTitle => 'Parte 1: Sentido Direto';

  @override
  String get dsForwardInstruction => 'Repita os dígitos pela mesma ordem';

  @override
  String get dsBackwardTitle => 'Parte 2: Sentido Inverso';

  @override
  String get dsBackwardInstruction => 'Repita os dígitos por ordem inversa';

  @override
  String get dsSequencingTitle => 'Parte 3: Sequenciação';

  @override
  String get dsSequencingInstruction => 'Repita os dígitos por ordem crescente';

  @override
  String get dsPresentationInfo =>
      'Os dígitos serão apresentados ao ritmo de 1 dígito por segundo.';

  @override
  String get dsTypeForward => 'Sentido Direto';

  @override
  String get dsTypeBackward => 'Sentido Inverso';

  @override
  String get dsTypeSequencing => 'Sequenciação';

  @override
  String get dsStartPart => 'Começar';

  @override
  String dsLengthTrial(int length, int trial) {
    return 'Comprimento $length - Tentativa $trial';
  }

  @override
  String get dsListenCarefully => 'Ouça com atenção';

  @override
  String get dsCorrect => 'Correto!';

  @override
  String get dsIncorrect => 'Incorreto';

  @override
  String dsPointsEarned(int count) {
    return 'Pontos obtidos: $count';
  }

  @override
  String dsCorrectAnswer(String answer) {
    return 'Resposta correta: $answer';
  }

  @override
  String dsYourAnswer(String answer) {
    return 'A sua resposta: $answer';
  }

  @override
  String get dsResultsByPart => 'Resultados por parte:';

  @override
  String dsForwardScore(int count) {
    return 'Sentido Direto: $count pontos';
  }

  @override
  String dsBackwardScore(int count) {
    return 'Sentido Inverso: $count pontos';
  }

  @override
  String dsSequencingScore(int count) {
    return 'Sequenciação: $count pontos';
  }

  @override
  String dsTotalScore(int count) {
    return 'Pontuação Total: $count pontos';
  }

  @override
  String get dsEnterAnswer => 'Introduza a sua resposta...';

  @override
  String dsValidateProgress(int count, int total) {
    return 'Validar ($count/$total)';
  }

  @override
  String get psTestName => 'Memória de Imagens';

  @override
  String get psDescription =>
      'Este teste avalia a sua memória de trabalho visual e a sua atenção seletiva.';

  @override
  String get psPhase1Title => 'Fase 1: Memorização';

  @override
  String get psPhase1Desc =>
      'As imagens serão apresentadas uma a uma (3 segundos cada)';

  @override
  String get psPhase2Title => 'Fase 2: Evocação';

  @override
  String get psPhase2Desc =>
      'Selecione as imagens exatamente pela ordem em que foram apresentadas';

  @override
  String get psProgressionTitle => 'Progressão';

  @override
  String get psProgressionDesc =>
      'A dificuldade aumenta: 1 a 6 imagens a memorizar';

  @override
  String get psTrialsInfo =>
      '12 tentativas no total. O teste para após 2 falhas no mesmo nível.';

  @override
  String get psMemorizationTab => 'Memorização';

  @override
  String get psRecallTab => 'Evocação';

  @override
  String psLevelTrial(int level, int trial) {
    return 'Nível $level - Tentativa $trial';
  }

  @override
  String get psMemorizeImages => 'Memorize as imagens';

  @override
  String psImageProgress(int current, int total) {
    return 'Imagem $current / $total';
  }

  @override
  String psSelectInOrder(int count) {
    return 'Selecione as $count imagens pela ordem correta';
  }

  @override
  String get psNoSelection => 'Nenhuma seleção';

  @override
  String get psClearLast => 'Apagar a última seleção';

  @override
  String psCorrectOrder(String names) {
    return 'Ordem correta: $names';
  }

  @override
  String psYourOrder(String names) {
    return 'A sua ordem: $names';
  }

  @override
  String psTrialsCompleted(int count) {
    return 'Tentativas completadas: $count/12';
  }

  @override
  String psScorePoints(int count) {
    return 'Pontuação Total: $count pontos';
  }

  @override
  String psMaxLevel(int level) {
    return 'Nível máximo alcançado: Nível $level';
  }

  @override
  String get psImgChat => 'Gato';

  @override
  String get psImgInsecte => 'Inseto';

  @override
  String get psImgLapin => 'Coelho';

  @override
  String get psImgOiseau => 'Pássaro';

  @override
  String get psImgPoisson => 'Peixe';

  @override
  String get psImgTortue => 'Tartaruga';

  @override
  String get psImgPapillon => 'Borboleta';

  @override
  String get psImgCoccinelle => 'Joaninha';

  @override
  String get psImgChaise => 'Cadeira';

  @override
  String get psImgLampe => 'Candeeiro';

  @override
  String get psImgMontre => 'Relógio';

  @override
  String get psImgParapluie => 'Guarda-chuva';

  @override
  String get psImgSac => 'Mala';

  @override
  String get psImgLit => 'Cama';

  @override
  String get psImgPorte => 'Porta';

  @override
  String get psImgFenetre => 'Janela';

  @override
  String get psImgGateau => 'Bolo';

  @override
  String get psImgCafe => 'Café';

  @override
  String get psImgPizza => 'Pizza';

  @override
  String get psImgPomme => 'Maçã';

  @override
  String get psImgGlace => 'Gelado';

  @override
  String get psImgBurger => 'Hambúrguer';

  @override
  String get psImgSandwich => 'Sanduíche';

  @override
  String get psImgOeuf => 'Ovo';

  @override
  String get psImgMarteau => 'Martelo';

  @override
  String get psImgCle => 'Chave inglesa';

  @override
  String get psImgCiseaux => 'Tesoura';

  @override
  String get psImgPinceau => 'Pincel';

  @override
  String get psImgCrayon => 'Lápis';

  @override
  String get psImgCouteau => 'Faca';

  @override
  String get psImgTournevis => 'Chave de fendas';

  @override
  String get psImgEngrenage => 'Engrenagem';

  @override
  String get psImgVoiture => 'Carro';

  @override
  String get psImgVelo => 'Bicicleta';

  @override
  String get psImgAvion => 'Avião';

  @override
  String get psImgTrain => 'Comboio';

  @override
  String get psImgBateau => 'Barco';

  @override
  String get psImgBus => 'Autocarro';

  @override
  String get psImgMoto => 'Mota';

  @override
  String get psImgFusee => 'Foguetão';

  @override
  String get ctShareScore => 'Partilhar a minha pontuação';

  @override
  String get ctSubtestExitBody =>
      'Saiu deste subteste antes de o terminar. Deseja retomá-lo ou parar a avaliação?';

  @override
  String get ctSubtestExitResume => 'Retomar o subteste';

  @override
  String get ctSubtestExitTitle => 'Subteste interrompido';

  @override
  String get demoBadge => 'PRÁTICA';

  @override
  String get demoContinue => 'Continuar';

  @override
  String get demoNotice => 'Prática: esta tentativa não conta.';

  @override
  String get demoRetry => 'Tentar de novo';

  @override
  String get demoStart => 'Começar o teste';

  @override
  String get demoTryAgain => 'Quase… tente novamente';

  @override
  String get demoWellDone => 'Correto!';

  @override
  String get histLockedBody =>
      'O teu resultado está guardado, mas fica desfocado até todas as missões serem validadas.';

  @override
  String get histLockedBodyNoResult =>
      'As tuas missões e o teu link de convite estão aqui. Termina a tua avaliação para desbloqueares o teu resultado.';

  @override
  String get histLockedCta => 'Ver as minhas missões';

  @override
  String get histLockedTitle => 'Missões por validar';

  @override
  String get inviteLandingBody =>
      'Um amigo convidou-te para fazer o teste de QI gratuito da Mentality. Ao terminares o teu teste, obténs o teu resultado e ajudas o teu amigo a desbloquear o dele.';

  @override
  String get inviteLandingCta => 'Começar o teste gratuito';

  @override
  String get inviteLandingTitle => 'Convite';

  @override
  String get shareCancel => 'Cancelar';

  @override
  String get shareCodeLabel => 'Código de convite';

  @override
  String get shareConfirm => 'Partilhar esta imagem';

  @override
  String get shareError =>
      'Não foi possível preparar a imagem. Tenta novamente.';

  @override
  String get shareEyebrow => 'Pré-visualização';

  @override
  String get shareIntro =>
      'Esta é a imagem que será partilhada. Nada é publicado até confirmares.';

  @override
  String get shareLinkCopied =>
      'O teu link está copiado — adiciona-o como sticker de Link na tua story';

  @override
  String sharePercentile(int rank) {
    return 'Mais alta do que a de $rank % dos participantes';
  }

  @override
  String get shareScoreLabel => 'Pontuação global';

  @override
  String get shareTitle => 'Partilhar a minha pontuação';

  @override
  String get ugCopied => 'Link copiado!';

  @override
  String get ugCopyLink => 'Copiar o meu link de convite';

  @override
  String get ugErrorBody =>
      'Não foi possível obter o estado do teu desbloqueio. Verifica a tua ligação e tenta novamente.';

  @override
  String get ugEyebrow => 'Últimas etapas';

  @override
  String get ugFreeNotice =>
      'O teste é 100% gratuito. Para receberes o teu resultado faltam alguns passos simples: são validados automaticamente.';

  @override
  String ugFriendDone(int n) {
    return 'Amigo $n: teste terminado';
  }

  @override
  String ugFriendPending(int n) {
    return 'Amigo $n: teste em curso';
  }

  @override
  String ugInviteCounter(int joined, int required) {
    return '$joined/$required amigos terminaram o seu teste';
  }

  @override
  String get ugRefresh => 'Atualizar';

  @override
  String get ugRefreshFailed =>
      'Não foi possível atualizar. Verifica a tua ligação — os números mostrados são da última atualização.';

  @override
  String get ugResultsHubNotice =>
      'Está tudo em «Os meus resultados»: as tuas missões, o teu link de convite e o teu resultado (desfocado até todas as missões serem validadas). Podes sair desta página e voltar quando quiseres.';

  @override
  String get ugRetry => 'Tentar novamente';

  @override
  String get ugStep1Body =>
      'Partilha o teu link pessoal com 3 amigos. Este passo avança quando eles TERMINAM o teste — não apenas quando se inscrevem. Não hesites em lembrá-los.';

  @override
  String get ugStep1Title => 'Convida 3 amigos';

  @override
  String get ugStep2Body =>
      'Os teus amigos precisam agora de terminar o teste de QI. Estamos à espera dos resultados — lembra-os!';

  @override
  String get ugStep2Title => 'Os teus amigos estão a fazer o teste';

  @override
  String get ugTitle => 'O teu resultado está pronto';

  @override
  String ugWaitBody(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other:
          'O teu resultado está a ser preparado. Será publicado dentro de $days dias, automaticamente — não tens de fazer mais nada.',
      one:
          'O teu resultado está a ser preparado. Será publicado dentro de $days dia, automaticamente — não tens de fazer mais nada.',
      zero:
          'O teu resultado está a ser preparado. Será publicado automaticamente — não tens de fazer mais nada.',
    );
    return '$_temp0';
  }

  @override
  String get ugWaitConfirming =>
      'O teu resultado é desbloqueado assim que o servidor confirmar — este ecrã atualiza-se sozinho.';

  @override
  String ugWaitCountdownDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Faltam $days dias',
      one: 'Falta $days dia',
    );
    return '$_temp0';
  }

  @override
  String get ugWaitCountdownDone => 'O prazo terminou.';

  @override
  String ugWaitCountdownHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: 'Faltam $hours horas',
      one: 'Falta $hours hora',
    );
    return '$_temp0';
  }

  @override
  String ugWaitCountdownMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'Faltam $minutes minutos',
      one: 'Falta $minutes minuto',
    );
    return '$_temp0';
  }

  @override
  String get ugWaitTitle => 'Os teus resultados estão a chegar';

  @override
  String get vpDemoEyebrow => 'DEMONSTRAÇÃO';

  @override
  String get vpDemoInstruction =>
      'Treino sem tempo: escolha as 3 peças que formam a figura e confirme.';

  @override
  String get vpDemoRetry => 'Tentar novamente';

  @override
  String get vpDemoStart => 'Começar o teste';

  @override
  String vpReadyBody(int count) {
    return 'O treino terminou. O teste vai começar: $count puzzles, cada um com o seu próprio cronómetro. O tempo começa assim que tocar no botão.';
  }

  @override
  String get vpReadyStart => 'Começar agora';

  @override
  String get vpReadyTitle => 'Pronto?';

  @override
  String get vpRecorded => 'Resposta registada';

  @override
  String get vocabTestName => 'Vocabulário';

  @override
  String get vocabEyebrow => 'COMPREENSÃO VERBAL · ICV';

  @override
  String vocabTimerScore(int seconds, int score) {
    return '$seconds s · $score pts';
  }

  @override
  String get vocabFeedbackExcellent => 'Excelente!';

  @override
  String get vocabFeedbackCorrect => 'Correto';

  @override
  String get vocabFeedbackIncomplete => 'Resposta incompleta';

  @override
  String get vocabFeedbackTwoPoints =>
      'Definição completa e precisa! +2 pontos';

  @override
  String get vocabFeedbackOnePoint =>
      'Definição parcial, mas correta. +1 ponto';

  @override
  String get vocabFeedbackZeroPoint =>
      'Resposta incorreta ou demasiado vaga. 0 pontos';

  @override
  String vocabWordLabel(String word) {
    return 'Palavra: «$word»';
  }

  @override
  String vocabYourAnswerLabel(String answer) {
    return 'A sua resposta: «$answer»';
  }

  @override
  String get vocabEmptyAnswer => '(vazio)';

  @override
  String get vocabTwoPointExamples => 'Exemplos de respostas de 2 pontos:';

  @override
  String get vocabOnePointExamples => 'Exemplos de respostas de 1 ponto:';

  @override
  String vocabTimeSeconds(int seconds) {
    return 'Tempo: $seconds s';
  }

  @override
  String vocabTotalScore(int score) {
    return 'Pontuação total: $score pontos';
  }

  @override
  String get vocabDiscontinued =>
      '3 pontuações de 0 consecutivas - Teste terminado (WAIS-IV)';

  @override
  String get vocabViewResults => 'Ver os resultados';

  @override
  String get vocabResultsTitle => 'Teste de Vocabulário - Resultados';

  @override
  String vocabRawScore(int score, int max) {
    return 'Pontuação bruta: $score/$max pontos';
  }

  @override
  String vocabItemsCompleted(int completed, int total) {
    return 'Itens concluídos: $completed/$total';
  }

  @override
  String vocabPercentage(int percent) {
    return 'Percentagem: $percent%';
  }

  @override
  String vocabTotalTime(int seconds) {
    return 'Tempo total: $seconds s';
  }

  @override
  String get vocabTestCaption =>
      'Teste de conhecimento lexical e compreensão verbal';

  @override
  String get vocabFrequencyBreakdownTitle => 'Distribuição por frequência:';

  @override
  String vocabFrequencyBreakdownRow(String name, int score, int max) {
    return '$name: $score/$max pontos';
  }

  @override
  String get vocabPerfExceptional => 'Desempenho excecional (θ > +2.0)';

  @override
  String get vocabPerfSuperior => 'Desempenho superior (θ > +1.0)';

  @override
  String get vocabPerfAverage => 'Desempenho médio (θ ≈ 0)';

  @override
  String get vocabPerfBelowAverage => 'Desempenho inferior (θ < 0)';

  @override
  String get vocabPerfLow => 'Desempenho fraco (θ < -1.0)';

  @override
  String get vocabFreqVeryHigh => 'Muito frequente';

  @override
  String get vocabFreqHigh => 'Frequente';

  @override
  String get vocabFreqMedium => 'Médio';

  @override
  String get vocabFreqLow => 'Raro';

  @override
  String get vocabFreqVeryLow => 'Muito raro';

  @override
  String get vocabInstruction => 'Defina a palavra seguinte';

  @override
  String get vocabYourDefinitionLabel => 'A sua definição:';

  @override
  String get vocabDefinitionHint => 'Escreva a definição da palavra...';

  @override
  String get vocabTipsTitle => 'Conselhos para obter 2 pontos:';

  @override
  String get vocabTipComplete => '• Apresente uma definição completa e precisa';

  @override
  String get vocabTipSynonyms => '• Utilize sinónimos exatos';

  @override
  String get vocabTipContext => '• Explique o significado com contexto';

  @override
  String get weGateCta => 'Ver o programa de hoje';

  @override
  String get weHubEyebrow => 'Durante a espera';

  @override
  String weHubTitle(int day) {
    return 'Dia $day';
  }

  @override
  String get weHubTitleDone => 'Programa concluído';

  @override
  String get weHubIntro =>
      'Todos os dias é revelada uma parte dos seus resultados, com uma atividade opcional. Nada aqui acelera o desbloqueio: só o tempo desbloqueia.';

  @override
  String get weTodayTag => 'Hoje';

  @override
  String get wePastTag => 'Para recuperar';

  @override
  String weLockedTag(int day) {
    return 'Abre no dia $day';
  }

  @override
  String get wePlaceholderTitle => 'Em preparação';

  @override
  String get wePlaceholderBody =>
      'O conteúdo deste dia chegará numa próxima atualização.';

  @override
  String get weAnnouncedTag => 'Teste do dia — com o seu resultado';

  @override
  String get weContributionTag =>
      'Contribuição — ajude-nos a construir o nosso teste';

  @override
  String get weShareTag => 'Recompensa final';

  @override
  String get weDay1Title => 'A sua personalidade';

  @override
  String get weDay2Title => 'Construa o nosso teste de leitura';

  @override
  String get weDay3Title => 'O seu equilíbrio';

  @override
  String get weDay4Title => 'Construa o nosso teste de atenção (1/2)';

  @override
  String get weDay5Title => 'Construa o nosso teste de atenção (2/2)';

  @override
  String get weDay6Title => 'A sua energia';

  @override
  String get weDay7Title => 'Perfil de autismo';

  @override
  String get weDay8Title => 'O seu QI global';

  @override
  String get weRevealVci => 'A sua Compreensão Verbal';

  @override
  String get weRevealPsi => 'A sua Velocidade de Processamento';

  @override
  String get weRevealWmi => 'A sua Memória de Trabalho';

  @override
  String get weRevealFri => 'O seu raciocínio';

  @override
  String get weRevealVsi => 'O seu índice espacial';

  @override
  String get weRevealStrengths => 'Os seus pontos fortes e fracos';

  @override
  String get weRevealFullIq => 'O seu QI global';

  @override
  String get weGameStroop => 'Jogo: Stroop';

  @override
  String get weGameDelayChoice => 'Jogo: tolerância à espera';

  @override
  String get weGameTimeEstimation => 'Jogo: estimativa do tempo';

  @override
  String get weGameConfidence => 'Jogo: calibração da confiança';
}
