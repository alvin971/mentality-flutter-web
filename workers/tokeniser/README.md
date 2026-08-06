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
  claim `d`, suffit). Seul état serveur depuis le LOT 0 anti-faux-test : un
  **compteur agrégé** d'émissions par tranche de temps (clé KV `issue:<n°>`, un
  entier, TTL court) — ni IP, ni claims, ni token, rien de rattachable à
  quiconque.
- **CORS ≠ contrôle d'accès** : le volume d'émission est plafonné par le
  compteur agrégé ci-dessus (429 au-delà de `ISSUE_MAX_PER_WINDOW` par fenêtre
  de `ISSUE_WINDOW_MINUTES` ; approximatif — KV sans incrément atomique). Le
  rate-limiting edge de Cloudflare reste une option complémentaire (distincte
  du no-log applicatif).
