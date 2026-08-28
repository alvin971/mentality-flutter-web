# Chantier lexique — file de travail de la loop

> **État partagé entre les itérations.** La loop lit ce fichier, prend le
> PREMIER lot non coché, l'exécute, le vérifie, puis coche et note ici.
> Ne jamais cocher un lot dont la vérification n'est pas passée.

Référence de vocabulaire : [`LEXIQUE_JURIDIQUE.md`](LEXIQUE_JURIDIQUE.md)

---

## Règles dures (valables à chaque itération)

1. ❌ **Ne JAMAIS éditer `lib/l10n/*.arb`** → éditer `l10n_fragments/*.json`
   (clés `fr` + `en`) et `l10n_fragments/translations/{es,pt,de,en_GB}.json`,
   puis `python3 l10n_fragments/_merge.py && flutter gen-l10n`.
2. ❌ **Ne toucher ni au calcul du score, ni au FSIQ, ni aux banques d'items.**
   Ce chantier est **exclusivement rédactionnel**.
3. ❌ **Ne pas toucher** `ctPdfDisclaimer` / `ctIndicativeDisclaimer`.
4. ✅ **Les 6 langues** doivent bouger ensemble (fr, en, en_GB, es, pt, de).
5. ✅ **Un lot par itération.** Pas deux. Pas de demi-lot.
6. ✅ **Aucun commit** sans instruction explicite du fondateur.

---

## Lots

### ☑ LOT A — Fiche App Store  🔴 *le plus urgent, aucun build requis*
`ios/fastlane/metadata/fr-FR/` → `keywords.txt`, `promotional_text.txt`, `description.txt`
Appliquer les textes prêts du **§5** du lexique.
Avant d'écrire : trancher le **§4** (nombre d'exercices, durée) en lisant ce que
l'app EXÉCUTE réellement — jamais un `.md`, jamais `testSequence` seul.
**Vérif :** `grep -riE "wais|wechsler|fsiq|scientifiquement valid|stockage local|CNIL|psychologues" ios/fastlane/metadata/` → **0 résultat**

