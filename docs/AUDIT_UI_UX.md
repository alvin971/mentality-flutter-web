# Audit UI / UX — Mental E.T.

**Date** : 2026-07-25
**Grille de lecture** : *Maximiser l'UX/UI d'une app — la logique derrière les pratiques modernes*
(synthèse NN/g + benchmarks activation/TTV + performance perçue, 25 juil. 2026).
**Périmètre** : style visuel, expérience, logique de système.
**Hors périmètre (contrainte explicite)** : logique des exercices — génération d'items, scoring, IRT,
timing psychométrique, valeurs retournées à l'orchestrateur. Aucun `domain/` d'exercice n'est touché.
**Nombre de sous-tests** : **l'app en annonce 13, 12 et 12 selon l'écran** — voir §2.0, c'est un
constat d'audit à part entière, pas une note de bas de page.
**Méthode** : lecture du design system, des 12 pages d'exercices, des 3 fichiers de l'étape orale et
des 27 pages produit ; mesure des
ratios de contraste WCAG sur la palette réelle ; comptage d'adoption des composants ; cartographie du
chemin critique inscription → valeur.

---

## 0. Avertissement méthodologique : ce document ne s'applique pas tel quel

Le doc de référence est excellent, mais il décrit des **produits SaaS et apps grand public**. Mental
E.T. est un **instrument de mesure psychométrique**. Trois de ses recommandations, appliquées
littéralement, dégraderaient le produit — il faut le dire avant de dérouler l'audit :

| Recommandation du doc | Verdict pour Mental E.T. |
|---|---|
| §6 « Chaque action a besoin d'une confirmation » | ❌ **À rejeter dans les sous-tests.** Un feedback juste/faux pendant la passation crée un effet d'apprentissage et invalide les normes. C'est exactement ce que les commits `2ef30c4`, `896e105` et `673dda9` viennent de retirer. Ne pas le réintroduire au nom des microinteractions. |
| §3b « Optimistic UI » | ❌ **À proscrire sur l'enregistrement d'une réponse chronométrée.** Afficher un succès avant la persistance réelle sur un item scoré, c'est risquer une divergence entre ce que voit l'utilisateur et ce qui est mesuré. |
| §4 « Défauts intelligents / champs pré-remplis » | ⚠️ **Valable sur l'inscription, interdit sur les items.** |
| §8 « Onboarding personnalisé par segmentation » | ⚠️ Applicable au **parcours** (pourquoi tu es là), jamais aux **conditions de passation** — la standardisation *est* la validité. |

Tout le reste — TTV, budget de friction, performance perçue, zone du pouce, charge cognitive, dark
mode, offline — s'applique pleinement, et c'est là que l'app a le plus à gagner.

---

## 1. Verdict en une page

Le doc dit : *« l'UI est devenue une commodité ; ce qui compte, ce sont les décisions de système et
de comportement. »* Appliqué à cette app, ça donne un diagnostic net :

- **La couche UI est déjà au-dessus de la moyenne.** Design system Kepler cohérent, 3 familles typo
  assumées, chrome de test unifié, écran de résultats à la composition réellement éditoriale. Ce n'est
  pas là que se joue le problème.
- **La couche système, elle, est en contradiction frontale avec la logique du TTV.** Le chemin entre
  l'ouverture de l'app et le moment où elle sert visiblement à quelque chose se compte en **jours ou
  en semaines**, et dépend du comportement de tierces personnes.
- **Et trois régressions de base annulent une partie du travail déjà fait** : le mode sombre est
  illisible, les polices ne sont pas embarquées, 5 exercices sur 12 quittent le design system pendant
  la passation.

Autrement dit : **le chantier n'est pas « refaire le style », c'est « finir de brancher l'existant »
puis « raccourcir le chemin vers la valeur ».**

---

## 2. AXE SYSTÈME — lecture par le Time-to-Value

### 2.0 🔴 L'app ne s'accorde pas avec elle-même sur son propre nombre de sous-tests

Quatre sources dans le code, trois réponses différentes :

| Source | Ce qu'elle dit | Référence |
|---|---|---|
| **Écran « Passer un test »** — liste des sous-tests individuels | **13**, la Compréhension Orale en 13ᵉ, avec le code d'indice `LO` | `assessment_intro_page.dart:154-179` |
| **Bilan complet** — séquence exécutée | **12**, l'oral n'y est pas ; il est ajouté *après* la boucle | `complete_test_session.dart:53-66` + `complete_test_orchestrator_page.dart:255` |
| **Barre de progression du bilan** | « xx / **12** » — puis une 13ᵉ étape que rien n'annonçait | `complete_test_orchestrator_page.dart:426` |
| **Copy produit / marketing** | « **12** sous-tests » | `homeHeroBody`, `homeAboutSubtestsTitle`, `ctIntroContentTitle` |

**Origine, visible dans l'historique git** — deux commits ont implémenté deux modèles mentaux
différents, et aucun n'a mis à jour le reste :

- `62b87d6` — *« move oral test into assessment flow **as a standard sub-test** »* → l'oral devient
  la 13ᵉ carte de la liste, présentée exactement comme les 12 autres.
- `9881f47` — *« compréhension orale **en fin de batterie** »* → dans le bilan complet, l'oral est
  appendu après la séquence, hors compteur.

**Pourquoi c'est un problème d'UX et pas une coquille :**

1. **`LO` n'est pas un indice normé.** Les 12 autres cartes portent `VCI / VSI / FRI / WMI / PSI` —
   des indices normés. La 13ᵉ porte `LO` (« Langage Oral »), avec la même carte, la même typo, le même
   traitement visuel. Elle **ressemble** à un sous-test normé.
