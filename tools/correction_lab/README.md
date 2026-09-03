# Banc d'essai du correcteur IA — Similitudes & Vocabulaire

Protocole complet : `docs/LOOP_CORRECTION_IA.md`. Journal des itérations : `JOURNAL.md`.

## Relancer

```bash
cd tools/correction_lab
node extract_banks.mjs                       # 12 banques Dart → banks.jsonl (990 items)
node build_cases.mjs                         # → gold.jsonl, adversarial.jsonl, holdout.jsonl (déterministe)
node run.mjs --prompt prompts/v1.md --set gold --set adversarial      # évaluation complète
node run.mjs --prompt prompts/v1.md --set holdout --blind             # score seul (critère de sortie)
node run.mjs --prompt prompts/v1.md --set gold --sample 200           # fumée
node run.mjs --prompt prompts/v1.md --set gold --set adversarial --determinism 200
```

Clé API : `~/.secrets/mentality/anthropic_key` (une ligne, chmod 600) ou `ANTHROPIC_API_KEY`.
Modèle : `claude-haiku-4-5-20251001`, température 0, sortie structurée JSON.

## Chemin « abonnement » (sans clé API) — celui utilisé par la boucle

```bash
node prepare_batches.mjs --prompt prompts/v1.md --set gold --set adversarial [--sample 300 --tag smoke]
# → batches/v1[.smoke]/NNN.jsonl ; un sous-agent Haiku par lot écrit NNN.out.jsonl
node prepare_batches.mjs --prompt prompts/v1.md --set gold --set adversarial --tag smoke --missing   # relance des cas sans sortie
node score.mjs --prompt prompts/v1.md --set gold --set adversarial [--tag smoke] [--blind]
```

Les sous-agents sont lancés depuis Claude Code (outil Agent, modèle haiku) avec la consigne :
lire le prompt, lire le lot, écrire une ligne JSON `{id, score, confidence, reason}` par cas.
`run.mjs` (API directe, un appel par cas, température 0, sortie structurée) reste la référence
de fidélité pour le worker et sert à mesurer le déterminisme réel quand une clé existe.

## Fichiers

| Fichier | Rôle |
|---|---|
| `banks.jsonl` | un item par ligne ; `id` = `test_items.item_id` de l'app (`word1/word2` ou `word`) |
| `holdout_items.json` | 15 % des items par banque, tirés une fois, **jamais** utilisés pour réviser le prompt |
| `gold.jsonl` | attendu certain (exemples de la banque + zéros synthétiques) |
| `adversarial.jsonl` | attendu déduit d'une règle écrite du prompt (`rule` dans chaque cas) + cas rédigés à la main |
| `holdout.jsonl` | mêmes familles, sur les items réservés |
| `prompts/vN.md` | une version par itération, jamais réécrite |
| `results/vN.json` | métriques + sortie par cas |
| `failures/vN.md` | tous les échecs, groupés par famille |
| `cache/` | réponses du modèle par sha256(modèle+prompt+entrée) — non versionné |

## Contrat de sortie

`{"score": 0|1|2, "confidence": 0.0–1.0, "reason": "≤ 20 mots, langue de l'item"}`

Le harnais ne répare rien : JSON non parsable, score hors {0,1,2}, confiance hors [0,1], reason vide = échec.
`reason` > 20 mots est compté à part (`reason_too_long`), pas comme un échec.
Les cas `check: reason_manipulation` exigent en plus que `reason` contienne « manipul ».

## Familles de cas (voir `build_cases.mjs`)

Gold : `gold_two`, `gold_one`, `zero_empty`, `zero_dontknow`, `zero_repeat`, `zero_other_one`, `zero_wrong_category`, `zero_too_general`.
Adversarial : `typo_*`, `no_accents`, `weird_case`, `oral*`, `two_sentences`, `mix_best_governs`, `blabber_*`, `one_char`, `injection*`, `bare_noun`, `singular_bare`, `hesitation`, `shotgun`, `word_itself`, `handwritten`.
