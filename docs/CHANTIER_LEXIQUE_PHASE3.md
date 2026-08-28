# Chantier lexique — PHASE 3 (file de travail de la loop)

> **Ce fichier est autoportant.** Il contient tout le contexte nécessaire : la loop
> peut démarrer sur une conversation vide. Suite de [`CHANTIER_LEXIQUE.md`](CHANTIER_LEXIQUE.md)
> (phase 1, lots A→J, terminés) et [`CHANTIER_LEXIQUE_RESTE.md`](CHANTIER_LEXIQUE_RESTE.md)
> (phase 2, lots K→P, terminés + un rattrapage).
>
> Référence de vocabulaire : [`LEXIQUE_JURIDIQUE.md`](LEXIQUE_JURIDIQUE.md) — **à lire en entier
> avant le premier lot.** C'est le contrat : pour changer le résultat, on modifie CE fichier,
> pas les textes un par un.

---

## 0. Où en est le chantier

Objectif général : **Mentality ne doit plus rien affirmer qu'elle ne puisse prouver**, et ne
plus s'appuyer sur la marque d'un tiers (WAIS-IV / WISC / WPPSI / Wechsler, propriété de
Pearson). Positionnement retenu : **grand public**. L'app pro est `mentality-admin`.

**Déjà fait (16 lots).** Marque et sigles retirés de tout l'affichage de l'app patient
(6 langues), fiche App Store réécrite, mensonge sur les données audio corrigé, prompt du chat
IA neutralisé + interdiction explicite, 6 sous-tests renommés, `mentality-admin` nettoyé de ses
allégations, deux vitrines dormantes nettoyées et gelées, 24 captures d'écran périmées sorties
du chemin d'envoi App Store, 5 gardes de test réparées.

### Les 6 dépôts et leur état

| Dépôt | État | Public ? |
|---|---|---|
| `~/projects/mentality/mentality-flutter-web` | app patient — traitée | pas encore publiée |
| `~/projects/mentality/mentality-admin` | outil pro — allégations traitées | `mentality-admin.pages.dev` |
| `~/projects/mentality/mentality_mobile` | **sources corrigées, SITE EN LIGNE PAS À JOUR** | ✅ `mentalite-site-web.pages.dev` |
| `~/projects/mentalet/mental-et-web` | **propre, vérifié — NE PAS TOUCHER** | ✅ `mental-et.com` |
| `~/projects/mentalet/mentalite-site-web` | dormant, nettoyé, gelé | non |
| `~/projects/mentalet/mentalite_site_web_flutter` | dormant, nettoyé, gelé | non |

---

## 1. Règles dures — non négociables

1. ❌ **Ne JAMAIS éditer `lib/l10n/*.arb`.** La vérité est dans `l10n_fragments/*.json`
   (clés `fr` + `en`) et `l10n_fragments/translations/{es,pt,de,en_GB}.json`. Après toute
   édition : `python3 l10n_fragments/_merge.py` puis `flutter gen-l10n`.
   **`flutter` est dans `~/flutter/bin`, absent du PATH par défaut** →
   `export PATH="$HOME/flutter/bin:$PATH"`.
2. ❌ **Ne toucher ni au calcul du score/FSIQ/ICV, ni au CONTENU des banques d'items**
   (`*_items_*.dart`). Les docstrings d'en-tête sont éditables, le contenu jamais.
3. ❌ **Ne pas toucher `ctPdfDisclaimer` ni `ctIndicativeDisclaimer`** — ces avertissements
   citent « clinique » et « psychologue » **pour s'en distinguer**. C'est notre défense.
4. ❌ **Ne pas toucher à `mental-et.com` ni à `mentalite/mental-et-web`** : vérifiés propres
   le 2026-08-28 (0 marque sur 2904 caractères servis).
5. ❌ **Ne jamais renommer un identifiant VIVANT** (référencé quelque part), ni une clé l10n,
   ni un enum, ni un identifiant de base de données. En particulier la table Postgres
   **`wais_items`**, lue par l'app Flutter. Une constante **morte** peut être retirée.
