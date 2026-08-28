# 🏗️ Architecture Technique - Mentality

## Vue d'ensemble

**Mentality** est une application mobile Flutter d'évaluation cognitive construite sur le modèle CHC (Cattell-Horn-Carroll), avec des items originaux et la théorie de réponse à l'item (IRT) pour ajuster la difficulté.

## Principes Architecturaux

### Clean Architecture

L'application suit les principes de Clean Architecture avec 3 couches principales :

```
┌─────────────────────────────────────────────────────────────┐
│                   PRESENTATION LAYER                        │
│  • UI (Pages, Widgets)                                     │
│  • BLoC (Business Logic Components)                       │
│  • State Management                                        │
│  Responsabilité : Interface utilisateur et gestion d'état  │
├─────────────────────────────────────────────────────────────┤
│                      DOMAIN LAYER                           │
│  • Entities (Modèles métier purs)                         │
│  • Use Cases (Logique métier)                             │
│  • Repository Interfaces (Contrats)                       │
│  Responsabilité : Règles métier de l'application          │
├─────────────────────────────────────────────────────────────┤
│                       DATA LAYER                            │
│  • Repository Implementations                              │
│  • Data Sources (Local, Remote, AI)                       │
│  • DTOs & Mappers                                          │
│  Responsabilité : Accès et persistance des données        │
└─────────────────────────────────────────────────────────────┘
```

### Avantages

1. **Séparation des responsabilités** : Chaque couche a un rôle précis
2. **Testabilité** : Les use cases peuvent être testés indépendamment
3. **Maintenabilité** : Modifications isolées par couche
4. **Scalabilité** : Ajout facile de nouvelles fonctionnalités
5. **Indépendance des frameworks** : La logique métier ne dépend pas de Flutter

---

## Gestion d'État : BLoC Pattern

### Pourquoi BLoC ?

- ✅ Séparation claire UI/Logique
- ✅ État prévisible et testable
- ✅ Recommandé par Google
- ✅ Excellent pour apps complexes
- ✅ Support des streams pour réactivité

### Structure d'un BLoC

```dart
// Event
abstract class AssessmentEvent extends Equatable {}

class StartAssessment extends AssessmentEvent {
  final String userId;
  StartAssessment(this.userId);
}

// State
abstract class AssessmentState extends Equatable {}

class AssessmentInitial extends AssessmentState {}
class AssessmentLoading extends AssessmentState {}
class AssessmentInProgress extends AssessmentState {
  final AssessmentSession session;
  AssessmentInProgress(this.session);
}

// BLoC
class AssessmentBloc extends Bloc<AssessmentEvent, AssessmentState> {
  final StartAssessmentUseCase startAssessment;

  AssessmentBloc({required this.startAssessment})
    : super(AssessmentInitial()) {
    on<StartAssessment>(_onStartAssessment);
  }

  Future<void> _onStartAssessment(
    StartAssessment event,
    Emitter<AssessmentState> emit,
  ) async {
    emit(AssessmentLoading());
    final result = await startAssessment(event.userId);
    result.fold(
      (failure) => emit(AssessmentError(failure.message)),
      (session) => emit(AssessmentInProgress(session)),
    );
  }
}
```

---

## Dépendances et Packages Clés

### State Management & Architecture

| Package | Version | Usage |
|---------|---------|-------|
| `flutter_bloc` | ^8.1.6 | Gestion d'état BLoC |
| `equatable` | ^2.0.5 | Comparaison d'objets |
| `get_it` | ^8.0.2 | Injection de dépendances |
| `injectable` | ^2.5.0 | Code generation pour DI |
| `dartz` | ^0.10.1 | Programmation fonctionnelle (Either) |

### Réseau & API

| Package | Version | Usage |
|---------|---------|-------|
| `dio` | ^5.7.0 | Client HTTP |
| `retrofit` | ^4.4.1 | API client type-safe |
| `connectivity_plus` | ^6.1.0 | Détection de connectivité |

### Base de données locale

| Package | Version | Usage |
|---------|---------|-------|
| `hive` | ^2.2.3 | Base NoSQL légère |
| `drift` | ^2.21.0 | ORM SQLite |
| `shared_preferences` | ^2.3.3 | Stockage clé-valeur |

### Intelligence Artificielle

| Package | Version | Usage |
|---------|---------|-------|
| `google_generative_ai` | ^0.4.6 | Génération d'items par IA |
| `tflite_flutter` | ^0.11.0 | ML on-device |

