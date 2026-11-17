import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inclass_act16/attempt_store.dart';

void main() {
  final attempt = CompletedAttempt(7);
  final saved = {...attempt.fields, 'submittedAt': Timestamp(100, 0)};

  test('a resolved six-field record returns the original score', () {
    expect(CompletedAttempt.fromServer(saved).score, 7);
    expect(attempt.matches(saved), isTrue);
    expect(CompletedAttempt(8).matches(saved), isFalse);
  });

  test('invalid fields and unresolved timestamps cannot verify a score', () {
    for (final invalid in [
      {...saved, 'submittedAt': null},
      {...saved, 'variant': 'B'},
      {...saved, 'categoryId': 9.0},
      {...saved, 'correctCount': 11},
      {...saved, 'questionCount': 9},
      {...saved, 'other': 1},
    ]) {
      expect(() => CompletedAttempt.fromServer(invalid), throwsFormatException);
    }
  });
}
