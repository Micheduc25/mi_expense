import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:collection/collection.dart';
import '../controllers/transaction_controller.dart';
import '../controllers/category_controller.dart';
import '../models/transaction.dart';
import '../utils/currency_utils.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  final TransactionController _transactionController =
      Get.find<TransactionController>();
  final CategoryController _categoryController = Get.find<CategoryController>();

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String _timeRange = 'Month';

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Trends'),
            Tab(text: 'Insights'),
          ],
        ),
      ),
      body: Obx(() {
        if (_transactionController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_transactionController.transactions.isEmpty) {
          return const Center(
            child: Text(
                'No transactions to analyze. Add some transactions first!'),
          );
        }

        // Filter transactions by selected date range
        final filteredTransactions = _transactionController.transactions
            .where((t) =>
                t.date.isAfter(_startDate.subtract(const Duration(days: 1))) &&
                t.date.isBefore(_endDate.add(const Duration(days: 1))))
            .toList();

        if (filteredTransactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.analytics_outlined,
                    size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No transactions in the selected period',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _timeRange = 'All Time';
                      _startDate = DateTime(2000);
                      _endDate = DateTime.now();
                    });
                  },
                  child: const Text('View All Time'),
                ),
              ],
            ),
          );
        }

        // Calculate totals
        final totalExpenses = filteredTransactions
            .where((t) => t.isExpense)
            .fold(0.0, (sum, t) => sum + t.amount);

        final totalIncome = filteredTransactions
            .where((t) => t.isIncome)
            .fold(0.0, (sum, t) => sum + t.amount);

        // Daily averages
        final daysInPeriod = _endDate.difference(_startDate).inDays + 1;
        final dailyAvgExpense = totalExpenses / daysInPeriod;
        final dailyAvgIncome = totalIncome / daysInPeriod;

        // Monthly data for trends
        final monthlyData = _getMonthlyData(filteredTransactions);

        // Category expenses
        final Map<String, double> categoryExpenses = {};
        for (final transaction
            in filteredTransactions.where((t) => t.isExpense)) {
          if (categoryExpenses.containsKey(transaction.category)) {
            categoryExpenses[transaction.category] =
                categoryExpenses[transaction.category]! + transaction.amount;
          } else {
            categoryExpenses[transaction.category] = transaction.amount;
          }
        }

        // Sort categories by amount
        final sortedCategories = categoryExpenses.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        // Top spending categories
        final topCategories = sortedCategories.take(3).toList();

        // Savings rate
        final savingsRate = totalIncome > 0
            ? ((totalIncome - totalExpenses) / totalIncome * 100)
            : 0.0;

        // Payment method breakdown
        final paymentMethodData = _getPaymentMethodData(filteredTransactions);

        // Weekly data for detailed trends
        final weeklyData = _getWeeklyData(filteredTransactions);

        return TabBarView(
          controller: _tabController,
          children: [
            // OVERVIEW TAB
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time range selector
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select Time Range',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildTimeRangeChip('Week', 7),
                                _buildTimeRangeChip('Month', 30),
                                _buildTimeRangeChip('3 Months', 90),
                                _buildTimeRangeChip('6 Months', 180),
                                _buildTimeRangeChip('Year', 365),
                                _buildTimeRangeChip('All Time', -1),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('MMM d, yyyy').format(_startDate),
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.7),
                                ),
                              ),
                              const Icon(Icons.arrow_forward, size: 16),
                              Text(
                                DateFormat('MMM d, yyyy').format(_endDate),
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Financial Summary Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Financial Summary',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildSummaryColumn(
                                  label: 'Income',
                                  amount: totalIncome,
                                  icon: Icons.arrow_upward,
                                  iconColor: Colors.green,
                                ),
                              ),
                              Expanded(
                                child: _buildSummaryColumn(
                                  label: 'Expenses',
                                  amount: totalExpenses,
                                  icon: Icons.arrow_downward,
                                  iconColor: Colors.red,
                                ),
                              ),
                              Expanded(
                                child: _buildSummaryColumn(
                                  label: 'Balance',
                                  amount: totalIncome - totalExpenses,
                                  icon: Icons.account_balance_wallet,
                                  iconColor:
                                      Theme.of(context).colorScheme.primary,
                                  isBalance: true,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 32),
                          Row(
                            children: [
                              Expanded(
                                child: _buildSummaryColumn(
                                  label: 'Daily Avg Exp',
                                  amount: dailyAvgExpense,
                                  icon: Icons.today,
                                  iconColor: Colors.orange,
                                ),
                              ),
                              Expanded(
                                child: _buildSavingsRateSummary(
                                    savingsRate: savingsRate, context: context),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Top Spending Categories
                  if (topCategories.isNotEmpty) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Top Spending Categories',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...topCategories.map((entry) {
                              final category = _categoryController
                                  .getCategoryById(entry.key);
                              final percentage =
                                  (entry.value / totalExpenses) * 100;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color:
                                            category?.color.withOpacity(0.2) ??
                                                Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                    .withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        category?.icon ?? Icons.category,
                                        color: category?.color ??
                                            Theme.of(context)
                                                .colorScheme
                                                .primary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            category?.name ?? 'Unknown',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          LinearProgressIndicator(
                                            value: entry.value /
                                                (topCategories.first.value),
                                            backgroundColor:
                                                Colors.grey.withOpacity(0.2),
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              category?.color ??
                                                  Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          CurrencyUtils.formatCurrency(
                                              entry.value),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '${percentage.toStringAsFixed(1)}%',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Expense breakdown by category
                  if (categoryExpenses.isNotEmpty) ...[
                    const Text(
                      'Expense Breakdown',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 300,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: PieChart(
                            PieChartData(
                              sections:
                                  _createPieChartSections(categoryExpenses),
                              centerSpaceRadius: 40,
                              sectionsSpace: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildPaymentMethodBreakdown(paymentMethodData, context),
                  ],
                ],
              ),
            ),

            // TRENDS TAB
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Monthly Spending Trends',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 250,
                            child:
                                _buildMonthlyTrendChart(monthlyData, context),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Weekly Spending Patterns',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 250,
                            child: _buildWeeklyTrendChart(weeklyData, context),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (monthlyData.length > 1) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Month-to-Month Comparison',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildMonthlyComparisonView(monthlyData, context),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // INSIGHTS TAB
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.lightbulb,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Financial Insights',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ..._generateInsights(
                            filteredTransactions,
                            totalIncome,
                            totalExpenses,
                            savingsRate,
                            sortedCategories,
                            context,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Spending Heat Map',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildSpendingHeatMap(filteredTransactions, context),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildSavingsRateSummary({
    required double savingsRate,
    required BuildContext context,
  }) {
    Color savingsColor = Colors.red;
    if (savingsRate >= 20) {
      savingsColor = Colors.green;
    } else if (savingsRate >= 10) {
      savingsColor = Colors.orange;
    }

    return Column(
      children: [
        Icon(Icons.savings, color: savingsColor),
        const SizedBox(height: 8),
        const Text(
          'Savings Rate',
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${savingsRate.toStringAsFixed(1)}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: savingsColor,
              ),
            ),
            Icon(
              savingsRate >= 15 ? Icons.thumb_up : Icons.thumb_down,
              size: 14,
              color: savingsColor,
            ),
          ],
        ),
      ],
    );
  }

  Map<String, Map<String, double>> _getMonthlyData(
      List<Transaction> transactions) {
    final Map<String, Map<String, double>> monthlyData = {};

    for (final transaction in transactions) {
      final monthYear = DateFormat('yyyy-MM').format(transaction.date);

      if (!monthlyData.containsKey(monthYear)) {
        monthlyData[monthYear] = {
          'income': 0.0,
          'expense': 0.0,
        };
      }

      if (transaction.isIncome) {
        monthlyData[monthYear]!['income'] =
            monthlyData[monthYear]!['income']! + transaction.amount;
      } else {
        monthlyData[monthYear]!['expense'] =
            monthlyData[monthYear]!['expense']! + transaction.amount;
      }
    }

    // Sort by date
    final sortedEntries = monthlyData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Map.fromEntries(sortedEntries);
  }

  Map<PaymentMethod, double> _getPaymentMethodData(
      List<Transaction> transactions) {
    final Map<PaymentMethod, double> paymentData = {};

    for (final transaction in transactions.where((t) => t.isExpense)) {
      if (paymentData.containsKey(transaction.paymentMethod)) {
        paymentData[transaction.paymentMethod] =
            paymentData[transaction.paymentMethod]! + transaction.amount;
      } else {
        paymentData[transaction.paymentMethod] = transaction.amount;
      }
    }

    return paymentData;
  }

  Map<String, double> _getWeeklyData(List<Transaction> transactions) {
    final Map<String, double> weeklyData = {};

    for (final transaction in transactions.where((t) => t.isExpense)) {
      // Get the week number
      final weekNumber = (transaction.date.day - 1) ~/ 7 + 1;
      final monthYear = DateFormat('yyyy-MM').format(transaction.date);
      final weekKey = '$monthYear-W$weekNumber';

      if (weeklyData.containsKey(weekKey)) {
        weeklyData[weekKey] = weeklyData[weekKey]! + transaction.amount;
      } else {
        weeklyData[weekKey] = transaction.amount;
      }
    }

    // Sort by date
    final sortedEntries = weeklyData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Map.fromEntries(sortedEntries);
  }

  Widget _buildMonthlyTrendChart(
      Map<String, Map<String, double>> monthlyData, BuildContext context) {
    if (monthlyData.isEmpty) {
      return const Center(child: Text('Not enough data to show trends'));
    }

    final List<FlSpot> expenseSpots = [];
    final List<FlSpot> incomeSpots = [];
    final List<String> months = [];

    int index = 0;
    monthlyData.forEach((month, data) {
      expenseSpots.add(FlSpot(index.toDouble(), data['expense'] ?? 0));
      incomeSpots.add(FlSpot(index.toDouble(), data['income'] ?? 0));
      months.add(DateFormat('MMM yy').format(DateTime.parse('$month-01')));
      index++;
    });

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.3),
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.3),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  CurrencyUtils.formatCurrency(value, showSymbol: false),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value >= 0 && value < months.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      months[value.toInt()],
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 10,
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        minX: -0.5,
        maxX: months.length - 0.5,
        minY: 0,
        lineBarsData: [
          LineChartBarData(
            spots: expenseSpots,
            isCurved: true,
            color: Colors.red,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.red.withOpacity(0.1),
            ),
          ),
          LineChartBarData(
            spots: incomeSpots,
            isCurved: true,
            color: Colors.green,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.green.withOpacity(0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((spot) {
                final String label = spot.barIndex == 0 ? 'Expense' : 'Income';
                return LineTooltipItem(
                  '$label: ${CurrencyUtils.formatCurrency(spot.y)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyTrendChart(
      Map<String, double> weeklyData, BuildContext context) {
    if (weeklyData.isEmpty || weeklyData.length < 2) {
      return const Center(child: Text('Not enough data to show weekly trends'));
    }

    final List<FlSpot> spots = [];
    final List<String> weeks = [];

    int index = 0;
    weeklyData.forEach((week, amount) {
      spots.add(FlSpot(index.toDouble(), amount));

      // Format the week label
      final parts = week.split('-W');
      final monthYear = parts[0];
      final weekNum = parts[1];
      weeks.add(
          'W$weekNum ${DateFormat('MMM').format(DateTime.parse('$monthYear-01'))}');

      index++;
    });

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.3),
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.3),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  CurrencyUtils.formatCurrency(value, showSymbol: false),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value.toInt() % 2 == 0 &&
                    value >= 0 &&
                    value < weeks.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      weeks[value.toInt()],
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 10,
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        minX: -0.5,
        maxX: weeks.length - 0.5,
        minY: 0,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Theme.of(context).colorScheme.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  '${weeks[spot.x.toInt()]}: ${CurrencyUtils.formatCurrency(spot.y)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMonthlyComparisonView(
      Map<String, Map<String, double>> monthlyData, BuildContext context) {
    if (monthlyData.length < 2) {
      return const Center(
          child: Text('Need at least 2 months of data for comparison'));
    }

    final entries = monthlyData.entries.toList();
    final currentMonth = entries.last;
    final previousMonth = entries[entries.length - 2];

    final currentMonthExpense = currentMonth.value['expense'] ?? 0.0;
    final previousMonthExpense = previousMonth.value['expense'] ?? 0.0;

    final percentChange = previousMonthExpense > 0
        ? ((currentMonthExpense - previousMonthExpense) /
            previousMonthExpense *
            100)
        : 0.0;

    final isIncrease = percentChange > 0;
    final changeText = isIncrease
        ? 'increased by ${percentChange.abs().toStringAsFixed(1)}%'
        : 'decreased by ${percentChange.abs().toStringAsFixed(1)}%';

    final currentMonthName = DateFormat('MMMM yyyy')
        .format(DateTime.parse('${currentMonth.key}-01'));
    final previousMonthName = DateFormat('MMMM yyyy')
        .format(DateTime.parse('${previousMonth.key}-01'));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style,
              children: [
                TextSpan(
                  text: 'Your spending in ',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                TextSpan(
                  text: currentMonthName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                TextSpan(
                  text: ' has ',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                TextSpan(
                  text: changeText,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isIncrease ? Colors.red : Colors.green,
                  ),
                ),
                TextSpan(
                  text: ' compared to ',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                TextSpan(
                  text: previousMonthName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMonthSummaryCard(
                  month: previousMonthName,
                  expense: previousMonthExpense,
                  income: previousMonth.value['income'] ?? 0.0,
                  context: context,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMonthSummaryCard(
                  month: currentMonthName,
                  expense: currentMonthExpense,
                  income: currentMonth.value['income'] ?? 0.0,
                  context: context,
                  isHighlighted: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSummaryCard({
    required String month,
    required double expense,
    required double income,
    required BuildContext context,
    bool isHighlighted = false,
  }) {
    final balance = income - expense;
    final savingsRate = income > 0 ? (balance / income * 100) : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isHighlighted
            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: isHighlighted
            ? Border.all(color: Theme.of(context).colorScheme.primary)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            month,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isHighlighted
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          _buildMonthDataRow(
            label: 'Income',
            value: income,
            icon: Icons.arrow_upward,
            color: Colors.green,
          ),
          const SizedBox(height: 8),
          _buildMonthDataRow(
            label: 'Expenses',
            value: expense,
            icon: Icons.arrow_downward,
            color: Colors.red,
          ),
          const Divider(height: 16),
          _buildMonthDataRow(
            label: 'Balance',
            value: balance,
            icon: Icons.account_balance_wallet,
            color: balance >= 0 ? Colors.green : Colors.red,
          ),
          const SizedBox(height: 8),
          _buildMonthDataRow(
            label: 'Savings Rate',
            value: savingsRate,
            icon: Icons.savings,
            color: savingsRate >= 20
                ? Colors.green
                : (savingsRate >= 10 ? Colors.orange : Colors.red),
            isPercentage: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMonthDataRow({
    required String label,
    required double value,
    required IconData icon,
    required Color color,
    bool isPercentage = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        Text(
          isPercentage
              ? '${value.toStringAsFixed(1)}%'
              : CurrencyUtils.formatCurrency(value),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodBreakdown(
      Map<PaymentMethod, double> paymentData, BuildContext context) {
    if (paymentData.isEmpty) {
      return const SizedBox();
    }

    final totalAmount =
        paymentData.values.fold(0.0, (sum, value) => sum + value);

    // Map to get icons and labels for payment methods
    final methodIcons = {
      PaymentMethod.cash: Icons.money,
      PaymentMethod.card: Icons.credit_card,
      PaymentMethod.mobilePayment: Icons.phone_android,
      PaymentMethod.bankTransfer: Icons.account_balance,
      PaymentMethod.other: Icons.more_horiz,
    };

    final methodLabels = {
      PaymentMethod.cash: 'Cash',
      PaymentMethod.card: 'Card',
      PaymentMethod.mobilePayment: 'Mobile Payment',
      PaymentMethod.bankTransfer: 'Bank Transfer',
      PaymentMethod.other: 'Other',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Methods',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            ...paymentData.entries.map((entry) {
              final percentage = (entry.value / totalAmount) * 100;
              final color = _getPaymentMethodColor(entry.key, context);

              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        methodIcons[entry.key] ?? Icons.payment,
                        color: color,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            methodLabels[entry.key] ?? 'Unknown',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: percentage / 100,
                            backgroundColor: Colors.grey.withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          CurrencyUtils.formatCurrency(entry.value),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Color _getPaymentMethodColor(PaymentMethod method, BuildContext context) {
    switch (method) {
      case PaymentMethod.cash:
        return Colors.green;
      case PaymentMethod.card:
        return Colors.blue;
      case PaymentMethod.mobilePayment:
        return Colors.orange;
      case PaymentMethod.bankTransfer:
        return Colors.purple;
      case PaymentMethod.other:
        return Colors.grey;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  List<Widget> _generateInsights(
    List<Transaction> transactions,
    double totalIncome,
    double totalExpenses,
    double savingsRate,
    List<MapEntry<String, double>> sortedCategories,
    BuildContext context,
  ) {
    final List<Widget> insights = [];

    // Insight 1: Savings Rate
    if (totalIncome > 0) {
      String savingsMessage;
      IconData savingsIcon;
      Color savingsColor;

      if (savingsRate >= 20) {
        savingsMessage =
            'Great job! Your savings rate of ${savingsRate.toStringAsFixed(1)}% is excellent. Financial experts recommend saving at least 20% of your income.';
        savingsIcon = Icons.sentiment_very_satisfied;
        savingsColor = Colors.green;
      } else if (savingsRate >= 10) {
        savingsMessage =
            'You\'re saving ${savingsRate.toStringAsFixed(1)}% of your income. Try to increase it to at least 20% for better financial security.';
        savingsIcon = Icons.sentiment_satisfied;
        savingsColor = Colors.orange;
      } else if (savingsRate > 0) {
        savingsMessage =
            'Your savings rate is ${savingsRate.toStringAsFixed(1)}%, which is below recommended levels. Consider reducing expenses to save more.';
        savingsIcon = Icons.sentiment_dissatisfied;
        savingsColor = Colors.red;
      } else {
        savingsMessage =
            'You\'re spending more than you earn. Review your budget to reduce expenses and avoid debt.';
        savingsIcon = Icons.warning;
        savingsColor = Colors.red;
      }

      insights.add(_buildInsightItem(
        message: savingsMessage,
        icon: savingsIcon,
        color: savingsColor,
      ));
    }

    // Insight 2: Top category spending
    if (sortedCategories.isNotEmpty) {
      final topCategory = sortedCategories.first;
      final categoryName =
          _categoryController.getCategoryById(topCategory.key)?.name ??
              'Unknown';
      final percentage = (topCategory.value / totalExpenses) * 100;

      if (percentage > 30) {
        insights.add(_buildInsightItem(
          message:
              'You spent ${percentage.toStringAsFixed(1)}% of your expenses on $categoryName. Consider if you can reduce this category to balance your spending better.',
          icon: Icons.priority_high,
          color: Colors.orange,
        ));
      }
    }

    // Insight 3: Spending trend
    if (transactions.length > 10) {
      // Group by day to analyze recent spending trends
      final Map<String, double> dailySpending = {};
      final recentTransactions = transactions.where((t) => t.isExpense).toList()
        ..sort((a, b) => b.date.compareTo(a.date)); // Sort newest first

      for (final transaction in recentTransactions.take(14)) {
        // Last 14 days
        final dayKey = DateFormat('yyyy-MM-dd').format(transaction.date);
        dailySpending[dayKey] =
            (dailySpending[dayKey] ?? 0) + transaction.amount;
      }

      if (dailySpending.length >= 7) {
        final last7DaysKeys = dailySpending.keys.take(7).toList();
        final last7DaysAmount = last7DaysKeys
            .map((day) => dailySpending[day] ?? 0)
            .fold(0.0, (sum, amount) => sum + amount);

        final previous7DaysAmount = dailySpending.entries
            .where((entry) => !last7DaysKeys.contains(entry.key))
            .map((entry) => entry.value)
            .fold(0.0, (sum, amount) => sum + amount);

        if (previous7DaysAmount > 0) {
          final percentChange =
              ((last7DaysAmount - previous7DaysAmount) / previous7DaysAmount) *
                  100;
          if (percentChange > 20) {
            insights.add(_buildInsightItem(
              message:
                  'Your spending has increased by ${percentChange.toStringAsFixed(1)}% in the last 7 days compared to the previous week. Keep an eye on your expenses.',
              icon: Icons.trending_up,
              color: Colors.red,
            ));
          } else if (percentChange < -20) {
            insights.add(_buildInsightItem(
              message:
                  'Great! Your spending has decreased by ${percentChange.abs().toStringAsFixed(1)}% in the last 7 days compared to the previous week.',
              icon: Icons.trending_down,
              color: Colors.green,
            ));
          }
        }
      }
    }

    // If no insights were generated, add a default one
    if (insights.isEmpty) {
      insights.add(_buildInsightItem(
        message:
            'Continue tracking your expenses regularly to get more personalized financial insights.',
        icon: Icons.info,
        color: Theme.of(context).colorScheme.primary,
      ));
    }

    return insights;
  }

  Widget _buildInsightItem({
    required String message,
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingHeatMap(
      List<Transaction> transactions, BuildContext context) {
    if (transactions.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(child: Text('Not enough data for a spending heat map')),
      );
    }

    // Group transactions by day of week and hour
    final Map<int, Map<int, double>> heatMapData = {};

    // Initialize the map with all days and hours
    for (int day = 0; day < 7; day++) {
      heatMapData[day] = {};
      for (int hour = 0; hour < 24; hour += 3) {
        // Group by 3-hour blocks
        heatMapData[day]![hour] = 0.0;
      }
    }

    // Fill the map with transaction data
    for (final transaction in transactions.where((t) => t.isExpense)) {
      final dayOfWeek =
          transaction.date.weekday % 7; // 0 = Sunday, 6 = Saturday
      final hour = (transaction.date.hour ~/ 3) * 3; // Round to 3-hour blocks

      heatMapData[dayOfWeek]![hour] =
          (heatMapData[dayOfWeek]![hour] ?? 0) + transaction.amount;
    }

    // Find the maximum amount for color scaling
    double maxAmount = 0.0;
    for (final dayMap in heatMapData.values) {
      for (final amount in dayMap.values) {
        if (amount > maxAmount) maxAmount = amount;
      }
    }

    // Day of week labels
    final dayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    // Build the heatmap grid
    return Column(
      children: [
        SizedBox(
          height: 250,
          child: Row(
            children: [
              // Day labels
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: dayLabels
                    .map((day) => SizedBox(
                          height: 30,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text(
                              day,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.7),
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),

              // Heat map cells
              Expanded(
                child: Column(
                  children: [
                    for (int day = 0; day < 7; day++)
                      Row(
                        children: [
                          for (int hour = 0; hour < 24; hour += 3)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(2.0),
                                child: Tooltip(
                                  message:
                                      '${dayLabels[day]} $hour:00-${hour + 3}:00: ${CurrencyUtils.formatCurrency(heatMapData[day]![hour] ?? 0)}',
                                  child: Container(
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: _getHeatMapColor(
                                        heatMapData[day]![hour] ?? 0,
                                        maxAmount,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Hour labels
        Padding(
          padding: const EdgeInsets.only(left: 40.0, top: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (int hour = 0; hour < 24; hour += 3)
                Text(
                  hour.toString(),
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.5),
                  ),
                ),
            ],
          ),
        ),

        // Legend
        Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 4),
              const Text('Low', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 16),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 4),
              const Text('Medium', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 16),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 4),
              const Text('High', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  Color _getHeatMapColor(double amount, double maxAmount) {
    if (amount <= 0) return Colors.green.withOpacity(0.1);

    final ratio = amount / maxAmount;
    if (ratio < 0.3) {
      return Colors.green.withOpacity(0.1 + ratio);
    } else if (ratio < 0.7) {
      return Colors.orange.withOpacity(ratio);
    } else {
      return Colors.red.withOpacity(ratio);
    }
  }

  Widget _buildTimeRangeChip(String label, int days) {
    final isSelected = _timeRange == label;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _timeRange = label;
              _endDate = DateTime.now();

              if (days == -1) {
                // All time - use a very old date
                _startDate = DateTime(2000);
              } else {
                _startDate = DateTime.now().subtract(Duration(days: days));
              }
            });
          }
        },
      ),
    );
  }

  Widget _buildSummaryColumn({
    required String label,
    required double amount,
    required IconData icon,
    required Color iconColor,
    bool isBalance = false,
  }) {
    return Column(
      children: [
        Icon(icon, color: iconColor),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          CurrencyUtils.formatCurrency(amount),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isBalance ? (amount >= 0 ? Colors.green : Colors.red) : null,
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> _createPieChartSections(
      Map<String, double> categoryExpenses) {
    final List<PieChartSectionData> sections = [];
    final totalExpenses =
        categoryExpenses.values.fold(0.0, (sum, amount) => sum + amount);

    categoryExpenses.forEach((categoryId, amount) {
      final category = _categoryController.getCategoryById(categoryId);
      final percentage = (amount / totalExpenses) * 100;

      sections.add(
        PieChartSectionData(
          value: amount,
          title: '${percentage.toStringAsFixed(1)}%',
          color: category?.color ?? Theme.of(context).colorScheme.primary,
          radius: 100,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      );
    });

    return sections;
  }
}
