# HW01 Calculator

The app implements the core calculator, Clear/AC, and error handling. It uses a
StatefulWidget and setState to update the screen. Calculator stores the current
operand, accumulator, pending operator, and input phase. The display is derived
from those values.

## State transitions

| Input | What happens |
| --- | --- |
| Digit while entering a number | Append it; replace a leading zero. |
| Digit after an operator | Start the next operand. |
| Operator after an operand | Apply the pending operation, show the running total, and store the new operator. |
| Operator while waiting for an operand | Replace the pending operator without calculating. |
| Equals after an operand | Finish the pending operation and show the result. |
| Equals without a new operand | Keep the display and pending operation unchanged; if an operator is pending, ask for the next number. |
| Digit after equals | Start a new calculation with no previous accumulator or operator. |
| Operator after equals | Continue using the result. |
| AC at any point | Show 0 and clear all calculation state and error feedback. |

The invariant is that an operator cannot use the same operand twice. While the
app is waiting for another operand, operators only change the pending operator
and equals does not calculate. It can show a message asking for the next number.

## Error handling

Division by zero is checked before applying a pending operation, whether equals
or the next operator triggers it. The app shows "Cannot divide by zero. Press AC
or enter a new number." It keeps the numeric display at 0 instead of showing
Infinity or NaN. Operators and equals do nothing until the user recovers. AC
resets everything, or entering a digit starts a fresh calculation.

For 7 + =, the app shows "Enter a number after the operator." The display stays
at 7 and + is still pending, so entering 2 = gives 9. The user can also replace
the operator or press AC. Initial equals and repeated equals after a result do
not show warnings. Error messages use text as well as color and a semantic live
region. On a small screen with enlarged text, the content can scroll so the
message and AC remain reachable.

## Test traces

These sequences are checked in test/calculator_test.dart. The main running-total
sequence is also checked by tapping the actual buttons in test/widget_test.dart.

| Keys | Expected display after each key |
| --- | --- |
| 2 + 3 × 4 = | 2, 2, 3, 5, 4, 20 |
| 9 + × 2 = | 9, 9, 9, 2, 18 |
| 7 + = = 2 = | 7, 7, 7, 7, 2, 9 |
| 8 + 2 = 4 + 1 = | 8, 8, 2, 10, 4, 4, 1, 5 |
| 8 + 2 × AC 4 + 1 = | 8, 8, 2, 10, 0, 4, 4, 1, 5 |

AC is tested from the initial display, during either operand, after an operator,
after a running total, and after equals. The tests check repeated AC, equals
immediately after AC, and a fresh multi-digit calculation. A separate test uses
8 + 2 × AC + 4 = to confirm the old accumulator cannot affect the new result.
The widget test taps AC and verifies the display resets and the next result is 5.

The tests also cover all four operations, negative and fractional results,
multi-digit input, repeated equals, and a 320 × 568 layout with text scaled to 2.
Error tests cover 8 ÷ 0 =, 0 ÷ 0 =, division by zero during a chain, recovery
with digits or AC, incomplete input, and valid division with a zero numerator.
Widget tests check both messages, recovery, and error text with enlarged text.

## Run and check

    flutter pub get
    flutter run
    flutter analyze
    flutter test
    flutter build apk --debug

Clear/AC and error handling are implemented. Theme toggle is selected for a
later checkpoint. There is no theme switch, percent, sign toggle, or decimal
input. Division can produce a fractional result. Overflow handling and decimal
precision improvements are outside this checkpoint.
