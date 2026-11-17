import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class CompletedAttempt {
  final int score;

  CompletedAttempt(this.score) {
    RangeError.checkValueInInterval(score, 0, 10, 'score');
  }

  Map<String, dynamic> get fields => {
        'schemaVersion': 1,
        'variant': 'A',
        'categoryId': 9,
        'questionCount': 10,
        'correctCount': score,
      };

  static CompletedAttempt fromServer(Map<String, dynamic> data) {
    final score = data['correctCount'];
    if (score is! int || score < 0 || score > 10) {
      throw const FormatException('The saved score is invalid.');
    }
    final attempt = CompletedAttempt(score);
    if (!attempt.matches(data) || data['submittedAt'] is! Timestamp) {
      throw const FormatException('The saved attempt has unexpected data.');
    }
    return attempt;
  }

  bool matches(Map<String, dynamic> data) {
    if (data.length != 6 || !data.containsKey('submittedAt')) return false;
    return fields.entries.every((entry) {
      final value = data[entry.key];
      if (entry.value is int && value is! int) return false;
      return value == entry.value;
    });
  }
}

enum SaveTest { normal, unavailable, quota, lostAcknowledgement }

class AttemptStore {
  final FirebaseAuth auth;
  final FirebaseFirestore db;

  AttemptStore(this.auth, this.db);

  CollectionReference<Map<String, dynamic>> _attempts() {
    final user = auth.currentUser;
    if (user == null) {
      throw FirebaseException(plugin: 'firebase_auth', code: 'unauthenticated');
    }
    return db.collection('users').doc(user.uid).collection('attempts');
  }

  DocumentReference<Map<String, dynamic>> newRound() => _attempts().doc();

  DocumentReference<Map<String, dynamic>> lookup(String roundId) {
    final id = roundId.trim();
    if (id.isEmpty || id.contains('/')) {
      throw const FormatException('Enter the saved round ID.');
    }
    return _attempts().doc(id);
  }

  Future<void> save(
      DocumentReference<Map<String, dynamic>> ref, CompletedAttempt attempt,
      {SaveTest test = SaveTest.normal}) async {
    if (kDebugMode &&
        (test == SaveTest.unavailable || test == SaveTest.quota)) {
      throw FirebaseException(
          plugin: 'cloud_firestore',
          code: test == SaveTest.unavailable
              ? 'unavailable'
              : 'resource-exhausted');
    }
    final payload = {
      ...attempt.fields,
      'submittedAt': FieldValue.serverTimestamp()
    };
    await db.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) {
        transaction.set(ref, payload);
      } else if (!attempt.matches(snapshot.data()!)) {
        throw const FormatException(
            'This round ID already holds a different result.');
      }
    });
  }

  Future<CompletedAttempt?> readServer(
      DocumentReference<Map<String, dynamic>> ref,
      {CompletedAttempt? expected}) async {
    final snapshot = await ref.get(const GetOptions(source: Source.server));
    if (snapshot.metadata.isFromCache || snapshot.metadata.hasPendingWrites) {
      throw StateError('Server verification is unavailable.');
    }
    if (!snapshot.exists) return null;
    final data = snapshot.data()!;
    final saved = CompletedAttempt.fromServer(data);
    if (expected != null && !expected.matches(data)) {
      throw const FormatException(
          'This round ID already holds a different result.');
    }
    return saved;
  }
}
