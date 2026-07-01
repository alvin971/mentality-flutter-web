// lib/data/reading_texts.dart
// Modèle d'un texte de lecture pour la collecte audio STT.
//
// Le corpus réel (753 textes, 6 langues) vit dans assets/reading_corpus/*.jsonl
// et est chargé dynamiquement par [ReadingCorpusService] — voir
// reading_corpus_service.dart.

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
