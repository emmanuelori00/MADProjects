# In-Class 12

This is my product app for the Firebase activity. It uses Flutter on Android and a Firestore collection called products. Each product has a name and a number for its price.

So far, the assignment starter can add, show, and edit products. Delete, search, price filters, and Reset still need to be added. The app hasnt been tested with the database yet.

To run it:

1. Open this folder in a terminal.
2. Run flutter pub get.
3. Use Firebase CLI and FlutterFire to connect an Android app to your own class Firebase project. Run flutterfire configure --platforms=android.
4. Create a default Firestore database and a products collection with the five products from the assignment.
5. Start an Android emulator, then run flutter run.

Only use made-up products in the class database. The Firebase settings connect the app to a project, but the database rules decide who can read or change the data.

The generated Firebase settings stay local. Running FlutterFire makes them for your project. After that, run flutter analyze and flutter test to check the code and form. The form tests use a fake database, so they dont prove that Firestore works.
