import 'package:flutter/material.dart';

void main() {
  runApp(const TactileDeckApp());
}

class TactileDeckApp extends StatefulWidget {
  const TactileDeckApp({super.key});

  @override
  State<TactileDeckApp> createState() => _TactileDeckAppState();
}

class _TactileDeckAppState extends State<TactileDeckApp> {
  bool isDarkMode = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cyber-Tactile Control Studio',
      debugShowCheckedModeBanner: false,
      theme: isDarkMode
          ? ThemeData.dark(useMaterial3: true)
          : ThemeData.light(useMaterial3: true),
      home: ControlDeckScreen(
        isDark: isDarkMode,
        onToggleTheme: () {
          setState(() {
            isDarkMode = !isDarkMode;
          });
        },
      ),
    );
  }
}

class ControlDeckScreen extends StatefulWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;

  const ControlDeckScreen({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
  });

  @override
  State<ControlDeckScreen> createState() => _ControlDeckScreenState();
}

class _ControlDeckScreenState extends State<ControlDeckScreen> {
  int totalTaps = 0;
  double powerLevel = 65.0;
  String systemStatus = 'READY';

  // Question 1: set true to test the shared-state bug.
  // Return to false after the experiment.
  final bool testSharedPress = false;
  bool sharedIsPressed = false;

  // Question 3: set true to move the unpressed highlight
  // to the top-right. Return to false after the experiment.
  final bool testTopRightLight = false;

  // Question 4: your actual four button configurations.
  // Add four more records here to support eight buttons.
  final buttons = [
    (
      icon: Icons.blender,
      label: 'BLENDER',
      color: Colors.orange,
      action: 'BLEND',
    ),
    (
      icon: Icons.bakery_dining,
      label: 'BAKE',
      color: Colors.brown,
      action: 'BAKE',
    ),
    (
      icon: Icons.ac_unit,
      label: 'CHILL',
      color: Colors.lightBlue,
      action: 'CHILL',
    ),
    (
      icon: Icons.whatshot,
      label: 'SEAR',
      color: Colors.deepOrange,
      action: 'SEAR',
    ),
  ];

  void _triggerAction(String actionName) {
    setState(() {
      totalTaps++;
      systemStatus = '$actionName ACTIVATED';
    });
  }

  void _changeSharedPress(bool value) {
    setState(() {
      sharedIsPressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isOverload = powerLevel > 80;

    final screenBg = isOverload
        ? (widget.isDark
            ? const Color(0xFF3A1712)
            : const Color(0xFFFBE6DF))
        : (widget.isDark
            ? const Color(0xFF1E1F29)
            : const Color(0xFFE0E5EC));

    final cardBg =
        widget.isDark ? const Color(0xFF282A36) : Colors.white;

    return Scaffold(
      backgroundColor: screenBg,
      appBar: AppBar(
        title: const Text(
          'TACTILE CONTROL STUDIO',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              widget.isDark ? Icons.light_mode : Icons.dark_mode,
            ),
            tooltip: 'Toggle Theme',
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(
                      widget.isDark ? 0.3 : 0.08,
                    ),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text(
                        'TOTAL TAPS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$totalTaps',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey.withOpacity(0.3),
                  ),
                  Column(
                    children: [
                      const Text(
                        'ENERGY LEVEL',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${powerLevel.toInt()}%',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'STATUS: $systemStatus',
              style: TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
                color: widget.isDark
                    ? Colors.tealAccent
                    : Colors.teal.shade700,
              ),
            ),
            const SizedBox(height: 28),
            Wrap(
              spacing: 20,
              runSpacing: 20,
              alignment: WrapAlignment.center,
              children: [
                for (final button in buttons)
                  TactileButton(
                    icon: button.icon,
                    label: button.label,
                    accentColor: button.color,
                    isDark: widget.isDark,
                    onPressed: () => _triggerAction(button.action),
                    sharedPressed:
                        testSharedPress ? sharedIsPressed : null,
                    onPressChanged:
                        testSharedPress ? _changeSharedPress : null,
                    topRightLight: testTopRightLight,
                  ),
              ],
            ),
            const SizedBox(height: 36),
            Text(
              'Power Calibration: ${powerLevel.toInt()}%',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            Slider(
              value: powerLevel,
              min: 0,
              max: 100,
              activeColor: Colors.blueAccent,
              inactiveColor: Colors.grey.withOpacity(0.3),
              onChanged: (newVal) {
                setState(() {
                  powerLevel = newVal;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

class TactileButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color accentColor;
  final bool isDark;
  final VoidCallback onPressed;

  // Optional inputs used only for the experiments.
  final bool? sharedPressed;
  final ValueChanged<bool>? onPressChanged;
  final bool topRightLight;

  const TactileButton({
    super.key,
    required this.icon,
    required this.label,
    required this.accentColor,
    required this.isDark,
    required this.onPressed,
    this.sharedPressed,
    this.onPressChanged,
    this.topRightLight = false,
  });

  @override
  State<TactileButton> createState() => _TactileButtonState();
}

class _TactileButtonState extends State<TactileButton> {
  bool isPressed = false;

  void _updatePressed(bool value) {
    if (widget.onPressChanged != null) {
      // Experiment: update the parent's shared boolean.
      widget.onPressChanged!(value);
    } else {
      // Normal behavior: update only this button.
      setState(() {
        isPressed = value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pressed = widget.sharedPressed ?? isPressed;

    final baseColor = widget.isDark
        ? const Color(0xFF222430)
        : const Color(0xFFE0E5EC);

    final darkShadow =
        widget.isDark ? Colors.black87 : const Color(0xFFA3B1C6);

    final lightShadow =
        widget.isDark ? const Color(0xFF2F3244) : Colors.white;

    return GestureDetector(
      onTapDown: (_) {
        print('${widget.label}: onTapDown');
        _updatePressed(true);
      },
      onTapUp: (_) {
        print('${widget.label}: onTapUp');
        _updatePressed(false);
        widget.onPressed();
      },
      onTapCancel: () {
        print('${widget.label}: onTapCancel');
        _updatePressed(false);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: pressed
              ? [
                  BoxShadow(
                    color: darkShadow.withOpacity(0.5),
                    offset: const Offset(2, 2),
                    blurRadius: 4,
                  ),
                  BoxShadow(
                    color: lightShadow.withOpacity(0.5),
                    offset: const Offset(-2, -2),
                    blurRadius: 4,
                  ),
                ]
              : [
                  BoxShadow(
                    color: darkShadow.withOpacity(0.7),
                    offset: widget.topRightLight
                        ? const Offset(-8, 8)
                        : const Offset(8, 8),
                    blurRadius: 16,
                  ),
                  BoxShadow(
                    color: lightShadow.withOpacity(0.9),
                    offset: widget.topRightLight
                        ? const Offset(8, -8)
                        : const Offset(-8, -8),
                    blurRadius: 16,
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.icon,
              size: pressed ? 40 : 46,
              color: pressed
                  ? widget.accentColor
                  : (widget.isDark ? Colors.white70 : Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              widget.label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.1,
                color: pressed
                    ? widget.accentColor
                    : (widget.isDark
                        ? Colors.white54
                        : Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}