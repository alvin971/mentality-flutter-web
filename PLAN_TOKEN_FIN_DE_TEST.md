# Plan — Token anonyme généré en fin de test (version simplifiée)

- **Date :** 2026-06-13
- **Remplace** : `PLAN_TOKENS_ANONYMES.md` (archi téléphone + Blind RSA), devenu inutile depuis que l'anti-multicompte n'est plus une exigence.
- **Décision fondatrice** : on accepte qu'un individu puisse refaire le test plusieurs fois. Du coup : **pas de vérification téléphone, pas de blocklist, pas de seconde base, pas de crypto aveugle.**

## Objectif & garantie d'anonymat

> À la fin du test de QI, on génère un token pour l'utilisateur et on lui demande **explicitement de le sauvegarder** (aucune récupération possible s'il le perd). Le token encode uniquement des données démographiques **larges**, signées par notre clé. Comme il n'y a **ni téléphone, ni identité, ni seconde base**, il n'existe **aucun lien à casser** : l'anonymat est garanti par construction.

## Données collectées (et leur granularité = le seul garde-fou)

| Donnée | Granularité retenue | Pourquoi |
|---|---|---|
| **Sexe** | H / F / ne préfère pas dire | OK |
| **Naissance** | **mois + année** (PAS le jour) | utile pour les normes de QI calées sur l'âge ; le jour serait un quasi-identifiant |
| **Région** | **région / département** (PAS code postal ni commune) | la combo {naissance précise, sexe, lieu précis} est le cas d'école de ré-identification |
| **Date d'inscription** | **le jour** (PAS l'heure/seconde) | l'instant précis de fin de test redeviendrait un quasi-identifiant |

**Règle d'or :** plus l'âge est précis, plus la région doit être large. mois/année + sexe + **région large** = anonyme. mois/année + **commune** = risque.

## Le token

- Contenu (claims compactes, `sv: 2`) : `{ s: sexe, y: annee_naissance, m: mois_naissance, r: region, d: jour_inscription (jours depuis epoch), n: nonce, sv }` — rien de secret. Clés raccourcies volontairement (le token doit rester court à copier/coller) — voir `lib/core/services/token_issuer.dart` (source de vérité côté client) et `workers/tokeniser/index.js` (miroir côté serveur).
- **Signé**, pas chiffré : une signature (clé privée côté serveur) empêche de fabriquer de faux tokens ; le contenu peut rester en clair (ex. JSON base64url + signature). **Ne PAS chiffrer avec « une clé que moi seul possède »** — ça ferait de nous le détenteur d'un profil ré-identifiable, ce qui contredit l'anonymat.
- **Immuable** : le token émis au début ne change JAMAIS, y compris à la fin du test. La complétion du test est enregistrée uniquement côté serveur (marqueur R2 `validated/<account>`, `account = SHA-256(nonce)`) — `POST /validate` vérifie une preuve de complétion et pose ce marqueur, il ne re-signe rien.
- Vérifiable hors-ligne via la clé **publique** au moment de l'usage.
- Persisté côté client (Hive AES-256, déjà en place via `AuthLocalStore`).

## Ce qu'on supprime de l'ancien plan

- ❌ Vérification OTP (email + SMS) → plus de Worker `otp-eu`, plus de provider SMS.
- ❌ Blocklist `verified_contacts` + HMAC + pepper.
- ❌ Signature aveugle Blind RSA, `pointycastle`, découplage temporel, double-instance.
- ❌ Toute la mécanique anti-corrélation (devenue sans objet).
- ✅ On garde : génération + **signature** du token, persistance locale chiffrée, et le discours « sauvegarde ton token, pas de récupération ».

## Étapes d'implémentation

1. **Modèle démographique** : formulaire fin de test → sexe, mois/année de naissance, région (liste de régions, pas de saisie libre d'adresse). Buckétiser à la source.
2. **Tokeniseur (serveur, Worker Cloudflare existant)** : reçoit les démographiques → construit le payload → **signe** (Ed25519 ou RSA) → renvoie le token. Clé privée en Worker Secret, clé publique pinnée côté client.
3. **Écran « sauvegarde ton token »** : afficher le token + bouton copier/télécharger + avertissement clair (perte = définitive). i18n FR/EN.
4. **Persistance client** : stocker via `AuthLocalStore` (déjà chiffré AES-256).
5. **Usage** : à chaque envoi de données (audio, etc.), joindre le token signé ; le serveur vérifie la signature avant d'accepter.
6. **RGPD** : données démographiques larges = faible risque, mais **vérifier la k-anonymité** des combos {sexe, mois/année, région} sur la population attendue (généraliser la région si une combo est trop rare). Mettre à jour la politique de confidentialité (plus de téléphone, données anonymes/larges) — beaucoup plus simple que l'ancienne version.

## Points de vigilance

- Granularité (cf. tableau) = la seule défense, à respecter strictement.
- Signer ≠ chiffrer.
- k-anonymité à vérifier au lancement (faible trafic) sur les combos démographiques.
- Tokens factices : la signature les bloque ; les doublons sont acceptés par choix.
