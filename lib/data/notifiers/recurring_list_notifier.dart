import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recurring_transaction_model.dart';
import '../repositories/recurring_repo.dart';

class RecurringListState {
  final List<RecurringTransactionModel> items;
  final List<RecurringTransactionModel> upcoming;
  final bool isLoading;
  final String? error;

  const RecurringListState({
    this.items = const [],
    this.upcoming = const [],
    this.isLoading = false,
    this.error,
  });

  RecurringListState copyWith({
    List<RecurringTransactionModel>? items,
    List<RecurringTransactionModel>? upcoming,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return RecurringListState(
      items: items ?? this.items,
      upcoming: upcoming ?? this.upcoming,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class RecurringListNotifier extends StateNotifier<RecurringListState> {
  RecurringListNotifier() : super(const RecurringListState()) {
    load();
  }

  final _repo = RecurringRepo();

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await _repo.getAll();
      final active = await _repo.getActive();
      active.sort((a, b) => a.nextDate.compareTo(b.nextDate));

      state = state.copyWith(
        items: items,
        upcoming: active.take(3).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addRecurring(RecurringTransactionModel item) async {
    try {
      await _repo.insert(item);
      await load();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> updateRecurring(RecurringTransactionModel item) async {
    try {
      await _repo.update(item);
      await load();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> deleteRecurring(String id) async {
    try {
      await _repo.delete(id);
      state = state.copyWith(
        items: state.items.where((i) => i.id != id).toList(),
        upcoming: state.upcoming.where((i) => i.id != id).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> toggleActive(String id) async {
    final item = state.items.where((i) => i.id == id).firstOrNull;
    if (item == null) return;

    try {
      final updated = item.copyWith(active: !item.active);
      await _repo.update(updated);
      await load();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }
}

final recurringListProvider =
    StateNotifierProvider<RecurringListNotifier, RecurringListState>(
  (ref) => RecurringListNotifier(),
);
