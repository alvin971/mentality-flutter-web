// lib/data/reading_texts.dart
// Modèle d'un texte de lecture pour la collecte audio STT.
//
// Le corpus réel vit dans assets/reading_corpus/*.jsonl et est chargé
// dynamiquement par [ReadingCorpusService] — voir reading_corpus_service.dart.
//
// Corpus v2 (2026-08-14) : 1000 FAMILLES alignées sur six langues, soit 6000
// textes. Une famille = un contenu, six réalisations natives reliées par le
// champ `family` — ce qui rend les enregistrements comparables d'une langue à
// l'autre, le contenu cessant d'être une variable parasite. Aucun texte ne
// contient de nom propre ni d'ancrage culturel : c'est ce qui permet à la même
// information d'exister dans les six langues sans trahir son origine.
//
// Les identifiants portent la révision (`fr_v2_00123`) parce que v1 et v2
// partageaient 493 numéros sur des textes différents : sans ce marquage, les
// enregistrements déjà collectés seraient devenus inattribuables.

class ReadingText {
  final String id;
  final String title;
  final String body;
  final int approximateWordCount;

  const ReadingText({
    required this.id,
    required this.title,
    required this.body,
    required this.approximateWordCount,
  });
}
