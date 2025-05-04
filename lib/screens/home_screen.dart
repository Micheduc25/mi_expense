import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/transaction_controller.dart';
import '../models/transaction.dart';
import '../routes/app_routes.dart';
import '../utils/currency_utils.dart';
import '../widgets/transaction_list_item.dart';
import '../widgets/summary_card.dart';
import '../widgets/app_icon.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final TransactionController _transactionController =
      Get.find<TransactionController>();

  // Animation controller for the FAB
  late AnimationController _animationController;
  final Duration _duration = const Duration(milliseconds: 300);
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: _duration,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void activate() {
    super.activate();
    // This is called when the screen comes back into view after being inactive
    // Perfect place to refresh data when returning from add transaction screen
    _transactionController.fetchTransactions();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Expense'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Get.toNamed(AppRoutes.settings),
          ),
        ],
      ),
      body: Obx(() {
        if (_transactionController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () => _transactionController.fetchTransactions(),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Balance Summary
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const Text(
                                'Current Balance',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Obx(() {
                                return Text(
                                  CurrencyUtils.formatCurrency(
                                      _transactionController.balance.value),
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        _transactionController.balance.value >=
                                                0
                                            ? Colors.green
                                            : Colors.red,
                                  ),
                                );
                              }),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  SummaryCard(
                                    title: 'Income',
                                    amount: _transactionController
                                        .totalIncome.value,
                                    icon: Icons.arrow_upward,
                                    iconColor: Colors.green,
                                  ),
                                  SummaryCard(
                                    title: 'Expenses',
                                    amount: _transactionController
                                        .totalExpenses.value,
                                    icon: Icons.arrow_downward,
                                    iconColor: Colors.red,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildActionButton(
                            icon: Icons.category,
                            label: 'Categories',
                            onTap: () => Get.toNamed(AppRoutes.categories),
                          ),
                          _buildActionButton(
                            icon: Icons.account_balance_wallet,
                            label: 'Budget',
                            onTap: () => Get.toNamed(AppRoutes.budget),
                          ),
                          _buildActionButton(
                            icon: Icons.bar_chart,
                            label: 'Analytics',
                            onTap: () => Get.toNamed(AppRoutes.analytics),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Transaction filter
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recent Transactions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          DropdownButton<TransactionType?>(
                            value: null,
                            hint: const Text('Filter'),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('All'),
                              ),
                              ...TransactionType.values
                                  .map((type) => DropdownMenuItem(
                                        value: type,
                                        child: Text(type.name.capitalize!),
                                      )),
                            ],
                            onChanged: (type) {
                              _transactionController
                                  .filterTransactionsByType(type);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Transaction list
              Obx(() {
                if (_transactionController.filteredTransactions.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Text(
                          'No transactions found. Add your first one!',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final transaction =
                          _transactionController.filteredTransactions[index];
                      return TransactionListItem(
                        transaction: transaction,
                        onTap: () => Get.toNamed(
                          AppRoutes.transactionDetail,
                          arguments: transaction,
                        ),
                      );
                    },
                    childCount:
                        _transactionController.filteredTransactions.length,
                  ),
                );
              }),

              // Bottom padding
              const SliverToBoxAdapter(
                child: SizedBox(height: 80),
              ),
            ],
          ),
        );
      }),
      floatingActionButton: _buildAnimatedFAB(),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        elevation: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: () {}, // Already on home
            ),
            IconButton(
              icon: const Icon(Icons.category),
              onPressed: () => Get.toNamed(AppRoutes.categories),
            ),
            const SizedBox(width: 20),
            const SizedBox(width: 20),
            IconButton(
              icon: const Icon(Icons.bar_chart),
              onPressed: () => Get.toNamed(AppRoutes.analytics),
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => Get.toNamed(AppRoutes.settings),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildAnimatedFAB() {
    return Transform.translate(
      offset: Offset(-Get.width * 0.09, -50),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Voice command mini FAB - shows when expanded
          ScaleTransition(
            scale: CurvedAnimation(
              parent: _animationController,
              curve: Curves.easeOut,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Voice label
                FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _animationController,
                    curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Get.theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Voice',
                      style: TextStyle(
                        color: Get.theme.colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                // Voice button
                FloatingActionButton.small(
                  heroTag: 'voice_button',
                  onPressed: () {
                    _toggleExpanded();
                    Get.toNamed(AppRoutes.voiceCommand);
                  },
                  tooltip: 'Add with voice',
                  backgroundColor: Get.theme.colorScheme.secondaryContainer,
                  foregroundColor: Get.theme.colorScheme.onSecondaryContainer,
                  child: const Icon(Icons.mic),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Manual entry mini FAB - shows when expanded
          ScaleTransition(
            scale: CurvedAnimation(
              parent: _animationController,
              curve: Curves.easeOut,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Manual label
                FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _animationController,
                    curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Get.theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Manual',
                      style: TextStyle(
                        color: Get.theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                // Manual button
                FloatingActionButton.small(
                  heroTag: 'manual_button',
                  onPressed: () {
                    _toggleExpanded();
                    Get.toNamed(AppRoutes.addTransaction);
                  },
                  tooltip: 'Add manually',
                  backgroundColor: Get.theme.colorScheme.primaryContainer,
                  foregroundColor: Get.theme.colorScheme.onPrimaryContainer,
                  child: const Icon(Icons.edit),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Main FAB - always visible
          FloatingActionButton(
            onPressed: _toggleExpanded,
            tooltip: 'Add Transaction',
            elevation: 4,
            backgroundColor: Get.theme.colorScheme.primary,
            foregroundColor: Get.theme.colorScheme.onPrimary,
            child: AnimatedIcon(
              icon: AnimatedIcons.menu_close,
              progress: _animationController,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Get.theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 28,
                color: Get.theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Get.theme.colorScheme.onBackground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
