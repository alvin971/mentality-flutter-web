# Journal — boucle « vérification vocale »

Une entrée par réveil. Critère de sortie : §6 de `docs/LOOP_VERIFICATION_VOCALE.md`.
Budget : ≤ 60 min d'audio nouvellement transcrit par réveil et par modèle (`results/ledger.jsonl`).

## Réveil 1 — 2026-09-03 — banc construit, jeux tirés, première mesure

**Prérequis (§0).** Branche `chantier/verification-vocale` créée depuis `main`
(`e4b02b1`), protocole commité en premier. `wrangler` 4.128.0 trouvé dans le cache
npx. ffmpeg 7.1.5, Node 22, piper-tts 1.7.0 installé dans `~/.venvs/piper` (pas de
binaire système), 12 voix piper téléchargées dans `~/.cache/piper-voices`.

**Piège rencontré : le token n'a pas la permission Workers AI.** `POST /ai/run`
répond 401 (token valide, permissions DNS + Workers Scripts seulement) ; l'API
`/ai/models` aussi. Contournement sans rien déployer : un mini-worker
(`worker/`) lancé par `wrangler dev` — le binding `AI` s'exécute à distance sur
le compte, avec exactement la primitive de production `env.AI.run`. C'est même
plus fidèle que l'API REST. Port 8787 déjà pris par un autre serveur → 8799.

**Catalogue (`results/models.json`, via `env.AI.models`).** ASR disponibles :
`@cf/openai/whisper` 0,000453 $/min · `@cf/openai/whisper-large-v3-turbo`
0,000513 $/min (file asynchrone) · `@cf/openai/whisper-tiny-en` (bêta, anglais
seul, sans prix) · `@cf/deepgram/nova-3` 0,0052 $/min (partenaire, payant, ×11)
· `@cf/deepgram/flux` (websocket temps réel, hors sujet). Allocation gratuite :
10 000 neurones/jour = 0,11 $/jour ⇒ ≈ 240 min de whisper par jour.

**Formes d'entrée/sortie (§5) mesurées sur une lecture fr de 44 s :**
- `@cf/openai/whisper` : entrée `{ audio: [octets] }` ; accepte `language: 'fr'`,
  `'en-GB'` ou rien **sans erreur et sans changer la sortie** (texte identique
  dans les trois cas : le paramètre est ignoré). Sortie `{ text, word_count,
  vtt, words[] }`. 3,7–5,8 s.
- `@cf/openai/whisper-large-v3-turbo` : **refuse la forme de production**
  (`'string' not in 'array','binary'`, erreur 5006) — exige `audio` en base64.
  Sortie `{ transcription_info{language, language_probability, duration}, text,
  word_count, segments, vtt, usage }`. 3,1 s. Passer en production à turbo
  impose donc de changer la forme d'appel dans `workers/r2-upload/index.js`.
- `@cf/openai/whisper-tiny-en` : anglais seul (sur du français : 42 mots de
  charabia). À ne mesurer, s'il le faut, que sur en/en_GB.
- mp4 (AAC 32 kbps) accepté par whisper comme le webm.

**Ce que l'app envoie réellement** (relu dans le code, pas dans les docs) :
`X-Language` = `LocaleNotifier.contentTag` ⇒ `fr`, `en`, **`en-GB`**, `es`,
`pt`, `de`, passé tel quel au modèle ; `record` configuré 16 kHz, mono,
32 kbps, Opus → AAC-LC → wav. Le banc reproduit ces valeurs (`LANG_PARAM`,
`degrade.sh`).

**Jeux (§3).** Graine **20260903** ; 40 textes par langue tirés au sort (fr sur
503, les autres sur 50), **6 en holdout** par langue (`manifests/texts.json`).
`words_ref` (mots distincts ≥ 4 lettres) : fr 68–93 · en 68–98 · en_GB 69–101 ·
es 62–87 · pt 67–96 · de 59–117 — un mot vaut ≈ 1,2 point de recouvrement.
Voix : fr siwis/tom · en lessac/ryan · en_GB jenny_dioco/alan · es
claude (MX)/davefx (ES) · pt faber (BR)/tugão (PT) · de kerstin/thorsten.
**1 997 cas** (pos 1 578 · neg 298 · sum 121, dont 192 holdout), 9 vagues.
Le corpus n'est PAS aligné entre langues (en_00001 ≠ traduction de fr_00001) :
les « traductions lues » (24) et les résumés (48 × sum30 20–27 mots + sum8 exactement
8 mots) ont été rédigés par des sous-agents (`manifests/xlang_src.json`,
`manifests/resumes_src.json`), voix synthétiques ensuite.

