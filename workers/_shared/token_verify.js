/**
 * Vérification SERVEUR d'un token signé (JWS compact EdDSA).
 *
 * C'est LE point où la signature a une valeur de sécurité : un serveur qui sert
 * ou accepte des données DOIT re-vérifier la signature ici (la vérif côté client
 * est contournable). Miroir exact de lib/core/services/token_signature_verifier.dart.
 *
 * Renvoie { valid, reason, nonce, claims } :
 *   - valid : booléen
 *   - reason : code d'échec lisible (null si valide)
 *   - nonce : base64url du nonce (128 bits, claim `n`) — UNIQUE identifiant
 *             d'accès aux données (jamais la chaîne token complète ni la
 *             signature : la signature Ed25519 est malléable, le nonce est
 *             dans les octets signés)
 *   - claims : payload décodé (si valide), clés compactes {s,y,m,r,d,n,sv}
 *
 * Usage (dans un Worker) :
 *   import { verifyToken, TOKEN_SIGNING_PUBLIC_KEYS } from '../_shared/token_verify.js';
 *   const v = await verifyToken(request.headers.get('X-Mentality-Token'),
 *                               TOKEN_SIGNING_PUBLIC_KEYS);
 *   if (!v.valid) return new Response('unauthorized', { status: 401 });
 *   const account = await sha256hex(v.nonce); // partition de données
 */

// Clés PUBLIQUES Ed25519 (base64url, 32 octets), indexées par kid.
// ⚠️ NON secret. DOIT rester synchronisé avec
//    AppConstants.tokenSigningPublicKeys (lib/core/constants/app_constants.dart).
export const TOKEN_SIGNING_PUBLIC_KEYS = {
  k1: 'mb7Vw9W63IPYxTzTiVYbkFk9LYBEhIm7w7meIjK8Dd4',
};

// Versions de schéma de claims supportées. Miroir de `kTokenSchemaVersion`
// dans lib/core/services/token_issuer.dart.
const SUPPORTED_SCHEMA_VERSIONS = new Set([2]);

// Alphabet base64url strict (anti-octets parasites / homoglyphes).
const B64URL_SEGMENT = /^[A-Za-z0-9\-_]+$/;

export async function verifyToken(token, pubKeysByKid) {
  if (typeof token !== 'string' || token.length === 0) {
    return fail('missing');
  }
  try {
    // Découpe sur la chaîne ORIGINALE : on vérifie exactement les octets reçus
    // pour `header.payload` (jamais une re-jointure / re-sérialisation).
    const lastDot = token.lastIndexOf('.');
    if (lastDot <= 0) return fail('format');
    const signingInputStr = token.slice(0, lastDot);
    const sigSeg = token.slice(lastDot + 1);

    const firstDot = signingInputStr.indexOf('.');
    if (firstDot <= 0) return fail('format');
    const headerSeg = signingInputStr.slice(0, firstDot);
    const payloadSeg = signingInputStr.slice(firstDot + 1);

    if (
      !B64URL_SEGMENT.test(headerSeg) ||
      !B64URL_SEGMENT.test(payloadSeg) ||
      !B64URL_SEGMENT.test(sigSeg)
    ) {
      return fail('format');
    }

    const header = decodeJson(headerSeg);
    if (!header) return fail('header');
    if (header.alg !== 'EdDSA') return fail('alg'); // alg EN DUR (anti alg:none)
    if (typeof header.kid !== 'string') return fail('kid');
    const pubB64 = pubKeysByKid[header.kid];
    if (!pubB64) return fail('kid_unknown');

    const pubBytes = b64urlToBytes(pubB64);
    if (!pubBytes || pubBytes.length !== 32) return fail('pubkey');
    const sigBytes = b64urlToBytes(sigSeg);
    if (!sigBytes || sigBytes.length !== 64) return fail('sig_len');

    const key = await crypto.subtle.importKey(
      'raw',
      pubBytes,
      { name: 'Ed25519' },
      false,
      ['verify'],
    );
    const ok = await crypto.subtle.verify(
      { name: 'Ed25519' },
      key,
      sigBytes,
      new TextEncoder().encode(signingInputStr),
    );
    if (!ok) return fail('signature');

    const payload = decodeJson(payloadSeg);
    if (!payload) return fail('payload');
    if (!SUPPORTED_SCHEMA_VERSIONS.has(payload.sv)) return fail('schema_version');
    if (typeof payload.n !== 'string' || !B64URL_SEGMENT.test(payload.n)) {
      return fail('nonce');
    }

    return { valid: true, reason: null, nonce: payload.n, claims: payload };
  } catch {
    return fail('exception');
  }
}

/** SHA-256 hex d'une chaîne (pour dériver une partition opaque depuis le nonce). */
export async function sha256hex(str) {
  const digest = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(str));
  const bytes = new Uint8Array(digest);
  let hex = '';
  for (let i = 0; i < bytes.length; i++) {
    hex += bytes[i].toString(16).padStart(2, '0');
  }
  return hex;
}

function fail(reason) {
  return { valid: false, reason, nonce: null, claims: null };
}

function decodeJson(seg) {
  const bytes = b64urlToBytes(seg);
  if (!bytes) return null;
  try {
    const obj = JSON.parse(new TextDecoder().decode(bytes));
    return obj && typeof obj === 'object' && !Array.isArray(obj) ? obj : null;
  } catch {
    return null;
  }
}

function b64urlToBytes(s) {
  try {
    let b64 = s.replace(/-/g, '+').replace(/_/g, '/');
    while (b64.length % 4 !== 0) b64 += '=';
    const bin = atob(b64);
    const out = new Uint8Array(bin.length);
    for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
    return out;
  } catch {
    return null;
  }
}
