import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'question.dart';

void main() {
  runApp(const TriviaShowdownApp());
}

class TriviaShowdownApp extends StatelessWidget {
  const TriviaShowdownApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'API-to-Cloud Trivia Showdown',
      home: const TriviaShowdownScreen(),
    );
  }
}

class TriviaShowdownScreen extends StatefulWidget {
  const TriviaShowdownScreen({super.key});
  @override
  State<TriviaShowdownScreen> createState() => _TriviaShowdownScreenState();
}

class _TriviaShowdownScreenState extends State<TriviaShowdownScreen> {
  List<Question> _questions = [];
  bool _isLoading = true;
  String _error = '';
  int _currentIndex = 0;
  int _score = 0;
  bool _answered = false;
  String? _selectedOption;
  bool _isSynced = false;
  bool _isSyncing = false;
  int _roundId = 0;
  @override
  void initState() {
    super.initState();
    _loadTriviaData();
  }

  Future<void> _loadTriviaData() async {
    final roundId = _roundId;
    try {
      final uri = Uri.parse(
        'https://opentdb.com/api.php?amount=5&category=9&difficulty=easy&type=multiple',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['response_code'] == 0) {
          final results = data['results'] as List;
          if (!mounted || roundId != _roundId) return;
          if (results.length != 5) {
            setState(() {
              _error = 'Could not load all five questions. Please try again.';
              _isLoading = false;
            });
            return;
          }
          setState(() {
            _questions = results.map((q) => Question.fromJson(q)).toList();
            _isLoading = false;
          });
        } else {
          if (!mounted || roundId != _roundId) return;
          setState(() {
            _error =
                'Trivia API returned response code ${data['response_code']}. Please try again.';
            _isLoading = false;
          });
        }
      } else {
        if (!mounted || roundId != _roundId) return;
        setState(() {
          _error = 'Server error: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted || roundId != _roundId) return;
      setState(() {
        _error = 'Connection failed: $e';
        _isLoading = false;
      });
    }
  }

  void _answerQuestion(String option) {
    if (_answered) return;
    setState(() {
      _answered = true;
      _selectedOption = option;
      if (option == _questions[_currentIndex].correctAnswer) {
        _score++;
      }
    });
  }

  void _nextQuestion() {
    setState(() {
      if (_currentIndex < _questions.length - 1) {
        _currentIndex++;
        _answered = false;
        _selectedOption = null;
      } else {
        _currentIndex++; // triggers results screen
      }
    });
  }

  Future<void> _syncScoreToCloud() async {
    if (_isSyncing || _isSynced) return;
    final roundId = _roundId;
    setState(() {
      _isSyncing = true;
    });
    final payload = {'score': _score, 'total': _questions.length};
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted || roundId != _roundId) return;
    setState(() {
      _isSyncing = false;
      _isSynced = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            "Simulated score: ${payload['score']} / ${payload['total']}. No backend request was sent."),
      ),
    );
  }

  void _restart() {
    _roundId++;
    setState(() {
      _isLoading = true;
      _error = '';
      _currentIndex = 0;
      _score = 0;
      _answered = false;
      _selectedOption = null;
      _isSynced = false;
      _isSyncing = false;
    });
    _loadTriviaData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cloud Trivia Showdown: API Edition')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error, textAlign: TextAlign.center),
                        TextButton(
                            onPressed: _restart,
                            child: const Text('Try Again')),
                      ],
                    ),
                  )
                : _currentIndex >= _questions.length
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Showdown Complete!',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Final Score: $_score / ${_questions.length}',
                              style: const TextStyle(fontSize: 18),
                            ),
                            const SizedBox(height: 24),
                            if (!_isSynced)
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                                onPressed:
                                    _isSyncing ? null : _syncScoreToCloud,
                                icon: const Icon(Icons.cloud_upload),
                                label: Text(
                                  _isSyncing
                                      ? 'Simulating sync...'
                                      : 'Simulate Score Sync',
                                ),
                              )
                            else
                              const Text(
                                'Score sync simulation complete',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: _restart,
                              child: const Text('Play Again'),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          LinearProgressIndicator(
                            value: (_currentIndex + 1) / _questions.length,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Question ${_currentIndex + 1} of ${_questions.length}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Card(
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Text(
                                _questions[_currentIndex].questionText,
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          ..._questions[_currentIndex].options.map((opt) {
                            Color btnColor = Colors.white;
                            if (_answered) {
                              if (opt ==
                                  _questions[_currentIndex].correctAnswer) {
                                btnColor = Colors.green.shade200;
                              } else if (opt == _selectedOption) {
                                btnColor = Colors.red.shade200;
                              }
                            }
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: btnColor,
                                  foregroundColor: Colors.black87,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                ),
                                onPressed: () => _answerQuestion(opt),
                                child: Text(opt,
                                    style: const TextStyle(fontSize: 16)),
                              ),
                            );
                          }),
                          const Spacer(),
                          if (_answered)
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                              onPressed: _nextQuestion,
                              child: Text(
                                _currentIndex < _questions.length - 1
                                    ? 'Next Question →'
                                    : 'View Final Score',
                              ),
                            ),
                        ],
                      ),
      ),
    );
  }
}
