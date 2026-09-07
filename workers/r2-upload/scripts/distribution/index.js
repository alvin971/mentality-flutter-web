/**
 * Distribution des verdicts de lecture, lue depuis les `customMetadata` —
 * donc sans télécharger un seul verdict, et sans qu'un mot transcrit existe
 * nulle part (les verdicts n'en contiennent aucun, par conception).
 *
 * Sert à répondre à UNE question : le seuil `VERIFY_MIN_WORDS_HIT` est-il au
 * bon endroit pour de VRAIES voix ? Les seuils livrés ont été calibrés sur des
 * voix synthétiques, plus propres qu'un vrai micro.
 */
export default {
  async fetch(request, env) {
    const prefix = new URL(request.url).searchParams.get('prefix') || 'verified/';
    const lignes = [];
    let cursor;
    do {
      const listed = await env.AUDIO_BUCKET.list({ prefix, cursor, limit: 1000, include: ['customMetadata'] });
      for (const obj of listed.objects) {
        const m = obj.customMetadata || {};
        lignes.push({
          ok: m.ok === 'true',
          reason: m.reason || '',
          type: m.record_type || '',
          // Le préfixe de l'identifiant de texte porte la langue (fr_00042, en_GB_00007).
          langue: (m.text_id || '').replace(/_\d+$/, '') || '—',
          mots: Number(m.words_hit || 0),
          ref: Number(m.words_ref || 0),
          ordre: m.order === '' || m.order === undefined ? null : Number(m.order),
          jour: m.day || '',
        });
      }
      cursor = listed.truncated ? listed.cursor : undefined;
    } while (cursor);

    const lectures = lignes.filter((l) => l.type === 'reading');
    const q = (v) => {
      if (!v.length) return null;
      const s = v.slice().sort((a, b) => a - b);
      return { n: s.length, min: s[0], med: s[s.length >> 1], max: s[s.length - 1] };
    };
    const compte = (cle, filtre = () => true) => {
      const o = {};
      for (const l of lignes.filter(filtre)) o[l[cle] || '—'] = (o[l[cle] || '—'] || 0) + 1;
      return o;
    };
    const tranches = {};
    for (const l of lectures) {
      const t = `${Math.floor(l.mots / 10) * 10}-${Math.floor(l.mots / 10) * 10 + 9}`;
      tranches[t] = (tranches[t] || 0) + 1;
    }
    return Response.json({
      verdicts: lignes.length,
      lectures: lectures.length,
      acceptees: lectures.filter((l) => l.ok).length,
      refusees: lectures.filter((l) => !l.ok).length,
      raisons: compte('reason', (l) => !l.ok),
      par_langue: compte('langue', (l) => l.type === 'reading'),
      par_jour: compte('jour'),
      mots_retrouves: q(lectures.map((l) => l.mots)),
      mots_retrouves_acceptees: q(lectures.filter((l) => l.ok).map((l) => l.mots)),
      mots_retrouves_refusees: q(lectures.filter((l) => !l.ok).map((l) => l.mots)),
      ordre: q(lectures.map((l) => l.ordre).filter((x) => x !== null)),
      tranches_de_10_mots: Object.fromEntries(Object.entries(tranches).sort((a, b) => parseInt(a[0], 10) - parseInt(b[0], 10))),
      // Ce qui décide s'il faut bouger le seuil : les lectures acceptées de
      // justesse (30 à 39 mots) et les refusées qui en étaient proches.
      limite_basse: lectures.filter((l) => l.mots >= 25 && l.mots < 45)
        .map((l) => ({ ok: l.ok, mots: l.mots, ref: l.ref, ordre: l.ordre, langue: l.langue })),
    });
  },
};