### Audio & TTS

| Package | Version | Usage |
|---------|---------|-------|
| `flutter_tts` | ^4.2.0 | Text-to-Speech |
| `speech_to_text` | ^7.0.0 | Reconnaissance vocale |

### UI & Animations

| Package | Version | Usage |
|---------|---------|-------|
| `flutter_screenutil` | ^5.9.3 | Responsive design |
| `lottie` | ^3.1.3 | Animations JSON |
| `flutter_animate` | ^4.5.0 | Animations déclaratives |
| `fl_chart` | ^0.70.1 | Graphiques et charts |

---

## Flux de Données

### Pattern Repository

```
┌──────────┐      ┌────────────┐      ┌────────────────┐
│   UI     │ ───> │    BLoC    │ ───> │   Use Case     │
│ (Widget) │      │  (Event)   │      │ (Business Logic│
└──────────┘      └────────────┘      └────────────────┘
                         │                      │
                         │                      ▼
                         │            ┌────────────────┐
                         │            │  Repository    │
                         │            │  (Interface)   │
                         │            └────────────────┘
                         │                      │
                         ▼                      ▼
                  ┌────────────┐      ┌────────────────┐
                  │   State    │      │ Repository Impl│
                  └────────────┘      └────────────────┘
                         │                      │
                         │                      ▼
                         │            ┌────────────────┐
                         │            │  Data Sources  │
                         │            │ (Local/Remote) │
                         │            └────────────────┘
                         │
                         ▼
                  ┌──────────┐
                  │    UI    │
                  │ (Update) │
                  └──────────┘
```

### Exemple concret : Démarrer une évaluation

```dart
// 1. UI déclenche l'événement
context.read<AssessmentBloc>().add(StartAssessment(userId));

// 2. BLoC reçoit l'événement et appelle le use case
final result = await startAssessmentUseCase(userId);

// 3. Use Case orchestre la logique métier
class StartAssessmentUseCase {
  final AssessmentRepository repository;

  Future<Either<Failure, AssessmentSession>> call(String userId) async {
    // Récupère le profil utilisateur
    final profile = await profileRepository.getProfile(userId);

    // Détermine le groupe d'âge
    final ageGroup = _calculateAgeGroup(profile.ageInMonths);

    // Sélectionne les sous-tests appropriés
    final subtests = _selectSubtests(ageGroup);

    // Crée la session
    return await repository.createSession(
      userId: userId,
      ageGroup: ageGroup,
      subtests: subtests,
    );
  }
}

// 4. Repository implémentation appelle le data source
class AssessmentRepositoryImpl implements AssessmentRepository {
  final AssessmentLocalDataSource localDataSource;

  @override
  Future<AssessmentSession> createSession(...) async {
    final model = AssessmentSessionModel(...);
    await localDataSource.saveSession(model);
    return model.toEntity();
  }
}

// 5. Data source persiste les données
class AssessmentLocalDataSource {
  final HiveInterface hive;

  Future<void> saveSession(AssessmentSessionModel model) async {
    final box = await hive.openBox('assessments');
    await box.put(model.id, model.toJson());
  }
}

// 6. BLoC émet le nouvel état
emit(AssessmentInProgress(session));

// 7. UI se reconstruit automatiquement
BlocBuilder<AssessmentBloc, AssessmentState>(
  builder: (context, state) {
    if (state is AssessmentInProgress) {
      return AssessmentSessionPage(session: state.session);
    }
    return Container();
  },
)
```

---

## Modèle de Données Principal

### Entités Clés

#### 1. AssessmentSession

Représente une session d'évaluation complète.

```dart
class AssessmentSession {
  final String id;
  final String userId;
  final String ageGroup;
  final DateTime startDate;
  final AssessmentState state;
  final List<String> plannedSubtests;
  final List<String> completedSubtests;
  final TestingMode mode; // adaptive | standard
}
```

#### 2. ExerciseItem

Unité de base de l'évaluation.

```dart
class ExerciseItem {
  final String id;
  final ExerciseType type;
  final double difficulty; // Paramètre IRT
  final double discrimination; // Paramètre IRT
  final Stimulus stimulus;
  final List<ResponseOption>? options;
  final String correctAnswer;

  // Calcul IRT
  double calculateProbability(double theta) {
    return 1 / (1 + exp(-discrimination * (theta - difficulty)));
  }
}
```

