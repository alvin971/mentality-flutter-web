# PLAN — Événement d'attente des 8 jours

> ## ⏸️ MIS DE CÔTÉ POUR LE LANCEMENT — 2026-07-31
>
> **Décision produit : au lancement, l'utilisateur ne voit que le décompte.**
> Un programme de huit journées à remplir est beaucoup à assumer pour un
> début ; on fait d'abord patienter, on rallumera ensuite.
>
> **Rien n'est supprimé.** Le code, ses contenus et ses ~950 tests restent
> dans la branche et continuent de tourner à chaque exécution de la suite.
> L'événement est éteint par un interrupteur unique :
> `lib/features/waiting_event/waiting_event_feature.dart`
> (`kWaitingEventEnabled = false`).
>
> Il ferme la seule porte d'entrée — le bouton « Voir le programme du jour »
> de la carte d'attente. Hub, révélations, questionnaires, bloc diagnostic et
> jeux sont tous derrière elle et derrière elle seule ; une garde de test
> (`waiting_event_feature_test.dart`) vérifie qu'aucune seconde porte n'est
> percée et que rien ne peut entrer dans la file d'envoi.
>
> **Pour rallumer** : passer l'interrupteur à `true`, mettre à jour la garde
> qui épingle sa valeur, et vérifier d'abord que `AppConstants.eventWorkerUrl`
> n'est plus un gabarit et que `workers/event` est déployé.
>
> **Livré avant la mise de côté** : lots A, B, C, D, F, J, H1, H2, H3, E1.
> **Non commencés** : E2, E3, E4, G, H4, H5, I.

> **Statut du plan :** conception validée en discussion (2026-07-26).
> **Prérequis techniques déjà livrés** : palier 3 = attente serveur 8 jours
> (`UNLOCK_DELAY_MINUTES=11520`, ancre `stage3StartedAt`, décompte à ancrage
> monotone, carte de partage J8) — commits `c1cc487`, `78b95ee`, `97bf113`.

---

## 1. Le concept en une phrase

Pendant les 8 jours d'attente, chaque jour apporte **une révélation** (un morceau
du profil cognitif déjà gagné pendant le test) et **une activité facultative**
(test annoncé, contribution communautaire ou jeu) — sans que rien ne conditionne
jamais le déblocage : **le temps seul débloque, côté serveur.**

---

## 2. Les trois piliers

### A · Révélation ≠ Activité

| | Révélation 🎁 | Activité |
|---|---|---|
| L'utilisateur… | ne fait RIEN, il découvre | répond ou joue |
| Contenu | un indice de SON test déjà passé | questionnaire ou jeu |
| Rôle | le cadeau quotidien | le contenu quotidien |

La révélation est le moteur du retour : il a payé 90 minutes de test, on lui rend
son dû morceau par morceau au lieu de tout retenir 8 jours.

### B · Annoncé ≠ Contribution

| | ✅ Annoncé | 🔬 Contribution |
|---|---|---|
| Résultat affiché | OUI — score + seuil | NON — aucun score |
| Instruments | validés, libres, vérifiés | nos questions candidates |
| Cadrage à l'écran | « ton résultat » | « aide-nous à construire notre test de dépistage » |
| Finalité RGPD | dépistage informatif | construction/amélioration de nos échelles |

La contribution est annoncée telle quelle, honnêtement — c'est ce qui rend les
données exploitables (et revendables) plus tard.

### C · Le temps seul débloque

- Les jours s'ouvrent par écoulement du délai **serveur** (dérivé de
  `stage3StartedAt`), jamais par une action.
- **Aucun questionnaire de santé n'est récompensé ni requis** — sinon les gens
  répondent n'importe quoi pour avancer et les données ne valent plus rien.
- Tout est facultatif ; un jour manqué reste rattrapable (recommandation — à
  confirmer).

---

## 3. Le tableau maître

Règle de volume : **chaque test fait entre 40 et 50 questions.** Les
instruments validés calculent le score ; nos questions complètent le volume et
enrichissent les données (composition dévoilée en page Méthodologie, jamais au
milieu du flux).

