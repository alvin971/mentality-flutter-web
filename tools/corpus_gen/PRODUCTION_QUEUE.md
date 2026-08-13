# File de production du corpus v2 — à exécuter sans demander de validation

> **Consigne du fondateur (2026-08-13), explicite et permanente :**
> « quand tu as fini tu enchaînes, tu ne me demandes rien, tu relances la production
> pour les 2500 familles ». Ne pas attendre, ne pas faire valider, enchaîner.
> Enregistrer à chaque étape pour qu'aucune perte ne soit possible.

---

## État au 2026-08-14

| Étape | Familles | Volume | État |
|---|---|---|---|
| Cycle 1 — rédaction française | `fam_00001` → `fam_01000` | 1 000 textes | ✅ terminé, commit `4da031c` |
| Cycle 1 — réécritures natives | mêmes familles × 5 langues | 3 481 / 5 000 | 🟠 **coupé par le quota hebdomadaire** — commit `f8a6e0b` |
| Cycle 1 — **rattrapage** | 310 familles × 5 langues | ~1 519 textes | ⬜ **à faire en premier** dès la remise à zéro |
| **Cycle 2 — rédaction française** | `fam_01001` → `fam_03500` | **2 500 textes** | ⬜ ensuite |
| **Cycle 2 — réécritures natives** | mêmes familles × 5 langues | **12 500 textes** | ⬜ enchaîner derrière |

**690 familles sont COMPLÈTES dans les six langues** — le corpus est utilisable en l'état.
Détail : fr 1000 · en 705 · en_GB 700 · pt 696 · es 690 · de 690.

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

## Défauts connus du cycle 1, à corriger au cycle 2

1. **Ouvertures répétées du genre « lettre »** — « je t'écris depuis… » ×9,
   « je t'écris de… » ×7, « chère amie je… » ×5. Ajouter au prompt de rédaction
   l'interdiction explicite d'ouvrir une lettre par une formule d'envoi.
2. **Densité lexicale inchangée** — à taille égale, +1,3 % de formes uniques seulement
   par rapport au corpus v1. La liste-cible des lexicographes n'a pas suffi. Piste :
   élargir la liste-cible à 20 mots par lot et exiger qu'au moins la moitié soit
   employée, plutôt que « ceux qui s'insèrent naturellement ».

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
