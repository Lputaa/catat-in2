import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/neo_brutal_colors.dart';
import '../../core/theme/neo_brutal_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/recurring_transaction_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/account_model.dart';
import '../../data/notifiers/recurring_list_notifier.dart';
import '../../data/repositories/recurring_repo.dart';
import '../../data/repositories/category_repo.dart';
import '../../data/repositories/account_repo.dart';
import '../../shared/widgets/neo_dialog.dart';
import '../../shared/widgets/neo_header_button.dart';

class AddRecurringSheet extends ConsumerStatefulWidget {
  const AddRecurringSheet({super.key, this.editItem});

  final RecurringTransactionModel? editItem;
  bool get isEdit => editItem != null;

  static Future<bool?> show(
    BuildContext context, {
    RecurringTransactionModel? editItem,
  }) {
    return showNeoDialog<bool>(
      context: context,
      child: AddRecurringSheet(editItem: editItem),
    );
  }

  @override
  ConsumerState<AddRecurringSheet> createState() => _AddRecurringSheetState();
}

class _AddRecurringSheetState extends ConsumerState<AddRecurringSheet> {
  TransactionType _type = TransactionType.expense;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  RecurrenceFrequency _frequency = RecurrenceFrequency.monthly;
  DateTime _startDate = DateTime.now();
  bool _autoRecord = false;
  CategoryModel? _selectedCategory;
  AccountModel? _selectedAccount;
  List<CategoryModel> _categories = [];
  List<AccountModel> _accounts = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    TransactionType type = TransactionType.expense;
    if (widget.isEdit) {
      type = widget.editItem!.transactionType == 'income'
          ? TransactionType.income
          : TransactionType.expense;
    }
    final catType = type == TransactionType.income
        ? CategoryType.income
        : CategoryType.expense;
    final cats = await CategoryRepo().getByType(catType);
    final accs = await AccountRepo().getAll();

