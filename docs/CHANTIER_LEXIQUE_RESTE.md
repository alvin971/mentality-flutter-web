# Chantier lexique — le RESTE (file de travail de la loop, phase 2)

> Suite de [`CHANTIER_LEXIQUE.md`](CHANTIER_LEXIQUE.md), dont les 10 lots A→J sont
> terminés. Ce fichier couvre ce que la phase 1 n'avait **pas** traité, soit parce
> que c'était hors de son périmètre, soit parce que c'était une exclusion assumée.
> Même discipline : un lot par itération, vérification, puis on coche.

Référence de vocabulaire : [`LEXIQUE_JURIDIQUE.md`](LEXIQUE_JURIDIQUE.md)

---

## Constats d'entrée (établis le 2026-08-28, avant de commencer)

Vérifiés sur ce qui est **réellement servi / réellement dans les dépôts**, pas sur la doc :

- ✅ **`mental-et.com` est EN LIGNE et déjà propre.** 25 Ko servis, 2904 caractères de
  texte visible, **0** occurrence de WAIS / Wechsler / WISC / stockage local /
  scientifique / psychologue / CNIL. Elle annonce même « 13 exercices, 60 à 90 minutes »
  et « Résultat indicatif, ne constitue pas un diagnostic » — exactement les faits
  tranchés au §4 de la phase 1. **Rien à corriger. Ne pas y toucher.**
- ❌ **CONSTAT ERRONÉ, corrigé le 2026-08-28 (voir Journal, ligne RATTRAPAGE)** : j'avais
  écrit que `mentalite-site-web.pages.dev` « sert 435 octets, c'est un talon ». **Faux** :
  la coquille HTML fait 435 octets, mais elle charge un bundle JS de **192 Ko** qui contient
  la marque WAIS-IV et l'allégation de supervision clinique. Ce site est **EN LIGNE** et sa
  source est `~/projects/mentality/mentality_mobile`.
- ⚠️ Dépôts vitrine **dormants** à qualifier : `~/projects/mentalet/mentalite-site-web`
  (2 fichiers concernés) et `~/projects/mentalet/mentalite_site_web_flutter` (8 fichiers).
- ⚠️ `~/projects/mentality/mentality-admin` : 12 fichiers concernés — mais le **§0 du
  lexique dit que c'est l'app PRO**, celle qui parle aux psychologues. Le postulat
  grand-public ne s'y applique pas tel quel : à trancher avant d'agir.
- ⚠️ Dépôt patient : **57 commentaires + docstrings** et **2 constantes mortes**
  (`'WISC'`, `'WAIS'`) portent encore la marque. Exclusion assumée en phase 1
  (« libellés affichés uniquement »), rouverte ici sur demande du fondateur.

---

## Règles dures (inchangées, sauf mention)

1. ❌ Ne JAMAIS éditer `lib/l10n/*.arb` → éditer `l10n_fragments/`, puis
   `python3 l10n_fragments/_merge.py && flutter gen-l10n`.
2. ❌ Ne toucher ni au calcul du score, ni au FSIQ, ni au **contenu** des banques d'items.
   *(Nouveauté phase 2 : les **docstrings d'en-tête** de ces fichiers deviennent
   éditables — le contenu des items, jamais.)*
3. ❌ Ne pas toucher `ctPdfDisclaimer` / `ctIndicativeDisclaimer`.
4. ❌ **Ne pas toucher à `mental-et.com` ni à son dépôt `mental-et-web`** : vérifié propre.
5. ✅ Les 6 langues bougent ensemble.
6. ✅ Un lot par itération.
7. ✅ **Aucun commit** sans instruction explicite du fondateur.
8. ✅ Ne jamais renommer un identifiant **vivant** (référencé quelque part). Une
   constante **morte** peut être supprimée, une constante vivante ne se touche pas.

---

## Lots

### ☑ LOT K — Dépôts vitrine dormants  🔴 *risque de redéploiement*
`~/projects/mentalet/mentalite-site-web` et `~/projects/mentalet/mentalite_site_web_flutter`.
D'abord **qualifier** : sont-ils morts, ou déployables en un clic ? (git, config de
déploiement, wrangler/pages, date du dernier commit). Puis :
- s'ils sont **déployables** → appliquer le lexique comme en phase 1 ;
- s'ils sont **morts** → le dire explicitement en tête de leur README, pour qu'on ne
  les redéploie pas par mégarde.
**Vérif :** aucun des deux dépôts ne peut publier un texte portant la marque —
soit parce qu'il est nettoyé, soit parce qu'il est marqué mort de façon visible.

