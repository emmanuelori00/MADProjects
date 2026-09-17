import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('Theme buttons update the status card', (tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Status: Online'), findsOneWidget);
    expect(Theme.of(tester.element(find.byType(Scaffold))).brightness,
        Brightness.light);

    await tester.tap(find.text('Dark Theme'));
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.byType(Scaffold))).brightness,
        Brightness.dark);
    final darkBadge = tester.widget<AnimatedContainer>(
        find.byWidgetPredicate((widget) => widget is AnimatedContainer && widget.duration == const Duration(milliseconds: 400)));
    expect((darkBadge.decoration as BoxDecoration).color, Colors.teal);

    await tester.tap(find.text('Light Theme'));
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.byType(Scaffold))).brightness,
        Brightness.light);
    final lightBadge = tester.widget<AnimatedContainer>(
        find.byWidgetPredicate((widget) => widget is AnimatedContainer && widget.duration == const Duration(milliseconds: 400)));
    expect((lightBadge.decoration as BoxDecoration).color, Colors.amber);
  });
}