2. **Elle n'est pas notée.** Aucune occurrence d'`oral` ou de `LO` dans
   `complete_test_results_page.dart` : l'utilisateur passe une 13ᵉ épreuve qui n'apparaît **nulle part**
   dans son résultat.
3. **C'est en réalité une collecte de données**, avec un consentement dont une case couvre la
   réutilisation « à des fins de recherche **et commerciales** » (`oralConsentCommercialCheckbox`).
   Présenter une collecte avec la grammaire visuelle d'une mesure normée est le point le plus sensible
   de tout cet audit — sur un produit psychométrique, la clarté du statut de chaque épreuve *est* la
   crédibilité.
4. **Durée réelle absente de la promesse** : le consentement annonce lui-même 5 textes × (~1 min de
   lecture + ~40 s de résumé) ≈ **8-10 minutes** (`oralConsentRecordBody`) — qui ne sont pas dans les
   « 60 – 90 minutes » affichées, puisque ce chiffre ne couvre que les 12 sous-tests notés.

**Décision à prendre (produit, pas technique)** — trois options cohérentes, à choisir explicitement :

| Option | Ce qu'on affiche | Conséquence |
|---|---|---|
| **A — 13 sous-tests** | L'oral devient un sous-test à part entière, entre dans `testSequence`, dans le compteur, dans la durée annoncée et dans les résultats | Demande un score ou au moins un retour qualitatif dans le bilan |
| **B — 12 + une étape de contribution** | L'oral sort de la liste des sous-tests, devient une étape clairement nommée « contribution à la recherche », visuellement distincte, avec sa durée annoncée | Le plus honnête, le moins coûteux |
| **C — statu quo** | 13 ici, 12 là | À écarter : l'incohérence est visible par l'utilisateur |

### 2.1 Le chemin critique, mesuré

Reconstitution du parcours réel d'un nouvel utilisateur, code en main :

| # | Étape | Coût |
|---|---|---|
| 1 | Splash | **2 600 ms figés** (`splash_page.dart:36`) + téléchargement des 3 polices |
| 2 | Onboarding | carrousel de **3 slides** (`onboarding_page.dart:21-40`) |
| 3 | Saisie email | 1 écran |
| 4 | OTP email | 1 écran + aller-retour réseau |
| 5 | Saisie téléphone | 1 écran |
| 6 | OTP téléphone | 1 écran + aller-retour réseau |
| 7 | Démographie | sexe + âge + code postal |
| 8 | Génération du token | 1 écran |
| 9 | Succès | 1 écran |
| 10 | Accueil | |
| 11 | Intro évaluation → intro test complet | 2 écrans |
| 12 | **12 sous-tests notés** | **~75-80 min typiques, jusqu'à 2 h** (`docs/TIMING_TEST_COMPLET.md`) |
| 12bis | **Étape orale finale, non notée** — 5 cycles × (lecture + pause 5 s + résumé) | **non comptée dans la durée annoncée** (`oral_test_flow.dart:135`, `_finishWithOralThenResults` → `complete_test_orchestrator_page.dart:255`) |
| 13 | **Verrou de déblocage** | **3 amis qui doivent CHACUN terminer leur propre test de 80 min** + abonnement Instagram + vérification « d'ici quelques heures » (`unlock_service.dart:43` — `unlocked => stage >= 4`) |
| 14 | Résultat | |

**≈ 9 écrans et 2 OTP avant la moindre valeur. Puis 80 minutes + l'étape orale. Puis une dépendance
à trois tiers.**

> ⚠️ **Écart de promesse détecté au passage.** L'app annonce « 60 – 90 minutes » à trois endroits
> (`homeActionStartSubtitle`, `assessBeforeStartBody`, `ctIntroDurationTitle`). Ce chiffre vient de
> `docs/TIMING_TEST_COMPLET.md`, qui ne compte **que les 12 sous-tests notés**. L'étape orale finale
> — 5 cycles de lecture + résumé enregistrés, plus l'écran de consentement et la permission micro —
> s'ajoute **après**, et n'est nulle part dans la durée annoncée. Sur un parcours déjà long, c'est le
> pire moment pour une surprise : elle tombe juste avant les résultats, quand l'utilisateur croit
> avoir fini. À corriger dans les 6 langues.

Le doc cible « première valeur en moins de 5 minutes » et rappelle que **~90 % des utilisateurs
churnent s'ils ne comprennent pas la valeur dans la première semaine**. Ici, un utilisateur qui fait
tout correctement peut ne **jamais** atteindre la valeur — si ses trois filleuls ne vont pas au bout.

### 2.2 Ce que ça veut dire — et ce que ça ne veut pas dire

Attention à ne pas surinterpréter. Le verrou de parrainage est une **décision produit assumée**
(mécanique de croissance en prod depuis juillet), pas un oubli. Et le contrat d'usage est différent
d'une app SaaS : un utilisateur qui vient passer un test de QI **sait** qu'il s'engage sur une durée.

Le problème n'est donc pas la longueur du test. **C'est que le produit ne délivre aucune valeur
intermédiaire sur un parcours d'environ 80 minutes, puis ajoute un verrou au moment précis où la
valeur devait enfin arriver.** Le doc décrit exactement ce cas : *« s'ils terminent le flow et
n'adoptent pas → problème produit, aucun flow ne réparera ça. »*

Deux choses jouent déjà en votre faveur, et il faut les créditer :

- **Le résultat flouté** (`results_history_page.dart:234-279`, `ImageFilter.blur(6,6)` sur le FSIQ) —
  c'est précisément le geste de valeur partielle que le framework prescrit. Bien vu.
- **Les routes par sous-test existent déjà** (`/test/cubes`, `/test/matrices`… — 12 routes dans
  `app_router.dart:122-177`). Le rail technique d'un parcours court est **déjà posé**, il n'est
  simplement pas exposé sur l'accueil.

