import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/neo_brutal_colors.dart';
import '../../data/models/account_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/transaction_template_model.dart';
import '../../data/repositories/account_repo.dart';
import '../../data/repositories/category_repo.dart';
import '../../data/repositories/template_repo.dart';
import '../../shared/widgets/neo_button.dart';
import '../../shared/widgets/neo_text_field.dart';

/// Bottom sheet form to create a quick-entry transaction template.
class TemplateFormSheet extends StatefulWidget {
  const TemplateFormSheet({super.key});

  /// Returns true when a template was saved.
  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const TemplateFormSheet(),
    );
  }

  @override
  State<TemplateFormSheet> createState() => _TemplateFormSheetState();
}

class _TemplateFormSheetState extends State<TemplateFormSheet> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();

  TransactionType _type = TransactionType.expense;
  List<CategoryModel> _categories = [];
  List<AccountModel> _accounts = [];
  CategoryModel? _selectedCategory;
  AccountModel? _selectedAccount;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    final cats = await CategoryRepo().getByType(
      _type == TransactionType.expense
          ? CategoryType.expense
          : CategoryType.income,
    );
    final accounts = await AccountRepo().getAll();
    if (!mounted) return;
    setState(() {
      _categories = cats;
      _accounts = accounts;
      _selectedCategory = cats.isNotEmpty ? cats.first : null;
      _selectedAccount ??= accounts.isNotEmpty ? accounts.first : null;
      _loading = false;
    });
  }

  void _setType(TransactionType type) {
    if (_type == type) return;
    HapticFeedback.selectionClick();
    setState(() {
      _type = type;
      _loading = true;
    });
    _loadOptions();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final amount = double.tryParse(
      _amountController.text.replaceAll('.', '').replaceAll(',', ''),
    );
    if (name.isEmpty) {
      _showError('Beri nama template');
      return;
    }
    if (amount == null || amount <= 0) {
      _showError('Masukkan jumlah yang valid');
      return;
    }
    if (_selectedCategory == null || _selectedAccount == null) {
      _showError('Pilih kategori & wallet');
      return;
    }

    setState(() => _saving = true);
    HapticFeedback.mediumImpact();
    final repo = TemplateRepo();
    await repo.insert(
      TransactionTemplateModel(
        id: repo.newId(),
        name: name,
        type: _type,
        amount: amount,
        categoryId: _selectedCategory!.id,
        accountId: _selectedAccount!.id,
      ),
    );
    if (mounted) Navigator.pop(context, true);
  }

  void _showError(String message) {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? NeoBrutalColors.bgDark : NeoBrutalColors.bg,
          border: Border(
            top: BorderSide(
              color: isDark ? NeoBrutalColors.darkLine : NeoBrutalColors.ink,
              width: 3,
            ),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TEMPLATE BARU',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Catat transaksi rutin cukup 2 tap dari dashboard',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              // Type toggle
              Row(
                children: [
                  _typeChip(
                    'PENGELUARAN',
                    TransactionType.expense,
                    NeoBrutalColors.danger,
                  ),
                  const SizedBox(width: 8),
                  _typeChip(
                    'PEMASUKAN',
                    TransactionType.income,
                    NeoBrutalColors.success,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              NeoTextField(
                controller: _nameController,
                label: 'Nama Template',
                hint: 'Kopi pagi, Bensin, Parkir...',
                prefixIcon: Icons.bookmark_border_rounded,
              ),
              const SizedBox(height: 16),
              Text(
                'JUMLAH (RP)',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: NeoBrutalColors.ink.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [_ThousandsFormatter()],
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
                decoration: const InputDecoration(
                  hintText: '0',
                  prefixIcon: Icon(Icons.payments_rounded, size: 20),
                ),
              ),
              const SizedBox(height: 16),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else ...[
                _sectionLabel('KATEGORI'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories.map((cat) {
                    final selected = _selectedCategory?.id == cat.id;
                    return _optionChip(
                      label: cat.name,
                      selected: selected,
                      onTap: () => setState(() => _selectedCategory = cat),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                _sectionLabel('WALLET'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _accounts.map((acc) {
                    final selected = _selectedAccount?.id == acc.id;
                    return _optionChip(
                      label: acc.name,
                      selected: selected,
                      onTap: () => setState(() => _selectedAccount = acc),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: NeoButton(
                  label: _saving ? 'MENYIMPAN...' : 'SIMPAN TEMPLATE',
                  icon: Icons.check_circle_outline_rounded,
                  color: NeoBrutalColors.success,
                  onTap: _saving ? null : _save,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
    text,
    style: GoogleFonts.spaceGrotesk(
      fontSize: 11,
      fontWeight: FontWeight.w900,
      letterSpacing: 1.2,
      color: NeoBrutalColors.ink.withValues(alpha: 0.7),
    ),
  );

  Widget _typeChip(String label, TransactionType type, Color color) {
    final selected = _type == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => _setType(type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color : NeoBrutalColors.surface,
            border: Border.all(
              color: NeoBrutalColors.ink,
              width: selected ? 3 : 2,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                color: selected ? Colors.white : NeoBrutalColors.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _optionChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? NeoBrutalColors.yellow : NeoBrutalColors.surface,
          border: Border.all(
            color: NeoBrutalColors.ink,
            width: selected ? 3 : 2,
          ),
          boxShadow: selected
              ? [
                  const BoxShadow(
                    color: NeoBrutalColors.ink,
                    offset: Offset(3, 3),
                    blurRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Text(
          label.toUpperCase(),
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
            letterSpacing: 0.5,
            color: NeoBrutalColors.ink,
          ),
        ),
      ),
    );
  }
}

class _ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll('.', '');
    if (digits.isEmpty) return newValue.copyWith(text: '');
    final number = int.tryParse(digits);
    if (number == null) return oldValue;
    final formatted = NumberFormat('#,###', 'id_ID').format(number);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
