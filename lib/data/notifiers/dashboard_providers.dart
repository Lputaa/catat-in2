import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction_model.dart';
import '../models/account_model.dart';
import '../models/recurring_transaction_model.dart';
import '../models/savings_goal_model.dart';
import '../repositories/account_repo.dart';
import 'budget_list_notifier.dart';
import 'recurring_list_notifier.dart';
import 'savings_list_notifier.dart';
import 'transaction_list_notifier.dart';

// ── Accounts (FutureProvider - still needed for account list) ──
final accountsProvider = FutureProvider<List<AccountModel>>((ref) {
  return AccountRepo().getAll();
});

// ── Account Balances (computed from transactions) ──
final accountBalancesProvider = Provider<Map<String, double>>((ref) {
  final transactions = ref.watch(transactionListProvider).transactions;
  final accounts = ref.watch(accountsProvider).valueOrNull ?? [];

  final balances = <String, double>{};
  for (final acc in accounts) {
    double balance = acc.initialBalance;
    for (final tx in transactions) {
      if (tx.accountId == acc.id) {
        if (tx.type == TransactionType.income) {
          balance += tx.amount;
        } else {
          balance -= tx.amount;
        }
      }
    }
    balances[acc.id] = balance;
  }
  return balances;
});

// ── Total Balance (computed from account balances) ──
final totalBalanceProvider = Provider<double>((ref) {
  final balances = ref.watch(accountBalancesProvider);
  return balances.values.fold<double>(0, (sum, b) => sum + b);
});

// ── Recent Transactions (today only, newest first) ──
final recentTransactionsProvider = Provider<List<TransactionModel>>((ref) {
  final transactions = ref.watch(transactionListProvider).transactions;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));

  // Filter today's transactions only
  final todayTxs = transactions.where((tx) {
    return tx.date.isAfter(today.subtract(const Duration(milliseconds: 1))) &&
        tx.date.isBefore(tomorrow);
  }).toList();

  // Sort newest first
  todayTxs.sort((a, b) => b.date.compareTo(a.date));

  return todayTxs;
});

// ── Month Summary (computed from transactions) ──
final monthSummaryProvider = Provider<Map<String, double>>((ref) {
  final transactions = ref.watch(transactionListProvider).transactions;
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, 1);
  final end = DateTime(now.year, now.month + 1, 1);

  double income = 0;
  double expense = 0;

  for (final tx in transactions) {
    if (tx.date.isAfter(start.subtract(const Duration(days: 1))) &&
        tx.date.isBefore(end)) {
      if (tx.type == TransactionType.income) {
        income += tx.amount;
      } else {
        expense += tx.amount;
      }
    }
  }

  return {'income': income, 'expense': expense};
});

// ── Budget Overview (Provider - watches BudgetListNotifier) ──
final budgetOverviewProvider = Provider<List<BudgetWithDetails>>((ref) {
  // Watch both budget list and transactions for updates
  ref.watch(budgetListProvider);
  ref.watch(transactionListProvider);
  return ref.watch(budgetListProvider).details;
});

// ── Upcoming Recurring (Provider - watches RecurringListNotifier) ──
final upcomingRecurringProvider = Provider<List<RecurringTransactionModel>>((ref) {
  return ref.watch(recurringListProvider).upcoming;
});

// ── Savings Goals (Provider - watches SavingsListNotifier) ──
final savingsGoalsDashboardProvider = Provider<List<SavingsGoalModel>>((ref) {
  return ref.watch(savingsListProvider).goals;
});
