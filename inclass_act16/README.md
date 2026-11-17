In-Class Activity 16 – Class A Quiz

Open the `inclass_act16` folder in VS Code and start an Android emulator in Android Studio. Run `flutter pub get`, then `flutter run`. Sign in with a class test account and tap Start quiz.

The app loads 10 easy General Knowledge questions. Each question accepts one answer. At the end, review your answers and tap Submit score. The app shows “Cloud verified” after it reads the matching score from Firestore.

To check a score after restarting the app, copy the round ID at the end of the displayed document path. Reopen the app with the same account, enter the ID under Saved round ID, and tap Look up score.

The Android app is configured for the Firebase project `mad-ica16-class-a-quiz-4c28`. It uses Email/Password sign-in and a Standard, Native mode Firestore database. To create the two test accounts, open Authentication in the Firebase console, enable Email/Password, then use Add user twice. Deploy the included rules with `firebase deploy --only firestore:rules`. Each account can read its own attempts. Once a score is saved, it can’t be edited.

To repeat the lost-confirmation test, run the debug app and finish a round. Under Test next save, choose Hide acknowledgement and tap Submit score. Tap Check server to recover the score using the same round ID. In the recorded test, round `…Oy3qrI` returned 3/10.

Run `flutter test` for the local checks and `flutter build apk --release` to build the APK. The submitted APK was installed on a Pixel 10a emulator and verified against the saved 3/10 score.
