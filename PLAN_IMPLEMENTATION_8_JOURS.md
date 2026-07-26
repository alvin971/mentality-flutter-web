# PLAN D'IMPLÉMENTATION — Événement d'attente des 8 jours

> **Compagnon de [PLAN_8_JOURS.md](PLAN_8_JOURS.md)** (le QUOI). Ce document est
> le COMMENT : arborescence, lots, critères d'acceptation, gardes automatiques.
> **Branche : `claude/rgpd-data-traceability-5f5372`** (le même worktree).
> Chaque lot = un commit vérifiable seul. Supervision possible lot par lot ou
> en séquence.

---

## 0. Décisions d'architecture

### 0.1 Nouveau dossier feature — `lib/features/waiting_event/`

**PAS dans `exercises_implementations/`** (réservé aux sous-tests de la
batterie), mais dans le même style : un sous-dossier par module, chacun avec
`domain/ · data/ · presentation/` selon besoin.

```
lib/features/waiting_event/
├── _shared/                     ← moteur commun (comme exercises_implementations/_shared)
│   ├── domain/
│   │   ├── models/              QItem, QScale, QInstrument, QModule, DayStatus, QAnswerSet
│   │   ├── services/            event_schedule.dart (jour → modules), day_gate.dart
│   │   └── scoring/             scorers par instrument (somme, seuils, sous-échelles, items inversés)
│   ├── data/
│   │   ├── question_bank/       items × 6 langues, un fichier par instrument
│   │   ├── event_local_store.dart      réponses chiffrées Hive (cipher partagé existant), reprise
│   │   └── event_upload_service.dart   envoi worker + REJEU (patron CompletionReporter — jamais tire-et-oublie)
│   └── presentation/
│       ├── questionnaire_runner_page.dart   moteur générique : 1 question/écran, progression, reprise
│       └── widgets/             échelles de réponse, écran « Partie 2 », transition
├── day_hub/                     page « Jour N » : révélation + activités + jours passés (rattrapage OUVERT)
├── reveals/                     les 7 révélations (lisent SessionHistoryEntry : fsiq/vci/vsi/fri/wmi/psi)
├── diagnostic_block/            fin J1 — écran liste + écrans détail (spec PLAN_8_JOURS §6)
├── personality/                 J1 — IPIP-50 (annoncé, 50 q)
├── wellbeing/                   J3 — GAD-7 + PHQ-8 + 30 plaintes cognitives (annoncé, 45 q)
├── energy/                      J6 — CBI + 25 alexithymie (annoncé, ~44 q)
├── autism/                      J7 — RAADS-14 + Partie 2 CAT-Q + 10 (annoncé, 49 q)
├── reading_build/               J2 — 40 candidates dyslexie (contribution)
├── attention_build/             J4+J5 — TDAH 45 puis 25+15 contexte (contribution)
├── stroop/                      jeu — score en ÉCART conflit/neutre
├── delay_choice/                jeu — tolérance au délai
├── time_estimation/             jeu — estimation du temps
├── confidence_calibration/      jeu — quiz = ESTIMATIONS (jamais culture G/vocabulaire)
├── daily_bias/                  1 biais/jour, sans score, rejouable
└── reports/                     rapports J1/J3/J6/J7/J8 + page Méthodologie
```

Pourquoi ce découpage : chaque module est **enfichable et supervisable seul**
(un descriptor `QModule` enregistré dans `event_schedule.dart`), le moteur est
écrit une fois, et le contenu (items, traductions) vit en `data/` séparé du code.

### 0.2 Serveur — deux chantiers distincts

1. **`workers/referral/index.js`** : ajouter `dayIndex` (1..8, ≥9 = débloqué)
   à `buildProgressResponse()`, dérivé de `stage3StartedAt` — même autorité
   serveur que `secondsRemaining`. Le client n'infère JAMAIS le jour de son
   horloge murale (il combine `dayIndex` reçu + ancrage monotone existant).
2. **`workers/event/` (nouveau worker)** : `POST /responses` — token auth via
   `_shared/token_verify.js`, écrit un JSON en **R2 UE** : clé `uuid` (jamais
   un timestamp), metadata **date seule**, partition par `account`. Miroir des
   conventions anti-ré-identification de `workers/r2-upload/`. Pas de lecture
   client. Consentement art. 9 exigé côté client AVANT tout envoi.

### 0.3 Règles transverses (héritées du dépôt)

- `theme_discipline_test` scanne `lib/features/**` → tout en
  `AppText.of(context)` / `KeplerColors.of(context)`. **Pas d'exemption** pour
  waiting_event (c'est de l'UI normale).
- Le Stroop a besoin de couleurs FIXES (rouge/vert/bleu = matériel du test) →
  poser le stimulus sur **`KeplerStimulusSurface`** (luminance fixe), aucune
  exemption nécessaire.
- **6 langues** pour tout contenu affiché. Les items vivent dans
  `question_bank/` (pas dans les ARB — trop volumineux) avec leur propre
  garde de parité ; le chrome (boutons, titres) va dans les ARB.
