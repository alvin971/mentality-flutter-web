#!/usr/bin/env python3
"""Merge l10n_fragments/*.json into one ARB file per language in lib/l10n/.

Source of truth = the fragments (each key carries at least `fr` and `en`).
Translations for the additional languages (es, pt, de, en_GB) live in flat
OVERLAY files `l10n_fragments/translations/<lang>.json` ({"keyName": "..."}),
so producing a language is a single self-contained file. A key may also be
translated inline inside a fragment (e.g. {"key": {"fr":..,"en":..,"es":..}});
inline values win over the overlay.

Resolution per (key, language): inline fragment value -> overlay value ->
fallback en -> fallback fr. The fallback guarantees the app always compiles
while a language is partially translated. Metadata (@key: description /
placeholders) is written ONLY in the template (app_fr.arb). An "untranslated"
report per language is printed and written to build/l10n_untranslated_<lang>.txt.

Run after editing any fragment or overlay, then `flutter gen-l10n`.
"""
import json
import glob
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FRAG_DIR = os.path.join(ROOT, "l10n_fragments")
TRANS_DIR = os.path.join(FRAG_DIR, "translations")
OUT_DIR = os.path.join(ROOT, "lib", "l10n")

# Languages to generate. "fr" is the template and carries @ metadata.
# The ARB file/locale code for British English is "en_GB" (file app_en_GB.arb).
LANGS = ["fr", "en", "es", "pt", "de", "en_GB"]
TEMPLATE = "fr"
# Languages whose translations may come from an overlay file.
OVERLAY_LANGS = ["es", "pt", "de", "en_GB"]
# Fallback chain applied when a language has no translation for a key.
FALLBACK = ["en", "fr"]


def load(p):
    with open(p, encoding="utf-8") as f:
        return json.load(f)


def load_overlay(lang):
    p = os.path.join(TRANS_DIR, f"{lang}.json")
    return load(p) if os.path.exists(p) else {}


def value_for(entry, key, lang, overlays):
    """Resolve (value, translated) for one key/language with fallback."""
    val = entry.get(lang)
    if isinstance(val, str) and val != "":
        return val, True
    ov = overlays.get(lang, {}).get(key)
    if isinstance(ov, str) and ov != "":
        return ov, True
    for fb in FALLBACK:
        v = entry.get(fb)
        if isinstance(v, str) and v != "":
            return v, False
    for v in entry.values():  # last resort: any string present
        if isinstance(v, str) and v != "":
            return v, False
    return "", False


def main():
    overlays = {lang: load_overlay(lang) for lang in OVERLAY_LANGS}
    merged = {lang: {"@@locale": lang} for lang in LANGS}
    untranslated = {lang: [] for lang in LANGS}
    seen = {}  # key -> fr text, for collision detection
    collisions = []
    added = 0

    # base.json holds the lead UI keys; emit it first, then the rest A→Z.
    paths = [p for p in sorted(glob.glob(os.path.join(FRAG_DIR, "*.json")))
             if not os.path.basename(p).startswith("_")]
    paths.sort(key=lambda p: (os.path.basename(p) != "base.json", p))

    all_keys = set()
    for path in paths:
        frag = load(path)
        for key, entry in frag.items():
            if not key or key == "maCle" or key.startswith("@"):
                continue
            all_keys.add(key)
            fr_text = entry.get("fr", entry.get("en", ""))
            if key in seen:
                if seen[key] != fr_text:
                    collisions.append((key, os.path.basename(path)))
                continue
            seen[key] = fr_text
            for lang in LANGS:
                value, translated = value_for(entry, key, lang, overlays)
                merged[lang][key] = value
                if lang != TEMPLATE and not translated:
                    untranslated[lang].append(key)
            placeholders = entry.get("placeholders")
            desc = entry.get("desc", "")
            if placeholders or desc:
                meta = {}
                if desc:
                    meta["description"] = desc
                if placeholders:
                    meta["placeholders"] = {
                        name: {"type": ptype} for name, ptype in placeholders.items()
                    }
                merged[TEMPLATE]["@" + key] = meta
            added += 1

    if collisions:
        print("COLLISIONS (same key, different FR text):")
        for k, src in collisions:
            print(f"  - {k} (from {src})")
        sys.exit(2)

    # Warn about overlay keys that match no fragment key (typos / stale keys).
    for lang in OVERLAY_LANGS:
        stale = [k for k in overlays[lang] if k not in all_keys]
        if stale:
            print(f"  WARNING {lang}: {len(stale)} overlay key(s) match no "
                  f"fragment key (ignored): {', '.join(sorted(stale)[:8])}"
                  + (" ..." if len(stale) > 8 else ""))

    os.makedirs(os.path.join(ROOT, "build"), exist_ok=True)
    for lang in LANGS:
        out = os.path.join(OUT_DIR, f"app_{lang}.arb")
        with open(out, "w", encoding="utf-8") as f:
            json.dump(merged[lang], f, ensure_ascii=False, indent=2)
            f.write("\n")

    total = len([k for k in merged[TEMPLATE] if not k.startswith("@")])
    print(f"Merged {added} keys into {len(LANGS)} languages. Template keys: {total}")
    for lang in LANGS:
        if lang == TEMPLATE:
            continue
        miss = sorted(set(untranslated[lang]))
        rep = os.path.join(ROOT, "build", f"l10n_untranslated_{lang}.txt")
        if miss:
            with open(rep, "w", encoding="utf-8") as f:
                f.write("\n".join(miss) + "\n")
            done = total - len(miss)
            print(f"  {lang}: {done}/{total} translated, {len(miss)} fell back "
                  f"-> build/l10n_untranslated_{lang}.txt")
        else:
            if os.path.exists(rep):
                os.remove(rep)
            print(f"  {lang}: fully translated ({total}/{total})")


if __name__ == "__main__":
    main()
