import 'package:flutter/material.dart';

// This widget gets no name, email, password, or form key.
class LocalSignupTip extends StatefulWidget {
  const LocalSignupTip({super.key});

  @override
  State<LocalSignupTip> createState() => _LocalSignupTipState();
}

class _LocalSignupTipState extends State<LocalSignupTip> {
  static const _category = 'password_help';
  static const _tips = {
    'password_help': [
      'Use a long password that you do not use for another account.',
      'Avoid using your name or birthday in your password.',
    ],
  };

  bool _loading = false;
  String? _tip;
  String? _error;
  int _nextTip = 0;

  Future<void> _getTip({bool showError = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _tip = null;
      _error = null;
    });

    // A short wait lets us show the loading part of the local demo.
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    final choices = _tips[_category];
    setState(() {
      _loading = false;
      if (showError || choices == null || choices.isEmpty) {
        _error = 'Could not load the demo tip. Tap Retry.';
      } else {
        final text = choices[_nextTip % choices.length];
        if (text.trim().isEmpty || text.length > 240) {
          _error = 'Could not load the demo tip. Tap Retry.';
        } else {
          _tip = text;
          _nextTip++;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Need a signup tip?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text('Preset demo tips, not live AI output.'),
            const Text('Tips do not check or approve your signup.'),
            const SizedBox(height: 12),
            if (_loading) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              const Text('Loading a demo tip...'),
            ],
            if (_tip != null) Semantics(liveRegion: true, child: Text(_tip!)),
            if (_error != null) ...[
              Semantics(liveRegion: true, child: Text(_error!)),
              TextButton(onPressed: _getTip, child: const Text('Retry')),
            ],
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _loading ? null : _getTip,
              child: const Text('Get a signup tip'),
            ),
            TextButton(
              onPressed: _loading ? null : () => _getTip(showError: true),
              child: const Text('Try a tip error'),
            ),
          ],
        ),
      ),
    );
  }
}
