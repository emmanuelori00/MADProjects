class Calculator {
  double? _accumulator;
  String _currentOperand = '0';
  String? _pendingOperator;
  bool _awaitingOperand = true;
  bool _showingResult = false;
  bool _hasCalculationError = false;
  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  void clearAll() {
    _accumulator = null;
    _currentOperand = '0';
    _pendingOperator = null;
    _awaitingOperand = true;
    _showingResult = false;
    _hasCalculationError = false;
    _errorMessage = null;
  }

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
    if (_hasCalculationError) clearAll();
    _errorMessage = null;
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
    if (_hasCalculationError) return;
    _errorMessage = null;
    if (!_awaitingOperand && !_showingResult) {
      if (!_applyOperand()) return;
    }
    _accumulator ??= 0;
    // A second operator replaces the first until a new operand is entered.
    _pendingOperator = operator;
    _awaitingOperand = true;
    _showingResult = false;
  }

  void equals() {
    if (_hasCalculationError) return;
    if (_awaitingOperand && _pendingOperator != null) {
      // Give feedback without changing the pending calculation.
      _errorMessage = 'Enter a number after the operator.';
      return;
    }
    if (_awaitingOperand || _showingResult) return;
    // Even a single number followed by equals finishes the entry.
    if (!_applyOperand()) return;
    _pendingOperator = null;
    _showingResult = true;
  }

  bool _applyOperand() {
    final operand = double.parse(_currentOperand);
    if (_pendingOperator == '÷' && operand == 0) {
      _hasCalculationError = true;
      _errorMessage = 'Cannot divide by zero. Press AC or enter a new number.';
      return false;
    }
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
    return true;
  }
}
