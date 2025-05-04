import 'package:get/get.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';
import '../models/category.dart';

class TransactionController extends GetxController {
  final DatabaseService _db = Get.find<DatabaseService>();

  final RxList<Transaction> transactions = <Transaction>[].obs;
  final RxList<Transaction> filteredTransactions = <Transaction>[].obs;
  final RxBool isLoading = false.obs;
  final RxDouble balance = 0.0.obs;
  final RxDouble totalIncome = 0.0.obs;
  final RxDouble totalExpenses = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchTransactions();
  }

  Future<void> fetchTransactions() async {
    isLoading.value = true;
    try {
      transactions.value = await _db.getTransactions();
      filteredTransactions.value = transactions;
      updateBalanceSummary();
    } catch (e) {
      Get.snackbar('Error', 'Failed to load transactions: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addTransaction(Transaction transaction) async {
    if (isLoading.value) return; // Prevent multiple submissions
    isLoading.value = true;
    try {
      final id = await _db.insertTransaction(transaction);
      final newTransaction = transaction.copyWith(id: id);

      // Use .assignAll to create a new list reference instead of modifying the existing one
      final updatedTransactions = List<Transaction>.from(transactions);
      updatedTransactions.add(newTransaction);
      transactions.assignAll(updatedTransactions);

      // Update filtered transactions as well
      filteredTransactions.assignAll(updatedTransactions);

      updateBalanceSummary();
      Get.back(); // Navigate back after adding
      Get.snackbar('Success', 'Transaction added successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to add transaction: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateTransaction(Transaction transaction) async {
    isLoading.value = true;
    try {
      await _db.updateTransaction(transaction);
      final index = transactions.indexWhere((t) => t.id == transaction.id);
      if (index != -1) {
        transactions[index] = transaction;
      }

      final filteredIndex =
          filteredTransactions.indexWhere((t) => t.id == transaction.id);
      if (filteredIndex != -1) {
        filteredTransactions[filteredIndex] = transaction;
      }

      updateBalanceSummary();
      Get.back(); // Navigate back after editing
      Get.snackbar('Success', 'Transaction updated successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update transaction: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteTransaction(String id) async {
    isLoading.value = true;
    try {
      await _db.deleteTransaction(id);
      transactions.removeWhere((t) => t.id == id);
      filteredTransactions.removeWhere((t) => t.id == id);
      updateBalanceSummary();
      Get.snackbar('Success', 'Transaction deleted successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete transaction: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  void filterTransactionsByType(TransactionType? type) {
    if (type == null) {
      filteredTransactions.value = transactions;
    } else {
      filteredTransactions.value =
          transactions.where((t) => t.type == type).toList();
    }
  }

  void filterTransactionsByCategory(String categoryId) {
    filteredTransactions.value =
        transactions.where((t) => t.category == categoryId).toList();
  }

  void filterTransactionsByDateRange(DateTime start, DateTime end) {
    filteredTransactions.value = transactions
        .where((t) =>
            t.date.isAfter(start.subtract(const Duration(days: 1))) &&
            t.date.isBefore(end.add(const Duration(days: 1))))
        .toList();
  }

  void updateBalanceSummary() {
    totalIncome.value = 0;
    totalExpenses.value = 0;

    for (final transaction in transactions) {
      if (transaction.isIncome) {
        totalIncome.value += transaction.amount;
      } else {
        totalExpenses.value += transaction.amount;
      }
    }

    balance.value = totalIncome.value - totalExpenses.value;
  }

  Map<String, double> getCategoryTotals() {
    final Map<String, double> result = {};

    for (final transaction in transactions.where((t) => t.isExpense)) {
      if (result.containsKey(transaction.category)) {
        result[transaction.category] =
            result[transaction.category]! + transaction.amount;
      } else {
        result[transaction.category] = transaction.amount;
      }
    }

    return result;
  }
}
