import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/neo_brutal_colors.dart';
import '../../core/theme/neo_brutal_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/transaction_filter_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/account_model.dart';
import '../../data/notifiers/transaction_list_notifier.dart';
import '../../data/repositories/category_repo.dart';
import '../../data/repositories/account_repo.dart';
import '../../shared/widgets/catat_in_app_bar.dart';
import '../../shared/widgets/neo_card.dart';
import '../../shared/widgets/neo_button.dart';
import 'add_transaction_sheet.dart';
import 'filter_bottom_sheet.dart';

// ── Providers ──
final _categoryMapProvider =
    FutureProvider<Map<String, CategoryModel>>((ref) async {
  final cats = await CategoryRepo().getAll();
  return {for (final c in cats) c.id: c};
});

final _accountsProvider = FutureProvider<List<AccountModel>>((ref) {
  return AccountRepo().getAll();
});

final _accountMapProvider =
    FutureProvider<Map<String, AccountModel>>((ref) async {
  final accs = await AccountRepo().getAll();
  return {for (final a in accs) a.id: a};
});

// ── Main Screen ──
class TransactionScreen extends ConsumerStatefulWidget {
  const TransactionScreen({super.key});

  @override
  ConsumerState<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends ConsumerState<TransactionScreen> {
  bool _showSearch = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _searchController.clear();
        ref.read(transactionListProvider.notifier).setSearchQuery('');
      }
    });
  }

  void _onSearchChanged(String query) {
    ref.read(transactionListProvider.notifier).setSearchQuery(query);
  }

  @override
  Widget build(BuildContext context) {
    final txState = ref.watch(transactionListProvider);
    final filteredTxs = ref.watch(filteredTransactionsProvider);
    final summary = ref.watch(transactionSummaryProvider);
    final catMap = ref.watch(_categoryMapProvider);
    final accMap = ref.watch(_accountMapProvider);
    final accounts = ref.watch(_accountsProvider);
    final filter = txState.filter;
    final formatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    return Scaffold(
      appBar: CatatInAppBar(
        subtitle: 'Transaksi',
        actions: [
          IconButton(
            icon: Icon(
              _showSearch ? Icons.close_rounded : Icons.search_rounded,
              color: NeoBrutalColors.ink,
            ),
            onPressed: _toggleSearch,
          ),
          IconButton(
            icon: Icon(
              Icons.filter_list_rounded,
              color: filter.isFiltered
                  ? NeoBrutalColors.primary
                  : NeoBrutalColors.ink,
            ),
            onPressed: () {
              HapticFeedback.mediumImpact();
              FilterBottomSheet.show(
                context: context,
                currentFilter: filter,
                accounts: accounts.valueOrNull ?? [],
                onApply: (f) =>
                    ref.read(transactionListProvider.notifier).applyFilter(f),
                onReset: () =>
                    ref.read(transactionListProvider.notifier).resetFilter(),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar (expandable)
          if (_showSearch)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: NeoCard(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                borderOn: true,
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded,
                        size: 20, color: NeoBrutalColors.muted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Cari transaksi...',
                          hintStyle: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: NeoBrutalColors.muted,
                          ),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                        child: const Icon(Icons.close_rounded,
                            size: 18, color: NeoBrutalColors.muted),
                      ),
                  ],
                ),
              ),
            ),

          // Filter bar
          _buildFilterBar(filter),

          // Summary card
          if (filteredTxs.isNotEmpty) _buildSummaryCard(summary, formatter),

          // Loading indicator
          if (txState.isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),

          // Error state
          if (txState.error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'Error: ${txState.error}',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    color: NeoBrutalColors.danger,
                  ),
                ),
              ),
            ),

          // Transaction list
          if (!txState.isLoading && txState.error == null)
            Expanded(
              child: filteredTxs.isEmpty
                  ? _buildEmptyState(filter)
                  : _buildGroupedList(
                      filteredTxs, catMap, accMap, formatter),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(TransactionFilterState filter) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Type filter - 3D Segmented
          Expanded(
            child: _ThreeDSegmentedControl(
              selected: filter.typeFilter,
              onChanged: (type) => ref
                  .read(transactionListProvider.notifier)
                  .setTypeFilter(type),
            ),
          ),
          const SizedBox(width: 8),
          // Date range
          GestureDetector(
            onTap: () async {
              HapticFeedback.selectionClick();
              final now = DateTime.now();
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime(now.year + 1),
                initialDateRange: filter.dateRange,
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: Theme.of(context).colorScheme.copyWith(
                            primary: NeoBrutalColors.primary,
                            onPrimary: Colors.white,
                          ),
                    ),
                    child: child!,
                  );
                },
              );
              ref.read(transactionListProvider.notifier).setDateRange(picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: filter.hasDateRange
                    ? NeoBrutalColors.secondary.withValues(alpha: 0.15)
                    : NeoBrutalColors.surface,
                border: Border.all(
                  color: filter.hasDateRange
                      ? NeoBrutalColors.secondary
                      : NeoBrutalColors.ink,
                  width: AppConstants.borderSecondary,
                ),
                boxShadow: NeoBrutalTheme.hardShadow(
                  offset: const Offset(3, 3),
                  brightness: Theme.of(context).brightness,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 14,
                    color: filter.hasDateRange
                        ? NeoBrutalColors.secondary
                        : NeoBrutalColors.ink,
                  ),
                  if (filter.hasDateRange) ...[
                    const SizedBox(width: 4),
                    Text(
                      filter.dateRangeLabel,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: NeoBrutalColors.secondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      TransactionSummary summary, NumberFormat formatter) {
    final isPositive = summary.net >= 0;
    final brightness = Theme.of(context).brightness;
    final borderColor = NeoBrutalTheme.borderColor(brightness);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        children: [
          // Net bar di atas
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
            decoration: BoxDecoration(
              color: isPositive ? NeoBrutalColors.success : NeoBrutalColors.danger,
              border: Border.all(color: borderColor, width: AppConstants.borderSecondary),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 6),
                Text(
                  'NET ${isPositive ? '+' : ''}${formatter.format(summary.net)}',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Card Masuk & Keluar
          NeoCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Masuk
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            color: NeoBrutalColors.success,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'MASUK',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '+${formatter.format(summary.income)}',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: NeoBrutalColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
                // Divider
                Container(
                  width: 1,
                  height: 40,
                  color: borderColor,
                ),
                // Keluar
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              color: NeoBrutalColors.danger,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'KELUAR',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '-${formatter.format(summary.expense)}',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: NeoBrutalColors.danger,
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
      ),
    );
  }

  Widget _buildGroupedList(
    List<TransactionModel> list,
    AsyncValue<Map<String, CategoryModel>> catMap,
    AsyncValue<Map<String, AccountModel>> accMap,
    NumberFormat formatter,
  ) {
    final cats = catMap.valueOrNull ?? {};
    final accs = accMap.valueOrNull ?? {};

    // Group by date
    final groups = <String, List<TransactionModel>>{};
    for (final tx in list) {
      final dateKey = DateFormat('yyyy-MM-dd').format(tx.date);
      groups.putIfAbsent(dateKey, () => []);
      groups[dateKey]!.add(tx);
    }

    final sortedKeys = groups.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final dateKey = sortedKeys[index];
        final txs = groups[dateKey]!;
        final date = DateTime.parse(dateKey);
        final dayTotal = txs.fold<double>(
          0,
          (sum, tx) =>
              sum +
              (tx.type == TransactionType.income ? tx.amount : -tx.amount),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Text(
                    _formatDateHeader(date),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${dayTotal >= 0 ? '+' : ''}${formatter.format(dayTotal)}',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: dayTotal >= 0
                          ? NeoBrutalColors.success
                          : NeoBrutalColors.danger,
                    ),
                  ),
                ],
              ),
            ),
            // Transactions for this date
            ...txs.map((tx) => _buildTransactionItem(tx, cats, accs, formatter)),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return 'HARI INI';
    if (dateOnly == yesterday) return 'KEMARIN';

    return DateFormat('EEEE, dd MMMM yyyy', 'id_ID')
        .format(date)
        .toUpperCase();
  }

  Widget _buildTransactionItem(
    TransactionModel tx,
    Map<String, CategoryModel> cats,
    Map<String, AccountModel> accs,
    NumberFormat formatter,
  ) {
    final cat = cats[tx.categoryId];
    final acc = accs[tx.accountId];
    final isIncome = tx.type == TransactionType.income;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Dismissible(
        key: ValueKey(tx.id),
        direction: DismissDirection.horizontal,
        // Swipe right = Edit
        secondaryBackground: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          color: NeoBrutalColors.danger,
          child:
              const Icon(Icons.delete_rounded, color: Colors.white, size: 28),
        ),
        // Swipe left = Delete
        background: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 24),
          color: NeoBrutalColors.secondary,
          child: const Icon(Icons.edit_rounded, color: Colors.white, size: 28),
        ),
        confirmDismiss: (direction) async {
          HapticFeedback.mediumImpact();
          if (direction == DismissDirection.startToEnd) {
            // Swipe right = Edit
            _openEditScreen(context, ref, tx);
            return false; // Don't dismiss
          }
          return true; // Swipe left = Delete
        },
        onDismissed: (_) async {
          // Backup for undo
          final backup = tx;
          await ref
              .read(transactionListProvider.notifier)
              .deleteTransaction(tx.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Transaksi dihapus'),
                action: SnackBarAction(
                  label: 'URUNGKAN',
                  textColor: NeoBrutalColors.yellow,
                  onPressed: () async {
                    await ref
                        .read(transactionListProvider.notifier)
                        .undoDelete(backup);
                  },
                ),
                duration: const Duration(seconds: 6),
              ),
            );
          }
        },
        child: GestureDetector(
          onTap: () => _openEditScreen(context, ref, tx),
          child: NeoCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                // Type indicator
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isIncome
                        ? NeoBrutalColors.success.withValues(alpha: 0.15)
                        : NeoBrutalColors.danger.withValues(alpha: 0.15),
                    border: Border.all(
                      color: isIncome
                          ? NeoBrutalColors.success
                          : NeoBrutalColors.danger,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    isIncome
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded,
                    color: isIncome
                        ? NeoBrutalColors.success
                        : NeoBrutalColors.danger,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx.note ?? 'Transaksi',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          if (cat != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: cat.colorValue, width: 1.5),
                              ),
                              child: Text(
                                cat.name.toUpperCase(),
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                  color: cat.colorValue,
                                ),
                              ),
                            ),
                            const SizedBox(width: 5),
                          ],
                          if (acc != null)
                            Text(
                              acc.name,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: NeoBrutalColors.muted,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Amount
                Text(
                  '${isIncome ? '+' : '-'}${formatter.format(tx.amount)}',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isIncome
                        ? NeoBrutalColors.success
                        : NeoBrutalColors.danger,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(TransactionFilterState filter) {
    final isFiltered = filter.isFiltered;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isFiltered
                  ? Icons.search_off_rounded
                  : Icons.receipt_long_rounded,
              size: 64,
              color: NeoBrutalColors.muted,
            ),
            const SizedBox(height: 16),
            Text(
              isFiltered ? 'TIDAK ADA TRANSAKSI' : 'BELUM ADA TRANSAKSI',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isFiltered
                  ? 'Coba ubah filter atau tambah transaksi baru'
                  : 'Tekan tombol + untuk memulai',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: NeoBrutalColors.muted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (isFiltered)
              NeoButton(
                label: 'Reset Filter',
                icon: Icons.filter_list_off_rounded,
                color: NeoBrutalColors.secondary,
                onTap: () =>
                    ref.read(transactionListProvider.notifier).resetFilter(),
              ),
          ],
        ),
      ),
    );
  }

  void _openEditScreen(
      BuildContext context, WidgetRef ref, TransactionModel tx) async {
    final result = await AddTransactionSheet.show(context, editTransaction: tx);
    if (result == true) {
      // Refresh from DB to sync any changes
      ref.read(transactionListProvider.notifier).refresh();
    }
  }
}