- Aucun `CircularProgressIndicator` pendant l'attente ; jamais de déblocage
  conditionné à une activité.
- Consentement : nouvelle finalité « construction/amélioration de nos échelles »
  dans `lib/core/consent/consent_service.dart` (versionné). Sans consentement :
  questionnaires jouables + score affiché, mais **rien n'est envoyé**.

---

## 1. Les lots

> Chaque lot : commit séparé · `flutter analyze` 0 erreur · suite verte ·
> critères d'acceptation listés. Ordre = dépendances réelles.

### LOT A — Serveur : `dayIndex` (petit, fondateur)
- `buildProgressResponse()` : `dayIndex = clamp(1..9, floor((now − stage3StartedAt)/86400) + 1)` ; `null` tant que stage < 3.
- `UnlockProgress` : champ `dayIndex` (défaut null — tolérance vieux worker).
- Tests : réplique Dart (unlock_stage_machine_test) + `selftest.mjs` étendu ;
  cas : J1 à h+0, J2 à h+24, J8 à h+168, ≥9 après déblocage, horloge client
  manipulée → dayIndex inchangé.
- ✅ Acceptation : `node workers/referral/scripts/selftest.mjs` vert.

### LOT B — Squelette + hub du jour
- Arborescence `waiting_event/` + modèles `_shared/domain/models/`.
- `event_schedule.dart` : table jour → [révélation, modules] (données du
  tableau maître PLAN_8_JOURS §3).
- `day_hub/` : page « Jour N » — révélation du jour, cartes activités,
  jours passés accessibles (rattrapage ouvert), jours futurs verrouillés
  (affichent le décompte existant).
- Intégration : la carte d'attente de `unlock_gate_page.dart` (palier 3)
  gagne un bouton « Voir le programme du jour » → day_hub.
- Tests : réplique pure des conditions d'affichage (style unlock_gate_steps) ;
  jour courant = TOUJOURS le `dayIndex` serveur, jamais l'horloge locale.
- ✅ Acceptation : hub navigable avec contenus placeholder, gate intact.

### LOT C — Moteur de questionnaire générique
- `questionnaire_runner_page.dart` : 1 question/écran, barre de progression,
  échelles de réponse configurables, écran « Partie 2 » quand l'échelle change,
  reprise après fermeture (event_local_store), aucune question sautable
  silencieusement (mais abandon possible — les données partielles sont
  marquées telles quelles).
- `event_local_store.dart` : chiffré (cipher partagé DataCollectionService),
  cloisonné par account (patron auth_local_store).
- Tests : runner widget-test avec un instrument factice ; reprise ; ordre des
  items préservé.
- ✅ Acceptation : un questionnaire factice de 45 q se passe de bout en bout.

### LOT D — Révélations (J1→J8)
- `reveals/` : 7 écrans, données depuis `SessionHistoryEntry`
  (fsiq/vci/vsi/fri/wmi/psi/classification suffisent ; forces & faiblesses =
  comparaison des 5 indices).
- J1 inclut l'auto-estimation du QI (1 q, AVANT toute révélation, stockée) ;
  J8 la compare au réel.
