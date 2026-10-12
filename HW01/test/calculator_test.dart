import 'package:flutter_test/flutter_test.dart';
import 'package:hw01/calculator.dart';

void press(Calculator calculator, String sequence) {
  for (final key in sequence.split(' ')) {
    if (key == 'AC') {
      calculator.clearAll();
    } else if (key == '=') {
      calculator.equals();
    } else if (['+', '−', '×', '÷'].contains(key)) {
      calculator.chooseOperator(key);
    } else {
      calculator.enterDigit(key);
    }
  }
}

void main() {
  for (final sequence in ['8 ÷ 0 =', '0 ÷ 0 =', '8 ÷ 0 +', '2 + 6 ÷ 0 ×']) {
    test('$sequence shows an error before calculating', () {
      final calculator = Calculator();
      press(calculator, sequence);
      expect(calculator.display, '0');
      expect(calculator.errorMessage, contains('Cannot divide by zero'));
      press(calculator, '= + × =');
      expect(calculator.display, '0');
      expect(calculator.errorMessage, contains('Cannot divide by zero'));
    });
  }

  for (final trigger in ['=', '+']) {
    test('Digits start fresh after division by zero triggered by $trigger', () {
      final calculator = Calculator();
      press(calculator, '8 ÷ 0 $trigger');
      press(calculator, '4 2');
      expect(calculator.errorMessage, isNull);
      expect(calculator.display, '42');
      press(calculator, '+ 1 =');
      expect(calculator.display, '43');
    });
  }

  test('AC clears the division error and all previous calculation state', () {
    final calculator = Calculator();
    press(calculator, '8 ÷ 0 = AC =');
    expect(calculator.errorMessage, isNull);
    expect(calculator.display, '0');
    press(calculator, '+ 4 =');
    expect(calculator.display, '4');
  });

  test(
    'Incomplete input keeps the pending operation until a number is entered',
    () {
      final calculator = Calculator();
      press(calculator, '7 + = =');
      expect(calculator.display, '7');
      expect(calculator.errorMessage, 'Enter a number after the operator.');
      press(calculator, '2');
      expect(calculator.errorMessage, isNull);
      press(calculator, '=');
      expect(calculator.display, '9');
    },
  );

  test('An incomplete-input warning allows operator replacement', () {
    final calculator = Calculator();
    press(calculator, '7 + = ×');
    expect(calculator.errorMessage, isNull);
    expect(calculator.display, '7');
    press(calculator, '2 =');
    expect(calculator.display, '14');
  });

  test('AC cancels an incomplete calculation and its warning', () {
    final calculator = Calculator();
    press(calculator, '7 + = AC');
    expect(calculator.errorMessage, isNull);
    expect(calculator.display, '0');
    press(calculator, '4 + 1 =');
    expect(calculator.display, '5');
  });

  test('Zero numerator and fractional division remain valid', () {
    final calculator = Calculator();
    press(calculator, '0 ÷ 5 =');
    expect(calculator.display, '0');
    expect(calculator.errorMessage, isNull);
    press(calculator, '5 ÷ 2 =');
    expect(calculator.display, '2.5');
    expect(calculator.errorMessage, isNull);
  });

  test(
    'Initial equals, operator replacement, and repeated equals are not errors',
    () {
      final calculator = Calculator();
      press(calculator, '=');
      expect(calculator.errorMessage, isNull);
      press(calculator, '9 + × 2 = =');
      expect(calculator.display, '18');
      expect(calculator.errorMessage, isNull);
    },
  );

  for (final state in {
    'initial display': '',
    'partial first operand': '1 2',
    'pending operator': '8 +',
    'partial second operand': '8 + 2',
    'running total': '8 + 2 ×',
    'finished result': '8 + 2 =',
  }.entries) {
    test('AC resets the ${state.key} and allows a fresh calculation', () {
      final calculator = Calculator();
      if (state.value.isNotEmpty) press(calculator, state.value);
      press(calculator, 'AC');
      expect(calculator.display, '0');
      press(calculator, '= =');
      expect(calculator.display, '0');
      press(calculator, '4 2');
      expect(calculator.display, '42');
      press(calculator, '=');
      expect(calculator.display, '42');
      press(calculator, '+ 1 =');
      expect(calculator.display, '43');
    });
  }

  test('AC clears a running total before an operator is pressed', () {
    final calculator = Calculator();
    press(calculator, '8 + 2 × AC + 4 =');
    expect(calculator.display, '4');
  });

  test('Repeated AC stays at zero and discards earlier operands', () {
    final calculator = Calculator();
    press(calculator, '8 + 2 × AC AC');
    expect(calculator.display, '0');
    press(calculator, '4 + 1 =');
    expect(calculator.display, '5');
  });

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
