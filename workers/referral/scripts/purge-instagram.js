#!/usr/bin/env node
/**
 * Purge RGPD des champs Instagram des lignes `progress:*` du KV referral,
 * et migration de l'ancre du délai (`stage3StartedAt`).
 *
 * ⚠️ CE SCRIPT NE SUPPRIME AUCUNE LIGNE. Les lignes portent le code de
 *    parrainage et l'état des paliers : les effacer ferait perdre à chaque
 *    parrain ses filleuls déjà acquis. On ne retire que trois CHAMPS.
 *
 * Usage (Node ≥ 18 — `fetch` est global, ce script n'a AUCUNE dépendance,
 * ce qui lui évite d'introduire un package.json dans un dépôt qui n'en a pas) :
 *
 *   CF_API_TOKEN=… CF_ACCOUNT_ID=… node workers/referral/scripts/purge-instagram.js
 *   CF_API_TOKEN=… CF_ACCOUNT_ID=… node workers/referral/scripts/purge-instagram.js --apply
 *   … --namespace-id=<id>    # cibler un autre namespace (test)
 *
 * Sans `--apply`, le script est en DRY-RUN : il lit, calcule et rapporte, mais
 * n'écrit rien. Lire le rapport AVANT d'appliquer — en particulier le compteur
 * `instagramVerified:false`.
 *
 * Le token doit porter la permission « Workers KV Storage: Edit ».
 * Les identifiants sont lus dans l'ENVIRONNEMENT uniquement, jamais en argv :
 * un argument de ligne de commande atterrit dans l'historique du shell et dans
 * la sortie de `ps`.
 *
 * ORDRE D'EXÉCUTION : déployer le worker D'ABORD, purger ENSUITE. L'ancien
 * worker réécrivait `instagramSubmittedAt` à chaque soumission ; tant qu'il est
 * en ligne, il recrée derrière le script ce que celui-ci vient d'effacer.
 *
 * Les deux ordres restent néanmoins SÛRS, parce que la migration de l'ancre et
 * la suppression des champs se font dans la MÊME écriture (cf. transform) :
 *   · déploiement puis purge → le worker a peut-être déjà posé stage3StartedAt ;
 *     le garde `!isValidIso` rend le script inopérant sur ce point, il ne fait
 *     alors que retirer les champs ;
 *   · purge puis déploiement → le script pose l'ancre, le worker la trouve.
 * Sans cette simultanéité, supprimer `instagramSubmittedAt` avant que le worker
 * n'ait relu la ligne ferait repartir l'utilisateur pour un délai complet.
 *
 * Course « lecture → transformation → écriture » : si le worker promeut une
 * ligne en stage 4 pendant cette fenêtre et que nous la réécrivons en stage 3,
 * la lecture suivante recalcule 3→4 depuis `stage3StartedAt`, dont le délai est
 * déjà écoulé. Seul `unlockedAt` se décale de quelques secondes.
 *
 * Idempotent : une seconde exécution doit rapporter 0 ligne modifiée.
 */

'use strict';

const API = 'https://api.cloudflare.com/client/v4';

/** Namespace de production — miroir de wrangler.toml. */
const DEFAULT_NAMESPACE_ID = '6c70f3aab78c4aeb92d1255f62edbafd';

/** Les trois champs à faire disparaître. Miroir de REMOVED_FIELDS d'index.js. */
const REMOVED_FIELDS = ['instagramHandle', 'instagramSubmittedAt', 'instagramVerified'];

/** L'API bulk accepte 10 000 clés ; on reste large pour garder des requêtes courtes. */
const CHUNK = 1000;

/** Un horodatage ISO exploitable ? (miroir exact de isValidIso d'index.js) */
function isValidIso(s) {
  return typeof s === 'string' && Number.isFinite(Date.parse(s));
}

/**
 * Transformation d'UNE ligne. Fonction pure : c'est ici, et nulle part
 * ailleurs, que se décide ce qui change.
 *
 * Trois cas de migration, alignés sur buildProgressResponse() du worker :
 *   (a) stage 4  → intouchée, inconditionnellement. Un déblocage acquis ne se
 *                  recalcule jamais.
 *   (b) stage 3 avec un ancien instagramSubmittedAt → il devient l'ancre :
 *                  l'attente déjà écoulée n'est pas perdue.
 *   (c) stage 3 sans rien → on NE POSE RIEN ici. Le compteur doit démarrer
 *                  quand l'utilisateur revient (le worker s'en charge à la
 *                  première lecture), pas quand un script tourne à 3 h du matin.
 */
function transform(row) {
  let changed = false;
  let migrated = false;

  if (row.stage === 3 &&
      !isValidIso(row.stage3StartedAt) &&
      isValidIso(row.instagramSubmittedAt)) {
    row.stage3StartedAt = row.instagramSubmittedAt;
    changed = true;
    migrated = true;
  }

  // Signalé, jamais traité : le levier de re-verrouillage manuel disparaît avec
  // le champ. Un humain doit savoir combien de comptes il concernait.
  const invalidated = row.instagramVerified === false;

  const anchorless = row.stage === 3 && !isValidIso(row.stage3StartedAt);

  for (const f of REMOVED_FIELDS) {
    if (f in row) {
      delete row[f];
      changed = true;
    }
  }

  return { changed, migrated, invalidated, anchorless };
}

// ─── Accès API ───────────────────────────────────────────────────────────────