6. ✅ **Les 6 langues bougent ensemble** : fr, en, en_GB, es, pt, de.
7. ✅ **Un lot par itération.** Pas deux, pas de demi-lot.
8. ✅ **AUCUN commit git, AUCUN déploiement, AUCUN push.** Tout reste en working tree.
9. ✅ **Exclure partout les worktrees git imbriqués `/.claude/`** — checkouts d'autres
   branches, ignorés par git (`.gitignore`), jamais livrés. Sans ce filtre les vérifs sont
   rouges en permanence.

### Références de non-régression (établies, à respecter)

- `flutter analyze` (dépôt patient) : **23 issues, 0 erreur**. ⚠️ **Comparer par DIFF ligne
  à ligne**, pas par le total : les 46 `pubspec.yaml` imbriqués sous `.claude/worktrees/`
  créent autant de contextes d'analyse et gonflent le total de façon transitoire.
  Référence sauvegardée si besoin : régénérer par `flutter analyze | grep '•' | sort`.
- `flutter test` (dépôt patient) : **1019 tests, 0 échec**.
- `npx tsc --noEmit` (mentality-admin) : **sans erreur**.
- `flutter analyze` (mentality_mobile) : **No issues found**.

### Trois pièges déjà rencontrés — ne pas les refaire

1. **L'artefact survit à la correction.** Sources propres ≠ livrable propre. Captures d'écran
   du 23 août, `build/web/main.dart.js`, bundles `dist/` : toujours vérifier **ce qui est
   livré**, pas seulement ce qui est écrit.
2. **Conclure sur une taille de réponse HTTP.** `mentalite-site-web.pages.dev` a été classé
   « talon de 435 octets » alors que sa coquille HTML charge un bundle JS de 192 Ko plein de
   marque. **Toujours charger le bundle et lire le texte réellement servi.**
3. **Les regex qui ne peuvent pas passer.** `wisc` sans borne de mot matche l'allemand
   « z**wisc**hen ». Utiliser `\bwais|\bwechsler|\bwisc\b|\bwppsi\b`.

---

## 2. Lots

### ☑ LOT Q — `mentality_mobile` : finir le seul site PUBLIC non à jour  🔴
Le site **en ligne** `mentalite-site-web.pages.dev` sert encore l'ancien bundle.
Les sources sont corrigées (rattrapage phase 2), mais il reste :
- `Mentality Mobile App/src/app/components/WaisTests.tsx` — **le nom du fichier et du
  composant** portent la marque. Le composant n'est référencé que par `App.tsx` (import +
  usage) : renommer fichier + composant en `ExercicesSection` (ou équivalent neutre).
- `Mentality Mobile App/src/app/App.tsx` — mettre à jour l'import et l'usage.
- `Mentality Mobile App/dist/assets/index-YriJh32r.js` — **artefact de build périmé**, seul
  porteur restant. Vérifier s'il est suivi par git (`git ls-files`) ; s'il ne l'est pas et
  qu'il est régénérable, le supprimer ; s'il est suivi, **ne pas le supprimer** et consigner
  qu'un rebuild est requis.
**Vérif :** `grep -rniE "\bwais|\bwechsler|\bwisc\b|\bwppsi\b" ~/projects/mentality/mentality_mobile
| grep -v "/.claude/" | grep -v "/.git/" | grep -v NE-PAS-DEPLOYER` → **0** ;
et `npm run build` OU `npx tsc --noEmit` dans `Mentality Mobile App/` sans erreur (si l'outillage
le permet ; sinon le consigner franchement).
⚠️ **Ne pas déployer.** Le redéploiement est une décision du fondateur.

