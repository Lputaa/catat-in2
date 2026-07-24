import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/neo_brutal_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/budget_model.dart';
import '../../data/models/category_model.dart';
import '../../data/repositories/budget_repo.dart';
import '../../data/repositories/category_repo.dart';
import '../../shared/widgets/neo_card.dart';
import '../../shared/widgets/neo_button.dart';
import '../../shared/widgets/catat_in_app_bar.dart';
import '../../shared/widgets/dot_pattern_background.dart';

class QuickBudgetScreen extends StatefulWidget {
  const QuickBudgetScreen({super.key});

  @override
  State<QuickBudgetScreen> createState() => _QuickBudgetScreenState();
}

class _QuickBudgetScreenState extends State<QuickBudgetScreen> {
  List<CategoryModel> _categories = [];
  Map<String, TextEditingController> _controllers = {};
  Map<String, bool> _selected = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cats = await CategoryRepo().getByType(CategoryType.expense);
    final controllers = <String, TextEditingController>{};
    final selected = <String, bool>{};
    for (final c in cats) {
      controllers[c.id] = TextEditingController();
      selected[c.id] = false;
    }
    setState(() {
      _categories = cats;
      _controllers = controllers;
      _selected = selected;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final now = DateTime.now();
    final repo = BudgetRepo();
    int count = 0;

    for (final cat in _categories) {
      if (_selected[cat.id] != true) continue;
      final amount = double.tryParse(
        (_controllers[cat.id]?.text ?? '')
            .replaceAll('.', '')
            .replaceAll(',', ''),
      );
      if (amount == null || amount <= 0) continue;

      await repo.insert(
        BudgetModel(
          id: repo.newId(),
          categoryId: cat.id,
          limitAmount: amount,
          year: now.year,
          month: now.month,
        ),
      );
      count++;
    }

    if (count == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pilih minimal 1 kategori dan isi nominal'),
          ),
        );
      }
      return;
    }

    HapticFeedback.mediumImpact();
    if (mounted) Navigator.pop(context, true);
  }

  void _selectAll() {
    setState(() {
      for (final c in _categories) {
        _selected[c.id] = true;
      }
    });
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final selectedCount = _selected.values.where((v) => v).length;

    return Scaffold(
      appBar: CatatInAppBar(
        subtitle: 'Atur Budget Cepat',
        actions: [
          TextButton(
            onPressed: _selectAll,
            child: Text(
              'PILIH SEMUA',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                color: NeoBrutalColors.primary,
              ),
            ),
          ),
        ],
      ),
      body: DotPatternBackground(
        child: Column(
          children: [
            // Info banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: NeoBrutalColors.yellow.withValues(alpha: 0.2),
              child: Text(
                'Pilih kategori dan tentukan budget sekaligus. Lebih cepat!',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _categories.length,
                itemBuilder: (context, i) {
                  final cat = _categories[i];
                  final isChecked = _selected[cat.id] ?? false;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: NeoCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      borderOffset: const Offset(4, 4),
                      child: Row(
                        children: [
                          // Checkbox
                          GestureDetector(
                            onTap: () =>
                                setState(() => _selected[cat.id] = !isChecked),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: isChecked
                                    ? NeoBrutalColors.success
                                    : Colors.transparent,
                                border: Border.all(
                                  color: isChecked
                                      ? NeoBrutalColors.success
                                      : NeoBrutalColors.ink,
                                  width: 2,
                                ),
                              ),
                              child: isChecked
                                  ? const Icon(
                                      Icons.check_rounded,
                                      size: 18,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Category icon + name
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: cat.colorValue.withValues(alpha: 0.15),
                              border: Border.all(
                                color: cat.colorValue,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.category_rounded,
                              size: 16,
                              color: cat.colorValue,
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Name + input
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cat.name.toUpperCase(),
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                    color: isChecked
                                        ? NeoBrutalColors.ink
                                        : NeoBrutalColors.muted,
                                  ),
                                ),
                                if (isChecked)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: TextField(
                                      controller: _controllers[cat.id],
                                      keyboardType: TextInputType.number,
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Rp',
                                        hintStyle: GoogleFonts.spaceGrotesk(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: NeoBrutalColors.muted,
                                        ),
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 8,
                                            ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.zero,
                                          borderSide: const BorderSide(
                                            color: NeoBrutalColors.ink,
                                            width: 2,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.zero,
                                          borderSide: const BorderSide(
                                            color: NeoBrutalColors.ink,
                                            width: 2,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.zero,
                                          borderSide: const BorderSide(
                                            color: NeoBrutalColors.primary,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Bottom action
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: NeoBrutalColors.ink,
                    width: AppConstants.borderPrimary,
                  ),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: NeoButton(
                  label: 'SIMPAN $selectedCount BUDGET',
                  icon: Icons.check_circle_outline_rounded,
                  color: selectedCount > 0
                      ? NeoBrutalColors.success
                      : NeoBrutalColors.muted,
                  onTap: selectedCount > 0 ? _save : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
