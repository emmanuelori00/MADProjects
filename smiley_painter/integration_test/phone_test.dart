import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:smiley_painter/main.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final screen = GlobalKey();
  final pictures = <String, String>{};
  Future<void> capture(String name) async {
    final boundary =
        screen.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    pictures[name] = base64Encode(data!.buffer.asUint8List());
    image.dispose();
  }

  testWidgets('Phone drawing, gestures, and rotation', (tester) async {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    await tester.pumpWidget(
      RepaintBoundary(key: screen, child: const SmileyApp()),
    );
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();
    await capture('classic-portrait');

    await tester.drag(find.byType(Slider), const Offset(-240, 0));
    await tester.pumpAndSettle();
    await capture('sad-portrait');
    tester.widget<Slider>(find.byType(Slider)).onChanged!(0.5);
    await tester.pumpAndSettle();
    await capture('neutral-portrait');

    await tester.tap(find.byKey(const ValueKey('face')));
    await tester.pumpAndSettle();
    expect(find.text('Face changed to sleepy.'), findsOneWidget);
    await capture('sleepy-portrait');
    await tester.tap(find.byKey(const ValueKey('face')));
    await tester.pumpAndSettle();
    expect(find.text('Face changed to surprised.'), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);
    await capture('surprised-portrait');

    await tester.longPress(find.byKey(const ValueKey('face')));
    await tester.pumpAndSettle();
    expect(find.textContaining('New mood:'), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);
    await capture('long-press-feedback');

    await tester.tap(find.byType(DropdownButton<FaceType>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Classic').last);
    await tester.pumpAndSettle();
    tester.widget<Slider>(find.byType(Slider)).onChanged!(0.8);
    ScaffoldMessenger.of(tester.element(find.byType(Slider)))
        .removeCurrentSnackBar();
    await tester.pumpAndSettle();
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
    ]);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));
    expect(
      tester.view.physicalSize.width,
      greaterThan(tester.view.physicalSize.height),
    );
    expect(tester.takeException(), isNull);
    await capture('classic-landscape');
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    await tester.pumpAndSettle();
    await SystemChrome.setPreferredOrientations([]);
    binding.reportData = {'pictures': pictures};
  });
}
