# Worker `mentality-tokeniser` — signature Ed25519 du token anonyme

Signe les claims démographiques larges en **JWS compact EdDSA** :
`header_b64url . payload_b64url . signature_b64url`.

La clé privée ne quitte jamais le Worker (Secret, `extractable=false`). Le client
ne reçoit que la signature et vérifie avec la **clé publique pinnée**.

Voir `PLAN_TOKEN_FIN_DE_TEST.md` à la racine du repo.

---

## 1. Générer le keypair Ed25519 (hors-ligne, une seule fois)

> ⚠️ À faire sur une machine de confiance, **dans un dossier HORS du repo**
> (ex. `~/.secrets/`). Ne JAMAIS committer `.pem`/`.der`/le base64 de la privée.

```bash
openssl genpkey -algorithm ed25519 -out priv.pem
openssl pkey -in priv.pem -outform DER -out priv.der            # PKCS#8, 48 octets
openssl pkey -in priv.pem -pubout -outform DER -out pub.der     # SPKI, 44 octets

# SECRET Worker (base64 du DER PKCS#8) :
base64 -w0 priv.der

# Clé PUBLIQUE raw 32o en base64url (pinning client) :
tail -c 32 pub.der | base64 -w0 | tr '+/' '-_' | tr -d '='
```

`tail -c 32` jette les 12 octets d'en-tête ASN.1 du SPKI → il reste la clé
publique brute (32 octets).

## 2. Configurer le secret + déployer

```bash
cd workers/tokeniser
wrangler secret put ED25519_PRIVATE_KEY_B64    # coller le base64 du DER PKCS#8
wrangler deploy
```

