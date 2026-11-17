import 'dart:convert';

import 'package:html_unescape/html_unescape.dart';
import 'package:http/http.dart' as http;

class Question {
  final String text;
  final String correct;
  final List<String> choices;

  Question._(this.text, this.correct, this.choices);

  factory Question.fromJson(Object? row) {
    if (row is! Map ||
        row['category'] != 'General Knowledge' ||
        row['difficulty'] != 'easy' ||
        row['type'] != 'multiple') {
      throw const FormatException('The question does not match this quiz.');
    }
    final wrong = row['incorrect_answers'];
    if (wrong is! List || wrong.length != 3) {
      throw const FormatException('A question is missing answer choices.');
    }
    final decoder = HtmlUnescape();
    String clean(Object? value) {
      if (value is String) {
        final text = decoder.convert(value).trim();
        if (text.isNotEmpty) return text;
      }
      throw const FormatException('A question or answer is empty.');
    }

    final text = clean(row['question']);
    final correct = clean(row['correct_answer']);
    final choices = [correct, ...wrong.map(clean)];
    if (choices.toSet().length != 4) {
      throw const FormatException('A question has repeated answer choices.');
    }
    choices.shuffle();
    return Question._(text, correct, List.unmodifiable(choices));
  }
}

class QuizLoader {
  static final url = Uri.parse(
    'https://opentdb.com/api.php?amount=10&category=9&difficulty=easy&type=multiple',
  );
  final http.Client client;
  final _sinceRequest = Stopwatch();

  QuizLoader(this.client);

  Future<List<Question>> load() async {
    if (_sinceRequest.isRunning &&
        _sinceRequest.elapsed < const Duration(seconds: 5)) {
      throw const FormatException('Wait five seconds between requests.');
    }
    _sinceRequest.reset();
    _sinceRequest.start();
    final response = await client.get(url).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw FormatException(
          'The question server returned HTTP ${response.statusCode}.');
    }
    final data = jsonDecode(response.body);
    if (data is! Map || data['response_code'] != 0) {
      throw const FormatException(
          'The question service could not supply a round.');
    }
    final results = data['results'];
    if (results is! List || results.length != 10) {
      throw const FormatException('The quiz needs exactly ten questions.');
    }
    return results.map(Question.fromJson).toList();
  }
}
