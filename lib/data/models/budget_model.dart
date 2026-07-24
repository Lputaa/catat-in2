class BudgetModel {
  final String id;
  final String categoryId;
  final double limitAmount;
  final int year;
  final int month;

  const BudgetModel({
    required this.id,
    required this.categoryId,
    required this.limitAmount,
    required this.year,
    required this.month,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'category_id': categoryId,
        'limit_amount': limitAmount,
        'year': year,
        'month': month,
      };

  factory BudgetModel.fromMap(Map<String, dynamic> m) => BudgetModel(
        id: m['id'] as String,
        categoryId: m['category_id'] as String,
        limitAmount: (m['limit_amount'] as num).toDouble(),
        year: m['year'] as int,
        month: m['month'] as int,
      );

  BudgetModel copyWith({
    String? id,
    String? categoryId,
    double? limitAmount,
    int? year,
    int? month,
  }) =>
      BudgetModel(
        id: id ?? this.id,
        categoryId: categoryId ?? this.categoryId,
        limitAmount: limitAmount ?? this.limitAmount,
        year: year ?? this.year,
        month: month ?? this.month,
      );
}
