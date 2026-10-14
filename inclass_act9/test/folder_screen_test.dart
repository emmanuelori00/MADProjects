import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inclass_act8/database_helper.dart';
import 'package:inclass_act8/folder.dart';
import 'package:inclass_act8/main.dart';
import 'package:sqflite/sqflite.dart';

class DuplicateFolder extends DatabaseException {
  DuplicateFolder() : super('UNIQUE constraint failed: folders.name');
  @override
  int? getResultCode() => 2067;
  @override
  Object? get result => null;
}

class FolderHelper extends DatabaseHelper {
  final folders = <Folder>[];
  int writes = 0;
  int nextId = 10;
  int? deletedId;
  bool failRead = false;
  bool failWrite = false;
  bool failReadAfterWrite = false;
  Completer<void>? pendingWrite;

  @override
  Future<List<Folder>> getFoldersWithCounts() async {
    if (failRead) throw StateError('Read unavailable');
    return List.of(folders);
  }

  @override
  Future<int> insertFolder(String name) async {
    if (failWrite) throw StateError('Write unavailable');
    await pendingWrite?.future;
    if (folders.any((folder) => folder.name == name)) throw DuplicateFolder();
    writes++;
    final id = nextId++;
    folders.add(Folder(id: id, name: name, createdAt: '2026-10-13T12:00:00'));
    if (failReadAfterWrite) failRead = true;
    return id;
  }

  @override
  Future<int> deleteFolder(int id) async {
    if (failWrite) throw StateError('Write unavailable');
    deletedId = id;
    writes++;
    final before = folders.length;
    folders.removeWhere((folder) => folder.id == id);
    if (failReadAfterWrite) failRead = true;
    return before - folders.length;
  }

  @override
  Future<List<Map<String, dynamic>>> queryAllRows() async => [];
  @override
  Future<int> queryRowCount() async => 0;
}

