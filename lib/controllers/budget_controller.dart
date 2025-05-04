import 'package:get/get.dart';
import '../models/budget.dart';
import '../services/database_service.dart';

class BudgetController extends GetxController {
  final DatabaseService _db = Get.find<DatabaseService>();

  final RxList<Budget> budgets = <Budget>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchBudgets();
  }

  Future<void> fetchBudgets() async {
    isLoading.value = true;
    try {
      budgets.value = await _db.getBudgets();
    } catch (e) {
      Get.snackbar('Error', 'Failed to load budgets: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchCurrentMonthBudgets() async {
    isLoading.value = true;
    try {
      budgets.value = await _db.getCurrentMonthBudgets();
    } catch (e) {
      Get.snackbar(
          'Error', 'Failed to load current month budgets: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addBudget(Budget budget) async {
    isLoading.value = true;
    try {
      final id = await _db.insertBudget(budget);
      final newBudget = Budget(
        id: id,
        categoryId: budget.categoryId,
        amount: budget.amount,
        startDate: budget.startDate,
        endDate: budget.endDate,
        spentAmount: budget.spentAmount,
      );
      budgets.add(newBudget);
      Get.back(); // Navigate back after adding
      Get.snackbar('Success', 'Budget added successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to add budget: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateBudget(Budget budget) async {
    isLoading.value = true;
    try {
      await _db.updateBudget(budget);
      final index = budgets.indexWhere((b) => b.id == budget.id);
      if (index != -1) {
        budgets[index] = budget;
      }
      Get.back(); // Navigate back after editing
      Get.snackbar('Success', 'Budget updated successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update budget: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteBudget(String id) async {
    isLoading.value = true;
    try {
      await _db.deleteBudget(id);
      budgets.removeWhere((b) => b.id == id);
      Get.snackbar('Success', 'Budget deleted successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete budget: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateBudgetSpentAmount(String categoryId, double amount) async {
    try {
      final now = DateTime.now();
      final budget = await _db.getBudgetByCategory(categoryId, now);

      if (budget != null) {
        budget.spentAmount += amount;
        await _db.updateBudget(budget);

        final index = budgets.indexWhere((b) => b.id == budget.id);
        if (index != -1) {
          budgets[index] = budget;
        }
      }
    } catch (e) {
      Get.snackbar(
          'Error', 'Failed to update budget spent amount: ${e.toString()}');
    }
  }

  List<Budget> getBudgetsExceeded() {
    return budgets.where((budget) => budget.isExceeded).toList();
  }

  double getTotalBudgetAmount() {
    return budgets.fold(0, (sum, budget) => sum + budget.amount);
  }

  double getTotalBudgetSpentAmount() {
    return budgets.fold(0, (sum, budget) => sum + budget.spentAmount);
  }
}
