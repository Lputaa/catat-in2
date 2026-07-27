import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/neo_brutal_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../data/notifiers/reports_providers.dart';
import '../../data/notifiers/transaction_list_notifier.dart';
import '../../shared/widgets/catat_in_app_bar.dart';
import '../../shared/widgets/neo_card.dart';
import '../../shared/widgets/neo_empty_state.dart';
import '../../shared/widgets/neo_segmented_control.dart';
import '../transactions/add_transaction_sheet.dart';
import 'report_insight_widgets.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(reportViewProvider);
    final txState = ref.watch(transactionListProvider);

    // No data at all — charts would be meaningless, guide user instead
    if (!txState.isLoading && txState.transactions.isEmpty) {
      return Scaffold(
        appBar: const CatatInAppBar(subtitle: 'Laporan'),
        body: NeoEmptyState(
          icon: Icons.bar_chart_rounded,
          title: 'Belum Ada Laporan',
          subtitle: 'Tambah transaksi dulu untuk lihat laporan keuanganmu',
          ctaLabel: 'Tambah Transaksi',
          onCta: () => AddTransactionSheet.show(context),
        ),
      );
    }

    return Scaffold(
      appBar: const CatatInAppBar(subtitle: 'Laporan'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mode laporan: analisis satu bulan vs ringkasan lintas waktu
            NeoSegmentedControl<ReportView>(
              segments: neoSegments([
                (ReportView.monthly, 'Bulanan'),
                (ReportView.overview, 'Ringkasan'),
              ]),
              selected: view,
              onChanged: (v) => ref.read(reportViewProvider.notifier).state = v,
            ),
            const SizedBox(height: 16),
            if (view == ReportView.monthly)
              const _MonthlyReportView()
            else
              const _OverviewReportView(),
          ],
        ),
      ),
    );
  }
}

// ── Tab BULANAN: analisis satu bulan, bisa navigasi mundur ──
class _MonthlyReportView extends ConsumerWidget {
  const _MonthlyReportView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(reportSelectedMonthProvider);
    final cashflow = ref.watch(reportCashflowProvider);
    final monthLabel = DateFormat('MMMM yyyy', 'id_ID').format(month);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Navigasi bulan — scope untuk SEMUA seksi di tab ini
        const _MonthNavigator(),
        const SizedBox(height: 20),

        // Cashflow bulan terpilih
        ReportSectionHeader(
          title: 'CASHFLOW ${monthLabel.toUpperCase()}',
          accent: NeoBrutalColors.success,
        ),
        const SizedBox(height: 12),
        _CashflowCards(cashflow: cashflow),
        const SizedBox(height: 12),
        const DailyAverageCard(),
        const SizedBox(height: 24),

        // Tren harian bulan terpilih
        const _MonthlyTrendSection(),
        const SizedBox(height: 24),

        // Heatmap pengeluaran harian (GitHub-style)
        ReportSectionHeader(
          title: 'HEATMAP PENGELUARAN',
          accent: NeoBrutalColors.danger,
          subtitle: 'Intensitas belanja harian • $monthLabel',
        ),
        const SizedBox(height: 12),
        const NeoCard(padding: EdgeInsets.all(16), child: SpendingHeatmap()),
        const SizedBox(height: 24),

        // Top 5 kategori pengeluaran
        ReportSectionHeader(
          title: 'TOP 5 KATEGORI',
          accent: NeoBrutalColors.yellow,
          subtitle: 'Pengeluaran terbesar $monthLabel',
        ),
        const SizedBox(height: 12),
        const NeoCard(padding: EdgeInsets.all(16), child: TopCategoriesCard()),
        const SizedBox(height: 24),

        // Category breakdown
        const _CategoryBreakdown(),
      ],
    );
  }
}

// ── Tab RINGKASAN: gambaran lintas waktu ──
class _OverviewReportView extends ConsumerWidget {
  const _OverviewReportView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final year = ref.watch(reportSelectedYearProvider);
    final cashflow = ref.watch(reportYearCashflowProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Navigasi tahun
        const _YearNavigator(),
        const SizedBox(height: 20),

        // Cashflow setahun
        ReportSectionHeader(
          title: 'CASHFLOW TAHUN $year',
          accent: NeoBrutalColors.success,
        ),
        const SizedBox(height: 12),
        _CashflowCards(cashflow: cashflow),
        const SizedBox(height: 24),

        // Tren bulanan setahun
        const _YearlyTrendSection(),
        const SizedBox(height: 24),

        // Bar chart: perbandingan bulan per bulan
        const ReportSectionHeader(
          title: 'PERBANDINGAN BULANAN',
          accent: NeoBrutalColors.secondary,
          subtitle: 'Masuk vs keluar, 6 bulan terakhir',
        ),
        const SizedBox(height: 12),
        const NeoCard(
          padding: EdgeInsets.all(16),
          child: MonthlyComparisonChart(),
        ),
      ],
    );
  }
}