#### 3. ThetaEstimate

Estimation de la capacité cognitive.

```dart
class ThetaEstimate {
  final double theta; // Capacité estimée
  final double standardError;
  final List<ResponseRecord> responseHistory;

  // Mise à jour bayésienne
  ThetaEstimate updateWithResponse({
    required double itemDifficulty,
    required double itemDiscrimination,
    required bool isCorrect,
  });
}
```

#### 4. IQScore

Résultat final avec tous les indices.

```dart
class IQScore {
  final int fsiq; // QI Total
  final int? vci; // Compréhension Verbale
  final int? vsi; // Visuo-Spatial
  final int? fri; // Raisonnement Fluide
  final int? wmi; // Mémoire de Travail
  final int? psi; // Vitesse de Traitement
  final Map<String, ConfidenceInterval> confidenceIntervals;
}
```

---

## Testing Adaptatif Informatisé (CAT)

### Algorithme de sélection d'items

```
┌─────────────────────────────────────────────────────────┐
│  ALGORITHME CAT (Computerized Adaptive Testing)        │
├─────────────────────────────────────────────────────────┤
│  1. Initialisation                                     │
│     θ₀ = 0.0 (capacité moyenne)                        │
│     SE₀ = 1.0 (incertitude maximale)                   │
│                                                         │
│  2. Sélection du premier item                          │
│     item₁ = item avec difficulté ≈ θ₀                  │
│                                                         │
│  3. Pour chaque réponse :                              │
│     a) Mettre à jour θ (Newton-Raphson)                │
│        θₙ₊₁ = θₙ - L'(θ) / L''(θ)                      │
│        où L = log-vraisemblance                        │
│                                                         │
│     b) Calculer SE(θₙ₊₁)                               │
│        SE = 1 / √I(θ)                                  │
│        où I = information de Fisher                    │
│                                                         │
│     c) Sélectionner item suivant                       │
│        itemₙ₊₁ = argmax I(θₙ₊₁)                        │
│                                                         │
│  4. Critère d'arrêt :                                  │
│     STOP si SE < 0.3 OU N ≥ 15 items                   │
│                                                         │
│  5. Score final :                                      │
│     QI = 100 + 15×θ_final                              │
└─────────────────────────────────────────────────────────┘
```

### Implémentation

```dart
class SelectNextItemUseCase {
  final ItemBankRepository itemBank;

  Future<ExerciseItem> call(ThetaEstimate currentTheta, String subtestCode) async {
    // Récupère tous les items non administrés du sous-test
    final availableItems = await itemBank.getAvailableItems(
      subtestCode: subtestCode,
      excludeIds: currentTheta.responseHistory.map((r) => r.itemId).toList(),
    );

    // Calcule l'information apportée par chaque item
    ExerciseItem? bestItem;
    double maxInformation = 0.0;

    for (final item in availableItems) {
      final information = currentTheta.calculateItemInformation(
        item.difficulty,
        item.discrimination,
      );

      if (information > maxInformation) {
        maxInformation = information;
        bestItem = item;
      }
    }

    return bestItem!;
  }
}
```

---

## Génération d'Items par IA

### Flux de génération

```
User Request
     │
     ▼
┌────────────────────┐
│ AI Generator Bloc  │
└────────────────────┘
     │
     ▼
┌──────────────────────────┐
│ Generate Matrix Item UC  │
│ • Type: matrix_reasoning │
│ • Difficulty: θ = 0.5    │
│ • Rules: rotation + color│
└──────────────────────────┘
     │
     ▼
┌────────────────────────┐
│ AI Remote DataSource   │
│ • Google Gemini API    │
│ • Prompt engineering   │
└────────────────────────┘
     │
     ▼
┌────────────────────────┐
│   Generated Item       │
│ • Stimulus (base64)    │
│ • Options (4-6)        │
│ • Correct answer       │
│ • Estimated difficulty │
└────────────────────────┘
     │
     ▼
┌────────────────────────┐
│ Validation             │
│ • Solvability check    │
│ • Uniqueness check     │
│ • IRT calibration      │
└────────────────────────┘
     │
     ▼
┌────────────────────────┐
│ Item Bank Storage      │
│ (Hive + Firestore)     │
└────────────────────────┘
```

### Prompt Example (Matrices)

