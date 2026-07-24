enum TransactionType { income, expense, transfer }

class TransactionModel {
  final String id;
  final TransactionType type;
  final double amount;
  final String categoryId;
  final String accountId;

  /// Destination account for [TransactionType.transfer]. Null for income/expense.
  final String? toAccountId;
  final DateTime date;
  final String? note;

  const TransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.categoryId,
    required this.accountId,
    this.toAccountId,
    required this.date,
    this.note,
  });

  bool get isTransfer => type == TransactionType.transfer;

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type.name,
    'amount': amount,
    'category_id': categoryId,
    'account_id': accountId,
    'to_account_id': toAccountId,
    'date': date.millisecondsSinceEpoch,
    'note': note,
  };

  factory TransactionModel.fromMap(Map<String, dynamic> m) => TransactionModel(
    id: m['id'] as String,
    type: TransactionType.values.firstWhere(
      (e) => e.name == m['type'],
      orElse: () => TransactionType.expense,
    ),
    amount: (m['amount'] as num).toDouble(),
    categoryId: m['category_id'] as String,
    accountId: m['account_id'] as String,
    toAccountId: m['to_account_id'] as String?,
    date: DateTime.fromMillisecondsSinceEpoch(m['date'] as int),
    note: m['note'] as String?,
  );

  TransactionModel copyWith({
    String? id,
    TransactionType? type,
    double? amount,
    String? categoryId,
    String? accountId,
    String? toAccountId,
    DateTime? date,
    String? note,
  }) => TransactionModel(
    id: id ?? this.id,
    type: type ?? this.type,
    amount: amount ?? this.amount,
    categoryId: categoryId ?? this.categoryId,
    accountId: accountId ?? this.accountId,
    toAccountId: toAccountId ?? this.toAccountId,
    date: date ?? this.date,
    note: note ?? this.note,
  );
}
