import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inclass_act8/card_record.dart';
import 'package:inclass_act8/folder.dart';
import 'package:inclass_act8/main.dart';

import 'folder_screen_test.dart' show FolderHelper;

class CardHelper extends FolderHelper {
  final cards = <CardRecord>[];
  int nextCardId = 100;

  CardHelper() {
    folders.addAll([
      const Folder(id: 41, name: 'Atlas', createdAt: '2026-10-13'),
      const Folder(id: 77, name: 'Harbor', createdAt: '2026-10-13'),
    ]);
  }

  @override
  Future<List<Folder>> getFoldersWithCounts() async {
    final rows = await super.getFoldersWithCounts();
    return rows
        .map(
          (f) => Folder(
            id: f.id,
            name: f.name,
            createdAt: f.createdAt,
            cardCount: cards.where((c) => c.folderId == f.id).length,
          ),
        )
        .toList();
  }

  @override
  Future<List<CardRecord>> getCards(int folderId) async {
    if (failRead) throw StateError('Read unavailable');
    return cards.where((c) => c.folderId == folderId).toList();
  }

  @override
  Future<int> insertCard(CardRecord card) async {
    if (failWrite) throw StateError('Write unavailable');
    await pendingWrite?.future;
    writes++;
    final id = nextCardId++;
    cards.add(CardRecord.fromMap({...card.toMap(), 'id': id}));
    if (failReadAfterWrite) failRead = true;
    return id;
  }

  @override
  Future<int> updateCard(CardRecord card) async {
    if (failWrite) throw StateError('Write unavailable');
    writes++;
    final index = cards.indexWhere((c) => c.id == card.id);
    if (index == -1) return 0;
    cards[index] = card;
    if (failReadAfterWrite) failRead = true;
    return 1;
  }

  @override
  Future<int> deleteCard(int id) async {
    if (failWrite) throw StateError('Write unavailable');
    writes++;
    final before = cards.length;
    cards.removeWhere((c) => c.id == id);
    if (failReadAfterWrite) failRead = true;
    return before - cards.length;
  }
}

Future<void> startCards(WidgetTester tester, CardHelper helper) async {
  tester.view.physicalSize = const Size(1000, 1700);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(DirectoryApp(helper: helper));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(ListTile, 'Atlas'));
  await tester.pumpAndSettle();
}

