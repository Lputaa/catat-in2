import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/neo_brutal_colors.dart';
import '../../core/theme/neo_brutal_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/budget_model.dart';
import '../../data/models/category_model.dart';
import '../../data/notifiers/budget_list_notifier.dart';
import '../../data/repositories/budget_repo.dart';

class AddBudgetSheet extends ConsumerStatefulWidget {
  const AddBudgetSheet({
    super.key,
    required this.year,
    required this.month,
    this.availableCategories,
  });

  final int year;
  final int month;
  final List<CategoryModel>? availableCategories;

  static Future<bool?> show(
    BuildContext context, {
    required int year,
    required int month,
    List<CategoryModel>? availableCategories,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: AddBudgetSheet(
          year: year,
          month: month,
          availableCategories: availableCategories,
        ),
      ),
    );
  }

  @override
  ConsumerState<AddBudgetSheet> createState() => _AddBudgetSheetState();
}

class _AddBudgetSheetState extends ConsumerState<AddBudgetSheet> {
  final _amountController = TextEditingController();
  CategoryModel? _selectedCategory;
  List<CategoryModel> _categories = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    if (widget.availableCategories != null) {
      _categories = widget.availableCategories!;
    } else {
      final notifier = ref.read(budgetListProvider.notifier);
      _categories = await notifier.getAvailableCategories();
    }
    setState(() {
      if (_categories.isNotEmpty) _selectedCategory = _categories.first;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final amount = double.tryParse(
      _amountController.text.replaceAll('.', '').replaceAll(',', ''),
    );
    if (amount == null || amount <= 0 || _selectedCategory == null) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi semua field')),
      );
      return;
    }

    setState(() => _saving = true);
    HapticFeedback.mediumImpact();

    try {
      final repo = BudgetRepo();
      final budget = BudgetModel(
        id: repo.newId(),
        categoryId: _selectedCategory!.id,
        limitAmount: amount,
        year: widget.year,
        month: widget.month,
      );
      await ref.read(budgetListProvider.notifier).addBudget(budget);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
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
          Container(height: 8, color: NeoBrutalColors.green),

          // Header
          _buildHeader(borderColor),

          // Content
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_categories.isEmpty)
            _buildAllCategoriesUsed()
          else
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('KATEGORI'),
                    const SizedBox(height: 10),
                    _buildCategoryChips(),
                    const SizedBox(height: 24),
                    _buildAmountInput(),
                    const SizedBox(height: 28),
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
              color: borderColor, width: AppConstants.borderSecondary),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: NeoBrutalColors.green,
              border: Border.all(
                  color: borderColor, width: AppConstants.borderSecondary),
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              size: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'BUDGET BARU',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(
                    color: borderColor, width: AppConstants.borderSecondary),
              ),
              child: const Icon(Icons.close_rounded, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllCategoriesUsed() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          const Icon(Icons.check_circle_outline_rounded,
              size: 64, color: NeoBrutalColors.success),
          const SizedBox(height: 16),
          Text(
            'SEMUA KATEGORI SUDAH PUNYA BUDGET',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: NeoBrutalColors.primary,
                border: Border.all(
                    color: NeoBrutalColors.ink,
                    width: AppConstants.borderPrimary),
              ),
              child: Text(
                'TUTUP',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
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
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                ? (Matrix4.identity()
                  ..translateByDouble(1.5, 1.5, 0.0, 1.0))
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

  Widget _buildAmountInput() {
    final brightness = Theme.of(context).brightness;
    final borderColor = NeoBrutalTheme.borderColor(brightness);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          color: NeoBrutalColors.green,
          child: Text(
            'LIMIT BUDGET',
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
            children: [
              Container(
                padding: const EdgeInsets.only(right: 12),
                decoration: const BoxDecoration(
                  border: Border(
                    right: BorderSide(
                        color: NeoBrutalColors.muted, width: 2),
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
                  autofocus: true,
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 4,
          color: NeoBrutalColors.green,
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
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: _saving ? NeoBrutalColors.muted : NeoBrutalColors.success,
          border: Border.all(
              color: borderColor, width: AppConstants.borderPrimary),
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
            ? (Matrix4.identity()
              ..translateByDouble(
                  AppConstants.shadowDefault.dx / 2,
                  AppConstants.shadowDefault.dy / 2,
                  0.0,
                  1.0))
            : Matrix4.identity(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_saving) ...[
              const Icon(Icons.check_circle_outline_rounded,
                  size: 18, color: Colors.white),
              const SizedBox(width: 8),
            ],
            Text(
              _saving ? 'MENYIMPAN...' : 'SIMPAN BUDGET',
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
