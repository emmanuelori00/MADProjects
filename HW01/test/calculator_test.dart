import 'package:flutter_test/flutter_test.dart';
import 'package:hw01/calculator.dart';

void press(Calculator calculator, String sequence) {
  for (final key in sequence.split(' ')) {
    if (key == '=') {
      calculator.equals();
    } else if (['+', '−', '×', '÷'].contains(key)) {
      calculator.chooseOperator(key);
    } else {
      calculator.enterDigit(key);
    }
  }
}

void main() {
  test('Starts at zero and enters multi-digit operands', () {
    final calculator = Calculator();
    expect(calculator.display, '0');
    press(calculator, '0 0 1 2 + 3 4 =');
    expect(calculator.display, '46');
  });

  test('Shows each transition in the left-to-right example', () {
    final calculator = Calculator();
    final keys = ['2', '+', '3', '×', '4', '='];
    final displays = ['2', '2', '3', '5', '4', '20'];
    for (var i = 0; i < keys.length; i++) {
      press(calculator, keys[i]);
      expect(calculator.display, displays[i], reason: 'After ${keys[i]}');
    }
  });

  for (final example in {
    '8 + 2 =': '10',
    '3 − 8 =': '-5',
    '6 × 7 =': '42',
    '5 ÷ 2 =': '2.5',
    '8 + 4 − 3 × 2 ÷ 6 =': '3',
    '1 2 + 3 × 4 =': '60',
    '9 + × 2 =': '18',
    '8 × 0 + 2 =': '2',
  }.entries) {
    test('${example.key} gives ${example.value}', () {
      final calculator = Calculator();
      press(calculator, example.key);
      expect(calculator.display, example.value);
    });
  }

  test('Equals without a new operand preserves the pending operation', () {
    final calculator = Calculator();
    press(calculator, '7 + = =');
    expect(calculator.display, '7');
    press(calculator, '2 =');
    expect(calculator.display, '9');
  });

  test('Repeated equals does not apply the operation again', () {
    final calculator = Calculator();
    press(calculator, '2 + 3 = = =');
    expect(calculator.display, '5');
  });

  test('Digit after a result starts fresh without a stale accumulator', () {
    final calculator = Calculator();
    press(calculator, '8 + 2 = 4 + 1 =');
    expect(calculator.display, '5');
  });

  test('Digit after a single number and equals starts fresh', () {
    final calculator = Calculator();
    press(calculator, '7 = 2');
    expect(calculator.display, '2');
  });

  test('An operator after equals continues from the result', () {
    final calculator = Calculator();
    press(calculator, '2 + 3 = × 4 =');
    expect(calculator.display, '20');
  });

  test('Equals on the initial display is ignored', () {
    final calculator = Calculator();
    press(calculator, '= =');
    expect(calculator.display, '0');
  });
}
