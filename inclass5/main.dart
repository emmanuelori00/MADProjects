// BLOCK 1: Import Flutter's Material widgets and launch the app.
import 'package:flutter/material.dart';

void main() => runApp(const CounterApp());

// BLOCK 2: This app shell does not change, so it is a StatelessWidget.
class CounterApp extends StatelessWidget {
  const CounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CounterPage(),
    );
  }
}

// BLOCK 3: This screen changes after user interactions, so it is stateful.
class CounterPage extends StatefulWidget {
  const CounterPage({super.key});

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  // BLOCK 4: State fields determine what the user sees at any moment.
  int _counter = 40;
  int _increment = 7;
  final List<int> _history = [];
  final TextEditingController _incrementController = TextEditingController(text: '7');

  @override
  void dispose() {
    // Controllers use resources; dispose them when this screen is removed.
    _incrementController.dispose();
    super.dispose();
  }

  // BLOCK 5: Helper methods enforce rules before they change UI state.
  bool _isValidValue(int value) => value >= 10 && value <= 150;

  // Activity 05 color-feedback rule, driven by the same counter state.
  Color _counterColor() {
    if (_counter == 10) return Colors.red;
    if (_counter > 90) return Colors.green;
    return Colors.black;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _moveTo(int nextValue) {
    // Reject the action before changing state or creating a history record.
    if (!_isValidValue(nextValue)) {
      _showMessage(
        'Can\'t move to $nextValue. The range is 10-150. '
        'Counter stays at $_counter. Try a smaller step or move the slider.',
      );
      return;
    }
    // Repeating the same value isn't a change and shouldn't use an undo.
    if (nextValue == _counter) return;

    setState(() {
      _history.add(_counter); // Save only the state that can be restored.
      _counter = nextValue;
    });
  }

  void _readIncrement(String input) {
    final value = int.tryParse(input);
    if (value == null || value <= 0) {
      _showMessage(
        'Use a whole number above 0, like 7. No decimals or words. '
        'The active step is still $_increment.',
      );
      return; // Keep the last valid increment unchanged.
    }
    setState(() => _increment = value);
  }

  void _undo() {
    if (_history.isEmpty) {
      _showMessage('There is no earlier value to restore.');
      return;
    }
    setState(() => _counter = _history.removeLast());
  }

  void _reset() {
    if (_counter != 10) _moveTo(10);
  }

  @override
  Widget build(BuildContext context) {
    // BLOCK 6: Build reads state and connects widgets to user actions.
    return Scaffold(
      appBar: AppBar(title: const Text('Activity 05 Counter')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '$_counter',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: _counterColor(),
                  ),
            ),
            Slider(
              value: _counter.toDouble(), min: 10, max: 150, divisions: 140,
              // Each changed whole-number position saves the previous value.
              // Undo retraces those positions, including a slider drag.
              onChanged: (value) => _moveTo(value.round()),
            ),
            TextField(
              controller: _incrementController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Increment amount (starts at 7)',
                helperText: 'Enter a whole number above 0.',
              ),
              onChanged: _readIncrement,
            ),
            const SizedBox(height: 8),
            Text('Active step: $_increment'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton(onPressed: () => _moveTo(_counter - _increment), child: const Text('Decrease')),
                ElevatedButton(onPressed: () => _moveTo(_counter + _increment), child: const Text('Increase')),
                OutlinedButton(onPressed: _reset, child: const Text('Reset to 10')),
                OutlinedButton(onPressed: _undo, child: const Text('Undo')),
              ],
            ),
            const SizedBox(height: 20),
            Text(_history.isEmpty ? 'History: none' : 'History: ${_history.join(', ')}'),
          ],
        ),
      ),
    );
  }
}
