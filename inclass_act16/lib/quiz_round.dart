import 'package:flutter/material.dart';

import 'quiz.dart';

class QuizRound extends StatefulWidget {
  final List<Question> questions;
  final ValueChanged<List<String>> onFinished;

  const QuizRound(
      {super.key, required this.questions, required this.onFinished});

  @override
  State<QuizRound> createState() => _QuizRoundState();
}

class _QuizRoundState extends State<QuizRound> {
  int index = 0;
  final answers = <String>[];

  @override
  Widget build(BuildContext context) {
    final number = index;
    final question = widget.questions[number];
    final answered = answers.length > number;
    final last = number == widget.questions.length - 1;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Question ${number + 1} of ${widget.questions.length}'),
        const SizedBox(height: 12),
        Text(question.text),
        const SizedBox(height: 12),
        for (final choice in question.choices)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                disabledForegroundColor:
                    Theme.of(context).colorScheme.onSurface,
                disabledBackgroundColor: !answered
                    ? null
                    : choice == question.correct
                        ? Colors.green.shade200
                        : choice == answers[number]
                            ? Colors.red.shade200
                            : null,
              ),
              onPressed: answered
                  ? null
                  : () {
                      if (index == number && answers.length == number) {
                        setState(() => answers.add(choice));
                      }
                    },
              child: Text(choice),
            ),
          ),
        if (answered)
          Text(answers[number] == question.correct
              ? 'Correct.'
              : 'Incorrect. Correct answer: ${question.correct}'),
        TextButton(
          onPressed: !answered
              ? null
              : () {
                  if (index != number) return;
                  if (last) {
                    widget.onFinished(List.unmodifiable(answers));
                  } else {
                    setState(() => index++);
                  }
                },
          child: Text(last ? 'Review answers' : 'Next'),
        ),
      ],
    );
  }
}

int countCorrect(List<Question> questions, List<String> answers) {
  var score = 0;
  for (var i = 0; i < questions.length; i++) {
    if (answers[i] == questions[i].correct) score++;
  }
  return score;
}

class QuizReview extends StatelessWidget {
  final List<Question> questions;
  final List<String> answers;
  final Widget actions;

  const QuizReview(
      {super.key,
      required this.questions,
      required this.answers,
      required this.actions});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
            'Final score: ${countCorrect(questions, answers)} / ${questions.length}'),
        actions,
        for (var i = 0; i < questions.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${i + 1}. ${questions[i].text}'),
              Text('Your answer: ${answers[i]}'),
              Text('Correct answer: ${questions[i].correct}'),
            ]),
          ),
      ],
    );
  }
}