### 2.3 L'événement d'activation n'est pas défini — et surtout, il n'est pas mesurable

Le doc §10.1 demande d'écrire : « un utilisateur est activé quand il a ______ ».

Aujourd'hui l'app n'a **aucune instrumentation** : 0 fichier contenant `analytics`, `logEvent` ou
`trackEvent` ; aucune dépendance analytics dans `pubspec.yaml`. Il n'existe donc **aucun moyen de
savoir** où les gens décrochent — ni sur les 9 écrans d'inscription, ni sur lequel des 12 sous-tests,
ni devant le verrou.

C'est, dans l'absolu, le point le plus lourd de cet audit : **tout le reste du plan d'action du doc
(cohortes de vitesse, drop-off écran par écran, rétention segmentée activés/non-activés) est
inapplicable tant que ce trou n'est pas comblé.** On optimise à l'aveugle.

### 2.4 Budget de friction — le détail

| Point du doc | État | Constat |
|---|---|---|
| Inscription différée | ❌ | Email **et** téléphone, avec OTP sur les deux, avant tout accès. Le doc appelle ça « un tueur de rétention majeur ». |
| Profilage progressif | ❌ | Sexe, âge, code postal demandés **en bloc** à l'étape 7, avant toute valeur. |
| Permissions contextuelles | ✅ | **Bien fait** : `oral_reading_test.dart:62` affiche un pré-prompt maison expliquant le pourquoi *avant* le prompt système. Exactement le pattern recommandé. |
| Carrousels explicatifs | ❌ | 3 slides + bouton « Passer ». Le doc est catégorique : personne ne les lit. |
| Auth biométrique | n/a | Le modèle token anonyme évite déjà la fatigue mot de passe. Non applicable, et c'est très bien. |

**Nuance importante** : la vérification téléphone n'est pas de la friction gratuite — c'est le
socle du dispositif de token anonyme vérifié (`PLAN_TOKENS_ANONYMES.md`), qui garantit l'unicité sans
linkage. Le sujet n'est donc pas de la supprimer, mais **de la déplacer après le premier moment de
valeur**.

---

## 3. AXE SYSTÈME — performance perçue et états

Le doc appelle ça « le levier le moins cher qui existe ». C'est aussi celui qui est le plus vide ici.

| Pratique | État | Évidence |
|---|---|---|
| **Skeleton screens** | ❌ **0** | 15 `CircularProgressIndicator` bruts, aucun squelette. Le doc mesure ~20 % de gain de vitesse *perçue* à durée identique. Cibles évidentes : historique des résultats, écran de résultats, verrou (polling serveur). |
| **Splash calibré** | ❌ | **2 600 ms en dur**, indépendants du temps réel de résolution du token. Cumulés au téléchargement des polices (§5.2), la première impression est une attente fixe et gratuite. |
| **Estimation de durée** | ✅ | « 60 à 90 minutes » annoncées sur 3 écrans, avec justification sourcée. Exactement ce que le doc recommande sur les attentes longues. |
| **Fermer la boucle** | ⚠️ | Le verrou dit « d'ici quelques heures » (`ugInstaPending`) sans notification de fin — l'utilisateur doit revenir vérifier lui-même. |
| **Offline-first** | ❌ | **1 seul** gestionnaire de perte réseau dans toute l'app (`registration_bloc.dart:271`). Aucun état hors-ligne, aucune file d'actions. Le doc : « une app qui casse hors ligne se fait désinstaller ». Pour une app qui persiste déjà les sessions en local (Hive chiffré), c'est un gaspillage. |
| **`prefers-reduced-motion`** | ❌ **0** | Aucune occurrence de `disableAnimations` / `accessibleNavigation`. |

---

## 4. AXE SYSTÈME — ergonomie, charge cognitive, microinteractions

### 4.1 Zone du pouce — le bon et le mauvais élève cohabitent

- ✅ **Les 12 exercices placent leur CTA en bas** via `KeplerTestScaffold.bottomBar` (12/12). C'est
  la zone verte, sur l'écran où l'utilisateur passe 80 minutes. Excellent.
- ❌ **Zéro page produit n'utilise `bottomBar`** (accueil, résultats, historique, verrou). Leurs CTA
  vivent dans le flux de scroll, donc en zone jaune ou rouge selon la position.
- ❌ **21 `AlertDialog` centrées contre 1 seul bottom sheet.** Le doc est explicite : bottom sheets
  plutôt que modales centrées, l'action là où le pouce est. Chaque dialogue de fin de sous-test, de
  reprise, de déconnexion est une modale centrée dont les boutons tombent au milieu de l'écran.
- ❌ **Actions destructrices en zone rouge inversée** : la déconnexion (`home_page.dart:83`) est une
  icône en **coin haut droit** — donc difficile à atteindre, ce qui est *bon* — mais elle est juste à
  côté du toggle de thème, sans séparation. Deux cibles de 20 sp côte à côte, dont une irréversible.
- ❌ **Cibles tactiles** : `KeplerButton` documente et respecte ≥48 dp ; les `IconButton` de l'AppBar
  sont à `size: 20.sp` sans contrainte de zone tactile explicite.

### 4.2 Charge cognitive

- ✅ **Loi de Hick respectée sur l'accueil** : exactement 3 cartes d'action (dont une « bientôt »).
- ✅ **Zero state travaillé** : `_EmptyState` avec eyebrow, hero éditorial et CTA
  (`histEmptyEyebrow/Hero1/Hero2/Description`). C'est le §4 du doc, appliqué correctement.
- ❌ **Pas de navigation persistante** : tout passe par `Navigator.push`. Le doc recommande une barre
  basse à 3–5 destinations pour les tâches cœur — ici « Passer un test », « Mes résultats », « Chat »
  sont exactement 3 destinations, mais elles ne sont accessibles que depuis l'accueil.
