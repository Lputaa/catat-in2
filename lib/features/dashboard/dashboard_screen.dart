import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/neo_brutal_colors.dart';
import '../../data/notifiers/dashboard_providers.dart';
import '../../data/notifiers/budget_list_notifier.dart';
import '../../data/notifiers/recurring_list_notifier.dart';
import '../../data/notifiers/savings_list_notifier.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/account_model.dart';
import '../../data/models/recurring_transaction_model.dart';
import '../../data/models/savings_goal_model.dart';
import '../../data/models/savings_contribution_model.dart';
import '../../data/repositories/savings_goal_repo.dart';
import '../../shared/widgets/catat_in_app_bar.dart';
import '../../shared/widgets/neo_card.dart';
import '../budget/add_budget_sheet.dart';
import '../recurring/add_recurring_sheet.dart';
import '../savings/add_savings_sheet.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: const CatatInAppBar(subtitle: 'Dashboard'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _WalletCarousel(),
            const SizedBox(height: 20),
            // Finance sections - vertical scrollable
            _FinanceSectionsScrollable(),
            const SizedBox(height: 20),
            _RecentTransactionsSection(),
          ],
        ),
      ),
    );
  }
}

// ── 3D Vertical Wallet Carousel ──
class _WalletCarousel extends ConsumerStatefulWidget {
  @override
  ConsumerState<_WalletCarousel> createState() => _WalletCarouselState();
}

class _WalletCarouselState extends ConsumerState<_WalletCarousel> {
  late PageController _pageController;
  double _currentPage = 0;
  Timer? _autoScrollTimer;
  bool _userInteracting = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.75,
      initialPage: 10000,
    );
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page ?? 0;
      });
    });
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!_userInteracting && _pageController.hasClients) {
        final nextPage = _currentPage.round() + 1;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _onUserInteraction() {
    setState(() => _userInteracting = true);
    _autoScrollTimer?.cancel();
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _userInteracting = false);
        _startAutoScroll();
      }
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider);
    final balances = ref.watch(accountBalancesProvider); // Now sync Provider
    final totalBalance = ref.watch(totalBalanceProvider); // Now sync Provider
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    return accounts.when(
      data: (accs) {
        if (accs.isEmpty) {
          return NeoCard(
            color: NeoBrutalColors.primary,
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                'BELUM ADA DOMPET',
                style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.0),
              ),
            ),
          );
        }

        // balances is now Map<String, double> directly (not AsyncValue)
        final balMap = balances;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total balance
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Text('TOTAL SALDO',
                    style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                  ),
                  const Spacer(),
                  Text(
                    formatter.format(totalBalance),
                    style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w900, color: NeoBrutalColors.primary),
                  ),
                ],
              ),
            ),
            // 3D Vertical carousel
            GestureDetector(
              onVerticalDragStart: (_) => _onUserInteraction(),
              child: SizedBox(
                height: 150,
                child: PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  itemCount: null,
                  onPageChanged: (_) => _onUserInteraction(),
                  itemBuilder: (context, i) {
                  final acc = accs[i % accs.length];
                  final balance = balMap[acc.id] ?? 0;
                  final icon = _iconForType(acc.type);
                  final color = _colorForType(acc.type);

                  // 3D perspective calculation
                  final diff = (i - _currentPage).abs();
                  final scale = (1 - (diff * 0.15)).clamp(0.75, 1.0);
                  final translateY = diff * 20;
                  final opacity = (1 - (diff * 0.3)).clamp(0.4, 1.0);

                  return Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.002) // perspective
                      ..translateByDouble(0.0, translateY * (i > _currentPage ? 1 : -1), 0.0, 1.0)
                      ..scaleByDouble(scale, scale, scale, 1.0),
                    alignment: Alignment.center,
                    child: Opacity(
                      opacity: opacity,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: NeoCard(
                          color: color,
                          padding: const EdgeInsets.all(18),
                          child: Row(
                            children: [
                              // Left: icon + name
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
                                ),
                                child: Icon(icon, size: 22, color: Colors.white),
                              ),
                              const SizedBox(width: 14),
                              // Middle: name + type
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(acc.name.toUpperCase(),
                                      style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: Colors.white),
                                    ),
                                    Text(acc.typeLabel,
                                      style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.7)),
                                    ),
                                  ],
                                ),
                              ),
                              // Right: balance
                              Text(
                                formatter.format(balance),
                                style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            ), // Close GestureDetector
            // Page dots
            if (accs.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(accs.length, (j) {
                    final isActive = j == _currentPage.round() % accs.length;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: isActive ? 20 : 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: isActive ? NeoBrutalColors.primary : NeoBrutalColors.muted,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ),
          ],
        );
      },
      loading: () => const SizedBox(height: 150),
      error: (_, _) => const SizedBox(height: 150),
    );
  }

  static IconData _iconForType(AccountType type) {
    switch (type) {
      case AccountType.cash:
        return Icons.payments_rounded;
      case AccountType.bank:
        return Icons.account_balance_rounded;
      case AccountType.ewallet:
        return Icons.account_balance_wallet_rounded;
      case AccountType.other:
        return Icons.wallet_rounded;
    }
  }

  static Color _colorForType(AccountType type) {
    switch (type) {
      case AccountType.cash:
        return NeoBrutalColors.primary;
      case AccountType.bank:
        return NeoBrutalColors.secondary;
      case AccountType.ewallet:
        return NeoBrutalColors.purple;
      case AccountType.other:
        return NeoBrutalColors.ink;
    }
  }
}

