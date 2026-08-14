# File de production du corpus v2 — à exécuter sans demander de validation

> **Consigne du fondateur (2026-08-13), explicite et permanente :**
> « quand tu as fini tu enchaînes, tu ne me demandes rien, tu relances la production
> pour les 2500 familles ». Ne pas attendre, ne pas faire valider, enchaîner.
> Enregistrer à chaque étape pour qu'aucune perte ne soit possible.

---

## ✅ LIVRÉ EN PRODUCTION — build TestFlight `31782370719` (2026-08-14, succès en 7 min 41)

Branche `claude/french-texts-notes-6cb067`, poussée sur `origin`, **non fusionnée dans `main`**.
Commits : `4da031c` (FR) → `32aae0a` (six langues) → `0af069d` (cycle 2A) → `14ff08b` (câblage app).

L'app sert le corpus v2 : `assets/reading_corpus/{fr,en,en_GB,es,pt,de}.jsonl`, 1000 textes
par langue. Publié par `publish.py`, qui **refuse de publier une langue désalignée**.
989 tests verts.

**Reprise du câblage** : rien à faire, c'est en place. Pour republier après un nouveau cycle :
```bash
python3 tools/corpus_gen/publish.py     # v2/ → assets/, estampille les identifiants
flutter test test/data/reading_corpus_service_test.dart
```

---

## État de la production au 2026-08-14 — **7 100 textes produits**

| Étape | Familles | Volume | État |
|---|---|---|---|
| Cycle 1 — rédaction française | `fam_00001` → `fam_01000` | 1 000 | ✅ commit `4da031c` |
| Cycle 1 — réécritures natives | × 5 langues | 5 000 | ✅ commit `32aae0a` |
| Cycle 2A — rédaction française | `fam_01001` → `fam_02250` | 1 100 / 1 250 | 🟠 **110 lots sur 125**, commit `0af069d` |
| Cycle 2A — **15 lots restants** | familles de `fam_02101` à `fam_02250` | 150 | ⬜ **reprendre ici** |
| Cycle 2B — rédaction française | `fam_02251` → `fam_03500` | 1 250 | ⬜ ensuite |
| Cycle 2 — réécritures natives | 2 500 familles × 5 langues | 12 500 | ⬜ en dernier, par vagues |

**Le cycle 1 est intégralement livré** : 1 000 familles complètes dans les six langues,
assemblées dans `assets/reading_corpus/v2/{fr,en,en_GB,es,pt,de}.jsonl`, 0 rejet,
0 divergence d'unités, temps de lecture homogène (médianes 797–822 caractères).
**Le corpus est utilisable en production tel quel.**

Le français du cycle 2 vit dans `tools/corpus_gen/out/fr/batch_c2_*.jsonl` et n'est
**volontairement pas** assemblé dans `v2/fr.jsonl` : ce fichier reste le corpus aligné.
Il n'accueillera les nouvelles familles que lorsque leurs cinq réécritures existeront.

### Reprise immédiate — les 15 lots du cycle 2A

Coupure à la **limite de session** (remise à zéro 5 h 50 Europe/Berlin), pas la limite
hebdomadaire. Lots manquants : `batch_c2_110` à `batch_c2_124`.

```
Workflow({scriptPath: '<session>/workflows/scripts/corpus-fr-cycle2-a-wf_b03de711-0ce.js',
          resumeFromRunId: 'wf_b03de711-0ce'})
```
Les 130 agents réussis reviennent du cache, seuls les 15 refusés sont rejoués.
Vérifier d'abord `ls tools/corpus_gen/out/fr/batch_c2_*.jsonl | wc -l` — si le compte
est à 125, il n'y a rien à reprendre.

Total visé : **3 500 familles**, soit **21 000 textes** sur six langues.

### ⚠️ Le quota est le facteur limitant, pas la technique

Le cycle 1 (6 000 textes) a consommé **37 millions de tokens de sous-agents** et épuisé la
limite hebdomadaire à 70 % des réécritures. Le cycle 2 pèse **2,5 fois plus**. Il faudra
donc **plusieurs fenêtres hebdomadaires** : découper en runs qui tiennent dans une fenêtre,
committer après chacun, reprendre à la suivante. Ne pas relancer un gros run juste après une
coupure : les agents échouent en masse sans rien produire.

### Reprise du rattrapage

Les lots manquants par langue sont dans `tools/corpus_gen/out/lots_manquants.json`
(≈30 lots par langue, familles `fam_00691` à `fam_01000`). Deux voies :

