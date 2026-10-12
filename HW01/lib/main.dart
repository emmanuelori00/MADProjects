import 'package:flutter/material.dart';

import 'calculator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: const CalculatorPage(),
    );
  }
}

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  final Calculator _calculator = Calculator();

  void _pressKey(String key) {
    setState(() {
      if (key == 'AC') {
        _calculator.clearAll();
      } else if (key == '=') {
        _calculator.equals();
      } else if (['+', '−', '×', '÷'].contains(key)) {
        _calculator.chooseOperator(key);
      } else {
        _calculator.enterDigit(key);
      }
    });
  }

  Widget _button(String key) {
    const labels = {
      'AC': 'All clear',
      '+': 'Add',
      '−': 'Subtract',
      '×': 'Multiply',
      '÷': 'Divide',
      '=': 'Equals',
    };
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: FilledButton.tonal(
          key: ValueKey('key_$key'),
          onPressed: () => _pressKey(key),
          style: FilledButton.styleFrom(
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            key,
            semanticsLabel: labels[key] ?? key,
            style: const TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calculator')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final rowHeight = ((constraints.maxHeight - 160) / 4).clamp(
                  64.0,
                  96.0,
                );
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: 120,
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.centerRight,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _calculator.display,
                                key: const ValueKey('display'),
                                semanticsLabel:
                                    'Display ${_calculator.display}',
                                style: const TextStyle(fontSize: 48),
                              ),
                            ),
                          ),
                          for (final row in [
                            ['7', '8', '9', '÷'],
                            ['4', '5', '6', '×'],
                            ['1', '2', '3', '−'],
                            ['AC', '0', '=', '+'],
                          ])
                            SizedBox(
                              height: rowHeight,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [for (final key in row) _button(key)],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
