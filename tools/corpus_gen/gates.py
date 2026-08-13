#!/usr/bin/env python3
# tools/corpus_gen/gates.py
#
# Gardes déterministes du corpus v2 (compréhension orale, six langues alignées).
#
# Ce que ce script fait, sans appeler aucun modèle :
#   - valide chaque texte d'un lot (longueur en CARACTÈRES, chiffres, symboles,
#     noms propres présumés, ancrages culturels d'une liste noire, unités
#     d'information, intégrité des champs) ;
#   - détecte les doublons entre textes d'une même langue (5-grammes) ;
#   - tient le LEDGER lexical de la langue : formes uniques, TTR, mots
#     sur-utilisés — c'est cette sortie qui alimente la liste {bannis} de la
#     vague suivante, donc la richesse lexicale du corpus entier ;
#   - assemble les lots validés en un corpus final.
#
# La bande de longueur porte sur les CARACTÈRES et non sur les mots : le texte
# est lu à voix haute, c'est le temps de lecture qui doit être comparable d'une
# langue à l'autre. L'allemand compose, l'espagnol dilue ; compter les mots
# rendrait les enregistrements incomparables.
#
# Usage :
#   python3 gates.py --lang fr --in tools/corpus_gen/out/fr            # rapport
#   python3 gates.py --lang fr --in tools/corpus_gen/out/fr --assemble assets/reading_corpus/v2/fr.jsonl
#   python3 gates.py --lang de --in tools/corpus_gen/out/de --source assets/reading_corpus/v2/fr.jsonl
#
# Stdlib uniquement.

import argparse
import json
import os
import re
import sys
import unicodedata
from collections import Counter

CHAR_MIN, CHAR_MAX = 780, 900
UNITS_MIN, UNITS_MAX = 6, 10

# L'allemand met une majuscule à tous les noms communs : l'heuristique de
# majuscule y est inutilisable, la traque des noms propres y repose sur la
# liste noire et sur l'agent vérificateur.
CAPITALIZATION_IS_MEANINGFUL = {"fr": True, "en": True, "en_GB": True, "es": True, "pt": True, "de": False}

# ─────────────────── Liste noire d'ancrages culturels ───────────────────────
# Non exhaustive par construction : elle attrape le gros des fuites, l'agent
# chasseur d'ancrages attrape le reste (climat, faune, habitudes de vie).
BLOCKLIST = {
    "pays_villes": """
        france français française francais paris lyon marseille bordeaux toulouse lille nantes
        strasbourg montpellier bretagne provence normandie alsace corse aquitaine
        allemagne allemand allemande berlin munich hambourg cologne francfort bavière
        espagne espagnol espagnole madrid barcelone séville andalousie catalogne
        portugal portugais portugaise lisbonne algarve madère açores
        angleterre anglais anglaise londres manchester liverpool oxford cambridge écosse
        royaume-uni grande-bretagne irlande galles édimbourg dublin
        italie italien italienne rome venise florence naples toscane sicile
        états-unis américain américaine amérique new york washington californie texas floride
        chicago boston seattle canada québec montréal toronto vancouver mexique mexico
        brésil brasilia rio argentine buenos chili pérou colombie
        chine chinois chinoise pékin shanghai japon japonais tokyo kyoto corée séoul
        inde indien delhi bombay russie russe moscou saint-pétersbourg ukraine kiev
        pologne varsovie suède stockholm norvège oslo danemark copenhague finlande helsinki
        pays-bas amsterdam belgique bruxelles suisse genève zurich autriche
        grèce athènes turquie istanbul égypte caire maroc rabat casablanca algérie alger
        tunisie tunis sénégal dakar afrique australie sydney melbourne
        europe européen européenne asie asiatique africain méditerranée atlantique
        alpes pyrénées himalaya andes sahara amazonie danube rhin loire
        londonien parisien new-yorkais
        germany german berlin spain spanish madrid england english london america american
        alemania alemán españa español inglaterra inglés estados unidos
        alemanha alemão espanha espanhol inglaterra inglês
        deutschland deutsch frankreich französisch spanien spanisch england englisch
        """,
    # Attention : n'inscrire ici que des termes SANS homonyme courant. « livre »
    # (ouvrage), « pied », « pouce », « cent », « franc » sont des mots français
    # ordinaires : les bannir noierait les vraies fuites sous les faux positifs.
    "monnaies_mesures": """
        euro euros dollar dollars sterling peso pesos yen yuan roupie
        centime centimes penny pence
        fahrenheit
        """,
    "institutions_fetes": """
        noël pâques toussaint ramadan hanouka thanksgiving halloween
        baccalauréat lycée sorbonne préfet préfecture
        église cathédrale mosquée synagogue chrétien musulman juive bouddhiste
        catholique protestant orthodoxe dieu bible coran messe
        olympique olympiques
        google facebook amazon apple microsoft twitter instagram youtube netflix
        """,
    "epoques": """
        renaissance antiquité préhistoire néolithique paléolithique
        romain romaine gaulois gauloise viking vikings celte celtes
        """,
}


