import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signup_app/main.dart';
import 'package:signup_app/screens/signup_screen.dart';
import 'package:signup_app/widgets/local_signup_tip.dart';

void main() {
  Future<void> openApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(440, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('Enter if you dare'));
    await tester.pumpAndSettle();
  }

  Future<void> fillForm(
    WidgetTester tester, {
    String name = 'Sam',
    String email = 'sam@example.com',
    String password = 'snack1',
  }) async {
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), name);
    await tester.enterText(fields.at(1), email);
    await tester.enterText(fields.at(2), password);
  }

  testWidgets('Empty fields block signup', (tester) async {
    await openApp(tester);
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();
    expect(find.text('Please enter your name'), findsOneWidget);
    expect(find.text('Please enter your email'), findsOneWidget);
    expect(find.text('Please enter a password'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('Bad email and five-character password are rejected', (
    tester,
  ) async {
    await openApp(tester);
    await fillForm(
      tester,
      name: '   ',
      email: 'sam.example.com',
      password: '12345',
    );
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();
    expect(find.text('Please enter your name'), findsOneWidget);
    expect(find.text('Please enter a valid email'), findsOneWidget);
    expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('Valid text still needs a birthday', (tester) async {
    await openApp(tester);
    await fillForm(tester);
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();
    expect(find.text('Please pick your birthday'), findsOneWidget);
    expect(find.text('Getting things ready…'), findsNothing);
  });

  testWidgets('Tip loads, disables repeated taps and shows a preset', (
    tester,
  ) async {
    await openApp(tester);
    await tester.tap(find.text('Get a signup tip'));
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(
      tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
      isNull,
    );
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    const tip = 'Use a long password that you do not use for another account.';
    expect(find.text(tip), findsOneWidget);
    expect(tip.length, lessThanOrEqualTo(240));
    expect(find.text('Preset demo tips, not live AI output.'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    await tester.tap(find.text('Get a signup tip'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(
      find.text('Avoid using your name or birthday in your password.'),
      findsOneWidget,
    );
  });

  testWidgets('Local error clears the old tip and Retry recovers', (
    tester,
  ) async {
    await openApp(tester);
    await tester.tap(find.text('Get a signup tip'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.tap(find.text('Try a tip error'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(
      find.text('Could not load the demo tip. Tap Retry.'),
      findsOneWidget,
    );
    expect(
      find.text('Use a long password that you do not use for another account.'),
      findsNothing,
    );
    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('Could not load the demo tip. Tap Retry.'), findsNothing);
    expect(
      find.text('Avoid using your name or birthday in your password.'),
      findsOneWidget,
    );
  });

  testWidgets('Tips ignore form values and do not approve invalid signup', (
    tester,
  ) async {
    await openApp(tester);
    await fillForm(
      tester,
      name: 'PrivateName',
      email: 'private@example.com',
      password: '123',
    );
    await tester.tap(find.text('Get a signup tip'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    final tipTexts = tester
        .widgetList<Text>(
          find.descendant(
            of: find.byType(LocalSignupTip),
            matching: find.byType(Text),
          ),
        )
        .map((widget) => widget.data ?? '')
        .join(' ');
    expect(tipTexts, isNot(contains('PrivateName')));
    expect(tipTexts, isNot(contains('private@example.com')));
    expect(tipTexts, isNot(contains('123')));
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();
    expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('Small screen with large text stays scrollable', (tester) async {
    await openApp(tester);
    tester.view.physicalSize = const Size(320, 568);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(2)),
          child: child!,
        ),
        home: const SignupScreen(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Try a tip error'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Try a tip error'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.ensureVisible(find.text('Retry'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Closing the screen while a tip loads is safe', (tester) async {
    await openApp(tester);
    await tester.tap(find.text('Get a signup tip'));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 700));
    expect(tester.takeException(), isNull);
  });
}