**Décisions de conception (à contester si les chiffres l'exigent).**
1. **Budget contre grille** : la grille §3 complète ≈ 25 h d'audio ⇒ ~26 réveils
   par modèle à 60 min. Les variantes acoustiques et les négatifs à audio sont
   donc en **rotation 1/3** sur les textes (≥ 11 textes par variante et par
   langue), les lectures intégrales voix A/webm et voix B/mp4 sur tous les
   textes. Rien n'est retiré : chaque variante du §3 est représentée.
2. **Cache sans texte** : suites d'indices de référence + histogrammes
   (`lib/tokens.mjs`, auto-testé contre `recouvrement()` de production). Les
   règles d'ordre (LIS) et de couverture (dernier tiers) se mesurent dessus
   sans retranscrire.
3. **Négatifs dérivés** : « autre texte même langue » (3 cibles en rotation +
   max sur toutes les paires pour la marge) et « autre langue » sont calculés
   sur les transcriptions des lectures intégrales : coût nul, milliers de paires.
4. **Ordre des modèles** : whisper (production) puis turbo sur les vagues 1–2,
   comparaison, puis la grille complète sur le meilleur ; l'autre reste mesuré
   comme repli.
5. Piper est ~10× temps réel sur cette machine (chargée par ailleurs, load > 80) :
   la synthèse tourne en arrière-plan, `OMP_NUM_THREADS=2` par processus.

**Mesure — `@cf/openai/whisper`, vague 1 partielle (budget 59,4 min = 74 lectures
intégrales voix A / opus webm, 12–13 par langue, 0 erreur modèle).** Cache
`cache/whisper/app`, ledger `results/ledger.jsonl`, détail `results/whisper.app.json`.

| langue | n | pire recouvrement | médiane | meilleur imposteur (max sur 33 « autres textes ») | ms / min d'audio (méd.) |
|---|---|---|---|---|---|
| fr | 12 | 0,694 | 0,800 | 0,200 | 7 068 |
| en | 13 | 0,919 | 0,968 | 0,173 | 4 670 |
| en_GB | 12 | 0,615 | 0,942 | 0,169 | 4 615 |
| es | 12 | 0,783 | 0,886 | 0,240 | 4 257 |
| pt | 12 | 0,610 | 0,747 | 0,179 | 5 712 |
| de | 13 | 0,611 | 0,840 | 0,195 | 4 933 |

- Positifs intégraux propres : **100 % `ok` jusqu'au seuil 0,60** (pire 0,610 pt,
  médiane globale 0,863). Chute au-delà : 96 % à 0,65, 89 % à 0,70.
- Négatifs dérivés « autre texte, même langue » (222 paires) : **100 % rejetés
  dès 0,20** (99,1 % à 0,15, 88 % à 0,10) ; meilleur imposteur 0,296 (une paire
  es). « Autre langue » (74 paires) : médiane 0,05, max ≈ 0,16.
- **Marge** (pire positif propre − meilleur imposteur) = **0,31** au seuil 0,30
  de production : le seuil actuel est dans la bonne zone, mais on ne sait encore
  rien des lectures dégradées, partielles, ni des formats mp4/wav.
- Signaux d'ordre : intégrales ordre (LIS) médian 1,00, couverture du dernier
  tiers 0,88 ; « autre texte » ordre 0,60, couverture 0,04. Les règles §4.6
  auront de quoi mordre si les mots mélangés / 25 % + silence passent le seuil.
- **Coût** : 2,74 min d'audio par bilan (3 × 48,8 s + résumé estimé 20 s) →
  **0,124 ¢/bilan** (whisper 0,000453 $/min), soit **88 bilans/jour dans
  l'allocation gratuite**. Légèrement au-dessus des 0,1 ¢ du §1 hors allocation ;
  dans l'allocation aux volumes du lancement — à trancher au FINAL.
- **Latence** : 4,7 s par minute d'audio (méd.), p95 10,9 s, max 16 s par
  fichier — très loin des 60 s de `ctx.waitUntil`. fr est le plus lent (7 s/min).
