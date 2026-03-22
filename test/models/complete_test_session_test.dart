import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/core/models/complete_test_session.dart';

void main() {
  group('CompleteTestSession', () {
    test('commence au test index 0', () {
      final session = CompleteTestSession(startTime: DateTime.now());
      expect(session.currentTestIndex, equals(0));
      expect(session.currentTestName, equals('Cubes'));
    });

    test('isComplete est false en début de session', () {
      final session = CompleteTestSession(startTime: DateTime.now());
      expect(session.isComplete, isFalse);
    });

    test('progressPercentage est 0% en début', () {
      final session = CompleteTestSession(startTime: DateTime.now());
      expect(session.progressPercentage, equals(0.0));
    });

    test('totalTests retourne 12', () {
      final session = CompleteTestSession(startTime: DateTime.now());
      expect(session.totalTests, equals(12));
    });

    test('copyWith préserve les champs non modifiés', () {
      final original = CompleteTestSession(
        startTime: DateTime(2026, 1, 1),
        cubesScore: 42,
      );
      final copy = original.copyWith(similaritiesScore: 25);

      expect(copy.cubesScore, equals(42));
      expect(copy.similaritiesScore, equals(25));
      expect(copy.startTime, equals(DateTime(2026, 1, 1)));
    });

    test('copyWith avec currentTestIndex avance correctement', () {
      final session = CompleteTestSession(
        startTime: DateTime.now(),
        currentTestIndex: 5,
      );
      expect(session.currentTestName, equals(CompleteTestSession.testSequence[5]));
    });

    test('icvRawScore est null si des scores manquent', () {
      final session = CompleteTestSession(
        startTime: DateTime.now(),
        similaritiesScore: 25,
        // vocabularyScore et informationScore manquants
      );
      expect(session.icvRawScore, isNull);
    });

    test('icvRawScore est correct quand tous les scores sont présents', () {
      final session = CompleteTestSession(
        startTime: DateTime.now(),
        similaritiesScore: 25,
        vocabularyScore: 30,
        informationScore: 18,
      );
      expect(session.icvRawScore, equals(73));
    });

    test('la séquence testSequence contient exactement 12 tests', () {
      expect(CompleteTestSession.testSequence.length, equals(12));
    });

    test('totalDuration est null si endTime n\'est pas défini', () {
      final session = CompleteTestSession(startTime: DateTime.now());
      expect(session.totalDuration, isNull);
    });

    test('totalDuration est calculé correctement', () {
      final start = DateTime(2026, 1, 1, 10, 0);
      final end = DateTime(2026, 1, 1, 11, 30);
      final session = CompleteTestSession(
        startTime: start,
        endTime: end,
      );
      expect(session.totalDuration?.inMinutes, equals(90));
    });
  });
}
