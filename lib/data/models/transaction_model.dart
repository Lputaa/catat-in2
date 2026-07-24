enum TransactionType { income, expense }

class TransactionModel {
  final String id;
  final TransactionType type;
  final double amount;
  final String categoryId;
  final String accountId;
  final DateTime date;
  final String? note;

  const TransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.categoryId,
    required this.accountId,
    required this.date,
    this.note,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type == TransactionType.income ? 'income' : 'expense',
        'amount': amount,
        'category_id': categoryId,
        'account_id': accountId,
        'date': date.millisecondsSinceEpoch,
        'note': note,
      };

  factory TransactionModel.fromMap(Map<String, dynamic> m) => TransactionModel(
        id: m['id'] as String,
        type: (m['type'] as String) == 'income'
            ? TransactionType.income
            : TransactionType.expense,
        amount: (m['amount'] as num).toDouble(),
        categoryId: m['category_id'] as String,
        accountId: m['account_id'] as String,
        date: DateTime.fromMillisecondsSinceEpoch(m['date'] as int),
        note: m['note'] as String?,
      );

  TransactionModel copyWith({
    String? id,
    TransactionType? type,
    double? amount,
    String? categoryId,
    String? accountId,
    DateTime? date,
    String? note,
  }) =>
      TransactionModel(
        id: id ?? this.id,
        type: type ?? this.type,
        amount: amount ?? this.amount,
        categoryId: categoryId ?? this.categoryId,
        accountId: accountId ?? this.accountId,
        date: date ?? this.date,
        note: note ?? this.note,
      );
}
