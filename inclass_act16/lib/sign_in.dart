import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

Future<void> signInWithEmail(String email, String password) async {
  await FirebaseAuth.instance
      .signInWithEmailAndPassword(email: email, password: password);
}

class SignInScreen extends StatefulWidget {
  final Future<void> Function(String, String) signIn;
  const SignInScreen({super.key, this.signIn = signInWithEmail});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool busy = false;
  String? error;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (busy) return;
    if (email.text.trim().isEmpty || password.text.isEmpty) {
      setState(() => error = 'Enter your email and password.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.signIn(email.text.trim(), password.text);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        error = switch (e.code) {
          'network-request-failed' => 'Check your connection and try again.',
          'too-many-requests' => 'Too many sign-in attempts. Try again later.',
          'invalid-credential' ||
          'invalid-email' ||
          'user-not-found' ||
          'wrong-password' =>
            'Check your email and password, then try again.',
          _ => 'Sign-in failed (${e.code}).',
        };
      });
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Class A Quiz')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        TextField(
            controller: email,
            enabled: !busy,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Email')),
        TextField(
            controller: password,
            enabled: !busy,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            onSubmitted: (_) => submit(),
            decoration: const InputDecoration(labelText: 'Password')),
        if (error != null) Text(error!),
        FilledButton(
            onPressed: busy ? null : submit,
            child: Text(busy ? 'Signing in…' : 'Sign in')),
      ]),
    );
  }
}
