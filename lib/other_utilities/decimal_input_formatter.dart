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