- ❌ **Aucune question de segmentation.** Le doc désigne ce pattern comme « le meilleur ratio
  effort/impact de toute la liste » : une question à l'ouverture (« qu'est-ce qui t'amène ? ») → 3
  parcours. Pour cette app, la segmentation est évidente et à forte valeur : *curiosité personnelle*
  / *démarche diagnostique* / *usage professionnel accompagné* — trois attentes, trois tons de
  restitution, trois niveaux de langage sur les résultats.

### 4.3 Microinteractions

- ⚠️ **Haptique présent dans 1 exercice sur 12** (`visual_puzzles`, 4 appels). Incohérence pure : soit
  le retour tactile de sélection fait partie du langage d'interaction, soit non.
- ⚠️ **10 animations dans toute l'app**, dont le logo animé et le fade du splash. Le doc demande que
  le mouvement *explique la spatialité* ; ici les transitions d'écran sont les transitions Material
  par défaut, y compris entre deux sous-tests d'une même batterie — là où une continuité visuelle
  aurait du sens.
- 🔴 **Rappel du §0** : ne surtout pas appliquer « chaque action a besoin d'une confirmation » aux
  réponses d'items. La confirmation légitime ici, c'est *« ta réponse est prise en compte »*, jamais
  *« ta réponse est juste »*.

### 4.4 La brique IA

La carte « Chat » est en `comingSoon` sur l'accueil. Le doc §7 (« 2026, année de la fatigue IA »)
donne une consigne directement actionnable pour quand elle sortira : **concevoir d'abord le chemin de
correction et le message d'échec, ensuite la fonctionnalité heureuse.** Sur un chat qui commente un
profil cognitif, la question de design n'est pas « comment montrer que c'est de l'IA » — c'est
« que se passe-t-il quand elle dit une bêtise sur les résultats de quelqu'un ». À traiter avant la
sortie, pas après.

---

## 5. AXE VISUEL — le design system existe, il est inégalement branché

### 5.1 Ce qui est solide (à préserver)

| Point | Détail |
|---|---|
| **Système de couleurs** | `AppColors` + `KeplerColors.of(context)` — séparation nette neutres/sémantiques |
| **Palette dark** | Ratios WCAG **calculés et documentés dans le code** (`textPrimaryDark` 14,5:1 AAA, indices 7–12:1) |
| **Typographie** | 3 familles, échelle cohérente (hero 40 → h1 30 → h2 24 → h3 19 → body 15 → mono 11), italiques d'accent = signature |
| **Composants** | `KeplerScaffold`, `KeplerCard`, `KeplerButton`, `KeplerProgress`, `KeplerAppBar`, `KeplerSectionLabel` |
| **Chrome de test** | `KeplerTestScaffold` importé par les 12 exercices, CTA sticky en bas |
| **Résultats** | Composition éditoriale réussie : hero, score 80 sp en mono, filets fins, cartes par indice |
| **i18n** | 6 locales (fr, en, en_GB, de, es, pt), quasi complet |

### 5.2 ✅ CORRIGÉ (2026-07-25) — le mode sombre était illisible

> **Statut : traité.** Palette sombre entièrement recalibrée en APCA, cause racine
> supprimée (typographie contextuelle `AppText.of(context)`), 54 fichiers migrés,
> 2 tests de non-régression ajoutés (contraste APCA + discipline architecturale).
> 385 tests verts, 0 erreur d'analyse. Le diagnostic ci-dessous est conservé pour
> mémoire — voir §5.2bis pour ce qui a été fait.

#### Diagnostic d'origine

Le doc §9 : *« le dark mode n'est plus une tendance, c'est un standard attendu ; son absence fait
paraître une app datée »*. Ici il est pire qu'absent : **il est présent et cassé.**

**Cause racine** : dans `app_typography.dart`, chaque style a une couleur claire par défaut
(`color ?? AppColors.textPrimary`, 14 occurrences lignes 22-126). Toute page appelant `AppText.body()`
**sans argument** grave la couleur du mode clair. Le `textTheme.apply(bodyColor: …)` du thème sombre
(`main.dart:233`) ne rattrape rien : il n'agit que sur les widgets qui *lisent* le `TextTheme`.

**Ampleur** : **68 appels** sans couleur, dans 12 fichiers — `unlock_gate_page` (11),
`results_history_page` (10), `complete_test_results_page` (9), `home_page` (7), `orchestrator` (5),
`assessment_intro` (5), 6 autres fichiers (21).

**Contrastes mesurés** (WCAG 2.1, AA = 4,5:1) :

| Élément | Rendu | Ratio | |
|---|---|---|---|
| Titre de l'accueil (`heroDisplay`) | `#0B1F17` sur `#121212` | **1,06:1** | invisible |
| Libellés d'indices (`bodyStrong`) | `#0B1F17` sur carte `#1F1F1F` | **1,04:1** | invisible |
| Corps de texte (`body`) | `#3D5248` sur `#121212` | **2,23:1** | illisible |
| Score FSIQ 80 sp | `#4D7C4A` sur `#1F1F1F` | **3,37:1** | échec AA |

**Reproduction** : accueil → icône lune (`home_page.dart:81`) → le titre de la page disparaît. Puis
« Mes résultats » → score et libellés illisibles.

**Le paradoxe** : la solution est déjà dans le codebase (`AppColors.primaryLightDark`,
`accentForBrightness()`, palette dark calibrée). Elle n'est simplement pas appelée par les pages.

### 5.2bis Ce qui a été fait (2026-07-25)

**Méthode — pourquoi APCA et pas WCAG.** Le ratio WCAG 2.x est symétrique : il traite
« clair sur sombre » comme « sombre sur clair ». La perception, non. WCAG surestime
donc le contraste en mode sombre, ce que confirme la littérature d'accessibilité. Les
commentaires du code affirmaient « AA garanti » sur des couples réellement sous le
seuil de lecture :

