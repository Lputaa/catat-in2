/// Direction of a debt record.
/// [hutang]  = user owes someone (pinjaman personal) — money to pay back.
/// Note: paylater/kredit is handled via AccountType.paylater wallets instead.
/// [piutang] = someone owes the user — money to collect.
enum DebtType { hutang, piutang }

class DebtModel {
  final String id;
  final DebtType type;

  /// Other party: person name (e.g. "Budi", "Kak Rina").
  final String counterpart;

  /// Total owed amount.
  final double amount;

  /// Amount already paid/collected via debt payments.
  final double paidAmount;
  final DateTime? dueDate;
  final String? note;
  final DateTime createdAt;

  const DebtModel({
    required this.id,
    required this.type,
    required this.counterpart,
    required this.amount,
    this.paidAmount = 0,
    this.dueDate,
    this.note,
    required this.createdAt,
  });

  double get remaining => (amount - paidAmount).clamp(0, double.infinity);

  double get percent => amount > 0 ? (paidAmount / amount).clamp(0.0, 1.0) : 0;

  bool get isSettled => paidAmount >= amount - 0.001;

  bool get isOverdue {
    if (isSettled || dueDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return dueDate!.isBefore(today);
  }

  String get typeLabel => type == DebtType.hutang ? 'Hutang' : 'Piutang';

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type.name,
    'counterpart': counterpart,
    'amount': amount,
    'paid_amount': paidAmount,
    'due_date': dueDate?.millisecondsSinceEpoch,
    'note': note,
    'created_at': createdAt.millisecondsSinceEpoch,
  };

  factory DebtModel.fromMap(Map<String, dynamic> m) => DebtModel(
    id: m['id'] as String,
    type: DebtType.values.firstWhere(
      (e) => e.name == m['type'],
      orElse: () => DebtType.hutang,
    ),
    counterpart: m['counterpart'] as String,
    amount: (m['amount'] as num).toDouble(),
    paidAmount: (m['paid_amount'] as num?)?.toDouble() ?? 0,
    dueDate: m['due_date'] != null
        ? DateTime.fromMillisecondsSinceEpoch(m['due_date'] as int)
        : null,
    note: m['note'] as String?,
    createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
  );

  DebtModel copyWith({
    String? id,
    DebtType? type,
    String? counterpart,
    double? amount,
    double? paidAmount,
    DateTime? dueDate,
    bool clearDueDate = false,
    String? note,
    DateTime? createdAt,
  }) => DebtModel(
    id: id ?? this.id,
    type: type ?? this.type,
    counterpart: counterpart ?? this.counterpart,
    amount: amount ?? this.amount,
    paidAmount: paidAmount ?? this.paidAmount,
    dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
    note: note ?? this.note,
    createdAt: createdAt ?? this.createdAt,
  );
}
