class SavingsGoalModel {
  final String id;
  final String name;
  final double targetAmount;
  final double savedAmount;
  final DateTime? deadline;
  final String? accountId;

  const SavingsGoalModel({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.savedAmount,
    this.deadline,
    this.accountId,
  });

  double get percent => targetAmount > 0 ? savedAmount / targetAmount : 0;
  bool get isComplete => savedAmount >= targetAmount;
  double get remaining => targetAmount - savedAmount;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'target_amount': targetAmount,
        'saved_amount': savedAmount,
        'deadline': deadline?.millisecondsSinceEpoch,
        'account_id': accountId,
      };

  factory SavingsGoalModel.fromMap(Map<String, dynamic> m) => SavingsGoalModel(
        id: m['id'] as String,
        name: m['name'] as String,
        targetAmount: (m['target_amount'] as num).toDouble(),
        savedAmount: (m['saved_amount'] as num).toDouble(),
        deadline: m['deadline'] != null
            ? DateTime.fromMillisecondsSinceEpoch(m['deadline'] as int)
            : null,
        accountId: m['account_id'] as String?,
      );

  SavingsGoalModel copyWith({
    String? id,
    String? name,
    double? targetAmount,
    double? savedAmount,
    DateTime? deadline,
    String? accountId,
  }) =>
      SavingsGoalModel(
        id: id ?? this.id,
        name: name ?? this.name,
        targetAmount: targetAmount ?? this.targetAmount,
        savedAmount: savedAmount ?? this.savedAmount,
        deadline: deadline ?? this.deadline,
        accountId: accountId ?? this.accountId,
      );
}
