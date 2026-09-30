// In-Class Activity 06 — Drawing with Flutter
// Student: Emmanuel Gohourou
// Date: September 30, 2026

import 'dart:math';

import 'package:flutter/material.dart';

void main() => runApp(const SmileyApp());

enum FaceType { classic, sleepy, surprised }

class SmileyApp extends StatelessWidget {
  const SmileyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smiley Painter Lab',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const DrawingPlayground(),
    );
  }
}

class DrawingPlayground extends StatefulWidget {
  const DrawingPlayground({super.key});

  @override
  State<DrawingPlayground> createState() => _DrawingPlaygroundState();
}

class _DrawingPlaygroundState extends State<DrawingPlayground> {
  double mood = 0.8;
  FaceType faceType = FaceType.classic;
  Color faceColor = Colors.orange.shade300;
  final random = Random();

  Color moodColor(double value) {
    if (value < 0.35) return Colors.lightBlue.shade200;
    if (value <= 0.7) return Colors.yellow.shade600;
    return Colors.orange.shade300;
  }

  void showMessage(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.removeCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  void cycleFace() {
    setState(() {
      if (faceType == FaceType.classic) {
        faceType = FaceType.sleepy;
      } else if (faceType == FaceType.sleepy) {
        faceType = FaceType.surprised;
      } else {
        faceType = FaceType.classic;
      }
    });
    showMessage('Face changed to ${faceType.name}.');
  }

  void randomizeFace() {
    setState(() {
      mood = random.nextDouble();
      // Pick a random shade that still fits the mood band.
      if (mood < 0.35) {
        faceColor = random.nextBool()
            ? Colors.lightBlue.shade200
            : Colors.cyan.shade200;
      } else if (mood <= 0.7) {
        faceColor = random.nextBool()
            ? Colors.yellow.shade600
            : Colors.yellow.shade300;
      } else {
        faceColor = random.nextBool()
            ? Colors.orange.shade300
            : Colors.deepOrange.shade200;
      }
    });
    showMessage('New mood: ${mood.toStringAsFixed(2)} and a new face color.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Smiley Painter Lab')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: GestureDetector(
                key: const ValueKey('face'),
                behavior: HitTestBehavior.opaque,
                onTap: cycleFace,
                onLongPress: randomizeFace,
                child: CustomPaint(
                  painter: SmileyPainter(
                    mood: mood,
                    faceColor: faceColor,
                    faceType: faceType,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            const Text('Tap the face to switch. Hold to randomize.'),
            DropdownButton<FaceType>(
              value: faceType,
              onChanged: (value) {
                if (value != null) setState(() => faceType = value);
              },
              items: const [
                DropdownMenuItem(
                  value: FaceType.classic,
                  child: Text('Classic'),
                ),
                DropdownMenuItem(value: FaceType.sleepy, child: Text('Sleepy')),
                DropdownMenuItem(
                  value: FaceType.surprised,
                  child: Text('Surprised'),
                ),
              ],
            ),
            Text('Mood: ${mood.toStringAsFixed(2)}'),
            Slider(
              value: mood,
              onChanged: (value) {
                setState(() {
                  mood = value;
                  faceColor = moodColor(value);
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

class SmileyPainter extends CustomPainter {
  SmileyPainter({
    required this.mood,
    required this.faceColor,
    required this.faceType,
  });
  final double mood;
  final Color faceColor;
  final FaceType faceType;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.4;
    final fill = Paint()..color = faceColor;
    final stroke = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.035
      ..strokeCap = StrokeCap.round;
    final eyePaint = Paint()..color = Colors.black87;

    // Draw the face first so it does not cover the eyes and mouth.
    canvas.drawCircle(center, radius, fill);
    canvas.drawCircle(center, radius, stroke);
    final leftEye = Offset(
      center.dx - radius * 0.35,
      center.dy - radius * 0.25,
    );
    final rightEye = Offset(
      center.dx + radius * 0.35,
      center.dy - radius * 0.25,
    );

    if (faceType == FaceType.sleepy) {
      canvas.drawArc(
        Rect.fromCenter(
          center: leftEye,
          width: radius * 0.25,
          height: radius * 0.15,
        ),
        0,
        pi,
        false,
        stroke,
      );
      canvas.drawArc(
        Rect.fromCenter(
          center: rightEye,
          width: radius * 0.25,
          height: radius * 0.15,
        ),
        0,
        pi,
        false,
        stroke,
      );
    } else {
      double eyeRadius = radius * 0.09;
      if (faceType == FaceType.surprised) eyeRadius = radius * 0.14;
      canvas.drawCircle(leftEye, eyeRadius, eyePaint);
      canvas.drawCircle(rightEye, eyeRadius, eyePaint);
    }

    if (faceType == FaceType.surprised) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(center.dx, center.dy + radius * 0.35),
          width: radius * 0.3,
          height: radius * (0.25 + mood * 0.2),
        ),
        stroke,
      );
    } else {
      double mouthHeight = radius * (0.15 + mood * 0.2);
      if (mood > 0.7 && faceType == FaceType.classic) {
        mouthHeight = radius * (0.5 + mood * 0.3);
      }
      final mouthRect = Rect.fromCenter(
        center: Offset(center.dx, center.dy + radius * 0.15),
        width: radius,
        height: mouthHeight,
      );
      if (mood < 0.35) {
        canvas.drawArc(
          mouthRect.translate(0, radius * 0.25),
          1.15 * pi,
          0.70 * pi,
          false,
          stroke,
        );
      } else {
        canvas.drawArc(mouthRect, 0.15 * pi, 0.70 * pi, false, stroke);
      }
    }
  }

  @override
  bool shouldRepaint(covariant SmileyPainter oldDelegate) {
    return oldDelegate.mood != mood ||
        oldDelegate.faceColor != faceColor ||
        oldDelegate.faceType != faceType;
  }
}
