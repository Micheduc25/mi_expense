import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'currency_config.dart';

enum TransactionType { expense, income }

enum PaymentMethod {
  cash,
  card,
  mobilePayment,
  bankTransfer,
  cheque,
  crypto,
  other
}

class Transaction {
  final String? id;
  final double amount;
  final TransactionType type;
  final DateTime date;
  final String category;
  final String? description;
  final PaymentMethod paymentMethod;
  final String? receiptImagePath;
  final String? location;

  Transaction({
    this.id,
    required this.amount,
    required this.type,
    required this.date,
    required this.category,
    this.description,
    required this.paymentMethod,
    this.receiptImagePath,
    this.location,
  });

  // Create a Transaction from a Map (for database operations)
  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      amount: map['amount'],
      type: TransactionType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => TransactionType.expense,
      ),
      date: DateTime.parse(map['date']),
      category: map['category'],
      description: map['description'],
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.toString() == map['paymentMethod'],
        orElse: () => PaymentMethod.cash,
      ),
      receiptImagePath: map['receiptImagePath'],
      location: map['location'],
    );
  }

  // Convert Transaction to a Map (for database operations)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'type': type.toString(),
      'date': date.toIso8601String(),
      'category': category,
      'description': description,
      'paymentMethod': paymentMethod.toString(),
      'receiptImagePath': receiptImagePath,
      'location': location,
    };
  }

  // Format the transaction date
  String get formattedDate => DateFormat('yyyy-MM-dd').format(date);

  // Format the transaction amount with currency
  String get formattedAmount => CurrencyConfig.formatAmount(amount);

  // Check if transaction is an expense
  bool get isExpense => type == TransactionType.expense;

  // Check if transaction is income
  bool get isIncome => type == TransactionType.income;

  // Create a copy of this transaction with some fields modified
  Transaction copyWith({
    String? id,
    double? amount,
    TransactionType? type,
    DateTime? date,
    String? category,
    String? description,
    PaymentMethod? paymentMethod,
    String? receiptImagePath,
    String? location,
  }) {
    return Transaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      date: date ?? this.date,
      category: category ?? this.category,
      description: description ?? this.description,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
      location: location ?? this.location,
    );
  }
}
