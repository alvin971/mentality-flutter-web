# Lexique juridique — ce que Mentality dit d'elle-même

> Contrat de vocabulaire issu de l'audit du 2026-08-28.
> **La loop `/loop` applique ce fichier à la lettre.** Pour changer le résultat,
> on modifie CE fichier, pas les textes un par un.

---

## 0. Postulat de positionnement — À VALIDER AVANT DE LANCER LA LOOP

**Mentality (mentality-flutter-web) s'adresse au GRAND PUBLIC.**

Fondé sur l'état du projet : pivot mobile-only, déblocage par parrainage,
événement de gamification, aucun compte requis. L'app **professionnelle**
est `mentality-admin` — c'est elle qui parle aux psychologues, pas celle-ci.

Conséquence : tout ce qui positionne l'app comme outil clinique sort.
**Si ce postulat est faux, ne pas lancer la loop : corriger ici d'abord.**

---

## 1. Les trois ancres de crédibilité (ce qu'on dit À LA PLACE)

On ne se tait pas — on s'appuie sur ce qui nous appartient réellement.

| Ancre | Pourquoi elle est sûre |
|---|---|
| **Modèle CHC (Cattell-Horn-Carroll)** | Cadre théorique **académique, domaine public**. Personne ne le possède. C'est déjà ce que l'app fait. Sonne aussi sérieux que « WAIS », sans le risque. |
| **Théorie de réponse à l'item (IRT)** | Une **méthode**, pas une marque. Librement citable. |
| **Nos items sont originaux** | Vérifié à l'audit : banques écrites maison. C'est notre actif réel — on l'affirme au lieu de le cacher derrière un nom d'emprunt. |

**Règle mère :** *ne jamais écrire une phrase qu'on ne peut pas prouver avec une pièce.*

---

## 2. Table de remplacement — INTERDIT → AUTORISÉ

### 2.1 Marques de tiers (Pearson / ECPA)

| ❌ Interdit | ✅ Remplacement |
|---|---|
| `WAIS`, `WAIS-IV`, `WISC`, `WPPSI`, `Wechsler` | **Supprimer.** Si un cadre est nécessaire → « le modèle CHC ». |
| « basée sur le WAIS-IV » | « construite sur le modèle CHC (Cattell-Horn-Carroll) » |
| « BILAN WAIS-IV » (surtitre résultats) | « VOTRE PROFIL COGNITIF » |
| « Rapport d'évaluation cognitive WAIS-IV » (PDF) | « Rapport de profil cognitif » |
| « inspiré des échelles Wechsler » | **Supprimer aussi.** Licite isolément, mais on ne garde aucune tête de pont. |
| « la référence mondiale » | Supprimer — on ne vante pas la marque d'autrui. |
| « g-loading : 0.78 (le plus élevé du WAIS-IV) » | « Cet exercice est fortement lié au raisonnement général. » |
| « 3 scores de 0 consécutifs — Test terminé (WAIS-IV) » | Retirer la parenthèse **et** aligner sur la règle réelle (arrêt sur renoncement depuis le 2026-08-24). |

### 2.2 Acronymes Wechsler dans l'interface

Ces sigles sont la nomenclature du WAIS-IV. Les noms français, eux, restent.

| ❌ | ✅ |
|---|---|
| `FSIQ` | Supprimer le sigle. **« QI » reste autorisé** (terme générique, aucune marque). |
| « QI TOTAL · FSIQ » | « SCORE GLOBAL » |
| « SCORE QI GLOBAL (FSIQ) » (PDF) | « SCORE GLOBAL » |
| `VCI`, `VSI`, `FRI`, `WMI`, `PSI` | Garder **uniquement** le nom français : « Compréhension verbale », « Visuo-spatial », « Raisonnement fluide », « Mémoire de travail », « Vitesse de traitement ». |

### 2.3 Allégations invérifiables