function requireEnv(name) {
  const v = process.env[name];
  if (!v) {
    console.error(
      `✗ Variable d'environnement ${name} absente.\n` +
      `  Usage : CF_API_TOKEN=… CF_ACCOUNT_ID=… node ${process.argv[1]} [--apply]`,
    );
    process.exit(1);
  }
  return v;
}

async function cf(token, path, init = {}) {
  const resp = await fetch(`${API}${path}`, {
    ...init,
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
      ...(init.headers || {}),
    },
  });
  const text = await resp.text();
  let body;
  try { body = JSON.parse(text); } catch { body = null; }
  if (!resp.ok || (body && body.success === false)) {
    const detail = body && body.errors ? JSON.stringify(body.errors) : text.slice(0, 300);
    throw new Error(`${init.method || 'GET'} ${path} → HTTP ${resp.status} : ${detail}`);
  }
  return body;
}

/** Itère toutes les clés `progress:*`, en suivant la pagination. */
async function* listProgressKeys(token, account, ns) {
  let cursor = '';
  do {
    const q = new URLSearchParams({ prefix: 'progress:', limit: '1000' });
    if (cursor) q.set('cursor', cursor);
    const body = await cf(
      token,
      `/accounts/${account}/storage/kv/namespaces/${ns}/keys?${q}`,
    );
    for (const k of body.result) yield k.name;
    cursor = (body.result_info && body.result_info.cursor) || '';
  } while (cursor);
}

async function getRow(token, account, ns, key) {
  const resp = await fetch(
    `${API}/accounts/${account}/storage/kv/namespaces/${ns}/values/${encodeURIComponent(key)}`,
    { headers: { Authorization: `Bearer ${token}` } },
  );
  if (!resp.ok) throw new Error(`GET ${key} → HTTP ${resp.status}`);
  const text = await resp.text();
  try {
    const obj = JSON.parse(text);
    return obj && typeof obj === 'object' && !Array.isArray(obj) ? obj : null;
  } catch {
    return null; // comptée « illisible », jamais réécrite
  }
}

async function bulkPut(token, account, ns, entries) {
  for (let i = 0; i < entries.length; i += CHUNK) {
    const slice = entries.slice(i, i + CHUNK);
    await cf(token, `/accounts/${account}/storage/kv/namespaces/${ns}/bulk`, {
      method: 'PUT',
      body: JSON.stringify(slice),
    });
    console.log(`  … ${Math.min(i + CHUNK, entries.length)}/${entries.length} lignes écrites`);
  }
}

// ─── Pilote ──────────────────────────────────────────────────────────────────

async function main() {
  const apply = process.argv.includes('--apply');
  const nsArg = process.argv.find((a) => a.startsWith('--namespace-id='));
  const ns = nsArg ? nsArg.split('=')[1] : DEFAULT_NAMESPACE_ID;

  const token = requireEnv('CF_API_TOKEN');
  const account = requireEnv('CF_ACCOUNT_ID');

  console.log(`Namespace : ${ns}`);
  console.log(apply ? 'Mode      : APPLY (écriture réelle)' : 'Mode      : DRY-RUN (aucune écriture)');
  console.log('');

  const stats = {
    lues: 0, modifiees: 0, migrees: 0, sansAncre: 0,
    stage4: 0, invalidees: 0, illisibles: 0,
  };
  const aEcrire = [];

  for await (const key of listProgressKeys(token, account, ns)) {
    stats.lues++;
    const row = await getRow(token, account, ns, key);
    if (!row) { stats.illisibles++; continue; }

    if (row.stage === 4) stats.stage4++;
    const { changed, migrated, invalidated, anchorless } = transform(row);
    if (migrated) stats.migrees++;
    if (invalidated) stats.invalidees++;
    if (anchorless) stats.sansAncre++;
    if (changed) {
      stats.modifiees++;
      aEcrire.push({ key, value: JSON.stringify(row) });
    }
  }

  if (apply && aEcrire.length > 0) {
    console.log(`Écriture de ${aEcrire.length} lignes…`);
    await bulkPut(token, account, ns, aEcrire);
    console.log('');
  }

  console.log('─── Rapport ────────────────────────────────────────────');
  console.log(`  lignes lues                          : ${stats.lues}`);
  console.log(`  lignes modifiées                     : ${stats.modifiees}${apply ? '' : ' (non écrites — dry-run)'}`);
  console.log(`  dont migrées (cas b, ancre héritée)  : ${stats.migrees}`);
  console.log(`  stage 3 sans ancre (cas c → worker)  : ${stats.sansAncre}`);
  console.log(`  stage 4 (cas a, intactes)            : ${stats.stage4}`);
  console.log(`  illisibles (ignorées)                : ${stats.illisibles}`);
  if (stats.invalidees > 0) {
    console.log('');
    console.log(`  ⚠️  instagramVerified:false rencontrés : ${stats.invalidees}`);
    console.log('     Ces comptes étaient re-verrouillés manuellement. Ce levier');
    console.log('     disparaît avec le champ : ils se débloqueront à l\'échéance');
    console.log('     du délai comme tout le monde. Décision humaine requise.');
  }
  console.log('────────────────────────────────────────────────────────');

  if (!apply && stats.modifiees > 0) {
    console.log('');
    console.log('Relancer avec --apply pour écrire.');
  }
}

main().catch((e) => {
  console.error(`✗ ${e.message}`);
  process.exit(1);
});
