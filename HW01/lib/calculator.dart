class Calculator {
  double? _accumulator;
  String _currentOperand = '0';
  String? _pendingOperator;
  bool _awaitingOperand = true;
  bool _showingResult = false;

  String get display {
    if (_awaitingOperand || _showingResult) {
      final result = (_accumulator ?? 0).toString();
      return result.endsWith('.0')
          ? result.substring(0, result.length - 2)
          : result;
    }
    return _currentOperand;
  }

  void enterDigit(String digit) {
    if (_showingResult) {
      _accumulator = null;
      _pendingOperator = null;
      _awaitingOperand = true;
      _showingResult = false;
    }
    if (_awaitingOperand || _currentOperand == '0') {
      _currentOperand = digit;
    } else {
      _currentOperand += digit;
    }
    _awaitingOperand = false;
  }

  void chooseOperator(String operator) {
    if (!_awaitingOperand && !_showingResult) {
      _applyOperand();
    }
    _accumulator ??= 0;
    // A second operator replaces the first until a new operand is entered.
    _pendingOperator = operator;
    _awaitingOperand = true;
    _showingResult = false;
  }

  void equals() {
    if (_awaitingOperand || _showingResult) return;
    // Even a single number followed by equals finishes the entry.
    _applyOperand();
    _pendingOperator = null;
    _showingResult = true;
  }

  void _applyOperand() {
    final operand = double.parse(_currentOperand);
    // Commit each pending pair immediately to evaluate left to right.
    switch (_pendingOperator) {
      case '+':
        _accumulator = _accumulator! + operand;
      case '−':
        _accumulator = _accumulator! - operand;
      case '×':
        _accumulator = _accumulator! * operand;
      case '÷':
        _accumulator = _accumulator! / operand;
      default:
        _accumulator = operand;
    }
  }
}
