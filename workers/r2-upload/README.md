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
reusable/<sessionId>/<layer>-<recordType>-<textId>-<timestamp>.<ext>   ← cessible (consentement commercial)
internal/<sessionId>/<layer>-<recordType>-<textId>-<timestamp>.<ext>   ← usage interne uniquement
```

Chaque objet porte aussi des `customMetadata` (consent_version, commercial_reuse,
durée, langue, session…).

## RGPD — opérations courantes

**Garde-fou intégré** : sans en-tête `X-Consent-Version`, l'upload est refusé
(403). Impossible de stocker un fichier sans base légale.

**Droit à l'effacement (art. 17)** — supprimer tout l'audio d'un utilisateur :

```bash
# Bucket EU → le flag --jurisdiction eu est requis sur CHAQUE commande.
wrangler r2 object delete mentality-audio --jurisdiction eu --prefix "reusable/<sessionId>/"
wrangler r2 object delete mentality-audio --jurisdiction eu --prefix "internal/<sessionId>/"
```

**Droit à la portabilité (art. 20)** — exporter les données d'un utilisateur :

```bash
rclone copy r2:mentality-audio/internal/<sessionId>/ ./export/<sessionId>/
rclone copy r2:mentality-audio/reusable/<sessionId>/ ./export/<sessionId>/
```

**Cession commerciale** — n'exporter QUE les fichiers cessibles :

```bash
rclone copy r2:mentality-audio/reusable/ ./lot-cessible/
```

## Sécurité / limites

- Origines restreintes (`ALLOWED_ORIGINS`).
- Taille max 25 Mo par fichier.
- Noms de clés assainis (anti-injection de chemin).
- À renforcer en prod : authentifier la requête (token de session signé) pour
  éviter qu'un tiers poste dans ton bucket depuis une origine autorisée.
