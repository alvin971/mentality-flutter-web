#!/usr/bin/env python3
"""Inject es/pt/de/enGB translations into arithmetic_templates.dart.

Reads build/i18n_work/arith/<lang>.json ({"trans": [...30 strings in source
order...]}) for each language and augments every `ArithTemplate(ArithKind.x,
'fr', 'en')` constructor (matched in file order) with named params
`es:`, `pt:`, `de:`, `enGB:`. The band structure, comments and fr/en values are
left untouched. Idempotent: only the 3-argument form is matched, so re-running
after injection is a no-op.
"""
import json
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DART = os.path.join(ROOT, "lib/features/exercises_implementations/"
                    "arithmetic/domain/arithmetic_templates.dart")
WORK = os.path.join(ROOT, "build/i18n_work/arith")
LANGS = ["es", "pt", "de", "en_GB"]
PARAM = {"es": "es", "pt": "pt", "de": "de", "en_GB": "enGB"}

# Matches ArithTemplate(ArithKind.X, 'fr', 'en')  — single-quoted Dart strings.
PAT = re.compile(
    r"ArithTemplate\(\s*ArithKind\.(\w+)\s*,\s*"
    r"'((?:[^'\\]|\\.)*)'\s*,\s*'((?:[^'\\]|\\.)*)'\s*\)")


def esc(s):
    return s.replace("\\", "\\\\").replace("'", "\\'").replace("$", "\\$")


def main():
    trans = {l: json.load(open(os.path.join(WORK, f"{l}.json")))["trans"]
             for l in LANGS}
    for l in LANGS:
        if len(trans[l]) != 30:
            raise SystemExit(f"{l}: expected 30 translations, got {len(trans[l])}")

    src = open(DART, encoding="utf-8").read()
    idx = {"i": 0}

    def repl(m):
        i = idx["i"]
        idx["i"] += 1
        kind, fr, en = m.group(1), m.group(2), m.group(3)
        extra = ", ".join(
            f"{PARAM[l]}: '{esc(trans[l][i])}'" for l in LANGS)
        return f"ArithTemplate(ArithKind.{kind}, '{fr}', '{en}', {extra})"

    out = PAT.sub(repl, src)
    if idx["i"] != 30:
        raise SystemExit(f"matched {idx['i']} templates, expected 30")
    open(DART, "w", encoding="utf-8").write(out)
    print(f"Injected es/pt/de/enGB into {idx['i']} ArithTemplate constructors.")


if __name__ == "__main__":
    main()
