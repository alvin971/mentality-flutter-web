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
