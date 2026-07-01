#!/usr/bin/env python3
# tools/corpus_gen/generate_corpus.py
#
# Pipeline de génération du corpus de textes de lecture (compréhension orale).
#   - Grille combinatoire (genre × domaine × ton × niveau × structure)
#   - Appel Mistral avec ROTATION de clés + BACKOFF (429/5xx)
#   - GARANTIE de longueur (compteur mots/caractères → coupe à la phrase / régénère)
#   - LEDGER : fréquence globale des mots (repère les mots sur-utilisés = tics du modèle),
#     couverture d'une liste-cible optionnelle, diversité (TTR), détection de doublons
#   - Boucle anti-répétition : les mots sur-utilisés sont BANNIS dans les prompts suivants
#   - Sortie JSONL + ledger JSON + rapport pour supervision (Opus lit l'agrégat + un échantillon)
#
# Clés : fichier ~/.claude/.mistral_keys (une clé par ligne, # = commentaire). JAMAIS dans le chat.
#
# Exemples :
#   python3 generate_corpus.py --dry-run --count 5           # inspecte les prompts, sans API
#   python3 generate_corpus.py --lang fr --count 30 --out corpus_fr.jsonl
#
# Stdlib uniquement — rien à installer.

import argparse, json, math, os, random, re, sys, time, urllib.request, urllib.error
from collections import Counter
from datetime import datetime, timezone

# ─────────────────────────── Grille (FR) ────────────────────────────────────
GENRES = [
    "explicatif / vulgarisation", "actualité / reportage", "récit / anecdote",
    "procédural / mode d'emploi", "opinion / éditorial", "dialogue rapporté (en prose)",
    "descriptif", "biographie / portrait", "critique", "lettre / message",
    "questions-réponses (FAQ en prose)", "historique",
]
DOMAINES = [
    "sciences et nature", "technologie", "santé et bien-être", "histoire",
    "voyage et géographie", "cuisine et gastronomie", "sport", "arts et culture",
    "société", "économie et travail", "éducation", "vie quotidienne",
    "environnement", "psychologie", "habitat et logement", "animaux",
    "musique", "transports", "mode et vêtements", "espace et astronomie",
]
TONS = ["neutre", "familier / conversationnel", "journalistique", "littéraire", "technique", "formel"]
NIVEAUX = ["B1", "B2"]
STRUCTURES = ["chronologique", "cause-effet", "problème-solution", "comparaison", "énumération thématique"]

# ─────────────────────────── Cibles de longueur ─────────────────────────────
CHAR_TARGET, CHAR_MIN, CHAR_MAX = 820, 780, 860
WORD_MIN, WORD_MAX = 120, 150

# ─────────────────────────── Stopwords FR (pour ne pas bannir les mots-outils) ──
STOPWORDS = set("""
le la les un une des de du d au aux à et ou mais donc or ni car en dans sur sous par
pour avec sans que qui quoi dont où ce cet cette ces son sa ses leur leurs mon ma mes
ton ta tes notre nos votre vos il elle ils elles on nous vous je tu se ne pas plus
est sont était étaient être a ont avoir fait faire comme aussi très bien peu tout tous
toute toutes cela ça y l s c j m n t qu si non oui puis alors quand comme entre vers
chaque plusieurs même autre autres ainsi cependant enfin ensuite d'abord surtout
zéro deux trois quatre cinq six sept huit neuf dix onze douze treize quatorze quinze
seize dix-sept dix-huit dix-neuf vingt trente quarante cinquante soixante quatre-vingts
cent cents mille million millions milliard milliards premier première deuxième troisième
demi demie moitié dizaine centaine millier
""".split())