| ❌ | ✅ |
|---|---|
| « 12 tests cognitifs **scientifiquement validés** » | « 13 exercices cognitifs originaux » |
| « **Validation scientifique** » (titre) | « Cadre théorique » |
| « Une évaluation **scientifique** adaptative » | « Une évaluation cognitive adaptative » |
| « avec la **précision des tests utilisés par les psychologues** » | Supprimer la phrase entière. |
| « Évaluation **fiable** en 30 à 60 minutes » | « Comptez 60 à 90 minutes » *(→ vérifier la durée réelle, cf. §4)* |
| « intervalles de confiance à **95 %** » | Supprimer de tout texte commercial. |
| « conformité RGPD et **recommandations de la CNIL** » | « Traitement conforme au RGPD » — **la CNIL ne certifie aucune app** ; suggérer son aval relève de l'art. L.121-4, 4° C. conso. |

### 2.4 Le mensonge factuel — priorité absolue

| ❌ | ✅ |
|---|---|
| « **Stockage local uniquement** — vos résultats restent sur votre appareil » | « Chiffrement AES-256 sur l'appareil · Hébergement en France (Paris) · Aucune revente de données » |

**Faux** : `lib/core/services/results_sync.dart` envoie vers Supabase (Paris) et
Cloudflare Workers. Une affirmation fausse sur des données de santé = pratique
commerciale trompeuse (C. conso. L.121-2) **et** manquement à la loyauté RGPD.

### 2.5 Cadrage clinique (risque dispositif médical — Règl. UE 2017/745)

| ❌ | ✅ |
|---|---|
| « conçue pour les professionnels de santé mentale et leurs patients » | « pour toute personne curieuse de son fonctionnement cognitif » |
| Section « POUR LES PSYCHOLOGUES / Administrez des bilans » | **Supprimer la section entière.** |
| « dossiers cliniques » | « vos archives personnelles » |
| « patient » | « participant » — ou la 2ᵉ personne (« votre âge »). |
| « bilan » | « évaluation », « parcours », « profil » |

⚠️ **Exception — NE PAS TOUCHER :** `ctPdfDisclaimer`, `ctIndicativeDisclaimer`.
Ces avertissements citent « clinique » et « psychologue » **pour s'en distinguer**.
C'est notre meilleure défense. On y touche pas.

### 2.6 Noms des sous-tests

Pris ensemble, ils reconstituent la nomenclature française ECPA du WAIS-IV.
On renomme **les plus signés**, on garde les mots ordinaires.

| Actuel | Décision |
|---|---|
| Similitudes | → **Points communs** |
| Code | → **Transcription** |
| Symboles / Recherche de symboles | → **Détection de symboles** |
| Balances | → **Équilibres** |
| Puzzles Visuels | → **Assemblages** |
| Mémoire des Chiffres | → **Suites de chiffres** |
| Cubes · Matrices · Vocabulaire · Information · Arithmétique | **Garder** — mots courants, employés par de nombreux tests. |

---

## 3. Le prompt du chat IA — traitement spécial

`lib/features/chat/presentation/services/claude_chat_service.dart` (5 langues).

Ce n'est pas une phrase figée : c'est un **porte-parole génératif**. Lui dire
qu'il est « basé sur le WAIS-IV » lui fait produire des affirmations qu'on
n'a jamais écrites et qu'on ne peut pas relire.

- ❌ « spécialisé dans l'évaluation cognitive basée sur les échelles WAIS-IV »
- ✅ « spécialisé en psychologie cognitive, qui accompagne les utilisateurs de Mental E.T. »
- ➕ **Ajouter une interdiction explicite** dans les 5 langues :
  *« Ne jamais mentionner le WAIS, le WISC, le WPPSI ni les échelles Wechsler.
  Ne jamais présenter Mental E.T. comme équivalent à un test clinique.
  Ne jamais poser de diagnostic. »*
- ✅ **Conserver** les garde-fous existants (« pas de diagnostic », « consulter un professionnel »).

---

## 4. Incohérences à trancher pendant le chantier

L'audit a relevé deux chiffres contradictoires. **Vérifier ce que l'app EXÉCUTE**
(pas un `.md`, pas `testSequence` seul), puis aligner partout :

- **Nombre d'exercices** : l'app affiche 13, la fiche App Store dit 12.
- **Durée** : l'app dit 60–90 min, la fiche App Store dit 30–60 min.

---

## 5. Fiche App Store — texte de remplacement complet