def _norm(w):
    """minuscule + suppression des diacritiques, pour comparer sans accent."""
    w = w.lower()
    return "".join(c for c in unicodedata.normalize("NFD", w) if unicodedata.category(c) != "Mn")


BLOCKED = set()
for _bloc in BLOCKLIST.values():
    for _w in _bloc.split():
        BLOCKED.add(_norm(_w))

WORD_RE = re.compile(r"[^\W\d_]+(?:['’-][^\W\d_]+)*", re.UNICODE)
DIGIT_RE = re.compile(r"\d")
SYMBOL_RE = re.compile(r"[%€$£¥@#&*_<>\[\]{}|\\/]|https?://|www\.")
ABBREV_RE = re.compile(r"\b(?:M\.|Mme|Mlle|Dr\.|St\.|etc\.|cf\.|p\.\s?ex\.|ex\.|vs\.?|i\.e\.|e\.g\.)", re.I)
# Début de phrase : début de texte, ou après . ! ? … suivi d'une espace,
# ou après un guillemet ouvrant.
SENT_START_RE = re.compile(r"(?:^|[.!?…]\s+|[«\"“]\s*)")


def tokens(text):
    return [w.lower() for w in WORD_RE.findall(text)]


def content_tokens(text, stop):
    return [w for w in tokens(text) if w not in stop and len(w) > 3]


def shingles(toks, k=5):
    return {" ".join(toks[i:i + k]) for i in range(max(0, len(toks) - k + 1))}


def sentence_initial_offsets(text):
    """Positions de caractères où un mot est légitimement en majuscule."""
    offs = set()
    for m in SENT_START_RE.finditer(text):
        offs.add(m.end())
    offs.add(0)
    return offs


def presumed_proper_nouns(text, lang):
    """Mots capitalisés hors début de phrase — heuristique inopérante en allemand."""
    if not CAPITALIZATION_IS_MEANINGFUL.get(lang, True):
        return []
    starts = sentence_initial_offsets(text)
    out = []
    for m in WORD_RE.finditer(text):
        w = m.group(0)
        if not w[0].isupper():
            continue
        if m.start() in starts:
            continue
        # « je » anglais et pronom allemand mis à part, un mot capitalisé au
        # milieu d'une phrase est un nom propre présumé.
        if w in ("I",):
            continue
        out.append(w)
    return out


def blocked_terms(text):
    hits = []
    for w in WORD_RE.findall(text):
        if _norm(w) in BLOCKED:
            hits.append(w)
    return hits


