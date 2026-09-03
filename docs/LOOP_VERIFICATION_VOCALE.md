# Boucle « vérification vocale » — prouver qu'une lecture a vraiment eu lieu

> Protocole autonome pour `/loop`. Une itération par réveil. **Ne jamais demander de validation** : décider, consigner, continuer. S'arrêter seulement au critère de sortie (§6), puis livrer (§7). Au premier réveil : lire ce fichier en entier, puis `tools/verif_lab/JOURNAL.md` s'il existe pour reprendre où on en était.

## 0. Prérequis à vérifier au premier réveil (et à chaque réveil, en 5 s)

- Dépôt : `/home/ubuntu/projects/mentality/mentality-flutter-web`. Branche de travail **`chantier/verification-vocale`**, créée depuis `main` au premier réveil (commiter ce fichier dessus en premier). Ignorer tout chemin `.claude/worktrees/`.
- Compte Cloudflare : `CLOUDFLARE_API_TOKEN` et `CLOUDFLARE_ACCOUNT_ID` sont dans `~/.bashrc` (les sourcer, ne jamais les écrire dans un fichier suivi). Workers AI s'appelle hors worker par `POST https://api.cloudflare.com/client/v4/accounts/<id>/ai/run/<modèle>` — c'est la voie du banc d'essai.
- Le binaire `wrangler` n'est **pas** dans le PATH : `W=$(ls -t ~/.npm/_npx/*/node_modules/.bin/wrangler | head -1)`.
- `ffmpeg` est installé (`/usr/bin/ffmpeg`). Node 22. `flutter` = `~/flutter/bin/flutter`. Pas de `piper` ni d'`espeak-ng` installé.
- Doctrine des workers : **aucun mot transcrit n'est conservé ni loggé**, jamais de donnée de personne dans un journal. Le banc d'essai travaille sur des voix **synthétiques** ou sur des enregistrements que le fondateur a lui-même produits en test.
- Si un réveil ne peut rien faire (API Cloudflare en panne, quota du jour épuisé), le consigner dans le JOURNAL et attendre le réveil suivant. Ne pas contourner.

## 1. Contexte (ce que le code ne dit pas)

- Le plan **Gratuit** paie le bilan avec sa voix : 3 lectures à voix haute d'un texte du corpus (`assets/reading_corpus/*.jsonl`, 753 textes, 6 langues fr/en/en_GB/es/pt/de) + un résumé oral. Un fichier de silence ou de bruit ne doit pas donner droit aux résultats. C'est la **preuve de lecture**, pas une évaluation de la personne : on ne mesure rien sur la voix, on vérifie que le texte attendu a été lu.
- Chaîne actuelle, en production depuis le 2026-09-03 (`workers/r2-upload/index.js`) : après chaque dépôt réussi, transcription en tâche de fond par Workers AI `@cf/openai/whisper`, puis **recouvrement** = part des mots distincts de la référence (`corpus/<textId>.json`, mots normalisés ≥ 4 lettres, module partagé `workers/_shared/text_norm.js`) retrouvés dans la transcription. Verdict `ok` si recouvrement ≥ `VERIFY_MIN_OVERLAP` (**0,30, valeur de départ posée sans aucune vraie voix**). Verdict écrit sous `verified/<account>/<sessionId>/reading-<textId>.json` avec seulement des **comptes** (`overlap, words_hit, words_ref, words_transcribed, model, day`). Résumé : `ok` si ≥ `VERIFY_MIN_SUMMARY_WORDS` (15) mots distincts.
- `POST /validate` du tokeniser exige `MIN_VERIFIED_READINGS` (3) lectures `ok` ; répond `409 VERIFICATION_PENDING` tant que des verdicts manquent, `400 VERIFICATION_FAILED` quand tout est tombé. Un verdict `ai_unavailable`/`ai_error` ne bloque jamais le dépôt, seulement les résultats.
- Format audio réel de l'app : **Opus 32 kbps dans webm** (Chrome/Firefox/Android), **AAC dans mp4** (Safari/iOS), wav en secours. Toute mesure doit se faire sur ces formats-là, pas sur du wav propre.
- Seule mesure réelle à ce jour : un dépôt de **silence** → `low_overlap`, `VERIFICATION_FAILED`. Le seuil 0,30 n'a jamais vu une lecture humaine. On ne sait pas s'il rejette des vraies lectures (faux négatifs = personnes honnêtes privées de résultats) ni s'il laisse passer une lecture d'un autre texte.
- Ce que le fondateur attend, mot pour mot : « l'outil ne va pas trouver tous les mots, mais en avoir assez peut permettre de vérifier que l'utilisateur a réellement bien lu ». Donc : **le meilleur modèle de transcription gratuit ou quasi-gratuit**, et un **seuil calibré sur des mesures**, langue par langue si nécessaire, robuste aux formats et aux voix.
- « Gratuit » se lit ainsi : dans l'allocation gratuite de Workers AI (10 000 neurones/jour, vérifier la page de tarifs au premier réveil) ou à un coût par bilan **inférieur à celui du correcteur IA** (≈ 0,1 ¢ US par bilan, `tools/correction_lab/JOURNAL.md`). Une solution qui exige un serveur permanent ou une clé tierce payante est hors sujet.

