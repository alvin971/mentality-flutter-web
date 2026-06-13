> ⚠️ **OBSOLÈTE (2026-06-13)** — Remplacé par [`PLAN_TOKEN_FIN_DE_TEST.md`](PLAN_TOKEN_FIN_DE_TEST.md). Cette archi (vérification téléphone + Blind RSA + blocklist) répondait à l'exigence « 1 humain = 1 token ». Cette exigence a été **abandonnée** (les doublons sont acceptés), rendant tout ce dispositif inutile. Conservé pour référence historique uniquement.

# Plan d'implémentation durci — Système de tokens anonymes vérifiés par téléphone (Mentality)

> **Version finale durcie** — intègre les mitigations des quatre revues adversariales (métadonnées/corrélation, faisabilité, crypto/soundness, RGPD/abus). Architecture **HYBRIDE** : blocklist HMAC+pepper (anti-réutilisation) + token client-fabriqué par **signature aveugle Blind RSA (RFC 9474, Privacy Pass type `0x0002`)** + OTP EU. Livraison **incrémentale** avec portes de décision.

- **Date :** 2026-06-13
- **Objectif :** permettre une inscription anti-multicompte (un humain = un token) **sans jamais pouvoir relier un numéro de téléphone à un token**, tout en restant juridiquement défendable (RGPD, données de santé mentale) et résistant à la fraude (Sybil, SMS-pumping).

## Garantie d'anonymat (une phrase, honnête et bornée)

> **Au-dessus d'un seuil de trafic `k_min` (voir §4) et sous réserve que les surfaces de jointure résiduelles soient neutralisées (auth.users, logs IP/timestamp, sessionId R2, backups/WAL), un observateur disposant des bases applicatives ne peut relier un numéro de téléphone à un token, parce que (a) le numéro n'existe en base que sous forme `HMAC-SHA256(pepper_hors_infra-DB, E164_canonique)`, (b) le token est généré et débindé côté client — le serveur ne le voit jamais à l'émission (blindness RFC 9474), (c) aucune colonne/FK/horodatage fin/ordre d'insertion ne relie les bases, et (d) les claims démographiques fins (code postal) sont sortis du token.** Contre un **administrateur d'infrastructure de l'instance Supabase unique** (superuser Postgres / `SERVICE_ROLE_KEY` / accès WAL+backups), cette garantie **n'est PAS atteinte tant que la double-instance §3.5 n'est pas déployée** — c'est explicitement hors périmètre couvert dans ce cas (voir §11).

---

## 0. Ce que la revue a changé par rapport au brouillon (résumé exécutif)

Le brouillon investissait dans la crypto (Blind RSA) mais laissait **cinq fenêtres ouvertes** qui annulaient la garantie. Le plan final les neutralise **avant** d'engager le poste coûteux :

1. **`auth.users` (Supabase Auth) liait email + téléphone EN CLAIR** avec 5 timestamps microseconde sur une seule ligne jamais effacée → nouvelle **Phase 1 « Neutralisation auth.users »**, prioritaire sur tout le reste.
2. **Les logs IP/timestamp (Cloudflare, GoTrue `auth.audit_log_entries`, Postgres) court-circuitaient la blindness** → politique **no-log / no-IP** durcie + randomisation du délai inter-phase.
3. **Le code postal dans le token (`postal_hash` SHA-256[:8]) était un quasi-identifiant ré-identifiant ET non attestable** → sorti du token, généralisé en zone à `k≥k_min`.
4. **L'`otpProof` n'était pas spécifié** → sans usage-unique lié à `H(blindedMsg)`, la one-more-unforgeability était vide (tokens illimités par numéro) → spécification complète §5.
5. **La séparation des rôles était du théâtre sur instance unique** → décision §3.5 tranchée (double-instance) ou garantie honnêtement rétrogradée.

S'y ajoutent : canonicalisation E.164/email réelle (anti-Sybil), pepper hors infra-DB, redemption atomique + token à usage unique avec expiration grossière, et la **réécriture de la politique de confidentialité + LIA + DPIA comme livrables bloquants** avant d'activer le gate.

---

## 1. Modèle de menace & garanties

### Surfaces à protéger (toutes les bases hostiles, pas seulement les deux applicatives)

| Base / canal | Contenu sensible | Statut dans le brouillon | Traitement final |
|---|---|---|---|
| `verified_contacts` | numéro/email | traité (HMAC) | HMAC+pepper, pepper hors infra-DB |
| `issued_tokens` | empreinte token | traité | SHA-256(nonce), write-at-redemption |
| **`auth.users` (GoTrue)** | **email + phone EN CLAIR + 5 TIMESTAMPTZ µs** | **JAMAIS mentionné** | **Phase 1 : supprimé/remplacé (voir §3.1)** |
| **`auth.audit_log_entries` (GoTrue)** | **email + IP + timestamp µs par OTP** | **JAMAIS mentionné** | **Phase 1 : purge/désactivation** |
| **Logs Cloudflare** (Logpush, Trace Events) | **IP + timestamp µs + headers** | ignoré | **no-log explicite sur tous les Workers** |
| **Logs Postgres / pgAudit** | valeurs de requêtes (`WHERE contact_hmac=…`) | ignoré | `log_statement=none`, pas de pgAudit sur ces tables |
| **WAL / PITR / backups** | ordre + instant µs d'INSERT, `ctid` | ignoré | double-instance (§3.5) + backups chiffrés par clé séparée |
| **Clés objet R2 + customMetadata** | `sessionId` + `uploaded_at` ISO µs | ignoré | UUID aléatoire, granularité DATE, séparation upload/redemption |
| **Logs provider OTP** | numéro E164 + timestamp + IP | ignoré | contrat (no-IP, rétention courte), proof sans identifiant du numéro |
| **Pepper** | clé de réversibilité du HMAC | sur même infra | **hors instance Supabase** (KMS/HSM EU ou Worker Secret isolé) |

### Adversaires & défenses

| Adversaire | Capacité | Notre défense | Garantie |
|---|---|---|---|
| **Fuite de base à froid (dump SQL / backup)** | Lit les tables sans le pepper | HMAC+pepper (pepper hors infra-DB) ; token = signature non liée | **Tenue** |
| **Insider applicatif mono-rôle** | Lit UNE table via un credential Edge | Rôles `role_blocklist` ≠ `role_tokens` connectés en **DSN dédiés** (pas `service_role`, voir §3.4) | **Tenue** |
| **Attaquant fraudeur (Sybil / SMS-pumping)** | Mass-minting via SIM farms, numéros jetables, OTP-phishing | Canonicalisation E.164/email + line-type + device attestation + rate-limit multi-vecteur + spend-cap + plafonds d'émission (§8) | **Atténuée** (le numéro seul n'est pas une barrière dure ; claims marqués « non vérifiés ») |
| **Énumération via oracle de présence** | Teste « ce numéro est-il utilisateur ? » (donnée art. 9) | `verify-uniqueness` supprimé en tant que pré-OTP ; unicité fermée par `UNIQUE(contact_hmac)` seul (§5.3) | **Tenue** |
| **Insider double-base + logs + réseau** | Lit les deux tables + corrèle par IP/timestamp/sessionId | Blindness + write-at-redemption + DATE/UUID + no-log IP + délai inter-phase randomisé + UUID R2 + séparation des rôles | **Tenue au-dessus de `k_min`** |
| **Émetteur (issuer) malveillant** | Lier `blindedMsg` ↔ token ; pousser une clé « sur-mesure » | Blindness (r secret) + variante RSABSSA pinnée + clé publique pinnée dans le binaire + transparence d'empreinte (§6) | **Tenue** |
| **Administrateur infra (instance unique)** | superuser Postgres / `SERVICE_ROLE_KEY` / WAL / backups / `auth.users` | **NON couverte sans double-instance §3.5** | **Hors périmètre** tant que §3.5 non déployé |
| **Réquisition US / CLOUD Act** | Contraint un sous-traitant à maison-mère US | Provider OTP EU souverain + résidence EU bout-en-bout + pepper hors juridiction admin DB | **Atténuée** (limite télécom irréductible) |