### `keywords.txt`
```
profil cognitif,exercices cognitifs,mémoire,raisonnement,logique,attention,concentration,QI,test logique,cognition,CHC
```
*(WAIS et FSIQ retirés : mot-clé = captation pure de notoriété, indéfendable
en droit comme au regard des règles ASO d'Apple et Google.)*

### `promotional_text.txt`
```
13 exercices cognitifs originaux, profil sur 5 domaines, rapport PDF, assistant IA. Gratuit, sans compte — découvrez votre façon de raisonner.
```

### `description.txt`
```
Découvrez votre profil cognitif.

Mental E.T. propose une série d'exercices originaux pour explorer votre façon de raisonner, de mémoriser et de traiter l'information. Aucun compte requis — commencez dès le premier écran.


CE QUE C'EST

13 exercices cognitifs construits selon le modèle CHC (Cattell-Horn-Carroll), le cadre de référence académique des aptitudes humaines. Chaque exercice explore une aptitude ; l'ensemble dessine votre profil.


CE QUE CE N'EST PAS

Ni un test clinique, ni un diagnostic, ni un substitut à l'évaluation d'un psychologue. Vos résultats sont indicatifs.


LES CINQ DOMAINES EXPLORÉS

• Compréhension verbale — points communs, vocabulaire, culture générale
• Raisonnement visuo-spatial — cubes, assemblages
• Raisonnement fluide — matrices, équilibres
• Mémoire de travail — suites de chiffres, calcul mental
• Vitesse de traitement — transcription, détection de symboles

+ Module optionnel Langage oral : lecture à voix haute et résumé.


VOS RÉSULTATS

• Un profil sur les cinq domaines
• Un score global qui les résume
• Un rang percentile pour situer votre résultat
• Un rapport PDF exportable


DIFFICULTÉ ADAPTATIVE

La difficulté s'ajuste au fil de vos réponses (théorie de réponse à l'item). Vous pouvez interrompre le parcours et le reprendre là où vous l'aviez laissé.


ASSISTANT IA

Posez vos questions sur vos résultats et sur le fonctionnement cognitif. L'assistant n'établit aucun diagnostic et vous oriente vers un professionnel quand c'est utile.


VOS DONNÉES

• Chiffrement AES-256 sur l'appareil
• Hébergement en France (Paris)
• Traitement conforme au RGPD
• Aucune publicité, aucune revente de données, gratuit


Mental E.T. — Explorez votre fonctionnement cognitif.
```

*(Le nombre d'exercices et la durée sont à confirmer — cf. §4.)*

---

## 6. Ce qu'on ne touche sous AUCUN prétexte

1. **Les banques d'items** (`*_items_*.dart`) — originales, c'est notre actif.
2. **Le calcul du score / FSIQ / ICV** (`ScoringService`, `_FSIQCard`) — le
   fondateur traite la notation par IA séparément. Ici on ne fait que du texte.
3. **`lib/l10n/*.arb`** — régénérés par `_merge.py`. Toute édition directe est effacée.
4. **Les disclaimers** `ctPdfDisclaimer` / `ctIndicativeDisclaimer` (cf. §2.5).
5. **La doctrine « jeu ≠ mesure clinique »** de l'événement — déjà exemplaire.

---

## 7. Base juridique (pour mémoire)

- **Marque** : art. L.713-6 CPI — usage référentiel licite **si** nécessaire à
  indiquer la destination **et** conforme aux usages loyaux. Un mot-clé ASO ne l'est pas.
- **Parasitisme** : art. 1240 C. civ. — se placer dans le sillage d'un
  investissement d'autrui. **N'exige aucun risque de confusion.**
- **Pratique commerciale trompeuse** : C. conso. L.121-2 et L.121-4.
  Sanction L.132-2 : 2 ans, 300 000 €, portable à 10 % du CA annuel moyen.
- **Dispositif médical** : Règl. UE 2017/745, règle 11 — un logiciel revendiqué
  pour des décisions diagnostiques est un DM (classe IIa+), marquage CE requis.
- **Titre de psychologue** : loi n° 85-772 du 25 juillet 1985, art. 44.
- **Stores** : App Store 5.2.1 (PI) et 1.4.1 (santé) ; Google Play (allégations
  médicales, usurpation).
