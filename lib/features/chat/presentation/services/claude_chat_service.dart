import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../pages/mentality_chat_page.dart';

/// Service de communication avec l'API Claude (Anthropic)
class ClaudeChatService {
  // Configuration API
  static const String _apiUrl = 'https://api.anthropic.com/v1/messages';
  static const String _apiVersion = '2023-06-01';

  // TODO: Remplacer par votre clé API Claude
  // IMPORTANT: Ne JAMAIS commiter la vraie clé API dans le code
  // Utiliser plutôt un fichier .env ou Firebase Remote Config
  static const String _apiKey = 'YOUR_CLAUDE_API_KEY_HERE';

  // Modèle Claude Haiku (le plus rapide et économique)
  static const String _model = 'claude-3-haiku-20240307';

  /// Envoie un message à Claude et retourne la réponse
  Future<String> sendMessage({
    required String message,
    required List<ChatMessage> conversationHistory,
  }) async {
    try {
      // Construire l'historique de conversation pour le contexte
      final messages = _buildMessages(message, conversationHistory);

      // Préparer la requête
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
          'anthropic-version': _apiVersion,
        },
        body: jsonEncode({
          'model': _model,
          'max_tokens': 1024,
          'system': _getSystemPrompt(),
          'messages': messages,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Extraire le texte de la réponse
        if (data['content'] != null && data['content'].isNotEmpty) {
          return data['content'][0]['text'] as String;
        } else {
          throw Exception('Réponse vide de l\'API');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Clé API invalide. Veuillez configurer votre clé API Claude.');
      } else if (response.statusCode == 429) {
        throw Exception('Limite de requêtes atteinte. Veuillez réessayer dans quelques instants.');
      } else {
        throw Exception('Erreur API: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      // Log l'erreur (en production, utiliser un service de logging comme Sentry)
      // ignore: avoid_print
      debugPrint('Erreur ClaudeChatService: $e');
      rethrow;
    }
  }

  /// Construit la liste des messages pour l'API Claude
  List<Map<String, dynamic>> _buildMessages(
    String currentMessage,
    List<ChatMessage> history,
  ) {
    final messages = <Map<String, dynamic>>[];

    // Ajouter l'historique (limité aux 10 derniers messages pour économiser tokens)
    final recentHistory = history.length > 10
        ? history.sublist(history.length - 10)
        : history;

    for (final msg in recentHistory) {
      // Ignorer le message de bienvenue initial
      if (!msg.isUser && recentHistory.first == msg) continue;

      messages.add({
        'role': msg.isUser ? 'user' : 'assistant',
        'content': msg.text,
      });
    }

    // Ajouter le message actuel
    messages.add({
      'role': 'user',
      'content': currentMessage,
    });

    return messages;
  }

  /// Retourne le prompt système qui définit le comportement de Mentality
  String _getSystemPrompt() {
    return '''Tu es Mentality, un assistant IA spécialisé dans l'évaluation cognitive basée sur les échelles WAIS-IV (Wechsler Adult Intelligence Scale).

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
