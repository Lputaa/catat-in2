/// A single payment/installment on a debt.
/// For hutang: money the user paid back. For piutang: money collected.
class DebtPaymentModel {
  final String id;
  final String debtId;
  final double amount;
  final DateTime date;
  final String? note;

  const DebtPaymentModel({
    required this.id,
    required this.debtId,
    required this.amount,
    required this.date,
    this.note,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'debt_id': debtId,
    'amount': amount,
    'date': date.millisecondsSinceEpoch,
    'note': note,
  };

  factory DebtPaymentModel.fromMap(Map<String, dynamic> m) => DebtPaymentModel(
    id: m['id'] as String,
    debtId: m['debt_id'] as String,
    amount: (m['amount'] as num).toDouble(),
    date: DateTime.fromMillisecondsSinceEpoch(m['date'] as int),
    note: m['note'] as String?,
  );
}