| Jour | 🎁 Révélation | Le test du jour (tel que vu) | Composition interne | 🎮 Jeu | Q |
|---|---|---|---|---|---|
| **J1** | Indice **verbal** (VCI) | « Ta personnalité » | IPIP-50 (50 scorées) · + auto-estimation QI + bloc diagnostic hors test | — | **50** |
| **J2** | **Vitesse** (PSI) | 🔬 « Construis notre test lecture » | 40 candidates dyslexie | Stroop | **40** |
| **J3** | **Mémoire de travail** (WMI) | « Ton équilibre » | GAD-7 (7) + PHQ-8 (8) scorées + 30 à nous (plaintes cognitives, même échelle) | — | **45** |
| **J4** | **Raisonnement** (FRI) | 🔬 « Construis notre test attention 1/2 » | 45 candidates TDAH | Tolérance au délai | **45** |
| **J5** | Indice **spatial** (VSI) | 🔬 « Construis notre test attention 2/2 » | 25 candidates TDAH + 15 contexte (sommeil, écrans, organisation) | Estimation du temps | **40** |
| **J6** | **Forces & faiblesses** | « Ton énergie » | CBI (~19 scorées) + 25 à nous (alexithymie) | Calibration de la confiance | **~44** |
| **J7** | — | 🏅 « Bilan autisme » | RAADS-14 (14) + *Partie 2 :* CAT-Q (25) scorées + 10 à nous | — | **49** |
| **J8** | 🏆 **QI global** (+ vs auto-estimation) | Carte de partage | — | — | 0 |

**Tous les jours** : 1 biais cognitif expliqué (fond de roulement, rejouable,
sans score).

Logique du rythme : J1 ouvre sur du valorisant (personnalité, jamais un
dépistage clinique en premier) ; J5 est volontairement léger (creux de milieu de
parcours) ; l'autisme ferme la série en J7 (« le meilleur pour la fin », choix
utilisateur) ; J8 = zéro question, pure récompense.

Cohérences thématiques : J2 = vitesse révélée + Stroop (lecture) + dyslexie ;
J3 = mémoire révélée + plaintes cognitives ; J7 = jour vedette, sans révélation
concurrente.

### Fusions d'instruments — validées

- **J3 « Ton équilibre »** : GAD-7 + PHQ-8 fusionnent sans couture — même
  équipe d'auteurs (famille PHQ), MÊME échelle de réponse à 4 niveaux sur
  2 semaines, co-administrés partout en pratique (le PHQ-4 est littéralement
  leur fusion officielle). Nos 30 questions adoptent la même échelle.
  Deux scores internes (anxiété / humeur), un seul rapport à deux jauges.
- **J7 « Bilan autisme »** : RAADS-14 + CAT-Q = un seul test, mais leurs
  échelles diffèrent (4 choix vs 7 niveaux) → couture ASSUMÉE par un écran
  « Partie 2 — Comment tu t'adaptes aux autres », comme un vrai bilan.
  RAADS-14 toujours en premier (il porte le seuil).
- **Deux cadrages, une différence unique** : quand un résultat est affiché
  (J1, J3, J6, J7) → test fluide, questions bonus invisibles dans le flux ;
  quand aucun score n'existe encore (J2, J4, J5) → cadrage « aide-nous à
  construire », car on ne fait pas attendre un résultat qu'on n'a pas.

### Ordre interne d'une journée

1. Révélation (sauf J1 : l'auto-estimation du QI passe **avant** toute
   révélation, sinon elle est ancrée)
2. Jeu s'il y en a un
3. **Instrument validé — intact, en premier, dans son ordre d'origine, rien
   d'inséré entre ses items** (le seuil a été calibré ainsi)
4. Questions candidates (après le calcul du score, jamais avant)
5. J1 uniquement : bloc diagnostic, tout à la fin

Même échelle de réponse à l'intérieur d'un bloc ; quand l'échelle change
(RAADS 4 points → CAT-Q 7 points), un **écran de transition** l'annonce.

---

## 4. Les instruments annoncés — tous vérifiés, libres, commercialisables

