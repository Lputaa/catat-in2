import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// SQLite database singleton for Catat-In Financial Tracker
/// Tables: categories, accounts, transactions, budgets
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();
  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'catat_in.db');
    return openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        icon TEXT NOT NULL,
        color INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE accounts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        initial_balance REAL NOT NULL DEFAULT 0,
        type TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        category_id TEXT NOT NULL,
        account_id TEXT NOT NULL,
        date INTEGER NOT NULL,
        note TEXT,
        FOREIGN KEY (category_id) REFERENCES categories(id),
        FOREIGN KEY (account_id) REFERENCES accounts(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE budgets (
        id TEXT PRIMARY KEY,
        category_id TEXT NOT NULL,
        limit_amount REAL NOT NULL,
        year INTEGER NOT NULL,
        month INTEGER NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE savings_goals (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        target_amount REAL NOT NULL,
        saved_amount REAL NOT NULL DEFAULT 0,
        deadline INTEGER,
        account_id TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE savings_contributions (
        id TEXT PRIMARY KEY,
        goal_id TEXT NOT NULL,
        amount REAL NOT NULL,
        date INTEGER NOT NULL,
        note TEXT,
        FOREIGN KEY (goal_id) REFERENCES savings_goals(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE recurring_transactions (
        id TEXT PRIMARY KEY,
        transaction_type TEXT NOT NULL,
        amount REAL NOT NULL,
        category_id TEXT NOT NULL,
        account_id TEXT NOT NULL,
        note TEXT,
        frequency TEXT NOT NULL,
        start_date INTEGER NOT NULL,
        next_date INTEGER NOT NULL,
        auto_record INTEGER NOT NULL DEFAULT 0,
        active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Seed defaults
    await _seedCategories(db);
    await _seedAccounts(db);
  }

  Future<void> _seedCategories(Database db) async {
    final defaults = <Map<String, dynamic>>[
      // Expense categories
      {'id': 'cat_makanan', 'name': 'Makanan', 'type': 'expense', 'icon': 'restaurant', 'color': 0xFFFF6B35},
      {'id': 'cat_transport', 'name': 'Transportasi', 'type': 'expense', 'icon': 'directions_car', 'color': 0xFF4361EE},
      {'id': 'cat_belanja', 'name': 'Belanja', 'type': 'expense', 'icon': 'shopping_bag', 'color': 0xFFB5179E},
      {'id': 'cat_hiburan', 'name': 'Hiburan', 'type': 'expense', 'icon': 'movie', 'color': 0xFFFFD60A},
      {'id': 'cat_kesehatan', 'name': 'Kesehatan', 'type': 'expense', 'icon': 'local_hospital', 'color': 0xFF06D6A0},
      {'id': 'cat_tagihan', 'name': 'Tagihan', 'type': 'expense', 'icon': 'receipt_long', 'color': 0xFFEF476F},
      {'id': 'cat_pendidikan', 'name': 'Pendidikan', 'type': 'expense', 'icon': 'school', 'color': 0xFF00D9FF},
      {'id': 'cat_lainnya_exp', 'name': 'Lainnya', 'type': 'expense', 'icon': 'more_horiz', 'color': 0xFFE5E5E5},
      // Income categories
      {'id': 'cat_gaji', 'name': 'Gaji', 'type': 'income', 'icon': 'work', 'color': 0xFF06D6A0},
      {'id': 'cat_bonus', 'name': 'Bonus', 'type': 'income', 'icon': 'card_giftcard', 'color': 0xFFFFD60A},
      {'id': 'cat_investasi', 'name': 'Investasi', 'type': 'income', 'icon': 'trending_up', 'color': 0xFFFF9F1C},
      {'id': 'cat_lainnya_inc', 'name': 'Lainnya', 'type': 'income', 'icon': 'more_horiz', 'color': 0xFFE5E5E5},
    ];
    for (final cat in defaults) {
      await db.insert('categories', cat);
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS savings_goals (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          target_amount REAL NOT NULL,
          saved_amount REAL NOT NULL DEFAULT 0,
          deadline INTEGER,
          account_id TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS savings_contributions (
          id TEXT PRIMARY KEY,
          goal_id TEXT NOT NULL,
          amount REAL NOT NULL,
          date INTEGER NOT NULL,
          note TEXT,
          FOREIGN KEY (goal_id) REFERENCES savings_goals(id)
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS recurring_transactions (
          id TEXT PRIMARY KEY,
          transaction_type TEXT NOT NULL,
          amount REAL NOT NULL,
          category_id TEXT NOT NULL,
          account_id TEXT NOT NULL,
          note TEXT,
          frequency TEXT NOT NULL,
          start_date INTEGER NOT NULL,
          next_date INTEGER NOT NULL,
          auto_record INTEGER NOT NULL DEFAULT 0,
          active INTEGER NOT NULL DEFAULT 1
        )
      ''');
    }
  }

  Future<void> _seedAccounts(Database db) async {
    final defaults = <Map<String, dynamic>>[
      {'id': 'acc_tunai', 'name': 'Tunai', 'initial_balance': 0, 'type': 'cash'},
      {'id': 'acc_bank', 'name': 'Rekening Bank', 'initial_balance': 0, 'type': 'bank'},
      {'id': 'acc_ewallet', 'name': 'E-Wallet', 'initial_balance': 0, 'type': 'ewallet'},
    ];
    for (final acc in defaults) {
      await db.insert('accounts', acc);
    }
  }
}
