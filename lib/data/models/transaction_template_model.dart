import 'transaction_model.dart';

/// Reusable quick-entry template: one tap records a pre-filled transaction.
class TransactionTemplateModel {
  final String id;
  final String name;
  final TransactionType type;
  final double amount;
  final String categoryId;
  final String accountId;
  final String? note;

  const TransactionTemplateModel({
    required this.id,
    required this.name,
    required this.type,
    required this.amount,
    required this.categoryId,
    required this.accountId,
    this.note,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'type': type.name,
    'amount': amount,
    'category_id': categoryId,
    'account_id': accountId,
    'note': note,
  };

  factory TransactionTemplateModel.fromMap(Map<String, dynamic> m) =>
      TransactionTemplateModel(
        id: m['id'] as String,
        name: m['name'] as String,
        type: TransactionType.values.firstWhere(
          (e) => e.name == m['type'],
          orElse: () => TransactionType.expense,
        ),
        amount: (m['amount'] as num).toDouble(),
        categoryId: m['category_id'] as String,
        accountId: m['account_id'] as String,
        note: m['note'] as String?,
      );
}