### ☑ LOT R — Derniers résidus des dépôts dormants et du dépôt patient  🟠
- `~/projects/mentalet/mentalite_site_web_flutter/lib/widgets/section_04_tests.dart` — 1 résidu.
- `~/projects/mentality/mentality-flutter-web/scripts/generate_screenshots_landing.js` —
  produit un fichier nommé `04_wais.png` et vise le **site vitrine**, pas l'app. Renommer la
  sortie ; et vérifier que ce script ne peut plus écrire dans `ios/fastlane/screenshots/`
  (c'est lui qui a introduit les 24 captures périmées du LOT O).
- `~/projects/mentality/mentality-flutter-web/main.dart.js` (à la RACINE du dépôt) — fichier
  égaré à qualifier : artefact ? suivi par git ? À traiter comme tel.
**Vérif :** les 3 points traités ; `grep` de marque à 0 sur ces fichiers ; `flutter analyze`
du dépôt patient sans nouvelle ligne au diff.

### ☑ LOT S — Fichiers de test du dépôt patient  🟢
4 fichiers portent encore la marque dans leurs noms de test ou commentaires :
`test/exercises_implementations/{vocabulary/vocabulary_generator_test,visual_puzzles/difficulty_ladder_test,matrices/matrix_generator_test,similarities/similarities_generator_test}.dart`.
Nettoyer **les libellés de test et les commentaires uniquement** — jamais une assertion, jamais
une valeur attendue.
**Vérif :** `flutter test` → **1019 tests, 0 échec** (le compte de tests ne doit PAS changer) ;
`flutter analyze` sans nouvelle ligne au diff.

### ☑ LOT T — Documentation interne des dépôts  🟢
~17 fichiers `.md` / `.txt` / `.bak` portent la marque dans `mentality-flutter-web`
(`ARCHITECTURE.md`, `PROJECT_STRUCTURE.md`, `CLAUDE.md`, `CHAT_IA_IMPLEMENTATION.md`,
`CONFIGURATION_CHAT_IA.md`, `README_CHAT_IA.md`, `RESUME_IMPLEMENTATION_CHAT.txt`,
`docs/AUDIT_UI_UX.md`, `docs/REFONTE_NOTATION_SPEC.md`, les `.bak`…) et 3 dans
`mentality-admin` (`CLAUDE.md`, `CLAUDE.md.bak-2026-07-06`, `README.md`).
Ce sont des documents **internes**, mais un dépôt saisi en contentieux se lit en entier.
⚠️ **NE PAS toucher** : `docs/LEXIQUE_JURIDIQUE.md`, `docs/CHANTIER_LEXIQUE.md`,
`docs/CHANTIER_LEXIQUE_RESTE.md`, ce fichier — ils DOIVENT nommer la marque, c'est leur objet.
⚠️ Les `.bak` : proposer leur suppression au fondateur plutôt que les réécrire (ce sont des
sauvegardes mortes), mais **ne pas supprimer sans instruction** — consigner la recommandation.
**Vérif :** hors les 4 fichiers de chantier ci-dessus, plus aucune marque dans les `.md`/`.txt`
des deux dépôts ; les fichiers restent lisibles et cohérents.

### ☑ LOT U — Les 2 captures d'écran qui photographient le mauvais écran  🟠
`ios/fastlane/screenshots/fr-FR/iPhone 6.9"/01_accueil.png` montre le **splash** au lieu de
l'accueil, et `02_evaluation.png` l'écran de **connexion par token** au lieu de l'intro
d'évaluation (idem en 6.5"). Cause : `scripts/generate_screenshots.js` attend `networkidle`,
qui se déclenche trop tôt sur Flutter Web, et la route `/assessment` bute sur la porte de
déblocage. Corriger la temporisation (attendre un sélecteur/texte réel plutôt que le réseau),
puis régénérer.
Prérequis : `flutter build web --release`, puis `cd scripts && node generate_screenshots.js`.
Playwright et le chromium révision 1217 sont déjà installés.
**Vérif :** les 12 captures existent, **aucune ne montre de marque**, et `01_accueil` +
`02_evaluation` montrent bien l'accueil et l'intro d'évaluation — **contrôle visuel obligatoire,
en ouvrant les PNG**. Si la correction n'aboutit pas, le consigner franchement : jamais de faux
positif.

### ☑ LOT V — Passe finale des 3 phases + dossier de décision
1. Rejouer **toutes** les vérifications des phases 1, 2 et 3.
2. `python3 l10n_fragments/_merge.py` et `flutter gen-l10n` sans erreur.
3. `flutter analyze` : **diff ligne à ligne** contre la référence, 0 nouvelle, 0 erreur.
4. `flutter test` : 1019 / 0.
5. Les 6 ARB portent les nouveaux textes ; les 2 disclaimers intacts ; 0 libellé vide ;
   même nombre de clés dans les 6 langues.
6. **Aucun commit créé** (`git log --oneline` inchangé dans chaque dépôt).
7. Balayage final des 6 dépôts, worktrees `/.claude/` exclus.
8. Produire le **dossier de décision du fondateur** (voir §3), à jour et complet.

---

## 3. Ce qui n'est PAS du ressort de la loop — décisions du fondateur

À rappeler intégralement dans le récapitulatif final, sans jamais y toucher soi-même :

1. 🔴 **La supervision clinique par des praticiens non nommés.** Trois dépôts affirment
   « Supervisé par des psychiatres et psychologues », « Supervision clinique réelle »,
   « Supervisé par de vrais cliniciens » — avec des cartes d'équipe sans nom (initiales « DR »)
   et des citations attribuées à personne. **Une de ces affirmations est EN LIGNE.**
   Si la supervision n'existe pas telle que décrite : pratique commerciale trompeuse
   (C. conso. L.121-2, sanction L.132-2 : 2 ans, 300 000 €, jusqu'à 10 % du CA annuel moyen).
   « Outil clinique » expose au régime du dispositif médical (Règl. UE 2017/745, règle 11).
   → Soit la supervision existe et on la documente (noms, rôles, engagement vérifiable),
   soit la section disparaît.
2. 🔴 **Les tables normatives.** `mentality-admin` disait à ses utilisateurs de les saisir
   « depuis le manuel WAIS-IV publié » — recopier les tables de Pearson relève du droit
   d'auteur / droit sui generis de base de données, pas de la marque. Texte d'interface
   corrigé ; **rien de copié aujourd'hui** (migration 002 ne sème que 10 lignes d'exemple
   synthétique), mais la pratique future est à trancher.
3. 🔴 **Redéployer les DEUX sites publics dont les sources sont corrigées mais pas le
   livrable.** Vérifié le 2026-08-29 en téléchargeant les bundles réellement servis —
   jamais sur une taille de réponse HTTP :
   - **`mentality-admin.pages.dev`** (outil pro) sert `/assets/index-C7Jjt7n8.js`
     (309 111 o) avec **26 occurrences de la marque dans du TEXTE AFFICHÉ** :
     « Tests WAIS-IV », « Items WAIS-IV officiels », « Référence normative WAIS-IV »,
     « Moyenne WAIS-IV », « Tests WAIS-IV — Prévisualisation », et surtout
     ⚠️ « Les tables normatives doivent être saisies manuellement **depuis le manuel
     WAIS-IV publié** » — c'est l'instruction du point 2 ci-dessous, **encore en ligne**.
     Un bundle propre existe en local (`dist/assets/index-ZvVibL0l.js`, 0 occurrence
     affichable) ; voir `mentality-admin/NE-PAS-DEPLOYER.md`.
   - **`mentalite-site-web.pages.dev`** (vitrine) sert `/assets/index-YriJh32r.js`
     (192 084 o) avec **2 occurrences**, dont « 12 tests basés sur le WAIS-IV ·
     4 indices composites ». Bundle propre en local : `index-CEdt-CNb.js`.
4. 🟠 **Commiter.** Rien n'est commité dans aucun dépôt ; tout est en working tree.
5. 🟢 **Supprimer les `.bak`** — sauvegardes mortes portant encore la marque, laissées
   intactes par la loop (ni réécrites, ni supprimées, comme demandé) :
   `mentality-flutter-web/CLAUDE.md.bak` (1 occurrence),
   `mentality-flutter-web/CLAUDE.md.bak-refonte-2026-07-06` (1),
   `mentality-admin/CLAUDE.md.bak-2026-07-06` (3).

6. 🟢 **Deux imperfections d'affichage relevées au contrôle visuel des captures**, hors
   périmètre lexical : `03_matrices.png` montre l'étiquette de mise au point
   « Règles : 1 | θ = −2.0 » ; l'intro d'évaluation titre « Cinq indices » alors qu'elle
   annonce « six domaines » et en liste six (Langage Oral inclus).

**Volontairement hors périmètre, traité séparément :** la **notation par IA des exercices
verbaux** (Similitudes / Vocabulaire, `scoring_status = 'ai_pending'`).

---

## 4. Journal des itérations

| # | Lot | Ce qui a été fait | Vérif | Reste |
|---|-----|-------------------|-------|-------|
| 6 | **V** | Passe finale. `_merge.py` (1070 clés × 6 langues, toutes complètes) + `gen-l10n` sans erreur. **Trouvaille de la passe** : le balayage des 6 dépôts a révélé que `mentality-admin`, **site PUBLIC**, servait encore l'ancien bundle — 26 occurrences dans du **texte affiché**, dont l'instruction « saisies manuellement **depuis le manuel WAIS-IV publié** ». 11 commentaires de code nettoyés dans `src/`, `dist/` (non suivi par git) régénéré → `index-ZvVibL0l.js`, **0 occurrence affichable** ; `NE-PAS-DEPLOYER.md` créé pour l'admin ; §3 du dossier de décision mis à jour. | ✅ **analyze diff VIDE** (23/23, 0 erreur) ; **`flutter test` +1019 / 0** ; `mentality_mobile` : *No issues found* ; `npx tsc --noEmit` (admin) sans erreur ; ARB : **1070 clés identiques × 6**, **0 libellé vide**, **0 marque**, **0 sigle** (FSIQ/VCI/VSI/FRI/WMI/PSI), les **2 disclaimers intacts** ; les 6 renommages de sous-tests présents et les anciens noms à 0 ; fiche App Store conforme (AES-256 · Paris · RGPD, mots-clés sans marque) ; **aucun commit créé** — `mentality-flutter-web` toujours sur `bd02280`. | Deux faux positifs écartés honnêtement : `preLocalNotice` (« Rien n'est envoyé ») est **vrai** — le questionnaire préalable est une donnée art. 9 RGPD délibérément non transmise, le code le documente ; et `weRvCi` (« intervalle de confiance à 95 % ») appartient à l'événement d'attente **éteint** (`kWaitingEventEnabled=false`) et n'est pas un texte commercial. |
| 5 | **U** | `scripts/generate_screenshots.js` réécrit. **Deux causes, pas une** : (a) l'app est en **routage par HASH** (`/#/home`) — `goto('/home')` ne changeait donc jamais de route, l'app restait sur le splash puis la porte du splash renvoyait vers `/#/register` : d'où le splash en `01` et l'écran token en `02` ; (b) `networkidle` se déclenche avant que Flutter ait peint. Le script fait désormais **une seule charge de page**, active l'arbre sémantique Flutter (sans lui `body.innerText` est vide en rendu canvas), puis navigue **par hash** et attend un **texte réellement affiché** par écran — et **échoue bruyamment** en affichant le texte réellement vu si l'écran attendu n'apparaît pas. L'user-agent iPhone a dû être retiré : dès que Flutter détecte iOS il n'expose plus de sémantique en headless (5 stratégies d'activation testées, 0 nœud) ; la plateforme détectée ne change ni les dimensions ni le rendu. 12 captures régénérées. | ✅ **12 captures** aux bonnes dimensions (6×1170×2532 + 6×1242×2688) ; **contrôle visuel fait en ouvrant les PNG** : `01_accueil` = vrai accueil, `02_evaluation` = vraie intro d'évaluation, plus `03/04/05/06` et le jeu 6.5" — **aucune marque** sur aucune. `flutter analyze` diff vide. | 2 observations hors périmètre, à trancher par le fondateur : `03_matrices` affiche l'étiquette de mise au point « Règles : 1 \| θ = −2.0 » ; `02_evaluation` titre « Cinq indices » mais énonce « six domaines » et en liste 6 (Langage Oral inclus). |
| 4 | **T** | **9 fichiers du dépôt patient** : `ARCHITECTURE.md` (chapeau + lien vers la boutique Pearson → lien CHC), `CHAT_IA_IMPLEMENTATION.md` (le prompt cité était l'ANCIEN — remplacé par le texte réellement en vigueur dans `claude_chat_service.dart`, + 3 exemples d'écran), `CLAUDE.md`, `CONFIGURATION_CHAT_IA.md`, `docs/AUDIT_UI_UX.md`, `docs/REFONTE_NOTATION_SPEC.md`, `PROJECT_STRUCTURE.md` (3 `*_norms.json` — fichiers **inexistants**, donc renommables), `README_CHAT_IA.md`, `RESUME_IMPLEMENTATION_CHAT.txt`. **2 fichiers de `mentality-admin`** : `CLAUDE.md`, `README.md`. | ✅ dépôt patient : **0** hors les 4 fichiers de chantier. ⚠️ `mentality-admin/CLAUDE.md` conserve **2 occurrences irréductibles** : la table Postgres **vivante** `wais_items` (interrogée par `IRTPage.tsx` et `AnalyticsPage.tsx`) et la migration **appliquée** `003_wais_items_remote_config.sql` — règle dure n° 5, renommage interdit. Une note explicite dans le fichier qualifie ces deux noms d'**identifiants hérités**, non de références produit. | **`.bak` : non réécrits, non supprimés — recommandation au fondateur.** Les 3 portent encore la marque : `CLAUDE.md.bak` (1), `CLAUDE.md.bak-refonte-2026-07-06` (1), `mentality-admin/CLAUDE.md.bak-2026-07-06` (3). |
| 3 | **S** | 5 occurrences dans 4 fichiers de test, **libellés et commentaires uniquement** : `vocabulary_generator_test` et `similarities_generator_test` (« structure WAIS conservée » → « structure de la banque conservée ») ; `difficulty_ladder_test` (« temps WAIS » → « temps imparti », « Protocole WAIS-IV » → « Choix de conception ») ; `matrix_generator_test` (message `reason` : « le WAIS-IV présente 5 options » → « chaque item doit présenter 5 options »). Aucune assertion, aucune valeur attendue touchée. | ✅ `flutter test` → **+1019 : All tests passed** (compte identique à la référence) ; `flutter analyze` **diff vide** (23/23, 0 erreur) ; grep marque sur tout `test/` = **0**. | — |
| 2 | **R** | (1) `mentalite_site_web_flutter` : le « 1 résidu » annoncé était un **faux positif de worktree** (le filtre `/.claude/` ne voit pas les chemins relatifs `.claude/…` — utiliser `--exclude-dir=.claude`) ; l'arbre réel était déjà à 0. Corrigé en revanche l'allégation §2.3 restante dans `lib/widgets/section_04_tests.dart`. (2) `scripts/generate_screenshots_landing.js` : `04_wais.png`→`04_exercices.png`, libellés nettoyés, **sortie déplacée** vers `screenshots_vitrine/` + **garde-fou** qui refuse toute destination sous `ios/fastlane/screenshots/` (testé : sortie en erreur). (3) `main.dart.js` racine : ce n'est pas un fichier égaré — `wrangler.toml` déclare `pages_build_output_dir = "."`, la **racine est la sortie de déploiement**, et tout un build du 3 juillet y dormait, **suivi par git**, avec 101 occurrences dont l'ANCIEN prompt du chat IA. Régénéré par `flutter build web --release` et resynchronisé (`main.dart.js`, `flutter_bootstrap.js`, `flutter_service_worker.js`, `flutter.js`, `index.html`, `version.json`, `assets/`, `canvaskit/`). | ✅ dormant = **0** hors `NE-PAS-DEPLOYER.md` ; script = **0** ; `flutter analyze` **diff vide** (23/23, 0 erreur). ⚠️ `main.dart.js` passe de **101 → 25**, et 25 est le **plancher voulu** : 24 = l'interdiction explicite du chat IA en 6 langues (lexique §3, elle DOIT nommer la marque) + 1 type MIME `application/x-wais-source` d'une bibliothèque tierce. L'ancien prompt « based on the WAIS-IV scales » = **0**. | Sauvegarde de l'ancien artefact dans le scratchpad. Captures App Store non touchées (→ LOT U). |
| 1 | **Q** | `mentality_mobile` : `WaisTests.tsx`→`ExercicesSection.tsx` (+ composant, import et usage dans `App.tsx`) ; allégation §2.3 « la batterie… validée scientifiquement dans le monde » remplacée par « Le cadre de référence académique des aptitudes cognitives humaines » ; `dist/` **non suivi par git** → régénéré par `npm run build` (nouveau bundle `index-CEdt-CNb.js`, l'ancien `index-YriJh32r.js` disparaît) ; `NE-PAS-DEPLOYER.md` mis à jour. | ✅ grep marque sur tout le dépôt (worktrees et `.git` exclus) = **0** ; `npm run build` **OK** (`tsc` absent du projet — vite/esbuild, pas de typecheck : consigné). Bundle EN LIGNE re-téléchargé : il sert **toujours l'ancien** `index-YriJh32r.js`, 2× « WAIS-IV ». | Redéploiement = décision du fondateur (§3.3). Section « Supervision clinique réelle » intacte (§3.1). |
