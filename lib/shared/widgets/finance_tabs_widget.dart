import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/neo_brutal_colors.dart';
import '../../core/constants/app_constants.dart';
import 'neo_card.dart';
import '../../data/notifiers/dashboard_providers.dart';
import '../../features/budget/budget_screen.dart';
import '../../features/recurring/recurring_screen.dart';
import '../../features/savings/savings_screen.dart';

enum FinanceTab { budget, recurring, savings }

/// Combined widget: Budget | Tagihan | Tabungan dalam 1 card dengan tab
class FinanceTabsWidget extends ConsumerStatefulWidget {
  const FinanceTabsWidget({super.key});

  @override
  ConsumerState<FinanceTabsWidget> createState() => _FinanceTabsWidgetState();
}

class _FinanceTabsWidgetState extends ConsumerState<FinanceTabsWidget> {
  FinanceTab _activeTab = FinanceTab.budget;

  @override
  Widget build(BuildContext context) {
    return NeoCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'KEUANGAN SAYA',
            style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5),
          ),
          const SizedBox(height: 12),
          // Tab bar
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: NeoBrutalColors.ink, width: AppConstants.borderSecondary),
            ),
            child: Row(
              children: [
                _TabButton(
                  label: 'BUDGET',
                  icon: Icons.account_balance_wallet_rounded,
                  color: NeoBrutalColors.green,
                  selected: _activeTab == FinanceTab.budget,
                  onTap: () => setState(() => _activeTab = FinanceTab.budget),
                ),
                Container(width: AppConstants.borderSecondary, color: NeoBrutalColors.ink, height: 36),
                _TabButton(
                  label: 'TAGIHAN',
                  icon: Icons.repeat_rounded,
                  color: NeoBrutalColors.orange,
                  selected: _activeTab == FinanceTab.recurring,
                  onTap: () => setState(() => _activeTab = FinanceTab.recurring),
                ),
                Container(width: AppConstants.borderSecondary, color: NeoBrutalColors.ink, height: 36),
                _TabButton(
                  label: 'TABUNGAN',
                  icon: Icons.savings_rounded,
                  color: NeoBrutalColors.secondary,
                  selected: _activeTab == FinanceTab.savings,
                  onTap: () => setState(() => _activeTab = FinanceTab.savings),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Content
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_activeTab) {
      case FinanceTab.budget:
        return _BudgetTabContent(key: const ValueKey('budget'));
      case FinanceTab.recurring:
        return _RecurringTabContent(key: const ValueKey('recurring'));
      case FinanceTab.savings:
        return _SavingsTabContent(key: const ValueKey('savings'));
    }
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          color: selected ? color.withValues(alpha: 0.15) : Colors.transparent,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: selected ? color : NeoBrutalColors.muted),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                  letterSpacing: 0.5,
                  color: selected ? color : NeoBrutalColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Budget Tab Content ──
class _BudgetTabContent extends ConsumerWidget {
  const _BudgetTabContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgets = ref.watch(budgetOverviewProvider);
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    if (budgets.isEmpty) {
      return _EmptyTabContent(
        icon: Icons.account_balance_wallet_rounded,
        message: 'Belum ada budget',
        ctaLabel: 'Atur Budget',
        color: NeoBrutalColors.green,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BudgetScreen())),
      );
    }

    double totalLimit = 0;
    double totalSpent = 0;
    for (final b in budgets) {
      totalLimit += b.budget.limitAmount;
      totalSpent += b.spent;
    }
    final totalPercent = totalLimit > 0 ? totalSpent / totalLimit : 0.0;
    final totalColor = totalPercent > 1.0
        ? NeoBrutalColors.danger
        : totalPercent >= 0.8
            ? NeoBrutalColors.orange
            : NeoBrutalColors.success;

    final warnings = budgets.where((b) => b.percent >= 0.8).toList();

    return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BudgetScreen())),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Total progress
              Row(
                children: [
                  Text('${(totalPercent * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w900, color: totalColor)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 10,
                      child: Stack(
                        children: [
                          Container(decoration: BoxDecoration(color: NeoBrutalColors.muted, border: Border.all(color: NeoBrutalColors.ink, width: 1))),
                          FractionallySizedBox(widthFactor: totalPercent.clamp(0, 1), child: Container(color: totalColor)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('${formatter.format(totalSpent)} / ${formatter.format(totalLimit)}',
                style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w600)),
              if (warnings.isNotEmpty) ...[
                const SizedBox(height: 8),
                ...warnings.take(2).map((w) => Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    children: [
                      Icon(w.isOver ? Icons.warning_amber_rounded : Icons.info_outline_rounded, size: 14,
                        color: w.isOver ? NeoBrutalColors.danger : NeoBrutalColors.orange),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${w.category.name} ${w.isOver ? "melebihi!" : "${(w.percent * 100).toStringAsFixed(0)}%"}',
                          style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w700,
                            color: w.isOver ? NeoBrutalColors.danger : NeoBrutalColors.orange),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
              const SizedBox(height: 8),
              _ViewAllLink(label: 'Lihat semua budget', color: NeoBrutalColors.green),
            ],
          ),
        );
  }
}

// ── Recurring Tab Content ──
class _RecurringTabContent extends ConsumerWidget {
  const _RecurringTabContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcoming = ref.watch(upcomingRecurringProvider);
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    if (upcoming.isEmpty) {
      return _EmptyTabContent(
        icon: Icons.repeat_rounded,
        message: 'Belum ada tagihan',
        ctaLabel: 'Atur Tagihan',
        color: NeoBrutalColors.orange,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecurringScreen())),
      );
    }

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecurringScreen())),
      child: Column(
        children: [
          ...upcoming.map((rt) {
            final isDue = rt.nextDate.isBefore(DateTime.now());
            final isIncome = rt.transactionType == 'income';
            final daysUntil = rt.nextDate.difference(DateTime.now()).inDays;
            String dueText = isDue ? 'JATUH TEMPO' : daysUntil == 0 ? 'Hari ini' : daysUntil == 1 ? 'Besok' : '$daysUntil hari lagi';

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(isDue ? Icons.warning_amber_rounded : Icons.repeat_rounded, size: 16,
                    color: isDue ? NeoBrutalColors.danger : NeoBrutalColors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(rt.note ?? 'Transaksi Berulang',
                          style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700)),
                        Text('${rt.frequencyLabel} • ${DateFormat('dd MMM').format(rt.nextDate)}',
                          style: GoogleFonts.spaceGrotesk(fontSize: 9, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${isIncome ? '+' : '-'}${formatter.format(rt.amount)}',
                        style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w800,
                          color: isIncome ? NeoBrutalColors.success : NeoBrutalColors.danger)),
                      Text(dueText,
                        style: GoogleFonts.spaceGrotesk(fontSize: 9, fontWeight: FontWeight.w700,
                          color: isDue ? NeoBrutalColors.danger : NeoBrutalColors.orange)),
                    ],
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 6),
          _ViewAllLink(label: 'Lihat semua tagihan', color: NeoBrutalColors.orange),
        ],
      ),
    );
  }
}

