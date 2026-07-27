import 'package:uuid/uuid.dart';
import '../database_helper.dart';
import '../models/account_model.dart';

class AccountRepo {
  final _db = DatabaseHelper.instance;
  final _uuid = const Uuid();

  Future<List<AccountModel>> getAll() async {
    final db = await _db.database;
    final maps = await db.query('accounts', orderBy: 'name');
    return maps.map(AccountModel.fromMap).toList();
  }

  Future<AccountModel?> getById(String id) async {
    final db = await _db.database;
    final maps = await db.query('accounts', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return AccountModel.fromMap(maps.first);
  }

  /// Get current balance = initial_balance + income - expense ± transfers
  Future<double> getBalance(String accountId) async {
    final db = await _db.database;
    final account = await getById(accountId);
    if (account == null) return 0;

    final incomeResult = await db.rawQuery(
      "SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE account_id = ? AND type = 'income'",
      [accountId],
    );
    final expenseResult = await db.rawQuery(
      "SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE account_id = ? AND type = 'expense'",
      [accountId],
    );
    final transferOutResult = await db.rawQuery(
      "SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE account_id = ? AND type = 'transfer'",
      [accountId],
    );
    final transferInResult = await db.rawQuery(
      "SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE to_account_id = ? AND type = 'transfer'",
      [accountId],
    );

    final income = (incomeResult.first['total'] as num).toDouble();
    final expense = (expenseResult.first['total'] as num).toDouble();
    final transferOut = (transferOutResult.first['total'] as num).toDouble();
    final transferIn = (transferInResult.first['total'] as num).toDouble();
    return account.initialBalance + income - expense - transferOut + transferIn;
  }

  Future<double> getTotalBalance() async {
    final accounts = await getAll();
    double total = 0;
    for (final a in accounts) {
      total += await getBalance(a.id);
    }
    return total;
  }

  Future<void> insert(AccountModel account) async {
    final db = await _db.database;
    await db.insert('accounts', account.toMap());
  }

  Future<void> update(AccountModel account) async {
    final db = await _db.database;
    await db.update(
      'accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('accounts', where: 'id = ?', whereArgs: [id]);
  }

  String newId() => 'acc_${_uuid.v4()}';

  /// Count transactions linked to this account (including incoming transfers).
  Future<int> countTransactions(String accountId) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM transactions WHERE account_id = ? OR to_account_id = ?',
      [accountId, accountId],
    );
    return (result.first['cnt'] as int?) ?? 0;
  }

  /// Count recurring transactions linked to this account.
  Future<int> countRecurring(String accountId) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM recurring_transactions WHERE account_id = ?',
      [accountId],
    );
    return (result.first['cnt'] as int?) ?? 0;
  }
}
