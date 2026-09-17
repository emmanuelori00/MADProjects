import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Theme buttons change colors and save the selected mode', (
    tester,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    await tester.pumpWidget(MyApp(preferences: preferences));
    expect(find.text('Status: Online'), findsOneWidget);
    ThemeData currentTheme() => Theme.of(tester.element(find.byType(Scaffold)));
    expect(currentTheme().brightness, Brightness.light);

    final lightColor = currentTheme().colorScheme.primary;
    final lightSuccess = currentTheme().extension<AppColors>()!.success;
    await tester.tap(find.text('Dark Theme'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    final halfwayColor = currentTheme().colorScheme.primary;
    expect(halfwayColor, isNot(lightColor));
    expect(halfwayColor, isNot(Colors.teal));
    expect(currentTheme().extension<AppColors>()!.success, isNot(lightSuccess));
    await tester.pumpAndSettle();
    expect(currentTheme().brightness, Brightness.dark);
    expect(currentTheme().colorScheme.secondary, Colors.teal);
    expect(preferences.getString('themeMode'), 'dark');
    final statusIcon = tester.widget<Icon>(
      find.byIcon(Icons.online_prediction),
    );
    expect(statusIcon.color, currentTheme().extension<AppColors>()!.success);

    // Recreate the app to check that it restores the saved choice.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(MyApp(preferences: preferences));
    expect(currentTheme().brightness, Brightness.dark);

    await tester.tap(find.text('Light Theme'));
    await tester.pumpAndSettle();
    expect(currentTheme().brightness, Brightness.light);
    expect(currentTheme().colorScheme.secondary, Colors.amber);
    expect(preferences.getString('themeMode'), 'light');
    final badge = tester.widget<AnimatedContainer>(
      find.byWidgetPredicate(
        (widget) =>
            widget is AnimatedContainer &&
            widget.duration == const Duration(milliseconds: 400),
      ),
    );
    expect((badge.decoration as BoxDecoration).color, Colors.amber);
  });

  testWidgets('Unknown saved theme uses light mode', (tester) async {
    SharedPreferences.setMockInitialValues({'themeMode': 'unknown'});
    final preferences = await SharedPreferences.getInstance();
    await tester.pumpWidget(MyApp(preferences: preferences));
    expect(
      Theme.of(tester.element(find.byType(Scaffold))).brightness,
      Brightness.light,
    );
  });
}
