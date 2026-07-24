enum RecurrenceFrequency { daily, weekly, monthly, yearly }

class RecurringTransactionModel {
  final String id;
  final String transactionType;   // 'income' or 'expense'
  final double amount;
  final String categoryId;
  final String accountId;
  final String? note;
  final RecurrenceFrequency frequency;
  final DateTime startDate;
  final DateTime nextDate;
  final bool autoRecord;          // true = auto-create, false = manual confirm
  final bool active;

  const RecurringTransactionModel({
    required this.id,
    required this.transactionType,
    required this.amount,
    required this.categoryId,
    required this.accountId,
    this.note,
    required this.frequency,
    required this.startDate,
    required this.nextDate,
    this.autoRecord = false,
    this.active = true,
  });

  String get frequencyLabel {
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return 'Harian';
      case RecurrenceFrequency.weekly:
        return 'Mingguan';
      case RecurrenceFrequency.monthly:
        return 'Bulanan';
      case RecurrenceFrequency.yearly:
        return 'Tahunan';
    }
  }

  /// Calculate next date after current nextDate
  DateTime calculateNextDate() {
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return nextDate.add(const Duration(days: 1));
      case RecurrenceFrequency.weekly:
        return nextDate.add(const Duration(days: 7));
      case RecurrenceFrequency.monthly:
        return DateTime(nextDate.year, nextDate.month + 1, nextDate.day);
      case RecurrenceFrequency.yearly:
        return DateTime(nextDate.year + 1, nextDate.month, nextDate.day);
    }
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'transaction_type': transactionType,
        'amount': amount,
        'category_id': categoryId,
        'account_id': accountId,
        'note': note,
        'frequency': frequency.name,
        'start_date': startDate.millisecondsSinceEpoch,
        'next_date': nextDate.millisecondsSinceEpoch,
        'auto_record': autoRecord ? 1 : 0,
        'active': active ? 1 : 0,
      };

  factory RecurringTransactionModel.fromMap(Map<String, dynamic> m) =>
      RecurringTransactionModel(
        id: m['id'] as String,
        transactionType: m['transaction_type'] as String,
        amount: (m['amount'] as num).toDouble(),
        categoryId: m['category_id'] as String,
        accountId: m['account_id'] as String,
        note: m['note'] as String?,
        frequency: RecurrenceFrequency.values.firstWhere(
          (e) => e.name == m['frequency'],
          orElse: () => RecurrenceFrequency.monthly,
        ),
        startDate: DateTime.fromMillisecondsSinceEpoch(m['start_date'] as int),
        nextDate: DateTime.fromMillisecondsSinceEpoch(m['next_date'] as int),
        autoRecord: (m['auto_record'] as int) == 1,
        active: (m['active'] as int) == 1,
      );

  RecurringTransactionModel copyWith({
    String? id,
    String? transactionType,
    double? amount,
    String? categoryId,
    String? accountId,
    String? note,
    RecurrenceFrequency? frequency,
    DateTime? startDate,
    DateTime? nextDate,
    bool? autoRecord,
    bool? active,
  }) =>
      RecurringTransactionModel(
        id: id ?? this.id,
        transactionType: transactionType ?? this.transactionType,
        amount: amount ?? this.amount,
        categoryId: categoryId ?? this.categoryId,
        accountId: accountId ?? this.accountId,
        note: note ?? this.note,
        frequency: frequency ?? this.frequency,
        startDate: startDate ?? this.startDate,
        nextDate: nextDate ?? this.nextDate,
        autoRecord: autoRecord ?? this.autoRecord,
        active: active ?? this.active,
      );
}
