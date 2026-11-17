import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inclass_act16/sign_in.dart';

void main() {
  testWidgets(
      'sign-in blocks empty and repeat submissions and shows an auth error',
      (tester) async {
    final request = Completer<void>();
    var calls = 0;
    await tester.pumpWidget(MaterialApp(home: SignInScreen(signIn: (email, _) {
      calls++;
      expect(email, 'quiz@example.test');
      return request.future;
    })));
    final button = find.byType(FilledButton);
    await tester.tap(button);
    await tester.pump();
    expect(find.text('Enter your email and password.'), findsOneWidget);
    expect(calls, 0);
    await tester.enterText(find.byType(TextField).first, ' quiz@example.test ');
    final field = find.byType(TextField).last;
    expect(tester.widget<TextField>(field).obscureText, isTrue);
    await tester.enterText(field, String.fromCharCode(65));
    await tester.tap(button);
    await tester.tap(button);
    await tester.pump();
    expect(calls, 1);
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    request.completeError(FirebaseAuthException(code: 'invalid-credential'));
    await tester.pumpAndSettle();
    expect(find.text('Check your email and password, then try again.'),
        findsOneWidget);
    expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
  });
}
