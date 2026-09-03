#!/usr/bin/env node
/**
 * extract_banks.mjs — lit les 12 banques Dart (Similitudes + Vocabulaire, 6 langues)
 * et produit banks.jsonl : une ligne par item.
 *
 *   node extract_banks.mjs            → écrit banks.jsonl
 *
 * Les banques ne sont JAMAIS modifiées (règle du chantier). L'identifiant `id`
 * reproduit exactement ce que l'app envoie dans test_items.item_id :
 *   - Similitudes : '${word1}/${word2}'  (similarities_test_page.dart, startItem)
 *   - Vocabulaire : '${word}'            (vocabulary_test_page.dart, startItem)
 * Le worker (§7) retrouvera donc l'item par (subtest, lang, id).
 *
 * Parseur : un mini-lecteur d'arguments Dart (chaînes simples avec échappements,
 * listes, identifiants, nombres). Pas de regex sur les chaînes : les réponses
 * contiennent des apostrophes échappées (\') et des virgules.
 */
import { readFileSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, '..', '..');
const LANGS = ['fr', 'en', 'en_gb', 'es', 'pt', 'de'];
const BANKS = [
  { subtest: 'SI', ctor: 'SimilarityItem', dir: 'lib/features/exercises_implementations/similarities/domain', prefix: 'similarities_items_' },
  { subtest: 'VO', ctor: 'VocabularyItem', dir: 'lib/features/exercises_implementations/vocabulary/domain', prefix: 'vocabulary_items_' },
];

/** Lit une valeur Dart à partir de src[i]. Retourne {value, next}. */
function readValue(src, i) {
  i = skipWs(src, i);
  const c = src[i];
  if (c === "'" || c === '"') return readString(src, i);
  if (c === '[') return readList(src, i);
  // identifiant / nombre / accès (AbstractionLevel.concrete, -1.5, true)
  let j = i;
  while (j < src.length && /[A-Za-z0-9_.\-]/.test(src[j])) j++;
  const tok = src.slice(i, j);
  if (/^-?\d+(\.\d+)?$/.test(tok)) return { value: Number(tok), next: j };
  return { value: tok.includes('.') ? tok.split('.').pop() : tok, next: j };
}
function skipWs(src, i) {
  while (i < src.length && /\s/.test(src[i])) i++;
  return i;
}
function readString(src, i) {
  const q = src[i];
  let out = '';
  i++;
  while (i < src.length && src[i] !== q) {
    if (src[i] === '\\') {
      const n = src[i + 1];
      out += n === 'n' ? '\n' : n; // \' \" \\ \n
      i += 2;
    } else {
      out += src[i++];
    }
  }
  return { value: out, next: i + 1 };
}
function readList(src, i) {
  const out = [];
  i++; // [
  for (;;) {
    i = skipWs(src, i);
    if (src[i] === ']') return { value: out, next: i + 1 };
    const r = readValue(src, i);
    out.push(r.value);
    i = skipWs(src, r.next);
    if (src[i] === ',') i++;
  }
}
/** Lit `Ctor(name: value, name: value, ...)` à partir de la parenthèse ouvrante. */
function readArgs(src, i) {
  const args = {};
  i++; // (
  for (;;) {
    i = skipWs(src, i);
    if (src[i] === ')') return { value: args, next: i + 1 };
    let j = i;
    while (/[A-Za-z0-9_]/.test(src[j])) j++;
    const name = src.slice(i, j);
    i = skipWs(src, j);
    if (src[i] !== ':') throw new Error(`':' attendu à ${i} (${name})`);
    const r = readValue(src, i + 1);
    args[name] = r.value;
    i = skipWs(src, r.next);
    if (src[i] === ',') i++;
  }
}

const lines = [];
const counts = {};
for (const bank of BANKS) {
  for (const lang of LANGS) {
    const file = join(root, bank.dir, `${bank.prefix}${lang}.dart`);
    const src = readFileSync(file, 'utf8');
    const needle = bank.ctor + '(';
    let pos = 0, n = 0;
    for (;;) {
      const at = src.indexOf(needle, pos);
      if (at < 0) break;
      const { value: a, next } = readArgs(src, at + needle.length - 1);
      pos = next;
      const item = bank.subtest === 'SI'
        ? { subtest: 'SI', lang, id: `${a.word1}/${a.word2}`, stimulus: { word1: a.word1, word2: a.word2 }, level: a.level, two: a.twoPointAnswers, one: a.onePointAnswers, theta: a.thetaValue }
        : { subtest: 'VO', lang, id: a.word, stimulus: { word: a.word }, level: a.frequency, two: a.twoPointAnswers, one: a.onePointAnswers, theta: a.thetaValue };
      if (!item.two?.length || !item.one?.length) throw new Error(`item sans exemples : ${lang} ${item.id}`);
      lines.push(JSON.stringify(item));
      n++;
    }
    counts[`${bank.subtest}/${lang}`] = n;
  }
}
writeFileSync(join(here, 'banks.jsonl'), lines.join('\n') + '\n');
console.log(`banks.jsonl : ${lines.length} items`);
console.table(counts);
