import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/neo_brutal_colors.dart';
import '../../core/theme/neo_brutal_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/account_model.dart';
import '../../data/models/category_model.dart';
import '../../data/notifiers/reports_providers.dart';
import '../../shared/widgets/catat_in_app_bar.dart';
import '../../shared/widgets/neo_card.dart';
import '../../shared/widgets/neo_segmented_control.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(reportPeriodProvider);
    final accounts = ref.watch(reportAccountsProvider);
    final accountFilter = ref.watch(reportAccountFilterProvider);

    return Scaffold(
      appBar: const CatatInAppBar(subtitle: 'Laporan'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period selector
            NeoSegmentedControl<ReportPeriod>(
              segments: neoSegments([
                (ReportPeriod.week, 'Minggu'),
                (ReportPeriod.month, 'Bulan'),
                (ReportPeriod.year, 'Tahun'),
              ]),
              selected: period,
              onChanged: (v) =>
                  ref.read(reportPeriodProvider.notifier).state = v,
            ),
            const SizedBox(height: 12),

            // Account filter
            accounts.when(
              data: (accs) => _AccountFilterChips(
                accounts: accs,
                selected: accountFilter,
                onChanged: (id) => ref
                    .read(reportAccountFilterProvider.notifier)
                    .state = id,
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 20),

            // Cashflow summary
            const _CashflowSummary(),
            const SizedBox(height: 24),

            // Trend chart (with category filter inside)
            const _TrendChart(),
            const SizedBox(height: 24),

            // Category breakdown
            const _CategoryBreakdown(),
          ],
        ),
      ),
    );
  }
}

// ── Account Filter Chips ──
class _AccountFilterChips extends StatelessWidget {
  const _AccountFilterChips({
    required this.accounts,
    required this.selected,
    required this.onChanged,
  });

  final List<AccountModel> accounts;
  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _FilterChip(
            label: 'SEMUA',
            selected: selected == null,
            onTap: () => onChanged(null),
          ),
          const SizedBox(width: 6),
          ...accounts.map((a) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: _FilterChip(
                  label: a.name.toUpperCase(),
                  selected: selected == a.id,
                  onTap: () => onChanged(a.id),
                ),
              )),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});
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
                      blurRadius: 0)
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 10,
            fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}

// ── Category Filter Chips (for chart) ──
class _CategoryFilterChips extends ConsumerWidget {
  const _CategoryFilterChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(reportCategoriesListProvider);
    final selected = ref.watch(reportCategoryFilterProvider);

