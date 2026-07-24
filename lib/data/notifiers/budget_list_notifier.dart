import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/budget_model.dart';
import '../models/category_model.dart';
import '../repositories/budget_repo.dart';
import '../repositories/category_repo.dart';
import '../repositories/transaction_repo.dart';

class BudgetWithDetails {
  final BudgetModel budget;
  final CategoryModel category;
  final double spent;

  BudgetWithDetails({
    required this.budget,
    required this.category,
    required this.spent,
  });

  double get percent => budget.limitAmount > 0 ? spent / budget.limitAmount : 0;
  bool get isOver => percent > 1.0;
  bool get isWarning => percent >= 0.8 && percent <= 1.0;
}

class BudgetListState {
  final List<BudgetModel> budgets;
  final List<BudgetWithDetails> details;
  final bool isLoading;
  final String? error;

  const BudgetListState({
    this.budgets = const [],
    this.details = const [],
    this.isLoading = false,
    this.error,
  });

  BudgetListState copyWith({
    List<BudgetModel>? budgets,
    List<BudgetWithDetails>? details,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return BudgetListState(
      budgets: budgets ?? this.budgets,
      details: details ?? this.details,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class BudgetListNotifier extends StateNotifier<BudgetListState> {
  BudgetListNotifier() : super(const BudgetListState()) {
    load();
  }

  final _repo = BudgetRepo();
  final _catRepo = CategoryRepo();
  final _txRepo = TransactionRepo();

  DateTime _currentMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  DateTime get currentMonth => _currentMonth;

  void setMonth(DateTime month) {
    _currentMonth = month;
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final budgets = await _repo.getByMonth(
        _currentMonth.year,
        _currentMonth.month,
      );

      final details = <BudgetWithDetails>[];
      for (final b in budgets) {
        final cat = await _catRepo.getById(b.categoryId);
        if (cat == null) continue;
        final spent = await _txRepo.getCategoryTotal(
          b.categoryId,
          b.year,
          b.month,
        );
        details.add(BudgetWithDetails(budget: b, category: cat, spent: spent));
      }
      details.sort((a, b) => b.percent.compareTo(a.percent));

      state = state.copyWith(
        budgets: budgets,
        details: details,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addBudget(BudgetModel budget) async {
    try {
      await _repo.insert(budget);
      await load(); // Reload to get updated details
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> updateBudget(BudgetModel budget) async {
    try {
      await _repo.update(budget);
      await load();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> deleteBudget(String id) async {
    try {
      await _repo.delete(id);
      state = state.copyWith(
        budgets: state.budgets.where((b) => b.id != id).toList(),
        details: state.details.where((d) => d.budget.id != id).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<List<CategoryModel>> getAvailableCategories() async {
    final cats = await _catRepo.getByType(CategoryType.expense);
    final existingIds = state.budgets.map((b) => b.categoryId).toSet();
    return cats.where((c) => !existingIds.contains(c.id)).toList();
  }
}

final budgetListProvider =
    StateNotifierProvider<BudgetListNotifier, BudgetListState>(
  (ref) => BudgetListNotifier(),
);
