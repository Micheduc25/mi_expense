import '../models/currency_config.dart';

class CurrencyUtils {
  static String formatCurrency(double amount) {
    return CurrencyConfig.formatAmount(amount);
  }

  static bool isValidAmount(String input) {
    // Remove any dots and spaces
    final cleanInput = input.replaceAll('.', '').replaceAll(' ', '');
    // Check if the cleaned input is a valid number
    return RegExp(r'^\d+$').hasMatch(cleanInput);
  }

  static double parseAmount(String input) {
    // Remove any dots and spaces
    final cleanInput = input.replaceAll('.', '').replaceAll(' ', '');
    return double.parse(cleanInput);
  }
}
