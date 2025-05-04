import 'package:sqflite/sqflite.dart' as sql;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import '../models/transaction.dart';
import '../models/category.dart';
import '../models/budget.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static sql.Database? _database;

  Future<sql.Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<sql.Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'mi_expense.db');
    return await sql.openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );
  }

  Future<void> _createDatabase(sql.Database db, int version) async {
    // Create transactions table
    await db.execute('''
      CREATE TABLE transactions(
        id TEXT PRIMARY KEY,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        date TEXT NOT NULL,
        category TEXT NOT NULL,
        description TEXT,
        paymentMethod TEXT NOT NULL,
        receiptImagePath TEXT,
        location TEXT
      )
    ''');

    // Create categories table
    await db.execute('''
      CREATE TABLE categories(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        iconCode INTEGER NOT NULL,
        colorValue INTEGER NOT NULL
      )
    ''');

    // Create budgets table
    await db.execute('''
      CREATE TABLE budgets(
        id TEXT PRIMARY KEY,
        categoryId TEXT NOT NULL,
        amount REAL NOT NULL,
        startDate TEXT NOT NULL,
        endDate TEXT NOT NULL,
        spentAmount REAL NOT NULL,
        FOREIGN KEY(categoryId) REFERENCES categories(id)
      )
    ''');

    // Insert default categories
    await _insertDefaultCategories(db);
  }

  Future<void> _insertDefaultCategories(sql.Database db) async {
    final defaultCategories = [
      {
        'id': 'food',
        'name': 'Food',
        'iconCode': 0xe25a, // restaurant icon
        'colorValue': 0xFFE57373, // red-300
      },
      {
        'id': 'transport',
        'name': 'Transport',
        'iconCode': 0xe5d1, // directions_car icon
        'colorValue': 0xFF64B5F6, // blue-300
      },
      {
        'id': 'housing',
        'name': 'Housing',
        'iconCode': 0xe318, // home icon
        'colorValue': 0xFF81C784, // green-300
      },
      {
        'id': 'utilities',
        'name': 'Utilities',
        'iconCode': 0xe336, // lightbulb icon
        'colorValue': 0xFFFFD54F, // amber-300
      },
      {
        'id': 'health',
        'name': 'Health',
        'iconCode': 0xe7f2, // local_hospital icon
        'colorValue': 0xFFF06292, // pink-300
      },
      {
        'id': 'entertainment',
        'name': 'Entertainment',
        'iconCode': 0xe87c, // movie icon
        'colorValue': 0xFF9575CD, // deep-purple-300
      },
      {
        'id': 'salary',
        'name': 'Salary',
        'iconCode': 0xe8f8, // payment icon
        'colorValue': 0xFF4DB6AC, // teal-300
      },
      {
        'id': 'other',
        'name': 'Other',
        'iconCode': 0xe883, // more_horiz icon
        'colorValue': 0xFF90A4AE, // blue-grey-300
      },
    ];

    for (final category in defaultCategories) {
      await db.insert('categories', category);
    }
  }

  // TRANSACTION METHODS

  Future<String> insertTransaction(Transaction transaction) async {
    final db = await database;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final map = transaction.toMap()..['id'] = id;
    await db.insert('transactions', map);
    return id;
  }

  Future<List<Transaction>> getTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('transactions', orderBy: 'date DESC');
    return List.generate(maps.length, (i) => Transaction.fromMap(maps[i]));
  }

  Future<List<Transaction>> getTransactionsByType(TransactionType type) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'type = ?',
      whereArgs: [type.toString()],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => Transaction.fromMap(maps[i]));
  }

  Future<List<Transaction>> getTransactionsByCategory(String categoryId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'category = ?',
      whereArgs: [categoryId],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => Transaction.fromMap(maps[i]));
  }

  Future<List<Transaction>> getTransactionsByDateRange(
      DateTime start, DateTime end) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => Transaction.fromMap(maps[i]));
  }

  Future<void> updateTransaction(Transaction transaction) async {
    final db = await database;
    await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<void> deleteTransaction(String id) async {
    final db = await database;
    await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // CATEGORY METHODS

  Future<List<Category>> getCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('categories');
    return List.generate(maps.length, (i) => Category.fromMap(maps[i]));
  }

  Future<Category> getCategoryById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
    return Category.fromMap(maps.first);
  }

  Future<void> insertCategory(Category category) async {
    final db = await database;
    await db.insert('categories', category.toMap());
  }

  Future<void> updateCategory(Category category) async {
    final db = await database;
    await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<void> deleteCategory(String id) async {
    final db = await database;
    await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // BUDGET METHODS

  Future<String> insertBudget(Budget budget) async {
    final db = await database;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final map = budget.toMap()..['id'] = id;
    await db.insert('budgets', map);
    return id;
  }

  Future<List<Budget>> getBudgets() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('budgets');
    return List.generate(maps.length, (i) => Budget.fromMap(maps[i]));
  }

  Future<Budget?> getBudgetByCategory(String categoryId, DateTime date) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'budgets',
      where: 'categoryId = ? AND startDate <= ? AND endDate >= ?',
      whereArgs: [categoryId, date.toIso8601String(), date.toIso8601String()],
    );
    if (maps.isEmpty) return null;
    return Budget.fromMap(maps.first);
  }

  Future<List<Budget>> getCurrentMonthBudgets() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'budgets',
      where: 'startDate <= ? AND endDate >= ?',
      whereArgs: [endOfMonth.toIso8601String(), startOfMonth.toIso8601String()],
    );
    return List.generate(maps.length, (i) => Budget.fromMap(maps[i]));
  }

  Future<void> updateBudget(Budget budget) async {
    final db = await database;
    await db.update(
      'budgets',
      budget.toMap(),
      where: 'id = ?',
      whereArgs: [budget.id],
    );
  }

  Future<void> deleteBudget(String id) async {
    final db = await database;
    await db.delete(
      'budgets',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ANALYTICS METHODS

  Future<double> getTotalExpenses() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT SUM(amount) as total
      FROM transactions
      WHERE type = ?
    ''', [TransactionType.expense.toString()]);
    return result.first['total'] as double? ?? 0.0;
  }

  Future<double> getTotalIncome() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT SUM(amount) as total
      FROM transactions
      WHERE type = ?
    ''', [TransactionType.income.toString()]);
    return result.first['total'] as double? ?? 0.0;
  }

  Future<Map<String, double>> getExpensesByCategory() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT category, SUM(amount) as total
      FROM transactions
      WHERE type = ?
      GROUP BY category
    ''', [TransactionType.expense.toString()]);

    final Map<String, double> categoryExpenses = {};
    for (final row in result) {
      categoryExpenses[row['category'] as String] =
          row['total'] as double? ?? 0.0;
    }
    return categoryExpenses;
  }

  Future<double> getExpensesByDateRange(DateTime start, DateTime end) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT SUM(amount) as total
      FROM transactions
      WHERE type = ? AND date BETWEEN ? AND ?
    ''', [
      TransactionType.expense.toString(),
      start.toIso8601String(),
      end.toIso8601String(),
    ]);
    return result.first['total'] as double? ?? 0.0;
  }

  Future<double> getIncomeByDateRange(DateTime start, DateTime end) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT SUM(amount) as total
      FROM transactions
      WHERE type = ? AND date BETWEEN ? AND ?
    ''', [
      TransactionType.income.toString(),
      start.toIso8601String(),
      end.toIso8601String(),
    ]);
    return result.first['total'] as double? ?? 0.0;
  }
}