```dart
class MatrixItemGenerator {
  final GenerativeModel model;

  Future<GeneratedItem> generate(double targetDifficulty) async {
    final prompt = '''
Generate a progressive matrix reasoning item with the following specifications:

Target Difficulty: $targetDifficulty (on IRT scale -3 to +3)

Rules to apply:
- Grid size: 2x2 (easy) or 3x3 (medium/hard)
- Pattern rules: ${_selectRules(targetDifficulty)}
- Number of distractors: ${_getDistractorCount(targetDifficulty)}

Output format (JSON):
{
  "grid": [[cell1, cell2], [cell3, "?"]],
  "correctAnswer": "option_id",
  "options": [
    {"id": "A", "content": "base64_image"},
    {"id": "B", "content": "base64_image"},
    ...
  ],
  "rules": ["rotation_90", "color_progression"],
  "estimatedDifficulty": 0.5
}

Generate unique, solvable items only.
''';

    final response = await model.generateContent([Content.text(prompt)]);
    return GeneratedItem.fromJson(json.decode(response.text));
  }
}
```

---

## Système de Scoring

### Conversion Scores Bruts → QI

```
Score Brut (sous-test)
     │
     ▼
┌────────────────────────────────────┐
│ Tables Normatives (par âge)       │
│ • Age: 6 ans 3 mois                │
│ • Subtest: Matrix Reasoning        │
│ • Raw Score: 18                    │
└────────────────────────────────────┘
     │
     ▼
┌────────────────────────────────────┐
│ Note Standard                      │
│ • Scaled Score: 12                 │
│ • Mean: 10, SD: 3                  │
└────────────────────────────────────┘
     │
     ▼
┌────────────────────────────────────┐
│ Somme des Notes Standard           │
│ • FRI: MR(12) + FW(11) = 23        │
└────────────────────────────────────┘
     │
     ▼
┌────────────────────────────────────┐
│ Indice Composite                   │
│ • Sum: 23 → FRI: 105               │
│ • Mean: 100, SD: 15                │
└────────────────────────────────────┘
     │
     ▼
┌────────────────────────────────────┐
│ QI Total (FSIQ)                    │
│ • Moyenne des 5 indices            │
│ • FSIQ = 108 [CI: 103-113]         │
└────────────────────────────────────┘
```

### Implémentation

```dart
class CalculateIQUseCase {
  final ScoringRepository scoringRepo;
  final NormsRepository normsRepo;

  Future<IQScore> call(String assessmentId) async {
    // 1. Récupère tous les scores bruts
    final rawScores = await scoringRepo.getRawScores(assessmentId);

    // 2. Convertit en notes standard
    final scaledScores = <ScaledScore>[];
    for (final raw in rawScores) {
      final scaled = await normsRepo.convertToScaledScore(
        subtestCode: raw.subtestCode,
        rawScore: raw.rawScore,
        ageInMonths: raw.ageInMonths,
      );
      scaledScores.add(scaled);
    }

    // 3. Calcule les indices composites
    final vci = _calculateIndex(['SI', 'VO', 'IN'], scaledScores);
    final vsi = _calculateIndex(['BD', 'VP'], scaledScores);
    final fri = _calculateIndex(['MR', 'FW'], scaledScores);
    final wmi = _calculateIndex(['DS', 'PM'], scaledScores);
    final psi = _calculateIndex(['CD', 'SS'], scaledScores);

    // 4. Calcule le QI Total
    final fsiq = _calculateFSIQ([vci, vsi, fri, wmi, psi]);

    // 5. Calcule les intervalles de confiance
    final ci = _calculateConfidenceIntervals(fsiq, vci, vsi, fri, wmi, psi);

    return IQScore(
      fsiq: fsiq,
      vci: vci,
      vsi: vsi,
      fri: fri,
      wmi: wmi,
      psi: psi,
      confidenceIntervals: ci,
      // ...
    );
  }
}
```

---

## Sécurité & RGPD

### Chiffrement des données

```dart
class EncryptionService {
  final encrypt.Encrypter _encrypter;

  // Chiffrement AES-256
  String encryptData(String plainText) {
    final encrypted = _encrypter.encrypt(plainText);
    return encrypted.base64;
  }

  String decryptData(String encryptedBase64) {
    final encrypted = encrypt.Encrypted.fromBase64(encryptedBase64);
    return _encrypter.decrypt(encrypted);
  }
}
```

### Anonymisation

