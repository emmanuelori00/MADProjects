Activity 14 - Campus alerts

This is my Flutter app for Firebase Cloud Messaging.

Setup
1. Run flutter pub get.
2. Connect an Android app to your Firebase project with FlutterFire. Use com.emmanuel.campus_alerts as the package name.
3. Run flutterfire configure --platforms=android --project=YOUR_PROJECT_ID.
4. Start an Android emulator with Google Play services and run flutter run.

The Firebase config files stay local. FlutterFire creates them during setup.

So far, Firebase starts before the app opens. The background handler is registered, and the two images are included. The message service and notification tests are next.
