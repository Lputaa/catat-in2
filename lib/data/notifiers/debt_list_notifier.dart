import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/debt_model.dart';
import '../models/debt_payment_model.dart';
import '../repositories/debt_repo.dart';

class DebtListState {
  final List<DebtModel> debts;
  final bool isLoading;
  final String? error;

  const DebtListState({
    this.debts = const [],
    this.isLoading = false,
    this.error,
  });

  List<DebtModel> get hutang =>
      debts.where((d) => d.type == DebtType.hutang).toList();
  List<DebtModel> get piutang =>
      debts.where((d) => d.type == DebtType.piutang).toList();

  /// Remaining amount the user still owes (unsettled hutang).
  double get totalHutang =>
      hutang.fold<double>(0, (sum, d) => sum + d.remaining);

  /// Remaining amount others still owe the user (unsettled piutang).
  double get totalPiutang =>
      piutang.fold<double>(0, (sum, d) => sum + d.remaining);

  DebtListState copyWith({
    List<DebtModel>? debts,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return DebtListState(
      debts: debts ?? this.debts,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class DebtListNotifier extends StateNotifier<DebtListState> {
  DebtListNotifier() : super(const DebtListState()) {
    load();
  }

  final _repo = DebtRepo();

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final debts = await _repo.getAll();
      state = state.copyWith(debts: debts, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addDebt(DebtModel debt) async {
    try {
      await _repo.insert(debt);
      await load();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> updateDebt(DebtModel debt) async {
    try {
      await _repo.update(debt);
      await load();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> deleteDebt(String id) async {
    try {
      await _repo.delete(id);
      state = state.copyWith(
        debts: state.debts.where((d) => d.id != id).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> addPayment(DebtPaymentModel payment) async {
    try {
      await _repo.addPayment(payment);
      await load();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }
}

final debtListProvider = StateNotifierProvider<DebtListNotifier, DebtListState>(
  (ref) => DebtListNotifier(),
);
