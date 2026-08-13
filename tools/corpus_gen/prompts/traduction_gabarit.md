# Prompt de réécriture native — gabarit commun aux cinq langues cibles

> Ce n'est **pas** une traduction. C'est ce qu'un locuteur natif **aurait écrit** pour dire
> exactement la même chose. Le fond est gelé, la surface est libre.

---

## Ta mission

Tu reçois un texte source français et la liste **gelée** de ses unités d'information. Tu réécris
ce contenu en `{langue}`, comme si tu l'avais conçu directement dans cette langue.

Le sujet lira ta version à voix haute (enregistrée), puis la résumera de mémoire (enregistrée).
Six langues portent le même contenu : c'est ce qui rend les enregistrements comparables. Si tu
ajoutes, retires ou déplaces une information, tu casses la comparaison.

---

## Ce qui est GELÉ — tu n'y touches pas

1. **Les unités d'information** `{unites}` : toutes présentes, aucune ajoutée, aucune retirée,
   **dans le même ordre**. C'est vérifié automatiquement, unité par unité.
2. **Le genre, le ton, le niveau (B1/B2) et la structure rhétorique** du texte source.
3. **L'absence totale d'ancrage culturel.** Le source n'en contient aucun ; ta version ne doit en
   introduire aucun. Interdits : nom propre de personne, de lieu, d'organisation ou d'œuvre ;
   monnaie ; unité de mesure locale ; fête, plat, sport, institution, système scolaire ou loi d'un
   pays ; époque nommée ; référence religieuse. Les personnes restent désignées par leur rôle, les
   lieux par leur type.
   ⚠️ C'est le piège numéro un de la réécriture native : en cherchant le naturel, on localise. Une
   image « qui parlerait à un lecteur d'ici » est exactement ce qu'il ne faut pas faire.
4. **Aucun chiffre.** Les rares nombres restent en toutes lettres et simples.
5. **Aucun jeu de mots, rime, proverbe ou expression idiomatique figée** — ni dans le source, ni
   dans ta version.

---

## Ce qui est LIBRE — et doit obligatoirement l'être

Le lexique, la syntaxe, l'ordre des mots dans la phrase, le découpage des phrases, le rythme, les
images concrètes, la ponctuation. **Tu dois t'écarter de la structure française.** Une phrase qui
suit servilement l'ordre du français est un échec, même si elle est grammaticalement correcte.

Interdictions explicites :

- ne traduis pas mot à mot, même quand c'est possible ;
- n'améliore pas le texte source, ne l'explique pas, ne l'enjolive pas, n'ajoute aucune précision
  qui n'y est pas ;
- ne conserve pas un connecteur français par réflexe : chaque langue a ses propres charnières ;
- ne calque pas la longueur des phrases : coupe ou fusionne selon ce qui est naturel chez toi.

---

## Longueur

**780 à 900 caractères**, espaces comprises — soit environ `{bande_mots}`.

L'invariant du corpus est le caractère, pas le mot, parce que c'est le **temps de lecture à voix
haute** qui doit être comparable entre les six langues. Compte tes caractères exactement.

---

## Richesse lexicale

Le corpus vise la couverture maximale du vocabulaire de **ta** langue, pas seulement du français.

- Préfère systématiquement le mot précis au mot passe-partout.
- Évite la liste `{bannis_langue_cible}` : ces mots sont déjà sur-utilisés dans le corpus de ta
  langue.
- Ne réutilise pas la même charnière ni la même construction d'un texte à l'autre dans un lot.

---

## Spécificités de ta langue

`{bloc_specificites}`

### Pièges de calque depuis le français

`{pieges_calque}`

### À bannir d'office — signatures d'une traduction du français

`{a_bannir}`

---

## Format de sortie

Une ligne JSON par texte, dans un fichier JSONL — pas de tableau englobant, pas de bloc de code.

```
{"family":"fam_00001","id":"<lang>_00001","lang":"<lang>","source_lang":"fr","genre":"...","domaine":"...","niveau":"B1","structure":"...","chars":842,"words":131,"units":[...],"text":"..."}
```

- `family` **identique à celle du source** : c'est la clé qui relie les six langues.
- `units` : reprends les unités du source **traduites dans ta langue**, même nombre, même ordre.
- `chars` : longueur exacte de `text`, entre 780 et 900.
- `text` : une seule ligne, sans retour à la ligne interne.

---

## Avant de rendre — ta propre vérification

1. Chaque unité gelée est-elle présente ? En ai-je ajouté une sans m'en rendre compte ?
2. L'ordre des unités est-il conservé ?
3. Ai-je introduit un nom propre, un chiffre, une monnaie, une référence culturelle ?
4. Chaque texte fait-il entre 780 et 900 caractères ? (compte, ne devine pas)
5. Relis à voix haute : est-ce qu'un natif aurait écrit **cette** phrase, ou est-ce qu'on sent le
   français derrière ?
6. Ai-je laissé passer un des pièges de calque listés plus haut ?