# ─────────────────────────── Client Mistral (rotation + backoff) ────────────
class MistralClient:
    URL = "https://api.mistral.ai/v1/chat/completions"

    def __init__(self, keys, model):
        self.keys = list(keys)
        self.model = model
        self.i = 0
        self.disabled = set()
        self.calls = 0

    def _next_key(self):
        for _ in range(len(self.keys)):
            self.i = (self.i + 1) % len(self.keys)
            if self.i not in self.disabled:
                return self.i
        raise RuntimeError("Aucune clé Mistral valide restante.")

    def generate(self, prompt, temperature=0.9, max_tokens=600, retries=7):
        body = json.dumps({
            "model": self.model,
            "messages": [{"role": "user", "content": prompt}],
            "temperature": temperature,
            "max_tokens": max_tokens,
        }).encode()
        last_err = None
        for attempt in range(retries):
            ki = self._next_key()
            req = urllib.request.Request(self.URL, data=body, headers={
                "Authorization": f"Bearer {self.keys[ki]}",
                "Content-Type": "application/json",
            })
            try:
                with urllib.request.urlopen(req, timeout=90) as r:
                    self.calls += 1
                    data = json.loads(r.read().decode())
                return data["choices"][0]["message"]["content"].strip()
            except urllib.error.HTTPError as e:
                code = e.code
                last_err = f"HTTP {code}"
                if code in (401, 403):
                    self.disabled.add(ki)          # clé invalide → on la retire
                    continue
                if code == 429 or 500 <= code < 600:
                    sleep = min(1.5 * (2 ** attempt), 30) + random.uniform(0, 0.8)
                    time.sleep(sleep)              # backoff exponentiel + jitter, rotation de clé
                    continue
                raise
            except Exception as e:
                last_err = f"{type(e).__name__}: {e}"
                time.sleep(min(2 * (2 ** attempt), 20))
        raise RuntimeError(f"Échec après {retries} tentatives ({last_err}).")

# ─────────────────────────── Normalisation / tokenisation ───────────────────
WORD_RE = re.compile(r"[a-zA-ZàâäéèêëîïôöùûüçœæÀÂÄÉÈÊËÎÏÔÖÙÛÜÇŒÆ]+", re.UNICODE)

def tokens(text):
    return [w.lower() for w in WORD_RE.findall(text)]

def content_tokens(text):
    return [w for w in tokens(text) if w not in STOPWORDS and len(w) > 2]

SENT_RE = re.compile(r"(?<=[.!?…])\s+(?=[A-ZÀÂÄÉÈÊËÎÏÔÖÙÛÜÇ«“])")

def split_sentences(text):
    return [s.strip() for s in SENT_RE.split(text.strip()) if s.strip()]

# ─────────────────────────── Ledger (compteur global) ───────────────────────
class Ledger:
    def __init__(self, target_words=None):
        self.word_freq = Counter()      # occurrences totales par mot de contenu
        self.doc_freq = Counter()       # nb de textes contenant le mot
        self.openings = Counter()       # 3 premiers mots (repère les ouvertures répétées)
        self.seen_shingles = set()      # 5-grammes déjà vus (anti-doublon)
        self.n_texts = 0
        self.total_words = 0
        self.unique_words = set()
        self.target = set(target_words or [])
        self.covered_target = set()

    @staticmethod
    def _shingles(toks, k=5):
        return {" ".join(toks[i:i + k]) for i in range(max(0, len(toks) - k + 1))}

    def dup_ratio(self, text):
        sh = self._shingles(tokens(text))
        if not sh:
            return 0.0
        return len(sh & self.seen_shingles) / len(sh)

    def add(self, text):
        toks = tokens(text)
        ct = content_tokens(text)
        self.n_texts += 1
        self.total_words += len(toks)
        self.unique_words.update(toks)
        self.word_freq.update(ct)
        for w in set(ct):
            self.doc_freq[w] += 1
        if len(toks) >= 3:
            self.openings[" ".join(toks[:3])] += 1
        self.seen_shingles |= self._shingles(toks)
        if self.target:
            self.covered_target.update(w for w in set(toks) if w in self.target)

    def overused(self, df_ratio=0.35, top=12):
        """Mots de contenu présents dans > df_ratio des textes → à bannir dans les prompts."""
        if self.n_texts < 8:
            return []
        cap = self.n_texts * df_ratio
        ranked = sorted(((w, c) for w, c in self.doc_freq.items() if c > cap),
                        key=lambda x: -x[1])
        return [w for w, _ in ranked[:top]]

    def ttr(self):
        return len(self.unique_words) / self.total_words if self.total_words else 0.0

    def report(self):
        lines = [
            f"textes acceptés : {self.n_texts}",
            f"longueur moy : {self.total_words / self.n_texts:.0f} mots" if self.n_texts else "",
            f"diversité (TTR global) : {self.ttr():.3f}",
            f"vocabulaire unique : {len(self.unique_words)} mots",
        ]
        ov = self.overused()
        if ov:
            lines.append("sur-utilisés (bannis) : " + ", ".join(
                f"{w}({self.doc_freq[w]})" for w in ov))
        rep_open = [(o, c) for o, c in self.openings.most_common(3) if c > 1]
        if rep_open:
            lines.append("ouvertures répétées : " + ", ".join(f"«{o}…»×{c}" for o, c in rep_open))
        if self.target:
            pct = 100 * len(self.covered_target) / len(self.target)
            lines.append(f"couverture liste-cible : {pct:.1f}% ({len(self.covered_target)}/{len(self.target)})")
        return "\n".join(l for l in lines if l)

    def dump(self, path):
        json.dump({
            "n_texts": self.n_texts, "ttr": self.ttr(),
            "word_freq": dict(self.word_freq.most_common(500)),
            "doc_freq": dict(self.doc_freq.most_common(500)),
            "covered_target": sorted(self.covered_target),
        }, open(path, "w", encoding="utf-8"), ensure_ascii=False, indent=2)