- Textes explicatifs 6 langues (ARB — c'est du chrome).
- ✅ Acceptation : chaque révélation rend avec des données réelles d'historique.

### LOT E — Instruments annoncés (4 modules)
Ordre interne obligatoire : instrument validé INTACT en premier, nos questions
après, score calculé sur le sous-ensemble validé uniquement.
- E1 `personality/` : IPIP-50 (+ scorer 5 traits, percentiles normes publiées).
- E2 `wellbeing/` : GAD-7 + PHQ-8 (même échelle 4 niveaux/2 semaines) + 30
  plaintes cognitives sur la MÊME échelle. Deux scores, un rapport.
- E3 `energy/` : CBI (3 sous-échelles) + 25 alexithymie.
- E4 `autism/` : RAADS-14 (item 6 inversé) + écran Partie 2 + CAT-Q + 10.
- **Bloquants contenu** (avant de coder E3/E4) : cotation exacte CAT-Q, items
  exacts CBI, traductions RAADS/CAT-Q (CC BY autorise la traduction en la
  signalant ; mention honnête en page Méthodologie).
- ✅ Acceptation : scorers en golden-value tests (cas calculés à la main).

### LOT F — Bloc diagnostic (fin J1)
- Spec PLAN_8_JOURS §6 : liste + détails, « je préfère ne pas répondre »,
  « je le pense sans diagnostic » = catégorie séparée. Stocké UNE fois.
- Gate consentement art. 9 AVANT l'écran.
- ✅ Acceptation : posé une seule fois, jamais reproposé, exporté avec les réponses.

### LOT G — Modules contribution (J2, J4, J5)
- `reading_build/` (40) + `attention_build/` (45 puis 25+15 contexte).
- Cadrage « aide-nous à construire » (pas de score affiché — écran de fin
  de remerciement).
- **Bloquant contenu** : rédaction des candidates (voir §2).
- ✅ Acceptation : garde 40-50 verte (voir §3), aucun score affiché.

### LOT H — Jeux (5 commits indépendants)
- H1 Stroop (KeplerStimulusSurface, score = écart) · H2 délai · H3 estimation
  du temps · H4 calibration (quiz d'estimations) · H5 biais quotidien.
- Local uniquement ; agrégats seuls envoyés (LOT J).
- ✅ Acceptation : rejouables, records locaux, zéro recoupement batterie.

### LOT I — Rapports + page Méthodologie
- Rapports J1/J3/J6/J7 avec les croisements (PLAN_8_JOURS §8) et les règles de
  formulation (§9 : score+seuil, jamais « diagnostic », caveat négatif, faux
  positifs, avertissement croisé TDAH↔RAADS).
- Page Méthodologie : sources, citations CC BY obligatoires, « pourquoi si
  court », composition des tests.
- Rapport J8 : QI + vs auto-estimation + carte de partage (déjà codée).
- ✅ Acceptation : relecture contre la checklist §9 du plan produit.

### LOT J — Worker event + envoi/rejeu
- `workers/event/` (spec §0.2) + `event_upload_service.dart` : persistance
  locale puis REJEU jusqu'à confirmation (patron CompletionReporter — leçon du
  gotcha parrainage), issues distinguées confirmé/refusé/injoignable.
- Consentement vérifié avant chaque envoi.
- ✅ Acceptation : selftest node du worker (patron selftest.mjs) + test de rejeu.

### Ordre & dépendances

```
A ─→ B ─→ C ─→ E1 → E2 → E3 → E4 → I
     │    ├──→ F (après E1 — fin J1)
     │    └──→ G (quand contenu prêt)
     ├──→ D (parallèle à C)
     └──→ H1..H5 (indépendants)
C ─→ J (parallèle à E)
```

Livraison incrémentale possible : A+B+C+D+E1 = un J1 complet en production,
le reste s'active jour par jour.

---

## 2. Livrables CONTENU (hors code — à produire en parallèle)

| Contenu | Volume | Bloque |
|---|---|---|
| Bloc diagnostic — libellés 6 langues | ~15 écrans | LOT F |
| Items RAADS-14 + CAT-Q extraits + cotations + citations | 39 items × 6 l. | LOT E4 |
| Items CBI + IPIP-50 + GAD-7 + PHQ-8 × 6 langues | ~84 items | LOT E |
| 30 plaintes cognitives | rédaction | LOT E2 |
| 40 candidates dyslexie · 45+25 TDAH · 15 contexte · 25 alexithymie · 10 autisme | rédaction | LOT G |
| Textes des 7 révélations + 5 rapports + Méthodologie | rédaction 6 l. | LOTS D, I |
| Banque de biais cognitifs (≥ 15 pour tenir des semaines) | rédaction | LOT H5 |

Règle de rédaction des candidates : échelle de fréquence homogène, ancrage
« ces 6 derniers mois », pas de question double, pas de double négation.

---

## 3. Gardes automatiques (tests qui encodent les règles du plan)

À créer dans `test/features/waiting_event/` :

1. **Garde 40-50** : chaque module questionnaire a 40 ≤ items ≤ 50 (IPIP-50 = 50 ✓).
2. **Garde d'intégrité des instruments** : les items validés sont premiers,
   dans l'ordre canonique, texte conforme à la banque de référence (checksum) —
   une reformulation accidentelle casse le test.
3. **Garde de parité 6 langues** : chaque QItem a ses 6 locales.
4. **Garde d'échelle homogène** : un bloc = une échelle (sauf transition déclarée).
5. **Garde d'autorité serveur** : le jour courant vient de `dayIndex`, réplique
   pure « horloge manipulée → jour inchangé ».
6. **Garde de non-gamification** : aucun module santé référencé par la logique
   de déblocage.
7. Golden-values par scorer (seuils : GAD-7 5/10/15, PHQ-8, RAADS ≥14,
   CBI sous-échelles, IPIP percentiles).

---

## 4. Décisions restantes (à trancher avant les lots concernés)

- [ ] Nom définitif du dossier (`waiting_event` proposé) — LOT B
- [ ] Rattrapage des jours manqués : OUVERT (recommandé) — LOT B
- [ ] Worker event : nouveau worker (recommandé) vs extension r2-upload — LOT J
- [ ] Notifications locales quotidiennes (compatibles anonymat) : hors périmètre v1 ?
- [ ] Traductions RAADS-14/CAT-Q : traduire nous-mêmes (CC BY ok, à signaler)
      vs chercher des versions publiées — LOT E4
- [ ] Les 3 mails (Kessler/BDA/MacCann) — indépendants, à envoyer quand tu veux

---

## 5. Definition of done globale

- `flutter analyze` : 0 erreur · suite complète verte (426 tests baseline + nouveaux)
- `node workers/referral/scripts/selftest.mjs` vert · selftest du worker event vert
- Parité 6 langues (garde n°3) · gardes §3 toutes vertes
- Aucune donnée santé envoyée sans consentement art. 9 · aucune activité requise
  pour débloquer · worker déployé sondé avant/après (leçon des divergences passées)
