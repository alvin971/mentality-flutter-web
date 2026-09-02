# Worker `mentality-r2-upload`

Reçoit les enregistrements audio du client Flutter Web et les écrit dans
Cloudflare R2. Le client n'a **jamais** de clé R2 : tout passe par ce worker.

## Résidence des données : EU garantie ?

Deux notions distinctes chez R2 :

| Flag | Effet | RGPD |
|------|-------|------|
| `--jurisdiction eu` | **Contrainte légale** : données stockées ET traitées uniquement dans l'UE | ✅ c'est CELUI-CI qu'il faut |
| `--location weur` | Simple *indice* de placement physique (perf), aucune garantie légale | ❌ insuffisant seul |

La résidence EU n'est réelle que si **les deux** conditions sont remplies :
1. bucket créé avec `--jurisdiction eu`, **et**
2. le binding du Worker porte `jurisdiction = "eu"` (déjà dans `wrangler.toml`).

⚠️ La juridiction est figée **à la création** du bucket : elle ne peut pas être
changée après coup. Si tu crées le bucket sans le flag, il faut le **recréer**.

## Déploiement

```bash
# 1. Créer le bucket EN JURIDICTION EU (obligatoire RGPD — résidence des données)
wrangler r2 bucket create mentality-audio --jurisdiction eu

# 2. Déployer le worker
cd workers/r2-upload
wrangler deploy

# 3. Copier l'URL affichée dans :
#    lib/core/constants/app_constants.dart → r2UploadWorkerUrl

# 4. Ajouter le domaine Pages de l'app dans ALLOWED_ORIGINS (index.js) si besoin.
```

## Vérifier que le bucket est bien en EU

```bash
# Le bucket EU n'apparaît QUE si on précise la juridiction :
wrangler r2 bucket list --jurisdiction eu      # → doit lister mentality-audio
wrangler r2 bucket list                        # → ne doit PAS le lister
```

Dashboard Cloudflare → R2 → le bucket doit afficher le badge **« Jurisdiction: EU »**.

Tant que `r2UploadWorkerUrl` reste le placeholder (`YOUR_SUBDOMAIN`), l'app
**fonctionne normalement** : l'upload est simplement sauté (no-op), l'audio
reste en local.

## Organisation des clés R2

```
reusable/<account>/<sessionId>/<layer>-<recordType>-<textId>-<uuid>.<ext>   ← cessible (passe sv 3 signé, free + cc)
internal/<account>/<sessionId>/<layer>-<recordType>-<textId>-<uuid>.<ext>   ← usage interne (tout le reste, sv 2 compris)
```

`account` = **SHA-256 du nonce signé du passe**, tronqué à 32 caractères hex. Il
n'est jamais choisi par le client : personne ne peut écrire dans le compartiment
d'autrui sans détenir le passe correspondant. `uuid` (et non un horodatage)
évite la ré-identification par l'ordre temporel des fichiers.

Chaque objet porte aussi des `customMetadata` :

