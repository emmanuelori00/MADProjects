import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smiley_painter/main.dart';

SmileyPainter currentPainter(WidgetTester tester) {
  final drawing = tester.widget<CustomPaint>(
    find.byWidgetPredicate(
      (widget) => widget is CustomPaint && widget.painter is SmileyPainter,
    ),
  );
  return drawing.painter! as SmileyPainter;
}

void main() {
  testWidgets('Slider updates the mood and the correct color band', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SmileyApp());

    expect(find.text('Mood: 0.80'), findsOneWidget);
    expect(currentPainter(tester).faceType, FaceType.classic);
    expect(currentPainter(tester).faceColor, Colors.orange.shade300);

    // First check a real drag, then check the exact band boundaries.
    await tester.drag(find.byType(Slider), const Offset(-100, 0));
    await tester.pumpAndSettle();
    expect(currentPainter(tester).mood, lessThan(0.8));

    final moods = [0.0, 0.34, 0.35, 0.7, 0.71, 1.0];
    final colors = [
      Colors.lightBlue.shade200,
      Colors.lightBlue.shade200,
      Colors.yellow.shade600,
      Colors.yellow.shade600,
      Colors.orange.shade300,
      Colors.orange.shade300,
    ];

    for (int i = 0; i < moods.length; i++) {
      tester.widget<Slider>(find.byType(Slider)).onChanged!(moods[i]);
      await tester.pump();
      expect(currentPainter(tester).mood, moods[i]);
      expect(currentPainter(tester).faceColor, colors[i]);
      expect(find.text('Mood: ${moods[i].toStringAsFixed(2)}'), findsOneWidget);
    }
  });

  testWidgets('Dropdown changes the selected face without restarting', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SmileyApp());

    await tester.tap(find.byType(DropdownButton<FaceType>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Surprised').last);
    await tester.pumpAndSettle();
    expect(currentPainter(tester).faceType, FaceType.surprised);

    await tester.tap(find.byType(DropdownButton<FaceType>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sleepy').last);
    await tester.pumpAndSettle();
    expect(currentPainter(tester).faceType, FaceType.sleepy);
  });

  testWidgets('Face gestures cycle designs and replace feedback messages', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SmileyApp());
    final face = find.byKey(const ValueKey('face'));

    await tester.tap(face);
    await tester.pumpAndSettle();
    expect(currentPainter(tester).faceType, FaceType.sleepy);
    expect(find.byType(SnackBar), findsOneWidget);

    await tester.tap(face);
    await tester.pumpAndSettle();
    expect(currentPainter(tester).faceType, FaceType.surprised);
    expect(find.byType(SnackBar), findsOneWidget);

    await tester.tap(face);
    await tester.pumpAndSettle();
    expect(currentPainter(tester).faceType, FaceType.classic);

    // A random double is below 1, so start at 1 to check that it changes.
    tester.widget<Slider>(find.byType(Slider)).onChanged!(1.0);
    await tester.pump();
    await tester.longPress(face);
    await tester.pumpAndSettle();
    final randomized = currentPainter(tester);
    expect(randomized.mood, greaterThanOrEqualTo(0.0));
    expect(randomized.mood, lessThan(1.0));
    if (randomized.mood < 0.35) {
      expect([
        Colors.lightBlue.shade200,
        Colors.cyan.shade200,
      ], contains(randomized.faceColor));
    } else if (randomized.mood <= 0.7) {
      expect([
        Colors.yellow.shade600,
        Colors.yellow.shade300,
      ], contains(randomized.faceColor));
    } else {
      expect([
        Colors.orange.shade300,
        Colors.deepOrange.shade200,
      ], contains(randomized.faceColor));
    }
    expect(randomized.faceType, FaceType.classic);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.textContaining('New mood:'), findsOneWidget);
    expect(
      find.text('Mood: ${randomized.mood.toStringAsFixed(2)}'),
      findsOneWidget,
    );

    // Moving the slider again should restore its normal color rules.
    tester.widget<Slider>(find.byType(Slider)).onChanged!(0.5);
    await tester.pump();
    expect(currentPainter(tester).faceColor, Colors.yellow.shade600);

    // Old action messages should not remain queued after this one finishes.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('Drawing and controls fit portrait and landscape phone sizes', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final sizes = [
      const Size(412, 915),
      const Size(915, 412),
      const Size(390, 844),
      const Size(844, 390),
    ];

    for (final size in sizes) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(const SmileyApp());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(Slider).hitTestable(), findsOneWidget);
      expect(
        find.byType(DropdownButton<FaceType>).hitTestable(),
        findsOneWidget,
      );
      final drawing = tester.getRect(find.byKey(const ValueKey('face')));
      expect(drawing.width, greaterThan(0));
      expect(drawing.height, greaterThan(0));
      expect(drawing.left, greaterThanOrEqualTo(0));
      expect(drawing.top, greaterThanOrEqualTo(0));
      expect(drawing.right, lessThanOrEqualTo(size.width));
      expect(drawing.bottom, lessThanOrEqualTo(size.height));
    }
  });

  test('Painter repaints only when one of its drawing inputs changes', () {
    final original = SmileyPainter(
      mood: 0.8,
      faceColor: Colors.orange,
      faceType: FaceType.classic,
    );

    expect(
      SmileyPainter(
        mood: 0.8,
        faceColor: Colors.orange,
        faceType: FaceType.classic,
      ).shouldRepaint(original),
      isFalse,
    );
    expect(
      SmileyPainter(
        mood: 0.3,
        faceColor: Colors.orange,
        faceType: FaceType.classic,
      ).shouldRepaint(original),
      isTrue,
    );
    expect(
      SmileyPainter(
        mood: 0.8,
        faceColor: Colors.blue,
        faceType: FaceType.classic,
      ).shouldRepaint(original),
      isTrue,
    );
    expect(
      SmileyPainter(
        mood: 0.8,
        faceColor: Colors.orange,
        faceType: FaceType.sleepy,
      ).shouldRepaint(original),
      isTrue,
    );
  });
}
