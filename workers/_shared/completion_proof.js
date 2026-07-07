/**
 * Preuve de complétion d'un test — partagée tokeniser / referral.
 *
 * Un compte est réputé avoir complété son test si :
 *   1. le marqueur `validated/<account>` existe (posé par tokeniser POST /validate), OU
 *   2. au moins [min] enregistrements existent sous reusable/<account>/ ou
 *      internal/<account>/ (repli : couvre la course où /progress/init arrive
 *      avant que /validate ait posé le marqueur).
 *
 * `account = SHA256(nonce)[:32]` — même dérivation dans tous les workers.
 */

/** True si ≥ [min] objets existent sous reusable/<account>/ ou internal/<account>/. */
export async function hasEnoughRecordings(bucket, account, min) {
  let count = 0;
  for (const prefix of [`reusable/${account}/`, `internal/${account}/`]) {
    const listed = await bucket.list({ prefix, limit: min });
    count += listed.objects.length;
    if (count >= min) return true;
  }
  return count >= min;
}

/** Marqueur `validated/<account>` OU enregistrements présents. */
export async function hasCompletionProof(bucket, account, min) {
  if ((await bucket.head(`validated/${account}`)) !== null) return true;
  return hasEnoughRecordings(bucket, account, min);
}
