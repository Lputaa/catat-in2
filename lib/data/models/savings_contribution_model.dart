class SavingsContributionModel {
  final String id;
  final String goalId;
  final double amount;
  final DateTime date;
  final String? note;

  const SavingsContributionModel({
    required this.id,
    required this.goalId,
    required this.amount,
    required this.date,
    this.note,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'goal_id': goalId,
        'amount': amount,
        'date': date.millisecondsSinceEpoch,
        'note': note,
      };

  factory SavingsContributionModel.fromMap(Map<String, dynamic> m) =>
      SavingsContributionModel(
        id: m['id'] as String,
        goalId: m['goal_id'] as String,
        amount: (m['amount'] as num).toDouble(),
        date: DateTime.fromMillisecondsSinceEpoch(m['date'] as int),
        note: m['note'] as String?,
      );
}
