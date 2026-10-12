# HW01 Calculator

This checkpoint implements the core left-to-right calculator. The app uses a
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
| Equals without a new operand | Keep the display and pending operation unchanged. |
| Digit after equals | Start a new calculation with no previous accumulator or operator. |
| Operator after equals | Continue using the result. |

The invariant is that an operator cannot use the same operand twice. While the
app is waiting for another operand, operators only change the pending operator
and equals does nothing.

## Test traces

These sequences are checked in test/calculator_test.dart. The main running-total
sequence is also checked by tapping the actual buttons in test/widget_test.dart.

| Keys | Expected display after each key |
| --- | --- |
| 2 + 3 × 4 = | 2, 2, 3, 5, 4, 20 |
| 9 + × 2 = | 9, 9, 9, 2, 18 |
| 7 + = = 2 = | 7, 7, 7, 7, 2, 9 |
| 8 + 2 = 4 + 1 = | 8, 8, 2, 10, 4, 4, 1, 5 |

The tests also cover all four operations, negative and fractional results,
multi-digit input, repeated equals, and a 320 × 568 layout with text scaled to 2.

## Run and check

    flutter pub get
    flutter run
    flutter analyze
    flutter test
    flutter build apk --debug

Optional pathway features are not part of this checkpoint. There is no AC,
theme switch, percent, sign toggle, or decimal input. Division can produce a
fractional result. Division-by-zero messages and recovery are not implemented;
Dart's non-finite result is displayed for now.
