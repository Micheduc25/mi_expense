import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/budget_controller.dart';
import '../controllers/category_controller.dart';
import '../models/budget.dart';
import '../utils/currency_utils.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final BudgetController budgetController = Get.find<BudgetController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Planning'),
      ),
      body: Obx(() {
        if (budgetController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (budgetController.budgets.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No budgets found',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Set up your first budget to start tracking your expenses',
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _showAddBudgetDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Budget'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => budgetController.fetchBudgets(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Budget summary
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Budget Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSummaryItem(
                        context,
                        label: 'Total Budget',
                        amount: budgetController.getTotalBudgetAmount(),
                      ),
                      const SizedBox(height: 8),
                      _buildSummaryItem(
                        context,
                        label: 'Total Spent',
                        amount: budgetController.getTotalBudgetSpentAmount(),
                        isExpense: true,
                      ),
                      const SizedBox(height: 8),
                      Divider(color: Theme.of(context).dividerColor),
                      const SizedBox(height: 8),
                      _buildSummaryItem(
                        context,
                        label: 'Remaining',
                        amount: budgetController.getTotalBudgetAmount() -
                            budgetController.getTotalBudgetSpentAmount(),
                        isExpense: budgetController.getTotalBudgetAmount() <
                            budgetController.getTotalBudgetSpentAmount(),
                      ),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: budgetController.getTotalBudgetAmount() > 0
                            ? budgetController.getTotalBudgetSpentAmount() /
                                budgetController.getTotalBudgetAmount()
                            : 0,
                        backgroundColor:
                            Theme.of(context).colorScheme.surfaceVariant,
                        color: budgetController.getTotalBudgetSpentAmount() >
                                budgetController.getTotalBudgetAmount()
                            ? Colors.red
                            : Theme.of(context).colorScheme.primary,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Your Budgets',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _showAddBudgetDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Budget'),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              ...budgetController.budgets
                  .map((budget) => _buildBudgetCard(context, budget)),
            ],
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBudgetDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context, {
    required String label,
    required double amount,
    bool isExpense = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        Text(
          CurrencyUtils.formatCurrency(amount),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isExpense ? Colors.red : null,
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetCard(BuildContext context, Budget budget) {
    final CategoryController categoryController =
        Get.find<CategoryController>();
    final BudgetController budgetController = Get.find<BudgetController>();

    final category = categoryController.getCategoryById(budget.categoryId);
    final percentSpent =
        budget.amount > 0 ? (budget.spentAmount / budget.amount * 100) : 0.0;
    final isExceeded = budget.spentAmount > budget.amount;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (category != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: category.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(category.icon, color: category.color),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category?.name ?? 'Unknown Category',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        budget.formattedPeriod,
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () =>
                      _confirmDeleteBudget(context, budgetController, budget),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Budget: ${budget.formattedAmount}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Spent: ${budget.formattedSpentAmount}',
                      style: TextStyle(
                        color: isExceeded ? Colors.red : null,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Remaining',
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      budget.formattedRemainingAmount,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isExceeded ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: percentSpent / 100,
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              color: isExceeded
                  ? Colors.red
                  : Theme.of(context).colorScheme.primary,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${percentSpent.toStringAsFixed(1)}% used',
                style: TextStyle(
                  fontSize: 12,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddBudgetDialog(BuildContext context) {
    final CategoryController categoryController =
        Get.find<CategoryController>();
    final BudgetController budgetController = Get.find<BudgetController>();

    final amountController = TextEditingController();
    String selectedCategoryId = '';
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime(
      DateTime.now().year,
      DateTime.now().month + 1,
      0,
    ); // Last day of current month

    if (categoryController.categories.isNotEmpty) {
      selectedCategoryId = categoryController.categories.first.id;
    }

    final formKey = GlobalKey<FormState>();

    // Use a specific width constraint for the dialog
    final dialogWidth = MediaQuery.of(context).size.width * 0.9 < 400
        ? MediaQuery.of(context).size.width * 0.9
        : 400.0;

    Get.dialog(
      Dialog(
        // Set a fixed width for the dialog to prevent infinite width constraints
        child: Container(
          width: dialogWidth,
          constraints: BoxConstraints(maxWidth: dialogWidth),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add Budget',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Category dropdown
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      value: selectedCategoryId.isNotEmpty
                          ? selectedCategoryId
                          : null,
                      items: categoryController.categories.map((category) {
                        return DropdownMenuItem(
                          value: category.id,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(category.icon,
                                  color: category.color, size: 20),
                              const SizedBox(width: 8),
                              Flexible(
                                  child: Text(category.name,
                                      overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          selectedCategoryId = value;
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a category';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Amount field
                    TextFormField(
                      controller: amountController,
                      decoration: const InputDecoration(
                        labelText: 'Budget Amount',
                        hintText: 'Enter amount',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: false),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an amount';
                        }
                        if (!CurrencyUtils.isValidAmount(value)) {
                          return 'Please enter a valid amount';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Date range - using Column instead of Row with Expanded
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date Range',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildDatePicker(
                          context,
                          label: 'Start Date',
                          selectedDate: startDate,
                          onDateSelected: (date) {
                            startDate = date;
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildDatePicker(
                          context,
                          label: 'End Date',
                          selectedDate: endDate,
                          onDateSelected: (date) {
                            endDate = date;
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Action buttons in a ButtonBar
                    OverflowBar(
                      alignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Get.back(),
                          child: const Text('CANCEL'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              final budget = Budget(
                                categoryId: selectedCategoryId,
                                amount: CurrencyUtils.parseAmount(
                                    amountController.text),
                                startDate: startDate,
                                endDate: endDate,
                                spentAmount: 0,
                              );

                              budgetController.addBudget(budget);
                              Get.back();
                            }
                          },
                          child: const Text('SAVE'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker(
    BuildContext context, {
    required String label,
    required DateTime selectedDate,
    required Function(DateTime) onDateSelected,
  }) {
    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );

        if (picked != null && picked != selectedDate) {
          onDateSelected(picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        child: Text(
          DateFormat('MM/dd/yyyy').format(selectedDate),
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }

  void _confirmDeleteBudget(
    BuildContext context,
    BudgetController budgetController,
    Budget budget,
  ) {
    final CategoryController categoryController =
        Get.find<CategoryController>();
    final category = categoryController.getCategoryById(budget.categoryId);

    Get.dialog(
      AlertDialog(
        title: const Text('Delete Budget'),
        content: Text(
            'Are you sure you want to delete the budget for "${category?.name ?? 'Unknown'}"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              budgetController.deleteBudget(budget.id!);
              Get.back();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }
}