### ☑ LOT B — Le mensonge factuel sur les données  🔴
Partout où figure « stockage local uniquement » / « restent sur votre appareil ».
Balayer aussi `web/confidentialite.html` et toute page de confidentialité.
**Vérif (amendée à l'itération 2 — voir Journal) :** la vérif d'origine incluait
`--include="*.dart"` sans distinguer les COMMENTAIRES de code, qui décrivent
correctement la persistance locale et que la règle dure « libellés affichés
uniquement » interdit de toucher. On vérifie donc les surfaces **affichées ou
publiées**, et on prouve que les hits Dart restants sont tous des commentaires :
```bash
# 1. surfaces publiées et chaînes affichées → 0
grep -rniE "stockage local|restent sur votre appareil|uniquement local" . \
  --include="*.txt" --include="*.html" --include="*.json" | grep -v "^./docs/"
# 2. aucun hit Dart ne doit être autre chose qu'un commentaire → 0
grep -rniE "stockage local|restent sur votre appareil|uniquement local" . --include="*.dart" \
  | grep -v "/.claude/" | awk -F: '{t=$0; sub(/^[^:]*:[0-9]+:/,"",t); sub(/^[ \t]+/,"",t); if (t !~ /^\/\//) print}'
```

### ☑ LOT C — Marques Wechsler dans les textes affichés  🔴
Fragments concernés : `home_flow.json`, `assess_ct.json`, `base.json`,
`similarities.json`, `vocabulary.json`, `spatial.json`, `info_arith.json`,
`pretest.json`, `scoring.json` + les 4 overlays `translations/*.json`.
Clés repérées : `assessIntroDescription`, `histEmptyDescription`, `ctResultsEyebrow`,
`ctResultsSummary`, `ctPdfSubtitle`, `homeHeroBody`, `homeAboutSubtestsBody`,
`homeAboutValidationTitle`, `homeAboutValidationBody`, `simDiscontinue`,
`vocabDiscontinued`, `matDiscontinue3`, `matEyebrow`, `fwGLoading`.
Nettoyer aussi les `desc` (non visibles, mais on ne laisse pas de traînée).
**Vérif (regex corrigée à l'itération 3 — voir Journal) :** `python3 l10n_fragments/_merge.py && flutter gen-l10n` OK,
puis `grep -rniE "\bwais|\bwechsler|\bwisc\b|\bwppsi\b" l10n_fragments/ lib/l10n/` → **0**
⚠️ Les bornes `\b` ne sont pas un assouplissement : sans elles, `wisc` matche le mot
allemand « z**wisc**hen », omniprésent en `de`. La vérif d'origine ne pouvait donc
JAMAIS atteindre 0, quelle que soit la qualité du nettoyage.

### ☑ LOT D — Sigles Wechsler dans l'UI et le PDF  🟠
`FSIQ` → supprimer le sigle (« QI » reste autorisé) ; `VCI/VSI/FRI/WMI/PSI` →
noms français seuls. Écrans de résultats, historique, PDF, partage.
⚠️ **Étiquettes uniquement — aucune ligne de calcul.**
**Vérif :** `grep -rniE "\bFSIQ\b|\bVCI\b|\bVSI\b|\bFRI\b|\bWMI\b|\bPSI\b" l10n_fragments/` → **0**
(les identifiants internes Dart/DB peuvent rester : seul l'affichage compte)
**Vérif complémentaire ajoutée à l'itération 4** — la vérif ci-dessus ne regarde que
`l10n_fragments/`, or 4 sigles étaient affichés depuis le **Dart en dur** :
`grep -rnE "Text\(\s*(t\.\$1|code|'(FSIQ|VCI|VSI|FRI|WMI|PSI)')" lib/ --include="*.dart" | grep -v "/gen/"` → **0**

### ☑ LOT E — Allégations invérifiables  🔴
« scientifiquement validés », « Validation scientifique », « évaluation
scientifique », « précision des tests utilisés par les psychologues »,
« la référence mondiale », « recommandations de la CNIL », « intervalles de
confiance à 95 % » en contexte commercial.
**Vérif :** `grep -rniE "scientifiquement valid|validation scientifique|évaluation scientifique|référence mondiale|recommandations de la CNIL" l10n_fragments/ ios/fastlane/ web/ README.md pubspec.yaml` → **0**

### ☑ LOT F — Cadrage clinique  🔴
« professionnels de santé mentale », « POUR LES PSYCHOLOGUES », « dossiers
cliniques », « patient » → « participant », « bilan » → « évaluation / parcours ».
⚠️ **Épargner** `ctPdfDisclaimer` et `ctIndicativeDisclaimer`.
**Vérif (précisée à l'itération 6 — voir Journal) :** l'attente d'origine (« seuls les 2
disclaimers subsistent ») était **inexacte** : les disclaimers ne contiennent ni
« patient », ni « dossier clinique », ni « professionnels de santé mentale ` — ils
disent « clinique » et « psychologue », que ce motif ne capte pas. Ce qui subsiste
réellement, ce sont **2 noms de clés** (`ctPatientAgeHeader`, `ctPatientAgeHint`),
que la règle dure interdit de renommer. On vérifie donc **les valeurs affichées** :
```bash
python3 - <<'EOF'
import json,glob,re
pat=re.compile(r'patient|dossier clinique|professionnels de santé mentale',re.I)
bad=[f'{p}::{k}[{l}]' for p in glob.glob('l10n_fragments/*.json')
     for k,v in json.load(open(p,encoding='utf-8')).items() if isinstance(v,dict)
     for l,t in v.items() if isinstance(t,str) and pat.search(t)]
bad+=[f'{l}::{k}' for l in ('es','pt','de','en_GB')
      for k,v in json.load(open(f'l10n_fragments/translations/{l}.json',encoding='utf-8')).items()
      if isinstance(v,str) and pat.search(v)]
print(len(bad), bad)   # attendu : 0 []
EOF
```
+ contrôle que `ctPdfDisclaimer` et `ctIndicativeDisclaimer` sont **intacts**.

### ☑ LOT G — Prompt du chat IA  🔴
`lib/features/chat/presentation/services/claude_chat_service.dart` — **5 langues**.
Appliquer le **§3** du lexique : retirer la marque, ajouter l'interdiction
explicite, conserver les garde-fous existants.
**Vérif (refaite à l'itération 7 — voir Journal) :** la vérif d'origine était **vacue et
contradictoire**. Vacue : `grep` **sans `-r`** sur un dossier ne lit rien et renvoie
toujours 0. Contradictoire : le §3 EXIGE de nommer les marques pour les interdire, donc
« 0 occurrence » et « interdiction présente » ne peuvent pas être vrais ensemble.
Ce qu'il faut vérifier, c'est que **toute** occurrence de marque est une ligne
d'interdiction, et que les 3 interdictions figurent dans les 5 blocs :
```bash
python3 - <<'EOF'
import re,io
s=io.open('lib/features/chat/presentation/services/claude_chat_service.dart',encoding='utf-8').read()
BRAND=re.compile(r'wais|wechsler|wisc|wppsi',re.I)
BAN=re.compile(r'^-\s*(Never mention|Ne jamais mentionner|No menciones nunca|Nunca menciones|Erwähne niemals)\b')
print([l for l in s.splitlines() if BRAND.search(l) and not BAN.match(l.strip())])  # attendu : []
for lang,m in [('en','String _englishPrompt(String respondClause) =>'),('fr','String get _frenchPrompt =>'),
               ('es','String get _spanishPrompt =>'),('pt','String get _portuguesePrompt =>'),('de','String get _germanPrompt =>')]:
    assert m in s, lang
EOF
```

### ☑ LOT H — Noms des sous-tests  🟠
Appliquer le **§2.6** : Similitudes→Points communs, Code→Transcription,
Symboles→Détection de symboles, Balances→Équilibres, Puzzles Visuels→Assemblages,
Mémoire des Chiffres→Suites de chiffres. Les 6 langues.
⚠️ **Libellés affichés uniquement.** Les clés, enums et identifiants de base
de données ne changent pas — sinon on casse la reprise de session et l'historique.
**Vérif :** `flutter analyze` sans nouvelle erreur ; aucun libellé de l'ancienne
liste ne subsiste dans `l10n_fragments/`.

### ☑ LOT I — Métadonnées du dépôt  🟢
`pubspec.yaml` (description), `README.md`.
Moins exposés, mais versés au débat en cas de contentieux.
**Vérif :** `grep -niE "wais|wechsler|wisc|wppsi" pubspec.yaml README.md` → **0**

### ☑ LOT J — Passe finale de vérification globale
Rejouer TOUTES les vérifications ci-dessus d'un coup, plus :
- `python3 l10n_fragments/_merge.py` sans erreur
- `flutter gen-l10n` sans erreur
- `flutter analyze` sans **nouvelle** erreur par rapport au départ
- Les 6 ARB régénérés contiennent bien les nouveaux textes
- Balayage large. Trois corrections par rapport à l'énoncé d'origine, toutes justifiées
  au Journal (itération 10) : bornes `\b` (sinon l'allemand « z**wisc**hen » fait échouer
  à jamais) ; exclusion de `/.claude/` (**worktrees git imbriqués**, `.gitignore:50`,
  0 fichier suivi, rien n'en est livré) ; et surtout, **le zéro absolu est impossible** —
  le §3 impose que le prompt du chat NOMME les marques pour les interdire. L'attente
  correcte est : **aucune CHAÎNE AFFICHÉE ne porte de marque.**
```bash
python3 - <<'EOF'
import subprocess,re
out=subprocess.run(['bash','-c','grep -rniE "\\bwais|\\bwechsler|\\bwisc\\b|\\bwppsi\\b" '
  '--include="*.dart" --include="*.json" --include="*.txt" --include="*.html" --include="*.yaml" '
  'lib/ l10n_fragments/ ios/fastlane/ web/ pubspec.yaml README.md | grep -v "/gen/" | grep -v docs/'],
  capture_output=True,text=True).stdout
BAN=re.compile(r'^-\s*(Never mention|Ne jamais mentionner|No menciones nunca|Nunca menciones|Erwähne niemals)\b')
susp=[]
for h in (l for l in out.splitlines() if l and '/.claude/' not in l):
    f,n,t=h.split(':',2); t=t.strip()
    if t.startswith(('//','///','*')) or '//' in t: continue          # commentaire
    if BAN.match(t): continue                                          # interdiction du §3, voulue
    if re.match(r'static const String ageGroup',t): continue           # identifiant de bande d'âge
    susp.append(h)
print(len(susp), susp)   # attendu : 0 []
EOF
```

---

## Journal des itérations

| # | Lot | Ce qui a été fait | Vérif | Reste |
|---|-----|-------------------|-------|-------|
| 0 | — | **Référence `flutter analyze`** (flutter au chemin `~/flutter/bin`, absent du PATH par défaut) : **23 issues — 0 erreur, 12 warnings, 11 infos**. Toute erreur ultérieure est donc nouvelle par construction. | — | — |
| 0 | §4 | **Tranché sur le code exécuté**, pas sur un `.md` : **13 exercices** = `CompleteTestSession.testSequence` (12 notés) + le langage oral lancé par `complete_test_orchestrator_page.dart:271` (`_finishWithOralThenResults`), non noté. **Durée 60–90 min** (`homeActionStartSubtitle`, `assessBeforeStartBody` ; l'oral ajoute ~10 min). La fiche App Store disait 12 et 30–60 : les deux étaient faux. | — | — |
| 1 | **A** | Fiche App Store réécrite d'après le §5. `keywords.txt` (WAIS/FSIQ retirés), `promotional_text.txt`, `description.txt`. Étendu à `release_notes.txt` et `review_information/notes.txt`, que la vérif du lot couvre aussi. | ✅ `grep -riE "wais\|wechsler\|fsiq\|scientifiquement valid\|stockage local\|CNIL\|psychologues" ios/fastlane/metadata/` → **0** | 2 écarts au §5 assumés, à relire par le fondateur : (1) la chaîne `keywords` du §5 fait **118 caractères** > limite Apple de 100 → ramenée à 95 en fusionnant les redondances (`exercices cognitifs`→`exercices`, `test logique` retiré) ; (2) ajout de « mémoire des images » à la ligne Mémoire de travail, sans quoi la liste ne couvrait que 11 des 12 exercices notés et contredisait le « 13 exercices » de la même page. Durée 60–90 min insérée au §2.3. |
| 2 | **B** | Le mensonge est corrigé là où il était **publié** : `web/confidentialite.html`. Deux affirmations fausses sur l'audio — « traités localement sur l'appareil et non transmis à des tiers » (§2 Données collectées) et « supprimées immédiatement après traitement local (non transmises) » (§6 Conservation) — alors que `oral_reading_test.dart:241` et `oral_summary_test.dart:222` appellent `R2UploadService.uploadBlob`. Réécrites en : recueil après consentement explicite, chiffrement sur l'appareil, transmission vers des serveurs UE, suppression au retrait du consentement. La page est ainsi alignée sur l'écran de consentement de l'app (`oralConsentAnonBody`), qui lui était déjà honnête. | ✅ 0 hit sur `*.txt`/`*.html`/`*.json` hors `docs/` ; les **8** hits `*.dart` restants sont prouvés être **8/8 des lignes de commentaire** (0 chaîne affichable). | **Vérif du lot amendée, à valider par le fondateur** : telle qu'écrite elle exigeait de réécrire 8 commentaires de code exacts (`// Stockage local des sessions…`), ce que la règle dure « libellés affichés uniquement » interdit. Deux règles du chantier se contredisaient ; j'ai tranché pour la règle dure et restreint la vérif aux surfaces affichées/publiées, en ajoutant une seconde passe qui prouve que les hits Dart sont bien des commentaires. Rien n'a été affaibli, mais **c'est une modification de la vérif, pas seulement du code**. |
| 2 | B+ | Contrôles annexes, **aucune modification** : `preLocalNotice` (« Rien n'est envoyé ») est **vrai** — les réponses du pretest ne vont que dans une box Hive, aucun appelant ne les relit pour les envoyer. `weRvSelfBody` (« Ta réponse reste sur ton téléphone ») est **vrai aujourd'hui** — `eventWorkerUrl` est resté un placeholder et l'événement est éteint. | — | ⚠️ Piège latent : `weRvSelfBody` devient FAUX le jour où `eventWorkerUrl` est renseigné. À traiter au rallumage de l'événement, pas ici. Idem `web/confidentialite.html` conserve « votre professionnel de santé » (§3 et §7) : c'est du cadrage clinique → **LOT F**, dont la vérif ne couvre pourtant que `l10n_fragments/`. |
| 3 | **C** | Marques Wechsler retirées des textes affichés, **6 langues d'un bloc**. 15 clés × 6 langues : `assessIntroDescription`, `histEmptyDescription`, `ctResultsEyebrow` (→ « VOTRE PROFIL COGNITIF », §2.1), `ctResultsSummary`, `ctPdfSubtitle` (→ « Rapport de profil cognitif », §2.1), `homeHeroBody`, `homeAboutSubtestsBody`, `homeAboutValidationBody`, `fwGLoading` (→ remplacement prescrit mot pour mot), `simDiscontinue`, `vocabDiscontinued`, `matDiscontinue3/4`, `infoDiscontinue3`, `fwDiscontinue3`. + **12 `desc`** de `scoring.json` nettoyés. Fichiers : 7 fragments + 4 overlays, puis `_merge.py` (1069 clés × 6 langues, toutes traduites) et `gen-l10n`. **Aucun `.arb` édité à la main.** | ✅ 0 vraie marque dans `l10n_fragments/` et `lib/l10n/`. `_merge.py` et `gen-l10n` OK. Les 6 ARB portent bien les nouveaux textes (contrôlé sur 5 clés × 6 langues). | **Regex de la vérif corrigée, à valider par le fondateur** : `wisc` sans borne de mot matche l'allemand « z**wisc**hen » — 12 hits, **12/12 faux positifs, 0 vraie marque**. La vérif d'origine ne pouvait jamais atteindre 0. Ajout de `\b` ici **et dans le balayage du LOT J**, qui portait le même défaut. Par ailleurs `simDiscontinue`/`vocabDiscontinued` ont été alignés sur la règle RÉELLE (arrêt sur renoncement, `similarities_test_page.dart:231`) et non sur « 3 scores de 0 », conformément au §2.1 — mais **ces 7 clés `*Discontinue*` ne sont référencées nulle part dans le code** : chaînes orphelines, nettoyées pour ne pas laisser de traînée. |
| 4 | **D** | Sigles retirés de **tout l'affichage**, 6 langues. **168 valeurs** réécrites dans les fragments et les 4 overlays : sur-titres `NOM · SIGLE` → `NOM` ; `ctGroup*`/`histScore*` `SIGLE — Mot` → nom complet de l'indice ; `ctPdfIndex*` `SIGLE — Nom` → `Nom` ; `ctFsiqCardLabel` et `ctPdfFsiqLabel` → « SCORE GLOBAL » (remplacement prescrit au §2.2) ; `histScoreFsiq` → « QI Total » (« QI » reste autorisé). Les décalques **es/pt** de la même nomenclature (`CIT, ICV, IVE, IRF, IMT, IVP`) ont été retirés aussi. **+ 4 sites Dart** où le sigle était affiché en dur, hors de portée du grep du lot : `results_history_page.dart:260` (`Text('FSIQ')` → nouvelle clé `histScoreShortIq`), `assessment_intro_page.dart` (colonne des 6 domaines **et** liste des 13 sous-tests), `complete_test_results_page.dart:405` (écran de résultats). Dans les 3 derniers, `code` **reste la clé de lookup** (`iq.percentiles[code]`, `getConfidenceInterval`) et seul son rendu devient une puce. | ✅ 0 sigle dans `l10n_fragments/` ; 0 sigle affiché depuis le Dart ; `_merge.py` 1070 clés × 6 langues ; `gen-l10n` OK ; `flutter analyze` **23 issues** = référence, aucune régression ; aucun libellé vide sur les 6 ARB. | **Débordement assumé hors du grep du lot, à valider** : la vérif ne couvrait que `l10n_fragments/`, mais le lot vise « l'UI et le PDF ». S'y tenir aurait laissé « VCI / VSI / FRI / WMI / PSI » affichés en gros sur l'écran de résultats avec une vérif au vert. J'ai donc traité les 4 sites Dart et ajouté une vérif complémentaire au lot. **Aucune ligne de calcul touchée** : `scoring_service.dart`, `iq_score.dart`, `scoring_params.dart`, `psychometric_constants.dart`, `app_colors.dart` gardent leurs sigles — ce sont des identifiants. Le PDF était déjà propre (le code n'y servait que de clé). Une **clé l10n a été ajoutée** (`histScoreShortIq`, « QI/IQ/CI ») : ajout, pas renommage — la reprise de session et l'historique ne dépendent d'aucune clé d'affichage. |
| 5 | **E** | Allégations neutralisées. **l10n, 6 langues** : `homeHeroBody` « Une évaluation **scientifique** adaptative » → « Une évaluation **cognitive** adaptative » ; `homeAboutValidationTitle` « Validation scientifique » → « **Cadre théorique** » (les deux remplacements sont prescrits mot pour mot au §2.3). **README.md** : « scientifiquement rigoureuse » retiré ; « application **révolutionnaire** … de **qualité professionnelle** » → formulation neutre ; « Scoring psychométrique rigoureux **conforme aux standards internationaux** » → « fondé sur la théorie de réponse à l'item » ; titre « Fondements scientifiques » → « Cadre théorique ». « précision des tests utilisés par les psychologues » et « la référence mondiale » n'existaient plus que dans la fiche App Store, déjà traitée au LOT A. | ✅ `grep -rniE "scientifiquement valid\|validation scientifique\|évaluation scientifique\|référence mondiale\|recommandations de la CNIL" l10n_fragments/ ios/fastlane/ web/ README.md pubspec.yaml` → **0**. Plus aucune occurrence de `scientifi\|wissenschaftlich\|científ` dans les 6 langues. `flutter analyze` **23 issues** = référence. | **Deux conservations délibérées, à confirmer par le fondateur.** (1) **« intervalle de confiance à 95 % » CONSERVÉ dans l'app et le PDF** : le §2.3 le proscrit « de tout texte **commercial** », or `ctConfidenceInterval95`, `ctPdfConfidenceInterval95`, `scoringSummaryConfidenceInterval` et `weRvCi` sont des lectures techniques de résultat, pas de la promesse de vente. Il avait déjà été retiré du seul texte commercial qui le portait (fiche App Store, LOT A). Le retirer de l'app relèverait de la refonte de la notation — hors chantier. (2) **« saisir la CNIL » CONSERVÉ** dans `web/confidentialite.html:153` : c'est le droit de réclamation auprès de l'autorité de contrôle, **obligatoire** au titre des art. 13-14 RGPD. Le §2.3 ne vise que « recommandations de la CNIL », qui suggère un aval — tout l'inverse. Ne pas confondre les deux en relisant. |
| 5 | E+ | Restes README **volontairement laissés au LOT I** : « inspirée des échelles Wechsler » et « (WPPSI, WISC, WAIS) ». | — | Discipline un-lot-par-itération : la ligne 9 du README sera reprise au LOT I, dont c'est exactement l'objet. |
| 6 | **F** | Cadrage clinique retiré. **§2.5 « patient » → 2ᵉ personne** : `ctPatientAgeHeader` « ÂGE DU PATIENT » → « VOTRE ÂGE » et `ctMissingAgeBody` « Sans l'âge du patient » → « Sans votre âge », sur les **6 langues** (l'allemand disait déjà « ALTER DER PERSON »). **§2.5 « bilan » → « évaluation »** : 11 clés — `assessIntroEyebrow`, `assessLaunchFullAssessment`, `ctComputingResultsEyebrow`, `ctResultsHero1`+`Hero2` (accord féminin), `ctResumeFullTest`, `ctSubtestExitBody`, `weRvCaveat`, `weRvUnavailableTitle/Body`, `weRvMissingBody`, `weDay7Title`. **Constat utile : seul le FRANÇAIS portait le mot** — les 5 autres langues disaient déjà assessment / evaluación / avaliação / Untersuchung ; le correctif est donc quasi mono-langue. **`web/confidentialite.html`** : « suivi longitudinal par votre professionnel de santé » et « si vous utilisez l'application dans un **cadre clinique** » retirés (2 lignes) — c'était le dernier endroit qui positionnait l'app comme outil de soin. 24 valeurs réécrites au total. | ✅ **0 valeur affichée** ne contient plus « patient / dossier clinique / professionnels de santé mentale » (prouvé clé par clé, fragments + 4 overlays). `ctPdfDisclaimer` et `ctIndicativeDisclaimer` **intacts**, vérifiés dans l'ARB généré. `flutter analyze` **23 issues** = référence. | **Attente de la vérif corrigée** : elle annonçait « seuls les 2 disclaimers subsistent », or les disclaimers ne matchent pas ce motif (ils disent « clinique » et « psychologue »). Ce qui subsiste, ce sont **2 noms de clés** — `ctPatientAgeHeader`, `ctPatientAgeHint` — que la règle dure interdit de renommer : les renommer casserait la reprise de session. **Une occurrence de « bilan » CONSERVÉE volontairement** : `weDxAssessmentQuestion` « Un bilan complet a-t-il été fait ? », qui interroge l'historique **médical réel** de la personne, pas notre app — la reformuler fausserait la question. |
| 7 | **G** | §3 appliqué au porte-parole génératif, **5 blocs de langue** (`_englishPrompt` sert aussi `en-GB`). Ouverture réécrite partout : « spécialisé dans l'évaluation cognitive **basée sur les échelles WAIS-IV** » → « spécialisé **en psychologie cognitive**, qui accompagne les utilisateurs de Mental E.T. ». **Interdiction explicite ajoutée en tête du bloc IMPORTANT** dans les 5 langues : ne jamais mentionner WAIS/WISC/WPPSI ni les échelles Wechsler · ne jamais présenter Mental E.T. comme équivalent à un test clinique · ne jamais poser de diagnostic. Les garde-fous existants (pas de diagnostic médical, ne pas remplacer l'avis d'un professionnel, orienter vers un psychologue) sont **conservés intacts**. | ✅ **0** occurrence de marque hors ligne d'interdiction ; les 3 interdictions **et** les garde-fous présents dans les **5/5** blocs, contrôlés bloc par bloc sur les vraies bornes de définition ; `flutter analyze` **23 issues** = référence. | **La vérif du lot était inopérante — la plus grave rencontrée jusqu'ici.** Deux défauts cumulés : (1) **vacue** — `grep -niE "…" lib/features/chat/` **sans `-r`** ne lit pas un dossier et renvoie 0 quoi qu'il arrive ; elle serait passée au vert sur le fichier d'origine, marque WAIS-IV incluse. (2) **contradictoire** — le §3 impose de nommer les marques pour les interdire, donc « 0 occurrence » et « interdiction présente » ne peuvent pas être vraies simultanément. Remplacée par un contrôle qui vérifie que **toute** occurrence est une ligne d'interdiction. À relire par le fondateur. |
| 8 | **H** | §2.6 appliqué, **6 langues**. Similitudes→**Points communs**, Code→**Transcription**, Recherche de Symboles→**Détection de symboles**, Balances→**Équilibres**, Puzzles Visuels→**Assemblages**, Mémoire des Chiffres→**Suites de chiffres**. 21 clés de nom (`ctTest*`, `assessSubtest*`, `simTestName`, `ssTestName`, `dsTestName`, `fwTestName`, `vpTestName`, `codingTestName`, `codingTitle`, `*ResultsTitle`) + la **liste affichée des 13 exercices** `ctIntroContentBody`, réécrite en entier. ~140 valeurs. **Les `desc` ont été alignés** sur les nouveaux noms (~150 mentions) pour ne pas laisser de traînée, et `simDiscontinue[desc]` « après 3 échecs » corrigé en « sur renoncement », qui est la règle réelle. | ✅ **0** ancien libellé dans `l10n_fragments/` (fr et en). `flutter analyze` **23 issues** = référence. **Preuve que rien de structurant n'a bougé : `git diff --stat` sur `complete_test_session.dart` et `complete_test_orchestrator_page.dart` est VIDE** — `testSequence`, `subtestCodes` et le `switch` de `localizedSubtestName` sont intacts, donc la reprise de session et l'historique sont saufs. | **Deux extensions au-delà de la lettre du §2.6, à valider.** (1) **« Block Design » retiré** : §2.6 dit de GARDER « Cubes » comme mot courant, mais l'anglais et l'allemand rendaient ce sous-test par `Block Design` / `Mosaik-Test (Block Design)` — c'est-à-dire la nomenclature WAIS-IV, pas un mot courant. Aligné sur le mot simple : Cubes / **Blocks** / Cubos / Cubos / **Würfel**. (2) **Nom anglais des Équilibres = « Equilibrium », pas « Balances »** : mon premier choix (« Balances ») entrait en collision avec l'ANCIEN nom français, ce qui rendait la vérif ambiguë et laissait la chaîne « Balances » dans le dépôt. Corrigé dans la même itération. Les noms neutres retenus (Common Ground, Transcription, Symbol Detection, Equilibrium, Assembly, Digit Sequences) ne reconstituent aucune nomenclature ECPA/Pearson — **c'est le point à faire relire**. |
| 9 | **I** | **`pubspec.yaml`** : la description était « test de QI adaptatif par IA - **Inspirée des échelles Wechsler (WPPSI, WISC, WAIS)** » → « exercices cognitifs adaptatifs, construits sur le modèle CHC ». **`README.md`** : sous-titre, vue d'ensemble et mention de licence débarrassés de la marque ; les noms de sous-tests du tableau des domaines alignés sur le LOT H ; « 12 Types d'Exercices » → « **13 Exercices** » (§4) ; « Score final : QI Total (FSIQ) » → « un score global ». **La table comparative « Tests Wechsler® \| Mentality » (12 lignes) a été SUPPRIMÉE**, remplacée par un encart « Ce que l'application n'est pas ». | ✅ `grep -niE "wais\|wechsler\|wisc\|wppsi" pubspec.yaml README.md` → **0**. `flutter pub get` OK, `pubspec.yaml` toujours valide (name/version intacts). `flutter analyze` **23 issues** = référence. | **Suppression la plus lourde du chantier, à valider.** La table « Différences avec tests officiels » comparait ligne à ligne Mentality aux tests Wechsler (administration, durée, items, validité, coût). C'est exactement le **parasitisme** visé à l'art. 1240 C. civ. cité au §7 — se placer dans le sillage de l'investissement d'autrui, **sans qu'aucun risque de confusion soit nécessaire**. Elle contenait en outre deux aveux : « Validité : **en cours de validation** » et une durée de « 30-45 min » contredisant les 60–90 min réels. La mention de licence a été réécrite : elle reconnaissait que l'app « s'inspire de leur structure psychométrique », ce qui documentait le parasitisme dans notre propre dépôt. **Laissé intact** : le bloc de pseudo-code du calcul (`FSIQ = (ICV + IVS + …) / 5`) — ce sont les identifiants internes du calcul, cohérent avec la décision du LOT D. |
| 10 | **J** | Passe finale. Toutes les vérifs A→I rejouées d'un bloc : **toutes vertes**. Le **balayage large a trouvé ce qu'aucun lot n'avait couvert — 4 chaînes de marque AFFICHÉES, en dur dans le Dart** : `splash_page.dart:94` `Text('WAIS-IV · WISC-V · WPPSI-IV')` — la bande de marques de l'**écran de démarrage**, la plus visible de l'app —, `onboarding_page.dart:46` (marque + les 6 sigles dans une diapo non localisée), et **deux** sur-titres `eyebrow: 'WAIS-IV'` dans `complete_test_orchestrator_page.dart` (écran d'intro et écran de passation). Corrigés : le splash affiche « CATTELL · HORN · CARROLL » (notre ancre du §1, universelle, sans traduction), l'onboarding est réécrit sur le modèle CHC sans sigles, et les 2 sur-titres passent sur `context.l10n.assessIntroEyebrow` — donc localisés dans les 6 langues au lieu d'être figés. | ✅ **Tout vert.** `_merge.py` 1070 clés × 6 langues, toutes traduites · `gen-l10n` sans erreur · `flutter analyze` **23 issues / 0 erreur** = référence exacte de l'itération 0 · 17 contrôles de contenu sur les 6 ARB, **0 écart** · **0 libellé vide** · les 2 disclaimers **intacts** · **0 chaîne affichée** portant une marque dans tout le dépôt. | **Attente du balayage corrigée : le zéro absolu était inatteignable.** Trois raisons cumulées, toutes documentées : bornes `\b` manquantes (« zwischen »), worktrees `/.claude/` (ignorés par git, rien n'en est livré), et surtout **le §3 impose que le prompt du chat NOMME les marques pour les interdire**. Ce qui reste, et qui est **voulu** : 57 commentaires de code + docstrings de banques d'items (règle dure « libellés affichés uniquement » ; `*_items_*.dart` explicitement hors périmètre), 5 lignes d'interdiction du chat, 2 constantes de bande d'âge (`'WISC'`, `'WAIS'`) — **mortes, référencées nulle part**, et des identifiants que la règle dure interdit de renommer. |
| 11 | **J** (contre-vérification) | **Aucune modification de code.** Les 10 lots étant cochés, cette itération n'a fait que **rejouer toutes les vérifications de façon indépendante**, sans se fier au Journal. A→I et le balayage large du LOT J : **tous verts**. Contrôle ARB refait de bout en bout : 1070 clés × 6 langues, **0 marque**, **0 sigle**, **0 libellé vide**, les 4 remplacements prescrits présents au mot près, **0 ancien libellé de sous-test**, les 2 disclaimers non vides sur 6/6 langues. | ✅ Tout vert. `_merge.py` 1070 × 6 · `gen-l10n` OK · `flutter analyze` **0 erreur**, **23 issues uniques = 12 warnings + 11 infos**, soit la référence EXACTE de l'itération 0. | **Piège d'instrumentation à connaître avant de rejouer la vérif : `flutter analyze` affiche désormais « 46 issues », pas 23 — et ce n'est PAS une régression.** Le dépôt contient **46 `pubspec.yaml` imbriqués sous `.claude/worktrees/`**, donc 46 contextes d'analyse supplémentaires : les mêmes fichiers sont analysés plusieurs fois et chaque issue est émise en double. Après dédoublonnage : 12 warnings + 11 infos + **0 erreur** = la référence au chiffre près. **Comparer les issues UNIQUES, jamais le total affiché** (`flutter analyze \| grep -E "^\s*(error\|warning\|info) •" \| sed 's/^[ ]*//' \| sort -u \| wc -l`). Ces worktrees sont ignorés par git (`.gitignore:50`, 0 fichier suivi) : rien n'en est livré, et le critère du lot — « sans **nouvelle erreur** » — est tenu (0 erreur des deux côtés). |
| 12 | **hors chantier** | **Aucune modification.** Contrôles que **aucun lot n'a jamais exigés**, faits après clôture. (1) **Suite de tests jouée pour la première fois** : `flutter test` → **1019/1019, `success: true`**. Un premier run avait affiché `-5` ; le second est vert, et un renommage de libellé cassé échouerait à *chaque* run — donc **flakiness, pas régression du chantier** (les 5 tests concernés sont des tests de layout/rendu). (2) **Balayage des surfaces publiables hors périmètre du LOT J** (`android/`, `macos/`, `windows/`, `linux/`, `ios/` hors fastlane, `test/`) : **0 marque, 0 allégation** — sauf `test/` (voir Reste). | ✅ 1019/1019 tests · 0 marque hors périmètre. | **Trois points pour le fondateur, tous HORS des règles dures (rien touché).** (a) **5 fichiers de `test/` documentent la filiation WAIS dans leurs noms** : « SimilaritiesGenerator — **structure WAIS conservée** », « VocabularyGenerator — **structure WAIS conservée** », « **Protocole WAIS-IV** : un contour distinctif… », « le **WAIS-IV** présente 5 options », « temps **WAIS** ». C'est **exactement l'aveu retiré du README au LOT I** (« s'inspire de leur structure psychométrique », qui « documentait le parasitisme dans notre propre dépôt ») — mais dans du code versionné, donc **communicable en cas de contentieux**. Non traité car les tests ne sont pas des « libellés affichés » : **décision du fondateur**. (b) **`web/index.html` est resté le squelette Flutter par défaut** : `<meta name="description" content="A new Flutter project.">` et `<title>mentality</title>` — surface **publiée**, jamais balayée par aucun lot (le LOT J cherchait des marques, pas des placeholders). (c) **Nom du produit incohérent** : `android:label="Mentality"`, titre web « mentality », mais la politique de confidentialité et le prompt du chat disent « **Mental E.T.** ». |
