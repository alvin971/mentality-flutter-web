/**
 * Mini-worker du banc d'essai « vérification vocale » (tools/verif_lab).
 *
 * Il n'est jamais déployé : lancé par `wrangler dev`, il expose sur localhost la
 * primitive exacte de la production, `env.AI.run(modèle, entrée)`, pour que le
 * banc transcrive comme workers/r2-upload/index.js et pas autrement.
 *
 * Rien n'est journalisé ni stocké ici : la réponse du modèle repart telle
 * quelle vers le client local (transcribe.mjs), qui n'en conserve que des
 * comptes — jamais le texte.
 *
 *   GET  /models?task=…      → env.AI.models({ task })   (catalogue du compte)
 *   POST /transcribe         → env.AI.run(X-Model, { audio, language? })
 *        en-têtes : X-Model (défaut @cf/openai/whisper), X-Language (optionnel),
 *                   X-Input-Form = bytes (tableau d'octets, forme du worker de
 *                   production) | base64 (forme des modèles whisper-large-v3-*)
 *        corps    : octets bruts du fichier audio, tels que l'app les envoie.
 */
export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (request.method === 'GET' && url.pathname === '/models') {
      const task = url.searchParams.get('task');
      try {
        const models = await env.AI.models(task ? { task, per_page: 100 } : { per_page: 100 });
        return json({ ok: true, models });
      } catch (e) {
        return json({ ok: false, error: message(e) }, 500);
      }
    }

    if (request.method === 'POST' && url.pathname === '/transcribe') {
      const model = request.headers.get('X-Model') || '@cf/openai/whisper';
      const language = request.headers.get('X-Language') || '';
      const form = request.headers.get('X-Input-Form') || 'bytes';
      const body = await request.arrayBuffer();
      const input = {};
      if (form === 'bytes') input.audio = [...new Uint8Array(body)];
      else if (form === 'base64') input.audio = base64(body);
      else return json({ ok: false, error: 'X-Input-Form inconnu' }, 400);
      if (language) input.language = language;
      const t0 = Date.now();
      try {
        const response = await env.AI.run(model, input);
        return json({ ok: true, ms: Date.now() - t0, bytes: body.byteLength, response });
      } catch (e) {
        return json({ ok: false, ms: Date.now() - t0, bytes: body.byteLength, error: message(e) }, 502);
      }
    }

    return new Response('verif-lab', { status: 404 });
  },
};

function json(obj, status = 200) {
  return new Response(JSON.stringify(obj), {
    status,
    headers: { 'content-type': 'application/json; charset=utf-8' },
  });
}

function message(e) {
  return e && e.message ? String(e.message) : String(e);
}

function base64(buffer) {
  const bytes = new Uint8Array(buffer);
  let bin = '';
  for (let i = 0; i < bytes.length; i += 0x8000) {
    bin += String.fromCharCode.apply(null, bytes.subarray(i, i + 0x8000));
  }
  return btoa(bin);
}