> Préférer la saisie **interactive** de `wrangler secret put` (ne pas piper le
> base64, qui resterait dans l'historique shell).

### ⚠️ Déployabilité permanente — les deux bindings sont COMMENTÉS

Ce worker sert l'inscription **live** de mental-et.com : il doit rester
déployable à tout moment. Or `wrangler deploy` **refuse de publier** si un
binding pointe vers une ressource inexistante. Au 2026-09-02, ni le bucket R2 ni
le namespace KV n'existent sur le compte :

| Binding | État | Constat |
|---|---|---|
| `AUDIO_BUCKET` (R2 `mentality-audio`) | **commenté** | R2 est désactivé sur le compte — `wrangler r2 bucket list` renvoie l'erreur API **10042** « Please enable R2 through the Cloudflare Dashboard » |
| `RATE_KV` (KV) | **commenté** | `wrangler kv namespace list` ne renvoie que `BOARD_DATA` et `REFERRAL_KV` ; l'`id` du toml était une chaîne littérale, pas un identifiant |

La **procédure d'activation numérotée** de chacun est dans `wrangler.toml`,
juste au-dessus du bloc commenté correspondant.

> ⚠️ `wrangler deploy --dry-run` **ne détecte pas** ce problème : il ne fait que
> bundler le code, sans jamais interroger l'API Cloudflare. Un dry-run vert ne
> prouve **rien** sur l'existence des ressources. Les seules vérifications
> réelles sont `wrangler kv namespace list` et `wrangler r2 bucket list` — plus
> la section « Configuration déployable » de `scripts/selftest.mjs`, qui relit le
> toml et échoue si un binding sans ressource y redevient actif.

**Le code est correct dans les deux états**, et c'est verrouillé par le selftest
(section « État DÉPLOYÉ ») :

- sans `RATE_KV` → `checkIssueCap` et `bumpConsentCounter` sortent immédiatement
  (fail-open) : l'émission des passes sv 2 **et** sv 3 fonctionne normalement ;
- sans `AUDIO_BUCKET` → `POST /validate` répond un **500 explicite** (« Bucket R2
  non lié ») : seule la confirmation de complétion est indisponible.

Deux conséquences assumées tant que `RATE_KV` n'est pas lié : le **plafond
d'émission ne s'applique pas** (voir plus bas) et l'**archive des textes légaux
ne peut pas être publiée** (§6 — `publish-legal.mjs` exige ce binding).

## 3. Brancher le client

Dans `lib/core/constants/app_constants.dart` :
- `tokeniserWorkerUrl` = URL réelle du Worker déployé (remplacer `YOUR_SUBDOMAIN`).
- `tokenSigningPublicKeys['k1']` = la clé publique base64url (étape 1).

Ajouter le domaine Pages de prod à `ALLOWED_ORIGINS` dans `index.js` si différent.

## 4. Vérifier l'interop crypto (BLOQUANT)

Le test Dart `test/token_signature_verifier_test.dart` valide la vérification
côté client. **Après déploiement**, valider aussi le chemin V8→Dart : émettre un
token via l'URL déployée et confirmer qu'il passe `verifyAndDecode` côté client
(un `importKey('pkcs8')` silencieusement cassé ou un mismatch clé privée/publique
ne se voit qu'ainsi).

```bash
# Émission du token (immuable, début de parcours, « se connecter ») :
curl -s -X POST "$URL/" -H 'Content-Type: application/json' \
  -d '{"s":"M","y":1998,"m":7,"r":"IDF"}'
# → {"token":"<3 segments, claims compactes s/y/m/r/d/n/sv>"}  (d = jour, calculé côté serveur)

# Confirmation de complétion à la soumission du test — NE re-signe rien, le
# client garde le MÊME token :
curl -s -X POST "$URL/validate" -H 'Content-Type: application/json' \
  -d '{"token":"<le token émis au début>"}'
# → {"ok":true}
```

---

## 5. Plan Gratuit / Payant — token `sv 3`

Le passe peut porter le **plan choisi sur le site** et la **preuve de
consentement au corpus vocal**. C'est la contrepartie du passe Gratuit : le
bilan ne coûte rien, l'enregistrement vocal rejoint un corpus cessible ; le
passe Payant donne le même bilan sans aucun enregistrement.

| `sv` | Claims | Émis quand |
|---|---|---|
| **2** | `{s, y, m, r, d, n, sv}` | le corps **n'a aucun** champ de plan (`p`/`cc`/`cv`) |
| **3** | `{s, y, m, r, p, cc, cv, d, n, sv}` | le corps porte un plan valide |

- `p` : `"free"` ou `"paid"` — allow-list fermée.
- `cc` : booléen, consentement au corpus vocal.
- `cv` : version des textes légaux acceptés, ∈ `LEGAL_VERSIONS`.

> ⚠️ **Invariant de production.** Un corps `{s,y,m,r}` sans `p` produit
> exactement le token `sv 2` d'avant — mêmes clés, même ordre. L'inscription
> live de `mental-et.com` continue de fonctionner sans que le site change, et
> un selftest épingle cet invariant (« corps sans `p` → payload sv 2 EXACT »).

Ces trois claims sont **signées** : côté serveur (`r2-upload`) elles font
autorité, jamais un en-tête client. Lecture confortable : `readPlan()` de
`workers/_shared/token_plan.js`.

### Interrupteur `PAID_PLAN_ENABLED`

Var wrangler. **Seule la chaîne `"true"`** ouvre le plan payant ; absente, vide,
`"TRUE"` ou `"1"` → fermé (**défaut fermé assumé** : une var oubliée ne doit pas
ouvrir la vente). À basculer **en même temps** que `SITE.plans.paidEnabled` côté
site Astro : tant qu'il n'existe pas d'alternative payante réelle, le
consentement au corpus ne serait pas « libre » (RGPD art. 7(4)) et reste donc
**facultatif**.

| Entrée | `"false"` (aujourd'hui) | `"true"` (jour de Stripe) | `code` |
|---|---|---|---|
| pas de `p` (ni `cc`/`cv`) | `sv 2` | `sv 2` | — |
| `cc` ou `cv` sans `p` | 400 | 400 | `PLAN_REQUIRED` |
| `p=free, cc=true` | 200 `sv 3` | 200 `sv 3` | — |
| `p=free, cc=false` | 200 `sv 3` (facultatif) | **400** | `CONSENT_REQUIRED` |
| `p=paid, cc=false` | **403** | 200 `sv 3` | `PAID_PLAN_DISABLED` |
| `p=paid, cc=true` | 400 | 400 | `PLAN_INCONSISTENT` |
| `cv` absente / ∉ `LEGAL_VERSIONS` | 400 | 400 | `LEGAL_VERSION_UNKNOWN` |
| `LEGAL_VERSIONS` non configurée | 500 | 500 | `SERVER_MISCONFIGURED` |
| `p=free, cc=true`, âge < 15 | 400 | 400 | `AGE_CONSENT` |

Toute erreur de plan renvoie **`{error, code}`** : le site discrimine sur `code`,
le statut seul ne suffirait pas — **403 signifie déjà « Origin non autorisée »**
dans ce worker.

**Formule d'âge, identique site et serveur** (UTC, mois de naissance en cours
compté comme **non révolu**, le jour n'étant pas collecté) :

```
age = Y − y − (m ≥ M ? 1 : 0)      // Y, M = année et mois courants UTC
```

Cas d'école : `y=2011, m=9` en septembre 2026 → **14**. Un écart entre les deux
implémentations ferait afficher « tu peux cocher » à quelqu'un que le serveur
refusera ensuite.

```bash
# Passe Gratuit avec consentement au corpus → sv 3
curl -s -X POST "$URL/" -H 'Origin: https://mental-et.com' -H 'Content-Type: application/json' \
  -d '{"s":"M","y":1998,"m":7,"r":"IDF","p":"free","cc":true,"cv":"2026-09-02.v1"}'

# Passe Payant tant que l'interrupteur est fermé → 403 PAID_PLAN_DISABLED
curl -s -X POST "$URL/" -H 'Origin: https://mental-et.com' -H 'Content-Type: application/json' \
  -d '{"s":"M","y":1998,"m":7,"r":"IDF","p":"paid","cc":false,"cv":"2026-09-02.v1"}'
```

**Stripe (plus tard, hors périmètre).** Un point d'accroche `checkPaidProof` est
commenté dans `validatePlan()` : la preuve de paiement sera exigée **avant** de
rendre le plan, jamais après — un passe payant ne doit pas être signé sans
paiement constaté.

## 6. Archive des textes légaux (`scripts/publish-legal.mjs`)

Le `cv` signé dans le token dit « la personne a accepté la version X ». Sans le
texte de X, cette claim ne prouve rien. Les textes exportés par le site
(`scripts/export-legal.mjs` → `legal/<cv>/{cgu,confidentialite,consent-corpus}.md`
+ `sha256.json`) sont donc archivés en KV :

> ⚠️ **Prérequis bloquant** : ce script passe par `wrangler kv key put --binding
> RATE_KV`. Il est donc **impossible à exécuter** tant que le binding `RATE_KV`
> reste commenté dans `wrangler.toml` (namespace inexistant, cf. §2). Créer le
> namespace et décommenter le binding est un **préalable** à toute publication
> de textes légaux.

```bash
export CLOUDFLARE_API_TOKEN=…
node workers/tokeniser/scripts/publish-legal.mjs \
  --dir ~/projects/web-site-maker/clients/mental-et/legal/2026-09-02.v1

# Contrôle
npx --yes wrangler@latest kv key list --binding RATE_KV --remote --prefix legal:2026-09-02.v1:
npx --yes wrangler@latest kv key get  --binding RATE_KV --remote legal:2026-09-02.v1:sha256
```

Le script **refuse** de publier si un `.md` ne correspond pas à son empreinte
dans `sha256.json` (texte retouché après l'export), et **refuse d'écraser** une
version déjà présente en KV sans `--force` : un texte qui change appelle un
**nouveau** numéro de version (bump de `LEGAL_VERSION` côté site **et** de
`LEGAL_VERSIONS` dans `wrangler.toml`), jamais un écrasement — réécrire
l'archive d'un consentement déjà donné le viderait de sa valeur probante
(RGPD art. 7(1)). Le contenu poussé est strictement **public** (ce sont les
pages du site) : aucune donnée personnelle n'entre en KV par ce chemin.

## `GET /geo` — suggestion de région (pré-remplissage)

```bash
curl -s "$URL/geo"   # → {"region":"IDF"|...|"OTHER"|null,"country":"FR"|...}
```

Déduit une région large depuis la **géo-IP Cloudflare** (`request.cf.regionCode` /
`region`, mappés sur l'allow-list ; hors France → `OTHER`). **Aucune permission,
aucune coordonnée, IP ni stockée ni loggée** — simple indice corrigeable côté
client (le menu reste modifiable). ⚠️ Vérifier au déploiement les valeurs réelles
de `request.cf.regionCode` pour la France (la donnée Cloudflare peut varier).

## Cycle de vie du token (immuable)

- `POST /` → émet le token : émis une fois au début, **ne change jamais
  ensuite**.
- `POST /validate` → **ne re-signe pas le token**. Vérifie une preuve de
  complétion (le worker vérifie dans R2, binding `AUDIO_BUCKET`, qu'au moins
  `MIN_RECORDINGS` enregistrements existent sous le compte `H(nonce)` — sinon
  400) puis écrit un marqueur `validated/<account>` (utilisé par le cron de
  nettoyage de r2-upload) et renvoie `{ok:true}`. Idempotent : rejouer l'appel
  écrase silencieusement le même marqueur.

  L'état « test complété » vit donc **uniquement côté serveur** (ce marqueur
  R2), jamais dans le token — le client n'a rien à re-persister après
  `/validate`.

  ⚠️ Le tokeniseur a donc besoin du **même bucket R2 que r2-upload** (voir
  `wrangler.toml`, binding `AUDIO_BUCKET`, `jurisdiction = "eu"`). `MIN_RECORDINGS`
  est un seuil de qualité (uploads best-effort → garder bas, ajustable via `[vars]`).

  ⚠️ **Aujourd'hui ce binding est commenté** (R2 désactivé sur le compte, §2) :
  `POST /validate` répond donc un **500 « Bucket R2 non lié »**. C'est délibéré
  et non bloquant pour l'inscription — l'émission du passe, elle, n'a jamais eu
  besoin de R2. La confirmation de complétion redeviendra fonctionnelle en
  suivant la procédure d'activation du `wrangler.toml`.

---

## Rotation de clé (`kid`)

`KID` (index.js) identifie la clé active. Pour tourner : ajouter la nouvelle clé
publique (`k2`) au trousseau client **avant** de passer `KID` à `k2`.

⚠️ **Honnêteté sur la compromission** : comme les tokens **n'expirent jamais** et
ne sont **pas révocables** (le token est l'unique accès permanent aux données),
une **fuite de la clé privée est catastrophique et irréversible** : la rotation
vers `k2` n'invalide pas les tokens forgés avec `k1` tant que `k1` reste dans le
trousseau client. La seule réponse réelle à une fuite = retirer `k1` du trousseau
(invalide TOUS les tokens k1, légitimes inclus) — sans canal de ré-émission, cela
équivaut à un reset. À assumer par écrit dans la politique de confidentialité.

## Garanties & limites (à documenter dans la politique)

- **Signature** = authenticité d'émission (anti-forge). N'est un **contrôle
  d'accès** que si un serveur **re-vérifie** la signature au moment de servir les
  données (à construire). La vérif côté client est un sanity-check de config.
- **Identifiant d'accès = le `nonce`** (128 bits, claim `n`, dans les octets
  signés), jamais la chaîne token complète ni la signature (malléabilité Ed25519).
- **Bearer token** : qui le détient y accède. Pas de révocation sans état serveur.
  Perte = définitive, vol = accès. Défense : entropie 128 bits (toujours
  cryptographiquement massive comme identifiant, pas un secret) + Hive AES-256 + HTTPS.
- **Anonymat / no-log** : aucun log par requête (IP/timestamp/claims/token),
  aucun stockage **par utilisateur**, aucun `iat` précis (le jour d'inscription,
  claim `d`, suffit). Tout l'état serveur tient dans **trois familles de clés
  KV** (namespace `RATE_KV`), toutes agrégées ou publiques :

  | Clé | Contenu | TTL | Rattachable à quelqu'un ? |
  |---|---|---|---|
  | `issue:<n° de tranche>` | compteur d'émissions par tranche de temps (LOT 0 anti-faux-test) — écrit dès que `RATE_KV` est lié, y compris quand le plafond est éteint | court | non — un entier |
  | `consent:<cv>:<p>:<cc>:<jour UTC>:<shard 0-15>` | compteur d'émissions par version de textes × plan × consentement : la **preuve agrégée** du recueil (RGPD art. 7(1)) | **aucun** — une preuve ne s'auto-détruit pas | non — un entier ; deux personnes du même jour, même plan, même version y sont indiscernables |
  | `legal:<cv>:{cgu,confidentialite,consent-corpus,sha256}` | archive des **textes** acceptés, poussée par `scripts/publish-legal.mjs` | aucun | non — contenu strictement public |

  Ni IP, ni claims individuelles, ni token, ni nonce nulle part. Le **shard**
  (1 octet aléatoire `& 15`) répartit les écritures `consent:` sur 16 clés pour
  contourner la limite Cloudflare d'« une écriture par seconde et par clé » ;
  la lecture somme le préfixe (`kv key list --prefix consent:<cv>:`).
  L'incrément `consent:` est **fail-open** comme `issue:` : il a lieu **après**
  une signature réussie, et un KV en panne ne transforme jamais un passe déjà
  signé en erreur (le prix assumé est un sous-comptage).
- **CORS ≠ contrôle d'accès** : le volume d'émission *peut* être plafonné par le
  compteur agrégé ci-dessus (429 au-delà de `ISSUE_MAX_PER_WINDOW` par fenêtre
  de `ISSUE_WINDOW_MINUTES` ; approximatif — KV sans incrément atomique).

  ⚠️ **À ce jour ce plafond ne tourne PAS**, et il faut le dire tel quel : le
  binding `RATE_KV` est commenté (§2), donc `checkIssueCap` court-circuite. Le
  volume d'émission n'est aujourd'hui limité par **rien** côté applicatif.

  Le rallumer demande **deux gestes distincts et volontairement séparés** :

  1. **lier `RATE_KV`** → le compteur `issue:` se met à écrire, sans jamais
     refuser. C'est la phase d'**observation** : on découvre le volume réel.
     Lecture : `wrangler kv key list --binding RATE_KV --remote --prefix issue:`
  2. **passer `ISSUE_CAP_ENABLED = "true"`** dans `[vars]` → le 429 s'applique,
     après avoir ajusté `ISSUE_MAX_PER_WINDOW` sur le volume constaté.

  Pourquoi les séparer : `checkIssueCap` **n'a jamais tourné en production**.
  Lier le namespace sans cet interrupteur allumerait d'un coup un seuil jamais
  éprouvé (300/heure, une valeur devinée) sur tout le trafic, chemin sv 2
  historique compris — des 429 sur l'inscription live à la clé. Seule la chaîne
  exacte `"true"` allume (`"TRUE"`, `"1"`, vide ou absente → éteint) ; défaut
  **ouvert** assumé, à l'inverse de `PAID_PLAN_ENABLED` dont le défaut est fermé.

  Le rate-limiting edge de Cloudflare reste une option complémentaire (distincte
  du no-log applicatif).
