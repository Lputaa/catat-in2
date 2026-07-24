import 'package:uuid/uuid.dart';
import '../database_helper.dart';
import '../models/savings_goal_model.dart';
import '../models/savings_contribution_model.dart';

class SavingsGoalRepo {
  final _db = DatabaseHelper.instance;
  final _uuid = const Uuid();

  Future<List<SavingsGoalModel>> getAll() async {
    final db = await _db.database;
    final maps = await db.query('savings_goals', orderBy: 'name');
    return maps.map(SavingsGoalModel.fromMap).toList();
  }

  Future<SavingsGoalModel?> getById(String id) async {
    final db = await _db.database;
    final maps = await db.query('savings_goals', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return SavingsGoalModel.fromMap(maps.first);
  }

  Future<void> insert(SavingsGoalModel goal) async {
    final db = await _db.database;
    await db.insert('savings_goals', goal.toMap());
  }

  Future<void> update(SavingsGoalModel goal) async {
    final db = await _db.database;
    await db.update('savings_goals', goal.toMap(), where: 'id = ?', whereArgs: [goal.id]);
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('savings_contributions', where: 'goal_id = ?', whereArgs: [id]);
    await db.delete('savings_goals', where: 'id = ?', whereArgs: [id]);
  }

  // ── Contributions ──
  Future<void> addContribution(SavingsContributionModel contrib) async {
    final db = await _db.database;
    await db.insert('savings_contributions', contrib.toMap());

    // Update goal saved_amount
    final goal = await getById(contrib.goalId);
    if (goal != null) {
      await update(goal.copyWith(savedAmount: goal.savedAmount + contrib.amount));
    }
  }

  Future<List<SavingsContributionModel>> getContributions(String goalId) async {
    final db = await _db.database;
    final maps = await db.query(
      'savings_contributions',
      where: 'goal_id = ?',
      whereArgs: [goalId],
      orderBy: 'date DESC',
    );
    return maps.map(SavingsContributionModel.fromMap).toList();
  }

  String newGoalId() => 'goal_${_uuid.v4()}';
  String newContribId() => 'contrib_${_uuid.v4()}';
}
