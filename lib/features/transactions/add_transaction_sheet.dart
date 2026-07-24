import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/neo_brutal_colors.dart';
import '../../core/theme/neo_brutal_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/account_model.dart';
import '../../data/notifiers/transaction_list_notifier.dart';
import '../../data/repositories/transaction_repo.dart';
import '../../data/repositories/category_repo.dart';
import '../../data/repositories/account_repo.dart';
import '../../shared/widgets/neo_segmented_control.dart';
import '../../shared/widgets/neo_dialog.dart';
import '../../shared/widgets/neo_header_button.dart';

class AddTransactionSheet extends ConsumerStatefulWidget {
  const AddTransactionSheet({super.key, this.editTransaction});

  final TransactionModel? editTransaction;

  bool get isEdit => editTransaction != null;

  static Future<bool?> show(
    BuildContext context, {
    TransactionModel? editTransaction,
  }) {
    return showNeoDialog<bool>(
      context: context,
      child: AddTransactionSheet(editTransaction: editTransaction),
    );
  }

  @override
  ConsumerState<AddTransactionSheet> createState() =>
      _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  TransactionType _type = TransactionType.expense;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _date = DateTime.now();
  CategoryModel? _selectedCategory;
  AccountModel? _selectedAccount;
  AccountModel? _selectedToAccount;
  List<CategoryModel> _categories = [];
  List<AccountModel> _accounts = [];
  bool _loading = true;
  bool _saving = false;

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
        _selectedCategory = cats
            .where((c) => c.id == tx.categoryId)
            .firstOrNull;
        _selectedAccount = accs.where((a) => a.id == tx.accountId).firstOrNull;
        _selectedToAccount = accs
            .where((a) => a.id == tx.toAccountId)
            .firstOrNull;
      } else {
        if (cats.isNotEmpty) _selectedCategory = cats.first;
        if (accs.isNotEmpty) _selectedAccount = accs.first;
      }
      // A transfer always needs a valid, distinct destination wallet.
      if (_type == TransactionType.transfer) {
        _selectedToAccount ??= accs
            .where((a) => a.id != _selectedAccount?.id)
            .firstOrNull;
      }
      _loading = false;
    });
  }

  Future<void> _onTypeChanged(TransactionType type) async {
    HapticFeedback.selectionClick();
    if (type == TransactionType.transfer) {
      setState(() {
        _type = type;
        // Default to a destination distinct from the source.
        _selectedToAccount ??= _accounts
            .where((a) => a.id != _selectedAccount?.id)
            .firstOrNull;
      });
      return;
    }
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
      HapticFeedback.selectionClick();
      setState(() => _date = picked);
    }
  }

  Future<void> _save() async {
    final amount = double.tryParse(
      _amountController.text.replaceAll('.', '').replaceAll(',', ''),
    );
    final isTransfer = _type == TransactionType.transfer;

    if (amount == null || amount <= 0) {
      _showError('Masukkan jumlah yang valid');
      return;
    }
    if (isTransfer) {
      if (_selectedAccount == null || _selectedToAccount == null) {
        _showError('Pilih wallet asal & tujuan');
        return;
      }
      if (_selectedAccount!.id == _selectedToAccount!.id) {
        _showError('Wallet asal & tujuan harus berbeda');
        return;
      }
    } else if (_selectedCategory == null || _selectedAccount == null) {
      _showError('Lengkapi semua field');
      return;
    }

    setState(() => _saving = true);
    HapticFeedback.mediumImpact();
    final notifier = ref.read(transactionListProvider.notifier);
    final repo = TransactionRepo();

    try {
      if (widget.isEdit) {
        final updated = widget.editTransaction!.copyWith(
          type: _type,
          amount: amount,
          categoryId: isTransfer ? '' : _selectedCategory!.id,
          accountId: _selectedAccount!.id,
          toAccountId: isTransfer ? _selectedToAccount!.id : null,
          date: _date,
          note: _noteController.text.isNotEmpty ? _noteController.text : null,
        );
        await notifier.updateTransaction(updated);
      } else {
        final tx = TransactionModel(
          id: repo.newId(),
          type: _type,
          amount: amount,
          categoryId: isTransfer ? '' : _selectedCategory!.id,
          accountId: _selectedAccount!.id,
          toAccountId: isTransfer ? _selectedToAccount!.id : null,
          date: _date,
          note: _noteController.text.isNotEmpty ? _noteController.text : null,
        );
        await notifier.addTransaction(tx);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        _showError('Error: $e');
      }
    }
  }

  void _showError(String message) {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Color get _typeColor => switch (_type) {
    TransactionType.income => NeoBrutalColors.success,
    TransactionType.expense => NeoBrutalColors.danger,
    TransactionType.transfer => NeoBrutalColors.secondary,
  };

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
          // ── Color Accent Bar ──
          Container(height: 8, color: _typeColor),

          // ── Header ──
          _buildHeader(borderColor),

          // ── Content ──
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
                    // Type selector
                    NeoSegmentedControl<TransactionType>(
                      segments: neoSegments([
                        (TransactionType.expense, 'Pengeluaran'),
                        (TransactionType.income, 'Pemasukan'),
                        (TransactionType.transfer, 'Transfer'),
                      ]),
                      selected: _type,
                      onChanged: _onTypeChanged,
                    ),
                    const SizedBox(height: 24),

                    // Amount input (dominant)
                    _buildAmountInput(),
                    const SizedBox(height: 24),

                    // Category / wallet section — transfers swap the category
                    // picker for a source → destination wallet selector.
                    if (_type == TransactionType.transfer)
                      _buildTransferAccounts()
                    else ...[
                      _buildSectionTitle('KATEGORI'),
                      const SizedBox(height: 10),
                      _buildCategoryChips(),
                      const SizedBox(height: 20),
                      _buildSectionTitle('AKUN'),
                      const SizedBox(height: 10),
                      _buildAccountChips(
                        selected: _selectedAccount,
                        onSelect: (a) => setState(() => _selectedAccount = a),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Date & Note
                    _buildSectionTitle('DETAIL'),
                    const SizedBox(height: 10),
                    _buildDateNoteRow(),
                    const SizedBox(height: 28),

                    // Save button
                    _buildSaveButton(),
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
          // Type icon block
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
            child: Icon(
              switch (_type) {
                TransactionType.income => Icons.arrow_downward_rounded,
                TransactionType.expense => Icons.arrow_upward_rounded,
                TransactionType.transfer => Icons.swap_horiz_rounded,
              },
              size: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          // Title
          Expanded(
            child: Text(
              widget.isEdit ? 'EDIT TRANSAKSI' : 'TRANSAKSI BARU',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ),
          // Delete button (edit mode)
          if (widget.isEdit) ...[
            NeoHeaderButton(
              icon: Icons.delete_outline_rounded,
              color: NeoBrutalColors.danger,
              borderColor: borderColor,
              onTap: _confirmDelete,
            ),
            const SizedBox(width: 8),
          ],
          // Close button with 3D press effect
          NeoHeaderButton(
            icon: Icons.close_rounded,
            borderColor: borderColor,
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountInput() {
    final brightness = Theme.of(context).brightness;
    final borderColor = NeoBrutalTheme.borderColor(brightness);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
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
        // Input area
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: NeoBrutalColors.surface,
            border: Border.all(
              color: borderColor,
              width: AppConstants.borderPrimary,
            ),
            boxShadow: [
              BoxShadow(
                color: borderColor,
                offset: AppConstants.shadowDefault,
                blurRadius: 0,
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
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
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _ThousandsSeparatorInputFormatter(),
                  ],
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
                  autofocus: !widget.isEdit,
                ),
              ),
            ],
          ),
        ),
        // Color accent bar at bottom
        Container(height: 4, color: _typeColor),
      ],
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

  Widget _buildCategoryChips() {
    final brightness = Theme.of(context).brightness;
    final borderColor = NeoBrutalTheme.borderColor(brightness);

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
                letterSpacing: 0.5,
                color: selected ? Colors.white : NeoBrutalColors.ink,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTransferAccounts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('DARI WALLET'),
        const SizedBox(height: 10),
        _buildAccountChips(
          selected: _selectedAccount,
          excludeId: _selectedToAccount?.id,
          selectedColor: NeoBrutalColors.danger,
          onSelect: (a) => setState(() => _selectedAccount = a),
        ),
        const SizedBox(height: 14),
        const Center(
          child: Icon(
            Icons.arrow_downward_rounded,
            size: 20,
            color: NeoBrutalColors.secondary,
          ),
        ),
        const SizedBox(height: 14),
        _buildSectionTitle('KE WALLET'),
        const SizedBox(height: 10),
        _buildAccountChips(
          selected: _selectedToAccount,
          excludeId: _selectedAccount?.id,
          selectedColor: NeoBrutalColors.success,
          onSelect: (a) => setState(() => _selectedToAccount = a),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildAccountChips({
    required AccountModel? selected,
    required ValueChanged<AccountModel> onSelect,
    String? excludeId,
    Color selectedColor = NeoBrutalColors.secondary,
  }) {
    final brightness = Theme.of(context).brightness;
    final borderColor = NeoBrutalTheme.borderColor(brightness);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _accounts.map((acc) {
        final isExcluded = excludeId != null && acc.id == excludeId;
        final isSelected = selected?.id == acc.id;
        return Opacity(
          opacity: isExcluded ? 0.35 : 1,
          child: GestureDetector(
            onTap: isExcluded
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    onSelect(acc);
                  },
            child: AnimatedContainer(
              duration: AppConstants.animButton,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? selectedColor : NeoBrutalColors.surface,
                border: Border.all(
                  color: borderColor,
                  width: AppConstants.borderSecondary,
                ),
                boxShadow: isSelected
                    ? []
                    : [
                        BoxShadow(
                          color: borderColor,
                          offset: const Offset(3, 3),
                          blurRadius: 0,
                        ),
                      ],
              ),
              transform: isSelected
                  ? (Matrix4.identity()..translateByDouble(1.5, 1.5, 0.0, 1.0))
                  : Matrix4.identity(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _iconForAccountType(acc.type),
                    size: 16,
                    color: isSelected ? Colors.white : NeoBrutalColors.ink,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    acc.name.toUpperCase(),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.w900
                          : FontWeight.w700,
                      letterSpacing: 0.5,
                      color: isSelected ? Colors.white : NeoBrutalColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _iconForAccountType(AccountType type) {
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

  Widget _buildDateNoteRow() {
    final brightness = Theme.of(context).brightness;
    final borderColor = NeoBrutalTheme.borderColor(brightness);

    return Row(
      children: [
        // Date picker
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
                  DateFormat('dd MMM yyyy').format(_date),
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
        // Note input
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
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    final brightness = Theme.of(context).brightness;
    final borderColor = NeoBrutalTheme.borderColor(brightness);

    return GestureDetector(
      onTap: _saving ? null : _save,
      child: AnimatedContainer(
        duration: AppConstants.animButton,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
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
                size: 20,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              _saving
                  ? 'MENYIMPAN...'
                  : widget.isEdit
                  ? 'SIMPAN PERUBAHAN'
                  : 'SIMPAN TRANSAKSI',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
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

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('HAPUS TRANSAKSI?'),
        content: const Text('Transaksi ini akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('BATAL'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final notifier = ref.read(transactionListProvider.notifier);
              await notifier.deleteTransaction(widget.editTransaction!.id);
              HapticFeedback.mediumImpact();
              if (mounted) Navigator.pop(context, true);
            },
            child: const Text(
              'HAPUS',
              style: TextStyle(color: NeoBrutalColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}

/// Input formatter for thousands separator
/// Simplified - always place cursor at end
class _ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove all non-digits
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Parse number
    final number = int.parse(digitsOnly);

    // Format with dots as thousands separator
    final formatted = _formatNumber(number);

    // Always place cursor at end for simplicity
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatNumber(int number) {
    final str = number.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return buffer.toString();
  }
}
