import 'package:intl/intl.dart';
import 'currency_config.dart';

class Budget {
  final String? id;
  final String categoryId;
  final double amount;
  final DateTime startDate;
  final DateTime endDate;
  double spentAmount;

  Budget({
    this.id,
    required this.categoryId,
    required this.amount,
    required this.startDate,
    required this.endDate,
    this.spentAmount = 0.0,
  });

  // Create a Budget from a Map (for database operations)
  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'],
      categoryId: map['categoryId'],
      amount: map['amount'],
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
      spentAmount: map['spentAmount'] ?? 0.0,
    );
  }

  // Convert Budget to a Map (for database operations)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoryId': categoryId,
      'amount': amount,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'spentAmount': spentAmount,
    };
  }

  // Format the budget amount with currency
  String get formattedAmount => CurrencyConfig.formatAmount(amount);

  // Format the spent amount with currency
  String get formattedSpentAmount => CurrencyConfig.formatAmount(spentAmount);

  // Calculate the remaining budget
  double get remainingAmount => amount - spentAmount;

  // Format the remaining amount with currency
  String get formattedRemainingAmount =>
      CurrencyConfig.formatAmount(remainingAmount);

  // Calculate the percentage of budget spent
  double get percentageSpent => (spentAmount / amount) * 100;

  // Check if budget is exceeded
  bool get isExceeded => spentAmount > amount;

  // Check if the budget is for the current month
  bool get isCurrentMonth {
    final now = DateTime.now();
    return startDate.year == now.year &&
        startDate.month == now.month &&
        endDate.year == now.year &&
        endDate.month == now.month;
  }

  // Format the budget period (e.g., "May 2025")
  String get formattedPeriod => DateFormat('MMMM yyyy').format(startDate);
}