def check_text(rec, lang, corpus_shingles=None, banned=()):
    """Retourne la liste des violations d'un enregistrement. Vide = accepté."""
    v = []
    text = (rec.get("text") or "").strip()

    if not text:
        return ["texte vide"]
    for champ in ("family", "id", "lang", "genre", "domaine", "niveau", "structure", "units", "text"):
        if champ not in rec:
            v.append(f"champ manquant : {champ}")
    if rec.get("lang") != lang:
        v.append(f"lang={rec.get('lang')} attendu {lang}")

    n = len(text)
    if n < CHAR_MIN or n > CHAR_MAX:
        v.append(f"longueur {n} hors bande {CHAR_MIN}-{CHAR_MAX}")
    if "\n" in text or "\r" in text:
        v.append("retour à la ligne dans le texte")
    if text[0] in "«\"“'" and text[-1] in "»\"”'":
        v.append("texte entouré de guillemets englobants")

    if DIGIT_RE.search(text):
        v.append("chiffre : " + ", ".join(sorted(set(DIGIT_RE.findall(text)))))
    if SYMBOL_RE.search(text):
        v.append("symbole ou adresse : " + SYMBOL_RE.search(text).group(0))
    if ABBREV_RE.search(text):
        v.append("abréviation : " + ABBREV_RE.search(text).group(0))

    pn = presumed_proper_nouns(text, lang)
    if pn:
        v.append("nom propre présumé : " + ", ".join(sorted(set(pn))[:6]))
    bt = blocked_terms(text)
    if bt:
        v.append("ancrage culturel : " + ", ".join(sorted(set(bt))[:6]))

    units = rec.get("units") or []
    if not isinstance(units, list):
        v.append("units n'est pas une liste")
    else:
        if not (UNITS_MIN <= len(units) <= UNITS_MAX):
            v.append(f"{len(units)} unités (attendu {UNITS_MIN}-{UNITS_MAX})")
        for u in units:
            if not isinstance(u, str) or len(u.split()) < 3:
                v.append(f"unité trop courte ou invalide : {u!r}")
                break

    low = _norm(text)
    used = [b for b in banned if _norm(b) in low]
    if used:
        v.append("mots bannis employés : " + ", ".join(used[:6]))

    if corpus_shingles is not None:
        sh = shingles(tokens(text))
        if sh:
            ratio = len(sh & corpus_shingles) / len(sh)
            if ratio > 0.5:
                v.append(f"doublon ({ratio:.0%} de 5-grammes déjà vus)")

    return v


# ─────────────────────────── Ledger lexical ─────────────────────────────────
STOP_FR = set("""
le la les un une des de du au aux à et ou mais donc or ni car en dans sur sous par pour avec
sans que qui quoi dont où ce cet cette ces son sa ses leur leurs mon ma mes ton ta tes notre
nos votre vos il elle ils elles on nous vous je tu se ne pas plus est sont était étaient être
a ont avoir fait faire comme aussi très bien peu tout tous toute toutes cela ça y qu si non oui
puis alors quand entre vers chaque plusieurs même autre autres ainsi cependant enfin ensuite
abord surtout deux trois quatre cinq six sept huit neuf dix cent mille avait avaient soit sera
seront été peut peuvent doit doivent va vont dit disent leur lui eux dès lors afin puisque
tandis ici là bas haut après avant pendant depuis jusque encore déjà toujours jamais souvent
parfois presque trop moins mieux vite loin près sous sur dans
""".split())


class Ledger:
    def __init__(self, stop=None):
        self.stop = stop or STOP_FR
        self.word_freq = Counter()
        self.doc_freq = Counter()
        self.openings = Counter()
        self.shingles = set()
        self.n = 0
        self.total = 0
        self.uniq = set()

    def add(self, text):
        toks = tokens(text)
        self.n += 1
        self.total += len(toks)
        self.uniq.update(toks)
        ct = content_tokens(text, self.stop)
        self.word_freq.update(ct)
        for w in set(ct):
            self.doc_freq[w] += 1
        if len(toks) >= 3:
            self.openings[" ".join(toks[:3])] += 1
        self.shingles |= shingles(toks)

    def overused(self, df_ratio=0.08, top=40):
        if self.n < 20:
            return []
        cap = self.n * df_ratio
        ranked = sorted(((w, c) for w, c in self.doc_freq.items() if c > cap), key=lambda x: -x[1])
        return [w for w, _ in ranked[:top]]

    def ttr(self):
        return len(self.uniq) / self.total if self.total else 0.0

    def report(self):
        lines = [
            f"textes            : {self.n}",
            f"mots              : {self.total}",
            f"formes uniques    : {len(self.uniq)}",
            f"diversité (TTR)   : {self.ttr():.3f}",
        ]
        if self.n:
            hap = sum(1 for w, c in self.word_freq.items() if c == 1)
            lines.append(f"hapax             : {hap} ({100 * hap / max(1, len(self.word_freq)):.0f} % du vocabulaire de contenu)")
        rep = [(o, c) for o, c in self.openings.most_common(5) if c > 1]
        if rep:
            lines.append("ouvertures répétées : " + ", ".join(f"«{o}…»×{c}" for o, c in rep))
        ov = self.overused()
        if ov:
            lines.append("sur-utilisés (à bannir à la vague suivante) : " + ", ".join(ov[:20]))
        return "\n".join(lines)


