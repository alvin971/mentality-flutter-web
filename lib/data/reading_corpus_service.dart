// lib/data/reading_corpus_service.dart
// Charge le corpus de lecture (assets/reading_corpus/<lang>.jsonl) et pioche
// des textes aléatoires par session, en évitant les répétitions tant que le
// corpus de la langue courante n'a pas été entièrement parcouru.

import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/l10n/locale_notifier.dart';
import 'reading_texts.dart';

class ReadingCorpusService {
  ReadingCorpusService._();

  static final ReadingCorpusService instance = ReadingCorpusService._();

  static const Map<String, String> _assetByTag = {
    'fr': 'fr',
    'en': 'en',
    'en-GB': 'en_GB',
    'es': 'es',
    'pt': 'pt',
    'de': 'de',
  };

  final Map<String, List<ReadingText>> _cache = {};

  String _assetNameForTag(String tag) => _assetByTag[tag] ?? 'fr';

  String _usedIdsPrefsKey(String asset) => 'reading_corpus_used_ids_$asset';

  Future<List<ReadingText>> _loadCorpus(String asset) async {
    final cached = _cache[asset];
    if (cached != null) return cached;

    final raw =
        await rootBundle.loadString('assets/reading_corpus/$asset.jsonl');
    final texts = raw
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .map((line) {
      final json = jsonDecode(line) as Map<String, dynamic>;
      final body = (json['text'] as String).trim();
      final domaine = (json['domaine'] as String?) ?? '';
      return ReadingText(
        id: json['id'] as String,
        title: domaine.isNotEmpty
            ? domaine[0].toUpperCase() + domaine.substring(1)
            : '',
        body: body,
        approximateWordCount: body.split(RegExp(r'\s+')).length,
      );
    }).toList();

    _cache[asset] = texts;
    return texts;
  }

  /// Pioche [count] textes dans le corpus de la langue courante, en évitant
  /// les textes déjà servis lors des sessions précédentes. Une fois le corpus
  /// épuisé, l'historique est réinitialisé pour repartir sur un cycle complet.
  Future<List<ReadingText>> pickSessionTexts({int count = 5}) async {
    final asset = _assetNameForTag(localeNotifier.contentTag);
    final corpus = await _loadCorpus(asset);

    final prefs = await SharedPreferences.getInstance();
    final key = _usedIdsPrefsKey(asset);
    var usedIds = (prefs.getStringList(key) ?? const <String>[]).toSet();

    var available =
        corpus.where((t) => !usedIds.contains(t.id)).toList(growable: false);
    if (available.length < count) {
      usedIds = {};
      available = corpus;
    }

    final picked = (List.of(available)..shuffle(Random())).take(count).toList();

    usedIds.addAll(picked.map((t) => t.id));
    await prefs.setStringList(key, usedIds.toList());

    return picked;
  }
}
