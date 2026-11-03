// The fake Firestore objects below are only used for these form tests.
// ignore_for_file: subtype_of_sealed_class

import 'package:autumn_products/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// These tests check the form. They dont connect to the real database.
class TestProducts extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  TestProducts({this.denySave = false});

  final saved = <Map<String, dynamic>>[];
  final bool denySave;

  @override
  Future<DocumentReference<Map<String, dynamic>>> add(
    Map<String, dynamic> data,
  ) async {
    if (denySave) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      );
    }
    saved.add(data);
    return TestDocument();
  }
}

class TestDocument extends Fake
    implements DocumentReference<Map<String, dynamic>> {}

Future<void> openEditor(WidgetTester tester, TestProducts products) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => ProductEditor(products: products),
            ),
            child: const Text('Add'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Add'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('A name with only spaces is rejected', (tester) async {
    final products = TestProducts();
    await openEditor(tester, products);
    await tester.enterText(find.byType(TextFormField).at(0), '   ');
    await tester.enterText(find.byType(TextFormField).at(1), '12.50');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a product name'), findsOneWidget);
    expect(products.saved, isEmpty);
  });

  for (final value in ['', 'toast', '-7', 'NaN', 'Infinity']) {
    testWidgets('Price "$value" doesnt save', (tester) async {
      final products = TestProducts();
      await openEditor(tester, products);
      await tester.enterText(find.byType(TextFormField).at(0), 'Cedar Mug');
      await tester.enterText(find.byType(TextFormField).at(1), value);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a finite price of zero or more'), findsOneWidget);
      expect(products.saved, isEmpty);
    });
  }

  testWidgets('Zero saves as a number and the name loses extra spaces', (
    tester,
  ) async {
    final products = TestProducts();
    await openEditor(tester, products);
    await tester.enterText(
      find.byType(TextFormField).at(0),
      '  Autumn Sample  ',
    );
    await tester.enterText(find.byType(TextFormField).at(1), '0');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(products.saved, [
      {'name': 'Autumn Sample', 'price': 0.0},
    ]);
    expect(find.byType(ProductEditor), findsNothing);
  });

  testWidgets('Cancel writes nothing and the next form is empty', (
    tester,
  ) async {
    final products = TestProducts();
    await openEditor(tester, products);
    await tester.enterText(find.byType(TextFormField).at(0), 'Temporary');
    await tester.enterText(find.byType(TextFormField).at(1), '20');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(products.saved, isEmpty);
    final fields = tester.widgetList<TextFormField>(find.byType(TextFormField));
    expect(fields.every((field) => field.controller!.text.isEmpty), isTrue);
  });

  testWidgets('A denied save keeps the form open and shows an error', (
    tester,
  ) async {
    final products = TestProducts(denySave: true);
    await openEditor(tester, products);
    await tester.enterText(find.byType(TextFormField).at(0), 'Cedar Mug');
    await tester.enterText(find.byType(TextFormField).at(1), '12.50');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Save failed (permission-denied)'),
      findsOneWidget,
    );
    expect(find.byType(ProductEditor), findsOneWidget);
    expect(products.saved, isEmpty);
  });
}
