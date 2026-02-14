import 'package:flutter/services.dart';

/// Allows only digits, an optional single decimal point, and up to two
/// digits after the decimal.  
/// If the user types something that would break that rule, we just
/// return [oldValue], leaving the field unchanged.
class TwoDecimalTextInputFormatter extends TextInputFormatter {
  static final _exp = RegExp(r'^[0-9]*\.?[0-9]{0,2}$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // If the new text matches our pattern, accept it; otherwise reject:
    if (_exp.hasMatch(newValue.text)) {
      return newValue;
    }
    // Reject the change by returning oldValue
    return oldValue;
  }
}

/// Allows only digits, an optional single decimal point, and up to one
/// digit after the decimal (e.g., 7.5, 225.5, etc.)
/// If the user types something that would break that rule, we just
/// return [oldValue], leaving the field unchanged.
class OneDecimalTextInputFormatter extends TextInputFormatter {
  static final _exp = RegExp(r'^[0-9]*\.?[0-9]{0,1}$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // If the new text matches our pattern, accept it; otherwise reject:
    if (_exp.hasMatch(newValue.text)) {
      return newValue;
    }
    // Reject the change by returning oldValue
    return oldValue;
  }
}

/// Allows only RPE values between 0 and 10 (inclusive) with up to one decimal place
/// Valid examples: 0, 5.5, 7, 10, 9.5
/// Invalid examples: 10.5, 11, -1, 15
class RPEInputFormatter extends TextInputFormatter {
  static final _exp = RegExp(r'^[0-9]*\.?[0-9]{0,1}$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Allow empty string (user is clearing the field)
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // First check if it matches the decimal pattern
    if (!_exp.hasMatch(newValue.text)) {
      return oldValue;
    }

    // Try to parse the value
    final value = double.tryParse(newValue.text);
    
    // If it can't be parsed or is out of range (0-10), reject it
    if (value == null || value < 0 || value > 10) {
      return oldValue;
    }

    // Valid input
    return newValue;
  }
}