```bash
# voie 1 — reprise du run interrompu : les 346 agents réussis reviennent du cache,
# seuls les 154 refusés sont rejoués
Workflow({scriptPath: '<session>/workflows/scripts/corpus-traductions-natives-wf_05fd3cc4-82e.js',
          resumeFromRunId: 'wf_05fd3cc4-82e'})
```

Voie 2 — nouveau workflow ciblant uniquement les lots de `lots_manquants.json`
(plus économe : ~155 agents au lieu de 500 même en cache).

---

## Paramètres du cycle 2

**Rédaction française — 2 500 textes**

- Familles `fam_01001` à `fam_03500`, identifiants `fr_01001` à `fr_03500`.
- 20 domaines × 5 sous-lots... porté à **250 lots de 10 textes** (soit 12 à 13 lots
  par domaine au lieu de 5).
- Index de départ d'un lot : `famStart = 1000 + (lot * 10) + 1`.
- Fichiers de sortie : `tools/corpus_gen/out/fr/batch_c2_<NNN>.jsonl`.
- **Liste des bannis** : reprendre `tools/corpus_gen/out/bannis_fr.txt`, régénérée par
  `gates.py --emit-banned` à la fin du cycle 1. C'est le mécanisme anti-répétition :
  sans elle, le cycle 2 reproduira les tics du cycle 1.
- Relancer les **lexicographes** avec la consigne de ne pas répéter les mots déjà
  fournis au cycle 1 (leur liste est dans les prompts des agents du run
  `wf_13c17850-014`).
- Plafond d'agents par workflow : **1 000**. 250 rédacteurs + 20 lexicographes passent
  en un seul run.

**Réécritures natives — 12 500 textes**

- 250 lots × 5 langues = **1 250 agents** : dépasse le plafond de 1 000, donc
  **deux runs** de 125 lots (625 agents chacun).
- Même structure que `wf_05fd3cc4-82e` : pipeline par lot, les cinq langues ensemble,
  pour que le corpus reste **aligné à tout instant d'interruption**.

---

## Ce que les deux cycles ont appris

1. **Les tics d'ouverture se corrigent, mais ils reviennent ailleurs.** Le cycle 1 avait
   « je t'écris depuis… » (×9) ; l'interdiction explicite dans le prompt l'a **éliminé à
   100 %** au cycle 2 (92 lettres, aucune formule d'envoi). Mais un nouveau tic est apparu :
   « Pendant des générations, » ouvre 18 textes du cycle 2. → **À chaque vague, relever les
   ouvertures répétées avec `gates.py` et les bannir explicitement dans le prompt.** C'est un
   jeu de taupes permanent, pas un défaut qu'on corrige une fois.

2. **La densité lexicale par texte est un PLAFOND DU MODÈLE, pas un défaut de prompt.**
   Deux tentatives, deux échecs : liste-cible souple de 12 mots → +1,3 % ; liste durcie de
   20 mots dont 10 obligatoires → **+0,4 %**, donc pire. Insister davantage produirait des
   mots plaqués et abîmerait les textes. **Ne pas retenter cette voie.**
   En revanche la couverture CUMULÉE marche très bien : chaque millier de textes apporte
   ~5 300 formes absentes du précédent (14 789 → 20 084 formes en passant de 1 000 à 2 000
   textes). **La couverture lexicale s'achète par le volume, pas par la densité** — ce qui
   justifie précisément les 2 500 familles demandées.

3. **Le quota est le seul facteur limitant.** Trois coupures en deux jours (hebdomadaire une
   fois, session deux fois). Le dispositif y résiste sans perte parce que chaque agent écrit
   son lot sur le disque avant de rendre son bilan.

---

## Garanties anti-perte (déjà en place)

- Chaque agent **écrit son lot sur le disque** avant de rendre : un workflow qui meurt
  ne détruit rien, les fichiers restent.
- Les workflows sont **reprenables** : `Workflow({scriptPath, resumeFromRunId})`, les
  agents terminés reviennent du cache.
- **Commit git après chaque étape terminée** — c'est la seule garantie qui survit à
  l'arrêt du processus.
- `gates.py` recalcule tout depuis les fichiers : aucun état n'est gardé en mémoire.

---

## Commandes de contrôle

```bash
# état des lots produits
ls tools/corpus_gen/out/*/ | wc -l

# gardes + assemblage d'une langue
python3 tools/corpus_gen/gates.py --lang fr --in tools/corpus_gen/out/fr \
  --assemble assets/reading_corpus/v2/fr.jsonl --emit-banned tools/corpus_gen/out/bannis_fr.txt

# contrôle d'alignement d'une langue sur le français
python3 tools/corpus_gen/gates.py --lang de --in tools/corpus_gen/out/de \
  --source assets/reading_corpus/v2/fr.jsonl
```
