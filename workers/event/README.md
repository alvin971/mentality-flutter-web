# Worker `mentality-event`

Reçoit les réponses des questionnaires de l'**événement d'attente des 8 jours**
et les écrit dans Cloudflare R2 (juridiction EU). Le client n'a **jamais** de
clé R2. Le worker n'expose **aucune lecture** : c'est une boîte aux lettres.

## Pourquoi un worker séparé de `r2-upload`

Ce ne sont ni les mêmes données ni la même base légale. L'audio relève du
consentement d'enregistrement ; ces réponses-ci sont des **données de santé**
(art. 9 RGPD). Un bucket distinct rend l'effacement et l'export séparables, et
permet à la garde de consentement d'exiger la **finalité exacte** au lieu d'un
consentement quelconque.

## Contrat

```
POST /responses
  X-Mentality-Token   passe anonyme SIGNÉ (Ed25519) — obligatoire
  X-Consent-Version   version du texte accepté (preuve, art. 7)
  X-Consent-Purpose   doit valoir exactement « event-health-research »
  Content-Type: application/json

  { "schema": 1, "moduleId": "j1_personality", "day": 1,
    "kind": "announced" | "contribution", "partial": false,
    "locale": "fr", "answers": { "<itemId>": <entier>, … } }
```

| Statut | Sens | Ce que fait le client |
|---|---|---|
| `200` | écrit | oublie la copie locale en attente |
| `400` / `413` | charge utile refusée définitivement | **cesse** de rejouer, garde la trace du refus |
| `401` | passe absent, non signé ou mal signé | **garde et rejoue** (un passe signé fera aboutir le même envoi) |
| `403` | origine, consentement ou finalité manquants | **garde et rejoue** (le consentement peut être accordé ensuite) |
| `404` / `405` | route ou méthode | **garde et rejoue** — une erreur de route est un défaut de *déploiement*, pas un vice de la donnée |
| `500` / `502` | binding absent, R2 en panne | garde et rejoue |

Seuls les statuts qui condamnent la **charge utile** sont définitifs. Tout ce qui
dépend du contexte (passe, consentement, déploiement, réseau) est réessayé : le
jour d'un mauvais déploiement, personne ne doit perdre ses réponses.

Le détail de cette table vit côté client dans
`lib/features/waiting_event/_shared/data/event_upload_service.dart`.

## Authentification : signature exigée, sans filet

Le patron est celui de `r2-upload` (`verifyToken` puis 401), **pas** celui de
`referral` — ce dernier accepte volontairement les passes DEV non signés
« `M2.<claims>` » parce qu'il ne garde qu'un compteur de parrainage. Ici,
accepter un nonce non signé laisserait n'importe qui écrire des réponses de
santé dans le compartiment d'autrui, ou polluer le jeu de données servant à
construire nos échelles.

**Conséquence opérationnelle** : tant qu'un utilisateur porte un passe non
signé (`AppConstants.kAllowUnsignedTokenInRelease`), ses réponses **restent sur
son appareil**, chiffrées, et le rejeu attend. Rien n'est perdu, rien n'est
envoyé sans preuve d'appartenance. Le selftest vérifie ce refus explicitement.

## Organisation des clés R2

```
responses/<account>/<moduleId>/<uuid>.json
```

- `account` = `SHA-256(nonce signé)[:32]` — partition dérivée du passe,
  **jamais** d'un identifiant choisi par le client (un `account` glissé dans le
  corps est ignoré ; le selftest le vérifie).
- `uuid`, **jamais un horodatage** : l'instant précis d'un envoi de santé serait
  un quasi-identifiant.
- `customMetadata` : `account`, `module_id`, `day`, `kind`, `partial`,
  `item_count`, `locale`, `consent_version`, `consent_purpose`, et
  `received_day` — la **date seule**, jamais l'heure.

### Doublons : assumés, pas subis

Le client rejoue jusqu'à confirmation. Une confirmation perdue en route produit
donc un second objet au contenu identique. Écraser une clé déterministe
éviterait ce doublon mais ferait perdre l'historique partiel → complet. On
préfère deux objets identiques (dédoublonnables à l'analyse) à une donnée
écrasée.

**Le jeu final d'un module est celui dont `partial` vaut `false`** ; à défaut,
celui dont `item_count` est le plus grand.

## Déploiement

```bash
wrangler r2 bucket create mentality-event --jurisdiction eu
```

```bash
node workers/event/scripts/selftest.mjs
```

```bash
cd workers/event && wrangler deploy
```

Puis reporter l'URL affichée dans `lib/core/constants/app_constants.dart` →
`eventWorkerUrl`, et ajouter le domaine Pages de l'app dans `ALLOWED_ORIGINS`
(`index.js`) si besoin.

Tant que `eventWorkerUrl` reste le placeholder (`YOUR_SUBDOMAIN`), l'app
**fonctionne normalement** : les questionnaires se passent, le score s'affiche,
les réponses restent en local (chiffrées) et rien n'est envoyé.

### Vérifier que le bucket est bien en EU

```bash
wrangler r2 bucket list --jurisdiction eu
```

Il doit lister `mentality-event` ; `wrangler r2 bucket list` (sans le flag) ne
doit **pas** le lister. La juridiction est figée **à la création** : un bucket
créé sans le flag doit être recréé.

## RGPD — opérations courantes

**Droit à l'effacement (art. 17)** — tout ce qu'un passe a envoyé :

```bash
wrangler r2 object delete mentality-event --jurisdiction eu --prefix "responses/<account>/"
```

**Droit à la portabilité (art. 20)** :

```bash
rclone copy r2:mentality-event/responses/<account>/ ./export/<account>/
```

**Ce qui n'est PAS dans ce bucket** : les jeux (locaux ; seuls des agrégats
remonteront, LOT H), les révélations et les scores (calculés sur l'appareil),
et tout horodatage plus fin que la journée.

## Pas de cron de purge

Contrairement à `r2-upload`, ce worker n'a pas de `scheduled()`. Celui de
`r2-upload` s'appuie sur le marqueur `validated/<account>` écrit par le
tokeniser dans le bucket **audio**, marqueur qui n'existe pas ici. Et
l'événement ne s'ouvre qu'au palier 3, donc **après** un test complet : il n'y a
pas de compte provisoire abandonné à nettoyer. Une politique de rétention propre
à ces données reste à décider — elle relève de la page Méthodologie, pas du
code.

## Auto-test

```bash
node workers/event/scripts/selftest.mjs
```

64 vérifications, sans réseau ni compte Cloudflare : le worker est importé tel
quel et branché sur un bucket R2 en mémoire. **À lancer avant chaque
`wrangler deploy`.** Le selftest forge un vrai couple de clés Ed25519 et signe
un vrai passe — la vérification exercée est donc celle de production, et le
refus du passe non signé est lui-même une vérification.
