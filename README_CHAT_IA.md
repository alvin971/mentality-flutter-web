# 💬 Chat IA Mentality - Guide Rapide

## 🎯 Qu'est-ce que c'est ?

Un assistant conversationnel IA intégré à Mentality, alimenté par **Claude 3 Haiku** d'Anthropic.

## ✨ Fonctionnalités

- 💬 **Chat en temps réel** avec l'assistant IA
- 🧠 **Spécialisé** en psychologie cognitive
- 📊 **Explications** sur les résultats et domaines cognitifs
- 💡 **Conseils personnalisés** pour améliorer vos capacités
- 🔄 **Historique contextuel** pour conversations naturelles
- ⚡ **Réponses rapides** (1-3 secondes)

## 🚀 Démarrage Rapide

### 1. Installer les dépendances

```bash
flutter pub get
```

### 2. Configurer la clé API Claude

**Option A : Pour tester rapidement (dev seulement)**

Éditez `lib/features/chat/presentation/services/claude_chat_service.dart` :

```dart
static const String _apiKey = 'sk-ant-votre-clé-api-ici';
```

**Option B : Avec variables d'environnement (recommandé)**

1. Créez un fichier `.env` à la racine :
```
CLAUDE_API_KEY=sk-ant-votre-clé-api-ici
```

2. Ajoutez `flutter_dotenv` au `pubspec.yaml`
3. Suivez les instructions dans `CONFIGURATION_CHAT_IA.md`

### 3. Obtenir une clé API

1. Allez sur https://console.anthropic.com/
2. Créez un compte (gratuit)
3. Générez une clé API
4. Copiez la clé (commence par `sk-ant-`)

### 4. Lancer l'application

```bash
flutter run
```

### 5. Tester le chat

1. Sur la page d'accueil → Cliquez sur **"Parler avec Mentality"**
2. Posez une question comme "Que mesure la mémoire de travail ?"
3. Profitez ! 🎉

## 📖 Documentation Complète

- **`CHAT_IA_IMPLEMENTATION.md`** : Détails techniques de l'implémentation
- **`CONFIGURATION_CHAT_IA.md`** : Guide complet de configuration

## 💰 Tarification

**Claude 3 Haiku** est très économique :

- **~$0.00038** par message (~0.04 centimes)
- **1000 messages** : ~$0.38
- **10 000 messages** : ~$3.80

→ Parfait pour un usage personnel ou prototypes !

## 📁 Structure des Fichiers

```
lib/features/chat/
├── presentation/
│   ├── pages/
│   │   └── mentality_chat_page.dart       # Interface du chat
│   └── services/
│       └── claude_chat_service.dart       # Service API Claude
```

## 💡 Exemples de Questions

### Sur les tests
- "Qu'est-ce que le test des Matrices ?"
- "Comment fonctionne le test de Vocabulaire ?"
- "Combien de temps dure une évaluation ?"

### Sur les résultats
- "Mon score de 115, c'est bien ?"
- "Que signifie 'raisonnement fluide' ?"
- "Comment interpréter mon score en mémoire de travail ?"

### Conseils pratiques
- "Comment améliorer ma mémoire ?"
- "Des exercices pour le raisonnement logique ?"
- "Comment augmenter ma vitesse de traitement ?"

## 🎨 Aperçu de l'Interface

### Nouveau Bouton sur la Page Principale

```
┌───────────────────────────────┐
│  💬  Parler avec Mentality    │
│      Assistant IA pour vos    │
│      questions           →    │
└───────────────────────────────┘
```

### Page de Chat

- **Messages utilisateur** : Bulles bleues à droite
- **Réponses IA** : Bulles grises à gauche
- **Indicateur de frappe** : "Mentality réfléchit..."
- **Champ de saisie** : Avec bouton d'envoi gradient
- **AppBar** : Avatar Mentality + bouton refresh

## 🔧 Personnalisation

### Changer le modèle Claude

```dart
// claude_chat_service.dart
static const String _model = 'claude-3-haiku-20240307';

// Autres options :
// 'claude-3-sonnet-20240229'  → Plus performant
// 'claude-3-opus-20240229'    → Le meilleur (plus cher)
```

### Modifier le prompt système

Éditez la méthode `_getSystemPrompt()` dans `claude_chat_service.dart` pour changer le comportement de l'assistant.

### Ajuster l'historique

```dart
// claude_chat_service.dart
final recentHistory = history.length > 10  // Changer à 20, 30...
```

## ⚠️ Limitations Actuelles

- Clé API en dur (pas sécurisé pour production)
- Pas de persistance (conversations perdues à la fermeture)
- Pas de retry automatique en cas d'erreur réseau
- Historique limité à 10 messages

## 🛠️ Prochaines Améliorations

- [ ] Sécuriser la clé API (Firebase Remote Config)
- [ ] Persistance avec Hive
- [ ] Mode vocal (speech-to-text)
- [ ] Suggestions de questions
- [ ] Export PDF des conversations
- [ ] Intégration avec les résultats réels

## 📞 Besoin d'Aide ?

### Problèmes Fréquents

**"Erreur 401"**
→ Clé API invalide. Vérifiez votre clé dans `claude_chat_service.dart`

**"Erreur 429"**
→ Limite de requêtes atteinte. Attendez quelques instants.

**"Erreur de connexion"**
→ Vérifiez votre connexion Internet.

### Logs de Debug

```dart
// Les erreurs sont loggées avec debugPrint
// Activez les logs dans votre terminal : flutter run -v
```

## 🔗 Liens Utiles

- **Console Anthropic** : https://console.anthropic.com/
- **Documentation Claude** : https://docs.anthropic.com/
- **Tarification** : https://www.anthropic.com/pricing

## ✅ Checklist de Déploiement

Avant de déployer en production :

- [ ] Déplacer la clé API vers variables d'environnement
- [ ] Implémenter la persistance avec Hive
- [ ] Ajouter rate limiting
- [ ] Tester sur plusieurs appareils
- [ ] Optimiser la consommation de données
- [ ] Ajouter analytics
- [ ] Tests unitaires et d'intégration

---

**Version** : 1.0.0
**Date** : 2026-01-20
**Status** : ✅ Fonctionnel

Profitez de votre assistant IA ! 🚀
