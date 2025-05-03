class CurrencyConfig {
  static const String defaultCurrency = 'XAF';
  static const String currencySymbol = 'FCFA';

  static String formatAmount(double amount) {
    // Format according to CFA Francs convention (e.g., 1.000 XAF)
    final formattedNumber = amount.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
    return '$formattedNumber $defaultCurrency';
  }
}