| Jeton | WCAG 2.x annoncé | APCA réel | Verdict |
|---|---|---|---|
| `textTertiaryDark` #888888 | 4,65:1 « AA » | **Lc 37** | illisible en 11 sp |
| `textSecondaryDark` #C0C0C0 | 9,06:1 « AAA » | **Lc 67** | sous le seuil corps |
| `primaryLightDark` #7CB58A | 6,93:1 « AA » | **Lc 53** | sous le seuil corps |
| bordure blanc 20 % | 1,72:1 | **Lc 0** | invisible |
| carte vs fond | 1,14:1 | **Lc 0** | aucune séparation |

Un test basé sur WCAG aurait laissé passer les cinq.

**Nouvelle palette.** Conçue par solveur : la cible perceptuelle pilote la couleur, et
non l'inverse. Teinte de marque conservée, saturation bornée par rôle, luminosité
résolue par dichotomie sous contrainte APCA.

| Rôle | Valeur | Lc sur carte |
|---|---|---|
| fond / surface / carte / raised | `#101312` `#181C1A` `#1E2321` `#272D2A` | — |
| texte primaire | `#E2E9E5` | 90 |
| texte secondaire | `#CBD7D1` | 78 |
| texte tertiaire | `#C1CDC7` | 72 |
| accent de marque | `#B9DAB6` | 76 |
| fill de bouton | `#C0DCBD` | label à 80 |
| bordure / filet | `#5C8B59` / `#598156` | 32 / 30 |
| success / error / warning / info | `#94E0C0` `#F4C6C0` `#ECCD95` `#BDD3F1` | 76 |
| indices VCI/VSI/FRI/WMI/PSI | `#E3C7F2` `#9FDAE9` `#DEE4F9` `#C0EEDD` `#ECCD8D` | 76–88 |
| FSIQ | = accent de marque | 76 |

Choix de conception notables :

- **Ni noir pur ni blanc pur.** #000 provoque de la halation sur OLED, #FFF « bave ».
  Le socle est un très sombre légèrement vert, en écho au crème/vert forêt du mode clair.
- **La carte se détache par son TRAIT, pas par son fond.** Entre deux quasi-noirs,
  l'écart de remplissage reste sous le seuil de perception quoi qu'on fasse ; c'est la
  bordure (Lc 32) qui porte la structure. L'ancienne bordure blanc 20 % était à Lc 0 —
  la mise en page n'existait littéralement pas pour l'œil.
- **FSIQ n'est plus une 6ᵉ teinte.** C'est le score global : il porte la couleur de
  marque. Ça règle au passage une collision présente aussi en mode clair — VCI, FRI et
  FSIQ étaient trois violets voisins (ΔE OKLab 0,005, indiscernables).
- **Les stimuli ne sont pas thématisés.** Les couleurs de `presentation/widgets/`
  (faces de cubes, cellules de matrices, jetons, balances) restent intactes : les
  changer modifierait la difficulté perceptive, donc la mesure.

**Cause racine supprimée.** `AppText.body()` gravait la couleur du mode clair dans le
style ; le `textTheme.apply()` du thème sombre ne rattrapait rien, puisqu'il n'agit que
sur les widgets lisant le `TextTheme`. Ajout de `AppText.of(context)` → `KeplerText`,
qui résout ses défauts via `KeplerColors`. Migration : **177 appels typographiques,
125 couleurs, 53 gris figés, 21 blancs de bouton — 54 fichiers.**

**Symétrie des thèmes rétablie.** Le thème clair a reçu les sections qui n'existaient
qu'en sombre : `outlinedButtonTheme`, `textButtonTheme`, `dialogTheme`, `dividerTheme`.
Les boutons ne changent plus de forme selon le thème.

