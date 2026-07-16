Les options 2 et 4 de l'item 18 ont des contenus couleur quasi identiques — je dois les départager géométriquement (rotation programmatique des crops).

---

Item 24 résolu : [2,4,5] (appariement exact des arêtes 29°/90°/144°). Je lis les items 25-26.

---

Toutes les vérifications de passe 2 sont faites. Bilan complet de l'audit du seed 5 :

**Passe 1 (aveugle)** : 26/26 items résolus conformes aux `correctLabels` — zéro divergence. 12 items résolus sans hésitation ; les 14 autres ont demandé un travail réel mais légitime (comptage d'aires, appariement d'arêtes, contrôle de chiralité pour les paires miroir 18:2/4, 19:1/2, 20:1/5, et assemblage géométrique complet pour les monochromes 22, 24, 26 — tous solubles par la seule forme, une seule solution géométrique possible).

**Passe 2 (vérifications ciblées)** :
- Candidats H (ssctp, colorDistance < 0.18) : items 03 [1,3], 04 [3,5], 05 [4,5], 07 [1,6] — tous des jumeaux wrongColors à inversion de teintes franches (vert/orange, jaune/vert, rouge/bleu) ; même sous rotation 180° le meilleur appariement pixel est 84 % avec une zone de désaccord macroscopique (proportion des bandes 60/40 vs 40/60) → discriminables en conditions réelles, pièges fonctionnels, pas de défaut.
- Candidats L (rotationInflation 1.41) : items 21 et 23 — cibles ~155 px, détails discriminants (échardes bleues/rouges ~30-60 px) parfaitement lisibles → pas de défaut.
- Candidats M : aucun fallbackUsed dans le seed 5.
- A/C/E/F/K : screenIdenticalPairs vides partout, trueAreaSumRel = 1.000 partout, paletteMinRgbDist ≥ 104 (rouge/orange distinguables), aucun areaShare < 0.03, aucun clipped=true, rotations du bandeau cohérentes avec le meta.
- D (drift 1.023) et G (cartouche tronqué sur petites cibles) : connus, non re-signalés.

Aucun défaut qui affecterait un candidat réel — le seed 5 est propre.