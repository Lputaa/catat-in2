import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/neo_brutal_colors.dart';
import '../../data/models/budget_model.dart';
import '../../data/models/category_model.dart';
import '../../data/notifiers/dashboard_providers.dart';
import '../../data/repositories/budget_repo.dart';
import '../../data/repositories/category_repo.dart';
import '../../data/repositories/transaction_repo.dart';
import '../../shared/widgets/catat_in_app_bar.dart';
import '../../shared/widgets/neo_card.dart';
import '../../shared/widgets/neo_button.dart';
import 'add_budget_screen.dart';
import 'quick_budget_screen.dart';

// ── Providers ──
final selectedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

final budgetsProvider = FutureProvider.family<List<BudgetModel>, DateTime>((ref, month) {
  return BudgetRepo().getByMonth(month.year, month.month);
});

class _BudgetItem {
  final BudgetModel budget;
  final CategoryModel category;
  final double spent;

  _BudgetItem({required this.budget, required this.category, required this.spent});

  double get percent => budget.limitAmount > 0 ? spent / budget.limitAmount : 0;
  bool get isOver => percent > 1.0;
  bool get isWarning => percent >= 0.8 && percent <= 1.0;
}

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final budgets = ref.watch(budgetsProvider(month));

    return Scaffold(
      appBar: const CatatInAppBar(subtitle: 'Budget'),
      body: budgets.when(
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.account_balance_wallet_rounded, size: 64, color: NeoBrutalColors.muted),
                    const SizedBox(height: 16),
                    Text(
                      'BELUM ADA BUDGET',
                      style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Atur budget untuk mengontrol pengeluaran',
                      style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: NeoButton(
                        label: 'ATUR BUDGET CEPAT',
                        icon: Icons.bolt_rounded,
                        color: NeoBrutalColors.yellow,
                        onTap: () => _openQuickBudget(context, ref, month),
                      ),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => _openAddBudget(context, ref, month),
                      child: Text(
                        'Atur satu per satu',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return _BudgetList(items: list, month: month);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: NeoBrutalColors.yellow,
        onPressed: () => _openAddBudget(context, ref, month),
        child: const Icon(Icons.add_rounded, color: NeoBrutalColors.ink),
      ),
    );
  }

  void _openAddBudget(BuildContext context, WidgetRef ref, DateTime month) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddBudgetScreen(year: month.year, month: month.month),
      ),
    );
    if (result == true) {
      ref.invalidate(budgetsProvider(month));
      ref.invalidate(budgetOverviewProvider);
    }
  }

  void _openQuickBudget(BuildContext context, WidgetRef ref, DateTime month) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const QuickBudgetScreen()),
    );
    if (result == true) {
      ref.invalidate(budgetsProvider(month));
      ref.invalidate(budgetOverviewProvider);
    }
  }
}

class _BudgetList extends ConsumerStatefulWidget {
  const _BudgetList({required this.items, required this.month});
  final List<BudgetModel> items;
  final DateTime month;

  @override
  ConsumerState<_BudgetList> createState() => _BudgetListState();
}

class _BudgetListState extends ConsumerState<_BudgetList> {
  List<_BudgetItem> _details = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final catRepo = CategoryRepo();
    final txRepo = TransactionRepo();
    final result = <_BudgetItem>[];

    for (final b in widget.items) {
      final cat = await catRepo.getById(b.categoryId);
      if (cat == null) continue;
      final spent = await txRepo.getCategoryTotal(b.categoryId, b.year, b.month);
      result.add(_BudgetItem(budget: b, category: cat, spent: spent));
    }

    setState(() {
      _details = result;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    return Column(
      children: [
        // Month selector
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {
                  final m = widget.month;
                  ref.read(selectedMonthProvider.notifier).state =
                      DateTime(m.year, m.month - 1);
                },
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Text(
                DateFormat('MMMM yyyy', 'id_ID').format(widget.month).toUpperCase(),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
              IconButton(
                onPressed: () {
                  final m = widget.month;
                  ref.read(selectedMonthProvider.notifier).state =
                      DateTime(m.year, m.month + 1);
                },
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _details.length,
            itemBuilder: (context, i) {
              final item = _details[i];
              final remaining = item.budget.limitAmount - item.spent;
              final statusColor = item.isOver
                  ? NeoBrutalColors.danger
                  : item.isWarning
                      ? NeoBrutalColors.orange
                      : NeoBrutalColors.success;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Dismissible(
                  key: ValueKey(item.budget.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    color: NeoBrutalColors.danger,
                    child: const Icon(Icons.delete_rounded, color: Colors.white, size: 28),
                  ),
                  confirmDismiss: (_) async {
                    HapticFeedback.mediumImpact();
                    return true;
                  },
                  onDismissed: (_) async {
                    await BudgetRepo().delete(item.budget.id);
                    ref.invalidate(budgetsProvider(widget.month));
                    ref.invalidate(budgetOverviewProvider);
                    ref.invalidate(totalBalanceProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Budget dihapus')),
                      );
                    }
                  },
                  child: GestureDetector(
                    onTap: () => _editBudget(context, ref, item),
                    child: NeoCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: item.category.colorValue.withValues(alpha: 0.15),
                                border: Border.all(color: item.category.colorValue, width: 2),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.category_rounded,
                                  size: 18,
                                  color: item.category.colorValue,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item.category.name.toUpperCase(),
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Text(
                              '${formatter.format(item.spent)} / ${formatter.format(item.budget.limitAmount)}',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 12,
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: NeoBrutalColors.muted,
                                  border: Border.all(color: NeoBrutalColors.ink, width: 1.5),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: item.percent.clamp(0, 1),
                                child: Container(color: statusColor),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item.isOver
                                  ? 'MELEBIHI ${formatter.format(-remaining)}'
                                  : 'SISA ${formatter.format(remaining)}',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                            Text(
                              '${(item.percent * 100).toStringAsFixed(0)}%',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: statusColor,
                              ),
                            ),
                          ],
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
      ],
    );
  }

  void _editBudget(BuildContext context, WidgetRef ref, _BudgetItem item) {
    final controller = TextEditingController(text: item.budget.limitAmount.toStringAsFixed(0));
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: const Border(top: BorderSide(color: NeoBrutalColors.ink, width: 3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('EDIT BUDGET', style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
              const SizedBox(height: 8),
              Text(item.category.name, style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w700),
                decoration: const InputDecoration(
                  labelText: 'Limit Budget (Rp)',
                  prefixIcon: Icon(Icons.payments_rounded),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: NeoButton(
                  label: 'SIMPAN PERUBAHAN',
                  icon: Icons.check_circle_outline_rounded,
                  color: NeoBrutalColors.success,
                  onTap: () async {
                    final amount = double.tryParse(controller.text.replaceAll('.', '').replaceAll(',', ''));
                    if (amount == null || amount <= 0) return;
                    HapticFeedback.mediumImpact();
                    await BudgetRepo().update(item.budget.copyWith(limitAmount: amount));
                    if (context.mounted) {
                      Navigator.pop(context);
                      ref.invalidate(budgetsProvider(widget.month));
                      ref.invalidate(budgetOverviewProvider);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
