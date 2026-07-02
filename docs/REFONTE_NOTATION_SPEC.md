# Refonte du système de notation — Spécification

> **But** : remplacer les tables de scoring actuelles (normes synthétiques arbitraires, sigmas devinés, barèmes incohérents) par un **système maison cohérent, paramétrique et âge-relatif**, conçu pour devenir empirique dès qu'on collecte des données réelles, et entièrement réglable par des psychologues sans toucher à la logique.
>
> Statut : **spec validée sur les principes** (2026-06-16). Décisions produit prises : norme âge-relative · refonte complète des barèmes · PM intégré au WMI.

---

## 1. Principes directeurs

1. **Cohérent par construction** : chaque chiffre découle d'un petit jeu d'hypothèses explicites et documentées. Aucune valeur « posée à la main » sans justification.
2. **Âge-relatif** : un score standard exprime toujours le rang de la personne **par rapport aux gens de son âge**. C'est le pivot du système.
3. **Provisoire mais honnête** : faute de données, les paramètres `µ/σ` sont des *priors* (estimations raisonnables). Le moteur est bâti pour qu'on les remplace par des moyennes/écarts **empiriques** dès N sessions collectées, sans réécrire le code.
4. **Réglable par des non-développeurs** : toute la « connaissance psychométrique » vit dans **un seul fichier de configuration** lisible (`scoring_params.dart`). Les psy ajustent des nombres, jamais des algorithmes.
5. **Non diagnostique** : tant que ce n'est pas validé sur échantillon par des cliniciens, l'app affiche un disclaimer « estimation indicative, non diagnostique ».

---

## 2. Doctrine de notation (règles transversales sur les 12 barèmes)

La « refonte complète » impose des règles uniformes pour que les 12 sous-tests parlent la même langue :

| Règle | Décision |
|---|---|
| **Précision vs vitesse** | La **vitesse ne compte QUE** pour les 2 sous-tests dont c'est le construct : **CD (Code)** et **SS (Recherche de symboles)**. Partout ailleurs → **précision pure, aucun bonus de temps**. |
| **Bonus de temps** | **Supprimés** sur BD (Cubes) et AR (Arithmétique). |
| **Pénalité d'erreur** | Conservée uniquement sur SS (`corrects − erreurs`), **bornée à 0** (jamais de brut négatif). CD = simple comptage. |
| **Points par item** | Précision : items à 1 pt, sauf SI et VO qui restent **0/1/2** (réponses libres graduées). |
| **Règle d'arrêt (discontinuation)** | Conservée (épargne les participants faibles), sans effet sur un parcours parfait. |
| **Brut borné** | Tout brut est borné `[rawMin, rawMax]` déclarés avant d'entrer dans le moteur. |
| **Source unique du brut** | Le brut stocké = le brut affiché = le brut envoyé au moteur (déjà vrai, à préserver). |

### Barèmes cibles « propres » par sous-test

| Code | Sous-test | Échelle propre | rawMax cible | Domaine cognitif |
|---|---|---|---|---|
| BD | Cubes | 2 pt (faciles) / 4 pt (difficiles), **sans bonus temps** | 42 | Visuo-spatial (VSI) |
| SI | Similitudes | 0/1/2 × 21 | 42 | Cristallisé (VCI) |
| DS | Mémoire des chiffres | **1 pt/essai correct** (fin du 2+1) | ~46 | Mémoire de travail (WMI) |
| MR | Matrices | 1 × 26 | 26 | Raisonnement fluide (FRI) |
| VO | Vocabulaire | 0/1/2 × 30 | 60 | Cristallisé (VCI) |
| AR | Arithmétique | 1 × 22, **sans bonus temps** | 22 | Mémoire de travail (WMI) |
| SS | Recherche de symboles | corrects − erreurs, **borné ≥ 0** | 60 | Vitesse (PSI) |
| VP | Puzzles visuels | 1 × 26 | 26 | Visuo-spatial (VSI) |
| IN | Information | 1 × 28 | 28 | Cristallisé (VCI) |
| CD | Code | comptage chrono 120 s | 135 | Vitesse (PSI) |
| PM | Mémoire des images | 1 × 12 | 12 | **Mémoire de travail (WMI)** ← nouveau |
| FW | Balances | 1 × 27 | 27 | Raisonnement fluide (FRI) |

**3 corrections de bugs incluses** : DS (fin du sur-plafonnement), AR (retrait du bonus), SS (brut borné ≥ 0).

---

## 3. Modèle de normalisation par âge (le cœur)

La personne saisit son âge → `ageInMonths`. On ne compare jamais son brut à une constante, mais à la **moyenne attendue pour son âge**.

### 3.1 Note standardisée (1–19)

```
scaled = clamp( round( 10 + 3 · (raw − µ_raw(age)) / σ_raw(age) ), 1, 19 )
```

- Moyenne 10, écart-type 3 **garantis par construction**.
- `µ_raw(age)` et `σ_raw(age)` dépendent de l'âge → c'est ici qu'opère la comparaison à l'âge.

### 3.2 Courbe d'âge par domaine (continue, pas des paliers grossiers)

`µ_raw(age) = µ_ref · ageFactor(age, domaine)`, où `ageFactor` vaut **1.0 à l'âge de référence** (25–35 ans) et varie selon le domaine cognitif :

| Domaine | Trajectoire avec l'âge | Sous-tests |
|---|---|---|
| **Cristallisé** | monte jusqu'à ~50 ans, plateau, légère baisse après 70 | SI, VO, IN |
| **Raisonnement fluide** | pic à ~25 ans, déclin régulier | MR, FW, VP, BD |
| **Mémoire de travail** | léger déclin après ~35 ans | DS, AR, PM |
| **Vitesse de traitement** | déclin le plus marqué, dès ~30 ans | CD, SS |