### Hors périmètre (assumé explicitement)
- Admin infra d'instance Supabase unique **avant** déploiement double-instance (§3.5).
- Trafic sous `k_min` (anonymity set/jour effondré) : l'anonymat n'est **pas garanti** contre l'insider double-base — limite inhérente, pas un détail (le k-anonymity au flush §4 est la seule défense et il devient **obligatoire**).
- Casse de RSA-2048, compromission simultanée du pepper ET de la clé privée d'émission ET de l'infra.

---

## 2. Architecture cible

```
┌──────────────────────────────────────────────────────────────────────────────┐
│  CLIENT FLUTTER WEB (Dart, cible dart2js ET dart2wasm)                         │
│  - nonce 32o (Random.secure → crypto.getRandomValues, exception si fallback)   │
│  - blinding factor r : CSPRNG, boucle de rejet gcd(r,n)=1, jamais réutilisé    │
│  - blind() : preparedMsg = EMSA-PSS(SHA-384, salt 48, Randomized) ; bMsg=…r^e   │
│  - finalize() : sig = blindSig·r^-1 mod n ; VERIFY local sous clé PINNÉE        │
│  - Persiste {nonce, claims_larges, sig, pubkey_ver} chiffré Hive AES-256        │
└───┬───────────────────┬────────────────────┬───────────────────┬──────────────┘
    │(1) OTP email        │(2) OTP SMS          │(5) /issue           │(7) redemption
    │  via Worker otp-eu  │  via Worker otp-eu  │  bMsg + otpProof    │  X-MentalET-Token
    ▼  (PAS Supabase Auth)▼                     ▼                     ▼
┌─────────────────────────────────┐   ┌────────────────────┐  ┌──────────────────────┐
│ Worker EU "otp-eu" (Cloudflare) │   │ Worker EU "issuer" │  │ Worker redemption     │
│ - provider EU souverain (46elks/│   │ - blindSign(privK, │  │ (r2-upload/claude-    │
│   Sinch) ; code OTP en KV TTL    │   │   bMsg)            │  │  proxy) :             │
│   court, JAMAIS de log du numéro │   │ - vérifie otpProof │  │ - verify RSA-PSS      │
│ - émet otpProof (usage-unique,   │   │   (usage-unique,   │  │   (clé publique)      │
│   lié à H(bMsg), SANS identifiant│   │   lié H(bMsg))     │  │ - appelle Edge redeem │
│   du numéro)                     │   │ - NE STOCKE RIEN   │  │   (service binding)   │
│ - calcule HMAC, écrit blocklist  │   │ - NO-LOG IP/ts     │  │ - NO-LOG IP/ts        │
│   (DSN role_blocklist)           │   └────────────────────┘  └──────────┬───────────┘
└──────────────┬──────────────────┘                                       │
               │ INSERT contact_hmac (DSN role_blocklist)                  │ service binding
               ▼                                                           ▼
   ┌────────────────────────────────────┐              ┌────────────────────────────────┐
   │ INSTANCE A — verified_contacts      │              │ Edge "redeem" (DSN role_tokens) │
   │ contact_hmac BYTEA UNIQUE           │   ⟂ aucun    │ INSERT issued_tokens ON CONFLICT│
   │ kind, pepper_ver, created_day DATE  │     lien     │ DO NOTHING + contrôle rowcount  │
   └────────────────────────────────────┘              └──────────────┬─────────────────┘
   (pepper en KMS/HSM EU, HORS instance)                              ▼
                                                  ┌────────────────────────────────┐
                                                  │ INSTANCE B — issued_tokens      │
                                                  │ token_hash BYTEA UNIQUE         │
                                                  │ issued_day DATE, pubkey_ver,    │
                                                  │ token_exp_period, revoked_at    │
                                                  └────────────────────────────────┘
```

**Différences clés vs brouillon :** OTP **entièrement via Worker `otp-eu`** (plus de `auth.users`) ; deux **instances Postgres** distinctes (A blocklist, B tokens) ; pepper **hors infra-DB** ; redemption via Edge `redeem` atomique appelée par les Workers (qui n'ont pas d'accès Postgres) ; **no-log IP/timestamp** sur tous les Workers ; claims **larges** seulement.

> Convention projet respectée : migrations/Edge Functions dans `mentality-admin/supabase/`. Point de swap client = `AppConstants` + constructeurs optionnels des datasources.

---

## 3. Modèle de données & infrastructure

