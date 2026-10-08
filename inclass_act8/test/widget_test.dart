import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inclass_act8/database_helper.dart';
import 'package:inclass_act8/main.dart';

class FakeHelper extends DatabaseHelper {
  final rows = <Map<String, dynamic>>[];
  int nextId = 10;
  int writes = 0;
  bool failRead = false;
  bool failWrite = false;
  bool failReadAfterWrite = false;
  Completer<void>? pendingWrite;

  @override
  Future<List<Map<String, dynamic>>> queryAllRows() async {
    if (failRead) throw StateError('Read unavailable');
    return rows.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  @override
  Future<int> queryRowCount() async => rows.length;

  @override
  Future<int> insert(Map<String, dynamic> row) async {
    if (failWrite) throw StateError('Write unavailable');
    await pendingWrite?.future;
    writes++;
    final id = nextId++;
    rows.add({'_id': id, ...row});
    if (failReadAfterWrite) failRead = true;
    return id;
  }

  @override
  Future<int> update(Map<String, dynamic> row) async {
    if (failWrite) throw StateError('Write unavailable');
    writes++;
    final index = rows.indexWhere((existing) => existing['_id'] == row['_id']);
    if (index == -1) return 0;
    rows[index] = Map<String, dynamic>.from(row);
    return 1;
  }

  @override
  Future<int> delete(int id) async {
    writes++;
    final before = rows.length;
    rows.removeWhere((row) => row['_id'] == id);
    return before - rows.length;
  }
}

Future<void> start(WidgetTester tester, FakeHelper helper) async {
  tester.view.physicalSize = const Size(900, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(DirectoryApp(helper: helper));
  await tester.pumpAndSettle();
}

Future<void> fill(WidgetTester tester, String name, String age) async {
  await tester.enterText(find.byType(TextFormField).at(0), name);
  await tester.enterText(find.byType(TextFormField).at(1), age);
}

void main() {
  testWidgets(
    'Validation rejects five invalid inputs and accepts both boundaries',
    (tester) async {
      final helper = FakeHelper();
      await start(tester, helper);
      expect(find.text('Record count: 0'), findsOneWidget);
      for (final input in [
        ['   ', '21'],
        ['Maple', 'abc'],
        ['Maple', '1.5'],
        ['Maple', '-1'],
        ['Maple', '131'],
      ]) {
        await fill(tester, input[0], input[1]);
        await tester.tap(find.text('Add'));
        await tester.pumpAndSettle();
        expect(helper.writes, 0);
        expect(helper.rows, isEmpty);
        expect(find.text('Record count: 0'), findsOneWidget);
        expect(
          find.text(
            input[0].trim().isEmpty
                ? 'Enter a name.'
                : 'Enter an integer age from 0 to 130.',
          ),
          findsOneWidget,
        );
      }
      for (final input in [
        [' Acorn ', '0'],
        ['Oak', '130'],
      ]) {
        await fill(tester, input[0], input[1]);
        await tester.tap(find.text('Add'));
        await tester.pumpAndSettle();
      }
      expect(helper.rows.map((row) => row['age']), [0, 130]);
      expect(helper.rows.first['name'], 'Acorn');
      expect(helper.rows.map((row) => row['_id']).toSet().length, 2);
      expect(find.text('Record count: 2'), findsOneWidget);
    },
  );

  testWidgets('Duplicate names edit and delete by ID, with both cancel paths', (
    tester,
  ) async {
    final helper = FakeHelper()
      ..rows.addAll([
        {'_id': 41, 'name': 'River', 'age': 21},
        {'_id': 77, 'name': 'River', 'age': 34},
      ]);
    await start(tester, helper);
    await tester.tap(find.byTooltip('Edit ID 77'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(1), '99');
    await tester.tap(find.text('Cancel edit'));
    await tester.pumpAndSettle();
    expect(helper.writes, 0);
    expect(helper.rows.last['age'], 34);
    await tester.tap(find.byTooltip('Edit ID 77'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(1), '35');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(helper.rows.map((row) => row['age']), [21, 35]);
    expect(find.text('Saved ID 77. Updated 1 row'), findsOneWidget);
    await tester.tap(find.byTooltip('Delete ID 41'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Delete ID 41: River?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(helper.rows.length, 2);
    await tester.tap(find.byTooltip('Edit ID 77'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete ID 77'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(helper.rows.single['_id'], 41);
    expect(find.text('Add guest'), findsOneWidget);
    expect(find.text('Record count: 1'), findsOneWidget);
  });

  testWidgets('A successful write with failed refresh retries only the read', (
    tester,
  ) async {
    final helper = FakeHelper()..failReadAfterWrite = true;
    await start(tester, helper);
    await fill(tester, 'Maple', '22');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(helper.writes, 1);
    expect(
      find.text(
        'Saved guest with ID 10, but refresh failed. Tap Refresh to retry.',
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).first)
          .controller!
          .text,
      isEmpty,
    );
    helper.failRead = false;
    await tester.tap(find.text('Refresh'));
    await tester.pumpAndSettle();
    expect(helper.writes, 1);
    expect(find.text('Record count: 1'), findsOneWidget);
  });

  testWidgets('Failed writes retain input and pending writes disable actions', (
    tester,
  ) async {
    final helper = FakeHelper()..failWrite = true;
    await start(tester, helper);
    await fill(tester, 'Oak', '130');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(
      find.text('Could not save. Your input is kept; try again.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).first)
          .controller!
          .text,
      'Oak',
    );
    helper.failWrite = false;
    helper.pendingWrite = Completer<void>();
    await tester.tap(find.text('Add'));
    await tester.pump();
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField).first).enabled,
      false,
    );
    expect(
      tester
          .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Refresh'),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Add'))
          .onPressed,
      isNull,
    );
    helper.pendingWrite!.complete();
    await tester.pumpAndSettle();
    expect(helper.writes, 1);
  });

  testWidgets('Missing ID is reported without claiming success', (
    tester,
  ) async {
    final helper = FakeHelper()
      ..rows.add({'_id': 77, 'name': 'River', 'age': 34});
    await start(tester, helper);
    await tester.tap(find.byTooltip('Edit ID 77'));
    await tester.pumpAndSettle();
    helper.rows.clear();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(
      find.text('ID 77 no longer exists. Updated 0 rows.'),
      findsOneWidget,
    );
    expect(find.text('Record count: 0'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).first)
          .controller!
          .text,
      'River',
    );
  });
}