`ageFactor` est défini par **points d'ancrage** éditables aux âges [16, 25, 35, 45, 55, 65, 75, 85], interpolés linéairement. Exemple (vitesse) : `{16:0.95, 25:1.0, 35:0.97, 45:0.90, 55:0.82, 65:0.72, 75:0.62, 85:0.52}`.

> **Conséquence concrète** : à 70 ans, la moyenne attendue en vitesse est plus basse → un brut modéré donne quand même une note standard ~10, parce qu'on est comparé à des gens de 70 ans. Exactement ce qui est voulu.

### 3.3 Valeurs par défaut (priors, en attendant les données)

À l'âge de référence : `µ_ref ≈ 0,55 · rawMax`, `σ_ref ≈ 0,16 · rawMax`.
→ un sans-faute atterrit ~18-19, un moyen ~10, un quasi-zéro ~1. Ajustable **par sous-test**.

---

## 4. Indices composites & FSIQ

### 4.1 Composition (après intégration PM au WMI)

| Indice | Sous-tests | k |
|---|---|---|
| VCI (compréhension verbale) | SI + VO + IN | 3 |
| VSI (visuo-spatial) | BD + VP | 2 |
| FRI (raisonnement fluide) | MR + FW | 2 |
| **WMI (mémoire de travail)** | **DS + AR + PM** | **3** ← nouveau |
| PSI (vitesse) | CD + SS | 2 |
| FSIQ | 10 primaires (BD,SI,DS,MR,VO,AR,SS,VP,IN,CD) | 10 |

> PM alimente **l'indice WMI** mais **pas le FSIQ** (logique « sous-test supplémentaire » du WAIS : il enrichit son indice sans déstabiliser le score global). À rediscuter avec les psy.

### 4.2 σ dérivé, plus deviné

Pour `k` notes standard (moyenne 10, écart-type 3) de corrélation moyenne `r` :

```
Var(somme) = 9 · [k + k(k−1)·r]
composite  = clamp( round( 100 + 15 · (somme − 10k) / (3·√(k + k(k−1)r)) ), 40, 160 )
```

Un seul paramètre par indice : `r` (corrélation inter-sous-tests, défaut ≈ 0,5–0,65). Le σ en découle mathématiquement.

### 4.3 FSIQ

Même formule, `k = 10`, avec une corrélation moyenne `r_g` (facteur g, défaut ≈ 0,5).

---

## 5. Percentile, classification, intervalle de confiance

- **Percentile** : calculé **analytiquement** depuis `N(100,15)` via la fonction d'erreur (plus de table figée), borné [0,1 ; 99,9].
- **Classification** : seuils inchangés (≥130 Très supérieur … <70 Extrêmement bas).
- **Intervalle de confiance 95 %** : méthode actuelle **conservée** (elle est correcte) — `vrai_score = 100 + rxx·(score−100)`, marge `1.96·SEM`, avec `SEM = 15·√(1−rxx)` (cohérent avec la fidélité).

---

## 6. Architecture logicielle

```
lib/features/scoring/
├── data/
│   ├── scoring_params.dart        ← NOUVEAU : source de vérité unique (éditable psy)
│   │     • par sous-test : rawMin, rawMax, muRef, sigmaRef, domaine
│   │     • par domaine   : points d'ancrage de la courbe d'âge
│   │     • par indice    : composition + corrélation r + fidélité rxx
│   ├── normative_tables.dart      ← REMPLACÉ : toScaledScore() devient paramétrique
│   └── composite_score_tables.dart← REMPLACÉ : sigma dérivé + percentile analytique
├── domain/
│   ├── services/scoring_service.dart  ← MAJ : WMI=DS+AR+PM ; reste de la chaîne intacte
│   └── entities/iq_score.dart         ← MAJ mineure si besoin
```

Côté exercices (refonte des barèmes) :
- `cubes/` retrait bonus temps · `arithmetic/` retrait bonus temps · `symbol_search/` borne brut ≥ 0 · `digit_span/` 1 pt/essai.
- Tests à mettre à jour en conséquence.

---

## 7. Plan d'implémentation par étapes

1. **Étape A — Moteur paramétrique** (cœur, sans toucher aux exercices) : créer `scoring_params.dart`, réécrire `toScaledScore` (âge-relatif), `computeCompositeScore` (σ dérivé), percentile analytique. Brancher WMI=DS+AR+PM. → scores cohérents immédiatement, même sur les barèmes actuels.
2. **Étape B — Corriger les 3 bugs de barème** : DS (1 pt/essai), AR (retrait bonus), SS (borne ≥ 0). + tests.
3. **Étape C — Nettoyage des barèmes restants** : BD (retrait bonus temps), harmonisation des échelles selon la doctrine §2. + tests.
4. **Étape D — UI & rapport** : afficher la note **toujours avec la référence d'âge**, disclaimer non-diagnostique, PDF.
5. **Étape E — Boucle empirique (plus tard)** : pipeline qui recalcule `µ/σ` par sous-test et par tranche d'âge à partir des sessions réelles collectées → remplace les priors.

---

## 8. Ce que les psychologues pourront régler (sans dev)

Tout, dans `scoring_params.dart` :
- la moyenne/écart-type attendus de chaque sous-test (priors → empiriques) ;
- les **courbes d'âge** par domaine (points d'ancrage) ;
- les **corrélations `r`** par indice et le facteur g ;
- les **fidélités `rxx`** (→ largeur des intervalles de confiance) ;
- la composition des indices, les seuils de classification.

---

*Document de référence — à faire évoluer avec l'arrivée des cliniciens et des premières données.*
