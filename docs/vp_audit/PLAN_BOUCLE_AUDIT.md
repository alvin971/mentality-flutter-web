# Boucle REACT — Audit visuel & correction des Puzzles Visuels (VP)

## Contexte

L'utilisateur perçoit « plein d'items incohérents » dans l'exercice Puzzles Visuels, malgré des gardes géométriques toutes vertes (0 ambiguïté / 1800 items, 226 tests verts). Explication probable : **les gardes tournent sur la géométrie NON tournée et hors écran**, alors que l'utilisateur voit des pièces **tournées, à l'échelle des painters réels**. Deux angles morts identifiés :

1. **Rotation d'affichage** : `visuallyConfusable` est calculé avant `displayRotationDeg` → deux options peuvent être identiques À L'ÉCRAN sans déclencher aucune garde. (Confirmé de visu : sur la planche seed 7, plusieurs barres quasi identiques sur les lignes 1, 2, 5.)
2. **Dérive d'échelle cible/pièces** : couplage manuel fragile `PuzzlePieceWidget.pixelsPerUnit` (`(tileSide-32)*0.94/unitsPerTile`) vs cadre cible clampé (`min(fitScale, ppu)` → la cible peut rétrécir SEULE silencieusement). `maxPieceExtent` est calculé APRÈS rotation → une pièce longue tournée rétrécit toutes les autres.

Objectif : une vraie boucle REACT (Percevoir → Réfléchir → Agir → Vérifier) où Claude **regarde chaque item lui-même** (rendu PNG lu par vision), corrige le code, re-rend, re-vérifie — avec évaluateur séparé, but mesurable et arrêt garanti.

## Les 3 ingrédients obligatoires de la boucle

- **Déclencheur** : approbation de ce plan.
- **But vérifiable G(R)** : sur l'échantillon complet du tour R → **0 défaut bloquant + 0 majeur confirmés** ET tous les tests VP verts ET `flutter analyze` propre ET nouvelles métriques verrouillées vertes. Succès = G vrai **2 tours consécutifs** (le 2e tour = rendu+inspection seulement, sans correction).
- **Vérificateur séparé** : les findings sont confirmés par des agents sceptiques indépendants (jamais l'inspecteur d'origine, jamais le correcteur) ; la re-inspection post-fix est faite par de NOUVEAUX agents.

**Garde-fous anti-boucle-infinie** : max **5 tours** ; si une classe de défaut survit à **2 tentatives de fix**, on la gèle et on la remonte à l'utilisateur (pas d'acharnement) ; défauts *mineurs* consignés mais jamais bloquants.

## Phase 0 — Harnais « Percevoir » (une fois, committé)

Rendu **widget-fidèle** : on pompe les VRAIS widgets (`PuzzleTargetWidget` + 6×`PuzzlePieceWidget`, câblage exact de `visual_puzzles_test_page.dart` layout large, tileSide 180, vrai pont `pixelsPerUnit`) → capture `RepaintBoundary.toImage(pixelRatio:1.6)` dans `tester.runAsync`. C'est le seul moyen d'attraper les dérives de painters que la reproduction canvas existante ne voit pas. (On ne pompe PAS la page complète : dépendances Hive/prefs.)

