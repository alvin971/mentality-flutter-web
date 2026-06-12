#!/usr/bin/env python3
"""Merge l10n_fragments/*.json into lib/l10n/app_fr.arb and app_en.arb.

Fragment format per key:
  {"keyName": {"fr": "...", "en": "...", "desc": "...", "placeholders": {"name":"int"}}}

Common/base keys already in the ARB files are preserved; fragments only add.
ICU placeholders generate the matching @key metadata block.
"""
import json
import glob
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FR = os.path.join(ROOT, "lib/l10n/app_fr.arb")
EN = os.path.join(ROOT, "lib/l10n/app_en.arb")


def load(p):
    with open(p, encoding="utf-8") as f:
        return json.load(f)


def main():
    fr = load(FR)
    en = load(EN)
    # Keep only the hand-authored base keys (locale marker + everything already there).
    base_fr = dict(fr)
    base_en = dict(en)

    merged_fr = {"@@locale": "fr"}
    merged_en = {"@@locale": "en"}

    # Re-add base keys (common.*, appTitle, languageSwitcherTooltip, etc.)
    for k, v in base_fr.items():
        if k == "@@locale":
            continue
        merged_fr[k] = v
    for k, v in base_en.items():
        if k == "@@locale":
            continue
        merged_en[k] = v

    seen = set(merged_fr.keys())
    collisions = []
    added = 0

    for path in sorted(glob.glob(os.path.join(ROOT, "l10n_fragments/*.json"))):
        if os.path.basename(path).startswith("_"):
            continue
        frag = load(path)
        for key, entry in frag.items():
            if not key or key == "maCle":
                continue
            if key in seen and not key.startswith("@"):
                # Allow identical re-definition, flag real conflicts.
                if merged_fr.get(key) != entry.get("fr"):
                    collisions.append((key, os.path.basename(path)))
                continue
            seen.add(key)
            merged_fr[key] = entry["fr"]
            merged_en[key] = entry.get("en", entry["fr"])
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
                merged_fr["@" + key] = meta
            added += 1

    with open(FR, "w", encoding="utf-8") as f:
        json.dump(merged_fr, f, ensure_ascii=False, indent=2)
        f.write("\n")
    with open(EN, "w", encoding="utf-8") as f:
        json.dump(merged_en, f, ensure_ascii=False, indent=2)
        f.write("\n")

    print(f"Merged {added} fragment keys. Total fr keys (incl base): "
          f"{len([k for k in merged_fr if not k.startswith('@')])}")
    if collisions:
        print("COLLISIONS (same key, different FR text):")
        for k, src in collisions:
            print(f"  - {k} (from {src})")
        sys.exit(2)


if __name__ == "__main__":
    main()
