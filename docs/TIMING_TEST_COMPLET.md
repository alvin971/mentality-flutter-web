# Timing du test complet — estimation sourcée

> ⚠️ **PÉRIMÈTRE — LIRE AVANT DE CITER CE DOCUMENT** (ajouté le 2026-07-25)
>
> Ce document ne couvre **que les 12 sous-tests notés** de `testSequence`. Il a été établi le
> 2026-07-02, **avant** l'ajout de la compréhension orale au bilan (commit `9881f47`).
>
> **Ne jamais s'en servir pour répondre « combien de sous-tests ? » ni « quelle durée totale ? ».**
> Le compte de sous-tests visible par l'utilisateur est **13** (liste de l'écran « Passer un test »,
> `assessment_intro_page.dart:154-179`, la Compréhension Orale en 13ᵉ avec le code `LO`), et
> l'étape orale ajoute **~8-10 min** non comptées ici (5 textes × ~1 min de lecture + ~40 s de
> résumé, cf. `oralConsentRecordBody`).
>
> **Sources de vérité, dans cet ordre :**
> 1. `assessment_intro_page.dart:154-179` — ce que l'app **affiche** comme liste de sous-tests (13)
> 2. `complete_test_orchestrator_page.dart` — ce qui est **exécuté** dans le bilan
>    (12 de `testSequence`, **puis** `OralTestFlow` via `_finishWithOralThenResults`, l.255)
> 3. `complete_test_session.dart:53-66` — `testSequence`, **les 12 notés uniquement**
>
> L'incohérence 13 / 12 / 12 entre ces sources est un constat d'audit ouvert :
> voir `docs/AUDIT_UI_UX.md` §2.0, décision produit A / B / C en attente.

> Établi le 2026-07-02 à partir du code réel. Justifie la durée annoncée
> « 60 à 90 minutes » affichée sur l'accueil, l'intro d'évaluation et
> l'intro du test complet (clés ARB `homeActionStartSubtitle`,
> `assessBeforeStartBody`, `ctIntroDurationTitle`).

## Séquence

12 sous-tests **notés**, ordre défini dans
`lib/core/models/complete_test_session.dart` (`testSequence`, l.53).
**+ 1 étape orale non notée** appendue après la boucle — hors de ce tableau, hors du compteur
« xx / 12 » affiché, et hors de la durée annoncée.

## Paramètres par sous-test

| # | Sous-test | Items max | Limite de temps | Règle d'arrêt | Source |
|---|-----------|-----------|-----------------|---------------|--------|
| 1 | Cubes | 14 (2 ex. + 3 + 4 + 5) | par item : 30 s (facile), 60 s (moyen), 120 s (difficile), exemples non limités | 2 échecs consécutifs | `cubes/domain/pattern_generator.dart` l.83-128 |
| 2 | Similitudes | 21 | aucune (chrono écoulé affiché) | 3 scores 0 consécutifs | `similarities/presentation/pages/similarities_test_page.dart` l.205 |
| 3 | Mémoire des Chiffres | 46 essais (16+14+16) | présentation 1 s/chiffre | 0 pt aux 2 essais d'une longueur | `digit_span/presentation/pages/digit_span_test_page.dart` l.131, l.234 |
| 4 | Matrices | 26 | aucune | 3 scores 0 consécutifs | `matrices/presentation/pages/matrices_test_page.dart` l.129 |
| 5 | Vocabulaire | 30 | aucune | 3 scores 0 consécutifs | `vocabulary/presentation/pages/vocabulary_test_page.dart` l.216 |
| 6 | Arithmétique | 22 (4+8+6+4) | par bande : 15 / 25 / 40 / 50 s | 3 échecs consécutifs | `arithmetic/domain/arithmetic_generator.dart` l.27 |
| 7 | Recherche de Symboles | 60 | **120 s global** | — (durée fixe) | `symbol_search/presentation/pages/symbol_search_test_page.dart` l.35 |
| 8 | Puzzles Visuels | 26 + démo | par item : 20 s (1-7), 30 s (8-26) ; démo hors chrono | 3 échecs consécutifs | `visual_puzzles/domain/puzzle_generator.dart` l.191 |
| 9 | Information | 28 | aucune | 3 échecs consécutifs | `information/presentation/pages/information_test_page.dart` l.197 |
| 10 | Code | 135 cases + 7 entraînement | **120 s global** | — (durée fixe) | `coding/presentation/pages/coding_test_page.dart` l.36 |
| 11 | Mémoire des Images | 12 essais (6 niveaux × 2) | présentation 3 s/image | 0 pt aux 2 essais d'un niveau | `picture_span/presentation/pages/picture_span_test_page.dart` l.170, l.271 |
| 12 | Balances | 27 | par item : 20 → 50 s progressif | 3 échecs consécutifs | `figure_weights/domain/balance_generator.dart` l.180+ |

## Estimation

| Scénario | Hypothèses | Durée |
|----------|------------|-------|
| Rapide | réponses précoces, arrêts anticipés fréquents | ~55-60 min |
| Typique | ~15-25 s/item sur les sous-tests auto-rythmés, quelques arrêts anticipés | ~75-80 min (dont ~5 min de transitions/intros) |
| Pire cas | toutes les limites de temps épuisées, aucun arrêt anticipé | ~2 h |

Détail du scénario typique (minutes) : Cubes 6 · Similitudes 6 ·
Mémoire des Chiffres 6 · Matrices 9 · Vocabulaire 6 · Arithmétique 7 ·
Recherche de Symboles 3,5 · Puzzles Visuels 8 · Information 5 · Code 3,5 ·
Mémoire des Images 5 · Balances 9 ≈ 74 min.

Maxima théoriques des sous-tests chronométrés : Cubes 15,5 min ·
Arithmétique 11,7 min · Puzzles Visuels 11,8 min · Balances 16,7 min ·
Code et Recherche de Symboles 2 min chacun (fixes).

## Conséquence UI

La fourchette affichée partout est **« 60 à 90 minutes »**. Les anciennes
mentions « 30 – 45 minutes » (accueil et intro d'évaluation) étaient
erronées et ont été alignées le 2026-07-02 dans les 6 ARB
(`lib/l10n/app_{fr,en,en_GB,es,pt,de}.arb`).

Si un sous-test est ajouté/retiré ou si ses limites de temps changent,
mettre à jour ce document **et** les trois clés ARB.