# ─────────────────────────── Entrées / sorties ──────────────────────────────
def load_batches(path):
    """Charge un fichier .jsonl ou tous les .jsonl d'un dossier."""
    files = []
    if os.path.isdir(path):
        files = sorted(os.path.join(path, f) for f in os.listdir(path) if f.endswith(".jsonl"))
    elif os.path.exists(path):
        files = [path]
    recs = []
    for f in files:
        for ln, line in enumerate(open(f, encoding="utf-8"), 1):
            line = line.strip()
            if not line:
                continue
            try:
                rec = json.loads(line)
                rec["_src"] = f"{os.path.basename(f)}:{ln}"
                recs.append(rec)
            except json.JSONDecodeError as e:
                print(f"  ! JSON invalide {os.path.basename(f)}:{ln} — {e}", file=sys.stderr)
    return recs, files


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--lang", required=True)
    ap.add_argument("--in", dest="inp", required=True, help="fichier .jsonl ou dossier de lots")
    ap.add_argument("--assemble", default="", help="écrit le corpus validé à ce chemin")
    ap.add_argument("--banned", default="", help="fichier de mots bannis (un par ligne)")
    ap.add_argument("--source", default="", help="corpus source pour vérifier l'alignement des familles")
    ap.add_argument("--emit-banned", default="", help="écrit la liste des sur-utilisés pour la vague suivante")
    ap.add_argument("--quiet", action="store_true")
    args = ap.parse_args()

    banned = []
    if args.banned and os.path.exists(args.banned):
        banned = [w.strip() for w in open(args.banned, encoding="utf-8") if w.strip() and not w.startswith("#")]

    recs, files = load_batches(args.inp)
    if not recs:
        print(f"Aucun texte trouvé dans {args.inp}", file=sys.stderr)
        sys.exit(1)

    ledger = Ledger()
    ok, ko = [], []
    seen_family = {}
    for rec in recs:
        v = check_text(rec, args.lang, ledger.shingles, banned)
        fam = rec.get("family")
        if fam in seen_family:
            v.append(f"famille dupliquée (déjà vue en {seen_family[fam]})")
        if v:
            ko.append((rec, v))
        else:
            seen_family[fam] = rec.get("_src")
            ledger.add(rec["text"])
            ok.append(rec)

    print(f"═══ Gardes — {args.lang} — {len(files)} lot(s), {len(recs)} textes ═══")
    print(f"acceptés : {len(ok)}   rejetés : {len(ko)}")
    if ko and not args.quiet:
        motifs = Counter()
        for _, v in ko:
            for x in v:
                motifs[x.split(":")[0].split("(")[0].strip()] += 1
        print("\nmotifs de rejet :")
        for m, c in motifs.most_common():
            print(f"  {c:4}  {m}")
        print("\nles dix premiers rejets :")
        for rec, v in ko[:10]:
            print(f"  {rec.get('_src','?'):24} {rec.get('id','?'):14} → {' | '.join(v)}")

    print("\n─── Ledger lexical ───")
    print(ledger.report())

    if args.source:
        src = {json.loads(l)["family"] for l in open(args.source, encoding="utf-8") if l.strip()}
        got = {r["family"] for r in ok}
        manquantes = src - got
        intruses = got - src
        print(f"\nalignement : {len(got & src)}/{len(src)} familles couvertes")
        if manquantes:
            print(f"  familles manquantes ({len(manquantes)}) : {sorted(manquantes)[:10]}")
        if intruses:
            print(f"  familles hors source ({len(intruses)}) : {sorted(intruses)[:10]}")

    if args.emit_banned:
        with open(args.emit_banned, "w", encoding="utf-8") as f:
            f.write("\n".join(ledger.overused()) + "\n")
        print(f"\nbannis pour la vague suivante → {args.emit_banned}")

    if args.assemble:
        os.makedirs(os.path.dirname(args.assemble) or ".", exist_ok=True)
        with open(args.assemble, "w", encoding="utf-8") as f:
            for rec in sorted(ok, key=lambda r: r["family"]):
                rec.pop("_src", None)
                f.write(json.dumps(rec, ensure_ascii=False) + "\n")
        print(f"corpus assemblé → {args.assemble} ({len(ok)} textes)")

    sys.exit(0 if not ko else 2)


if __name__ == "__main__":
    main()
