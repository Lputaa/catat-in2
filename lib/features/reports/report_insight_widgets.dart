import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/neo_brutal_colors.dart';
import '../../data/notifiers/reports_providers.dart';

// ── Section Header (aksen kotak warna + judul, dipakai semua seksi) ──
class ReportSectionHeader extends StatelessWidget {
  const ReportSectionHeader({
    super.key,
    required this.title,
    required this.accent,
    this.subtitle,
  });

  final String title;
  final Color accent;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final ink = brightness == Brightness.light
        ? NeoBrutalColors.ink
        : NeoBrutalColors.inkDark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: accent,
                border: Border.all(color: ink, width: 2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Text(
              subtitle!,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: ink.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Daily Average Card (rata-rata pengeluaran harian) ──
class DailyAverageCard extends ConsumerWidget {
  const DailyAverageCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avg = ref.watch(reportDailyAverageProvider);
    final brightness = Theme.of(context).brightness;
    final borderColor = brightness == Brightness.light
        ? NeoBrutalColors.ink
        : NeoBrutalColors.darkLine;
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        // Impeller-safe: blend alpha ke bg opaque, bukan fill transparan
        color: Color.alphaBlend(
          NeoBrutalColors.secondary.withValues(alpha: 0.12),
          brightness == Brightness.light
              ? NeoBrutalColors.surface
              : NeoBrutalColors.surfaceDark,
        ),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [BoxShadow(color: borderColor, offset: const Offset(3, 3))],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: NeoBrutalColors.secondary,
              border: Border.all(color: borderColor, width: 2),
            ),
            child: const Icon(
              Icons.query_stats_rounded,
              size: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RATA-RATA HARIAN',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: NeoBrutalColors.secondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatter.format(avg),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'pengeluaran\nper hari',
            textAlign: TextAlign.right,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              height: 1.3,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Monthly Comparison Bar Chart (6 bulan terakhir) ──
class MonthlyComparisonChart extends ConsumerWidget {
  const MonthlyComparisonChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(reportMonthlyComparisonProvider);
    final compactFormatter = NumberFormat.compactCurrency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    final fullFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    double maxVal = 0;
    for (final d in data) {
      if (d.income > maxVal) maxVal = d.income;
      if (d.expense > maxVal) maxVal = d.expense;
    }
    if (maxVal == 0) maxVal = 1;

    // Insight: pengeluaran bulan ini vs bulan lalu
    final currExpense = data.isNotEmpty ? data.last.expense : 0.0;
    final prevExpense = data.length >= 2 ? data[data.length - 2].expense : 0.0;
    Widget? insight;
    if (prevExpense > 0) {
      final deltaPct = ((currExpense - prevExpense) / prevExpense * 100);
      final isUp = deltaPct > 0;
      final color = isUp ? NeoBrutalColors.danger : NeoBrutalColors.success;
      insight = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'PENGELUARAN ${isUp ? 'NAIK' : 'TURUN'} '
              '${deltaPct.abs().toStringAsFixed(0)}% VS BULAN LALU',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                color: color,
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _legendBox(NeoBrutalColors.success, 'Masuk'),
            const SizedBox(width: 16),
            _legendBox(NeoBrutalColors.danger, 'Keluar'),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: BarChart(
            BarChartData(
              maxY: maxVal * 1.2,
              alignment: BarChartAlignment.spaceAround,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => NeoBrutalColors.ink,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final label = rodIndex == 0 ? 'Masuk' : 'Keluar';
                    return BarTooltipItem(
                      '${data[group.x].label}\n'
                      '$label: ${fullFormatter.format(rod.toY)}',
                      GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 26,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= data.length) {
                        return const SizedBox.shrink();
                      }
                      final isCurrent = index == data.length - 1;
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          data[index].label.toUpperCase(),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 9,
                            fontWeight: isCurrent
                                ? FontWeight.w900
                                : FontWeight.w600,
                            color: isCurrent ? NeoBrutalColors.primary : null,
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
                getDrawingHorizontalLine: (value) => FlLine(
                  color: NeoBrutalColors.muted.withValues(alpha: 0.3),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(data.length, (i) {
                return BarChartGroupData(
                  x: i,
                  barsSpace: 3,
                  barRods: [
                    BarChartRodData(
                      toY: data[i].income,
                      width: 9,
                      color: NeoBrutalColors.success,
                      borderRadius: BorderRadius.zero,
                      borderSide: const BorderSide(
                        color: NeoBrutalColors.ink,
                        width: 1,
                      ),
                    ),
                    BarChartRodData(
                      toY: data[i].expense,
                      width: 9,
                      color: NeoBrutalColors.danger,
                      borderRadius: BorderRadius.zero,
                      borderSide: const BorderSide(
                        color: NeoBrutalColors.ink,
                        width: 1,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
        if (insight != null) ...[
          const SizedBox(height: 14),
          Center(child: insight),
        ],
        const SizedBox(height: 4),
        Center(
          child: Text(
            'Ketuk batang untuk lihat nominal • Maks ${compactFormatter.format(maxVal)}',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: NeoBrutalColors.ink.withValues(alpha: 0.4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _legendBox(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: NeoBrutalColors.ink, width: 1.5),
          ),
        ),
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

// ── Spending Heatmap (GitHub-style, bulan berjalan) ──
class SpendingHeatmap extends ConsumerStatefulWidget {
  const SpendingHeatmap({super.key});

  @override
  ConsumerState<SpendingHeatmap> createState() => _SpendingHeatmapState();
}

class _SpendingHeatmapState extends ConsumerState<SpendingHeatmap> {
  int? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final daily = ref.watch(reportDailyHeatmapProvider);
    final month = ref.watch(reportSelectedMonthProvider);
    final now = DateTime.now();
    final isCurrentMonth = month.year == now.year && month.month == now.month;
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    // Reset pilihan hari saat bulan berganti
    ref.listen(reportSelectedMonthProvider, (prev, next) {
      if (prev != next) setState(() => _selectedDay = null);
    });

    final maxVal = daily.fold<double>(0, (a, b) => a > b ? a : b);
    final firstWeekday = DateTime(month.year, month.month, 1).weekday; // 1=Sen
    final leadingBlanks = firstWeekday - 1;
    final selected = _selectedDay ?? (isCurrentMonth ? now.day : 1);
    final selectedAmount = selected >= 1 && selected <= daily.length
        ? daily[selected - 1]
        : 0.0;

    const dayLabels = ['SEN', 'SEL', 'RAB', 'KAM', 'JUM', 'SAB', 'MIN'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header hari
        Row(
          children: dayLabels
              .map(
                (d) => Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: NeoBrutalColors.ink.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 6),
        // Grid heatmap
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 4.0;
            final cellSize = (constraints.maxWidth - gap * 6) / 7;
            final totalCells = leadingBlanks + daily.length;
            final rows = (totalCells / 7).ceil();

            return Column(
              children: List.generate(rows, (row) {
                return Padding(
                  padding: EdgeInsets.only(bottom: row < rows - 1 ? gap : 0),
                  child: Row(
                    children: List.generate(7, (col) {
                      final cellIndex = row * 7 + col;
                      final day = cellIndex - leadingBlanks + 1;
                      Widget cell;

                      if (day < 1 || day > daily.length) {
                        cell = SizedBox(width: cellSize, height: cellSize);
                      } else {
                        cell = _HeatCell(
                          size: cellSize,
                          day: day,
                          amount: daily[day - 1],
                          maxVal: maxVal,
                          isToday: isCurrentMonth && day == now.day,
                          isFuture: isCurrentMonth && day > now.day,
                          isSelected: day == selected,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedDay = day);
                          },
                        );
                      }

                      return Padding(
                        padding: EdgeInsets.only(right: col < 6 ? gap : 0),
                        child: cell,
                      );
                    }),
                  ),
                );
              }),
            );
          },
        ),
        const SizedBox(height: 12),
        // Detail hari terpilih
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Color.alphaBlend(
              NeoBrutalColors.danger.withValues(alpha: 0.08),
              NeoBrutalColors.surface,
            ),
            border: Border.all(color: NeoBrutalColors.ink, width: 2),
          ),
          child: Row(
            children: [
              const Icon(Icons.touch_app_rounded, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  DateFormat('EEEE, d MMMM', 'id_ID')
                      .format(DateTime(month.year, month.month, selected))
                      .toUpperCase(),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Text(
                selectedAmount > 0
                    ? formatter.format(selectedAmount)
                    : 'Tidak ada',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: selectedAmount > 0
                      ? NeoBrutalColors.danger
                      : NeoBrutalColors.ink.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Legend intensitas
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'SEDIKIT',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: NeoBrutalColors.ink.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(width: 6),
            ...[0.15, 0.35, 0.6, 0.9].map(
              (alpha) => Padding(
                padding: const EdgeInsets.only(right: 3),
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Color.alphaBlend(
                      NeoBrutalColors.danger.withValues(alpha: alpha),
                      NeoBrutalColors.surface,
                    ),
                    border: Border.all(color: NeoBrutalColors.ink, width: 1),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 3),
            Text(
              'BANYAK',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: NeoBrutalColors.ink.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeatCell extends StatelessWidget {
  const _HeatCell({
    required this.size,
    required this.day,
    required this.amount,
    required this.maxVal,
    required this.isToday,
    required this.isFuture,
    required this.isSelected,
    required this.onTap,
  });

  final double size;
  final int day;
  final double amount;
  final double maxVal;
  final bool isToday;
  final bool isFuture;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // 4 level intensitas ala GitHub contribution graph
    Color fill;
    if (isFuture) {
      fill = Color.alphaBlend(
        NeoBrutalColors.muted.withValues(alpha: 0.25),
        NeoBrutalColors.surface,
      );
    } else if (amount <= 0 || maxVal <= 0) {
      fill = NeoBrutalColors.surface;
    } else {
      final ratio = amount / maxVal;
      final alpha = ratio > 0.75
          ? 0.9
          : ratio > 0.5
          ? 0.6
          : ratio > 0.25
          ? 0.35
          : 0.15;
      fill = Color.alphaBlend(
        NeoBrutalColors.danger.withValues(alpha: alpha),
        NeoBrutalColors.surface,
      );
    }

    final darkText = amount / (maxVal <= 0 ? 1 : maxVal) > 0.5 && !isFuture;

    return GestureDetector(
      onTap: isFuture ? null : onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: fill,
          border: Border.all(
            color: isSelected
                ? NeoBrutalColors.secondary
                : isToday
                ? NeoBrutalColors.ink
                : NeoBrutalColors.ink.withValues(alpha: 0.25),
            width: isSelected || isToday ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            '$day',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 9,
              fontWeight: isToday ? FontWeight.w900 : FontWeight.w600,
              color: darkText
                  ? Colors.white
                  : NeoBrutalColors.ink.withValues(alpha: isFuture ? 0.3 : 0.8),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Top 5 Categories (list peringkat) ──
class TopCategoriesCard extends ConsumerWidget {
  const TopCategoriesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final top = ref.watch(reportTopCategoriesProvider);
    final categories = ref.watch(reportCategoriesProvider);
    final breakdown = ref.watch(reportCategoryBreakdownProvider);
    final formatter = NumberFormat.compactCurrency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    if (top.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'Belum ada pengeluaran bulan ini',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: NeoBrutalColors.ink.withValues(alpha: 0.5),
            ),
          ),
        ),
      );
    }

    final total = breakdown.values.fold<double>(0, (a, b) => a + b);
    final topValue = top.first.value;

    return categories.when(
      data: (catMap) => Column(
        children: List.generate(top.length, (i) {
          final entry = top[i];
          final cat = catMap[entry.key];
          final percent = total > 0 ? entry.value / total * 100 : 0.0;
          final barFraction = topValue > 0 ? entry.value / topValue : 0.0;
          final isFirst = i == 0;

          return Padding(
            padding: EdgeInsets.only(bottom: i < top.length - 1 ? 12 : 0),
            child: Row(
              children: [
                // Rank badge
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isFirst
                        ? NeoBrutalColors.yellow
                        : NeoBrutalColors.surface,
                    border: Border.all(color: NeoBrutalColors.ink, width: 2),
                    boxShadow: isFirst
                        ? const [
                            BoxShadow(
                              color: NeoBrutalColors.ink,
                              offset: Offset(2, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: NeoBrutalColors.ink,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              (cat?.name ?? entry.key).toUpperCase(),
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          Text(
                            '${formatter.format(entry.value)} • ${percent.toStringAsFixed(0)}%',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      // Bar proporsional terhadap kategori teratas
                      Stack(
                        children: [
                          Container(
                            height: 10,
                            decoration: BoxDecoration(
                              color: Color.alphaBlend(
                                NeoBrutalColors.muted.withValues(alpha: 0.4),
                                NeoBrutalColors.surface,
                              ),
                              border: Border.all(
                                color: NeoBrutalColors.ink,
                                width: 1.5,
                              ),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: barFraction.clamp(0.02, 1.0),
                            child: Container(
                              height: 10,
                              decoration: BoxDecoration(
                                color: cat?.colorValue ?? NeoBrutalColors.muted,
                                border: Border.all(
                                  color: NeoBrutalColors.ink,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
