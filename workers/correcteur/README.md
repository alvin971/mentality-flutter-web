# mentality-correcteur — correcteur IA des sous-tests à réponse libre

Worker Cloudflare qui note **Points communs (Similitudes)** et **Vocabulaire**
après coup. L'app enregistre les réponses telles quelles avec
`scoring_status = 'ai_pending'` (migration 017) ; ce worker passe toutes les
10 minutes, note chaque réponse avec **Claude Haiku 4.5 à température 0**, puis
bascule la ligne en `'ai_scored'` (migration 019 pour les colonnes de suivi).

Le prompt et son banc d'essai vivent dans `tools/correction_lab/` — le fichier
`prompt.js` ici est **généré** depuis `prompts/FINAL.md`, ne pas l'éditer.

## Ce que fait un passage

1. Lit jusqu'à `BATCH_ROWS` lignes `test_results` en attente, complètes, sous
   le plafond de tentatives, dans l'ordre d'arrivée.
2. Pour chaque ligne : charge ses `test_items` (ordre d'administration), déduit
   la **langue par vote** des `item_id` sur les 6 banques, résout tous les items
   dans la banque **avant** le premier appel.
3. Note item par item. Réponse vide ou sautée → 0 sans appel. Après **trois 0
   consécutifs**, tout ce qui suit vaut 0 sans appel (règle d'arrêt post-hoc :
   l'app ne s'arrête plus, le worker applique la règle au calme).
4. Écrit **tous** les items (`score`, `ai_confidence`) puis la ligne
   (`raw_score`, `max_score = 2 × items`, `'ai_scored'`, `ai_scored_at`,
   `ai_review` si une confiance < `REVIEW_THRESHOLD`).
5. Toute erreur (JSON invalide du modèle, panne d'API, item hors banque, langue
   indécidable) → **rien d'écrit**, `ai_attempts + 1`, la ligne reste
   `'ai_pending'`. Au plafond `MAX_ATTEMPTS` → `ai_review = true`, ignorée
   ensuite. Jamais de demi-score.

Rejouer un passage est sans effet : une ligne notée n'est plus sélectionnée.

## Routes

| Route | Auth | Rôle |
|---|---|---|
| `GET /health` | — | version du prompt, format d'entrée, modèle |
| `POST /run?limit=N` | `X-Admin-Secret` | déclenche un passage à la main, renvoie le résumé |
| cron `*/10 * * * *` | — | passage automatique |

## Secrets et variables

Secrets (`wrangler secret put …`) :

| Secret | Valeur |
|---|---|
| `SUPABASE_URL` | URL du projet Supabase (`https://<ref>.supabase.co`) |
| `SUPABASE_SERVICE_KEY` | clé *service_role* (contourne la RLS — ce worker écrit) |
| `ANTHROPIC_API_KEY` | **clé NEUVE**, jamais celle de `claude-proxy` (exposée dans l'historique git, à révoquer) |
| `ADMIN_SECRET` | chaîne aléatoire longue pour `POST /run` |

Variables (`wrangler.toml`) : `BATCH_ROWS` (40), `MAX_ATTEMPTS` (5),
`REVIEW_THRESHOLD` (0.6), `MODEL` (`claude-haiku-4-5-20251001`).

## Déployer

```bash
# 1. Migration côté admin (jamais ici) — mentality-admin/supabase/migrations/019_ai_correcteur.sql
# 2. Assets à jour
node tools/correction_lab/export_worker_assets.mjs
# 3. Auto-test (zéro réseau) — doit finir sur « 0 échouées »
node workers/correcteur/scripts/selftest.mjs
# 4. Secrets
cd workers/correcteur
wrangler secret put SUPABASE_URL
wrangler secret put SUPABASE_SERVICE_KEY
wrangler secret put ANTHROPIC_API_KEY
wrangler secret put ADMIN_SECRET
# 5. Répétition puis déploiement
wrangler deploy --dry-run
wrangler deploy
# 6. Premier passage à la main, sur 5 lignes
curl -X POST -H "X-Admin-Secret: $ADMIN_SECRET" "https://mentality-correcteur.<compte>.workers.dev/run?limit=5"
```

## Journal

Une ligne JSON par ligne traitée (`correcteur.row`) et par passage
(`correcteur.cron` / `correcteur.run`) : identifiants de session, sous-test,
langue, nombre d'appels, code d'erreur. **Aucune réponse de personne** n'est
journalisée.

## Coût

Un item = un appel Haiku (~1 800 tokens d'entrée, ~40 de sortie). Un bilan
complet (21 + 30 items, moins la règle d'arrêt) ≈ 50 appels ≈ 0,1 ¢ US. Le
prompt (~1 800 tokens) est **sous le minimum de cache** de Haiku 4.5 (4 096) :
`cache_control` est posé mais ne s'active pas ; sans effet sur le coût ci-dessus.