Future<void> startFolders(WidgetTester tester, FolderHelper helper) async {
  tester.view.physicalSize = const Size(900, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(DirectoryApp(helper: helper));
  await tester.pumpAndSettle();
}

Future<void> confirmDialog(WidgetTester tester, String name) async {
  await tester.tap(find.byTooltip('Delete $name'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets(
    'Empty state, validation, duplicate feedback and guest navigation',
    (tester) async {
      final helper = FolderHelper();
      await startFolders(tester, helper);
      expect(find.text('No folders yet. Create one above.'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), '   ');
      await tester.tap(find.text('Create folder'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a folder name.'), findsOneWidget);
      expect(helper.writes, 0);
      await tester.enterText(find.byType(TextFormField), ' Atlas ');
      await tester.tap(find.text('Create folder'));
      await tester.pumpAndSettle();
      expect(helper.folders.single.name, 'Atlas');
      expect(find.text('Cards: 0'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), 'Atlas');
      await tester.tap(find.text('Create folder'));
      await tester.pumpAndSettle();
      expect(
        find.text('That folder name already exists. Choose another name.'),
        findsOneWidget,
      );
      expect(helper.writes, 1);
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField))
            .controller!
            .text,
        'Atlas',
      );
      await tester.tap(find.text('Guest roster'));
      await tester.pumpAndSettle();
      expect(find.text('Fall Festival Roster'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Folders'), findsOneWidget);
    },
  );

  testWidgets(
    'Counts, named cancel and confirmed deletion use the selected ID',
    (tester) async {
      final helper = FolderHelper()
        ..folders.addAll([
          const Folder(
            id: 41,
            name: 'Atlas',
            createdAt: '2026-10-13',
            cardCount: 2,
          ),
          const Folder(
            id: 77,
            name: 'Harbor',
            createdAt: '2026-10-13',
            cardCount: 1,
          ),
        ]);
      await startFolders(tester, helper);
      expect(find.text('Cards: 2'), findsOneWidget);
      expect(find.text('Cards: 1'), findsOneWidget);
      await confirmDialog(tester, 'Atlas');
      expect(find.text('Delete "Atlas" and all its cards?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(helper.writes, 0);
      await confirmDialog(tester, 'Atlas');
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(helper.deletedId, 41);
      expect(helper.folders.single.id, 77);
      expect(find.text('Deleted "Atlas".'), findsOneWidget);
    },
  );

  testWidgets(
    'Failed read shows an error instead of empty and Refresh retries',
    (tester) async {
      final helper = FolderHelper()..failRead = true;
      await startFolders(tester, helper);
      expect(
        find.text('Could not load folders. Tap Refresh to retry.'),
        findsOneWidget,
      );
      expect(find.text('No folders yet. Create one above.'), findsNothing);
      helper.failRead = false;
      await tester.tap(find.text('Refresh'));
      await tester.pumpAndSettle();
      expect(find.text('No folders yet. Create one above.'), findsOneWidget);
      expect(helper.writes, 0);
    },
  );

  testWidgets(
    'Failed write keeps input; busy blocks repeats; failed refresh only rereads',
    (tester) async {
      final helper = FolderHelper()..failWrite = true;
      await startFolders(tester, helper);
      await tester.enterText(find.byType(TextFormField), 'Atlas');
      await tester.tap(find.text('Create folder'));
      await tester.pumpAndSettle();
      expect(
        find.text('Could not create the folder. Your name is kept; try again.'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField))
            .controller!
            .text,
        'Atlas',
      );
      helper.failWrite = false;
      helper.failReadAfterWrite = true;
      helper.pendingWrite = Completer<void>();
      await tester.tap(find.text('Create folder'));
      await tester.pump();
      for (final label in ['Create folder', 'Refresh']) {
        expect(
          tester
              .widget<ElevatedButton>(
                find.widgetWithText(ElevatedButton, label),
              )
              .onPressed,
          isNull,
        );
      }
      expect(
        tester.widget<TextFormField>(find.byType(TextFormField)).enabled,
        false,
      );
      helper.pendingWrite!.complete();
      await tester.pumpAndSettle();
      expect(helper.writes, 1);
      expect(
        find.text('Created "Atlas". Refresh failed. Tap Refresh to retry.'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField))
            .controller!
            .text,
        isEmpty,
      );
      helper.failRead = false;
      await tester.tap(find.text('Refresh'));
      await tester.pumpAndSettle();
      expect(helper.writes, 1);
      expect(find.text('Cards: 0'), findsOneWidget);
    },
  );

  testWidgets('Delete failure and missing row do not claim success', (
    tester,
  ) async {
    final helper = FolderHelper()
      ..folders.add(
        const Folder(id: 41, name: 'Atlas', createdAt: '2026-10-13'),
      );
    await startFolders(tester, helper);
    helper.failWrite = true;
    await confirmDialog(tester, 'Atlas');
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(
      find.text('Could not delete the folder. Try again.'),
      findsOneWidget,
    );
    expect(helper.folders.length, 1);
    helper.failWrite = false;
    await confirmDialog(tester, 'Atlas');
    helper.folders.clear();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(
      find.text('Folder no longer exists. Deleted 0 folders.'),
      findsOneWidget,
    );
    expect(find.text('No folders yet. Create one above.'), findsOneWidget);
  });

  testWidgets('Successful delete with failed refresh never repeats deletion', (
    tester,
  ) async {
    final helper = FolderHelper()
      ..folders.add(
        const Folder(id: 41, name: 'Atlas', createdAt: '2026-10-13'),
      );
    await startFolders(tester, helper);
    helper.failReadAfterWrite = true;
    await confirmDialog(tester, 'Atlas');
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(
      find.text('Deleted "Atlas". Refresh failed. Tap Refresh to retry.'),
      findsOneWidget,
    );
    expect(helper.writes, 1);
    helper.failRead = false;
    await tester.tap(find.text('Refresh'));
    await tester.pumpAndSettle();
    expect(helper.writes, 1);
    expect(helper.folders, isEmpty);
  });
}