- Le paramètre `language` n'a produit aucun repli (`fallback` 0), et comme vu
  sur la sonde il ne change pas la sortie de ce modèle : la policy `none` ne
  sera mesurée que sur turbo, où il compte.

**Décision.** Whisper (production) tient §6 sur la seule tranche mesurée, sans
aucun échec. Rien n'est concluant tant que dégradations, partielles et négatifs
à audio ne sont pas mesurés. Prochain réveil : **turbo sur la vague 1** (même
74 fichiers, forme base64) pour la comparaison à budget égal ; puis alternance
sur les vagues 2–5 du meilleur. Vague 2 (371 audios) en cours de synthèse.

## Réveil 2 — 2026-09-03 — turbo sur la même vague 1

**Mesure — `@cf/openai/whisper-large-v3-turbo`, mêmes 74 lectures intégrales
(voix A / opus webm, 59,4 min), entrée base64 + `language` de l'app, 0 erreur.
Correctif de lecture : 12 replis, pas 0 — turbo REFUSE `en-GB` (les 12 fichiers
en_GB sont repartis sans `language`, comme le ferait le worker de production) ;
la langue détectée reste juste. Si turbo est retenu, le worker devra ramener
`X-Language` à son code ISO 639-1 (`en-GB` → `en`) avant l'appel.**
`results/whisper-large-v3-turbo.app.json`.

| langue | n | pire recouvrement | médiane | meilleur imposteur | ms / min d'audio (méd.) | langue détectée |
|---|---|---|---|---|---|---|
| fr | 12 | 0,933 | 0,960 | 0,247 | 5 927 | fr=12 |
| en | 13 | 0,925 | 0,977 | 0,176 | 4 831 | en=13 |
| en_GB | 12 | 0,917 | 0,979 | 0,169 | 5 043 | en=12 |
| es | 12 | 0,907 | 0,988 | 0,227 | 2 511 | es=12 |
| pt | 12 | 0,835 | 0,934 | 0,183 | 4 519 | pt=12 |
| de | 13 | 0,819 | 0,936 | 0,241 | 5 130 | de=13 |

Comparaison à budget égal (mêmes fichiers) :

| | whisper | turbo |
|---|---|---|
| pire positif intégral propre | 0,610 | **0,819** |
| médiane | 0,863 | **0,962** |
| meilleur imposteur (222 paires) | 0,296 | 0,296 |
| marge au seuil (pire − imposteur) | 0,31 | **0,52** |
| seuil le plus bas qui rejette 100 % des imposteurs | 0,20 | 0,20 |
| latence méd. / p95 / max (par min d'audio, par fichier) | 4,7 s / 10,9 s / 16 s | 4,5 s / 12,8 s / 14,5 s |
| coût par bilan (2,74 min) · bilans/jour gratuits | 0,124 ¢ · 88 | 0,141 ¢ · 78 |
| forme d'entrée | octets (production) | **base64 (changement de worker)** |
| langue détectée | non renvoyée | `transcription_info.language`, juste 74/74 |

- Turbo transcrit ~10 points de recouvrement de plus sur des voix propres et
  resserre surtout la queue basse (fr 0,69 → 0,93, en_GB 0,62 → 0,92, pt
  0,61 → 0,84) : c'est la queue qui décide des faux négatifs sur vraies voix.
- Les imposteurs ne bougent pas (même paire es à 0,296) : le bruit de fond des
  « autres textes » vient du vocabulaire partagé, pas du modèle. Rien sous 0,30
  avec les deux modèles, mais 0,30 est **trop proche** de 0,296 pour être
  retenu tel quel : un seuil retenu doit se choisir dans la marge, pas à son bord.
- Turbo renvoie la langue détectée : signal gratuit pour un futur garde-fou
  (lecture dans une autre langue), à mesurer sur les cas `xlang` de la vague 2.
- Coût : +13 % pour turbo ; les deux tiennent l'allocation gratuite jusqu'à
  ~80 bilans/jour, et ~0,13 ¢ au-delà (le §1 visait 0,1 ¢ — écart à acter au FINAL).

**Décision.** Turbo prend la tête ; la grille complète (vagues 2–7) se mesure
d'abord sur turbo, whisper reste mesuré sur les vagues 2 puis 3 comme repli
(il est le modèle déployé). Prochain réveil : reste de la vague 1 turbo
(130 lectures, 2 réveils) ou vague 2 turbo si la synthèse a fini.