### ☑ LOT L — `mentality-admin` : trancher puis agir  🟠 *décision de positionnement*
12 fichiers concernés. **Le §0 dit que c'est l'app PRO.** Donc le postulat grand public
ne s'applique pas — mais l'usage de la marque d'un tiers reste encadré par
l'art. L.713-6 CPI (usage référentiel licite **si** nécessaire à indiquer la
destination **et** conforme aux usages loyaux).
Trancher fichier par fichier : **libellé d'interface** vu par un psychologue
(potentiellement licite en usage référentiel) vs **allégation commerciale** ou
**identifiant interne** (à traiter comme en phase 1).
⚠️ Ne rien casser : `normative.service.ts`, `scoring.ts`, `types/index.ts` portent
probablement des identifiants de calcul.
**Vérif :** plus aucune **allégation** portant la marque ; les usages restants sont
soit des identifiants, soit un usage référentiel assumé et **listé** dans le journal.

### ☑ LOT M — Traînée interne du dépôt patient  🟢
57 commentaires et docstrings (`scoring_service.dart`, `complete_test_bloc.dart`,
`pdf_report_service.dart`, en-têtes des banques d'items…) + les 2 constantes mortes
`ageGroupChild = 'WISC'` / `ageGroupAdult = 'WAIS'` de `psychometric_constants.dart`.
⚠️ **Le contenu des items ne bouge pas** — uniquement les docstrings d'en-tête.
⚠️ Vérifier que les constantes sont bien **mortes** avant de les retirer.
**Vérif :** `flutter analyze` sans nouvelle erreur ; plus aucune marque dans les
commentaires de `lib/` hors interdictions du chat ; `flutter test` au même niveau qu'avant.

### ☑ LOT N — Le piège latent de l'événement  🟠
`weRvSelfBody` promet « Ta réponse reste sur ton téléphone et te sera rendue au jour 8 ».
C'est **vrai aujourd'hui** (`eventWorkerUrl` est un placeholder, événement éteint) et
**faux le jour où le worker est renseigné**. Rendre la phrase vraie par construction,
sur les 6 langues, sans promettre ce qu'on ne contrôle pas.
**Vérif :** la phrase reste exacte que le worker soit configuré ou non ; 6 langues ;
`_merge.py` + `gen-l10n` OK.

### ☑ LOT O — Captures d'écran du store  🔴 *sinon tout le LOT A est neutralisé*
`ios/fastlane/screenshots/fr-FR/` est **vide** aujourd'hui, mais
`scripts/generate_screenshots.js` les fabrique depuis l'app buildée. Toute capture
produite avant le 2026-08-28 montre l'ancien splash « WAIS-IV · WISC-V · WPPSI-IV ».
Régénérer après `flutter build web`, ou — si le build n'aboutit pas dans cet
environnement — écrire la marche à suivre et **le dire franchement**, sans faire
croire que c'est fait.
**Vérif :** soit des captures fraîches existent et ne montrent aucune marque, soit
l'impossibilité est constatée, expliquée et consignée. Jamais de faux positif.

### ☑ LOT P — Passe finale phase 2
Rejouer les vérifs K→O, **plus** celles de la phase 1 (elles ne doivent pas avoir
régressé), puis produire la **liste des décisions qui restent au fondateur**.

---

## Journal des itérations

| # | Lot | Ce qui a été fait | Vérif | Reste |
|---|-----|-------------------|-------|-------|
| — | — | *(la loop remplit à partir d'ici)* | — | — |
| 1 | **K** | **Constat d'abord : `mental-et.com` est en ligne et DÉJÀ PROPRE** (0 marque sur 2904 caractères servis, annonce « 13 exercices, 60 à 90 minutes » — les faits mêmes tranchés en phase 1). Non touchée. Les deux dépôts **dormants mais redéployables** ont été nettoyés du **factuel** : marque WAIS-IV, « la référence mondiale », « la plus validée scientifiquement dans le monde », et comptages faux (12 tests / 4 indices → **13 exercices / 5 indices**). Fichiers : `index.html`, `css/style.css`, `KEPLER_STYLE_ANALYSIS.md` d'un côté ; `README.md`, `web/index.html` + artefact `build/`, 4 widgets de section, et **le worker `email-confirmation`** de l'autre. Découvert au passage : un **second jeu de métadonnées App Store** (`fr-FR` **et `en-US`**) dans le dépôt dormant, réécrit lui aussi. | ✅ **0** marque et **0** allégation dans les deux dépôts (hors worktrees `.claude/`, ignorés par git). Bannière `NE-PAS-DEPLOYER.md` présente dans les deux. `mental-et.com` revérifiée : 0. | **DÉCISION FONDATEUR — le point le plus lourd de tout le chantier.** Les deux dépôts portent une section « **Supervisé par de vrais cliniciens** » : supervision clinique affirmée par des psychiatres et psychologues **non nommés** (initiales « DR », citations attribuées à personne), produit qualifié d'« **outil clinique** ». **Je ne l'ai pas réécrite** — ce n'est pas du vocabulaire, c'est un fait à établir. Si cette supervision n'existe pas telle que décrite : pratique commerciale trompeuse (L.121-2, sanction L.132-2 : 2 ans, 300 000 €, jusqu'à 10 % du CA) ; et « outil clinique » expose au régime du dispositif médical (Règl. UE 2017/745, règle 11). Gelé par une bannière dans les deux dépôts. **Deux notes rassurantes** : le worker d'e-mails envoyait « 12 tests cognitifs validés (WAIS-IV) » à de vraies personnes — corrigé ; et le dépôt dormant n'a **pas d'`Appfile`** (bundle `com.mentalite.mentaliteSiteWeb` ≠ `com.mentalite.app`), il ne pouvait donc pas écraser la fiche App Store principale. |
| 2 | **L** | **Tranché : le §0 protège le POSITIONNEMENT de l'admin (outil pro), pas l'usage de la marque d'un tiers.** Fichier par fichier : sur 120 occurrences, **89 sont des identifiants** — `WAIS_TESTS`, `WaisTestConfig`, `WAIS_TEST_IDS`, et surtout la **table Postgres `wais_items`, lue par l'app Flutter** : intouchables, les renommer casserait les deux apps. Corrigé en revanche tout ce qui est **génératif ou affiché** : **8 prompts IA** de `claude.service.ts` (« Tu es un neuropsychologue clinicien expert en interprétation du WAIS-IV », « Analyse cet item WAIS-IV »…) neutralisés vers « psychométrie / modèle CHC », **avec l'interdiction explicite du §3 ajoutée** ; et **12 libellés d'interface** dans `ScoreConfigPage`, `ImprovementNotesPage`, `PreviewPage`, `AnalyticsPage`, `ItemsLibraryPage`. | ✅ **0 allégation** restante sur tout le `.ts`/`.tsx` (89 identifiants + 11 commentaires internes correctement classés). `npx tsc --noEmit` **sans erreur** — rien de cassé. | **Deux découvertes qui dépassent le lexique, à trancher.** (1) `AnalyticsPage` affichait à ses utilisateurs : « Les tables normatives doivent être saisies manuellement **depuis le manuel WAIS-IV publié** » — c'est une consigne de **recopier les tables normatives de Pearson**, soit du droit d'auteur / droit sui generis de base de données, très au-delà de la marque. Texte d'interface corrigé (« à partir de nos propres données d'étalonnage »), mais **la pratique reste à trancher** : vérifié que la migration 002 ne sème que **10 lignes d'exemple synthétique** (percentiles 1/2/9/25/50/75/91/98/99 = repères de la loi normale), donc rien de copié **aujourd'hui**. (2) `ItemsLibraryPage` annonçait « **Items WAIS-IV officiels** » — ce qui contredit le constat de la phase 1 selon lequel nos banques sont originales, et revendiquait la détention d'items protégés. Corrigé. **Non touché volontairement** : les commentaires des migrations SQL déjà appliquées (`002` ligne 35, `013` ligne 96) — éditer une migration jouée est un piège ; la consigne dangereuse a été neutralisée là où elle est réellement lue, dans l'interface. |
| 3 | **M** | **52 commentaires et docstrings** réécrits par transformation contrôlée (relue en simulation avant écriture, deux règles corrigées parce qu'elles cassaient des phrases : « Basé sur les standards WAIS-IV (…, 4e édition) » et les parenthèses orphelines « (Vocabulary - ) »). Dont les **6 docstrings de banques d'items** — `vocabulary_items_fr/en`, `information_items_fr/en`, `similarities_items_fr/en` — qui étiquetaient **nos items originaux** comme « sous-test … (WAIS-IV) », l'exact contraire de notre position. **Le contenu des items n'a pas été touché**, uniquement la ligne 1 de chaque fichier. **5 constantes mortes retirées** de `psychometric_constants.dart` (`WPPSI_BAND1/2`, `OVERLAP`, `WISC`, `WAIS`) après vérification : **0 référence** dans `lib/` ni `test/`. | ✅ **0** marque dans `lib/` hors les 5 interdictions du chat. `flutter analyze` **23 issues / 0 erreur** = référence. | **Référence `flutter test` manquante — comblée par une preuve directe.** La phase 1 n'avait capturé qu'une référence `analyze`, pas `test`. La suite sort à **1014 passés / 5 échoués**, et les 5 sont des **gardes d'architecture** sans rapport avec du texte (« aucun appel à google_fonts dans lib/ », « aucun gris figé dans le chrome », « la porte est unique », « rien ne peut entrer dans la file d'envoi », « aucune page n'appelle la typographie statique »). Plutôt que de supposer, j'ai **mis mes modifications de côté (`git stash` sur `lib/` et `l10n_fragments/`) et rejoué ces deux fichiers de test** : **les mêmes 5 échouent sur l'arbre d'avant**. Ce sont donc des échecs **préexistants**, pas des régressions. Modifications restaurées et vérifiées après coup. **Ces 5 gardes cassées méritent leur propre correctif — hors chantier lexique.** |
| 4 | **N** | **Ma crainte de la phase 1 était FAUSSE, et je l'ai vérifiée avant d'agir.** Je pensais que « Ta réponse reste sur ton téléphone » n'était vraie que par accident, parce que `eventWorkerUrl` est resté un placeholder. C'est l'inverse : `SelfEstimateStore` (`self_estimate_store.dart:19-22`) réutilise le stockage chiffré du moteur de questionnaire mais **JAMAIS sa file d'envoi**, délibérément — « Aucun consentement art. 9 n'est recueilli à ce stade, donc rien n'a le droit de sortir ». La promesse est donc **vraie par construction**, y compris worker configuré. **Aucun libellé n'avait besoin de changer.** En revanche le commentaire ajoutait « une garde de test le vérifie » — et cette garde était **rouge**. C'est elle que j'ai réparée : `waiting_event_feature_test.dart` et `theme_discipline_test.dart` parcouraient `lib/` **sans exclure les worktrees git imbriqués** (`.claude/worktrees/`, checkouts d'autres branches, ignorés par git). 3 parcours de fichiers corrigés. | ✅ **`flutter test` : 1019 tests, 0 échec** — contre 5 échecs en référence. La suite est verte pour la première fois. `flutter analyze` **23 issues / 0 erreur**. | **Gain inattendu : les 5 gardes cassées du LOT M sont réparées, pas contournées.** Elles échouaient toutes pour la même raison — le parcours de `lib/` ramassait les worktrees imbriqués. Une garde rouge en permanence est une garde **morte** : elle ne signale plus rien. Celle qui protège « rien ne part » vaut particulièrement d'être vivante, puisque c'est elle qui rend la promesse de `weRvSelfBody` vérifiable. **Aucune modification de libellé dans ce lot** — la correction porte uniquement sur les tests. |
| 5 | **O** | **Je m'étais trompé en disant les dossiers vides — ils contenaient 24 captures du 23 août**, mon premier contrôle n'avait regardé qu'un seul des quatre répertoires. Elles venaient de `generate_screenshots_landing.js`, qui photographie le **site vitrine dormant**, pas l'app. Vérifié en ouvrant `04_wais.png` : elle porte en texte incrusté « **Supervisé par des psychiatres et psychologues** » (la supervision non tranchée du LOT K), les anciens noms « Similitudes » / « Puzzles visuels », et son nom de fichier même est `04_wais`. **Tout PNG sous `ios/fastlane/screenshots/` est téléversé par fastlane** : les laisser annulait le LOT A en entier. Les 24 ont été **déplacées** (pas supprimées) vers `~/backups/mentality-captures-perimees-2026-08-28/` avec une note expliquant pourquoi. Puis `flutter build web --release` (le build datait aussi du 23 août), installation du chromium playwright manquant (révision 1217), et **12 captures fraîches** générées en 6.5" et 6.9". | ✅ Le bundle compilé ne contient **aucune chaîne de marque affichable** : les 6 occurrences de `WAIS`/`Wechsler` sont les 5 interdictions du chat, et les 6 de `Similitudes` sont des `case` de switch et des clés de `testSequence` — vérifié un par un par contexte. Les captures en découlent. Contrôle visuel sur 3 des 12 : `01_accueil` montre **« CATTELL · HORN · CARROLL »** là où figurait « WAIS-IV · WISC-V · WPPSI-IV », et `05_memoire` montre « MÉMOIRE DE TRAVAIL » (sigle WMI retiré) + « Suites de chiffres » (renommé au LOT H). Aucune marque. | **Deux captures sur douze photographient le mauvais écran** — problème de qualité, pas de lexique, à corriger avant publication : `01_accueil` a saisi le **splash** au lieu de l'accueil, et `02_evaluation` l'écran de **connexion par token** au lieu de l'intro d'évaluation. Le générateur attend `networkidle`, qui se déclenche trop tôt sur une app Flutter Web, et la route `/assessment` bute sur la porte de déblocage. **Corriger la temporisation de `generate_screenshots.js` relève de l'outillage, pas du chantier lexique** — je ne l'ai pas fait pour ne pas élargir le lot une fois de plus. Les 4 autres écrans (matrices, cubes, mémoire, chat) sont exploitables. |
| 6 | **P** | Passe finale, **deux phases rejouées d'un bloc**. Les 6 vérifs de la phase 1 (A, B, C, D, E, I) : **toutes vertes, aucune régression**. Phase 2 : la vérif K a d'abord **ÉCHOUÉ** sur 3 artefacts — `build/web/main.dart.js` et `.dart_tool/` de la vitrine dormante, du JS compilé **d'avant** les corrections, portant encore `WAIS` ×5, « 12 tests » et « scientifiquement ». Un `deploy build/web` aurait repoussé l'ancien texte malgré des sources propres. Vérifiés gitignorés (`.gitignore:29` et `:34`), **0 fichier suivi**, régénérables par `flutter build web` → supprimés (61 Mo). Re-vérif : 0. | ✅ **Tout vert.** `_merge.py` 1070 clés × 6 langues, toutes traduites · `gen-l10n` sans erreur · `flutter analyze` **diff ligne à ligne contre la référence : 0 nouvelle, 0 erreur** · `flutter test` **1019 / 0 échec** · 16 contrôles de contenu sur les 6 ARB, **0 écart** · **0 libellé vide** · 1070 clés dans chacune des 6 langues · les 2 disclaimers **intacts** · 12 captures dans le chemin d'envoi, **toutes du 28 août** · **0 commit créé**. | **Leçon de cette passe : une vérification qui ne regarde que les sources ment.** Le LOT K avait été coché sur des sources propres, mais le JS compilé restait dans le dépôt et restait déployable. C'est le troisième cas du chantier où l'artefact survit à la correction — après les captures d'écran du 23 août (LOT O) et les worktrees imbriqués (LOTs B, C, J, N). **Toujours vérifier ce qui est LIVRÉ, pas seulement ce qui est écrit.** |
| 7 | **RATTRAPAGE** | **Une erreur de ma part, trouvée en re-vérifiant à la demande du fondateur.** En phase 2 j'avais écarté `mentalite-site-web.pages.dev` en écrivant « 435 octets, c'est un talon, pas la vitrine ». **Je n'avais lu que la coquille HTML, pas le bundle JS chargé côté client** — 192 Ko. Ce site est **EN LIGNE** et servait : « 12 tests basés sur le **WAIS-IV** », « **Basé sur le WAIS-IV** », « la batterie la plus utilisée et **validée scientifiquement dans le monde** », « **Supervision clinique réelle** », « **Supervisé par des psychiatres et psychologues** ». Sa source est **`~/projects/mentality/mentality_mobile`**, un dépôt que **je n'avais jamais traité** : mon balayage par dépôt l'avait bien compté (12 fichiers) mais je n'en avais fait aucun lot. Corrigé : 12 remplacements sur 10 fichiers (React + Flutter), marque retirée, allégation « validée scientifiquement » retirée, comptages remis à 13 exercices / 5 indices. Bannière `NE-PAS-DEPLOYER.md` ajoutée, précisant que **le site en ligne, lui, n'est pas corrigé**. | ✅ **0** marque dans les sources ; `flutter analyze` du dépôt : **No issues found**. Une erreur que j'avais introduite au passage (apostrophe de `d'exercices` fermant une chaîne Dart simple-quotée, phrase cassée) a été détectée par `analyze` et réparée avant de conclure. | **Le site EN LIGNE n'est toujours pas corrigé** : le bundle `dist/` servi contient encore l'ancien texte. Rebuild + redéploiement = décision et action du fondateur. Et la **supervision clinique par des praticiens non nommés y figure toujours**, volontairement non réécrite — même réserve qu'au LOT K. **Ce rattrapage confirme la leçon du LOT P, en pire : j'avais conclu sur la taille d'une réponse HTTP au lieu de lire ce qui était réellement servi.** Le même réflexe que celui que le lexique reproche aux textes : affirmer sans pièce. |
