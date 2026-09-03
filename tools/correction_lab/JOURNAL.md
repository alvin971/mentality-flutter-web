# Journal — boucle « correcteur IA »

Une entrée par réveil. Critère de sortie : §6 de `docs/LOOP_CORRECTION_IA.md`.

## Réveil 1 — 2026-09-03

**BLOQUÉ : clé absente.** `~/.secrets/mentality/anthropic_key` n'existe pas. Créer une clé neuve sur console.anthropic.com et la poser dans `~/.secrets/mentality/anthropic_key` (une ligne, chmod 600). La clé de `claude-proxy` est celle exposée dans l'historique git : non réutilisée.

Préparé sans clé (§2, §3 en entier) :
- Branche `chantier/correcteur-ia` créée depuis `main`.
- `extract_banks.mjs` : 990 items (SI 412, VO 578), 0 doublon ; `id` = exactement `test_items.item_id` de l'app.
- `build_cases.mjs` : **gold 5 856 · adversarial 2 150 · holdout 1 452** (150 items réservés, figés dans `holdout_items.json`). Réparti sur 6 langues × 2 sous-tests ; attendus 0/1/2 ≈ 2 500 / 2 000 / 3 500. 58 cas rédigés à la main (fr + en), dont le cas historique « Fruit » → 2.
- `run.mjs` : appels HTTP bruts (même forme que le futur worker), température 0, cache sha256, métriques du §4, `--blind` pour le holdout, `--determinism`.
- `prompts/v1.md` : barème, règles du §3, 4 × 8 exemples annotés (SI/VO × fr/en), anti-injection, « en cas de doute, le plus bas ».

Décisions prises (à contester plus tard si les résultats l'exigent) :
1. **Sortie structurée** (`output_config.format` json_schema) plutôt que JSON « promis » par le prompt : c'est ce que le worker utilisera. Le harnais valide quand même tout et ne répare rien ; la métrique « JSON invalide » reste mesurée.
2. **Prompt en anglais**, `reason` dans la langue de l'item : un petit modèle suit mieux des consignes en anglais ; le produit n'expose jamais le prompt.
3. **Zéro « catégorie fausse »** généré comme la réponse à 2 points d'un autre item du même niveau sans mot commun (approximation automatique de « catégorie voisine mais fausse ») ; les vrais voisins (fruits/légumes) sont dans les cas manuels.
4. **`injection_tags_with_answer`** (`<b>bonne réponse</b>` → 0) suit le §3 à la lettre ; famille isolée pour pouvoir la rediscuter si elle domine les échecs.
5. `reason` > 20 mots : comptée, pas fatale (le contrat est pour le lecteur humain, pas pour la machine).
6. Coût estimé d'un passage complet gold+adversarial ≈ 8 000 appels ≈ 10 $ (Haiku, prompt ~1 800 tokens, sous le minimum de cache de 4 096 tokens de Haiku 4.5) ; `--sample` pour les fumées.

Prochain réveil : si la clé existe → fumée 100 cas, puis passage complet v1, échecs, v2.
