import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/neo_brutal_colors.dart';
import '../../data/models/recurring_transaction_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/account_model.dart';
import '../../data/repositories/recurring_repo.dart';
import '../../data/repositories/category_repo.dart';
import '../../data/repositories/account_repo.dart';
import '../../shared/widgets/neo_button.dart';
import '../../shared/widgets/neo_segmented_control.dart';
import '../../shared/widgets/neo_text_field.dart';
import '../../shared/widgets/catat_in_app_bar.dart';
import '../../shared/widgets/dot_pattern_background.dart';

class AddRecurringScreen extends StatefulWidget {
  const AddRecurringScreen({super.key, this.editTransaction});

  final RecurringTransactionModel? editTransaction;
  bool get isEdit => editTransaction != null;

  @override
  State<AddRecurringScreen> createState() => _AddRecurringScreenState();
}

class _AddRecurringScreenState extends State<AddRecurringScreen> {
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    TransactionType type = TransactionType.expense;
    if (widget.isEdit) {
      type = widget.editTransaction!.transactionType == 'income'
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
        final rt = widget.editTransaction!;
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
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _save() async {
    final amount = double.tryParse(
      _amountController.text.replaceAll('.', '').replaceAll(',', ''),
    );
    if (amount == null ||
        amount <= 0 ||
        _selectedCategory == null ||
        _selectedAccount == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lengkapi semua field')));
      return;
    }

    HapticFeedback.mediumImpact();
    final repo = RecurringRepo();
    if (widget.isEdit) {
      await repo.update(
        widget.editTransaction!.copyWith(
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
      await repo.insert(
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
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: CatatInAppBar(
        subtitle: widget.isEdit
            ? 'Edit Transaksi Berulang'
            : 'Tambah Transaksi Berulang',
      ),
      body: DotPatternBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NeoSegmentedControl<TransactionType>(
                segments: neoSegments([
                  (TransactionType.expense, 'Pengeluaran'),
                  (TransactionType.income, 'Pemasukan'),
                ]),
                selected: _type,
                onChanged: _onTypeChanged,
              ),
              const SizedBox(height: 24),

              NeoTextField(
                controller: _amountController,
                label: 'Jumlah',
                hint: '0',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.payments_rounded,
              ),
              const SizedBox(height: 16),

              // Category
              _buildLabel('KATEGORI'),
              const SizedBox(height: 8),
              _buildChipWrap(
                items: _categories.map((c) => (c.id, c.name)).toList(),
                selectedId: _selectedCategory?.id,
                onTap: (id) => setState(
                  () => _selectedCategory = _categories.firstWhere(
                    (c) => c.id == id,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Account
              _buildLabel('AKUN'),
              const SizedBox(height: 8),
              _buildChipWrap(
                items: _accounts.map((a) => (a.id, a.name)).toList(),
                selectedId: _selectedAccount?.id,
                onTap: (id) => setState(
                  () => _selectedAccount = _accounts.firstWhere(
                    (a) => a.id == id,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Frequency
              _buildLabel('FREKUENSI'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: RecurrenceFrequency.values.map((f) {
                  final selected = _frequency == f;
                  String label;
                  switch (f) {
                    case RecurrenceFrequency.daily:
                      label = 'Harian';
                    case RecurrenceFrequency.weekly:
                      label = 'Mingguan';
                    case RecurrenceFrequency.monthly:
                      label = 'Bulanan';
                    case RecurrenceFrequency.yearly:
                      label = 'Tahunan';
                  }
                  return GestureDetector(
                    onTap: () => setState(() => _frequency = f),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? NeoBrutalColors.yellow
                            : NeoBrutalColors.surface,
                        border: Border.all(
                          color: NeoBrutalColors.ink,
                          width: selected ? 3 : 2,
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: NeoBrutalColors.ink,
                                  offset: const Offset(3, 3),
                                  blurRadius: 0,
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        label.toUpperCase(),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          fontWeight: selected
                              ? FontWeight.w900
                              : FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Start date
              GestureDetector(
                onTap: _pickDate,
                child: AbsorbPointer(
                  child: NeoTextField(
                    label: 'Mulai Tanggal',
                    hint: DateFormat('dd MMM yyyy').format(_startDate),
                    prefixIcon: Icons.calendar_month_rounded,
                    readOnly: true,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Note
              NeoTextField(
                controller: _noteController,
                label: 'Catatan',
                hint: 'Contoh: Langganan Netflix',
                prefixIcon: Icons.notes_rounded,
              ),
              const SizedBox(height: 16),

              // Auto record toggle
              GestureDetector(
                onTap: () => setState(() => _autoRecord = !_autoRecord),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: NeoBrutalColors.surface,
                    border: Border.all(color: NeoBrutalColors.ink, width: 2),
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
                                  ? 'Transaksi dicatat otomatis saat jatuh tempo'
                                  : 'Perlu konfirmasi manual saat jatuh tempo',
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
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: NeoButton(
                  label: 'SIMPAN',
                  icon: Icons.check_circle_outline_rounded,
                  color: NeoBrutalColors.success,
                  onTap: _save,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.spaceGrotesk(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
        color: NeoBrutalColors.ink.withValues(alpha: 0.7),
      ),
    );
  }

  Widget _buildChipWrap({
    required List<(String, String)> items,
    required String? selectedId,
    required ValueChanged<String> onTap,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final selected = selectedId == item.$1;
        return GestureDetector(
          onTap: () => onTap(item.$1),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? NeoBrutalColors.yellow
                  : NeoBrutalColors.surface,
              border: Border.all(
                color: NeoBrutalColors.ink,
                width: selected ? 3 : 2,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: NeoBrutalColors.ink,
                        offset: const Offset(3, 3),
                        blurRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Text(
              item.$2.toUpperCase(),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
