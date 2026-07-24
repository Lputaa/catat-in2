import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/neo_brutal_colors.dart';
import '../../core/theme/neo_brutal_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/transaction_filter_model.dart';
import '../../data/models/account_model.dart';

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({
    super.key,
    required this.initialFilter,
    required this.accounts,
    required this.onApply,
    required this.onReset,
  });

  final TransactionFilterState initialFilter;
  final List<AccountModel> accounts;
  final ValueChanged<TransactionFilterState> onApply;
  final VoidCallback onReset;

  static Future<void> show({
    required BuildContext context,
    required TransactionFilterState currentFilter,
    required List<AccountModel> accounts,
    required ValueChanged<TransactionFilterState> onApply,
    required VoidCallback onReset,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: FilterBottomSheet(
          initialFilter: currentFilter,
          accounts: accounts,
          onApply: onApply,
          onReset: onReset,
        ),
      ),
    );
  }

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late TransactionTypeFilter _typeFilter;
  late DateTimeRange? _dateRange;
  late String? _accountId;
  late SortOrder _sortOrder;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _typeFilter = widget.initialFilter.typeFilter;
    _dateRange = widget.initialFilter.dateRange;
    _accountId = widget.initialFilter.accountId;
    _sortOrder = widget.initialFilter.sortOrder;
  }

  void _apply() {
    HapticFeedback.mediumImpact();
    widget.onApply(TransactionFilterState(
      typeFilter: _typeFilter,
      dateRange: _dateRange,
      accountId: _accountId,
      sortOrder: _sortOrder,
      searchQuery: widget.initialFilter.searchQuery,
    ));
    Navigator.pop(context);
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    widget.onReset();
    Navigator.pop(context);
  }

  void _selectDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _dateRange,
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
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final borderColor = NeoBrutalTheme.borderColor(brightness);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
        maxWidth: 420,
      ),
      decoration: BoxDecoration(
        color: brightness == Brightness.light
            ? NeoBrutalColors.bg
            : NeoBrutalColors.bgDark,
        border: Border.all(
          color: borderColor,
          width: AppConstants.borderPrimary,
        ),
        boxShadow: [
          BoxShadow(
            color: borderColor,
            offset: AppConstants.shadowLarge,
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Color accent bar
          Container(
            height: 8,
            color: NeoBrutalColors.secondary,
          ),

          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 14, 14),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                    color: borderColor, width: AppConstants.borderSecondary),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: NeoBrutalColors.secondary,
                    border: Border.all(
                        color: borderColor,
                        width: AppConstants.borderSecondary),
                  ),
                  child: const Icon(
                    Icons.filter_list_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'FILTER TRANSAKSI',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                // Reset button
                GestureDetector(
                  onTap: _reset,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: NeoBrutalColors.danger.withValues(alpha: 0.1),
                      border: Border.all(
                          color: NeoBrutalColors.danger,
                          width: AppConstants.borderSecondary),
                    ),
                    child: Text(
                      'RESET',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: NeoBrutalColors.danger,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Close button with 3D effect
                GestureDetector(
                  onTapDown: (_) => setState(() => _pressed = true),
                  onTapUp: (_) {
                    setState(() => _pressed = false);
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                  },
                  onTapCancel: () => setState(() => _pressed = false),
                  child: AnimatedContainer(
                    duration: AppConstants.animButton,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: borderColor,
                          width: AppConstants.borderSecondary),
                      boxShadow: _pressed
                          ? []
                          : [
                              BoxShadow(
                                color: borderColor,
                                offset: const Offset(2, 2),
                                blurRadius: 0,
                              ),
                            ],
                    ),
                    transform: _pressed
                        ? (Matrix4.identity()
                          ..translateByDouble(2.0, 2.0, 0.0, 1.0))
                        : Matrix4.identity(),
                    child: const Icon(Icons.close_rounded, size: 18),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('TIPE'),
                  const SizedBox(height: 10),
                  _buildTypeFilter(borderColor),
                  const SizedBox(height: 20),

                  _buildSectionTitle('RENTANG TANGGAL'),
                  const SizedBox(height: 10),
                  _buildDateFilter(borderColor),
                  const SizedBox(height: 20),

                  _buildSectionTitle('AKUN'),
                  const SizedBox(height: 10),
                  _buildAccountFilter(borderColor),
                  const SizedBox(height: 20),

                  _buildSectionTitle('URUTAN'),
                  const SizedBox(height: 10),
                  _buildSortFilter(borderColor),
                ],
              ),
            ),
          ),

          // Apply button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                    color: borderColor, width: AppConstants.borderSecondary),
              ),
            ),
            child: GestureDetector(
              onTap: _apply,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: NeoBrutalColors.primary,
                  border: Border.all(
                      color: borderColor, width: AppConstants.borderPrimary),
                  boxShadow: [
                    BoxShadow(
                      color: borderColor,
                      offset: AppConstants.shadowDefault,
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_rounded,
                        size: 18, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'TERAPKAN FILTER',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.spaceGrotesk(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 2.0,
        color: NeoBrutalColors.ink.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildTypeFilter(Color borderColor) {
    return Row(
      children: [
        _buildFilterChip(
          'Semua',
          _typeFilter == TransactionTypeFilter.all,
          () => setState(() => _typeFilter = TransactionTypeFilter.all),
          borderColor,
        ),
        const SizedBox(width: 8),
        _buildFilterChip(
          'Pemasukan',
          _typeFilter == TransactionTypeFilter.income,
          () => setState(() => _typeFilter = TransactionTypeFilter.income),
          borderColor,
          activeColor: NeoBrutalColors.success,
        ),
        const SizedBox(width: 8),
        _buildFilterChip(
          'Pengeluaran',
          _typeFilter == TransactionTypeFilter.expense,
          () => setState(() => _typeFilter = TransactionTypeFilter.expense),
          borderColor,
          activeColor: NeoBrutalColors.danger,
        ),
      ],
    );
  }

  Widget _buildDateFilter(Color borderColor) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final presets = [
      (
        'Hari Ini',
        DateTimeRange(
            start: today, end: today.add(const Duration(days: 1)))
      ),
      (
        '7 Hari',
        DateTimeRange(
            start: today.subtract(const Duration(days: 6)),
            end: today.add(const Duration(days: 1)))
      ),
      (
        'Bulan Ini',
        DateTimeRange(
            start: DateTime(now.year, now.month, 1),
            end: DateTime(now.year, now.month + 1, 1))
      ),
    ];

    final isCustomDate = _dateRange != null &&
        !presets.any((p) =>
            _dateRange!.start == p.$2.start &&
            _dateRange!.end == p.$2.end);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...presets.map((preset) {
          final isActive = _dateRange != null &&
              _dateRange!.start == preset.$2.start &&
              _dateRange!.end == preset.$2.end;
          return _buildFilterChip(
            preset.$1,
            isActive,
            () => setState(() {
              _dateRange = isActive ? null : preset.$2;
            }),
            borderColor,
            activeColor: NeoBrutalColors.secondary,
          );
        }),
        GestureDetector(
          onTap: _selectDateRange,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isCustomDate
                  ? NeoBrutalColors.secondary
                  : Colors.transparent,
              border: Border.all(
                color: borderColor,
                width: AppConstants.borderSecondary,
              ),
              boxShadow: isCustomDate
                  ? []
                  : [
                      BoxShadow(
                        color: borderColor,
                        offset: const Offset(3, 3),
                        blurRadius: 0,
                      ),
                    ],
            ),
            transform: isCustomDate
                ? (Matrix4.identity()
                  ..translateByDouble(1.5, 1.5, 0.0, 1.0))
                : Matrix4.identity(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 14,
                  color:
                      isCustomDate ? Colors.white : NeoBrutalColors.ink,
                ),
                const SizedBox(width: 6),
                Text(
                  isCustomDate
                      ? '${_dateRange!.start.day}/${_dateRange!.start.month} - ${_dateRange!.end.day}/${_dateRange!.end.month}'
                      : 'Custom',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    fontWeight:
                        isCustomDate ? FontWeight.w900 : FontWeight.w600,
                    color:
                        isCustomDate ? Colors.white : NeoBrutalColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountFilter(Color borderColor) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildFilterChip(
          'Semua',
          _accountId == null,
          () => setState(() => _accountId = null),
          borderColor,
        ),
        ...widget.accounts.map((acc) => _buildFilterChip(
              acc.name,
              _accountId == acc.id,
              () => setState(() => _accountId = acc.id),
              borderColor,
              activeColor: NeoBrutalColors.secondary,
            )),
      ],
    );
  }

  Widget _buildSortFilter(Color borderColor) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildFilterChip(
          'Terbaru',
          _sortOrder == SortOrder.newest,
          () => setState(() => _sortOrder = SortOrder.newest),
          borderColor,
        ),
        _buildFilterChip(
          'Terlama',
          _sortOrder == SortOrder.oldest,
          () => setState(() => _sortOrder = SortOrder.oldest),
          borderColor,
        ),
        _buildFilterChip(
          'Terbesar',
          _sortOrder == SortOrder.largest,
          () => setState(() => _sortOrder = SortOrder.largest),
          borderColor,
        ),
        _buildFilterChip(
          'Terkecil',
          _sortOrder == SortOrder.smallest,
          () => setState(() => _sortOrder = SortOrder.smallest),
          borderColor,
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    String label,
    bool isActive,
    VoidCallback onTap,
    Color borderColor, {
    Color? activeColor,
  }) {
    final color = activeColor ?? NeoBrutalColors.yellow;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: AppConstants.animButton,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color : Colors.transparent,
          border: Border.all(
            color: borderColor,
            width: AppConstants.borderSecondary,
          ),
          boxShadow: isActive
              ? []
              : [
                  BoxShadow(
                    color: borderColor,
                    offset: const Offset(3, 3),
                    blurRadius: 0,
                  ),
                ],
        ),
        transform: isActive
            ? (Matrix4.identity()
              ..translateByDouble(1.5, 1.5, 0.0, 1.0))
            : Matrix4.identity(),
        child: Text(
          label.toUpperCase(),
          style: GoogleFonts.spaceGrotesk(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
            letterSpacing: 0.5,
            color: isActive ? Colors.white : NeoBrutalColors.ink,
          ),
        ),
      ),
    );
  }
}
