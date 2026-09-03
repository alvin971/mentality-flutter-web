#!/usr/bin/env python3
"""Pilote piper du banc : charge chaque voix UNE fois et rend une liste de
travaux lus sur stdin (JSONL : {"voice": "<chemin .onnx>", "text": "...",
"out": "<wav>"}). Écrit une ligne JSON par travail terminé sur stdout.
Aucun texte n'est journalisé."""
import json
import os
import sys
import wave

from piper import PiperVoice  # ~/.venvs/piper

jobs = [json.loads(l) for l in sys.stdin if l.strip()]
by_voice = {}
for j in jobs:
    by_voice.setdefault(j["voice"], []).append(j)
for voice_path, lst in by_voice.items():
    voice = PiperVoice.load(voice_path)
    for j in lst:
        os.makedirs(os.path.dirname(j["out"]), exist_ok=True)
        tmp = j["out"] + ".part"
        with wave.open(tmp, "wb") as wav_file:
            voice.synthesize_wav(j["text"], wav_file)
        os.replace(tmp, j["out"])
        print(json.dumps({"out": j["out"], "ok": True}), flush=True)
