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

### Réveil 1 bis — pivot « abonnement » (décision fondateur, 2026-09-03)

Le fondateur ne veut pas de clé API : **le banc d'essai tourne sur des sous-agents Haiku lancés depuis Claude Code** (abonnement, coût nul). Nouveau chemin :
- `prepare_batches.mjs` découpe le jeu en lots de 50 cas (`batches/<version>[.tag]/NNN.jsonl`, sans l'attendu) ;
- un sous-agent Haiku par lot lit `prompts/vN.md` puis le lot, écrit `NNN.out.jsonl` ;
- `score.mjs` agrège, valide (même contrat strict), produit `results/` et `failures/`.

Ce que ça change dans la mesure (à garder en tête au moment de lire les chiffres) :
1. Le sous-agent reçoit 50 cas dans un même contexte au lieu d'un cas par appel : les cas peuvent s'influencer malgré la consigne d'indépendance. Le worker, lui, fera un appel par réponse.
2. Température non contrôlée (harnais Claude Code), pas de sortie structurée forcée : le **déterminisme mesuré ici est une borne pessimiste** ; le vrai chiffre sera mesuré au §7 avec `run.mjs` (conservé, même contrat) dès qu'une clé existe pour le worker.
3. Le modèle « haiku » du harnais est Haiku 4.5, comme le worker.

Fumée lancée : 300 cas gold+adversarial, 6 lots, tag `smoke`.

**Fumée v1 (300 cas, 6 lots de 50, sous-agents Haiku)** : exactitude **96,67 %** · sur-notation 1,33 % · sous-notation 1,33 % · 2 sans sortie (préfixe d'id mal recopié par l'agent, réparé par suffixe dans `score.mjs`) · kappa 0,958 · reason > 20 mots : 0. Par langue : de 97,1 · en 98,4 · en_gb 97,7 · es 98,1 · fr 95,4 · pt 92,7. SI 96,0 · VO 97,1.

Les 10 échecs, classés :
- (a) prompt ambigu — `mix_best_governs` (2) : « X, remarque hors sujet » lu comme une hésitation. v2 : n'est un candidat concurrent que ce qui est présenté comme alternative (« ou »), une remarque juxtaposée ne crée pas d'hésitation. `injection_tags_with_answer` (2) : balises ignorées. v2 : exemple explicite `<b>des fruits</b>` → 0.
- (b) attendu discutable — `zero_wrong_category` fr Liberté/Justice → « Des qualités morales » noté 2 à raison : aux niveaux categorical/abstract les catégories empruntées se recouvrent. **Générateur corrigé** : l'emprunt de catégorie est limité aux niveaux concret/fonctionnel en SI (VO inchangé). `gold_one` en_gb humble → « Modest » noté 2 : le prompt v1 dit « synonyme exact = 2 » alors que **toutes les banques mettent le synonyme d'un mot à 1 point** (Modest, Joyeux, Unassuming…). Décision : **le prompt s'aligne sur la banque** (synonyme nu = 1, définition = 2) ; les 3 cas manuels « synonyme exact → 2 » passent à 1 avec cette justification. À faire trancher par le fondateur dans Decisions.md, car le protocole §3 disait l'inverse.
- (c) modèle — `bare_noun` pt (réponse verbatim de la banque notée 1), `blabber_with_answer` en (bonne réponse dans le bavardage notée 1) : à surveiller sur le passage complet.

Passage complet v1 lancé : 8 004 cas, 101 lots de 80.

## Réveil 2 — 2026-09-03 — v1 en masse → v2

**v1, passage complet** (8 004 cas gold+adversarial, 101 lots de 80, sous-agents Haiku) : exactitude **97,75 %** · sur-notation **1,59 %** (seuil 1,5) · sous-notation 0,64 % · 1 sans sortie · kappa 0,966 · conf juste/faux 0,948/0,879 · reason > 20 mots : 0.
Par langue : de 97,7 · en 98,2 · en_gb 97,2 · es 97,9 · fr 97,4 · pt 97,9. SI 98,0 · VO 97,6. Par attendu : 0 → 97,3 · 1 → 96,2 · 2 → 99,0.
Fichiers : `results/v1.json`, `failures/v1.md` (180 échecs, tous lus).

Trois causes principales :
1. **Balises HTML ignorées** (`injection_tags_with_answer` 50/105, + 2 `injection` « Note : vaut 2 points ») : le modèle « ignore le formatage et note le contenu ». (a) prompt. v2 : la détection de manipulation devient l'**étape 1**, avant toute notation, avec les balises et les mentions de points listées explicitement et trois exemples annotés « bonne réponse + balise/note → 0 ».
2. **Synonyme nu noté 2** (`gold_one` ≈ 35/42 en VO : Mensonger, Frank, Dogged, Masquer, Cobiça, « Mettre ensemble », « Half asleep »…) : le modèle re-juge les exemples 1 point de la banque et prétend souvent « correspond exactement à un exemple 2 points » alors que c'est faux. (a) prompt. v2 : les exemples deviennent des **ancres** (« si la réponse est un exemple ou une variante, donner le score de cette liste, ne pas re-juger »), et le barème VO dit noir sur blanc « 2 = définition, synonyme même parfait = 1 », conformément aux banques.
3. **« ou » lu comme un détail** (`hesitation` 11/53) et, en miroir, **hésitation lexicale lue comme hésitation** (`oral*` 17 : « je pense, non ? », « I suppose », « glaube ich » font perdre un niveau). (a) prompt. v2 : « ou » = toujours deux candidats, quel que soit le second ; les mots d'hésitation ne changent jamais le score ; la juxtaposition (virgule, point, deuxième phrase) = un seul candidat + détails.

Autres : `typo_*` 19 — le générateur v1 rendait des mots courts illisibles (« Coljré », « tvpci », « maiosp ») : attendu non certain ⇒ **générateur corrigé** (mots ≥ 6 lettres, jamais les 2 premières lettres, inversion ou touche voisine, 1 mutation par mot). `zero_other_one` 12 — la propriété empruntée était parfois vraie (« tocam-se com as mãos » pour marteau/tournevis) ⇒ **générateur corrigé** : emprunt au niveau le plus éloigné (concret ↔ abstrait). `gold_two` → 1 (7) : le modèle prétend un « exemple 1 point » inexistant ⇒ règle « lire toute la liste, ne jamais inventer une correspondance ; si présent dans les deux listes → 2 ». Propriétés subjectives (« c'est joli » → 0 par le modèle, 1 dans la banque) ⇒ règle « toute propriété vraie des deux compte, même subjective ». `zero_wrong_category` 3 — emprunts vrais au niveau concret (« instruments » pour marteau/tournevis) : bruit résiduel accepté, non retiré.

Cas retirés : aucun. Cas dont l'attendu change : les 3 cas manuels « synonyme exact » (2 → 1, décidé au réveil 1 bis, confirmé par 35 échecs `gold_one` qui vont dans le même sens).

v2 lancée sur gold+adversarial régénérés (mêmes items, mêmes familles ; ids renumérotés).

## Réveil 3 — 2026-09-03 — v2 en masse + holdout → v3

**v2, passage complet** (7 973 cas, 100 lots + relance de 12 cas omis par des agents) : exactitude **98,86 %** · sur-notation **0,31 %** · sous-notation **0,83 %** · 0 invalide · kappa 0,983 · conf juste/faux 0,953/0,823.
Par langue : de 98,6 · en 98,5 · en_gb 99,2 · es 98,9 · fr 98,2 · pt 99,3. SI 98,8 · VO 98,7. Par attendu : 0 → 99,3 · 1 → 99,1 · 2 → 98,2.
**v2, holdout en aveugle** (1 446 cas, 150 items jamais vus pendant le tuning) : exactitude **99,03 %** · sur-notation 0,35 % · sous-notation 0,62 % · 0 invalide · kappa 0,985. Toutes langues ≥ 91,6 → après relance du lot manquant, toutes ≥ 96 (chiffre global 99,03). Pas de sur-apprentissage : le holdout fait mieux que le jeu de tuning.

→ v2 **satisfait tous les seuils du §6** sur gold+adversarial ET holdout. Manquent : déterminisme (≥ 99 %, mesuré sur 200 cas × 3) et stabilité (3 passages consécutifs).

Les 102 échecs de v2 (91 valides + 11 omissions d'agents relancées), classés :
1. **Confusion des deux listes d'exemples** (`gold_two` 14, `typo_two` 5, `no_accents` 2, `gold_one` 6) : le modèle note 1 des réponses **verbatim** de la liste 2 points en affirmant « exact match to examples_1_point » (confiance 0,95–1). Les noms `examples_2_points`/`examples_1_point` se ressemblent trop pour Haiku. (a)+(c). **v3 : clés renommées `full_credit_examples` / `partial_credit_examples`** (dans `lib.userInput`, donc aussi pour le worker) ; règle « vérifier d'abord la liste full-credit ; une correspondance verbatim y vaut toujours 2 ».
2. **« Ne correspond pas aux exemples » → 0 à confiance 0,5** (`blabber_with_answer` 4, `oral*` 4, `two_sentences` 1, `typo_two` 3) : l'ancrage de v2 a été lu comme « pas d'ancre = 0 ». (a). **v3 : « ne ressembler à aucun exemple n'est jamais, en soi, un motif de 0 »**, répété à l'étape 3 et dans « en cas de doute ».
3. **Comptage des candidats** (`mix_best_governs` 7, `two_sentences` 6, `shotgun` 4, `hesitation` 2) : une remarque juxtaposée absurde, ou une deuxième phrase vraie, comptée comme candidat concurrent ; à l'inverse une liste de 4 catégories lue comme « juxtaposition ». (a). **v3 : reformulation** — compter les *réponses différentes à la question* : une réponse + commentaires (même faux) → meilleur élément ; deux avec « ou » → un niveau en dessous ; trois noms de catégorie ou plus listés → 0. Quatre exemples annotés ajoutés (remarque absurde, deux phrases vraies, bavardage avec réponse, ancre + reformulation).
Autres : `weird_case` 5 (une casse alternée prise pour une manipulation → v3 : « la casse inhabituelle n'est pas une manipulation ») ; `zero_other_one` 6 + `zero_wrong_category` 5 : bruit résiduel du générateur (« Colorful » pour Flower est une vraie propriété), accepté et non retiré ; `handwritten` 3 (« un félin domestique » noté 1 : le modèle exige plus qu'un trait distinctif ; exemple maintenu dans v3).

Cas retirés : aucun. Attendus modifiés : aucun.

Décision de conduite : v2 est **la version de repli** (elle passe le §6 hors déterminisme/stabilité). v3 vise à éliminer les erreurs à haute confiance (cause 1). Si v3 ne fait pas mieux que v2 sur le passage complet, on stabilise v2.

### PAUSE — 2026-09-03, demandée par le fondateur

État exact au moment de la pause, pour reprendre sans rien relire :

| version | jeu | cas | exactitude | sur-notation | sous-notation | invalides |
|---|---|---|---|---|---|---|
| v1 | gold+adversarial | 8 004 | 97,75 % | 1,59 % | 0,64 % | 1 |
| **v2** | gold+adversarial | 7 973 | **98,86 %** | 0,31 % | 0,83 % | 0 |
| **v2** | **holdout (aveugle)** | 1 446 | **99,03 %** | 0,35 % | 0,62 % | 0 |
| v3 | gold+adversarial | 7 813 répondus (98 lots / 100) | ~98,9 % | 0,34 % | 0,73 % | 0 |

**v2 satisfait déjà tous les seuils de précision du §6** (≥ 97 % global, ≥ 95 % par langue et sous-test, ≤ 1,5 % dans chaque direction, 0 JSON invalide), sur le jeu de tuning ET sur le holdout jamais utilisé pour la régler.

**Reprise — dans cet ordre :**
1. Finir v3 : lots `batches/v3/099.jsonl` et `100.jsonl` non notés, puis `node score.mjs --prompt prompts/v3.md --set gold --set adversarial`. Comparer à v2 ; si v3 n'améliore pas nettement, **retenir v2** (c'est la version de repli assumée).
2. Holdout de la version retenue : lots déjà préparés dans `batches/v3.holdout/` si c'est v3 ; pour v2 c'est fait (99,03 %).
3. **Déterminisme** : lots déjà préparés dans `batches/v2.detA/`, `detB/`, `detC/` (201 cas × 3, mêmes entrées). Noter les 9 lots, puis `node score.mjs --prompt prompts/v2.md --set gold --set adversarial --tag detA` (idem detB, detC) et `node determinism.mjs --prompt prompts/v2.md`. Seuil : ≥ 99 %.
4. **Stabilité** : la même version doit tenir les seuils sur 3 passages consécutifs, ordre des cas mélangé (la graine change à chaque `prepare_batches.mjs`).
5. Puis §7 : worker `workers/correcteur/`, migration admin 018, selftest ≥ 40 assertions, `wrangler deploy --dry-run` sans déployer.

Tout est sur la branche `chantier/correcteur-ia`, poussée. Rien sur `main`. Aucun déploiement.

## Réveil 4 — 2026-09-03 — reprise : v3 complète, déterminisme, stabilité

**v3, passage complet** (7 973 cas) : exactitude **98,51 %** (98,8 % sur les 7 951 répondus) · sur-notation 0,38 % · sous-notation 0,73 % · 22 omissions d'agents · kappa 0,983. Par langue : de 99,2 · en 98,2 · en_gb 99,0 · es 98,2 · fr 98,0 · pt 99,2.
Comparaison ciblée v2 → v3 : `gold_two` 99,44 → 98,40 (la poche « exemple 2 points noté 1 » s'est **aggravée**), `gold_one` 99,58 → 98,99, `injection_tags_with_answer` 100 → 98,1. Le renommage des listes n'a pas aidé : le modèle s'ancre sur le **fragment** d'exemple 1 point contenu dans l'exemple 2 points (« économe, qui se contente de peu » ⊃ « économe »). C'est un biais de lecture du modèle, pas une ambiguïté du prompt. Une v4 « ancrer sur l'exemple le plus long » reste possible, mais **v2 est meilleure sur tous les axes** : décision, **v2 retenue**, v3 abandonnée.

**Déterminisme v2** : 201 cas × 3 rejouages indépendants → **99,5 %** d'accord (1 désaccord : `adversarial-04611`, 2/2/1). Seuil ≥ 99 % atteint, sur le chemin sous-agents (borne pessimiste : température non contrôlée ; l'API à température 0 fera au moins aussi bien).

**Stabilité** : passage 1 = `results/v2.json` (98,86 %). Passages 2 et 3 lancés (`batches/v2.stab2/`, `batches/v2.stab3/`, ordres mélangés, graines 1749754737 / 1749754907).

Bilan du §6 pour v2 : exactitude ✔ (98,86 / 99,03 holdout) · par langue et sous-test ✔ (min 98,2) · sur/sous-notation ✔ (0,31 / 0,83) · JSON invalide ✔ (0) · déterminisme ✔ (99,5) · stabilité : en cours.

## Réveil 5 — 2026-09-03 — stabilité : passages 2 invalidé puis refait, worker §7 construit

**Invalidation de `stab2`/`stab3`.** Les lots avaient été générés avec les clés d'entrée de v3 (`full_credit_examples` / `partial_credit_examples`) alors que v2 attend `examples_2_points` / `examples_1_point` : le prompt n'aurait pas retrouvé ses listes d'ancrage. Les ~47 lots déjà notés de `stab2` sont **jetés**, pas comptés. Correctif structurel : le format d'entrée est désormais **dicté par le texte du prompt** (`lib.inputFormatOf`) dans `prepare_batches.mjs`, `run.mjs` et le manifeste — plus jamais choisi à la main. Passages régénérés : `v2.stabB` (graine 1750179848) et `v2.stabC`, format `points`, ordres mélangés.

**Passage 2 (`stabB`, 7 973 cas, 1 relance de 32 omissions)** : exactitude **99,13 %** · sur-notation 0,21 % · sous-notation 0,60 % · invalides 0 · kappa 0,9875 · conf juste/faux 0,95/0,88. Par langue : de 99,5 · en 99,1 · en_gb 99,5 · es 99,5 · **fr 98,35** · pt 99,5. Par sous-test : SI 99,2 · VO 99,1. Tous les seuils du §6 tenus ; le point bas reste le français (sous-notation 1,19 %, poche `gold_two` inchangée).

**Passage 3 (`stabC`)** : en cours, résultat ci-dessous.

**Worker §7, construit pendant les passages** (`workers/correcteur/`) :
- `export_worker_assets.mjs` → `banks.json` (990 items, 356 Ko, embarqué dans le bundle : pas de KV, une seule source de vérité versionnée avec le prompt) et `prompt.js` (généré depuis `prompts/FINAL.md`).
- `index.js` : cron toutes les 10 min + `POST /run` (secret admin, comparaison à temps constant), lot de 40 lignes, langue par **vote** des `item_id` (18 collisions / 972 ids, jamais entre en et en_gb ; « Orange/Banane » existe en fr ET en de → une session d'un seul item ambigu est différée, ce qui n'arrive pas en pratique : ≥ 3 items par sous-test), résolution de tous les items **avant** le premier appel, règle d'arrêt post-hoc (3 zéros → 0 sans appel), vide/sauté → 0 sans appel, écriture atomique du point de vue métier (items puis ligne ; toute erreur → rien d'écrit, `ai_attempts + 1`, plafond → `ai_review`). Appel API brut (Haiku 4.5, T = 0, sortie structurée `json_schema`, retries 429/5xx ×3, timeout 30 s). Aucune réponse de personne dans les journaux.
- `scripts/selftest.mjs` : **94 assertions, 0 échec**, zéro réseau (fetch intercepté : Supabase en mémoire, Anthropic scripté). Pièges rencontrés en l'écrivant : `*/` dans un commentaire d'en-tête fermait le bloc ; `import … from './banks.json'` exige `with { type: 'json' }` sous Node 22 (esbuild/wrangler l'accepte) ; `new Response('', {status: 204})` est refusé par undici (corps interdit) → `null`.
- `wrangler deploy --dry-run` : **compile**, 394 Ko (125 Ko gzip), 4 variables liées. Pas déployé.
- Migration **019** commitée dans `mentality-admin` sur `chantier/correcteur-ia` (`8f8f1ef`) : `test_items.ai_confidence`, `test_results.ai_attempts/ai_review/ai_scored_at`, index partiel de file, vue `ai_review_queue`.
- App (§7.5) : `CompleteTestResultsPage` **omettait** silencieusement une ligne SI/VO sans score. Ajout de `CompleteTestSession.awaitsAiScore()` + libellé `ctScorePending` (6 langues, via `l10n_fragments/` + `_merge.py` + `gen-l10n`) affiché dans les scores standardisés et dans le repli brut ; 5 tests unitaires. `flutter test` complet en cours.

**Passage 3 (`stabC`, 7 973 cas, 1 relance de 2 omissions)** : exactitude **98,96 %** · sur-notation 0,25 % · sous-notation 0,75 % · invalides 0 · kappa 0,9846. Par langue : de 99,5 · en 98,7 · en_gb 99,6 · es 99,0 · **fr 98,24** · pt 99,5. SI 98,96 · VO 98,96.

## CONVERGÉ — 2026-09-03 — v2 = FINAL

| Critère §6 | Seuil | Passage 1 (`v2`) | Passage 2 (`stabB`) | Passage 3 (`stabC`) | Holdout aveugle |
|---|---|---|---|---|---|
| Exactitude globale | ≥ 97 % | 98,86 % | 99,13 % | 98,96 % | 99,03 % |
| Min. par langue | ≥ 95 % | 98,0 (fr) | 98,35 (fr) | 98,24 (fr) | ✔ |
| Min. par sous-test | ≥ 95 % | 98,7 | 99,1 | 98,96 | ✔ |
| Sur-notation | ≤ 1,5 % | 0,31 % | 0,21 % | 0,25 % | ✔ |
| Sous-notation | ≤ 1,5 % | 0,83 % | 0,60 % | 0,75 % | ✔ |
| JSON invalide | 0 / 1000 | 0 | 0 | 0 | 0 |
| Déterminisme (201 × 3) | ≥ 99 % | 99,5 % | — | — | — |

Trois passages consécutifs, ordres mélangés, même version, tous les seuils tenus : **`prompts/v2.md` copié tel quel en `prompts/FINAL.md`**. Point faible connu et documenté : le français (sous-notation 1,2–1,3 %, poche `gold_two` = ancrage sur un fragment d'exemple 1 point). Mesures prises sur des sous-agents Haiku à température non contrôlée : l'API à T = 0 fera au moins aussi bien.

`export_worker_assets.mjs` relancé depuis FINAL.md (`prompt.js` → `PROMPT_SOURCE = "prompts/FINAL.md"`), auto-test 94/94, `wrangler deploy --dry-run` OK (394 Ko). `flutter test` : 1 100 verts (suite complète hors un fichier) + 11 verts (`questionnaire_runner_upload_test.dart` seul — dans la suite complète il restait bloqué en `tearDownAll` sous la charge des 20 sous-agents, pas un défaut du code).

## Pour le fondateur

Rien n'est déployé ni fusionné. Tout est sur `chantier/correcteur-ia` (app **et** admin).

1. **Clé Anthropic NEUVE** — ne pas réutiliser celle de `claude-proxy` (dans l'historique git, **à révoquer** sur console.anthropic.com).
2. **Migration** : appliquer `mentality-admin/supabase/migrations/019_ai_correcteur.sql` (branche `chantier/correcteur-ia` de l'admin, commit `8f8f1ef` — **locale seulement**, le push a été refusé par les permissions de la session : `cd ~/projects/mentality/mentality-admin && git push -u origin chantier/correcteur-ia`) sur le projet Supabase Cloud `ktrnievuknfhwffbxaog`, AVANT le premier déploiement.
3. **Secrets** (depuis `workers/correcteur/`) :
   ```bash
   wrangler secret put SUPABASE_URL
   wrangler secret put SUPABASE_SERVICE_KEY
   wrangler secret put ANTHROPIC_API_KEY
   wrangler secret put ADMIN_SECRET
   ```
4. **Déployer** :
   ```bash
   node tools/correction_lab/export_worker_assets.mjs && node workers/correcteur/scripts/selftest.mjs
   cd workers/correcteur && wrangler deploy
   ```
   (le binaire wrangler n'est pas dans le PATH sur le VPS : `ls -t ~/.npm/_npx/*/node_modules/.bin/wrangler | head -1`).
5. **Premier passage à la main, sur 5 lignes**, puis vérifier `ai_review_queue` :
   ```bash
   curl -X POST -H "X-Admin-Secret: $ADMIN_SECRET" "https://mentality-correcteur.<compte>.workers.dev/run?limit=5"
   ```
6. **Fusionner** `chantier/correcteur-ia` dans `main` (app) et dans la branche de travail de l'admin — décision du fondateur, jamais de la boucle.
