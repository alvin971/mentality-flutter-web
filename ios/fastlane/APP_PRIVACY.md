# App Privacy — Mental E.T. (à remplir manuellement dans App Store Connect)

Section : App Store Connect → Confidentialité de l'app

Cette section NE peut pas être automatisée via l'API publique Apple.
À remplir UNE seule fois sur : https://appstoreconnect.apple.com

---

## Données collectées par Mental E.T.

### 1. Données de santé et fitness
- **Type** : Santé (scores cognitifs, profil neuropsychologique)
- **Utilisation** : Fonctionnalité de l'app
- **Liées à l'identité** : OUI (si compte professionnel de santé)
- **Utilisées pour le suivi** : NON

### 2. Données audio
- **Type** : Données audio (enregistrements oraux pour les tests de lecture)
- **Utilisation** : Fonctionnalité de l'app uniquement
- **Liées à l'identité** : NON (traitement local, non transmis)
- **Utilisées pour le suivi** : NON

### 3. Identifiants
- **Type** : Identifiant utilisateur (ID de session anonyme)
- **Utilisation** : Fonctionnalité de l'app
- **Liées à l'identité** : NON
- **Utilisées pour le suivi** : NON

### 4. Données d'utilisation
- **Type** : Interaction avec le produit (temps de réponse, progression)
- **Utilisation** : Fonctionnalité de l'app, Analytique
- **Liées à l'identité** : OUI (via compte professionnel)
- **Utilisées pour le suivi** : NON

### 5. Diagnostics
- **Type** : Données de crash, performances
- **Utilisation** : Fonctionnalité de l'app
- **Liées à l'identité** : NON
- **Utilisées pour le suivi** : NON

---

## Ce que l'app NE collecte PAS
- Coordonnées (nom, email, téléphone, adresse)
- Données financières
- Localisation
- Contacts
- Historique de navigation
- Historique de recherche
- Données publicitaires (IDFA : NON utilisé)

---

## Étiquette de confidentialité résultante
L'app devrait afficher : **Données liées à vous** (santé, utilisation) + **Données non liées à vous** (diagnostics)

---

## Marche à suivre dans App Store Connect
1. Aller sur https://appstoreconnect.apple.com
2. Sélectionner l'app Mental E.T.
3. Menu gauche → Confidentialité de l'app
4. Cliquer "Commencer"
5. Répondre OUI aux catégories listées ci-dessus
6. Répondre NON à tout le reste
7. Enregistrer