# ─────────────────────────── Construction du prompt ─────────────────────────
def build_prompt(spec, banned, target_hint):
    genre, domaine, ton, niveau, structure = spec
    p = [
        f"Rédige UN texte en français, de type « {genre} », sur le thème « {domaine} », "
        f"ton {ton}, niveau {niveau}, structure {structure}.",
        "Contraintes STRICTES :",
        f"- longueur : {WORD_MIN + 5} à {WORD_MAX - 5} mots (environ {CHAR_TARGET} caractères) ;",
        "- texte COHÉRENT et AUTONOME, compréhensible sans aucun contexte extérieur ;",
        "- écris tous les nombres en toutes lettres ; aucune abréviation, sigle, symbole ni adresse web ;",
        "- pas de titre, pas de guillemets englobants, aucun commentaire ;",
        "- ne commence pas par une formule générique du type « Les X jouent un rôle essentiel ».",
    ]
    if banned:
        p.append("- évite soigneusement ces mots (déjà trop employés ailleurs) : " + ", ".join(banned) + ".")
    if target_hint:
        p.append("- emploie NATURELLEMENT ces mots : " + ", ".join(target_hint) + ".")
    p.append("Réponds UNIQUEMENT par le texte.")
    return "\n".join(p)

# ─────────────────────────── Validation de longueur ─────────────────────────
def enforce_length(text):
    """Retourne (texte_ajusté, ok). Coupe à la dernière phrase si trop long ;
    signale trop court (à régénérer)."""
    if len(text) <= CHAR_MAX and len(tokens(text)) <= WORD_MAX and len(tokens(text)) >= WORD_MIN:
        return text, True
    if len(text) < CHAR_MIN or len(tokens(text)) < WORD_MIN:
        return text, False                      # trop court → régénérer
    # trop long → on garde le maximum de phrases entières sous la cible
    sents, acc = split_sentences(text), ""
    for s in sents:
        cand = (acc + " " + s).strip()
        if len(cand) > CHAR_MAX and len(acc) >= CHAR_MIN:
            break
        acc = cand
    ok = CHAR_MIN <= len(acc) <= CHAR_MAX and WORD_MIN <= len(tokens(acc)) <= WORD_MAX
    return acc, ok

def constraint_flags(text):
    flags = []
    if re.search(r"\d", text):
        flags.append("chiffres")
    if re.search(r"\b(M\.|Mme|etc\.|cf\.|p\.ex\.|www\.|http)", text) or re.search(r"[%€$@]", text):
        flags.append("abréviation/symbole")
    return flags

# ─────────────────────────── Chargement des clés ────────────────────────────
def load_keys(path):
    path = os.path.expanduser(path)
    if not os.path.exists(path):
        return []
    out = []
    for line in open(path, encoding="utf-8"):
        s = line.strip()
        if s and not s.startswith("#"):
            out.append(s)
    return out

def load_target(path):
    if not path or not os.path.exists(path):
        return []
    return [w.strip().lower() for w in open(path, encoding="utf-8") if w.strip() and not w.startswith("#")]