```dart
class DataAnonymizer {
  // Pseudonymisation des données de recherche
  Map<String, dynamic> anonymize(AssessmentSession session) {
    return {
      'user_id': _hashUserId(session.userId),
      'age_group': session.ageGroup,
      'responses': session.responses.map((r) => {
        'item_id': r.itemId,
        'is_correct': r.isCorrect,
        'response_time': r.responseTime,
        // Pas d'identifiants personnels
      }).toList(),
    };
  }
}
```

### Gestion du consentement

```dart
class GDPRRepository {
  Future<void> exportUserData(String userId) async {
    // Collecte toutes les données utilisateur
    // Génère un PDF avec toutes les informations
    // Envoie par email sécurisé
  }

  Future<void> deleteUserData(String userId) async {
    // Supprime toutes les données personnelles
    // Conserve uniquement les données anonymisées pour recherche
    // Log l'action pour audit
  }
}
```

---

## Performance & Optimisation

### Lazy Loading

```dart
class ItemBankRepository {
  // Charge uniquement les items nécessaires
  Future<List<ExerciseItem>> getItemsForSubtest(String code) async {
    return await _database.query(
      'items',
      where: 'subtest_code = ? AND is_active = 1',
      whereArgs: [code],
      limit: 20, // Limite initiale
    );
  }
}
```

### Image Caching

```dart
CachedNetworkImage(
  imageUrl: item.stimulus.content,
  cacheManager: DefaultCacheManager(),
  maxHeightDiskCache: 1000,
  maxWidthDiskCache: 1000,
  memCacheHeight: 500,
  memCacheWidth: 500,
)
```

### BLoC Optimization

```dart
// Éviter les rebuilds inutiles
BlocBuilder<AssessmentBloc, AssessmentState>(
  buildWhen: (previous, current) {
    // Ne rebuild que si l'item a changé
    return previous.currentItem?.id != current.currentItem?.id;
  },
  builder: (context, state) => ExerciseWidget(item: state.currentItem),
)
```

---

## Tests

### Structure des tests

```
test/
├── unit/
│   ├── core/
│   ├── features/
│   │   ├── adaptive_testing/
│   │   │   └── usecases/
│   │   │       └── estimate_ability_test.dart
│   │   └── scoring/
│   │       └── usecases/
│   │           └── calculate_iq_test.dart
├── widget/
│   └── exercises/
│       └── matrix_exercise_widget_test.dart
└── integration/
    └── assessment_flow_test.dart
```

### Exemple de test unitaire

```dart
void main() {
  group('CalculateIQUseCase', () {
    late CalculateIQUseCase useCase;
    late MockScoringRepository mockRepo;

    setUp(() {
      mockRepo = MockScoringRepository();
      useCase = CalculateIQUseCase(scoringRepo: mockRepo);
    });

    test('should calculate correct FSIQ from scaled scores', () async {
      // Arrange
      when(() => mockRepo.getRawScores(any()))
          .thenAnswer((_) async => mockRawScores);

      // Act
      final result = await useCase('assessment_123');

      // Assert
      expect(result.fsiq, equals(108));
      expect(result.vci, equals(110));
      expect(result.confidenceIntervals['FSIQ']?.lowerBound, equals(103));
    });
  });
}
```

---

## Déploiement

### CI/CD Pipeline

```yaml
# .github/workflows/main.yml
name: CI/CD

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test --coverage

  build:
    needs: test
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - run: flutter build ios --release
      - run: flutter build apk --release
```

---

## Prochaines Étapes

1. ✅ Architecture définie
2. ✅ Packages sélectionnés
3. ✅ Entités créées
4. 🔄 Implémenter les repositories
5. 🔄 Créer les use cases
6. 🔄 Développer les BLoCs
7. 🔄 Construire les UI par groupe d'âge
8. 🔄 Intégrer l'IA pour génération d'items
9. 🔄 Implémenter le moteur CAT
10. 🔄 Développer le système de scoring

---

## Ressources

- [Flutter Docs](https://flutter.dev/docs)
- [BLoC Library](https://bloclibrary.dev)
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [IRT Theory](https://en.wikipedia.org/wiki/Item_response_theory)
- [Modèle CHC (Cattell-Horn-Carroll)](https://en.wikipedia.org/wiki/Cattell%E2%80%93Horn%E2%80%93Carroll_theory)

---

**Auteur** : Architecture Mentality
**Version** : 1.0.0
**Dernière mise à jour** : 2025-12-23