## 2. Le banc d'essai — `tools/verif_lab/` (à créer au premier réveil)

```
tools/verif_lab/
  models.mjs           # liste les modèles de transcription disponibles sur le compte (API /ai/models?task=Automatic Speech Recognition), leur prix, leurs langues
  synth.mjs            # fabrique les voix synthétiques (§3) → audio/<lang>/<textId>.<variante>.<ext> ; cache, jamais régénéré
  degrade.sh           # ffmpeg : wav propre → opus 32 kbps webm, aac mp4, + variantes bruit/vitesse/troncature
  transcribe.mjs       # appelle un modèle sur un fichier via l'API compte ; cache par sha256(modèle+audio+langue) dans cache/ ; ne conserve que les COMPTES et le recouvrement, JAMAIS le texte transcrit sur disque
  score.mjs            # recouvrement (importe workers/_shared/text_norm.js, pas une copie), courbes seuil→(faux négatifs, faux positifs), par langue / format / variante
  results/<modèle>.<jeu>.json
  JOURNAL.md           # une entrée par réveil : ce qui a été mesuré, chiffres, décision
  README.md
```

`transcribe.mjs` doit mimer **exactement** l'entrée du worker : octets bruts du fichier, paramètre `language` s'il est accepté, même normalisation. Un banc qui transcrit autrement que le worker mesure autre chose que la production.

Budget : **≤ 60 minutes d'audio transcrites par réveil et par modèle**, comptées dans le JOURNAL. Le cache rend chaque rejeu gratuit.

## 3. Jeux d'audio — construits une fois, rejoués à chaque modèle et chaque seuil

Voix synthétiques, **libres de droits et locales de préférence** : au premier réveil, installer `piper` (voix fr, en_US, en_GB, es, pt, de disponibles) ; à défaut, le modèle TTS de Workers AI (`@cf/myshell-ai/melotts` ou équivalent listé) pour les langues qu'il couvre, en le notant. Au moins **2 voix par langue** (timbres différents). Textes : **40 textes par langue** tirés au sort du corpus (graine fixée, consignée), dont **15 % mis de côté en holdout** jamais regardés pendant la calibration.

**positifs.jsonl** (une lecture honnête, verdict attendu `ok`) :
- lecture intégrale, voix 1 et voix 2, en wav puis **opus 32 kbps webm** puis **aac mp4** (les trois formats sont comptés séparément) ;
- vitesse ×0,8 et ×1,3 (`atempo`) ;
- bruit de fond ajouté à −20 dB et −10 dB (bruit blanc filtré, et un fond « pièce » si disponible) ;
- **lecture partielle** : 75 % du texte, puis 60 % (tronqué à la fin) — une personne qui bute sur la fin a quand même lu ;
- micro faible : gain −15 dB ; micro saturé : gain +12 dB avec écrêtage.

**négatifs.jsonl** (verdict attendu `ok:false`) :
- silence ; bruit blanc seul ; musique ou parole de fond sans lecture ;
- lecture d'un **autre texte** du corpus de la **même langue** (le cas frauduleux réaliste : rejouer un fichier d'un ami) ;
- lecture du **bon texte dans une autre langue** (traduction lue) ;
- lecture de **≤ 25 %** du texte puis silence ;
- une seule phrase répétée en boucle ;
- le texte lu **à l'envers** (mots mélangés : même vocabulaire, autre ordre) — ce cas dit si le recouvrement par sac de mots suffit ou s'il faut un signal d'ordre.

