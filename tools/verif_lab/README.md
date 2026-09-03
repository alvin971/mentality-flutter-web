# Banc d'essai « vérification vocale » — `tools/verif_lab/`

Prouver qu'une lecture à voix haute a vraiment eu lieu (plan Gratuit), avec le
meilleur modèle de transcription gratuit ou quasi-gratuit de Workers AI et un
seuil **calibré sur des mesures**. Protocole complet : `docs/LOOP_VERIFICATION_VOCALE.md`.
Journal des réveils : `JOURNAL.md`. Résultat final : `FINAL.md` (après convergence).

## Doctrine

- **Aucun mot transcrit n'est écrit sur disque.** Le cache ne garde que des
  comptes : pour chaque référence publique du corpus, la suite des *indices*
  des mots de cette référence retrouvés dans la transcription (ordre et
  répétitions conservés), et des histogrammes de longueurs (`lib/tokens.mjs`).
  Ces entiers recalculent exactement le recouvrement de production et
  permettent de mesurer des règles d'ordre ou de couverture sans retranscrire.
- **La normalisation est celle de la production** : `workers/_shared/text_norm.js`
  est importé, jamais recopié. Sa signature comportementale est stockée dans
  chaque entrée du cache (`norm_sig`) ; si elle change, tout est à retranscrire.
- **Voix synthétiques** (piper, libres, locales) : plus propres que de vraies
  voix, donc seuils optimistes — d'où la marge exigée au §6 et le suivi sur
  vraies voix prévu au §7.
- **Rien n'est déployé.** Le mini-worker `worker/` ne tourne que sous `wrangler dev`.

## Pourquoi un mini-worker

Le token du compte (`CLOUDFLARE_API_TOKEN`) n'a pas la permission « Workers AI »
que l'API REST `/ai/run` exige (401). `wrangler dev` accepte ce token, et un
binding `AI` s'exécute **toujours à distance**, facturé au compte, exactement
comme en production : le banc appelle donc `env.AI.run(modèle, entrée)` via
`worker/index.js`, avec la même forme d'entrée que `workers/r2-upload/index.js`
(octets bruts du fichier, `language` = `X-Language` de l'app, même repli).

## Lancer

```bash
# 0. token + compte (dans ~/.bashrc, jamais dans un fichier suivi)
eval "$(grep -E '^export CLOUDFLARE_(API_TOKEN|ACCOUNT_ID)=' ~/.bashrc)"; export CLOUDFLARE_API_TOKEN CLOUDFLARE_ACCOUNT_ID
W=$(ls -t ~/.npm/_npx/*/node_modules/.bin/wrangler | head -1)
(cd tools/verif_lab/worker && $W dev --port 8799 --ip 127.0.0.1 --show-interactive-dev-session=false &)

# 1. catalogue des modèles ASR du compte (prix, propriétés) → results/models.json
node tools/verif_lab/models.mjs

# 2. manifestes (graine 20260903 : 40 textes/langue, 6 en holdout ; 1 997 cas)
node tools/verif_lab/manifest.mjs

# 3. audio synthétique (cache : jamais régénéré) — voix piper dans ~/.cache/piper-voices
#    résumés et traductions rédigés à part : manifests/resumes_src.json, manifests/xlang_src.json
node tools/verif_lab/synth.mjs --wave 1,2 --jobs 6

# 4. transcription sous budget (≤ 60 min d'audio NOUVEAU par réveil et par modèle)
node tools/verif_lab/transcribe.mjs --model @cf/openai/whisper --minutes 60 --wave 1,2
node tools/verif_lab/transcribe.mjs --model @cf/openai/whisper --language none --minutes 60   # sans paramètre language

# 5. courbes seuil → erreurs, check-list §6, coût, latence → results/<modèle>.<policy>.json
node tools/verif_lab/score.mjs --model @cf/openai/whisper            # calibration (hors holdout)
node tools/verif_lab/score.mjs --model @cf/openai/whisper --holdout  # holdout, seulement après convergence

# stabilité (§6) : vider 10 % du cache tiré au sort, retranscrire, comparer
node tools/verif_lab/transcribe.mjs --model @cf/openai/whisper --clear-sample 0.10 --seed 42
```

Prérequis : Node 22, ffmpeg, `~/.venvs/piper` (`pip install piper-tts`), voix
piper (`python -m piper.download_voices --download-dir ~/.cache/piper-voices <voix>`
— `pt_PT-tugão-medium` se télécharge à la main, le script bute sur le « ã »).

## Jeux (§3) et vagues de priorité (§2)

`manifest.mjs` fixe la grille. Chaque texte de calibration reçoit : lecture
intégrale voix A en opus webm (vague 1) et voix B en aac mp4 (vague 3) ; puis,
en rotation 1/3 pour tenir le budget, les négatifs à audio propre (mots
mélangés, 25 % puis silence, phrase en boucle — vague 2), les lectures
partielles 75 %/60 % (vague 4), les dégradations acoustiques (vitesse ×0,8/×1,3,
bruit −20/−10 dB, fond pièce, micro −15 dB, saturé +12 dB — vague 5), le
croisement voix × format (vague 6) et le wav (vague 7). Traductions lues
(3 textes/langue), parole de fond, silence/bruit/musique et résumés (6
textes/langue) sont en vague 2. Le holdout (6 textes/langue) est en vague 9.
Les négatifs « autre texte » (même langue, autre langue) sont **dérivés** des
transcriptions des lectures intégrales, sans audio ni coût supplémentaires.

Formats = ceux de l'app (`record ^5.2`, 16 kHz mono 32 kbps) : Opus/webm
(Chrome, Firefox, Android), AAC-LC/mp4 (Safari, iOS), wav (secours).

## Fichiers

| Fichier | Rôle |
|---|---|
| `worker/` | mini-worker `wrangler dev` : `GET /models`, `POST /transcribe` |
| `manifest.mjs` | tirage des textes, grille des cas, chemins d'audio |
| `synth.mjs` + `lib/synth_piper.py` + `degrade.sh` | fabrication des audios (piper → ffmpeg) |
| `transcribe.mjs` | appels modèle, cache de comptes, budget, `results/ledger.jsonl` |
| `score.mjs` | recouvrement, courbes, check-list §6, coût, latence, signaux d'ordre |
| `lib/tokens.mjs` | indices de référence, recalcul du recouvrement (auto-test contre la production) |
| `manifests/` | `texts.json`, `voices.json`, `cases.jsonl`, `audio_index.json`, sources des résumés/traductions |
| `results/` | `models.json`, `<modèle>.<policy>.json`, `ledger.jsonl` |
| `audio/`, `work/`, `cache/` | non commités (`.gitignore`) — tout se régénère |
