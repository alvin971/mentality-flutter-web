#!/usr/bin/env bash
# Distribution réelle des verdicts de lecture (bucket R2 en juridiction EU).
#
#   bash workers/r2-upload/scripts/distribution.sh
#
# Pourquoi ce détour : `wrangler r2 object` n'a PAS de sous-commande `list`, et
# sur un bucket EU le `get` répond « key does not exist » à tort. Seul le
# binding R2 d'un worker lit correctement — d'où ce mini-worker de lecture
# seule, lancé le temps d'une requête puis arrêté. Rien n'est déployé.
set -euo pipefail
cd "$(dirname "$0")/distribution"
eval "$(grep -E '^export CLOUDFLARE_(API_TOKEN|ACCOUNT_ID)=' ~/.bashrc)"
export CLOUDFLARE_API_TOKEN CLOUDFLARE_ACCOUNT_ID WRANGLER_SEND_METRICS=false
W=$(ls -t ~/.npm/_npx/*/node_modules/.bin/wrangler | head -1)
PORT=${PORT:-8801}
LOG=$(mktemp)
"$W" dev --remote --port "$PORT" --ip 127.0.0.1 --show-interactive-dev-session=false > "$LOG" 2>&1 &
PID=$!
trap 'kill $PID 2>/dev/null || true' EXIT
for _ in $(seq 1 60); do
  sleep 2
  if curl -s -m 5 -o /tmp/distribution.json "http://127.0.0.1:$PORT/?prefix=${1:-verified/}"; then
    node -e '
const d = JSON.parse(require("fs").readFileSync("/tmp/distribution.json", "utf8"));
const q = (o) => (o ? `n=${o.n}  min ${o.min}  méd ${o.med}  max ${o.max}` : "—");
console.log(`\nverdicts ${d.verdicts} · lectures ${d.lectures} — acceptées ${d.acceptees}, refusées ${d.refusees}`);
console.log(`\nmots retrouvés   ${q(d.mots_retrouves)}`);
console.log(`  acceptées      ${q(d.mots_retrouves_acceptees)}`);
console.log(`  refusées       ${q(d.mots_retrouves_refusees)}`);
console.log(`score d ordre    ${q(d.ordre)}`);
if (Object.keys(d.raisons).length) console.log(`\nraisons de refus : ${Object.entries(d.raisons).map(([k, v]) => `${k}=${v}`).join("  ")}`);
if (Object.keys(d.par_langue).length) console.log(`par langue       : ${Object.entries(d.par_langue).map(([k, v]) => `${k}=${v}`).join("  ")}`);
if (Object.keys(d.tranches_de_10_mots).length) {
  console.log("\nrépartition des mots retrouvés :");
  for (const [t, n] of Object.entries(d.tranches_de_10_mots)) console.log(`  ${t.padStart(7)} ${"█".repeat(Math.min(n, 60))} ${n}`);
}
if (d.limite_basse.length) {
  console.log("\n⚠️  cas proches du seuil de 30 mots (c est eux qui disent s il faut bouger) :");
  for (const c of d.limite_basse) console.log(`   ${c.ok ? "accepté" : "REFUSÉ "} ${String(c.mots).padStart(3)} mots sur ${c.ref} · ordre ${c.ordre} · ${c.langue}`);
} else if (d.lectures) console.log("\nAucune lecture entre 25 et 45 mots : le seuil de 30 est loin de tout le monde.");
if (!d.lectures) console.log("\n(aucune lecture verdictée pour l instant — fais une passation et relance)");
'
    exit 0
  fi
done
echo "le mini-worker n a pas démarré :" >&2; tail -20 "$LOG" >&2; exit 1
