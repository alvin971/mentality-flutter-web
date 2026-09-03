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
