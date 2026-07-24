import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/savings_goal_model.dart';
import '../models/savings_contribution_model.dart';
import '../repositories/savings_goal_repo.dart';

class SavingsListState {
  final List<SavingsGoalModel> goals;
  final bool isLoading;
  final String? error;

  const SavingsListState({
    this.goals = const [],
    this.isLoading = false,
    this.error,
  });

  SavingsListState copyWith({
    List<SavingsGoalModel>? goals,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return SavingsListState(
      goals: goals ?? this.goals,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class SavingsListNotifier extends StateNotifier<SavingsListState> {
  SavingsListNotifier() : super(const SavingsListState()) {
    load();
  }

  final _repo = SavingsGoalRepo();

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final goals = await _repo.getAll();
      state = state.copyWith(goals: goals, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addGoal(SavingsGoalModel goal) async {
    try {
      await _repo.insert(goal);
      await load();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> updateGoal(SavingsGoalModel goal) async {
    try {
      await _repo.update(goal);
      await load();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> deleteGoal(String id) async {
    try {
      await _repo.delete(id);
      state = state.copyWith(
        goals: state.goals.where((g) => g.id != id).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> addContribution(SavingsContributionModel contribution) async {
    try {
      await _repo.addContribution(contribution);
      await load();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }
}

final savingsListProvider =
    StateNotifierProvider<SavingsListNotifier, SavingsListState>(
  (ref) => SavingsListNotifier(),
);