Future<void> deleteDialog(WidgetTester tester, int id) async {
  final button = find.byTooltip('Delete card $id');
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets(
    'Blank title, defaults, suit selection and folder count refresh',
    (tester) async {
      final helper = CardHelper();
      await startCards(tester, helper);
      expect(find.text('No cards in this folder yet.'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).first, '   ');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a card title.'), findsOneWidget);
      expect(helper.writes, 0);
      await tester.enterText(find.byType(TextFormField).first, ' Compass ');
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Spades').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      expect(helper.cards.single.title, 'Compass');
      expect(helper.cards.single.suit, 'Spades');
      expect(helper.cards.single.folderId, 41);
      expect(helper.cards.single.notes, '');
      expect(helper.cards.single.imageRef, isNull);
      expect(find.text('♠'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.widgetWithText(ListTile, 'Atlas'),
          matching: find.text('Cards: 1'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Duplicate titles edit by ID; cancel edit and cancel delete do not write',
    (tester) async {
      final helper = CardHelper()
        ..cards.addAll([
          const CardRecord(
            id: 11,
            title: 'Compass',
            suit: 'Hearts',
            folderId: 41,
          ),
          const CardRecord(
            id: 22,
            title: 'Compass',
            suit: 'Diamonds',
            folderId: 41,
          ),
          const CardRecord(
            id: 33,
            title: 'Signal',
            suit: 'Spades',
            folderId: 77,
          ),
        ]);
      await startCards(tester, helper);
      expect(find.text('Signal'), findsNothing);
      await tester.tap(find.byTooltip('Edit card 22'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'Not saved');
      await tester.tap(find.text('Cancel edit'));
      await tester.pumpAndSettle();
      expect(helper.writes, 0);
      await tester.tap(find.byTooltip('Edit card 11'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).first,
        'Compass revised',
      );
      await tester.enterText(find.byType(TextFormField).last, 'Saved notes');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(helper.cards.first.title, 'Compass revised');
      expect(helper.cards.first.notes, 'Saved notes');
      expect(helper.cards[1].title, 'Compass');
      await deleteDialog(tester, 22);
      expect(find.text('Delete "Compass" (ID 22)?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(helper.writes, 1);
      await deleteDialog(tester, 22);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(helper.cards.map((c) => c.id), [11, 33]);
      expect(find.text('Cards: 1'), findsOneWidget);
    },
  );

  testWidgets(
    'Moving a card uses selected folder ID and resets Add to current folder',
    (tester) async {
      final helper = CardHelper()
        ..cards.add(
          const CardRecord(
            id: 11,
            title: 'Compass',
            suit: 'Clubs',
            folderId: 41,
          ),
        );
      await startCards(tester, helper);
      await tester.tap(find.byTooltip('Edit card 11'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Harbor').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(helper.cards.single.folderId, 77);
      expect(find.text('No cards in this folder yet.'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).first, 'New card');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      expect(helper.cards.last.folderId, 41);
      expect(helper.cards.last.suit, 'Hearts');
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Cards: 1'), findsNWidgets(2));
    },
  );

  testWidgets(
    'Read failures are not empty lists and a removed folder cannot be selected',
    (tester) async {
      final helper = CardHelper();
      await startCards(tester, helper);
      helper.failRead = true;
      await tester.tap(find.text('Refresh'));
      await tester.pumpAndSettle();
      expect(
        find.text('Could not load cards. Tap Refresh to retry.'),
        findsOneWidget,
      );
      expect(find.text('No cards in this folder yet.'), findsNothing);
      helper.failRead = false;
      helper.folders.removeWhere((f) => f.id == 41);
      await tester.tap(find.text('Refresh'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'Card');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      expect(find.text('Choose an existing folder.'), findsOneWidget);
      expect(helper.writes, 0);
    },
  );

  testWidgets(
    'Failed write retains input; pending save blocks repeats; refresh retry does not insert twice',
    (tester) async {
      final helper = CardHelper()..failWrite = true;
      await startCards(tester, helper);
      await tester.enterText(find.byType(TextFormField).first, 'Signal');
      await tester.enterText(
        find.byType(TextFormField).last,
        'Keep these notes',
      );
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      expect(
        find.text('Could not save. Your input is kept; try again.'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).last)
            .controller!
            .text,
        'Keep these notes',
      );
      helper.failWrite = false;
      helper.failReadAfterWrite = true;
      helper.pendingWrite = Completer<void>();
      await tester.tap(find.text('Add'));
      await tester.pump();
      expect(
        tester
            .widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Add'))
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, 'Refresh'),
            )
            .onPressed,
        isNull,
      );
      helper.pendingWrite!.complete();
      await tester.pumpAndSettle();
      expect(helper.writes, 1);
      expect(
        find.text('Saved card ID 100. Refresh failed. Tap Refresh to retry.'),
        findsOneWidget,
      );
      helper.failRead = false;
      await tester.tap(find.text('Refresh'));
      await tester.pumpAndSettle();
      expect(helper.writes, 1);
      expect(helper.cards.length, 1);
    },
  );

  testWidgets(
    'Delete failure keeps row; successful deletion refresh never repeats write',
    (tester) async {
      final helper = CardHelper()
        ..cards.add(
          const CardRecord(
            id: 11,
            title: 'Compass',
            suit: 'Hearts',
            folderId: 41,
          ),
        );
      await startCards(tester, helper);
      helper.failWrite = true;
      await deleteDialog(tester, 11);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(
        find.text('Could not delete the card. Try again.'),
        findsOneWidget,
      );
      expect(helper.cards.length, 1);
      helper.failWrite = false;
      helper.failReadAfterWrite = true;
      await deleteDialog(tester, 11);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(
        find.text('Deleted card ID 11. Refresh failed. Tap Refresh to retry.'),
        findsOneWidget,
      );
      helper.failRead = false;
      await tester.tap(find.text('Refresh'));
      await tester.pumpAndSettle();
      expect(helper.writes, 1);
      expect(helper.cards, isEmpty);
    },
  );

  testWidgets('Missing update and delete report zero rows', (tester) async {
    final helper = CardHelper()
      ..cards.add(
        const CardRecord(
          id: 11,
          title: 'Compass',
          suit: 'Hearts',
          folderId: 41,
        ),
      );
    await startCards(tester, helper);
    await tester.tap(find.byTooltip('Edit card 11'));
    await tester.pumpAndSettle();
    helper.cards.clear();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(
      find.text('Card no longer exists. Updated 0 cards.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancel edit'));
    helper.cards.add(
      const CardRecord(id: 22, title: 'Other', suit: 'Hearts', folderId: 41),
    );
    await tester.tap(find.text('Refresh'));
    await tester.pumpAndSettle();
    await deleteDialog(tester, 22);
    helper.cards.clear();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(
      find.text('Card no longer exists. Deleted 0 cards.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'All suit symbols remain visible with null or unusable image references',
    (tester) async {
      final helper = CardHelper();
      for (var i = 0; i < CardRecord.suits.length; i++) {
        helper.cards.add(
          CardRecord(
            id: i + 1,
            title: 'Card $i',
            suit: CardRecord.suits[i],
            folderId: 41,
            imageRef: i == 0 ? null : 'missing-image',
          ),
        );
      }
      await startCards(tester, helper);
      for (final symbol in ['♥', '♦', '♣', '♠']) {
        expect(find.text(symbol), findsOneWidget);
      }
      expect(find.byType(Image), findsNothing);
    },
  );
}