// ── Savings Tab Content ──
class _SavingsTabContent extends ConsumerWidget {
  const _SavingsTabContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(savingsGoalsDashboardProvider);
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    if (goals.isEmpty) {
      return _EmptyTabContent(
        icon: Icons.savings_rounded,
        message: 'Belum ada target',
        ctaLabel: 'Buat Target',
        color: NeoBrutalColors.secondary,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SavingsScreen())),
      );
    }

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SavingsScreen())),
      child: Column(
        children: [
          ...goals.take(3).map((goal) {
            final statusColor = goal.isComplete
                ? NeoBrutalColors.success
                : goal.percent >= 0.8 ? NeoBrutalColors.orange : NeoBrutalColors.secondary;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(goal.isComplete ? Icons.check_circle_rounded : Icons.savings_rounded,
                        size: 14, color: statusColor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(goal.name.toUpperCase(),
                          style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                      ),
                      Text('${(goal.percent * 100).toStringAsFixed(0)}%',
                        style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w900, color: statusColor)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 6,
                    child: Stack(
                      children: [
                        Container(decoration: BoxDecoration(color: NeoBrutalColors.muted, border: Border.all(color: NeoBrutalColors.ink, width: 0.5))),
                        FractionallySizedBox(widthFactor: goal.percent.clamp(0, 1), child: Container(color: statusColor)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text('${formatter.format(goal.savedAmount)} / ${formatter.format(goal.targetAmount)}',
                    style: GoogleFonts.spaceGrotesk(fontSize: 9, fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }),
          const SizedBox(height: 4),
          _ViewAllLink(label: 'Lihat semua target', color: NeoBrutalColors.secondary),
        ],
      ),
    );
  }
}

// ── Shared Widgets ──
class _EmptyTabContent extends StatelessWidget {
  const _EmptyTabContent({
    required this.icon,
    required this.message,
    required this.ctaLabel,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String message;
  final String ctaLabel;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: NeoBrutalColors.muted),
            const SizedBox(height: 6),
            Text(message, style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(ctaLabel,
              style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }
}

class _ViewAllLink extends StatelessWidget {
  const _ViewAllLink({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label,
          style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(width: 4),
        Icon(Icons.chevron_right_rounded, size: 16, color: color),
      ],
    );
  }
}