def load_existing(out_path, ledger):
    """Reprise : réinjecte les textes déjà générés dans le ledger (couverture cumulative)."""
    if not os.path.exists(out_path):
        return 0
    n = 0
    for line in open(out_path, encoding="utf-8"):
        try:
            rec = json.loads(line)
            ledger.add(rec["text"]); n += 1
        except Exception:
            pass
    return n

# ─────────────────────────── Orchestrateur ──────────────────────────────────
def sample_spec(i):
    # rotation des genres/domaines pour un balayage régulier + aléatoire sur le reste
    return (GENRES[i % len(GENRES)], DOMAINES[(i * 7) % len(DOMAINES)],
            random.choice(TONS), random.choice(NIVEAUX), random.choice(STRUCTURES))

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--lang", default="fr")
    ap.add_argument("--count", type=int, default=30)
    ap.add_argument("--out", default="corpus_fr.jsonl")
    ap.add_argument("--model", default=os.environ.get("MISTRAL_MODEL", "mistral-large-latest"))
    ap.add_argument("--keys-file", default="~/.claude/.mistral_keys")
    ap.add_argument("--target-words", default="")
    ap.add_argument("--report-every", type=int, default=10)
    ap.add_argument("--max-regen", type=int, default=2)
    ap.add_argument("--dry-run", action="store_true", help="affiche les prompts sans appeler l'API")
    args = ap.parse_args()

    ledger = Ledger(load_target(args.target_words))
    resumed = load_existing(args.out, ledger)
    if resumed:
        print(f"Reprise : {resumed} textes existants réinjectés dans le ledger.")

    if args.dry_run:
        for i in range(args.count):
            print("\n" + "=" * 72)
            print(build_prompt(sample_spec(i), ledger.overused(), []))
        return

    keys = load_keys(args.keys_file)
    if not keys:
        print(f"ERREUR : aucune clé dans {args.keys_file} (une par ligne).", file=sys.stderr)
        sys.exit(1)
    client = MistralClient(keys, args.model)
    print(f"Modèle={args.model} | clés={len(keys)} | cible={args.count} textes | sortie={args.out}")

    out = open(args.out, "a", encoding="utf-8")
    accepted, rejected_dup, rejected_len, i = 0, 0, 0, resumed
    while accepted < args.count:
        spec = sample_spec(i); i += 1
        banned = ledger.overused()
        prompt = build_prompt(spec, banned, [])
        text, ok = None, False
        for _ in range(args.max_regen + 1):
            try:
                raw = client.generate(prompt)
            except Exception as e:
                print(f"  ! génération échouée : {e}"); break
            text, ok = enforce_length(raw)
            if ok:
                break
            prompt = build_prompt(spec, banned, []) + "\n(La version précédente n'était pas dans la bonne longueur : vise strictement 130 mots.)"
        if not text or not ok:
            rejected_len += 1; continue
        if ledger.dup_ratio(text) > 0.5:
            rejected_dup += 1; continue
        rec = {
            "id": f"{args.lang}_{i:06d}", "lang": args.lang,
            "genre": spec[0], "domaine": spec[1], "ton": spec[2],
            "niveau": spec[3], "structure": spec[4],
            "chars": len(text), "words": len(tokens(text)),
            "flags": constraint_flags(text), "model": args.model,
            "ts": datetime.now(timezone.utc).isoformat(), "text": text,
        }
        out.write(json.dumps(rec, ensure_ascii=False) + "\n"); out.flush()
        ledger.add(text); accepted += 1
        if accepted % args.report_every == 0:
            print(f"\n──── Rapport ({accepted}/{args.count}) ────")
            print(ledger.report())
            print(f"rejetés : {rejected_len} (longueur), {rejected_dup} (doublon) | appels API : {client.calls}")

    out.close()
    ledger.dump(args.out.replace(".jsonl", "") + ".ledger.json")
    print("\n" + "=" * 72 + "\nTERMINÉ\n" + ledger.report())
    print(f"rejetés : {rejected_len} (longueur), {rejected_dup} (doublon) | appels API : {client.calls}")
    print(f"corpus → {args.out} | ledger → {args.out.replace('.jsonl','')}.ledger.json")

if __name__ == "__main__":
    main()
