import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw01/main.dart';

Future<void> tapKeys(WidgetTester tester, List<String> keys) async {
  for (final key in keys) {
    final button = find.byKey(ValueKey('key_$key'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
  }
}

Future<void> toggleTheme(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('theme_toggle')));
  await tester.pumpAndSettle();
}

String display(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const ValueKey('display'))).data!;

ThemeData theme(WidgetTester tester) =>
    Theme.of(tester.element(find.byKey(const ValueKey('display'))));

Color materialColor(WidgetTester tester, Finder parent) => tester
    .widget<Material>(
      find.descendant(of: parent, matching: find.byType(Material)).first,
    )
    .color!;

List<Color> surfaceColors(WidgetTester tester) => [
  materialColor(tester, find.byType(Scaffold)),
  materialColor(tester, find.byType(AppBar)),
  materialColor(tester, find.byKey(const ValueKey('key_8'))),
  (tester
              .widget<Container>(find.byKey(const ValueKey('display_panel')))
              .decoration!
          as BoxDecoration)
      .color!,
];

double contrast(Color first, Color second) {
  final a = first.computeLuminance();
  final b = second.computeLuminance();
  return a > b ? (a + 0.05) / (b + 0.05) : (b + 0.05) / (a + 0.05);
}

void main() {
  testWidgets('Themes change every surface smoothly in both directions', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    final light = surfaceColors(tester);
    expect(theme(tester).brightness, Brightness.light);
    expect(find.byTooltip('Switch to dark theme'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('theme_toggle')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    final middle = surfaceColors(tester);
    await tester.pumpAndSettle();
    final dark = surfaceColors(tester);
    expect(theme(tester).brightness, Brightness.dark);
    expect(find.byTooltip('Switch to light theme'), findsOneWidget);
    for (var i = 0; i < light.length; i++) {
      expect(dark[i], isNot(light[i]));
      expect(middle[i], isNot(light[i]));
      expect(middle[i], isNot(dark[i]));
    }
    await tester.tap(find.byKey(const ValueKey('theme_toggle')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    final returning = surfaceColors(tester);
    for (var i = 0; i < light.length; i++) {
      expect(returning[i], isNot(dark[i]));
      expect(returning[i], isNot(light[i]));
    }
    await tester.pumpAndSettle();
    expect(surfaceColors(tester), light);
    expect(theme(tester).brightness, Brightness.light);
  });

  testWidgets(
    'Switching themes preserves operands, running totals, and results',
    (tester) async {
      await tester.pumpWidget(const MyApp());
      await tapKeys(tester, ['2', '+', '3']);
      await toggleTheme(tester);
      expect(display(tester), '3');
      await tapKeys(tester, ['×']);
      expect(display(tester), '5');
      await toggleTheme(tester);
      await tapKeys(tester, ['4', '=']);
      expect(display(tester), '20');
      await toggleTheme(tester);
      expect(display(tester), '20');
      await tapKeys(tester, ['+', '2', '=']);
      expect(display(tester), '22');
    },
  );

  testWidgets('Both errors survive theme changes and AC keeps the theme', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tapKeys(tester, ['7', '+', '=']);
    await toggleTheme(tester);
    expect(find.text('Enter a number after the operator.'), findsOneWidget);
    expect(display(tester), '7');
    await tapKeys(tester, ['2', '=']);
    expect(display(tester), '9');
    await tapKeys(tester, ['8', '÷', '0', '=']);
    await toggleTheme(tester);
    expect(
      find.text('Cannot divide by zero. Press AC or enter a new number.'),
      findsOneWidget,
    );
    await toggleTheme(tester);
    await tapKeys(tester, ['AC']);
    expect(display(tester), '0');
    expect(find.byKey(const ValueKey('error_message')), findsNothing);
    expect(theme(tester).brightness, Brightness.dark);
    await tapKeys(tester, ['4', '+', '1', '=']);
    expect(display(tester), '5');
  });

  testWidgets('Text and error colors remain readable in both themes', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tapKeys(tester, ['8', '÷', '0', '=']);
    for (var i = 0; i < 2; i++) {
      final colors = surfaceColors(tester);
      final displayText = DefaultTextStyle.of(
        tester.element(find.byKey(const ValueKey('display'))),
      ).style.color!;
      final buttonText = DefaultTextStyle.of(
        tester.element(
          find.descendant(
            of: find.byKey(const ValueKey('key_8')),
            matching: find.byType(Text),
          ),
        ),
      ).style.color!;
      final error = tester
          .widget<Text>(find.byKey(const ValueKey('error_message')))
          .style!
          .color!;
      expect(contrast(displayText, colors[3]), greaterThanOrEqualTo(4.5));
      expect(contrast(buttonText, colors[2]), greaterThanOrEqualTo(4.5));
      expect(contrast(error, colors[0]), greaterThanOrEqualTo(4.5));
      await toggleTheme(tester);
    }
  });

  testWidgets(
    'Theme toggle stays reachable with enlarged text on a narrow screen',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(const MyApp());
      final toggle = find.byKey(const ValueKey('theme_toggle'));
      expect(toggle.hitTestable(), findsOneWidget);
      await toggleTheme(tester);
      await tapKeys(tester, ['8', '÷', '0', '=']);
      expect(toggle.hitTestable(), findsOneWidget);
      await toggleTheme(tester);
      expect(find.byKey(const ValueKey('error_message')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