    return categories.when(
      data: (cats) {
        // Filter only expense categories for chart
        final expenseCats =
            cats.where((c) => c.type == CategoryType.expense).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FILTER KATEGORI',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
                color: NeoBrutalColors.ink.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 32,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _FilterChip(
                    label: 'SEMUA',
                    selected: selected == null,
                    onTap: () => ref
                        .read(reportCategoryFilterProvider.notifier)
                        .state = null,
                  ),
                  const SizedBox(width: 6),
                  ...expenseCats.map((cat) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _FilterChip(
                          label: cat.name.toUpperCase(),
                          selected: selected == cat.id,
                          onTap: () => ref
                              .read(reportCategoryFilterProvider.notifier)
                              .state = selected == cat.id ? null : cat.id,
                        ),
                      )),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

// ── Cashflow Summary ──
class _CashflowSummary extends ConsumerWidget {
  const _CashflowSummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cashflow = ref.watch(reportCashflowProvider);
    final period = ref.watch(reportPeriodProvider);
    final now = DateTime.now();
    final formatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    final income = cashflow['income'] ?? 0;
    final expense = cashflow['expense'] ?? 0;
    final net = income - expense;

    String periodLabel;
    switch (period) {
      case ReportPeriod.week:
        periodLabel = 'MINGGU INI';
        break;
      case ReportPeriod.month:
        periodLabel =
            DateFormat('MMMM yyyy', 'id_ID').format(now).toUpperCase();
        break;
      case ReportPeriod.year:
        periodLabel = 'TAHUN ${now.year}';
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CASHFLOW $periodLabel',
          style: GoogleFonts.spaceGrotesk(
              fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _StatCard(
                    label: 'MASUK',
                    value: formatter.format(income),
                    color: NeoBrutalColors.success)),
            const SizedBox(width: 8),
            Expanded(
                child: _StatCard(
                    label: 'KELUAR',
                    value: formatter.format(expense),
                    color: NeoBrutalColors.danger)),
          ],
        ),
        const SizedBox(height: 8),
        _StatCard(
          label: 'NET',
          value: '${net >= 0 ? '+' : ''}${formatter.format(net)}',
          color: net >= 0 ? NeoBrutalColors.success : NeoBrutalColors.danger,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(
      {required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return NeoCard(
      borderOffset: const Offset(4, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  color: color)),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 18, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

// ── Trend Chart (Line Chart) with Navigation ──
class _TrendChart extends ConsumerWidget {
  const _TrendChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendData = ref.watch(reportTrendProvider);
    final period = ref.watch(reportPeriodProvider);
    final offset = ref.watch(chartPeriodOffsetProvider);
    final fullFormatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    if (trendData.isEmpty) {
      return const SizedBox.shrink();
    }

    // Find max for scaling
    double maxVal = 0;
    for (final d in trendData) {
      if (d.income > maxVal) maxVal = d.income;
      if (d.expense > maxVal) maxVal = d.expense;
    }
    if (maxVal == 0) maxVal = 1;

    // Build line data points
    final incomeSpots = <FlSpot>[];
    final expenseSpots = <FlSpot>[];
    for (int i = 0; i < trendData.length; i++) {
      incomeSpots.add(FlSpot(i.toDouble(), trendData[i].income));
      expenseSpots.add(FlSpot(i.toDouble(), trendData[i].expense));
    }

    // Period label
    final now = DateTime.now();
    String periodLabel;
    switch (period) {
      case ReportPeriod.week:
        final weekStart =
            now.subtract(Duration(days: now.weekday - 1 + (offset * 7)));
        periodLabel =
            '${DateFormat('dd MMM').format(weekStart)} - ${DateFormat('dd MMM yyyy').format(weekStart.add(const Duration(days: 6)))}';
        break;
      case ReportPeriod.month:
        final targetMonth = DateTime(now.year, now.month + offset);
        periodLabel = DateFormat('MMMM yyyy', 'id_ID').format(targetMonth);
        break;
      case ReportPeriod.year:
        periodLabel = '${now.year + offset}';
        break;
    }

    // Label interval
    int labelInterval;
    switch (period) {
      case ReportPeriod.week:
        labelInterval = 1; // Show all days
        break;
      case ReportPeriod.month:
        labelInterval = 5; // Show every 5 days
        break;
      case ReportPeriod.year:
        labelInterval = 2; // Show every 2 months
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with navigation
        Row(
          children: [
            Expanded(
              child: Text(
                'TREN ${period == ReportPeriod.week
                    ? 'MINGGUAN'
                    : period == ReportPeriod.month
                        ? 'BULANAN'
                        : 'TAHUNAN'}',
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Navigation row with 3D buttons
        Row(
          children: [
            // Prev button (3D effect)
            _NavButton(
              icon: Icons.chevron_left_rounded,
              onTap: () {
                HapticFeedback.selectionClick();
                ref.read(chartPeriodOffsetProvider.notifier).state--;
              },
            ),
            // Period label
            Expanded(
              child: Center(
                child: Text(
                  periodLabel.toUpperCase(),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
            // Next button (3D effect)
            _NavButton(
              icon: Icons.chevron_right_rounded,
              enabled: offset < 0,
              onTap: offset < 0
                  ? () {
                      HapticFeedback.selectionClick();
                      ref.read(chartPeriodOffsetProvider.notifier).state++;
                    }
                  : null,
            ),
            const SizedBox(width: 8),
            // Today button (3D effect)
            if (offset != 0)
              _NavButton(
                label: 'HARI INI',
                color: NeoBrutalColors.primary,
                onTap: () {
                  HapticFeedback.selectionClick();
                  ref.read(chartPeriodOffsetProvider.notifier).state = 0;
                },
              ),
          ],
        ),
        const SizedBox(height: 12),
        NeoCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category filter inside card
              const _CategoryFilterChips(),
              const SizedBox(height: 16),
              // Legend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _LegendDot(color: NeoBrutalColors.success, label: 'Masuk'),
                  const SizedBox(width: 16),
                  _LegendDot(color: NeoBrutalColors.danger, label: 'Keluar'),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    maxY: maxVal * 1.2,
                    minY: 0,
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            final label =
                                spot.barIndex == 0 ? 'Masuk' : 'Keluar';
                            return LineTooltipItem(
                              '$label\n${fullFormatter.format(spot.y)}',
                              GoogleFonts.spaceGrotesk(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 24,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            // Only show label for integer positions
                            if (value != index) return const SizedBox.shrink();
                            if (index < 0 || index >= trendData.length) {
                              return const SizedBox.shrink();
                            }
                            // Skip labels based on interval
                            if (index % labelInterval != 0) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                trendData[index].label,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: period == ReportPeriod.month ? 9 : 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: maxVal / 4,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color:
                              NeoBrutalColors.muted.withValues(alpha: 0.3),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      // Income line
                      LineChartBarData(
                        spots: incomeSpots,
                        isCurved: period != ReportPeriod.week,
                        color: NeoBrutalColors.success,
                        barWidth: 2.5,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: period != ReportPeriod.month,
                          getDotPainter: (spot, percent, bar, index) {
                            return FlDotCirclePainter(
                              radius: 3,
                              color: NeoBrutalColors.success,
                              strokeWidth: 1.5,
                              strokeColor: Colors.white,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: NeoBrutalColors.success
                              .withValues(alpha: 0.1),
                        ),
                      ),
                      // Expense line
                      LineChartBarData(
                        spots: expenseSpots,
                        isCurved: period != ReportPeriod.week,
                        color: NeoBrutalColors.danger,
                        barWidth: 2.5,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: period != ReportPeriod.month,
                          getDotPainter: (spot, percent, bar, index) {
                            return FlDotCirclePainter(
                              radius: 3,
                              color: NeoBrutalColors.danger,
                              strokeWidth: 1.5,
                              strokeColor: Colors.white,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color:
                              NeoBrutalColors.danger.withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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
          style:
              GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

// ── 3D Navigation Button ──
class _NavButton extends StatefulWidget {
  const _NavButton({
    this.icon,
    this.label,
    this.color,
    this.enabled = true,
    required this.onTap,
  });

  final IconData? icon;
  final String? label;
  final Color? color;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final borderColor = NeoBrutalTheme.borderColor(brightness);

    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => setState(() => _pressed = true) : null,
      onTapUp: widget.onTap != null
          ? (_) {
              setState(() => _pressed = false);
              widget.onTap?.call();
            }
          : null,
      onTapCancel: widget.onTap != null ? () => setState(() => _pressed = false) : null,
      child: AnimatedContainer(
        duration: AppConstants.animButton,
        padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: widget.enabled
              ? (widget.color ?? NeoBrutalColors.surface)
              : NeoBrutalColors.muted.withValues(alpha: 0.3),
          border: Border.all(
            color: widget.enabled ? borderColor : NeoBrutalColors.muted,
            width: AppConstants.borderSecondary,
          ),
          boxShadow: (_pressed || !widget.enabled)
              ? []
              : [
                  BoxShadow(
                    color: widget.enabled ? borderColor : NeoBrutalColors.muted,
                    offset: const Offset(2, 2),
                    blurRadius: 0,
                  ),
                ],
        ),
        transform: _pressed
            ? (Matrix4.identity()
              ..translateByDouble(2.0, 2.0, 0.0, 1.0))
            : Matrix4.identity(),
        child: widget.icon != null
            ? Icon(
                widget.icon,
                size: 18,
                color: widget.enabled ? null : NeoBrutalColors.muted,
              )
            : Text(
                widget.label ?? '',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }
}

// ── Category Breakdown ──
class _CategoryBreakdown extends ConsumerWidget {
  const _CategoryBreakdown();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final breakdown = ref.watch(reportCategoryBreakdownProvider);
    final categories = ref.watch(reportCategoriesProvider);
    final formatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    if (breakdown.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BREAKDOWN KATEGORI',
            style: GoogleFonts.spaceGrotesk(
                fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5),
          ),
          const SizedBox(height: 12),
          NeoCard(
            child: Center(
              child: Text(
                'Belum ada data pengeluaran',
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      );
    }

    final total = breakdown.values.fold<double>(0, (a, b) => a + b);
    final entries = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return categories.when(
      data: (catMap) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BREAKDOWN KATEGORI',
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5),
            ),
            const SizedBox(height: 12),
            NeoCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SizedBox(
                    height: 200,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            sectionsSpace: 3,
                            centerSpaceRadius: 50,
                            sections: entries.map((e) {
                              final cat = catMap[e.key];
                              final percent = (e.value / total * 100);
                              return PieChartSectionData(
                                value: e.value,
                                color:
                                    cat?.colorValue ?? NeoBrutalColors.muted,
                                title: percent >= 5
                                    ? '${percent.toStringAsFixed(0)}%'
                                    : '',
                                titleStyle: GoogleFonts.spaceGrotesk(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                                radius: 45,
                                titlePositionPercentageOffset: 0.6,
                              );
                            }).toList(),
                          ),
                        ),
                        // Center text
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'TOTAL',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                                color: NeoBrutalColors.ink.withValues(alpha: 0.5),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              NumberFormat.compactCurrency(
                                locale: 'id_ID',
                                symbol: 'Rp',
                                decimalDigits: 0,
                              ).format(total),
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...entries.map((e) {
                    final cat = catMap[e.key];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color:
                                  cat?.colorValue ?? NeoBrutalColors.muted,
                              border: Border.all(
                                  color: NeoBrutalColors.ink, width: 1.5),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              cat?.name ?? e.key,
                              style: GoogleFonts.spaceGrotesk(
                                  fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                          ),
                          Text(
                            formatter.format(e.value),
                            style: GoogleFonts.spaceGrotesk(
                                fontSize: 13, fontWeight: FontWeight.w800),
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
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
