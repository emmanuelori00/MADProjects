import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inclass_act16/quiz.dart';
import 'package:inclass_act16/quiz_round.dart';

void main() {
  testWidgets('one answer counts per question and all ten appear in the review',
      (tester) async {
    final questions = List.generate(
        10,
        (i) => Question.fromJson({
              'category': 'General Knowledge',
              'difficulty': 'easy',
              'type': 'multiple',
              'question': 'Pick A &amp; B for question ${i + 1}.',
              'correct_answer': 'A &amp; B',
              'incorrect_answers': ['C', 'D', 'E'],
            }));
    List<String>? saved;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: QuizRound(
      questions: questions,
      onFinished: (answers) => saved = answers,
    ))));
    for (var i = 0; i < 10; i++) {
      expect(find.text('Question ${i + 1} of 10'), findsOneWidget);
      final next =
          find.widgetWithText(TextButton, i == 9 ? 'Review answers' : 'Next');
      expect(tester.widget<TextButton>(next).onPressed, isNull);
      await tester.tap(find.text(i.isEven ? 'A & B' : 'C'));
      await tester.tap(find.text('D'));
      await tester.pump();
      expect(
          find.text(i.isEven ? 'Correct.' : 'Incorrect. Correct answer: A & B'),
          findsOneWidget);
      expect(
          tester
              .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'D'))
              .onPressed,
          isNull);
      await tester.tap(next);
      await tester.pump();
    }
    expect(saved, List.generate(10, (i) => i.isEven ? 'A & B' : 'C'));
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: QuizReview(
      questions: questions,
      answers: saved!,
      actions: const SizedBox.shrink(),
    ))));
    expect(find.text('Final score: 5 / 10'), findsOneWidget);
    for (var i = 1; i <= 10; i++) {
      final entry = find.text('$i. Pick A & B for question $i.');
      await tester.scrollUntilVisible(entry, 120);
      final group =
          find.ancestor(of: entry, matching: find.byType(Column)).first;
      expect(
          find.descendant(
              of: group,
              matching: find.text('Your answer: ${i.isOdd ? "A & B" : "C"}')),
          findsOneWidget);
      expect(
          find.descendant(
              of: group, matching: find.text('Correct answer: A & B')),
          findsOneWidget);
    }
  });
}
