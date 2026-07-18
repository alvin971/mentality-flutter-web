// lib/core/services/token_account.dart
//
// Dérive l'IDENTITÉ DE COMPTE (partition opaque) portée par un token.
//
// MIROIR EXACT de la dérivation serveur (workers/_shared/token_verify.js) :
//     account = SHA256(nonce)[:32]
// Les deux DOIVENT rester alignés : c'est la même identité qui partitionne les
// données côté worker (parrainage, progression) et côté app (historique local).
//
// ⚠️ PORTÉE : ce calcul n'authentifie RIEN — il ne vérifie pas la signature.
// Il ne sert qu'à savoir « à quel passe appartient cette donnée locale ». Un
// token altéré donne simplement un autre compte (donc aucun résultat visible),
// ce qui est le comportement fail-safe recherché. Le contrôle d'accès réel
// reste la re-vérification Ed25519 côté serveur.

import 'dart:convert';

import 'package:cryptography/cryptography.dart';

class TokenAccount {
  TokenAccount._();

  /// Longueur de la partition (miroir du `.slice(0, 32)` du worker).
  static const int accountLength = 32;

  static final _sha256 = Sha256();

  /// Identité de compte portée par [token], ou `null` si le token est absent
  /// ou inexploitable. Accepte les deux formes : signée (3 segments) et DEV
  /// non signée (`M2.<claims>`).
  static Future<String?> fromToken(String? token) async {
    final nonce = nonceOf(token);
    if (nonce == null) return null;
    final digest = await _sha256.hash(utf8.encode(nonce));
    final hex = digest.bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    return hex.substring(0, accountLength);
  }

  /// Nonce (claim `n`) porté par [token], quelle que soit sa forme. Renvoie
  /// `null` si le token est malformé ou si le nonce est absent/invalide.
  static String? nonceOf(String? token) {
    if (token == null || token.isEmpty) return null;
    final parts = token.split('.');
    // Signé : header.payload.signature — DEV : M2.payload
    final int payloadIndex;
    if (parts.length == 3) {
      payloadIndex = 1;
    } else if (parts.length == 2 && parts[0] == 'M2') {
      payloadIndex = 1;
    } else {
      return null;
    }
    try {
      final seg = parts[payloadIndex];
      final normalized = base64Url.normalize(seg);
      final claims = jsonDecode(utf8.decode(base64Url.decode(normalized)));
      if (claims is! Map) return null;
      final n = claims['n'];
      return (n is String && n.isNotEmpty) ? n : null;
    } catch (_) {
      return null;
    }
  }
}
