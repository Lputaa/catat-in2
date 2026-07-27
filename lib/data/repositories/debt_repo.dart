import 'package:uuid/uuid.dart';
import '../database_helper.dart';
import '../models/debt_model.dart';
import '../models/debt_payment_model.dart';

class DebtRepo {
  final _db = DatabaseHelper.instance;
  final _uuid = const Uuid();

  Future<List<DebtModel>> getAll() async {
    final db = await _db.database;
    final maps = await db.query('debts', orderBy: 'created_at DESC');
    return maps.map(DebtModel.fromMap).toList();
  }

  Future<DebtModel?> getById(String id) async {
    final db = await _db.database;
    final maps = await db.query('debts', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return DebtModel.fromMap(maps.first);
  }

  Future<void> insert(DebtModel debt) async {
    final db = await _db.database;
    await db.insert('debts', debt.toMap());
  }

  Future<void> update(DebtModel debt) async {
    final db = await _db.database;
    await db.update(
      'debts',
      debt.toMap(),
      where: 'id = ?',
      whereArgs: [debt.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('debt_payments', where: 'debt_id = ?', whereArgs: [id]);
    await db.delete('debts', where: 'id = ?', whereArgs: [id]);
  }

  // ── Payments ──
  Future<void> addPayment(DebtPaymentModel payment) async {
    final db = await _db.database;
    await db.insert('debt_payments', payment.toMap());

    // Bump paid_amount on the parent debt
    final debt = await getById(payment.debtId);
    if (debt != null) {
      await update(debt.copyWith(paidAmount: debt.paidAmount + payment.amount));
    }
  }

  Future<List<DebtPaymentModel>> getPayments(String debtId) async {
    final db = await _db.database;
    final maps = await db.query(
      'debt_payments',
      where: 'debt_id = ?',
      whereArgs: [debtId],
      orderBy: 'date DESC',
    );
    return maps.map(DebtPaymentModel.fromMap).toList();
  }

  /// Unsettled debts due today or tomorrow (for startup notification).
  Future<List<DebtModel>> getDueSoon() async {
    final all = await getAll();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dayAfterTomorrow = today.add(const Duration(days: 2));
    return all.where((d) {
      if (d.isSettled || d.dueDate == null) return false;
      final due = DateTime(d.dueDate!.year, d.dueDate!.month, d.dueDate!.day);
      return !due.isBefore(today) && due.isBefore(dayAfterTomorrow);
    }).toList();
  }

  String newDebtId() => 'debt_${_uuid.v4()}';
  String newPaymentId() => 'debtpay_${_uuid.v4()}';
}
