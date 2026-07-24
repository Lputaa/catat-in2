import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../database_helper.dart';
import '../models/transaction_model.dart';
import '../models/transaction_filter_model.dart';

class TransactionRepo {
  final _db = DatabaseHelper.instance;
  final _uuid = const Uuid();

  Future<List<TransactionModel>> getAll({int? limit}) async {
    final db = await _db.database;
    final maps = await db.query(
      'transactions',
      orderBy: 'date DESC',
      limit: limit,
    );
    return maps.map(TransactionModel.fromMap).toList();
  }

  Future<List<TransactionModel>> getByDateRange(DateTime start, DateTime end) async {
    final db = await _db.database;
    final maps = await db.query(
      'transactions',
      where: 'date >= ? AND date < ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'date DESC',
    );
    return maps.map(TransactionModel.fromMap).toList();
  }

  Future<List<TransactionModel>> getByMonth(int year, int month) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);
    return getByDateRange(start, end);
  }

  Future<List<TransactionModel>> getByAccount(String accountId) async {
    final db = await _db.database;
    final maps = await db.query(
      'transactions',
      where: 'account_id = ?',
      whereArgs: [accountId],
      orderBy: 'date DESC',
    );
    return maps.map(TransactionModel.fromMap).toList();
  }

  Future<List<TransactionModel>> getByCategory(String categoryId) async {
    final db = await _db.database;
    final maps = await db.query(
      'transactions',
      where: 'category_id = ?',
      whereArgs: [categoryId],
      orderBy: 'date DESC',
    );
    return maps.map(TransactionModel.fromMap).toList();
  }

  Future<List<TransactionModel>> getFiltered({
    TransactionTypeFilter type = TransactionTypeFilter.all,
    DateTimeRange? dateRange,
    String? accountId,
    SortOrder sort = SortOrder.newest,
    String? search,
  }) async {
    final db = await _db.database;
    final where = <String>[];
    final args = <dynamic>[];

    if (type != TransactionTypeFilter.all) {
      where.add('type = ?');
      args.add(type == TransactionTypeFilter.income ? 'income' : 'expense');
    }

    if (dateRange != null) {
      where.add('date >= ? AND date < ?');
      args.addAll([
        dateRange.start.millisecondsSinceEpoch,
        dateRange.end.millisecondsSinceEpoch,
      ]);
    }

    if (accountId != null) {
      where.add('account_id = ?');
      args.add(accountId);
    }

    if (search != null && search.isNotEmpty) {
      where.add('note LIKE ?');
      args.add('%$search%');
    }

    final orderBy = switch (sort) {
      SortOrder.newest => 'date DESC',
      SortOrder.oldest => 'date ASC',
      SortOrder.largest => 'amount DESC',
      SortOrder.smallest => 'amount ASC',
    };

    final maps = await db.query(
      'transactions',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: orderBy,
    );
    return maps.map(TransactionModel.fromMap).toList();
  }

  /// Total spent in a category for a given month
  Future<double> getCategoryTotal(String categoryId, int year, int month) async {
    final db = await _db.database;
    final start = DateTime(year, month, 1).millisecondsSinceEpoch;
    final end = DateTime(year, month + 1, 1).millisecondsSinceEpoch;
    final result = await db.rawQuery(
      "SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE category_id = ? AND type = 'expense' AND date >= ? AND date < ?",
      [categoryId, start, end],
    );
    return (result.first['total'] as num).toDouble();
  }

  /// Total income/expense for a month
  Future<Map<String, double>> getMonthSummary(int year, int month) async {
    final db = await _db.database;
    final start = DateTime(year, month, 1).millisecondsSinceEpoch;
    final end = DateTime(year, month + 1, 1).millisecondsSinceEpoch;

    final incomeResult = await db.rawQuery(
      "SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE type = 'income' AND date >= ? AND date < ?",
      [start, end],
    );
    final expenseResult = await db.rawQuery(
      "SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE type = 'expense' AND date >= ? AND date < ?",
      [start, end],
    );

    return {
      'income': (incomeResult.first['total'] as num).toDouble(),
      'expense': (expenseResult.first['total'] as num).toDouble(),
    };
  }

  /// Month summary filtered by account (null = all accounts)
  Future<Map<String, double>> getMonthSummaryFiltered({
    required int year,
    required int month,
    String? accountId,
  }) async {
    final db = await _db.database;
    final start = DateTime(year, month, 1).millisecondsSinceEpoch;
    final end = DateTime(year, month + 1, 1).millisecondsSinceEpoch;

    final accFilter = accountId != null ? 'AND account_id = ?' : '';
    final args = accountId != null
        ? [start, end, accountId]
        : [start, end];

    final incomeResult = await db.rawQuery(
      "SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE type = 'income' AND date >= ? AND date < ? $accFilter",
      args,
    );
    final expenseResult = await db.rawQuery(
      "SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE type = 'expense' AND date >= ? AND date < ? $accFilter",
      args,
    );

    return {
      'income': (incomeResult.first['total'] as num).toDouble(),
      'expense': (expenseResult.first['total'] as num).toDouble(),
    };
  }

  /// Expense per category for a month, optionally filtered by account
  Future<Map<String, double>> getCategoryBreakdown({
    required int year,
    required int month,
    String? accountId,
  }) async {
    final db = await _db.database;
    final start = DateTime(year, month, 1).millisecondsSinceEpoch;
    final end = DateTime(year, month + 1, 1).millisecondsSinceEpoch;

    final accFilter = accountId != null ? 'AND account_id = ?' : '';
    final args = accountId != null
        ? [start, end, accountId]
        : [start, end];

    final result = await db.rawQuery(
      "SELECT category_id, COALESCE(SUM(amount), 0) as total FROM transactions WHERE type = 'expense' AND date >= ? AND date < ? $accFilter GROUP BY category_id",
      args,
    );

    return {for (final r in result) r['category_id'] as String: (r['total'] as num).toDouble()};
  }

  /// Daily income/expense totals for a month (for trend chart)
  Future<List<Map<String, double>>> getDailyTotals({
    required int year,
    required int month,
    String? accountId,
  }) async {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final db = await _db.database;
    final start = DateTime(year, month, 1).millisecondsSinceEpoch;
    final end = DateTime(year, month + 1, 1).millisecondsSinceEpoch;

    final accFilter = accountId != null ? 'AND account_id = ?' : '';
    final args = accountId != null
        ? [start, end, accountId]
        : [start, end];

    final result = await db.rawQuery(
      "SELECT date, type, COALESCE(SUM(amount), 0) as total FROM transactions WHERE date >= ? AND date < ? $accFilter GROUP BY date, type",
      args,
    );

    // Build per-day map
    final dayMap = <int, Map<String, double>>{};
    for (final r in result) {
      final dt = DateTime.fromMillisecondsSinceEpoch(r['date'] as int);
      final day = dt.day;
      dayMap.putIfAbsent(day, () => {'income': 0, 'expense': 0});
      dayMap[day]![r['type'] as String] = (r['total'] as num).toDouble();
    }

    return List.generate(daysInMonth, (i) {
      final day = i + 1;
      return dayMap[day] ?? {'income': 0, 'expense': 0};
    });
  }

  Future<void> insert(TransactionModel tx) async {
    final db = await _db.database;
    await db.insert('transactions', tx.toMap());
  }

  Future<void> update(TransactionModel tx) async {
    final db = await _db.database;
    await db.update('transactions', tx.toMap(), where: 'id = ?', whereArgs: [tx.id]);
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  String newId() => 'tx_${_uuid.v4()}';
}
