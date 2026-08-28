# Configuration du Chat IA avec Claude Haiku

## 📋 Vue d'ensemble

Le chat IA "Parler avec Mentality" utilise **Claude 3 Haiku** d'Anthropic, le modèle le plus rapide et économique de la famille Claude 3.

## 🔑 Obtenir une clé API Claude

### Étape 1 : Créer un compte Anthropic

1. Allez sur [https://console.anthropic.com/](https://console.anthropic.com/)
2. Cliquez sur "Sign Up" (Inscription)
3. Créez votre compte avec votre email

### Étape 2 : Générer une clé API

1. Connectez-vous à votre compte Anthropic
2. Allez dans **Settings** > **API Keys**
3. Cliquez sur **"Create Key"**
4. Donnez un nom à votre clé (ex: "Mentality Chat")
5. Copiez la clé générée (elle commence par `sk-ant-`)

⚠️ **IMPORTANT** : Sauvegardez cette clé immédiatement, vous ne pourrez plus la voir après avoir quitté la page !

### Étape 3 : Configurer la clé dans l'application

#### Option 1 : Configuration directe (développement uniquement)

⚠️ **NE PAS utiliser en production** - La clé serait visible dans le code !

Ouvrez le fichier :
```
lib/features/chat/presentation/services/claude_chat_service.dart
```

Ligne 12, remplacez :
```dart
static const String _apiKey = 'YOUR_CLAUDE_API_KEY_HERE';
```

Par :
```dart
static const String _apiKey = 'sk-ant-votre-clé-ici';
```

#### Option 2 : Variables d'environnement (recommandé)

1. Installez le package `flutter_dotenv` :

```yaml
# pubspec.yaml
dependencies:
  flutter_dotenv: ^5.1.0
```

2. Créez un fichier `.env` à la racine du projet :

```bash
# .env
CLAUDE_API_KEY=sk-ant-votre-clé-ici
```

3. Ajoutez `.env` au `.gitignore` :

```
# .gitignore
.env
```

4. Modifiez `claude_chat_service.dart` :

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ClaudeChatService {
  static String get _apiKey => dotenv.env['CLAUDE_API_KEY'] ?? '';
  // ...
}
```

5. Chargez le fichier `.env` dans `main.dart` :

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const MentalityApp());
}
```

#### Option 3 : Firebase Remote Config (production recommandée)

Pour une application en production, utilisez Firebase Remote Config pour stocker la clé API de manière sécurisée.

## 💰 Tarification Claude Haiku

**Claude 3 Haiku** est le modèle le plus économique :

| Modèle | Input (MTok) | Output (MTok) |
|--------|--------------|---------------|
| Claude 3 Haiku | $0.25 | $1.25 |

**MTok** = Million de tokens

### Estimation des coûts

Conversation moyenne :
- **Input** : ~500 tokens (historique + message)
- **Output** : ~200 tokens (réponse)

**Coût par message** : ~$0.00038 (0.038 centimes)

**Pour 1000 messages** : ~$0.38

**Pour 10 000 messages** : ~$3.80

→ Très économique pour un usage normal !

## 🔧 Fonctionnalités du Chat

Le service `ClaudeChatService` gère automatiquement :

### 1. Historique de conversation
- Conserve les **10 derniers messages** pour le contexte
- Économise les tokens en limitant l'historique

### 2. Prompt système
Le prompt système définit le comportement de Mentality :
- Assistant spécialisé en psychologie cognitive
- Ton bienveillant et encourageant
- Explications claires et accessibles
- Rappelle de consulter un professionnel si nécessaire

### 3. Gestion des erreurs
- **401** : Clé API invalide
- **429** : Limite de requêtes atteinte
- **200** : Succès
- Autres : Erreurs génériques

## 🎨 Interface Utilisateur

Le chat comprend :

### Page principale (HomePage)
- **3 cartes** :
  1. "Commencer une évaluation"
  2. "Mes résultats"
  3. **"Parler avec Mentality"** ⬅️ NOUVEAU !

### Page de chat (MentalityChatPage)
- **Messages utilisateur** : Bulles bleues à droite
- **Réponses IA** : Bulles grises à gauche
- **Champ de saisie** : En bas avec bouton d'envoi
- **Indicateur de chargement** : "Mentality réfléchit..."
- **Bouton refresh** : Pour recommencer une conversation

## 🧪 Test du Chat

### Sans clé API (pour tester l'interface)

Modifiez temporairement `claude_chat_service.dart` pour retourner une réponse simulée :

```dart
Future<String> sendMessage({
  required String message,
  required List<ChatMessage> conversationHistory,
}) async {
  // Simuler un délai
  await Future.delayed(const Duration(seconds: 1));

  // Réponse simulée
  return "Ceci est une réponse simulée. Pour obtenir de vraies réponses, configurez votre clé API Claude.";
}
```

### Avec clé API

1. Configurez votre clé API (voir ci-dessus)
2. Lancez l'application
3. Cliquez sur "Parler avec Mentality"
4. Posez une question, par exemple :
   - "Que mesure la mémoire de travail ?"
   - "Comment puis-je améliorer ma mémoire de travail ?"
   - "Explique-moi le raisonnement fluide"

## 📱 Exemples de Questions

Voici des questions que les utilisateurs peuvent poser à Mentality :

### Sur les tests
- "Qu'est-ce que le test des Matrices ?"
- "À quoi sert le test de Vocabulaire ?"
- "Comment sont calculés les scores ?"

### Sur les domaines cognitifs
- "C'est quoi la Compréhension Verbale ?"
- "Quelle est la différence entre mémoire de travail et mémoire à long terme ?"
- "Pourquoi ma vitesse de traitement est importante ?"

### Conseils personnalisés
- "Comment améliorer ma mémoire ?"
- "Des exercices pour le raisonnement fluide ?"
- "Comment augmenter ma concentration ?"

### Interprétation des résultats
- "Mon score de 115, c'est bien ?"
- "Que signifie un score de 85 en vitesse de traitement ?"
- "J'ai 130 en raisonnement fluide, qu'est-ce que ça veut dire ?"

## 🔒 Sécurité et Bonnes Pratiques

### ✅ À FAIRE
- Utiliser `.env` ou Firebase Remote Config
- Ne JAMAIS commiter la clé API dans Git
- Ajouter `.env` au `.gitignore`
- Limiter l'historique de conversation (économie de tokens)
- Valider les entrées utilisateur

### ❌ NE PAS FAIRE
- Hardcoder la clé API dans le code source
- Commiter `.env` dans Git
- Partager la clé API publiquement
- Envoyer tout l'historique à chaque requête

## 🚀 Prochaines Améliorations Possibles

1. **Personnalisation** : Adapter les réponses selon les résultats réels de l'utilisateur
2. **Suggestions intelligentes** : Proposer des questions fréquentes
3. **Mode vocal** : Intégration de speech-to-text
4. **Historique persistant** : Sauvegarder les conversations avec Hive
5. **Analyses de sentiment** : Détecter le niveau de stress/anxiété
6. **Graphiques interactifs** : Visualiser les conseils donnés
7. **Partage** : Exporter les conversations en PDF

## 📞 Support

Si vous rencontrez des problèmes :

1. Vérifiez que votre clé API est valide
2. Vérifiez votre connexion Internet
3. Consultez les logs de debug
4. Vérifiez les limites de votre compte Anthropic

## 🔗 Liens Utiles

- **Console Anthropic** : https://console.anthropic.com/
- **Documentation Claude API** : https://docs.anthropic.com/
- **Tarification** : https://www.anthropic.com/pricing
- **Status API** : https://status.anthropic.com/

---

**Date** : 2026-01-20
**Version** : 1.0.0
**Auteur** : Mentality Team
