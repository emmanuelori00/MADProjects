In-Class 15: Trivia Showdown

Open the inclass_act15 folder in VS Code. Start an Android emulator in Android Studio. In the VS Code terminal, run flutter pub get, then flutter run. Choose the Android emulator if Flutter asks for a device.

The app gets five easy general knowledge questions from Open Trivia Database. In _loadTriviaData, HTTP 200 means the server answered the request. The app also checks that response_code is 0 and that all five questions came back. Question.fromJson cleans up text like `&quot;` and shuffles the answer choices.

The app shows a spinner while the questions load. During the round, green shows the correct answer and red shows a wrong pick. _answerQuestion counts only the first tap for each question.

In the Pixel 9 test, questions 1 and 3 were correct. Tapping question 1 again didn’t add a point. The final score was 2/5. Simulate Score Sync showed that score and said no backend request was sent. Play Again loaded a different first question. Starting offline showed an error, and Try Again worked after the connection came back.

1. If I lose internet after all five questions load, I’d want to finish the round. _loadTriviaData already saved the questions and answers in _questions, so the app can still check my picks and show my final score. If I tap Play Again, the app needs internet to get five new questions. If that request fails, I can tap Try Again once I’m back online.

2. I’d save my best score on my phone so I have something to beat next time. The app already uses _score to show how many I got right out of five. I’d have it replace my saved best only when I score higher. Right now the app doesn’t save a best score between games. Saving it on my phone would give me a personal record. A shared leaderboard would need a server where other players could see the scores.
