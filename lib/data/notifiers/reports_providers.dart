import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../models/account_model.dart';
import '../repositories/category_repo.dart';
import '../repositories/account_repo.dart';
import 'transaction_list_notifier.dart';

// ── Report Period ──
enum ReportPeriod { week, month, year }

final reportPeriodProvider =
    StateProvider<ReportPeriod>((ref) => ReportPeriod.month);

// ── Account Filter ──
final reportAccountFilterProvider = StateProvider<String?>((ref) => null);

// ── Category Filter (for chart) ──
final reportCategoryFilterProvider = StateProvider<String?>((ref) => null);

// ── Accounts List ──
final reportAccountsProvider = FutureProvider<List<AccountModel>>((ref) {
  return AccountRepo().getAll();
});

// ── Categories Map ──
final reportCategoriesProvider =
    FutureProvider<Map<String, CategoryModel>>((ref) async {
  final cats = await CategoryRepo().getAll();
  return {for (final c in cats) c.id: c};
});

// ── Categories List ──
final reportCategoriesListProvider =
    FutureProvider<List<CategoryModel>>((ref) async {
  return CategoryRepo().getAll();
});

// ── Filtered Transactions for Reports (account filter only) ──
final reportTransactionsProvider = Provider<List<TransactionModel>>((ref) {
  final transactions = ref.watch(transactionListProvider).transactions;
  final accountFilter = ref.watch(reportAccountFilterProvider);

  if (accountFilter == null) return transactions;
  return transactions.where((tx) => tx.accountId == accountFilter).toList();
});

// ── Filtered Transactions for Trend Chart (account + category filter) ──
final reportTrendTransactionsProvider =
    Provider<List<TransactionModel>>((ref) {
  final transactions = ref.watch(reportTransactionsProvider);
  final categoryFilter = ref.watch(reportCategoryFilterProvider);

  if (categoryFilter == null) return transactions;
  return transactions.where((tx) => tx.categoryId == categoryFilter).toList();
});

// ── Cashflow Summary (computed) ──
final reportCashflowProvider = Provider<Map<String, double>>((ref) {
  final transactions = ref.watch(reportTransactionsProvider);
  final period = ref.watch(reportPeriodProvider);
  final now = DateTime.now();

  DateTime start;
  DateTime end;

  switch (period) {
    case ReportPeriod.week:
      start = now.subtract(Duration(days: now.weekday - 1));
      start = DateTime(start.year, start.month, start.day);
      end = start.add(const Duration(days: 7));
      break;
    case ReportPeriod.month:
      start = DateTime(now.year, now.month, 1);
      end = DateTime(now.year, now.month + 1, 1);
      break;
    case ReportPeriod.year:
      start = DateTime(now.year, 1, 1);
      end = DateTime(now.year + 1, 1, 1);
      break;
  }

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

// ── Chart Period Offset (for navigation) ──
final chartPeriodOffsetProvider = StateProvider<int>((ref) => 0);

// ── Trend Data for Chart (computed based on period) ──
class TrendDataPoint {
  final String label;
  final double income;
  final double expense;

  const TrendDataPoint({
    required this.label,
    required this.income,
    required this.expense,
  });
}

final reportTrendProvider = Provider<List<TrendDataPoint>>((ref) {
  final transactions = ref.watch(reportTrendTransactionsProvider);
  final period = ref.watch(reportPeriodProvider);
  final offset = ref.watch(chartPeriodOffsetProvider);
  final now = DateTime.now();

  switch (period) {
    case ReportPeriod.week:
      return _getWeekTrend(transactions, now, offset);
    case ReportPeriod.month:
      return _getMonthTrend(transactions, now, offset);
    case ReportPeriod.year:
      return _getYearTrend(transactions, now, offset);
  }
});

List<TrendDataPoint> _getWeekTrend(
    List<TransactionModel> transactions, DateTime now, int offset) {
  final weekStart = now.subtract(Duration(days: now.weekday - 1 + (offset * 7)));
  final start = DateTime(weekStart.year, weekStart.month, weekStart.day);

  final dayNames = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
  final result = <TrendDataPoint>[];

  for (int i = 0; i < 7; i++) {
    final day = start.add(Duration(days: i));
    final nextDay = day.add(const Duration(days: 1));
    double income = 0, expense = 0;

    for (final tx in transactions) {
      if (tx.date.isAfter(day.subtract(const Duration(milliseconds: 1))) &&
          tx.date.isBefore(nextDay)) {
        if (tx.type == TransactionType.income) {
          income += tx.amount;
        } else {
          expense += tx.amount;
        }
      }
    }

    result.add(TrendDataPoint(
      label: dayNames[i],
      income: income,
      expense: expense,
    ));
  }

  return result;
}

List<TrendDataPoint> _getMonthTrend(
    List<TransactionModel> transactions, DateTime now, int offset) {
  final targetMonth = DateTime(now.year, now.month + offset, 1);
  final daysInMonth = DateTime(targetMonth.year, targetMonth.month + 1, 0).day;
  final start = targetMonth;

  final result = <TrendDataPoint>[];

  for (int i = 0; i < daysInMonth; i++) {
    final day = start.add(Duration(days: i));
    final nextDay = day.add(const Duration(days: 1));
    double income = 0, expense = 0;

    for (final tx in transactions) {
      if (tx.date.isAfter(day.subtract(const Duration(milliseconds: 1))) &&
          tx.date.isBefore(nextDay)) {
        if (tx.type == TransactionType.income) {
          income += tx.amount;
        } else {
          expense += tx.amount;
        }
      }
    }

    result.add(TrendDataPoint(
      label: '${i + 1}',
      income: income,
      expense: expense,
    ));
  }

  return result;
}

List<TrendDataPoint> _getYearTrend(
    List<TransactionModel> transactions, DateTime now, int offset) {
  final targetYear = now.year + offset;
  final monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
  ];
  final result = <TrendDataPoint>[];

  for (int i = 0; i < 12; i++) {
    final start = DateTime(targetYear, i + 1, 1);
    final end = DateTime(targetYear, i + 2, 1);
    double income = 0, expense = 0;

    for (final tx in transactions) {
      if (tx.date.isAfter(start.subtract(const Duration(milliseconds: 1))) &&
          tx.date.isBefore(end)) {
        if (tx.type == TransactionType.income) {
          income += tx.amount;
        } else {
          expense += tx.amount;
        }
      }
    }
    result.add(TrendDataPoint(
      label: monthNames[i],
      income: income,
      expense: expense,
    ));
  }

  return result;
}

// ── Category Breakdown (computed) ──
final reportCategoryBreakdownProvider =
    Provider<Map<String, double>>((ref) {
  final transactions = ref.watch(reportTransactionsProvider);
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, 1);
  final end = DateTime(now.year, now.month + 1, 1);

  final breakdown = <String, double>{};

  for (final tx in transactions) {
    if (tx.type == TransactionType.expense &&
        tx.date.isAfter(start.subtract(const Duration(days: 1))) &&
        tx.date.isBefore(end)) {
      breakdown[tx.categoryId] =
          (breakdown[tx.categoryId] ?? 0) + tx.amount;
    }
  }

  return breakdown;
});
