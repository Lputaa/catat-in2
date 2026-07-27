class BudgetModel {
  final String id;
  final String categoryId;
  final double limitAmount;
  final int year;
  final int month;

  /// Carry positive leftover from last month into this month's limit.
  final bool rollover;

  const BudgetModel({
    required this.id,
    required this.categoryId,
    required this.limitAmount,
    required this.year,
    required this.month,
    this.rollover = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'category_id': categoryId,
    'limit_amount': limitAmount,
    'year': year,
    'month': month,
    'rollover': rollover ? 1 : 0,
  };

  factory BudgetModel.fromMap(Map<String, dynamic> m) => BudgetModel(
    id: m['id'] as String,
    categoryId: m['category_id'] as String,
    limitAmount: (m['limit_amount'] as num).toDouble(),
    year: m['year'] as int,
    month: m['month'] as int,
    rollover: (m['rollover'] as int? ?? 0) == 1,
  );

  BudgetModel copyWith({
    String? id,
    String? categoryId,
    double? limitAmount,
    int? year,
    int? month,
    bool? rollover,
  }) => BudgetModel(
    id: id ?? this.id,
    categoryId: categoryId ?? this.categoryId,
    limitAmount: limitAmount ?? this.limitAmount,
    year: year ?? this.year,
    month: month ?? this.month,
    rollover: rollover ?? this.rollover,
  );
}