**résumés.jsonl** (mêmes variantes que ci-dessus, plus légères) : un résumé libre de 20 à 40 mots → `ok` ; 8 mots → `ok:false` ; silence → `ok:false`.

Chaque cas porte : langue, textId, variante, format, durée, verdict attendu. Aucun fichier audio n'est commité (`.gitignore` : `audio/`, `cache/`) ; seuls `synth.mjs`, la graine et les manifestes le sont, pour tout régénérer.

## 4. Une itération (= un réveil)

1. Lire le JOURNAL, vérifier §0.
2. Si les jeux n'existent pas : les construire (§3), consigner tailles et graine.
3. Choisir **un** modèle non encore mesuré (ordre : celui en production `@cf/openai/whisper`, puis `@cf/openai/whisper-large-v3-turbo`, puis tout autre modèle ASR listé par `models.mjs` dans l'allocation gratuite ; un modèle payant hors allocation n'est mesuré que si tout le gratuit échoue au §6).
4. Transcrire positifs + négatifs + résumés (dans le budget du §2, en commençant par le sous-ensemble le plus discriminant si le budget ne couvre pas tout), puis `score.mjs` : pour chaque seuil de 0,05 à 0,95 par pas de 0,05, taux de **faux négatifs** (lecture honnête rejetée) et de **faux positifs** (fraude acceptée), global, par langue, par format, par variante. Coût et latence par minute d'audio.
5. Écrire `results/` et l'entrée du JOURNAL : tableau seuil × erreurs, le seuil qui minimise les faux négatifs sous contrainte de faux positifs (§6), les cas qui résistent, la décision (modèle retenu ? seuil ? règle supplémentaire ?).
6. Si une **règle** est nécessaire au-delà du seuil (ex. exiger que les mots retrouvés couvrent au moins deux tiers de la longueur du texte, pour rejeter le « 25 % puis silence » ; ou un score d'ordre par plus longue sous-séquence commune, pour rejeter les mots mélangés), l'écrire dans `workers/_shared/text_norm.js` sous forme de fonction pure **avec tests**, la mesurer au réveil suivant. Une règle par réveil, jamais deux changements à la fois.
7. Commiter (`lab(verif): …`) et pousser sur la branche.

## 5. Pièges connus (ne pas refaire)

- Le worker recopie les octets dans un tableau JS pour le modèle : au-delà de 8 Mo il ne transcrit pas (`VERIFY_MAX_BYTES`). Tester la borne, ne pas la relever sans mesurer la mémoire.
- La forme exacte de la réponse Whisper sur Workers AI (`{ text }`) n'est confirmée que pour `@cf/openai/whisper`. Tout autre modèle : vérifier la forme sur un premier appel et l'écrire dans le JOURNAL avant d'en dépendre.
- `wrangler r2 object get --jurisdiction eu` ment (« key does not exist ») : lire R2 via un mini-worker en `wrangler dev --remote` (Gotchas du vault).
- La normalisation est partagée (`text_norm.js`) : ne jamais dupliquer ses règles dans le banc, l'**importer**. Si une règle change, la référence publiée dans R2 (`publish-corpus.mjs`) doit être republiée — le noter dans §7.
- Les mots < 4 lettres sont ignorés des deux côtés : un texte court en anglais peut n'avoir que 15 mots de référence, le recouvrement y est granulaire (1 mot = 6,7 points). Regarder `words_ref` par texte avant de conclure sur une langue.
- Le paramètre `language` : Whisper détecte seul, mais le forcer évite qu'une lecture française bruitée soit transcrite en portugais. Mesurer avec et sans.
- Une voix synthétique est plus propre qu'une vraie : les seuils calibrés dessus sont **optimistes**. Le §6 impose une marge, et le §7 prévoit le suivi sur vraies voix.

## 6. Critère de sortie de la boucle de calibration

Sur **positifs + négatifs + résumés hors holdout, PUIS sur le holdout**, pour le modèle et le seuil retenus, formats opus webm et aac mp4 comptés séparément :
- lectures intégrales et à 75 % : **≥ 98 % `ok`** globalement, **≥ 96 % par langue**, **≥ 96 % par format** ;
- lectures à 60 % : ≥ 90 % `ok` (on tolère une marge : c'est le cas limite) ;
- négatifs : **≥ 98 % rejetés** globalement, **100 %** pour silence, bruit seul et « autre texte de la même langue » ;
- résumés : ≥ 95 % dans le bon sens ;
- le seuil retenu laisse une **marge d'au moins 0,10** entre le pire recouvrement des positifs intégraux et le meilleur recouvrement des négatifs « autre texte » (sinon la calibration ne survivra pas aux vraies voix) ;
- coût : ≤ 0,1 ¢ US par bilan (3 lectures + 1 résumé, durées réelles mesurées sur les synthèses) ou dans l'allocation gratuite ; latence de transcription < 60 s par fichier (borne de `ctx.waitUntil`) ;
- stabilité : les mêmes chiffres à ±1 point sur **deux réveils consécutifs** (cache vidé pour 10 % des cas tirés au sort, pour vérifier que le modèle est stable).

Si aucun modèle gratuit ne tient le §6 après les avoir tous mesurés : retenir le meilleur, écrire dans le JOURNAL le critère exact qui échoue et de combien, proposer dans `FINAL.md` deux seuils (« strict » et « tolérant ») avec leurs taux, et livrer quand même le §7 avec le seuil tolérant : une personne honnête privée de résultats coûte plus cher qu'une fraude qui passe.

## 7. Livraison (après convergence, plusieurs réveils)

1. `tools/verif_lab/FINAL.md` : modèle, seuil(s), règles ajoutées, tableau des taux par langue et format, coût par bilan, ce qui reste optimiste (voix synthétiques), comment rejouer.
2. `workers/r2-upload/` : modèle et seuils dans `wrangler.toml` (`[vars]`, valeurs chaînes) et `index.js` ; toute règle nouvelle dans `_shared/text_norm.js` avec tests ; `scripts/selftest.mjs` étendu (≥ 20 assertions nouvelles : chaque variante du §3 représentée par un cas synthétique de comptes, la borne 8 Mo, la forme de réponse du nouveau modèle, `ai_error` ne bloque pas le dépôt). Si la normalisation a changé : republier la référence (`publish-corpus.mjs --dry-run` d'abord, comparer, puis pousser) et l'écrire dans FINAL.md.
3. `workers/tokeniser/` : si la calibration montre qu'un seuil par langue est nécessaire, le porter par `X-Text-Id` (le préfixe de langue est dans l'identifiant) sans changer le contrat de `/validate`.
4. **Suivi sur vraies voix** : ajouter au verdict un champ `bucket` (recouvrement arrondi au dixième) et un compteur KV par jour, langue et bucket — des comptes, jamais un mot — pour que le fondateur puisse lire la distribution réelle après les premières passations et resserrer ou desserrer le seuil. Documenter la lecture de ce compteur dans `workers/r2-upload/README.md`.
5. `wrangler deploy --dry-run` sur r2-upload (et tokeniser si touché). **Ne pas déployer.**
6. Vault : `~/obsidian-vault/Projects/Mentality/Decisions.md` (modèle retenu, seuil, règles, pourquoi), `Progress.md` ; mémoire `project_verification_vocale.md` + index. Le MCP `obsidian-vault` échoue souvent : écrire les fichiers directement.
7. Commit final sur `chantier/verification-vocale`, pousser. Puis `ScheduleWakeup stop` avec un message final : chiffres du §6, chemin de `FINAL.md`, commande de déploiement, ce qui a changé dans R2, actions fondateur.

## 8. Ce qui est interdit

- Fusionner dans `main`. Déployer. Republier la référence R2 sans `--dry-run` comparé d'abord.
- Écrire une transcription (même partielle, même d'une voix synthétique) dans un fichier suivi, un log, un verdict ou un compteur. Les seuls artefacts textuels sont des comptes et des taux.
- Éditer le corpus (`assets/reading_corpus/`), `lib/l10n/*.arb`, ou la doctrine d'anonymat des workers.
- Retirer un cas des jeux du §3 sans justification écrite dans le JOURNAL.
- Dépasser le budget d'audio du §2 ; utiliser un service de transcription tiers ou une clé qui n'est pas celle du compte Cloudflare.
- Demander une validation au fondateur avant la fin.
