#!/usr/bin/env python3
# tools/corpus_gen/publish.py
#
# Publie le corpus v2 vers les assets chargés par l'app.
#
#   assets/reading_corpus/v2/<lang>.jsonl   (source, identifiants naturels)
#        → assets/reading_corpus/<lang>.jsonl   (publié, identifiants estampillés)
#
# POURQUOI ESTAMPILLER LES IDENTIFIANTS
# Le corpus v1 et le corpus v2 partagent 493 identifiants (`fr_00123` existe dans
# les deux, sur des textes complètement différents). Or l'app envoie le `text_id`
# du texte lu dans les métadonnées de l'enregistrement audio (`X-Text-Id`). Sans
# marquage, tout enregistrement déjà collecté deviendrait inattribuable : on ne
# saurait plus quel texte a été lu.
#
# On estampille donc la révision DANS l'identifiant : `fr_00123` → `fr_v2_00123`.
# Le worker R2 ne conserve que [a-zA-Z0-9_-] : la forme passe intacte. Aucune
# nouvelle en-tête HTTP n'est nécessaire, donc ni déploiement de worker, ni
# élargissement de la liste CORS — l'app peut partir en build immédiatement.
#
# Le champ `family` reste tel quel : c'est lui qui relie les six langues.
#
# Usage :
#   python3 tools/corpus_gen/publish.py            # publie
#   python3 tools/corpus_gen/publish.py --dry-run  # montre sans écrire

import argparse
import json
import os
import sys

REV = "v2"
LANGS = ["fr", "en", "en_GB", "es", "pt", "de"]
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = os.path.join(ROOT, "assets", "reading_corpus", REV)
DST = os.path.join(ROOT, "assets", "reading_corpus")


def stamp(rec_id, lang):
    """fr_00123 → fr_v2_00123 (idempotent)."""
    marqueur = f"{lang}_{REV}_"
    if rec_id.startswith(marqueur):
        return rec_id
    prefixe = f"{lang}_"
    reste = rec_id[len(prefixe):] if rec_id.startswith(prefixe) else rec_id
    return f"{marqueur}{reste}"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    familles_par_langue = {}
    total = 0

    for lang in LANGS:
        src = os.path.join(SRC, f"{lang}.jsonl")
        if not os.path.exists(src):
            print(f"ERREUR : {src} absent", file=sys.stderr)
            sys.exit(1)

        rows = [json.loads(l) for l in open(src, encoding="utf-8") if l.strip()]
        for r in rows:
            r["id"] = stamp(r["id"], lang)
            r["rev"] = REV
        rows.sort(key=lambda r: r["family"])

        familles_par_langue[lang] = {r["family"] for r in rows}
        total += len(rows)

        dst = os.path.join(DST, f"{lang}.jsonl")
        if args.dry_run:
            print(f"{lang:6} {len(rows):5} textes → {dst}  (ex. {rows[0]['id']})")
            continue
        with open(dst, "w", encoding="utf-8") as f:
            for r in rows:
                f.write(json.dumps(r, ensure_ascii=False) + "\n")
        print(f"{lang:6} {len(rows):5} textes → assets/reading_corpus/{lang}.jsonl  (ex. {rows[0]['id']})")

    # L'alignement est la raison d'être du corpus : on refuse de publier un jeu
    # de fichiers où une langue ne couvrirait pas exactement les mêmes familles.
    ref = familles_par_langue[LANGS[0]]
    for lang in LANGS[1:]:
        if familles_par_langue[lang] != ref:
            manque = len(ref - familles_par_langue[lang])
            trop = len(familles_par_langue[lang] - ref)
            print(f"\nERREUR : {lang} n'est pas aligné sur fr "
                  f"({manque} famille(s) manquante(s), {trop} en trop). Publication refusée.",
                  file=sys.stderr)
            sys.exit(2)

    print(f"\n{len(ref)} familles alignées sur {len(LANGS)} langues — {total} textes publiés.")


if __name__ == "__main__":
    main()
