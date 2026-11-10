Activity 14 - Campus alerts

This is my Flutter app for Firebase Cloud Messaging.

Setup
1. Run flutter pub get.
2. Connect an Android app to your Firebase project with FlutterFire. Use com.emmanuel.campus_alerts as the package name.
3. Run flutterfire configure --platforms=android --project=YOUR_PROJECT_ID.
4. Start an Android emulator with Google Play services and run flutter run.

The Firebase config files stay local. FlutterFire creates them during setup.

The app uses one FCMService for messages and notification taps. A message with action=update_ui and asset=promo shows the event image. Using asset=default shows the starting image. Bad values leave the last title and image alone and show a message.

The screen also shows the last handler, message count, and message ID. The service cancels its listeners when the screen closes.

The Android app builds and opens. All four tests passed on the Android 17 emulator: foreground, background notification tap, cold start from a notification, and an invalid asset value. The report in submission has the results and screenshots.