// ── Month Navigator (scope tab Bulanan) ──
class _MonthNavigator extends ConsumerWidget {
  const _MonthNavigator();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(reportSelectedMonthProvider);
    final now = DateTime.now();
    final isCurrent = month.year == now.year && month.month == now.month;

    void goTo(DateTime target) {
      HapticFeedback.selectionClick();
      ref.read(reportSelectedMonthProvider.notifier).state = target;
    }

    return Row(
      children: [
        _NavButton(
          icon: Icons.chevron_left_rounded,
          onTap: () => goTo(DateTime(month.year, month.month - 1)),
        ),
        Expanded(
          child: Center(
            child: Text(
              DateFormat('MMMM yyyy', 'id_ID').format(month).toUpperCase(),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
        _NavButton(
          icon: Icons.chevron_right_rounded,
          enabled: !isCurrent,
          onTap: isCurrent
              ? null
              : () => goTo(DateTime(month.year, month.month + 1)),
        ),
        if (!isCurrent) ...[
          const SizedBox(width: 8),
          _NavButton(
            label: 'BULAN INI',
            color: NeoBrutalColors.primary,
            onTap: () => goTo(DateTime(now.year, now.month)),
          ),
        ],
      ],
    );
  }
}

// ── Year Navigator (scope tab Ringkasan) ──
class _YearNavigator extends ConsumerWidget {
  const _YearNavigator();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final year = ref.watch(reportSelectedYearProvider);
    final now = DateTime.now();
    final isCurrent = year == now.year;

    void goTo(int target) {
      HapticFeedback.selectionClick();
      ref.read(reportSelectedYearProvider.notifier).state = target;
    }

    return Row(
      children: [
        _NavButton(
          icon: Icons.chevron_left_rounded,
          onTap: () => goTo(year - 1),
        ),
        Expanded(
          child: Center(
            child: Text(
              'TAHUN $year',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
        _NavButton(
          icon: Icons.chevron_right_rounded,
          enabled: !isCurrent,
          onTap: isCurrent ? null : () => goTo(year + 1),
        ),
        if (!isCurrent) ...[
          const SizedBox(width: 8),
          _NavButton(
            label: 'TAHUN INI',
            color: NeoBrutalColors.primary,
            onTap: () => goTo(now.year),
          ),
        ],
      ],
    );
  }
}

// ── Cashflow Cards (redesign: blok warna solid khas Neo-Brutal) ──
class _CashflowCards extends StatelessWidget {
  const _CashflowCards({required this.cashflow});

  final Map<String, double> cashflow;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    final income = cashflow['income'] ?? 0;
    final expense = cashflow['expense'] ?? 0;
    final net = income - expense;
    final isSurplus = net >= 0;
    final usedPct = income > 0 ? (expense / income * 100) : null;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _FlowStatCard(
                label: 'MASUK',
                icon: Icons.south_west_rounded,
                value: formatter.format(income),
                fill: NeoBrutalColors.success,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _FlowStatCard(
                label: 'KELUAR',
                icon: Icons.north_east_rounded,
                value: formatter.format(expense),
                fill: NeoBrutalColors.danger,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // NET card — blok besar dengan badge status & bar rasio
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSurplus ? NeoBrutalColors.yellow : NeoBrutalColors.danger,
            border: Border.all(
              color: NeoBrutalColors.ink,
              width: AppConstants.borderPrimary,
            ),
            boxShadow: const [
              BoxShadow(color: NeoBrutalColors.ink, offset: Offset(4, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'SISA (NET)',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: isSurplus ? NeoBrutalColors.ink : Colors.white,
                      ),
                    ),
                  ),
                  // Badge status
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: NeoBrutalColors.ink, width: 2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSurplus
                              ? Icons.thumb_up_alt_rounded
                              : Icons.warning_amber_rounded,
                          size: 12,
                          color: isSurplus
                              ? NeoBrutalColors.success
                              : NeoBrutalColors.danger,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isSurplus ? 'SURPLUS' : 'DEFISIT',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color: NeoBrutalColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '${isSurplus ? '+' : ''}${formatter.format(net)}',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: isSurplus ? NeoBrutalColors.ink : Colors.white,
                  ),
                ),
              ),
              if (usedPct != null) ...[
                const SizedBox(height: 10),
                // Bar rasio: berapa persen pemasukan yang terpakai
                Stack(
                  children: [
                    Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: NeoBrutalColors.ink,
                          width: 2,
                        ),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: (usedPct / 100).clamp(0.0, 1.0),
                      child: Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: isSurplus ? NeoBrutalColors.ink : Colors.white,
                          border: Border.all(
                            color: NeoBrutalColors.ink,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  usedPct > 100
                      ? 'PENGELUARAN ${usedPct.toStringAsFixed(0)}% DARI PEMASUKAN!'
                      : '${usedPct.toStringAsFixed(0)}% PEMASUKAN TERPAKAI',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: isSurplus ? NeoBrutalColors.ink : Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _FlowStatCard extends StatelessWidget {
  const _FlowStatCard({
    required this.label,
    required this.icon,
    required this.value,
    required this.fill,
  });

  final String label;
  final IconData icon;
  final String value;
  final Color fill;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: fill,
        border: Border.all(
          color: NeoBrutalColors.ink,
          width: AppConstants.borderPrimary,
        ),
        boxShadow: const [
          BoxShadow(color: NeoBrutalColors.ink, offset: Offset(4, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: NeoBrutalColors.ink, width: 2),
                ),
                child: Icon(icon, size: 14, color: NeoBrutalColors.ink),
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  color: NeoBrutalColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: NeoBrutalColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter Chip ──
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? NeoBrutalColors.yellow : NeoBrutalColors.surface,
          border: Border.all(
            color: NeoBrutalColors.ink,
            width: selected
                ? AppConstants.borderPrimary
                : AppConstants.borderSecondary,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: NeoBrutalColors.ink,
                    offset: const Offset(2, 2),
                    blurRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 10,
            fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
            letterSpacing: 0.8,
            color: NeoBrutalColors.ink,
          ),
        ),
      ),
    );
  }
}

// ── Flow Filter Chips (Semua / Masuk / Keluar, untuk chart tren) ──
class _FlowFilterChips extends ConsumerWidget {
  const _FlowFilterChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(reportFlowFilterProvider);

    void select(FlowFilter f) {
      HapticFeedback.selectionClick();
      ref.read(reportFlowFilterProvider.notifier).state = f;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TAMPILKAN',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
            color: NeoBrutalColors.ink.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _FilterChip(
              label: 'SEMUA',
              selected: selected == FlowFilter.all,
              onTap: () => select(FlowFilter.all),
            ),
            const SizedBox(width: 6),
            _FilterChip(
              label: '↓ MASUK',
              selected: selected == FlowFilter.income,
              onTap: () => select(FlowFilter.income),
            ),
            const SizedBox(width: 6),
            _FilterChip(
              label: '↑ KELUAR',
              selected: selected == FlowFilter.expense,
              onTap: () => select(FlowFilter.expense),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Legend Masuk/Keluar ──
class _FlowLegend extends StatelessWidget {
  const _FlowLegend();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendDot(color: NeoBrutalColors.success, label: 'Masuk'),
        const SizedBox(width: 16),
        _LegendDot(color: NeoBrutalColors.danger, label: 'Keluar'),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ── Tren Harian (tab Bulanan) ──
class _MonthlyTrendSection extends ConsumerWidget {
  const _MonthlyTrendSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(reportMonthTrendProvider);
    final flow = ref.watch(reportFlowFilterProvider);
    final month = ref.watch(reportSelectedMonthProvider);
    final monthLabel = DateFormat('MMMM yyyy', 'id_ID').format(month);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReportSectionHeader(
          title: 'TREN HARIAN',
          accent: NeoBrutalColors.primary,
          subtitle: 'Arus kas per tanggal • $monthLabel',
        ),
        const SizedBox(height: 12),
        NeoCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _FlowFilterChips(),
              const SizedBox(height: 16),
              if (flow == FlowFilter.all) ...[
                const _FlowLegend(),
                const SizedBox(height: 16),
              ],
              _FlowLineChart(
                data: data,
                flow: flow,
                labelInterval: 5,
                showDots: false,
                labelFontSize: 9,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Tren Tahunan (tab Ringkasan) ──
class _YearlyTrendSection extends ConsumerWidget {
  const _YearlyTrendSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(reportYearTrendProvider);
    final flow = ref.watch(reportFlowFilterProvider);
    final year = ref.watch(reportSelectedYearProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReportSectionHeader(
          title: 'TREN TAHUNAN',
          accent: NeoBrutalColors.primary,
          subtitle: 'Total per bulan • $year',
        ),
        const SizedBox(height: 12),
        NeoCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _FlowFilterChips(),
              const SizedBox(height: 16),
              if (flow == FlowFilter.all) ...[
                const _FlowLegend(),
                const SizedBox(height: 16),
              ],
              _FlowLineChart(
                data: data,
                flow: flow,
                labelInterval: 2,
                showDots: true,
                labelFontSize: 10,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Line Chart Masuk/Keluar (dipakai tren harian & tahunan) ──
class _FlowLineChart extends StatelessWidget {
  const _FlowLineChart({
    required this.data,
    required this.flow,
    required this.labelInterval,
    required this.showDots,
    required this.labelFontSize,
  });

  final List<TrendDataPoint> data;
  final FlowFilter flow;
  final int labelInterval;
  final bool showDots;
  final double labelFontSize;

  @override
  Widget build(BuildContext context) {
    final compactFormatter = NumberFormat.compactCurrency(
      locale: 'id_ID',
      symbol: '',
      decimalDigits: 0,
    );
    final fullFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    final showIncome = flow != FlowFilter.expense;
    final showExpense = flow != FlowFilter.income;

    // Skala hanya dari garis yang tampil, agar garis tunggal tidak gepeng
    double maxVal = 0;
    for (final p in data) {
      if (showIncome && p.income > maxVal) maxVal = p.income;
      if (showExpense && p.expense > maxVal) maxVal = p.expense;
    }
    if (maxVal == 0) maxVal = 100000;

    final incomeSpots = <FlSpot>[];
    final expenseSpots = <FlSpot>[];
    for (int i = 0; i < data.length; i++) {
      incomeSpots.add(FlSpot(i.toDouble(), data[i].income));
      expenseSpots.add(FlSpot(i.toDouble(), data[i].expense));
    }

    // Label tooltip mengikuti urutan garis yang tampil
    final lineLabels = [if (showIncome) 'Masuk', if (showExpense) 'Keluar'];

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxVal * 1.2,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxVal / 4,
            getDrawingHorizontalLine: (value) => FlLine(
              color: NeoBrutalColors.ink.withValues(alpha: 0.08),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const SizedBox.shrink();
                  return Text(
                    compactFormatter.format(value),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: NeoBrutalColors.ink.withValues(alpha: 0.6),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= data.length) {
                    return const SizedBox.shrink();
                  }
                  if (idx % labelInterval != 0) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      data[idx].label,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: labelFontSize,
                        fontWeight: FontWeight.w700,
                        color: NeoBrutalColors.ink.withValues(alpha: 0.6),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              left: BorderSide(color: NeoBrutalColors.ink, width: 2),
              bottom: BorderSide(color: NeoBrutalColors.ink, width: 2),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => NeoBrutalColors.ink,
              getTooltipItems: (spots) {
                return spots.map((spot) {
                  final label = lineLabels[spot.barIndex];
                  return LineTooltipItem(
                    '$label\n${fullFormatter.format(spot.y)}',
                    GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: spot.barIndex == 0 && showIncome
                          ? NeoBrutalColors.success
                          : NeoBrutalColors.danger,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            if (showIncome)
              LineChartBarData(
                spots: incomeSpots,
                isCurved: true,
                curveSmoothness: 0.25,
                preventCurveOverShooting: true,
                color: NeoBrutalColors.success,
                barWidth: 3,
                isStrokeCapRound: false,
                dotData: FlDotData(
                  show: showDots,
                  getDotPainter: (spot, percent, barData, index) =>
                      FlDotSquarePainter(
                        size: 6,
                        color: NeoBrutalColors.success,
                        strokeColor: NeoBrutalColors.ink,
                        strokeWidth: 1.5,
                      ),
                ),
              ),
            if (showExpense)
              LineChartBarData(
                spots: expenseSpots,
                isCurved: true,
                curveSmoothness: 0.25,
                preventCurveOverShooting: true,
                color: NeoBrutalColors.danger,
                barWidth: 3,
                isStrokeCapRound: false,
                dotData: FlDotData(
                  show: showDots,
                  getDotPainter: (spot, percent, barData, index) =>
                      FlDotSquarePainter(
                        size: 6,
                        color: NeoBrutalColors.danger,
                        strokeColor: NeoBrutalColors.ink,
                        strokeWidth: 1.5,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Nav Button (navigasi bulan/tahun) ──
class _NavButton extends StatelessWidget {
  const _NavButton({
    this.icon,
    this.label,
    this.color,
    this.enabled = true,
    this.onTap,
  });

  final IconData? icon;
  final String? label;
  final Color? color;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bg = enabled
        ? (color ?? NeoBrutalColors.surface)
        : NeoBrutalColors.muted;
    final fg = color != null && enabled ? Colors.white : NeoBrutalColors.ink;

    return GestureDetector(
      onTap: enabled
          ? () {
              HapticFeedback.selectionClick();
              onTap?.call();
            }
          : null,
      child: Container(
        padding: label != null
            ? const EdgeInsets.symmetric(horizontal: 10, vertical: 8)
            : const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(
            color: enabled
                ? NeoBrutalColors.ink
                : NeoBrutalColors.ink.withValues(alpha: 0.3),
            width: AppConstants.borderSecondary,
          ),
          boxShadow: enabled
              ? const [
                  BoxShadow(color: NeoBrutalColors.ink, offset: Offset(2, 2)),
                ]
              : null,
        ),
        child: label != null
            ? Text(
                label!,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  color: fg,
                ),
              )
            : Icon(
                icon,
                size: 18,
                color: enabled
                    ? NeoBrutalColors.ink
                    : NeoBrutalColors.ink.withValues(alpha: 0.3),
              ),
      ),
    );
  }
}

// ── Category Breakdown (pie chart + legend, bulan terpilih) ──
class _CategoryBreakdown extends ConsumerWidget {
  const _CategoryBreakdown();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final breakdown = ref.watch(reportCategoryBreakdownProvider);
    final categoriesAsync = ref.watch(reportCategoriesProvider);
    final month = ref.watch(reportSelectedMonthProvider);
    final monthLabel = DateFormat('MMMM yyyy', 'id_ID').format(month);

    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    if (breakdown.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReportSectionHeader(
            title: 'BREAKDOWN KATEGORI',
            accent: NeoBrutalColors.purple,
            subtitle: 'Proporsi pengeluaran $monthLabel',
          ),
          const SizedBox(height: 12),
          NeoCard(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.pie_chart_outline_rounded,
                    size: 40,
                    color: NeoBrutalColors.ink.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Belum ada pengeluaran di bulan ini',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: NeoBrutalColors.ink.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    final total = breakdown.values.fold<double>(0, (a, b) => a + b);
    final entries = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return categoriesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (categories) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ReportSectionHeader(
              title: 'BREAKDOWN KATEGORI',
              accent: NeoBrutalColors.purple,
              subtitle: 'Proporsi pengeluaran $monthLabel',
            ),
            const SizedBox(height: 12),
            NeoCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SizedBox(
                    height: 180,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 3,
                        centerSpaceRadius: 40,
                        sections: entries.map((e) {
                          final cat = categories[e.key];
                          final pct = (e.value / total * 100);
                          return PieChartSectionData(
                            value: e.value,
                            title: pct >= 8 ? '${pct.toStringAsFixed(0)}%' : '',
                            titleStyle: GoogleFonts.spaceGrotesk(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                            color: cat?.colorValue ?? NeoBrutalColors.muted,
                            radius: 50,
                            borderSide: const BorderSide(
                              color: NeoBrutalColors.ink,
                              width: 2,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...entries.map((e) {
                    final cat = categories[e.key];
                    final pct = (e.value / total * 100);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: cat?.colorValue ?? NeoBrutalColors.muted,
                              border: Border.all(
                                color: NeoBrutalColors.ink,
                                width: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              (cat?.name ?? 'Lainnya').toUpperCase(),
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            '${pct.toStringAsFixed(1)}%',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: NeoBrutalColors.ink.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            formatter.format(e.value),
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
