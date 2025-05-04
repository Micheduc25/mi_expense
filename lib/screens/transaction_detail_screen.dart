import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../controllers/transaction_controller.dart';
import '../controllers/category_controller.dart';
import '../controllers/budget_controller.dart';
import '../models/transaction.dart';
import '../routes/app_routes.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class TransactionDetailScreen extends StatelessWidget {
  const TransactionDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Transaction transaction = Get.arguments;
    final TransactionController transactionController =
        Get.find<TransactionController>();
    final CategoryController categoryController =
        Get.find<CategoryController>();
    final BudgetController budgetController = Get.find<BudgetController>();

    final category = categoryController.getCategoryById(transaction.category);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Navigate to edit transaction screen
              Get.toNamed(AppRoutes.EDIT_TRANSACTION, arguments: transaction);
            },
          ),
        ],
      ),
      body: Slidable(
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (context) async {
                await transactionController.deleteTransaction(transaction.id!);
                if (transaction.isExpense) {
                  await budgetController.updateBudgetSpentAmount(
                    transaction.category,
                    -transaction
                        .amount, // Subtract the amount since we're deleting
                  );
                }
                // Navigate to home screen instead of just going back one screen
                Get.offAllNamed(AppRoutes.HOME);
              },
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Delete',
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with amount and type
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: transaction.isIncome
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Column(
                  children: [
                    Text(
                      transaction.isIncome ? 'Income' : 'Expense',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: transaction.isIncome ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      transaction.formattedAmount,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: transaction.isIncome ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Transaction details
              _buildDetailItem(
                context,
                icon: Icons.category,
                title: 'Category',
                value: category?.name ?? 'Unknown',
                iconColor: category?.color,
              ),

              _buildDetailItem(
                context,
                icon: Icons.calendar_today,
                title: 'Date',
                value:
                    DateFormat('EEEE, MMMM d, yyyy').format(transaction.date),
              ),

              if (transaction.description != null &&
                  transaction.description!.isNotEmpty)
                _buildDetailItem(
                  context,
                  icon: Icons.description,
                  title: 'Description',
                  value: transaction.description!,
                ),

              _buildDetailItem(
                context,
                icon: Icons.payment,
                title: 'Payment Method',
                value: transaction.paymentMethod.name.capitalize!,
              ),

              // Receipt image (if available)
              if (transaction.receiptImagePath != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Receipt',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.0),
                          image: DecorationImage(
                            image:
                                FileImage(File(transaction.receiptImagePath!)),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 32),

              // Delete button - Updated to navigate to home page
              ElevatedButton.icon(
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
                        -transaction
                            .amount, // Subtract the amount since we're deleting
                      );
                    }
                    // Navigate to home screen instead of just going back one screen
                    Get.offAllNamed(AppRoutes.HOME);
                  }
                },
                icon: const Icon(Icons.delete, color: Colors.white),
                label: const Text('Delete Transaction'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    Color? iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: (iconColor ?? Theme.of(context).colorScheme.primary)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(
              icon,
              color: iconColor ?? Theme.of(context).colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
