import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/neo_brutal_colors.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/account_model.dart';
import '../../data/notifiers/transaction_list_notifier.dart';
import '../../data/repositories/transaction_repo.dart';
import '../../data/repositories/category_repo.dart';
import '../../data/repositories/account_repo.dart';
import '../../shared/widgets/neo_button.dart';
import '../../shared/widgets/neo_segmented_control.dart';
import '../../shared/widgets/neo_text_field.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key, this.editTransaction});

  final TransactionModel? editTransaction;

  bool get isEdit => editTransaction != null;

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  TransactionType _type = TransactionType.expense;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _date = DateTime.now();
  CategoryModel? _selectedCategory;
  AccountModel? _selectedAccount;
  List<CategoryModel> _categories = [];
  List<AccountModel> _accounts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final accs = await AccountRepo().getAll();
    TransactionType type = TransactionType.expense;

    if (widget.isEdit) {
      type = widget.editTransaction!.type;
    }

    final catType = type == TransactionType.income
        ? CategoryType.income
        : CategoryType.expense;
    final cats = await CategoryRepo().getByType(catType);

    setState(() {
      _type = type;
      _categories = cats;
      _accounts = accs;

      if (widget.isEdit) {
        final tx = widget.editTransaction!;
        _amountController.text = tx.amount.toStringAsFixed(0);
        _noteController.text = tx.note ?? '';
        _date = tx.date;
        _selectedCategory = cats.where((c) => c.id == tx.categoryId).firstOrNull;
        _selectedAccount = accs.where((a) => a.id == tx.accountId).firstOrNull;
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
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final amount = double.tryParse(
      _amountController.text.replaceAll('.', '').replaceAll(',', ''),
    );
    if (amount == null || amount <= 0 || _selectedCategory == null || _selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi semua field')),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    final notifier = ref.read(transactionListProvider.notifier);
    final repo = TransactionRepo();

    if (widget.isEdit) {
      final updated = widget.editTransaction!.copyWith(
        type: _type,
        amount: amount,
        categoryId: _selectedCategory!.id,
        accountId: _selectedAccount!.id,
        date: _date,
        note: _noteController.text.isNotEmpty ? _noteController.text : null,
      );
      await notifier.updateTransaction(updated);
    } else {
      final tx = TransactionModel(
        id: repo.newId(),
        type: _type,
        amount: amount,
        categoryId: _selectedCategory!.id,
        accountId: _selectedAccount!.id,
        date: _date,
        note: _noteController.text.isNotEmpty ? _noteController.text : null,
      );
      await notifier.addTransaction(tx);
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
      appBar: AppBar(
        title: Text(
          widget.isEdit ? 'EDIT TRANSAKSI' : 'TAMBAH TRANSAKSI',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
        actions: [
          if (widget.isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: NeoBrutalColors.danger),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: SingleChildScrollView(
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
            _buildLabel('KATEGORI'),
            const SizedBox(height: 8),
            _buildChipWrap(
              items: _categories.map((c) => (c.id, c.name)).toList(),
              selectedId: _selectedCategory?.id,
              onTap: (id) => setState(() {
                _selectedCategory = _categories.firstWhere((c) => c.id == id);
              }),
            ),
            const SizedBox(height: 16),
            _buildLabel('AKUN'),
            const SizedBox(height: 8),
            _buildChipWrap(
              items: _accounts.map((a) => (a.id, a.name)).toList(),
              selectedId: _selectedAccount?.id,
              onTap: (id) => setState(() {
                _selectedAccount = _accounts.firstWhere((a) => a.id == id);
              }),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pickDate,
              child: AbsorbPointer(
                child: NeoTextField(
                  label: 'Tanggal',
                  hint: DateFormat('dd MMM yyyy').format(_date),
                  prefixIcon: Icons.calendar_month_rounded,
                  readOnly: true,
                ),
              ),
            ),
            const SizedBox(height: 16),
            NeoTextField(
              controller: _noteController,
              label: 'Catatan (opsional)',
              hint: 'Tambahkan catatan...',
              prefixIcon: Icons.notes_rounded,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: NeoButton(
                label: widget.isEdit ? 'SIMPAN PERUBAHAN' : 'SIMPAN TRANSAKSI',
                icon: Icons.check_circle_outline_rounded,
                color: NeoBrutalColors.success,
                onTap: _save,
              ),
            ),
          ],
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
              color: selected ? NeoBrutalColors.yellow : NeoBrutalColors.surface,
              border: Border.all(
                color: NeoBrutalColors.ink,
                width: selected ? 3 : 2,
              ),
              boxShadow: selected
                  ? [BoxShadow(color: NeoBrutalColors.ink, offset: const Offset(3, 3), blurRadius: 0)]
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

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('HAPUS TRANSAKSI?'),
        content: const Text('Transaksi ini akan dihapus permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('BATAL')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final notifier = ref.read(transactionListProvider.notifier);
              await notifier.deleteTransaction(widget.editTransaction!.id);
              HapticFeedback.mediumImpact();
              if (mounted) Navigator.pop(context, true);
            },
            child: const Text('HAPUS', style: TextStyle(color: NeoBrutalColors.danger)),
          ),
        ],
      ),
    );
  }
}
