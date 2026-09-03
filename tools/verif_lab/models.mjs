#!/usr/bin/env node
/**
 * Catalogue des modèles de transcription disponibles sur le compte.
 *
 *   node tools/verif_lab/models.mjs            → results/models.json + tableau
 *
 * Passe par le mini-worker (`env.AI.models`, tools/verif_lab/worker, lancé par
 * `wrangler dev --port 8799`) : le token du compte n'a pas la permission
 * « Workers AI » exigée par l'API REST /ai/models. Le prix vient des propriétés
 * du catalogue, la page de tarifs publique fait foi en cas de doute
 * (developers.cloudflare.com/workers-ai/platform/pricing).
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const ICI = path.dirname(fileURLToPath(import.meta.url));
const LAB = process.env.VERIF_LAB_URL || 'http://127.0.0.1:8799';

const r = await fetch(`${LAB}/models?task=${encodeURIComponent('Automatic Speech Recognition')}`);
const j = await r.json();
if (!j.ok) { console.error('échec :', j.error); process.exit(1); }

const modeles = j.models.map((m) => {
  const props = Object.fromEntries((m.properties || []).map((p) => [p.property_id, p.value]));
  return {
    name: m.name,
    description: (m.description || '').slice(0, 160),
    price: props.price ?? null,
    partner: props.partner === 'true' || props.partner === true,
    beta: props.beta === 'true' || props.beta === true,
    async_queue: props.async_queue === 'true' || props.async_queue === true,
    realtime: props.realtime === 'true' || props.realtime === true,
    languages: props.languages ?? null,
  };
});
fs.mkdirSync(path.join(ICI, 'results'), { recursive: true });
fs.writeFileSync(path.join(ICI, 'results', 'models.json'), JSON.stringify({ day: new Date().toISOString().slice(0, 10), models: modeles }, null, 2));
for (const m of modeles) {
  console.log(`${m.name.padEnd(36)} partner=${m.partner} beta=${m.beta} realtime=${m.realtime} async=${m.async_queue}`);
  console.log(`  prix : ${JSON.stringify(m.price)}`);
}