// ── 3D Segmented Control Widget ──
class _ThreeDSegmentedControl extends StatelessWidget {
  const _ThreeDSegmentedControl({
    required this.selected,
    required this.onChanged,
  });

  final TransactionTypeFilter selected;
  final ValueChanged<TransactionTypeFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final borderColor = NeoBrutalTheme.borderColor(brightness);

    final items = [
      (TransactionTypeFilter.all, 'Semua', NeoBrutalColors.yellow),
      (TransactionTypeFilter.income, 'Masuk', NeoBrutalColors.success),
      (TransactionTypeFilter.expense, 'Keluar', NeoBrutalColors.danger),
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
            color: borderColor, width: AppConstants.borderPrimary),
        boxShadow: [
          BoxShadow(
            color: borderColor,
            offset: AppConstants.shadowSmall,
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: items.map((item) {
          final isSelected = selected == item.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(item.$1);
              },
              child: AnimatedContainer(
                duration: AppConstants.animButton,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? item.$3 : NeoBrutalColors.surface,
                  border: Border(
                    right: BorderSide(
                      color: borderColor,
                      width: AppConstants.borderSecondary,
                    ),
                  ),
                  boxShadow: isSelected
                      ? []
                      : [
                          BoxShadow(
                            color: borderColor.withValues(alpha: 0.3),
                            offset: const Offset(2, 2),
                            blurRadius: 0,
                          ),
                        ],
                ),
                transform: isSelected
                    ? (Matrix4.identity()
                      ..translateByDouble(1.0, 1.0, 0.0, 1.0))
                    : Matrix4.identity(),
                child: Center(
                  child: Text(
                    item.$2.toUpperCase(),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      fontWeight:
                          isSelected ? FontWeight.w900 : FontWeight.w700,
                      letterSpacing: 0.8,
                      color: isSelected
                          ? (item.$3 == NeoBrutalColors.yellow
                              ? NeoBrutalColors.ink
                              : Colors.white)
                          : NeoBrutalColors.ink,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
