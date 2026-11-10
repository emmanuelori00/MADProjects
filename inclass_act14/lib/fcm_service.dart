import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class FCMService {
  final FirebaseMessaging messaging = FirebaseMessaging.instance;
  StreamSubscription<RemoteMessage>? _foreground;
  StreamSubscription<RemoteMessage>? _opened;
  StreamSubscription<String>? _tokenRefresh;
  bool _disposed = false;

  Future<void> initialize({
    required void Function(RemoteMessage, String) onData,
    required void Function(String) onStatus,
  }) async {
    if (_disposed || _foreground != null) {
      throw StateError('Use a new service instance for initialization.');
    }
    void receive(String source, RemoteMessage message) {
      if (_disposed) return;
      debugPrint('$source: ${message.messageId}');
      onData(message, source);
    }

    void streamError(Object error, StackTrace stack) {
      debugPrint('FCM stream error: $error\n$stack');
      if (!_disposed) onStatus('Messaging stream error: $error');
    }

    _foreground = FirebaseMessaging.onMessage.listen(
      (message) => receive('onMessage', message),
      onError: streamError,
    );
    _opened = FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => receive('onMessageOpenedApp', message),
      onError: streamError,
    );
    final initialMessage = await messaging.getInitialMessage();
    if (_disposed) return;
    if (initialMessage != null) {
      receive('getInitialMessage', initialMessage);
    }

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (_disposed) return;
    onStatus('Permission: ${settings.authorizationStatus.name}');

    _tokenRefresh = messaging.onTokenRefresh.listen((token) {
      if (_disposed) return;
      if (kDebugMode) debugPrint('FCM token refreshed: $token');
      onStatus('Token refreshed. Use the current token for the next test.');
    }, onError: streamError);
    final token = await messaging.getToken();
    if (_disposed) return;
    if (token == null) {
      throw StateError('No FCM token. Check network and platform setup.');
    }
    if (kDebugMode) debugPrint('FCM token: $token');
  }

  Future<void> dispose() async {
    _disposed = true;
    await _foreground?.cancel();
    await _opened?.cancel();
    await _tokenRefresh?.cancel();
  }
}
