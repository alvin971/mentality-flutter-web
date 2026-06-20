import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/app_constants.dart';
import '../../../../core/l10n/l10n_ext.dart';
import '../../../../core/l10n/locale_notifier.dart';
import '../../../../core/services/auth_local_store.dart';
import '../pages/mentality_chat_page.dart';

/// Service de communication avec Claude via le Cloudflare Worker proxy.
///
/// La clé API n'est jamais exposée côté client. Elle est stockée comme
/// secret Cloudflare Workers et injectée par le worker à chaque requête.
///
/// Pour configurer le worker :
///   1. cd workers/claude-proxy
///   2. wrangler secret put ANTHROPIC_API_KEY
///   3. wrangler deploy
///   4. Mettre à jour AppConstants.claudeWorkerUrl avec l'URL du worker
class ClaudeChatService {
  static const String _model = 'claude-haiku-4-5-20251001';

  /// Envoie un message à Claude et retourne la réponse
  Future<String> sendMessage({
    required String message,
    required List<ChatMessage> conversationHistory,
  }) async {
    final workerUrl = AppConstants.claudeWorkerUrl;

    if (workerUrl.contains('YOUR_SUBDOMAIN')) {
      throw Exception(
        'Worker Claude non configuré. '
        'Déployer workers/claude-proxy/ et mettre à jour AppConstants.claudeWorkerUrl.',
      );
    }

    try {
      final token = await AuthLocalStore.instance.getToken();
      final messages = _buildMessages(message, conversationHistory);

      final response = await http
          .post(
            Uri.parse(workerUrl),
            headers: {
              'Content-Type': 'application/json',
              if (token != null && token.isNotEmpty) 'X-Mentality-Token': token,
            },
            body: jsonEncode({
              'model': _model,
              'max_tokens': 1024,
              'system': _getSystemPrompt(),
              'messages': messages,
            }),
          )
          .timeout(AppConstants.connectionTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final content = data['content'] as List?;
        if (content != null && content.isNotEmpty) {
          return (content[0] as Map<String, dynamic>)['text'] as String;
        }
        throw Exception(appL10n.chatErrorEmptyResponse);
      } else if (response.statusCode == 403) {
        throw Exception(appL10n.chatErrorAccessDenied);
      } else if (response.statusCode == 429) {
        throw Exception(appL10n.chatErrorRateLimit);
      } else if (response.statusCode == 500) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(data['error'] ?? 'Erreur serveur (${response.statusCode})');
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('ClaudeChatService error: $e');
      rethrow;
    }
  }

  List<Map<String, dynamic>> _buildMessages(
    String currentMessage,
    List<ChatMessage> history,
  ) {
    final messages = <Map<String, dynamic>>[];

    // Limiter aux 10 derniers messages pour économiser les tokens
    final recentHistory =
        history.length > 10 ? history.sublist(history.length - 10) : history;

    for (final msg in recentHistory) {
      // Ignorer le message de bienvenue initial
      if (!msg.isUser && recentHistory.first == msg) continue;
      messages.add({
        'role': msg.isUser ? 'user' : 'assistant',
        'content': msg.text,
      });
    }

    messages.add({'role': 'user', 'content': currentMessage});
    return messages;
  }

  /// Prompt système dépendant de la langue courante de l'app.
  /// Volontairement hors ARB : c'est une instruction pour l'IA, pas une
  /// chaîne d'interface.
  String _getSystemPrompt() {
    if (localeNotifier.languageCode == 'en') {
      return '''You are Mental E.T., an AI assistant specialized in cognitive assessment based on the WAIS-IV scales (Wechsler Adult Intelligence Scale).

Your role is to help users:
1. Understand their cognitive test results
2. Explain the different cognitive domains (Verbal Comprehension, Visual-Spatial Reasoning, Fluid Reasoning, Working Memory, Processing Speed)
3. Provide personalized advice to improve their cognitive abilities
4. Answer questions about the tests and what they mean

Important characteristics:
- You are caring, patient and encouraging
- You explain complex concepts in a simple, accessible way
- You use clear language, without unnecessary jargon
- You are honest and accurate in your explanations
- You always encourage the user in a positive way
- You respond in English

IMPORTANT:
- Do not make any medical or psychological diagnosis
- Do not replace the advice of a healthcare professional
- Always encourage consulting a professional psychologist when appropriate
- Stay within the scope of general information and advice

Your tone is: friendly, professional, encouraging and accessible.''';
    }
    return '''Tu es Mental E.T., un assistant IA spécialisé dans l'évaluation cognitive basée sur les échelles WAIS-IV (Wechsler Adult Intelligence Scale).

Ton rôle est d'aider les utilisateurs à :
1. Comprendre leurs résultats aux tests cognitifs
2. Expliquer les différents domaines cognitifs (Compréhension Verbale, Raisonnement Visuo-Spatial, Raisonnement Fluide, Mémoire de Travail, Vitesse de Traitement)
3. Donner des conseils personnalisés pour améliorer leurs capacités cognitives
4. Répondre aux questions sur les tests et leur signification

Caractéristiques importantes :
- Tu es bienveillant, patient et encourageant
- Tu expliques les concepts complexes de manière simple et accessible
- Tu utilises un langage clair, sans jargon inutile
- Tu es honnête et précis dans tes explications
- Tu encourages toujours l'utilisateur de manière positive
- Tu réponds en français

IMPORTANT :
- Ne pas poser de diagnostic médical ou psychologique
- Ne pas remplacer l'avis d'un professionnel de santé
- Toujours encourager la consultation d'un psychologue professionnel si nécessaire
- Rester dans le cadre de l'information et du conseil général

Ton ton est : amical, professionnel, encourageant et accessible.''';
  }
}
