#!/usr/bin/env python3
"""Insert es/pt/de/en-GB reading-text corpora into lib/data/reading_texts.dart.

Reads build/i18n_work/reading/<lang>.json ({"texts":[{id,title,body,words}]})
and inserts `const List<ReadingText> _kReadingTexts<Xx> = [...]` blocks just
before the "Sélection par langue" marker. Idempotent: existing generated blocks
(between the BEGIN/END markers) are replaced on re-run. The selector getter is
edited separately.
"""
import json
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DART = os.path.join(ROOT, "lib/data/reading_texts.dart")
WORK = os.path.join(ROOT, "build/i18n_work/reading")
LANGS = [("es", "Es"), ("pt", "Pt"), ("de", "De"), ("en_GB", "EnGb")]
BEGIN = "// ─── BEGIN generated multilingual corpora ───"
END = "// ─── END generated multilingual corpora ───"


def dq(s):
    s = str(s).replace("\\", "\\\\").replace("'", "\\'")
    s = re.sub(r"\s+", " ", s).strip()
    return f"'{s}'"


def wc(text, declared):
    return int(declared) if declared else len(str(text).split())


def main():
    blocks = [BEGIN, ""]
    for code, suffix in LANGS:
        data = json.load(open(os.path.join(WORK, f"{code}.json")))["texts"]
        if len(data) != 5:
            raise SystemExit(f"{code}: expected 5 texts, got {len(data)}")
        blocks.append(f"const List<ReadingText> _kReadingTexts{suffix} = [")
        for i, t in enumerate(data):
            body = t.get("body", "")
            if len(body.split()) < 80:
                raise SystemExit(f"{code} text {i}: body too short ({len(body.split())} words)")
            blocks.append("  ReadingText(")
            blocks.append(f"    id: {dq(t.get('id', f'text_0{i+1}'))},")
            blocks.append(f"    title: {dq(t.get('title',''))},")
            blocks.append(f"    body: {dq(body)},")
            blocks.append(f"    approximateWordCount: {wc(body, t.get('words'))},")
            blocks.append("  ),")
        blocks.append("];")
        blocks.append("")
    blocks.append(END)
    block = "\n".join(blocks)

    src = open(DART, encoding="utf-8").read()
    if BEGIN in src and END in src:
        src = re.sub(re.escape(BEGIN) + r".*?" + re.escape(END), block, src, flags=re.S)
    else:
        marker = "// ─── Sélection par langue"
        idx = src.index(marker)
        src = src[:idx] + block + "\n\n" + src[idx:]
    open(DART, "w", encoding="utf-8").write(src)
    print("Inserted es/pt/de/en-GB reading corpora (5 texts each).")


if __name__ == "__main__":
    main()
