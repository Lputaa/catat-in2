import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction_model.dart';
import '../models/transaction_filter_model.dart';
import '../repositories/transaction_repo.dart';

class TransactionListState {
  final List<TransactionModel> transactions;
  final TransactionFilterState filter;
  final bool isLoading;
  final String? error;

  const TransactionListState({
    this.transactions = const [],
    this.filter = const TransactionFilterState(),
    this.isLoading = false,
    this.error,
  });

  TransactionListState copyWith({
    List<TransactionModel>? transactions,
    TransactionFilterState? filter,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return TransactionListState(
      transactions: transactions ?? this.transactions,
      filter: filter ?? this.filter,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  // Computed: filtered + sorted list
  List<TransactionModel> get filteredList {
    var list = List<TransactionModel>.from(transactions);

    // Apply type filter
    if (filter.typeFilter != TransactionTypeFilter.all) {
      list = list.where((tx) {
        if (filter.typeFilter == TransactionTypeFilter.income) {
          return tx.type == TransactionType.income;
        }
        return tx.type == TransactionType.expense;
      }).toList();
    }

    // Apply date range filter
    if (filter.dateRange != null) {
      final start = filter.dateRange!.start;
      final end = filter.dateRange!.end;
      list = list.where((tx) {
        return tx.date.isAfter(start.subtract(const Duration(days: 1))) &&
            tx.date.isBefore(end.add(const Duration(days: 1)));
      }).toList();
    }

    // Apply account filter
    if (filter.accountId != null) {
      list = list.where((tx) => tx.accountId == filter.accountId).toList();
    }

    // Apply search filter
    if (filter.searchQuery.isNotEmpty) {
      final query = filter.searchQuery.toLowerCase();
      list = list.where((tx) {
        return (tx.note?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Apply sort
    switch (filter.sortOrder) {
      case SortOrder.newest:
        list.sort((a, b) => b.date.compareTo(a.date));
        break;
      case SortOrder.oldest:
        list.sort((a, b) => a.date.compareTo(b.date));
        break;
      case SortOrder.largest:
        list.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case SortOrder.smallest:
        list.sort((a, b) => a.amount.compareTo(b.amount));
        break;
    }

    return list;
  }

  // Summary computed
  double get totalIncome {
    return filteredList
        .where((tx) => tx.type == TransactionType.income)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  double get totalExpense {
    return filteredList
        .where((tx) => tx.type == TransactionType.expense)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  double get totalNet => totalIncome - totalExpense;
}

class TransactionListNotifier extends StateNotifier<TransactionListState> {
  TransactionListNotifier() : super(const TransactionListState()) {
    _loadInitial();
  }

  final _repo = TransactionRepo();

  Future<void> _loadInitial() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final transactions = await _repo.getAll();
      final now = DateTime.now();
      state = state.copyWith(
        transactions: transactions,
        isLoading: false,
        filter: state.filter.copyWith(
          dateRange: DateTimeRange(
            start: DateTime(now.year, now.month, 1),
            end: DateTime(now.year, now.month + 1, 0),
          ),
        ),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ── Filter Methods ──

  void setTypeFilter(TransactionTypeFilter type) {
    state = state.copyWith(filter: state.filter.copyWith(typeFilter: type));
  }

  void setDateRange(DateTimeRange? range) {
    state = state.copyWith(
      filter: state.filter.copyWith(
        dateRange: range,
        clearDateRange: range == null,
      ),
    );
  }

  // ── Monthly Period Navigation ──

  /// Scope the list to the full calendar month that contains [month].
  void setMonthPeriod(DateTime month) {
    state = state.copyWith(
      filter: state.filter.copyWith(
        dateRange: DateTimeRange(
          start: DateTime(month.year, month.month, 1),
          end: DateTime(month.year, month.month + 1, 0),
        ),
      ),
    );
  }

  void previousMonth() {
    final anchor = state.filter.dateRange?.start ?? DateTime.now();
    setMonthPeriod(DateTime(anchor.year, anchor.month - 1, 1));
  }

  void nextMonth() {
    final anchor = state.filter.dateRange?.start ?? DateTime.now();
    setMonthPeriod(DateTime(anchor.year, anchor.month + 1, 1));
  }

  void goToCurrentMonth() => setMonthPeriod(DateTime.now());

  void setAccount(String? accountId) {
    state = state.copyWith(
      filter: state.filter.copyWith(
        accountId: accountId,
        clearAccount: accountId == null,
      ),
    );
  }

  void setSortOrder(SortOrder sort) {
    state = state.copyWith(filter: state.filter.copyWith(sortOrder: sort));
  }

  void setSearchQuery(String query) {
    state = state.copyWith(filter: state.filter.copyWith(searchQuery: query));
  }

  void applyFilter(TransactionFilterState filter) {
    state = state.copyWith(filter: filter);
  }

  void resetFilter() {
    final now = DateTime.now();
    state = state.copyWith(
      filter: TransactionFilterState(
        dateRange: DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 0),
        ),
      ),
    );
  }

  // ── CRUD Methods (Sync Update) ──

  Future<void> addTransaction(TransactionModel tx) async {
    try {
      // DB first
      await _repo.insert(tx);
      // Then state (optimistic - add to front since newest)
      state = state.copyWith(transactions: [tx, ...state.transactions]);
    } catch (e) {
      // Rollback: refetch from DB
      await _refreshFromDb();
      rethrow;
    }
  }

  Future<void> updateTransaction(TransactionModel tx) async {
    try {
      // DB first
      await _repo.update(tx);
      // Then state (replace in list)
      final updated = state.transactions.map((t) {
        return t.id == tx.id ? tx : t;
      }).toList();
      state = state.copyWith(transactions: updated);
    } catch (e) {
      // Rollback: refetch from DB
      await _refreshFromDb();
      rethrow;
    }
  }

  Future<void> deleteTransaction(String id) async {
    // Backup for undo
    final backup = state.transactions;

    try {
      // Optimistic: remove from state first
      state = state.copyWith(
        transactions: state.transactions.where((tx) => tx.id != id).toList(),
      );
      // Then DB
      await _repo.delete(id);
    } catch (e) {
      // Rollback on error
      state = state.copyWith(transactions: backup);
      rethrow;
    }
  }

  Future<void> undoDelete(TransactionModel tx) async {
    try {
      // DB first
      await _repo.insert(tx);
      // Then state (add back)
      state = state.copyWith(transactions: [tx, ...state.transactions]);
    } catch (e) {
      await _refreshFromDb();
      rethrow;
    }
  }

  Future<void> refresh() async {
    await _refreshFromDb();
  }

  Future<void> _refreshFromDb() async {
    try {
      final transactions = await _repo.getAll();
      state = state.copyWith(transactions: transactions, clearError: true);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

// ── Provider ──
final transactionListProvider =
    StateNotifierProvider<TransactionListNotifier, TransactionListState>(
      (ref) => TransactionListNotifier(),
    );

// Convenience providers for computed values
final filteredTransactionsProvider = Provider<List<TransactionModel>>((ref) {
  return ref.watch(transactionListProvider).filteredList;
});

final transactionSummaryProvider = Provider<TransactionSummary>((ref) {
  final state = ref.watch(transactionListProvider);
  return TransactionSummary(
    income: state.totalIncome,
    expense: state.totalExpense,
    net: state.totalNet,
  );
});

class TransactionSummary {
  final double income;
  final double expense;
  final double net;

  const TransactionSummary({
    required this.income,
    required this.expense,
    required this.net,
  });
}
