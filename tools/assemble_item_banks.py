#!/usr/bin/env python3
"""Assemble AI-generated JSON item banks into Dart `build<Lang>XxxBanks()` files.

The generation workflow writes one JSON file per (language, subtest, band/cell)
under build/i18n_work/items/<lang>/<subtest>/<bandkey>.json, each of the form
{"items": [ ... ]}. This script combines those, assigns the deterministic
calibration metadata (frequency / level / domain / difficulty enum + a nominal
thetaValue — NOTE the generator overrides thetaValue by slot, so it is only
informational here) and renders a Dart file matching the FR/EN bank structure.

Usage: python3 tools/assemble_item_banks.py <subtest> <lang>
  subtest ∈ {vocabulary, similarities, information}
  lang    ∈ {es, pt, de, en_GB}
"""
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ITEMS = os.path.join(ROOT, "build", "i18n_work", "items")

# Dart build-function infix + items-file suffix per language.
LANG_FN = {"es": "Spanish", "pt": "Portuguese", "de": "German", "en_GB": "British"}
LANG_FILE = {"es": "es", "pt": "pt", "de": "de", "en_GB": "en_gb"}

VOCAB_BANDS = [  # (json key, WordFrequency enum, nominal theta)
    ("veryHigh", "WordFrequency.veryHigh", -2.0),
    ("high", "WordFrequency.high", -1.0),
    ("medium", "WordFrequency.medium", 0.0),
    ("low", "WordFrequency.low", 1.0),
    ("veryLow", "WordFrequency.veryLow", 2.0),
]
SIM_LEVELS = [  # (json key, AbstractionLevel enum, nominal theta)
    ("concrete", "AbstractionLevel.concrete", -1.5),
    ("functional", "AbstractionLevel.functional", -0.5),
    ("categorical", "AbstractionLevel.categorical", 0.5),
    ("abstract", "AbstractionLevel.abstract", 1.5),
]
INFO_DOMAINS = ["science", "historyGeography", "generalCulture", "mathLogic", "artsLiterature"]
INFO_DIFF = [("easy", -2.0), ("medium", 0.0), ("hard", 2.0)]
DOMAIN_ENUM = {d: f"KnowledgeDomain.{d}" for d in INFO_DOMAINS}
DIFF_ENUM = {"easy": "DifficultyLevel.easy", "medium": "DifficultyLevel.medium",
             "hard": "DifficultyLevel.hard"}


def dq(s):
    """Dart single-quoted string literal with escaping."""
    s = str(s).replace("\\", "\\\\").replace("'", "\\'").replace("\n", " ").strip()
    return f"'{s}'"


def lst(xs):
    return "[" + ", ".join(dq(x) for x in xs) + "]"


def load(lang, subtest, key):
    p = os.path.join(ITEMS, lang, subtest, f"{key}.json")
    if not os.path.exists(p):
        raise SystemExit(f"MISSING input: {p}")
    return json.load(open(p, encoding="utf-8"))["items"]


def assemble_vocabulary(lang):
    fn = f"build{LANG_FN[lang]}VocabularyBanks"
    out = [f"/// Banque d'items du sous-test Vocabulaire — {lang} (GÉNÉRÉ par IA, "
           "vérifié). 5 bandes de fréquence. NE PAS éditer à la main.",
           "library;", "", "import 'vocabulary_generator.dart';", "",
           f"List<List<VocabularyItem>> {fn}() {{", "  return ["]
    total = 0
    for key, enum, theta in VOCAB_BANDS:
        items = load(lang, "vocabulary", key)
        out.append(f"    // {key} ({len(items)} items)")
        out.append("    [")
        for it in items:
            out.append(
                f"      VocabularyItem(word: {dq(it['word'])}, frequency: {enum}, "
                f"twoPointAnswers: {lst(it['two'])}, onePointAnswers: {lst(it['one'])}, "
                f"thetaValue: {theta}),")
            total += 1
        out.append("    ],")
    out += ["  ];", "}", ""]
    return "\n".join(out), total


def assemble_similarities(lang):
    fn = f"build{LANG_FN[lang]}SimilarityBanks"
    out = [f"/// Banque de paires du sous-test Similitudes — {lang} (GÉNÉRÉ par IA, "
           "vérifié). 4 niveaux d'abstraction. NE PAS éditer à la main.",
           "library;", "", "import 'similarities_generator.dart';", "",
           f"List<List<SimilarityItem>> {fn}() {{", "  return ["]
    total = 0
    for key, enum, theta in SIM_LEVELS:
        items = load(lang, "similarities", key)
        out.append(f"    // {key} ({len(items)} paires)")
        out.append("    [")
        for it in items:
            out.append(
                f"      SimilarityItem(word1: {dq(it['w1'])}, word2: {dq(it['w2'])}, "
                f"level: {enum}, twoPointAnswers: {lst(it['two'])}, "
                f"onePointAnswers: {lst(it['one'])}, thetaValue: {theta}),")
            total += 1
        out.append("    ],")
    out += ["  ];", "}", ""]
    return "\n".join(out), total


def assemble_information(lang):
    fn = f"build{LANG_FN[lang]}InformationBanks"
    out = [f"/// Banque de QCM du sous-test Information — {lang} (GÉNÉRÉ par IA, "
           "adapté culturellement + fact-check). 15 cellules domaine×difficulté. "
           "NE PAS éditer à la main.",
           "library;", "", "import 'information_generator.dart';", "",
           f"List<List<InformationItem>> {fn}() {{", "  return ["]
    total = 0
    for diff, theta in INFO_DIFF:
        for dom in INFO_DOMAINS:
            items = load(lang, "information", f"{diff}__{dom}")
            out.append(f"    // {diff} / {dom} ({len(items)})")
            out.append("    [")
            for it in items:
                ci = int(it["correct"])
                opts = it["options"]
                assert len(opts) == 4, f"{lang} {diff}/{dom}: need 4 options"
                assert 0 <= ci < 4, f"{lang} {diff}/{dom}: bad correct index"
                out.append(
                    f"      InformationItem(question: {dq(it['q'])}, "
                    f"options: {lst(opts)}, correctAnswer: {ci}, "
                    f"domain: {DOMAIN_ENUM[dom]}, difficulty: {DIFF_ENUM[diff]}, "
                    f"thetaValue: {theta}),")
                total += 1
            out.append("    ],")
    out += ["  ];", "}", ""]
    return "\n".join(out), total


ASSEMBLERS = {
    "vocabulary": (assemble_vocabulary, "vocabulary/domain/vocabulary_items_{f}.dart"),
    "similarities": (assemble_similarities, "similarities/domain/similarities_items_{f}.dart"),
    "information": (assemble_information, "information/domain/information_items_{f}.dart"),
}


def main():
    if len(sys.argv) != 3:
        raise SystemExit("usage: assemble_item_banks.py <subtest> <lang>")
    subtest, lang = sys.argv[1], sys.argv[2]
    fn, relpath = ASSEMBLERS[subtest]
    code, total = fn(lang)
    dest = os.path.join(ROOT, "lib", "features", "exercises_implementations",
                        relpath.format(f=LANG_FILE[lang]))
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    with open(dest, "w", encoding="utf-8") as f:
        f.write(code)
    print(f"{subtest}/{lang}: wrote {total} items -> {os.path.relpath(dest, ROOT)}")


if __name__ == "__main__":
    main()
