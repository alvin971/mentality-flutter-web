#!/usr/bin/env bash
# Déploiement ordonné du durcissement anti-fraude du parrainage (2026-07-07).
# ORDRE OBLIGATOIRE (cf. gotcha « ordre de déploiement workers ») :
#   1. bucket R2  →  2. KV rate-limit + tokeniser  →  3. r2-upload
#   →  4. (bundle web déjà rebuilt/commité)  →  5. referral EN DERNIER.
#
# Usage :  bash scripts/deploy-antifraude.sh
# Pré-requis : R2 activé sur le compte devgreenpro (dashboard), token CF dans
# ~/.config/cloudflare.env.
set -euo pipefail
cd "$(dirname "$0")/.."

set -a; . ~/.config/cloudflare.env; set +a

echo "── 1/5 Bucket R2 (jurisdiction EU obligatoire — RGPD) ──"
npx wrangler r2 bucket create mentality-audio --jurisdiction eu 2>&1 \
  | grep -v '^$' || true   # idempotent : « already exists » toléré

echo "── 2/5 KV rate-limit + tokeniser ──"
cd workers/tokeniser
if grep -q RATE_KV_NAMESPACE_ID_PLACEHOLDER wrangler.toml; then
  OUT=$(npx wrangler kv namespace create RATE_KV 2>&1) || {
    # Namespace peut-être déjà créé lors d'un run précédent : le retrouver.
    OUT=$(npx wrangler kv namespace list 2>/dev/null)
  }
  ID=$(echo "$OUT" | grep -oE '[0-9a-f]{32}' | head -1)
  [ -n "$ID" ] || { echo "ERREUR : id du namespace RATE_KV introuvable"; exit 1; }
  sed -i "s/RATE_KV_NAMESPACE_ID_PLACEHOLDER/$ID/" wrangler.toml
  echo "RATE_KV id = $ID (reporté dans wrangler.toml — à committer)"
fi
npx wrangler deploy

echo "── 3/5 r2-upload ──"
cd ../r2-upload
npx wrangler deploy

echo "── 4/5 Bundle web : déjà rebuilt + commité (rien à faire ici) ──"

echo "── 5/5 referral (EN DERNIER : rejette désormais les tokens non signés) ──"
cd ../referral
npx wrangler deploy

echo "✅ Déploiement anti-fraude terminé."
