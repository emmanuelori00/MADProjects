import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw01/main.dart';

void main() {
  testWidgets('AC button resets the display and the pending calculation', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    for (final step in [
      ['8', '8'],
      ['+', '8'],
      ['2', '2'],
      ['×', '10'],
      ['AC', '0'],
      ['4', '4'],
      ['+', '4'],
      ['1', '1'],
      ['=', '5'],
      ['AC', '0'],
      ['=', '0'],
    ]) {
      await tester.tap(find.byKey(ValueKey('key_${step[0]}')));
      await tester.pump();
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('display'))).data,
        step[1],
        reason: 'After ${step[0]}',
      );
    }
  });

  testWidgets('Buttons show the running total and final result', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    String display() =>
        tester.widget<Text>(find.byKey(const ValueKey('display'))).data!;
    expect(display(), '0');
    for (final step in [
      ['2', '2'],
      ['+', '2'],
      ['3', '3'],
      ['×', '5'],
      ['4', '4'],
      ['=', '20'],
      ['8', '8'],
    ]) {
      await tester.tap(find.byKey(ValueKey('key_${step[0]}')));
      await tester.pump();
      expect(display(), step[1]);
    }
  });

  testWidgets('Core keys and AC fit a narrow screen with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(const MyApp());
    for (final key in [
      'AC',
      '0',
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '+',
      '−',
      '×',
      '÷',
      '=',
    ]) {
      final button = find.byKey(ValueKey('key_$key'));
      expect(button.hitTestable(), findsOneWidget);
      final size = tester.getSize(button);
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    }
    expect(tester.takeException(), isNull);
  });
}