| Clé | Contenu |
|---|---|
| `account` | SHA-256(nonce) tronqué — lien anonyme au passe |
| `consent_version` | version des textes légaux consentis |
| `commercial_reuse` | `'true'` / `'false'` — miroir exact du préfixe ; `'true'` implique `consent_source = 'token'` |
| `plan` | `'free'` (passe sv 3) ou `'legacy'` (passe sv 2, avant les plans) |
| `consent_source` | `'token'` (claims signées) ou `'header'` (déclaré par le client) |
| `session_id`, `text_id`, `layer`, `record_type`, `duration_seconds`, `language`, `uploaded_day` | métadonnées techniques (jamais d'heure, seulement la date) |

## RGPD — d'où vient la preuve de consentement

> ⚠️ **La couche cessible est inatteignable sans claims signées.** Un objet ne
> peut atterrir sous `reusable/` **que** si le passe est un `sv ≥ 3` **signé**
> portant `p='free'`, `cc=true` et une `cv` ∈ `LEGAL_VERSIONS`. Aucun en-tête,
> aucune combinaison d'en-têtes, aucun passe `sv 2` n'y conduit.

Deux régimes, selon la version de schéma du passe (`sv`) :

- **`sv ≥ 3` — les claims signées font autorité.** Le passe porte le plan (`p`),
  le consentement au corpus vocal (`cc`) et la version des textes acceptés
  (`cv`). Les en-têtes `X-Consent-Version` et `X-Commercial-Reuse` sont
  **ignorés** : ils sont déclaratifs, donc forgeables. Conséquences :
  - plan `paid` → **403**, rien n'est écrit (le passe Payant est l'alternative
    sans enregistrement — c'est elle qui rend libre le consentement du Gratuit,
    RGPD art. 7(4)) ;
  - plan absent/inconnu ou `cv` manquante → **403** ;
  - `LEGAL_VERSIONS` absente/vide → **500** `SERVER_MISCONFIGURED` (fail-closed :
    on n'archive pas une preuve dont on ne peut pas produire le texte) ;
  - `cv` ∉ `LEGAL_VERSIONS` → **403** `LEGAL_VERSION_UNKNOWN` ;
  - plan `free` → `consent_version = cv`, `commercial_reuse = cc`.
- **`sv 2` — régime historique, durci sur un point.** Le consentement vient de
  l'écran in-app et voyage dans les en-têtes ; sans `X-Consent-Version`, **403**.
  Les passes déjà distribués continuent donc d'envoyer, **mais la destination
  est toujours `internal/`**, quoi que dise `X-Commercial-Reuse`. Un `sv 2` ne
  porte aucune claim de consentement au corpus : sa seule « preuve » serait une
  chaîne choisie par l'appelant. C'est exactement la faille qu'un auditeur a
  exploitée le 2026-09-02 (passe `sv 2` signé + `X-Consent-Version:
  JE-NAI-RIEN-SIGNE` + `X-Commercial-Reuse: true` → HTTP 200 sous `reusable/`).

Dans les deux cas : pas de preuve, pas de stockage.

### `LEGAL_VERSIONS` — le levier de révocation côté écriture

La `cv` d'un passe est recopiée dans `customMetadata.consent_version` : elle est
**la preuve conservée avec le fichier**. Le worker qui écrit doit donc savoir à
quel texte elle renvoie — le contrôle à l'émission (tokeniser) ne suffit pas,
puisque les passes signés circulent ensuite librement.

```toml
# workers/r2-upload/wrangler.toml — mêmes valeurs que côté tokeniser
LEGAL_VERSIONS = "2026-09-02.v1"
```

- **Révoquer une version** : la retirer de la liste → tout nouvel upload qui s'en
  réclame est refusé (403), sans ré-émettre un seul passe. Les objets déjà
  écrits ne sont pas touchés.
- **Publier une nouvelle version** : ajouter la nouvelle (`"ancienne,nouvelle"`)
  le temps que les passes en circulation se renouvellent, puis retirer l'ancienne.
- **Vider la liste** ferme le worker en `sv 3` (500). C'est voulu.

## Fragments de clé : refusés, pas nettoyés

`X-Session-Id`, `X-Text-Id`, `X-Layer`, `X-Record-Type` et `X-Language` doivent
respecter `^[A-Za-z0-9_-]{1,80}$` ; sinon **400** `FIELD_FORMAT`, rien n'est
écrit. Un en-tête facultatif absent retombe sur son défaut.

L'ancienne version *supprimait* les caractères interdits : `sess/1` et `sess?1`
se repliaient tous deux sur `sess1`, donc deux sessions distinctes finissaient
dans le **même dossier R2**. Un effacement art. 17 ciblé sur l'une emportait
l'autre — ou la manquait. La granularité de l'effacement suppose une clé
injective : un nom qu'on ne peut pas écrire fidèlement doit être refusé.

## RGPD — opérations courantes

Toutes les opérations par utilisateur passent par son `account`, qu'on ne peut
calculer **qu'à partir de son passe** (`account = SHA-256(nonce)[0:32]`) — c'est
la contrepartie de l'anonymat par conception : sans le passe, la personne n'est
pas retrouvable chez nous (art. 11 RGPD).

**Droit à l'effacement (art. 17)** — supprimer tout l'audio d'un utilisateur :

```bash
# Bucket EU → le flag --jurisdiction eu est requis sur CHAQUE commande.
wrangler r2 object delete mentality-audio --jurisdiction eu --prefix "reusable/<account>/"
wrangler r2 object delete mentality-audio --jurisdiction eu --prefix "internal/<account>/"
```

L'effacement n'est possible que **tant que le fichier est chez nous** : une fois
l'enregistrement intégré au corpus ou cédé à un tiers, il ne peut plus être
retiré (c'est exactement ce que le texte de consentement annonce).

**Droit à la portabilité (art. 20)** — exporter les données d'un utilisateur :

```bash
rclone copy r2:mentality-audio/internal/<account>/ ./export/<account>/
rclone copy r2:mentality-audio/reusable/<account>/ ./export/<account>/
```

**Cession commerciale** — n'exporter QUE les fichiers cessibles :

```bash
rclone copy r2:mentality-audio/reusable/ ./lot-cessible/
```

## Auto-test

```bash
node workers/r2-upload/scripts/selftest.mjs   # depuis la racine du dépôt
```

Aucun réseau, aucun compte Cloudflare : le worker est importé tel quel et
branché sur un bucket R2 en mémoire. Il verrouille notamment :

- le refus des passes non signés (aucun repli DEV `M2.` ici) ;
- **qu'un passe `sv 2` n'atteint jamais `reusable/`** — l'exploit prouvé est
  rejoué tel quel, en-têtes menteurs et `Origin` absent compris, avec ses
  variantes de casse et de graphie ;
- qu'en `sv 3` un en-tête mensonger ne fait pas basculer un fichier dans
  `reusable/`, et que le chemin légitime `free`/`cc:true` y reste ouvert ;
- qu'une `cv` hors `LEGAL_VERSIONS` est refusée (403) et qu'une liste absente
  ferme le worker (500), sans rien écrire dans les deux cas ;
- qu'un fragment de clé hors format est refusé (400) au lieu d'être nettoyé.

**À lancer avant chaque `wrangler deploy`.**

## Sécurité / limites

- Passe signé Ed25519 **obligatoire** (`X-Mentality-Token`), re-vérifié côté
  serveur ; aucun repli sur un passe DEV non signé.
- Compartiment de stockage dérivé du nonce signé, jamais d'un identifiant
  fourni par le client.
- Origines restreintes (`ALLOWED_ORIGINS`) ; une requête sans `Origin` (client
  mobile natif) est acceptée, l'authentification reposant sur le passe.
- Taille max 25 Mo par fichier.
- Noms de clés **refusés s'ils sortent du format** (400), jamais assainis en
  silence : deux sessions distinctes ne peuvent pas fusionner dans un même
  dossier, ce qui préserve la granularité de l'effacement (art. 17).
- Couche `reusable/` accessible uniquement sur claims signées `sv ≥ 3`
  (`p='free'` ∧ `cc=true` ∧ `cv` ∈ `LEGAL_VERSIONS`).
