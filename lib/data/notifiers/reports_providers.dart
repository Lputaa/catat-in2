import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../repositories/category_repo.dart';
import 'transaction_list_notifier.dart';

// ── Report View (mode tampilan laporan) ──
enum ReportView { monthly, overview }

final reportViewProvider = StateProvider<ReportView>(
  (ref) => ReportView.monthly,
);

// ── Selected Month (tab Bulanan, selalu tanggal 1) ──
final reportSelectedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

// ── Selected Year (tab Ringkasan) ──
final reportSelectedYearProvider = StateProvider<int>(
  (ref) => DateTime.now().year,
);

// ── Flow Filter untuk chart tren (Semua / Masuk / Keluar) ──
enum FlowFilter { all, income, expense }

final reportFlowFilterProvider = StateProvider<FlowFilter>(
  (ref) => FlowFilter.all,
);

// ── Categories Map ──
final reportCategoriesProvider = FutureProvider<Map<String, CategoryModel>>((
  ref,
) async {
  final cats = await CategoryRepo().getAll();
  return {for (final c in cats) c.id: c};
});

// ── Transactions for Reports ──
final reportTransactionsProvider = Provider<List<TransactionModel>>((ref) {
  return ref.watch(transactionListProvider).transactions;
});

// ── Helper: total masuk/keluar dalam rentang [start, end) ──
Map<String, double> _sumFlow(
  List<TransactionModel> transactions,
  DateTime start,
  DateTime end,
) {
  double income = 0;
  double expense = 0;

  for (final tx in transactions) {
    if (!tx.date.isBefore(start) && tx.date.isBefore(end)) {
      if (tx.type == TransactionType.income) {
        income += tx.amount;
      } else if (tx.type == TransactionType.expense) {
        expense += tx.amount;
      }
    }
  }

  return {'income': income, 'expense': expense};
}

// ── Cashflow Summary (bulan terpilih) ──
final reportCashflowProvider = Provider<Map<String, double>>((ref) {
  final transactions = ref.watch(reportTransactionsProvider);
  final month = ref.watch(reportSelectedMonthProvider);
  final start = DateTime(month.year, month.month, 1);
  final end = DateTime(month.year, month.month + 1, 1);
  return _sumFlow(transactions, start, end);
});

// ── Cashflow Summary (tahun terpilih, untuk tab Ringkasan) ──
final reportYearCashflowProvider = Provider<Map<String, double>>((ref) {
  final transactions = ref.watch(reportTransactionsProvider);
  final year = ref.watch(reportSelectedYearProvider);
  return _sumFlow(transactions, DateTime(year, 1, 1), DateTime(year + 1, 1, 1));
});

// ── Trend Data Point ──
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

const _monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

// ── Tren harian untuk bulan terpilih (tab Bulanan) ──
final reportMonthTrendProvider = Provider<List<TrendDataPoint>>((ref) {
  final transactions = ref.watch(reportTransactionsProvider);
  final month = ref.watch(reportSelectedMonthProvider);
  final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
  final result = <TrendDataPoint>[];

  for (int i = 0; i < daysInMonth; i++) {
    final day = DateTime(month.year, month.month, i + 1);
    final nextDay = DateTime(month.year, month.month, i + 2);
    final flow = _sumFlow(transactions, day, nextDay);

    result.add(
      TrendDataPoint(
        label: '${i + 1}',
        income: flow['income']!,
        expense: flow['expense']!,
      ),
    );
  }

  return result;
});

// ── Tren bulanan untuk tahun terpilih (tab Ringkasan) ──
final reportYearTrendProvider = Provider<List<TrendDataPoint>>((ref) {
  final transactions = ref.watch(reportTransactionsProvider);
  final year = ref.watch(reportSelectedYearProvider);
  final result = <TrendDataPoint>[];

  for (int i = 0; i < 12; i++) {
    final flow = _sumFlow(
      transactions,
      DateTime(year, i + 1, 1),
      DateTime(year, i + 2, 1),
    );

    result.add(
      TrendDataPoint(
        label: _monthNames[i],
        income: flow['income']!,
        expense: flow['expense']!,
      ),
    );
  }

  return result;
});

// ── Category Breakdown (bulan terpilih) ──
final reportCategoryBreakdownProvider = Provider<Map<String, double>>((ref) {
  final transactions = ref.watch(reportTransactionsProvider);
  final month = ref.watch(reportSelectedMonthProvider);
  final start = DateTime(month.year, month.month, 1);
  final end = DateTime(month.year, month.month + 1, 1);

  final breakdown = <String, double>{};

  for (final tx in transactions) {
    if (tx.type == TransactionType.expense &&
        !tx.date.isBefore(start) &&
        tx.date.isBefore(end)) {
      breakdown[tx.categoryId] = (breakdown[tx.categoryId] ?? 0) + tx.amount;
    }
  }

  return breakdown;
});

// ── Monthly Comparison (bar chart, 6 bulan terakhir) ──
class MonthlyComparisonPoint {
  final String label;
  final double income;
  final double expense;

  const MonthlyComparisonPoint({
    required this.label,
    required this.income,
    required this.expense,
  });
}

final reportMonthlyComparisonProvider = Provider<List<MonthlyComparisonPoint>>((
  ref,
) {
  final transactions = ref.watch(reportTransactionsProvider);
  final now = DateTime.now();
  final result = <MonthlyComparisonPoint>[];

  for (int i = 5; i >= 0; i--) {
    final start = DateTime(now.year, now.month - i, 1);
    final end = DateTime(now.year, now.month - i + 1, 1);
    final flow = _sumFlow(transactions, start, end);

    result.add(
      MonthlyComparisonPoint(
        label: _monthNames[start.month - 1],
        income: flow['income']!,
        expense: flow['expense']!,
      ),
    );
  }

  return result;
});

// ── Daily Heatmap (pengeluaran per hari, bulan terpilih) ──
final reportDailyHeatmapProvider = Provider<List<double>>((ref) {
  final transactions = ref.watch(reportTransactionsProvider);
  final month = ref.watch(reportSelectedMonthProvider);
  final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
  final totals = List<double>.filled(daysInMonth, 0);

  for (final tx in transactions) {
    if (tx.type == TransactionType.expense &&
        tx.date.year == month.year &&
        tx.date.month == month.month) {
      totals[tx.date.day - 1] += tx.amount;
    }
  }

  return totals;
});

// ── Daily Average (rata-rata pengeluaran harian, bulan terpilih) ──
final reportDailyAverageProvider = Provider<double>((ref) {
  final daily = ref.watch(reportDailyHeatmapProvider);
  final month = ref.watch(reportSelectedMonthProvider);
  final now = DateTime.now();
  final isCurrentMonth = month.year == now.year && month.month == now.month;

  // Bulan berjalan: bagi hari yang sudah lewat; bulan lampau: bagi jumlah hari
  final divisor = isCurrentMonth ? now.day : daily.length;
  if (divisor == 0) return 0;
  final total = daily.take(divisor).fold<double>(0, (a, b) => a + b);
  return total / divisor;
});

// ── Top 5 Kategori (bulan terpilih) ──
final reportTopCategoriesProvider = Provider<List<MapEntry<String, double>>>((
  ref,
) {
  final breakdown = ref.watch(reportCategoryBreakdownProvider);
  final entries = breakdown.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return entries.take(5).toList();
});
