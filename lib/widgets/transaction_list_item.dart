import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/transaction.dart';
import '../controllers/category_controller.dart';
import '../controllers/transaction_controller.dart';
import '../controllers/budget_controller.dart';
import '../utils/currency_utils.dart';
import '../routes/app_routes.dart';

class TransactionListItem extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onTap;

  const TransactionListItem({
    super.key,
    required this.transaction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final categoryController = Get.find<CategoryController>();
    final transactionController = Get.find<TransactionController>();
    final budgetController = Get.find<BudgetController>();
    final category = categoryController.getCategoryById(transaction.category);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Category icon
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: category?.color.withOpacity(0.2) ??
                      Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(
                  category?.icon ?? Icons.receipt,
                  color:
                      category?.color ?? Theme.of(context).colorScheme.primary,
                ),
              ),

              const SizedBox(width: 16),

              // Transaction details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category?.name ?? 'Other',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (transaction.description != null &&
                        transaction.description!.isNotEmpty)
                      Text(
                        transaction.description!,
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7),
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    Text(
                      transaction.formattedDate,
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Amount
              Text(
                transaction.formattedAmount,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: transaction.isIncome ? Colors.green : Colors.red,
                ),
              ),

              // Quick action buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.edit,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    onPressed: () {
                      // Navigate to edit transaction screen
                      Get.toNamed(AppRoutes.EDIT_TRANSACTION,
                          arguments: transaction);
                    },
                    tooltip: 'Edit',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.only(left: 8.0, right: 4.0),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete,
                      color: Colors.red,
                      size: 20,
                    ),
                    onPressed: () async {
                      final confirmed = await Get.dialog<bool>(
                        AlertDialog(
                          title: const Text('Confirm Delete'),
                          content: const Text(
                              'Are you sure you want to delete this transaction?'),
                          actions: [
                            TextButton(
                              onPressed: () => Get.back(result: false),
                              child: const Text('CANCEL'),
                            ),
                            TextButton(
                              onPressed: () => Get.back(result: true),
                              child: const Text('DELETE'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        await transactionController
                            .deleteTransaction(transaction.id!);
                        if (transaction.isExpense) {
                          await budgetController.updateBudgetSpentAmount(
                            transaction.category,
                            -transaction.amount,
                          );
                        }
                        // Navigate to home screen after deletion
                        Get.offAllNamed(AppRoutes.HOME);
                      }
                    },
                    tooltip: 'Delete',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.only(left: 4.0, right: 4.0),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
