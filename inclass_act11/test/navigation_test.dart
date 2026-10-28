import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signup_app/main.dart';
import 'package:signup_app/screens/signup_screen.dart';
import 'package:signup_app/screens/success_screen.dart';
import 'package:signup_app/screens/welcome_screen.dart';

void main() {
  Future<void> openSignup(WidgetTester tester) async {
    tester.view.physicalSize = const Size(440, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('Enter if you dare'));
    await tester.pumpAndSettle();
  }

  Future<void> fillText(WidgetTester tester) async {
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Sam');
    await tester.enterText(fields.at(1), 'sam@example.com');
    await tester.enterText(fields.at(2), 'snack1');
    tester.testTextInput.hide();
    await tester.pump();
  }

  Future<void> pickDefaultBirthday(WidgetTester tester) async {
    await tester.tap(find.byType(TextFormField).at(3));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  Future<void> finishSignup(WidgetTester tester) async {
    await fillText(tester);
    await pickDefaultBirthday(tester);
    await tester.tap(find.text('Sign Up'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
  }

  testWidgets('Password toggle shows and hides the same password', (
    tester,
  ) async {
    await openSignup(tester);
    await fillText(tester);
    final password = find.byType(TextFormField).at(2);
    TextField input() => tester.widget<TextField>(
      find.descendant(of: password, matching: find.byType(TextField)),
    );
    expect(input().obscureText, isTrue);
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(input().obscureText, isFalse);
    expect(input().controller!.text, 'snack1');
    await tester.tap(find.byTooltip('Hide password'));
    await tester.pump();
    expect(input().obscureText, isTrue);
  });

  testWidgets('Signup waits and ignores a second submit before rebuilding', (
    tester,
  ) async {
    await openSignup(tester);
    await fillText(tester);
    await pickDefaultBirthday(tester);
    final button = find.widgetWithText(ElevatedButton, 'Sign Up');
    await tester.tap(button);
    await tester.tap(button);
    await tester.pump();
    expect(find.text('Getting things ready…'), findsOneWidget);
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNull,
    );
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(SuccessScreen), findsNothing);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.text('Welcome, Sam!'), findsOneWidget);
    expect(find.byType(SignupScreen, skipOffstage: false), findsNothing);
    expect(find.byType(SuccessScreen, skipOffstage: false), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.byType(SuccessScreen, skipOffstage: false), findsNothing);
  });

  testWidgets('Leaving signup clears its values on the next visit', (
    tester,
  ) async {
    await openSignup(tester);
    await fillText(tester);
    await pickDefaultBirthday(tester);
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enter if you dare'));
    await tester.pumpAndSettle();
    final fields = tester.widgetList<TextField>(find.byType(TextField));
    expect(fields.every((field) => field.controller!.text.isEmpty), isTrue);
    expect(find.text('Pick your birthday'), findsOneWidget);
    expect(find.byTooltip('Show password'), findsOneWidget);
  });

  testWidgets('Back during loading does not navigate later or throw', (
    tester,
  ) async {
    await openSignup(tester);
    await fillText(tester);
    await pickDefaultBirthday(tester);
    await tester.tap(find.text('Sign Up'));
    await tester.pump();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 3));
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.byType(SuccessScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Success has confetti and returns to welcome without keeping the form',
    (tester) async {
      await openSignup(tester);
      await finishSignup(tester);
      final confetti = tester.widget<ConfettiWidget>(
        find.byType(ConfettiWidget),
      );
      expect(confetti.shouldLoop, isFalse);
      expect(
        confetti.confettiController.state,
        ConfettiControllerState.playing,
      );
      expect(confetti.confettiController.duration, const Duration(seconds: 2));
      expect(find.text('Welcome, Sam!'), findsOneWidget);
      await tester.tap(find.text('Back to welcome'));
      await tester.pumpAndSettle();
      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.byType(SignupScreen, skipOffstage: false), findsNothing);
      expect(find.byType(SuccessScreen, skipOffstage: false), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final birthdays = {
    'oldest allowed date': DateTime(1920),
    'year 2000': DateTime(2000),
    'yesterday': DateTime(today.year, today.month, today.day - 1),
    'today': today,
    'tomorrow': DateTime(today.year, today.month, today.day + 1),
  };
  for (final entry in birthdays.entries) {
    testWidgets('Birthday picker checks ${entry.key}', (tester) async {
      await openSignup(tester);
      await tester.tap(find.byType(TextFormField).at(3));
      await tester.pumpAndSettle();
      final localizations = MaterialLocalizations.of(
        tester.element(find.byType(DatePickerDialog)),
      );
      await tester.tap(find.byTooltip(localizations.inputDateModeButtonLabel));
      await tester.pumpAndSettle();
      final input = find.descendant(
        of: find.byType(DatePickerDialog),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(
        input,
        localizations.formatCompactDate(entry.value),
      );
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      if (entry.key == 'tomorrow') {
        expect(find.byType(DatePickerDialog), findsOneWidget);
        expect(find.text(localizations.dateOutOfRangeLabel), findsOneWidget);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(find.text('Pick your birthday'), findsOneWidget);
      } else {
        expect(find.byType(DatePickerDialog), findsNothing);
        expect(
          find.text(
            '${entry.value.month}/${entry.value.day}/${entry.value.year}',
          ),
          findsOneWidget,
        );
      }
    });
  }

  testWidgets('Rotation keeps form values, birthday, and password visibility', (
    tester,
  ) async {
    await openSignup(tester);
    await fillText(tester);
    await pickDefaultBirthday(tester);
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    tester.view.physicalSize = const Size(1100, 440);
    await tester.pumpAndSettle();
    final fields = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();
    expect(fields[0].controller!.text, 'Sam');
    expect(fields[1].controller!.text, 'sam@example.com');
    expect(fields[2].controller!.text, 'snack1');
    expect(fields[2].obscureText, isFalse);
    expect(find.text('1/1/2008'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Loading and success fit a narrow screen with larger text', (
    tester,
  ) async {
    await openSignup(tester);
    await fillText(tester);
    await pickDefaultBirthday(tester);
    tester.view.physicalSize = const Size(320, 568);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Sign Up'));
    await tester.tap(find.text('Sign Up'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.text('Welcome, Sam!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
