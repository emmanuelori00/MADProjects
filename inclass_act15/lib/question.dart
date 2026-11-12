class Question {
  final String questionText;
  final String correctAnswer;
  final List<String> options;
  Question({
    required this.questionText,
    required this.correctAnswer,
    required this.options,
  });
  factory Question.fromJson(Map<String, dynamic> json) {
    var incorrect = List<String>.from(json['incorrect_answers']);
    var correct = json['correct_answer'] as String;
    var allOptions = [...incorrect, correct];
    allOptions.shuffle();
    String clean(String val) => val
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll('&amp;', '&');
    return Question(
      questionText: clean(json['question']),
      correctAnswer: clean(correct),
      options: allOptions.map(clean).toList(),
    );
  }
}
