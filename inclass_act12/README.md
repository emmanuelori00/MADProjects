# In-Class 12

This is my product app for the Firebase activity. It uses Flutter on Android and a Firestore collection called products. Each product has a name and a number for its price.

The app can add, show, edit, and delete products. Search ignores capitals and matches part of a name. Min and max prices include both ends of the range. Reset clears all three filters. Invalid prices and ranges show a message.

The app ran on the Android emulator. All 14 local tests passed, and flutter analyze found no issues. The database tests covered adding, editing, deleting one of two matching names, live updates, filters, bad input, and offline reopening. The rules allow/deny test was a simulation. I didnt publish the test rules.

The Word report is in submission/Gohourou_Emmanuel_InClass12_Report.docx. It has the screenshots, test results, and Q1 through Q10. The tested app code is commit 4c68cf4.

To run it:

1. Open this folder in a terminal.
2. Run flutter pub get.
3. Use Firebase CLI and FlutterFire to connect an Android app to your own class Firebase project. Run flutterfire configure --platforms=android.
4. Create a default Firestore database and a products collection with the five products from the assignment.
5. Start an Android emulator, then run flutter run.

Only use made-up products in the class database. The Firebase settings connect the app to a project, but the database rules decide who can read or change the data.

The generated Firebase settings stay local. Running FlutterFire makes them for your project. After that, run flutter analyze and flutter test to check the code and form. The form tests use a fake database, so they dont prove that Firestore works.

The app uses Flutter 3.47.2, Dart 3.13.2, firebase_core 5.1.0, and cloud_firestore 7.1.0. The tests used Android 17 API 37. The offline test only checked products already loaded on that emulator. Login, stock, and a bigger search system are ideas in the report, not app features.