**Verrous anti-régression** (c'est ce qui rend la correction durable) :

1. `test/core/theme/dark_palette_contrast_test.dart` — réimplémente APCA en Dart et
   vérifie chaque couple de jetons contre son seuil. Modifier une constante sans
   refaire le calcul fait échouer la CI.
2. `test/core/theme/theme_discipline_test.dart` — interdit dans `lib/features/` et
   `lib/core/widgets/` tout appel `AppText.<méthode>()` statique et tout
   `AppColors.grey*`. Les répertoires de stimuli sont exclus explicitement.

**Suite traitée le même jour** (commits `af13690`, `ffc50d8`) : palette claire
recalibrée (17 échecs sur 23 → 0 sur 33), réponse invisible du sous-test Code,
fonds de boutons désactivés, panneau de stimulus à luminance constante pour les
5 épreuves perceptives, et polices embarquées.

### 5.3 ✅ CORRIGÉ (2026-07-25) — les polices n'étaient pas embarquées

> **Statut : traité** (commit `ffc50d8`). Les trois familles sont dans
> `assets/fonts/`, déclarées au pubspec, allégées de 2,4 Mo à 472 Ko (latin +
> graisses utilisées, couverture des 6 langues vérifiée). `app_typography.dart`
> n'appelle plus `GoogleFonts` : fabriques locales pilotant l'axe `wght` via
> `fontVariations`. `scripts/subset_fonts.py` rend l'opération reproductible.
> Contradiction « DM Mono » vs Roboto Mono tranchée en faveur de Roboto Mono.
> Build web vérifié, 398 tests verts.

#### Diagnostic d'origine

`pubspec.yaml` déclare `google_fonts` mais **aucune section `fonts:`** ; le seul fichier de police du
build est `MaterialIcons-Regular.otf`. Source Serif 4, DM Sans et Roboto Mono sont téléchargées au
runtime.

- **Premier lancement sans réseau → identité perdue** : retour à Roboto/SF système, les italiques
  serif — la signature de la marque — disparaissent. Le doc §9 classe l'offline dans les motifs de
  désinstallation.
- **FOUT au démarrage** : le splash s'affiche en police système puis bascule.
- **Requête vers `fonts.gstatic.com` au lancement** : à trancher côté RGPD pour une app qui se veut
  zéro-linkage.
- **Contradiction interne** : `app_typography.dart:4` documente « DM Mono » alors que le code appelle
  `GoogleFonts.robotoMono()`.

### 5.4 🟠 Majeur — 5 exercices sur 12 quittent le design system *pendant* la passation

`KeplerTestScaffold` est importé par les 12 exercices, mais dans 5 il n'habille que l'écran d'**intro**.
L'écran de test — celui où l'utilisateur passe la totalité de son temps — repart d'un `Scaffold` +
`AppBar` Material bruts.

| Exercice | Écrans concernés | `Scaffold` bruts |
|---|---|---|
| `digit_span` | intro de partie, présentation, saisie | 3 |
| `picture_span` | présentation, rappel | 2 |
| `coding` | écran de test | 1 |
| `symbol_search` | écran de test | 1 |
| `arithmetic` | écran de test | 1 |

Disparaissent alors : eyebrow mono, titre serif italique, logo animé, accent d'indice, barre de
progression Kepler. Apparaissent à la place (mesuré sur `coding_test_page.dart:286-400`) : `AppBar`
Material standard, `TextStyle(fontSize: 14.sp, bold)` inline hors échelle, un badge timer réinventé
(pilule radius 20) alors que `KeplerTestTimer` existe, et des `AppColors.grey100/200/300/600` figés —
**donc ces écrans sont intégralement cassés en mode sombre** (cellules `#F3F4F6` sur fond `#121212`).
**57 usages** de `AppColors.grey*` subsistent dans les exercices, concentrés sur ces 5 pages.

> Tout ceci est du **chrome**. Remplacer l'enrobage ne touche ni la génération d'items, ni les
> timers, ni le scoring, ni ce qui remonte à l'orchestrateur.

**Et le cas le plus lourd n'est pas dans `exercises_implementations/` : c'est l'étape orale finale.**
Les 3 fichiers de `lib/features/data_collection/` n'utilisent **rien** du design system :

| Fichier | `AppText` | `KeplerButton` | `Kepler*Scaffold` | `TextStyle` inline | Couleurs figées | `ElevatedButton` |
|---|---|---|---|---|---|---|
| `oral_test_flow.dart` | **0** | **0** | **0** | 18 | 4 | 4 |
| `oral_reading_test.dart` | **0** | **0** | **0** | 10 | 7 | 6 |
| `oral_summary_test.dart` | **0** | **0** | **0** | 10 | 6 | 6 |

Zéro typographie Kepler, zéro couleur de thème, **38 `TextStyle` inline** et **17 couleurs codées en
dur**. C'est du Material brut de bout en bout — donc cassé en mode sombre comme les 5 exercices
ci-dessus. Et c'est **le dernier écran que voit l'utilisateur avant ses résultats**, après 80 minutes
de passation dans la charte Kepler. La rupture visuelle tombe au pire endroit du parcours.

### 5.5 🟠 Majeur — la palette *claire* n'a jamais reçu le traitement WCAG de la palette sombre

| Couleur | Sur fond | Ratio | AA texte | AA UI (3:1) |
|---|---|---|---|---|
| `textTertiary #7A9488` | crème `#FAF9F6` | **3,11:1** | ❌ | ✅ |
| `textTertiary` | `surfaceVariant #EEF1EC` | **2,87:1** | ❌ | ❌ |
| `indexPSI #F59E0B` | crème | **2,04:1** | ❌ | ❌ |
| `indexVSI #06B6D4` | crème | **2,31:1** | ❌ | ❌ |
| `indexWMI #10B981` | crème | **2,41:1** | ❌ | ❌ |
| `iqLowAverage #FBBF24` | crème | **1,59:1** | ❌ | ❌ |
| `warning #F59E0B` | blanc | **2,15:1** | ❌ | ❌ |

Deux conséquences :

1. **`textTertiary` est la couleur par défaut de `mono()` et `monoLabel()`** — soit **60 appels** :
   tous les eyebrows, tous les compteurs « 01 / 12 », toutes les méta-données. Du **11 sp à 3,11:1**,
   c'est le pire couple possible.
2. **Les couleurs d'indices sont les couleurs des résultats** — celles qui portent la valeur
   commerciale. À 2,0–2,4:1 elles échouent même le seuil 3:1 des éléments graphiques non textuels
   (WCAG 1.4.11), donc y compris en simple remplissage de barre.

### 5.6 🟠 Majeur — incohérences structurelles du thème et du design system

| Section `ThemeData` | Clair | Sombre |
|---|---|---|
| `elevatedButtonTheme` | ✅ | ✅ |
| `outlinedButtonTheme` | ❌ **absent** | ✅ |
| `dialogTheme` | ❌ **absent** | ✅ |
| `dividerTheme` | ❌ **absent** | ✅ |
| `textButtonTheme` | ❌ absent | ❌ absent |

→ **La forme des boutons change selon le thème** : les 11 `OutlinedButton` sont en *stadium* Material
en clair, en radius 6 Kepler en sombre. Idem pour les 21 `AlertDialog`.

**Composants du DS jamais utilisés** :

| Composant | Pages qui l'utilisent |
|---|---|
| `KeplerTestScaffold` / `KeplerTestButton` | 12 / 12 |
| **`KeplerTestTimer`** | **0** |
| **`KeplerInstructionCard`** | **0** |

**Trois langages de bouton** : 49 `ElevatedButton`, 33 `TextButton`, 22 `KeplerButton`,
11 `OutlinedButton`, 1 `FilledButton`. `TextButton` n'a **aucun thème dans les deux modes** — et c'est
lui qui porte les actions secondaires des 21 dialogues, donc les moments décisifs du parcours.

### 5.7 🟡 Moyens et mineurs

| # | Constat | Évidence |
|---|---|---|
| Y1 | **`ThemeMode.system` jamais utilisé** — l'app démarre toujours en clair et ignore la préférence OS | `theme_notifier.dart:11` |
| Y2 | **10 chaînes françaises codées en dur**, toutes sur le **tunnel d'entrée** (« Bienvenue », « Se connecter », « Passer », « Générer mon token ») — un utilisateur allemand voit du français avant tout le reste | `token_login_page.dart:28`, `token_restore_page.dart:60,125`, `onboarding_page.dart:82`, `token_issuance_step.dart:278-382` |
| Y3 | **Accessibilité minimale** : 0 `semanticLabel`, 3 `tooltip`, 20 `Semantics` sur 152 fichiers | balayage `lib/` |
| Y4 | **Responsive quasi inexistant** : 2 breakpoints (accueil 800 px, `visual_puzzles` 900 px). Le doc §5 insiste sur le multi-format ; sur tablette — usage plausible en passation accompagnée — 26 écrans sur 28 sont un layout téléphone étiré | `home_page.dart:53` |
| Y5 | **165 couleurs codées en dur** hors `core/theme`, dont 13 dans le générateur de PDF (le livrable vendu) | balayage `lib/` |
| m1 | `KeplerSectionLabel.withGlyph` déclaré, jamais lu — API mensongère | |
| m2 | `_TestAppBar` empile `FittedBox` + `ConstrainedBox(maxHeight:34)` + `FittedBox` : rustine anti-débordement qui signale une échelle typo non responsive | `kepler_test_scaffold.dart:170-195` |
| m3 | `KeplerCard` applique une ombre `black 4 %` identique en clair et en sombre — sans effet sur `#121212` | |
| m4 | Trois hauteurs d'en-tête : `KeplerAppBar` 72.h, `_TestAppBar` 78.h, `AppBarTheme` 56 | |

---

## 6. Grille de conformité au doc de référence

| § du doc | Sujet | État |
|---|---|---|
| 1 | Événement d'activation défini | ❌ inexistant |
| 1 | Instrumentation / cohortes de vitesse | ❌ **0 analytics dans l'app** |
| 2 | Inscription différée | ❌ email + tel + 2 OTP avant valeur |
| 2 | Profilage progressif | ❌ démographie en bloc |
| 2 | Permissions contextuelles | ✅ pré-prompt micro exemplaire |
| 2 | Carrousel d'onboarding retiré | ❌ 3 slides |
| 3 | Skeleton screens | ❌ 0 (15 spinners) |
| 3 | Optimistic UI | 🚫 volontairement inapplicable (§0) |
| 3 | Estimation de durée sur attente longue | ✅ « 60-90 min » sourcé |
| 3 | Fermer la boucle | ⚠️ verrou sans notification de fin |
| 3 | `prefers-reduced-motion` | ❌ 0 |
| 4 | Loi de Hick (3-5 options) | ✅ 3 cartes |
| 4 | Zero states travaillés | ✅ `_EmptyState` éditorial |
| 4 | Navigation visible, pas cachée | ❌ pas de barre persistante |
| 5 | CTA en zone verte | ✅ 12/12 exercices · ❌ 0/4 pages produit |
| 5 | Bottom sheets > modales | ❌ 21 dialogues / 1 sheet |
| 5 | Cibles ≥ 44-48 px | ⚠️ OK boutons, non garanti icônes |
| 5 | Multi-format | ❌ 2 breakpoints |
| 6 | Haptique en renfort du critique | ⚠️ 1 exercice sur 12 |
| 6 | Confirmation systématique | 🚫 volontairement rejeté dans les sous-tests (§0) |
| 7 | IA : chemin d'erreur conçu d'abord | ⏳ chat « bientôt » — à cadrer avant sortie |
| 8 | Question de segmentation | ❌ absente |
| 9 | Dark mode | 🔴 présent et **illisible** |
| 9 | Offline-first | ❌ 1 gestionnaire réseau dans toute l'app |

---

## 7. Le chantier — 5 lots

Ordonnés par ratio impact/risque. **Aucun lot ne touche à `domain/`, au scoring, au timing ni à la
génération d'items.**

### Lot 0 — Instrumenter *(prérequis à tout pilotage, ~2 j)*
Sans ça, les lots suivants s'évaluent à l'intuition.
- Écrire la phrase d'activation. Proposition à valider : **« un utilisateur est activé quand il a
  terminé son premier sous-test et vu un retour »** — observable, atteignable en < 10 min, et
  compatible avec le verrou (qui ne porte que sur le bilan complet).
- Événements minimaux : `app_open`, `onboarding_slide_view`, `otp_sent/verified`, `subtest_start/end`
  (id + durée + abandon), `results_view`, `unlock_step_reached`.
- Cohortes de vitesse et drop-off écran par écran.
- Choisir un outil respectueux du modèle anonyme (auto-hébergé ou sans identifiant persistant) — ce
  point est à arbitrer avec les contraintes du dispositif de token.

### Lot 1 — Rendre le mode sombre viable *(bloquant, risque faible)*
- Typographie contextuelle (`AppText.of(context)` ou équivalent) résolvant la couleur via
  `KeplerColors.of(context)`.
- Migrer les **68 appels** sans couleur.
- Remplacer les `AppColors.primary/success/warning` figés des résultats par `accentForBrightness()`.
- Purger les `AppColors.grey*` des 5 pages d'exercices.
- **Filet** : goldens clair + sombre sur accueil, résultats, historique, verrou et une page
  d'exercice ; un contraste < 4,5:1 échoue la CI.
- *Nature du changement : couleur de texte. Zéro impact sur la mesure.*

### Lot 2 — Sécuriser l'identité et le démarrage *(bloquant, risque très faible)*
- Embarquer les 3 polices dans `assets/fonts/` + `pubspec.yaml`, désactiver
  `GoogleFonts.config.allowRuntimeFetching`.
- Trancher DM Mono vs Roboto Mono, aligner code **et** doc.
- Splash piloté par la résolution réelle du token (plancher ~800 ms au lieu de 2 600 ms fixes).
- Gains cumulés : plus de FOUT, plus de requête Google, démarrage nettement plus court.

### Lot 3 — Raccourcir le chemin vers la valeur *(le lot à plus fort impact, à cadrer avec toi)*
Le rail existe déjà, il faut l'exposer :
- **Exposer un sous-test unique en accès libre depuis l'accueil**, avant inscription — les 12 routes
  `/test/*` existent. C'est le « accès invité » du doc, appliqué sans rien casser : le verrou continue
  de porter sur le **bilan complet**, seul livrable commercial.
- **Différer l'inscription** après ce premier sous-test. La vérification téléphone reste obligatoire
  avant le bilan complet (elle fonde l'unicité du token) — elle change juste de place.
- **Profilage progressif** : demander la démographie au moment où elle sert (le calcul normatif),
  pas à l'inscription.
- **Remplacer le carrousel** par une question de segmentation (§8 du doc) : « qu'est-ce qui
  t'amène ? » → curiosité / démarche diagnostique / usage professionnel → 3 tons de restitution.
- **Valeur intermédiaire pendant les 80 minutes** : une progression lisible « 4 / 12 · domaine
  travaillé », sans aucun score — cohérent avec le protocole, qui interdit le feedback de performance,
  pas le feedback d'avancement.

### Lot 4 — Unifier la couche visuelle des exercices *(majeur, risque contenu)*
- **Priorité : l'étape orale** (3 fichiers `data_collection/`, 0 % de design system) — c'est le dernier
  écran avant les résultats, et le plus éloigné de la charte.
- Passer les 5 écrans de test restants sous `KeplerTestScaffold`.
- Brancher `KeplerTestTimer` partout, supprimer les 5 badges maison.
- Remplacer les `_buildInfoCard()` dupliqués par `KeplerInstructionCard`.
- Compléter le thème clair : `outlinedButtonTheme`, `textButtonTheme`, `dialogTheme`, `dividerTheme`.
- **Règle** : on ne modifie que l'enrobage et les styles. `setState`, timers, compteurs d'items et
  valeurs retournées restent identiques ligne pour ligne.
- **Filet** : les 372 tests restent verts sans qu'aucune assertion soit modifiée.

### Lot 5 — Performance perçue, ergonomie, accessibilité *(cadençable)*
- Squelettes sur historique, résultats et polling du verrou (gain perçu ~20 %, coût quasi nul).
- Migrer les dialogues d'action vers des bottom sheets ; garder la modale centrée pour les
  confirmations critiques (abandon de sous-test).
- CTA des pages produit en `bottomBar`.
- Palette claire recalibrée : variantes assombries des couleurs d'indices, `textTertiary` au-dessus
  de 4,5:1 ou réservé au non-textuel.
- `ThemeMode.system` par défaut ; `prefers-reduced-motion` respecté ; `semanticLabel` sur les icônes
  porteuses de sens.
- État hors-ligne explicite + file d'actions (Hive chiffré est déjà en place).
- Externaliser les 10 chaînes françaises du tunnel d'entrée.
- **Corriger la durée annoncée** dans les 6 langues pour inclure l'étape orale, et l'annoncer *avant*
  le lancement du bilan — pas au moment où l'utilisateur croit avoir fini.
- Grille tablette au-delà de 600 px.

---

## 8. Ce qu'il faut trancher avant de lancer

0. **Combien de sous-tests a ce produit — 12 ou 13 ?** (§2.0) C'est la question la plus urgente de
   la liste, parce qu'aujourd'hui l'app répond les deux selon l'écran, et parce qu'elle engage le
   statut d'une épreuve non notée présentée comme normée. Options A / B / C en §2.0.
1. **Le mode sombre est-il un objectif produit ?** Si oui, le Lot 1 est bloquant avant publication.
   Si non, l'alternative honnête est de **retirer le bouton lune** — un mode sombre illisible coûte
   plus cher qu'un mode sombre absent. Ça conditionne l'ordre de tout le chantier.
2. **Accepte-t-on un sous-test en accès libre avant inscription ?** C'est le cœur du Lot 3 et le seul
   levier qui fasse passer le TTV de « plusieurs jours » à « quelques minutes ». Le risque à peser :
   exposition d'items normés à des utilisateurs non identifiés (effet d'apprentissage sur une
   éventuelle passation ultérieure). Un sous-test dédié « démo », hors bilan, neutralise ce risque.
3. **Analytics vs modèle anonyme** : quel niveau de mesure est acceptable sans trahir la promesse
   zéro-linkage ? Sans réponse, le Lot 0 ne peut pas démarrer — et tout le reste se pilote à l'aveugle.
4. **Cible tablette** : passation accompagnée sur téléphone uniquement, ou pas ? Décide si le
   responsive du Lot 5 est cosmétique ou nécessaire.
5. **Niveau d'accessibilité visé** : AA partout, ou AA sur le parcours produit et « best effort » dans
   les stimuli ? Les cubes, matrices et puzzles ont des contraintes perceptives propres qui peuvent
   légitimement primer sur WCAG — mais il faut le décider, pas le subir.
