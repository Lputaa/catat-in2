import 'package:uuid/uuid.dart';
import '../database_helper.dart';
import '../models/budget_model.dart';

class BudgetRepo {
  final _db = DatabaseHelper.instance;
  final _uuid = const Uuid();

  Future<List<BudgetModel>> getByMonth(int year, int month) async {
    final db = await _db.database;
    final maps = await db.query(
      'budgets',
      where: 'year = ? AND month = ?',
      whereArgs: [year, month],
    );
    return maps.map(BudgetModel.fromMap).toList();
  }

  Future<BudgetModel?> getByCategoryAndMonth(String categoryId, int year, int month) async {
    final db = await _db.database;
    final maps = await db.query(
      'budgets',
      where: 'category_id = ? AND year = ? AND month = ?',
      whereArgs: [categoryId, year, month],
    );
    if (maps.isEmpty) return null;
    return BudgetModel.fromMap(maps.first);
  }

  Future<void> insert(BudgetModel budget) async {
    final db = await _db.database;
    await db.insert('budgets', budget.toMap());
  }

  Future<void> update(BudgetModel budget) async {
    final db = await _db.database;
    await db.update('budgets', budget.toMap(), where: 'id = ?', whereArgs: [budget.id]);
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }

  /// Copy all budgets from source month to target month
  Future<void> copyMonth(int fromYear, int fromMonth, int toYear, int toMonth) async {
    final source = await getByMonth(fromYear, fromMonth);
    for (final b in source) {
      final exists = await getByCategoryAndMonth(b.categoryId, toYear, toMonth);
      if (exists == null) {
        await insert(BudgetModel(
          id: newId(),
          categoryId: b.categoryId,
          limitAmount: b.limitAmount,
          year: toYear,
          month: toMonth,
        ));
      }
    }
  }

  String newId() => 'bgt_${_uuid.v4()}';
}