**Nouveaux fichiers** :
- `test/exercises_implementations/visual_puzzles/support/vp_audit_capture.dart` — helpers :
  - `loadRealFonts()` : FontLoader avec `/home/ubuntu/flutter/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf`, enregistré sous `'Roboto'` ET sous les familles résolues par GoogleFonts (`GoogleFonts.robotoMono().fontFamily!`…) + `GoogleFonts.config.allowRuntimeFetching=false` → **sinon tout texte rend en blocs Ahem**.
  - `wrapItemCard(item)` : pattern `_wrap` de `vp_flow_test.dart:19-37` + `RepaintBoundary` (cible + grille 3×2 numérotée 1-6, échelle unifiée réelle).
  - `captureCard(tester)` : `setSurfaceSize(660×760)`, `devicePixelRatio=1.0` (+ addTearDown reset).
  - `compositeAndSave(...)` : PNG final ≈1000×1250 px = bandeau méta en haut (seed/item/palier/stratégie/fallback/ppu), carte au centre, **bandeau réponses en bas** (corrects + trapKind/rotation par option).
  - `itemMetadata(item)` + **pré-checks déterministes** écrits en sidecar JSON par seed : `displayedConfusablePairs` (confusabilité sur `displayPolygon` TOURNÉ — le détecteur de l'angle mort), `targetScaleDrift` (reproduction du clamp du cadre cible), `pieceClipped`, `trueAreaSumRel`, `rotationInflation` (maxPieceExtent / extent non-tourné, flag >1.4), paires daltoniennes.
- `test/exercises_implementations/visual_puzzles/render_item_cards_audit_test.dart` — point d'entrée : `--dart-define=VP_AUDIT_SEEDS=…` + `VP_AUDIT_OUT=…` ; sans define → smoke-test 1 seed (reste un test vert permanent). Nommage `seed007_item03_palier2.png`.

**Porte de sanité** : rendre seed 7 seul → je lis moi-même 2-3 PNG pour valider (pas de blocs Ahem, bandeaux lisibles, échelle visible) avant de lancer la boucle.

**Échantillon** : fixe `seeds 1..10` (260 items, reproductible tour à tour, inclut le seed démo 7) + **5 seeds frais par tour** (`110+…`, jamais vus par le correcteur) pour éviter le sur-ajustement.

## La boucle (par tour R)

1. **PERCEVOIR** — `export PATH="/home/ubuntu/flutter/bin:$PATH" && flutter test render_item_cards_audit_test.dart --dart-define=…` → 260 PNG + sidecars dans `<scratchpad>/vp_audit/round_R/`. Les flags programmatiques deviennent des findings candidats.
2. **RÉFLÉCHIR (inspection)** — Workflow : 10 inspecteurs vision en parallèle, 1 seed chacun (26 PNG + sidecar). Protocole par item : **résoudre à l'aveugle d'abord** (avant de regarder le bandeau réponses), puis balayer la taxonomie. Sortie JSON structurée `{seed,item,options,defectCode,sévérité,description,confiance,blindPickMatched}`.
   **Taxonomie** : A options identiques à rotation d'affichage (bloquant) · B piège complète plausiblement la cible = réponse ambiguë (bloquant) · C les 3 bonnes pièces ne « somment » visiblement pas la cible (bloquant) · D échelle cible≠pièces (majeur) · E couleurs trop proches / paire daltonienne (majeur) · F pièce-aiguille (majeur) · G badge sur le dessin (mineur) · H wrongColors indiscernable (majeur) · I miroir = simple rotation d'une vraie pièce (bloquant) · J item monochrome insoluble (bloquant) · K pièce rognée par la tuile (majeur) · L rotation gonfle l'échelle commune (majeur) · M item fallbackUsed dégénéré (majeur) · N « un candidat naïf dirait incohérent » (sévérité argumentée).
3. **RÉFLÉCHIR (vérif adversariale)** — chaque finding rejugé par 3 sceptiques indépendants (consigne : « présume le finding FAUX sauf si l'image le montre clairement ») ; confirmé si ≥2/3.
4. **AGIR** — triage par cause racine, 1 commit conventionnel FR par cluster, **chaque fix livré avec son test de régression** (ou nouvelle métrique verrouillée : `displayedConfusablePairs==0`, `targetScaleDrift==0`, `clippedPieces==0`, cap `rotationInflation`) :
   - Gardes générateur/pièges → `puzzle_generator.dart`, `trap_engine.dart`, `geometry.dart` : re-check post-assemblage de la confusabilité sur géométrie TOURNÉE (re-tirage rotation/piège borné).
   - Painters/échelle → `puzzle_target_widget.dart`, `puzzle_piece_widget.dart`, `polygon_painter.dart` : supprimer le rétrécissement silencieux `min(fitScale, ppu)` (clamp global cohérent cible+pièces), unifier les paddings.
   - Recettes → `difficulty_ladder.dart` / `cut_engine.dart` si un palier est systématiquement impliqué.
5. **VÉRIFIER (évaluateur séparé)** — re-rendu frais (fixe + 5 seeds neufs) → re-inspection par de NOUVEAUX agents + sceptiques → `flutter test test/exercises_implementations/visual_puzzles/` (tous verts) → `flutter analyze` (0 issue) → suite complète (~219 tests) au tour final.
6. **G(R) vrai ?** → oui 2× de suite : stop ✅. Non → tour R+1 (max 5).

## Livrables

- Code corrigé committé sur `claude/puzzle-audit-loop-87870c` ; **merge vers `main` + push seulement après convergence de la boucle et suite complète verte**.
- Harnais d'audit committé (actif permanent, vert par défaut) + nouvelles métriques verrouillées.
- Rapport final : défauts par tour, confirmations/rejets, fixes, chemins PNG avant/après, mineurs restants, éventuelles classes gelées.
- Vault (Gotchas : Ahem/FontLoader, clamp cible, angle mort rotation ; Progress) + mémoire projet.

## Vérification de bout en bout

La boucle EST la vérification (évaluateur séparé, seeds jamais vus, 2 tours propres consécutifs). En plus : porte de sanité Phase 0 validée par moi visuellement, tests VP + suite complète + analyze, et comparaison avant/après sur les mêmes seeds fixes.

## Pièges connus (exécuteur)

- `toImage` et lecture de fontes ⇒ `tester.runAsync` obligatoire ; `setSurfaceSize` sinon carte rognée (défaut 800×600@3.0).
- GoogleFonts rend en Ahem si les bytes ne sont pas enregistrés sous SES noms de familles résolus.
- PNG uniquement sous le scratchpad de session (pas `/tmp` nu).
- `pumpWidget(SizedBox.shrink())` entre items (fuites de timers — pattern `vp_flow_test.dart:132`).
- Distinguer défaut vs design : les « jumeaux » (pièges scaled, maxTwins=3 aux paliers faciles) sont VOULUS — le critère est le test de résolution à l'aveugle : *similaire mais discriminable* = OK ; *indiscernable/ambigu en conditions réelles* = défaut.
