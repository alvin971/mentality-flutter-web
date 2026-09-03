#!/usr/bin/env bash
# Dégradations et encodages du banc « vérification vocale » (protocole §3).
#
#   degrade.sh <entrée.wav> <sortie.(wav|webm|mp4)> [proc]
#
# proc ∈ clean | x0.8 | x1.3 | noise-20 | noise-10 | room-20 | gain-15 | gain+12 | bg
#   x0.8 / x1.3      : vitesse (atempo), hauteur inchangée ;
#   noise-20 / -10   : bruit blanc filtré (< 3,5 kHz) à −20 / −10 dB sous le niveau moyen de la parole ;
#   room-20          : fond « pièce » (bruit rose < 800 Hz) à −20 dB ;
#   gain-15          : micro faible (−15 dB) ;
#   gain+12          : micro saturé (+12 dB en virgule fixe → écrêtage réel) ;
#   bg               : parole de FOND sans lecture (−15 dB + fond pièce à −25 dB).
#
# Formats = ceux de l'app (record ^5.2 : 16 kHz, mono, 32 kbps) :
#   webm = Opus 32 kbps (Chrome/Firefox/Android) · mp4 = AAC-LC 32 kbps (Safari/iOS) · wav = PCM 16 bits (secours).
set -euo pipefail
in=$1; out=$2; proc=${3:-clean}
ext=${out##*.}
case "$ext" in
  webm) enc=(-c:a libopus -b:a 32k -vbr on -ar 16000 -ac 1 -f webm) ;;
  mp4)  enc=(-c:a aac -b:a 32k -ar 16000 -ac 1 -movflags +faststart -f mp4) ;;
  wav)  enc=(-c:a pcm_s16le -ar 16000 -ac 1 -f wav) ;;
  *) echo "format inconnu : $ext" >&2; exit 2 ;;
esac
FF=(ffmpeg -nostats -loglevel error -y)
mean_db() { ffmpeg -nostats -i "$in" -af volumedetect -f null - 2>&1 | sed -n 's/.*mean_volume: \(-\?[0-9.]*\) dB.*/\1/p' | head -1; }
amp() { awk -v m="$2" -v snr="$1" 'BEGIN { printf "%.6f", 10 ^ ((m - snr) / 20) }'; }
dur() { ffprobe -v error -show_entries format=duration -of csv=p=0 "$in"; }
tmp="$out.part.$ext"
case "$proc" in
  clean)   "${FF[@]}" -i "$in" "${enc[@]}" "$tmp" ;;
  x0.8)    "${FF[@]}" -i "$in" -af "atempo=0.8" "${enc[@]}" "$tmp" ;;
  x1.3)    "${FF[@]}" -i "$in" -af "atempo=1.3" "${enc[@]}" "$tmp" ;;
  gain-15) "${FF[@]}" -i "$in" -af "volume=-15dB" "${enc[@]}" "$tmp" ;;
  gain+12) "${FF[@]}" -i "$in" -af "volume=12dB:precision=fixed" "${enc[@]}" "$tmp" ;;
  noise-20|noise-10)
    snr=${proc#noise-}; m=$(mean_db); a=$(amp "$snr" "$m"); d=$(dur)
    "${FF[@]}" -i "$in" -f lavfi -i "anoisesrc=c=white:a=$a:r=16000:d=$d:s=7,lowpass=f=3500" \
      -filter_complex "[0:a]aresample=16000[s];[s][1:a]amix=inputs=2:duration=first:normalize=0[o]" -map "[o]" "${enc[@]}" "$tmp" ;;
  room-20)
    m=$(mean_db); a=$(amp 20 "$m"); d=$(dur)
    "${FF[@]}" -i "$in" -f lavfi -i "anoisesrc=c=pink:a=$a:r=16000:d=$d:s=11,lowpass=f=800" \
      -filter_complex "[0:a]aresample=16000[s];[s][1:a]amix=inputs=2:duration=first:normalize=0[o]" -map "[o]" "${enc[@]}" "$tmp" ;;
  bg)
    m=$(mean_db); a=$(amp 25 "$m"); d=$(dur)
    "${FF[@]}" -i "$in" -f lavfi -i "anoisesrc=c=pink:a=$a:r=16000:d=$d:s=13,lowpass=f=800" \
      -filter_complex "[0:a]aresample=16000,volume=-15dB[s];[s][1:a]amix=inputs=2:duration=first:normalize=0[o]" -map "[o]" "${enc[@]}" "$tmp" ;;
  *) echo "proc inconnu : $proc" >&2; exit 2 ;;
esac
mv -f "$tmp" "$out"
