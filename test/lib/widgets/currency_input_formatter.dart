import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Formats the input to a currency-style string with thousand separators.
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Remove all non-digit characters
    final newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (newText.isEmpty) {
      return const TextEditingValue();
    }

    final number = double.parse(newText);
    final formatter = NumberFormat.decimalPattern('en_US');
    final formattedText = formatter.format(number);

    return newValue.copyWith(
        text: formattedText,
        selection: TextSelection.collapsed(offset: formattedText.length));
  }
}
