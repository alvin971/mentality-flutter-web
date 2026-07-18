// lib/services/session_history_service.dart
// Stockage local des sessions de test terminées (historique des résultats).
//
// Chaque entrée contient les scores finaux pour affichage dans ResultsHistoryPage.
// Utilise la box Hive 'session_history' (chiffrée avec la même clé AES que sell).

import 'dart:convert';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:hive_flutter/hive_flutter.dart';

import '../core/services/auth_local_store.dart';
import '../core/services/token_account.dart';

/// Un résumé de session sauvegardé dans l'historique.
class SessionHistoryEntry {
  final String id;

  /// Identité du passe (TokenAccount) qui a produit ce résultat. `null` pour
  /// les entrées écrites avant l'introduction du tampon : impossible de
  /// deviner leur propriétaire, elles ne sont donc affichées à PERSONNE
  /// (fail-closed — cf. getAll()).
  final String? account;
  final DateTime date;
  final int ageInMonths;
  final int fsiq;
  final int? vci;
  final int? vsi;
  final int? fri;
  final int? wmi;
  final int? psi;
  final String classification;

  const SessionHistoryEntry({
    required this.id,
    this.account,
    required this.date,
    required this.ageInMonths,
    required this.fsiq,
    this.vci,
    this.vsi,
    this.fri,
    this.wmi,
    this.psi,
    required this.classification,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        if (account != null) 'account': account,
        'date': date.toIso8601String(),
        'ageInMonths': ageInMonths,
        'fsiq': fsiq,
        if (vci != null) 'vci': vci,
        if (vsi != null) 'vsi': vsi,
        if (fri != null) 'fri': fri,
        if (wmi != null) 'wmi': wmi,
        if (psi != null) 'psi': psi,
        'classification': classification,
      };

  /// Copie tamponnée avec l'identité du passe [account].
  SessionHistoryEntry withAccount(String? account) => SessionHistoryEntry(
        id: id,
        account: account,
        date: date,
        ageInMonths: ageInMonths,
        fsiq: fsiq,
        vci: vci,
        vsi: vsi,
        fri: fri,
        wmi: wmi,
        psi: psi,
        classification: classification,
      );

  static SessionHistoryEntry fromMap(Map<dynamic, dynamic> map) =>
      SessionHistoryEntry(
        id: map['id'] as String,
        account: map['account'] as String?,
        date: DateTime.parse(map['date'] as String),
        ageInMonths: map['ageInMonths'] as int,
        fsiq: map['fsiq'] as int,
        vci: map['vci'] as int?,
        vsi: map['vsi'] as int?,
        fri: map['fri'] as int?,
        wmi: map['wmi'] as int?,
        psi: map['psi'] as int?,
        classification: map['classification'] as String,
      );
}

/// Singleton qui gère l'historique des évaluations terminées.
class SessionHistoryService {
  static final SessionHistoryService instance = SessionHistoryService._();
  SessionHistoryService._();

  static const String _boxName = 'session_history';

  Box<dynamic>? _box;
  bool _initialized = false;

  Future<void> initialize({HiveCipher? encryptionCipher}) async {
    if (_initialized) return;
    _box = await Hive.openBox<dynamic>(
      _boxName,
      encryptionCipher: encryptionCipher,
    );
    _initialized = true;
  }

  void _assertReady() {
    assert(_initialized, 'SessionHistoryService.initialize() n\'a pas été appelé.');
  }

  /// Sauvegarde un résultat de session dans l'historique, TAMPONNÉ avec
  /// l'identité du passe courant (voir [SessionHistoryEntry.account]).
  /// Le tampon fourni dans [entry] prime (utile aux tests) ; sinon il est
  /// dérivé du token local.
  Future<void> saveEntry(SessionHistoryEntry entry) async {
    _assertReady();
    final stamped = entry.account != null
        ? entry
        : entry.withAccount(await currentAccount());
    await _box!.put(stamped.id, jsonEncode(stamped.toMap()));
  }

  /// Identité du passe actuellement connecté, ou `null` si aucun token.
  ///
  /// Ne propage jamais d'exception : un incident de lecture du passe ne doit
  /// ni faire perdre un résultat à l'écriture, ni révéler l'historique d'un
  /// autre passe à la lecture (null ⇒ liste vide, fail-closed).
  Future<String?> currentAccount() async {
    try {
      return await TokenAccount.fromToken(
          await AuthLocalStore.instance.getToken());
    } catch (_) {
      return null;
    }
  }

  /// Résultats DU PASSE COURANT uniquement, du plus récent au plus ancien.
  ///
  /// Fail-closed : sans passe connecté, ou pour les entrées non tamponnées
  /// (antérieures au tampon, propriétaire inconnu), rien n'est renvoyé — un
  /// résultat n'est jamais montré à un passe qui ne l'a pas produit.
  Future<List<SessionHistoryEntry>> getAllForCurrentAccount() async =>
      entriesForAccount(await currentAccount());

  /// Résultats appartenant à [account]. `account == null` (aucun passe) →
  /// liste vide ; les entrées non tamponnées ne matchent jamais un compte
  /// réel, donc restent invisibles.
  List<SessionHistoryEntry> entriesForAccount(String? account) {
    if (account == null) return const [];
    return _decodeAll().where((e) => e.account == account).toList();
  }

  /// Toutes les entrées stockées, tous passes confondus (maintenance/tests).
  /// L'UI doit utiliser [getAllForCurrentAccount].
  @visibleForTesting
  List<SessionHistoryEntry> getAll() => _decodeAll();

  List<SessionHistoryEntry> _decodeAll() {
    _assertReady();
    final entries = <SessionHistoryEntry>[];
    for (final value in _box!.values) {
      try {
        final map = jsonDecode(value as String) as Map<String, dynamic>;
        entries.add(SessionHistoryEntry.fromMap(map));
      } catch (_) {
        // Ignorer les entrées corrompues
      }
    }
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  /// Supprime une entrée par son identifiant.
  Future<void> deleteEntry(String id) async {
    _assertReady();
    await _box!.delete(id);
  }

  /// Nombre d'évaluations sauvegardées.
  int get count {
    _assertReady();
    return _box!.length;
  }
}