    setState(() {
      _type = type;
      _categories = cats;
      _accounts = accs;

      if (widget.isEdit) {
        final rt = widget.editItem!;
        _amountController.text = rt.amount.toStringAsFixed(0);
        _noteController.text = rt.note ?? '';
        _frequency = rt.frequency;
        _startDate = rt.startDate;
        _autoRecord = rt.autoRecord;
        _selectedCategory = cats
            .where((c) => c.id == rt.categoryId)
            .firstOrNull;
        _selectedAccount = accs.where((a) => a.id == rt.accountId).firstOrNull;
      } else {
        if (cats.isNotEmpty) _selectedCategory = cats.first;
        if (accs.isNotEmpty) _selectedAccount = accs.first;
      }
      _loading = false;
    });
  }

  Future<void> _onTypeChanged(TransactionType type) async {
    HapticFeedback.selectionClick();
    final catType = type == TransactionType.income
        ? CategoryType.income
        : CategoryType.expense;
    final cats = await CategoryRepo().getByType(catType);
    setState(() {
      _type = type;
      _categories = cats;
      _selectedCategory = cats.isNotEmpty ? cats.first : null;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      HapticFeedback.selectionClick();
      setState(() => _startDate = picked);
    }
  }

  Future<void> _save() async {
    final amount = double.tryParse(
      _amountController.text.replaceAll('.', '').replaceAll(',', ''),
    );
    if (amount == null ||
        amount <= 0 ||
        _selectedCategory == null ||
        _selectedAccount == null) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lengkapi semua field')));
      return;
    }

    setState(() => _saving = true);
    HapticFeedback.mediumImpact();

    try {
      final notifier = ref.read(recurringListProvider.notifier);
      if (widget.isEdit) {
        await notifier.updateRecurring(
          widget.editItem!.copyWith(
            transactionType: _type == TransactionType.income
                ? 'income'
                : 'expense',
            amount: amount,
            categoryId: _selectedCategory!.id,
            accountId: _selectedAccount!.id,
            note: _noteController.text.isNotEmpty ? _noteController.text : null,
            frequency: _frequency,
            startDate: _startDate,
            autoRecord: _autoRecord,
          ),
        );
      } else {
        final repo = RecurringRepo();
        await notifier.addRecurring(
          RecurringTransactionModel(
            id: repo.newId(),
            transactionType: _type == TransactionType.income
                ? 'income'
                : 'expense',
            amount: amount,
            categoryId: _selectedCategory!.id,
            accountId: _selectedAccount!.id,
            note: _noteController.text.isNotEmpty ? _noteController.text : null,
            frequency: _frequency,
            startDate: _startDate,
            nextDate: _startDate,
            autoRecord: _autoRecord,
          ),
        );
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Color get _typeColor => _type == TransactionType.income
      ? NeoBrutalColors.success
      : NeoBrutalColors.orange;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final borderColor = NeoBrutalTheme.borderColor(brightness);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
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
          Container(height: 8, color: _typeColor),
          _buildHeader(borderColor),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTypeSelector(borderColor),
                    const SizedBox(height: 20),
                    _buildAmountInput(),
                    const SizedBox(height: 20),
                    _buildSectionTitle('KATEGORI'),
                    const SizedBox(height: 10),
                    _buildCategoryChips(borderColor),
                    const SizedBox(height: 16),
                    _buildSectionTitle('AKUN'),
                    const SizedBox(height: 10),
                    _buildAccountChips(borderColor),
                    const SizedBox(height: 16),
                    _buildSectionTitle('FREKUENSI'),
                    const SizedBox(height: 10),
                    _buildFrequencyChips(borderColor),
                    const SizedBox(height: 16),
                    _buildSectionTitle('DETAIL'),
                    const SizedBox(height: 10),
                    _buildDateNoteRow(borderColor),
                    const SizedBox(height: 12),
                    _buildAutoRecordToggle(borderColor),
                    const SizedBox(height: 24),
                    _buildSaveButton(borderColor),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(Color borderColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 14, 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: borderColor,
            width: AppConstants.borderSecondary,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _typeColor,
              border: Border.all(
                color: borderColor,
                width: AppConstants.borderSecondary,
              ),
            ),
            child: const Icon(
              Icons.repeat_rounded,
              size: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.isEdit ? 'EDIT BERULANG' : 'TRANSAKSI BERULANG',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ),
          NeoHeaderButton(
            icon: Icons.close_rounded,
            borderColor: borderColor,
            onTap: () => Navigator.pop(context),
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
        color:
            (Theme.of(context).brightness == Brightness.dark
                    ? NeoBrutalColors.inkDark
                    : NeoBrutalColors.ink)
                .withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildTypeSelector(Color borderColor) {
    return Row(
      children: [
        _buildFilterChip(
          'Pengeluaran',
          _type == TransactionType.expense,
          () => _onTypeChanged(TransactionType.expense),
          borderColor,
          activeColor: NeoBrutalColors.danger,
        ),
        const SizedBox(width: 8),
        _buildFilterChip(
          'Pemasukan',
          _type == TransactionType.income,
          () => _onTypeChanged(TransactionType.income),
          borderColor,
          activeColor: NeoBrutalColors.success,
        ),
      ],
    );
  }

  Widget _buildAmountInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          color: _typeColor,
          child: Text(
            'JUMLAH',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
              color: Colors.white,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: NeoBrutalColors.surface,
            border: Border.all(
              color: NeoBrutalColors.ink,
              width: AppConstants.borderPrimary,
            ),
            boxShadow: [
              BoxShadow(
                color: NeoBrutalColors.ink,
                offset: AppConstants.shadowDefault,
                blurRadius: 0,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.only(right: 12),
                decoration: const BoxDecoration(
                  border: Border(
                    right: BorderSide(color: NeoBrutalColors.muted, width: 2),
                  ),
                ),
                child: Text(
                  'Rp',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: NeoBrutalColors.ink.withValues(alpha: 0.5),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: GoogleFonts.spaceGrotesk(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: NeoBrutalColors.muted,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(height: 4, color: _typeColor),
      ],
    );
  }

  Widget _buildCategoryChips(Color borderColor) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _categories.map((cat) {
        final selected = _selectedCategory?.id == cat.id;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selectedCategory = cat);
          },
          child: AnimatedContainer(
            duration: AppConstants.animButton,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? cat.colorValue : NeoBrutalColors.surface,
              border: Border.all(
                color: borderColor,
                width: AppConstants.borderSecondary,
              ),
              boxShadow: selected
                  ? []
                  : [
                      BoxShadow(
                        color: borderColor,
                        offset: const Offset(3, 3),
                        blurRadius: 0,
                      ),
                    ],
            ),
            transform: selected
                ? (Matrix4.identity()..translateByDouble(1.5, 1.5, 0.0, 1.0))
                : Matrix4.identity(),
            child: Text(
              cat.name.toUpperCase(),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                color: selected ? Colors.white : NeoBrutalColors.ink,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAccountChips(Color borderColor) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _accounts.map((acc) {
        final selected = _selectedAccount?.id == acc.id;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selectedAccount = acc);
          },
          child: AnimatedContainer(
            duration: AppConstants.animButton,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? NeoBrutalColors.secondary
                  : NeoBrutalColors.surface,
              border: Border.all(
                color: borderColor,
                width: AppConstants.borderSecondary,
              ),
              boxShadow: selected
                  ? []
                  : [
                      BoxShadow(
                        color: borderColor,
                        offset: const Offset(3, 3),
                        blurRadius: 0,
                      ),
                    ],
            ),
            transform: selected
                ? (Matrix4.identity()..translateByDouble(1.5, 1.5, 0.0, 1.0))
                : Matrix4.identity(),
            child: Text(
              acc.name.toUpperCase(),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                color: selected ? Colors.white : NeoBrutalColors.ink,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFrequencyChips(Color borderColor) {
    final items = [
      (RecurrenceFrequency.daily, 'Harian'),
      (RecurrenceFrequency.weekly, 'Mingguan'),
      (RecurrenceFrequency.monthly, 'Bulanan'),
      (RecurrenceFrequency.yearly, 'Tahunan'),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final selected = _frequency == item.$1;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _frequency = item.$1);
          },
          child: AnimatedContainer(
            duration: AppConstants.animButton,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? NeoBrutalColors.yellow
                  : NeoBrutalColors.surface,
              border: Border.all(
                color: borderColor,
                width: AppConstants.borderSecondary,
              ),
              boxShadow: selected
                  ? []
                  : [
                      BoxShadow(
                        color: borderColor,
                        offset: const Offset(3, 3),
                        blurRadius: 0,
                      ),
                    ],
            ),
            transform: selected
                ? (Matrix4.identity()..translateByDouble(1.5, 1.5, 0.0, 1.0))
                : Matrix4.identity(),
            child: Text(
              item.$2.toUpperCase(),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                color: selected ? NeoBrutalColors.ink : NeoBrutalColors.ink,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateNoteRow(Color borderColor) {
    return Row(
      children: [
        GestureDetector(
          onTap: _pickDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: NeoBrutalColors.surface,
              border: Border.all(
                color: borderColor,
                width: AppConstants.borderSecondary,
              ),
              boxShadow: [
                BoxShadow(
                  color: borderColor,
                  offset: const Offset(3, 3),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today_rounded, size: 16),
                const SizedBox(width: 8),
                Text(
                  DateFormat('dd MMM yyyy').format(_startDate),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: NeoBrutalColors.surface,
              border: Border.all(
                color: borderColor,
                width: AppConstants.borderSecondary,
              ),
              boxShadow: [
                BoxShadow(
                  color: borderColor,
                  offset: const Offset(3, 3),
                  blurRadius: 0,
                ),
              ],
            ),
            child: TextField(
              controller: _noteController,
              maxLength: 500,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: 'Catatan...',
                hintStyle: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: NeoBrutalColors.muted,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                isDense: true,
                counterText: '',
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAutoRecordToggle(Color borderColor) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _autoRecord = !_autoRecord);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: NeoBrutalColors.surface,
          border: Border.all(
            color: borderColor,
            width: AppConstants.borderSecondary,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _autoRecord
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              color: _autoRecord
                  ? NeoBrutalColors.success
                  : NeoBrutalColors.muted,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CATAT OTOMATIS',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    _autoRecord
                        ? 'Dicatat otomatis saat jatuh tempo'
                        : 'Perlu konfirmasi manual',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
    final inactiveBg = Theme.of(context).brightness == Brightness.dark
        ? NeoBrutalColors.bgDark
        : NeoBrutalColors.bg;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppConstants.animButton,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color : inactiveBg,
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
            ? (Matrix4.identity()..translateByDouble(1.5, 1.5, 0.0, 1.0))
            : Matrix4.identity(),
        child: Text(
          label.toUpperCase(),
          style: GoogleFonts.spaceGrotesk(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
            color: isActive ? Colors.white : NeoBrutalColors.ink,
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton(Color borderColor) {
    return GestureDetector(
      onTap: _saving ? null : _save,
      child: AnimatedContainer(
        duration: AppConstants.animButton,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: _saving ? NeoBrutalColors.muted : NeoBrutalColors.success,
          border: Border.all(
            color: borderColor,
            width: AppConstants.borderPrimary,
          ),
          boxShadow: _saving
              ? []
              : [
                  BoxShadow(
                    color: borderColor,
                    offset: AppConstants.shadowDefault,
                    blurRadius: 0,
                  ),
                ],
        ),
        transform: _saving
            ? (Matrix4.identity()..translateByDouble(
                AppConstants.shadowDefault.dx / 2,
                AppConstants.shadowDefault.dy / 2,
                0.0,
                1.0,
              ))
            : Matrix4.identity(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_saving) ...[
              const Icon(
                Icons.check_circle_outline_rounded,
                size: 18,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              _saving ? 'MENYIMPAN...' : 'SIMPAN',
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
    );
  }
}
