import 'package:uuid/uuid.dart';
import '../budget_alert_service.dart';
import '../database_helper.dart';
import '../models/recurring_transaction_model.dart';
import '../models/transaction_model.dart';
import 'transaction_repo.dart';

class RecurringRepo {
  final _db = DatabaseHelper.instance;
  final _uuid = const Uuid();

  Future<List<RecurringTransactionModel>> getAll() async {
    final db = await _db.database;
    final maps = await db.query(
      'recurring_transactions',
      orderBy: 'next_date ASC',
    );
    return maps.map(RecurringTransactionModel.fromMap).toList();
  }

  Future<List<RecurringTransactionModel>> getActive() async {
    final db = await _db.database;
    final maps = await db.query(
      'recurring_transactions',
      where: 'active = 1',
      orderBy: 'next_date ASC',
    );
    return maps.map(RecurringTransactionModel.fromMap).toList();
  }

  Future<List<RecurringTransactionModel>> getDue() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final db = await _db.database;
    final maps = await db.query(
      'recurring_transactions',
      where: 'active = 1 AND next_date <= ?',
      whereArgs: [now],
      orderBy: 'next_date ASC',
    );
    return maps.map(RecurringTransactionModel.fromMap).toList();
  }

  /// Active recurring transactions whose next date falls on tomorrow.
  Future<List<RecurringTransactionModel>> getDueTomorrow() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day + 1);
    final end = DateTime(now.year, now.month, now.day + 2);
    final db = await _db.database;
    final maps = await db.query(
      'recurring_transactions',
      where: 'active = 1 AND next_date >= ? AND next_date < ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'next_date ASC',
    );
    return maps.map(RecurringTransactionModel.fromMap).toList();
  }

  Future<RecurringTransactionModel?> getById(String id) async {
    final db = await _db.database;
    final maps = await db.query(
      'recurring_transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return RecurringTransactionModel.fromMap(maps.first);
  }

  Future<void> insert(RecurringTransactionModel rt) async {
    final db = await _db.database;
    await db.insert('recurring_transactions', rt.toMap());
  }

  Future<void> update(RecurringTransactionModel rt) async {
    final db = await _db.database;
    await db.update(
      'recurring_transactions',
      rt.toMap(),
      where: 'id = ?',
      whereArgs: [rt.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('recurring_transactions', where: 'id = ?', whereArgs: [id]);
  }

  /// Process due recurring transactions:
  /// - autoRecord=true: create transaction + advance nextDate
  /// - autoRecord=false: return list for manual confirmation
  Future<List<RecurringTransactionModel>> processDueTransactions() async {
    final due = await getDue();
    final txRepo = TransactionRepo();
    final manualConfirm = <RecurringTransactionModel>[];

    for (final rt in due) {
      if (rt.autoRecord) {
        // Auto-create transaction
        final type = rt.transactionType == 'income'
            ? TransactionType.income
            : TransactionType.expense;
        final tx = TransactionModel(
          id: txRepo.newId(),
          type: type,
          amount: rt.amount,
          categoryId: rt.categoryId,
          accountId: rt.accountId,
          date: rt.nextDate,
          note: rt.note,
        );
        await txRepo.insert(tx);
        await BudgetAlertService.checkAfterExpense(tx);
        // Advance next date
        await update(rt.copyWith(nextDate: rt.calculateNextDate()));
      } else {
        manualConfirm.add(rt);
      }
    }

    return manualConfirm;
  }

  /// Manually record a recurring transaction and advance its date
  Future<void> recordAndAdvance(RecurringTransactionModel rt) async {
    final txRepo = TransactionRepo();
    final type = rt.transactionType == 'income'
        ? TransactionType.income
        : TransactionType.expense;
    final tx = TransactionModel(
      id: txRepo.newId(),
      type: type,
      amount: rt.amount,
      categoryId: rt.categoryId,
      accountId: rt.accountId,
      date: rt.nextDate,
      note: rt.note,
    );
    await txRepo.insert(tx);
    await BudgetAlertService.checkAfterExpense(tx);
    await update(rt.copyWith(nextDate: rt.calculateNextDate()));
  }

  String newId() => 'rec_${_uuid.v4()}';
}