| Instrument | Domaine | Items | Licence | Seuil | Obligation |
|---|---|---|---|---|---|
| **IPIP-50** | Personnalité (Big Five) | 50 | domaine public | percentiles | aucune |
| **GAD-7** | Anxiété | 7 | libéré par Pfizer | 5/10/15 | aucune |
| **PHQ-8** | Humeur | 8 | libéré par Pfizer | 5/10/15/20 | aucune — **jamais le PHQ-9** (item suicidaire) |
| **CBI** | Burnout | ~19 | domaine public | par sous-échelle | aucune |
| **RAADS-14** | Autisme | 14 | CC BY 2.0 | ≥ 14 | **citer** (Eriksson & Bejerot 2013, *Molecular Autism*) |
| **CAT-Q** | Camouflage autistique | 25 | CC BY 4.0 | ⚠️ à vérifier | **citer** (Hull et al. 2019) |

Sources primaires : items RAADS-14 dans le Tableau 2 de l'article (PMC3907126) ;
CAT-Q dans Hull et al. (PMC6394586) ; IPIP sur ipip.ori.org ; PHQ/GAD libérés
par Pfizer (2010).

---

## 5. Les échelles construites avec la communauté

**Méthode : keying empirique par critère** — celle qui a produit l'ASRS.
On pose des questions candidates à tout le monde, on identifie ensuite celles
qui séparent le mieux le groupe diagnostiqué du groupe témoin.

| Échelle | Candidates | Juge n°1 | Juge n°2 | Livrable |
|---|---|---|---|---|
| **TDAH** | 70 (45 + 25) + 15 contexte au J5 | diagnostic déclaré | **WMI mesuré** | dépistage |
| **Dyslexie** | 40 | diagnostic déclaré | **PSI mesuré** | dépistage |
| **Plaintes cognitives** | 30 | — | **WMI mesuré** ⭐ | profil + croisement |
| **Alexithymie** | 25 | — | IPIP | profil seulement |
| Autisme (affinage) | 10 | diagnostic déclaré | score RAADS-14 | affinage + recalibrage du seuil |

Règles de construction (les 5 conditions) :

1. **Critère dur** — groupe de référence = diagnostiqué par un spécialiste
   (idéalement traité). « Je pense en avoir un » = 3ᵉ catégorie, jamais
   mélangée. Refus de répondre = exclu de l'analyse.
2. **Biais d'auto-sélection assumé** — validité annoncée « sur notre
   population », jamais « en population générale ». Ne jamais estimer une
   prévalence avec ces données.
3. **Découpage 50/50** — moitié construction (choix des items), moitié
   validation (touchée UNE fois, à la fin). Sans ça, les chiffres sont fictifs.
4. **Volume** — ≥ 200-300 diagnostiqués par trouble avant de construire
   (plusieurs mois de collecte).
5. **Claims honnêtes** — « échelle développée sur N utilisateurs » ✅ ;
   « sensibilité 91 % » sans validation clinique ❌ ; « validé » avant
   publication ❌.

Bonus unique au produit : le RAADS-14 pourra être **recalibré sur notre
population** (seuil publié 14, seuil optimal chez nous peut-être différent —
sa spécificité tombe à 46 % chez les TDAH).

**Écarté : échelle HPI** — le QI est déjà mesuré par 13 sous-tests ; un
questionnaire qui devine ce qu'on mesure est absurde. Restes conservés :
1 question d'auto-estimation du QI (J1 → comparée au réel en J8) + case « HPI »
dans le bloc diagnostic (déclaré vs mesuré = donnée unique).

---

## 6. Le bloc diagnostic — spec

**Posé UNE SEULE FOIS, à la toute fin du J1.** Jamais reposé (agacement,
redondance), jamais en début de journée (amorçage des réponses). Posé au J1, il
ne peut plus contaminer le dépistage autisme du J7.

**Écran 1 — la liste** (cadrage : « ces réponses ne changent rien à tes
résultats ; elles servent à construire nos outils »)

