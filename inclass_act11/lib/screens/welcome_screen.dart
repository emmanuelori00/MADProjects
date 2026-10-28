import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';

import 'signup_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2E1065), Color(0xFF14101F)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cookie_outlined,
                    size: 80,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 24),
                  AnimatedTextKit(
                    isRepeatingAnimation: false,
                    animatedTexts: [
                      TypewriterAnimatedText(
                        'Spooky Snack Club',
                        textAlign: TextAlign.center,
                        textStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                        speed: const Duration(milliseconds: 90),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SignupScreen(),
                      ),
                    ),
                    child: const Text('Enter if you dare'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