Migration : `/home/ubuntu/projects/mentality/mentality-admin/supabase/migrations/008_blind_token_hardening.sql` (+ une migration miroir sur l'instance B si double-instance).

### 3.1 Neutralisation de `auth.users` (BLOQUANT, prioritaire)

**Problème confirmé dans le code** (`register-and-issue-token/index.ts` lit `userData.user.email`/`.phone` + `email_confirmed_at`/`phone_confirmed_at` ; `registration_remote_datasource.dart` fait `signInWithOtp(email)` → `updateUser(phone)` → `verifyOTP`). Résultat : une ligne `auth.users` porte **email + téléphone en clair + 5 TIMESTAMPTZ µs**. `signOut` n'efface PAS cette ligne. Tout le HMAC est annulé.

**Décision (cible) :** **abandonner Supabase Auth pour l'OTP** (email ET SMS) au profit du Worker `otp-eu` stateless qui ne persiste jamais email+phone dans une table requêtable. Il émet un JWT court (otpProof) signé. Aucune ligne `auth.users` n'est créée.

**Repli court terme acceptable (si l'abandon total prend du temps) :** appeler `supabase.auth.admin.deleteUser(id)` **immédiatement après** vérification OTP + écriture blocklist, **dans la même Edge invocation, AVANT le `signOut`**, ET désactiver/purger `auth.audit_log_entries` (rétention 0 ou trigger de suppression). Ce repli reste fragile (backups/WAL/réplication de `auth.users`) → ne pas s'y arrêter.

### 3.2 Instance A — Blocklist (réécrit 006 ; supprime le clair `email_lower`/`phone_e164`/`created_at TIMESTAMPTZ`)

```sql
ALTER TABLE public.verified_contacts RENAME TO verified_contacts_legacy_006;

CREATE TABLE public.verified_contacts (
  id           UUID     PRIMARY KEY DEFAULT gen_random_uuid(),  -- aléatoire, PAS de séquence
  contact_hmac BYTEA    NOT NULL,                  -- HMAC-SHA256(pepper_v{n}, kind||':'||canonical(value))
  kind         SMALLINT NOT NULL,                  -- 0=phone, 1=email (domain separation dans l'entrée HMAC)
  pepper_ver   SMALLINT NOT NULL,
  created_day  DATE     NOT NULL DEFAULT now()::date,
  CONSTRAINT uq_contact_hmac UNIQUE (contact_hmac)
);
ALTER TABLE public.verified_contacts ENABLE ROW LEVEL SECURITY;  -- aucune policy → role_blocklist seul
COMMENT ON TABLE public.verified_contacts IS
  'Empreintes HMAC-SHA256 (pepper HORS infra-DB) de numéros/emails CANONIQUES vérifiés. '
  'Anti-multicompte. PSEUDONYMISÉ (pas anonyme : réversible par bruteforce si pepper fuite). '
  'AUCUN lien avec issued_tokens. created_day = DATE.';
```

- **Domain separation** : l'entrée HMAC est préfixée par `kind` (`"phone:"`/`"email:"`) pour qu'un même pepper ne serve pas deux espaces.
- **Purge automatisée DÈS cette phase** (`pg_cron` ou Worker cron) à la durée unique fixée par la LIA (§7) — pas reportée.

### 3.3 Instance B — Tokens (remplace 007 ; supprime AES serveur + `idx_tokens_created_at` + `created_at` fin)

```sql
CREATE TABLE public.issued_tokens (
  id                UUID     PRIMARY KEY DEFAULT gen_random_uuid(),
  token_hash        BYTEA    NOT NULL,            -- SHA-256(nonce). Vu seulement à l'usage.
  issued_day        DATE     NOT NULL DEFAULT now()::date,  -- jour de 1re redemption
  pubkey_ver        SMALLINT NOT NULL,
  token_exp_period  SMALLINT NOT NULL,            -- période d'expiration grossière (ex. n° de mois calendaire)
  revoked_at        TIMESTAMPTZ,                  -- NULL sauf révocation
  CONSTRAINT uq_token_hash UNIQUE (token_hash)
);
ALTER TABLE public.issued_tokens ENABLE ROW LEVEL SECURITY;  -- aucune policy → role_tokens seul
```

> **Claims** : le code postal **NE figure PLUS dans le token** (voir §3.6). Seuls des buckets larges (pays, tranche d'âge large) peuvent y figurer, et ils sont **marqués « auto-déclarés / non vérifiés »** dans le dataset (Blind RSA ne les atteste pas).

### 3.4 Rôles & connexion réelle (pas `service_role`)

**Problème confirmé :** les 3 Edge Functions actuelles utilisent `SUPABASE_SERVICE_ROLE_KEY` (bypass RLS + tous les GRANT). La séparation des rôles est inopérante tant que `service_role` est la clé d'accès.

```sql
CREATE ROLE role_blocklist NOLOGIN; GRANT SELECT, INSERT ON public.verified_contacts TO role_blocklist;
CREATE ROLE role_tokens    NOLOGIN; GRANT SELECT, INSERT, UPDATE ON public.issued_tokens TO role_tokens;
```

**Connexion concrète (à spécifier, pas une boîte noire) :** abandonner `supabase-js`/`service_role` pour ces fonctions → **connexion Postgres directe via `deno-postgres`** avec deux DSN distincts (`user=role_blocklist` / `user=role_tokens`, mots de passe en secrets séparés). Le Worker `issuer` n'a **aucun** accès Postgres.

### 3.5 Double-instance (tranche la « décision ouverte » du brouillon)

La séparation des rôles ne protège pas d'un superuser. Pour que la garantie « insider double-base » soit **réelle** :

- **Cible forte :** `verified_contacts` sur l'**instance A**, `issued_tokens` sur l'**instance B** — instances Postgres physiquement distinctes, credentials et **clés de backup séparés**, idéalement deux hébergeurs/juridictions.
- **Si non déployé :** la garantie §0 est **honnêtement rétrogradée** — « insider double-base » sort du périmètre couvert et c'est écrit noir sur blanc dans la politique et la DPIA. **Ne pas vendre une protection fausse.**

### 3.6 Secrets & frontières de confiance
- `BLOCKLIST_PEPPER_V1` — 256 bits aléatoires. **HORS instance Supabase** : KMS/HSM EU dédié, ou Worker Secret Cloudflare isolé. Idéalement, calculé dans un **service HMAC isolé** auquel la DB n'a pas accès (n'expose que des comparaisons d'égalité). **Procédure de rotation + re-hachage documentée** (un pepper compromis est définitif sinon).
- `RSA_ISSUER_PRIVKEY_V1` — RSA-2048 → Worker Secret `issuer`. Clé **publique** pinnée dans `AppConstants` + empreinte publiée (transparence).
- `OTP_PROOF_SIGNING_KEY` — clé de signature de l'otpProof (Worker `otp-eu`).
- `TOKEN_AES_KEY` (legacy) — **détruite tôt** (voir Phase 6 séquencement, §9).

---

## 4. Mécanisme anti-linkage (le cœur, durci)

### Couche 1 — Blindness (RFC 9474)
Le serveur ne reçoit que `blindedMsg = preparedMsg · r^e mod n` ; `r` secret, jamais transmis, **CSPRNG, coprime à `n` (boucle de rejet), jamais réutilisé**. *Limite reconnue :* la blindness protège le **contenu**, pas les **métadonnées de transport** (IP, timing, sessionId) — d'où les couches 4-6.

### Couche 2 — Découplage temporel (write-at-redemption) + délai inter-phase randomisé
`issued_tokens` n'est touchée qu'à la **première redemption** (heures/jours après l'inscription). **Renfort obligatoire** : le client introduit un **délai aléatoire significatif (heures, pas ms)** entre émission et 1re redemption, et la redemption peut emprunter un **réseau/IP différent**, pour décorréler les instants de logs.

### Couche 3 — Granularité DATE + UUID + suppression des timestamps fins
`created_day`/`issued_day` = DATE ; PK = UUID aléatoire ; `idx_tokens_created_at` supprimé ; `epoch/60` retiré (voir séquencement §9). **Suppression du `postal_hash` du token** (couche aussi anti-ré-identification, voir Couche 7).

### Couche 4 — Séparation des accès réelle (DSN dédiés + double-instance)
`role_blocklist` ≠ `role_tokens` connectés en **DSN Postgres directs** (§3.4), sur **deux instances** (§3.5). Le Worker `issuer` ne lit aucune des deux.

### Couche 5 — No-log IP/timestamp (ferme le canal réseau)
- **Désactiver Logpush / Workers Trace Events** sur `otp-eu`, `issuer`, `r2-upload`, `claude-proxy`.
- **Ne JAMAIS journaliser IP+HMAC sur la même ligne** (le §8.8 du brouillon proposait l'inverse → **corrigé** : le logging forensique sépare les canaux, IP hachée/tronquée, jamais jointe au HMAC, rétention ≤ 30 j).
- **Postgres** : `log_statement=none`, pas de pgAudit sur ces tables.
- **`auth.audit_log_entries`** purgé/désactivé (§3.1).

### Couche 6 — Neutralisation du canal R2 (sessionId / timestamps)
**Problème confirmé** (`r2-upload/index.js` : `stamp = new Date().toISOString()` µs dans le nom d'objet + `customMetadata.uploaded_at` ISO µs ; `session_manager.dart` : UUID v4 stable sur tout le cycle, partagé entre les deux tests, embarqué dans la clé R2). 
- Clé R2 = **UUID aléatoire** par objet (plus de timestamp dans le nom) ; `uploaded_at`/`stamp` en **granularité DATE**.
- **Séparer redemption et upload** : le token signé ne transite pas dans la même requête HTTP que l'écriture R2 ; la redemption passe par l'Edge `redeem` (service binding), `r2-upload` ne voit jamais `token_hash`.
- Vérifier/documenter que `sessionId` reste **indépendant** du token et de l'inscription (généré après émission). L'ajouter au modèle de menace comme identifiant de jointure potentiel.

### Couche 7 — k-anonymity des claims + des dates (OBLIGATOIRE au lancement)
- **Quasi-identifiants** : `postal_hash` (SHA-256[:8] d'un code postal, **réversible en secondes via la table `postal_codes` du projet** — dictionnaire complet) **sorti du token**. Si une géo est nécessaire, **généraliser** en région/département à population `≥ k_min` ; vérifier que chaque combinaison `{sexe, tranche_âge_large, géo}` a `k ≥ k_min` sur la population attendue.
- **k-anonymity au flush** : à faible trafic (lancement = faible trafic **garanti**, donc période la plus vulnérable), ne pas matérialiser une ligne `issued_tokens` (ni libérer un lot blocklist) tant que **`N ≥ k_min` (ex. `k_min = 20`)** événements distincts ne sont pas en attente dans la fenêtre, avec timeout max et **monitoring/alerte si backlog > 2 h** ou si anonymity set/jour `< k_min`. **Obligatoire, pas optionnel.**

### Gate de validation par DATE **ET par ATTRIBUTS** (avant prod, bloquant)
Test d'attaque sur jeu simulé : tenter le ré-appariement (a) par date, (b) **par attributs (claims)**, (c) par IP/timestamp de logs simulés. **Critère bloquant :** `|anonymity set| ≥ k_min` sur les trois axes, sinon pas de mise en prod. (Le test du brouillon ne mesurait que la date → faux positif corrigé.)

---

## 5. Flow complet (endpoints & payloads durcis)

### Étape 0 — Génération client (Flutter Web, avant tout réseau)
- nonce 32o (`Random.secure` ; **lever une exception si fallback PRNG** sur Web).
- message = `{token_type=0x0002, nonce[32], claims_larges?}` (claims **larges** uniquement, **sans code postal**).
- `preparedMsg = EMSA-PSS-ENCODE(SHA-384, salt 48, **Randomized**)` ; variante **RSABSSA-SHA384-PSS-Randomized pinnée**.
- `r` : CSPRNG, **boucle de rejet `gcd(r,n)=1`**, jamais réutilisé ; `blindedMsg = preparedMsg·r^e mod n` ; `inv = r^-1 mod n`.

### Étape 1-2 — OTP email + SMS (Worker `otp-eu`, PAS Supabase Auth)
- `POST {otpWorkerUrl}/otp/send` puis `/otp/verify` pour email **et** SMS via provider EU souverain (46elks/Sinch). Code OTP en KV TTL court (60-90 s), **numéro jamais loggé**, validation 100 % server-side, binding session/device, plafond d'essais.
- **Résultat :** `otpProof` (voir Étape 5) — aucune ligne `auth.users`.

### Étape 3 — Pré-check unicité : **supprimé en tant qu'endpoint pré-OTP**
**Problème confirmé** (`verify-uniqueness`, non authentifié, CORS `*`) = oracle de présence (« ce numéro est-il utilisateur d'une app de santé mentale ? », donnée art. 9). **Décision :** ne pas exposer l'unicité avant l'OTP. Le **seul** garde-fou est `UNIQUE(contact_hmac)` à l'INSERT. Si un feedback UX précoce est jugé indispensable : réponse **à temps constant**, **rate-limit fort + Turnstile**, **après** un début d'OTP (preuve de possession), **non journalisé**.

### Étape 4 — Enregistrement blocklist (T1, DSN `role_blocklist`)
Après OTP validé : `INSERT verified_contacts(contact_hmac = HMAC(pepper, kind||':'||canonical(value)), kind, pepper_ver, created_day)`. `UNIQUE(contact_hmac)` ferme la race ; conflit → `phone_taken`/`email_taken`. **HMAC calculé côté serveur isolé** (pepper hors infra-DB). Aucune écriture token ici.

### Étape 5 — Émission aveugle (Worker `issuer`)
`POST {issuerUrl}/issue` body `{blindedMsg, otpProof}`. **Spécification de l'`otpProof` (maillon critique) :**
- À la validation OTP, le client envoie `H(blindedMsg)` au Worker `otp-eu` ; celui-ci retourne `otpProof = Sign(OTP_PROOF_SIGNING_KEY, H(blindedMsg) || jti_aléatoire || exp_court)`.
- Le proof **ne contient AUCUN identifiant du numéro** (pas de HMAC, rien de dérivable) → l'issuer ne peut corréler ses `/issue` ni par numéro ni entre eux.
- Le Worker `issuer` : (1) vérifie la signature du proof, (2) vérifie `H(blindedMsg reçu) == celui du proof`, (3) **consomme `jti` dans un store usage-unique atomique** (KV/Durable Object, TTL court) — rejet si déjà vu. **« 1 OTP vérifié = exactement 1 blindSign ».** Sans ce store, la one-more-unforgeability est vide.
- `blindSignature = blindSign(privKey, blindedMsg)` ; réponse `{blindSignature, pubkey_ver}`. **NO-LOG IP/ts/proof.**

### Étape 6 — Finalize client (Flutter)
`signature = blindSignature·inv mod n` ; **`verify(pubKey_PINNÉE, signature, preparedMsg)` obligatoire AVANT stockage** (rejet sinon). Token = `{nonce, claims_larges, signature, pubkey_ver, exp_period}` → Hive AES-256.

### Étape 7 — Redemption (découplée, atomique)
Header `X-MentalET-Token: base64url({nonce, signature, pubkey_ver, exp_period})`. Le Worker de redemption : `verify('RSA-PSS', pubKey, sig, data, {saltLength:48})` + vérifie `exp_period` (validité grossière, ex. mois calendaire — borne le rejeu d'un token volé **sans** timestamp fin). Puis appelle l'**Edge `redeem`** (service binding, DSN `role_tokens`) qui fait :
```sql
INSERT INTO issued_tokens (token_hash, ...) VALUES (sha256(nonce), ...) ON CONFLICT DO NOTHING;
```
**N'autoriser que si rowcount = 1** (ferme le TOCTOU ; usage-unique). 2e présentation = rejet. Politique **usage-unique** par défaut (pour l'upload multi-fichiers d'une session : émettre un **batch de N tokens à usage unique** plutôt qu'un bearer réutilisable → décorrèle les redemptions entre elles). CORS strict (prérequis, pas nice-to-have).

---

## 6. Choix techniques (stack réelle)

| Brique | Choix | Détails durcis |
|---|---|---|
| **Émission aveugle** | Worker `issuer` | `@cloudflare/blindrsa-ts {supportRSARAW:true}`. Variante **RSABSSA-SHA384-PSS-Randomized PINNÉE** (constante testée contre test vectors RFC 9474). |
| **HMAC pepper** | Service/Worker isolé | `crypto.subtle` HMAC-SHA256, pepper **hors instance DB** (KMS/HSM EU). Jamais côté client. Domain separation par `kind`. |
| **Vérif token** | Workers redemption + Edge | `crypto.subtle.verify('RSA-PSS', …, {saltLength:48})`. Zéro dépendance native. |
| **Connexion DB** | `deno-postgres` 2 DSN | `role_blocklist` / `role_tokens`. **Abandon de `service_role`** pour ces fonctions. |
| **Redemption** | Edge `redeem` + service binding | `INSERT … ON CONFLICT DO NOTHING` + rowcount. Workers R2/claude-proxy n'accèdent jamais à Postgres. |
| **Client Dart** | **pointycastle (à déclarer en dépendance DIRECTE)** | Aujourd'hui **transitive-only** (`pubspec.lock`), **pas dans `pubspec.yaml`** → l'ajouter + figer la version + re-résoudre. `blind()`/`finalize()` ~150 lignes : op RSA brute + EMSA-PSS + BigInt. **Tests de propriété adversariaux** (gcd, non-réutilisation de r, inversibilité, r=0/salt nul) + test vectors RFC 9474 **EXÉCUTÉS DANS LE NAVIGATEUR cible (dart2js ET dart2wasm), pas en VM Dart.** |
| **Canonicalisation** | `libphonenumber-js` (Worker) + normalisation email | **Remplace le regex `isValidE164`** (`token.ts:181`, confirmé regex pur) : strip trunk, `9` mobile optionnel (AR/MX/IT), rejet non-attribuables. Email : **retirer points + `+tag` (gmail), NFC + IDNA** (`normalizeEmail` = trim+lowercase seul aujourd'hui). Corpus de tests d'équivalence. Hacher la **forme canonique** uniquement. |
| **Point de swap client** | `AppConstants` + constructeurs | URLs `otp-eu`/`issuer`/`redeem` + clé RSA publique pinnée. `kSkipRegistrationGate=false` **seulement** quand OTP validé bout-en-bout (`app_constants.dart:263`). |
| **OTP** | Worker `otp-eu` + provider EU souverain | Code en KV TTL court, no-log numéro. À défaut Twilio Verify IE1 (⚠️ SMS « SNA only » en IE1 — **spike de délivrabilité obligatoire avant engagement**). |

---

## 7. Conformité RGPD (livrables bloquants, pas des TODO)

> **Verdict de la revue juridique : architecture anti-linkage solide, mais coquille de conformité manquante. Ne pas activer le gate ni le lien politique avant d'avoir refermé les bloquants ci-dessous.**

### Bloquants AVANT mise en prod du gate
1. **Réécriture de la politique de confidentialité publiée** (`mentalite_site_web_flutter/.../confidentialite_page.dart`) **AVANT** de wirer `oralConsentPrivacyLink`. La page actuelle promet l'**inverse** du système : consentement exclusif, effacement total sur demande, 12 mois, et **ne mentionne ni blocklist, ni HMAC, ni intérêt légitime**. Pointer ce lien en l'état = violation art. 13 auto-documentée. Y ajouter : finalité « prévention des inscriptions multiples / fraude », base **art. 6-1-f** (pas le consentement) + renvoi LIA, catégorie « empreinte HMAC du numéro », **durée propre unique**, limites de l'effacement.
2. **Consentement à la cession commerciale « anonymisée »** : la voix est un **identifiant biométrique (art. 9)** non anonymisable. Promesse trompeuse → consentement vicié + cession illicite. Reformuler honnêtement (« pseudonymisée, sans nom ni numéro, mais la voix reste biométrique »), consentement **explicite et séparé** (art. 9-2-a). Corriger `oralConsentCommercialCheckbox` (`app_fr.arb:329`/`app_en.arb:95`) **et** `oralReadingPermissionBody2` (`:183`/`:61`) : « anonymisé » → « pseudonymisé ». **`kConsentVersion++`** après correction (re-sollicitation auto).
3. **LIA (test de mise en balance art. 6-1-f)** écrite et versionnée (absente du repo). Documenter finalité, **nécessité** (pourquoi le HMAC est indispensable vs alternatives device-bound/proof-of-personhood sans rétention durable — la balance est aggravée par le contexte santé mentale art. 9), proportionnalité (durée minimale réelle), attente raisonnable. Si la balance est douteuse, basculer vers un anti-multicompte **sans rétention persistante**.
4. **DPIA (art. 35)** : traitement à grande échelle de données de santé/biométriques (voix) → DPIA très probablement exigée. À produire.
5. **Registre des traitements (art. 30)** : entrées blocklist, audio, OTP.

### Cadre permanent
- **HMAC = pseudonymisation, PAS anonymisation.** Ne **jamais** le qualifier d'« irréversible » : numéro ≈ 30 bits → bruteforce GPU en secondes **dès que le pepper fuit** (d'où pepper hors infra-DB §3.6). C'est de la **donnée personnelle pleine** → l'effacement art. 17 s'applique.
- **Refus d'effacement** : pas via une lecture large de l'art. 17-3, mais via l'articulation **art. 21 (opposition) ↔ motifs légitimes impérieux**, évaluée au cas par cas (documentée en LIA). Pour de la santé mentale, ces motifs prévalent difficilement.
- **Procédure DSAR opérationnelle** : sur demande, (a) re-hacher le numéro fourni → retrouver `contact_hmac` → supprimer si l'opposition l'emporte ; (b) **audio** : l'effacement par `sessionId` est **inexécutable si l'utilisateur perd son device** (sessionId local perdu). **Trancher honnêtement** : soit anonymat fort + effacement audio impossible après perte du device (et l'assumer dans la politique), soit effacement via ré-vérification OTP contrôlée (qui recrée un lien). Délai art. 12-3 (1 mois).
- **Durée de conservation unique** : fixer **UNE** durée motivée par la LIA, identique partout (politique / `COMMENT` SQL / cron / `DECISIONS.md`). Supprimer les trois durées contradictoires (« permanente » / 24 mois / 12 mois). Purge `pg_cron`/Worker **dès la Phase 2**.
- **Minimisation (art. 5-1-c)** : plus d'email/phone en clair ; token sans code postal ; un seul ancrage (téléphone).
- **Sous-traitants** : qualifier (art. 28 DPA / art. 26) les destinataires audio (Whisper/Speechmatics) et tout cessionnaire commercial.
- **Résidence EU & CLOUD Act** : R2 `jurisdiction=eu` OK ; **confirmer région EU du Supabase self-hosté** ; OTP via provider EU **sans maison-mère US** ; pepper hors juridiction de l'admin DB. Tracer dans `/home/ubuntu/mentality-shared/DECISIONS.md`.

---

## 8. Anti-abus / anti-Sybil (la barrière primaire, déplacée en amont)

> **Verdict de la revue abus : le numéro seul n'est pas une barrière Sybil suffisante pour un dataset de santé vendable. L'OTP+anti-abus est un PRÉ-REQUIS, pas une Phase 5.**

1. **État actuel non sécurisé** : `kSkipRegistrationGate=true` = **aucune barrière téléphone aujourd'hui**. Ne **jamais** exposer l'émission en prod tant que le gate est off **et** l'OTP non validé bout-en-bout.
2. **Canonicalisation E.164/email réelle** (§6) : sans elle, Sybil **sans 2e SIM** (`+33…` vs variantes, `9` mobile optionnel, `a.b+x@gmail.com`).
3. **SIM farms / numéros jetables** : line-type lookup (refuser/scorer VoIP, MVNO data-only), reputation des ranges, détection portabilité SIM récente → step-up (refus pour santé). Le numéro mobile à 0,x€ ne suffit pas.
4. **Proof-of-personhood léger** : device attestation (Play Integrity/App Attest) + friction (délai, Turnstile) pour rendre le mass-minting non rentable. **Plafonds globaux d'émission/jour + circuit-breaker** sur pics.
5. **Claims auto-déclarés** : Blind RSA ne les atteste pas → **marquer « self-reported / unverified »** dans le dataset vendu (sinon empoisonnement). Idéalement corroborer (cohérence test oral).
6. **Anti-SMS-pumping / AIT (IRSF)** : rate-limit multi-vecteur (HMAC-numéro, IP, session), **spend-cap par pays chiffré**, blocage ranges premium/IRSF, plafond resend/codes erronés avant lockout. Turnstile/risk-score **avant** d'envoyer le SMS.
7. **DoS / verrouillage de numéro légitime** : inscription définitive ⇒ inscrire le numéro d'autrui le bannit → n'inscrire **qu'après OTP prouvé par le détenteur** + **procédure de déblocage humaine**.
8. **Double-spend** : `INSERT … ON CONFLICT DO NOTHING` + rowcount (atomique) ; token à usage unique ; expiration grossière ; CORS strict.
9. **Protection clé d'émission** : RSA-2048 en Worker Secret ; **une seule clé active** à un instant T (les anciennes `pubkey_ver` en vérif seule) — éviter le metadata partitioning (RFC 9576). Transparence d'empreinte de la clé publique (anti-clé « sur-mesure » singularisante).
10. **Auth d'upload** : exiger `X-MentalET-Token` signé sur `r2-upload` ET `claude-proxy` (ferme l'absence d'auth documentée).
11. **Logging forensique corrigé** : journaliser le **strict minimum**, **jamais HMAC+IP sur la même ligne**, IP hachée/tronquée, rétention ≤ 30 j (le §8.8 du brouillon créait le canal qu'on ferme).
12. **Réquisition au niveau Worker** : les Workers (`issuer`, `otp-eu`, redemption) voient IP↔numéro↔token en transit → no-log + analyse CLOUD Act au niveau edge, pas seulement au repos.

---

## 9. Plan d'exécution en phases

> **Réordonnancement majeur vs brouillon :** la neutralisation `auth.users`, l'OTP+anti-abus, et la destruction des artefacts legacy passent **en tête**. Les phases 2→4 captent l'essentiel du gain RGPD/anti-corrélation. La phase 6 (Blind RSA) reste **conditionnée** à une porte de décision. On peut **s'arrêter après la phase 4** (token serveur découplé) si le coût Blind RSA n'est pas justifié — **mais seulement si l'OTP+anti-abus sont déjà en place.**

### Phase 0 — Pré-requis, audit, spikes bloquants
- **Actions :** vérifier que 005-007 sont appliquées ; **confirmer région EU** du Supabase self-hosté + support `pg_cron` + rôles NOLOGIN exploitables ; générer `BLOCKLIST_PEPPER_V1` et le placer **hors infra-DB** ; **spike délivrabilité provider OTP EU** (couverture SMS des pays cibles, où le code+numéro transitent, no-log) ; **spike pointycastle en navigateur** (dart2js+dart2wasm) contre test vectors RFC 9474. Documenter `DECISIONS.md` (résidence EU, CLOUD Act, HMAC+pepper, double-instance).
- **Validation :** pepper hors instance ; provider OTP EU validé bout-en-bout ; interop Blind RSA prouvée **en navigateur** (sinon Phase 6 abandonnée) ; décisions tracées.

### Phase 1 — Neutralisation `auth.users` + logs (BLOQUANT)
- **But :** fermer la vraie base reliante avant tout hardening des tables annexes.
- **Fichiers :** Worker `otp-eu` (OTP email+SMS stateless, otpProof) ; `registration_remote_datasource.dart` (remplacer `signInWithOtp`/`updateUser`/`verifyOTP` Supabase Auth) ; désactivation Logpush/Trace Events tous Workers ; purge/désactivation `auth.audit_log_entries` ; `log_statement=none` Postgres.
- **Validation :** **aucune ligne `auth.users` créée** lors d'une inscription ; aucun log IP+timestamp µs côté OTP/issuer/redemption ; le test d'absence-de-lien §4 inclut désormais `auth.users` et passe.

### Phase 2 — HMAC+pepper + canonicalisation + DATE/UUID + purge
- **But :** supprimer le clair (faille 006), tuer le canal timing/ordre, fermer le Sybil par canonicalisation.
- **Fichiers :** `008_*.sql` (table A + `role_blocklist` + DATE + UUID + suppression `idx_tokens_created_at`) ; `_shared/blocklist.ts` (HMAC, pepper hors infra-DB, domain separation) ; **canonicalisation** (remplace `isValidE164` regex + `normalizeEmail`) + corpus de tests d'équivalence ; suppression `epoch/60` ; **purge `pg_cron`** à la durée LIA ; connexion `deno-postgres` DSN `role_blocklist`.
- **Migration legacy :** re-hacher `verified_contacts_legacy_006` **hors-ligne sur env isolé** (forme canonique), puis **DROP immédiat** des colonnes claires + purge des backups antérieurs (pas de « le temps de la migration » indéfini ; fenêtre ≤ 7 j).
- **Validation :** numéro re-soumis → `phone_taken` ; `SELECT` ne montre que `contact_hmac` BYTEA ; pepper absent base+git+instance ; paires équivalentes (téléphone/email) → même HMAC ; aucune colonne TIMESTAMPTZ fine ni séquence.

### Phase 3 — Découplage temporel + k-anonymity au flush + double-instance
- **But :** fermer la batching attack et protéger le lancement (faible trafic).
- **Fichiers :** `008_*.sql` (table B `issued_tokens` + `role_tokens`, sur **instance B** si double-instance §3.5) ; Edge `redeem` (DSN `role_tokens`, `ON CONFLICT` + rowcount) appelée via service binding ; logique de k-anonymity au flush (`k_min`, timeout, monitoring backlog) ; délai inter-phase randomisé côté client.
- **Validation :** après inscription, `issued_tokens` **vide** ; ligne créée seulement après usage réel ; gate d'attaque **par date ET attributs ET logs simulés** → `≥ k_min` ; alerte si anonymity set/jour `< k_min` ; double-instance déployée **ou** garantie rétrogradée par écrit.

### Phase 4 — Neutralisation canal R2 + auth d'upload
- **But :** fermer le canal sessionId/timestamp et l'absence d'auth.
- **Fichiers :** `r2-upload/index.js` (clé = UUID aléatoire, `uploaded_at`/`stamp` en DATE, séparation upload/redemption) ; `r2-upload`+`claude-proxy` exigent `X-MentalET-Token` signé ; `sessionId` vérifié indépendant ; `cors.ts`+`ALLOWED_ORIGINS` restreints.
- **🚪 Porte de décision :** si le modèle de menace ne justifie pas le coût Blind RSA, **s'arrêter ici** (token serveur découplé) — **acceptable uniquement** si Phases 1-2 (OTP+anti-abus) sont en place. Sinon → Phase 5.

### Phase 5 — OTP EU complet + anti-abus en profondeur
- **But :** barrière Sybil primaire + souveraineté (formalise/complète le Worker `otp-eu` de Phase 1).
- **Fichiers :** rate-limit multi-vecteur, spend-cap, line-type, device attestation, Turnstile, plafonds d'émission, circuit-breaker ; logging forensique corrigé (no HMAC+IP).
- **Validation :** OTP SMS EU fonctionnel ; mass-minting non rentable (plafonds testés) ; oracle d'énumération fermé ; budget SMS protégé.

### Phase 6 — Blind RSA (poste de risque #1, conditionné)
- **6.0 Spike d'interop (GATE, déjà amorcé Phase 0) :** variante **RSABSSA-SHA384-PSS-Randomized pinnée** validée contre test vectors RFC 9474 + `@cloudflare/blindrsa-ts`, **en navigateur (dart2js+dart2wasm)**, avec tests de propriété adversariaux. **Si non prouvé : ne pas engager.**
- **Fichiers :** Worker `issuer` (otpProof usage-unique lié `H(blindedMsg)`) ; `blind_rsa.dart` (pointycastle, dépendance directe) ; vérif RSA-PSS + `exp_period` côté redemption ; **claims larges seulement** dans le token ; clé publique pinnée + empreinte publiée.
- **Validation :** token client-fabriqué vérifié hors-ligne ; **1 OTP = 1 blindSign** (store usage-unique testé) ; double-spend rejeté (rowcount) ; finalize rejette une signature qui ne vérifie pas sous la clé pinnée ; aucun log reliant `blindedMsg`↔IP↔ts.

### Phase 7 — RGPD discours + gate + nettoyage legacy
- **Fichiers :** **politique réécrite + LIA + DPIA + registre art. 30** (bloquants) ; ARB FR/EN (anonymisé→pseudonymisé), wirer `oralConsentPrivacyLink` ; `kConsentVersion++` ; `kSkipRegistrationGate=false` ; DROP `verified_contacts_legacy_006` + `public.tokens` ; suppression `decode-token` **uniquement après** extinction complète des tokens AES legacy.
- **Validation :** re-sollicitation consentement déclenchée ; gate splash→/register actif **et** OTP opérationnel ; lien politique cliquable vers une page cohérente ; aucun token AES legacy déchiffrable ; LIA/DPIA/registre archivés.

---

## 10. Failles identifiées et comment le plan les neutralise

| # | Faille (revue adversariale) | Sévérité | Neutralisation dans ce plan |
|---|---|---|---|
| 1 | **`auth.users` lie email+phone+5 timestamps µs** ; `signOut` n'efface pas la ligne ; lue par le code actuel | Critique | **Phase 1** : OTP via Worker `otp-eu` stateless (pas Supabase Auth) ; repli = `admin.deleteUser` immédiat ; `auth.users` ajouté au modèle de menace §1 et au test §4 |
| 2 | **`auth.audit_log_entries`** journalise email+IP+ts µs par OTP | Critique | **Phase 1** : purge/désactivation (rétention 0) ; abandon Supabase Auth supprime la source |
| 3 | **Corrélation IP/timestamp transverse** (OTP→issuer→redemption) court-circuite la blindness | Élevée | **Couche 5** : no-log IP/ts (Logpush/Trace off) ; délai inter-phase randomisé (heures) ; IP jamais jointe au HMAC |
| 4 | **WAL / PITR / `ctid`** révèlent ordre+instant réels malgré DATE | Élevée | **§3.5 double-instance** (WAL non comparables) + backups chiffrés par clé séparée ; sinon garantie rétrogradée |
| 5 | **Séparation des rôles = théâtre** (`service_role` bypass RLS ; superuser/backups) | Critique/Élevée | **§3.4** DSN `deno-postgres` dédiés (abandon `service_role`) + **§3.5** double-instance, sinon « insider double-base » retiré du périmètre |
| 6 | **Code postal dans le token** : non attestable (Blind RSA) + quasi-identifiant ré-identifiant (postal_hash réversible via `postal_codes` du projet) | Critique | **§3.6 + Couche 7** : `postal_hash` sorti du token ; claims larges seulement ; `k≥k_min` sur `{sexe,âge,géo}` ; claims marqués « non vérifiés » |
| 7 | **`otpProof` non spécifié** ⇒ one-more-unforgeability vide (tokens illimités/numéro) | Critique | **§5 Étape 5** : proof signé, **usage-unique (jti)**, lié à `H(blindedMsg)`, sans identifiant du numéro, consommé atomiquement |
| 8 | **HMAC qualifié « irréversible »** alors que ~30 bits + pepper sur même infra | Élevée | **§3.6 + §7** : pepper **hors infra-DB** (KMS/HSM) + rotation ; discours corrigé (pseudonymisation, donnée personnelle pleine) |
| 9 | **Double-spend TOCTOU + token bearer rejouable sans expiration** | Élevée | **§5 Étape 7** : `ON CONFLICT DO NOTHING` + rowcount=1 ; **usage-unique** + batch de N tokens ; `exp_period` grossier signé ; CORS strict |
| 10 | **`verify-uniqueness` = oracle de présence** (membership leak, art. 9) + race | Élevée | **§5 Étape 3** : supprimé en pré-OTP ; unicité par `UNIQUE(contact_hmac)` seul ; sinon temps constant + Turnstile + rate-limit + no-log |
| 11 | **Canonicalisation E.164/email absente** (regex pur) ⇒ Sybil sans 2e SIM | Élevée | **§6 + Phase 2** : `libphonenumber` + normalisation email (points/+tag/NFC/IDNA) + corpus de tests ; HMAC sur forme canonique |
| 12 | **SIM farms / numéros jetables** + claims signés non vérifiés ⇒ empoisonnement dataset | Élevée | **§8** : line-type, reputation, device attestation, plafonds d'émission, claims « self-reported / unverified » |
| 13 | **Ordonnancement** : OTP+anti-abus en Phase 5 (sautable) ; `kSkipRegistrationGate=true` | Critique | **§9** : OTP+anti-abus **pré-requis** (Phases 1-2) ; « stop Phase 4 » conditionné ; interdiction d'exposer l'émission tant que gate off |
| 14 | **Canal R2 sessionId + `uploaded_at` ISO µs** relie token↔audio | Critique | **Couche 6 + Phase 4** : clé R2 = UUID, timestamps DATE, séparation upload/redemption, sessionId indépendant |
| 15 | **Fenêtre legacy non bornée** (timestamp minute déchiffrable + `created_at` µs) | Moyenne | **Phase 2 + Phase 7** : re-hachage hors-ligne + DROP immédiat (fenêtre ≤ 7 j) + destruction `TOKEN_AES_KEY` tôt + purge backups |
| 16 | **Politique publiée contredit le système** (consentement exclusif/12 mois/effacement total) | Critique | **§7 bloquant 1** : réécriture AVANT de wirer le lien (finalité, art. 6-1-f, durée unique, limites effacement) |
| 17 | **Consentement « anonymisé » sur voix biométrique** (art. 9) ⇒ vicié | Critique | **§7 bloquant 2** : reformulation honnête + consentement explicite séparé art. 9-2-a + `kConsentVersion++` |
| 18 | **LIA/DPIA/registre absents** ⇒ intérêt légitime non opposable | Élevée | **§7 bloquants 3-5** : livrables bloquants avant prod |
| 19 | **Effacement art. 17-3 mal fondé** ; effacement audio inexécutable après perte device | Élevée | **§7** : refus via art. 21 (motifs impérieux) + DSAR (re-hachage) ; trancher honnêtement l'audio post-perte-device |
| 20 | **RNG / blinding maison** (gcd, réutilisation r, salt CSPRNG) sur Flutter Web | Moyenne | **§5/§6** : boucle de rejet gcd, r jamais réutilisé, salt CSPRNG, exception si PRNG ; tests de propriété + vectors **en navigateur** |
| 21 | **Variante RSABSSA non pinnée** + clé publique non vérifiée au finalize | Moyenne | **§6** : variante pinnée + testée ; verify obligatoire sous clé pinnée avant stockage ; transparence d'empreinte ; une seule clé active |
| 22 | **k-anonymity au flush optionnel** alors qu'au lancement c'est la seule défense | Élevée | **Couche 7** : **obligatoire**, `k_min≥20`, timeout, monitoring/alerte backlog>2h et set/jour<k_min |
| 23 | **pointycastle « (existant) »** alors que transitive-only | Élevée | **§6** : à déclarer en dépendance directe + figer version + re-résoudre `pubspec` |
| 24 | **Logs OTP provider** (numéro+ts+IP) corrélables | Moyenne | **§8 + §5** : contrat no-IP/rétention courte ; otpProof sans identifiant du numéro ; code OTP en KV TTL court non loggé |
| 25 | **Token = pseudonyme persistant** (linkability inter-sessions) | Moyenne | **§5 Étape 7** : batch de N **tokens à usage unique** ; à défaut, documenté honnêtement comme pseudonyme persistant |

---

## 11. Risques résiduels & décisions ouvertes

1. **Admin infra d'instance unique** : tant que la **double-instance §3.5** n'est pas déployée, l'« insider double-base » (superuser/`SERVICE_ROLE_KEY`/WAL/backups/`auth.users` résiduel) **n'est pas couvert** — garantie §0 rétrogradée par écrit. **Décision à trancher** : double-instance (cible) vs périmètre réduit assumé.
2. **Faible trafic au lancement** : sous `k_min`, l'anonymat contre l'insider double-base n'est **pas garanti** ; le k-anonymity au flush (§Couche 7) atténue mais introduit de la latence. Limite inhérente documentée.
3. **Interop Blind RSA en navigateur** (risque #1 réel, côté Dart pas Worker) : gate Phase 6.0 bloquant ; repli = rester Phase 4.
4. **CLOUD Act / résidence** : confirmer région Supabase ; provider OTP EU sans maison-mère US ; pepper hors juridiction admin DB ; limite télécom destinataire irréductible.
5. **Rotation de clé RSA** : fragmente l'anonymity set ; une seule clé active, anciennes `pubkey_ver` en vérif seule.
6. **Rotation du pepper** : un pepper compromis est définitif sans re-hachage ; procédure §3.6 à éprouver.
7. **Disponibilité `issuer`/`otp-eu`** : SPOF d'émission ; monitoring + l'app gate-only reste fonctionnelle.
8. **Effacement audio post-perte-device** : tension anonymat fort ↔ DSAR exécutable, tranchée honnêtement dans la politique (§7).

---

## Fichiers clés référencés (chemins absolus, vérifiés contre le code)

- **Migration à créer :** `/home/ubuntu/projects/mentality/mentality-admin/supabase/migrations/008_blind_token_hardening.sql` (+ miroir instance B)
- **Edge Functions :** `/home/ubuntu/projects/mentality/mentality-admin/supabase/functions/{register-and-issue-token→register, verify-uniqueness, decode-token, redeem}/index.ts` + `_shared/token.ts` (canonicalisation à corriger : `isValidE164`=regex, `normalizeEmail`=trim+lowercase ; `epoch/60` ligne ~68 ; `postal_hash` SHA-256[:8] ligne ~57) + `_shared/blocklist.ts` (à créer)
- **Workers :** `/home/ubuntu/projects/mentality/mentality-flutter-web/workers/{r2-upload (clé+stamp+uploaded_at ISO µs lignes ~99/114), claude-proxy}/` (+ `issuer/`, `otp-eu/` à créer)
- **DDL legacy confirmée :** `006_verified_contacts.sql` (`email_lower`/`phone_e164` clair, `created_at TIMESTAMPTZ` L18, index UNIQUE partiels) ; `007_tokens.sql` (`ciphertext UNIQUE`, `created_at TIMESTAMPTZ` L18, `idx_tokens_created_at` L23)
- **Client :** `lib/core/constants/app_constants.dart` (`kSkipRegistrationGate:263`, URLs+clé RSA publique) ; `lib/features/registration/data/datasources/registration_remote_datasource.dart` (flow `signInWithOtp`/`updateUser`/`verifyOTP`→`auth.users`) ; `lib/core/services/auth_local_store.dart` ; `lib/core/consent/consent_record.dart` (`kConsentVersion:12`) ; `lib/services/session_manager.dart` (UUID v4 stable sur le cycle)
- **i18n :** `lib/l10n/app_fr.arb` (`:183`, `:329`, `:337`) ; `lib/l10n/app_en.arb` (`:61`, `:95`) ; `pubspec.yaml` (ajouter `pointycastle` en dépendance directe)
- **RGPD publié :** `mentalite_site_web_flutter/lib/pages/confidentialite_page.dart` (à réécrire avant de wirer le lien)

🧰 Skills utilisés : aucun · Agent adopté : architecte principal