// ── Budget Overview Widget ──

// ── Budget Overview Widget ──
// ── Shared Dashboard Section Widget ──
class _DashboardSection extends StatelessWidget {
  const _DashboardSection({
    required this.color,
    required this.icon,
    required this.title,
    required this.child,
    this.onTap,
    this.trailing,
  });

  final Color color;
  final IconData icon;
  final String title;
  final Widget child;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: NeoCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Consistent header
            Row(
              children: [
                Container(
                  width: 6, height: 18, color: color,
                ),
                const SizedBox(width: 10),
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title,
                    style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                ),
                trailing ?? Icon(Icons.chevron_right_rounded, size: 20, color: NeoBrutalColors.muted),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

// ── Empty Section Placeholder ──
class _EmptySectionPlaceholder extends StatelessWidget {
  const _EmptySectionPlaceholder({required this.message, required this.ctaLabel, required this.color});
  final String message;
  final String ctaLabel;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(message,
            style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w600)),
        ),
        Text(ctaLabel,
          style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}

// ── Finance Sections - Vertical Scrollable with Auto Scroll ──
class _FinanceSectionsScrollable extends ConsumerStatefulWidget {
  @override
  ConsumerState<_FinanceSectionsScrollable> createState() => _FinanceSectionsScrollableState();
}

class _FinanceSectionsScrollableState extends ConsumerState<_FinanceSectionsScrollable> {
  late PageController _pageController;
  double _currentPage = 0;
  Timer? _autoScrollTimer;
  bool _userInteracting = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.85,
      initialPage: 10000,
    );
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page ?? 0;
      });
    });
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!_userInteracting && _pageController.hasClients) {
        final nextPage = _currentPage.round() + 1;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _onUserInteraction() {
    setState(() => _userInteracting = true);
    _autoScrollTimer?.cancel();
    // Resume auto scroll after 5 seconds of no interaction
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _userInteracting = false);
        _startAutoScroll();
      }
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final widgets = [
      _BudgetOverviewWidget(),
      _UpcomingRecurringWidget(),
      _SavingsProgressWidget(),
    ];

    return GestureDetector(
      onVerticalDragStart: (_) => _onUserInteraction(),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: null,
              onPageChanged: (_) => _onUserInteraction(),
              itemBuilder: (context, i) {
                final index = i % widgets.length;
                final diff = (i - _currentPage).abs();
                final scale = (1 - (diff * 0.08)).clamp(0.9, 1.0);
                final opacity = (1 - (diff * 0.3)).clamp(0.5, 1.0);

                return Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.002)
                    ..scaleByDouble(scale, scale, scale, 1.0),
                  alignment: Alignment.center,
                  child: Opacity(
                    opacity: opacity,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                      child: widgets[index],
                    ),
                  ),
                );
              },
            ),
          ),
          // Page dots
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widgets.length, (j) {
                final isActive = j == _currentPage.round() % widgets.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isActive ? 20 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: isActive ? NeoBrutalColors.secondary : NeoBrutalColors.muted,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Budget Overview Widget (Summary Only) ──
class _BudgetOverviewWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(budgetOverviewProvider);
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    if (list.isEmpty) {
      return _DashboardSection(
        color: NeoBrutalColors.green,
        icon: Icons.account_balance_wallet_rounded,
        title: 'BUDGET BULAN INI',
        onTap: () => AddBudgetSheet.show(context, year: DateTime.now().year, month: DateTime.now().month),
        child: const _EmptySectionPlaceholder(
          message: 'Atur budget untuk kontrol pengeluaran',
          ctaLabel: 'Atur →',
          color: NeoBrutalColors.green,
        ),
      );
    }

    double totalLimit = 0;
    double totalSpent = 0;
    for (final b in list) {
      totalLimit += b.budget.limitAmount;
      totalSpent += b.spent;
    }
    final totalPercent = totalLimit > 0 ? totalSpent / totalLimit : 0.0;
    final totalColor = totalPercent > 1.0
        ? NeoBrutalColors.danger
        : totalPercent >= 0.8 ? NeoBrutalColors.orange : NeoBrutalColors.success;
    final warnings = list.where((b) => b.percent >= 0.8).length;

    return _DashboardSection(
      color: totalColor,
      icon: Icons.account_balance_wallet_rounded,
      title: 'BUDGET BULAN INI',
      onTap: () => _showBudgetDetail(context, ref, list),
      trailing: Text('${(totalPercent * 100).toStringAsFixed(0)}%',
        style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w900, color: totalColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress bar
          SizedBox(
            height: 10,
            child: Stack(
              children: [
                Container(decoration: BoxDecoration(color: NeoBrutalColors.muted, border: Border.all(color: NeoBrutalColors.ink, width: 1))),
                FractionallySizedBox(widthFactor: totalPercent.clamp(0, 1), child: Container(color: totalColor)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text('${formatter.format(totalSpent)} / ${formatter.format(totalLimit)}',
            style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          // Summary text
          Text(
            'Anda memiliki ${list.length} budget bulan ini'
            '${warnings > 0 ? ', $warnings di antaranya mendekati/melebihi batas' : ''}',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: NeoBrutalColors.ink.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  void _showBudgetDetail(BuildContext context, WidgetRef ref, List<BudgetWithDetails> list) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('SEMUA BUDGET',
                        style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w900)),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: list.length,
                  itemBuilder: (ctx, i) {
                    final w = list[i];
                    final itemColor = w.isOver
                        ? NeoBrutalColors.danger
                        : w.isWarning ? NeoBrutalColors.orange : NeoBrutalColors.success;
                    return Dismissible(
                      key: ValueKey(w.budget.id),
                      direction: DismissDirection.horizontal,
                      background: Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 16),
                        color: NeoBrutalColors.secondary,
                        child: const Icon(Icons.edit_rounded, color: Colors.white),
                      ),
                      secondaryBackground: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        color: NeoBrutalColors.danger,
                        child: const Icon(Icons.delete_rounded, color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        HapticFeedback.mediumImpact();
                        if (direction == DismissDirection.startToEnd) {
                          _showEditBudgetDialog(context, ref, w);
                          return false;
                        }
                        return await _confirmDelete(context, 'Budget ${w.category.name}');
                      },
                      onDismissed: (_) {
                        ref.read(budgetListProvider.notifier).deleteBudget(w.budget.id);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(width: 4, height: 20, color: itemColor),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(w.category.name,
                                      style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700)),
                                ),
                                Text('${(w.percent * 100).toStringAsFixed(0)}%',
                                    style: GoogleFonts.spaceGrotesk(
                                        fontWeight: FontWeight.w900, color: itemColor)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: w.percent.clamp(0, 1),
                              backgroundColor: NeoBrutalColors.muted,
                              color: itemColor,
                            ),
                            const SizedBox(height: 2),
                            Text('${formatter.format(w.spent)} / ${formatter.format(w.budget.limitAmount)}',
                                style: GoogleFonts.spaceGrotesk(fontSize: 11)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    AddBudgetSheet.show(context, year: DateTime.now().year, month: DateTime.now().month);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: NeoBrutalColors.green,
                      border: Border.all(color: NeoBrutalColors.ink, width: 2),
                    ),
                    child: Center(
                      child: Text('+ TAMBAH BUDGET',
                          style: GoogleFonts.spaceGrotesk(
                              fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditBudgetDialog(BuildContext context, WidgetRef ref, BudgetWithDetails item) {
    final controller = TextEditingController(text: item.budget.limitAmount.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('EDIT BUDGET ${item.category.name.toUpperCase()}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Limit Baru (Rp)', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('BATAL')),
          TextButton(
            onPressed: () {
              final amount = double.tryParse(controller.text.replaceAll('.', ''));
              if (amount != null && amount > 0) {
                ref.read(budgetListProvider.notifier).updateBudget(item.budget.copyWith(limitAmount: amount));
                Navigator.pop(ctx);
              }
            },
            child: const Text('SIMPAN'),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, String name) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('HAPUS $name?'),
        content: const Text('Item ini akan dihapus permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('BATAL')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('HAPUS', style: TextStyle(color: NeoBrutalColors.danger)),
          ),
        ],
      ),
    ) ?? false;
  }
}

// ── Upcoming Recurring Widget (Summary Only) ──
class _UpcomingRecurringWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(upcomingRecurringProvider);
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    if (list.isEmpty) {
      return _DashboardSection(
        color: NeoBrutalColors.orange,
        icon: Icons.repeat_rounded,
        title: 'TAGIHAN BERULANG',
        onTap: () => AddRecurringSheet.show(context),
        child: const _EmptySectionPlaceholder(
          message: 'Atur tagihan & pemasukan rutin',
          ctaLabel: 'Atur →',
          color: NeoBrutalColors.orange,
        ),
      );
    }

    final dueCount = list.where((rt) => rt.nextDate.isBefore(DateTime.now())).length;
    final totalAmount = list.fold<double>(0, (sum, rt) => sum + rt.amount);

    return _DashboardSection(
      color: dueCount > 0 ? NeoBrutalColors.danger : NeoBrutalColors.orange,
      icon: Icons.repeat_rounded,
      title: 'TAGIHAN BERULANG',
      onTap: () => _showRecurringDetail(context, ref, list),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Anda memiliki ${list.length} tagihan berulang',
            style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Total: ${formatter.format(totalAmount)}/bulan'
            '${dueCount > 0 ? '\n$dueCount tagihan sudah jatuh tempo!' : ''}',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: dueCount > 0 ? NeoBrutalColors.danger : NeoBrutalColors.ink.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  void _showRecurringDetail(BuildContext context, WidgetRef ref, List<RecurringTransactionModel> list) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('SEMUA TAGIHAN',
                        style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w900)),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: list.length,
                  itemBuilder: (ctx, i) {
                    final rt = list[i];
                    final isDue = rt.nextDate.isBefore(DateTime.now());
                    final isIncome = rt.transactionType == 'income';
                    final daysUntil = rt.nextDate.difference(DateTime.now()).inDays;
                    String dueText = isDue ? 'JATUH TEMPO' : daysUntil == 0 ? 'Hari ini' : daysUntil == 1 ? 'Besok' : '$daysUntil hari lagi';

                    return Dismissible(
                      key: ValueKey(rt.id),
                      direction: DismissDirection.horizontal,
                      background: Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 16),
                        color: NeoBrutalColors.secondary,
                        child: const Icon(Icons.edit_rounded, color: Colors.white),
                      ),
                      secondaryBackground: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        color: NeoBrutalColors.danger,
                        child: const Icon(Icons.delete_rounded, color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        HapticFeedback.mediumImpact();
                        if (direction == DismissDirection.startToEnd) {
                          Navigator.pop(ctx);
                          await AddRecurringSheet.show(context, editItem: rt);
                          return false;
                        }
                        return await _confirmDelete(context, rt.note ?? 'Transaksi Berulang');
                      },
                      onDismissed: (_) {
                        ref.read(recurringListProvider.notifier).deleteRecurring(rt.id);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(
                                color: (isDue ? NeoBrutalColors.danger : NeoBrutalColors.orange).withValues(alpha: 0.15),
                                border: Border.all(color: isDue ? NeoBrutalColors.danger : NeoBrutalColors.orange, width: 1.5),
                              ),
                              child: Icon(isDue ? Icons.warning_amber_rounded : Icons.repeat_rounded, size: 16,
                                  color: isDue ? NeoBrutalColors.danger : NeoBrutalColors.orange),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(rt.note ?? 'Transaksi Berulang',
                                      style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w700)),
                                  Text('${rt.frequencyLabel} • ${DateFormat('dd MMM').format(rt.nextDate)}',
                                      style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${isIncome ? '+' : '-'}${formatter.format(rt.amount)}',
                                    style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w800,
                                        color: isIncome ? NeoBrutalColors.success : NeoBrutalColors.danger)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (isDue ? NeoBrutalColors.danger : NeoBrutalColors.orange).withValues(alpha: 0.15),
                                    border: Border.all(color: isDue ? NeoBrutalColors.danger : NeoBrutalColors.orange, width: 1),
                                  ),
                                  child: Text(dueText,
                                      style: GoogleFonts.spaceGrotesk(fontSize: 9, fontWeight: FontWeight.w900,
                                          color: isDue ? NeoBrutalColors.danger : NeoBrutalColors.orange)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    AddRecurringSheet.show(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: NeoBrutalColors.orange,
                      border: Border.all(color: NeoBrutalColors.ink, width: 2),
                    ),
                    child: Center(
                      child: Text('+ TAMBAH TAGIHAN',
                          style: GoogleFonts.spaceGrotesk(
                              fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, String name) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('HAPUS $name?'),
        content: const Text('Item ini akan dihapus permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('BATAL')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('HAPUS', style: TextStyle(color: NeoBrutalColors.danger)),
          ),
        ],
      ),
    ) ?? false;
  }
}

// ── Savings Progress Widget (Summary Only) ──
class _SavingsProgressWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(savingsGoalsDashboardProvider);
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    if (list.isEmpty) {
      return _DashboardSection(
        color: NeoBrutalColors.secondary,
        icon: Icons.savings_rounded,
        title: 'TARGET MENABUNG',
        onTap: () => AddSavingsSheet.show(context),
        child: const _EmptySectionPlaceholder(
          message: 'Buat target untuk capai tujuanmu',
          ctaLabel: 'Buat →',
          color: NeoBrutalColors.secondary,
        ),
      );
    }

    final completedCount = list.where((g) => g.isComplete).length;
    final totalSaved = list.fold<double>(0, (sum, g) => sum + g.savedAmount);
    final totalTarget = list.fold<double>(0, (sum, g) => sum + g.targetAmount);

    return _DashboardSection(
      color: NeoBrutalColors.secondary,
      icon: Icons.savings_rounded,
      title: 'TARGET MENABUNG',
      onTap: () => _showSavingsDetail(context, ref, list),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Anda memiliki ${list.length} target menabung',
            style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Terkumpul: ${formatter.format(totalSaved)} / ${formatter.format(totalTarget)}'
            '${completedCount > 0 ? '\n$completedCount target sudah tercapai!' : ''}',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: completedCount > 0 ? NeoBrutalColors.success : NeoBrutalColors.ink.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  void _showSavingsDetail(BuildContext context, WidgetRef ref, List<SavingsGoalModel> list) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('SEMUA TARGET',
                        style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w900)),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: list.length,
                  itemBuilder: (ctx, i) {
                    final goal = list[i];
                    final statusColor = goal.isComplete
                        ? NeoBrutalColors.success
                        : goal.percent >= 0.8 ? NeoBrutalColors.orange : NeoBrutalColors.secondary;

                    return Dismissible(
                      key: ValueKey(goal.id),
                      direction: DismissDirection.horizontal,
                      background: Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 16),
                        color: NeoBrutalColors.success,
                        child: const Icon(Icons.savings_rounded, color: Colors.white),
                      ),
                      secondaryBackground: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        color: NeoBrutalColors.danger,
                        child: const Icon(Icons.delete_rounded, color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        HapticFeedback.mediumImpact();
                        if (direction == DismissDirection.startToEnd) {
                          Navigator.pop(ctx);
                          _showContributionDialog(context, ref, goal);
                          return false;
                        }
                        return await _confirmDelete(context, goal.name);
                      },
                      onDismissed: (_) {
                        ref.read(savingsListProvider.notifier).deleteGoal(goal.id);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 32, height: 32,
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.15),
                                    border: Border.all(color: statusColor, width: 1.5),
                                  ),
                                  child: Icon(goal.isComplete ? Icons.check_circle_rounded : Icons.savings_rounded,
                                      size: 16, color: statusColor),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(goal.name,
                                          style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w700)),
                                      Text('${formatter.format(goal.savedAmount)} / ${formatter.format(goal.targetAmount)}',
                                          style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ),
                                Text('${(goal.percent * 100).toStringAsFixed(0)}%',
                                    style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w900, color: statusColor)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            LinearProgressIndicator(
                              value: goal.percent.clamp(0, 1),
                              backgroundColor: NeoBrutalColors.muted,
                              color: statusColor,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    AddSavingsSheet.show(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: NeoBrutalColors.secondary,
                      border: Border.all(color: NeoBrutalColors.ink, width: 2),
                    ),
                    child: Center(
                      child: Text('+ BUAT TARGET',
                          style: GoogleFonts.spaceGrotesk(
                              fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, String name) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('HAPUS TARGET "$name"?'),
        content: const Text('Target dan semua kontribusi akan dihapus permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('BATAL')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('HAPUS', style: TextStyle(color: NeoBrutalColors.danger)),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showContributionDialog(BuildContext context, WidgetRef ref, SavingsGoalModel goal) {
    final controller = TextEditingController();
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    final remaining = goal.targetAmount - goal.savedAmount;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('TAMBAH TABUNGAN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(goal.name, style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Sisa: ${formatter.format(remaining)}',
                style: GoogleFonts.spaceGrotesk(fontSize: 12, color: NeoBrutalColors.muted)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Jumlah (Rp)',
                border: OutlineInputBorder(),
                prefixText: 'Rp ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('BATAL')),
          TextButton(
            onPressed: () {
              final amount = double.tryParse(controller.text.replaceAll('.', ''));
              if (amount != null && amount > 0) {
                final repo = SavingsGoalRepo();
                ref.read(savingsListProvider.notifier).addContribution(
                  SavingsContributionModel(
                    id: repo.newContribId(),
                    goalId: goal.id,
                    amount: amount,
                    date: DateTime.now(),
                  ),
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Berhasil menambah ${formatter.format(amount)}')),
                );
              }
            },
            child: const Text('TAMBAH'),
          ),
        ],
      ),
    );
  }
}

// ── Recent Transactions ──
class _RecentTransactionsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txs = ref.watch(recentTransactionsProvider); // Now sync Provider
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('TRANSAKSI TERBARU',
          style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5),
        ),
        const SizedBox(height: 12),
        if (txs.isEmpty)
          NeoCard(
            child: Center(
              child: Text('Belum ada transaksi',
                style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          )
        else
          Column(
            children: txs.map((tx) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: NeoCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      tx.type == TransactionType.income
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded,
                      color: tx.type == TransactionType.income
                          ? NeoBrutalColors.success
                          : NeoBrutalColors.danger,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tx.note ?? 'Transaksi',
                            style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                          Text(DateFormat('dd MMM yyyy').format(tx.date),
                            style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${tx.type == TransactionType.income ? '+' : '-'}${formatter.format(tx.amount)}',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: tx.type == TransactionType.income
                            ? NeoBrutalColors.success
                            : NeoBrutalColors.danger,
                      ),
                    ),
                  ],
                ),
              ),
            )).toList(),
          ),
      ],
    );
  }
}
