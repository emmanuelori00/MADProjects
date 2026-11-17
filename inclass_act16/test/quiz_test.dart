import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:inclass_act16/quiz.dart';

void main() {
  final row = {
    'category': 'General Knowledge',
    'difficulty': 'easy',
    'type': 'multiple',
    'question': 'Which choice contains an &amp; sign?',
    'correct_answer': 'A &amp; B',
    'incorrect_answers': ['C', 'D', 'E'],
  };
  String round(int count) => jsonEncode({
        'response_code': 0,
        'results': List.filled(count, row),
      });
  QuizLoader withBody(String body) => QuizLoader(MockClient((request) async {
        expect(request.url, QuizLoader.url);
        return http.Response(body, 200);
      }));

  test('a full round keeps four decoded choices per question', () async {
    final questions = await withBody(round(10)).load();
    expect(questions.length, 10);
    expect(questions.first.text, 'Which choice contains an & sign?');
    expect(questions.first.correct, 'A & B');
    expect(questions.first.choices, unorderedEquals(['A & B', 'C', 'D', 'E']));
  });

  for (final entry in {
    'bad JSON': '{',
    'nonzero API code': '{"response_code":1,"results":[]}',
    'nine questions': round(9),
  }.entries) {
    test('T03 rejects ${entry.key}', () async {
      await expectLater(withBody(entry.value).load(), throwsFormatException);
    });
  }

  test('another tap within five seconds sends no second request', () async {
    var calls = 0;
    final loader = QuizLoader(MockClient((_) async {
      calls++;
      return http.Response(round(10), 200);
    }));
    await loader.load();
    await expectLater(loader.load(), throwsFormatException);
    expect(calls, 1);
  });

  test('choices that match after decoding are rejected', () {
    expect(
        () => Question.fromJson({
              ...row,
              'incorrect_answers': ['A & B', 'D', 'E']
            }),
        throwsFormatException);
  });
}
