import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/neo_brutal_colors.dart';
import '../../data/models/budget_model.dart';
import '../../data/models/category_model.dart';
import '../../data/repositories/budget_repo.dart';
import '../../data/repositories/category_repo.dart';
import '../../shared/widgets/neo_button.dart';
import '../../shared/widgets/neo_text_field.dart';
import '../../shared/widgets/catat_in_app_bar.dart';
import '../../shared/widgets/dot_pattern_background.dart';

class AddBudgetScreen extends StatefulWidget {
  const AddBudgetScreen({super.key, required this.year, required this.month});

  final int year;
  final int month;

  @override
  State<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends State<AddBudgetScreen> {
  final _amountController = TextEditingController();
  List<CategoryModel> _categories = [];
  CategoryModel? _selectedCategory;
  bool _rollover = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cats = await CategoryRepo().getByType(CategoryType.expense);
    final existingBudgets = await BudgetRepo().getByMonth(
      widget.year,
      widget.month,
    );
    final existingIds = existingBudgets.map((b) => b.categoryId).toSet();
    // Only show categories without budget yet
    final available = cats.where((c) => !existingIds.contains(c.id)).toList();
    setState(() {
      _categories = available;
      if (available.isNotEmpty) _selectedCategory = available.first;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final amount = double.tryParse(
      _amountController.text.replaceAll('.', '').replaceAll(',', ''),
    );
    if (amount == null || amount <= 0 || _selectedCategory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lengkapi semua field')));
      return;
    }

    HapticFeedback.mediumImpact();
    final repo = BudgetRepo();
    await repo.insert(
      BudgetModel(
        id: repo.newId(),
        categoryId: _selectedCategory!.id,
        limitAmount: amount,
        year: widget.year,
        month: widget.month,
        rollover: _rollover,
      ),
    );

    if (mounted) Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_categories.isEmpty) {
      return Scaffold(
        appBar: const CatatInAppBar(subtitle: 'Tambah Budget'),
        body: DotPatternBackground(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 64,
                  color: NeoBrutalColors.success,
                ),
                const SizedBox(height: 16),
                Text(
                  'SEMUA KATEGORI SUDAH PUNYA BUDGET',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: const CatatInAppBar(subtitle: 'Tambah Budget'),
      body: DotPatternBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'KATEGORI',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: NeoBrutalColors.ink.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((cat) {
                  final selected = _selectedCategory?.id == cat.id;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
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
                        cat.name.toUpperCase(),
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
              const SizedBox(height: 24),
              NeoTextField(
                controller: _amountController,
                label: 'Limit Budget (Rp)',
                hint: '0',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.payments_rounded,
              ),
              const SizedBox(height: 16),
              // Rollover toggle — carry positive leftover into next month
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ROLLOVER SISA BUDGET',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Sisa bulan ini ditambahkan ke limit bulan depan',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _rollover,
                    activeThumbColor: NeoBrutalColors.secondary,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _rollover = v);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: NeoButton(
                  label: 'SIMPAN BUDGET',
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
}
