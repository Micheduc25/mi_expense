import '../models/currency_config.dart';

class CurrencyUtils {
  static String formatCurrency(double amount, {bool showSymbol = true}) {
    return CurrencyConfig.formatAmount(amount, showSymbol: showSymbol);
  }

  static bool isValidAmount(String input) {
    // Remove currency code, dots, and spaces
    final cleanInput = input
        .replaceAll('XAF', '')
        .replaceAll('.', '')
        .replaceAll(' ', '')
        .trim();

    // Check if the cleaned input is a valid number
    return RegExp(r'^\d+$').hasMatch(cleanInput);
  }

  static double parseAmount(String input) {
    // Remove currency code, dots, and spaces
    final cleanInput = input
        .replaceAll('XAF', '')
        .replaceAll('.', '')
        .replaceAll(' ', '')
        .trim();

    return double.parse(cleanInput);
  }
}