> As-tu reçu un diagnostic — ou penses-tu être concerné — pour l'un de ces
> troubles ? *(coche tout ce qui s'applique)*
> ☐ TDAH · ☐ Autisme/TSA · ☐ Dyslexie · ☐ Dyspraxie · ☐ Dyscalculie ·
> ☐ HPI · ☐ Dépression · ☐ Trouble anxieux · ☐ Bipolarité · ☐ TOC ·
> ☐ Trouble du sommeil · ☐ Burn-out · ☐ Autre : ___
> ☐ **Aucun** · ☐ **Je préfère ne pas répondre**

**Écran 2 — le détail, seulement pour ce qui est coché**

> Diagnostiqué par… ○ psychiatre/neuropsychologue ○ médecin généraliste
> ○ psychologue ○ **je le pense, sans diagnostic**
> Année : ___ · Traitement : ○ oui ○ non ○ par le passé ·
> Bilan complet : ○ oui ○ non ○ je ne sais pas

**« Je préfère ne pas répondre » est une nécessité technique** : sans elle, les
gens qui ne veulent pas se déclarer cochent « non » et polluent silencieusement
le groupe témoin.

⚠️ C'est le bloc le plus sensible de l'app (données de santé, art. 9 RGPD) :
consentement explicite via le système versionné existant, finalité écrite
conforme à l'usage réel.

---

## 7. Les 5 jeux — aucun ne recoupe les 13 sous-tests (vérifié dans le code)

| Jeu | Mesure | Durée | Note d'implémentation |
|---|---|---|---|
| **Stroop** | inhibition | 2 min | score = **écart** conflit/neutre, jamais la vitesse brute (sinon recoupe le PSI) |
| **Tolérance au délai** | impulsivité de choix | 2 min | « 100 € maintenant ou 150 € dans un mois » |
| **Estimation du temps** | perception des durées | 2 min | totalement orthogonal à la batterie |
| **Calibration de la confiance** | métacognition | 3 min | quiz support = **estimations/perception**, jamais culture générale ni vocabulaire (recouperait Information/Vocabulaire) |
| **Biais cognitifs** | démonstration | 1 min/j | **aucun score** — ancrage, cadrage, disponibilité, confirmation… un par jour |

Écartés pour doublon avec la batterie : rotation mentale, N-back, Corsi,
matrices. Écartés pour doublon entre eux / avec le PSI : Go/No-Go, alternance de
tâches, attention soutenue.

Ce sont des paradigmes de recherche ré-implémentés (libres), présentés comme
**jeux avec ton score** — jamais comme mesures cliniques, jamais de percentile
clinique.

---

## 8. Les croisements — le vrai produit

Aucune autre app ne peut afficher ces lignes (il faut mesure objective +
déclaratif sur la même personne) :

| Croisement | Ce qu'il révèle | Jour |
|---|---|---|
| RAADS bas **+** CAT-Q élevé | le profil qui passe entre les mailles (camouflage) | J7 |
| Névrosisme bas **+** GAD-7 élevé | « ce n'est pas ton état habituel » | J3 |
| Plaintes mémoire **+** WMI mesuré haut | la plainte ne vient pas de la cognition | J3 |
| Plaintes faibles **+** WMI mesuré bas | faible conscience des difficultés | J3 |
| QI élevé **+** dépistage TDAH positif | la compensation | J4/J8 |
| Confiance élevée **+** justesse basse | surestimation de soi | J6 |
| QI auto-estimé **vs** QI mesuré | « comme 7 sur 10, tu t'es surestimé » | J8 |
| HPI déclaré **vs** QI mesuré | donnée que personne n'a | interne |

---

## 9. Affichage des résultats — règles de formulation

1. **Score + seuil, jamais de pourcentage inventé.**
   ✅ « Tu coches 5 items sur 6. Le seuil est de 4. » ❌ « 78 % de chances
   d'avoir un TDAH. »
2. **Jamais « diagnostic ».** Toujours : « ce n'est pas un diagnostic — seul un
   professionnel peut en poser un » + orientation.
3. **Un négatif n'est pas un « rien ».** Caveat obligatoire : un dépistage
   laisse passer des cas ; « si tu te reconnais malgré tout, un négatif ne doit
   pas t'arrêter ».
4. **Faux positifs nommés** : manque de sommeil, stress, anxiété, burnout
   produisent les mêmes réponses.
5. **Avertissement croisé RAADS-14** : chez les personnes TDAH, plus d'une sur
   deux sans autisme ressort positive (spécificité 46 %) — phrase dédiée si
   TDAH déclaré ou dépisté.
6. **Vocabulaire** : « score », « classement », « signaux » — jamais clinique,
   jamais de référence à une échelle standardisée dans le flux.
7. **Page Méthodologie** séparée (lien discret en bas des rapports) : sources,
   citations obligatoires (RAADS-14, CAT-Q), et l'explication « pourquoi si
   court » (les items ont été sélectionnés statistiquement — un dépistage court
   est un dépistage trié).
8. **Cadrage contribution** : « ces questions ne calculent aucun score pour
   toi ; elles servent à construire l'outil pour les suivants ».
9. Résultat positif fréquent = **normal** sur une population auto-sélectionnée :
   formuler comme une invitation, pas une révélation.

---

## 10. Écarté définitivement (ne pas y revenir)

| Idée | Pourquoi c'est mort |
|---|---|
| Fausses questions cachées « pour ne pas éveiller les soupçons » | effet de contexte (casse les seuils) + finalité RGPD + données invendables. Remplacé par la contribution transparente. |
| Pourcentage de probabilité diagnostique | nombre inventé (il faudrait prévalence + sensibilité/spécificité locales) |
| Reformuler les items d'un instrument validé | casse le barème silencieusement + œuvre dérivée |
| PHQ-9 | item suicidaire sans dispositif d'orientation |
| PCL-5, bipolarité, TCA, addictions | libres mais hors registre, potentiellement nuisibles ici |
| Échelle HPI | le QI est mesuré — voir §5 |
| Jeux doublons (rotation, N-back, Corsi, matrices, Go/No-Go…) | recoupent la batterie ou se recoupent entre eux |
| AQ-10/50, TAS-20, Epworth, Kit ETS, MBI, BDI-II, EQ/RMET, DIVA, CAARS | payants ou cliniciens uniquement |
| Récompenser le remplissage d'un questionnaire de santé | incite à sur-déclarer → données mortes |
| Paiement pendant les 8 jours | décision utilisateur — modèle éco séparé |
| Blind tokens pour le paiement | inutile tant que tout est clé par `account` |

---

## 11. En attente / à vérifier

**Trois mails à envoyer (non bloquants — on lance sans eux) :**

| Destinataire | Objet | Si oui |
|---|---|---|
| Pr Kessler (Harvard) | ASRS v1.1 — reproduction + traductions officielles 6 langues | journée TDAH **annoncée** (en plus de l'échelle maison) |
| British Dyslexia Association | Vinegrad — usage commercial | renfort de la journée dyslexie |
| Pr MacCann (Sydney) | STEU-B / STEM-B — usage commercial + traductions | journée « intelligence émotionnelle » en performance (extension possible) |

**Vérifications avant codage :**

- [ ] Seuil et cotation exacts du **CAT-Q** (article Hull et al.)
- [ ] RAADS-14 : item n°6 inversé (confirmé) + traductions par langue — CC BY
      autorise la traduction (en signalant la modification), mais les seuils ont
      été validés en langue d'origine → mention honnête en page méthodologie
- [ ] Items et cotation exacts du **CBI** (3 sous-échelles)
- [ ] Normes IPIP au lancement (normes publiées, puis normes maison avec le volume)
- [ ] Rattrapage des jours manqués : ouvert ou perdu ? (recommandation : ouvert)
- [ ] Notifications locales quotidiennes (compatibles anonymat) : oui/non

---

## 12. Pont avec l'implémentation existante

- Le **jour courant** se dérive de `stage3StartedAt` — le worker doit le
  renvoyer (autorité serveur, comme `secondsRemaining`) ; jamais dérivé de
  l'horloge locale.
- Le stockage des réponses (questionnaires + candidates + bloc diagnostic) est
  **à concevoir** : partition par `account`, consentement art. 9 avant tout
  questionnaire de santé, architecture d'anonymat existante à respecter.
- 6 langues obligatoires pour tout contenu affiché (fr, en, en_GB, de, es, pt).
- Les jeux tournent en local ; seuls des agrégats montent au serveur.

---

## 13. Backlog de production (ordre recommandé)

1. **Bloc diagnostic** — 6 langues (conditionne toutes les échelles)
2. **Extraction RAADS-14 + CAT-Q** — items, échelles, cotation, citations
3. **70 candidates TDAH** (priorité n°1 de construction)
4. **40 dyslexie · 30 plaintes cognitives · 25 alexithymie · 10 autisme**
5. **Rapport J7** (vitrine : deux scores + croisement camouflage)
6. **Rapports J1/J3/J6** + page Méthodologie
7. **Specs des 5 jeux** (écrans, consignes, scores)
8. **Rapport J8** (QI + vs auto-estimation — le moment de conversion)
9. **Infra** : jour courant serveur, stockage réponses, l10n, écrans
