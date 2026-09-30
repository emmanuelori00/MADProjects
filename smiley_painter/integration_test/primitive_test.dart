import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Bullseye and hat paint order on the phone', (tester) async {
    final pictures = <String, String>{};
    final names = ['bullseye', 'hat-on-top', 'hat-behind-face'];
    for (int step = 0; step < 3; step++) {
      if (step > 0) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(seconds: 65)),
        );
      }
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: MaterialApp(
            home: Scaffold(
              appBar: AppBar(title: Text(names[step])),
              body: CustomPaint(
                painter: PracticePainter(step),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      pictures[names[step]] = base64Encode(bytes!.buffer.asUint8List());
      image.dispose();
    }
    binding.reportData = {'pictures': pictures};
  });
}

class PracticePainter extends CustomPainter {
  PracticePainter(this.step);
  final int step;
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide * 0.4;
    final hat = Rect.fromCenter(
      center: c + Offset(0, -r * 0.7),
      width: r * 1.5,
      height: r * 0.5,
    );
    if (step == 2) canvas.drawRect(hat, Paint()..color = Colors.indigo);
    canvas.drawCircle(c, r, Paint()..color = Colors.amber);
    if (step == 0) {
      canvas.drawCircle(c, r * 0.65, Paint()..color = Colors.blue);
      canvas.drawCircle(c, r * 0.3, Paint()..color = Colors.red);
    }
    if (step > 0) {
      final black = Paint()..color = Colors.black;
      canvas.drawCircle(c + Offset(-r * 0.35, -r * 0.25), r * 0.09, black);
      canvas.drawCircle(c + Offset(r * 0.35, -r * 0.25), r * 0.09, black);
      canvas.drawArc(
        Rect.fromCenter(
          center: c + Offset(0, r * 0.15),
          width: r,
          height: r * 0.7,
        ),
        pi * 0.15,
        pi * 0.7,
        false,
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.035,
      );
    }
    if (step == 1) canvas.drawRect(hat, Paint()..color = Colors.indigo);
  }

  @override
  bool shouldRepaint(covariant PracticePainter old) => old.step != step;
}
